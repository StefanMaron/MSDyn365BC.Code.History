report 1180 "Shortcut Pay Vendor"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPayVendor.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pay Vendor';
    UsageCategory = Tasks;
    UseRequestPage = false;
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
    ObsoleteReason = 'This report will be deprecated the search word will be added to page Vendor Ledger Entries';

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

