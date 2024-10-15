codeunit 104000 "Upgrade - BaseApp"
{
    Subtype = Upgrade;
    Permissions = TableData "User Group Plan" = rimd;

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
        UpdateItems();
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
        UpgradeEmailLogging();
        UpgradeIntegrationTableMapping();
        UpgradeIntegrationFieldMapping();
        UpgradeWorkflowStepArgumentEventFilters();
        SetReviewRequiredOnBankPmtApplRules();

        UpgradeAPIs();
        UpgradeTemplates();
        AddPowerBIWorkspaces();
        UpgradePurchaseRcptLineOverReceiptCode();
        UpgradeGenJnlLineArchive();
        UpgradeItemDocuments();
        UpgradePostCodeServiceKey();
        UpgradeCustomDeclarations();
        UpgradeIntrastatJnlLine();
        UpgradeDimensionSetEntry();
        UpgradeUserTaskDescriptionToUTF8();
#if not CLEAN19
        UpgradeRemoveSmartListGuidedExperience();
#endif
        UpgradeCRMIntegrationRecord();

        UpdateWorkflowTableRelations();
        UpgradeWordTemplateTables();
        UpdatePriceSourceGroupInPriceListLines();
        UpdatePriceListLineStatus();
        UpdateAllJobsResourcePrices();
        UpgradeCreditTransferIBAN();
        UpgradeDocumentDefaultLineType();
        UpgradeOnlineMap();
        UpgradeDataExchFieldMapping();
    end;

    local procedure ClearTemporaryTables()
    var
        BinContentBuffer: Record "Bin Content Buffer";
        DocumentEntry: Record "Document Entry";
        EntrySummary: Record "Entry Summary";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
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

        InvoicePostBuffer.Reset();
        InvoicePostBuffer.DeleteAll();

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

        IF DefaultDimension.FINDSET THEN
            REPEAT
                DefaultDimension.UpdateReferencedIds;
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

        IF GenJournalBatch.FINDSET THEN
            REPEAT
                GenJournalBatch.UpdateBalAccountId;
                IF GenJournalBatch.MODIFY THEN;
            UNTIL GenJournalBatch.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetBalAccountNoOnJournalAPIUpgradeTag());
    end;

    local procedure UpdateItems()
    var
        ItemCategory: Record "Item Category";
        Item: Record "Item";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemCategoryOnItemAPIUpgradeTag()) THEN
            EXIT;

        IF NOT ItemCategory.ISEMPTY THEN BEGIN
            Item.SETFILTER("Item Category Code", '<>''''');
            IF Item.FINDSET(TRUE, FALSE) THEN
                REPEAT
                    Item.UpdateItemCategoryId;
                    IF Item.MODIFY THEN;
                UNTIL Item.Next() = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemCategoryOnItemAPIUpgradeTag());
    end;

    local procedure UpdateJobs()
    var
        Job: Record "Job";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        IntegrationManagement: Codeunit "Integration Management";
        RecordRef: RecordRef;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddingIDToJobsUpgradeTag()) THEN
            EXIT;

        IF Job.FINDSET(TRUE, FALSE) THEN
            REPEAT
                IF ISNULLGUID(Job.SystemId) THEN BEGIN
                    RecordRef.GETTABLE(Job);
                    IntegrationManagement.InsertUpdateIntegrationRecord(RecordRef, CURRENTDATETIME());
                    RecordRef.SETTABLE(Job);
                    Job.Modify();
                    Job.UpdateReferencedIds;
                END;
            UNTIL Job.Next() = 0;
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddingIDToJobsUpgradeTag());
    end;

    local procedure UpdatePriceSourceGroupInPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupUpgradeTag()) then
            exit;
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag()) then
            exit;

        PriceListLine.SetRange("Source Group", "Price Source Group"::All);
        if EnvironmentInformation.IsSaaS() then
            if PriceListLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;
        if PriceListLine.FindSet(true) then
            repeat
                if PriceListLine."Source Type" in
                    ["Price Source Type"::"All Jobs",
                    "Price Source Type"::Job,
                    "Price Source Type"::"Job Task"]
                then
                    PriceListLine."Source Group" := "Price Source Group"::Job
                else
                    case PriceListLine."Price Type" of
                        "Price Type"::Purchase:
                            PriceListLine."Source Group" := "Price Source Group"::Vendor;
                        "Price Type"::Sale:
                            PriceListLine."Source Group" := "Price Source Group"::Customer;
                    end;
                if PriceListLine."Source Group" <> "Price Source Group"::All then
                    PriceListLine.Modify();
            until PriceListLine.Next() = 0;

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

        IF CRMConnectionSetup.GET THEN
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

        IF IncomingDocument.FINDSET THEN
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

        if RecordLink.FINDSET then
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
        CreateTimeSheetDetailsIds;
        UpgradeSalesInvoiceEntityAggregate;
        UpgradePurchInvEntityAggregate;
        UpgradeSalesOrderEntityBuffer;
        UpgradeSalesQuoteEntityBuffer;
        UpgradeSalesCrMemoEntityBuffer;
        UpgradeSalesOrderShipmentMethod;
        UpgradeSalesCrMemoShipmentMethod;
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
        ItemModified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemPostingGroupsUpgradeTag()) then
            exit;

        Item.SetLoadFields("Gen. Prod. Posting Group", "Inventory Posting Group");
        if Item.FindSet() then
            repeat
                ItemModified := false;
                if Item."Gen. Prod. Posting Group" <> '' then
                    if GenProdPostingGroup.Get(Item."Gen. Prod. Posting Group") then begin
                        Item."Gen. Prod. Posting Group Id" := GenProdPostingGroup.SystemId;
                        ItemModified := true;
                    end;
                if Item."Inventory Posting Group" <> '' then
                    if InventoryPostingGroup.Get(Item."Inventory Posting Group") then begin
                        Item."Inventory Posting Group Id" := InventoryPostingGroup.SystemId;
                        ItemModified := true;
                    end;
                if ItemModified then
                    Item.Modify(false);
            until Item.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemPostingGroupsUpgradeTag());
    end;

    local procedure CreateTimeSheetDetailsIds()
    var
        GraphMgtTimeRegistration: Codeunit "Graph Mgt - Time Registration";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetTimeRegistrationUpgradeTag()) THEN
            EXIT;

        GraphMgtTimeRegistration.UpdateIntegrationRecords(TRUE);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetTimeRegistrationUpgradeTag());
    end;

    local procedure UpgradeSalesShipmentLineDocumentId()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesShipmentLineUpgradeTag()) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            if SalesShipmentLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        if SalesShipmentHeader.FindSet() then
            repeat
                SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
                SalesShipmentLine.ModifyAll("Document Id", SalesShipmentHeader.SystemId);
            until SalesShipmentHeader.Next() = 0;

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
                    IF SalesInvoiceHeader.FINDFIRST THEN BEGIN
                        SourceRecordRef.GETTABLE(SalesInvoiceHeader);
                        TargetRecordRef.GETTABLE(SalesInvoiceEntityAggregate);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, TRUE);
                    END;
                END ELSE BEGIN
                    SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SETRANGE(SystemId, SalesInvoiceEntityAggregate.Id);
                    IF SalesHeader.FINDFIRST THEN BEGIN
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
                    IF PurchInvHeader.FINDFIRST THEN BEGIN
                        SourceRecordRef.GETTABLE(PurchInvHeader);
                        TargetRecordRef.GETTABLE(PurchInvEntityAggregate);
                        UpdatePurchaseDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE);
                    END;
                END ELSE BEGIN
                    PurchaseHeader.SETRANGE("Document Type", PurchaseHeader."Document Type"::Invoice);
                    PurchaseHeader.SETRANGE(SystemId, PurchInvEntityAggregate.Id);
                    IF PurchaseHeader.FINDFIRST THEN BEGIN
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
                IF SalesHeader.FINDFIRST THEN BEGIN
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
                IF SalesHeader.FINDFIRST THEN BEGIN
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
                    IF SalesCrMemoHeader.FINDFIRST THEN BEGIN
                        SourceRecordRef.GETTABLE(SalesCrMemoHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, FALSE);
                    END;
                END ELSE BEGIN
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesHeader.FINDFIRST THEN BEGIN
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, TRUE, TRUE, FALSE);
                    END;
                END;
            UNTIL SalesCrMemoEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesCrMemoEntityBufferUpgradeTag());
    end;

    local procedure UpgradeCRMIntegrationRecord()
    begin
        SetCoupledFlags();
    end;

    local procedure SetCoupledFlags()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSetCoupledFlagsUpgradeTag()) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            if CRMIntegrationRecord.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        if CRMIntegrationRecord.FindSet() then
            repeat
                CRMIntegrationManagement.SetCoupledFlag(CRMIntegrationRecord, true, false)
            until CRMIntegrationRecord.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSetCoupledFlagsUpgradeTag());
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

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag);
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
                NotificationEntry."Error Message" := NotificationEntry."Error Message 2" +
                  NotificationEntry."Error Message 3" + NotificationEntry."Error Message 4";

                NotificationEntry.Modify();
            until NotificationEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNotificationEntryMergeErrorMessageFieldsUpgradeTag);
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
            IF NOT GET THEN
                EXIT;
            IF IsPeriodReminderCalculation OR ("Period Reminder Time" = 0) THEN
                EXIT;

            DateFormulaText := STRSUBSTNO('<%1D>', "Period Reminder Time");
            EVALUATE("Period Reminder Calculation", DateFormulaText);
            "Period Reminder Time" := 0;

            IF MODIFY THEN;
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

        IF StandardSalesCode.FINDSET THEN
            REPEAT
                StandardCustomerSalesCode.SETRANGE(Code, StandardSalesCode.Code);
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

        IF StandardPurchaseCode.FINDSET THEN
            REPEAT
                StandardVendorPurchaseCode.SETRANGE(Code, StandardPurchaseCode.Code);
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
        PowerBIReportBuffer: Record "Power BI Report Buffer";
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

        if PowerBIReportBuffer.FindSet(true, false) then
            repeat
                if PowerBIReportBuffer.ReportEmbedUrl = '' then begin
                    PowerBIReportBuffer.ReportEmbedUrl := PowerBIReportBuffer.EmbedUrl;
                    PowerBIReportBuffer.Modify();
                end;
            until PowerBIReportBuffer.Next() = 0;

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
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemVariantItemIdUpgradeTag()) then
            exit;

        if ItemVariant.FindSet() then
            repeat
                if Item.Get(ItemVariant."Item No.") then
                    if ItemVariant."Item Id" <> Item.SystemId then begin
                        ItemVariant2 := ItemVariant;
                        ItemVariant2."Item Id" := Item.SystemId;
                        ItemVariant2.Modify();
                    end;
            until ItemVariant.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemVariantItemIdUpgradeTag());
    end;

    local procedure UpgradeDefaultDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionParentTypeUpgradeTag()) then
            exit;

        DefaultDimension.SetRange("Table ID", Database::Item);
        DefaultDimension.ModifyAll("Parent Type", DefaultDimension."Parent Type"::Item);

        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Customer);
        DefaultDimension.ModifyAll("Parent Type", DefaultDimension."Parent Type"::Customer);

        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Vendor);
        DefaultDimension.ModifyAll("Parent Type", DefaultDimension."Parent Type"::Vendor);

        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Employee);
        DefaultDimension.ModifyAll("Parent Type", DefaultDimension."Parent Type"::Employee);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultDimensionParentTypeUpgradeTag());
    end;

    local procedure UpgradeDimensionValues()
    var
        Dimension: Record "Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimensionValueDimensionIdUpgradeTag()) then
            exit;

        if DimensionValue.FindSet() then
            repeat
                if Dimension.Get(DimensionValue."Dimension Code") then
                    if DimensionValue."Dimension Id" <> Dimension.SystemId then begin
                        DimensionValue2 := DimensionValue;
                        DimensionValue2."Dimension Id" := Dimension.SystemId;
                        DimensionValue2.Modify();
                    end;
            until DimensionValue.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDimensionValueDimensionIdUpgradeTag());
    end;

    local procedure UpgradeGLAccountAPIType()
    var
        GLAccount: Record "G/L Account";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGLAccountAPITypeUpgradeTag()) then
            exit;

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Posting);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Heading);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Heading);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Total);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Total);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"Begin-Total");
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::"Begin-Total");

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"End-Total");
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::"End-Total");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLAccountAPITypeUpgradeTag());
    end;

    local procedure AddDeviceISVEmbPlan()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddDeviceISVEmbUpgradeTag()) THEN
            EXIT;

        UpdateUserGroupPlan;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddDeviceISVEmbUpgradeTag());
    end;

    local procedure UpdateUserGroupPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        InsertUserGroupPlanFields(PlanIds.GetDeviceISVPlanId(), 'D365 BUS FULL ACCESS');
    end;

    local procedure InsertUserGroupPlanFields(PlanId: Guid; UserGroupCode: Code[20])
    var
        UserGroupPlan: Record "User Group Plan";
        UserGroup: Record "User Group";
    begin
        if UserGroupPlan.Get(PlanId, UserGroupCode) then
            exit;

        if not UserGroup.Get(UserGroupCode) then
            exit;

        UserGroupPlan.Init();
        UserGroupPlan."Plan ID" := PlanId;
        UserGroupPlan."User Group Code" := UserGroupCode;

        UserGroupPlan.Insert();

        Session.LogMessage('00001PS', STRSUBSTNO('User Group %1 was linked to Plan %2.', UserGroupCode, PlanId), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
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
                IF SalesHeader.FINDFIRST THEN BEGIN
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
                    IF SalesCrMemoHeader.FINDFIRST THEN BEGIN
                        SourceRecordRef.GETTABLE(SalesCrMemoHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                    END;
                END ELSE BEGIN
                    SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SETRANGE(SystemId, SalesCrMemoEntityBuffer.Id);
                    IF SalesHeader.FINDFIRST THEN BEGIN
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

    local procedure UpgradeEmailLogging()
    var
        MarketingSetup: Record "Marketing Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetEmailLoggingUpgradeTag()) then
            exit;

        if IsEmailLoggingConfigured() then
            if MarketingSetup.Get() then
                if not MarketingSetup."Email Logging Enabled" then begin
                    MarketingSetup."Email Logging Enabled" := true;
                    MarketingSetup.Modify();
                end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEmailLoggingUpgradeTag());
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

    local procedure IsEmailLoggingConfigured(): Boolean
    var
        MarketingSetup: Record "Marketing Setup";
        JobQueueEntry: Record "Job Queue Entry";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
    begin
        if not InteractionTemplateSetup.Get() then
            exit(false);

        if InteractionTemplateSetup."E-Mails" = '' then
            exit(false);

        InteractionTemplate.SetRange(Code, InteractionTemplateSetup."E-Mails");
        if InteractionTemplate.IsEmpty() then
            exit(false);

        if not MarketingSetup.Get() then
            exit(false);

        if MarketingSetup."Autodiscovery E-Mail Address" = '' then
            exit(false);

        if not MarketingSetup."Queue Folder UID".HasValue then
            exit(false);

        if not MarketingSetup."Storage Folder UID".HasValue then
            exit(false);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Email Logging Context Adapter");
        if JobQueueEntry.IsEmpty() then
            exit(false);

        exit(true);
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

    local procedure UpgradeGenJnlLineArchive()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        GenJournalLineArchive: Record "Gen. Journal Line Archive";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGenJnlLineArchiveUpgradeTag()) then
            exit;

        if GenJournalLineArchive.FindSet() then
            repeat
                PostedGenJournalLine.Init();
                PostedGenJournalLine.TransferFields(GenJournalLineArchive);
                PostedGenJournalLine.Insert();
            until GenJournalLineArchive.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGenJnlLineArchiveUpgradeTag());
    end;

    local procedure UpgradePurchRcptLineDocumentId()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag()) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            if PurchRcptLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        if PurchRcptHeader.FindSet() then
            repeat
                PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
                PurchRcptLine.ModifyAll("Document Id", PurchRcptHeader.SystemId);
            until PurchRcptHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag());
    end;

    local procedure UpgradeItemDocuments()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemReceiptHeader: Record "Item Receipt Header";
        ItemReceiptLine: Record "Item Receipt Line";
        ItemShipmentHeader: Record "Item Shipment Header";
        ItemShipmentLine: Record "Item Shipment Line";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        DirectTransferHeader: Record "Direct Transfer Header";
        DirectTransferLine: Record "Direct Transfer Line";
        DirectTransHeader: Record "Direct Trans. Header";
        DirectTransLine: Record "Direct Trans. Line";
        InventorySetup: Record "Inventory Setup";
        SourceCodeSetup: Record "Source Code Setup";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemDocumentsUpgradeTag()) then
            exit;

        if InventorySetup.Get() then begin
            InventorySetup."Invt. Receipt Nos." := InventorySetup."Item Receipt Nos.";
            InventorySetup."Invt. Shipment Nos." := InventorySetup."Item Shipment Nos.";
            InventorySetup."Posted Direct Trans. Nos." := InventorySetup."Posted Direct Transfer Nos.";
            InventorySetup."Posted Invt. Receipt Nos." := InventorySetup."Posted Item Receipt Nos.";
            InventorySetup."Posted Invt. Shipment Nos." := InventorySetup."Posted Item Shipment Nos.";
            InventorySetup.Modify();
        end;

        if SourceCodeSetup.Get() then begin
            SourceCodeSetup."Invt. Receipt" := SourceCodeSetup."Item Receipt";
            SourceCodeSetup."Invt. Shipment" := SourceCodeSetup."Item Shipment";
            SourceCodeSetup.Modify();
        end;

        if ItemDocumentHeader.FindSet() then
            repeat
                InvtDocumentHeader.Init();
                InvtDocumentHeader.TransferFields(ItemDocumentHeader);
                InvtDocumentHeader.Insert();
            until ItemDocumentHeader.Next() = 0;

        if ItemDocumentLine.FindSet() then
            repeat
                InvtDocumentLine.Init();
                InvtDocumentLine.TransferFields(ItemDocumentLine);
                InvtDocumentLine.Insert();
            until ItemDocumentLine.Next() = 0;

        if ItemReceiptHeader.FindSet() then
            repeat
                InvtReceiptHeader.Init();
                InvtReceiptHeader.TransferFields(ItemReceiptHeader);
                InvtReceiptHeader.Insert();
            until ItemReceiptHeader.Next() = 0;

        if ItemReceiptLine.FindSet() then
            repeat
                InvtReceiptLine.Init();
                InvtReceiptLine.TransferFields(ItemReceiptLine);
                InvtReceiptLine.Insert();
            until ItemReceiptLine.Next() = 0;

        if ItemShipmentHeader.FindSet() then
            repeat
                InvtShipmentHeader.Init();
                InvtShipmentHeader.TransferFields(ItemShipmentHeader);
                InvtShipmentHeader.Insert();
            until ItemShipmentHeader.Next() = 0;

        if ItemShipmentLine.FindSet() then
            repeat
                InvtShipmentLine.Init();
                InvtShipmentLine.TransferFields(ItemShipmentLine);
                InvtShipmentLine.Insert();
            until ItemShipmentLine.Next() = 0;

        if DirectTransferHeader.FindSet() then
            repeat
                DirectTransHeader.Init();
                DirectTransHeader.TransferFields(DirectTransferHeader);
                DirectTransHeader.Insert();
            until DirectTransferHeader.Next() = 0;

        if DirectTransferLine.FindSet() then
            repeat
                DirectTransLine.Init();
                DirectTransLine.TransferFields(DirectTransferLine);
                DirectTransLine.Insert();
            until DirectTransferLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemDocumentsUpgradeTag());
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

    local procedure UpgradeIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntrastatJnlLinePartnerIDUpgradeTag) THEN
            exit;

        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        if IntrastatJnlLine.FindSet() then
            repeat
                IntrastatJnlLine."Country/Region of Origin Code" := IntrastatJnlLine.GetCountryOfOriginCode();
                IntrastatJnlLine."Partner VAT ID" := IntrastatJnlLine.GetPartnerID();
                IntrastatJnlLine.Modify();
            until IntrastatJnlLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetIntrastatJnlLinePartnerIDUpgradeTag);
    end;

    local procedure UpgradeDimensionSetEntry()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        EnvironmentInformation: Codeunit "Environment Information";
        UpdateDimSetGlblDimNo: Codeunit "Update Dim. Set Glbl. Dim. No.";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimSetEntryGlobalDimNoUpgradeTag()) THEN
            exit;

        if GeneralLedgerSetup.Get() then begin
            if EnvironmentInformation.IsSaaS() then
                if DimensionSetEntry.Count() > GetSafeRecordCountForSaaSUpgrade() then
                    exit;

            if UpgradeDimensionSetEntryIsHandled() then
                exit;
            UpdateDimSetGlblDimNo.BlankGlobalDimensionNo();
            UpdateDimSetGlblDimNo.SetGlobalDimensionNos(GeneralLedgerSetup);
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

    local procedure UpgradeCustomDeclarations()
    var
        InventoryProfile: Record "Inventory Profile";
        ItemEntryRelation: Record "Item Entry Relation";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        PostedInvtPutawayLine: Record "Posted Invt. Put-away Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        CDNoInfo: Record "CD No. Information";
        PackageNoInfo: Record "Package No. Information";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCustomDeclarationsUpgradeTag()) then
            exit;

        if ItemTrackingCode.FindSet() then
            repeat
                ItemTrackingCode."Package Specific Tracking" := ItemTrackingCode."CD Specific Tracking";
                ItemTrackingCode."Package Warehouse Tracking" := ItemTrackingCode."CD Warehouse Tracking";
                ItemTrackingCode.Modify();
            until ItemTrackingCode.Next() = 0;

        InventoryProfile.SetFilter("CD No.", '<>%1', '');
        if InventoryProfile.FindSet() then
            repeat
                InventoryProfile."Package No." := InventoryProfile."CD No.";
                InventoryProfile.Modify();
            until InventoryProfile.Next() = 0;

        ItemEntryRelation.SetFilter("CD No.", '<>%1', '');
        if ItemEntryRelation.FindSet() then
            repeat
                ItemEntryRelation."Package No." := ItemEntryRelation."CD No.";
                ItemEntryRelation.Modify();
            until ItemEntryRelation.Next() = 0;

        ItemJournalLine.SetFilter("CD No.", '<>%1', '');
        if ItemJournalLine.FindSet() then
            repeat
                ItemJournalLine."Package No." := ItemJournalLine."CD No.";
                ItemJournalLine.Modify();
            until ItemJournalLine.Next() = 0;

        ItemLedgerEntry.SetFilter("CD No.", '<>%1', '');
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry."Package No." := ItemLedgerEntry."CD No.";
                ItemLedgerEntry.Modify();
            until ItemLedgerEntry.Next() = 0;

        JobJournalLine.SetFilter("CD No.", '<>%1', '');
        if JobJournalLine.FindSet() then
            repeat
                JobJournalLine."Package No." := JobJournalLine."CD No.";
                JobJournalLine.Modify();
            until JobJournalLine.Next() = 0;

        JobLedgerEntry.SetFilter("CD No.", '<>%1', '');
        if JobLedgerEntry.FindSet() then
            repeat
                JobLedgerEntry."Package No." := JobLedgerEntry."CD No.";
                JobLedgerEntry.Modify();
            until JobLedgerEntry.Next() = 0;

        JobPlanningLine.SetFilter("CD No.", '<>%1', '');
        if JobPlanningLine.FindSet() then
            repeat
                JobPlanningLine."Package No." := JobPlanningLine."CD No.";
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;

        PostedInvtPickLine.SetFilter("CD No.", '<>%1', '');
        if PostedInvtPickLine.FindSet() then
            repeat
                PostedInvtPickLine."Package No." := PostedInvtPickLine."CD No.";
                PostedInvtPickLine.Modify();
            until PostedInvtPickLine.Next() = 0;

        PostedInvtPutawayLine.SetFilter("CD No.", '<>%1', '');
        if PostedInvtPutawayLine.FindSet() then
            repeat
                PostedInvtPutawayLine."Package No." := PostedInvtPutawayLine."CD No.";
                PostedInvtPutawayLine.Modify();
            until PostedInvtPutawayLine.Next() = 0;

        PostedWhseReceiptLine.SetFilter("CD No.", '<>%1', '');
        if PostedWhseReceiptLine.FindSet() then
            repeat
                PostedWhseReceiptLine."Package No." := PostedWhseReceiptLine."CD No.";
                PostedWhseReceiptLine.Modify();
            until PostedWhseReceiptLine.Next() = 0;

        RegisteredInvtMovementLine.SetFilter("CD No.", '<>%1', '');
        if RegisteredInvtMovementLine.FindSet() then
            repeat
                RegisteredInvtMovementLine."Package No." := RegisteredInvtMovementLine."CD No.";
                RegisteredInvtMovementLine.Modify();
            until RegisteredInvtMovementLine.Next() = 0;

        RegisteredWhseActivityLine.SetFilter("CD No.", '<>%1', '');
        if RegisteredWhseActivityLine.FindSet() then
            repeat
                RegisteredWhseActivityLine."Package No." := RegisteredWhseActivityLine."CD No.";
                RegisteredWhseActivityLine.Modify();
            until RegisteredWhseActivityLine.Next() = 0;

        ReservationEntry.SetFilter("CD No.", '<>%1', '');
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry."Package No." := ReservationEntry."CD No.";
                ReservationEntry.Modify();
            until ReservationEntry.Next() = 0;

        TrackingSpecification.SetFilter("CD No.", '<>%1', '');
        if TrackingSpecification.FindSet() then
            repeat
                TrackingSpecification."Package No." := TrackingSpecification."CD No.";
                TrackingSpecification.Modify();
            until TrackingSpecification.Next() = 0;

        WarehouseActivityLine.SetFilter("CD No.", '<>%1', '');
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine."Package No." := WarehouseActivityLine."CD No.";
                WarehouseActivityLine.Modify();
            until WarehouseActivityLine.Next() = 0;

        WarehouseJournalLine.SetFilter("CD No.", '<>%1', '');
        if WarehouseJournalLine.FindSet() then
            repeat
                WarehouseJournalLine."Package No." := WarehouseJournalLine."CD No.";
                WarehouseJournalLine.Modify();
            until WarehouseJournalLine.Next() = 0;

        WarehouseEntry.SetFilter("CD No.", '<>%1', '');
        if WarehouseEntry.FindSet() then
            repeat
                WarehouseEntry."Package No." := WarehouseEntry."CD No.";
                WarehouseEntry.Modify();
            until WarehouseEntry.Next() = 0;

        WhseItemEntryRelation.SetFilter("CD No.", '<>%1', '');
        if WhseItemEntryRelation.FindSet() then
            repeat
                WhseItemEntryRelation."Package No." := WhseItemEntryRelation."CD No.";
                WhseItemEntryRelation.Modify();
            until WhseItemEntryRelation.Next() = 0;

        WhseItemTrackingLine.SetFilter("CD No.", '<>%1', '');
        if WhseItemTrackingLine.FindSet() then
            repeat
                WhseItemTrackingLine."Package No." := WhseItemTrackingLine."CD No.";
                WhseItemTrackingLine.Modify();
            until WhseItemTrackingLine.Next() = 0;

        if CDNoInfo.FindSet() then
            repeat
                case CDNoInfo.Type of
                    CDNoInfo.Type::Item:
                        begin
                            PackageNoInfo.Init();
                            PackageNoInfo."Item No." := CDNoInfo."No.";
                            PackageNoInfo."Package No." := CDNoInfo."CD No.";
                            PackageNoInfo."Country/Region Code" := CDNoInfo."Country/Region Code";
                            PackageNoInfo.Description := CDNoInfo.Description;
                            PackageNoInfo."Certificate Number" := CDNoInfo."Certificate Number";
                            PackageNoInfo.Blocked := CDNoInfo.Blocked;
                            PackageNoInfo.Insert();
                        end;
                end;
            until CDNoInfo.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCustomDeclarationsUpgradeTag());
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
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCreditMemoReasonCodeUpgradeTag()) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            if SalesCrMemoEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then
                exit;

        SalesCrMemoEntityBuffer.SetLoadFields(SalesCrMemoEntityBuffer.Id);
        if SalesCrMemoEntityBuffer.FindSet(true, false) then
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetLoadFields(SalesCrMemoHeader."Reason Code");
                    if SalesCrMemoHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id) then
                        UpdateSalesCreditMemoReasonCodeFields(SalesCrMemoHeader."Reason Code", SalesCrMemoEntityBuffer);
                end else begin
                    SalesHeader.SetLoadFields(SalesHeader."Reason Code");
                    if SalesHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id) then
                        UpdateSalesCreditMemoReasonCodeFields(SalesHeader."Reason Code", SalesCrMemoEntityBuffer);
                end;
            until SalesCrMemoEntityBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCreditMemoReasonCodeUpgradeTag());
    end;

    local procedure UpgradeSalesOrderShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradeSalesOrderShortcutDimension();
    end;

    local procedure UpgradeSalesQuoteShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradeSalesQuoteShortcutDimension();
    end;

    local procedure UpgradeSalesInvoiceShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradeSalesInvoiceShortcutDimension();
    end;

    local procedure UpgradeSalesCrMemoShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradeSalesCrMemoShortcutDimension();
    end;

    local procedure UpgradePurchaseOrderShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradePurchaseOrderShortcutDimension();
    end;

    local procedure UpgradePurchInvoiceShortcutDimension()
    var
        APIFixDocumentShortcutDim: Codeunit "API Fix Document Shortcut Dim.";
    begin
        APIFixDocumentShortcutDim.UpgradePurchInvoiceShortcutDimension()
    end;

    local procedure UpgradePowerBIOptin()
    var
        MediaRepository: Record "Media Repository";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        PowerBIReportSpinnerPart: Page "Power BI Report Spinner Part";
        TargetClientType: ClientType;
        ImageName: Text[250];
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag()) THEN
            exit;

        ImageName := PowerBIReportSpinnerPart.GetOptinImageName();

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
        PowerBIReportSpinnerPart: Page "Power BI Report Spinner Part";
        ImageName: Text[250];
    begin
        Session.LogMessage('0000EH4', STRSUBSTNO(AttemptingPowerBIUpdateTxt, targetClientType), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');

        // Insert the same image we use on web
        ImageName := PowerBIReportSpinnerPart.GetOptinImageName();
        if not MediaRepository.Get(ImageName, Format(ClientType::Web)) then
            exit(false);

        TargetMediaRepository.TransferFields(MediaRepository);
        TargetMediaRepository."File Name" := ImageName;
        TargetMediaRepository."Display Target" := Format(targetClientType);
        exit(TargetMediaRepository.Insert());
    end;

    local procedure UpgradeNativeAPIWebService()
    var
        NativeSetupAPIs: Codeunit "Native - Setup APIs";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpgradeNativeAPIWebServiceUpgradeTag()) THEN
            exit;

        NativeSetupAPIs.InsertNativeInvoicingWebServices(false);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUpgradeNativeAPIWebServiceUpgradeTag());
    end;

#if not CLEAN19
    local procedure UpgradeRemoveSmartListGuidedExperience()
    var
        GuidedExperience: Codeunit "Guided Experience";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveSmartListManualSetupEntryUpgradeTag()) THEN
            exit;

        if GuidedExperience.Exists(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, Page::"SmartList Designer Setup") then
            GuidedExperience.Remove(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, Page::"SmartList Designer Setup");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveSmartListManualSetupEntryUpgradeTag());
    end;
#endif

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

    local procedure UpdateSalesCreditMemoReasonCodeFields(SourceReasonCode: Code[10]; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"): Boolean
    var
        ReasonCode: Record "Reason Code";
        NewReasonCodeId: Guid;
        EmptyGuid: Guid;
        Changed: Boolean;
    begin
        if SalesCrMemoEntityBuffer."Reason Code" <> SourceReasonCode then begin
            SalesCrMemoEntityBuffer."Reason Code" := SourceReasonCode;
            Changed := true;
        end;

        if SalesCrMemoEntityBuffer."Reason Code" <> '' then begin
            if ReasonCode.Get(SalesCrMemoEntityBuffer."Reason Code") then
                NewReasonCodeId := ReasonCode.SystemId
            else
                NewReasonCodeId := EmptyGuid;
        end else
            NewReasonCodeId := EmptyGuid;

        if SalesCrMemoEntityBuffer."Reason Code Id" <> NewReasonCodeId then begin
            SalesCrMemoEntityBuffer."Reason Code Id" := NewReasonCodeId;
            Changed := true;
        end;

        if Changed then
            exit(SalesCrMemoEntityBuffer.Modify());
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
            until OnlineMapSetup.next = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEnableOnlineMapUpgradeTag());
    end;
}

