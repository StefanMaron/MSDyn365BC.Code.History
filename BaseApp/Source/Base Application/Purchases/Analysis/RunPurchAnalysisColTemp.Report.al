namespace Microsoft.Purchases.Analysis;

using Microsoft.Inventory.Analysis;

report 7118 "Run Purch. Analysis Col. Temp."
{
    ApplicationArea = PurchaseAnalysis;
    Caption = 'Purchase Analysis Column Templates';
    ProcessingOnly = true;
    UsageCategory = Administration;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

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
        AnalysisColumnTemplate.FilterGroup := 2;
        AnalysisColumnTemplate.SetRange("Analysis Area", AnalysisColumnTemplate."Analysis Area"::Purchase);
        AnalysisColumnTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisColumnTemplate);
    end;

    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
}

