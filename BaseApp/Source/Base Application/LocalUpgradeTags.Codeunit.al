codeunit 11790 "Local Upgrade Tag Definitions"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetCorrectionsForBadReceivableUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

    procedure GetCorrectionsForBadReceivableUpgradeTag(): Code[250]
    begin
        exit('CZ-323219-CorrectionsForBadReceivable-20190823');
    end;

    procedure GetUseIsolatedCertificateInsteadOfCertificateCZ(): Code[250]
    begin
        exit('CZ-322699-UseIsolatedCertificateInsteadOfCertificateCZ-20190909');
    end;
}