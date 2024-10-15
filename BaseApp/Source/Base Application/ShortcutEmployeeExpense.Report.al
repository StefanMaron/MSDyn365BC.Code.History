report 1187 "Shortcut Employee Expense"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutEmployeeExpense.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Expense';
    UsageCategory = Tasks;
    UseRequestPage = false;
#if not CLEAN18
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
    ObsoleteReason = 'This report will be deprecated the search word will be added to page Employee Ledger Entries';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '21.0';
#endif

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

