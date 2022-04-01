codeunit 1820 "Customer Consent Mgt."
{
    procedure ConfirmUserConsent(): Boolean
    var
        CustConsentConfirmation: Page "Cust. Consent Confirmation";
    begin
        CustConsentConfirmation.LookupMode(true);
        CustConsentConfirmation.RunModal();
        exit(CustConsentConfirmation.WasAgreed())
    end;

    procedure ConfirmUserConsentToMicrosoftService(): Boolean
    var
        CustConsentConfirmation: Page "Consent Microsoft Confirm";
    begin
        CustConsentConfirmation.LookupMode(true);
        CustConsentConfirmation.RunModal();
        exit(CustConsentConfirmation.WasAgreed())
    end;
}