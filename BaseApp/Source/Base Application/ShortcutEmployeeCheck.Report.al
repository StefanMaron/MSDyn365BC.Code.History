report 1186 "Shortcut Employee Check"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutEmployeeCheck.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Check';
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

