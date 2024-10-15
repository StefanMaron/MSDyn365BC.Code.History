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
using Microsoft.Service.Contract;
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
using Microsoft.Foundation;
using Microsoft.Purchases.Document;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Planning;
using Microsoft.Bank.PositivePay;
using System.Integration.PowerBI;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
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
using Microsoft.Service.Resources;
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
using Microsoft.Service.Item;
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

permissionset 207 "D365 BASIC"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Basic access';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "System App - Basic",
                             "Bus. Found. - Edit",
                             "Session - Edit";

    Permissions = tabledata "Add-in" = imd,
                  tabledata "Aggregate Permission Set" = Rimd,
                  tabledata AllObj = imd,
                  tabledata AllObjWithCaption = Rimd,
                  tabledata "Alt. Customer Posting Group" = R,
                  tabledata "Alt. Vendor Posting Group" = R,
                  tabledata "Buffer IC Comment Line" = RIMD,
                  tabledata "Buffer IC Document Dimension" = RIMD,
                  tabledata "Buffer IC Inbox Jnl. Line" = RIMD,
                  tabledata "Buffer IC Inbox Purchase Line" = RIMD,
                  tabledata "Buffer IC Inbox Purch Header" = RIMD,
                  tabledata "Buffer IC Inbox Sales Header" = RIMD,
                  tabledata "Buffer IC Inbox Sales Line" = RIMD,
                  tabledata "Buffer IC Inbox Transaction" = RIMD,
                  tabledata "Buffer IC InOut Jnl. Line Dim." = RIMD,
                  tabledata "IC Incoming Notification" = RIMD,
                  tabledata "IC Outgoing Notification" = RIMD,
                  tabledata Chart = imd,
                  tabledata "Code Coverage" = Rimd,
                  tabledata "CodeUnit Metadata" = imd,
                  tabledata "Data Sensitivity" = R,
                  tabledata Date = imd,
#if not CLEAN24
                  tabledata "Deposits Page Setup" = R,
#endif
                  tabledata "Designed Query" = R,
                  tabledata "Designed Query Caption" = R,
                  tabledata "Designed Query Category" = R,
                  tabledata "Designed Query Column" = R,
                  tabledata "Designed Query Column Filter" = R,
                  tabledata "Designed Query Data Item" = R,
                  tabledata "Designed Query Filter" = R,
                  tabledata "Designed Query Group" = R,
                  tabledata "Designed Query Join" = R,
                  tabledata "Designed Query Management" = RIMD,
                  tabledata "Designed Query Obj" = Rimd,
                  tabledata "Designed Query Order By" = R,
                  tabledata "Designed Query Permission" = R,
                  tabledata "Dispute Status" = R,
                  tabledata Device = Rimd,
                  tabledata "Direct Trans. Header" = RIMD,
                  tabledata "Direct Trans. Line" = RIMD,
                  tabledata "Document Service" = imd,
                  tabledata Drive = Rimd,
                  tabledata Entitlement = imd,
                  tabledata "Entitlement Set" = imd,
                  tabledata "Event Subscription" = Rimd,
                  tabledata "Feature Key" = R,
                  tabledata Field = Rimd,
                  tabledata File = Rimd,
                  tabledata Integer = Rimd,
                  tabledata "Intelligent Cloud" = Rimd,
                  tabledata "Intelligent Cloud Status" = Rimd,
                  tabledata Key = Rimd,
                  tabledata "License Information" = imd,
                  tabledata "License Permission" = imd,
                  tabledata Media = imd,
                  tabledata "Media Set" = imd,
                  tabledata "Membership Entitlement" = imd,
                  tabledata "NAV App Setting" = RIMD,
                  tabledata "Object Metadata" = imd,
                  tabledata "Page Metadata" = imd,
                  tabledata "Permission Range" = imd,
                  tabledata "Query Navigation" = RIMD,
                  tabledata "Report Layout" = Rimd,
                  tabledata "Report Metadata" = imd,
                  tabledata "Scheduled Task" = imd,
                  tabledata "Server Instance" = imd,
                  tabledata "SID - Account ID" = Rimd,
                  tabledata "System Object" = imd,
                  tabledata "Table Information" = Rimd,
                  tabledata "Table Metadata" = imd,
                  tabledata "Table Synch. Setup" = Rimd,
                  tabledata "Tenant Profile Page Metadata" = imd,
                  tabledata "Tenant Web Service" = RIMD,
                  tabledata "Time Zone" = imd,
                  tabledata "Upgrade Blob Storage" = Rimd,
                  tabledata User = RM,
                  tabledata "User Property" = Rimd,
                  tabledata "Windows Language" = imd,
                  tabledata "AAD Application" = R,
                  tabledata "Acc. Sched. Cell Value" = Rimd,
                  tabledata "Acc. Sched. Chart Setup Line" = RIMD,
                  tabledata "Acc. Sched. KPI Buffer" = RIMD,
                  tabledata "Acc. Schedule Line" = R,
                  tabledata "Acc. Schedule Line Entity" = R,
                  tabledata "Acc. Schedule Name" = R,
                  tabledata "Financial Report" = R,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Account Schedules Chart Setup" = RIMD,
                  tabledata "Account Use Buffer" = RIMD,
                  tabledata "Accounting Period" = R,
                  tabledata "Accounting Services Cue" = RIMD,
                  tabledata "Activities Cue" = RIMD,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Additional Fee Setup" = RIMD,
                  tabledata "Adjust Exchange Rate Buffer" = RIMD,
                  tabledata "Administration Cue" = RIMD,
                  tabledata "Aged Report Entity" = RIMD,
                  tabledata "Aging Band Buffer" = Rimd,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = R,
                  tabledata "Allocation Account" = R,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Analysis by Dim. Parameters" = RIMD,
                  tabledata "Analysis by Dim. User Param." = RIMD,
                  tabledata "Analysis Dim. Selection Buffer" = RIMD,
                  tabledata "Analysis Report Chart Line" = RIMD,
                  tabledata "Analysis Report Chart Setup" = RIMD,
                  tabledata "Analysis Selected Dimension" = RIMD,
                  tabledata "API Data Upgrade" = RIMD,
                  tabledata "API Entities Setup" = RIMD,
                  tabledata "Application Area Buffer" = RIMD,
                  tabledata "Application Area Setup" = RIMD,
                  tabledata "Approval Comment Line" = RIMD,
                  tabledata "Approval Entry" = Rimd,
                  tabledata "Approvals Activities Cue" = RIMD,
                  tabledata Area = R,
                  tabledata "Assisted Company Setup Status" = R,
                  tabledata "Attachment Entity Buffer" = RIMD,
                  tabledata "Autocomplete Address" = RIMD,
                  tabledata "Availability at Date" = Rimd,
                  tabledata "Availability Calc. Overview" = R,
                  tabledata "Azure AD App Setup" = R,
                  tabledata "Azure AD Mgt. Setup" = Rim,
                  tabledata "Azure AI Usage" = Rimd,
                  tabledata "Balance Sheet Buffer" = RIMD,
                  tabledata "Bank Account Balance Buffer" = RIMD,
                  tabledata "Bank Export/Import Setup" = Rimd,
                  tabledata "Bank Statement Matching Buffer" = RIMD,
                  tabledata "Bar Chart Buffer" = RIMD,
                  tabledata "Base Calendar" = R,
                  tabledata "Base Calendar Change" = Rimd,
                  tabledata "Bin Content" = Rimd,
                  tabledata "BOM Buffer" = RIMD,
                  tabledata "BOM Component" = R,
                  tabledata "BOM Warning Log" = RIMD,
                  tabledata "Booking Item" = RIMD,
                  tabledata "Booking Mailbox" = RIMD,
                  tabledata "Booking Mgr. Setup" = RIMD,
                  tabledata "Booking Service" = RIMD,
                  tabledata "Booking Service Mapping" = RIMD,
                  tabledata "Booking Staff" = RIMD,
                  tabledata "Booking Sync" = RIMD,
                  tabledata "Budget Buffer" = RIMD,
                  tabledata "Bus. Unit In Cons. Process" = R,
                  tabledata "Business Chart Buffer" = RIMD,
                  tabledata "Business Chart Map" = RIMD,
                  tabledata "Business Chart User Setup" = RIMD,
                  tabledata "Business Relation" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
#if not CLEAN24
                  tabledata "Calendar Event" = Rimd,
                  tabledata "Calendar Event User Config." = Rimd,
#endif
                  tabledata Campaign = R,
                  tabledata "Cancelled Document" = R,
                  tabledata "Cash Flow Availability Buffer" = RIMD,
                  tabledata "Cash Flow Azure AI Buffer" = Rimd,
                  tabledata "Cash Flow Chart Setup" = R,
                  tabledata "Cash Flow Setup" = Ri,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "Change Global Dim. Header" = R,
                  tabledata "Change Global Dim. Log Entry" = R,
                  tabledata "Change Log Entry" = ri,
                  tabledata "Change Log Setup (Field)" = r,
                  tabledata "Change Log Setup (Table)" = r,
                  tabledata "Change Log Setup" = r,
                  tabledata "Chart Definition" = RIMD,
                  tabledata "Close Income Statement Buffer" = Rimd,
                  tabledata "Column Layout" = RIMD,
                  tabledata "Column Layout Name" = RIMD,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Company Information" = R,
                  tabledata "Company Size" = R,
                  tabledata "Config. Field Map" = R,
                  tabledata "Config. Line" = R,
                  tabledata "Config. Media Buffer" = RIMD,
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
                  tabledata Contact = Rim,
                  tabledata "Contact Alt. Addr. Date Range" = RIMD,
                  tabledata "Contact Alt. Address" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Copy Gen. Journal Parameters" = RIMD,
                  tabledata "Copy Item Buffer" = RIMD,
                  tabledata "Copy Item Parameters" = RIMD,
                  tabledata "Cost Accounting Setup" = R,
                  tabledata "Cost Element Buffer" = RIMD,
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata "Country/Region" = RIMD,
                  tabledata "Country/Region Translation" = RIMD,
                  tabledata "CRM Connection Setup" = R,
                  tabledata "CSV Buffer" = RIMD,
                  tabledata "Curr. Exch. Rate Update Setup" = R,
                  tabledata Currency = Rim,
                  tabledata "Currency Amount" = Rimd,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Currency Total Buffer" = Rimd,
                  tabledata "Custom Address Format" = RIMD,
                  tabledata "Custom Address Format Line" = RIMD,
                  tabledata "Custom Report Layout" = RIMD,
                  tabledata "Custom Report Selection" = RIMD,
                  tabledata Customer = Rim,
                  tabledata "Customer Amount" = RIMD,
                  tabledata "Customer Discount Group" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Customer Sales Buffer" = RIMD,
                  tabledata "Customer Templ." = R,
                  tabledata "Customized Calendar Change" = Rimd,
                  tabledata "CV Ledger Entry Buffer" = RIMD,
                  tabledata "Data Exch." = Rimd,
                  tabledata "Data Exch. Column Def" = RIMD,
                  tabledata "Data Exch. Def" = RIMD,
                  tabledata "Data Exch. Field" = RIMD,
                  tabledata "Data Exch. Field Mapping" = RIMD,
                  tabledata "Data Exch. Field Mapping Buf." = RIMD,
                  tabledata "Data Exch. Line Def" = RIMD,
                  tabledata "Data Exch. Mapping" = RIMD,
                  tabledata "Data Exch. Field Grouping" = RIMD,
                  tabledata "Data Exch. FlowField Gr. Buff." = RIMD,
                  tabledata "Data Exchange Type" = R,
                  tabledata "Data Exch. Table Filter" = Rimd,
                  tabledata "Data Privacy Records" = R,
                  tabledata "DataExch-RapidStart Buffer" = RIMD,
                  tabledata "Date Lookup Buffer" = RIMD,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Default Dimension Priority" = RIMD,
                  tabledata "Deferral Header" = RIMD,
                  tabledata "Deferral Header Archive" = Rimd,
                  tabledata "Deferral Line" = RIMD,
                  tabledata "Deferral Line Archive" = Rimd,
                  tabledata "Deferral Posting Buffer" = RIMD,
                  tabledata "Deferral Template" = RIMD,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Detailed CV Ledg. Entry Buffer" = RIMD,
                  tabledata "Detailed Employee Ledger Entry" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "Dim Correct Selection Criteria" = R,
                  tabledata "Dim Correction Blocked Setup" = R,
                  tabledata "Dim Correction Change" = R,
                  tabledata "Dim Correction Set Buffer" = R,
                  tabledata "Dim Correction Entry Log" = R,
                  tabledata "Dim. Value per Account" = RIMD,
                  tabledata Dimension = R,
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
                  tabledata "Dimension Value" = R,
                  tabledata "Dimension Value Combination" = RIMD,
                  tabledata "Dimensions Field Map" = RIMD,
                  tabledata "Dimensions Template" = RIMD,
                  tabledata "Doc. Exch. Service Setup" = R,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Document Entry" = RIMD,
                  tabledata "Document Search Result" = RIMD,
                  tabledata "Document Sending Profile" = RIMD,
#if not CLEAN23
                  tabledata "Document Service Cache" = Rimd,
#endif
                  tabledata "Drop Shpt. Post. Buffer" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = Rim,
                  tabledata "Duplicate Price Line" = Rim,
                  tabledata "Dynamic Request Page Entity" = R,
                  tabledata "Dynamic Request Page Field" = R,
                  tabledata "ECSL VAT Report Line" = RIMD,
                  tabledata "ECSL VAT Report Line Relation" = RIMD,
                  tabledata "Electronic Document Format" = RIMD,
                  tabledata "Email Item" = RIMD,
                  tabledata "Email Parameter" = RIMD,
                  tabledata "Employee Payment Buffer" = RIMD,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Employee Templ." = R,
                  tabledata "Employee Time Reg Buffer" = RIMD,
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
                  tabledata "Exchange Service Setup" = R,
                  tabledata "Exchange Sync" = RIMD,
                  tabledata "Experience Tier Buffer" = RIMD,
                  tabledata "Experience Tier Setup" = RIMD,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "Field Buffer" = RIMD,
                  tabledata "Field Monitoring Setup" = Rm,
                  tabledata "Filter Item Attributes Buffer" = RIMD,
                  tabledata "Finance Charge Terms" = R,
                  tabledata "Finance Cue" = RIMD,
                  tabledata "Flow Service Configuration" = r,
                  tabledata "Flow User Environment Buffer" = RIMD,
                  tabledata "Flow User Environment Config" = RIMD,
                  tabledata "G/L - Item Ledger Relation" = Rimd,
                  tabledata "G/L Acc. Balance Buffer" = RIMD,
                  tabledata "G/L Acc. Balance/Budget Buffer" = RIMD,
                  tabledata "G/L Acc. Budget Buffer" = RIMD,
                  tabledata "G/L Account" = r,
                  tabledata "G/L Account Category" = r,
                  tabledata "G/L Account Net Change" = RIMD,
                  tabledata "G/L Account Where-Used" = RIMD,
                  tabledata "G/L Account Source Currency" = r,
                  tabledata "G/L Entry" = r,
                  tabledata "Gen. Business Posting Group" = RIMD,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = Rim,
                  tabledata "Gen. Journal Template" = Rim,
                  tabledata "Gen. Product Posting Group" = RIMD,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Generic Chart Captions Buffer" = RIMD,
                  tabledata "Generic Chart Filter" = RIMD,
                  tabledata "Generic Chart Memo Buffer" = RIMD,
                  tabledata "Generic Chart Query Column" = RIMD,
                  tabledata "Generic Chart Setup" = RIMD,
                  tabledata "Generic Chart Y-Axis" = RIMD,
                  tabledata Geolocation = RIMD,
                  tabledata "Human Resources Setup" = R,
                  tabledata "IC Setup" = R,
                  tabledata "Image Analysis Setup" = RIMD,
                  tabledata "Image Analysis Scenario" = R,
                  tabledata "Import G/L Transaction" = RIMD,
                  tabledata "Incoming Document" = RIM,
                  tabledata "Incoming Document Approver" = R,
                  tabledata "Incoming Document Attachment" = RIMD,
                  tabledata "Incoming Documents Setup" = R,
                  tabledata "Interaction Merge Data" = RIMD,
                  tabledata "Interaction Template Setup" = RIMD,
#if not CLEAN22
                  tabledata "Advanced Intrastat Checklist" = RIMD,
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Line" = Rim,
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata "Intrastat Setup" = R,
#endif
                  tabledata "Invalidated Dim Correction" = R,
                  tabledata "Inventory Adjustment Buffer" = Rimd,
                  tabledata "Inventory Buffer" = Rimd,
                  tabledata "Inventory Event Buffer" = RIMD,
                  tabledata "Inventory Page Data" = R,
                  tabledata "Inventory Period" = R,
                  tabledata "Inventory Period Entry" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata "Inventory Setup" = R,
#if not CLEAN23
                  tabledata "Invoice Post. Buffer" = Rimd,
#endif
                  tabledata "Invoice Posting Buffer" = Rimd,
                  tabledata "Invoiced Booking Item" = RIMD,
                  tabledata "Invt. Post to G/L Test Buffer" = RIMD,
                  tabledata "Invt. Posting Buffer" = Rimd,
                  tabledata "Isolated Certificate" = R,
                  tabledata Item = Rim,
                  tabledata "Item Amount" = RIMD,
                  tabledata "Item Application Entry" = Rimd,
                  tabledata "Item Application Entry History" = Rimd,
                  tabledata "Item Attr. Value Translation" = RIMD,
                  tabledata "Item Attribute" = RIMD,
                  tabledata "Item Attribute Translation" = RIMD,
                  tabledata "Item Attribute Value" = RIMD,
                  tabledata "Item Attribute Value Mapping" = RIMD,
                  tabledata "Item Attribute Value Selection" = RIMD,
                  tabledata "Item Availability Buffer" = RIMD,
                  tabledata "Item Availability by Date" = R,
                  tabledata "Item Budget Buffer" = RIMD,
                  tabledata "Item Discount Group" = R,
                  tabledata "Item Journal Batch" = RIMD,
                  tabledata "Item Journal Buffer" = RIMD,
                  tabledata "Item Journal Line" = Rim,
                  tabledata "Item Journal Template" = RIMD,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Picture Buffer" = RIMD,
                  tabledata "Item Statistics Buffer" = RIMD,
                  tabledata "Item Substitution" = RIMD,
                  tabledata "Item Templ." = RIMD,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Translation" = Rim,
                  tabledata "Item Turnover Buffer" = RIMD,
                  tabledata "Item Unit of Measure" = RIMD,
                  tabledata "Item Variant" = RIMD,
                  tabledata "Item Vendor" = Rim,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Entry Buffer" = RIMD,
                  tabledata "Job Queue Log Entry" = Rimd,
                  tabledata "Jobs Setup" = R,
                  tabledata "Journal User Preferences" = RIMD,
                  tabledata "JSON Buffer" = RIMD,
                  tabledata "Last Used Chart" = RIMD,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "License Agreement" = RIM,
                  tabledata "Line Number Buffer" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata Location = R,
                  tabledata "Manufacturing Setup" = R,
                  tabledata "Marketing Setup" = R,
                  tabledata "Media Repository" = RIMD,
                  tabledata "Memoized Result" = R,
                  tabledata "MS-QBD Setup" = R,
                  tabledata "My Account" = RIMD,
                  tabledata "My Customer" = RIMD,
                  tabledata "My Item" = RIMD,
                  tabledata "My Notifications" = RIMD,
                  tabledata "My Time Sheets" = RIMD,
                  tabledata "My Vendor" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD,
                  tabledata "Named Forward Link" = RIMD,
                  tabledata "Notification Context" = RIMD,
                  tabledata "Notification Entry" = Rimd,
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
                  tabledata "OCR Service Setup" = R,
                  tabledata "OData Initialized Status" = RIMD,
                  tabledata "Office Add-in" = RIMD,
                  tabledata "Office Add-in Context" = RIMD,
                  tabledata "Office Add-in Setup" = R,
                  tabledata "Office Admin. Credentials" = Rimd,
                  tabledata "Office Contact Details" = RIMD,
                  tabledata "Office Document Selection" = RIMD,
                  tabledata "Office Invoice" = RIMD,
                  tabledata "Office Job Journal" = RIMD,
                  tabledata "Office Suggested Line Item" = RIMD,
                  tabledata "Online Bank Acc. Link" = RIMD,
                  tabledata "Online Map Parameter Setup" = Rimd,
                  tabledata "Online Map Setup" = Rimd,
                  tabledata "Option Lookup Buffer" = rimd,
                  tabledata "Order Address" = Rim,
                  tabledata "Over-Receipt Code" = RIMD,
                  tabledata "Overdue Approval Entry" = Rimd,
#if not CLEAN22
                  tabledata "Payment Buffer" = RIMD,
#endif
                  tabledata "Vendor Payment Buffer" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Export Remittance Text" = RIMD,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Method Translation" = RIMD,
                  tabledata "Payment Registration Buffer" = RIMD,
                  tabledata "Payment Registration Setup" = RIMD,
                  tabledata "Payment Reporting Argument" = Rimd,
                  tabledata "Payment Service Setup" = R,
                  tabledata "Payment Term Translation" = RIMD,
                  tabledata "Payment Terms" = R,
                  tabledata "Payroll Import Buffer" = RIMD,
                  tabledata "Payroll Setup" = RIMD,
                  tabledata "Phys. Inventory Ledger Entry" = Rim,
                  tabledata "Picture Entity" = RIMD,
                  tabledata "Planning Assignment" = R,
                  tabledata "Positive Pay Detail" = RIMD,
                  tabledata "Positive Pay Entry" = Rimd,
                  tabledata "Positive Pay Entry Detail" = Rimd,
                  tabledata "Positive Pay Footer" = RIMD,
                  tabledata "Positive Pay Header" = RIMD,
                  tabledata "Post Code" = Ri,
                  tabledata "Post Value Entry to G/L" = R,
                  tabledata "Postcode Service Config" = R,
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
                  tabledata "Price Asset" = Rim,
                  tabledata "Price Calculation Buffer" = Rim,
                  tabledata "Price Calculation Setup" = Rim,
                  tabledata "Price Line Filters" = Rim,
                  tabledata "Price List Header" = Rim,
                  tabledata "Price List Line" = Rim,
                  tabledata "Price Source" = Rim,
                  tabledata "Price Worksheet Line" = Rim,
                  tabledata "Printer Selection" = RIMD,
                  tabledata "Purch. Comment Line" = RIMD,
                  tabledata "Purch. Comment Line Archive" = RIMD,
                  tabledata "Purch. Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Purch. Inv. Entity Aggregate" = RIMD,
                  tabledata "Purch. Inv. Line Aggregate" = RIMD,
#if not CLEAN23
                  tabledata "Purch. Price Line Disc. Buff." = RIMD,
#endif
                  tabledata "Purchase Cue" = RIMD,
                  tabledata "Purchase Discount Access" = Rim,
                  tabledata "Purchase Header" = Rim,
                  tabledata "Purchase Line" = Rim,
#if not CLEAN23
                  tabledata "Purchase Line Discount" = Rim,
#endif
                  tabledata "Purchase Order Entity Buffer" = RIMD,
                  tabledata "Purchase Prepayment %" = Rim,
#if not CLEAN23
                  tabledata "Purchase Price" = Rim,
#endif
                  tabledata "Purchase Price Access" = Rim,
                  tabledata "Purchases & Payables Setup" = Rm,
                  tabledata "Query Metadata" = imd,
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
                  tabledata "Relationship Mgmt. Cue" = RIMD,
                  tabledata "Reminder Attachment Text" = R,
                  tabledata "Reminder Email Text" = R,
                  tabledata "Reminder Terms" = R,
                  tabledata "Reminder Terms Translation" = RIMD,
                  tabledata "Reminder Action Group" = R,
                  tabledata "Reminder Action" = R,
                  tabledata "Create Reminders Setup" = R,
                  tabledata "Issue Reminders Setup" = R,
                  tabledata "Send Reminders Setup" = R,
                  tabledata "Reminder Automation Error" = R,
                  tabledata "Reminder Action Group Log" = R,
                  tabledata "Reminder Action Log" = R,
                  tabledata "Remit Address" = Rim,
                  tabledata "Report Inbox" = RIMD,
                  tabledata "Report Layout Selection" = RIMD,
                  tabledata "Report Layout Update Log" = RIMD,
                  tabledata "Report List Translation" = RIMD,
                  tabledata "Report Selection Warehouse" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Report Totals Buffer" = RIMD,
                  tabledata "Req. Wksh. Template" = R,
                  tabledata "Requisition Line" = Rim,
                  tabledata "Requisition Wksh. Name" = R,
                  tabledata "Res. Availability Buffer" = RIMD,
                  tabledata "Res. Gr. Availability Buffer" = RIMD,
                  tabledata "Res. Journal Batch" = RIMD,
                  tabledata "Res. Journal Template" = RIMD,
                  tabledata "Res. Ledger Entry" = Ri,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata "Reservation Entry Buffer" = RIMD,
                  tabledata Resource = Rimd,
                  tabledata "Resource Group" = R,
                  tabledata "Resource Register" = Rim,
                  tabledata "Resource Skill" = Rim,
                  tabledata "Resources Setup" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Restricted Record" = Rimd,
                  tabledata "Reversal Entry" = RIMD,
                  tabledata "Role Center Notifications" = RIMD,
                  tabledata "Rounding Method" = R,
                  tabledata "Rounding Residual Buffer" = Rimd,
                  tabledata "Sales & Receivables Setup" = Rm,
                  tabledata "Sales by Cust. Grp.Chart Setup" = RIMD,
                  tabledata "Sales Comment Line" = RIMD,
                  tabledata "Sales Comment Line Archive" = RIMD,
                  tabledata "Sales Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Sales Cue" = RIMD,
                  tabledata "Sales Discount Access" = Rim,
                  tabledata "Sales Document Icon" = Rimd,
                  tabledata "Sales Header" = Rim,
                  tabledata "Sales Invoice Entity Aggregate" = RIMD,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Invoice Line Aggregate" = RIMD,
                  tabledata "Sales Line" = Rim,
#if not CLEAN23
                  tabledata "Sales Line Discount" = Rim,
#endif
                  tabledata "Sales Order Entity Buffer" = RIMD,
                  tabledata "Sales Prepayment %" = Rim,
#if not CLEAN23
                  tabledata "Sales Price" = Rim,
#endif
                  tabledata "Sales Price Access" = Rim,
#if not CLEAN23
                  tabledata "Sales Price and Line Disc Buff" = RIMD,
#endif
                  tabledata "Sales Quote Entity Buffer" = RIMD,
                  tabledata "Sales Shipment Buffer" = RIMD,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "SB Owner Cue" = RIMD,
                  tabledata "Segment Line" = R,
                  tabledata "Selected Dimension" = RIMD,
                  tabledata "Semi-Manual Execution Log" = RIMD,
                  tabledata "Semi-Manual Test Wizard" = RIMD,
                  tabledata "Sent Notification Entry" = Rimd,
                  tabledata "SEPA Direct Debit Mandate" = RIMD,
                  tabledata "Service Connection" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Ship-to Address" = Rim,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipment Method Translation" = RIMD,
                  tabledata "Shipping Agent" = R,
                  tabledata "Sorting Table" = RIMD,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Address" = Rimd,
                  tabledata "Standard Customer Sales Code" = R,
                  tabledata "Standard General Journal" = RIMD,
                  tabledata "Standard General Journal Line" = Rimd,
                  tabledata "Standard Item Journal" = Rim,
                  tabledata "Standard Item Journal Line" = Rimd,
                  tabledata "Standard Purchase Code" = R,
                  tabledata "Standard Purchase Line" = R,
                  tabledata "Standard Sales Code" = R,
                  tabledata "Standard Sales Line" = R,
                  tabledata "Standard Text" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = R,
                  tabledata "Support Contact Information" = R,
                  tabledata "Table Filter" = RIMD,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Buffer" = RIMD,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Area Translation" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Group Buffer" = RIMD,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Tax Jurisdiction Translation" = R,
                  tabledata "Tax Rate Buffer" = RIMD,
                  tabledata "Tax Setup" = RIMD,
                  tabledata "Team Member Cue" = RIMD,
                  tabledata TempStack = RIMD,
                  tabledata "Tenant Config. Package File" = R,
                  tabledata "Terms And Conditions" = RIM,
                  tabledata "Terms And Conditions State" = RIM,
                  tabledata Territory = R,
                  tabledata "Text-to-Account Mapping" = RIMD,
                  tabledata "Time Series Buffer" = RIMD,
                  tabledata "Time Series Forecast" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = RM,
                  tabledata "Time Sheet Detail Archive" = RM,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Header Archive" = Rm,
                  tabledata "Time Sheet Line" = Rm,
                  tabledata "Time Sheet Line Archive" = Rm,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Top Customers By Sales Buffer" = RIMD,
                  tabledata "Tracking Specification" = R,
                  tabledata "Trailing Sales Orders Setup" = RIMD,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transformation Rule" = RIMD,
                  tabledata "Trial Balance Cache" = RIMD,
                  tabledata "Trial Balance Cache Info" = RIMD,
                  tabledata "Trial Balance Entity Buffer" = RIMD,
                  tabledata "Trial Balance Setup" = RIMD,
                  tabledata "Unit Group" = RIMD,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "Unlinked Attachment" = RIMD,
#if not CLEAN22
                  tabledata "User Group" = R,
                  tabledata "User Group Access Control" = R,
                  tabledata "User Group Member" = R,
                  tabledata "User Group Permission Set" = R,
#endif
                  tabledata "User Preference" = RIMD,
                  tabledata "User Setup" = R,
                  tabledata "User Task" = RIMD,
                  tabledata "User Task Group" = R,
                  tabledata "User Task Group Member" = R,
                  tabledata "User Time Register" = Rimd,
                  tabledata "User Tours" = RIMD,
                  tabledata "Value Entry" = Rim,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Clause" = R,
                  tabledata "VAT Clause by Doc. Type" = R,
                  tabledata "VAT Clause by Doc. Type Trans." = R,
                  tabledata "VAT Clause Translation" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Registration Log" = RIMD,
                  tabledata "VAT Report Archive" = Rimd,
                  tabledata "VAT Reports Configuration" = RIMD,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Statement Line" = R,
                  tabledata "VAT Statement Name" = R,
                  tabledata "VAT Statement Report Line" = RIMD,
                  tabledata "VAT Statement Template" = R,
                  tabledata "VAT Setup" = RIMD,
                  tabledata Vendor = Rim,
                  tabledata "Vendor Amount" = RIMD,
                  tabledata "Vendor Posting Group" = R,
                  tabledata "Vendor Purchase Buffer" = RIMD,
                  tabledata "Vendor Templ." = RIMD,
                  tabledata "Warehouse Class" = R,
                  tabledata "Warehouse Setup" = R,
                  tabledata "WF Event/Response Combination" = RIMD,
                  tabledata "Workflow - Record Change" = Rimd,
                  tabledata "Workflow - Table Relation" = R,
                  tabledata Workflow = R,
                  tabledata "Workflow Buffer" = RIMD,
                  tabledata "Workflow Category" = RIMD,
                  tabledata "Workflow Event" = RiMD,
                  tabledata "Workflow Event Queue" = Rimd,
                  tabledata "Workflow Record Change Archive" = Rimd,
                  tabledata "Workflow Response" = R,
                  tabledata "Workflow Rule" = Rimd,
                  tabledata "Workflow Step" = R,
                  tabledata "Workflow Step Argument" = Rimd,
                  tabledata "Workflow Step Argument Archive" = Rimd,
                  tabledata "Workflow Step Buffer" = RIMD,
                  tabledata "Workflow Step Instance" = Rimd,
                  tabledata "Workflow Step Instance Archive" = Rimd,
                  tabledata "Workflow Table Relation Value" = Rimd,
                  tabledata "Workflow User Group" = R,
                  tabledata "Workflow User Group Member" = R,
                  tabledata "Workflow Webhook Entry" = Rimd,
                  tabledata "Workflow Webhook Notification" = Rimd,
                  tabledata "Workflows Entries Buffer" = Rimd,
                  tabledata "XML Buffer" = RIMD,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
