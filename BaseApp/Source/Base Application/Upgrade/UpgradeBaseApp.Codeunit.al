codeunit 104000 "Upgrade - BaseApp"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    var
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

    trigger OnUpgradePerDatabase()
    begin
        CreateWorkflowWebhookWebServices();
        CreateExcelTemplateWebServices();
        CopyRecordLinkURLsIntoOneField();
        UpgradeSharePointConnection();
        CreateDefaultAADApplication();
        UpgradePowerBIOptin();
        UpgradeNativeAPIWebService();
    end;

    trigger OnUpgradePerCompany()
    begin
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
        UpgradeIntegrationTableMappingFilterForOpportunities();
        UpgradeIntegrationFieldMappingForOpportunities();
        UpgradeIntegrationFieldMappingForContacts();
        UpgradeWorkflowStepArgumentEventFilters();
        SetReviewRequiredOnBankPmtApplRules();

        UpgradeAPIs();
        UpgradeTemplates();
        UpgradePurchaseRcptLineOverReceiptCode();
        UpgradeContactMobilePhoneNo();
        UpgradePostCodeServiceKey();
        UpgradeIntrastatJnlLine();
        UpgradeDimensionSetEntry();
        UpgradeUserTaskDescriptionToUTF8();

        UpdateWorkflowTableRelations();
        UpgradeWordTemplateTables();
        UpdatePriceSourceGroupInPriceListLines();
        UpdatePriceListLineStatus()
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
        IF UserGroupPlan.GET(PlanId, UserGroupCode) THEN
            EXIT;

        IF NOT UserGroup.GET(UserGroupCode) THEN
            EXIT;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewVendorTemplatesUpgradeTag()) then
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

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewVendorTemplatesUpgradeTag());
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewCustomerTemplatesUpgradeTag()) then
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

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewCustomerTemplatesUpgradeTag());
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewItemTemplatesUpgradeTag()) then
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

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewItemTemplatesUpgradeTag());
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
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimensionSetEntryUpgradeTag()) THEN
            exit;

        if GeneralLedgerSetup.Get() then begin
            if GeneralLedgerSetup."Shortcut Dimension 3 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 3 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 3);
            end;
            if GeneralLedgerSetup."Shortcut Dimension 4 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 4 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 4);
            end;
            if GeneralLedgerSetup."Shortcut Dimension 5 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 5 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 5);
            end;
            if GeneralLedgerSetup."Shortcut Dimension 6 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 6 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 6);
            end;
            if GeneralLedgerSetup."Shortcut Dimension 7 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 7 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 7);
            end;
            if GeneralLedgerSetup."Shortcut Dimension 8 Code" <> '' then begin
                DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 8 Code");
                DimensionSetEntry.ModifyAll("Global Dimension No.", 8);
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDimensionSetEntryUpgradeTag());
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
}

