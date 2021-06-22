codeunit 1317 "Aged Inventory Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        YCaptionTxt: Label 'Inventory Value';
        XCaptionTxt: Label 'Time on Inventory';
        PeriodStartDate: array[6] of Date;
        XFromToYearsTxt: Label '%1..%2 years', Comment = '%1=number of years,%2=number of years';
        XFromToDaysTxt: Label '%1..%2 days', Comment = '%1=number of days,%2=number of days';
        XOverYearsTxt: Label 'Over %1 years';
        XOverDaysTxt: Label 'Over %1 days';

    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        ColumnIndex: Integer;
        PeriodStartDate: array[6] of Date;
        InvtValue: array[5] of Decimal;
    begin
        with BusChartBuf do begin
            Initialize;
            AddMeasure(YCaptionTxt, 1, "Data Type"::Decimal, "Chart Type"::StackedColumn);
            SetXAxis(XCaptionTxt, "Data Type"::String);
            CalcPeriodStartDates(PeriodStartDate, GetPeriodLengthInDays(BusChartBuf));
            AddChartColumns(BusChartBuf);
            CalcInventoryValuePerAge(InvtValue, PeriodStartDate);
            for ColumnIndex := 1 to 5 do
                SetValueByIndex(0, ColumnIndex - 1, InvtValue[6 - ColumnIndex]);
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        DrillDownXIndex: Integer;
    begin
        CalcPeriodStartDates(PeriodStartDate, GetPeriodLengthInDays(BusChartBuf));
        DrillDownXIndex := BusChartBuf."Drill-Down X Index";
        case BusChartBuf."Drill-Down Measure Index" + 1 of
            1: // Item Ledger Entries
                DrillDownItemLedgerEntries(PeriodStartDate[5 - DrillDownXIndex], PeriodStartDate[6 - DrillDownXIndex]);
        end;
    end;

    procedure CalcInventoryValuePerAge(var InvtValue: array[5] of Decimal; PeriodStartDate: array[6] of Date)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        InvtQty: array[5] of Decimal;
        UnitCost: Decimal;
        PeriodNo: Integer;
    begin
        Item.SetRange(Type, Item.Type::Inventory, Item.Type::Inventory);
        if Item.Find('-') then
            repeat
                with ItemLedgerEntry do begin
                    SetRange(Open, true, true);
                    SetRange("Item No.", Item."No.", Item."No.");
                    if Find('-') then
                        repeat
                            CalcRemainingQty(ItemLedgerEntry, PeriodStartDate, InvtQty, PeriodNo);
                            UnitCost := CalcUnitCost(ItemLedgerEntry);
                            InvtValue[PeriodNo] += UnitCost * Abs(InvtQty[PeriodNo]);
                        until Next = 0;
                end;
            until Item.Next = 0;
    end;

    local procedure AddChartColumns(var BusChartBuf: Record "Business Chart Buffer")
    var
        I: Integer;
        PeriodLengthOnXAxis: Integer;
        XAxisValueTxt: Text[30];
        LastXAxisValueTxt: Text[30];
    begin
        with BusChartBuf do begin
            PeriodLengthOnXAxis := GetPeriodLengthInDays(BusChartBuf);
            if PeriodLengthOnXAxis = 365 then begin
                PeriodLengthOnXAxis := 1;
                XAxisValueTxt := XFromToYearsTxt;
                LastXAxisValueTxt := XOverYearsTxt;
            end else begin
                XAxisValueTxt := XFromToDaysTxt;
                LastXAxisValueTxt := XOverDaysTxt;
            end;
            for I := 0 to 3 do
                AddColumn(StrSubstNo(XAxisValueTxt, I * PeriodLengthOnXAxis, (I + 1) * PeriodLengthOnXAxis));  // X-Axis value
            AddColumn(StrSubstNo(LastXAxisValueTxt, Format(4 * PeriodLengthOnXAxis)));  // X-Axis value
        end;
    end;

    local procedure CalcPeriodStartDates(var PeriodStartDate: array[6] of Date; PeriodLength: Integer)
    var
        I: Integer;
    begin
        PeriodStartDate[6] := WorkDate;
        PeriodStartDate[1] := 0D;
        for I := 2 to 5 do
            PeriodStartDate[I] := CalcDate('<-' + Format((6 - I) * PeriodLength) + 'D>', PeriodStartDate[6]);
    end;

    procedure CalcRemainingQty(ItemLedgerEntry: Record "Item Ledger Entry"; PeriodStartDate: array[6] of Date; var InvtQty: array[5] of Decimal; var PeriodNo: Integer)
    begin
        with ItemLedgerEntry do begin
            for PeriodNo := 1 to 5 do
                InvtQty[PeriodNo] := 0;

            for PeriodNo := 1 to 5 do
                if ("Posting Date" > PeriodStartDate[PeriodNo]) and
                   ("Posting Date" <= PeriodStartDate[PeriodNo + 1])
                then
                    if "Remaining Quantity" <> 0 then begin
                        InvtQty[PeriodNo] := "Remaining Quantity";
                        exit;
                    end;
        end;
    end;

    procedure CalcUnitCost(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        with ValueEntry do begin
            SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            UnitCost := 0;

            if Find('-') then
                repeat
                    if "Partial Revaluation" then
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", "Valued Quantity")
                    else
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", ItemLedgerEntry.Quantity);
                until Next = 0;
        end;
        exit(UnitCost);
    end;

    procedure GetPeriodLengthInDays(BusChartBuf: Record "Business Chart Buffer"): Integer
    begin
        with BusChartBuf do
            case "Period Length" of
                "Period Length"::Day:
                    exit(1);
                "Period Length"::Week:
                    exit(7);
                "Period Length"::Month:
                    exit(30);
                "Period Length"::Quarter:
                    exit(90);
                "Period Length"::Year:
                    exit(365);
            end;
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    local procedure DrillDownItemLedgerEntries(StartDate: Date; EndDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange(Open, true);
        // we don't want to include start date in the filter, unless it is 0D
        if StartDate = 0D then
            ItemLedgerEntry.SetRange("Posting Date", StartDate, EndDate)
        else
            ItemLedgerEntry.SetRange("Posting Date", CalcDate('<1D>', StartDate), EndDate);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '<>0');
        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgerEntry);
    end;

    procedure FromToYearsTxt(): Text[30]
    begin
        exit(XFromToYearsTxt);
    end;

    procedure FromToDaysTxt(): Text[30]
    begin
        exit(XFromToDaysTxt);
    end;

    procedure OverYearsTxt(): Text[30]
    begin
        exit(XOverYearsTxt);
    end;

    procedure OverDaysTxt(): Text[30]
    begin
        exit(XOverDaysTxt);
    end;
}

