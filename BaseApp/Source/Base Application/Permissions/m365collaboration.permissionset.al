#if not CLEAN23
namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Campaign;
using Microsoft.Foundation.Company;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Diagnostics;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.Dimension;
using System.Environment.Configuration;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.CRM.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.CRM.Outlook;
using Microsoft.Bank.BankAccount;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using System.Environment;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;
using System.Automation;
using Microsoft.Foundation.Attachment;
using Microsoft.Finance.VAT.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Projects.Project.Planning;
using Microsoft.Utilities;

permissionset 4785 "M365 COLLABORATION"
{
    Assignable = true;
    Caption = 'Microsoft 365 Collaboration';
    ObsoleteReason = 'No longer used.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "LOGIN";

    Permissions = tabledata "Approval Entry" = R,
                  tabledata "Assembly Header" = R,
                  tabledata "Assembly Line" = R,
                  tabledata "Campaign Target Group" = R,
                  tabledata "Company Information" = R,
                  tabledata Contact = R,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Country/Region" = R,
                  tabledata Customer = R,
                  tabledata "Database Missing Indexes" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Set Entry" = R,
                  tabledata "Dimension Translation" = R,
                  tabledata "Document Attachment" = R,
                  tabledata "Expanded Permission" = R,
                  tabledata "Feature Data Update Status" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "G/L Account" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "Incoming Document" = R,
                  tabledata "Inventory Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Charge" = R,
                  tabledata "Item Charge Assignment (Purch)" = R,
                  tabledata "Item Charge Assignment (Sales)" = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Substitution" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Marketing Setup" = R,
                  tabledata "No. Series" = R,
                  tabledata "No. Series Line" = R,
                  tabledata "Office Add-in Setup" = R,
                  tabledata "Page Data Personalization" = R,
                  tabledata "Page Documentation" = R,
                  tabledata "Payment Method" = R,
                  tabledata "Planning Component" = R,
                  tabledata "Prod. Order Component" = R,
                  tabledata "Prod. Order Line" = R,
                  tabledata "Purch. Cr. Memo Hdr." = R,
                  tabledata "Purch. Inv. Header" = R,
                  tabledata "Purch. Rcpt. Header" = R,
                  tabledata "Purchase Header" = R,
                  tabledata "Purchase Header Archive" = R,
                  tabledata "Purchase Line" = R,
                  tabledata "Purchases & Payables Setup" = R,
                  tabledata "Record Link" = R,
                  tabledata "Requisition Line" = R,
                  tabledata "Reservation Entry" = R,
                  tabledata Resource = R,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Return Shipment Header" = R,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Header Archive" = R,
                  tabledata "Sales Invoice Header" = R,
                  tabledata "Sales Line" = R,
                  tabledata "Sales Shipment Header" = R,
                  tabledata Microsoft.Service.Document."Service Line" = R,
                  tabledata "Standard Text" = R,
                  tabledata "Tenant Media" = R,
                  tabledata "Tenant Permission" = R,
                  tabledata "Transfer Line" = R,
                  tabledata "Vendor" = R,
                  tabledata "Workflow Webhook Entry" = R;
}
#endif