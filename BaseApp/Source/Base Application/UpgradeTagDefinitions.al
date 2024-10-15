﻿codeunit 9998 "Upgrade Tag Definitions"
{
    // Tag Structure - MS-[TFSID]-[Description]-[DateChangeWasDoneToSeeHowOldItWas]
    // Tags must be the same in all branches

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetTimeRegistrationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNotificationEntryMergeErrorMessageFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesInvoiceEntityAggregateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewPurchInvEntityAggregateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesOrderEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesQuoteEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesCrMemoEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesShipmentLineUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCleanupDataExchUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDefaultDimensionAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetBalAccountNoOnJournalAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemCategoryOnItemAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMoveCurrencyISOCodeTag());
        PerCompanyUpgradeTags.Add(GetItemTrackingCodeUseExpirationDatesTag());
        PerCompanyUpgradeTags.Add(GetCountryApplicationAreasTag());
        PerCompanyUpgradeTags.Add(GetVATRepSetupPeriodRemCalcUpgradeTag());
        PerCompanyUpgradeTags.Add(GetGLBankAccountNoTag());
        PerCompanyUpgradeTags.Add(GetServicePasswordToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetAddingIDToJobsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobPlanningLinePlanningDueDateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEncryptedKeyValueToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetGraphMailRefreshCodeToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetStandardSalesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetStandardPurchaseCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesOrderShipmentMethodUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesCrMemoShipmentMethodUpgradeTag());
        PerCompanyUpgradeTags.Add(GetLastUpdateInvoiceEntryNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIncomingDocumentURLUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUpdateProfileReferencesForCompanyTag());
        PerCompanyUpgradeTags.Add(GetCashFlowCortanaFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCortanaIntelligenceUsageUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPriceCalcMethodInSetupTag());
        PerCompanyUpgradeTags.Add(GetPowerBiEmbedUrlTooShortUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSearchEmailUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesInvoiceDimensionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPurchInvoiceDimensionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesOrderDimensionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesQuoteDimensionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesCrMemoDimensionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemVariantItemIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEmailLoggingUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewVendorTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewCustomerTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewItemTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(PurchRcptLineOverReceiptCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationTableMappingUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationFieldMappingForContactsUpgradeTag());
        PerCompanyUpgradeTags.Add(WorkflowStepArgumentUpgradeTag());
        PerCompanyUpgradeTags.Add(GetGenJnlLineArchiveUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMoveAzureADAppSetupSecretToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetDefaultDimensionParentTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDimensionValueDimensionIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetGLAccountAPITypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPostCodeServiceKeyUpgradeTag());
        PerCompanyUpgradeTags.Add(GetFixAPISalesInvoicesCreatedFromOrders());
        PerCompanyUpgradeTags.Add(GetFixAPIPurchaseInvoicesCreatedFromOrders());
        PerCompanyUpgradeTags.Add(GetDeleteSalesOrdersOrphanedRecords());
        PerCompanyUpgradeTags.Add(GetIntrastatJnlLinePartnerIDUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewPurchRcptLineUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDimensionSetEntryUpgradeTag());
        PerCompanyUpgradeTags.Add(GetRemoveOldWorkflowTableRelationshipRecordsTag());
        PerCompanyUpgradeTags.Add(GetUserTaskDescriptionToUTF8UpgradeTag());
        PerCompanyUpgradeTags.Add(GetClearTemporaryTablesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAdvancedIntrastatBaseDemoDataUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetNewISVPlansUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetWorkflowWebhookWebServicesUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetExcelTemplateWebServicesUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAddDeviceISVEmbUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAddBackupRestorePermissionSetUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUpdateProfileReferencesForDatabaseTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromPlanUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromUsersUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetHideBlankProfileUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetCreateDefaultAADApplicationTag());
        PerDatabaseUpgradeTags.Add(GetMonitorSensitiveFieldPermissionUpgradeTag());
    end;
    [Obsolete('Function will be removed in release 18.0', '16.0')]
    procedure GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('291121-JobQueueEntryMergingErrorMessageFields-20190307')
    end;

    procedure GetHideBlankProfileUpgradeTag(): Code[250]
    begin
        exit('322930-HideBlankProfile-20191023')
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNotificationEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('323517-NotificationEntryMergingErrorMessageFields-20190823')
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetTimeRegistrationUpgradeTag(): Code[250]
    begin
        exit('284963-TimeRegistrationAPI-ReadOnly-20181010');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('298839-SalesInvoiceAddingMultipleAddresses-20190213');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('294917-PurchInvoiceAddingMultipleAddresses-20190213');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetPriceCalcMethodInSetupTag(): Code[250]
    begin
        exit('344135-PriceCalcMethodInSetup-20200210');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesOrderAddingMultipleAddresses-20190213');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesQuoteAddingMultipleAddresses-20190213');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesCrMemoAddingMultipleAddresses-20190213');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesInvoiceAddingMultipleAddresses-20190731');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-PurchInvoiceAddingMultipleAddresses-20190731');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesOrderAddingMultipleAddresses-20190731');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesQuoteAddingMultipleAddresses-20190731');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesCrMemoAddingMultipleAddresses-20190731');
    end;

    [Obsolete('Function will be removed', '18.0')]
    procedure GetNewSalesShipmentLineUpgradeTag(): Code[250]
    begin
        exit('MS-383010-SalesShipmentLineDocumentId-20201210');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetNewISVPlansUpgradeTag(): Code[250]
    begin
        exit('MS-287563-NewISVPlansAdded-20181105');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetWorkflowWebhookWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-WorkflowWebhookWebServices-20180907');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetExcelTemplateWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-ExcelTemplateWebServices-20180907');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetCleanupDataExchUpgradeTag(): Code[250]
    begin
        exit('MS-CleanupDataExchUpgrade-20180821');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetDefaultDimensionAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275427-DefaultDimensionAPI-20180719');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetBalAccountNoOnJournalAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275328-BalAccountNoOnJournalAPI-20180823');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetItemCategoryOnItemAPIUpgradeTag(): Code[250]
    begin
        exit('MS-279686-ItemCategoryOnItemAPI-20180903');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetMoveCurrencyISOCodeTag(): Code[250]
    begin
        exit('MS-267101-MoveCurrencyISOCode-20190209');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetItemTrackingCodeUseExpirationDatesTag(): Code[250]
    begin
        exit('MS-296384-GetItemTrackingCodeUseExpirationDates-20190305');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetCountryApplicationAreasTag(): Code[250]
    begin
        exit('MS-GetCountryApplicationAreas-20190315');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetGLBankAccountNoTag(): Code[250]
    begin
        exit('MS-305176-GetGLBankAccountNoTag-20190408');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetVATRepSetupPeriodRemCalcUpgradeTag(): Code[250]
    begin
        exit('MS-306583-VATReportSetup-20190402');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetServicePasswordToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-ServicePassword-20190429');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetAddingIDToJobsUpgradeTag(): Code[250]
    begin
        exit('MS-310839-GETAddingIDToJobs-20190506');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetEncryptedKeyValueToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-EncKeyValue-20190429');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetGraphMailRefreshCodeToIsolatedStorageTag(): Code[250]
    begin
        EXIT('MS-304318-GraphMailRefreshCode-20190429');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetStandardSalesCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardSalesCode-20190517');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetStandardPurchaseCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardPurchaseCode-20190517');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesOrderShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesOrderShipmentMethod-20190606');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetUpdateProfileReferencesForCompanyTag(): Code[250]
    begin
        exit('315647-ProfilesReferencesCompany-20190814');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetUpdateProfileReferencesForDatabaseTag(): Code[250]
    begin
        exit('315647-ProfileReferencesDatabase-20190814');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetSalesCrMemoShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesCrMemoShipmentMethod-20190606');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetLastUpdateInvoiceEntryNoUpgradeTag(): Code[250]
    begin
        exit('MS-310795-LastUpdateInvoiceEntryNo-20190607');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetAddDeviceISVEmbUpgradeTag(): Code[250]
    begin
        exit('MS-312516-AddDeviceISVEmbPlan-20190601');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetIncomingDocumentURLUpgradeTag(): Code[250]
    begin
        exit('319444-DeprecateURLFieldsIncomingDocs-20190724');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetRemoveExtensionManagementFromPlanUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromPlan-20190821');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetRemoveExtensionManagementFromUsersUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromUsers-20190821');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetAddBackupRestorePermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-317694-AddBackupRestorePermissionset-20190812');
    end;

    [Obsolete('Function will be removed', '18.0')]
    procedure GetAddFeatureDataUpdatePernissionsUpgradeTag(): Code[250];
    begin
        exit('MS-375048-AddBackupRestorePermissionset-20201028');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetCashFlowCortanaFieldsUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCashFlowCortanaIntelligenceFields-20190820');
    end;

    [Obsolete('Function will be removed', '16.0')]
    procedure GetCortanaIntelligenceUsageUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCortanaIntelligenceUsage-20190820');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSetReviewRequiredOnBankPmtApplRulesTag(): Code[250]
    begin
        exit('MS-327612-SetReviewRequiredOnBankPmtApplRules-20200204');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetLoadNamedForwardLinksUpgradeTag(): Code[250];
    begin
        exit('MS-328639-LoadNamedForwardLinks-20191003');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetRecordLinkURLUpgradeTag(): Code[250]
    begin
        exit('MS-326679-DeprecateURLFieldsRecordLink-20191022');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetExcelExportActionPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-328760-ExcelExportActionPermissionset-20191022');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetPowerBiEmbedUrlTooShortUpgradeTag(): Code[250];
    begin
        exit('MS-343007-PowerBiEmbedUrlTooShort-20200220');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSearchEmailUpgradeTag(): Code[250];
    begin
        exit('MS-346850-SearchEmail-20200302');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSalesInvoiceDimensionUpgradeTag(): Code[250];
    begin
        exit('MS-348479-SalesInvoiceDimension-20200316');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetPurchInvoiceDimensionUpgradeTag(): Code[250];
    begin
        exit('MS-348479-PurchInvoiceDimension-20200316');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSalesOrderDimensionUpgradeTag(): Code[250];
    begin
        exit('MS-348479-SalesOrderDimension-20200316');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSalesQuoteDimensionUpgradeTag(): Code[250];
    begin
        exit('MS-348479-SalesQuoteDimension-20200316');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSalesCrMemoDimensionUpgradeTag(): Code[250];
    begin
        exit('MS-348479-SalesCrMemoDimension-20200316');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetItemVariantItemIdUpgradeTag(): Code[250];
    begin
        exit('MS-345848-ItemVariantsItemId-20200319');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetSmartListDesignerPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-334180-ExcelExportActionPermissionset-20200317');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetCompanyHubPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-342774-IntroduceCompanyHubPermissionSet-20200707');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetEmailLoggingUpgradeTag(): Code[250];
    begin
        exit('MS-359086-EmailLogging-20200526');
    end;

    procedure GetNewVendorTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewVendorTemplates-20200531');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetNewCustomerTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewCustomerTemplates-20200531');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetNewItemTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewItemTemplates-20200531');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure PurchRcptLineOverReceiptCodeUpgradeTag(): Code[250];
    begin
        exit('MS-360362-PurchRcptLineOverReceiptCode-20200612');
    end;

    [Obsolete('Function will be removed', '18.0')]
    procedure GetNewPurchRcptLineUpgradeTag(): Code[250]
    begin
        exit('MS-383010-PurchRcptLineDocumentId-20201210');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetIntegrationTableMappingUpgradeTag(): Code[250];
    begin
        exit('MS-368854-IntegrationTableMapping-20200818');
    end;

    [Obsolete('Function will be removed', '18.0')]
    procedure GetIntegrationFieldMappingForContactsUpgradeTag(): Code[250];
    begin
        exit('MS-387286-IntegrationFieldMappingForContacts-20210125');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure WorkflowStepArgumentUpgradeTag(): Code[250];
    begin
        exit('MS-355773-WorkflowStepArgumentUpgradeTag-20200617');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetMoveAzureADAppSetupSecretToIsolatedStorageTag(): Code[250];
    begin
        exit('MS-361172-MoveAzureADAppSetupSecretToIsolatedStorageTag-20200716');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetGenJnlLineArchiveUpgradeTag(): Code[250];
    begin
        exit('MS-277244-PostedGenJnlLine-20200716');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetCreateDefaultAADApplicationTag(): Code[250]
    begin
        exit('MS-366236-AADApplication-20200813');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetMonitorSensitiveFieldPermissionUpgradeTag(): Code[250];
    begin
        exit('MS-366164-AddD365MonitorFieldsToSecurityUserGroup-20200811');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetDefaultDimensionParentTypeUpgradeTag(): Code[250];
    begin
        exit('MS-367190-DefaultDimensionParentType-20200816');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetDimensionValueDimensionIdUpgradeTag(): Code[250];
    begin
        exit('MS-367190-DimensionValueDimensionId-20200816');
    end;

    [Obsolete('Function will be removed', '17.0')]
    procedure GetGLAccountAPITypeUpgradeTag(): Code[250];
    begin
        exit('MS-367190-GLAccountAPIType-20200816');
    end;

    procedure GetPostCodeServiceKeyUpgradeTag(): Code[250];
    begin
        exit('MS-369092-PostCodeServiceKey-20200915')
    end;

    [Scope('OnPrem')]
    procedure GetIntrastatJnlLinePartnerIDUpgradeTag(): Code[250]
    begin
        exit('MS-373278-IntrastatJnlLinePartnerID-20201001');
    end;
    
    procedure GetFixAPISalesInvoicesCreatedFromOrders(): Code[250];
    begin
        exit('MS-377282-GetFixAPISalesInvoicesCreatedFromOrders-20201029');
    end;

    procedure GetFixAPIPurchaseInvoicesCreatedFromOrders(): Code[250];
    begin
        exit('MS-377282-GetFixAPIPurchaseInvoicesCreatedFromOrders-20201029');
    end;

    procedure GetDeleteSalesOrdersOrphanedRecords(): Code[250];
    begin
        exit('MS-377433-DeleteSalesOrdersOrphanedRecords-20201102');
    end;

    procedure GetDimensionSetEntryUpgradeTag(): Code[250]
    begin
        exit('MS-352854-ShortcutDimensionsInGLEntry-20201204');
    end;

    procedure GetRemoveOldWorkflowTableRelationshipRecordsTag(): Code[250]
    begin
        exit('MS-384473-RemoveOldWorkflowTableRelationshipRecords-20201222');
    end;

    [Obsolete('Function will be removed', '18.0')]
    procedure GetNewPurchaseOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-385184-PurchaseOrderEntityBuffer-20210104');
    end;

    procedure GetUserTaskDescriptionToUTF8UpgradeTag(): Code[250]
    begin
        exit('MS-385481-UserTaskDescriptionToUTF8-20210112');
    end;

    procedure GetClearTemporaryTablesUpgradeTag(): Code[250]
    begin
        exit('MS-396184-CleanTemporaryTables-20210427');
    end;

    procedure GetAdvancedIntrastatBaseDemoDataUpgradeTag(): Code[250]
    begin
        exit('MS-395476-AdvancedIntrastatChecklistSetup-20210525');
    end;

    procedure GetJobPlanningLinePlanningDueDateUpgradeTag(): Code[250]
    begin
        exit('MS-402915-JobPlanningLinePlanningDueDate-20210809');
    end;
}
