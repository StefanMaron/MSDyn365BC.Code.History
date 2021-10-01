report 1184 "Shortcut Receive Customer Pay"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutReceiveCustomerPay.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Receive Customer Payments';
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
        PAGE.Run(PAGE::"Payment Registration");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

