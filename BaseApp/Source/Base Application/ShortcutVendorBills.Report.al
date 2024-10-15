report 1182 "Shortcut Vendor Bills"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutVendorBills.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Bills';
    UsageCategory = Tasks;
    UseRequestPage = false;
#if not CLEAN18
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
    ObsoleteReason = 'This report will be deprecated the search word will be added to page Vendor Ledger Entries';
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
        PAGE.Run(PAGE::"Vendor Ledger Entries");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

