// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft;
using Microsoft.AccountantPortal;
using Microsoft.API;
using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Reports;
using Microsoft.Assembly.Setup;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.Booking;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.RoleCenters;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension.Correction;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.Payroll;
using Microsoft.Finance.RoleCenters;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Task;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Integration.SyncEngine;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
#if not CLEAN23
using Microsoft.Projects.Project.Pricing;
#endif
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
#if not CLEAN23
using Microsoft.Projects.Resources.Pricing;
#endif
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.RoleCenters;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
#if not CLEAN23
using Microsoft.Purchases.Pricing;
#endif
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.RoleCenters;
using Microsoft.Sales.Setup;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Service.RoleCenters;
using Microsoft.Service.Setup;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.RoleCenters;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.AI;
using System.Apps;
using System.Automation;
using System.Azure.Identity;
using System.DataAdministration;
using System.Device;
using System.Diagnostics;
using System.Reflection;
using System.EMail;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.PowerBI;
using System.IO;
using System.Privacy;
using System.Globalization;
using System.Security;
using System.Security.AccessControl;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Security.User;
using System.TestTools;
using System.TestTools.TestRunner;
using System.Text;
using System.Threading;
using System.Tooling;
using System.Visualization;
using System.Utilities;
using System.Xml;

codeunit 1751 "Data Classification Eval. Data"
{
    procedure CreateEvaluationData()
    var
        Company: Record Company;
        "Field": Record "Field";
        DataSensitivity: Record "Data Sensitivity";
        TableMetadata: Record "Table Metadata";
        DataClassEvalDataCountry: Codeunit "Data Class. Eval. Data Country";
    begin
        if not Company.Get(CompanyName) then
            exit;

        if not Company."Evaluation Company" then
            exit;

        Field.SetFilter(DataClassification, '%1|%2|%3',
            Field.DataClassification::CustomerContent,
            Field.DataClassification::EndUserIdentifiableInformation,
            Field.DataClassification::EndUserPseudonymousIdentifiers);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);

        if Field.FindSet() then
            repeat
                DataSensitivity."Company Name" := CompanyName;
                DataSensitivity."Table No" := Field.TableNo;
                DataSensitivity."Field No" := Field."No.";
                DataSensitivity."Data Sensitivity" := DataSensitivity."Data Sensitivity"::Unclassified;
                if DataSensitivity.Insert() then;
            until Field.Next() = 0;

        ClassifyTablesPart1();
        ClassifyTablesPart2();
        ClassifyTablesPart3();

        ClassifyTablesToNormalPart1();
        ClassifyTablesToNormalPart2();
        ClassifyTablesToNormalPart3();
        ClassifyTablesToNormalPart4();
        ClassifyTablesToNormalPart5();
        ClassifyTablesToNormalPart6();
        ClassifyTablesToNormalPart7();
        ClassifyTablesToNormalPart8();
        ClassifyTablesToNormalPart9();
        ClassifyTablesToNormalPart10();
        ClassifyTablesToNormalPart11();

        OnCreateEvaluationDataOnAfterClassifyTablesToNormal();

        DataClassEvalDataCountry.ClassifyCountrySpecificTables();

        // All EUII and EUPI Fields are set to Personal
        DataSensitivity.SetFilter("Data Classification", '%1|%2',
            DataSensitivity."Data Classification"::EndUserIdentifiableInformation,
            DataSensitivity."Data Classification"::EndUserPseudonymousIdentifiers);
        DataSensitivity.ModifyAll("Data Sensitivity", DataSensitivity."Data Sensitivity"::Personal);

        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
        if TableMetadata.FindSet() then
            repeat
                DataSensitivity.Reset();
                DataSensitivity.SetRange("Table No", TableMetadata.ID);
                DataSensitivity.DeleteAll();
            until TableMetadata.Next() = 0;
    end;

    local procedure ClassifyTablesPart1()
    begin
        ClassifyCreditTransferEntry();
        ClassifyActiveSession();
        ClassifyRegisteredInvtMovementHdr();
        ClassifySEPADirectDebitMandate();
        ClassifyPostedAssemblyHeader();
        ClassifyPostedInvtPickHeader();
        ClassifyPostedInvtPutawayHeader();
        ClassifyPurchInvEntityAggregate();
        ClassifySalesInvoiceEntityAggregate();
        ClassifySalesOrderEntityBuffer();
        ClassifySalesQuoteEntityBuffer();
        ClassifySalesCrMemoEntityBuffer();
        ClassifyPurchaseOrderEntityBuffer();
        ClassifyPurchCrMemoEntityBuffer();
        ClassifyWarehouseEntry();
        ClassifyWarehouseJournalLine();
        ClassifyWarehouseEmployee();
        ClassifyContactAltAddress();
        ClassifyCashFlowForecastEntry();
        ClassifyDirectDebitCollection();
        ClassifyActivityLog();
        ClassifyInventoryPeriodEntry();
        ClassifyMyItem();
        ClassifyUserSecurityStatus();
        ClassifyCueSetup();
        ClassifyVATReportArchive();
        ClassifySessionEvent();
        ClassifyUserDefaultStyleSheet();
        ClassifyUserPlan();
#if not CLEAN22
        ClassifyUserGroupAccessControl();
        ClassifyUserGroupMember();
#endif
        ClassifyAADApplication();
        ClassifyAnalysisSelectedDimension();
        ClassifyItemAnalysisViewBudgEntry();
        ClassifyItemAnalysisViewEntry();
        ClassifyTokenCache();
        ClassifyTenantLicenseState();
        ClassifyFAJournalSetup();
        ClassifyCustomizedCalendarEntry();
        ClassifyOfficeContactDetails();
        ClassifyMyVendor();
        ClassifyItemBudgetEntry();
        ClassifyMyCustomer();
        ClassifyAccessControl();
        ClassifyUserProperty();
        ClassifyUser();
        ClassifyConfidentialInformation();
        ClassifyAttendee();
        ClassifyOverdueApprovalEntry();
        ClassifyApplicationAreaSetup();
        ClassifyDateComprRegister();
        ClassifyEmployeeAbsence();
        ClassifyWorkflowStepInstanceArchive();
        ClassifyMyJob();
        ClassifyAlternativeAddress();
        ClassifyWorkflowStepArgument();
        ClassifyPageDataPersonalization();
        ClassifySentNotificationEntry();
        ClassifyICOutboxPurchaseHeader();
        ClassifyUserMetadata();
        ClassifyNotificationEntry();
        ClassifyUserPersonalization();
        ClassifyWorkflowStepInstance();
        ClassifyWorkCenter();
        ClassifyCampaignEntry();
        ClassifySession();
        ClassifyIsolatedStorage();
        ClassifyNavAppSetting();
        ClassifyPurchaseLineArchive();
        ClassifyPurchaseHeaderArchive();
        ClassifySalesLineArchive();
        ClassifySalesHeaderArchive();
        ClassifyApprovalCommentLine();
        ClassifyCommunicationMethod();
        ClassifySavedSegmentCriteria();
        ClassifyOpportunityEntry();
        ClassifyOpportunity();
        ClassifyContactProfileAnswer();
        ClassifyTodo();
        ClassifyMarketingSetup();
        ClassifySegmentLine();
        ClassifyLoggedSegment();
        ClassifyServiceInvoiceLine();
        ClassifyServiceInvoiceHeader();
        ClassifyServiceShipmentLine();
        ClassifyServiceShipmentHeader();
        ClassifyJobQueueLogEntry();
        ClassifyJobQueueEntry();
        ClassifyInteractionLogEntry();
        ClassifyInteractionMergeData();
        ClassifyPostedApprovalCommentLine();
        ClassifyPostedApprovalEntry();
        ClassifyContact();
        ClassifyApprovalEntry();
        ClassifyContractChangeLog();
        ClassifyServiceContractHeader();
        ClassifyHandledICInboxPurchHeader();
        ClassifyHandledICInboxSalesHeader();
        ClassifyICInboxPurchaseHeader();
        ClassifyICInboxSalesHeader();
        ClassifyHandledICOutboxPurchHdr();
        ClassifyPersistentBlob();
        ClassifyPublishedApplication();
    end;

    local procedure ClassifyTablesPart2()
    begin
        ClassifyServiceItemLog();
        ClassifyServiceCrMemoHeader();
        ClassifyServiceRegister();
        ClassifyUserPageMetadata();
        ClassifyICPartner();
        ClassifyChangeLogEntry();
        ClassifyInsCoverageLedgerEntry();
        ClassifyLoanerEntry();
        ClassifyServiceDocumentLog();
        ClassifyWarrantyLedgerEntry();
        ClassifyServiceLedgerEntry();
        ClassifyTermsAndConditionsState();
        ClassifyServiceLine();
        ClassifyServiceHeader();
        ClassifyDetailedVendorLedgEntry();
        ClassifyDetailedCustLedgEntry();
        ClassifyDetailedCVLedgEntryBuffer();
        ClassifyPostedPaymentReconLine();
        ClassifyAppliedPaymentEntry();
        ClassifySelectedDimension();
        ClassifyConfigLine();
        ClassifyItemApplicationEntryHistory();
        ClassifyConfigPackageTable();
        ClassifyItemApplicationEntry();
        ClassifyReservationEntry();
#if not CLEAN24
        ClassifyCalendarEvent();
#endif
        ClassifyCapacityLedgerEntry();
        ClassifyPayableVendorLedgerEntry();
        ClassifyReminderFinChargeEntry();
        ClassifyPositivePayEntryDetail();
        ClassifySalesShipmentLine();
        ClassifyICOutboxSalesHeader();
        ClassifyIssuedFinChargeMemoHeader();
        ClassifyFinanceChargeMemoHeader();
        ClassifyFiledServiceContractHeader();
        ClassifyBinCreationWorksheetLine();
        ClassifyIssuedReminderHeader();
        ClassifyReminderHeader();
        ClassifyDirectDebitCollectionEntry();
        ClassifyValueEntry();
        ClassifyCustomerBankAccount();
        ClassifyCreditTransferRegister();
        ClassifyPhysInventoryLedgerEntry();
        ClassifyBankAccReconciliationLine();
        ClassifyBankAccRecMatchBuffer();
        ClassifyTimeSheetLine();
        ClassifyCheckLedgerEntry();
        ClassifyBankAccountLedgerEntry();
        ClassifyBookingSync();
        ClassifyExchangeSync();
        ClassifyVATEntry();
        ClassifyWarehouseActivityHeader();
        ClassifyVATRegistrationLog();
        ClassifyRequisitionLine();
        ClassifyServiceCrMemoLine();
        ClassifyJobRegister();
        ClassifyResourceRegister();
        ClassifyReturnReceiptLine();
        ClassifyReturnReceiptHeader();
        ClassifyOrderAddress();
        ClassifyShiptoAddress();
        ClassifyReturnShipmentLine();
        ClassifyReturnShipmentHeader();
        ClassifyResLedgerEntry();
        ClassifyInsuranceRegister();
        ClassifyContractGainLossEntry();
        ClassifyMyTimeSheets();
        ClassifyCustomReportLayout();
        ClassifyCostBudgetRegister();
        ClassifyCostBudgetEntry();
        ClassifyCostAllocationTarget();
        ClassifyCostAllocationSource();
        ClassifyCostRegister();
        ClassifyCostEntry();
        ClassifyCostType();
        ClassifyReversalEntry();
        ClassifyJobLedgerEntry();
        ClassifyTimeSheetLineArchive();
        ClassifyJob();
        ClassifyJobArchive();
        ClassifyResCapacityEntry();
        ClassifyResource();
        ClassifyIncomingDocument();
        ClassifyWarehouseRegister();
        ClassifyPurchCrMemoLine();
        ClassifyPurchCrMemoHdr();
        ClassifyPurchInvLine();
        ClassifyPurchInvHeader();
        ClassifyPurchRcptLine();
        ClassifyPurchRcptHeader();
        ClassifySalesCrMemoLine();
        ClassifySalesCrMemoHeader();
        ClassifySalesInvoiceLine();
        ClassifySalesInvoiceHeader();
        ClassifyMaintenanceLedgerEntry();
        ClassifySalesShipmentHeader();
        ClassifyFARegister();
        ClassifyMaintenanceRegistration();
        ClassifyWorkflowStepArgumentArchive();
        ClassifyGLBudgetEntry();
        ClassifyUserSetup();
        ClassifyFALedgerEntry();
    end;

    local procedure ClassifyTablesPart3()
    begin
        ClassifyHandledICOutboxSalesHeader();
        ClassifyJobPlanningLine();
        ClassifyJobPlanningLineArchive();
        ClassifyGenJournalLine();
        ClassifyPrinterSelection();
        ClassifyTimeSheetChartSetup();
        ClassifyUserTimeRegister();
        ClassifyItemRegister();
        ClassifyGLRegister();
        ClassifyPurchaseLine();
        ClassifyPurchaseHeader();
        ClassifySalesLine();
        ClassifySalesHeader();
        ClassifyTimeSheetHeaderArchive();
        ClassifyItemLedgerEntry();
        ClassifyTimeSheetHeader();
        ClassifyItem();
        ClassifyEntityText();
        ClassifyVendorLedgerEntry();
        ClassifyVendor();
        ClassifyCustLedgerEntry();
        ClassifyMyAccount();
        ClassifyCustomer();
        ClassifyGLEntry();
        ClassifySalespersonPurchaser();
        ClassifyManufacturingUserTemplate();
        ClassifyVendorBankAccount();
        ClassifyApiWebhookSubscripitonFields();
        ClassifyExternalEventSubscriptionFields();
        ClassifySupportInformation();
        ClassifyCRMSynchStatus();
        ClassifyRetentionPolicyLogEntry();
        ClassifyDocumentSharing();
        ClassifyEmailConnectorLogo();
        ClassifyEmailError();
        ClassifyEmailOutbox();
        ClassifySentEmail();
        ClassifyEmailScenarioAttachments();
        ClassifyRateLimit();
        ClassifyEmailMessage();
        ClassifyEmailRecipient();
        ClassifyEmailMessageAttachment();
        ClassifyEmailRelatedAttachments();
        ClassifyEmailLookup();
        ClassifyPostedGenJournalLine();
        ClassifyWordTemplate();
        ClassifyBatchProcessingSessionMap();
        ClassifyConfigPackageError();
        ClassifyBankAccount();
        ClassifyCRMOptionMapping();
        ClassifyDataExch();
        ClassifyDataMigrationError();
        ClassifyDataMigrationParameters();
        ClassifyErrorMessage();
        ClassifyIntegrationSynchJobErrors();
        ClassifyInventoryPageData();
        ClassifyNotificationContext();
        ClassifyPaymentReportingArgument();
        ClassifyPaymentServiceSetup();
        ClassifyRestrictedRecord();
        ClassifyServiceConnection();
        ClassifyStandardAddress();
        ClassifyTempStack();
        ClassifyTimelineEvent();
        ClassifyVATRateChangeLogEntry();
        ClassifyWorkflowEventQueue();
        ClassifyWorkflowRecordChange();
        ClassifyWorkflowRecordChangeArchive();
        ClassifyWorkflowTableRelationValue();
        ClassifyWorkflowWebhookEntry();
        ClassifyTenantWebServiceOData();
        ClassifyTenantWebServiceColumns();
        ClassifyTenantWebServiceFilter();
        ClassifyCouplingRecordBuffer();
        ClassifyCRMAnnotationBuffer();
        ClassifyCRMAnnotationCoupling();
        ClassifyCRMPostBuffer();
        ClassifyCRMSynchConflictBuffer();
        ClassifyInventoryEventBuffer();
        ClassifyItemTracingBuffer();
        ClassifyMergeDuplicatesBuffer();
        ClassifyMergeDuplicatesConflict();
        ClassifyRecordSetBuffer();
        ClassifyRecordBuffer();
        ClassifyRecordExportBuffer();
        ClassifyParallelSessionEntry();
        ClassifyWorkflowsEntriesBuffer();
        ClassifyRecordSetTree();
        ClassifyApplicationUserSettings();
        ClassifyPermissionSetInPlan();
        ClassifyFinancialReports();
        ClassifyRemitToAddress();
        ClassifyICBankAccount();
        ClassifyAllocationAccounts();
    end;

    local procedure ClassifyFinancialReports()
    var
        FinancialReportUserFilters: Record "Financial Report User Filters";
    begin
        SetTableFieldsToNormal(Database::"Financial Report");
        SetTableFieldsToNormal(Database::"Financial Report User Filters");
        SetFieldToPersonal(Database::"Financial Report User Filters", FinancialReportUserFilters.FieldNo("User ID"));
    end;

    local procedure ClassifyTablesToNormalPart1()
    begin
        SetTableFieldsToNormal(DATABASE::"Payment Terms");
        SetTableFieldsToNormal(DATABASE::Currency);
        SetTableFieldsToNormal(DATABASE::"Finance Charge Terms");
        SetTableFieldsToNormal(DATABASE::"Customer Price Group");
        SetTableFieldsToNormal(DATABASE::"Standard Text");
        SetTableFieldsToNormal(DATABASE::Language);
        SetTableFieldsToNormal(DATABASE::"Country/Region");
        SetTableFieldsToNormal(DATABASE::"Shipment Method");
        SetTableFieldsToNormal(DATABASE::"Country/Region Translation");
        SetTableFieldsToNormal(DATABASE::Location);
        SetTableFieldsToNormal(DATABASE::"G/L Account");
        SetTableFieldsToNormal(DATABASE::"Cust. Invoice Disc.");
        SetTableFieldsToNormal(DATABASE::"Vendor Invoice Disc.");
        SetTableFieldsToNormal(DATABASE::"Item Translation");
        SetTableFieldsToNormal(DATABASE::"Sales Line");
        SetTableFieldsToNormal(DATABASE::"Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Rounding Method");
        SetTableFieldsToNormal(DATABASE::"Purch. Comment Line");
        SetTableFieldsToNormal(DATABASE::"Sales Comment Line");
        SetTableFieldsToNormal(DATABASE::"Accounting Period");
        SetTableFieldsToNormal(DATABASE::"Batch Processing Parameter");
        SetTableFieldsToNormal(DATABASE::"Document Sending Profile");
        SetTableFieldsToNormal(DATABASE::"Electronic Document Format");
        SetTableFieldsToNormal(DATABASE::"Report Selections");
        SetTableFieldsToNormal(DATABASE::"Report Selection Warehouse");
        SetTableFieldsToNormal(DATABASE::"Company Information");
        SetTableFieldsToNormal(DATABASE::"Gen. Journal Template");
        SetTableFieldsToNormal(DATABASE::"Item Journal Template");
        SetTableFieldsToNormal(DATABASE::"Item Journal Line");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Name");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Line");
        SetTableFieldsToNormal(DATABASE::"Exch. Rate Adjmt. Reg.");
        SetTableFieldsToNormal(DATABASE::"Exch. Rate Adjmt. Ledg. Entry");
        SetTableFieldsToNormal(DATABASE::"BOM Component");
        SetTableFieldsToNormal(DATABASE::"Customer Posting Group");
        SetTableFieldsToNormal(DATABASE::"Alt. Customer Posting Group");
        SetTableFieldsToNormal(DATABASE::"Vendor Posting Group");
        SetTableFieldsToNormal(DATABASE::"Alt. Vendor Posting Group");
        SetTableFieldsToNormal(DATABASE::"Inventory Posting Group");
        SetTableFieldsToNormal(DATABASE::"G/L Budget Name");
        SetTableFieldsToNormal(DATABASE::"Comment Line");
        SetTableFieldsToNormal(DATABASE::"Comment Line Archive");
        SetTableFieldsToNormal(DATABASE::"General Ledger Setup");
        SetTableFieldsToNormal(DATABASE::"Item Vendor");
        SetTableFieldsToNormal(DATABASE::"Incoming Documents Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. KPI Web Srv. Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. KPI Web Srv. Line");
        SetTableFieldsToNormal(DATABASE::"Unlinked Attachment");
        SetTableFieldsToNormal(DATABASE::"ECSL VAT Report Line Relation");
        SetTableFieldsToNormal(DATABASE::"Resource Group");
        SetTableFieldsToNormal(DATABASE::"Standard Sales Code");
        SetTableFieldsToNormal(DATABASE::"Standard Sales Line");
        SetTableFieldsToNormal(DATABASE::"Standard Customer Sales Code");
        SetTableFieldsToNormal(DATABASE::"Standard Purchase Code");
        SetTableFieldsToNormal(DATABASE::"Standard Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Standard Vendor Purchase Code");
        SetTableFieldsToNormal(DATABASE::"G/L Account Source Currency");
        SetTableFieldsToNormal(DATABASE::"G/L Account Where-Used");
        SetTableFieldsToNormal(DATABASE::"Work Type");
#if not CLEAN23
        SetTableFieldsToNormal(DATABASE::"Resource Price");
        SetTableFieldsToNormal(DATABASE::"Resource Cost");
#endif
        SetTableFieldsToNormal(DATABASE::"Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Resource Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Res. Journal Template");
        SetTableFieldsToNormal(DATABASE::"Res. Journal Line");
        SetTableFieldsToNormal(DATABASE::"Job Posting Group");
        SetTableFieldsToNormal(DATABASE::"Job Journal Template");
        SetTableFieldsToNormal(DATABASE::"Job Journal Line");
        SetTableFieldsToNormal(DATABASE::"Journal User Preferences");
        SetTableFieldsToNormal(DATABASE::"Business Unit");
        SetTableFieldsToNormal(DATABASE::"Gen. Jnl. Allocation");
        SetTableFieldsToNormal(DATABASE::"Post Code");
        SetTableFieldsToNormal(DATABASE::"Source Code");
        SetTableFieldsToNormal(DATABASE::"Reason Code");
        SetTableFieldsToNormal(DATABASE::"Gen. Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Item Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Res. Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Job Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Source Code Setup");
        SetTableFieldsToNormal(DATABASE::"Req. Wksh. Template");
        SetTableFieldsToNormal(DATABASE::"Requisition Wksh. Name");
#if not CLEAN22
        SetTableFieldsToNormal(DATABASE::"Intrastat Setup");
#endif
        SetTableFieldsToNormal(DATABASE::"VAT Reg. No. Srv Config");
        SetTableFieldsToNormal(DATABASE::"VAT Reg. No. Srv. Template");
        SetTableFieldsToNormal(DATABASE::"Gen. Business Posting Group");
        SetTableFieldsToNormal(DATABASE::"Gen. Product Posting Group");
        SetTableFieldsToNormal(DATABASE::"General Posting Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Template");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Line");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Name");
        SetTableFieldsToNormal(DATABASE::"Transaction Type");
        SetTableFieldsToNormal(DATABASE::"Transport Method");
        SetTableFieldsToNormal(DATABASE::"Tariff Number");
#if not CLEAN22
        SetTableFieldsToNormal(DATABASE::"Intrastat Jnl. Template");
        SetTableFieldsToNormal(DATABASE::"Intrastat Jnl. Batch");
        SetTableFieldsToNormal(DATABASE::"Intrastat Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"Advanced Intrastat Checklist");
#endif
        SetTableFieldsToNormal(DATABASE::"Currency Amount");
        SetTableFieldsToNormal(DATABASE::"Customer Amount");
        SetTableFieldsToNormal(DATABASE::"Vendor Amount");
        SetTableFieldsToNormal(DATABASE::"Item Amount");
        SetTableFieldsToNormal(DATABASE::"G/L Account Net Change");
        SetTableFieldsToNormal(DATABASE::"Bank Acc. Reconciliation");
        SetTableFieldsToNormal(DATABASE::"Ledger Entry Matching Buffer");
        SetTableFieldsToNormal(DATABASE::"Bank Account Statement");
        SetTableFieldsToNormal(DATABASE::"Bank Account Statement Line");
        SetTableFieldsToNormal(DATABASE::"Bank Account Posting Group");
        SetTableFieldsToNormal(DATABASE::"Bank Account Balance Buffer");
        SetTableFieldsToNormal(DATABASE::"Bank Pmt. Appl. Settings");
        SetTableFieldsToNormal(DATABASE::"Bank Statement Matching Buffer");
        SetTableFieldsToNormal(DATABASE::"Job Journal Quantity");
        SetTableFieldsToNormal(DATABASE::"Custom Address Format");
        SetTableFieldsToNormal(DATABASE::"Custom Address Format Line");
        SetTableFieldsToNormal(Database::"Posted Gen. Journal Batch");
        SetTableFieldsToNormal(Database::"Copy Gen. Journal Parameters");
    end;

    local procedure ClassifyTablesToNormalPart2()
    begin
        SetTableFieldsToNormal(DATABASE::"Extended Text Header");
        SetTableFieldsToNormal(DATABASE::"Extended Text Line");
        SetTableFieldsToNormal(DATABASE::Area);
        SetTableFieldsToNormal(DATABASE::"Transaction Specification");
        SetTableFieldsToNormal(DATABASE::Territory);
        SetTableFieldsToNormal(DATABASE::"Payment Method");
        SetTableFieldsToNormal(DATABASE::"VAT Amount Line");
        SetTableFieldsToNormal(DATABASE::"Dispute Status");
        SetTableFieldsToNormal(DATABASE::"Shipping Agent");
        SetTableFieldsToNormal(DATABASE::"Reminder Attachment Text");
        SetTableFieldsToNormal(DATABASE::"Reminder Email Text");
        SetTableFieldsToNormal(DATABASE::"Reminder Terms");
        SetTableFieldsToNormal(DATABASE::"Reminder Level");
        SetTableFieldsToNormal(DATABASE::"Reminder Text");
        SetTableFieldsToNormal(DATABASE::"Reminder Line");
        SetTableFieldsToNormal(DATABASE::"Issued Reminder Line");
        SetTableFieldsToNormal(DATABASE::"Reminder Comment Line");
        SetTableFieldsToNormal(Database::"Reminder Action Group");
        SetTableFieldsToNormal(Database::"Reminder Action");
        SetTableFieldsToNormal(Database::"Create Reminders Setup");
        SetTableFieldsToNormal(Database::"Issue Reminders Setup");
        SetTableFieldsToNormal(Database::"Send Reminders Setup");
        SetTableFieldsToNormal(Database::"Reminder Automation Error");
        SetTableFieldsToNormal(Database::"Reminder Action Group Log");
        SetTableFieldsToNormal(Database::"Reminder Action Log");
        SetTableFieldsToNormal(DATABASE::"Finance Charge Text");
        SetTableFieldsToNormal(DATABASE::"Finance Charge Memo Line");
        SetTableFieldsToNormal(DATABASE::"Issued Fin. Charge Memo Line");
        SetTableFieldsToNormal(DATABASE::"Fin. Charge Comment Line");
        SetTableFieldsToNormal(DATABASE::"No. Series");
        SetTableFieldsToNormal(DATABASE::"No. Series Line");
#if not CLEAN24
#pragma warning disable AL0432
        SetTableFieldsToNormal(DATABASE::"No. Series Line Sales");
        SetTableFieldsToNormal(DATABASE::"No. Series Line Purchase");
#pragma warning restore AL0432
#endif
        SetTableFieldsToNormal(DATABASE::"No. Series Relationship");
        SetTableFieldsToNormal(DATABASE::"Sales & Receivables Setup");
        SetTableFieldsToNormal(DATABASE::"Purchases & Payables Setup");
        SetTableFieldsToNormal(DATABASE::"Inventory Setup");
        SetTableFieldsToNormal(DATABASE::"Resources Setup");
        SetTableFieldsToNormal(DATABASE::"Jobs Setup");
        SetTableFieldsToNormal(DATABASE::"Tax Area Translation");
        SetTableFieldsToNormal(DATABASE::"Tax Area");
        SetTableFieldsToNormal(DATABASE::"Tax Area Line");
        SetTableFieldsToNormal(DATABASE::"Tax Jurisdiction");
        SetTableFieldsToNormal(DATABASE::"Tax Group");
        SetTableFieldsToNormal(DATABASE::"Tax Detail");
        SetTableFieldsToNormal(DATABASE::"VAT Business Posting Group");
        SetTableFieldsToNormal(DATABASE::"VAT Product Posting Group");
        SetTableFieldsToNormal(DATABASE::"VAT Posting Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Reporting Code");
        SetTableFieldsToNormal(DATABASE::"VAT Setup");
        SetTableFieldsToNormal(DATABASE::"Tax Setup");
        SetTableFieldsToNormal(DATABASE::"Tax Jurisdiction Translation");
        SetTableFieldsToNormal(DATABASE::"Currency for Fin. Charge Terms");
        SetTableFieldsToNormal(DATABASE::"Currency for Reminder Level");
        SetTableFieldsToNormal(DATABASE::"Currency Exchange Rate");
        SetTableFieldsToNormal(DATABASE::"Column Layout Name");
        SetTableFieldsToNormal(DATABASE::"Column Layout");
#if not CLEAN23
        SetTableFieldsToNormal(DATABASE::"Resource Price Change");
#endif
        SetTableFieldsToNormal(DATABASE::"Tracking Specification");
        SetTableFieldsToNormal(DATABASE::"Customer Discount Group");
        SetTableFieldsToNormal(DATABASE::"Item Discount Group");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. Cell Value");
        SetTableFieldsToNormal(DATABASE::Dimension);
        SetTableFieldsToNormal(DATABASE::"Dimension Value");
        SetTableFieldsToNormal(DATABASE::"Dimension Combination");
        SetTableFieldsToNormal(DATABASE::"Dimension Value Combination");
        SetTableFieldsToNormal(DATABASE::"Default Dimension");
        SetTableFieldsToNormal(DATABASE::"Default Dimension Priority");
        SetTableFieldsToNormal(DATABASE::"Dimension Set ID Filter Line");
        SetTableFieldsToNormal(DATABASE::"ECSL VAT Report Line");
        SetTableFieldsToNormal(DATABASE::"Analysis View");
        SetTableFieldsToNormal(DATABASE::"Analysis View Filter");
        SetTableFieldsToNormal(DATABASE::"G/L Account (Analysis View)");
        SetTableFieldsToNormal(DATABASE::"Object Translation");
        SetTableFieldsToNormal(DATABASE::"Report List Translation");
        SetTableFieldsToNormal(DATABASE::"VAT Registration No. Format");
        SetTableFieldsToNormal(DATABASE::"Dimension Translation");
        SetTableFieldsToNormal(DATABASE::"Availability at Date");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup (Table)");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup (Field)");
        SetTableFieldsToNormal(DATABASE::"IC G/L Account");
        SetTableFieldsToNormal(DATABASE::"IC Dimension");
        SetTableFieldsToNormal(DATABASE::"IC Dimension Value");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Transaction");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Trans.");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Transaction");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Trans.");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox/Outbox Jnl. Line Dim.");
        SetTableFieldsToNormal(DATABASE::"IC Comment Line");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Purch. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Purch. Line");
        SetTableFieldsToNormal(DATABASE::"IC Document Dimension");
        SetTableFieldsToNormal(DATABASE::"Sales Prepayment %");
        SetTableFieldsToNormal(DATABASE::"Purchase Prepayment %");
        SetTableFieldsToNormal(Database::"Gen. Jnl. Dim. Filter");
    end;

    local procedure ClassifyTablesToNormalPart3()
    begin
        SetTableFieldsToNormal(DATABASE::"Payment Term Translation");
        SetTableFieldsToNormal(DATABASE::"Shipment Method Translation");
        SetTableFieldsToNormal(DATABASE::"Payment Method Translation");
        SetTableFieldsToNormal(DATABASE::"Job Queue Category");
        SetTableFieldsToNormal(DATABASE::"Dimension Set Tree Node");
        SetTableFieldsToNormal(DATABASE::"Business Chart Map");
        SetTableFieldsToNormal(DATABASE::"VAT Rate Change Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Rate Change Conversion");
        SetTableFieldsToNormal(DATABASE::"VAT Clause");
        SetTableFieldsToNormal(DATABASE::"VAT Clause Translation");
        SetTableFieldsToNormal(DATABASE::"VAT Clause by Doc. Type");
        SetTableFieldsToNormal(DATABASE::"VAT Clause by Doc. Type Trans.");
        SetTableFieldsToNormal(DATABASE::"G/L Account Category");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Report Line");
        SetTableFieldsToNormal(DATABASE::"VAT Report Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Report Line Relation");
        SetTableFieldsToNormal(DATABASE::"VAT Report Error Log");
        SetTableFieldsToNormal(DATABASE::"VAT Reports Configuration");
        SetTableFieldsToNormal(DATABASE::"Standard General Journal");
        SetTableFieldsToNormal(DATABASE::"Standard General Journal Line");
        SetTableFieldsToNormal(DATABASE::"Standard Item Journal");
        SetTableFieldsToNormal(DATABASE::"Standard Item Journal Line");
        SetTableFieldsToNormal(DATABASE::"Online Bank Acc. Link");
        SetTableFieldsToNormal(DATABASE::"Certificate of Supply");
        SetTableFieldsToNormal(DATABASE::"Online Map Setup");
        SetTableFieldsToNormal(DATABASE::"Online Map Parameter Setup");
        SetTableFieldsToNormal(DATABASE::Geolocation);
        SetTableFieldsToNormal(DATABASE::"Cash Flow Account");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Account Comment");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Availability Buffer");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Setup");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Worksheet Line");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Manual Revenue");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Manual Expense");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Azure AI Buffer");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Report Selection");
        SetTableFieldsToNormal(DATABASE::"Excel Template Storage");
        SetTableFieldsToNormal(DATABASE::"Assembly Line");
        SetTableFieldsToNormal(DATABASE::"Assemble-to-Order Link");
        SetTableFieldsToNormal(DATABASE::"Assembly Setup");
        SetTableFieldsToNormal(DATABASE::"Assembly Comment Line");
        SetTableFieldsToNormal(DATABASE::"Posted Assembly Line");
        SetTableFieldsToNormal(DATABASE::"Posted Assemble-to-Order Link");
        SetTableFieldsToNormal(DATABASE::"ATO Sales Buffer");
        SetTableFieldsToNormal(DATABASE::"Time Sheet Detail");
        SetTableFieldsToNormal(DATABASE::"Time Sheet Comment Line");
        SetTableFieldsToNormal(DATABASE::"Time Sheet Detail Archive");
        SetTableFieldsToNormal(DATABASE::"Time Sheet Cmt. Line Archive");
        SetTableFieldsToNormal(DATABASE::"Document Search Result");
        SetTableFieldsToNormal(DATABASE::"Job Task");
        SetTableFieldsToNormal(DATABASE::"Job Task Archive");
        SetTableFieldsToNormal(DATABASE::"Job Task Dimension");
        SetTableFieldsToNormal(DATABASE::"Job WIP Method");
        SetTableFieldsToNormal(DATABASE::"Job WIP Warning");
#if not CLEAN23
        SetTableFieldsToNormal(DATABASE::"Job Resource Price");
        SetTableFieldsToNormal(DATABASE::"Job Item Price");
        SetTableFieldsToNormal(DATABASE::"Job G/L Account Price");
#endif
        SetTableFieldsToNormal(DATABASE::"Job Usage Link");
        SetTableFieldsToNormal(DATABASE::"Job WIP Total");
        SetTableFieldsToNormal(DATABASE::"Job Planning Line Invoice");
        SetTableFieldsToNormal(DATABASE::"Job Planning Line - Calendar");
        SetTableFieldsToNormal(DATABASE::"Additional Fee Setup");
        SetTableFieldsToNormal(DATABASE::"Sorting Table");
        SetTableFieldsToNormal(DATABASE::"Reminder Terms Translation");
        SetTableFieldsToNormal(DATABASE::"Line Fee Note on Report Hist.");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Template");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Line");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Cost Accounting Setup");
        SetTableFieldsToNormal(DATABASE::"Cost Budget Buffer");
        SetTableFieldsToNormal(DATABASE::"Cost Budget Name");
        SetTableFieldsToNormal(DATABASE::"Cost Center");
        SetTableFieldsToNormal(DATABASE::"Cost Object");
        SetTableFieldsToNormal(DATABASE::"Document Attachment");
        SetTableFieldsToNormal(DATABASE::"Bank Export/Import Setup");
        SetTableFieldsToNormal(DATABASE::"Data Exchange Type");
        SetTableFieldsToNormal(DATABASE::"Intermediate Data Import");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Def");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Column Def");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Mapping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field Grouping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Table Filter");
        SetTableFieldsToNormal(DATABASE::"Payment Export Data");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Line Def");
        SetTableFieldsToNormal(DATABASE::"Payment Jnl. Export Error Text");
        SetTableFieldsToNormal(DATABASE::"Payment Export Remittance Text");
        SetTableFieldsToNormal(DATABASE::"Payment Registration Buffer");
        SetTableFieldsToNormal(DATABASE::"Payment Rec. Related Entry");
        SetTableFieldsToNormal(DATABASE::"Pmt. Rec. Applied-to Entry");
        SetTableFieldsToNormal(DATABASE::"Transformation Rule");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Header");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Detail");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Footer");
        SetTableFieldsToNormal(DATABASE::"Bank Stmt Multiple Match Line");
        SetTableFieldsToNormal(DATABASE::"Text-to-Account Mapping");
        SetTableFieldsToNormal(DATABASE::"Bank Pmt. Appl. Rule");
        SetTableFieldsToNormal(DATABASE::"OCR Service Document Template");
        SetTableFieldsToNormal(DATABASE::"Bank Clearing Standard");
        SetTableFieldsToNormal(DATABASE::"Outstanding Bank Transaction");
        SetTableFieldsToNormal(DATABASE::"Payment Application Proposal");
    end;

    local procedure ClassifyTablesToNormalPart4()
    begin
        SetTableFieldsToNormal(DATABASE::"Posted Payment Recon. Hdr");
        SetTableFieldsToNormal(DATABASE::"Payment Matching Details");
        SetTableFieldsToNormal(DATABASE::"Dimensions Template");
        SetTableFieldsToNormal(DATABASE::"O365 Device Setup Instructions");
        SetTableFieldsToNormal(DATABASE::"O365 Getting Started Page Data");
        SetTableFieldsToNormal(DATABASE::"Chart Definition");
        SetTableFieldsToNormal(DATABASE::"Last Used Chart");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Setup");
        SetTableFieldsToNormal(DATABASE::"Activities Cue");
        SetTableFieldsToNormal(DATABASE::"Approvals Activities Cue");
        SetTableFieldsToNormal(1432); // Net Promoter Score Setup
        SetTableFieldsToNormal(1471); // Table "Product Video Category"
        SetTableFieldsToNormal(DATABASE::Workflow);
        SetTableFieldsToNormal(DATABASE::"Workflow Step");
        SetTableFieldsToNormal(DATABASE::"Workflow - Table Relation");
        SetTableFieldsToNormal(DATABASE::"Workflow Category");
        SetTableFieldsToNormal(DATABASE::"WF Event/Response Combination");
        SetTableFieldsToNormal(DATABASE::"Dynamic Request Page Entity");
        SetTableFieldsToNormal(DATABASE::"Dynamic Request Page Field");
        SetTableFieldsToNormal(DATABASE::"Workflow Event");
        SetTableFieldsToNormal(DATABASE::"Workflow Response");
        SetTableFieldsToNormal(DATABASE::"Workflow Rule");
        SetTableFieldsToNormal(DATABASE::"Workflow User Group");
        SetTableFieldsToNormal(DATABASE::"Flow Service Configuration");
        SetTableFieldsToNormal(DATABASE::"Flow User Environment Config");
        SetTableFieldsToNormal(DATABASE::"Office Add-in Context");
        SetTableFieldsToNormal(DATABASE::"Office Add-in Setup");
        SetTableFieldsToNormal(DATABASE::"Office Invoice");
        SetTableFieldsToNormal(DATABASE::"Office Add-in");
        SetTableFieldsToNormal(DATABASE::"Office Admin. Credentials");
        SetTableFieldsToNormal(DATABASE::"Office Job Journal");
        SetTableFieldsToNormal(DATABASE::"Office Document Selection");
        SetTableFieldsToNormal(DATABASE::"Office Suggested Line Item");
        SetTableFieldsToNormal(DATABASE::"Invoiced Booking Item");
        SetTableFieldsToNormal(DATABASE::"Curr. Exch. Rate Update Setup");
        SetTableFieldsToNormal(DATABASE::"Import G/L Transaction");
        SetTableFieldsToNormal(DATABASE::"Deferral Template");
        SetTableFieldsToNormal(DATABASE::"Deferral Header");
        SetTableFieldsToNormal(DATABASE::"Deferral Line");
        SetTableFieldsToNormal(DATABASE::"Posted Deferral Header");
        SetTableFieldsToNormal(DATABASE::"Posted Deferral Line");
        SetTableFieldsToNormal(DATABASE::"Data Migration Status");
        SetTableFieldsToNormal(DATABASE::"Data Migrator Registration");
        SetTableFieldsToNormal(DATABASE::"Data Migration Entity");
        SetTableFieldsToNormal(DATABASE::"Assisted Company Setup Status");
        SetTableFieldsToNormal(1803); // Assisted Setup table
        SetTableFieldsToNormal(DATABASE::"Data Migration Setup");
        SetTableFieldsToNormal(1807); // Assisted Setup Log table
        SetTableFieldsToNormal(1808); // Aggregated Assisted Setup table
        SetTableFieldsToNormal(1810); // Assisted Setup Icons table
        SetTableFieldsToNormal(DATABASE::"Business Unit Setup");
        SetTableFieldsToNormal(DATABASE::"Business Unit Information");
        SetTableFieldsToNormal(DATABASE::"Consolidation Account");
        SetTableFieldsToNormal(Database::"Consolidation Process");
        SetTableFieldsToNormal(Database::"Bus. Unit In Cons. Process");
        SetTableFieldsToNormal(Database::"Consolidation Setup");
        SetTableFieldsToNormal(3700); // "Manual Setup" table
        SetTableFieldsToNormal(1876); // "Business Setup Icon" table
        SetTableFieldsToNormal(DATABASE::"VAT Setup Posting Groups");
        SetTableFieldsToNormal(DATABASE::"VAT Assisted Setup Templates");
        SetTableFieldsToNormal(DATABASE::"VAT Assisted Setup Bus. Grp.");
        SetTableFieldsToNormal(DATABASE::"Cancelled Document");
        SetTableFieldsToNormal(DATABASE::"Time Series Forecast");
        SetTableFieldsToNormal(2004); // Azure AI Usage table
        SetTableFieldsToNormal(DATABASE::"Image Analysis Setup");
        SetTableFieldsToNormal(DATABASE::"Image Analysis Scenario");
        SetTableFieldsToNormal(DATABASE::"Sales Document Icon");
        SetTableFieldsToNormal(DATABASE::"O365 HTML Template");
        SetTableFieldsToNormal(DATABASE::"O365 Payment Service Logo");
        SetTableFieldsToNormal(DATABASE::"O365 Brand Color");
        SetTableFieldsToNormal(Database::"Customer Templ.");
        SetTableFieldsToNormal(Database::"Item Templ.");
        SetTableFieldsToNormal(Database::"Vendor Templ.");
        SetTableFieldsToNormal(Database::"Employee Templ.");
    end;

    local procedure ClassifyTablesToNormalPart5()
    begin
        SetTableFieldsToNormal(DATABASE::"Contact Alt. Addr. Date Range");
        SetTableFieldsToNormal(DATABASE::"Business Relation");
        SetTableFieldsToNormal(DATABASE::"Contact Business Relation");
        SetTableFieldsToNormal(DATABASE::"Mailing Group");
        SetTableFieldsToNormal(DATABASE::"Contact Mailing Group");
        SetTableFieldsToNormal(DATABASE::"Industry Group");
        SetTableFieldsToNormal(DATABASE::"Contact Industry Group");
        SetTableFieldsToNormal(DATABASE::"Contact Information Buffer");
        SetTableFieldsToNormal(DATABASE::"Web Source");
        SetTableFieldsToNormal(DATABASE::"Contact Web Source");
        SetTableFieldsToNormal(DATABASE::"Rlshp. Mgt. Comment Line");
        SetTableFieldsToNormal(DATABASE::Attachment);
        SetTableFieldsToNormal(DATABASE::"Interaction Group");
        SetTableFieldsToNormal(DATABASE::"Interaction Template");
        SetTableFieldsToNormal(DATABASE::"Job Responsibility");
        SetTableFieldsToNormal(DATABASE::"Contact Job Responsibility");
        SetTableFieldsToNormal(DATABASE::"Merge Duplicates Line Buffer");
        SetTableFieldsToNormal(DATABASE::Salutation);
        SetTableFieldsToNormal(DATABASE::"Salutation Formula");
        SetTableFieldsToNormal(DATABASE::"Organizational Level");
        SetTableFieldsToNormal(DATABASE::Campaign);
        SetTableFieldsToNormal(DATABASE::"Campaign Status");
        SetTableFieldsToNormal(DATABASE::"Delivery Sorter");
        SetTableFieldsToNormal(DATABASE::"Segment Header");
        SetTableFieldsToNormal(DATABASE::"Segment History");
        SetTableFieldsToNormal(DATABASE::Activity);
        SetTableFieldsToNormal(DATABASE::"Activity Step");
        SetTableFieldsToNormal(DATABASE::Team);
        SetTableFieldsToNormal(DATABASE::"Team Salesperson");
        SetTableFieldsToNormal(DATABASE::"Contact Duplicate");
        SetTableFieldsToNormal(DATABASE::"Contact Dupl. Details Buffer");
        SetTableFieldsToNormal(DATABASE::"Cont. Duplicate Search String");
        SetTableFieldsToNormal(DATABASE::"Profile Questionnaire Header");
        SetTableFieldsToNormal(DATABASE::"Profile Questionnaire Line");
        SetTableFieldsToNormal(DATABASE::"Sales Cycle");
        SetTableFieldsToNormal(DATABASE::"Sales Cycle Stage");
        SetTableFieldsToNormal(DATABASE::"Close Opportunity Code");
        SetTableFieldsToNormal(DATABASE::"Duplicate Search String Setup");
        SetTableFieldsToNormal(DATABASE::"Segment Wizard Filter");
        SetTableFieldsToNormal(DATABASE::"Segment Criteria Line");
        SetTableFieldsToNormal(DATABASE::"Saved Segment Criteria Line");
        SetTableFieldsToNormal(DATABASE::"Contact Value");
        SetTableFieldsToNormal(DATABASE::"RM Matrix Management");
        SetTableFieldsToNormal(DATABASE::"Interaction Tmpl. Language");
        SetTableFieldsToNormal(DATABASE::"Segment Interaction Language");
        SetTableFieldsToNormal(DATABASE::Rating);
        SetTableFieldsToNormal(DATABASE::"Interaction Template Setup");
        SetTableFieldsToNormal(DATABASE::"Current Salesperson");
        SetTableFieldsToNormal(DATABASE::"Purch. Comment Line Archive");
        SetTableFieldsToNormal(DATABASE::"Sales Comment Line Archive");
        SetTableFieldsToNormal(DATABASE::"Deferral Header Archive");
        SetTableFieldsToNormal(DATABASE::"Deferral Line Archive");
        SetTableFieldsToNormal(DATABASE::"Alternative Address");
        SetTableFieldsToNormal(DATABASE::Qualification);
        SetTableFieldsToNormal(DATABASE::Relative);
        SetTableFieldsToNormal(DATABASE::"Human Resource Comment Line");
        SetTableFieldsToNormal(DATABASE::Union);
        SetTableFieldsToNormal(DATABASE::"Cause of Inactivity");
        SetTableFieldsToNormal(DATABASE::"Employment Contract");
        SetTableFieldsToNormal(DATABASE::"Employee Statistics Group");
        SetTableFieldsToNormal(DATABASE::"Misc. Article");
        SetTableFieldsToNormal(DATABASE::"Misc. Article Information");
        SetTableFieldsToNormal(DATABASE::Confidential);
        SetTableFieldsToNormal(DATABASE::"Grounds for Termination");
        SetTableFieldsToNormal(DATABASE::"Human Resources Setup");
        SetTableFieldsToNormal(DATABASE::"HR Confidential Comment Line");
        SetTableFieldsToNormal(DATABASE::"Human Resource Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Exchange Folder");
        SetTableFieldsToNormal(DATABASE::"Exchange Service Setup");
        SetTableFieldsToNormal(DATABASE::"CRM Redirect");
        SetTableFieldsToNormal(DATABASE::"CRM Integration Record");
        SetTableFieldsToNormal(DATABASE::"Integration Table Mapping");
        SetTableFieldsToNormal(DATABASE::"Integration Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Man. Integration Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Man. Integration Table Mapping");
        SetTableFieldsToNormal(DATABASE::"Temp Integration Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Man. Int. Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Integration Synch. Job");
        SetTableFieldsToNormal(DATABASE::"CRM Systemuser");
        SetTableFieldsToNormal(DATABASE::"CRM Account");
        SetTableFieldsToNormal(DATABASE::"CRM Contact");
        SetTableFieldsToNormal(DATABASE::"CRM Opportunity");
        SetTableFieldsToNormal(DATABASE::"CRM Post");
        SetTableFieldsToNormal(DATABASE::"CRM Transactioncurrency");
        SetTableFieldsToNormal(DATABASE::"CRM Pricelevel");
        SetTableFieldsToNormal(DATABASE::"CRM Productpricelevel");
        SetTableFieldsToNormal(DATABASE::"CRM Product");
        SetTableFieldsToNormal(DATABASE::"CRM Incident");
        SetTableFieldsToNormal(DATABASE::"CRM Incidentresolution");
        SetTableFieldsToNormal(DATABASE::"CRM Quote");
        SetTableFieldsToNormal(DATABASE::"CDS Company");
        SetTableFieldsToNormal(DATABASE::"CDS Solution");
        SetTableFieldsToNormal(DATABASE::"CDS Teamroles");
        SetTableFieldsToNormal(DATABASE::"CDS Teammembership");
        SetTableFieldsToNormal(DATABASE::"CRM Company");
        SetTableFieldsToNormal(DATABASE::"CRM BC Virtual Table Config.");
    end;

    local procedure ClassifyTablesToNormalPart6()
    begin
        SetTableFieldsToNormal(DATABASE::"CRM Quotedetail");
        SetTableFieldsToNormal(DATABASE::"CRM Salesorder");
        SetTableFieldsToNormal(DATABASE::"CRM Salesorderdetail");
        SetTableFieldsToNormal(DATABASE::"CRM Invoice");
        SetTableFieldsToNormal(DATABASE::"CRM Invoicedetail");
        SetTableFieldsToNormal(DATABASE::"CRM Contract");
        SetTableFieldsToNormal(DATABASE::"CRM Team");
        SetTableFieldsToNormal(DATABASE::"CRM Customeraddress");
        SetTableFieldsToNormal(DATABASE::"CRM Uom");
        SetTableFieldsToNormal(DATABASE::"CRM Uomschedule");
        SetTableFieldsToNormal(DATABASE::"CRM Organization");
        SetTableFieldsToNormal(DATABASE::"CRM Businessunit");
        SetTableFieldsToNormal(DATABASE::"CRM Discount");
        SetTableFieldsToNormal(DATABASE::"CRM Discounttype");
        SetTableFieldsToNormal(DATABASE::"CRM Account Statistics");
        SetTableFieldsToNormal(DATABASE::"CRM NAV Connection");
        SetTableFieldsToNormal(DATABASE::"CRM Synch. Job Status Cue");
        SetTableFieldsToNormal(DATABASE::"CRM Full Synch. Review Line");
        SetTableFieldsToNormal(DATABASE::"Item Variant");
        SetTableFieldsToNormal(DATABASE::"Unit of Measure Translation");
        SetTableFieldsToNormal(DATABASE::"Item Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Line");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Component");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Line");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Capacity Need");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Tool");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Personnel");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Rtng Qlty Meas.");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Comment Line");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Rtng Comment Line");
        SetTableFieldsToNormal(DATABASE::"Prod. Order Comp. Cmt Line");
        SetTableFieldsToNormal(DATABASE::"Planning Error Log");
        SetTableFieldsToNormal(DATABASE::"API Entities Setup");
        SetTableFieldsToNormal(DATABASE::"Sales Invoice Line Aggregate");
        SetTableFieldsToNormal(DATABASE::"Purch. Inv. Line Aggregate");
        SetTableFieldsToNormal(DATABASE::"Aged Report Entity");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Line Entity");
        SetTableFieldsToNormal(DATABASE::"Unplanned Demand");
        SetTableFieldsToNormal(DATABASE::"Timeline Event Change");
        SetTableFieldsToNormal(DATABASE::"Fixed Asset");
        SetTableFieldsToNormal(DATABASE::"FA Setup");
        SetTableFieldsToNormal(DATABASE::"FA Posting Type Setup");
        SetTableFieldsToNormal(DATABASE::"FA Posting Group");
        SetTableFieldsToNormal(DATABASE::"FA Class");
        SetTableFieldsToNormal(DATABASE::"FA Subclass");
        SetTableFieldsToNormal(DATABASE::"FA Location");
        SetTableFieldsToNormal(DATABASE::"Depreciation Book");
        SetTableFieldsToNormal(DATABASE::"FA Depreciation Book");
        SetTableFieldsToNormal(DATABASE::"FA Allocation");
        SetTableFieldsToNormal(DATABASE::"FA Journal Template");
        SetTableFieldsToNormal(DATABASE::"FA Journal Batch");
        SetTableFieldsToNormal(DATABASE::"FA Journal Line");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Template");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Batch");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Line");
        SetTableFieldsToNormal(DATABASE::Maintenance);
        SetTableFieldsToNormal(DATABASE::Insurance);
        SetTableFieldsToNormal(DATABASE::"Insurance Type");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Template");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Line");
        SetTableFieldsToNormal(DATABASE::"Main Asset Component");
        SetTableFieldsToNormal(DATABASE::"Depreciation Table Header");
        SetTableFieldsToNormal(DATABASE::"Depreciation Table Line");
        SetTableFieldsToNormal(DATABASE::"FA Posting Type");
        SetTableFieldsToNormal(DATABASE::"FA Date Type");
        SetTableFieldsToNormal(DATABASE::"FA Matrix Posting Type");
        SetTableFieldsToNormal(DATABASE::"Total Value Insured");
        SetTableFieldsToNormal(DATABASE::"Stockkeeping Unit");
        SetTableFieldsToNormal(DATABASE::"Stockkeeping Unit Comment Line");
        SetTableFieldsToNormal(DATABASE::"Responsibility Center");
        SetTableFieldsToNormal(DATABASE::"Item Substitution");
        SetTableFieldsToNormal(DATABASE::"Substitution Condition");
        SetTableFieldsToNormal(DATABASE::"Item Reference");
        SetTableFieldsToNormal(DATABASE::"Nonstock Item");
        SetTableFieldsToNormal(DATABASE::"Nonstock Item Setup");
        SetTableFieldsToNormal(DATABASE::Manufacturer);
        SetTableFieldsToNormal(DATABASE::Purchasing);
        SetTableFieldsToNormal(DATABASE::"Item Category");
        SetTableFieldsToNormal(DATABASE::"Transfer Line");
        SetTableFieldsToNormal(DATABASE::"Transfer Route");
        SetTableFieldsToNormal(DATABASE::"Transfer Shipment Header");
        SetTableFieldsToNormal(DATABASE::"Transfer Shipment Line");
        SetTableFieldsToNormal(DATABASE::"Transfer Receipt Header");
        SetTableFieldsToNormal(DATABASE::"Transfer Receipt Line");
        SetTableFieldsToNormal(DATABASE::"Inventory Comment Line");
        SetTableFieldsToNormal(DATABASE::"Warehouse Request");
        SetTableFieldsToNormal(DATABASE::"Warehouse Activity Line");
        SetTableFieldsToNormal(DATABASE::"Warehouse Reason Code");
        SetTableFieldsToNormal(DATABASE::"Whse. Cross-Dock Opportunity");
    end;

    local procedure ClassifyTablesToNormalPart7()
    begin
        SetTableFieldsToNormal(DATABASE::"Warehouse Setup");
        SetTableFieldsToNormal(DATABASE::"Warehouse Comment Line");
        SetTableFieldsToNormal(DATABASE::"Warehouse Source Filter");
        SetTableFieldsToNormal(DATABASE::"Registered Whse. Activity Line");
        SetTableFieldsToNormal(DATABASE::"Shipping Agent Services");
        SetTableFieldsToNormal(DATABASE::"Item Charge");
        SetTableFieldsToNormal(DATABASE::"Item Charge Assignment (Purch)");
        SetTableFieldsToNormal(DATABASE::"Item Charge Assignment (Sales)");
        SetTableFieldsToNormal(DATABASE::"Inventory Posting Setup");
        SetTableFieldsToNormal(DATABASE::"Inventory Period");
        SetTableFieldsToNormal(DATABASE::"G/L - Item Ledger Relation");
        SetTableFieldsToNormal(DATABASE::"Availability Calc. Overview");
        SetTableFieldsToNormal(DATABASE::"Standard Cost Worksheet Name");
        SetTableFieldsToNormal(DATABASE::"Standard Cost Worksheet");
        SetTableFieldsToNormal(DATABASE::"Inventory Report Header");
        SetTableFieldsToNormal(DATABASE::"Average Cost Calc. Overview");
        SetTableFieldsToNormal(DATABASE::"Memoized Result");
        SetTableFieldsToNormal(DATABASE::"Item Availability by Date");
        SetTableFieldsToNormal(DATABASE::"BOM Warning Log");
        SetTableFieldsToNormal(DATABASE::"Service Item Line");
        SetTableFieldsToNormal(DATABASE::"Service Order Type");
        SetTableFieldsToNormal(DATABASE::"Service Item Group");
        SetTableFieldsToNormal(DATABASE::"Service Cost");
        SetTableFieldsToNormal(DATABASE::"Service Comment Line");
        SetTableFieldsToNormal(DATABASE::"Service Hour");
        SetTableFieldsToNormal(DATABASE::"Service Mgt. Setup");
        SetTableFieldsToNormal(DATABASE::Loaner);
        SetTableFieldsToNormal(DATABASE::"Fault Area");
        SetTableFieldsToNormal(DATABASE::"Symptom Code");
        SetTableFieldsToNormal(DATABASE::"Fault Reason Code");
        SetTableFieldsToNormal(DATABASE::"Fault Code");
        SetTableFieldsToNormal(DATABASE::"Resolution Code");
        SetTableFieldsToNormal(DATABASE::"Fault/Resol. Cod. Relationship");
        SetTableFieldsToNormal(DATABASE::"Fault Area/Symptom Code");
        SetTableFieldsToNormal(DATABASE::"Repair Status");
        SetTableFieldsToNormal(DATABASE::"Service Status Priority Setup");
        SetTableFieldsToNormal(DATABASE::"Service Shelf");
        SetTableFieldsToNormal(DATABASE::"Service Email Queue");
        SetTableFieldsToNormal(DATABASE::"Service Document Register");
        SetTableFieldsToNormal(DATABASE::"Service Item");
        SetTableFieldsToNormal(DATABASE::"Service Item Component");
        SetTableFieldsToNormal(DATABASE::"Troubleshooting Header");
        SetTableFieldsToNormal(DATABASE::"Troubleshooting Line");
        SetTableFieldsToNormal(DATABASE::"Troubleshooting Setup");
        SetTableFieldsToNormal(DATABASE::"Service Order Allocation");
        SetTableFieldsToNormal(DATABASE::"Resource Location");
        SetTableFieldsToNormal(DATABASE::"Work-Hour Template");
        SetTableFieldsToNormal(DATABASE::"Skill Code");
        SetTableFieldsToNormal(DATABASE::"Resource Skill");
        SetTableFieldsToNormal(DATABASE::"Service Zone");
        SetTableFieldsToNormal(DATABASE::"Resource Service Zone");
        SetTableFieldsToNormal(DATABASE::"Service Contract Line");
        SetTableFieldsToNormal(DATABASE::"Contract Group");
        SetTableFieldsToNormal(DATABASE::"Service Contract Template");
        SetTableFieldsToNormal(DATABASE::"Filed Contract Line");
        SetTableFieldsToNormal(DATABASE::"Contract/Service Discount");
        SetTableFieldsToNormal(DATABASE::"Service Contract Account Group");
        SetTableFieldsToNormal(DATABASE::"Service Shipment Item Line");
        SetTableFieldsToNormal(DATABASE::"Standard Service Code");
        SetTableFieldsToNormal(DATABASE::"Standard Service Line");
        SetTableFieldsToNormal(DATABASE::"Standard Service Item Gr. Code");
        SetTableFieldsToNormal(DATABASE::"Service Price Group");
        SetTableFieldsToNormal(DATABASE::"Serv. Price Group Setup");
        SetTableFieldsToNormal(DATABASE::"Service Price Adjustment Group");
        SetTableFieldsToNormal(DATABASE::"Serv. Price Adjustment Detail");
        SetTableFieldsToNormal(DATABASE::"Service Line Price Adjmt.");
        SetTableFieldsToNormal(DATABASE::"Azure AD App Setup");
        SetTableFieldsToNormal(DATABASE::"Azure AD Mgt. Setup");
        SetTableFieldsToNormal(DATABASE::"Item Tracking Code");
        SetTableFieldsToNormal(DATABASE::"Item Tracking Setup");
        SetTableFieldsToNormal(DATABASE::"Serial No. Information");
        SetTableFieldsToNormal(DATABASE::"Lot No. Information");
        SetTableFieldsToNormal(DATABASE::"Package No. Information");
        SetTableFieldsToNormal(DATABASE::"Item Tracking Comment");
        SetTableFieldsToNormal(DATABASE::"Whse. Item Tracking Line");
        SetTableFieldsToNormal(DATABASE::"Return Reason");
        SetTableFieldsToNormal(DATABASE::"Returns-Related Document");
        SetTableFieldsToNormal(DATABASE::"Exchange Contact");
        SetTableFieldsToNormal(DATABASE::"Booking Service");
        SetTableFieldsToNormal(DATABASE::"Booking Mailbox");
        SetTableFieldsToNormal(DATABASE::"Booking Staff");
        SetTableFieldsToNormal(DATABASE::"Booking Service Mapping");
        SetTableFieldsToNormal(DATABASE::"Booking Item");
        SetTableFieldsToNormal(DATABASE::"Booking Mgr. Setup");
        SetTableFieldsToNormal(DATABASE::"Price Calculation Buffer");
        SetTableFieldsToNormal(DATABASE::"Price Calculation Setup");
        SetTableFieldsToNormal(DATABASE::"Dtld. Price Calculation Setup");
        SetTableFieldsToNormal(DATABASE::"Price List Header");
        SetTableFieldsToNormal(DATABASE::"Price List Line");
        SetTableFieldsToNormal(DATABASE::"Price Asset");
        SetTableFieldsToNormal(DATABASE::"Price Source");
        SetTableFieldsToNormal(DATABASE::"Price Worksheet Line");
#if not CLEAN23
        SetTableFieldsToNormal(DATABASE::"Sales Price");
        SetTableFieldsToNormal(DATABASE::"Sales Line Discount");
        SetTableFieldsToNormal(DATABASE::"Purchase Price");
        SetTableFieldsToNormal(DATABASE::"Purchase Line Discount");
        SetTableFieldsToNormal(DATABASE::"Sales Price Worksheet");
#endif
        SetTableFieldsToNormal(DATABASE::"Campaign Target Group");
        SetTableFieldsToNormal(DATABASE::"Analysis Field Value");
        SetTableFieldsToNormal(DATABASE::"Analysis Report Name");
        SetTableFieldsToNormal(DATABASE::"Analysis Line Template");
        SetTableFieldsToNormal(DATABASE::"Analysis Type");
        SetTableFieldsToNormal(DATABASE::"Analysis Line");
        SetTableFieldsToNormal(DATABASE::"Analysis Column Template");
        SetTableFieldsToNormal(DATABASE::"Analysis Column");
        SetTableFieldsToNormal(DATABASE::"Item Budget Name");
        SetTableFieldsToNormal(DATABASE::"Item Analysis View");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Order Header");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Order Line");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Record Header");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Record Line");
        SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Order Hdr");
        SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Order Line");
        SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Record Hdr");
        SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Record Line");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Comment Line");
        SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Tracking");
#if not CLEAN24
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Tracking");
        SetTableFieldsToNormal(DATABASE::"Exp. Phys. Invt. Tracking");
        SetTableFieldsToNormal(DATABASE::"Pstd. Exp. Phys. Invt. Track");
#endif
        SetTableFieldsToNormal(DATABASE::"Invt. Order Tracking");
        SetTableFieldsToNormal(DATABASE::"Exp. Invt. Order Tracking");
        SetTableFieldsToNormal(DATABASE::"Pstd.Exp.Invt.Order.Tracking");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Count Buffer");
        SetTableFieldsToNormal(DATABASE::"Invt. Document Header");
        SetTableFieldsToNormal(DATABASE::"Invt. Receipt Header");
        SetTableFieldsToNormal(DATABASE::"Invt. Receipt Line");
        SetTableFieldsToNormal(DATABASE::"Invt. Document Line");
        SetTableFieldsToNormal(DATABASE::"Invt. Shipment Header");
        SetTableFieldsToNormal(DATABASE::"Invt. Shipment Line");
        SetTableFieldsToNormal(DATABASE::"Direct Trans. Header");
        SetTableFieldsToNormal(DATABASE::"Direct Trans. Line");
    end;

    local procedure ClassifyTablesToNormalPart8()
    begin
        SetTableFieldsToNormal(DATABASE::"Item Analysis View Filter");
        SetTableFieldsToNormal(DATABASE::Zone);
        SetTableFieldsToNormal(DATABASE::"Bin Content");
        SetTableFieldsToNormal(DATABASE::"Bin Type");
        SetTableFieldsToNormal(DATABASE::"Warehouse Class");
        SetTableFieldsToNormal(DATABASE::"Special Equipment");
        SetTableFieldsToNormal(DATABASE::"Put-away Template Header");
        SetTableFieldsToNormal(DATABASE::"Put-away Template Line");
        SetTableFieldsToNormal(DATABASE::"Warehouse Journal Template");
        SetTableFieldsToNormal(DATABASE::"Warehouse Receipt Line");
        SetTableFieldsToNormal(DATABASE::"Posted Whse. Receipt Line");
        SetTableFieldsToNormal(DATABASE::"Warehouse Shipment Line");
        SetTableFieldsToNormal(DATABASE::"Posted Whse. Shipment Line");
        SetTableFieldsToNormal(DATABASE::"Whse. Put-away Request");
        SetTableFieldsToNormal(DATABASE::"Whse. Pick Request");
        SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Line");
        SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Name");
        SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Template");
        SetTableFieldsToNormal(DATABASE::"Whse. Internal Put-away Line");
        SetTableFieldsToNormal(DATABASE::"Whse. Internal Pick Line");
        SetTableFieldsToNormal(DATABASE::"Allocation Policy");
        SetTableFieldsToNormal(DATABASE::"Reservation Wksh. Batch");
        SetTableFieldsToNormal(DATABASE::"Reservation Wksh. Line");
        SetTableFieldsToNormal(DATABASE::"Reservation Worksheet Log");
        SetTableFieldsToNormal(DATABASE::"Bin Template");
        SetTableFieldsToNormal(DATABASE::"Bin Creation Wksh. Template");
        SetTableFieldsToNormal(DATABASE::"Bin Creation Wksh. Name");
        SetTableFieldsToNormal(DATABASE::"Posted Invt. Put-away Line");
        SetTableFieldsToNormal(DATABASE::"Posted Invt. Pick Line");
        SetTableFieldsToNormal(DATABASE::"Registered Invt. Movement Line");
        SetTableFieldsToNormal(DATABASE::"Internal Movement Line");
        SetTableFieldsToNormal(DATABASE::Bin);
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Item Selection");
        SetTableFieldsToNormal(DATABASE::"Phys. Invt. Counting Period");
        SetTableFieldsToNormal(DATABASE::"Item Attribute");
        SetTableFieldsToNormal(DATABASE::"Item Attribute Value");
        SetTableFieldsToNormal(DATABASE::"Item Attribute Translation");
        SetTableFieldsToNormal(DATABASE::"Item Attr. Value Translation");
        SetTableFieldsToNormal(DATABASE::"Item Attribute Value Selection");
        SetTableFieldsToNormal(DATABASE::"Item Attribute Value Mapping");
        SetTableFieldsToNormal(DATABASE::"Base Calendar");
        SetTableFieldsToNormal(DATABASE::"Base Calendar Change");
        SetTableFieldsToNormal(DATABASE::"Customized Calendar Change");
        SetTableFieldsToNormal(DATABASE::"Where Used Base Calendar");
        SetTableFieldsToNormal(DATABASE::"Miniform Header");
        SetTableFieldsToNormal(DATABASE::"Miniform Line");
        SetTableFieldsToNormal(DATABASE::"Miniform Function Group");
        SetTableFieldsToNormal(DATABASE::"Miniform Function");
        SetTableFieldsToNormal(DATABASE::"Item Identifier");
        SetTableFieldsToNormal(DATABASE::"MS-QBD Setup");
        SetTableFieldsToNormal(DATABASE::"Dimensions Field Map");
        SetTableFieldsToNormal(DATABASE::"Record Set Definition");
        SetTableFieldsToNormal(DATABASE::"Config. Questionnaire");
        SetTableFieldsToNormal(DATABASE::"Config. Question Area");
        SetTableFieldsToNormal(DATABASE::"Config. Question");
        SetTableFieldsToNormal(DATABASE::"Config. Package Record");
        SetTableFieldsToNormal(DATABASE::"Config. Package Data");
        SetTableFieldsToNormal(DATABASE::"Config. Package Field");
        SetTableFieldsToNormal(DATABASE::"Config. Template Header");
        SetTableFieldsToNormal(DATABASE::"Config. Template Line");
        SetTableFieldsToNormal(DATABASE::"Config. Tmpl. Selection Rules");
        SetTableFieldsToNormal(DATABASE::"Config. Selection");
        SetTableFieldsToNormal(DATABASE::"Config. Package");
        SetTableFieldsToNormal(DATABASE::"Config. Related Field");
        SetTableFieldsToNormal(DATABASE::"Config. Related Table");
        SetTableFieldsToNormal(DATABASE::"Config. Package Filter");
        SetTableFieldsToNormal(DATABASE::"Config. Setup");
        SetTableFieldsToNormal(DATABASE::"Config. Field Map");
        SetTableFieldsToNormal(DATABASE::"Config. Table Processing Rule");
        SetTableFieldsToNormal(DATABASE::"Config. Record For Processing");
#if not CLEAN22
        SetTableFieldsToNormal(DATABASE::"User Group");
        SetTableFieldsToNormal(DATABASE::"User Group Permission Set");
        SetTableFieldsToNormal(DATABASE::"User Group Plan");
#endif
        SetTableFieldsToNormal(9020); // Security Group
        SetTableFieldsToNormal(DATABASE::"Team Member Cue");
        SetTableFieldsToNormal(DATABASE::"Warehouse Basic Cue");
        SetTableFieldsToNormal(DATABASE::"Warehouse WMS Cue");
        SetTableFieldsToNormal(DATABASE::"Service Cue");
        SetTableFieldsToNormal(DATABASE::"Sales Cue");
        SetTableFieldsToNormal(DATABASE::"Finance Cue");
        SetTableFieldsToNormal(DATABASE::"Purchase Cue");
        SetTableFieldsToNormal(DATABASE::"Manufacturing Cue");
        SetTableFieldsToNormal(DATABASE::"Job Cue");
        SetTableFieldsToNormal(DATABASE::"Warehouse Worker WMS Cue");
        SetTableFieldsToNormal(DATABASE::"Administration Cue");
        SetTableFieldsToNormal(DATABASE::"SB Owner Cue");
        SetTableFieldsToNormal(DATABASE::"RapidStart Services Cue");
        SetTableFieldsToNormal(DATABASE::"User Security Status");
        SetTableFieldsToNormal(DATABASE::"Relationship Mgmt. Cue");
    end;

    local procedure ClassifyTablesToNormalPart9()
    begin
        SetTableFieldsToNormal(DATABASE::"Accounting Services Cue");
        SetTableFieldsToNormal(DATABASE::"Autocomplete Address");
        SetTableFieldsToNormal(DATABASE::"Postcode Service Config");
        SetTableFieldsToNormal(DATABASE::"Experience Tier Setup");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Filter");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Y-Axis");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Query Column");
        SetTableFieldsToNormal(DATABASE::"Terms And Conditions");
        SetTableFieldsToNormal(DATABASE::"Media Repository");
        SetTableFieldsToNormal(DATABASE::"Email Item");
        SetTableFieldsToNormal(DATABASE::"Email Parameter");
        SetTableFieldsToNormal(DATABASE::"XML Schema");
        SetTableFieldsToNormal(DATABASE::"XML Schema Element");
        SetTableFieldsToNormal(DATABASE::"XML Schema Restriction");
        SetTableFieldsToNormal(DATABASE::"Referenced XML Schema");
        SetTableFieldsToNormal(DATABASE::"Report Layout Selection");
        SetTableFieldsToNormal(DATABASE::"Report Layout Update Log");
        SetTableFieldsToNormal(DATABASE::"Custom Report Selection");
        SetTableFieldsToNormal(DATABASE::"Table Filter");
        SetTableFieldsToNormal(DATABASE::"Web Service Aggregate");
        SetTableFieldsToNormal(DATABASE::"CAL Test Suite");
        SetTableFieldsToNormal(DATABASE::"CAL Test Line");
        SetTableFieldsToNormal(DATABASE::"CAL Test Codeunit");
        SetTableFieldsToNormal(DATABASE::"CAL Test Enabled Codeunit");
        SetTableFieldsToNormal(DATABASE::"CAL Test Method");
        SetTableFieldsToNormal(DATABASE::"CAL Test Result");
        SetTableFieldsToNormal(DATABASE::"CAL Test Coverage Map");
        SetTableFieldsToNormal(DATABASE::"Semi-Manual Test Wizard");
        SetTableFieldsToNormal(DATABASE::"Semi-Manual Execution Log");
        SetTableFieldsToNormal(DATABASE::"Work Shift");
        SetTableFieldsToNormal(DATABASE::"Company Size");
    end;

    local procedure ClassifyTablesToNormalPart10()
    begin
        SetTableFieldsToNormal(DATABASE::"Shop Calendar");
        SetTableFieldsToNormal(DATABASE::"Shop Calendar Working Days");
        SetTableFieldsToNormal(DATABASE::"Shop Calendar Holiday");
        SetTableFieldsToNormal(DATABASE::"Work Center Group");
        SetTableFieldsToNormal(DATABASE::"Machine Center");
        SetTableFieldsToNormal(DATABASE::Stop);
        SetTableFieldsToNormal(DATABASE::Scrap);
        SetTableFieldsToNormal(DATABASE::"Routing Header");
        SetTableFieldsToNormal(DATABASE::"Routing Line");
        SetTableFieldsToNormal(DATABASE::"Manufacturing Setup");
        SetTableFieldsToNormal(DATABASE::"Manufacturing Comment Line");
        SetTableFieldsToNormal(DATABASE::"Production BOM Header");
        SetTableFieldsToNormal(DATABASE::"Production BOM Line");
        SetTableFieldsToNormal(DATABASE::Family);
        SetTableFieldsToNormal(DATABASE::"Family Line");
        SetTableFieldsToNormal(DATABASE::"Routing Comment Line");
        SetTableFieldsToNormal(DATABASE::"Production BOM Comment Line");
        SetTableFieldsToNormal(DATABASE::"Routing Link");
        SetTableFieldsToNormal(DATABASE::"Standard Task");
        SetTableFieldsToNormal(DATABASE::"Production BOM Version");
        SetTableFieldsToNormal(DATABASE::"Capacity Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Standard Task Tool");
        SetTableFieldsToNormal(DATABASE::"Standard Task Personnel");
        SetTableFieldsToNormal(DATABASE::"Standard Task Description");
        SetTableFieldsToNormal(DATABASE::"Standard Task Quality Measure");
        SetTableFieldsToNormal(DATABASE::"Quality Measure");
        SetTableFieldsToNormal(DATABASE::"Routing Version");
        SetTableFieldsToNormal(DATABASE::"Production Matrix BOM Line");
        SetTableFieldsToNormal(DATABASE::"Where-Used Line");
        SetTableFieldsToNormal(DATABASE::"Sales Planning Line");
        SetTableFieldsToNormal(DATABASE::"Routing Tool");
        SetTableFieldsToNormal(DATABASE::"Routing Personnel");
        SetTableFieldsToNormal(DATABASE::"Routing Quality Measure");
        SetTableFieldsToNormal(DATABASE::"Planning Component");
        SetTableFieldsToNormal(DATABASE::"Planning Routing Line");
        SetTableFieldsToNormal(DATABASE::"Item Availability Line");
        SetTableFieldsToNormal(DATABASE::"Registered Absence");
        SetTableFieldsToNormal(DATABASE::"Planning Assignment");
        SetTableFieldsToNormal(DATABASE::"Production Forecast Name");
        SetTableFieldsToNormal(Database::"Forecast Item Variant Loc");
        SetTableFieldsToNormal(DATABASE::"Inventory Profile");
        SetTableFieldsToNormal(DATABASE::"Untracked Planning Element");
        SetTableFieldsToNormal(DATABASE::"Capacity Constrained Resource");
        SetTableFieldsToNormal(DATABASE::"Order Promising Setup");
        SetTableFieldsToNormal(DATABASE::"Order Promising Line");
        SetTableFieldsToNormal(DATABASE::"Incoming Document Attachment");
        SetTableFieldsToNormal(DATABASE::"License Agreement");
        SetTableFieldsToNormal(DATABASE::"G/L Entry - VAT Entry Link");
        SetTableFieldsToNormal(DATABASE::"Document Entry");
        SetTableFieldsToNormal(DATABASE::"Entry/Exit Point");
        SetTableFieldsToNormal(DATABASE::"Entry Summary");
        SetTableFieldsToNormal(DATABASE::"Analysis View Entry");
        SetTableFieldsToNormal(DATABASE::"Analysis View Budget Entry");
        SetTableFieldsToNormal(DATABASE::"Workflow Webhook Notification");
        SetTableFieldsToNormal(DATABASE::"Workflow Webhook Subscription");
        SetTableFieldsToNormal(DATABASE::"Report Inbox");
        SetTableFieldsToNormal(DATABASE::"Dimension Set Entry");
        SetTableFieldsToNormal(DATABASE::"Change Global Dim. Log Entry");
        SetTableFieldsToNormal(DATABASE::"Business Chart User Setup");
        SetTableFieldsToNormal(DATABASE::"Finance Charge Interest Rate");
        SetTableFieldsToNormal(DATABASE::"VAT Report Line");
        SetTableFieldsToNormal(DATABASE::"Trailing Sales Orders Setup");
        SetTableFieldsToNormal(DATABASE::"Account Schedules Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. Chart Setup Line");
        SetTableFieldsToNormal(DATABASE::"Analysis Report Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Analysis Report Chart Line");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Forecast");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Assembly Header");
        SetTableFieldsToNormal(DATABASE::"Time Sheet Posting Entry");
        SetTableFieldsToNormal(DATABASE::"Payment Registration Setup");
        SetTableFieldsToNormal(DATABASE::"Job WIP Entry");
        SetTableFieldsToNormal(DATABASE::"Job WIP G/L Entry");
        SetTableFieldsToNormal(DATABASE::"Job Entry No.");
        SetTableFieldsToNormal(DATABASE::"User Task");
        SetTableFieldsToNormal(DATABASE::"User Task Group");
        SetTableFieldsToNormal(DATABASE::"User Task Group Member");
        SetTableFieldsToNormal(DATABASE::"Credit Trans Re-export History");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Entry");
        SetTableFieldsToNormal(DATABASE::"OCR Service Setup");
        SetTableFieldsToNormal(DATABASE::"Doc. Exch. Service Setup");
        SetTableFieldsToNormal(DATABASE::"User Preference");
        SetTableFieldsToNormal(DATABASE::"O365 Getting Started");
        SetTableFieldsToNormal(DATABASE::"User Tours");
        SetTableFieldsToNormal(DATABASE::"Sales by Cust. Grp.Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Role Center Notifications");
        SetTableFieldsToNormal(1433); // Net Promoter Score
        SetTableFieldsToNormal(DATABASE::"Notification Setup");
        SetTableFieldsToNormal(DATABASE::"Notification Schedule");
        SetTableFieldsToNormal(DATABASE::"My Notifications");
        SetTableFieldsToNormal(DATABASE::"Workflow User Group Member");
        SetTableFieldsToNormal(DATABASE::"Exchange Object");
        SetTableFieldsToNormal(DATABASE::"Payroll Setup");
        SetTableFieldsToNormal(DATABASE::"Approval Workflow Wizard");
        SetTableFieldsToNormal(DATABASE::"Calendar Event User Config.");
    end;

    local procedure ClassifyTablesToNormalPart11()
    begin
        SetTableFieldsToNormal(DATABASE::"Inter. Log Entry Comment Line");
        SetTableFieldsToNormal(DATABASE::"To-do Interaction Language");
        SetTableFieldsToNormal(DATABASE::"CRM Connection Setup");
        SetTableFieldsToNormal(DATABASE::"Production Order");
        SetTableFieldsToNormal(DATABASE::"Transfer Header");
        SetTableFieldsToNormal(DATABASE::"Registered Whse. Activity Hdr.");
        SetTableFieldsToNormal(DATABASE::"Avg. Cost Adjmt. Entry Point");
        SetTableFieldsToNormal(DATABASE::"Post Value Entry to G/L");
        SetTableFieldsToNormal(DATABASE::"Inventory Report Entry");
        SetTableFieldsToNormal(DATABASE::"Inventory Adjmt. Entry (Order)");
        SetTableFieldsToNormal(Database::"Cost Adj. Item Bucket");
        SetTableFieldsToNormal(Database::"Cost Adjustment Detailed Log");
        SetTableFieldsToNormal(Database::"Cost Adjustment Log");
#if not CLEAN22
        SetTableFieldsToNormal(DATABASE::"Power BI Service Status Setup");
#endif
#if not CLEAN23
        SetTableFieldsToNormal(DATABASE::"Power BI User Configuration");
        SetTableFieldsToNormal(DATABASE::"Power BI Report Configuration");
        SetTableFieldsToNormal(DATABASE::"Power BI User Status");
#endif
        SetTableFieldsToNormal(DATABASE::"Power BI Selection Element");
        SetTableFieldsToNormal(DATABASE::"Power BI Displayed Element");
        SetTableFieldsToNormal(DATABASE::"Power BI Report Uploads");
        SetTableFieldsToNormal(DATABASE::"Power BI Context Settings");
        SetTableFieldsToNormal(DATABASE::"Power BI Customer Reports");
        SetTableFieldsToNormal(DATABASE::"Power BI Blob");
        SetTableFieldsToNormal(DATABASE::"Power BI Default Selection");
        SetTableFieldsToNormal(DATABASE::"Profile Designer Diagnostic");
        SetTableFieldsToNormal(DATABASE::"Designer Diagnostic");
        SetTableFieldsToNormal(DATABASE::"Profile Import");
        SetTableFieldsToNormal(DATABASE::"Item Entry Relation");
        SetTableFieldsToNormal(DATABASE::"Value Entry Relation");
        SetTableFieldsToNormal(DATABASE::"Whse. Item Entry Relation");
        SetTableFieldsToNormal(DATABASE::"Warehouse Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Warehouse Receipt Header");
        SetTableFieldsToNormal(DATABASE::"Posted Whse. Receipt Header");
        SetTableFieldsToNormal(DATABASE::"Warehouse Shipment Header");
        SetTableFieldsToNormal(DATABASE::"Posted Whse. Shipment Header");
        SetTableFieldsToNormal(DATABASE::"Whse. Internal Put-away Header");
        SetTableFieldsToNormal(DATABASE::"Whse. Internal Pick Header");
        SetTableFieldsToNormal(DATABASE::"Internal Movement Header");
        SetTableFieldsToNormal(DATABASE::"ADCS User");
        SetTableFieldsToNormal(9004); // Plan
        SetTableFieldsToNormal(9008); // User Login
        SetTableFieldsToNormal(9010); // "Azure AD User Update"
        SetTableFieldsToNormal(DATABASE::"Calendar Entry");
        SetTableFieldsToNormal(DATABASE::"Calendar Absence Entry");
        SetTableFieldsToNormal(DATABASE::"Production Matrix  BOM Entry");
        SetTableFieldsToNormal(DATABASE::"Order Tracking Entry");
        SetTableFieldsToNormal(DATABASE::"Action Message Entry");
        SetTableFieldsToNormal(DATABASE::"Production Forecast Entry");
        SetTableFieldsToNormal(DATABASE::"Record Link");
        SetTableFieldsToNormal(DATABASE::"Document Service");
        SetTableFieldsToNormal(DATABASE::"Data Privacy Entities");
        SetTableFieldsToNormal(DATABASE::"Isolated Certificate");
        SetTableFieldsToNormal(DATABASE::"No. Series Tenant");
        SetTableFieldsToNormal(DATABASE::"OAuth 2.0 Setup");
        SetTableFieldsToNormal(DATABASE::"Item Picture Buffer");
        SetTableFieldsToNormal(DATABASE::"SWIFT Code");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Cache Info");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Cache");
        SetTableFieldsToNormal(3712); // Translation
        SetTableFieldsToNormal(DATABASE::"CRM Synch Status");
        SetTableFieldsToNormal(Database::"Over-Receipt Code");
        SetTableFieldsToNormal(DATABASE::"Designed Query");
        SetTableFieldsToNormal(DATABASE::"Designed Query Caption");
        SetTableFieldsToNormal(DATABASE::"Designed Query Category");
        SetTableFieldsToNormal(DATABASE::"Designed Query Column Filter");
        SetTableFieldsToNormal(DATABASE::"Designed Query Column");
        SetTableFieldsToNormal(DATABASE::"Designed Query Data Item");
        SetTableFieldsToNormal(DATABASE::"Designed Query Filter");
        SetTableFieldsToNormal(DATABASE::"Designed Query Join");
        SetTableFieldsToNormal(DATABASE::"Designed Query Order By");
        SetTableFieldsToNormal(Database::"Dim Correct Selection Criteria");
        SetTableFieldsToNormal(Database::"Dim Correction Blocked Setup");
        SetTableFieldsToNormal(Database::"Dim Correction Change");
        SetTableFieldsToNormal(Database::"Dim Correction Set Buffer");
        SetTableFieldsToNormal(Database::"Dim Correction Entry Log");
        SetTableFieldsToNormal(Database::"Dimension Correction");
        SetTableFieldsToNormal(Database::"Invalidated Dim Correction");
        SetTableFieldsToNormal(Database::"Retention Period");
        SetTableFieldsToNormal(Database::"Retention Policy Setup");
        SetTableFieldsToNormal(Database::"Retention Policy Setup Line");
        SetTableFieldsToNormal(3903); // Database::"Reten. Pol. Allowed Table"
        SetTableFieldsToNormal(Database::"Feature Data Update Status");
        SetTableFieldsToNormal(Database::"OData Initialized Status");
        SetTableFieldsToNormal(149000); // Database::"BCPT Header"
        SetTableFieldsToNormal(149001); // Database::"BCPT Line"
        SetTableFieldsToNormal(149002); // Database::"BCPT Log Entry"
        SetTableFieldsToNormal(149003); // Database::"BCPT Parameter Line"
        SetTableFieldsToNormal(DATABASE::"Availability Info. Buffer");
        SetTableFieldsToNormal(Database::"IC Setup");
        SetTableFieldsToNormal(Database::"Net Balances Parameters");
        SetTableFieldsToNormal(9017); // Database::"Plan Configuration"
        SetTableFieldsToNormal(Database::"Buffer IC Comment Line");
        SetTableFieldsToNormal(Database::"Buffer IC Document Dimension");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Jnl. Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Purch Header");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Purchase Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Header");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Transaction");
        SetTableFieldsToNormal(Database::"Buffer IC InOut Jnl. Line Dim.");
        SetTableFieldsToNormal(Database::"IC Incoming Notification");
        SetTableFieldsToNormal(Database::"IC Outgoing Notification");
    end;

    procedure SetTableFieldsToNormal(TableNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
    end;

    local procedure SetFieldToPersonal(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToPersonal(TableNo, FieldNo);
    end;

    local procedure SetFieldToSensitive(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToSensitive(TableNo, FieldNo);
    end;

    local procedure SetFieldToCompanyConfidential(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, FieldNo);
    end;

    local procedure ClassifyCouplingRecordBuffer()
    var
        DummyCouplingRecordBuffer: Record "Coupling Record Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Coupling Record Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCouplingRecordBuffer.FieldNo("NAV Record ID"));
    end;

    local procedure ClassifyCRMAnnotationBuffer()
    var
        DummyCRMAnnotationBuffer: Record "CRM Annotation Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Annotation Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationBuffer.FieldNo("Related Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationBuffer.FieldNo("Record ID"));
    end;

    local procedure ClassifyCRMAnnotationCoupling()
    var
        DummyCRMAnnotationCoupling: Record "CRM Annotation Coupling";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Annotation Coupling";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationCoupling.FieldNo("Record Link Record ID"));
    end;

    local procedure ClassifyAllocationAccounts()
    begin
        SetTableFieldsToNormal(DATABASE::"Alloc. Acc. Manual Override");
        SetTableFieldsToNormal(DATABASE::"Alloc. Account Distribution");
        SetTableFieldsToNormal(DATABASE::"Allocation Account");
        SetTableFieldsToNormal(DATABASE::"Allocation Line");
    end;

    local procedure ClassifyCRMPostBuffer()
    var
        DummyCRMPostBuffer: Record "CRM Post Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Post Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMPostBuffer.FieldNo(RecId));
    end;

    local procedure ClassifyCRMSynchConflictBuffer()
    var
        DummyCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Synch. Conflict Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMSynchConflictBuffer.FieldNo("Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCRMSynchConflictBuffer.FieldNo("Int. Record ID"));
    end;

    local procedure ClassifyInventoryEventBuffer()
    var
        DummyInventoryEventBuffer: Record "Inventory Event Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Event Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInventoryEventBuffer.FieldNo("Source Line ID"));
    end;

    local procedure ClassifyItemTracingBuffer()
    var
        DummyItemTracingBuffer: Record "Item Tracing Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Tracing Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemTracingBuffer.FieldNo("Record Identifier"));
    end;

    local procedure ClassifyMergeDuplicatesBuffer()
    var
        DummyMergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Merge Duplicates Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesBuffer.FieldNo("Duplicate Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesBuffer.FieldNo("Current Record ID"));
    end;

    local procedure ClassifyMergeDuplicatesConflict()
    var
        DummyMergeDuplicatesConflict: Record "Merge Duplicates Conflict";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Merge Duplicates Conflict";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesConflict.FieldNo(Duplicate));
        SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesConflict.FieldNo(Current));
    end;

    local procedure ClassifyRecordSetBuffer()
    var
        DummyRecordSetBuffer: Record "Record Set Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Set Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordSetBuffer.FieldNo("Value RecordID"));
    end;

    local procedure ClassifyRecordBuffer()
    var
        DummyRecordBuffer: Record "Record Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordBuffer.FieldNo("Record Identifier"));
    end;

    local procedure ClassifyRecordExportBuffer()
    var
        DummyRecordExportBuffer: Record "Record Export Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Export Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordExportBuffer.FieldNo(RecordID));
    end;

    local procedure ClassifyParallelSessionEntry()
    var
        DummyParallelSessionEntry: Record "Parallel Session Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Parallel Session Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyParallelSessionEntry.FieldNo("Record ID to Process"));
    end;

    local procedure ClassifyWorkflowsEntriesBuffer()
    var
        DummyWorkflowsEntriesBuffer: Record "Workflows Entries Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflows Entries Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowsEntriesBuffer.FieldNo("Record ID"));
    end;

    local procedure ClassifyTenantWebServiceOData()
    var
        DummyTenantWebServiceOData: Record "Tenant Web Service OData";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service OData";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceOData.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyTenantWebServiceColumns()
    var
        DummyTenantWebServiceColumns: Record "Tenant Web Service Columns";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service Columns";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceColumns.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyTenantWebServiceFilter()
    var
        DummyTenantWebServiceFilter: Record "Tenant Web Service Filter";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service Filter";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceFilter.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyWorkflowWebhookEntry()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Webhook Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowWebhookEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowTableRelationValue()
    var
        DummyWorkflowTableRelationValue: Record "Workflow Table Relation Value";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Table Relation Value";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowTableRelationValue.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowRecordChangeArchive()
    var
        DummyWorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Record Change Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowRecordChangeArchive.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowRecordChange()
    var
        DummyWorkflowWorkflowRecordChange: Record "Workflow - Record Change";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow - Record Change";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowWorkflowRecordChange.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowEventQueue()
    var
        DummyWorkflowEventQueue: Record "Workflow Event Queue";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Event Queue";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowEventQueue.FieldNo("Step Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowEventQueue.FieldNo("Record ID"));
    end;

    local procedure ClassifyVATRateChangeLogEntry()
    var
        DummyVATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Rate Change Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyVATRateChangeLogEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyTimelineEvent()
    var
        DummyTimelineEvent: Record "Timeline Event";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Timeline Event";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTimelineEvent.FieldNo("Source Line ID"));
        SetFieldToCompanyConfidential(TableNo, DummyTimelineEvent.FieldNo("Source Document ID"));
    end;

    local procedure ClassifyTempStack()
    var
        DummyTempStack: Record TempStack;
        TableNo: Integer;
    begin
        TableNo := DATABASE::TempStack;
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTempStack.FieldNo(Value));
    end;

    local procedure ClassifyStandardAddress()
    var
        DummyStandardAddress: Record "Standard Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Standard Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyStandardAddress.FieldNo("Related RecordID"));
    end;

    local procedure ClassifyServiceConnection()
    var
        DummyServiceConnection: Record "Service Connection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Connection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyServiceConnection.FieldNo("Record ID"));
    end;

    local procedure ClassifyRestrictedRecord()
    var
        DummyRestrictedRecord: Record "Restricted Record";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Restricted Record";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRestrictedRecord.FieldNo("Record ID"));
    end;

    local procedure ClassifyRecordSetTree()
    var
        DummyRecordSetTree: Record "Record Set Tree";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Set Tree";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordSetTree.FieldNo(Value));
    end;

    local procedure ClassifyPaymentServiceSetup()
    var
        DummyPaymentServiceSetup: Record "Payment Service Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payment Service Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPaymentServiceSetup.FieldNo("Setup Record ID"));
    end;

    local procedure ClassifyPaymentReportingArgument()
    var
        DummyPaymentReportingArgument: Record "Payment Reporting Argument";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payment Reporting Argument";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPaymentReportingArgument.FieldNo("Document Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPaymentReportingArgument.FieldNo("Setup Record ID"));
    end;

    local procedure ClassifyNotificationContext()
    var
        DummyClassifyNotificationContext: Record "Notification Context";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Notification Context";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyClassifyNotificationContext.FieldNo("Record ID"));
    end;

    local procedure ClassifyInventoryPageData()
    var
        DummyInventoryPageData: Record "Inventory Page Data";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Page Data";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPageData.FieldNo("Source Line ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPageData.FieldNo("Source Document ID"));
    end;

    local procedure ClassifyIntegrationSynchJobErrors()
    var
        DummyIntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Integration Synch. Job Errors";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyIntegrationSynchJobErrors.FieldNo("Source Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyIntegrationSynchJobErrors.FieldNo("Destination Record ID"));
    end;

    local procedure ClassifyErrorMessage()
    var
        DummyErrorMessage: Record "Error Message";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Error Message";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyErrorMessage.FieldNo("Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyErrorMessage.FieldNo("Context Record ID"));
    end;

    local procedure ClassifyDataMigrationParameters()
    var
        DummyDataMigrationParameters: Record "Data Migration Parameters";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Migration Parameters";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataMigrationParameters.FieldNo("Staging Table RecId To Process"));
    end;

    local procedure ClassifyDataMigrationError()
    var
        DummyDataMigrationError: Record "Data Migration Error";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Migration Error";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataMigrationError.FieldNo("Source Staging Table Record ID"));
    end;

    local procedure ClassifyDataExch()
    var
        DummyDataExch: Record "Data Exch.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Exch.";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataExch.FieldNo("Related Record"));
    end;

    local procedure ClassifyCRMOptionMapping()
    var
        DummyCRMOptionMapping: Record "CRM Option Mapping";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Option Mapping";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMOptionMapping.FieldNo("Record ID"));
    end;

    local procedure ClassifyBatchProcessingSessionMap()
    var
        DummyBatchProcessingSessionMap: Record "Batch Processing Session Map";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Batch Processing Session Map";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBatchProcessingSessionMap.FieldNo("Record ID"));
    end;

    local procedure ClassifyConfigPackageError()
    var
        DummyConfigPackageError: Record "Config. Package Error";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Package Error";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyConfigPackageError.FieldNo("Record ID"));
    end;

    local procedure ClassifyBankAccount()
    var
        DummyBankAccount: Record "Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBankAccount.FieldNo("Bank Stmt. Service Record ID"));
    end;

    local procedure ClassifyCreditTransferEntry()
    var
        DummyCreditTransferEntry: Record "Credit Transfer Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Credit Transfer Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Message to Recipient"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Bank Acc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient IBAN"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transaction ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transfer Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transfer Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Credit Transfer Register No."));
    end;

    local procedure ClassifyActiveSession()
    var
        DummyActiveSession: Record "Active Session";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Active Session";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("Session Unique ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("Session ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("User SID"));
    end;

    local procedure ClassifyRegisteredInvtMovementHdr()
    var
        DummyRegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Registered Invt. Movement Hdr.";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyRegisteredInvtMovementHdr.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifySEPADirectDebitMandate()
    var
        DummySEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"SEPA Direct Debit Mandate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(Closed));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Debit Counter"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Expected Number of Debits"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(Blocked));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Type of Payment"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Date of Signature"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Valid To"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Valid From"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Customer Bank Account Code"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(ID));
    end;

    local procedure ClassifyPostedAssemblyHeader()
    var
        DummyPostedAssemblyHeader: Record "Posted Assembly Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Assembly Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedAssemblyHeader.FieldNo("User ID"));
    end;

    local procedure ClassifyPostedInvtPickHeader()
    var
        DummyPostedInvtPickHeader: Record "Posted Invt. Pick Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Invt. Pick Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedInvtPickHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyPostedInvtPutawayHeader()
    var
        DummyPostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Invt. Put-away Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedInvtPutAwayHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyPurchInvEntityAggregate()
    var
        DummyPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Entity Aggregate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Order No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Invoice No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Country/Region Code"));
    end;

    local procedure ClassifySalesInvoiceEntityAggregate()
    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Entity Aggregate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Order No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Liable"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Bus. Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Calculation"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Value"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(IsTest));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Subtotal Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Contact Graph Id"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Country/Region Code"));
    end;

    local procedure ClassifyWarehouseEntry()
    var
        DummyWarehouseEntry: Record "Warehouse Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Dedicated));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Phys Invt Counting Period Type"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Phys Invt Counting Period Code"));
        SetFieldToPersonal(TableNo, DummyWarehouseEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Serial No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reference No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reference Document"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Warranty Date"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Journal Template Name"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Weight));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Cubage));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Lot No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Expiration Date"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Bin Type Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Document"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Subline No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Subtype"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Qty. (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Bin Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Zone Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Registering Date"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyWarehouseJournalLine()
    var
        DummyWarehouseJournalLine: Record "Warehouse Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Journal Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWarehouseJournalLine.FieldNo("User ID"));
    end;

    local procedure ClassifyWarehouseEmployee()
    var
        DummyWarehouseEmployee: Record "Warehouse Employee";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Employee";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWarehouseEmployee.FieldNo("ADCS User"));
        SetFieldToPersonal(TableNo, DummyWarehouseEmployee.FieldNo("User ID"));
    end;

    local procedure ClassifyContactAltAddress()
    var
        DummyContactAltAddress: Record "Contact Alt. Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contact Alt. Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Search E-Mail"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(Pager));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Mobile Phone No."));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Extension No."));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Company Name 2"));
        SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Company Name"));
    end;

    local procedure ClassifyCashFlowForecastEntry()
    var
        DummyCashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cash Flow Forecast Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("G/L Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Recurring Method"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Associated Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Associated Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Payment Discount"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Overdue));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Forecast No."));
        SetFieldToPersonal(TableNo, DummyCashFlowForecastEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyDirectDebitCollection()
    var
        DummyDirectDebitCollection: Record "Direct Debit Collection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Direct Debit Collection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyDirectDebitCollection.FieldNo("Created by User"));
    end;

    local procedure ClassifyActivityLog()
    var
        DummyActivityLog: Record "Activity Log";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Activity Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyActivityLog.FieldNo("Record ID"));
        SetFieldToPersonal(TableNo, DummyActivityLog.FieldNo("User ID"));
    end;

    local procedure ClassifyInventoryPeriodEntry()
    var
        DummyInventoryPeriodEntry: Record "Inventory Period Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Period Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Closing Item Register No."));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Creation Time"));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Creation Date"));
        SetFieldToPersonal(TableNo, DummyInventoryPeriodEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Ending Date"));
        SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyItem()
    var
        DummyMyItem: Record "My Item";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Item";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyItem.FieldNo("User ID"));
    end;

    local procedure ClassifyUserSecurityStatus()
    var
        DummyUserSecurityStatus: Record "User Security Status";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Security Status";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserSecurityStatus.FieldNo("User Security ID"));
    end;

    local procedure ClassifyCueSetup()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 9701; // Cue Setup
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // User Name
    end;

    local procedure ClassifyVATReportArchive()
    var
        DummyVATReportArchive: Record "VAT Report Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Report Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATReportArchive.FieldNo("Submitted By"));
    end;

    local procedure ClassifySessionEvent()
    var
        DummySessionEvent: Record "Session Event";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Session Event";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("Session Unique ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("Session ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("User SID"));
    end;

    local procedure ClassifyUserDefaultStyleSheet()
    var
        DummyUserDefaultStyleSheet: Record "User Default Style Sheet";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Default Style Sheet";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserDefaultStyleSheet.FieldNo("User ID"));
    end;

    local procedure ClassifyUserPlan()
    var
        TableNo: Integer;
    begin
        TableNo := 9005; // UserPlan
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // "UserPlan"."User Security ID"
    end;

#if not CLEAN22
    local procedure ClassifyUserGroupAccessControl()
    var
        DummyUserGroupAccessControl: Record "User Group Access Control";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Group Access Control";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserGroupAccessControl.FieldNo("User Security ID"));
    end;

    local procedure ClassifyUserGroupMember()
    var
        DummyUserGroupMember: Record "User Group Member";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Group Member";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserGroupMember.FieldNo("User Security ID"));
        SetFieldToPersonal(TableNo, DummyUserGroupMember.FieldNo("User Group Code"));
    end;
#endif

    local procedure ClassifyAADApplication()
    var
        DummyAADApplication: Record "AAD Application";
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := Database::"AAD Application"; // Persistent Blob
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAADApplication.FieldNo("User ID"));
    end;

    local procedure ClassifyApplicationUserSettings()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 9222; // Application User Settings
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // User Security ID
    end;

    local procedure ClassifyAnalysisSelectedDimension()
    var
        DummyAnalysisSelectedDimension: Record "Analysis Selected Dimension";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Analysis Selected Dimension";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAnalysisSelectedDimension.FieldNo("User ID"));
    end;

    local procedure ClassifyItemAnalysisViewBudgEntry()
    var
        DummyItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Analysis View Budg. Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Cost Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Sales Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 3 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 2 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 1 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Analysis View Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Analysis Area"));
    end;

    local procedure ClassifyItemAnalysisViewEntry()
    var
        DummyItemAnalysisViewEntry: Record "Item Analysis View Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Analysis View Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Expected)"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Sales Amount (Expected)"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Non-Invtbl.)"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Actual)"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Sales Amount (Actual)"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Invoiced Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Item Ledger Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 3 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 2 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 1 Value Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Analysis View Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Analysis Area"));
    end;

    local procedure ClassifyTokenCache()
    var
        DummyTokenCache: Record "Token Cache";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Token Cache";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTokenCache.FieldNo("Tenant ID"));
        SetFieldToPersonal(TableNo, DummyTokenCache.FieldNo("User Unique ID"));
        SetFieldToPersonal(TableNo, DummyTokenCache.FieldNo("User Security ID"));
    end;

    local procedure ClassifyTenantLicenseState()
    var
        DummyTenantLicenseState: Record "Tenant License State";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant License State";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTenantLicenseState.FieldNo("User Security ID"));
    end;

    local procedure ClassifyFAJournalSetup()
    var
        DummyFAJournalSetup: Record "FA Journal Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Journal Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFAJournalSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyCustomizedCalendarEntry()
    var
        DummyCustomizedCalendarEntry: Record "Customized Calendar Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Customized Calendar Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Nonworking));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Base Calendar Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Additional Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Source Type"));
    end;

    local procedure ClassifyOfficeContactDetails()
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Office Contact Details";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyOfficeContactDetails.FieldNo("Contact Name"));
    end;

    local procedure ClassifyMyVendor()
    var
        DummyMyVendor: Record "My Vendor";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Vendor";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo("User ID"));
    end;

    local procedure ClassifyItemBudgetEntry()
    var
        DummyItemBudgetEntry: Record "Item Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Budget Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 3 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Location Code"));
        SetFieldToPersonal(TableNo, DummyItemBudgetEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Sales Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Cost Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Analysis Area"));
        SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyCustomer()
    var
        DummyMyCustomer: Record "My Customer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Customer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo("User ID"));
    end;

    local procedure ClassifyAccessControl()
    var
        DummyAccessControl: Record "Access Control";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Access Control";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAccessControl.FieldNo("User Security ID"));
    end;

    local procedure ClassifyUserProperty()
    var
        DummyUserProperty: Record "User Property";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Property";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserProperty.FieldNo(Password));
        SetFieldToPersonal(TableNo, DummyUserProperty.FieldNo("User Security ID"));
    end;

    local procedure ClassifyUser()
    var
        DummyUser: Record User;
        TableNo: Integer;
    begin
        TableNo := DATABASE::User;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Exchange Identifier"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Contact Email"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Authentication Email"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Windows Security ID"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Full Name"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("User Name"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("User Security ID"));
    end;

    local procedure ClassifyConfidentialInformation()
    var
        DummyConfidentialInformation: Record "Confidential Information";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Confidential Information";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyConfidentialInformation.FieldNo(Description));
    end;

    local procedure ClassifyAttendee()
    var
        DummyAttendee: Record Attendee;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Attendee;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAttendee.FieldNo("Attendee Name"));
    end;

    local procedure ClassifyOverdueApprovalEntry()
    var
        DummyOverdueApprovalEntry: Record "Overdue Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Overdue Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Approval Code"));
        SetFieldToPersonal(TableNo, DummyOverdueApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent to Name"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("E-Mail"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent Date"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent Time"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent to ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    local procedure ClassifyApplicationAreaSetup()
    var
        DummyApplicationAreaSetup: Record "Application Area Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Application Area Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyApplicationAreaSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyDateComprRegister()
    var
        DummyDateComprRegister: Record "Date Compr. Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Date Compr. Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyDateComprRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyEmployeeAbsence()
    var
        DummyEmployeeAbsence: Record "Employee Absence";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Absence";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Quantity (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Cause of Absence Code"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("To Date"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("From Date"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Employee No."));
    end;

    local procedure ClassifyWorkflowStepInstanceArchive()
    var
        DummyWorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Instance Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Record ID"));
    end;

    local procedure ClassifyMyJob()
    var
        DummyMyJob: Record "My Job";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Job";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyJob.FieldNo("User ID"));
    end;

    local procedure ClassifyAlternativeAddress()
    var
        DummyAlternativeAddress: Record "Alternative Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Alternative Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(Name));
    end;

    local procedure ClassifyWorkflowStepArgument()
    var
        DummyWorkflowStepArgument: Record "Workflow Step Argument";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Argument";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Response User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Notification User ID"));
    end;

    local procedure ClassifyPageDataPersonalization()
    var
        DummyPageDataPersonalization: Record "Page Data Personalization";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Page Data Personalization";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPageDataPersonalization.FieldNo("User SID"));
    end;

    local procedure ClassifySentNotificationEntry()
    var
        DummySentNotificationEntry: Record "Sent Notification Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sent Notification Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Aggregated with Entry"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Notification Method"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Notification Content"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Sent Date-Time"));
        SetFieldToPersonal(TableNo, DummySentNotificationEntry.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Created Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Custom Link"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Link Target Page"));
        SetFieldToPersonal(TableNo, DummySentNotificationEntry.FieldNo("Recipient User ID"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Triggered By Record"));
    end;

    local procedure ClassifyICOutboxPurchaseHeader()
    var
        DummyICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Purchase Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyUserMetadata()
    var
        DummyUserMetadata: Record "User Metadata";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Metadata";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserMetadata.FieldNo("User SID"));
    end;

    local procedure ClassifyNotificationEntry()
    var
        DummyNotificationEntry: Record "Notification Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Notification Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyNotificationEntry.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Created Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Custom Link"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Link Target Page"));
        SetFieldToPersonal(TableNo, DummyNotificationEntry.FieldNo("Recipient User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Triggered By Record"));
    end;

    local procedure ClassifyUserPersonalization()
    var
        DummyUserPersonalization: Record "User Personalization";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Personalization";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserPersonalization.FieldNo("User SID"));
    end;

    local procedure ClassifyWorkflowStepInstance()
    var
        DummyWorkflowStepInstance: Record "Workflow Step Instance";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Instance";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstance.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstance.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepInstance.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkCenter()
    var
        DummyWorkCenter: Record "Work Center";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Work Center";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Search Name"));
        SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(Name));
    end;

    local procedure ClassifyCampaignEntry()
    var
        DummyCampaignEntry: Record "Campaign Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Campaign Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Register No."));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Salesperson Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Canceled));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Segment No."));
        SetFieldToPersonal(TableNo, DummyCampaignEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Campaign No."));
        SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySession()
    var
        DummySession: Record Session;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Session;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySession.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySession.FieldNo("Connection ID"));
    end;

    local procedure ClassifyIsolatedStorage()
    var
        DummyIsolatedStorage: Record "Isolated Storage";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Isolated Storage";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo("User Id"));
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo(Key));
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo(Value));
    end;

    local procedure ClassifyNavAppSetting()
    var
        DummyNavAppSetting: Record "NAV App Setting";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"NAV App Setting";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyNavAppSetting.FieldNo("Allow HttpClient Requests"));
    end;

    local procedure ClassifyPurchaseLineArchive()
    var
        DummyPurchaseLineArchive: Record "Purchase Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Line Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchaseLineArchive.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPublishedApplication()
    var
        DummyPublishedApplication: Record "Published Application";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Published Application";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Description));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Blob));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Brief));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Logo));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Documentation));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Screenshots));
    end;

    local procedure ClassifyPurchaseHeaderArchive()
    var
        DummyPurchaseHeaderArchive: Record "Purchase Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Header Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Archived By"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifySalesLineArchive()
    var
        DummySalesLineArchive: Record "Sales Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Line Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesLineArchive.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesHeaderArchive()
    var
        DummySalesHeaderArchive: Record "Sales Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Header Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Archived By"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyApprovalCommentLine()
    var
        DummyApprovalCommentLine: Record "Approval Comment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Approval Comment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyApprovalCommentLine.FieldNo("Record ID to Approve"));
        SetFieldToPersonal(TableNo, DummyApprovalCommentLine.FieldNo("User ID"));
    end;

    local procedure ClassifyCommunicationMethod()
    var
        DummyCommunicationMethod: Record "Communication Method";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Communication Method";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCommunicationMethod.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyCommunicationMethod.FieldNo(Name));
    end;

    local procedure ClassifySavedSegmentCriteria()
    var
        DummySavedSegmentCriteria: Record "Saved Segment Criteria";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Saved Segment Criteria";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySavedSegmentCriteria.FieldNo("User ID"));
    end;

    local procedure ClassifyOpportunityEntry()
    var
        DummyOpportunityEntry: Record "Opportunity Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Opportunity Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Stage Description"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Action Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Cancel Old To Do"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Wizard Step"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Estimated Close Date"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Previous Sales Cycle Stage"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Close Opportunity Code"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Probability %"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Chances of Success %"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Completed %"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Calcd. Current Value (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Estimated Value (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Action Taken"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Days Open"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Date Closed"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo(Active));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Date of Change"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Campaign No."));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Salesperson Code"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Contact Company No."));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Contact No."));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Stage"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Code"));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Opportunity No."));
        SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyOpportunity()
    var
        DummyOpportunity: Record Opportunity;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Opportunity;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyOpportunity.FieldNo("Wizard Contact Name"));
    end;

    local procedure ClassifyContactProfileAnswer()
    var
        DummyContactProfileAnswer: Record "Contact Profile Answer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contact Profile Answer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToSensitive(TableNo, DummyContactProfileAnswer.FieldNo("Profile Questionnaire Value"));
    end;

    local procedure ClassifyTodo()
    var
        DummyToDo: Record "To-do";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"To-do";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyToDo.FieldNo("Wizard Contact Name"));
        SetFieldToPersonal(TableNo, DummyToDo.FieldNo("Completed By"));
    end;

    local procedure ClassifyMarketingSetup()
    var
#if not CLEAN22
        DummyMarketingSetup: Record "Marketing Setup";
#endif
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Marketing Setup";
        SetTableFieldsToNormal(TableNo);
#if not CLEAN22
        SetFieldToPersonal(TableNo, DummyMarketingSetup.FieldNo("Exchange Account User Name"));
#endif
    end;

    local procedure ClassifySegmentLine()
    var
        DummySegmentLine: Record "Segment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Segment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySegmentLine.FieldNo("Wizard Contact Name"));
    end;

    local procedure ClassifyLoggedSegment()
    var
        DummyLoggedSegment: Record "Logged Segment";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Logged Segment";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyLoggedSegment.FieldNo("User ID"));
    end;

    local procedure ClassifyServiceInvoiceLine()
    var
        DummyServiceInvoiceLine: Record "Service Invoice Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Invoice Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceInvoiceLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyServiceInvoiceHeader()
    var
        DummyServiceInvoiceHeader: Record "Service Invoice Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Invoice Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Phone 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Contact Name"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Phone No. 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Phone"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceInvoiceHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyServiceShipmentLine()
    var
        DummyServiceShipmentLine: Record "Service Shipment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Shipment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceShipmentLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyServiceShipmentHeader()
    var
        DummyServiceShipmentHeader: Record "Service Shipment Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Shipment Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Phone 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Contact Name"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Phone No. 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Phone"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceShipmentHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyJobQueueLogEntry()
    var
        DummyJobQueueLogEntry: Record "Job Queue Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Queue Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Job Queue Category Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Object ID to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Object Type to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("End Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Start Date/Time"));
        SetFieldToPersonal(TableNo, DummyJobQueueLogEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyJobQueueEntry()
    var
        DummyJobQueueEntry: Record "Job Queue Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Queue Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Manual Recurrence"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("System Task ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Rerun Delay (sec.)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Report Request Page Options"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Printer Name"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("User Language ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Notify On Success"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("User Session Started"));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User Service Instance ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Job Queue Category Code"));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User Session ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run in User Session"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Reference Starting Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Ending Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Starting Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Sundays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Saturdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Fridays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Thursdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Wednesdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Tuesdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Mondays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("No. of Minutes between Runs"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Recurring Job"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Parameter String"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("No. of Attempts to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Maximum No. of Attempts to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Report Output Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Object ID to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Object Type to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Earliest Start Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Expiration Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Last Ready State"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(XML));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Record ID to Process"));
    end;

    local procedure ClassifyInteractionLogEntry()
    var
        DummyInteractionLogEntry: Record "Interaction Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Interaction Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Postponed));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Opportunity No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Subject));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("E-Mail Logged"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Language Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Send Word Docs. as Attmt."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Via"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Doc. No. Occurrence"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Version No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Logged Segment Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Alt. Address Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Correspondence Type"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Canceled));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Delivery Status"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Salesperson Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("To-do No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Attempt Failed"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Time of Interaction"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Evaluation));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Segment No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Target"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Response"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Template Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Group Code"));
        SetFieldToPersonal(TableNo, DummyInteractionLogEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Duration (Min.)"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Attachment No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Initiated By"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Information Flow"));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Company No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact No."));
        SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyInteractionMergeData()
    var
        DummyInteractionMergeData: Record "Interaction Merge Data";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Interaction Merge Data";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInteractionMergeData.FieldNo(ID));
        SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Contact No."));
        SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Log Entry Number"));
    end;

    local procedure ClassifyPostedApprovalCommentLine()
    var
        DummyPostedApprovalCommentLine: Record "Posted Approval Comment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Approval Comment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedApprovalCommentLine.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalCommentLine.FieldNo("Posted Record ID"));
    end;

    local procedure ClassifyPostedApprovalEntry()
    var
        DummyPostedApprovalEntry: Record "Posted Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Iteration No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Number of Rejected Requests"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Number of Approved Requests"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Delegation Date Formula"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Available Credit Limit (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Last Modified By ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Last Date-Time Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Date-Time Sent for Approval"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPostedApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Sender ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Approval Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Posted Record ID"));
    end;

    local procedure ClassifyContact()
    var
        DummyContact: Record Contact;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Contact;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("E-Mail 2"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Search E-Mail"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(Image));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(Pager));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Mobile Phone No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Extension No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(Surname));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Middle Name"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("First Name"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Post Code"));
        SetFieldToSensitive(TableNo, DummyContact.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo("Search Name"));
        SetFieldToPersonal(TableNo, DummyContact.FieldNo(Name));
    end;

    local procedure ClassifyApprovalEntry()
    var
        DummyApprovalEntry: Record "Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Workflow Step Instance ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Delegation Date Formula"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Available Credit Limit (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyApprovalEntry.FieldNo("Last Modified By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Last Date-Time Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Date-Time Sent for Approval"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Sender ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Approval Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    local procedure ClassifyContractChangeLog()
    var
        DummyContractChangeLog: Record "Contract Change Log";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contract Change Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyContractChangeLog.FieldNo("User ID"));
    end;

    local procedure ClassifyServiceContractHeader()
    var
        DummyServiceContractHeader: Record "Service Contract Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Contract Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceContractHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceContractHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceContractHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceContractHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyServiceContractHeader.FieldNo("Contact Name"));
    end;

    local procedure ClassifyHandledICInboxPurchHeader()
    var
        DummyHandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Purch. Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICInboxSalesHeader()
    var
        DummyHandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyICInboxPurchaseHeader()
    var
        DummyICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Purchase Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyICInboxSalesHeader()
    var
        DummyICInboxSalesHeader: Record "IC Inbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICOutboxPurchHdr()
    var
        DummyHandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Purch. Hdr";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICOutboxSalesHeader()
    var
        DummyHandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyServiceItemLog()
    var
        DummyServiceItemLog: Record "Service Item Log";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Item Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceItemLog.FieldNo("User ID"));
    end;

    local procedure ClassifyServiceCrMemoHeader()
    var
        DummyServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Cr.Memo Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Phone 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Contact Name"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Phone No. 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Phone"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceCrMemoHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyServiceRegister()
    var
        DummyServiceRegister: Record "Service Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyUserPageMetadata()
    var
        DummyUserPageMetadata: Record "User Page Metadata";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Page Metadata";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserPageMetadata.FieldNo("User SID"));
    end;

    local procedure ClassifyICPartner()
    var
        DummyICPartner: Record "IC Partner";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Partner";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICPartner.FieldNo(Name));
    end;

    local procedure ClassifyChangeLogEntry()
    var
        DummyChangeLogEntry: Record "Change Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Change Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 3 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 3 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 2 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 2 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 1 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 1 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("New Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Old Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Type of Change"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Field No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Table No."));
        SetFieldToPersonal(TableNo, DummyChangeLogEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo(Time));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Date and Time"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyInsCoverageLedgerEntry()
    var
        DummyInsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Ins. Coverage Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyInsCoverageLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Description"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Disposed FA"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Insurance No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyLoanerEntry()
    var
        DummyLoanerEntry: Record "Loaner Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Loaner Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo(Lent));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Time Received"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Date Received"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Time Lent"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Date Lent"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Service Item Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Service Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Service Item Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Loaner No."));
        SetFieldToCompanyConfidential(TableNo, DummyLoanerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyServiceDocumentLog()
    var
        DummyServiceDocumentLog: Record "Service Document Log";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Document Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceDocumentLog.FieldNo("User ID"));
    end;

    local procedure ClassifyWarrantyLedgerEntry()
    var
        DummyWarrantyLedgerEntry: Record "Warranty Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warranty Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Service Order Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Vendor Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Vendor No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Work Type Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Resolution Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Symptom Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Fault Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Fault Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Fault Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Service Contract No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Service Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Service Item Group (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Serial No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Item No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Service Item No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Variant Code (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Bill-to Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Ship-to Code"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyWarrantyLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyServiceLedgerEntry()
    var
        DummyServiceLedgerEntry: Record "Service Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Job Posted"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Job Line Type"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Job Task No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Apply Until Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Prepaid));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Service Price Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Serv. Price Adjmt. Gr. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Responsibility Center"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Bin Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Work Type Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Service Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Service Order Type"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Fault Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Bill-to Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Contract Disc. Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Discount %"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Unit Price"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Charged Qty."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Discount Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Cost Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Contract Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Variant Code (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Service Item No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Contract Invoice Period"));
        SetFieldToPersonal(TableNo, DummyServiceLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Serial No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Item No. (Serviced)"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Ship-to Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Moved from Prepaid Acc."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Document Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Serv. Contract Acc. Gr. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Service Contract No."));
        SetFieldToCompanyConfidential(TableNo, DummyServiceLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyEmailConnectorLogo()
    begin
        SetTableFieldsToNormal(8887);
    end;

    local procedure ClassifyEmailError()
    begin
        SetFieldToPersonal(8901, 3); // Error Message
    end;

    local procedure ClassifyEmailOutbox()
    begin
        SetFieldToPersonal(8888, 6); // Description / Email subject
        SetFieldToPersonal(8888, 13); // Send from
        SetFieldToPersonal(8888, 14); // Error Message
    end;

    local procedure ClassifySentEmail()
    begin
        SetFieldToPersonal(8889, 6); // Description / Email subject
        SetFieldToPersonal(8889, 13); // Send from
    end;

    local procedure ClassifyEmailScenarioAttachments()
    begin
        SetFieldToPersonal(8911, 3); // Attachment Name
        SetFieldToPersonal(8911, 4); // Email Attachment
    end;

    local procedure ClassifyRateLimit()
    begin
        SetFieldToPersonal(8912, 2); // Email Address
    end;

    local procedure ClassifyEmailLookup()
    begin
        SetFieldToPersonal(8944, 1); // Name;
        SetFieldToPersonal(8944, 2); // Email;
        SetFieldToPersonal(8944, 3); // Company;
    end;

    local procedure ClassifyEmailMessage()
    begin
        SetFieldToPersonal(8900, 2); // Subject
        SetFieldToPersonal(8900, 3); // Body
    end;

    local procedure ClassifyEmailRecipient()
    begin
        SetFieldToPersonal(8903, 2); // Email Address
    end;

    local procedure ClassifyEmailMessageAttachment()
    begin
        SetFieldToPersonal(8904, 3); // Attachment
        SetFieldToPersonal(8904, 4); // Attachment Name
        SetFieldToPersonal(8904, 9); // Media Attachment
    end;

    local procedure ClassifyWordTemplate()
    begin
        SetFieldToPersonal(9988, 1); // Code
        SetFieldToPersonal(9988, 2); // Name
        SetFieldToPersonal(9988, 4); // Template
        SetFieldToPersonal(9990, 1); // Code
        SetFieldToPersonal(9990, 7); // Related Table Code
        SetFieldToPersonal(9989, 1); // Word Template Code
        SetFieldToPersonal(9989, 5); // Exclude
    end;

    local procedure ClassifyDocumentSharing()
    begin
        SetFieldToPersonal(9560, 2); // Data
        SetFieldToPersonal(9560, 3); // Name
        SetFieldToPersonal(9560, 6); // Token
        SetFieldToPersonal(9560, 7); // Document Root Uri
        SetFieldToPersonal(9560, 8); // Document Uri
        SetFieldToPersonal(9560, 9); // Document Preview Uri
    end;

    local procedure ClassifyEmailRelatedAttachments()
    begin
        SetFieldToPersonal(8910, 2); // Attachment Name
    end;

    local procedure ClassifyTermsAndConditionsState()
    var
        DummyTermsAndConditionsState: Record "Terms And Conditions State";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Terms And Conditions State";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTermsAndConditionsState.FieldNo("User ID"));
    end;

    local procedure ClassifyServiceLine()
    var
        DummyServiceLine: Record "Service Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyServiceHeader()
    var
        DummyServiceHeader: Record "Service Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Phone 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Phone"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Phone No. 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Contact Name"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyServiceHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyDetailedVendorLedgEntry()
    var
        DummyDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed Vendor Ledg. Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Ledger Entry Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Application No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Tax Jurisdiction Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Max. Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Unapplied by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo(Unapplied));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Applied Vend. Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Global Dim. 2"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Global Dim. 1"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyDetailedVendorLedgEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Vendor No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Vendor Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyDetailedCustLedgEntry()
    var
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed Cust. Ledg. Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Ledger Entry Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Application No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Tax Jurisdiction Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Max. Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Unapplied by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo(Unapplied));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Applied Cust. Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Global Dim. 2"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Global Dim. 1"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyDetailedCustLedgEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Cust. Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyDetailedCVLedgEntryBuffer()
    var
        DummyDetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed CV Ledg. Entry Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCVLedgEntryBuffer.FieldNo("Non-Deductible VAT Amount LCY"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCVLedgEntryBuffer.FieldNo("Non-Deductible VAT Amount ACY"));
    end;

    local procedure ClassifyPostedPaymentReconLine()
    var
        DummyPostedPaymentReconLine: Record "Posted Payment Recon. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Payment Recon. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedPaymentReconLine.FieldNo("Related-Party Name"));
    end;

    local procedure ClassifyAppliedPaymentEntry()
    var
        DummyAppliedPaymentEntry: Record "Applied Payment Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Applied Payment Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo(Quality));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applied Pmt. Discount"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applied Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Match Confidence"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("External Document No."));
    end;

    local procedure ClassifySelectedDimension()
    var
        DummySelectedDimension: Record "Selected Dimension";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Selected Dimension";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySelectedDimension.FieldNo("User ID"));
    end;

    local procedure ClassifyConfigLine()
    var
        DummyConfigLine: Record "Config. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyConfigLine.FieldNo("Responsible ID"));
    end;

    local procedure ClassifyItemApplicationEntryHistory()
    var
        DummyItemApplicationEntryHistory: Record "Item Application Entry History";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Application Entry History";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Output Completely Invd. Date"));
        SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Deleted By User"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Deleted Date"));
        SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Last Modified By User"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Last Modified Date"));
        SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Created By User"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Creation Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Transferred-from Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Primary Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Outbound Item Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Inbound Item Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Item Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Cost Application"));
    end;

    local procedure ClassifyConfigPackageTable()
    var
        DummyConfigPackageTable: Record "Config. Package Table";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Package Table";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyConfigPackageTable.FieldNo("Created by User ID"));
        SetFieldToPersonal(TableNo, DummyConfigPackageTable.FieldNo("Imported by User ID"));
    end;

    local procedure ClassifyItemApplicationEntry()
    var
        DummyItemApplicationEntry: Record "Item Application Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Application Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Outbound Entry is Updated"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Output Completely Invd. Date"));
        SetFieldToPersonal(TableNo, DummyItemApplicationEntry.FieldNo("Last Modified By User"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Last Modified Date"));
        SetFieldToPersonal(TableNo, DummyItemApplicationEntry.FieldNo("Created By User"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Creation Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Transferred-from Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Outbound Item Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Inbound Item Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Item Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Cost Application"));
    end;

    local procedure ClassifyReservationEntry()
    var
        DummyReservationEntry: Record "Reservation Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reservation Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Expiration Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Lot No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Serial No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item Tracking"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Lot No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Quantity Invoiced (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. to Invoice (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. to Handle (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Expiration Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Warranty Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Appl.-to Item Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Planning Flexibility"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Suppressed Action Msg."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Binding));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Positive));
        SetFieldToPersonal(TableNo, DummyReservationEntry.FieldNo("Changed By"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Appl.-from Item Entry"));
        SetFieldToPersonal(TableNo, DummyReservationEntry.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Serial No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Shipment Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Expected Receipt Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Ref. No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Prod. Order Line"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source ID"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Subtype"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Transferred from Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Creation Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Disallow Cancellation"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Reservation Status"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Quantity (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Entry No."));
    end;

#if not CLEAN24
    local procedure ClassifyCalendarEvent()
    var
        DummyCalendarEvent: Record "Calendar Event";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Calendar Event";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCalendarEvent.FieldNo(User));
        SetFieldToCompanyConfidential(TableNo, DummyCalendarEvent.FieldNo("Record ID to Process"));
    end;
#endif

    local procedure ClassifyCapacityLedgerEntry()
    var
        DummyCapacityLedgerEntry: Record "Capacity Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Capacity Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Subcontracting));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Shift Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Center Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Scrap Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Stop Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Routing Reference No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Routing No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Ending Time"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Starting Time"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Completely Invoiced"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Last Output Line"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Cap. Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Cap. Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Concurrent Capacity"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Scrap Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Output Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Invoiced Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Stop Time"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Run Time"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Setup Time"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Center No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Operation No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyPayableVendorLedgerEntry()
    var
        DummyPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payable Vendor Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Future));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Vendor Ledg. Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Vendor No."));
        SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Priority));
    end;

    local procedure ClassifyReminderFinChargeEntry()
    var
        DummyReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reminder/Fin. Charge Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyReminderFinChargeEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Remaining Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Customer Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Interest Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Interest Posted"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Reminder Level"));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyPositivePayEntryDetail()
    var
        DummyPositivePayEntryDetail: Record "Positive Pay Entry Detail";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Positive Pay Entry Detail";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Update Date"));
        SetFieldToPersonal(TableNo, DummyPositivePayEntryDetail.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo(Payee));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Check No."));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Upload Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Bank Account No."));
    end;

    local procedure ClassifySalesShipmentLine()
    var
        DummySalesShipmentLine: Record "Sales Shipment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Shipment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesShipmentLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyICOutboxSalesHeader()
    var
        DummyICOutboxSalesHeader: Record "IC Outbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyIssuedFinChargeMemoHeader()
    var
        DummyIssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Issued Fin. Charge Memo Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Name));
    end;

    local procedure ClassifyFinanceChargeMemoHeader()
    var
        DummyFinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Finance Charge Memo Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Name));
    end;

    local procedure ClassifyFiledServiceContractHeader()
    var
        DummyFiledServiceContractHeader: Record "Filed Service Contract Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Filed Service Contract Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Filed By"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Contact Name"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyFiledServiceContractHeader.FieldNo(Name));
    end;

    local procedure ClassifyBinCreationWorksheetLine()
    var
        DummyBinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bin Creation Worksheet Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyBinCreationWorksheetLine.FieldNo("User ID"));
    end;

    local procedure ClassifyIssuedReminderHeader()
    var
        DummyIssuedReminderHeader: Record "Issued Reminder Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Issued Reminder Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Name));
    end;

    local procedure ClassifyReminderHeader()
    var
        DummyReminderHeader: Record "Reminder Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reminder Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Name));
    end;

    local procedure ClassifyDirectDebitCollectionEntry()
    var
        DummyDirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Direct Debit Collection Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Mandate ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Sequence Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transaction ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transfer Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transfer Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Direct Debit Collection No."));
    end;

    local procedure ClassifyValueEntry()
    var
        DummyValueEntry: Record "Value Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Value Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Exp. Cost Posted to G/L (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Expected Cost Posted to G/L"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Non-Invtbl.)(ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Expected) (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Non-Invtbl.)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Expected)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Sales Amount (Expected)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Purchase Amount (Expected)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Purchase Amount (Actual)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Capacity Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Adjustment));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Variance Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valuation Date"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Inventoriable));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Partial Revaluation"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Return Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valued By Average Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Charge No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Expected Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost per Unit (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Posted to G/L (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Actual) (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Drop Shipment"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Posted to G/L"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Actual)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Applies-to Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyValueEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Discount Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Average Cost Exception"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Sales Amount (Actual)"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job Task No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost per Unit"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Invoiced Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valued Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Inventory Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCustomerBankAccount()
    var
        DummyCustomerBankAccount: Record "Customer Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Customer Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(IBAN));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Transit No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Bank Account No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Bank Branch No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Name));
    end;

    local procedure ClassifyCreditTransferRegister()
    var
        DummyCreditTransferRegister: Record "Credit Transfer Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Credit Transfer Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCreditTransferRegister.FieldNo("Created by User"));
    end;

    local procedure ClassifyPhysInventoryLedgerEntry()
    var
        DummyPhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Phys. Inventory Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Phys Invt Counting Period Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Phys Invt Counting Period Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Last Item Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Qty. (Phys. Inventory)"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Qty. (Calculated)"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Inventory Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyBankAccReconciliationLine()
    var
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Acc. Reconciliation Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party City"));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Address"));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Bank Acc. No."));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Name"));
    end;

    local procedure ClassifyTimeSheetLine()
    var
        DummyTimeSheetLine: Record "Time Sheet Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTimeSheetLine.FieldNo("Approved By"));
        SetFieldToPersonal(TableNo, DummyTimeSheetLine.FieldNo("Approver ID"));
    end;

    local procedure ClassifyCheckLedgerEntry()
    var
        DummyCheckLedgerEntry: Record "Check Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Check Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Positive Pay Exported"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Data Exch. Voided Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Data Exch. Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummyCheckLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Original Entry Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Entry Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Payment Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Account Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyBankAccountLedgerEntry()
    var
        DummyBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Account Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement Status"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Closed at Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyBankAccountLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Our Contact Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bank Acc. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Remaining Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyBookingSync()
    var
        DummyBookingSync: Record "Booking Sync";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Booking Sync";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyBookingSync.FieldNo("User ID"));
    end;

    local procedure ClassifyExchangeSync()
    var
        DummyExchangeSync: Record "Exchange Sync";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Exchange Sync";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyExchangeSync.FieldNo("User ID"));
    end;

    local procedure ClassifyVATEntry()
    var
        DummyVATEntry: Record "VAT Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("EU Service"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Registration No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Ship-to/Order Address Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. VAT Difference"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Difference"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. Rem. Unreal. Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. Rem. Unreal. Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Base Discount %"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Currency Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Currency Unrealized Amt."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Additional-Currency Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized VAT Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Sales Tax Connection No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax on Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Group Used"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Jurisdiction Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Remaining Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Remaining Unrealized Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Internal Ref. No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Country/Region Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Closed));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyVATEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("EU 3-Party Trade"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Bill-to/Pay-to No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Calculation Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Base));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyWarehouseActivityHeader()
    var
        DummyWarehouseActivityHeader: Record "Warehouse Activity Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Activity Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWarehouseActivityHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyVATRegistrationLog()
    var
        DummyVATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Registration Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified City"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Postcode"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Street"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Address"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Name"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("VAT Registration No."));

        TableNo := Database::"VAT Registration Log Details";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo(Requested));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo(Response));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo("Current Value"));
    end;

    local procedure ClassifyRequisitionLine()
    var
        DummyRequisitionLine: Record "Requisition Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Requisition Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyRequisitionLine.FieldNo("User ID"));
    end;

    local procedure ClassifyServiceCrMemoLine()
    var
        DummyServiceCrMemoLine: Record "Service Cr.Memo Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Cr.Memo Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyServiceCrMemoLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyJobRegister()
    var
        DummyJobRegister: Record "Job Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyJobRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyResourceRegister()
    var
        DummyResourceRegister: Record "Resource Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Resource Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyResourceRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyReturnReceiptLine()
    var
        DummyReturnReceiptLine: Record "Return Receipt Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Receipt Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyReturnReceiptLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyReturnReceiptHeader()
    var
        DummyReturnReceiptHeader: Record "Return Receipt Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Receipt Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyOrderAddress()
    var
        DummyOrderAddress: Record "Order Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Order Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Name));
    end;

    local procedure ClassifyShiptoAddress()
    var
        DummyShipToAddress: Record "Ship-to Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Ship-to Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Name));
    end;

    local procedure ClassifyReturnShipmentLine()
    var
        DummyReturnShipmentLine: Record "Return Shipment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Shipment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyReturnShipmentLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyReturnShipmentHeader()
    var
        DummyReturnShipmentHeader: Record "Return Shipment Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Shipment Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyResLedgerEntry()
    var
        DummyResLedgerEntry: Record "Res. Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Res. Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order Type"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Quantity (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Chargeable));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyResLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Total Price"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit Price"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Total Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Direct Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Work Type Code"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Resource Group No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Resource No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyInsuranceRegister()
    var
        DummyInsuranceRegister: Record "Insurance Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Insurance Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyInsuranceRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyContractGainLossEntry()
    var
        DummyContractGainLossEntry: Record "Contract Gain/Loss Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contract Gain/Loss Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummyContractGainLossEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Ship-to Code"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Responsibility Center"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Type of Change"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Change Date"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Contract Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Contract No."));
        SetFieldToCompanyConfidential(TableNo, DummyContractGainLossEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyTimeSheets()
    var
        DummyMyTimeSheets: Record "My Time Sheets";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Time Sheets";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyTimeSheets.FieldNo("User ID"));
    end;

    local procedure ClassifyCustomReportLayout()
    var
        DummyCustomReportLayout: Record "Custom Report Layout";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Custom Report Layout";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCustomReportLayout.FieldNo("Last Modified by User"));
    end;

    local procedure ClassifyCostBudgetRegister()
    var
        DummyCostBudgetRegister: Record "Cost Budget Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Budget Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostBudgetRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyCostBudgetEntry()
    var
        DummyCostBudgetEntry: Record "Cost Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Budget Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Last Date Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocated with Journal No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Allocated));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocation ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocation Description"));
        SetFieldToPersonal(TableNo, DummyCostBudgetEntry.FieldNo("Last Modified By User"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Object Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Center Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Type No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCostAllocationTarget()
    var
        DummyCostAllocationTarget: Record "Cost Allocation Target";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Allocation Target";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostAllocationTarget.FieldNo("User ID"));
    end;

    local procedure ClassifyCostAllocationSource()
    var
        DummyCostAllocationSource: Record "Cost Allocation Source";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Allocation Source";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostAllocationSource.FieldNo("User ID"));
    end;

    local procedure ClassifyCostRegister()
    var
        DummyCostRegister: Record "Cost Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyCostEntry()
    var
        DummyCostEntry: Record "Cost Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocated with Journal No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Allocated));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("G/L Account"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Object Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Center Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocation ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocation Description"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Add.-Currency Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Type No."));
        SetFieldToPersonal(TableNo, DummyCostEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Add.-Currency Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCostType()
    var
        DummyCostType: Record "Cost Type";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Type";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostType.FieldNo("Modified By"));
    end;

    local procedure ClassifyReversalEntry()
    var
        DummyReversalEntry: Record "Reversal Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reversal Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Reversal Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("FA Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("FA Posting Category"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Account Name"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("G/L Register No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Line No."));
    end;

    local procedure ClassifyJobLedgerEntry()
    var
        DummyJobLedgerEntry: Record "Job Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Price"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Posted Service Shipment No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Service Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transaction Specification"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Description 2"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Quantity (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Bin Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Add.-Currency Line Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Add.-Currency Total Price"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Additional-Currency Total Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Area));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry/Exit Point"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Country/Region Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transport Method"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transaction Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job Task No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Unit Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Amt. Posted to G/L"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Amt. to Post to G/L"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Ledger Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("DateTime Adjusted"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Adjusted));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost (ACY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Unit Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyJobLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount %"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Lot No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Serial No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Customer Price Group"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Work Type Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Currency Factor"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Price"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Cost"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Resource Group No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Price (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Price (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Direct Unit Cost (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyTimeSheetLineArchive()
    var
        DummyTimeSheetLineArchive: Record "Time Sheet Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Line Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTimeSheetLineArchive.FieldNo("Approved By"));
        SetFieldToPersonal(TableNo, DummyTimeSheetLineArchive.FieldNo("Approver ID"));
    end;

    local procedure ClassifyJob()
    var
        DummyJob: Record Job;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Job;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Contact"));
    end;

    local procedure ClassifyJobArchive()
    var
        DummyJobArchive: Record "Job Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Contact"));
    end;

    local procedure ClassifyResCapacityEntry()
    var
        DummyResCapacityEntry: Record "Res. Capacity Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Res. Capacity Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo(Capacity));
        SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Resource Group No."));
        SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Resource No."));
        SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyResource()
    var
        DummyResource: Record Resource;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Resource;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyResource.FieldNo(Image));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Time Sheet Approver User ID"));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Time Sheet Owner User ID"));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Post Code"));
        SetFieldToSensitive(TableNo, DummyResource.FieldNo("Employment Date"));
        SetFieldToSensitive(TableNo, DummyResource.FieldNo(Education));
        SetFieldToSensitive(TableNo, DummyResource.FieldNo("Social Security No."));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo("Search Name"));
        SetFieldToPersonal(TableNo, DummyResource.FieldNo(Name));
    end;

    local procedure ClassifyIncomingDocument()
    var
        DummyIncomingDocument: Record "Incoming Document";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Incoming Document";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Phone No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Bank Account No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Bank Branch No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor IBAN"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Name"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Released By User ID"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyIncomingDocument.FieldNo("Related Record ID"));
    end;

    local procedure ClassifyWarehouseRegister()
    var
        DummyWarehouseRegister: Record "Warehouse Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWarehouseRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyPurchCrMemoLine()
    var
        DummyPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Cr. Memo Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchCrMemoLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchCrMemoHdr()
    var
        DummyPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Cr. Memo Hdr.";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchInvLine()
    var
        DummyPurchInvLine: Record "Purch. Inv. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchInvLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchInvHeader()
    var
        DummyPurchInvHeader: Record "Purch. Inv. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Creditor No."));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchRcptLine()
    var
        DummyPurchRcptLine: Record "Purch. Rcpt. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Rcpt. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchRcptLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchRcptHeader()
    var
        DummyPurchRcptHeader: Record "Purch. Rcpt. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Rcpt. Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifySalesCrMemoLine()
    var
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr.Memo Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesCrMemoLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesCrMemoHeader()
    var
        DummySalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr.Memo Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifySalesInvoiceLine()
    var
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesInvoiceLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesInvoiceHeader()
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyMaintenanceLedgerEntry()
    var
        DummyMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Maintenance Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Automatic Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Maintenance Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Exchange Rate"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Depreciation Book Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToPersonal(TableNo, DummyMaintenanceLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA No./Budgeted FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySalesShipmentHeader()
    var
        DummySalesShipmentHeader: Record "Sales Shipment Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Shipment Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyFARegister()
    var
        DummyFARegister: Record "FA Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFARegister.FieldNo("User ID"));
    end;

    local procedure ClassifyMaintenanceRegistration()
    var
        DummyMaintenanceRegistration: Record "Maintenance Registration";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Maintenance Registration";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Mobile Phone"));
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Phone No."));
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Name"));
    end;

    local procedure ClassifyWorkflowStepArgumentArchive()
    var
        DummyWorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Argument Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Response User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Notification User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Original Record ID"));
    end;

    local procedure ClassifyGLBudgetEntry()
    var
        DummyGLBudgetEntry: Record "G/L Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Budget Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Last Date Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 4 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 3 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 1 Code"));
        SetFieldToPersonal(TableNo, DummyGLBudgetEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Business Unit Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("G/L Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyApiWebhookSubscripitonFields()
    var
        DummyAPIWebhookSubscription: Record "API Webhook Subscription";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"API Webhook Subscription";
        SetTableFieldsToNormal(TableNo);
        SetFieldToSensitive(TableNo, DummyAPIWebhookSubscription.FieldNo("Client State"));
    end;

    local procedure ClassifyExternalEventSubscriptionFields()
    var
        DummyExternalEventSubscription: Record "External Event Subscription";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"External Event Subscription";
        SetTableFieldsToNormal(TableNo);
        SetFieldToSensitive(TableNo, DummyExternalEventSubscription.FieldNo("Client State"));
    end;

    local procedure ClassifyUserSetup()
    var
        DummyUserSetup: Record "User Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo(Substitute));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("Approver ID"));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("User ID"));
    end;

    local procedure ClassifySupportInformation()
    var
        DummySupportContactInformation: Record "Support Contact Information";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Support Contact Information";
        SetTableFieldsToNormal(TableNo);

        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(Email));
        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(URL));
    end;

    local procedure ClassifyCRMSynchStatus()
    var
        DummyCRMSynchStatus: Record "CRM Synch Status";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Synch Status";
        SetTableFieldsToNormal(TableNo);

        SetFieldToPersonal(TableNo, DummyCRMSynchStatus.FieldNo("Primary Key"));
        SetFieldToPersonal(TableNo, DummyCRMSynchStatus.FieldNo("Last Update Invoice Entry No."));
    end;

    local procedure ClassifyRetentionPolicyLogEntry()
    var
        TableNo: Integer;
    begin
        TableNo := 3905; // Database::"Retention Policy Log Entry"
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 4); // FieldNo("User Id")
    end;

    local procedure ClassifyFALedgerEntry()
    var
        DummyFALedgerEntry: Record "FA Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Property Class (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. % this year (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Accum. Depr. % (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. Ending Date (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. Starting Date (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Automatic Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Use FA Ledger Check"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Ending Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Canceled from FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Result on Disposal"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Exchange Rate"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Table Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Declining-Balance %"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Fixed Depr. Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. of Depreciation Years"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Straight-Line %"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Starting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Method"));
        SetFieldToPersonal(TableNo, DummyFALedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA No./Budgeted FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. of Depreciation Days"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Disposal Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Disposal Calculation Method"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Part of Depreciable Basis"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Part of Book Value"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reclassification Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Category"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Book Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyJobPlanningLine()
    var
        DummyJobPlanningLine: Record "Job Planning Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Planning Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyJobPlanningLine.FieldNo("User ID"));
    end;

    local procedure ClassifyJobPlanningLineArchive()
    var
        DummyJobPlanningLineArchive: Record "Job Planning Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Planning Line Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyJobPlanningLineArchive.FieldNo("User ID"));
    end;

    local procedure ClassifyGenJournalLine()
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Gen. Journal Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyGenJournalLine.FieldNo("VAT Registration No."));
    end;

    local procedure ClassifyPrinterSelection()
    var
        DummyPrinterSelection: Record "Printer Selection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Printer Selection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPrinterSelection.FieldNo("User ID"));
    end;

    local procedure ClassifyTimeSheetChartSetup()
    var
        DummyTimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Chart Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTimeSheetChartSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyUserTimeRegister()
    var
        DummyUserTimeRegister: Record "User Time Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Time Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserTimeRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyItemRegister()
    var
        DummyItemRegister: Record "Item Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyItemRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyGLRegister()
    var
        DummyGLRegister: Record "G/L Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyGLRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyPurchaseLine()
    var
        DummyPurchaseLine: Record "Purchase Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchaseLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchaseHeader()
    var
        DummyPurchaseHeader: Record "Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Creditor No."));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Vendor Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Name 2"));
        SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifySalesLine()
    var
        DummySalesLine: Record "Sales Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesHeader()
    var
        DummySalesHeader: Record "Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Assigned User ID"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Customer Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Name 2"));
        SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyTimeSheetHeaderArchive()
    var
        DummyTimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Header Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTimeSheetHeaderArchive.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyTimeSheetHeaderArchive.FieldNo("Owner User ID"));
    end;

    local procedure ClassifyItemLedgerEntry()
    var
        DummyItemLedgerEntry: Record "Item Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Serial No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Purchasing Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Nonstock));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Category Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Out-of-Stock Substitution"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Originally Ordered Var. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Originally Ordered No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Reference No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Prod. Order Comp. Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Assemble to Order"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Return Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Shipped Qty. Not Returned"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Applied Entry to Adjust"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Last Invoice Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Completely Invoiced"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Variant Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transaction Specification"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Area));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry/Exit Point"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Country/Region Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transport Method"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transaction Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Drop Shipment"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Derived from Blanket Order"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Applies-to Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Expiration Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job Purchase"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job Task No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Invoiced Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Remaining Quantity"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Warranty Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Tracking"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Lot No."));
    end;

    local procedure ClassifyTimeSheetHeader()
    var
        DummyTimeSheetHeader: Record "Time Sheet Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTimeSheetHeader.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyTimeSheetHeader.FieldNo("Owner User ID"));
    end;

    local procedure ClassifyItem()
    var
        DummyItem: Record Item;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Item;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyItem.FieldNo("Application Wksh. User ID"));
    end;

    local procedure ClassifyEntityText()
    begin
        SetTableFieldsToNormal(Database::"Entity Text");
        SetTableFieldsToNormal(2010); // Azure OpenAi Settings
        SetFieldToCompanyConfidential(2010, 4); // Secret
    end;

    local procedure ClassifyVendorLedgerEntry()
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Vendor Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Ext. Doc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Payment Method Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Payment Reference"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Creditor No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Exported to Payment File"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Message to Recipient"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Recipient Bank Account"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Prepayment));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applying Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("IC Partner Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Amount to Apply"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Tolerance (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Accepted Pmt. Disc. Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Accepted Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Max. Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Disc. Tolerance Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Original Currency Factor"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Adjusted Currency Factor"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to ID"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed at Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Disc. Rcd.(LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Original Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Discount Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Doc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Doc. Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("On Hold"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyVendorLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Purchaser Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Vendor Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Buy-from Vendor No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Inv. Discount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Purchase (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Vendor No."));
        SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyVendor()
    var
        DummyVendor: Record Vendor;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Vendor;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Creditor No."));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Image));
        SetFieldToCompanyConfidential(TableNo, DummyVendor.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(GLN));
        SetFieldToSensitive(TableNo, DummyVendor.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Search Name"));
        SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Name));
    end;

    local procedure ClassifyCustLedgerEntry()
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cust. Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Ext. Doc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Payment Method Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Direct Debit Mandate ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Exported to Payment File"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Message to Recipient"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Recipient Bank Account"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Prepayment));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applying Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("IC Partner Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Amount to Apply"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Tolerance (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Accepted Pmt. Disc. Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Accepted Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Last Issued Reminder Level"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Max. Payment Tolerance"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Disc. Tolerance Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Original Currency Factor"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Adjusted Currency Factor"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closing Interest Calculated"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Calculate Interest"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed at Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Disc. Given (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Original Pmt. Disc. Possible"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Discount Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Doc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Doc. Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("On Hold"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyCustLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Salesperson Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Customer Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Sell-to Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Inv. Discount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Profit (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Sales (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyAccount()
    var
        DummyMyAccount: Record "My Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyAccount.FieldNo("User ID"));
    end;

    local procedure ClassifyCustomer()
    var
        DummyCustomer: Record Customer;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Customer;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Image));
        SetFieldToCompanyConfidential(TableNo, DummyCustomer.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(GLN));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Search Name"));
        SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Name));
    end;

    local procedure ClassifyGLEntry()
    var
        DummyGLEntry: Record "G/L Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Last Modified DateTime"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("FA Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("FA Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Account Id"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("IC Partner Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Close Income Statement Dim. ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Add.-Currency Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Add.-Currency Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Business Unit Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Prod. Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Prior-Year Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyGLEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("G/L Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySalespersonPurchaser()
    var
        DummySalespersonPurchaser: Record "Salesperson/Purchaser";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Salesperson/Purchaser";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummySalespersonPurchaser.FieldNo("Job Title"));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo(Image));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("E-Mail 2"));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("Search E-Mail"));
        SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo(Name));
    end;

    local procedure ClassifyManufacturingUserTemplate()
    var
        DummyManufacturingUserTemplate: Record "Manufacturing User Template";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Manufacturing User Template";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyManufacturingUserTemplate.FieldNo("User ID"));
    end;

    local procedure ClassifySalesOrderEntityBuffer()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Order Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-To Contact No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Shipping Advice"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Completely Shipped"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Requested Delivery Date"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Country/Region Code"));
    end;

    local procedure ClassifySalesQuoteEntityBuffer()
    var
        DummySalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Quote Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Tax Liable"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("VAT Bus. Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Calculation"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Value"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Valid Until Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Sent to Customer"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Accepted"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Accepted Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Subtotal Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Country/Region Code"));
    end;

    local procedure ClassifySalesCrMemoEntityBuffer()
    var
        DummySalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr. Memo Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Shipping Advice"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Completely Shipped"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Requested Delivery Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Country/Region Code"));
    end;

    local procedure ClassifyPurchCrMemoEntityBuffer()
    var
        DummyPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := Database::"Purch. Cr. Memo Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Reason Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"));
    end;

    local procedure ClassifyVendorBankAccount()
    var
        DummyVendorBankAccount: Record "Vendor Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Vendor Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(IBAN));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Home Page"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Language Code"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Telex Answer Back"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Transit No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Bank Account No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Bank Branch No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Telex No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Contact));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Name));
    end;

    local procedure ClassifyPersistentBlob()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 4151; // Persistent Blob
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 2); // Blob
    end;

    local procedure ClassifyPostedGenJournalLine()
    var
        DummyPostedGenJournalLine: Record "Posted Gen. Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Gen. Journal Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedGenJournalLine.FieldNo("VAT Registration No."));
    end;

    local procedure ClassifyPurchaseOrderEntityBuffer()
    var
        PurchOrderEntityBufer: Record "Purchase Order Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Order Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Completely Received"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Requested Receipt Date"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo(Status));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Country/Region Code"));
    end;

    local procedure ClassifyBankAccRecMatchBuffer()
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Acc. Rec. Match Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Bank Account No."));
    end;

    local procedure ClassifyPermissionSetInPlan()
    var
        TableNo: Integer;
    begin
        TableNo := 9018; // Database::"Custom Permission Set In Plan"
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, 3); // FieldNo("Role ID")
        SetFieldToCompanyConfidential(TableNo, 8); // FieldNo("Company Name")

        TableNo := 9019; // Database::"Default Permission Set In Plan"
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, 3); // FieldNo("Role ID")
    end;

    local procedure ClassifyRemitToAddress()
    var
        RemitAddress: Record "Remit Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Remit Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Name));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Contact));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Home Page"));
    end;

    local procedure ClassifyICBankAccount()
    var
        RemitAddress: Record "IC Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Name));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Bank Account No."));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(IBAN));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateEvaluationDataOnAfterClassifyTablesToNormal()
    begin
    end;
}
