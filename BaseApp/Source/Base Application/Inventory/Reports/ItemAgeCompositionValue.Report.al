namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 5808 "Item Age Composition - Value"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemAgeCompositionValue.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Age Composition - Value';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] + 1))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] + 1))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] + 1))
            {
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5]))
            {
            }
            column(PrintLine; PrintLine)
            {
            }
            column(InvtValueRTC1; InvtValueRTC[1])
            {
            }
            column(InvtValueRTC2; InvtValueRTC[2])
            {
            }
            column(InvtValueRTC5; InvtValueRTC[5])
            {
            }
            column(InvtValueRTC4; InvtValueRTC[4])
            {
            }
            column(InvtValueRTC3; InvtValueRTC[3])
            {
            }
            column(TotalInvtValueRTC; TotalInvtValueRTC)
            {
            }
            column(InvtValue1_Item; InvtValue[1])
            {
                AutoFormatType = 1;
            }
            column(InvtValue2_Item; InvtValue[2])
            {
                AutoFormatType = 1;
            }
            column(InvtValue3_Item; InvtValue[3])
            {
                AutoFormatType = 1;
            }
            column(InvtValue4_Item; InvtValue[4])
            {
                AutoFormatType = 1;
            }
            column(InvtValue5_Item; InvtValue[5])
            {
                AutoFormatType = 1;
            }
            column(TotalInvtValue_Item; TotalInvtValue_Item)
            {
                AutoFormatType = 1;
            }
            column(ItemAgeCompositionValueCaption; ItemAgeCompositionValueCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(InventoryValueCaption; InventoryValueCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", Open) where(Open = const(true));

                trigger OnAfterGetRecord()
                begin
                    if "Remaining Quantity" = 0 then
                        CurrReport.Skip();
                    PrintLine := true;
                    CalcRemainingQty();
                    RemainingQty += TotalInvtQty;

                    if Item."Costing Method" = Item."Costing Method"::Average then begin
                        InvtValue[i] += AverageCost[i] * InvtQty[i];
                        InvtValueRTC[i] += AverageCost[i] * InvtQty[i];
                    end else begin
                        CalcUnitCost();
                        TotalInvtValue_Item += UnitCost * Abs(TotalInvtQty);
                        InvtValue[i] += UnitCost * Abs(InvtQty[i]);

                        TotalInvtValueRTC += UnitCost * Abs(TotalInvtQty);
                        InvtValueRTC[i] += UnitCost * Abs(InvtQty[i]);
                    end
                end;

                trigger OnPostDataItem()
                var
                    AvgCostCurr: Decimal;
                    AvgCostCurrLCY: Decimal;
                begin
                    if Item."Costing Method" = Item."Costing Method"::Average then begin
                        Item.SetRange("Date Filter");
                        ItemCostMgt.CalculateAverageCost(Item, AvgCostCurr, AvgCostCurrLCY);
                        TotalInvtValue_Item := AvgCostCurr * RemainingQty;
                        TotalInvtValueRTC += TotalInvtValue_Item;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TotalInvtValue_Item := 0;
                    for i := 1 to 5 do
                        InvtValue[i] := 0;
                    RemainingQty := 0;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TotalInvtValue_ItemLedgEntry; TotalInvtValue_Item)
                {
                    AutoFormatType = 1;
                }
                column(InvtValue5_ItemLedgEntry; InvtValue[5])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue4_ItemLedgEntry; InvtValue[4])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue3_ItemLedgEntry; InvtValue[3])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue2_ItemLedgEntry; InvtValue[2])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue1_ItemLedgEntry; InvtValue[1])
                {
                    AutoFormatType = 1;
                }
                column(Description_Item; Item.Description)
                {
                }
                column(No_Item; Item."No.")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Costing Method" = "Costing Method"::Average then begin
                    for i := 2 to 5 do begin
                        SetRange("Date Filter", PeriodStartDate[i] + 1, PeriodStartDate[i + 1]);
                        ItemCostMgt.CalculateAverageCost(Item, AverageCost[i], AverageCostACY[i]);
                    end;

                    SetRange("Date Filter", 0D, PeriodStartDate[2]);
                    ItemCostMgt.CalculateAverageCost(Item, AverageCost[1], AverageCostACY[1]);
                end;

                PrintLine := false;
            end;

            trigger OnPreDataItem()
            begin
                Clear(InvtValue);
                Clear(TotalInvtValue_Item);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EndingDate; PeriodStartDate[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the end date of the report. The report calculates backwards from this date and sets up three periods of the length specified in the Period Length field.';

                        trigger OnValidate()
                        begin
                            if PeriodStartDate[5] = 0D then
                                Error(Text002);
                        end;
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of the three periods in the report.';

                        trigger OnValidate()
                        begin
                            if Format(PeriodLength) = '' then
                                Evaluate(PeriodLength, '<0D>');
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[5] = 0D then
                PeriodStartDate[5] := CalcDate('<CM>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        NegPeriodLength: DateFormula;
    begin
        ItemFilter := Item.GetFilters();

        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
        Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));
        for i := 1 to 3 do
            PeriodStartDate[5 - i] := CalcDate(NegPeriodLength, PeriodStartDate[6 - i]);
    end;

    var
        ItemCostMgt: Codeunit ItemCostManagement;
        PeriodLength: DateFormula;
        ItemFilter: Text;
        InvtValue: array[6] of Decimal;
        InvtValueRTC: array[6] of Decimal;
        InvtQty: array[6] of Decimal;
        UnitCost: Decimal;
        PeriodStartDate: array[6] of Date;
        i: Integer;
        TotalInvtValue_Item: Decimal;
        TotalInvtValueRTC: Decimal;
        TotalInvtQty: Decimal;
        PrintLine: Boolean;
        AverageCost: array[5] of Decimal;
        AverageCostACY: array[5] of Decimal;

        Text002: Label 'Enter the ending date';
        ItemAgeCompositionValueCaptionLbl: Label 'Item Age Composition - Value';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AfterCaptionLbl: Label 'After...';
        BeforeCaptionLbl: Label '...Before';
        InventoryValueCaptionLbl: Label 'Inventory Value';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';
        TotalCaptionLbl: Label 'Total';
        RemainingQty: Decimal;

    local procedure CalcRemainingQty()
    begin
        with "Item Ledger Entry" do begin
            for i := 1 to 5 do
                InvtQty[i] := 0;

            TotalInvtQty := "Remaining Quantity";
            for i := 1 to 5 do
                if ("Posting Date" > PeriodStartDate[i]) and
                   ("Posting Date" <= PeriodStartDate[i + 1])
                then
                    if "Remaining Quantity" <> 0 then begin
                        InvtQty[i] := "Remaining Quantity";
                        exit;
                    end;
        end;
    end;

    local procedure CalcUnitCost()
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            UnitCost := 0;

            if Find('-') then
                repeat
                    if "Partial Revaluation" then
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", "Valued Quantity")
                    else
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", "Item Ledger Entry".Quantity);
                until Next() = 0;
        end;
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    procedure InitializeRequest(NewEndingDate: Date; NewPeriodLength: DateFormula)
    begin
        PeriodStartDate[5] := NewEndingDate;
        PeriodLength := NewPeriodLength;
    end;
}

