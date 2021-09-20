codeunit 1820 "Customer Consent Mgt."
{
    procedure ConfirmUserConsent(): Boolean
    var
        CustConsentConfirmation: Page "Cust. Consent Confirmation";
    begin
        CustConsentConfirmation.LookupMode(true);
        exit(CustConsentConfirmation.RunModal() = Action::Yes);
    end;
}