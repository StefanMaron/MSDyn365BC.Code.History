codeunit 9998 "Upgrade Tag Definitions"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetTimeRegistrationUpgradeTag);
        PerCompanyUpgradeTags.Add(GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNotificationEntryMergeErrorMessageFieldsUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNewSalesInvoiceEntityAggregateUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNewPurchInvEntityAggregateUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNewSalesOrderEntityBufferUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNewSalesQuoteEntityBufferUpgradeTag);
        PerCompanyUpgradeTags.Add(GetNewSalesCrMemoEntityBufferUpgradeTag);
        PerCompanyUpgradeTags.Add(GetCleanupDataExchUpgradeTag);
        PerCompanyUpgradeTags.Add(GetDefaultDimensionAPIUpgradeTag);
        PerCompanyUpgradeTags.Add(GetBalAccountNoOnJournalAPIUpgradeTag);
        PerCompanyUpgradeTags.Add(GetItemCategoryOnItemAPIUpgradeTag);
        PerCompanyUpgradeTags.Add(GetMoveCurrencyISOCodeTag);
        PerCompanyUpgradeTags.Add(GetItemTrackingCodeUseExpirationDatesTag);
        PerCompanyUpgradeTags.Add(GetCountryApplicationAreasTag);
        PerCompanyUpgradeTags.Add(GetVATRepSetupPeriodRemCalcUpgradeTag);
        PerCompanyUpgradeTags.Add(GetGLBankAccountNoTag);
        PerCompanyUpgradeTags.Add(GetServicePasswordToIsolatedStorageTag);
        PerCompanyUpgradeTags.Add(GetAddingIDToJobsUpgradeTag);
        PerCompanyUpgradeTags.Add(GetEncryptedKeyValueToIsolatedStorageTag);
        PerCompanyUpgradeTags.Add(GetGraphMailRefreshCodeToIsolatedStorageTag);
        PerCompanyUpgradeTags.Add(GetStandardSalesCodeUpgradeTag);
        PerCompanyUpgradeTags.Add(GetStandardPurchaseCodeUpgradeTag);
        PerCompanyUpgradeTags.Add(GetSalesOrderShipmentMethodUpgradeTag);
        PerCompanyUpgradeTags.Add(GetSalesCrMemoShipmentMethodUpgradeTag);
        PerCompanyUpgradeTags.Add(GetLastUpdateInvoiceEntryNoUpgradeTag);
        PerCompanyUpgradeTags.Add(GetIncomingDocumentURLUpgradeTag);
        PerCompanyUpgradeTags.Add(GetUpdateProfileReferencesForCompanyTag());
        PerCompanyUpgradeTags.Add(GetCashFlowCortanaFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCortanaIntelligenceUsageUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetNewISVPlansUpgradeTag);
        PerDatabaseUpgradeTags.Add(GetWorkflowWebhookWebServicesUpgradeTag);
        PerDatabaseUpgradeTags.Add(GetExcelTemplateWebServicesUpgradeTag);
        PerDatabaseUpgradeTags.Add(GetAddDeviceISVEmbUpgradeTag);
        PerDatabaseUpgradeTags.Add(GetAddBackupRestorePermissionSetUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUpdateProfileReferencesForDatabaseTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromPlanUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromUsersUpgradeTag());
    end;

    procedure GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('291121-JobQueueEntryMergingErrorMessageFields-20190307')
    end;

    procedure GetNotificationEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('323517-NotificationEntryMergingErrorMessageFields-20190823')
    end;

    procedure GetTimeRegistrationUpgradeTag(): Code[250]
    begin
        exit('284963-TimeRegistrationAPI-ReadOnly-20181010');
    end;

    procedure GetSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('298839-SalesInvoiceAddingMultipleAddresses-20190213');
    end;

    procedure GetPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('294917-PurchInvoiceAddingMultipleAddresses-20190213');
    end;

    procedure GetSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesOrderAddingMultipleAddresses-20190213');
    end;

    procedure GetSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesQuoteAddingMultipleAddresses-20190213');
    end;

    procedure GetSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesCrMemoAddingMultipleAddresses-20190213');
    end;

    procedure GetNewSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesInvoiceAddingMultipleAddresses-20190731');
    end;

    procedure GetNewPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-PurchInvoiceAddingMultipleAddresses-20190731');
    end;

    procedure GetNewSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesOrderAddingMultipleAddresses-20190731');
    end;

    procedure GetNewSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesQuoteAddingMultipleAddresses-20190731');
    end;

    procedure GetNewSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesCrMemoAddingMultipleAddresses-20190731');
    end;

    procedure GetNewISVPlansUpgradeTag(): Code[250]
    begin
        exit('MS-287563-NewISVPlansAdded-20181105');
    end;

    procedure GetWorkflowWebhookWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-WorkflowWebhookWebServices-20180907');
    end;

    procedure GetExcelTemplateWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-ExcelTemplateWebServices-20180907');
    end;

    procedure GetCleanupDataExchUpgradeTag(): Code[250]
    begin
        exit('MS-CleanupDataExchUpgrade-20180821');
    end;

    procedure GetDefaultDimensionAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275427-DefaultDimensionAPI-20180719');
    end;

    procedure GetBalAccountNoOnJournalAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275328-BalAccountNoOnJournalAPI-20180823');
    end;

    procedure GetItemCategoryOnItemAPIUpgradeTag(): Code[250]
    begin
        exit('MS-279686-ItemCategoryOnItemAPI-20180903');
    end;

    procedure GetMoveCurrencyISOCodeTag(): Code[250]
    begin
        exit('MS-267101-MoveCurrencyISOCode-20190209');
    end;

    procedure GetItemTrackingCodeUseExpirationDatesTag(): Code[250]
    begin
        exit('MS-296384-GetItemTrackingCodeUseExpirationDates-20190305');
    end;

    procedure GetCountryApplicationAreasTag(): Code[250]
    begin
        exit('MS-GetCountryApplicationAreas-20190315');
    end;

    procedure GetGLBankAccountNoTag(): Code[250]
    begin
        exit('MS-305176-GetGLBankAccountNoTag-20190408');
    end;

    procedure GetVATRepSetupPeriodRemCalcUpgradeTag(): Code[250]
    begin
        exit('MS-306583-VATReportSetup-20190402');
    end;

    procedure GetServicePasswordToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-ServicePassword-20190429');
    end;

    procedure GetAddingIDToJobsUpgradeTag(): Code[250]
    begin
        exit('MS-310839-GETAddingIDToJobs-20190506');
    end;

    procedure GetEncryptedKeyValueToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-EncKeyValue-20190429');
    end;

    procedure GetGraphMailRefreshCodeToIsolatedStorageTag(): Code[250]
    begin
        EXIT('MS-304318-GraphMailRefreshCode-20190429');
    end;

    procedure GetStandardSalesCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardSalesCode-20190517');
    end;

    procedure GetStandardPurchaseCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardPurchaseCode-20190517');
    end;

    procedure GetSalesOrderShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesOrderShipmentMethod-20190606');
    end;

    procedure GetUpdateProfileReferencesForCompanyTag(): Code[250]
    begin
        exit('315647-ProfilesReferencesCompany-20190814');
    end;

    procedure GetUpdateProfileReferencesForDatabaseTag(): Code[250]
    begin
        exit('315647-ProfileReferencesDatabase-20190814');
    end;

    procedure GetSalesCrMemoShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesCrMemoShipmentMethod-20190606');
    end;

    procedure GetLastUpdateInvoiceEntryNoUpgradeTag(): Code[250]
    begin
        exit('MS-310795-LastUpdateInvoiceEntryNo-20190607');
    end;

    procedure GetAddDeviceISVEmbUpgradeTag(): Code[250]
    begin
        exit('MS-312516-AddDeviceISVEmbPlan-20190601');
    end;

    procedure GetIncomingDocumentURLUpgradeTag(): Code[250]
    begin
        exit('319444-DeprecateURLFieldsIncomingDocs-20190724');
    end;

    procedure GetRemoveExtensionManagementFromPlanUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromPlan-20190821');
    end;

    procedure GetRemoveExtensionManagementFromUsersUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromUsers-20190821');
    end;

    procedure GetAddBackupRestorePermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-317694-AddBackupRestorePermissionset-20190812');
    end;

    procedure GetCashFlowCortanaFieldsUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCashFlowCortanaIntelligenceFields-20190820');
    end;

    procedure GetCortanaIntelligenceUsageUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCortanaIntelligenceUsage-20190820');
    end;

    procedure GetLoadNamedForwardLinksUpgradeTag(): Code[250];
    begin
        exit('MS-328639-LoadNamedForwardLinks-20191003');
    end;
}

