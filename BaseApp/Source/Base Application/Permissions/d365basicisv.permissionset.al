namespace System.Security.AccessControl;

using Microsoft.AccountantPortal;
using Microsoft.Booking;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Team;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Projects.Project.Job;
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
using Microsoft.Finance.VAT.Ledger;
using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.Payroll;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Projects.Project.Journal;
#if not CLEAN21
using Microsoft.Projects.Project.Pricing;
#endif
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Project.Setup;
using System.Globalization;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Assembly.Setup;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.CRM.BusinessRelation;
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
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.RoleCenters;
using Microsoft.Finance.SalesTax;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Integration.SyncEngine;
using Microsoft.Integration.PowerBI;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
#if not CLEAN21
using Microsoft.Projects.Resources.Pricing;
#endif
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.RoleCenters;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Analysis;
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
using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Warehouse.Setup;
using System.AI;
using System.Apps;
using System.Automation;
using System.Azure.Identity;
using System.DateTime;
using System.Device;
using System.Diagnostics;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Integration.PowerBI;
using System.Integration;
using System.IO;
using System.Privacy;
using System.Reflection;
using System.Security.User;
using System.TestTools;
using System.Text;
using System.Threading;
using System.Utilities;
using System.Visualization;
using System.Xml;
using System.Upgrade;
using Microsoft.Foundation.Period;
using Microsoft.RoleCenters;
using Microsoft.Utilities;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.HumanResources.Absence;
using Microsoft.API.Upgrade;
using Microsoft.API;
using Microsoft;

permissionset 732 "D365 BASIC ISV"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dyn. 365 Basic ISV Acc.';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "System App - Basic",
                             "Company - Edit",
                             LOGIN;

    Permissions = system "Tools, Security, Roles" = X,
                  tabledata AllObjWithCaption = R,
                  tabledata Chart = imd,
                  tabledata "Data Sensitivity" = IMD,
                  tabledata Key = Rimd,
                  tabledata "NAV App Installed App" = Rimd,
                  tabledata "Object Options" = IMD,
                  tabledata Permission = imd,
                  tabledata "Permission Set" = imd,
                  tabledata "Tenant Web Service" = R,
                  tabledata "Upgrade Blob Storage" = Rimd,
                  tabledata User = RMD,
                  tabledata "Acc. Sched. Cell Value" = RIMD,
                  tabledata "Acc. Sched. Chart Setup Line" = RIMD,
                  tabledata "Acc. Sched. KPI Buffer" = RIMD,
                  tabledata "Acc. Sched. KPI Web Srv. Line" = RIMD,
                  tabledata "Acc. Sched. KPI Web Srv. Setup" = RIMD,
                  tabledata "Acc. Schedule Line" = RIMD,
                  tabledata "Acc. Schedule Line Entity" = RIMD,
                  tabledata "Acc. Schedule Name" = RIMD,
                  tabledata "Financial Report" = RIMD,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Account Schedules Chart Setup" = RIMD,
                  tabledata "Account Use Buffer" = RIMD,
                  tabledata "Accounting Period" = RIMD,
                  tabledata "Accounting Services Cue" = RIMD,
                  tabledata "Action Message Entry" = RIMD,
                  tabledata "Activities Cue" = RIMD,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Additional Fee Setup" = RIMD,
                  tabledata "Adjust Exchange Rate Buffer" = RIMD,
                  tabledata "Administration Cue" = RIMD,
                  tabledata "Aged Report Entity" = RIMD,
                  tabledata "Aging Band Buffer" = RIMD,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Alt. Customer Posting Group" = RIMD,
                  tabledata "Alt. Vendor Posting Group" = RIMD,
                  tabledata "Analysis by Dim. Parameters" = RIMD,
                  tabledata "Analysis by Dim. User Param." = RIMD,
                  tabledata "Analysis Report Chart Setup" = R,
                  tabledata "API Data Upgrade" = RIMD,
                  tabledata "API Entities Setup" = RIMD,
                  tabledata "API Extension Upload" = rimd,
                  tabledata "Application Area Buffer" = RIMD,
                  tabledata "Application Area Setup" = RIMD,
                  tabledata "Applied Payment Entry" = RIMD,
                  tabledata "Approval Comment Line" = RIMD,
                  tabledata "Approval Entry" = Rimd,
                  tabledata "Approval Workflow Wizard" = RIMD,
                  tabledata Area = RIMD,
                  tabledata "Assembly Setup" = Ri,
                  tabledata "Assisted Company Setup Status" = RIMD,
                  tabledata "Attachment Entity Buffer" = RIMD,
                  tabledata "Autocomplete Address" = RIMD,
                  tabledata "Availability at Date" = RIMD,
                  tabledata "Availability Calc. Overview" = RIMD,
                  tabledata "Average Cost Calc. Overview" = RIMD,
                  tabledata "Avg. Cost Adjmt. Entry Point" = RIMD,
                  tabledata "Azure AD App Setup" = RIMD,
                  tabledata "Azure AD Mgt. Setup" = RIMD,
                  tabledata "Azure AI Usage" = Rimd,
                  tabledata "Balance Sheet Buffer" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = RIMD,
                  tabledata "Bank Acc. Reconciliation Line" = RIMD,
                  tabledata "Bank Acc. Rec. Match Buffer" = RIMD,
                  tabledata "Bank Account" = RIMD,
                  tabledata "Bank Account Balance Buffer" = RIMD,
                  tabledata "Bank Account Ledger Entry" = Rimd,
                  tabledata "Bank Account Posting Group" = RIMD,
                  tabledata "Bank Account Statement" = RimD,
                  tabledata "Bank Account Statement Line" = Rimd,
                  tabledata "Bank Clearing Standard" = RIMD,
                  tabledata "Bank Export/Import Setup" = RIMD,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Statement Matching Buffer" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIMD,
                  tabledata "Bar Chart Buffer" = RIMD,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "BOM Buffer" = RIMD,
                  tabledata "BOM Component" = RIMD,
                  tabledata "BOM Warning Log" = RIMD,
                  tabledata "Booking Item" = RIMD,
                  tabledata "Booking Mailbox" = RIMD,
                  tabledata "Booking Mgr. Setup" = RIMD,
                  tabledata "Booking Service" = RIMD,
                  tabledata "Booking Service Mapping" = RIMD,
                  tabledata "Booking Staff" = RIMD,
                  tabledata "Booking Sync" = RIMD,
                  tabledata "Budget Buffer" = RIMD,
                  tabledata "Bus. Unit In Cons. Process" = RIMD,
                  tabledata "Business Chart Buffer" = RIMD,
                  tabledata "Business Chart Map" = RIMD,
                  tabledata "Business Chart User Setup" = RIMD,
                  tabledata "Business Relation" = RIMD,
                  tabledata "Business Unit" = RIMD,
                  tabledata "Business Unit Information" = RIMD,
                  tabledata "Business Unit Setup" = RIMD,
                  tabledata "Calendar Event" = Rimd,
                  tabledata "Calendar Event User Config." = Rimd,
                  tabledata "Cancelled Document" = Rimd,
                  tabledata "Cash Flow Account" = RIMD,
                  tabledata "Cash Flow Account Comment" = RIMD,
                  tabledata "Cash Flow Availability Buffer" = RIMD,
                  tabledata "Cash Flow Azure AI Buffer" = Rimd,
                  tabledata "Cash Flow Chart Setup" = RIMD,
                  tabledata "Cash Flow Forecast" = RIMD,
                  tabledata "Cash Flow Forecast Entry" = RIMD,
                  tabledata "Cash Flow Manual Expense" = RIMD,
                  tabledata "Cash Flow Manual Revenue" = RIMD,
                  tabledata "Cash Flow Report Selection" = RIMD,
                  tabledata "Cash Flow Setup" = RIMD,
                  tabledata "Cash Flow Worksheet Line" = RIMD,
                  tabledata "Cause of Absence" = RIMD,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "Change Global Dim. Log Entry" = RIMD,
                  tabledata "Change Log Entry" = Rimd,
                  tabledata "Change Log Setup (Field)" = RIMD,
                  tabledata "Change Log Setup (Table)" = RIMD,
                  tabledata "Change Log Setup" = RIMD,
                  tabledata "Chart Definition" = RIMD,
                  tabledata "Check Ledger Entry" = RIMD,
                  tabledata "Close Income Statement Buffer" = RIMD,
                  tabledata "Column Layout" = RIMD,
                  tabledata "Column Layout Name" = RIMD,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Communication Method" = RIMD,
                  tabledata "Company Information" = RIMD,
                  tabledata "Company Size" = RIMD,
                  tabledata "Confidential Information" = RIMD,
                  tabledata "Config. Field Map" = RIMD,
                  tabledata "Config. Line" = RIMD,
                  tabledata "Config. Media Buffer" = RIMD,
                  tabledata "Config. Package" = RIMD,
                  tabledata "Config. Package Data" = RIMD,
                  tabledata "Config. Package Error" = RIMD,
                  tabledata "Config. Package Field" = RIMD,
                  tabledata "Config. Package Filter" = RIMD,
                  tabledata "Config. Package Record" = RIMD,
                  tabledata "Config. Package Table" = RIMD,
                  tabledata "Config. Question" = RIMD,
                  tabledata "Config. Question Area" = RIMD,
                  tabledata "Config. Questionnaire" = RIMD,
                  tabledata "Config. Record For Processing" = RIMD,
                  tabledata "Config. Related Field" = RIMD,
                  tabledata "Config. Related Table" = RIMD,
                  tabledata "Config. Selection" = RIMD,
                  tabledata "Config. Setup" = RIMD,
                  tabledata "Config. Table Processing Rule" = RIMD,
                  tabledata "Config. Template Header" = RIMD,
                  tabledata "Config. Template Line" = RIMD,
                  tabledata "Config. Tmpl. Selection Rules" = RIMD,
                  tabledata "Consolidation Account" = RIMD,
                  tabledata "Consolidation Process" = RIMD,
                  tabledata "Consolidation Setup" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIMD,
                  tabledata "Contact Alt. Addr. Date Range" = RIMD,
                  tabledata "Contact Alt. Address" = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "Contact Duplicate" = RIMD,
                  tabledata "Contact Industry Group" = RIMD,
                  tabledata "Contact Job Responsibility" = RIMD,
                  tabledata "Contact Mailing Group" = RIMD,
                  tabledata "Contact Profile Answer" = RIMD,
                  tabledata "Contact Value" = RIMD,
                  tabledata "Contact Web Source" = RIMD,
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIMD,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Copy Item Buffer" = RIMD,
                  tabledata "Copy Item Parameters" = RIMD,
                  tabledata "Cost Accounting Setup" = Ri,
                  tabledata "Cost Element Buffer" = RIMD,
                  tabledata "Cost Share Buffer" = RIMD,
                  tabledata "Country/Region" = RIMD,
                  tabledata "Country/Region Translation" = RIMD,
#if not CLEAN22
                  tabledata "Coupling Field Buffer" = RIMD,
#endif
                  tabledata "Coupling Record Buffer" = RIMD,
                  tabledata "Credit Trans Re-export History" = RIMD,
                  tabledata "Credit Transfer Entry" = RIMD,
                  tabledata "Credit Transfer Register" = RIMD,
                  tabledata "CRM Connection Setup" = R,
                  tabledata "CSV Buffer" = RIMD,
                  tabledata "Curr. Exch. Rate Update Setup" = RIMD,
                  tabledata Currency = RIMD,
                  tabledata "Currency Amount" = RIMD,
                  tabledata "Currency Exchange Rate" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Currency for Reminder Level" = RIMD,
                  tabledata "Currency Total Buffer" = RIMD,
                  tabledata "Current Salesperson" = RIMD,
                  tabledata "Cust. Invoice Disc." = RIMD,
                  tabledata "Cust. Ledger Entry" = RiMd,
                  tabledata "Custom Address Format" = RIMD,
                  tabledata "Custom Address Format Line" = RIMD,
                  tabledata "Custom Report Layout" = RIMD,
                  tabledata "Custom Report Selection" = RIMD,
                  tabledata Customer = RIMD,
                  tabledata "Customer Amount" = RIMD,
                  tabledata "Customer Bank Account" = RIMD,
                  tabledata "Customer Discount Group" = RIMD,
                  tabledata "Customer Posting Group" = RIMD,
                  tabledata "Customer Price Group" = RIMD,
                  tabledata "Customer Sales Buffer" = RIMD,
                  tabledata "Customer Templ." = RIMD,
                  tabledata "CV Ledger Entry Buffer" = RIMD,
                  tabledata "Data Exch." = RIMD,
                  tabledata "Data Exch. Column Def" = RIMD,
                  tabledata "Data Exch. Def" = RIMD,
                  tabledata "Data Exch. Field" = RIMD,
                  tabledata "Data Exch. Field Mapping" = RIMD,
                  tabledata "Data Exch. Field Mapping Buf." = RIMD,
                  tabledata "Data Exch. Line Def" = RIMD,
                  tabledata "Data Exch. Mapping" = RIMD,
                  tabledata "Data Exch. Field Grouping" = RIMD,
                  tabledata "Data Exch. FlowField Gr. Buff." = RIMD,
                  tabledata "Data Exchange Type" = RIMD,
                  tabledata "Data Exch. Table Filter" = RIMD,
                  tabledata "Data Migration Entity" = RIMD,
                  tabledata "Data Migration Error" = RIMD,
                  tabledata "Data Migration Parameters" = RIMD,
                  tabledata "Data Migration Setup" = RIMD,
                  tabledata "Data Migration Status" = RIMD,
                  tabledata "Data Migrator Registration" = RIMD,
                  tabledata "Data Privacy Records" = RIMD,
                  tabledata "DataExch-RapidStart Buffer" = RIMD,
                  tabledata "Date Compr. Register" = Rimd,
                  tabledata "Date Lookup Buffer" = RIMD,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Default Dimension Priority" = RIMD,
                  tabledata "Deferral Header" = RIMD,
                  tabledata "Deferral Header Archive" = RIMD,
                  tabledata "Deferral Line" = RIMD,
                  tabledata "Deferral Line Archive" = RIMD,
                  tabledata "Deferral Posting Buffer" = RIMD,
                  tabledata "Deferral Template" = RIMD,
                  tabledata "Deposits Page Setup" = RIMD,
                  tabledata "Depreciation Book" = RIMD,
                  tabledata "Depreciation Table Buffer" = RIMD,
                  tabledata "Depreciation Table Header" = RIMD,
                  tabledata "Depreciation Table Line" = RIMD,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "Detailed CV Ledg. Entry Buffer" = RIMD,
                  tabledata "Detailed Employee Ledger Entry" = Rimd,
                  tabledata "Detailed Vendor Ledg. Entry" = Rimd,
                  tabledata "Dim. Value per Account" = RIMD,
                  tabledata Dimension = RIMD,
                  tabledata "Dimension Buffer" = RIMD,
                  tabledata "Dimension Code Amount Buffer" = RIMD,
                  tabledata "Dimension Code Buffer" = RIMD,
                  tabledata "Dimension Combination" = RIMD,
                  tabledata "Dimension Entry Buffer" = RIMD,
                  tabledata "Dimension ID Buffer" = RIMD,
                  tabledata "Dimension Selection Buffer" = RIMD,
                  tabledata "Dimension Set Entry" = Rimd,
                  tabledata "Dimension Set Entry Buffer" = RIMD,
                  tabledata "Dimension Set ID Filter Line" = RIMD,
                  tabledata "Dimension Set Tree Node" = Rimd,
                  tabledata "Dimension Translation" = RIMD,
                  tabledata "Dimension Value" = RIMD,
                  tabledata "Dimension Value Combination" = RIMD,
                  tabledata "Dimensions Field Map" = RIMD,
                  tabledata "Dimensions Template" = RIMD,
                  tabledata "Direct Debit Collection" = RIMD,
                  tabledata "Direct Debit Collection Entry" = RIMD,
                  tabledata "Doc. Exch. Service Setup" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Document Entry" = RIMD,
                  tabledata "Document Search Result" = RIMD,
                  tabledata "Document Sending Profile" = RIMD,
                  tabledata "Duplicate Search String Setup" = RIMD,
                  tabledata "Dynamic Request Page Entity" = RIMD,
                  tabledata "Dynamic Request Page Field" = RIMD,
                  tabledata "ECSL VAT Report Line" = RIMD,
                  tabledata "ECSL VAT Report Line Relation" = RIMD,
                  tabledata "Electronic Document Format" = RIMD,
                  tabledata "Email Item" = RIMD,
                  tabledata "Email Parameter" = RIMD,
                  tabledata Employee = RIMD,
                  tabledata "Employee Absence" = RIMD,
                  tabledata "Employee Ledger Entry" = Rimd,
                  tabledata "Employee Payment Buffer" = RIMD,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Employee Qualification" = RIMD,
                  tabledata "Employee Relative" = RIMD,
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
                  tabledata "Exch. Rate Adjmt. Reg." = Rimd,
                  tabledata "Exch. Rate Adjmt. Ledg. Entry" = Rimd,
                  tabledata "Exchange Contact" = RIMD,
                  tabledata "Exchange Folder" = RIMD,
                  tabledata "Exchange Object" = RIMD,
                  tabledata "Exchange Service Setup" = RIMD,
                  tabledata "Exchange Sync" = RIMD,
                  tabledata "Experience Tier Buffer" = RIMD,
                  tabledata "Experience Tier Setup" = RIMD,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "FA Allocation" = RIMD,
                  tabledata "FA Buffer Projection" = RIMD,
                  tabledata "FA Class" = RIMD,
                  tabledata "FA Date Type" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
                  tabledata "FA G/L Posting Buffer" = RIMD,
                  tabledata "FA Journal Batch" = RIMD,
                  tabledata "FA Journal Line" = RIMD,
                  tabledata "FA Journal Setup" = RIMD,
                  tabledata "FA Journal Template" = RIMD,
                  tabledata "FA Ledger Entry" = Rimd,
                  tabledata "FA Location" = RIMD,
                  tabledata "FA Matrix Posting Type" = RIMD,
                  tabledata "FA Posting Group" = RIMD,
                  tabledata "FA Posting Group Buffer" = RIMD,
                  tabledata "FA Posting Type" = RIMD,
                  tabledata "FA Posting Type Setup" = RIMD,
                  tabledata "FA Reclass. Journal Batch" = RIMD,
                  tabledata "FA Reclass. Journal Line" = RIMD,
                  tabledata "FA Reclass. Journal Template" = RIMD,
                  tabledata "FA Register" = Rimd,
                  tabledata "FA Setup" = RIMD,
                  tabledata "FA Subclass" = RIMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Field Buffer" = RIMD,
                  tabledata "Filed Contract Line" = RIMD,
                  tabledata "Filter Item Attributes Buffer" = RIMD,
                  tabledata "Fin. Charge Comment Line" = RIMD,
                  tabledata "Finance Charge Interest Rate" = RIMD,
                  tabledata "Finance Charge Memo Header" = RIMD,
                  tabledata "Finance Charge Memo Line" = RIMD,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "Finance Charge Text" = RIMD,
                  tabledata "Finance Cue" = RIMD,
                  tabledata "Fixed Asset" = RIMD,
                  tabledata "Flow Service Configuration" = Rimd,
                  tabledata "Flow User Environment Buffer" = RIMD,
                  tabledata "Flow User Environment Config" = RIMD,
                  tabledata "G/L - Item Ledger Relation" = RIMD,
                  tabledata "G/L Acc. Balance Buffer" = RIMD,
                  tabledata "G/L Acc. Balance/Budget Buffer" = RIMD,
                  tabledata "G/L Acc. Budget Buffer" = RIMD,
                  tabledata "G/L Account (Analysis View)" = RIMD,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L Account Category" = RIMD,
                  tabledata "G/L Account Net Change" = RIMD,
                  tabledata "G/L Account Where-Used" = RIMD,
                  tabledata "G/L Budget Entry" = RIMD,
                  tabledata "G/L Budget Name" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = Rimd,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Business Posting Group" = RIMD,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Gen. Product Posting Group" = RIMD,
                  tabledata "General Ledger Setup" = RIMD,
                  tabledata "General Posting Setup" = RIMD,
                  tabledata "Generic Chart Captions Buffer" = RIMD,
                  tabledata "Generic Chart Filter" = RIMD,
                  tabledata "Generic Chart Memo Buffer" = RIMD,
                  tabledata "Generic Chart Query Column" = RIMD,
                  tabledata "Generic Chart Setup" = RIMD,
                  tabledata "Generic Chart Y-Axis" = RIMD,
                  tabledata Geolocation = RIMD,
#if not CLEAN21
                  tabledata "Graph Mail Setup" = RIMD,
#endif
                  tabledata "Human Resource Comment Line" = RIMD,
                  tabledata "Human Resource Unit of Measure" = RIMD,
                  tabledata "Human Resources Setup" = RIMD,
                  tabledata "Hybrid Deployment Setup" = Rimd,
                  tabledata "IC Setup" = RIMD,
                  tabledata "Image Analysis Setup" = RIMD,
                  tabledata "Image Analysis Scenario" = R,
                  tabledata "Import G/L Transaction" = RIMD,
                  tabledata "Inc. Doc. Attachment Overview" = RIMD,
                  tabledata "Incoming Document" = RIMD,
                  tabledata "Incoming Document Approver" = RIMD,
                  tabledata "Incoming Document Attachment" = RIMD,
                  tabledata "Incoming Documents Setup" = RIMD,
                  tabledata "Industry Group" = RIMD,
                  tabledata "Ins. Coverage Ledger Entry" = Rimd,
                  tabledata Insurance = RIMD,
                  tabledata "Insurance Journal Batch" = RIMD,
                  tabledata "Insurance Journal Line" = RIMD,
                  tabledata "Insurance Journal Template" = RIMD,
                  tabledata "Insurance Register" = Rimd,
                  tabledata "Insurance Type" = RIMD,
                  tabledata Integer = RIMD,
                  tabledata "Integration Field Mapping" = RIMD,
                  tabledata "Integration Synch. Job" = RIMD,
                  tabledata "Integration Synch. Job Errors" = RIMD,
                  tabledata "Integration Table Mapping" = RIMD,
                  tabledata "Interaction Log Entry" = r,
                  tabledata "Interaction Merge Data" = RIMD,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Template Setup" = i,
                  tabledata "Interaction Tmpl. Language" = RIMD,
                  tabledata "Intermediate Data Import" = RIMD,
#if not CLEAN22
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Line" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata "Intrastat Setup" = RIMD,
#endif
                  tabledata "Inventory Adjmt. Entry (Order)" = Rimd,
                  tabledata "Inventory Adjustment Buffer" = Rimd,
                  tabledata "Inventory Buffer" = RIMD,
                  tabledata "Inventory Comment Line" = RIMD,
                  tabledata "Inventory Event Buffer" = RIMD,
                  tabledata "Inventory Page Data" = RIMD,
                  tabledata "Inventory Period" = RIMD,
                  tabledata "Inventory Period Entry" = RIMD,
                  tabledata "Inventory Posting Group" = RIMD,
                  tabledata "Inventory Posting Setup" = RIMD,
                  tabledata "Inventory Profile Track Buffer" = RIMD,
                  tabledata "Inventory Report Entry" = RIMD,
                  tabledata "Inventory Report Header" = RIMD,
                  tabledata "Inventory Setup" = RIMD,
#if not CLEAN23
                  tabledata "Invoice Post. Buffer" = RIMD,
#endif
                  tabledata "Invoice Posting Buffer" = RIMD,
                  tabledata "Invoiced Booking Item" = RIMD,
                  tabledata "Invt. Post to G/L Test Buffer" = RIMD,
                  tabledata "Invt. Posting Buffer" = RIMD,
                  tabledata "Issued Fin. Charge Memo Header" = RimD,
                  tabledata "Issued Fin. Charge Memo Line" = Rimd,
                  tabledata "Issued Reminder Header" = RimD,
                  tabledata "Issued Reminder Line" = Rimd,
                  tabledata Item = RIMD,
                  tabledata "Item Amount" = RIMD,
                  tabledata "Item Analysis View" = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = RIMD,
                  tabledata "Item Analysis View Entry" = RIMD,
                  tabledata "Item Analysis View Filter" = RIMD,
                  tabledata "Item Application Entry" = RImd,
                  tabledata "Item Application Entry History" = RIMD,
                  tabledata "Item Attr. Value Translation" = RIMD,
                  tabledata "Item Attribute" = RIMD,
                  tabledata "Item Attribute Translation" = RIMD,
                  tabledata "Item Attribute Value" = RIMD,
                  tabledata "Item Attribute Value Mapping" = RIMD,
                  tabledata "Item Attribute Value Selection" = RIMD,
                  tabledata "Item Availability Buffer" = RIMD,
                  tabledata "Item Availability by Date" = RIMD,
                  tabledata "Item Availability Line" = RIMD,
                  tabledata "Item Category" = RIMD,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Entry Relation" = RIMD,
                  tabledata "Item Journal Batch" = RIMD,
                  tabledata "Item Journal Buffer" = RIMD,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Journal Template" = RIMD,
                  tabledata "Item Ledger Entry" = Rimd,
                  tabledata "Item Register" = Rimd,
                  tabledata "Item Statistics Buffer" = RIMD,
                  tabledata "Item Substitution" = RIMD,
                  tabledata "Item Templ." = RIMD,
                  tabledata "Item Translation" = RIMD,
                  tabledata "Item Turnover Buffer" = RIMD,
                  tabledata "Item Unit of Measure" = RIMD,
                  tabledata "Item Variant" = RIMD,
                  tabledata Job = RIMD,
                  tabledata "Job Cue" = RIMD,
                  tabledata "Job Entry No." = RIMD,
#if not CLEAN21
                  tabledata "Job G/L Account Price" = RIMD,
                  tabledata "Job Item Price" = RIMD,
#endif
                  tabledata "Job Journal Batch" = RIMD,
                  tabledata "Job Journal Line" = RIMD,
                  tabledata "Job Journal Quantity" = RIMD,
                  tabledata "Job Journal Template" = RIMD,
                  tabledata "Job Ledger Entry" = Rimd,
                  tabledata "Job Planning Line - Calendar" = RIMD,
                  tabledata "Job Planning Line" = RIMD,
                  tabledata "Job Planning Line Invoice" = RIMD,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata "Job Posting Group" = RIMD,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Entry Buffer" = RIMD,
                  tabledata "Job Queue Log Entry" = RIMD,
                  tabledata "Job Register" = Rimd,
#if not CLEAN21
                  tabledata "Job Resource Price" = RIMD,
#endif
                  tabledata "Job Responsibility" = RIMD,
                  tabledata "Job Task" = RIMD,
                  tabledata "Job Task Dimension" = RIMD,
                  tabledata "Job Usage Link" = RIMD,
                  tabledata "Job WIP Entry" = RIMD,
                  tabledata "Job WIP G/L Entry" = Rimd,
                  tabledata "Job WIP Method" = RIMD,
                  tabledata "Job WIP Total" = RIMD,
                  tabledata "Job WIP Warning" = RIMD,
                  tabledata "Jobs Setup" = RIMD,
                  tabledata "JSON Buffer" = RIMD,
                  tabledata "Last Used Chart" = RIMD,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "License Agreement" = RIMD,
                  tabledata "Line Fee Note on Report Hist." = Rimd,
                  tabledata "Line Number Buffer" = RIMD,
                  tabledata "Load Buffer" = RIMD,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata Location = RIMD,
                  tabledata "Mailing Group" = RIMD,
                  tabledata "Main Asset Component" = RIMD,
                  tabledata Maintenance = RIMD,
                  tabledata "Maintenance Ledger Entry" = Rimd,
                  tabledata "Maintenance Registration" = RIMD,
                  tabledata Manufacturer = RIMD,
                  tabledata "Manufacturing Setup" = Ri,
                  tabledata "Marketing Setup" = RIMD,
                  tabledata "Media Repository" = RIMD,
                  tabledata "Memoized Result" = RIMD,
                  tabledata "Misc. Article Information" = RIMD,
                  tabledata "MS-QBD Setup" = R,
                  tabledata "My Account" = RIMD,
                  tabledata "My Customer" = RIMD,
                  tabledata "My Item" = RIMD,
                  tabledata "My Job" = RIMD,
                  tabledata "My Notifications" = RIMD,
                  tabledata "My Time Sheets" = RIMD,
                  tabledata "My Vendor" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD,
                  tabledata "Named Forward Link" = RIMD,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "No. Series Relationship" = RIMD,
                  tabledata "Nonstock Item Setup" = Ri,
                  tabledata "Notification Context" = RIMD,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Notification Schedule" = RIMD,
                  tabledata "Notification Setup" = RIMD,
                  tabledata "O365 Brand Color" = RIMD,
#if not CLEAN21
                  tabledata "O365 C2Graph Event Settings" = RIMD,
                  tabledata "O365 Country/Region" = RIMD,
                  tabledata "O365 Coupon Claim" = RIMD,
                  tabledata "O365 Coupon Claim Doc. Link" = RIMD,
                  tabledata "O365 Cust. Invoice Discount" = RIMD,
                  tabledata "O365 Customer" = RIMD,
                  tabledata "O365 Default Email Message" = RIMD,
#endif
                  tabledata "O365 Device Setup Instructions" = RIMD,
#if not CLEAN21
                  tabledata "O365 Document Sent History" = RimD,
                  tabledata "O365 Email Setup" = RIMD,
                  tabledata "O365 Field Excel Mapping" = RIMD,
#endif
                  tabledata "O365 Getting Started" = RIMD,
                  tabledata "O365 Getting Started Page Data" = RIMD,
                  tabledata "O365 HTML Template" = RIMD,
#if not CLEAN21
                  tabledata "O365 Item Basket Entry" = RIMD,
                  tabledata "O365 Payment History Buffer" = RIMD,
                  tabledata "O365 Payment Instr. Transl." = RIMD,
                  tabledata "O365 Payment Instructions" = RIMD,
                  tabledata "O365 Payment Method" = RIMD,
#endif
                  tabledata "O365 Payment Service Logo" = RIMD,
#if not CLEAN21
                  tabledata "O365 Payment Terms" = RIMD,
                  tabledata "O365 Posted Coupon Claim" = Rimd,
                  tabledata "O365 Sales Cue" = RIMD,
                  tabledata "O365 Sales Document" = RIMD,
                  tabledata "O365 Sales Event" = RIMD,
                  tabledata "O365 Sales Graph" = Rimd,
                  tabledata "O365 Sales Initial Setup" = RIMD,
                  tabledata "O365 Sales Invoice Document" = RIMD,
                  tabledata "O365 Settings Menu" = RIMD,
                  tabledata "O365 Social Network" = RIMD,
#endif
                  tabledata "Object Translation" = RIMD,
                  tabledata "OCR Service Document Template" = RIMD,
                  tabledata "OCR Service Setup" = RIMD,
                  tabledata "Office Add-in" = RIMD,
                  tabledata "Office Add-in Context" = RIMD,
                  tabledata "Office Add-in Setup" = RIMD,
                  tabledata "Office Admin. Credentials" = Rimd,
                  tabledata "Office Contact Details" = RIMD,
                  tabledata "Office Document Selection" = RIMD,
                  tabledata "Office Invoice" = RIMD,
                  tabledata "Office Job Journal" = RIMD,
                  tabledata "Office Suggested Line Item" = RIMD,
                  tabledata "Online Bank Acc. Link" = RIMD,
                  tabledata "Online Map Parameter Setup" = RIMD,
                  tabledata "Online Map Setup" = RIMD,
                  tabledata Opportunity = r,
                  tabledata "Opportunity Entry" = r,
                  tabledata "Option Lookup Buffer" = rimd,
                  tabledata "Order Promising Setup" = R,
                  tabledata "Order Tracking Entry" = RIMD,
                  tabledata "Organizational Level" = RIMD,
                  tabledata "Overdue Approval Entry" = Rimd,
                  tabledata "Payable Employee Ledger Entry" = RIMD,
                  tabledata "Payable Vendor Ledger Entry" = RIMD,
                  tabledata "Payment Application Proposal" = RIMD,
#if not CLEAN22
                  tabledata "Payment Buffer" = RIMD,
#endif
                  tabledata "Vendor Payment Buffer" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Export Remittance Text" = RIMD,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Method Translation" = RIMD,
                  tabledata "Payment Rec. Related Entry" = RIMD,
                  tabledata "Pmt. Rec. Applied-to Entry" = RIMD,
                  tabledata "Payment Registration Buffer" = RIMD,
                  tabledata "Payment Registration Setup" = RIMD,
                  tabledata "Payment Reporting Argument" = Rimd,
                  tabledata "Payment Service Setup" = RIMD,
                  tabledata "Payment Term Translation" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Payroll Import Buffer" = RIMD,
                  tabledata "Payroll Setup" = RIMD,
                  tabledata "Positive Pay Detail" = RIMD,
                  tabledata "Positive Pay Entry" = RIMD,
                  tabledata "Positive Pay Entry Detail" = RIMD,
                  tabledata "Positive Pay Footer" = RIMD,
                  tabledata "Positive Pay Header" = RIMD,
                  tabledata "Post Code" = RIMD,
                  tabledata "Post Value Entry to G/L" = RImd,
                  tabledata "Postcode Service Config" = RIMD,
                  tabledata "Posted Approval Comment Line" = Rimd,
                  tabledata "Posted Approval Entry" = Rimd,
                  tabledata "Posted Deferral Header" = RIMD,
                  tabledata "Posted Deferral Line" = RIMD,
                  tabledata "Posted Docs. With No Inc. Buf." = RIMD,
                  tabledata "Posted Payment Recon. Hdr" = RIMD,
                  tabledata "Posted Payment Recon. Line" = RIMD,
#if not CLEAN21
                  tabledata "Power BI Report Buffer" = RIMD,
                  tabledata "Power BI User License" = RIMD,
#endif
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
                  tabledata "Printer Selection" = RIMD,
                  tabledata "Profile Questionnaire Header" = RIMD,
                  tabledata "Profile Questionnaire Line" = RIMD,
                  tabledata "Purch. Comment Line" = RIMD,
                  tabledata "Purch. Comment Line Archive" = RIMD,
                  tabledata "Purch. Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = RIMD,
                  tabledata "Purch. Cr. Memo Line" = Rimd,
                  tabledata "Purch. Inv. Entity Aggregate" = RIMD,
                  tabledata "Purch. Inv. Header" = RimD,
                  tabledata "Purch. Inv. Line" = Rimd,
                  tabledata "Purch. Inv. Line Aggregate" = RIMD,
#if not CLEAN21
                  tabledata "Purch. Price Line Disc. Buff." = RIMD,
#endif
                  tabledata "Purchase Cue" = RIMD,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Header" = RIMD,
                  tabledata "Purchase Line" = RIMD,
#if not CLEAN21
                  tabledata "Purchase Line Discount" = RIMD,
#endif
                  tabledata "Purchase Order Entity Buffer" = RIMD,
#if not CLEAN21
                  tabledata "Purchase Price" = RIMD,
#endif
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Purchases & Payables Setup" = RIMD,
                  tabledata Purchasing = RIMD,
                  tabledata "RapidStart Services Cue" = RIMD,
                  tabledata Rating = RIMD,
                  tabledata "RC Headlines User Data" = RIMD,
                  tabledata "Reason Code" = RIMD,
                  tabledata "Receivables-Payables Buffer" = RIMD,
                  tabledata "Reclas. Dimension Set Buffer" = RIMD,
                  tabledata "Reconcile CV Acc Buffer" = RIMD,
                  tabledata "Record Buffer" = Rimd,
                  tabledata "Record Export Buffer" = RIMD,
                  tabledata "Record Set Buffer" = Rimd,
                  tabledata "Record Set Definition" = Rimd,
                  tabledata "Record Set Tree" = Rimd,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Relationship Mgmt. Cue" = RIMD,
                  tabledata "Reminder Comment Line" = RIMD,
                  tabledata "Reminder Header" = RIMD,
                  tabledata "Reminder Level" = RIMD,
                  tabledata "Reminder Line" = RIMD,
                  tabledata "Reminder Terms" = RIMD,
                  tabledata "Reminder Terms Translation" = RIMD,
                  tabledata "Reminder Text" = RIMD,
                  tabledata "Reminder/Fin. Charge Entry" = Rimd,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Report Inbox" = RIMD,
                  tabledata "Report Layout Selection" = RIMD,
                  tabledata "Report Layout Update Log" = RIMD,
                  tabledata "Report List Translation" = RIMD,
                  tabledata "Report Selection Warehouse" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Report Totals Buffer" = RIMD,
                  tabledata "Req. Wksh. Template" = RIMD,
                  tabledata "Requisition Line" = RIMD,
                  tabledata "Requisition Wksh. Name" = RIMD,
                  tabledata "Res. Availability Buffer" = RIMD,
                  tabledata "Res. Capacity Entry" = RIMD,
                  tabledata "Res. Gr. Availability Buffer" = RIMD,
                  tabledata "Res. Journal Batch" = RIMD,
                  tabledata "Res. Journal Line" = RIMD,
                  tabledata "Res. Journal Template" = RIMD,
                  tabledata "Res. Ledger Entry" = Rimd,
                  tabledata "Reservation Entry" = RIMD,
                  tabledata "Reservation Entry Buffer" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata Resource = RIMD,
#if not CLEAN21
                  tabledata "Resource Cost" = RIMD,
#endif
                  tabledata "Resource Group" = RIMD,
                  tabledata "Resource Location" = RIMD,
#if not CLEAN21
                  tabledata "Resource Price" = RIMD,
#endif
                  tabledata "Resource Register" = RIMD,
                  tabledata "Resource Service Zone" = RIMD,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Resource Unit of Measure" = RIMD,
                  tabledata "Resources Setup" = RIMD,
                  tabledata "Restricted Record" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Return Receipt Header" = RimD,
                  tabledata "Return Receipt Line" = Rimd,
                  tabledata "Reversal Entry" = RIMD,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "Role Center Notifications" = RIMD,
                  tabledata "Rounding Method" = RIMD,
                  tabledata "Sales & Receivables Setup" = RIMD,
                  tabledata "Sales by Cust. Grp.Chart Setup" = RIMD,
                  tabledata "Sales Comment Line" = RIMD,
                  tabledata "Sales Comment Line Archive" = RIMD,
                  tabledata "Sales Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Sales Cr.Memo Header" = RimD,
                  tabledata "Sales Cr.Memo Line" = Rimd,
                  tabledata "Sales Cue" = RIMD,
                  tabledata "Sales Discount Access" = RIMD,
                  tabledata "Sales Document Icon" = Rimd,
                  tabledata "Sales Header" = RIMD,
                  tabledata "Sales Header Archive" = RIMD,
                  tabledata "Sales Invoice Entity Aggregate" = RIMD,
                  tabledata "Sales Invoice Header" = RimD,
                  tabledata "Sales Invoice Line" = Rimd,
                  tabledata "Sales Invoice Line Aggregate" = RIMD,
                  tabledata "Sales Line" = RIMD,
                  tabledata "Sales Line Archive" = RIMD,
#if not CLEAN21
                  tabledata "Sales Line Discount" = RIMD,
#endif
                  tabledata "Sales Order Entity Buffer" = RIMD,
                  tabledata "Sales Planning Line" = Rimd,
#if not CLEAN21
                  tabledata "Sales Price" = RIMD,
#endif
                  tabledata "Sales Price Access" = RIMD,
#if not CLEAN21
                  tabledata "Sales Price and Line Disc Buff" = RIMD,
                  tabledata "Sales Price Worksheet" = RIMD,
#endif
                  tabledata "Sales Quote Entity Buffer" = RIMD,
                  tabledata "Sales Shipment Buffer" = RIMD,
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata Salutation = RIMD,
                  tabledata "Salutation Formula" = RIMD,
                  tabledata "SB Owner Cue" = RIMD,
                  tabledata "Segment Interaction Language" = RIMD,
                  tabledata "Segment Line" = RIMD,
                  tabledata "Selected Dimension" = RIMD,
                  tabledata "Semi-Manual Execution Log" = RIMD,
                  tabledata "Semi-Manual Test Wizard" = RIMD,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "SEPA Direct Debit Mandate" = RIMD,
                  tabledata "Service Connection" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Mgt. Setup" = Ri,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Shipment Method Translation" = RIMD,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Sorting Table" = RIMD,
                  tabledata "Source Code" = RIMD,
                  tabledata "Source Code Setup" = RIMD,
                  tabledata "Standard Address" = Rimd,
                  tabledata "Standard Customer Sales Code" = RIMD,
                  tabledata "Standard General Journal" = RIMD,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "Standard Item Journal" = RIMD,
                  tabledata "Standard Item Journal Line" = RIMD,
                  tabledata "Standard Purchase Code" = RIMD,
                  tabledata "Standard Purchase Line" = RIMD,
                  tabledata "Standard Sales Code" = RIMD,
                  tabledata "Standard Sales Line" = RIMD,
                  tabledata "Standard Text" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = RIMD,
                  tabledata "Substitution Condition" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Table Filter" = RIMD,
#if not CLEAN21
                  tabledata "Table Permission Buffer" = RIMD,
#endif
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Tax Area" = RIMD,
                  tabledata "Tax Area Buffer" = RIMD,
                  tabledata "Tax Area Line" = RIMD,
                  tabledata "Tax Area Translation" = RIMD,
                  tabledata "Tax Detail" = RIMD,
                  tabledata "Tax Group" = RIMD,
                  tabledata "Tax Group Buffer" = RIMD,
                  tabledata "Tax Jurisdiction" = RIMD,
                  tabledata "Tax Jurisdiction Translation" = RIMD,
                  tabledata "Tax Rate Buffer" = RIMD,
                  tabledata "Tax Setup" = RIMD,
                  tabledata Team = RIMD,
                  tabledata "Team Member Cue" = RIMD,
                  tabledata "Team Salesperson" = RIMD,
                  tabledata "Temp Integration Field Mapping" = RIMD,
                  tabledata TempStack = RIMD,
                  tabledata "Terms And Conditions" = RIM,
                  tabledata "Terms And Conditions State" = RIM,
                  tabledata Territory = RIMD,
                  tabledata "Text-to-Account Mapping" = RIMD,
                  tabledata "Time Series Buffer" = R,
                  tabledata "Time Series Forecast" = R,
                  tabledata "Time Sheet Chart Setup" = RIMD,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Detail Archive" = RIMD,
                  tabledata "Time Sheet Header" = RIMD,
                  tabledata "Time Sheet Header Archive" = RIMD,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Line Archive" = RIMD,
                  tabledata "Time Sheet Posting Entry" = RIMD,
                  tabledata "Timeline Event" = RIMD,
                  tabledata "Timeline Event Change" = RIMD,
                  tabledata "To-do" = r,
                  tabledata "Total Value Insured" = RIMD,
                  tabledata "Trailing Sales Orders Setup" = RIMD,
                  tabledata "Transaction Specification" = RIMD,
                  tabledata "Transaction Type" = RIMD,
                  tabledata "Transfer Header" = RIMD,
                  tabledata "Transfer Line" = RIMD,
                  tabledata "Transfer Receipt Header" = RIMD,
                  tabledata "Transfer Receipt Line" = RIMD,
                  tabledata "Transfer Route" = RIMD,
                  tabledata "Transfer Shipment Header" = RIMD,
                  tabledata "Transfer Shipment Line" = RIMD,
                  tabledata "Transformation Rule" = RIMD,
                  tabledata "Transport Method" = RIMD,
                  tabledata "Trial Balance Entity Buffer" = RIMD,
                  tabledata "Trial Balance Setup" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Unit Group" = RIMD,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "Unlinked Attachment" = RIMD,
                  tabledata "Unplanned Demand" = RIMD,
                  tabledata "Untracked Planning Element" = RIMD,
#if not CLEAN22
                  tabledata "User Group" = R,
                  tabledata "User Group Access Control" = R,
                  tabledata "User Group Member" = Rimd,
                  tabledata "User Group Permission Set" = R,
                  tabledata "User Group Plan" = Rimd,
#endif
                  tabledata "User Preference" = RIMD,
                  tabledata "User Security Status" = RIMD,
                  tabledata "User Setup" = RIMD,
                  tabledata "User Task" = RIMD,
                  tabledata "User Time Register" = RIMD,
                  tabledata "User Tours" = RIMD,
                  tabledata "Value Entry" = Rimd,
                  tabledata "Value Entry Relation" = RIMD,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = RIMD,
                  tabledata "VAT Assisted Setup Templates" = RIMD,
                  tabledata "VAT Business Posting Group" = RIMD,
                  tabledata "VAT Clause" = RIMD,
                  tabledata "VAT Clause by Doc. Type" = RIMD,
                  tabledata "VAT Clause by Doc. Type Trans." = RIMD,
                  tabledata "VAT Clause Translation" = RIMD,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Posting Setup" = RIMD,
                  tabledata "VAT Product Posting Group" = RIMD,
                  tabledata "VAT Rate Change Conversion" = RIMD,
                  tabledata "VAT Rate Change Log Entry" = Rimd,
                  tabledata "VAT Rate Change Setup" = RIMD,
                  tabledata "VAT Reg. No. Srv Config" = RIMD,
                  tabledata "VAT Reg. No. Srv. Template" = RIMD,
                  tabledata "VAT Registration Log" = RIMD,
                  tabledata "VAT Registration Log Details" = RIMD,
                  tabledata "VAT Registration No. Format" = RIMD,
                  tabledata "VAT Report Archive" = Rimd,
                  tabledata "VAT Report Error Log" = RIMD,
                  tabledata "VAT Report Header" = RIMD,
                  tabledata "VAT Report Line" = RIMD,
                  tabledata "VAT Report Line Relation" = RIMD,
                  tabledata "VAT Report Setup" = RIMD,
                  tabledata "VAT Reporting Code" = RIMD,
                  tabledata "VAT Reports Configuration" = RIMD,
                  tabledata "VAT Setup Posting Groups" = RIMD,
                  tabledata "VAT Statement Line" = RIMD,
                  tabledata "VAT Statement Name" = RIMD,
                  tabledata "VAT Statement Report Line" = RIMD,
                  tabledata "VAT Statement Template" = RIMD,
                  tabledata "VAT Setup" = RIMD,
                  tabledata "VAT Posting Parameters" = RIMD,
                  tabledata Vendor = RIMD,
                  tabledata "Vendor Amount" = RIMD,
                  tabledata "Vendor Bank Account" = RIMD,
                  tabledata "Vendor Invoice Disc." = RIMD,
                  tabledata "Vendor Ledger Entry" = RiMd,
                  tabledata "Vendor Posting Group" = RIMD,
                  tabledata "Vendor Purchase Buffer" = RIMD,
                  tabledata "Vendor Templ." = RIMD,
                  tabledata "Warehouse Setup" = Ri,
                  tabledata "Warranty Ledger Entry" = RIMD,
                  tabledata "Web Source" = RIMD,
                  tabledata "WF Event/Response Combination" = RIMD,
                  tabledata "Work Center" = RIMD,
                  tabledata "Work Type" = RIMD,
                  tabledata "Work-Hour Template" = RIMD,
                  tabledata "Workflow - Record Change" = Rimd,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Buffer" = RIMD,
                  tabledata "Workflow Category" = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Record Change Archive" = Rimd,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Argument Archive" = Rimd,
                  tabledata "Workflow Step Buffer" = RIMD,
                  tabledata "Workflow Step Instance" = RIMD,
                  tabledata "Workflow Step Instance Archive" = Rimd,
                  tabledata "Workflow Table Relation Value" = RIMD,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD,
                  tabledata "Workflow Webhook Entry" = Rimd,
                  tabledata "Workflow Webhook Notification" = Rimd,
                  tabledata "Workflow Webhook Sub Buffer" = RIMD,
                  tabledata "Workflow Webhook Subscription" = RIMD,
                  tabledata "Workflows Entries Buffer" = Rimd,
                  tabledata "XML Buffer" = RIMD,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
