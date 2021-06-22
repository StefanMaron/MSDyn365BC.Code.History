report 1183 "Shortcut Payment Registration"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ShortcutPaymentRegistration.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Registration';
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
        PAGE.Run(PAGE::"Payment Registration");
        Error(''); // To prevent pdf of this report from downloading.
    end;
}

