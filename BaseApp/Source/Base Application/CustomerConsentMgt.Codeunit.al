namespace System.Privacy;

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

    procedure ConsentToMicrosoftServiceWithAI(): Boolean
    var
        CustConsentConfirmation: Page "Consent Microsoft AI";
    begin
        CustConsentConfirmation.LookupMode(true);
        CustConsentConfirmation.RunModal();
        exit(CustConsentConfirmation.WasAgreed())
    end;

    procedure ConfirmUserConsentToOpenExternalLink(): Boolean
    var
        CustConsentConfirmation: Page "Cust. Consent Confirmation";
    begin
        CustConsentConfirmation.SetOpenExternalLinkConsentText();
        CustConsentConfirmation.LookupMode(true);
        CustConsentConfirmation.RunModal();
        exit(CustConsentConfirmation.WasAgreed())
    end;

    procedure ConfirmCustomConsent(CustomConsentText: Text): Boolean
    var
        CustConsentConfirmation: Page "Cust. Consent Confirmation";
    begin
        CustConsentConfirmation.SetCustomConsentText(CustomConsentText);
        CustConsentConfirmation.LookupMode(true);
        CustConsentConfirmation.RunModal();
        exit(CustConsentConfirmation.WasAgreed())
    end;
}