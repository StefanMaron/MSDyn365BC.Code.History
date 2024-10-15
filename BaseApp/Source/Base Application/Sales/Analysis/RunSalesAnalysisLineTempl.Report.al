namespace Microsoft.Sales.Analysis;

using Microsoft.Inventory.Analysis;

report 7114 "Run Sales Analysis Line Templ."
{
    ApplicationArea = SalesAnalysis;
    Caption = 'Sales Analysis Line Templates';
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
        AnalysisLineTemplate.FilterGroup := 2;
        AnalysisLineTemplate.SetRange("Analysis Area", AnalysisLineTemplate."Analysis Area"::Sales);
        AnalysisLineTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisLineTemplate);
    end;

    var
        AnalysisLineTemplate: Record "Analysis Line Template";
}

