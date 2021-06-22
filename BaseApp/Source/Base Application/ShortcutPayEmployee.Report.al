report 1185 "Shortcut Pay Employee"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPayEmployee.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pay Employee';
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
        PAGE.Run(PAGE::"Employee Ledger Entries");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

