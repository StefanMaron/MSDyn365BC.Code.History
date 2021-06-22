report 1182 "Shortcut Vendor Bills"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutVendorBills.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Bills';
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

