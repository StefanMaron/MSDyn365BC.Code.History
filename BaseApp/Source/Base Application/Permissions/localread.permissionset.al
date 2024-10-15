namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft;
using Microsoft.Foundation.Reporting;
using Microsoft.Finance.AuditFileExport;
using Microsoft.Purchases.Document;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Inventory.Counting;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Setup;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Bank Directory" = R,
#if not CLEAN22
                  tabledata Certificate = R,
#endif
                  tabledata "DACH Report Selections" = R,
                  tabledata "Data Exp. Primary Key Buffer" = R,
                  tabledata "Data Export" = R,
                  tabledata "Data Export Buffer" = R,
                  tabledata "Data Export Record Definition" = R,
                  tabledata "Data Export Record Field" = R,
                  tabledata "Data Export Record Source" = R,
                  tabledata "Data Export Record Type" = R,
                  tabledata "Data Export Setup" = R,
                  tabledata "Data Export Table Relation" = R,
                  tabledata "Delivery Reminder Comment Line" = R,
                  tabledata "Delivery Reminder Header" = R,
                  tabledata "Delivery Reminder Ledger Entry" = R,
                  tabledata "Delivery Reminder Level" = R,
                  tabledata "Delivery Reminder Line" = R,
                  tabledata "Delivery Reminder Term" = R,
                  tabledata "Delivery Reminder Text" = R,
                  tabledata "DTA Setup" = R,
                  tabledata "Electronic VAT Decl. Setup" = R,
                  tabledata "ESR Setup" = R,
                  tabledata "Expect. Phys. Inv. Track. Line" = R,
                  tabledata "Issued Deliv. Reminder Header" = R,
                  tabledata "Issued Deliv. Reminder Line" = R,
                  tabledata "Key Buffer" = R,
                  tabledata "LSV Journal" = R,
                  tabledata "LSV Journal Line" = R,
                  tabledata "LSV Setup" = R,
                  tabledata "Number Series Buffer" = R,
                  tabledata "Phys. Inventory Comment Line" = R,
                  tabledata "Phys. Inventory Order Header" = R,
                  tabledata "Phys. Inventory Order Line" = R,
                  tabledata "Phys. Invt. Diff. List Buffer" = R,
                  tabledata "Phys. Invt. Recording Header" = R,
                  tabledata "Phys. Invt. Recording Line" = R,
                  tabledata "Phys. Invt. Tracking Buffer" = R,
                  tabledata "Place of Dispatcher" = R,
                  tabledata "Place of Receiver" = R,
                  tabledata "Post. Exp. Ph. In. Track. Line" = R,
                  tabledata "Post. Phys. Invt. Order Header" = R,
                  tabledata "Posted Phys. Invt. Order Line" = R,
                  tabledata "Posted Phys. Invt. Rec. Header" = R,
                  tabledata "Posted Phys. Invt. Rec. Line" = R,
                  tabledata "Posted Phys. Invt. Track. Line" = R,
                  tabledata "Sales VAT Advance Notification" = R,
                  tabledata "Transmission Log Entry" = R,
                  tabledata "VAT Cipher Code" = R,
                  tabledata "VAT Cipher Setup" = R,
                  tabledata "VAT Currency Adjustment Buffer" = R;
}
