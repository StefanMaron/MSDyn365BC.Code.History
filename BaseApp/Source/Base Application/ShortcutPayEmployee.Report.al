report 1185 "Shortcut Pay Employee"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPayEmployee.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pay Employee';
    UsageCategory = Tasks;
    UseRequestPage = false;
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
    ObsoleteReason = 'This report will be deprecated the search word will be added to page Employee Ledger Entries';

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
        PAGE.Run(PAGE::"Employee Ledger Entries");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

