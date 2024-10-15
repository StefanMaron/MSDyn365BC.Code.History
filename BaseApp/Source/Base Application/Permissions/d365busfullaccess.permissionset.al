namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.AccountantPortal;
using Microsoft.API;
using Microsoft.API.Upgrade;
using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Reports;
using Microsoft.Booking;
using Microsoft.Bank.Payment;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
#if not CLEAN24
using Microsoft.Bank.Deposit;
#endif
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Forecast;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.RoleCenters;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension.Correction;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Payroll;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.RoleCenters;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Task;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Integration.PowerBI;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
#if not CLEAN23
using Microsoft.Projects.Resources.Pricing;
#endif
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
#if not CLEAN23
using Microsoft.Purchases.Pricing;
#endif
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
#if not CLEAN23
using Microsoft.Sales.Pricing;
#endif
using Microsoft.Sales.Reminder;
using Microsoft.Sales.RoleCenters;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.RoleCenters;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.RoleCenters;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

using System.AI;
using System.Apps;
using System.Automation;
using System.DateTime;
using System.Device;
using System.Diagnostics;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Globalization;
using System.Integration;
using System.Integration.PowerBI;
using System.IO;
using System.Privacy;
using System.Reflection;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Security.User;
using System.TestTools;
using System.TestTools.TestRunner;
using System.Text;
using System.Threading;
using System.Tooling;
using System.Utilities;
using System.Visualization;
using System.Xml;

permissionset 959 "D365 BUS FULL ACCESS"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dyn. 365 Full Business Acc.';

    IncludedPermissionSets = "Company - Edit",
                             "D365 BASIC",
                             "D365 ADCS, EDIT",
                             "D365 ACC. PAYABLE",
                             "D365 ACC. RECEIVABLE",
                             "D365 ASSEMBLY, SETUP",
                             "D365 ASSEMBLY, EDIT",
                             "D365 BANKING",
                             "D365 CASH FLOW",
                             "D365 COSTACC, EDIT",
                             "D365 COSTACC, SETUP",
                             "D365 DYN CRM MGT",
                             "D365 FA, EDIT",
                             "D365 FA, SETUP",
                             "D365 FINANCIAL REP.",
                             "D365 GLOBAL DIM MGT",
                             "D365 HR, EDIT",
                             "D365 HR, SETUP",
                             "D365 IC, EDIT",
                             "D365 IC, SETUP",
                             "D365 INV DOC, CREATE",
                             "D365 INV DOC, POST",
                             "D365 JOBS, EDIT",
                             "D365 OPPORTUNITY MGT",
                             "D365 RM SETUP",
                             "D365 SETUP",
                             "D365 WEBHOOK SUBSCR",
                             "D365 WHSE, EDIT",
                             "LOCAL",
                             "LOGIN";

    Permissions = system "Tools, Security, Roles" = X,
                  tabledata "Add-in" = imd,
                  tabledata "All Profile" = imd,
                  tabledata AllObjWithCaption = R,
                  tabledata "Designed Query Group" = IMD,
                  tabledata "Designed Query Permission" = IMD,
                  tabledata "Object Access Intent Override" = Rimd,
                  tabledata Permission = imd,
                  tabledata "Permission Set" = imd,
                  tabledata "Profile Configuration Symbols" = imd,
                  tabledata "Published Application" = Rimd,
#pragma warning disable AL0432
                  tabledata "Tenant Profile" = imd,
#pragma warning restore AL0432
                  tabledata "Tenant Profile Extension" = imd,
                  tabledata "Tenant Profile Setting" = imd,
                  tabledata "Tenant Web Service" = R,
                  tabledata User = D,
                  tabledata "AAD Application" = RIMD,
                  tabledata "Acc. Sched. Cell Value" = RIM,
                  tabledata "Acc. Sched. Chart Setup Line" = RIMD,
                  tabledata "Acc. Sched. KPI Buffer" = RIMD,
                  tabledata "Account Schedules Chart Setup" = RIMD,
                  tabledata "Account Use Buffer" = RIMD,
                  tabledata "Accounting Services Cue" = RIMD,
                  tabledata "Action Message Entry" = RIM,
                  tabledata "Activities Cue" = RIMD,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Additional Fee Setup" = RIMD,
                  tabledata "Adjust Exchange Rate Buffer" = RIMD,
                  tabledata "Administration Cue" = RIMD,
                  tabledata "Aged Report Entity" = RIMD,
                  tabledata "Aging Band Buffer" = RIMD,
                  tabledata "Allocation Policy" = RIMD,
                  tabledata "Alternative Address" = IM,
                  tabledata "Analysis by Dim. Parameters" = RIMD,
                  tabledata "Analysis by Dim. User Param." = RIMD,
                  tabledata "Analysis Dim. Selection Buffer" = RIMD,
                  tabledata "Analysis Field Value" = IM,
                  tabledata "Analysis Report Chart Line" = RIMD,
                  tabledata "Analysis Report Chart Setup" = RIMD,
                  tabledata "Analysis Selected Dimension" = RIMD,
                  tabledata "API Data Upgrade" = RIMD,
                  tabledata "API Entities Setup" = RIMD,
                  tabledata "API Extension Upload" = rimd,
                  tabledata "Application Area Buffer" = RIMD,
                  tabledata "Application Area Setup" = RIMD,
                  tabledata "Approval Comment Line" = RIMD,
                  tabledata "Approval Entry" = Rimd,
                  tabledata "Approvals Activities Cue" = RIMD,
                  tabledata "Assembly Comment Line" = RIMD,
                  tabledata "ATO Sales Buffer" = RIMD,
                  tabledata "Attachment Entity Buffer" = RIMD,
                  tabledata Attendee = RIMD,
                  tabledata "Autocomplete Address" = RIMD,
                  tabledata "Availability at Date" = RIM,
                  tabledata "Availability Calc. Overview" = RIM,
                  tabledata "Average Cost Calc. Overview" = RIM,
                  tabledata "Azure AI Usage" = Rimd,
                  tabledata "Balance Sheet Buffer" = RIMD,
                  tabledata "Bank Account Balance Buffer" = RIMD,
                  tabledata "Bank Clearing Standard" = RM,
                  tabledata "Bank Statement Matching Buffer" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIM,
                  tabledata "Bar Chart Buffer" = RIMD,
                  tabledata "BOM Buffer" = RIMD,
                  tabledata "BOM Warning Log" = RIMD,
                  tabledata "Booking Item" = RIMD,
                  tabledata "Booking Mailbox" = RIMD,
                  tabledata "Booking Mgr. Setup" = RIMD,
                  tabledata "Booking Service" = RIMD,
                  tabledata "Booking Service Mapping" = RIMD,
                  tabledata "Booking Staff" = RIMD,
                  tabledata "Booking Sync" = RIMD,
                  tabledata "Budget Buffer" = RIMD,
                  tabledata "Bus. Unit In Cons. Process" = RIM,
                  tabledata "Business Chart Buffer" = RIMD,
                  tabledata "Business Chart Map" = RIMD,
                  tabledata "Business Chart User Setup" = RIMD,
                  tabledata "Business Unit" = RIM,
                  tabledata "Business Unit Information" = RIM,
                  tabledata "Business Unit Setup" = RIM,
                  tabledata "CAL Test Codeunit" = RIMD,
                  tabledata "CAL Test Coverage Map" = RIMD,
                  tabledata "CAL Test Enabled Codeunit" = RIMD,
                  tabledata "CAL Test Line" = RIMD,
                  tabledata "CAL Test Method" = RIMD,
                  tabledata "CAL Test Result" = RIMD,
                  tabledata "CAL Test Suite" = RIMD,
#if not CLEAN24
                  tabledata "Calendar Event" = Rimd,
                  tabledata "Calendar Event User Config." = Rimd,
#endif
                  tabledata Campaign = RIM,
                  tabledata "Campaign Entry" = IM,
                  tabledata "Campaign Status" = RIM,
                  tabledata "Capacity Ledger Entry" = Rim,
                  tabledata "Cash Flow Availability Buffer" = RIMD,
                  tabledata "Cash Flow Azure AI Buffer" = Rimd,
                  tabledata "Cause of Inactivity" = RIMD,
                  tabledata "Certificate of Supply" = RIMD,
                  tabledata "Change Global Dim. Header" = RIMD,
                  tabledata "Change Global Dim. Log Entry" = RIMD,
                  tabledata "Change Log Entry" = Rimd,
                  tabledata "Chart Definition" = RIMD,
                  tabledata "Check Ledger Entry" = IMD,
                  tabledata "Close Income Statement Buffer" = RIMD,
                  tabledata "Column Layout" = RIMD,
                  tabledata "Column Layout Name" = RIMD,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Comment Line Archive" = RIMD,
                  tabledata Confidential = RIMD,
                  tabledata "Confidential Information" = IM,
                  tabledata "Config. Media Buffer" = RIMD,
                  tabledata "Consolidation Account" = RIM,
                  tabledata "Consolidation Process" = RIM,
                  tabledata "Consolidation Setup" = RIM,
                  tabledata "Contact Alt. Addr. Date Range" = RIMD,
                  tabledata "Contact Alt. Address" = RIMD,
                  tabledata "Contact Dupl. Details Buffer" = RIMD,
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIM,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Company Size" = RIMD,
                  tabledata "Copy Gen. Journal Parameters" = RIMD,
                  tabledata "Copy Item Buffer" = RIMD,
                  tabledata "Copy Item Parameters" = RIMD,
                  tabledata "Cost Adj. Item Bucket" = RIMD,
                  tabledata "Cost Adjustment Detailed Log" = RIMD,
                  tabledata "Cost Adjustment Log" = RIMD,
                  tabledata "Cost Element Buffer" = RIMD,
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata "Country/Region" = RIMD,
                  tabledata "Country/Region Translation" = RIMD,
                  tabledata "CRM Post Configuration" = RIMD,
                  tabledata "CRM Redirect" = IMD,
                  tabledata "CSV Buffer" = RIMD,
                  tabledata "Currency Amount" = RIMD,
                  tabledata "Currency Total Buffer" = RIMD,
                  tabledata "Current Salesperson" = RIMD,
                  tabledata "Custom Address Format" = RIMD,
                  tabledata "Custom Address Format Line" = RIMD,
                  tabledata "Custom Report Layout" = RIMD,
                  tabledata "Custom Report Selection" = RIMD,
                  tabledata "Customer Amount" = RIMD,
                  tabledata "Customer Sales Buffer" = RIMD,
                  tabledata "Customer Templ." = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "CV Ledger Entry Buffer" = RIMD,
                  tabledata "Data Exch. Column Def" = RIMD,
                  tabledata "Data Exch. Def" = RIMD,
                  tabledata "Data Exch. Field" = RIMD,
                  tabledata "Data Exch. Field Mapping" = RIMD,
                  tabledata "Data Exch. Field Mapping Buf." = RIMD,
                  tabledata "Data Exch. Line Def" = RIMD,
                  tabledata "Data Exch. Mapping" = RIMD,
                  tabledata "Data Exch. Field Grouping" = RIMD,
                  tabledata "Data Exch. FlowField Gr. Buff." = RIMD,
                  tabledata "Data Exchange Type" = IM,
                  tabledata "DataExch-RapidStart Buffer" = RIMD,
                  tabledata "Date Lookup Buffer" = RIMD,
                  tabledata "Default Dimension Priority" = RIMD,
                  tabledata "Deferral Header" = RIMD,
                  tabledata "Deferral Header Archive" = RIM,
                  tabledata "Deferral Line" = RIMD,
                  tabledata "Deferral Line Archive" = RIM,
                  tabledata "Deferral Posting Buffer" = RIMD,
                  tabledata "Deferral Template" = RIMD,
#if not CLEAN24
                  tabledata "Deposits Page Setup" = RIMD,
#endif
                  tabledata "Detailed CV Ledg. Entry Buffer" = RIMD,
                  tabledata "Dim Correct Selection Criteria" = R,
                  tabledata "Dim Correction Blocked Setup" = R,
                  tabledata "Dim Correction Change" = R,
                  tabledata "Dim Correction Set Buffer" = R,
                  tabledata "Dim Correction Entry Log" = R,
                  tabledata "Dim. Value per Account" = RIMD,
                  tabledata "Dimension Buffer" = RIMD,
                  tabledata "Dimension Code Amount Buffer" = RIMD,
                  tabledata "Dimension Code Buffer" = RIMD,
                  tabledata "Dimension Combination" = RIMD,
                  tabledata "Dimension Correction" = R,
                  tabledata "Dimension Entry Buffer" = RIMD,
                  tabledata "Dimension ID Buffer" = RIMD,
                  tabledata "Dimension Selection Buffer" = RIMD,
                  tabledata "Dimension Set Entry" = Rimd,
                  tabledata "Dimension Set Entry Buffer" = RIMD,
                  tabledata "Dimension Set ID Filter Line" = RIMD,
                  tabledata "Dimension Set Tree Node" = Rimd,
                  tabledata "Dimension Translation" = RIMD,
                  tabledata "Dimension Value Combination" = RIMD,
                  tabledata "Dimensions Field Map" = RIMD,
                  tabledata "Dimensions Template" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Document Entry" = RIMD,
                  tabledata "Document Search Result" = RIMD,
                  tabledata "Document Sending Profile" = RIMD,
#if not CLEAN23
                  tabledata "Document Service Cache" = Rimd,
#endif
                  tabledata "Drop Shpt. Post. Buffer" = RIMD,
                  tabledata "ECSL VAT Report Line" = RIMD,
                  tabledata "ECSL VAT Report Line Relation" = RIMD,
                  tabledata "Electronic Document Format" = RIMD,
                  tabledata "Email Item" = RIMD,
                  tabledata "Email Parameter" = RIMD,
                  tabledata "Employee Absence" = M,
                  tabledata "Employee Payment Buffer" = RIMD,
                  tabledata "Employee Qualification" = RIMD,
                  tabledata "Employee Relative" = RIMD,
                  tabledata "Employee Statistics Group" = RIMD,
                  tabledata "Employee Templ." = RIMD,
                  tabledata "Employee Time Reg Buffer" = RIMD,
                  tabledata "Employment Contract" = RIMD,
                  tabledata "Entry No. Amount Buffer" = RIMD,
                  tabledata "Entry Summary" = RIMD,
                  tabledata "Entry/Exit Point" = RIMD,
                  tabledata "Error Buffer" = RIMD,
                  tabledata "Error Handling Parameters" = RIMD,
                  tabledata "Error Message" = RIMD,
                  tabledata "Error Message Register" = RIMD,
                  tabledata "Excel Buffer" = RIMD,
                  tabledata "Excel Template Storage" = RIMD,
                  tabledata "Exchange Contact" = RIMD,
                  tabledata "Exchange Object" = RIMD,
                  tabledata "Exchange Sync" = RIMD,
                  tabledata "Experience Tier Buffer" = RIMD,
                  tabledata "Experience Tier Setup" = RIMD,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "FA Journal Template" = IMD,
                  tabledata "FA Location" = IMD,
                  tabledata "FA Matrix Posting Type" = IMD,
                  tabledata "FA Posting Group" = D,
                  tabledata "FA Posting Type" = IMD,
                  tabledata "FA Reclass. Journal Template" = IMD,
                  tabledata "FA Setup" = IMD,
                  tabledata "FA Subclass" = IMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Area/Symptom Code" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Field Buffer" = RIMD,
                  tabledata "Field Monitoring Setup" = Rm,
                  tabledata "Filed Contract Line" = RIMD,
                  tabledata "Filed Service Contract Header" = rm,
                  tabledata "Filter Item Attributes Buffer" = RIMD,
                  tabledata "Finance Cue" = RIMD,
                  tabledata "Flow Service Configuration" = Rimd,
                  tabledata "Flow User Environment Buffer" = RIMD,
                  tabledata "Flow User Environment Config" = RIMD,
                  tabledata "G/L Acc. Balance Buffer" = RIMD,
                  tabledata "G/L Acc. Balance/Budget Buffer" = RIMD,
                  tabledata "G/L Acc. Budget Buffer" = RIMD,
                  tabledata "G/L Account Net Change" = RIMD,
                  tabledata "G/L Account Source Currency" = RIMD,
                  tabledata "G/L Account Where-Used" = RIMD,
                  tabledata "Gen. Business Posting Group" = RIMD,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Jnl. Dim. Filter" = RIMD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Product Posting Group" = RIMD,
                  tabledata "Generic Chart Captions Buffer" = RIMD,
                  tabledata "Generic Chart Filter" = RIMD,
                  tabledata "Generic Chart Memo Buffer" = RIMD,
                  tabledata "Generic Chart Query Column" = RIMD,
                  tabledata "Generic Chart Setup" = RIMD,
                  tabledata "Generic Chart Y-Axis" = RIMD,
                  tabledata Geolocation = RIMD,
                  tabledata "Grounds for Termination" = RIMD,
                  tabledata "HR Confidential Comment Line" = RIMD,
                  tabledata "Human Resource Comment Line" = IM,
                  tabledata "Hybrid Deployment Setup" = RIMD,
                  tabledata "Image Analysis Setup" = RIMD,
                  tabledata "Image Analysis Scenario" = Rimd,
                  tabledata "Import G/L Transaction" = RIMD,
                  tabledata "Incoming Document Attachment" = RIMD,
                  tabledata "Insurance Journal Template" = IMD,
                  tabledata "Insurance Type" = IMD,
                  tabledata Integer = RIMD,
                  tabledata "Interaction Template Setup" = RIMD,
                  tabledata "Intermediate Data Import" = IM,
                  tabledata "Internal Movement Header" = RIMD,
                  tabledata "Internal Movement Line" = RIMD,
#if not CLEAN22
                  tabledata "Advanced Intrastat Checklist" = RIMD,
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
#endif
                  tabledata "Invalidated Dim Correction" = R,
                  tabledata "Inventory Adjmt. Entry (Order)" = Rim,
                  tabledata "Inventory Adjustment Buffer" = Rimd,
                  tabledata "Inventory Buffer" = RIMD,
                  tabledata "Inventory Comment Line" = RIM,
                  tabledata "Inventory Event Buffer" = RIMD,
                  tabledata "Inventory Page Data" = RIM,
                  tabledata "Inventory Period Entry" = RIM,
                  tabledata "Inventory Profile Track Buffer" = RIM,
                  tabledata "Inventory Report Entry" = RIM,
                  tabledata "Inventory Report Header" = RIM,
#if not CLEAN23
                  tabledata "Invoice Post. Buffer" = RIMD,
#endif
                  tabledata "Invoice Posting Buffer" = RIMD,
                  tabledata "Invoiced Booking Item" = RIMD,
                  tabledata "Invt. Document Header" = RIMD,
                  tabledata "Invt. Document Line" = RIMD,
                  tabledata "Invt. Post to G/L Test Buffer" = RIMD,
                  tabledata "Invt. Posting Buffer" = RIMD,
                  tabledata "Invt. Receipt Header" = Rimd,
                  tabledata "Invt. Receipt Line" = Rimd,
                  tabledata "Invt. Shipment Header" = Rimd,
                  tabledata "Invt. Shipment Line" = Rimd,
                  tabledata "Isolated Certificate" = RIMD,
                  tabledata "Issued Fin. Charge Memo Header" = D,
                  tabledata "Issued Reminder Header" = D,
                  tabledata "Item Amount" = RIMD,
                  tabledata "Item Application Entry" = RImd,
                  tabledata "Item Application Entry History" = RIM,
                  tabledata "Item Attr. Value Translation" = RIMD,
                  tabledata "Item Attribute" = RIMD,
                  tabledata "Item Attribute Translation" = RIMD,
                  tabledata "Item Attribute Value" = RIMD,
                  tabledata "Item Attribute Value Selection" = RIMD,
                  tabledata "Item Availability Buffer" = RIMD,
                  tabledata "Item Availability by Date" = RIM,
                  tabledata "Item Availability Line" = RIM,
                  tabledata "Item Budget Buffer" = RIMD,
                  tabledata "Item Budget Entry" = RIMD,
                  tabledata "Item Budget Name" = RIMD,
                  tabledata "Item Category" = RIMD,
                  tabledata "Item Charge" = RIMD,
                  tabledata "Item Charge Assignment (Purch)" = RIMD,
                  tabledata "Item Charge Assignment (Sales)" = RIMD,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Entry Relation" = RIMD,
                  tabledata "Item Identifier" = RIMD,
                  tabledata "Item Journal Batch" = RIMD,
                  tabledata "Item Journal Buffer" = RIMD,
                  tabledata "Item Journal Template" = RIMD,
                  tabledata "Item Picture Buffer" = RIMD,
                  tabledata "Item Statistics Buffer" = RIMD,
                  tabledata "Item Substitution" = RIMD,
                  tabledata "Item Templ." = RIMD,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = RIMD,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Turnover Buffer" = RIMD,
                  tabledata "Item Unit of Measure" = RIMD,
                  tabledata "Item Variant" = RIMD,
                  tabledata "Job Buffer" = Rimd,
                  tabledata "Job Difference Buffer" = Rimd,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Entry Buffer" = RIMD,
                  tabledata "Job WIP Buffer" = Rimd,
                  tabledata "Journal User Preferences" = RIMD,
                  tabledata "JSON Buffer" = RIMD,
                  tabledata "Last Used Chart" = RIMD,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "Line Number Buffer" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata "Logged Segment" = RIM,
                  tabledata "Lot Bin Buffer" = RIMD,
                  tabledata Maintenance = IMD,
                  tabledata "Manufacturing Cue" = RIMD,
                  tabledata "Manufacturing Setup" = RIMD,
                  tabledata "Manufacturing User Template" = RIMD,
                  tabledata "Media Repository" = RIMD,
                  tabledata "Memoized Result" = RIM,
                  tabledata "Merge Duplicates Buffer" = RIMD,
                  tabledata "Merge Duplicates Conflict" = RIMD,
                  tabledata "Merge Duplicates Line Buffer" = RIMD,
                  tabledata "Miniform Function" = RIMD,
                  tabledata "Miniform Function Group" = RIMD,
                  tabledata "Miniform Header" = RIMD,
                  tabledata "Miniform Line" = RIMD,
                  tabledata "Misc. Article" = RIMD,
                  tabledata "Misc. Article Information" = IM,
                  tabledata "MS-QBD Setup" = R,
                  tabledata "My Account" = RIMD,
                  tabledata "My Customer" = RIMD,
                  tabledata "My Notifications" = RIMD,
                  tabledata "My Time Sheets" = RIMD,
                  tabledata "My Vendor" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD,
                  tabledata "Named Forward Link" = RIMD,
                  tabledata "No. Series Tenant" = RIMD,
                  tabledata "Notification Context" = RIMD,
                  tabledata "Notification Schedule" = RIMD,
                  tabledata "Notification Setup" = RIMD,
                  tabledata "O365 Brand Color" = RIMD,
                  tabledata "O365 Device Setup Instructions" = RIMD,
                  tabledata "O365 Getting Started" = RIMD,
                  tabledata "O365 Getting Started Page Data" = RIMD,
                  tabledata "O365 HTML Template" = RIMD,
                  tabledata "O365 Payment Service Logo" = RIMD,
                  tabledata "OAuth 2.0 Setup" = RIMD,
                  tabledata "Object Translation" = RIMD,
                  tabledata "OCR Service Document Template" = RIMD,
                  tabledata "OData Initialized Status" = RIMD,
                  tabledata "Office Add-in" = RIMD,
                  tabledata "Office Add-in Context" = RIMD,
                  tabledata "Office Admin. Credentials" = Rimd,
                  tabledata "Office Contact Details" = RIMD,
                  tabledata "Office Document Selection" = RIMD,
                  tabledata "Office Invoice" = RIMD,
                  tabledata "Office Job Journal" = RIMD,
                  tabledata "Office Suggested Line Item" = RIMD,
                  tabledata "Online Bank Acc. Link" = RIMD,
                  tabledata "Option Lookup Buffer" = rimd,
                  tabledata "Order Promising Line" = I,
                  tabledata "Order Tracking Entry" = RIMD,
                  tabledata "Outstanding Bank Transaction" = RIMD,
                  tabledata "Over-Receipt Code" = RIMD,
                  tabledata "Overdue Approval Entry" = Rimd,
#if not CLEAN22
                  tabledata "Payment Buffer" = RIMD,
#endif
                  tabledata "Vendor Payment Buffer" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Export Remittance Text" = RIMD,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Method Translation" = RIMD,
                  tabledata "Payment Registration Buffer" = RIMD,
                  tabledata "Payment Registration Setup" = RIMD,
                  tabledata "Payment Reporting Argument" = Rimd,
                  tabledata "Payment Term Translation" = RIMD,
                  tabledata "Payroll Import Buffer" = RIMD,
                  tabledata "Payroll Setup" = RIMD,
                  tabledata "Permission Buffer" = RIMD,
                  tabledata "Permission Conflicts" = RIMD,
                  tabledata "Permission Conflicts Overview" = RIMD,
                  tabledata "Permission Set Buffer" = RIMD,
                  tabledata "Permission Set Link" = rimd,
                  tabledata "Phys. Inventory Ledger Entry" = i,
                  tabledata "Picture Entity" = RIMD,
                  tabledata "Planning Assignment" = IM,
                  tabledata "Planning Buffer" = RIMD,
                  tabledata "Planning Component" = M,
                  tabledata "Planning Error Log" = RIMD,
                  tabledata "Positive Pay Detail" = RIMD,
                  tabledata "Positive Pay Footer" = RIMD,
                  tabledata "Positive Pay Header" = RIMD,
                  tabledata "Post Value Entry to G/L" = RIm,
                  tabledata "Posted Approval Comment Line" = Rimd,
                  tabledata "Posted Approval Entry" = Rimd,
                  tabledata "Posted Deferral Header" = RIMD,
                  tabledata "Posted Deferral Line" = RIMD,
                  tabledata "Posted Docs. With No Inc. Buf." = RIMD,
                  tabledata "Posted Gen. Journal Batch" = RIMD,
                  tabledata "Posted Gen. Journal Line" = RIMD,
#if not CLEAN22
                  tabledata "Power BI Service Status Setup" = RIMD,
#endif
#if not CLEAN23
                  tabledata "Power BI User Configuration" = RIMD,
                  tabledata "Power BI Report Configuration" = RIMD,
                  tabledata "Power BI User Status" = RIMD,
#endif
                  tabledata "Power BI Chart Buffer" = RIMD,
                  tabledata "Power BI Context Settings" = RIMD,
                  tabledata "Power BI Customer Reports" = RIMD,
                  tabledata "Power BI Displayed Element" = RIMD,
                  tabledata "Power BI Report Labels" = R,
                  tabledata "Power BI Report Uploads" = RIMD,
                  tabledata "Prepayment Inv. Line Buffer" = RIMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Printer Selection" = RIMD,
                  tabledata "Prod. Order Capacity Need" = rm,
                  tabledata "Prod. Order Component" = rm,
                  tabledata "Prod. Order Line" = rm,
                  tabledata "Prod. Order Routing Line" = rm,
                  tabledata "Prod. Order Routing Personnel" = rm,
                  tabledata "Prod. Order Routing Tool" = rm,
                  tabledata "Prod. Order Rtng Qlty Meas." = rm,
                  tabledata "Production BOM Header" = r,
                  tabledata "Production BOM Line" = Rm,
                  tabledata "Production Forecast Entry" = RIMD,
                  tabledata "Production Forecast Name" = RIMD,
                  tabledata "Production Order" = rm,
                  tabledata "Purch. Comment Line" = RIMD,
                  tabledata "Purch. Comment Line Archive" = RIMD,
                  tabledata "Purch. Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = IM,
                  tabledata "Purch. Inv. Entity Aggregate" = RIMD,
                  tabledata "Purch. Inv. Line Aggregate" = RIMD,
#if not CLEAN23
                  tabledata "Purch. Price Line Disc. Buff." = RIMD,
#endif
                  tabledata "Purch. Rcpt. Header" = IM,
                  tabledata "Purchase Cue" = RIMD,
                  tabledata "Purchase Order Entity Buffer" = RIMD,
                  tabledata Qualification = RIMD,
                  tabledata "RapidStart Services Cue" = RIMD,
                  tabledata "RC Headlines User Data" = RIMD,
                  tabledata "Reason Code" = RIMD,
                  tabledata "Receivables-Payables Buffer" = RIMD,
                  tabledata "Reclas. Dimension Set Buffer" = RIMD,
                  tabledata "Reconcile CV Acc Buffer" = RIMD,
                  tabledata "Record Export Buffer" = RIMD,
                  tabledata "Record Set Buffer" = Rimd,
                  tabledata "Record Set Definition" = Rimd,
                  tabledata "Record Set Tree" = Rimd,
                  tabledata "Recorded Event Buffer" = RIMD,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Registered Invt. Movement Hdr." = RimD,
                  tabledata "Registered Invt. Movement Line" = Rimd,
                  tabledata "Relationship Mgmt. Cue" = RIMD,
                  tabledata Relative = RIMD,
                  tabledata "Reminder Terms Translation" = RIMD,
                  tabledata "Reminder Text" = IMD,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Report Inbox" = RIMD,
                  tabledata "Report Layout Selection" = RIMD,
                  tabledata "Report Layout Update Log" = RIMD,
                  tabledata "Report List Translation" = RIMD,
                  tabledata "Report Selection Warehouse" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Report Totals Buffer" = RIMD,
                  tabledata "Res. Availability Buffer" = RIMD,
                  tabledata "Res. Gr. Availability Buffer" = RIMD,
                  tabledata "Res. Journal Batch" = RIMD,
                  tabledata "Res. Journal Line" = RIM,
                  tabledata "Res. Journal Template" = RIMD,
                  tabledata "Res. Ledger Entry" = Rimd,
                  tabledata "Reservation Entry" = IM,
                  tabledata "Reservation Entry Buffer" = RIMD,
                  tabledata "Reservation Wksh. Batch" = RIMD,
                  tabledata "Reservation Wksh. Line" = RIMD,
                  tabledata "Reservation Worksheet Log" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata Resource = RIMD,
#if not CLEAN23
                  tabledata "Resource Cost" = IM,
#endif
                  tabledata "Resource Group" = RIMD,
                  tabledata "Resource Location" = RIMD,
#if not CLEAN23
                  tabledata "Resource Price" = IM,
                  tabledata "Resource Price Change" = RIMD,
#endif
                  tabledata "Resource Register" = RIMD,
                  tabledata "Resource Service Zone" = RIMD,
                  tabledata "Resource Unit of Measure" = IM,
                  tabledata "Resources Setup" = IM,
                  tabledata "Return Receipt Line" = d,
                  tabledata "Return Shipment Line" = d,
                  tabledata "Returns-Related Document" = RIMD,
                  tabledata "Reversal Entry" = RIMD,
                  tabledata "RM Matrix Management" = d,
                  tabledata "Role Center Notifications" = RIMD,
                  tabledata "Rounding Residual Buffer" = Rimd,
                  tabledata "Routing Header" = r,
                  tabledata "Sales by Cust. Grp.Chart Setup" = RIMD,
                  tabledata "Sales Comment Line" = RIMD,
                  tabledata "Sales Comment Line Archive" = RIMD,
                  tabledata "Sales Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Sales Cue" = RIMD,
                  tabledata "Sales Document Icon" = Rimd,
                  tabledata "Sales Invoice Entity Aggregate" = RIMD,
                  tabledata "Sales Invoice Line Aggregate" = RIMD,
                  tabledata "Sales Order Entity Buffer" = RIMD,
#if not CLEAN23
                  tabledata "Sales Price and Line Disc Buff" = RIMD,
#endif
                  tabledata "Sales Quote Entity Buffer" = RIMD,
                  tabledata "Sales Shipment Buffer" = RIMD,
                  tabledata "SB Owner Cue" = RIMD,
                  tabledata "Segment Interaction Language" = RIMD,
                  tabledata "Selected Dimension" = RIMD,
                  tabledata "Semi-Manual Execution Log" = RIMD,
                  tabledata "Semi-Manual Test Wizard" = RIMD,
                  tabledata "SEPA Direct Debit Mandate" = RIMD,
                  tabledata "Service Connection" = RIMD,
                  tabledata "Service Cue" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Mgt. Setup" = RI,
                  tabledata "Service Shipment Buffer" = RimD,
                  tabledata "Shipment Method Translation" = RIMD,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Sorting Table" = RIMD,
                  tabledata "Standard Address" = Rimd,
                  tabledata "Standard Cost Worksheet" = RIMD,
                  tabledata "Standard Cost Worksheet Name" = RIMD,
                  tabledata "Standard General Journal" = RIMD,
                  tabledata "Standard Service Code" = RIMD,
                  tabledata "Standard Service Item Gr. Code" = RIMD,
                  tabledata "Standard Service Line" = RIMD,
                  tabledata "Standard Text" = RIMD,
                  tabledata "Support Contact Information" = R,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Table Filter" = RIMD,
                  tabledata "Tax Area Buffer" = RIMD,
                  tabledata "Tax Group Buffer" = RIMD,
                  tabledata "Tax Rate Buffer" = RIMD,
                  tabledata "Tax Setup" = RIMD,
                  tabledata "Team Member Cue" = RIMD,
                  tabledata TempStack = RIMD,
                  tabledata "Terms And Conditions" = RIM,
                  tabledata "Terms And Conditions State" = RIM,
                  tabledata "Text-to-Account Mapping" = RIMD,
                  tabledata "Time Series Buffer" = R,
                  tabledata "Time Series Forecast" = R,
                  tabledata "Time Sheet Cmt. Line Archive" = RIMD,
                  tabledata "Time Sheet Detail Archive" = RIMD,
                  tabledata "Time Sheet Header Archive" = RIMD,
                  tabledata "Time Sheet Line Archive" = RIMD,
                  tabledata "Timeline Event" = RIM,
                  tabledata "Timeline Event Change" = RIM,
                  tabledata "Top Customers By Sales Buffer" = RIMD,
                  tabledata "Tracking Specification" = IM,
                  tabledata "Trailing Sales Orders Setup" = RIMD,
                  tabledata "Transformation Rule" = RIMD,
                  tabledata "Trial Balance Cache" = RIMD,
                  tabledata "Trial Balance Cache Info" = RIMD,
                  tabledata "Trial Balance Entity Buffer" = RIMD,
                  tabledata "Trial Balance Setup" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata Union = RIMD,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "Unlinked Attachment" = RIMD,
                  tabledata "Untracked Planning Element" = RIM,
#if not CLEAN22
                  tabledata "User Group" = R,
                  tabledata "User Group Access Control" = R,
                  tabledata "User Group Permission Set" = R,
                  tabledata "User Group Plan" = Rimd,
#endif
                  tabledata "User Preference" = RIMD,
                  tabledata "User Security Status" = RIM,
                  tabledata "User Task" = RIMD,
                  tabledata "User Tours" = RIMD,
                  tabledata "Value Entry" = Rimd,
                  tabledata "Value Entry Relation" = IMD,
                  tabledata "VAT Rate Change Log Entry" = m,
                  tabledata "VAT Registration Log" = RIMD,
                  tabledata "VAT Report Archive" = Rimd,
                  tabledata "VAT Reports Configuration" = RIMD,
                  tabledata "VAT Statement Report Line" = RIMD,
                  tabledata "Vendor Amount" = RIMD,
                  tabledata "Vendor Purchase Buffer" = RIMD,
                  tabledata "Vendor Templ." = RIMD,
                  tabledata "Warehouse Basic Cue" = RIMD,
                  tabledata "Warehouse Comment Line" = RIM,
                  tabledata "Warehouse Source Filter" = RIM,
                  tabledata "Warehouse WMS Cue" = RIMD,
                  tabledata "Warehouse Worker WMS Cue" = RIMD,
                  tabledata "Warranty Ledger Entry" = ID,
                  tabledata "WF Event/Response Combination" = RIMD,
                  tabledata "Where Used Base Calendar" = RIMD,
                  tabledata "Whse. Item Tracking Line" = RIMD,
                  tabledata "Work Center" = RIM,
                  tabledata "Work Type" = IM,
                  tabledata "Work-Hour Template" = RIMD,
                  tabledata "Workflow - Record Change" = Rimd,
                  tabledata "Workflow Buffer" = RIMD,
                  tabledata "Workflow Category" = RIMD,
                  tabledata "Workflow Record Change Archive" = Rimd,
                  tabledata "Workflow Step Argument Archive" = Rimd,
                  tabledata "Workflow Step Buffer" = RIMD,
                  tabledata "Workflow Step Instance Archive" = Rimd,
                  tabledata "Workflow Webhook Entry" = Rimd,
                  tabledata "Workflow Webhook Notification" = Rimd,
                  tabledata "Workflows Entries Buffer" = Rimd,
                  tabledata "XML Buffer" = RIMD,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD,
                  tabledata "Report Settings Override" = Rimd;
}
