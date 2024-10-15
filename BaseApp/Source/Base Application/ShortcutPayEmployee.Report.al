report 1185 "Shortcut Pay Employee"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPayEmployee.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pay Employee';
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

