codeunit 11790 "Local Upgrade Tag Definitions"
{
#if not CLEAN21
    ObsoleteState = Pending;
    ObsoleteReason = 'The access of this codeunit will be changed to internal.';
    ObsoleteTag = '21.0';
#else
    Access = internal;
#endif

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
        PerCompanyUpgradeTags.Add(GetCreditWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPaymentOrderWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetBankPaymentApplicationWithoutCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetTextToAccountMappingWithoutCodeUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetCorrectionsForBadReceivableUpgradeTag(): Code[250]
#else
    internal procedure GetCorrectionsForBadReceivableUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-386361-CorrectionsForBadReceivable-20210122');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetUseIsolatedCertificateInsteadOfCertificateCZ(): Code[250]
#else
    internal procedure GetUseIsolatedCertificateInsteadOfCertificateCZ(): Code[250]
#endif
    begin
        exit('CZ-322699-UseIsolatedCertificateInsteadOfCertificateCZ-20190909');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag(): Code[250]
#else
    internal procedure GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-335319-ObsoleteGeneralLedgerEntryDescriptionFeature-20191128');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetVendorTemplateUpgradeTag(): Code[250]
#else
    internal procedure GetVendorTemplateUpgradeTag(): Code[250]
#endif    
    begin
        exit('CZ-383715-VendorTemplate-20201217');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetIntrastatJnlLineShipmentMethodCodeUpgradeTag(): Code[250]
#else
    internal procedure GetIntrastatJnlLineShipmentMethodCodeUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-386361-IntrastatJnlLineShipmentMethodCode-20210122');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetItemJournalLineShipmentMethodCodeUpgradeTag(): Code[250]
#else
    internal procedure GetItemJournalLineShipmentMethodCodeUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-386361-ItemJournalLineShipmentMethodCode-20210122');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetItemLedgerEntryShipmentMethodCodeUpgradeTag(): Code[250]
#else
    internal procedure GetItemLedgerEntryShipmentMethodCodeUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-386361-ItemLedgerEntryShipmentMethodCode-20210122');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetCashDeskWorkflowTemplatesCodeUpgradeTag(): Code[250]
#else
    internal procedure GetCashDeskWorkflowTemplatesCodeUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-403757-CashDeskWorkflowTemplatesCode-20210629');
    end;

#if not CLEAN21
    [Obsolete('The access of this codeunit will be changed to internal.', '21.0')]
    procedure GetCreditWorkflowTemplatesCodeUpgradeTag(): Code[250]
#else
    internal procedure GetCreditWorkflowTemplatesCodeUpgradeTag(): Code[250]
#endif
    begin
        exit('CZ-403757-CreditWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetPaymentOrderWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-PaymentOrderWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-AdvanceLetterWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetBankPaymentApplicationWithoutCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-443967-BankPaymentApplicationWithoutCode-20220726');
    end;

    internal procedure GetTextToAccountMappingWithoutCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-443967-TextToAccountMappingWithoutCode-20220726');
    end;
}