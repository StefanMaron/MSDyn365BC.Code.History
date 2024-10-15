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
        PerCompanyUpgradeTags.Add(GetVendorTemplateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntrastatJnlLineShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemJournalLineShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemLedgerEntryShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCashDeskWorkflowTemplatesCodeUpgradeTag());
#if CLEAN18
        PerCompanyUpgradeTags.Add(GetCreditWorkflowTemplatesCodeUpgradeTag());
#endif
#if CLEAN19
        PerCompanyUpgradeTags.Add(GetPaymentOrderWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag());
#endif
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

    procedure GetCashDeskWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-CashDeskWorkflowTemplatesCode-20210629');
    end;

#if CLEAN18
    procedure GetCreditWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-CreditWorkflowTemplatesCode-20210629');
    end;

#endif
#if CLEAN19
    procedure GetPaymentOrderWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-PaymentOrderWorkflowTemplatesCode-20210629');
    end;

    procedure GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-AdvanceLetterWorkflowTemplatesCode-20210629');
    end;
#endif
}