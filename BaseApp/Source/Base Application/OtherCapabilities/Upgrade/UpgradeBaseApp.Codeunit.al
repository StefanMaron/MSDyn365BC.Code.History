﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Assembly.Document;
using Microsoft.API.Upgrade;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Task;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Integration.SyncEngine;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Setup;
#if not CLEAN22
using Microsoft.Inventory.Intrastat;
#endif
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Setup;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Resource;
#if not CLEAN22
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
#endif
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Structure;
using Microsoft.Utilities;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.PowerBI;
using System.Integration.Word;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Encryption;
using System.Security.User;
using System.Telemetry;
using System.Threading;
using System.Upgrade;
using System.Utilities;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Bank.Ledger;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;

codeunit 104000 "Upgrade - BaseApp"
{
    Subtype = Upgrade;
    Permissions =
        TableData "User Group Plan" = rimd,
        TableData "Cust. Ledger Entry" = rm;

    var
        EnvironmentInformation: Codeunit "Environment Information";
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
        NoOfRecordsInTableMsg: Label 'Table %1, number of records to upgrade: %2', Comment = '%1- table id, %2 - number of records';
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
        CreatePowerPagesAAdApplications();
        UpgradePowerBIOptin();
    end;

    trigger OnUpgradePerCompany()
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        ClearTemporaryTables();

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
        UpgradePowerBiReportUploads();
        UpgradeSearchEmail();
        UpgradeIntegrationTableMapping();
        UpgradeIntegrationFieldMapping();
        UpgradeAddExtraIntegrationFieldMappings();
        UpgradeWorkflowStepArgumentEventFilters();
        SetReviewRequiredOnBankPmtApplRules();

        UpgradeAPIs();
        UpgradeTemplates();
        AddPowerBIWorkspaces();
        UpgradePowerBiDisplayedElements();
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
        UpgradeCustomerVATLiable();
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
        UpgradeJournalTemplateNamesInSetupTables();
        UpgradeGLEntryJournalTemplateName();
        UpgradeGLRegisterJournalTemplateName();
        UpgradeGenJournalTemplates();
        UpgradeVATEntryJournalTemplateName();
        UpgradeBankAccLedgerEntryJournalTemplateName();
        UpgradeCustLedgerEntryJournalTemplateName();
        UpgradeEmplLedgerEntryJournalTemplateName();
        UpgradeVendLedgerEntryJournalTemplateName();
        UpgradePurchaseHeaderJournalTemplateName();
        UpgradeSalesHeaderJournalTemplateName();
        UpgradeServiceHeaderJournalTemplateName();
        UpgradeCustLedgEntryPmtDiscountPossible();
        UpgradeVendLedgEntryPmtDiscountPossible();
        UpgradeGenJournalLinePmtDiscountPossible();
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
        UpdateServiceLineOrderNo();
        UpgradeMapCurrencySymbol();
        UpgradeOptionMapping();
        UpdateProductionSourceCode();
        UpgradeICGLAccountNoInPostedGenJournalLine();
        UpgradePurchasesPayablesAndSalesReceivablesSetups();
        UpgradeLocationBinPolicySetups();
        UpgradeInventorySetupAllowInvtAdjmt();
        UpgradeGranularWarehouseHandlingSetup();
        UpgradeVATSetup();
#if not CLEAN22
        UpgradeTimesheetExperience();
#endif
        UpgradeVATSetupAllowVATDate();
    end;

    local procedure ClearTemporaryTables()
    var
        BinContentBuffer: Record "Bin Content Buffer";
        DocumentEntry: Record "Document Entry";
        EntrySummary: Record "Entry Summary";
#if not CLEAN23
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

#if not CLEAN23
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

    local procedure UpdateGenJournalBatchReferencedIds()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBalAccountNoOnJournalAPIUpgradeTag()) then
            exit;

        if GenJournalBatch.FindSet() then
            repeat
                GenJournalBatch.UpdateBalAccountId();
                if GenJournalBatch.Modify() then;
            until GenJournalBatch.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetBalAccountNoOnJournalAPIUpgradeTag());
    end;

    local procedure UpdateJobs()
    var
        Job: Record "Job";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddingIDToJobsUpgradeTag()) then
            exit;

        if Job.FindSet(true, false) then
            repeat
                if ISNULLGUID(Job.SystemId) then
                    Job.Modify();
            until Job.Next() = 0;
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetWorkflowWebhookWebServicesUpgradeTag()) then
            exit;

        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Entity", 'salesDocuments', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Line Entity", 'salesDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Entity", 'purchaseDocuments', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Line Entity", 'purchaseDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Entity", 'workflowSalesDocuments', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Sales Document Line Entity", 'workflowSalesDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Entity", 'workflowPurchaseDocuments', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Purchase Document Line Entity", 'workflowPurchaseDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Gen. Journal Batch Entity", 'workflowGenJournalBatches', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Gen. Journal Line Entity", 'workflowGenJournalLines', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Customer Entity", 'workflowCustomers', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Item Entity", 'workflowItems', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow - Vendor Entity", 'workflowVendors', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Workflow Webhook Subscriptions", 'workflowWebhookSubscriptions', true);
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Codeunit, CODEUNIT::"Workflow Webhook Subscription", 'WorkflowActionResponse', true);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetWorkflowWebhookWebServicesUpgradeTag());
    end;

    local procedure CreateExcelTemplateWebServices()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetExcelTemplateWebServicesUpgradeTag()) then
            exit;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLastUpdateInvoiceEntryNoUpgradeTag()) then
            exit;

        if CRMConnectionSetup.Get() then
            CRMSynchStatus."Last Update Invoice Entry No." := CRMConnectionSetup."Last Update Invoice Entry No."
        else
            CRMSynchStatus."Last Update Invoice Entry No." := 0;

        if CRMSynchStatus.Insert() then;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLastUpdateInvoiceEntryNoUpgradeTag());
    end;

    local procedure CopyIncomingDocumentURLsIntoOneFiled()
    var
        IncomingDocument: Record "Incoming Document";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIncomingDocumentURLUpgradeTag()) then
            exit;

        if IncomingDocument.FindSet() then
            repeat
                IncomingDocument.URL := IncomingDocument.URL1 + IncomingDocument.URL2 + IncomingDocument.URL3 + IncomingDocument.URL4;
                IncomingDocument.Modify();
            until IncomingDocument.Next() = 0;

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
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, PageID, ObjectName, true);
    end;

    local procedure UpgradeAPIs()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        APIDataUpgrade: Codeunit "API Data Upgrade";
    begin
        if UpgradeTag.HasUpgradeTag(APIDataUpgrade.GetDisableAPIDataUpgradesTag()) then
            if UpgradeTag.HasUpgradeTagSkipped(APIDataUpgrade.GetDisableAPIDataUpgradesTag(), CopyStr(CompanyName(), 1, 30)) then
                exit;

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
        UpgradeFixedAssetLocationId();
        UpgradeFixedAssetResponsibleEmployeeId();
    end;

    procedure UpgradeItemPostingGroups()
    var
        Item: Record "Item";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
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
            GenProdPostingGroupDataTransfer.AddFieldValue(GenProductPostingGroup.FieldNo("SystemId"), Item.FieldNo("Gen. Prod. Posting Group Id"));
            GenProdPostingGroupDataTransfer.AddJoin(GenProductPostingGroup.FieldNo(Code), Item.FieldNo("Gen. Prod. Posting Group"));
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

    local procedure UpgradeFixedAssetLocationId()
    var
        FixedAsset: Record "Fixed Asset";
        FALocation: Record "FA Location";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        BlankGuid: Guid;
        LocationIdDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFixedAssetLocationIdUpgradeTag()) then
            exit;

        FixedAsset.SetFilter("FA Location Id", '<>%1', BlankGuid);
        if FixedAsset.IsEmpty() then begin
            LocationIdDataTransfer.SetTables(Database::"FA Location", Database::"Fixed Asset");
            LocationIdDataTransfer.AddFieldValue(FALocation.FieldNo("SystemId"), FixedAsset.FieldNo("FA Location Id"));
            LocationIdDataTransfer.AddJoin(FALocation.FieldNo(Code), FixedAsset.FieldNo("Location Code"));
            LocationIdDataTransfer.UpdateAuditFields := false;
            LocationIdDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetFixedAssetLocationIdUpgradeTag());
    end;

    local procedure UpgradeFixedAssetResponsibleEmployeeId()
    var
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        BlankGuid: Guid;
        EmployeeIdDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFixedAssetResponsibleEmployeeIdUpgradeTag()) then
            exit;

        FixedAsset.SetFilter("Responsible Employee Id", '<>%1', BlankGuid);
        if FixedAsset.IsEmpty() then begin
            EmployeeIdDataTransfer.SetTables(Database::Employee, Database::"Fixed Asset");
            EmployeeIdDataTransfer.AddFieldValue(Employee.FieldNo("SystemId"), FixedAsset.FieldNo("Responsible Employee Id"));
            EmployeeIdDataTransfer.AddJoin(Employee.FieldNo("No."), FixedAsset.FieldNo("Responsible Employee"));
            EmployeeIdDataTransfer.UpdateAuditFields := false;
            EmployeeIdDataTransfer.CopyFields();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetFixedAssetResponsibleEmployeeIdUpgradeTag());
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesInvoiceEntityAggregateUpgradeTag()) then
            exit;

        if SalesInvoiceEntityAggregate.FINDSET(true, false) then
            repeat
                if SalesInvoiceEntityAggregate.Posted then begin
                    SalesInvoiceHeader.SetRange(SystemId, SalesInvoiceEntityAggregate.Id);
                    if SalesInvoiceHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(SalesInvoiceHeader);
                        TargetRecordRef.GETTABLE(SalesInvoiceEntityAggregate);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, true);
                    end;
                end else begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SetRange(SystemId, SalesInvoiceEntityAggregate.Id);
                    if SalesHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesInvoiceEntityAggregate);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, true);
                    end;
                end;
            until SalesInvoiceEntityAggregate.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchInvEntityAggregateUpgradeTag()) then
            exit;

        if PurchInvEntityAggregate.FINDSET(true, false) then
            repeat
                if PurchInvEntityAggregate.Posted then begin
                    PurchInvHeader.SetRange(SystemId, PurchInvEntityAggregate.Id);
                    if PurchInvHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(PurchInvHeader);
                        TargetRecordRef.GETTABLE(PurchInvEntityAggregate);
                        UpdatePurchaseDocumentFields(SourceRecordRef, TargetRecordRef, true, true);
                    end;
                end else begin
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
                    PurchaseHeader.SetRange(SystemId, PurchInvEntityAggregate.Id);
                    if PurchaseHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(PurchaseHeader);
                        TargetRecordRef.GETTABLE(PurchInvEntityAggregate);
                        UpdatePurchaseDocumentFields(SourceRecordRef, TargetRecordRef, true, true);
                    end;
                end;
            until PurchInvEntityAggregate.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesOrderEntityBufferUpgradeTag()) then
            exit;

        if SalesOrderEntityBuffer.FINDSET(true, false) then
            repeat
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange(SystemId, SalesOrderEntityBuffer.Id);
                if SalesHeader.FindFirst() then begin
                    SourceRecordRef.GETTABLE(SalesHeader);
                    TargetRecordRef.GETTABLE(SalesOrderEntityBuffer);
                    UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, true);
                end;
            until SalesOrderEntityBuffer.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesQuoteEntityBufferUpgradeTag()) then
            exit;

        if SalesQuoteEntityBuffer.FINDSET(true, false) then
            repeat
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SetRange(SystemId, SalesQuoteEntityBuffer.Id);
                if SalesHeader.FindFirst() then begin
                    SourceRecordRef.GETTABLE(SalesHeader);
                    TargetRecordRef.GETTABLE(SalesQuoteEntityBuffer);
                    UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, true);
                end;
            until SalesQuoteEntityBuffer.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesCrMemoEntityBufferUpgradeTag()) then
            exit;

        if SalesCrMemoEntityBuffer.FINDSET(true, false) then
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    if SalesCrMemoHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(SalesCrMemoHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, false);
                    end;
                end else begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    if SalesHeader.FindFirst() then begin
                        SourceRecordRef.GETTABLE(SalesHeader);
                        TargetRecordRef.GETTABLE(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentFields(SourceRecordRef, TargetRecordRef, true, true, false);
                    end;
                end;
            until SalesCrMemoEntityBuffer.Next() = 0;

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
        if SellTo then begin
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Sell-to Phone No.")) then
                Changed := true;
            if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FIELDNO("Sell-to E-Mail")) then
                Changed := true;
        end;
        if BillTo then begin
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
            CodeFieldRef := TargetRecordRef.Field(SalesOrderEntityBuffer.FIELDNO("Bill-to Customer No."));
            IdFieldRef := TargetRecordRef.Field(SalesOrderEntityBuffer.FIELDNO("Bill-to Customer Id"));
            OldId := IdFieldRef.Value;
            if Customer.Get(Format(CodeFieldRef.Value)) then
                NewId := Customer.SystemId
            else
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
        end;
        if ShipTo then begin
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
        end;
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
        if PayTo then begin
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
            CodeFieldRef := TargetRecordRef.Field(PurchInvEntityAggregate.FIELDNO("Pay-to Vendor No."));
            IdFieldRef := TargetRecordRef.Field(PurchInvEntityAggregate.FIELDNO("Pay-to Vendor Id"));
            OldId := IdFieldRef.Value;
            if Vendor.Get(Format(CodeFieldRef.Value)) then
                NewId := Vendor.SystemId
            else
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
            CodeFieldRef := TargetRecordRef.Field(PurchInvEntityAggregate.FIELDNO("Currency Code"));
            IdFieldRef := TargetRecordRef.Field(PurchInvEntityAggregate.FIELDNO("Currency Id"));
            OldId := IdFieldRef.Value;
            if Currency.Get(Format(CodeFieldRef.Value)) then
                NewId := Currency.SystemId
            else
                NewId := EmptyGuid;
            if OldId <> NewId then begin
                IdFieldRef.Value := NewId;
                Changed := true;
            end;
        end;
        if ShipTo then begin
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
        end;
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
        if TargetFieldRef.VALUE <> SourceFieldRef.VALUE then begin
            TargetFieldRef.VALUE := SourceFieldRef.VALUE;
            exit(true);
        end;
        exit(false);
    end;

    local procedure UpdateItemTrackingCodes()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemTrackingCodeUseExpirationDatesTag()) then
            exit;

        ItemTrackingCode.SetRange("Use Expiration Dates", false);
        if not ItemTrackingCode.IsEmpty() then
            // until now, expiration date was always ON, so let's reflect this
            ItemTrackingCode.MODIFYALL("Use Expiration Dates", true);

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag()) then
            exit;

        JobQueueEntry.SETFILTER("Error Message 2", '<>%1', '');
        if JobQueueEntry.FINDSET(true) then
            repeat
                JobQueueEntry."Error Message" := JobQueueEntry."Error Message" + JobQueueEntry."Error Message 2" +
                    JobQueueEntry."Error Message 3" + JobQueueEntry."Error Message 4";
                JobQueueEntry."Error Message 2" := '';
                JobQueueEntry."Error Message 3" := '';
                JobQueueEntry."Error Message 4" := '';
                JobQueueEntry.Modify();
            until JobQueueEntry.Next() = 0;

        JobQueueLogEntry.SETFILTER("Error Message 2", '<>%1', '');
        if JobQueueLogEntry.FINDSET(true) then
            repeat
                OldErrorMsg := JobQueueLogEntry."Error Message" + JobQueueLogEntry."Error Message 2" +
                  JobQueueLogEntry."Error Message 3" + JobQueueLogEntry."Error Message 4";
                JobQueueLogEntry."Error Message 2" := '';
                JobQueueLogEntry."Error Message 3" := '';
                JobQueueLogEntry."Error Message 4" := '';
                JobQueueLogEntry.Modify();
            until JobQueueLogEntry.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATRepSetupPeriodRemCalcUpgradeTag()) then
            exit;

        WITH VATReportSetup DO begin
            if not GET() then
                exit;
            if IsPeriodReminderCalculation() OR ("Period Reminder Time" = 0) then
                exit;

            DateFormulaText := StrSubstNo('<%1D>', "Period Reminder Time");
            EVALUATE("Period Reminder Calculation", DateFormulaText);
            "Period Reminder Time" := 0;

            if Modify() then;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATRepSetupPeriodRemCalcUpgradeTag());
    end;

    local procedure UpgradeStandardCustomerSalesCodes()
    var
        StandardSalesCode: Record "Standard Sales Code";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetStandardSalesCodeUpgradeTag()) then
            exit;

        if StandardSalesCode.FindSet() then
            repeat
                StandardCustomerSalesCode.SetRange(Code, StandardSalesCode.Code);
                StandardCustomerSalesCode.SetFilter("Currency Code", '<>%1', StandardSalesCode."Currency Code");
                StandardCustomerSalesCode.MODIFYALL("Currency Code", StandardSalesCode."Currency Code");
            until StandardSalesCode.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetStandardSalesCodeUpgradeTag());
    end;

    local procedure UpgradeStandardVendorPurchaseCode()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetStandardPurchaseCodeUpgradeTag()) then
            exit;

        if StandardPurchaseCode.FindSet() then
            repeat
                StandardVendorPurchaseCode.SetRange(Code, StandardPurchaseCode.Code);
                StandardVendorPurchaseCode.SetFilter("Currency Code", '<>%1', StandardPurchaseCode."Currency Code");
                StandardVendorPurchaseCode.MODIFYALL("Currency Code", StandardPurchaseCode."Currency Code");
            until StandardPurchaseCode.Next() = 0;

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

    local procedure UpgradePowerBIDisplayedElements()
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPowerBIDisplayedElementUpgradeTag()) then
            exit;

        if PowerBIReportConfiguration.FindSet() then
            repeat
                if not PowerBIDisplayedElement.Get(PowerBIReportConfiguration."User Security ID", PowerBIReportConfiguration.Context, Format(PowerBIReportConfiguration."Report ID"), PowerBIDisplayedElement.ElementType::Report) then begin
                    Clear(PowerBIDisplayedElement);
                    PowerBIDisplayedElement.Context := PowerBIReportConfiguration.Context;
                    PowerBIDisplayedElement.UserSID := PowerBIReportConfiguration."User Security ID";
                    PowerBIDisplayedElement.ElementId := Format(PowerBIReportConfiguration."Report ID");
                    PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
                    PowerBIDisplayedElement.ElementName := PowerBIReportConfiguration.ReportName;
                    PowerBIDisplayedElement.ElementEmbedUrl := PowerBIReportConfiguration.ReportEmbedUrl;
                    PowerBIDisplayedElement.WorkspaceID := PowerBIReportConfiguration."Workspace ID";
                    PowerBIDisplayedElement.WorkspaceName := PowerBIReportConfiguration."Workspace Name";
                    PowerBIDisplayedElement.ShowPanesInNormalMode := PowerBIReportConfiguration."Show Panes";
                    PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
                    PowerBIDisplayedElement.ReportPage := PowerBIReportConfiguration."Report Page";
                    PowerBIDisplayedElement.Insert();
                end;
            until PowerBIReportConfiguration.Next() = 0;

        if PowerBIUserConfiguration.FindSet() then
            repeat
                if not PowerBIContextSettings.Get(PowerBIUserConfiguration."User Security ID", PowerBIUserConfiguration."Page ID") then begin
                    Clear(PowerBIContextSettings);
                    PowerBIContextSettings.Context := PowerBIUserConfiguration."Page ID";
                    PowerBIContextSettings.UserSID := PowerBIUserConfiguration."User Security ID";
                    PowerBIContextSettings.SelectedElementId := Format(PowerBIUserConfiguration."Selected Report ID");
                    PowerBIContextSettings.SelectedElementType := PowerBIContextSettings.SelectedElementType::Report;
                    PowerBIContextSettings.LockToSelectedElement := PowerBIUserConfiguration."Lock to first visual";
                    PowerBIContextSettings.Insert();
                end;
            until PowerBIUserConfiguration.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPowerBIDisplayedElementUpgradeTag());
    end;

    local procedure UpgradePowerBiReportUploads()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        EmptyGuid: Guid;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPowerBIUploadsStatusUpgradeTag()) then
            exit;

        PowerBIReportUploads.SetRange("Report Upload Status", PowerBIReportUploads."Report Upload Status"::NotStarted);
        if PowerBIReportUploads.FindSet(true) then
            repeat
                case true of
                    PowerBIReportUploads."Needs Deletion":
                        PowerBIReportUploads."Report Upload Status" := PowerBIReportUploads."Report Upload Status"::PendingDeletion;
                    PowerBIReportUploads."Is Selection Done":
                        PowerBIReportUploads."Report Upload Status" := PowerBIReportUploads."Report Upload Status"::Completed;
                    PowerBIReportUploads."Report Embed Url" <> '':
                        PowerBIReportUploads."Report Upload Status" := PowerBIReportUploads."Report Upload Status"::DataRefreshed;
                    (PowerBIReportUploads."Import ID" <> EmptyGuid) and (not PowerBIReportUploads."Should Retry"):
                        PowerBIReportUploads."Report Upload Status" := PowerBIReportUploads."Report Upload Status"::Failed;
                // Else the status remains NotStarted
                end;

                if PowerBIReportUploads."Report Upload Status" <> PowerBIReportUploads."Report Upload Status"::NotStarted then
                    PowerBIReportUploads.Modify();
            until PowerBIReportUploads.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPowerBIUploadsStatusUpgradeTag());
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
        if SalespersonPurchaser.FindFirst() then
            repeat
                if SalespersonPurchaser."E-Mail" <> '' then begin
                    SalespersonPurchaser."Search E-Mail" := SalespersonPurchaser."E-Mail";
                    SalespersonPurchaser.Modify();
                end;
            until SalespersonPurchaser.Next() = 0;

        Contact.SetCurrentKey("Search E-Mail");
        Contact.SetRange("Search E-Mail", '');
        if Contact.FindFirst() then
            repeat
                if Contact."E-Mail" <> '' then begin
                    Contact."Search E-Mail" := Contact."E-Mail";
                    Contact.Modify();
                end;
            until Contact.Next() = 0;

        ContactAltAddress.SetCurrentKey("Search E-Mail");
        ContactAltAddress.SetRange("Search E-Mail", '');
        if ContactAltAddress.FindFirst() then
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
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ModifyDefaultDimension: Record "Default Dimension";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        BlankGuid: Guid;
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
            Clear(DefaultDimensionDataTransfer);
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetFilter(DimensionId, '%1', BlankGuid);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::Dimension, Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddFieldValue(Dimension.FieldNo(SystemId), DefaultDimension.FieldNo(DimensionId));
            DefaultDimensionDataTransfer.AddJoin(Dimension.FieldNo(Code), DefaultDimension.FieldNo("Dimension Code"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
            Clear(DefaultDimensionDataTransfer);
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetFilter(DimensionValueId, '%1', BlankGuid);
        if not DefaultDimension.IsEmpty() then begin
            DefaultDimensionDataTransfer.SetTables(Database::"Dimension Value", Database::"Default Dimension");
            DefaultDimensionDataTransfer.AddFieldValue(DimensionValue.FieldNo(SystemId), DefaultDimension.FieldNo(DimensionValueId));
            DefaultDimensionDataTransfer.AddJoin(DimensionValue.FieldNo("Dimension Code"), DefaultDimension.FieldNo("Dimension Code"));
            DefaultDimensionDataTransfer.AddJoin(DimensionValue.FieldNo(Code), DefaultDimension.FieldNo("Dimension Value Code"));
            DefaultDimensionDataTransfer.UpdateAuditFields := false;
            DefaultDimensionDataTransfer.CopyFields();
        end;

        Clear(DefaultDimension);
        DefaultDimension.SetFilter(ParentId, '%1', BlankGuid);
        if DefaultDimension.FindSet() then
            repeat
                ModifyDefaultDimension := DefaultDimension;
                if ModifyDefaultDimension.UpdateParentId() then
                    ModifyDefaultDimension.Modify();
            until DefaultDimension.Next() = 0;

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
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShipmentMethodUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesOrderShipmentMethod();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShipmentMethodUpgradeTag());
    end;

    local procedure UpgradeSalesCrMemoShipmentMethod()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShipmentMethodUpgradeTag()) then
            exit;

        APIDataUpgrade.UpgradeSalesCrMemoShipmentMethod();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShipmentMethodUpgradeTag());
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
#if not CLEAN23
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
#else
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then 
            exit;
        AADApplicationSetup.CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
#endif
    end;

    local procedure UpgradeIntegrationTableMapping()
    begin
        UpgradeIntegrationTableMappingUncoupleCodeunitId();
        UpgradeIntegrationTableMappingCouplingCodeunitId();
        UpgradeIntegrationTableMappingFilterForOpportunities();
    end;

    local procedure UpgradeAddExtraIntegrationFieldMappings()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        RunUpgradeLogic: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddExtraIntegrationFieldMappingsUpgradeTag()) then
            exit;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Is Enabled" then
                RunUpgradeLogic := true;

        if not RunUpgradeLogic then
            if CRMConnectionSetup.Get() then
                if CRMConnectionSetup."Is Enabled" then
                    RunUpgradeLogic := true;

        if RunUpgradeLogic then
            CDSSetupDefaults.AddExtraIntegrationFieldMappings();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddExtraIntegrationFieldMappingsUpgradeTag());
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
        InStream: InStream;
        OutStream: OutStream;
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
                    InTempBlob.CreateInStream(InStream, FromEncoding);
                    InStream.Read(Value);

                    // Write the value in UTF8
                    OutTempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.Write(Value);

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
        OnUpdateNewCustomerTemplateFromConversionTemplateOnBeforeModify(CustomerTempl, CustomerTemplate);
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetIntrastatJnlLinePartnerIDUpgradeTag()) then
            exit;

        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        if IntrastatJnlLine.FindSet() then
            repeat
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDimSetEntryGlobalDimNoUpgradeTag()) then
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchaseOrderEntityBufferUpgradeTag()) then
            exit;

        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if PurchaseHeader.FindSet() then
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag()) then
            exit;

        ImageName := PowerBIEmbeddedReportPart.GetOptinImageName();

        TargetClientType := ClientType::Phone;
        if not MediaRepository.Get(ImageName, TargetClientType) then
            if not UpdatePowerBIOptinFromExistingImage(TargetClientType) then
                Session.LogMessage('0000EH1', StrSubstNo(FailedToUpdatePowerBIImageTxt, TargetClientType), Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');

        TargetClientType := ClientType::Tablet;
        if not MediaRepository.Get(ImageName, TargetClientType) then
            if not UpdatePowerBIOptinFromExistingImage(TargetClientType) then
                Session.LogMessage('0000EH2', StrSubstNo(FailedToUpdatePowerBIImageTxt, TargetClientType), Verbosity::Warning, DataClassification::SystemMetadata,
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
        Session.LogMessage('0000EH4', StrSubstNo(AttemptingPowerBIUpdateTxt, targetClientType), Verbosity::Normal, DataClassification::SystemMetadata,
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveSmartListManualSetupEntryUpgradeTag()) then
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserTaskDescriptionToUTF8UpgradeTag()) then
            exit;

        ChangeEncodingToUTF8(Database::"User Task", UserTask.FieldNo(Description), TextEncoding::Windows);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserTaskDescriptionToUTF8UpgradeTag());
    end;

    local procedure GetSafeRecordCountForSaaSUpgrade(): Integer
    begin
        exit(300000);
    end;

    local procedure UpgradeCustomerVATLiable()
    var
        Customer: Record Customer;
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        UpgradeTag: Codeunit "Upgrade Tag";
        CustomerDataTransfer: DataTransfer;
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCustomerVATLiableTag()) then
            exit;

        Customer.SetRange("VAT liable", true);
        if not Customer.IsEmpty() then
            exit;

        CustomerDataTransfer.SetTables(Database::Customer, Database::Customer);
        CustomerDataTransfer.AddConstantValue(true, Customer.FieldNo("VAT Liable"));
        CustomerDataTransfer.UpdateAuditFields := false;
        CustomerDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCustomerVATLiableTag());
    end;

    local procedure UpgradeCreditTransferIBAN()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreditTransferIBANUpgradeTag()) then
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
        CompanyInformation: Record "Company Information";
        ICSetup: Record "IC Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICSetupUpgradeTag()) then
            exit;

        if not CompanyInformation.Get() then
            exit;

        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;

        ICSetup."IC Partner Code" := CompanyInformation."IC Partner Code";
        ICSetup."IC Inbox Type" := CompanyInformation."IC Inbox Type";
        ICSetup."IC Inbox Details" := CompanyInformation."IC Inbox Details";
        ICSetup."Auto. Send Transactions" := CompanyInformation."Auto. Send Transactions";
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

    local procedure UpgradeGLEntryJournalTemplateName()
    var
        GLEntry: Record "G/L Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GLEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGLEntryJournalTemplateNameUpgradeTag()) then
            exit;

        GLEntry.SetFilter("Journal Templ. Name", '<>%1', '');
        if not GLEntry.IsEmpty() then
            exit;

        GLEntryDataTransfer.SetTables(Database::"G/L Entry", Database::"G/L Entry");
        GLEntryDataTransfer.AddSourceFilter(GLEntry.FieldNo("Journal Template Name"), '<>%1', '');
        GLEntryDataTransfer.AddFieldValue(GLEntry.FieldNo("Journal Template Name"), GLEntry.FieldNo("Journal Templ. Name"));
        GLEntryDataTransfer.UpdateAuditFields := false;
        GLEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeGLRegisterJournalTemplateName()
    var
        GLRegister: Record "G/L Register";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GLRegisterDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGLRegisterJournalTemplateNameUpgradeTag()) then
            exit;

        GLRegister.SetFilter("Journal Templ. Name", '<>%1', '');
        if not GLRegister.IsEmpty() then
            exit;

        GLRegisterDataTransfer.SetTables(Database::"G/L Register", Database::"G/L Register");
        GLRegisterDataTransfer.AddSourceFilter(GLRegister.FieldNo("Journal Template Name"), '<>%1', '');
        GLRegisterDataTransfer.AddFieldValue(GLRegister.FieldNo("Journal Template Name"), GLRegister.FieldNo("Journal Templ. Name"));
        GLRegisterDataTransfer.UpdateAuditFields := false;
        GLRegisterDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLRegisterJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeGenJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGenJournalTemplateDatesUpgradeTag()) then
            exit;

        GenJournalTemplate.SetLoadFields(
            "Allow Posting Date From", "Allow Posting Date To", "Allow Posting From", "Allow Posting To");
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Gen. Journal Template", GenJournalTemplate.Count()) then
                exit;
        if GenJournalTemplate.FindSet(true) then
            repeat
                if (GenJournalTemplate."Allow Posting From" <> 0D) or (GenJournalTemplate."Allow Posting To" <> 0D) then begin
                    GenJournalTemplate."Allow Posting Date From" := GenJournalTemplate."Allow Posting From";
                    GenJournalTemplate."Allow Posting Date To" := GenJournalTemplate."Allow Posting To";
                    GenJournalTemplate.Modify();
                end;
            until GenJournalTemplate.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGenJournalTemplateDatesUpgradeTag());
    end;

    local procedure UpgradeJournalTemplateNamesInSetupTables()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGenJournalTemplateNamesSetupUpgradeTag()) then
            exit;

        if not GeneralLedgerSetup.Get() then
            exit;

        GeneralLedgerSetup."Bank Acc. Recon. Template Name" := GeneralLedgerSetup."Payment Recon. Template Name";
        GeneralLedgerSetup."Apply Jnl. Template Name" := GeneralLedgerSetup."Jnl. Templ. Name for Applying";
        GeneralLedgerSetup."Apply Jnl. Batch Name" := GeneralLedgerSetup."Jnl. Batch Name for Applying";
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := true;
        GeneralLedgerSetup.Modify();

        if InventorySetup.Get() then
            if (InventorySetup."Jnl. Templ. Name Cost Posting" <> '') or
                (InventorySetup."Jnl. Batch Name Cost Posting" <> '')
            then begin
                InventorySetup."Invt. Cost Jnl. Template Name" := InventorySetup."Jnl. Templ. Name Cost Posting";
                InventorySetup."Invt. Cost Jnl. Batch Name" := InventorySetup."Jnl. Batch Name Cost Posting";
                InventorySetup.Modify();
            end;

        if SalesReceivablesSetup.Get() then
            if (SalesReceivablesSetup."IC Jnl. Templ. Sales Invoice" <> '') or (SalesReceivablesSetup."IC Jnl. Templ. Sales Cr. Memo" <> '') or
                (SalesReceivablesSetup."Journal Templ. Sales Invoice" <> '') or (SalesReceivablesSetup."Journal Templ. Sales Cr. Memo" <> '') or
                (SalesReceivablesSetup."Jnl. Templ. Prep. S. Inv." <> '') or (SalesReceivablesSetup."Jnl. Templ. Prep. S. Cr. Memo" > '')
            then begin
                SalesReceivablesSetup."S. Invoice Template Name" := SalesReceivablesSetup."Journal Templ. Sales Invoice";
                SalesReceivablesSetup."S. Cr. Memo Template Name" := SalesReceivablesSetup."Journal Templ. Sales Cr. Memo";
                SalesReceivablesSetup."S. Prep. Inv. Template Name" := SalesReceivablesSetup."Jnl. Templ. Prep. S. Inv.";
                SalesReceivablesSetup."S. Prep. Inv. Template Name" := SalesReceivablesSetup."Jnl. Templ. Prep. S. Cr. Memo";
                SalesReceivablesSetup."IC Sales Invoice Template Name" := SalesReceivablesSetup."IC Jnl. Templ. Sales Invoice";
                SalesReceivablesSetup."IC Sales Cr. Memo Templ. Name" := SalesReceivablesSetup."IC Jnl. Templ. Sales Cr. Memo";
                SalesReceivablesSetup.Modify();
            end;

        if PurchasesPayablesSetup.Get() then
            if (PurchasesPayablesSetup."Journal Templ. Purch. Invoice" <> '') or (PurchasesPayablesSetup."Journal Templ. Purch. Cr. Memo" <> '') or
                (PurchasesPayablesSetup."Jnl. Templ. Prep. P. Inv." <> '') or (PurchasesPayablesSetup."Jnl. Templ. Prep. P. Cr. Memo" <> '') or
                (PurchasesPayablesSetup."IC Jnl. Templ. Purch. Invoice" <> '') or (PurchasesPayablesSetup."IC Jnl. Templ. Purch. Cr. Memo" <> '')
            then begin
                PurchasesPayablesSetup."P. Invoice Template Name" := PurchasesPayablesSetup."Journal Templ. Purch. Invoice";
                PurchasesPayablesSetup."P. Cr. Memo Template Name" := PurchasesPayablesSetup."Journal Templ. Purch. Cr. Memo";
                PurchasesPayablesSetup."P. Prep. Inv. Template Name" := PurchasesPayablesSetup."Jnl. Templ. Prep. P. Inv.";
                PurchasesPayablesSetup."P. Prep. Cr.Memo Template Name" := PurchasesPayablesSetup."Jnl. Templ. Prep. P. Cr. Memo";
                PurchasesPayablesSetup."IC Purch. Invoice Templ. Name" := PurchasesPayablesSetup."IC Jnl. Templ. Purch. Invoice";
                PurchasesPayablesSetup."IC Purch. Cr. Memo Templ. Name" := PurchasesPayablesSetup."IC Jnl. Templ. Purch. Cr. Memo";
                PurchasesPayablesSetup.Modify();
            end;

        if ServiceMgtSetup.Get() then
            if (ServiceMgtSetup."Jnl. Templ. Serv. Inv." <> '') or (ServiceMgtSetup."Jnl. Templ. Serv. CM" <> '') or
                (ServiceMgtSetup."Jnl. Templ. Serv. Contr. Inv." <> '') or (ServiceMgtSetup."Jnl. Templ. Serv. Contr. CM" <> '')
            then begin
                ServiceMgtSetup."Serv. Inv. Template Name" := ServiceMgtSetup."Jnl. Templ. Serv. Inv.";
                ServiceMgtSetup."Serv. Cr. Memo Templ. Name" := ServiceMgtSetup."Jnl. Templ. Serv. Contr. Inv.";
                ServiceMgtSetup."Serv. Contr. Inv. Templ. Name" := ServiceMgtSetup."Jnl. Templ. Serv. Contr. CM";
                ServiceMgtSetup."Serv. Contr. Cr.M. Templ. Name" := ServiceMgtSetup."Jnl. Templ. Serv. CM";
                ServiceMgtSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGenJournalTemplateNamesSetupUpgradeTag());
    end;

    local procedure UpgradeVATEntryJournalTemplateName()
    var
        VATEntry: Record "VAT Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        VATEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATEntryJournalTemplateNameUpgradeTag()) then
            exit;

        VATEntry.SetRange("Journal Templ. Name", '<>%1', '');
        if not VATEntry.IsEmpty() then
            exit;

        VATEntryDataTransfer.SetTables(Database::"VAT Entry", Database::"VAT Entry");
        VATEntryDataTransfer.AddSourceFilter(VATEntry.FieldNo("Journal Template Name"), '<>%1', '');
        VATEntryDataTransfer.AddFieldValue(VATEntry.FieldNo("Journal Template Name"), VATEntry.FieldNo("Journal Templ. Name"));
        VATEntryDataTransfer.UpdateAuditFields := false;
        VATEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeBankAccLedgerEntryJournalTemplateName()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BankAccountLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBankAccountLedgerEntryJournalTemplateNameUpgradeTag()) then
            exit;

        BankAccountLedgerEntry.SetRange("Journal Templ. Name", '<>%1', '');
        if not BankAccountLedgerEntry.IsEmpty() then
            exit;

        BankAccountLedgerEntryDataTransfer.SetTables(Database::"Bank Account Ledger Entry", Database::"Bank Account Ledger Entry");
        BankAccountLedgerEntryDataTransfer.AddSourceFilter(BankAccountLedgerEntry.FieldNo("Journal Template Name"), '<>%1', '');
        BankAccountLedgerEntryDataTransfer.AddFieldValue(BankAccountLedgerEntry.FieldNo("Journal Template Name"), BankAccountLedgerEntry.FieldNo("Journal Templ. Name"));
        BankAccountLedgerEntryDataTransfer.UpdateAuditFields := false;
        BankAccountLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetBankAccountLedgerEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeCustLedgerEntryJournalTemplateName()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        CustLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryJournalTemplateNameUpgradeTag()) then
            exit;

        CustLedgerEntry.SetRange("Journal Templ. Name", '<>%1', '');
        if not CustLedgerEntry.IsEmpty() then
            exit;

        CustLedgerEntryDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
        CustLedgerEntryDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Journal Template Name"), '<>%1', '');
        CustLedgerEntryDataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Journal Template Name"), CustLedgerEntry.FieldNo("Journal Templ. Name"));
        CustLedgerEntryDataTransfer.UpdateAuditFields := false;
        CustLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeEmplLedgerEntryJournalTemplateName()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        EmployeeLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetEmplLedgerEntryJournalTemplateNameUpgradeTag()) then
            exit;

        EmployeeLedgerEntry.SetRange("Journal Templ. Name", '<>%1', '');
        if not EmployeeLedgerEntry.IsEmpty() then
            exit;

        EmployeeLedgerEntryDataTransfer.SetTables(Database::"Employee Ledger Entry", Database::"Employee Ledger Entry");
        EmployeeLedgerEntryDataTransfer.AddSourceFilter(EmployeeLedgerEntry.FieldNo("Journal Template Name"), '<>%1', '');
        EmployeeLedgerEntryDataTransfer.AddFieldValue(EmployeeLedgerEntry.FieldNo("Journal Template Name"), EmployeeLedgerEntry.FieldNo("Journal Templ. Name"));
        EmployeeLedgerEntryDataTransfer.UpdateAuditFields := false;
        EmployeeLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEmplLedgerEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeVendLedgerEntryJournalTemplateName()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        VendLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVendLedgerEntryJournalTemplateNameUpgradeTag()) then
            exit;

        VendLedgerEntry.SetRange("Journal Templ. Name", '<>%1', '');
        if not VendLedgerEntry.IsEmpty() then
            exit;

        VendLedgerEntryDataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Vendor Ledger Entry");
        VendLedgerEntryDataTransfer.AddSourceFilter(VendLedgerEntry.FieldNo("Journal Template Name"), '<>%1', '');
        VendLedgerEntryDataTransfer.AddFieldValue(VendLedgerEntry.FieldNo("Journal Template Name"), VendLedgerEntry.FieldNo("Journal Templ. Name"));
        VendLedgerEntryDataTransfer.UpdateAuditFields := false;
        VendLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVendLedgerEntryJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeSalesHeaderJournalTemplateName()
    var
        SalesHeader: Record "Sales Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        SalesHeaderDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesHeaderJournalTemplateNameUpgradeTag()) then
            exit;

        SalesHeader.SetRange("Journal Templ. Name", '<>%1', '');
        if not SalesHeader.IsEmpty() then
            exit;

        SalesHeaderDataTransfer.SetTables(Database::"Sales Header", Database::"Sales Header");
        SalesHeaderDataTransfer.AddSourceFilter(SalesHeader.FieldNo("Journal Template Name"), '<>%1', '');
        SalesHeaderDataTransfer.AddFieldValue(SalesHeader.FieldNo("Journal Template Name"), SalesHeader.FieldNo("Journal Templ. Name"));
        SalesHeaderDataTransfer.UpdateAuditFields := false;
        SalesHeaderDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesHeaderJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeServiceHeaderJournalTemplateName()
    var
        ServiceHeader: Record "Service Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ServiceHeaderDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServiceHeaderJournalTemplateNameUpgradeTag()) then
            exit;

        ServiceHeader.SetRange("Journal Templ. Name", '<>%1', '');
        if not ServiceHeader.IsEmpty() then
            exit;

        ServiceHeaderDataTransfer.SetTables(Database::"Service Header", Database::"Service Header");
        ServiceHeaderDataTransfer.AddSourceFilter(ServiceHeader.FieldNo("Journal Template Name"), '<>%1', '');
        ServiceHeaderDataTransfer.AddFieldValue(ServiceHeader.FieldNo("Journal Template Name"), ServiceHeader.FieldNo("Journal Templ. Name"));
        ServiceHeaderDataTransfer.UpdateAuditFields := false;
        ServiceHeaderDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetServiceHeaderJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradePurchaseHeaderJournalTemplateName()
    var
        PurchaseHeader: Record "Purchase Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PurchaseHeaderDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseHeaderJournalTemplateNameUpgradeTag()) then
            exit;

        PurchaseHeader.SetRange("Journal Templ. Name", '<>%1', '');
        if not PurchaseHeader.IsEmpty() then
            exit;

        PurchaseHeaderDataTransfer.SetTables(Database::"Purchase Header", Database::"Purchase Header");
        PurchaseHeaderDataTransfer.AddSourceFilter(PurchaseHeader.FieldNo("Journal Template Name"), '<>%1', '');
        PurchaseHeaderDataTransfer.AddFieldValue(PurchaseHeader.FieldNo("Journal Template Name"), PurchaseHeader.FieldNo("Journal Templ. Name"));
        PurchaseHeaderDataTransfer.UpdateAuditFields := false;
        PurchaseHeaderDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaseHeaderJournalTemplateNameUpgradeTag());
    end;

    local procedure UpgradeCustLedgEntryPmtDiscountPossible()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        CustLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryPmtDiscPossibleUpgradeTag()) then
            exit;

        CustLedgerEntry.SetFilter("Orig. Pmt. Disc. Possible(LCY)", '<>%1', 0);
        if not CustLedgerEntry.IsEmpty() then
            exit;

        CustLedgerEntryDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
        CustLedgerEntryDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Org. Pmt. Disc. Possible (LCY)"), '<>%1', 0);
        CustLedgerEntryDataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Org. Pmt. Disc. Possible (LCY)"), CustLedgerEntry.FieldNo("Orig. Pmt. Disc. Possible(LCY)"));
        CustLedgerEntryDataTransfer.UpdateAuditFields := false;
        CustLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCustLedgerEntryPmtDiscPossibleUpgradeTag());
    end;

    local procedure UpgradeVendLedgEntryPmtDiscountPossible()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        VendLedgerEntryDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVendLedgerEntryPmtDiscPossibleUpgradeTag()) then
            exit;

        VendLedgerEntry.SetFilter("Orig. Pmt. Disc. Possible(LCY)", '<>%1', 0);
        if not VendLedgerEntry.IsEmpty() then
            exit;

        VendLedgerEntryDataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Vendor Ledger Entry");
        VendLedgerEntryDataTransfer.AddSourceFilter(VendLedgerEntry.FieldNo("Org. Pmt. Disc. Possible (LCY)"), '<>%1', 0);
        VendLedgerEntryDataTransfer.AddFieldValue(VendLedgerEntry.FieldNo("Org. Pmt. Disc. Possible (LCY)"), VendLedgerEntry.FieldNo("Orig. Pmt. Disc. Possible(LCY)"));
        VendLedgerEntryDataTransfer.UpdateAuditFields := false;
        VendLedgerEntryDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVendLedgerEntryPmtDiscPossibleUpgradeTag());
    end;

    local procedure UpgradeGenJournalLinePmtDiscountPossible()
    var
        GenJournalLine: Record "Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGenJournalLinePmtDiscPossibleUpgradeTag()) then
            exit;

        GenJournalLine.SetFilter("Orig. Pmt. Disc. Possible(LCY)", '<>%1', 0);
        if not GenJournalLine.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"Gen. Journal Line", Database::"Gen. Journal Line");
        GenJournalLineDataTransfer.AddSourceFilter(GenJournalLine.FieldNo("Org. Pmt. Disc. Possible (LCY)"), '<>%1', 0);
        GenJournalLineDataTransfer.AddFieldValue(GenJournalLine.FieldNo("Original Pmt. Disc. Possible"), GenJournalLine.FieldNo("Orig. Pmt. Disc. Possible"));
        GenJournalLineDataTransfer.AddFieldValue(GenJournalLine.FieldNo("Org. Pmt. Disc. Possible (LCY)"), GenJournalLine.FieldNo("Orig. Pmt. Disc. Possible(LCY)"));
        GenJournalLineDataTransfer.UpdateAuditFields := false;
        GenJournalLineDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGenJournalLinePmtDiscPossibleUpgradeTag());
    end;

    local procedure LogTelemetryForManyRecords(TableNo: Integer; NoOfRecords: Integer): Boolean;
    begin
        Session.LogMessage(
            '0000G46', StrSubstNo(NoOfRecordsInTableMsg, TableNo, NoOfRecords),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'AL SaaS Upgrade');
        exit(NoOfRecords > GetSafeRecordCountForSaaSUpgrade());
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

    local procedure UpdateServiceLineOrderNo()
    var
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServiceLineOrderNoUpgradeTag()) then
            exit;

        ServiceLine.SetLoadFields("Shipment No.", "Shipment Line No.");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetFilter("Shipment No.", '<>%1', '');
        ServiceLine.SetFilter("Shipment Line No.", '<>%1', 0);
        if ServiceLine.FindSet(true) then
            repeat
                ServiceShipmentLine.SetLoadFields("Order No.");
                if ServiceShipmentLine.Get(ServiceLine."Shipment No.", ServiceLine."Shipment Line No.") then begin
                    ServiceLine."Order No." := ServiceShipmentLine."Order No.";
                    ServiceLine.Modify();
                end;
            until ServiceLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetServiceLineOrderNoUpgradeTag());
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

    local procedure UpgradePurchasesPayablesAndSalesReceivablesSetups()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchasesPayablesAndSalesReceivablesSetupsUpgradeTag()) then
            exit;

        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup.Validate("Link Doc. Date to Posting Date", true);
            PurchasesPayablesSetup.Modify();
        end;
        if SalesReceivablesSetup.Get() then begin
            SalesReceivablesSetup.Validate("Link Doc. Date to Posting Date", true);
            SalesReceivablesSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchasesPayablesAndSalesReceivablesSetupsUpgradeTag());
    end;

    local procedure UpgradeLocationBinPolicySetups()
    var
        Location: Record Location;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        LocationDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLocationBinPolicySetupsUpgradeTag()) then
            exit;

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Directed Put-away and Pick"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Pick Bin Policy"::"Bin Ranking", Location.FieldNo("Pick Bin Policy"));
        LocationDataTransfer.AddConstantValue("Put-away Bin Policy"::"Put-away Template", Location.FieldNo("Put-away Bin Policy"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Directed Put-away and Pick"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Bin Mandatory"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Pick Bin Policy"::"Default Bin", Location.FieldNo("Pick Bin Policy"));
        LocationDataTransfer.AddConstantValue("Put-away Bin Policy"::"Default Bin", Location.FieldNo("Put-away Bin Policy"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Directed Put-away and Pick"), '=%1', false);
        LocationDataTransfer.AddConstantValue(false, Location.FieldNo("Always Create Pick Line"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Directed Put-away and Pick"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Put-away"), '=%1', true);
        LocationDataTransfer.AddConstantValue(true, Location.FieldNo("Always Create Put-away Line"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLocationBinPolicySetupsUpgradeTag());
    end;

    local procedure UpgradeInventorySetupAllowInvtAdjmt()
    var
        InventorySetup: Record "Inventory Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAllowInventoryAdjmtUpgradeTag()) then
            exit;

        if InventorySetup.Get() then begin
            InventorySetup."Allow Inventory Adjustment" := ApplicationAreaMgmtFacade.IsFoundationEnabled();
            InventorySetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAllowInventoryAdjmtUpgradeTag());
    end;

    local procedure UpgradeGranularWarehouseHandlingSetup()
    var
        Location: Record Location;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        LocationDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLocationGranularWarehouseHandlingSetupsUpgradeTag()) then
            exit;

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Pick"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Shipment"), '=%1', false);
        LocationDataTransfer.AddConstantValue("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Prod. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Asm. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Job Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Job Consump. Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Pick"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Shipment"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Prod. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Asm. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Job Consump. Whse. Handling"::"Warehouse Pick (optional)", Location.FieldNo("Job Consump. Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Pick"), '=%1', true);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Shipment"), '=%1', false);
        LocationDataTransfer.AddConstantValue("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement", Location.FieldNo("Prod. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Asm. Consump. Whse. Handling"::"Inventory Movement", Location.FieldNo("Asm. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Job Consump. Whse. Handling"::"Inventory Pick", Location.FieldNo("Job Consump. Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Pick"), '=%1', true);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Shipment"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location.FieldNo("Prod. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location.FieldNo("Asm. Consump. Whse. Handling"));
        LocationDataTransfer.AddConstantValue("Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location.FieldNo("Job Consump. Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Put-away"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Receive"), '=%1', false);
        LocationDataTransfer.AddConstantValue("Prod. Output Whse. Handling"::"No Warehouse Handling", Location.FieldNo("Prod. Output Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Put-away"), '=%1', false);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Receive"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Prod. Output Whse. Handling"::"No Warehouse Handling", Location.FieldNo("Prod. Output Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Put-away"), '=%1', true);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Receive"), '=%1', true);
        LocationDataTransfer.AddConstantValue("Prod. Output Whse. Handling"::"No Warehouse Handling", Location.FieldNo("Prod. Output Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        LocationDataTransfer.SetTables(Database::Location, Database::Location);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Put-away"), '=%1', true);
        LocationDataTransfer.AddSourceFilter(Location.FieldNo("Require Receive"), '=%1', false);
        LocationDataTransfer.AddConstantValue("Prod. Output Whse. Handling"::"Inventory Put-away", Location.FieldNo("Prod. Output Whse. Handling"));
        LocationDataTransfer.CopyFields();
        Clear(LocationDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLocationGranularWarehouseHandlingSetupsUpgradeTag());
    end;

    local procedure CreatePowerPagesAAdApplications()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        AADApplicationSetup: Codeunit "AAD Application Setup";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultPowerPagesAADApplicationsTag()) then
            exit;
        AADApplicationSetup.CreatePowerPagesAAdApplications();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultPowerPagesAADApplicationsTag());
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

    local procedure UpgradeVATSetupAllowVATDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATSetup: Record "VAT Setup";
        UserSetup: Record "User Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInfo: Codeunit "Environment Information";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        DataTransfer: DataTransfer;
        CountryCode: Text;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATSetupAllowVATDateTag()) then
            exit;

        CountryCode := EnvironmentInfo.GetApplicationFamily();
        if CountryCode in ['US', 'CA'] then begin
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATSetupAllowVATDateTag());
            exit;
        end;

        if not GeneralLedgerSetup.Get() then
            exit;

        if not VATSetup.Get() then
            VATSetup.Insert();

        if not UserSetup.Get() then
            UserSetup.Insert();

        if (UserSetup."Allow VAT Date From" <> 0D) or (UserSetup."Allow VAT Date To" <> 0D) then
            exit;

        if (VATSetup."Allow VAT Date From" <> 0D) or (VATSetup."Allow VAT Date To" <> 0D) then
            exit;

        VATSetup."Allow VAT Date From" := GeneralLedgerSetup."Allow Posting From";
        VATSetup."Allow VAT Date To" := GeneralLedgerSetup."Allow Posting To";
        VATSetup.Modify();

        DataTransfer.SetTables(Database::"User Setup", Database::"User Setup");
        DataTransfer.AddFieldValue(UserSetup.FieldNo("Allow Posting From"), UserSetup.FieldNo("Allow VAT Date From"));
        DataTransfer.AddFieldValue(UserSetup.FieldNo("Allow Posting To"), UserSetup.FieldNo("Allow VAT Date To"));
        DataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATSetupAllowVATDateTag());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNewCustomerTemplateFromConversionTemplateOnBeforeModify(var CustomerTempl: Record "Customer Templ."; CustomerTemplate: Record "Customer Template")
    begin
    end;

}
