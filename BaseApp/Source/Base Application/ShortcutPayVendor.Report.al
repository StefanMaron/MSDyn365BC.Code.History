report 1180 "Shortcut Pay Vendor"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPayVendor.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Pay Vendor';
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
        PAGE.Run(PAGE::"Vendor Ledger Entries");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

