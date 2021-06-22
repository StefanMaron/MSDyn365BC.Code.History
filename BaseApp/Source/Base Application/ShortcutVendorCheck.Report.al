report 1181 "Shortcut Vendor Check"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutVendorCheck.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Check';
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

