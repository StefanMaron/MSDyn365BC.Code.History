codeunit 11790 "Local Upgrade Tag Definitions"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetCorrectionsForBadReceivableUpgradeTag());
        PerCompanyUpgradeTags.Add(GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

    procedure GetCorrectionsForBadReceivableUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-CorrectionsForBadReceivable-20210122');
    end;

    procedure GetUseIsolatedCertificateInsteadOfCertificateCZ(): Code[250]
    begin
        exit('CZ-322699-UseIsolatedCertificateInsteadOfCertificateCZ-20190909');
    end;

    procedure GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag(): Code[250]
    begin
        exit('CZ-335319-ObsoleteGeneralLedgerEntryDescriptionFeature-20191128');
    end;

    procedure GetVendorTemplateUpgradeTag(): Code[250]
    begin
        exit('CZ-383715-VendorTemplate-20201217');
    end;

    procedure GetIntrastatJnlLineShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-IntrastatJnlLineShipmentMethodCode-20210122');
    end;

    procedure GetItemJournalLineShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-ItemJournalLineShipmentMethodCode-20210122');
    end;

    procedure GetItemLedgerEntryShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-ItemLedgerEntryShipmentMethodCode-20210122');
    end;
}