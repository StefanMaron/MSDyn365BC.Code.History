codeunit 104000 "Upgrade - BaseApp"
{
    Subtype = Upgrade;
    Permissions =
        TableData "User Group Plan" = rimd,
        TableData "Cust. Ledger Entry" = rm;

    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        ExcelTemplateIncomeStatementTxt: Label 'ExcelTemplateIncomeStatement', Locked = true;
        ExcelTemplateBalanceSheetTxt: Label 'ExcelTemplateBalanceSheet', Locked = true;
        ExcelTemplateTrialBalanceTxt: Label 'ExcelTemplateTrialBalance', Locked = true;
        ExcelTemplateRetainedEarningsStatementTxt: Label 'ExcelTemplateRetainedEarnings', Locked = true;
        ExcelTemplateCashFlowStatementTxt: Label 'ExcelTemplateCashFlowStatement', Locked = true;
        ExcelTemplateAgedAccountsReceivableTxt: Label 'ExcelTemplateAgedAccountsReceivable', Locked = true;
        ExcelTemplateAgedAccountsPayableTxt: Label 'ExcelTemplateAgedAccountsPayable', Locked = true;
        ExcelTemplateCompanyInformationTxt: Label 'ExcelTemplateViewCompanyInformation', Locked = true;
        FailedToUpdatePowerBIImageTxt: Label 'Failed to update PowerBI optin image for client type %1.', Locked = true;
        AttemptingPowerBIUpdateTxt: Label 'Attempting to update PowerBI optin image for client type %1.', Locked = true;
        SourceCodeGeneralDeferralLbl: Label 'Gen-Defer', Locked = true;
        SourceCodeSalesDeferralLbl: Label 'Sal-Defer', Locked = true;
        SourceCodePurchaseDeferralLbl: Label 'Pur-Defer', Locked = true;
        SourceCodeGeneralDeferralTxt: Label 'General Deferral', Locked = true;
        SourceCodeSalesDeferralTxt: Label 'Sales Deferral', Locked = true;
        SourceCodePurchaseDeferralTxt: Label 'Purchase Deferral', Locked = true;
        ProductionOrderLbl: Label 'PRODUCTION', Locked = true;
        ProductionOrderTxt: Label 'Production Order', Locked = true;

    trigger OnCheckPreconditionsPerDatabase()
    begin
        HybridDeployment.VerifyCanStartUpgrade('');
    end;

    trigger OnCheckPreconditionsPerCompany()
    begin
        HybridDeployment.VerifyCanStartUpgrade(CompanyName());
    end;

    trigger OnUpgradePerDatabase()
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        CreateWorkflowWebhookWebServices();
        CreateExcelTemplateWebServices();
        CopyRecordLinkURLsIntoOneField();
        UpgradeSharePointConnection();
        CreateDefaultAADApplication();
        UpgradePowerBIOptin();
    end;

    trigger OnUpgradePerCompany()
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        ClearTemporaryTables();

        UpdateDefaultDimensionsReferencedIds();
        UpdateGenJournalBatchReferencedIds();
        UpdateJobs();
        UpdateItemTrackingCodes();
        UpgradeJobQueueEntries();
        UpgradeNotificationEntries();
        UpgradeVATReportSetup();
        UpgradeStandardCustomerSalesCodes();
        UpgradeStandardVendorPurchaseCode();
        MoveLastUpdateInvoiceEntryNoValue();
        CopyIncomingDocumentURLsIntoOneFiled();
        UpgradePowerBiEmbedUrl();
        UpgradeSearchEmail();
        UpgradeIntegrationTableMapping();
        UpgradeIntegrationFieldMapping();
        UpgradeWorkflowStepArgumentEventFilters();
        SetReviewRequiredOnBankPmtApplRules();

        UpgradeAPIs();
        UpgradeTemplates();
        AddPowerBIWorkspaces();
        UpgradePurchaseRcptLineOverReceiptCode();
        UpgradeContactMobilePhoneNo();
        UpgradePostCodeServiceKey();
#if not CLEAN22
        UpgradeIntrastatJnlLine();
#endif
        UpgradeDimensionSetEntry();
        UpgradeUserTaskDescriptionToUTF8();
        UpgradeRemoveSmartListGuidedExperience();

        UseCustomLookupInPrices();
        FillItemChargeAssignmentQtyToHandle();
        UpdateWorkflowTableRelations();
        UpgradeWordTemplateTables();
        UpdatePriceSourceGroupInPriceListLines();
        UpdatePriceListLineStatus();
        UpdateAllJobsResourcePrices();
        UpgradeCreditTransferIBAN();
        UpgradeDocumentDefaultLineType();
        UpgradeJobShipToSellToFunctionality();
        UpgradeOnlineMap();
        UpgradeDataExchFieldMapping();
        UpgradeJobReportSelection();
        UpgradeICSetup();
        UpgradeAccountSchedulesToFinancialReports();
        UpgradeCRMUnitGroupMapping();
        UpgradeCRMSDK90ToCRMSDK91();
        UpgradeCRMSDK91ToDataverseSDK();
        UpdatePurchaserOnRequisitionLines();
        SendCloudMigrationUsageTelemetry();
        UpdateCustLedgerEntrySetYourReference();
        UpgradeICPartnerGLAccountNo();
        UpgradeICInboxTransactionAccountNo();
        UpgradeHandledICInboxTransactionAccountNo();
        UpgradeICOutboxTransactionAccountNo();
        UpgradeHandledICOutboxTransactionAccountNo();
        UpdateCheckWhseClassOnLocation();
        UpdateDeferralSourceCode();
        UpgradeMapCurrencySymbol();
        UpgradeOptionMapping();
        UpdateProductionSourceCode();
        UpgradeICGLAccountNoInPostedGenJournalLine();
        UpgradeICGLAccountNoInStandardGeneralJournalLine();
        UpgradeVATSetup();
#if not CLEAN22
        UpgradeTimesheetExperience();
#endif
    end;

    local procedure ClearTemporaryTables()
    var
        BinContentBuffer: Record "Bin Content Buffer";
        DocumentEntry: Record "Document Entry";
        EntrySummary: Record "Entry Summary";
#if not CLEAN20
        InvoicePostBuffer: Record "Invoice Post. Buffer";
#endif
        ItemTrackingSetup: Record "Item Tracking Setup";
        OptionLookupBuffer: Record "Option Lookup Buffer";
        ParallelSessionEntry: Record "Parallel Session Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetClearTemporaryTablesUpgradeTag()) then
            exit;

        BinContentBuffer.Reset();
        BinContentBuffer.DeleteAll();

        DocumentEntry.Reset();
        DocumentEntry.DeleteAll();

        EntrySummary.Reset();
        EntrySummary.DeleteAll();

#if not CLEAN20
        InvoicePostBuffer.Reset();
        InvoicePostBuffer.DeleteAll();
#endif
        ItemTrackingSetup.Reset();
        ItemTrackingSetup.DeleteAll();

        OptionLookupBuffer.Reset();
        OptionLookupBuffer.DeleteAll();

        ParallelSessionEntry.Reset();
        ParallelSessionEntry.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetClearTemporaryTablesUpgradeTag());
    end;

    internal procedure UpgradeWordTemplateTables()
    var
        WordTemplate: Codeunit "Word Template";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultWordTemplateAllowedTablesUpgradeTag()) then
            exit;

        WordTemplate.AddTable(Database::Contact);
        WordTemplate.AddTable(Database::Customer);
        WordTemplate.AddTable(Database::Item);
        WordTemplate.AddTable(Database::Vendor);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultWordTemplateAllowedTablesUpgradeTag());
    end;

    local procedure UpdateWorkflowTableRelations()
    var
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveOldWorkflowTableRelationshipRecordsTag()) then
            exit;

        // SetTag is in the method
        WorkflowWebhookEvents.CleanupOldIntegrationIdsTableRelation();
    end;

    local procedure SetReviewRequiredOnBankPmtApplRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSetReviewRequiredOnBankPmtApplRulesTag()) then
            exit;

        BankPmtApplRule.SetRange("Match Confidence", BankPmtApplRule."Match Confidence"::None);
        BankPmtApplRule.ModifyAll("Review Required", true);
        BankPmtApplRule.SetRange("Match Confidence", BankPmtApplRule."Match Confidence"::Low);
        BankPmtApplRule.ModifyAll("Review Required", true);
        BankPmtApplRule.SetRange("Match Confidence", BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule.ModifyAll("Review Required", true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSetReviewRequiredOnBankPmtApplRulesTag());
    end;

    local procedure UpdateDefaultDimensionsReferencedIds()
    var
        DefaultDimension: Record "Default Dimension";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionAPIUpgradeTag()) THEN
            EXIT;

        IF DefaultDimension.FindSet() then
            REPEAT
                DefaultDimension.UpdateReferencedIds();
            UNTIL DefaultDimension.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionAPIUpgradeTag());
    end;

    local procedure UpdateGenJournalBatchReferencedIds()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBalAccountNoOnJournalAPIUpgradeTag()) THEN
            EXIT;

        IF GenJournalBatch.FindSet() then
            REPEAT
                GenJournalBatch.UpdateBalAccountId();
                IF GenJournalBatch.MODIFY() THEN;
            UNTIL GenJournalBatch.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetBalAccountNoOnJournalAPIUpgradeTag());
    end;

    local procedure UpdateJobs()
    var
        Job: Record "Job";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddingIDToJobsUpgradeTag()) THEN
            EXIT;

        IF Job.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF ISNULLGUID(Job.SystemId) THEN
                    Job.UpdateReferencedIds();
            UNTIL Job.Next() = 0;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddingIDToJobsUpgradeTag());
    end;

    local procedure UpdatePriceSourceGroupInPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PriceListLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupUpgradeTag()) then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag()) then
            exit;

        PriceListLineDataTransfer.SetTables(Database::"Price List Line", Database::"Price List Line");
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Group"), '=%1', "Price Source Group"::All);
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Type"), '%1|%2|%3', "Price Source Type"::"All Jobs", "Price Source Type"::Job, "Price Source Type"::"Job Task");
        PriceListLineDataTransfer.AddConstantValue("Price Source Group"::Job, PriceListLine.FieldNo("Source Group"));
        PriceListLineDataTransfer.UpdateAuditFields := false;
        PriceListLineDataTransfer.CopyFields();
        Clear(PriceListLineDataTransfer);

        PriceListLineDataTransfer.SetTables(Database::"Price List Line", Database::"Price List Line");
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Group"), '=%1', "Price Source Group"::All);
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Type"), '<>%1&<>%2&<>%3', "Price Source Type"::"All Jobs", "Price Source Type"::Job, "Price Source Type"::"Job Task");
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Price Type"), '=%1', "Price Type"::Purchase);
        PriceListLineDataTransfer.AddConstantValue("Price Source Group"::Vendor, PriceListLine.FieldNo("Source Group"));
        PriceListLineDataTransfer.UpdateAuditFields := false;
        PriceListLineDataTransfer.CopyFields();
        Clear(PriceListLineDataTransfer);

        PriceListLineDataTransfer.SetTables(Database::"Price List Line", Database::"Price List Line");
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Group"), '=%1', "Price Source Group"::All);
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Source Type"), '<>%1&<>%2&<>%3', "Price Source Type"::"All Jobs", "Price Source Type"::Job, "Price Source Type"::"Job Task");
        PriceListLineDataTransfer.AddSourceFilter(PriceListLine.FieldNo("Price Type"), '=%1', "Price Type"::Sale);
        PriceListLineDataTransfer.AddConstantValue("Price Source Group"::Customer, PriceListLine.FieldNo("Source Group"));
        PriceListLineDataTransfer.UpdateAuditFields := false;
        PriceListLineDataTransfer.CopyFields();
        Clear(PriceListLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag());
    end;

    local procedure UpdatePriceListLineStatus()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Status: Enum "Price Status";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupUpgradeTag()) then
            exit;
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSyncPriceListLineStatusUpgradeTag()) then
            exit;

        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if EnvironmentInformation.IsSaaS() then
            if PriceListLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        if PriceListLine.Findset(true) then
            repeat
                if PriceListHeader.Code <> PriceListLine."Price List Code" then
                    if PriceListHeader.Get(PriceListLine."Price List Code") then
                        Status := PriceListHeader.Status
                    else
                        Status := Status::Draft;
                if Status = Status::Active then begin
                    PriceListLine.Status := Status::Active;
                    PriceListLine.Modify();
                end;
            until PriceListLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSyncPriceListLineStatusUpgradeTag());
    end;

    local procedure UpdateAllJobsResourcePrices()
    var
        NewPriceListLine: Record "Price List Line";
        PriceListLine: Record "Price List Line";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAllJobsResourcePriceUpgradeTag()) then
            exit;

        PriceListLine.SetRange(Status, "Price Status"::Active);
        PriceListLine.SetRange("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine.SetFilter("Asset Type", '%1|%2', "Price Asset Type"::Resource, "Price Asset Type"::"Resource Group");
        if EnvironmentInformation.IsSaaS() then
            if PriceListLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;
        if PriceListLine.Findset() then
            repeat
                NewPriceListLine := PriceListLine;
                case PriceListLine."Price Type" of
                    "Price Type"::Sale:
                        NewPriceListLine."Source Type" := "Price Source Type"::"All Customers";
                    "Price Type"::Purchase:
                        NewPriceListLine."Source Type" := "Price Source Type"::"All Vendors";
                end;
                InsertPriceListLine(NewPriceListLine);
            until PriceListLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAllJobsResourcePriceUpgradeTag());
    end;

    local procedure InsertPriceListLine(var PriceListLine: Record "Price List Line")
    var
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        PriceListManagement: Codeunit "Price List Management";
    begin
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.InitLineNo(PriceListLine);
        if not PriceListManagement.FindDuplicatePrice(PriceListLine) then
            PriceListLine.Insert(true);
    end;

    local procedure CreateWorkflowWebhookWebServices()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetWorkflowWebhookWebServicesUpgradeTag()) THEN
            EXIT;

        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Entity", 'salesDocuments', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Line Entity", 'salesDocumentLines', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Entity", 'purchaseDocuments', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Line Entity", 'purchaseDocumentLines', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Entity", 'workflowSalesDocuments', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Line Entity", 'workflowSalesDocumentLines', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Entity", 'workflowPurchaseDocuments', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Line Entity", 'workflowPurchaseDocumentLines', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Gen. Journal Batch Entity", 'workflowGenJournalBatches', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Gen. Journal Line Entity", 'workflowGenJournalLines', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Customer Entity", 'workflowCustomers', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Item Entity", 'workflowItems', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Vendor Entity", 'workflowVendors', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow Webhook Subscriptions", 'workflowWebhookSubscriptions', TRUE);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Codeunit, CODEUNIT::"Workflow Webhook Subscription", 'WorkflowActionResponse', TRUE);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetWorkflowWebhookWebServicesUpgradeTag());
    end;

    local procedure CreateExcelTemplateWebServices()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetExcelTemplateWebServicesUpgradeTag()) THEN
            EXIT;

        CreateExcelTemplateWebService(ExcelTemplateIncomeStatementTxt, PAGE::"Income Statement Entity");
        CreateExcelTemplateWebService(ExcelTemplateBalanceSheetTxt, PAGE::"Balance Sheet Entity");
        CreateExcelTemplateWebService(ExcelTemplateTrialBalanceTxt, PAGE::"Trial Balance Entity");
        CreateExcelTemplateWebService(ExcelTemplateRetainedEarningsStatementTxt, PAGE::"Retained Earnings Entity");
        CreateExcelTemplateWebService(ExcelTemplateCashFlowStatementTxt, PAGE::"Cash Flow Statement Entity");
        CreateExcelTemplateWebService(ExcelTemplateAgedAccountsReceivableTxt, PAGE::"Aged AR Entity");
        CreateExcelTemplateWebService(ExcelTemplateAgedAccountsPayableTxt, PAGE::"Aged AP Entity");
        CreateExcelTemplateWebService(ExcelTemplateCompanyInformationTxt, PAGE::ExcelTemplateCompanyInfo);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetExcelTemplateWebServicesUpgradeTag());
    end;

    local procedure MoveLastUpdateInvoiceEntryNoValue()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchStatus: Record "CRM Synch Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLastUpdateInvoiceEntryNoUpgradeTag()) THEN
            EXIT;

        IF CRMConnectionSetup.Get() then
            CRMSynchStatus."Last Update Invoice Entry No." := CRMConnectionSetup."Last Update Invoice Entry No."
        ELSE
            CRMSynchStatus."Last Update Invoice Entry No." := 0;

        IF CRMSynchStatus.Insert() then;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLastUpdateInvoiceEntryNoUpgradeTag());
    end;

    local procedure CopyIncomingDocumentURLsIntoOneFiled()
    var
        IncomingDocument: Record "Incoming Document";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIncomingDocumentURLUpgradeTag()) THEN
            EXIT;

        IF IncomingDocument.FindSet() then
            REPEAT
                IncomingDocument.URL := IncomingDocument.URL1 + IncomingDocument.URL2 + IncomingDocument.URL3 + IncomingDocument.URL4;
                IncomingDocument.Modify();
            UNTIL IncomingDocument.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIncomingDocumentURLUpgradeTag());
    end;

    local procedure CopyRecordLinkURLsIntoOneField()
    var
        RecordLink: Record "Record Link";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRecordLinkURLUpgradeTag()) then
            exit;

        RecordLink.SetFilter("URL2", '<>''''');

        if RecordLink.FindSet() then
            repeat
                RecordLink.URL1 := RecordLink.URL1 + RecordLink.URL2 + RecordLink.URL3 + RecordLink.URL4;
                RecordLink.Modify();
            until RecordLink.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRecordLinkURLUpgradeTag());
    end;

    local procedure CreateExcelTemplateWebService(ObjectName: Text; PageID: Integer)
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        CLEAR(TenantWebService);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, PageID, ObjectName, TRUE);
    end;

    local procedure UpgradeAPIs()
    begin
        UpgradeSalesInvoiceEntityAggregate();
        UpgradePurchInvEntityAggregate();
        UpgradeSalesOrderEntityBuffer();
        UpgradeSalesQuoteEntityBuffer();
        UpgradeSalesCrMemoEntityBuffer();
        UpgradeSalesOrderShipmentMethod();
        UpgradeSalesCrMemoShipmentMethod();

        UpgradeSalesShipmentLineDocumentId();
        UpdateItemVariants();
        UpgradeDefaultDimensions();
        UpgradeDimensionValues();
        UpgradeGLAccountAPIType();
        UpgradeInvoicesCreatedFromOrders();
        UpgradePurchRcptLineDocumentId();
        UpgradePurchaseOrderEntityBuffer();
        UpgradeSalesCreditMemoReasonCode();
        UpgradeSalesOrderShortcutDimension();
        UpgradeSalesQuoteShortcutDimension();
        UpgradeSalesInvoiceShortcutDimension();
        UpgradeSalesCrMemoShortcutDimension();
        UpgradePurchaseOrderShortcutDimension();
        UpgradePurchInvoiceShortcutDimension();
        UpgradeItemPostingGroups();
    end;

    procedure UpgradeItemPostingGroups()
    var
        Item: Record "Item";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        BlankGuid: Guid;
        GenProdPostingGroupDataTransfer: DataTransfer;
        InventoryPostingGroupDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemPostingGroupsUpgradeTag()) then
            exit;

        // Scenario - Set a default value to a new field
        Item.SetFilter("Gen. Prod. Posting Group Id", '<>%1', BlankGuid);
        if Item.IsEmpty() then begin
            GenProdPostingGroupDataTransfer.SetTables(Database::"Gen. Product Posting Group", Database::Item);
            GenProdPostingGroupDataTransfer.AddFieldValue(GenProdPostingGroup.FieldNo("SystemId"), Item.FieldNo("Gen. Prod. Posting Group Id"));
            GenProdPostingGroupDataTransfer.AddJoin(GenProdPostingGroup.FieldNo(Code), Item.FieldNo("Gen. Prod. Posting Group"));
            GenProdPostingGroupDataTransfer.UpdateAuditFields := false;
            GenProdPostingGroupDataTransfer.CopyFields();
        end;

        Item.SetFilter("Inventory Posting Group Id", '<>%1', BlankGuid);
        if Item.IsEmpty() then begin
            InventoryPostingGroupDataTransfer.SetTables(Database::"Inventory Posting Group", Database::Item);
            InventoryPostingGroupDataTransfer.AddFieldValue(InventoryPostingGroup.FieldNo("SystemId"), Item.FieldNo("Inventory Posting Group Id"));
            InventoryPostingGroupDataTransfer.AddJoin(InventoryPostingGroup.FieldNo(Code), Item.FieldNo("Inventory Posting Group"));
            InventoryPostingGroupDataTransfer.UpdateAuditFields := false;
            InventoryPostingGroupDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemPostingGroupsUpgradeTag());
    end;

    local procedure UpgradeSalesShipmentLineDocumentId()
    var
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        APIDataUpgrade: Codeunit "API Data Upgrade";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesShipmentLineUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesShipmentLineDocumentId(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesShipmentLineUpgradeTag());
    end;

    local procedure UpgradeSalesInvoiceEntityAggregate()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesInvoiceEntityAggregateUpgradeTag()) THEN
            EXIT;

        IF SalesInvoiceEntityAggregate.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF SalesInvoiceEntityAggregate.Posted THEN BEGIN
                    SalesInvoiceHeader.SETRANGE(SystemId, SalesInvoiceEntityAggregate.Id);
                    IF SalesInvoiceHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesInvoiceHeader);
                        TargetRecordRef.GETTABLE(SalesInvoiceEntityAggregate);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, TRUE);
                    END;
                END ELSE BEGIN
                    SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SETRANGE(SystemId, SalesInvoiceEntityAggregate.Id);
                    IF SalesHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesInvoiceEntityAggregate);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, TRUE);
                    END;
                END;
            UNTIL SalesInvoiceEntityAggregate.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesInvoiceEntityAggregateUpgradeTag());
    end;

    local procedure UpgradeInvoicesCreatedFromOrders()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalesOrderBuffer: Codeunit "Graph Mgt - Sales Order Buffer";
        GraphMgtPurchOrderBuffer: Codeunit "Graph Mgt - Purch Order Buffer";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not (UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFixAPISalesInvoicesCreatedFromOrders())) then
            SalesInvoiceAggregator.FixInvoicesCreatedFromOrders();

        if not (UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFixAPIPurchaseInvoicesCreatedFromOrders())) then
            PurchInvAggregator.FixInvoicesCreatedFromOrders();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDeleteSalesOrdersOrphanedRecords()) then
            GraphMgtSalesOrderBuffer.DeleteOrphanedRecords();

        if not UpgradeTag.HasUpgradeTag((UpgradeTagDefinitions.GetDeletePurchaseOrdersOrphanedRecords())) then
            GraphMgtPurchOrderBuffer.DeleteOrphanedRecords();
    end;

    local procedure UpgradePurchInvEntityAggregate()
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchInvEntityAggregateUpgradeTag()) THEN
            EXIT;

        IF PurchInvEntityAggregate.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF PurchInvEntityAggregate.Posted THEN BEGIN
                    PurchInvHeader.SETRANGE(SystemId, PurchInvEntityAggregate.Id);
                    IF PurchInvHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(PurchInvHeader);
                        TargetRecordRef.GETTABLE(PurchInvEntityAggregate);
                        UpdatePurchaseDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE);
                    END;
                END ELSE BEGIN
                    PurchaseHeader.SETRANGE("Document Type", PurchaseHeader."Document Type"::Invoice);
                    PurchaseHeader.SETRANGE(SystemId, PurchInvEntityAggregate.Id);
                    IF PurchaseHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(PurchaseHeader);
                        TargetRecordRef.GETTABLE(PurchInvEntityAggregate);
                        UpdatePurchaseDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE);
                    END;
                END;
            UNTIL PurchInvEntityAggregate.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchInvEntityAggregateUpgradeTag());
    end;

    local procedure UpgradeSalesOrderEntityBuffer()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesOrderEntityBufferUpgradeTag()) THEN
            EXIT;

        IF SalesOrderEntityBuffer.FINDSET(TRUE, FALSE) THEN
            REPEAT
                SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SETRANGE(SystemId, SalesOrderEntityBuffer.Id);
                IF SalesHeader.FindFirst() then BEGIN
                    SourceRecordRef.GETTABLE(SalesHeader);
                    TargetRecordRef.GETTABLE(SalesOrderEntityBuffer);
                    UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, TRUE);
                END;
            UNTIL SalesOrderEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesOrderEntityBufferUpgradeTag());
    end;

    local procedure UpgradeSalesQuoteEntityBuffer()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesQuoteEntityBufferUpgradeTag()) THEN
            EXIT;

        IF SalesQuoteEntityBuffer.FINDSET(TRUE, FALSE) THEN
            REPEAT
                SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SETRANGE(SystemId, SalesQuoteEntityBuffer.Id);
                IF SalesHeader.FindFirst() then BEGIN
                    SourceRecordRef.GETTABLE(SalesHeader);
                    TargetRecordRef.GETTABLE(SalesQuoteEntityBuffer);
                    UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, TRUE);
                END;
            UNTIL SalesQuoteEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesQuoteEntityBufferUpgradeTag());
    end;

    local procedure UpgradeSalesCrMemoEntityBuffer()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesCrMemoEntityBufferUpgradeTag()) THEN
            EXIT;

        IF SalesCrMemoEntityBuffer.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF SalesCrMemoEntityBuffer.Posted THEN BEGIN
                    SalesCrMemoHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesCrMemoHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesCrMemoHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, FALSE);
                    END;
                END ELSE BEGIN
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, FALSE);
                    END;
                END;
            UNTIL SalesCrMemoEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesCrMemoEntityBufferUpgradeTag());
    end;

    local procedure UpdateSalesDocumentFields(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef; SellTo: Boolean; BillTo: Boolean; ShipTo: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        Customer: Record "Customer";
        CodeFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        EmptyGuid: Guid;
        OldId: Guid;
        NewId: Guid;
        Changed: Boolean;
    begin
        IF SellTo THEN BEGIN
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Sell-to Phone No.")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Sell-to E-Mail")) then
                Changed := true;
        END;
        IF BillTo THEN BEGIN
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Customer No.")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Name")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Address")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Address 2")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to City")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Contact")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Post Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to County")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Bill-to Country/Region Code")) then
                Changed := true;
            CodeFieldRef := TargetRecordRef.FIELD(SalesOrderEntityBuffer.FIELDNO("Bill-to Customer No."));
            IdFieldRef := TargetRecordRef.FIELD(SalesOrderEntityBuffer.FIELDNO("Bill-to Customer Id"));
            OldId := IdFieldRef.Value;
            IF Customer.GET(CodeFieldRef.VALUE) THEN
                NewId := Customer.SystemId
            ELSE
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
        END;
        IF ShipTo THEN BEGIN
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Name")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Address")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Address 2")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to City")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Contact")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Post Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to County")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Ship-to Country/Region Code")) then
                Changed := true;
        END;
        if Changed then
            TargetRecordRef.Modify();
    end;

    local procedure UpdatePurchaseDocumentFields(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef; PayTo: Boolean; ShipTo: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        Vendor: Record "Vendor";
        Currency: Record "Currency";
        CodeFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        EmptyGuid: Guid;
        OldId: Guid;
        NewId: Guid;
        Changed: Boolean;
    begin
        IF PayTo THEN BEGIN
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Vendor No.")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Name")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Address")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Address 2")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to City")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Contact")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Post Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to County")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Pay-to Country/Region Code")) then
                Changed := true;
            CodeFieldRef := TargetRecordRef.FIELD(PurchInvEntityAggregate.FIELDNO("Pay-to Vendor No."));
            IdFieldRef := TargetRecordRef.FIELD(PurchInvEntityAggregate.FIELDNO("Pay-to Vendor Id"));
            OldId := IdFieldRef.Value;
            IF Vendor.GET(CodeFieldRef.VALUE) THEN
                NewId := Vendor.SystemId
            ELSE
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
            CodeFieldRef := TargetRecordRef.FIELD(PurchInvEntityAggregate.FIELDNO("Currency Code"));
            IdFieldRef := TargetRecordRef.FIELD(PurchInvEntityAggregate.FIELDNO("Currency Id"));
            OldId := IdFieldRef.Value;
            IF Currency.GET(CodeFieldRef.VALUE) THEN
                NewId := Currency.SystemId
            ELSE
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
        END;
        IF ShipTo THEN BEGIN
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Name")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Address")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Address 2")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to City")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Contact")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Post Code")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to County")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, PurchaseHeader.FIELDNO("Ship-to Country/Region Code")) then
                Changed := true;
        END;
        if Changed then
            TargetRecordRef.Modify();
    end;

    local procedure CopyFieldValue(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef; FieldNo: Integer): Boolean
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := SourceRecordRef.FIELD(FieldNo);
        TargetFieldRef := TargetRecordRef.FIELD(FieldNo);
        IF TargetFieldRef.VALUE <> SourceFieldRef.VALUE THEN BEGIN
            TargetFieldRef.VALUE := SourceFieldRef.VALUE;
            exit(true);
        END;
        exit(false);
    end;

    local procedure UpdateItemTrackingCodes()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemTrackingCodeUseExpirationDatesTag()) THEN
            EXIT;

        ItemTrackingCode.SETRANGE("Use Expiration Dates", FALSE);
        IF NOT ItemTrackingCode.ISEMPTY THEN
            // until now, expiration date was always ON, so let's reflect this
            ItemTrackingCode.MODIFYALL("Use Expiration Dates", TRUE);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemTrackingCodeUseExpirationDatesTag());
    end;

    local procedure UpgradeDataExchFieldMapping()
    var
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDataExchOCRVendorNoTag()) then
            exit;

        UpgradeDataExchVendorIdFieldMapping('OCRINVOICE', 'OCRINVHEADER', 18);
        UpgradeDataExchVendorIdFieldMapping('OCRCREDITMEMO', 'OCRCRMEMOHEADER', 18);
        UpgradeDataExchVendorNoFieldMapping('OCRINVOICE', 'OCRINVHEADER', 19);
        UpgradeDataExchVendorNoFieldMapping('OCRCREDITMEMO', 'OCRCRMEMOHEADER', 19);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDataExchOCRVendorNoTag());
    end;

    local procedure UpgradeDataExchVendorIdFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempVendor: Record Vendor temporary;
    begin
        if not DataExchDef.Get(DataExchDefCode) then
            exit;

        UpgradeDataExchColumnDef(DataExchColumnDef, DataExchDefCode, DataExchLineDefCode, ColumnNo, 'Supplier ID', 'Buy-from Vendor ID', '/Document/Parties/Party[Type[text()=''supplier'']]/ExternalId');
        UpgradeDataExchFieldMapping(DataExchColumnDef, Database::Vendor, TempVendor.FieldNo(SystemId));
    end;

    local procedure UpgradeDataExchVendorNoFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempVendor: Record Vendor temporary;
    begin
        if not DataExchDef.Get(DataExchDefCode) then
            exit;

        UpgradeDataExchColumnDef(DataExchColumnDef, DataExchDefCode, DataExchLineDefCode, ColumnNo, 'Supplier No.', 'Buy-from Vendor No.', '/Document/Parties/Party[Type[text()=''supplier'']]/ExternalId');
        UpgradeDataExchFieldMapping(DataExchColumnDef, Database::Vendor, TempVendor.FieldNo("No."));
    end;

    local procedure UpgradeDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; Name: Text[250]; Description: Text[100]; Path: Text[250])
    begin
        if not DataExchColumnDef.Get(DataExchDefCode, DataExchLineDefCode, ColumnNo) then begin
            DataExchColumnDef."Data Exch. Def Code" := DataExchDefCode;
            DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDefCode;
            DataExchColumnDef."Column No." := ColumnNo;
            DataExchColumnDef.Name := Name;
            DataExchColumnDef.Description := Description;
            DataExchColumnDef.Path := Path;
            DataExchColumnDef."Data Type" := DataExchColumnDef."Data Type"::Text;
            DataExchColumnDef.Insert();
        end;
    end;

    local procedure UpgradeDataExchFieldMapping(var DataExchColumnDef: Record "Data Exch. Column Def"; TargetTableId: Integer; TargetFieldId: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Changed: Boolean;
    begin
        if not DataExchFieldMapping.Get(DataExchColumnDef."Data Exch. Def Code", DataExchColumnDef."Data Exch. Line Def Code", Database::"Intermediate Data Import", DataExchColumnDef."Column No.", 0) then begin
            DataExchFieldMapping."Data Exch. Def Code" := DataExchColumnDef."Data Exch. Def Code";
            DataExchFieldMapping."Data Exch. Line Def Code" := DataExchColumnDef."Data Exch. Line Def Code";
            DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";
            DataExchFieldMapping."Table ID" := Database::"Intermediate Data Import";
            DataExchFieldMapping."Field ID" := 0;
            DataExchFieldMapping."Target Table ID" := TargetTableId;
            DataExchFieldMapping."Target Field ID" := TargetFieldId;
            DataExchFieldMapping.Optional := true;
            DataExchFieldMapping.Insert();
        end else begin
            if DataExchFieldMapping."Target Table ID" <> TargetTableId then begin
                DataExchFieldMapping."Target Table ID" := TargetTableId;
                Changed := true;
            end;
            if DataExchFieldMapping."Target Field ID" <> TargetFieldId then begin
                DataExchFieldMapping."Target Field ID" := TargetFieldId;
                Changed := true;
            end;
            if Changed then
                DataExchFieldMapping.Modify();
        end;
    end;

    local procedure UpgradeJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        OldErrorMsg: Text;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag()) THEN
            EXIT;

        JobQueueEntry.SETFILTER("Error Message 2", '<>%1', '');
        IF JobQueueEntry.FINDSET(TRUE) THEN
            REPEAT
                JobQueueEntry."Error Message" := JobQueueEntry."Error Message" + JobQueueEntry."Error Message 2" +
                    JobQueueEntry."Error Message 3" + JobQueueEntry."Error Message 4";
                JobQueueEntry."Error Message 2" := '';
                JobQueueEntry."Error Message 3" := '';
                JobQueueEntry."Error Message 4" := '';
                JobQueueEntry.Modify();
            UNTIL JobQueueEntry.Next() = 0;

        JobQueueLogEntry.SETFILTER("Error Message 2", '<>%1', '');
        IF JobQueueLogEntry.FINDSET(TRUE) THEN
            REPEAT
                OldErrorMsg := JobQueueLogEntry."Error Message" + JobQueueLogEntry."Error Message 2" +
                  JobQueueLogEntry."Error Message 3" + JobQueueLogEntry."Error Message 4";
                JobQueueLogEntry."Error Message 2" := '';
                JobQueueLogEntry."Error Message 3" := '';
                JobQueueLogEntry."Error Message 4" := '';
                JobQueueLogEntry.Modify();
            UNTIL JobQueueLogEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag());
    end;

    local procedure UpgradeNotificationEntries()
    var
        NotificationEntry: Record "Notification Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNotificationEntryMergeErrorMessageFieldsUpgradeTag()) then
            exit;

        if NotificationEntry.FindSet(true) then
            repeat
                NotificationEntry."Error Message" :=
                    CopyStr(
                        NotificationEntry."Error Message" +
                        NotificationEntry."Error Message 2" +
                        NotificationEntry."Error Message 3" +
                        NotificationEntry."Error Message 4",
                        1, MaxStrLen(NotificationEntry."Error Message"));

                NotificationEntry.Modify();
            until NotificationEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNotificationEntryMergeErrorMessageFieldsUpgradeTag());
    end;

    local procedure UpgradeVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        DateFormulaText: Text;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATRepSetupPeriodRemCalcUpgradeTag()) THEN
            EXIT;

        WITH VATReportSetup DO BEGIN
            IF NOT GET() THEN
                EXIT;
            IF IsPeriodReminderCalculation() OR ("Period Reminder Time" = 0) THEN
                EXIT;

            DateFormulaText := STRSUBSTNO('<%1D>', "Period Reminder Time");
            EVALUATE("Period Reminder Calculation", DateFormulaText);
            "Period Reminder Time" := 0;

            if Modify() then;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATRepSetupPeriodRemCalcUpgradeTag());
    end;

    local procedure UpgradeStandardCustomerSalesCodes()
    var
        StandardSalesCode: Record "Standard Sales Code";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetStandardSalesCodeUpgradeTag()) THEN
            EXIT;

        IF StandardSalesCode.FindSet() then
            REPEAT
                StandardCustomerSalesCode.SETRANGE(Code, StandardSalesCode.Code);
                StandardCustomerSalesCode.SetFilter("Currency Code", '<>%1', StandardSalesCode."Currency Code");
                StandardCustomerSalesCode.MODIFYALL("Currency Code", StandardSalesCode."Currency Code");
            UNTIL StandardSalesCode.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetStandardSalesCodeUpgradeTag());
    end;

    local procedure UpgradeStandardVendorPurchaseCode()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetStandardPurchaseCodeUpgradeTag()) THEN
            EXIT;

        IF StandardPurchaseCode.FindSet() then
            REPEAT
                StandardVendorPurchaseCode.SETRANGE(Code, StandardPurchaseCode.Code);
                StandardVendorPurchaseCode.SetFilter("Currency Code", '<>%1', StandardPurchaseCode."Currency Code");
                StandardVendorPurchaseCode.MODIFYALL("Currency Code", StandardPurchaseCode."Currency Code");
            UNTIL StandardPurchaseCode.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetStandardPurchaseCodeUpgradeTag());
    end;

    local procedure AddPowerBIWorkspaces()
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        EmptyGuid: Guid;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPowerBIWorkspacesUpgradeTag()) then
            exit;

        PowerBIReportConfiguration.SetRange("Workspace Name", '');
        PowerBIReportConfiguration.SetRange("Workspace ID", EmptyGuid);

        if PowerBIReportConfiguration.FindSet() then
            PowerBIReportConfiguration.ModifyAll("Workspace Name", PowerBIWorkspaceMgt.GetMyWorkspaceLabel());

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPowerBIWorkspacesUpgradeTag());
    end;

    local procedure UpgradePowerBiEmbedUrl()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
#if not CLEAN21
        PowerBIReportBuffer: Record "Power BI Report Buffer";
#endif
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPowerBiEmbedUrlTooShortUpgradeTag()) then
            exit;

        if PowerBIReportUploads.FindSet(true, false) then
            repeat
                if PowerBIReportUploads."Report Embed Url" = '' then begin
                    PowerBIReportUploads."Report Embed Url" := PowerBIReportUploads."Embed Url";
                    PowerBIReportUploads.Modify();
                end;
            until PowerBIReportUploads.Next() = 0;

        if PowerBIReportConfiguration.FindSet(true, false) then
            repeat
                if PowerBIReportConfiguration.ReportEmbedUrl = '' then begin
                    PowerBIReportConfiguration.ReportEmbedUrl := PowerBIReportConfiguration.EmbedUrl;
                    PowerBIReportConfiguration.Modify();
                end;
            until PowerBIReportConfiguration.Next() = 0;

#if not CLEAN21
        if PowerBIReportBuffer.FindSet(true, false) then
            repeat
                if PowerBIReportBuffer.ReportEmbedUrl = '' then begin
                    PowerBIReportBuffer.ReportEmbedUrl := PowerBIReportBuffer.EmbedUrl;
                    PowerBIReportBuffer.Modify();
                end;
            until PowerBIReportBuffer.Next() = 0;
#endif

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPowerBiEmbedUrlTooShortUpgradeTag());
    end;

    local procedure UpgradeSearchEmail()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSearchEmailUpgradeTag()) then
            exit;

        SalespersonPurchaser.SetCurrentKey("Search E-Mail");
        SalespersonPurchaser.SetRange("Search E-Mail", '');
        if SalespersonPurchaser.FindSet(true, false) then
            repeat
                if SalespersonPurchaser."E-Mail" <> '' then begin
                    SalespersonPurchaser."Search E-Mail" := SalespersonPurchaser."E-Mail";
                    SalespersonPurchaser.Modify();
                end;
            until SalespersonPurchaser.Next() = 0;

        Contact.SetCurrentKey("Search E-Mail");
        Contact.SetRange("Search E-Mail", '');
        if Contact.FindSet(true, false) then
            repeat
                if Contact."E-Mail" <> '' then begin
                    Contact."Search E-Mail" := Contact."E-Mail";
                    Contact.Modify();
                end;
            until Contact.Next() = 0;

        ContactAltAddress.SetCurrentKey("Search E-Mail");
        ContactAltAddress.SetRange("Search E-Mail", '');
        if ContactAltAddress.FindSet(true, false) then
            repeat
                if ContactAltAddress."E-Mail" <> '' then begin
                    ContactAltAddress."Search E-Mail" := ContactAltAddress."E-Mail";
                    ContactAltAddress.Modify();
                end;
            until ContactAltAddress.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSearchEmailUpgradeTag());
    end;

    local procedure UpdateItemVariants()
    var
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        ItemVariantDataTransfer: DataTransfer;
        BlankGuid: Guid;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemVariantItemIdUpgradeTag()) then
            exit;

        ItemVariant.SetFilter("Item Id", '%1', BlankGuid);
        if not ItemVariant.IsEmpty() then begin
            ItemVariantDataTransfer.SetTables(Database::Item, Database::"Item Variant");
            ItemVariantDataTransfer.AddFieldValue(Item.FieldNo(SystemId), ItemVariant.FieldNo("Item Id"));
            ItemVariantDataTransfer.AddJoin(Item.FieldNo("No."), ItemVariant.FieldNo("Item No."));
            ItemVariantDataTransfer.UpdateAuditFields := false;
            ItemVariantDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemVariantItemIdUpgradeTag());
    end;

    local procedure UpgradeDefaultDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        DefaultDimensionDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionParentTypeUpgradeTag()) then
            exit;

        DefaultDimension.SetRange("Table ID", Database::Item);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::"Default Dimension", Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddSourceFilter(DefaultDimension.FieldNo("Table ID"), '=%1', Database::Item);
            DefaultDimensionDataTransfer.AddConstantValue("Default Dimension Parent Type"::Item, DefaultDimension.FieldNo("Parent Type"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
            Clear(DefaultDimensionDataTransfer);
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetRange("Table ID", Database::Customer);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::"Default Dimension", Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddSourceFilter(DefaultDimension.FieldNo("Table ID"), '=%1', Database::Customer);
            DefaultDimensionDataTransfer.AddConstantValue("Default Dimension Parent Type"::Customer, DefaultDimension.FieldNo("Parent Type"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
            Clear(DefaultDimensionDataTransfer);
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetRange("Table ID", Database::Vendor);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::"Default Dimension", Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddSourceFilter(DefaultDimension.FieldNo("Table ID"), '=%1', Database::Vendor);
            DefaultDimensionDataTransfer.AddConstantValue("Default Dimension Parent Type"::Vendor, DefaultDimension.FieldNo("Parent Type"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
            Clear(DefaultDimensionDataTransfer);
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetRange("Table ID", Database::Employee);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::"Default Dimension", Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddSourceFilter(DefaultDimension.FieldNo("Table ID"), '=%1', Database::Employee);
            DefaultDimensionDataTransfer.AddConstantValue("Default Dimension Parent Type"::Employee, DefaultDimension.FieldNo("Parent Type"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionParentTypeUpgradeTag());
    end;

    local procedure UpgradeDimensionValues()
    var
        Dimension: Record "Dimension";
        DimensionValue: Record "Dimension Value";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        BlankGuid: Guid;
        DimensionValueDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimensionValueDimensionIdUpgradeTag()) then
            exit;

        DimensionValue.SetFilter("Dimension Id", '<>%1', BlankGuid);
        if DimensionValue.IsEmpty() then begin
            DimensionValueDataTransfer.SetTables(Database::"Dimension", Database::"Dimension Value");
            DimensionValueDataTransfer.AddFieldValue(Dimension.FieldNo(SystemId), DimensionValue.FieldNo("Dimension Id"));
            DimensionValueDataTransfer.AddJoin(Dimension.FieldNo(Code), DimensionValue.FieldNo("Dimension Code"));
            DimensionValueDataTransfer.UpdateAuditFields := false;
            DimensionValueDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDimensionValueDimensionIdUpgradeTag());
    end;

    local procedure UpgradeGLAccountAPIType()
    var
        GLAccount: Record "G/L Account";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        GLAccountDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGLAccountAPITypeUpgradeTag()) then
            exit;

        GLAccountDataTransfer.SetTables(Database::"G/L Account", Database::"G/L Account");
        GLAccountDataTransfer.AddSourceFilter(GLAccount.FieldNo("Account Type"), '=%1', GLAccount."Account Type"::Posting);
        GLAccountDataTransfer.AddConstantValue(GLAccount."API Account Type"::Posting, GLAccount.FieldNo("API Account Type"));
        GLAccountDataTransfer.UpdateAuditFields := false;
        GLAccountDataTransfer.CopyFields();
        Clear(GLAccountDataTransfer);

        GLAccountDataTransfer.SetTables(Database::"G/L Account", Database::"G/L Account");
        GLAccountDataTransfer.AddSourceFilter(GLAccount.FieldNo("Account Type"), '=%1', GLAccount."Account Type"::Heading);
        GLAccountDataTransfer.AddConstantValue(GLAccount."API Account Type"::Heading, GLAccount.FieldNo("API Account Type"));
        GLAccountDataTransfer.UpdateAuditFields := false;
        GLAccountDataTransfer.CopyFields();
        Clear(GLAccountDataTransfer);

        GLAccountDataTransfer.SetTables(Database::"G/L Account", Database::"G/L Account");
        GLAccountDataTransfer.AddSourceFilter(GLAccount.FieldNo("Account Type"), '=%1', GLAccount."Account Type"::Total);
        GLAccountDataTransfer.AddConstantValue(GLAccount."API Account Type"::Total, GLAccount.FieldNo("API Account Type"));
        GLAccountDataTransfer.UpdateAuditFields := false;
        GLAccountDataTransfer.CopyFields();
        Clear(GLAccountDataTransfer);

        GLAccountDataTransfer.SetTables(Database::"G/L Account", Database::"G/L Account");
        GLAccountDataTransfer.AddSourceFilter(GLAccount.FieldNo("Account Type"), '=%1', GLAccount."Account Type"::"Begin-Total");
        GLAccountDataTransfer.AddConstantValue(GLAccount."API Account Type"::"Begin-Total", GLAccount.FieldNo("API Account Type"));
        GLAccountDataTransfer.UpdateAuditFields := false;
        GLAccountDataTransfer.CopyFields();
        Clear(GLAccountDataTransfer);

        GLAccountDataTransfer.SetTables(Database::"G/L Account", Database::"G/L Account");
        GLAccountDataTransfer.AddSourceFilter(GLAccount.FieldNo("Account Type"), '=%1', GLAccount."Account Type"::"End-Total");
        GLAccountDataTransfer.AddConstantValue(GLAccount."API Account Type"::"End-Total", GLAccount.FieldNo("API Account Type"));
        GLAccountDataTransfer.UpdateAuditFields := false;
        GLAccountDataTransfer.CopyFields();
        Clear(GLAccountDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLAccountAPITypeUpgradeTag());
    end;

    local procedure UpgradeSalesOrderShipmentMethod()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShipmentMethodUpgradeTag()) THEN
            EXIT;

        IF SalesOrderEntityBuffer.FINDSET(TRUE, FALSE) THEN
            REPEAT
                SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SETRANGE(SystemId, SalesOrderEntityBuffer.Id);
                IF SalesHeader.FindFirst() then BEGIN
                    SourceRecordRef.GETTABLE(SalesHeader);
                    TargetRecordRef.GETTABLE(SalesOrderEntityBuffer);
                    UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                END;
            UNTIL SalesOrderEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShipmentMethodUpgradeTag());
    end;

    local procedure UpgradeSalesCrMemoShipmentMethod()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShipmentMethodUpgradeTag()) THEN
            EXIT;

        IF SalesCrMemoEntityBuffer.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF SalesCrMemoEntityBuffer.Posted THEN BEGIN
                    SalesCrMemoHeader.SETRANGE(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesCrMemoHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesCrMemoHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                    END;
                END ELSE BEGIN
                    SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SETRANGE(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesHeader.FindFirst() then BEGIN
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                    END;
                END;
            UNTIL SalesCrMemoEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShipmentMethodUpgradeTag());
    end;

    local procedure UpdateSalesDocumentShipmentMethodFields(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        ShipmentMethod: Record "Shipment Method";
        CodeFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        EmptyGuid: Guid;
        OldId: Guid;
        NewId: Guid;
        Changed: Boolean;
    begin
        if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Shipment Method Code")) then
            Changed := true;
        CodeFieldRef := TargetRecordRef.FIELD(SalesOrderEntityBuffer.FIELDNO("Shipment Method Code"));
        IdFieldRef := TargetRecordRef.FIELD(SalesOrderEntityBuffer.FIELDNO("Shipment Method Id"));
        OldId := IdFieldRef.Value;
        IF ShipmentMethod.GET(CodeFieldRef.VALUE) THEN
            NewId := ShipmentMethod.SystemId
        ELSE
            NewId := EmptyGuid;
        if OldId <> NewId then begin
            IdFieldRef.Value := NewId;
            Changed := true;
        end;
        if Changed then
            TargetRecordRef.Modify();
    end;

    local procedure UpgradeSharePointConnection()
    var
        DocumentService: Record "Document Service";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSharePointConnectionUpgradeTag()) then
            exit;

        if DocumentService.FindFirst() then begin
            DocumentService."Authentication Type" := DocumentService."Authentication Type"::Legacy;
            DocumentService.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSharePointConnectionUpgradeTag());
    end;

    local procedure CreateDefaultAADApplication()
    var
        AADApplicationSetup: Codeunit "AAD Application Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then begin
            if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag()) then
                exit;
            AADApplicationSetup.ModifyDescriptionOfDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag());
        end else begin
            AADApplicationSetup.CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag());
        end;
    end;

    local procedure UpgradeIntegrationTableMapping()
    begin
        UpgradeIntegrationTableMappingUncoupleCodeunitId();
        UpgradeIntegrationTableMappingCouplingCodeunitId();
        UpgradeIntegrationTableMappingFilterForOpportunities();
    end;

    local procedure UpgradeIntegrationTableMappingUncoupleCodeunitId()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Uncouple Codeunit ID", 0);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter(Direction, '%1|%2',
            IntegrationTableMapping.Direction::ToIntegrationTable,
            IntegrationTableMapping.Direction::Bidirectional);
        IntegrationTableMapping.SetFilter("Integration Table ID", '%1|%2|%3|%4|%5|%6|%7|%8',
            Database::"CRM Account",
            Database::"CRM Contact",
            Database::"CRM Invoice",
            Database::"CRM Quote",
            Database::"CRM Salesorder",
            Database::"CRM Opportunity",
            Database::"CRM Product",
            Database::"CRM Productpricelevel");
        IntegrationTableMapping.ModifyAll("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingUpgradeTag());
    end;

    local procedure UpgradeIntegrationTableMappingCouplingCodeunitId()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingCouplingCodeunitIdUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Coupling Codeunit ID", 0);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter("Integration Table ID", '%1|%2|%3|%4|%5|%6',
            Database::"CRM Account",
            Database::"CRM Contact",
            Database::"CRM Opportunity",
            Database::"CRM Product",
            Database::"CRM Uomschedule",
            Database::"CRM Transactioncurrency");
        IntegrationTableMapping.ModifyAll("Coupling Codeunit ID", Codeunit::"CDS Int. Table Couple");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingCouplingCodeunitIdUpgradeTag());
    end;

    local procedure UpgradeIntegrationTableMappingFilterForOpportunities()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Opportunity: Record Opportunity;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        OldTableFilter: Text;
        NewTableFilter: Text;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingFilterForOpportunitiesUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange(Name, 'OPPORTUNITY');
        IntegrationTableMapping.SetRange("Table ID", Database::Opportunity);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Opportunity");
        if IntegrationTableMapping.FindFirst() then begin
            OldTableFilter := IntegrationTableMapping.GetTableFilter();
            if OldTableFilter = '' then begin
                Opportunity.SetFilter(Status, '%1|%2', Opportunity.Status::"Not Started", Opportunity.Status::"In Progress");
                NewTableFilter := CRMSetupDefaults.GetTableFilterFromView(Database::Opportunity, Opportunity.TableCaption(), Opportunity.GetView());
                IntegrationTableMapping.SetTableFilter(NewTableFilter);
                IntegrationTableMapping.Modify();
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationTableMappingFilterForOpportunitiesUpgradeTag());
    end;

    local procedure UpgradeIntegrationFieldMapping()
    begin
        UpgradeIntegrationFieldMappingForOpportunities();
        UpgradeIntegrationFieldMappingForContacts();
        UpgradeIntegrationFieldMappingForInvoices();
    end;

    local procedure UpgradeIntegrationFieldMappingForOpportunities()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempOpportunity: Record Opportunity temporary;
        TempCRMOpportunity: Record "CRM Opportunity" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForOpportunitiesUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange(Name, 'OPPORTUNITY');
        IntegrationTableMapping.SetRange("Table ID", Database::Opportunity);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Opportunity");
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempOpportunity.FieldNo("Contact Company No."));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", TempCRMOpportunity.FieldNo(ParentAccountId));
            if IntegrationFieldMapping.IsEmpty() then
                IntegrationFieldMapping.CreateRecord(
                    IntegrationTableMapping.Name,
                    TempOpportunity.FieldNo("Contact Company No."),
                    TempCRMOpportunity.FieldNo(ParentAccountId),
                    IntegrationFieldMapping.Direction::ToIntegrationTable,
                    '', true, false);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForOpportunitiesUpgradeTag());
    end;

    local procedure UpgradeIntegrationFieldMappingForContacts()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempContact: Record Contact temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForContactsUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange(Name, GetContactIntegrationTableMappingName());
        IntegrationTableMapping.SetRange("Table ID", Database::Contact);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Contact");
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempContact.FieldNo(Type));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", 0);
            IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::FromIntegrationTable);
            IntegrationFieldMapping.SetRange("Transformation Direction", IntegrationFieldMapping."Transformation Direction"::FromIntegrationTable);
            IntegrationFieldMapping.SetFilter("Constant Value", '<>%1', GetContactTypeFieldMappingConstantValue());
            if IntegrationFieldMapping.FindFirst() then begin
                IntegrationFieldMapping."Constant Value" := CopyStr(GetContactTypeFieldMappingConstantValue(), 1, MaxStrLen(IntegrationFieldMapping."Constant Value"));
                IntegrationFieldMapping.Modify();
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForContactsUpgradeTag());
    end;

    local procedure UpgradeIntegrationFieldMappingForInvoices()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        TempCRMInvoice: Record "CRM Invoice" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForInvoicesUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange(Name, 'POSTEDSALESINV-INV');
        IntegrationTableMapping.SetRange("Table ID", Database::"Sales Invoice Header");
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Invoice");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempSalesInvoiceHeader.FieldNo("Work Description"));
            if IntegrationFieldMapping.IsEmpty() then begin
                IntegrationFieldMapping.SetRange("Field No.");
                IntegrationFieldMapping.SetRange("Integration Table Field No.", TempCRMInvoice.FieldNo(Description));
                if IntegrationFieldMapping.IsEmpty() then
                    IntegrationFieldMapping.CreateRecord(
                        IntegrationTableMapping.Name,
                        TempSalesInvoiceHeader.FieldNo("Work Description"),
                        TempCRMInvoice.FieldNo(Description),
                        IntegrationFieldMapping.Direction::ToIntegrationTable,
                        '', false, false);
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntegrationFieldMappingForInvoicesUpgradeTag());
    end;

    local procedure GetContactIntegrationTableMappingName(): Text
    begin
        exit('CONTACT');
    end;

    local procedure GetContactTypeFieldMappingConstantValue(): Text
    begin
        exit('Person');
    end;

    local procedure UpgradeWorkflowStepArgumentEventFilters()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.WorkflowStepArgumentUpgradeTag()) then
            exit;

        ChangeEncodingToUTF8(Database::"Workflow Step Argument", WorkflowStepArgument.FieldNo("Event Conditions"), TextEncoding::MSDos);
        ChangeEncodingToUTF8(Database::"Workflow Step Argument Archive", WorkflowStepArgumentArchive.FieldNo("Event Conditions"), TextEncoding::MSDos);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.WorkflowStepArgumentUpgradeTag());
    end;

    local procedure ChangeEncodingToUTF8(TableNo: Integer; FieldNo: Integer; FromEncoding: TextEncoding)
    var
        InTempBlob, OutTempBlob : Codeunit "Temp Blob";
        RecordRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        Value: Text;
    begin
        RecordRef.Open(TableNo);

        if RecordRef.FindSet(true) then
            repeat
                Clear(InTempBlob);
                Clear(OutTempBlob);

                InTempBlob.FromRecordRef(RecordRef, FieldNo);

                if InTempBlob.HasValue() then begin
                    // Read the value using the given encoding
                    InTempBlob.CreateInStream(InStr, FromEncoding);
                    InStr.Read(Value);

                    // Write the value in UTF8
                    OutTempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.Write(Value);

                    OutTempBlob.ToRecordRef(RecordRef, FieldNo);
                    RecordRef.Modify();
                end;
            until RecordRef.Next() = 0;

        RecordRef.Close();
    end;

    local procedure UpgradeTemplates()
    begin
        UpgradeVendorTemplates();
        UpgradeCustomerTemplates();
        UpgradeItemTemplates();
    end;

    local procedure UpgradeVendorTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        VendorTempl: Record "Vendor Templ.";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        TemplateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVendorTemplatesUpgradeTag()) then
            exit;

        if FindConfigTemplateHeader(ConfigTemplateHeader, Database::Vendor) then
            repeat
                if InsertNewVendorTemplate(VendorTempl, ConfigTemplateHeader.Code, ConfigTemplateHeader.Description) then begin
                    TemplateRecordRef.Open(Database::"Vendor Templ.");
                    TemplateRecordRef.GetTable(VendorTempl);

                    if FindConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code) then
                        repeat
                            if ConfigTemplateFieldCanBeProcessed(ConfigTemplateLine, Database::"Vendor Templ.") then begin
                                TemplateFieldRef := TemplateRecordRef.Field(ConfigTemplateLine."Field ID");
                                ConfigValidateManagement.EvaluateValue(TemplateFieldRef, ConfigTemplateLine."Default Value", false);
                            end;
                        until ConfigTemplateLine.Next() = 0;

                    TemplateRecordRef.Modify();
                    TemplateRecordRef.Close();
                end;
            until ConfigTemplateHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVendorTemplatesUpgradeTag());
    end;

    local procedure UpgradeCustomerTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplate: Record "Customer Template";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        TemplateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCustomerTemplatesUpgradeTag()) then
            exit;

        if FindConfigTemplateHeader(ConfigTemplateHeader, Database::Customer) then
            repeat
                if InsertNewCustomerTemplate(CustomerTempl, ConfigTemplateHeader.Code, ConfigTemplateHeader.Description) then begin
                    TemplateRecordRef.Open(Database::"Customer Templ.");
                    TemplateRecordRef.GetTable(CustomerTempl);

                    if FindConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code) then
                        repeat
                            if ConfigTemplateFieldCanBeProcessed(ConfigTemplateLine, Database::"Customer Templ.") then begin
                                TemplateFieldRef := TemplateRecordRef.Field(ConfigTemplateLine."Field ID");
                                ConfigValidateManagement.EvaluateValue(TemplateFieldRef, ConfigTemplateLine."Default Value", false);
                            end;
                        until ConfigTemplateLine.Next() = 0;

                    TemplateRecordRef.Modify();
                    TemplateRecordRef.Close();
                end;
            until ConfigTemplateHeader.Next() = 0;

        if CustomerTemplate.FindSet() then
            repeat
                if InsertNewCustomerTemplate(CustomerTempl, CustomerTemplate.Code, CustomerTemplate.Description) then
                    UpdateNewCustomerTemplateFromConversionTemplate(CustomerTempl, CustomerTemplate);
            until CustomerTemplate.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCustomerTemplatesUpgradeTag());
    end;

    local procedure UpgradeItemTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        ItemTempl: Record "Item Templ.";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        TemplateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemTemplatesUpgradeTag()) then
            exit;

        if FindConfigTemplateHeader(ConfigTemplateHeader, Database::Item) then
            repeat
                if InsertNewItemTemplate(ItemTempl, ConfigTemplateHeader.Code, ConfigTemplateHeader.Description) then begin
                    TemplateRecordRef.Open(Database::"Item Templ.");
                    TemplateRecordRef.GetTable(ItemTempl);

                    if FindConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code) then
                        repeat
                            if ConfigTemplateFieldCanBeProcessed(ConfigTemplateLine, Database::"Item Templ.") then begin
                                TemplateFieldRef := TemplateRecordRef.Field(ConfigTemplateLine."Field ID");
                                ConfigValidateManagement.EvaluateValue(TemplateFieldRef, ConfigTemplateLine."Default Value", false);
                            end;
                        until ConfigTemplateLine.Next() = 0;

                    TemplateRecordRef.Modify();
                    TemplateRecordRef.Close();
                end;
            until ConfigTemplateHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemTemplatesUpgradeTag());
    end;

    local procedure FindConfigTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; TableId: Integer): Boolean
    begin
        ConfigTemplateHeader.SetRange("Table ID", TableId);
        ConfigTemplateHeader.SetRange(Enabled, true);
        exit(ConfigTemplateHeader.FindSet());
    end;

    local procedure FindConfigTemplateLine(var ConfigTemplateLine: Record "Config. Template Line"; ConfigTemplateHeaderCode: Code[10]): Boolean
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeaderCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.SetFilter("Field ID", '<>0');
        ConfigTemplateLine.SetFilter("Default Value", '<>''''');
        exit(ConfigTemplateLine.FindSet());
    end;

    local procedure InsertNewVendorTemplate(var VendorTempl: Record "Vendor Templ."; TemplateCode: Code[20]; TemplateDescription: Text[100]): Boolean
    begin
        if VendorTempl.Get(TemplateCode) then
            exit(false);

        VendorTempl.Init();
        VendorTempl.Code := TemplateCode;
        VendorTempl.Description := TemplateDescription;
        exit(VendorTempl.Insert());
    end;

    local procedure InsertNewCustomerTemplate(var CustomerTempl: Record "Customer Templ."; TemplateCode: Code[20]; TemplateDescription: Text[100]): Boolean
    begin
        if CustomerTempl.Get(TemplateCode) then
            exit(false);

        CustomerTempl.Init();
        CustomerTempl.Code := TemplateCode;
        CustomerTempl.Description := TemplateDescription;
        exit(CustomerTempl.Insert());
    end;

    local procedure InsertNewItemTemplate(var ItemTempl: Record "Item Templ."; TemplateCode: Code[20]; TemplateDescription: Text[100]): Boolean
    begin
        if ItemTempl.Get(TemplateCode) then
            exit(false);

        ItemTempl.Init();
        ItemTempl.Code := TemplateCode;
        ItemTempl.Description := TemplateDescription;
        exit(ItemTempl.Insert());
    end;

    local procedure ConfigTemplateFieldCanBeProcessed(ConfigTemplateLine: Record "Config. Template Line"; TemplateTableId: Integer): Boolean
    var
        ConfigTemplateField: Record Field;
        NewTemplateField: Record Field;
    begin
        if not ConfigTemplateField.Get(ConfigTemplateLine."Table ID", ConfigTemplateLine."Field ID") then
            exit(false);

        if not NewTemplateField.Get(TemplateTableId, ConfigTemplateLine."Field ID") then
            exit(false);

        if (ConfigTemplateField.Class <> ConfigTemplateField.Class::Normal) or (NewTemplateField.Class <> NewTemplateField.Class::Normal) or
            (ConfigTemplateField.Type <> NewTemplateField.Type) or (ConfigTemplateField.FieldName <> NewTemplateField.FieldName)
        then
            exit(false);

        exit(true);
    end;

    local procedure UpdateNewCustomerTemplateFromConversionTemplate(var CustomerTempl: Record "Customer Templ."; CustomerTemplate: Record "Customer Template")
    begin
        CustomerTempl."Territory Code" := CustomerTemplate."Territory Code";
        CustomerTempl."Global Dimension 1 Code" := CustomerTemplate."Global Dimension 1 Code";
        CustomerTempl."Global Dimension 2 Code" := CustomerTemplate."Global Dimension 2 Code";
        CustomerTempl."Customer Posting Group" := CustomerTemplate."Customer Posting Group";
        CustomerTempl."Currency Code" := CustomerTemplate."Currency Code";
        CustomerTempl."Customer Price Group" := CustomerTemplate."Customer Price Group";
        CustomerTempl."Payment Terms Code" := CustomerTemplate."Payment Terms Code";
        CustomerTempl."Shipment Method Code" := CustomerTemplate."Shipment Method Code";
        CustomerTempl."Invoice Disc. Code" := CustomerTemplate."Invoice Disc. Code";
        CustomerTempl."Customer Disc. Group" := CustomerTemplate."Customer Disc. Group";
        CustomerTempl."Country/Region Code" := CustomerTemplate."Country/Region Code";
        CustomerTempl."Payment Method Code" := CustomerTemplate."Payment Method Code";
        CustomerTempl."Prices Including VAT" := CustomerTemplate."Prices Including VAT";
        CustomerTempl."Gen. Bus. Posting Group" := CustomerTemplate."Gen. Bus. Posting Group";
        CustomerTempl."VAT Bus. Posting Group" := CustomerTemplate."VAT Bus. Posting Group";
        CustomerTempl."Contact Type" := CustomerTemplate."Contact Type";
        CustomerTempl."Allow Line Disc." := CustomerTemplate."Allow Line Disc.";
        CustomerTempl.Modify();
    end;

    procedure UpgradePurchaseRcptLineOverReceiptCode()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.PurchRcptLineOverReceiptCodeUpgradeTag()) then
            exit;

        PurchRcptLine.SetFilter("Over-Receipt Code", '<>''''');
        PurchRcptLine.SetRange("Over-Receipt Code 2", '');
        if PurchRcptLine.FindSet(true) then
            repeat
                PurchRcptLine."Over-Receipt Code 2" := PurchRcptLine."Over-Receipt Code";
                PurchRcptLine.Modify(false);
            until PurchRcptLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.PurchRcptLineOverReceiptCodeUpgradeTag());
    end;

    local procedure UpgradePurchRcptLineDocumentId()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchRcptLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag()) then
            exit;

        PurchRcptLineDataTransfer.SetTables(Database::"Purch. Rcpt. Header", Database::"Purch. Rcpt. Line");
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptHeader.FieldNo("SystemId"), PurchRcptLine.FieldNo("Document Id"));
        PurchRcptLineDataTransfer.AddJoin(PurchRcptHeader.FieldNo("No."), PurchRcptLine.FieldNo("Document No."));
        PurchRcptLineDataTransfer.UpdateAuditFields := false;
        PurchRcptLineDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag());
    end;

    local procedure UpgradeContactMobilePhoneNo()
    var
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.ContactMobilePhoneNoUpgradeTag()) then
            exit;

        UpgradeCustomersMobilePhoneNo();
        UpgradeVendorsMobilePhoneNo();
        UpgradeBankAccountsMobilePhoneNo();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.ContactMobilePhoneNoUpgradeTag());
    end;

    local procedure UpgradeCustomersMobilePhoneNo()
    var
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        Customer.SetFilter("Primary Contact No.", '<>%1', '');
        if Customer.FindSet(true) then
            repeat
                if Contact.Get(Customer."Primary Contact No.") then
                    if Contact."Mobile Phone No." <> '' then begin
                        Customer."Mobile Phone No." := Contact."Mobile Phone No.";
                        Customer.Modify();
                    end;
            until Customer.Next() = 0;
    end;

    local procedure UpgradeVendorsMobilePhoneNo()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        Vendor.SetFilter("Primary Contact No.", '<>%1', '');
        if Vendor.FindSet(true) then
            repeat
                if Contact.Get(Vendor."Primary Contact No.") then
                    if Contact."Mobile Phone No." <> '' then begin
                        Vendor."Mobile Phone No." := Contact."Mobile Phone No.";
                        Vendor.Modify();
                    end;
            until Vendor.Next() = 0;
    end;

    local procedure UpgradeBankAccountsMobilePhoneNo()
    var
        BankAccount: Record "Bank Account";
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");

        if BankAccount.FindSet() then
            repeat
                ContactBusinessRelation.SetRange("No.", BankAccount."No.");
                if ContactBusinessRelation.FindFirst() then
                    if Contact.Get(ContactBusinessRelation."Contact No.") then
                        if Contact."Mobile Phone No." <> '' then begin
                            BankAccount."Mobile Phone No." := Contact."Mobile Phone No.";
                            BankAccount.Modify();
                        end;
            until BankAccount.Next() = 0;
    end;

    local procedure UpgradePostCodeServiceKey()
    var
        PostCodeServiceConfig: Record "Postcode Service Config";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        IsolatedStorageValue: Text;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPostCodeServiceKeyUpgradeTag()) then
            exit;

        if not PostCodeServiceConfig.Get() then
            exit;

        if not IsolatedStorageManagement.Get(PostCodeServiceConfig.ServiceKey, DataScope::Company, IsolatedStorageValue) then
            exit;

        if not IsolatedStorageManagement.Delete(PostCodeServiceConfig.ServiceKey, DataScope::Company) then;

        if IsolatedStorageValue = '' then
            IsolatedStorageValue := 'Disabled';

        PostCodeServiceConfig.SaveServiceKey(IsolatedStorageValue);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPostCodeServiceKeyUpgradeTag());
    end;

#if not CLEAN22
    local procedure UpgradeIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntrastatJnlLinePartnerIDUpgradeTag()) THEN
            exit;

        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        if IntrastatJnlLine.FindSet() then
            repeat
                IntrastatJnlLine."Country/Region of Origin Code" := IntrastatJnlLine.GetCountryOfOriginCode();
                IntrastatJnlLine."Partner VAT ID" := IntrastatJnlLine.GetPartnerID();
                IntrastatJnlLine.Modify();
            until IntrastatJnlLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntrastatJnlLinePartnerIDUpgradeTag());
    end;
#endif

    local procedure UpgradeDimensionSetEntry()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        DimensionSetEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimSetEntryGlobalDimNoUpgradeTag()) THEN
            exit;

        if GeneralLedgerSetup.Get() then begin
            if UpgradeDimensionSetEntryIsHandled() then
                exit;

            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Global Dimension No."), '>0');
            DimensionSetEntryDataTransfer.AddConstantValue(0, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 3 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(3, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 4 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(4, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 5 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(5, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 6 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(6, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 7 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(7, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();

            Clear(DimensionSetEntryDataTransfer);
            DimensionSetEntryDataTransfer.SetTables(Database::"Dimension Set Entry", Database::"Dimension Set Entry");
            DimensionSetEntryDataTransfer.AddSourceFilter(DimensionSetEntry.FieldNo("Dimension Code"), '=%1', GeneralLedgerSetup."Shortcut Dimension 8 Code");
            DimensionSetEntryDataTransfer.AddConstantValue(8, DimensionSetEntry.FieldNo("Global Dimension No."));
            DimensionSetEntryDataTransfer.UpdateAuditFields := false;
            DimensionSetEntryDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDimSetEntryGlobalDimNoUpgradeTag());
    end;

    local procedure UpgradeDimensionSetEntryIsHandled() IsHandled: Boolean;
    begin
        // If you have extended the table "Dimension Set Entry", ModifyAll calls in Codeunit "Update Dim. Set Glbl. Dim. No."
        // can lead to the whole upgrade failed by time out.
        // Subscribe to OnUpgradeDimensionSetEntry and return IsHandled as true to skip the "Dimension Set Entry" update.
        // After upgrade is done you can run the same update by report 482 "Update Dim. Set Glbl. Dim. No.".
        OnUpgradeDimensionSetEntry(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpgradeDimensionSetEntry(var IsHandled: Boolean)
    begin
    end;

    local procedure UpgradePurchaseOrderEntityBuffer()
    var
        PurchaseHeader: Record "Purchase Header";
        GraphMgtPurchOrderBuffer: Codeunit "Graph Mgt - Purch Order Buffer";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchaseOrderEntityBufferUpgradeTag()) THEN
            EXIT;

        PurchaseHeader.SETRANGE("Document Type", PurchaseHeader."Document Type"::Order);
        IF PurchaseHeader.FindSet() THEN
            repeat
                GraphMgtPurchOrderBuffer.InsertOrModifyFromPurchaseHeader(PurchaseHeader);
            until PurchaseHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchaseOrderEntityBufferUpgradeTag());
    end;

    procedure UpgradeSalesCreditMemoReasonCode()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCreditMemoReasonCodeUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesCreditMemoReasonCode(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCreditMemoReasonCodeUpgradeTag());
    end;

    local procedure UpgradeSalesOrderShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesOrderShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradeSalesQuoteShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesQuoteShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesQuoteShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesQuoteShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradeSalesInvoiceShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesInvoiceShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesInvoiceShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesInvoiceShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradeSalesCrMemoShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesCrMemoShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradePurchaseOrderShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseOrderShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradePurchaseOrderShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaseOrderShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradePurchInvoiceShortcutDimension()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchInvoiceShortcutDimensionsUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradePurchInvoiceShortcutDimension(true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchInvoiceShortcutDimensionsUpgradeTag());
    end;

    local procedure UpgradePowerBIOptin()
    var
        MediaRepository: Record "Media Repository";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        TargetClientType: ClientType;
        ImageName: Text[250];
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag()) THEN
            exit;

        ImageName := PowerBIEmbeddedReportPart.GetOptinImageName();

        TargetClientType := ClientType::Phone;
        if not MediaRepository.Get(ImageName, TargetClientType) then
            if not UpdatePowerBIOptinFromExistingImage(TargetClientType) then
                Session.LogMessage('0000EH1', STRSUBSTNO(FailedToUpdatePowerBIImageTxt, TargetClientType), Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');

        TargetClientType := ClientType::Tablet;
        if not MediaRepository.Get(ImageName, TargetClientType) then
            if not UpdatePowerBIOptinFromExistingImage(TargetClientType) then
                Session.LogMessage('0000EH2', STRSUBSTNO(FailedToUpdatePowerBIImageTxt, TargetClientType), Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag());
    end;

    local procedure UpdatePowerBIOptinFromExistingImage(targetClientType: ClientType): Boolean
    var
        MediaRepository: Record "Media Repository";
        TargetMediaRepository: Record "Media Repository";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        ImageName: Text[250];
    begin
        Session.LogMessage('0000EH4', STRSUBSTNO(AttemptingPowerBIUpdateTxt, targetClientType), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');

        // Insert the same image we use on web
        ImageName := PowerBIEmbeddedReportPart.GetOptinImageName();
        if not MediaRepository.Get(ImageName, Format(ClientType::Web)) then
            exit(false);

        TargetMediaRepository.TransferFields(MediaRepository);
        TargetMediaRepository."File Name" := ImageName;
        TargetMediaRepository."Display Target" := Format(targetClientType);
        exit(TargetMediaRepository.Insert());
    end;

    local procedure UpgradeRemoveSmartListGuidedExperience()
    var
        GuidedExperience: Codeunit "Guided Experience";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveSmartListManualSetupEntryUpgradeTag()) THEN
            exit;

        // Page 889 is Page::"SmartList Designer Setup"
        if GuidedExperience.Exists(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, 889) then
            GuidedExperience.Remove(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, 889);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveSmartListManualSetupEntryUpgradeTag());
    end;

    local procedure UpgradeUserTaskDescriptionToUTF8()
    var
        UserTask: Record "User Task";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserTaskDescriptionToUTF8UpgradeTag()) THEN
            exit;

        ChangeEncodingToUTF8(Database::"User Task", UserTask.FieldNo(Description), TextEncoding::Windows);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserTaskDescriptionToUTF8UpgradeTag());
    end;

    local procedure GetSafeRecordCountForSaaSUpgrade(): Integer
    begin
        exit(300000);
    end;

    local procedure UpgradeCreditTransferIBAN()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreditTransferIBANUpgradeTag()) THEN
            exit;

        CreditTransferEntry.SetFilter("Account No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if CreditTransferEntry.Count > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        if CreditTransferEntry.FindSet(true) then
            repeat
                CreditTransferEntry.FillRecipientData();
                CreditTransferEntry.Modify();
            until CreditTransferEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreditTransferIBANUpgradeTag());
    end;

    local procedure UpgradeDocumentDefaultLineType()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDocumentDefaultLineTypeUpgradeTag()) then
            exit;

        if SalesReceivablesSetup.Get() then begin
            SalesReceivablesSetup."Document Default Line Type" := SalesReceivablesSetup."Document Default Line Type"::Item;
            SalesReceivablesSetup.Modify();
        end;

        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup."Document Default Line Type" := PurchasesPayablesSetup."Document Default Line Type"::Item;
            PurchasesPayablesSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDocumentDefaultLineTypeUpgradeTag());
    end;

    local procedure UpgradeJobShipToSellToFunctionality()
    var
        Job: Record Job;
        Customer: Record Customer;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetJobShipToSellToFunctionalityUpgradeTag()) then
            exit;

        Job.SetLoadFields(
            "Bill-to Customer No.",
            "Bill-to Name",
            "Bill-to Name 2",
            "Bill-to Contact",
            "Bill-to Contact No.",
            "Bill-to Address",
            "Bill-to Address 2",
            "Bill-to Post Code",
            "Bill-to Country/Region Code",
            "Bill-to City",
            "Bill-to County",
            "Sell-to Customer Name",
            "Sell-to Customer Name 2",
            "Sell-to Address",
            "Sell-to Address 2",
            "Sell-to City",
            "Sell-to County",
            "Sell-to Post Code",
            "Sell-to Country/Region Code",
            "Sell-to Contact"
        );
        if Job.FindSet() then
            repeat
                Job."Sell-to Customer No." := Job."Bill-to Customer No.";
                Job."Sell-to Customer Name" := Job."Bill-to Name";
                Job."Sell-to Customer Name 2" := Job."Bill-to Name 2";
                Job."Sell-to Contact" := Job."Bill-to Contact";
                Job."Sell-to Contact No." := Job."Bill-to Contact No.";
                Job."Sell-to Address" := Job."Bill-to Address";
                Job."Sell-to Address 2" := Job."Bill-to Address 2";
                Job."Sell-to Post Code" := Job."Bill-to Post Code";
                Job."Sell-to Country/Region Code" := Job."Bill-to Country/Region Code";
                Job."Sell-to City" := Job."Bill-to City";
                Job."Sell-to County" := Job."Bill-to County";
                if Customer.Get(Job."Bill-to Customer No.") then begin
                    Job."Payment Method Code" := Customer."Payment Method Code";
                    Job."Payment Terms Code" := Customer."Payment Terms Code";
                end;

                Job.SyncShipToWithSellTo();
                Job.Modify();
            until Job.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetJobShipToSellToFunctionalityUpgradeTag());
    end;

    procedure UpgradeOnlineMap()
    var
        OnlineMapSetup: Record "Online Map Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetEnableOnlineMapUpgradeTag()) then
            exit;
        if OnlineMapSetup.FindSet() then
            repeat
                OnlineMapSetup.Enabled := true;
                OnlineMapSetup.Modify();
            until OnlineMapSetup.Next() = 0;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEnableOnlineMapUpgradeTag());
    end;

    local procedure UpgradeJobReportSelection()
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetJobReportSelectionUpgradeTag()) then
            exit;
        ReportSelectionMgt.InitReportSelectionJob();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetJobReportSelectionUpgradeTag());
    end;

    local procedure UpgradeICSetup()
    var
        CompanyInfo: Record "Company Information";
        ICSetup: Record "IC Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICSetupUpgradeTag()) then
            exit;

        if not CompanyInfo.Get() then
            exit;

        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;

        ICSetup."IC Partner Code" := CompanyInfo."IC Partner Code";
        ICSetup."IC Inbox Type" := CompanyInfo."IC Inbox Type";
        ICSetup."IC Inbox Details" := CompanyInfo."IC Inbox Details";
        ICSetup."Auto. Send Transactions" := CompanyInfo."Auto. Send Transactions";
        ICSetup.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICSetupUpgradeTag());
    end;

    local procedure UpgradeCRMUnitGroupMapping()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        UnitGroup: Record "Unit Group";
        Item: Record Item;
        Resource: Record Resource;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UnitGroupDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCRMUnitGroupMappingUpgradeTag()) then
            exit;

        if CRMConnectionSetup.Get() then
            if IntegrationTableMapping.Get('UNIT GROUP') then begin
                CRMConnectionSetup."Unit Group Mapping Enabled" := true;
                CRMConnectionSetup.Modify();

                IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
#if not CLEAN22
                IntegrationFieldMapping.SetRange("Field No.", UnitGroup.FieldNo("Code"));
#endif
                IntegrationFieldMapping.ModifyAll("Field No.", UnitGroup.FieldNo("Source No."));
            end else begin
                UnitGroup.DeleteAll();

                UnitGroupDataTransfer.SetTables(Database::Item, Database::"Unit Group");
                UnitGroupDataTransfer.AddFieldValue(Item.FieldNo(SystemId), UnitGroup.FieldNo("Source Id"));
                UnitGroupDataTransfer.AddFieldValue(Item.FieldNo("No."), UnitGroup.FieldNo("Source No."));
                UnitGroupDataTransfer.AddConstantValue(UnitGroup."Source Type"::Item, UnitGroup.FieldNo("Source Type"));
                UnitGroupDataTransfer.UpdateAuditFields := false;
                UnitGroupDataTransfer.CopyRows();
                Clear(UnitGroupDataTransfer);

                UnitGroupDataTransfer.SetTables(Database::Resource, Database::"Unit Group");
                UnitGroupDataTransfer.AddFieldValue(Resource.FieldNo(SystemId), UnitGroup.FieldNo("Source Id"));
                UnitGroupDataTransfer.AddFieldValue(Resource.FieldNo("No."), UnitGroup.FieldNo("Source No."));
                UnitGroupDataTransfer.AddConstantValue(UnitGroup."Source Type"::Resource, UnitGroup.FieldNo("Source Type"));
                UnitGroupDataTransfer.UpdateAuditFields := false;
                UnitGroupDataTransfer.CopyRows();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCRMUnitGroupMappingUpgradeTag());
    end;

    local procedure UpgradeCRMSDK90ToCRMSDK91()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCRMSDK90UpgradeTag()) then
            exit;

        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Proxy Version" = 9 then begin
                CRMConnectionSetup."Proxy Version" := 91;
                CRMConnectionSetup.Modify();
            end;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Proxy Version" = 9 then begin
                CDSConnectionSetup."Proxy Version" := 91;
                CDSConnectionSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCRMSDK90UpgradeTag());
    end;

    local procedure UpgradeCRMSDK91ToDataverseSDK()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCRMSDK91UpgradeTag()) then
            exit;

        if not EnvironmentInformation.IsSaaS() then begin
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCRMSDK91UpgradeTag());
            exit;
        end;

        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Proxy Version" = 91 then begin
                CRMConnectionSetup.Validate("Proxy Version", 100);
                CRMConnectionSetup.Modify();
            end;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Proxy Version" = 91 then begin
                CDSConnectionSetup.Validate("Proxy Version", 100);
                CDSConnectionSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCRMSDK91UpgradeTag());
    end;

    local procedure FillItemChargeAssignmentQtyToHandle()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemChargeHandleQtyUpgradeTag()) then
            exit;

        ItemChargeAssignmentPurch.SetFilter("Qty. to Assign", '>0');
        if ItemChargeAssignmentPurch.FindSet(true) then
            repeat
                ItemChargeAssignmentPurch."Qty. to Handle" := ItemChargeAssignmentPurch."Qty. to Assign";
                ItemChargeAssignmentPurch."Amount to Handle" := ItemChargeAssignmentPurch."Amount to Assign";
                ItemChargeAssignmentPurch.Modify();
            until ItemChargeAssignmentPurch.Next() = 0;

        ItemChargeAssignmentSales.SetFilter("Qty. to Assign", '>0');
        if ItemChargeAssignmentSales.FindSet(true) then
            repeat
                ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
                ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
                ItemChargeAssignmentSales.Modify();
            until ItemChargeAssignmentSales.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemChargeHandleQtyUpgradeTag());
    end;

    local procedure UseCustomLookupInPrices()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUseCustomLookupUpgradeTag()) then
            exit;

        if SalesReceivablesSetup.Get() and not SalesReceivablesSetup."Use Customized Lookup" then
            if PriceCalculationMgt.FindActiveSubscriptions() <> '' then begin
                SalesReceivablesSetup.Validate("Use Customized Lookup", true);
                SalesReceivablesSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUseCustomLookupUpgradeTag());
    end;

    [Scope('OnPrem')]
    local procedure UpgradeAccountSchedulesToFinancialReports()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinancialReport: Record "Financial Report";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        AnythingModified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAccountSchedulesToFinancialReportsUpgradeTag()) then
            exit;
        if not GeneralLedgerSetup.Get() then
            exit;
        FinancialReportMgt.Initialize();
        if not (GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '') then
            if FinancialReport.Get(GeneralLedgerSetup."Acc. Sched. for Balance Sheet") then
                if GeneralLedgerSetup."Fin. Rep. for Balance Sheet" = '' then begin
                    GeneralLedgerSetup."Fin. Rep. for Balance Sheet" := GeneralLedgerSetup."Acc. Sched. for Balance Sheet";
                    AnythingModified := true;
                end;
        if not (GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '') then
            if FinancialReport.Get(GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt") then
                if GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" = '' then begin
                    GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" := GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt";
                    AnythingModified := true;
                end;
        if not (GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '') then
            if FinancialReport.Get(GeneralLedgerSetup."Acc. Sched. for Income Stmt.") then
                if GeneralLedgerSetup."Fin. Rep. for Income Stmt." = '' then begin
                    GeneralLedgerSetup."Fin. Rep. for Income Stmt." := GeneralLedgerSetup."Acc. Sched. for Income Stmt.";
                    AnythingModified := true;
                end;
        if not (GeneralLedgerSetup."Acc. Sched. for Retained Earn." = '') then
            if FinancialReport.Get(GeneralLedgerSetup."Acc. Sched. for Retained Earn.") then
                if GeneralLedgerSetup."Fin. Rep. for Retained Earn." = '' then begin
                    GeneralLedgerSetup."Fin. Rep. for Retained Earn." := GeneralLedgerSetup."Acc. Sched. for Retained Earn.";
                    AnythingModified := true;
                end;
        if AnythingModified then
            GeneralLedgerSetup.Modify();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAccountSchedulesToFinancialReportsUpgradeTag());
    end;

    local procedure UpdatePurchaserOnRequisitionLines()
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PurchaserCodeToAssign: Code[20];
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaserOnRequisitionLineUpdateTag()) then
            exit;

        RequisitionLine.SetFilter("Vendor No.", '<>%1', '');
        if RequisitionLine.FindSet(true) then
            repeat
                if Vendor.Get(RequisitionLine."Vendor No.") and (Vendor."Purchaser Code" <> '') then
                    if ReturnPurchaserCode(Vendor."Purchaser Code", PurchaserCodeToAssign) then begin
                        RequisitionLine.Validate("Purchaser Code", PurchaserCodeToAssign);
                        RequisitionLine.Modify();
                    end;
            until RequisitionLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaserOnRequisitionLineUpdateTag());
    end;

    local procedure ReturnPurchaserCode(PurchaserCodeToCheck: Code[20]; var PurchaserCodeToAssign: Code[20]): Boolean
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if SalespersonPurchaser.Get(PurchaserCodeToCheck) then begin
            if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                PurchaserCodeToAssign := ''
            else
                PurchaserCodeToAssign := PurchaserCodeToCheck;
        end else
            PurchaserCodeToAssign := '';
        exit(PurchaserCodeToAssign <> '');
    end;

    local procedure SendCloudMigrationUsageTelemetry()
    var
        IntelligentCloud: Record "Intelligent Cloud";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSendCloudMigrationUpgradeTelemetryBaseAppTag()) then
            exit;

        if IntelligentCloud.Get() then begin
            FeatureTelemetry.LogUptake('0000JMJ', 'Cloud Migration', Enum::"Feature Uptake Status"::Used);
            TelemetryDimensions.Add('MigrationDateTime', Format(IntelligentCloud.SystemModifiedAt, 0, 9));
            FeatureTelemetry.LogUsage('0000JMK', 'Cloud Migration', 'Base app - Tenant used cloud migration', TelemetryDimensions);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSendCloudMigrationUpgradeTelemetryBaseAppTag());
    end;

    local procedure UpdateCustLedgerEntrySetYourReference()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        CustLedgerDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryYourReferenceUpdateTag()) then
            exit;

        SalesInvoiceHeader.SetLoadFields("Your Reference");
        SalesInvoiceHeader.SetFilter("Your Reference", '<>%1', '');
        if SalesInvoiceHeader.FindSet() then
            repeat
                CustLedgerDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
                CustLedgerDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Document Type"), '=%1', CustLedgerEntry."Document Type"::Invoice);
                CustLedgerDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Document No."), '=%1', SalesInvoiceHeader."No.");
                CustLedgerDataTransfer.AddConstantValue(SalesInvoiceHeader."Your Reference", CustLedgerEntry.FieldNo("Your Reference"));
                CustLedgerDataTransfer.CopyFields();
                Clear(CustLedgerDataTransfer);
            until SalesInvoiceHeader.Next() = 0;

        SalesCrMemoHeader.SetLoadFields("Your Reference");
        SalesCrMemoHeader.SetFilter("Your Reference", '<>%1', '');
        if SalesCrMemoHeader.FindSet() then
            repeat
                CustLedgerDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
                CustLedgerDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Document Type"), '=%1', CustLedgerEntry."Document Type"::"Credit Memo");
                CustLedgerDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Document No."), '=%1', SalesCrMemoHeader."No.");
                CustLedgerDataTransfer.AddConstantValue(SalesCrMemoHeader."Your Reference", CustLedgerEntry.FieldNo("Your Reference"));
                CustLedgerDataTransfer.CopyFields();
                Clear(CustLedgerDataTransfer);
            until SalesCrMemoHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryYourReferenceUpdateTag());
    end;

    local procedure UpgradeICPartnerGLAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        GenJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if GenJournalLine.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"Gen. Journal Line", Database::"Gen. Journal Line");
        GenJournalLineDataTransfer.AddSourceFilter(GenJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", GenJournalLine.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(GenJournalLine.FieldNo("IC Partner G/L Acc. No."), GenJournalLine.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICInboxTransactionAccountNo()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        ICInboxTransaction.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if ICInboxTransaction.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"IC Inbox Transaction", Database::"IC Inbox Transaction");
        GenJournalLineDataTransfer.AddSourceFilter(ICInboxTransaction.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", ICInboxTransaction.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(ICInboxTransaction.FieldNo("IC Partner G/L Acc. No."), ICInboxTransaction.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeHandledICInboxTransactionAccountNo()
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        HandledICInboxTrans.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if HandledICInboxTrans.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"Handled IC Inbox Trans.", Database::"Handled IC Inbox Trans.");
        GenJournalLineDataTransfer.AddSourceFilter(HandledICInboxTrans.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", HandledICInboxTrans.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(HandledICInboxTrans.FieldNo("IC Partner G/L Acc. No."), HandledICInboxTrans.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICOutboxTransactionAccountNo()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        ICOutboxTransaction.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if ICOutboxTransaction.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"IC Outbox Transaction", Database::"IC Outbox Transaction");
        GenJournalLineDataTransfer.AddSourceFilter(ICOutboxTransaction.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", ICOutboxTransaction.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(ICOutboxTransaction.FieldNo("IC Partner G/L Acc. No."), ICOutboxTransaction.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeHandledICOutboxTransactionAccountNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        HandledICOutboxTrans.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if HandledICOutboxTrans.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"Handled IC Outbox Trans.", Database::"Handled IC Outbox Trans.");
        GenJournalLineDataTransfer.AddSourceFilter(HandledICOutboxTrans.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", HandledICOutboxTrans.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(HandledICOutboxTrans.FieldNo("IC Partner G/L Acc. No."), HandledICOutboxTrans.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpdateCheckWhseClassOnLocation()
    var
        Location: Record Location;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        LocationDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCheckWhseClassOnLocationUpgradeTag()) then
            exit;

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Directed Put-away and Pick"), '=%1', true);
        LocationDataTransfer.AddConstantValue(true, Location.FieldNo("Check Whse. Class"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCheckWhseClassOnLocationUpgradeTag());
    end;

    local procedure UpdateDeferralSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDeferralSourceCodeUpdateTag()) then
            exit;

        InsertSourceCode(SourceCodeGeneralDeferralLbl, SourceCodeGeneralDeferralTxt);
        InsertSourceCode(SourceCodeSalesDeferralLbl, SourceCodeSalesDeferralTxt);
        InsertSourceCode(SourceCodePurchaseDeferralLbl, SourceCodePurchaseDeferralTxt);
        if SourceCodeSetup.Get() then begin
            if SourceCodeSetup."General Deferral" = '' then
                SourceCodeSetup."General Deferral" := SourceCodeGeneralDeferralLbl;
            if SourceCodeSetup."Sales Deferral" = '' then
                SourceCodeSetup."Sales Deferral" := SourceCodeSalesDeferralLbl;
            if SourceCodeSetup."Purchase Deferral" = '' then
                SourceCodeSetup."Purchase Deferral" := SourceCodePurchaseDeferralLbl;
            SourceCodeSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDeferralSourceCodeUpdateTag());
    end;

    local procedure UpdateProductionSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetProductionSourceCodeUpdateTag()) then
            exit;

        InsertSourceCode(ProductionOrderLbl, ProductionOrderTxt);
        if SourceCodeSetup.Get() then
            if SourceCodeSetup."Production Order" = '' then begin
                SourceCodeSetup."Production Order" := ProductionOrderLbl;
                SourceCodeSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetProductionSourceCodeUpdateTag());
    end;

    local procedure InsertSourceCode(NewSourceCode: Code[10]; Description: Text[100])
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Init();
        SourceCode.Code := NewSourceCode;
        SourceCode.Description := Description;
        if SourceCode.Insert() then;
    end;

    local procedure UpgradeMapCurrencySymbol()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempCurrency: Record Currency temporary;
        TempCRMTransactionCurrency: Record "CRM Transactioncurrency" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMapCurrencySymbolUpgradeTag()) then
            exit;

        if IntegrationTableMapping.FindMapping(Database::Currency, Database::"CRM Transactioncurrency") then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempCurrency.FieldNo(Code));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", TempCRMTransactionCurrency.FieldNo(CurrencySymbol));
            if IntegrationFieldMapping.FindFirst() then begin
                IntegrationFieldMapping."Field No." := TempCurrency.FieldNo(Symbol);
                IntegrationFieldMapping.Modify();
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMapCurrencySymbolUpgradeTag());
    end;

    local procedure UpgradeOptionMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
#if not CLEAN22
        CDSFailedOptionMapping: Record "CDS Failed Option Mapping";
#endif
        TempCRMAccount: Record "CRM Account" temporary;
        TempCRMInvoice: Record "CRM Invoice" temporary;
        TempCRMSalesorder: Record "CRM Salesorder" temporary;
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetOptionMappingUpgradeTag()) then
            exit;

        CDSSetupDefaults.ResetOptionMappingConfiguration();

        //Payment Terms
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|PAYMENT TERMS');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 15);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMAccount.FieldNo(PaymentTermsCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'POSTEDSALESINV-INV');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 24);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMInvoice.FieldNo(PaymentTermsCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'SALESORDER-ORDER');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 28);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMSalesorder.FieldNo(PaymentTermsCodeEnum));

        //Shipment Method
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|SHIPMENT METHOD');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 75);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMAccount.FieldNo(Address1_FreightTermsCodeEnum));

        //Shipping Agent
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'CUSTOMER|VENDOR|SHIPPING AGENT');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 80);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMAccount.FieldNo(Address1_ShippingMethodCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'POSTEDSALESINV-INV');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 23);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMInvoice.FieldNo(ShippingMethodCodeEnum));

        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'SALESORDER-ORDER');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", 27);
        if not IntegrationFieldMapping.IsEmpty() then
            IntegrationFieldMapping.ModifyAll("Integration Table Field No.", TempCRMSalesorder.FieldNo(ShippingMethodCodeEnum));

        if IntegrationTableMapping.Get('CUSTOMER') then begin
            IntegrationTableMapping."Dependency Filter" += '|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
            IntegrationTableMapping.Modify();
        end;

        if IntegrationTableMapping.Get('VENDOR') then begin
            IntegrationTableMapping."Dependency Filter" += '|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
            IntegrationTableMapping.Modify();
        end;

#if not CLEAN22
        CDSFailedOptionMapping.DeleteAll();
#endif

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetOptionMappingUpgradeTag());
    end;

    local procedure UpgradeICGLAccountNoInPostedGenJournalLine()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PostedGenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        PostedGenJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if PostedGenJournalLine.IsEmpty() then
            exit;

        PostedGenJournalLineDataTransfer.SetTables(Database::"Posted Gen. Journal Line", Database::"Posted Gen. Journal Line");
        PostedGenJournalLineDataTransfer.AddSourceFilter(PostedGenJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        PostedGenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", PostedGenJournalLine.FieldNo("IC Account Type"));
        PostedGenJournalLineDataTransfer.AddFieldValue(PostedGenJournalLine.FieldNo("IC Partner G/L Acc. No."), PostedGenJournalLine.FieldNo("IC Account No."));
        PostedGenJournalLineDataTransfer.CopyFields();
        Clear(PostedGenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICGLAccountNoInStandardGeneralJournalLine()
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        StandardGeneralJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        StandardGeneralJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if StandardGeneralJournalLine.IsEmpty() then
            exit;

        StandardGeneralJournalLineDataTransfer.SetTables(Database::"Standard General Journal Line", Database::"Standard General Journal Line");
        StandardGeneralJournalLineDataTransfer.AddSourceFilter(StandardGeneralJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        StandardGeneralJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", StandardGeneralJournalLine.FieldNo("IC Account Type"));
        StandardGeneralJournalLineDataTransfer.AddFieldValue(StandardGeneralJournalLine.FieldNo("IC Partner G/L Acc. No."), StandardGeneralJournalLine.FieldNo("IC Account No."));
        StandardGeneralJournalLineDataTransfer.CopyFields();
        Clear(StandardGeneralJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeVATSetup()
    var
        VATSetup: Record "VAT Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATSetupUpgradeTag()) then
            exit;
        if not VATSetup.Get() then
            VATSetup.Insert();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATSetupUpgradeTag());
    end;

#if not CLEAN22
    local procedure UpgradeTimesheetExperience()
    var
        ResourcesSetup: Record "Resources Setup";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewTimeSheetExperienceUpgradeTag()) then
            exit;

        if TimeSheetManagement.GetTimeSheetV2FeatureKey() <> '' then
            if ResourcesSetup.Get() then
                if not ResourcesSetup."Use New Time Sheet Experience" then begin
                    // Set to True if the feature NewTimeSheetExperience is enabled for any company
                    FeatureDataUpdateStatus.SetFilter("Feature Key", TimeSheetManagement.GetTimeSheetV2FeatureKey());
                    FeatureDataUpdateStatus.SetRange("Feature Status", FeatureDataUpdateStatus."Feature Status"::"Enabled");
                    if not FeatureDataUpdateStatus.IsEmpty() then begin
                        ResourcesSetup."Use New Time Sheet Experience" := true;
                        ResourcesSetup.Modify();
                    end;
                end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewTimeSheetExperienceUpgradeTag());
    end;
#endif
}
