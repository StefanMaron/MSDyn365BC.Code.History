report 1187 "Shortcut Employee Expense"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutEmployeeExpense.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Expense';
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

