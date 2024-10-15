namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using System.Visualization;

codeunit 869 "Cash Flow Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        TextTotal: Label 'Total';
        TextPositive: Label 'Positive';
        TextNegative: Label 'Negative';
        Text001: Label 'Select the "Show in Chart on Role Center" field in the Cash Flow Forecast window to display the chart on the Role Center.';

    procedure OnOpenPage(var CashFlowChartSetup: Record "Cash Flow Chart Setup")
    begin
        with CashFlowChartSetup do
            if not Get(UserId) then begin
                "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                "Start Date" := "Start Date"::"Working Date";
                "Period Length" := "Period Length"::Month;
                Show := Show::Combined;
                "Chart Type" := "Chart Type"::"Stacked Column";
                "Group By" := "Group By"::"Source Type";
                Insert();
            end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        ToDate: Date;
    begin
        ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");

        CashFlowChartSetup.Get(UserId);
        BusChartBuf."Period Length" := CashFlowChartSetup."Period Length";
        CashFlowForecast.Reset();
        CashFlowForecast.SetCashFlowDateFilter(BusChartBuf.CalcFromDate(ToDate), ToDate);
        DrillDownAmountForGroupBy(CashFlowForecast, CashFlowChartSetup."Group By", BusChartBuf.GetCurrMeasureValueString());
    end;

    local procedure DrillDownAmountForGroupBy(var CashFlowForecast: Record "Cash Flow Forecast"; GroupBy: Option; Value: Text[30])
    var
        SourceType: Integer;
        AccountNo: Code[20];
        PositiveAmount: Boolean;
    begin
        if Value = '' then
            CashFlowForecast.DrillDown()
        else
            case GroupBy of
                CashFlowChartSetup."Group By"::"Positive/Negative":
                    begin
                        Evaluate(PositiveAmount, Value, 9);
                        CashFlowForecast.DrillDownPosNegEntries(PositiveAmount);
                    end;
                CashFlowChartSetup."Group By"::"Account No.":
                    begin
                        Evaluate(AccountNo, Value, 9);
                        CashFlowForecast.DrillDownEntriesForAccNo(AccountNo);
                    end;
                CashFlowChartSetup."Group By"::"Source Type":
                    begin
                        Evaluate(SourceType, Value, 9);
                        CashFlowForecast.DrillDownSourceTypeEntries("Cash Flow Source Type".FromInteger(SourceType));
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer"): Boolean
    var
        BusChartMapColumn: Record "Business Chart Map";
        BusChartMapMeasure: Record "Business Chart Map";
        Amount: Decimal;
        FromDate: Date;
        ToDate: Date;
        Accumulate: Boolean;
    begin
        if not CashFlowSetup.Get() or CashFlowForecast.IsEmpty() then
            exit(false);
        if CashFlowSetup."CF No. on Chart in Role Center" = '' then begin
            Message(Text001);
            exit(false);
        end;
        CashFlowForecast.Get(CashFlowSetup."CF No. on Chart in Role Center");
        CashFlowChartSetup.Get(UserId);

        with BusChartBuf do begin
            Initialize();
            "Period Length" := CashFlowChartSetup."Period Length";
            SetPeriodXAxis();

            if CalcPeriods(CashFlowForecast, BusChartBuf) then begin
                case CashFlowChartSetup.Show of
                    CashFlowChartSetup.Show::"Accumulated Cash":
                        AddMeasures(CashFlowForecast, CashFlowChartSetup.Show::"Accumulated Cash", BusChartBuf);
                    CashFlowChartSetup.Show::"Change in Cash":
                        AddMeasures(CashFlowForecast, CashFlowChartSetup.Show::"Change in Cash", BusChartBuf);
                    CashFlowChartSetup.Show::Combined:
                        begin
                            AddMeasures(CashFlowForecast, CashFlowChartSetup.Show::"Change in Cash", BusChartBuf);
                            AddMeasures(CashFlowForecast, CashFlowChartSetup.Show::"Accumulated Cash", BusChartBuf);
                        end;
                end;

                if FindFirstMeasure(BusChartMapMeasure) then
                    repeat
                        Accumulate := BusChartMapMeasure.Name = TextTotal;
                        if FindFirstColumn(BusChartMapColumn) then
                            repeat
                                ToDate := BusChartMapColumn.GetValueAsDate();

                                if Accumulate then begin
                                    if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                                        FromDate := WorkDate()
                                    else
                                        FromDate := 0D
                                end else
                                    FromDate := CalcFromDate(ToDate);

                                CashFlowForecast.Reset();
                                CashFlowForecast.SetCashFlowDateFilter(FromDate, ToDate);
                                Amount := CalcAmountForGroupBy(CashFlowForecast, CashFlowChartSetup."Group By", BusChartMapMeasure."Value String");

                                SetValue(BusChartMapMeasure.Name, BusChartMapColumn.Index, Amount);
                            until not NextColumn(BusChartMapColumn);
                    until not NextMeasure(BusChartMapMeasure);
            end;
        end;
        exit(true);
    end;

    local procedure CalcAmountForGroupBy(var CashFlowForecast: Record "Cash Flow Forecast"; GroupBy: Option; Value: Text[30]): Decimal
    var
        SourceType: Integer;
        AccountNo: Code[20];
        PositiveAmount: Boolean;
    begin
        if Value = '' then
            exit(CashFlowForecast.CalcAmount());

        case GroupBy of
            CashFlowChartSetup."Group By"::"Positive/Negative":
                begin
                    Evaluate(PositiveAmount, Value, 9);
                    exit(CashFlowForecast.CalcAmountForPosNeg(PositiveAmount));
                end;
            CashFlowChartSetup."Group By"::"Account No.":
                begin
                    Evaluate(AccountNo, Value, 9);
                    exit(CashFlowForecast.CalcAmountForAccountNo(AccountNo));
                end;
            CashFlowChartSetup."Group By"::"Source Type":
                begin
                    Evaluate(SourceType, Value, 9);
                    exit(CashFlowForecast.CalcSourceTypeAmount("Cash Flow Source Type".FromInteger(SourceType)));
                end;
        end;
    end;

    local procedure AddMeasures(CashFlowForecast: Record "Cash Flow Forecast"; Show: Option; var BusChartBuf: Record "Business Chart Buffer")
    begin
        case Show of
            CashFlowChartSetup.Show::"Accumulated Cash":
                BusChartBuf.AddDecimalMeasure(TextTotal, '', BusChartBuf."Chart Type"::StepLine);
            CashFlowChartSetup.Show::"Change in Cash":
                case CashFlowChartSetup."Group By" of
                    CashFlowChartSetup."Group By"::"Positive/Negative":
                        CollectPosNeg(CashFlowForecast, BusChartBuf);
                    CashFlowChartSetup."Group By"::"Account No.":
                        CollectAccounts(CashFlowForecast, BusChartBuf);
                    CashFlowChartSetup."Group By"::"Source Type":
                        CollectSourceTypes(CashFlowForecast, BusChartBuf);
                end;
        end;
    end;

    local procedure GetEntryDate(CashFlowForecast: Record "Cash Flow Forecast"; Which: Option First,Last): Date
    begin
        if Which = Which::First then
            if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                exit(WorkDate());
        exit(CashFlowForecast.GetEntryDate(Which));
    end;

    [Scope('OnPrem')]
    procedure CollectSourceTypes(CashFlowForecast: Record "Cash Flow Forecast"; var BusChartBuf: Record "Business Chart Buffer"): Integer
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        FromDate: Date;
        ToDate: Date;
        SourceType: Option;
        Which: Option First,Last;
        Index: Integer;
    begin
        Index := 0;
        FromDate := CashFlowChartSetup.GetStartDate();
        ToDate := CashFlowForecast.GetEntryDate(Which::Last);
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.SetRange("Cash Flow Date", FromDate, ToDate);
        for SourceType := 1 to CashFlowWorksheetLine.GetNumberOfSourceTypes() do begin
            CFForecastEntry.SetRange("Source Type", SourceType);
            if not CFForecastEntry.IsEmpty() then begin
                CashFlowForecast."Source Type Filter" := "Cash Flow Source Type".FromInteger(SourceType);
                Index += 1;
                BusChartBuf.AddDecimalMeasure(
                  Format(CashFlowForecast."Source Type Filter"),
                  CashFlowForecast."Source Type Filter", BusChartBuf."Chart Type"::StackedColumn);
            end;
        end;
        exit(Index);
    end;

    [Scope('OnPrem')]
    procedure CollectAccounts(CashFlowForecast: Record "Cash Flow Forecast"; var BusChartBuf: Record "Business Chart Buffer"): Integer
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFAccount: Record "Cash Flow Account";
        FromDate: Date;
        ToDate: Date;
        Which: Option First,Last;
        Index: Integer;
    begin
        Index := 0;
        FromDate := CashFlowChartSetup.GetStartDate();
        ToDate := CashFlowForecast.GetEntryDate(Which::Last);
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.SetRange("Cash Flow Date", FromDate, ToDate);
        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
        if CFAccount.FindSet() then
            repeat
                CFForecastEntry.SetRange("Cash Flow Account No.", CFAccount."No.");
                if not CFForecastEntry.IsEmpty() then begin
                    Index += 1;
                    BusChartBuf.AddDecimalMeasure(
                      CFAccount."No.", CFAccount."No.", BusChartBuf."Chart Type"::StackedColumn);
                end;
            until CFAccount.Next() = 0;
        exit(Index);
    end;

    [Scope('OnPrem')]
    procedure CollectPosNeg(CashFlowForecast: Record "Cash Flow Forecast"; var BusChartBuf: Record "Business Chart Buffer"): Integer
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        Caption: Text[80];
        FromDate: Date;
        ToDate: Date;
        Which: Option First,Last;
        Index: Integer;
        Positive: Boolean;
    begin
        Index := 0;
        FromDate := CashFlowChartSetup.GetStartDate();
        ToDate := CashFlowForecast.GetEntryDate(Which::Last);
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.SetRange("Cash Flow Date", FromDate, ToDate);
        Caption := TextNegative;
        for Positive := false to true do begin
            CFForecastEntry.SetRange(Positive, Positive);
            if not CFForecastEntry.IsEmpty() then begin
                Index += 1;
                BusChartBuf.AddDecimalMeasure(Caption, Positive, BusChartBuf."Chart Type"::StackedColumn);
            end;
            Caption := TextPositive;
        end;
        exit(Index);
    end;

    local procedure CalcPeriods(CashFlowForecast: Record "Cash Flow Forecast"; var BusChartBuf: Record "Business Chart Buffer"): Boolean
    var
        Which: Option First,Last;
        FromDate: Date;
        ToDate: Date;
    begin
        FromDate := GetEntryDate(CashFlowForecast, Which::First);
        ToDate := GetEntryDate(CashFlowForecast, Which::Last);
        if ToDate <> 0D then
            BusChartBuf.AddPeriods(FromDate, ToDate);
        exit(ToDate <> 0D);
    end;
}

