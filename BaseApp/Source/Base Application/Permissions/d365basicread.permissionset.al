namespace System.Security.AccessControl;

using Microsoft.AccountantPortal;
using Microsoft.Booking;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Team;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Location;
using Microsoft.Projects.TimeSheet;
using Microsoft.CostAccounting.Setup;
using Microsoft.Manufacturing.Reports;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Reporting;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Navigate;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.Payroll;
using Microsoft.Projects.Project.Setup;
using System.Security.Authentication;
using System.Globalization;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Registration;
using System.Reflection;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using System.Tooling;
using System.Privacy;
using System.Utilities;
#if not CLEAN24
using Microsoft.Bank.Deposit;
#endif
using Microsoft.Inventory.Transfer;
using System.Integration;
using System.IO;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;
using System.DateTime;
using Microsoft.Finance.FinancialReports;
using Microsoft.Integration.Entity;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Inventory.Analysis;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Availability;
using System.Azure.Identity;
using System.AI;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Reconciliation;
using System.Visualization;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.BOM;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.Consolidation;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Finance.Dimension;
using System.Diagnostics;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Costing;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.PowerBI;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Analysis;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.Deferral;
using Microsoft.Sales.Receivables;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.Dimension.Correction;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using System.Email;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Tracking;
using Microsoft.CRM.Outlook;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Finance.RoleCenters;
using System.Automation;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Integration.Graph;
using Microsoft.HumanResources.Setup;
using Microsoft.Intercompany.Setup;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Setup;
using System.Security.Encryption;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item.Catalog;
using System.Threading;
using Microsoft.Manufacturing.Setup;
using Microsoft.CRM.Setup;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Purchases.Document;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Planning;
using Microsoft.Bank.PositivePay;
using System.Integration.PowerBI;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Foundation;
using Microsoft.Pricing.Worksheet;
using System.Device;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Setup;
using Microsoft.Finance.GeneralLedger.Reports;
using System.Xml;
using Microsoft.CRM.RoleCenters;
using Microsoft.Sales.Reminder;
using Microsoft.Purchases.Remittance;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Comment;
using Microsoft.Sales.RoleCenters;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.CRM.Segment;
using Microsoft.Bank.DirectDebit;
using System.Text;
using Microsoft.Finance.SalesTax;
using System.Security.User;
using Microsoft.Foundation.Period;
using Microsoft.RoleCenters;
using Microsoft.Utilities;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.Calendar;
using Microsoft.API.Upgrade;
using Microsoft.API;
using Microsoft.Intercompany.DataExchange;
using Microsoft;
using System.TestTools;
using Microsoft.Service.Contract;
using Microsoft.Service.Resources;
using Microsoft.Service.Item;

permissionset 209 "D365 Basic - Read"
{
    Access = Public;
    Caption = 'Dynamics 365 Basic - Read access';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "System App - Basic",
                             "Bus. Found. - Edit",
                             "Session - Edit";

    Permissions = tabledata "Aggregate Permission Set" = R,
                  tabledata AllObjWithCaption = R,
                  tabledata "Alt. Customer Posting Group" = R,
                  tabledata "Alt. Vendor Posting Group" = R,
                  tabledata "Buffer IC Comment Line" = R,
                  tabledata "Buffer IC Document Dimension" = R,
                  tabledata "Buffer IC Inbox Jnl. Line" = R,
                  tabledata "Buffer IC Inbox Purchase Line" = R,
                  tabledata "Buffer IC Inbox Purch Header" = R,
                  tabledata "Buffer IC Inbox Sales Header" = R,
                  tabledata "Buffer IC Inbox Sales Line" = R,
                  tabledata "Buffer IC Inbox Transaction" = R,
                  tabledata "Buffer IC InOut Jnl. Line Dim." = R,
                  tabledata "IC Incoming Notification" = R,
                  tabledata "IC Outgoing Notification" = R,
                  tabledata "Code Coverage" = R,
                  tabledata "Data Sensitivity" = R,
#if not CLEAN24
                  tabledata "Deposits Page Setup" = R,
#endif
                  tabledata "Dispute Status" = R,
                  tabledata Device = R,
                  tabledata "Direct Trans. Header" = R,
                  tabledata "Direct Trans. Line" = R,
                  tabledata Drive = R,
                  tabledata "Event Subscription" = R,
                  tabledata "Extension Execution Info" = R,
                  tabledata "Feature Key" = R,
                  tabledata Field = R,
                  tabledata File = R,
                  tabledata Integer = R,
                  tabledata "Intelligent Cloud" = R,
                  tabledata "Intelligent Cloud Status" = R,
                  tabledata Key = R,
                  tabledata "NAV App Setting" = R,
                  tabledata "Query Navigation" = R,
                  tabledata "Report Layout" = R,
                  tabledata "SID - Account ID" = R,
                  tabledata "Table Information" = R,
                  tabledata "Table Synch. Setup" = R,
                  tabledata "Tenant Web Service" = R,
                  tabledata "Upgrade Blob Storage" = R,
                  tabledata User = R,
                  tabledata "User Property" = R,
                  tabledata "AAD Application" = R,
                  tabledata "Acc. Sched. Cell Value" = R,
                  tabledata "Acc. Sched. Chart Setup Line" = R,
                  tabledata "Acc. Sched. KPI Buffer" = R,
                  tabledata "Acc. Schedule Line" = R,
                  tabledata "Acc. Schedule Line Entity" = R,
                  tabledata "Acc. Schedule Name" = R,
                  tabledata "Financial Report" = R,
                  tabledata "Financial Report User Filters" = R,
                  tabledata "Account Schedules Chart Setup" = R,
                  tabledata "Account Use Buffer" = R,
                  tabledata "Accounting Period" = R,
                  tabledata "Accounting Services Cue" = R,
                  tabledata "Activities Cue" = R,
                  tabledata "Activity Log" = R,
                  tabledata "Additional Fee Setup" = R,
                  tabledata "Adjust Exchange Rate Buffer" = R,
                  tabledata "Administration Cue" = R,
                  tabledata "Aged Report Entity" = R,
                  tabledata "Aging Band Buffer" = R,
                  tabledata "Alloc. Acc. Manual Override" = R,
                  tabledata "Alloc. Account Distribution" = R,
                  tabledata "Allocation Account" = R,
                  tabledata "Allocation Line" = R,
                  tabledata "Analysis by Dim. Parameters" = R,
                  tabledata "Analysis by Dim. User Param." = R,
                  tabledata "Analysis Dim. Selection Buffer" = R,
                  tabledata "Analysis Report Chart Line" = R,
                  tabledata "Analysis Report Chart Setup" = R,
                  tabledata "Analysis Selected Dimension" = R,
                  tabledata "API Data Upgrade" = R,
                  tabledata "API Entities Setup" = R,
                  tabledata "Application Area Buffer" = R,
                  tabledata "Application Area Setup" = R,
                  tabledata "Approval Comment Line" = R,
                  tabledata "Approval Entry" = R,
                  tabledata "Approvals Activities Cue" = R,
                  tabledata Area = R,
                  tabledata "Assisted Company Setup Status" = R,
                  tabledata "Attachment Entity Buffer" = R,
                  tabledata "Autocomplete Address" = R,
                  tabledata "Availability at Date" = R,
                  tabledata "Availability Calc. Overview" = R,
                  tabledata "Azure AD App Setup" = R,
                  tabledata "Azure AD Mgt. Setup" = R,
                  tabledata "Azure AI Usage" = R,
                  tabledata "Balance Sheet Buffer" = R,
                  tabledata "Bank Account Balance Buffer" = R,
                  tabledata "Bank Export/Import Setup" = R,
                  tabledata "Bank Statement Matching Buffer" = R,
                  tabledata "Bar Chart Buffer" = R,
                  tabledata "Base Calendar" = R,
                  tabledata "Base Calendar Change" = R,
                  tabledata "Bin Content" = R,
                  tabledata "BOM Buffer" = R,
                  tabledata "BOM Component" = R,
                  tabledata "BOM Warning Log" = R,
                  tabledata "Booking Item" = R,
                  tabledata "Booking Mailbox" = R,
                  tabledata "Booking Mgr. Setup" = R,
                  tabledata "Booking Service" = R,
                  tabledata "Booking Service Mapping" = R,
                  tabledata "Booking Staff" = R,
                  tabledata "Booking Sync" = R,
                  tabledata "Budget Buffer" = R,
                  tabledata "Bus. Unit In Cons. Process" = R,
                  tabledata "Business Chart Buffer" = R,
                  tabledata "Business Chart Map" = R,
                  tabledata "Business Chart User Setup" = R,
                  tabledata "Business Relation" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
#if not CLEAN24
                  tabledata "Calendar Event" = R,
                  tabledata "Calendar Event User Config." = R,
#endif
                  tabledata Campaign = R,
                  tabledata "Cancelled Document" = R,
                  tabledata "Cash Flow Availability Buffer" = R,
                  tabledata "Cash Flow Azure AI Buffer" = R,
                  tabledata "Cash Flow Chart Setup" = R,
                  tabledata "Cash Flow Setup" = R,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "Change Global Dim. Header" = R,
                  tabledata "Change Global Dim. Log Entry" = R,
                  tabledata "Change Log Entry" = r,
                  tabledata "Change Log Setup (Field)" = r,
                  tabledata "Change Log Setup (Table)" = r,
                  tabledata "Change Log Setup" = r,
                  tabledata "Chart Definition" = R,
                  tabledata "Close Income Statement Buffer" = R,
                  tabledata "Column Layout" = R,
                  tabledata "Column Layout Name" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Company Information" = R,
                  tabledata "Company Size" = R,
                  tabledata "Config. Field Map" = R,
                  tabledata "Config. Line" = R,
                  tabledata "Config. Media Buffer" = R,
                  tabledata "Config. Package" = R,
                  tabledata "Config. Package Data" = R,
                  tabledata "Config. Package Error" = R,
                  tabledata "Config. Package Field" = R,
                  tabledata "Config. Package Filter" = R,
                  tabledata "Config. Package Record" = R,
                  tabledata "Config. Package Table" = R,
                  tabledata "Config. Question" = R,
                  tabledata "Config. Question Area" = R,
                  tabledata "Config. Questionnaire" = R,
                  tabledata "Config. Record For Processing" = R,
                  tabledata "Config. Related Field" = R,
                  tabledata "Config. Related Table" = R,
                  tabledata "Config. Selection" = R,
                  tabledata "Config. Setup" = R,
                  tabledata "Config. Table Processing Rule" = R,
                  tabledata "Config. Template Header" = R,
                  tabledata "Config. Template Line" = R,
                  tabledata "Config. Tmpl. Selection Rules" = R,
                  tabledata "Consolidation Account" = R,
                  tabledata "Consolidation Process" = R,
                  tabledata "Consolidation Setup" = R,
                  tabledata Contact = R,
                  tabledata "Contact Alt. Addr. Date Range" = R,
                  tabledata "Contact Alt. Address" = R,
                  tabledata "Copy Gen. Journal Parameters" = R,
                  tabledata "Copy Item Buffer" = R,
                  tabledata "Copy Item Parameters" = R,
                  tabledata "Cost Accounting Setup" = R,
                  tabledata "Cost Element Buffer" = R,
                  tabledata "Cost Share Buffer" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Country/Region Translation" = R,
                  tabledata "CRM Connection Setup" = R,
                  tabledata "CSV Buffer" = R,
                  tabledata "Curr. Exch. Rate Update Setup" = R,
                  tabledata Currency = R,
                  tabledata "Currency Amount" = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Currency Total Buffer" = R,
                  tabledata "Custom Address Format" = R,
                  tabledata "Custom Address Format Line" = R,
                  tabledata "Custom Report Layout" = R,
                  tabledata "Custom Report Selection" = R,
                  tabledata Customer = R,
                  tabledata "Customer Amount" = R,
                  tabledata "Customer Discount Group" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Customer Sales Buffer" = R,
                  tabledata "Customer Templ." = R,
                  tabledata "Customized Calendar Change" = R,
                  tabledata "CV Ledger Entry Buffer" = R,
                  tabledata "Data Exch." = R,
                  tabledata "Data Exch. Column Def" = R,
                  tabledata "Data Exch. Def" = R,
                  tabledata "Data Exch. Field" = R,
                  tabledata "Data Exch. Field Mapping" = R,
                  tabledata "Data Exch. Field Mapping Buf." = R,
                  tabledata "Data Exch. Line Def" = R,
                  tabledata "Data Exch. Mapping" = R,
                  tabledata "Data Exch. Field Grouping" = R,
                  tabledata "Data Exch. FlowField Gr. Buff." = R,
                  tabledata "Data Exchange Type" = R,
                  tabledata "Data Exch. Table Filter" = R,
                  tabledata "Data Privacy Records" = R,
                  tabledata "DataExch-RapidStart Buffer" = R,
                  tabledata "Date Lookup Buffer" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Deferral Header" = R,
                  tabledata "Deferral Header Archive" = R,
                  tabledata "Deferral Line" = R,
                  tabledata "Deferral Line Archive" = R,
                  tabledata "Deferral Posting Buffer" = R,
                  tabledata "Deferral Template" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Detailed CV Ledg. Entry Buffer" = R,
                  tabledata "Detailed Employee Ledger Entry" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "Dim Correct Selection Criteria" = R,
                  tabledata "Dim Correction Blocked Setup" = R,
                  tabledata "Dim Correction Change" = R,
                  tabledata "Dim Correction Set Buffer" = R,
                  tabledata "Dim Correction Entry Log" = R,
                  tabledata "Dim. Value per Account" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Buffer" = R,
                  tabledata "Dimension Code Amount Buffer" = R,
                  tabledata "Dimension Code Buffer" = R,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Correction" = R,
                  tabledata "Dimension Entry Buffer" = R,
                  tabledata "Dimension ID Buffer" = R,
                  tabledata "Dimension Selection Buffer" = R,
                  tabledata "Dimension Set Entry" = R,
                  tabledata "Dimension Set Entry Buffer" = R,
                  tabledata "Dimension Set ID Filter Line" = R,
                  tabledata "Dimension Set Tree Node" = R,
                  tabledata "Dimension Translation" = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "Dimensions Field Map" = R,
                  tabledata "Dimensions Template" = R,
                  tabledata "Doc. Exch. Service Setup" = R,
                  tabledata "Document Attachment" = R,
                  tabledata "Document Entry" = R,
                  tabledata "Document Search Result" = R,
                  tabledata "Document Sending Profile" = R,
#if not CLEAN23
                  tabledata "Document Service Cache" = R,
#endif
                  tabledata "Drop Shpt. Post. Buffer" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Dynamic Request Page Entity" = R,
                  tabledata "Dynamic Request Page Field" = R,
                  tabledata "ECSL VAT Report Line" = R,
                  tabledata "ECSL VAT Report Line Relation" = R,
                  tabledata "Electronic Document Format" = R,
                  tabledata "Email Item" = R,
                  tabledata "Email Parameter" = R,
                  tabledata "Employee Payment Buffer" = R,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Employee Templ." = R,
                  tabledata "Employee Time Reg Buffer" = R,
                  tabledata "Entry No. Amount Buffer" = R,
                  tabledata "Entry Summary" = R,
                  tabledata "Entry/Exit Point" = R,
                  tabledata "Error Buffer" = R,
                  tabledata "Error Handling Parameters" = R,
                  tabledata "Error Message" = R,
                  tabledata "Error Message Register" = R,
                  tabledata "Excel Buffer" = R,
                  tabledata "Excel Template Storage" = R,
                  tabledata "Exchange Contact" = R,
                  tabledata "Exchange Object" = R,
                  tabledata "Exchange Service Setup" = R,
                  tabledata "Exchange Sync" = R,
                  tabledata "Experience Tier Buffer" = R,
                  tabledata "Experience Tier Setup" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "Field Buffer" = R,
                  tabledata "Field Monitoring Setup" = R,
                  tabledata "Filter Item Attributes Buffer" = R,
                  tabledata "Finance Charge Terms" = R,
                  tabledata "Finance Cue" = R,
                  tabledata "Flow Service Configuration" = r,
                  tabledata "Flow User Environment Buffer" = R,
                  tabledata "Flow User Environment Config" = R,
                  tabledata "G/L - Item Ledger Relation" = R,
                  tabledata "G/L Acc. Balance Buffer" = R,
                  tabledata "G/L Acc. Balance/Budget Buffer" = R,
                  tabledata "G/L Acc. Budget Buffer" = R,
                  tabledata "G/L Account" = r,
                  tabledata "G/L Account Category" = r,
                  tabledata "G/L Account Net Change" = R,
                  tabledata "G/L Account Where-Used" = R,
                  tabledata "G/L Account Source Currency" = r,
                  tabledata "G/L Entry" = r,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = R,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Line" = R,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Generic Chart Captions Buffer" = R,
                  tabledata "Generic Chart Filter" = R,
                  tabledata "Generic Chart Memo Buffer" = R,
                  tabledata "Generic Chart Query Column" = R,
                  tabledata "Generic Chart Setup" = R,
                  tabledata "Generic Chart Y-Axis" = R,
                  tabledata Geolocation = R,
                  tabledata "Human Resources Setup" = R,
                  tabledata "IC Setup" = R,
                  tabledata "Image Analysis Setup" = R,
                  tabledata "Image Analysis Scenario" = R,
                  tabledata "Import G/L Transaction" = R,
                  tabledata "Incoming Document" = R,
                  tabledata "Incoming Document Approver" = R,
                  tabledata "Incoming Document Attachment" = R,
                  tabledata "Incoming Documents Setup" = R,
                  tabledata "Interaction Merge Data" = R,
                  tabledata "Interaction Template Setup" = R,
                  tabledata "Invalidated Dim Correction" = R,
                  tabledata "Inventory Adjustment Buffer" = R,
                  tabledata "Inventory Buffer" = R,
                  tabledata "Inventory Event Buffer" = R,
                  tabledata "Inventory Page Data" = R,
                  tabledata "Inventory Period" = R,
                  tabledata "Inventory Period Entry" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata "Inventory Setup" = R,
#if not CLEAN23
                  tabledata "Invoice Post. Buffer" = R,
#endif
                  tabledata "Invoice Posting Buffer" = R,
                  tabledata "Invoiced Booking Item" = R,
                  tabledata "Invt. Post to G/L Test Buffer" = R,
                  tabledata "Invt. Posting Buffer" = R,
                  tabledata "Isolated Certificate" = R,
                  tabledata Item = R,
                  tabledata "Item Amount" = R,
                  tabledata "Item Application Entry" = R,
                  tabledata "Item Application Entry History" = R,
                  tabledata "Item Attr. Value Translation" = R,
                  tabledata "Item Attribute" = R,
                  tabledata "Item Attribute Translation" = R,
                  tabledata "Item Attribute Value" = R,
                  tabledata "Item Attribute Value Mapping" = R,
                  tabledata "Item Attribute Value Selection" = R,
                  tabledata "Item Availability Buffer" = R,
                  tabledata "Item Availability by Date" = R,
                  tabledata "Item Budget Buffer" = R,
                  tabledata "Item Discount Group" = R,
                  tabledata "Item Journal Batch" = R,
                  tabledata "Item Journal Buffer" = R,
                  tabledata "Item Journal Line" = R,
                  tabledata "Item Journal Template" = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Picture Buffer" = R,
                  tabledata "Item Statistics Buffer" = R,
                  tabledata "Item Substitution" = R,
                  tabledata "Item Templ." = R,
                  tabledata "Item Tracking Comment" = R,
                  tabledata "Item Translation" = R,
                  tabledata "Item Turnover Buffer" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Item Vendor" = R,
                  tabledata "Job Queue Category" = R,
                  tabledata "Job Queue Entry" = R,
                  tabledata "Job Queue Entry Buffer" = R,
                  tabledata "Job Queue Log Entry" = R,
                  tabledata "Jobs Setup" = R,
                  tabledata "Journal User Preferences" = R,
                  tabledata "JSON Buffer" = R,
                  tabledata "Last Used Chart" = R,
                  tabledata "Ledger Entry Matching Buffer" = R,
                  tabledata "License Agreement" = R,
                  tabledata "Line Number Buffer" = R,
                  tabledata "Load Buffer" = R,
                  tabledata Location = R,
                  tabledata "Manufacturing Setup" = R,
                  tabledata "Marketing Setup" = R,
                  tabledata "Media Repository" = R,
                  tabledata "Memoized Result" = R,
                  tabledata "MS-QBD Setup" = R,
                  tabledata "My Account" = R,
                  tabledata "My Customer" = R,
                  tabledata "My Item" = R,
                  tabledata "My Notifications" = R,
                  tabledata "My Time Sheets" = R,
                  tabledata "My Vendor" = R,
                  tabledata "Name/Value Buffer" = R,
                  tabledata "Named Forward Link" = R,
                  tabledata "Notification Context" = R,
                  tabledata "Notification Entry" = R,
                  tabledata "Notification Schedule" = R,
                  tabledata "Notification Setup" = R,
                  tabledata "O365 Brand Color" = R,
                  tabledata "O365 Device Setup Instructions" = R,
                  tabledata "O365 Getting Started" = R,
                  tabledata "O365 Getting Started Page Data" = R,
                  tabledata "O365 HTML Template" = R,
                  tabledata "O365 Payment Service Logo" = R,
                  tabledata "OAuth 2.0 Setup" = R,
                  tabledata "Object Translation" = R,
                  tabledata "OCR Service Document Template" = R,
                  tabledata "OCR Service Setup" = R,
                  tabledata "OData Initialized Status" = R,
                  tabledata "Office Add-in" = R,
                  tabledata "Office Add-in Context" = R,
                  tabledata "Office Add-in Setup" = R,
                  tabledata "Office Admin. Credentials" = R,
                  tabledata "Office Contact Details" = R,
                  tabledata "Office Document Selection" = R,
                  tabledata "Office Invoice" = R,
                  tabledata "Office Job Journal" = R,
                  tabledata "Office Suggested Line Item" = R,
                  tabledata "Online Bank Acc. Link" = R,
                  tabledata "Online Map Parameter Setup" = R,
                  tabledata "Online Map Setup" = R,
                  tabledata "Option Lookup Buffer" = r,
                  tabledata "Order Address" = R,
                  tabledata "Over-Receipt Code" = R,
                  tabledata "Overdue Approval Entry" = R,
                  tabledata "Vendor Payment Buffer" = R,
                  tabledata "Page Info And Fields" = R,
                  tabledata "Payment Export Data" = R,
                  tabledata "Payment Export Remittance Text" = R,
                  tabledata "Payment Jnl. Export Error Text" = R,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Method Translation" = R,
                  tabledata "Payment Registration Buffer" = R,
                  tabledata "Payment Registration Setup" = R,
                  tabledata "Payment Reporting Argument" = R,
                  tabledata "Payment Service Setup" = R,
                  tabledata "Payment Term Translation" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Payroll Import Buffer" = R,
                  tabledata "Payroll Setup" = R,
                  tabledata "Phys. Inventory Ledger Entry" = R,
                  tabledata "Picture Entity" = R,
                  tabledata "Planning Assignment" = R,
                  tabledata "Positive Pay Detail" = R,
                  tabledata "Positive Pay Entry" = R,
                  tabledata "Positive Pay Entry Detail" = R,
                  tabledata "Positive Pay Footer" = R,
                  tabledata "Positive Pay Header" = R,
                  tabledata "Post Code" = R,
                  tabledata "Post Value Entry to G/L" = R,
                  tabledata "Postcode Service Config" = R,
                  tabledata "Posted Approval Comment Line" = R,
                  tabledata "Posted Approval Entry" = R,
                  tabledata "Posted Deferral Header" = R,
                  tabledata "Posted Deferral Line" = R,
                  tabledata "Posted Docs. With No Inc. Buf." = R,
                  tabledata "Posted Gen. Journal Batch" = R,
                  tabledata "Posted Gen. Journal Line" = R,
#if not CLEAN23
                  tabledata "Power BI User Configuration" = R,
                  tabledata "Power BI Report Configuration" = R,
                  tabledata "Power BI User Status" = R,
#endif
                  tabledata "Power BI Chart Buffer" = R,
                  tabledata "Power BI Context Settings" = R,
                  tabledata "Power BI Customer Reports" = R,
                  tabledata "Power BI Displayed Element" = R,
                  tabledata "Power BI Report Labels" = R,
                  tabledata "Power BI Report Uploads" = R,
                  tabledata "Prepayment Inv. Line Buffer" = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Printer Selection" = R,
                  tabledata "Purch. Comment Line" = R,
                  tabledata "Purch. Comment Line Archive" = R,
                  tabledata "Purch. Cr. Memo Entity Buffer" = R,
                  tabledata "Purch. Inv. Entity Aggregate" = R,
                  tabledata "Purch. Inv. Line Aggregate" = R,
#if not CLEAN25
                  tabledata "Purch. Price Line Disc. Buff." = R,
#endif
                  tabledata "Purchase Cue" = R,
                  tabledata "Purchase Discount Access" = R,
                  tabledata "Purchase Header" = R,
                  tabledata "Purchase Line" = R,
#if not CLEAN25
                  tabledata "Purchase Line Discount" = R,
#endif
                  tabledata "Purchase Order Entity Buffer" = R,
                  tabledata "Purchase Prepayment %" = R,
#if not CLEAN25
                  tabledata "Purchase Price" = R,
#endif
                  tabledata "Purchase Price Access" = R,
                  tabledata "Purchases & Payables Setup" = R,
                  tabledata "RapidStart Services Cue" = R,
                  tabledata "RC Headlines User Data" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Receivables-Payables Buffer" = R,
                  tabledata "Reclas. Dimension Set Buffer" = R,
                  tabledata "Reconcile CV Acc Buffer" = R,
                  tabledata "Record Export Buffer" = R,
                  tabledata "Record Set Buffer" = R,
                  tabledata "Record Set Definition" = R,
                  tabledata "Record Set Tree" = R,
                  tabledata "Recorded Event Buffer" = R,
                  tabledata "Referenced XML Schema" = R,
                  tabledata "Relationship Mgmt. Cue" = R,
                  tabledata "Reminder Attachment Text" = R,
                  tabledata "Reminder Attachment Text Line" = R,
                  tabledata "Reminder Email Text" = R,
                  tabledata "Reminder Terms" = R,
                  tabledata "Reminder Terms Translation" = R,
                  tabledata "Reminder Action Group" = R,
                  tabledata "Reminder Action" = R,
                  tabledata "Create Reminders Setup" = R,
                  tabledata "Issue Reminders Setup" = R,
                  tabledata "Send Reminders Setup" = R,
                  tabledata "Reminder Automation Error" = R,
                  tabledata "Reminder Action Group Log" = R,
                  tabledata "Reminder Action Log" = R,
                  tabledata "Remit Address" = R,
                  tabledata "Report Inbox" = R,
                  tabledata "Report Layout Selection" = R,
                  tabledata "Report Layout Update Log" = R,
                  tabledata "Report List Translation" = R,
                  tabledata "Report Selection Warehouse" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Report Totals Buffer" = R,
                  tabledata "Req. Wksh. Template" = R,
                  tabledata "Requisition Line" = R,
                  tabledata "Requisition Wksh. Name" = R,
                  tabledata "Res. Availability Buffer" = R,
                  tabledata "Res. Gr. Availability Buffer" = R,
                  tabledata "Res. Journal Batch" = R,
                  tabledata "Res. Journal Template" = R,
                  tabledata "Res. Ledger Entry" = R,
                  tabledata "Reservation Entry" = R,
                  tabledata "Reservation Entry Buffer" = R,
                  tabledata Resource = R,
                  tabledata "Resource Group" = R,
                  tabledata "Resource Register" = R,
                  tabledata "Resources Setup" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Restricted Record" = R,
                  tabledata "Reversal Entry" = R,
                  tabledata "Role Center Notifications" = R,
                  tabledata "Rounding Method" = R,
                  tabledata "Rounding Residual Buffer" = R,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Sales by Cust. Grp.Chart Setup" = R,
                  tabledata "Sales Comment Line" = R,
                  tabledata "Sales Comment Line Archive" = R,
                  tabledata "Sales Cr. Memo Entity Buffer" = R,
                  tabledata "Sales Cue" = R,
                  tabledata "Sales Discount Access" = R,
                  tabledata "Sales Document Icon" = R,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Invoice Entity Aggregate" = R,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Invoice Line Aggregate" = R,
                  tabledata "Sales Line" = R,
#if not CLEAN25
                  tabledata "Sales Line Discount" = R,
#endif
                  tabledata "Sales Order Entity Buffer" = R,
                  tabledata "Sales Prepayment %" = R,
#if not CLEAN25
                  tabledata "Sales Price" = R,
#endif
                  tabledata "Sales Price Access" = R,
#if not CLEAN25
                  tabledata "Sales Price and Line Disc Buff" = R,
#endif
                  tabledata "Sales Quote Entity Buffer" = R,
                  tabledata "Sales Shipment Buffer" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "SB Owner Cue" = R,
                  tabledata "Segment Line" = R,
                  tabledata "Selected Dimension" = R,
                  tabledata "Semi-Manual Execution Log" = R,
                  tabledata "Semi-Manual Test Wizard" = R,
                  tabledata "Sent Notification Entry" = R,
                  tabledata "SEPA Direct Debit Mandate" = R,
                  tabledata "Service Connection" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipment Method Translation" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Sorting Table" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Address" = R,
                  tabledata "Standard Customer Sales Code" = R,
                  tabledata "Standard General Journal" = R,
                  tabledata "Standard General Journal Line" = R,
                  tabledata "Standard Item Journal" = R,
                  tabledata "Standard Item Journal Line" = R,
                  tabledata "Standard Purchase Code" = R,
                  tabledata "Standard Purchase Line" = R,
                  tabledata "Standard Sales Code" = R,
                  tabledata "Standard Sales Line" = R,
                  tabledata "Standard Text" = R,
                  tabledata "Standard Vendor Purchase Code" = R,
                  tabledata "Support Contact Information" = R,
                  tabledata "Table Filter" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Buffer" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Area Translation" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Group Buffer" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Tax Jurisdiction Translation" = R,
                  tabledata "Tax Rate Buffer" = R,
                  tabledata "Tax Setup" = R,
                  tabledata "Team Member Cue" = R,
                  tabledata TempStack = R,
                  tabledata "Tenant Config. Package File" = R,
                  tabledata "Terms And Conditions" = R,
                  tabledata "Terms And Conditions State" = R,
                  tabledata Territory = R,
                  tabledata "Text-to-Account Mapping" = R,
                  tabledata "Time Series Buffer" = R,
                  tabledata "Time Series Forecast" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = R,
                  tabledata "Time Sheet Detail Archive" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Header Archive" = R,
                  tabledata "Time Sheet Line" = R,
                  tabledata "Time Sheet Line Archive" = R,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Top Customers By Sales Buffer" = R,
                  tabledata "Tracking Specification" = R,
                  tabledata "Trailing Sales Orders Setup" = R,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transformation Rule" = R,
                  tabledata "Trial Balance Cache" = R,
                  tabledata "Trial Balance Cache Info" = R,
                  tabledata "Trial Balance Entity Buffer" = R,
                  tabledata "Trial Balance Setup" = R,
                  tabledata "Unit Group" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "Unlinked Attachment" = R,
                  tabledata "User Preference" = R,
                  tabledata "User Setup" = R,
                  tabledata "User Task" = R,
                  tabledata "User Task Group" = R,
                  tabledata "User Task Group Member" = R,
                  tabledata "User Time Register" = R,
                  tabledata "User Tours" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Clause" = R,
                  tabledata "VAT Clause by Doc. Type" = R,
                  tabledata "VAT Clause by Doc. Type Trans." = R,
                  tabledata "VAT Clause Translation" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Registration Log" = R,
                  tabledata "VAT Report Archive" = R,
                  tabledata "VAT Reports Configuration" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Statement Line" = R,
                  tabledata "VAT Statement Name" = R,
                  tabledata "VAT Statement Report Line" = R,
                  tabledata "VAT Statement Template" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "Alt. Cust. VAT Reg." = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Amount" = R,
                  tabledata "Vendor Posting Group" = R,
                  tabledata "Vendor Purchase Buffer" = R,
                  tabledata "Vendor Templ." = R,
                  tabledata "Warehouse Class" = R,
                  tabledata "Warehouse Setup" = R,
                  tabledata "WF Event/Response Combination" = R,
                  tabledata "Workflow - Record Change" = R,
                  tabledata "Workflow - Table Relation" = R,
                  tabledata Workflow = R,
                  tabledata "Workflow Buffer" = R,
                  tabledata "Workflow Category" = R,
                  tabledata "Workflow Event" = R,
                  tabledata "Workflow Event Queue" = R,
                  tabledata "Workflow Record Change Archive" = R,
                  tabledata "Workflow Response" = R,
                  tabledata "Workflow Rule" = R,
                  tabledata "Workflow Step" = R,
                  tabledata "Workflow Step Argument" = R,
                  tabledata "Workflow Step Argument Archive" = R,
                  tabledata "Workflow Step Buffer" = R,
                  tabledata "Workflow Step Instance" = R,
                  tabledata "Workflow Step Instance Archive" = R,
                  tabledata "Workflow Table Relation Value" = R,
                  tabledata "Workflow User Group" = R,
                  tabledata "Workflow User Group Member" = R,
                  tabledata "Workflow Webhook Entry" = R,
                  tabledata "Workflow Webhook Notification" = R,
                  tabledata "Workflows Entries Buffer" = R,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = R,
                  tabledata "XML Schema Element" = R,
                  tabledata "XML Schema Restriction" = R,

                  // Service
                  tabledata "Contract Trend Buffer" = R,
                  tabledata "Resource Skill" = R,
                  tabledata "Service Item Trend Buffer" = R;
}
