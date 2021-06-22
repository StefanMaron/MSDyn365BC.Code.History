codeunit 853 "License Agreement Management"
{

    trigger OnRun()
    begin
    end;

    var
        PartnerAgreementNotAcceptedErr: Label 'Partner Agreement has not been accepted.';

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnShowTermsAndConditions', '', false, false)]
    local procedure OnShowTermsAndConditionsSubscriber()
    var
        LicenseAgreement: Record "License Agreement";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if GuiAllowed then
            if not CompanyInformationMgt.IsDemoCompany then
                if LicenseAgreement.Get then
                    if LicenseAgreement.GetActive and not LicenseAgreement.Accepted then begin
                        PAGE.RunModal(PAGE::"Additional Customer Terms");
                        LicenseAgreement.Get();
                        if not LicenseAgreement.Accepted then
                            Error(PartnerAgreementNotAcceptedErr)
                    end;
    end;
}

