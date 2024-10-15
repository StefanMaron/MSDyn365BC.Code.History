namespace Microsoft.CostAccounting.Journal;

report 150 "Transfer GL Entries to CA"
{
    ApplicationArea = CostAccounting;
    Caption = 'Transfer GL Entries to CA';
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
        CODEUNIT.Run(CODEUNIT::"Transfer GL Entries to CA");
    end;
}

