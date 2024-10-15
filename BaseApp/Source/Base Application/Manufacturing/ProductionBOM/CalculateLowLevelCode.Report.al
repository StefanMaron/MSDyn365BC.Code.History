namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.BOM.Tree;

report 152 "Calculate Low Level Code"
{
    ApplicationArea = Planning;
    Caption = 'Calculate Low Level Code';
    ProcessingOnly = true;
    UsageCategory = Tasks;
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

    trigger OnInitReport()
    begin
        Codeunit.Run(Codeunit::"Low-Level Code Calculator");
    end;
}

