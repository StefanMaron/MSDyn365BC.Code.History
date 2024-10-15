namespace Microsoft.Manufacturing.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Document;

report 99000791 "Production Order Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProductionOrderStatistics.rdlc';
    AdditionalSearchTerms = 'material cost,capacity cost,material overhead';
    ApplicationArea = Manufacturing;
    Caption = 'Production Order Statistics';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ProdOrderTableCaptionFilt; StrSubstNo('%1: %2', TableCaption(), ProdOrderFilter))
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(No_ProdOrder; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_ProdOrder; Description)
            {
                IncludeCaption = true;
            }
            column(ExpCost2; ExpCost[2])
            {
                AutoFormatType = 1;
            }
            column(ExpCost1; ExpCost[1])
            {
                AutoFormatType = 1;
            }
            column(ExpCost6; ExpCost[6])
            {
                AutoFormatType = 1;
            }
            column(ExpCost3; ExpCost[3])
            {
                AutoFormatType = 1;
            }
            column(ExpCost4; ExpCost[4])
            {
                AutoFormatType = 1;
            }
            column(ExpCost5; ExpCost[5])
            {
                AutoFormatType = 1;
            }
            column(ActCost1; ActCost[1])
            {
                AutoFormatType = 1;
            }
            column(ActCost2; ActCost[2])
            {
                AutoFormatType = 1;
            }
            column(ActCost3; ActCost[3])
            {
                AutoFormatType = 1;
            }
            column(ActCost4; ActCost[4])
            {
                AutoFormatType = 1;
            }
            column(ActCost5; ActCost[5])
            {
                AutoFormatType = 1;
            }
            column(ActCost6; ActCost[6])
            {
                AutoFormatType = 1;
            }
            column(VarPct1; VarPct[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct2; VarPct[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct3; VarPct[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct4; VarPct[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct5; VarPct[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct6; VarPct[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Status_ProdOrder; Status)
            {
                IncludeCaption = true;
            }
            column(ProdOrderStatisticsCapt; ProdOrderStatisticsCaptLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CapacityCostCaption; CapacityCostCaptionLbl)
            {
            }
            column(MaterialCostCaption; MaterialCostCaptionLbl)
            {
            }
            column(TotalCostCaption; TotalCostCaptionLbl)
            {
            }
            column(SubcontractedCostCaption; SubcontractedCostCaptionLbl)
            {
            }
            column(CapOverheadCostCaption; CapOverheadCostCaptionLbl)
            {
            }
            column(MatOverheadCostCaption; MatOverheadCostCaptionLbl)
            {
            }
            column(ExpectedCaption; ExpectedCaptionLbl)
            {
            }
            column(ActualCaption; ActualCaptionLbl)
            {
            }
            column(DeviationCaption; DeviationCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                Clear(StdCost);
                Clear(ExpCost);
                Clear(ActCost);
                Clear(CostCalcMgt);

                GLSetup.Get();

                ProdOrderLine.SetRange(Status, Status);
                ProdOrderLine.SetRange("Prod. Order No.", "No.");
                ProdOrderLine.SetRange("Planning Level Code", 0);
                if ProdOrderLine.FindSet() then
                    repeat
                        CostCalcMgt.CalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
                        CostCalcMgt.CalcProdOrderLineStdCost(
                          ProdOrderLine, 1, GLSetup."Amount Rounding Precision",
                          StdCost[1], StdCost[2], StdCost[3], StdCost[4], StdCost[5]);
                        CostCalcMgt.CalcProdOrderLineExpCost(
                          ProdOrderLine, ShareOfTotalCapCost,
                          ExpCost[1], ExpCost[2], ExpCost[3], ExpCost[4], ExpCost[5]);
                        CostCalcMgt.CalcProdOrderLineActCost(
                          ProdOrderLine,
                          ActCost[1], ActCost[2], ActCost[3], ActCost[4], ActCost[5],
                          DummyVar, DummyVar, DummyVar, DummyVar, DummyVar);
                    until ProdOrderLine.Next() = 0;

                CalcTotal(StdCost, StdCost[6]);
                CalcTotal(ExpCost, ExpCost[6]);
                CalcTotal(ActCost, ActCost[6]);
                CalcVariance();
            end;

            trigger OnPreDataItem()
            begin
                Clear(ExpCost);
                Clear(ActCost);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Production Order Statistics';
        AboutText = 'Analyse your actual costs and variance from expected cost for production orders to make key decisions about your production execution and its impact on costs. Displays a breakdown of all cost categories for a production order including material, capacity, subcontracting, and overheads.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ProdOrderFilter := "Production Order".GetFilters();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ProdOrderFilter: Text;
        ShareOfTotalCapCost: Decimal;
        ExpCost: array[6] of Decimal;
        ActCost: array[6] of Decimal;
        StdCost: array[6] of Decimal;
        VarPct: array[6] of Decimal;
        DummyVar: Decimal;
        ProdOrderStatisticsCaptLbl: Label 'Production Order Statistics';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CapacityCostCaptionLbl: Label 'Capacity Cost';
        MaterialCostCaptionLbl: Label 'Material Cost';
        TotalCostCaptionLbl: Label 'Total Cost';
        SubcontractedCostCaptionLbl: Label 'Subcontracted Cost';
        CapOverheadCostCaptionLbl: Label 'Capacity Overhead Cost';
        MatOverheadCostCaptionLbl: Label 'Material Overhead Cost';
        ExpectedCaptionLbl: Label 'Expected';
        ActualCaptionLbl: Label 'Actual';
        DeviationCaptionLbl: Label 'Deviation';
        TotalCaptionLbl: Label 'Total';

    local procedure CalcTotal(Operand: array[6] of Decimal; var Total: Decimal)
    var
        i: Integer;
    begin
        Total := 0;

        for i := 1 to ArrayLen(Operand) - 1 do
            Total := Total + Operand[i];
    end;

    local procedure CalcVariance()
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VarPct) do
            VarPct[i] := CalcIndicatorPct(ExpCost[i], ActCost[i]);
    end;

    local procedure CalcIndicatorPct(Value: Decimal; "Sum": Decimal): Decimal
    begin
        if Value = 0 then
            exit(0);

        exit(Round((Sum - Value) / Value * 100, 1));
    end;
}

