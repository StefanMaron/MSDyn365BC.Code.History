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

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Bank Directory" = RIMD,
#if not CLEAN22
                  tabledata Certificate = RIMD,
#endif
                  tabledata "DACH Report Selections" = RIMD,
                  tabledata "Data Exp. Primary Key Buffer" = RIMD,
                  tabledata "Data Export" = RIMD,
                  tabledata "Data Export Buffer" = RIMD,
                  tabledata "Data Export Record Definition" = RIMD,
                  tabledata "Data Export Record Field" = RIMD,
                  tabledata "Data Export Record Source" = RIMD,
                  tabledata "Data Export Record Type" = RIMD,
                  tabledata "Data Export Setup" = RIMD,
                  tabledata "Data Export Table Relation" = RIMD,
                  tabledata "Delivery Reminder Comment Line" = RIMD,
                  tabledata "Delivery Reminder Header" = RIMD,
                  tabledata "Delivery Reminder Ledger Entry" = RIMD,
                  tabledata "Delivery Reminder Level" = RIMD,
                  tabledata "Delivery Reminder Line" = RIMD,
                  tabledata "Delivery Reminder Term" = RIMD,
                  tabledata "Delivery Reminder Text" = RIMD,
                  tabledata "DTA Setup" = RIMD,
                  tabledata "Electronic VAT Decl. Setup" = RIMD,
                  tabledata "ESR Setup" = RIMD,
                  tabledata "Expect. Phys. Inv. Track. Line" = RIMD,
                  tabledata "Issued Deliv. Reminder Header" = RIMD,
                  tabledata "Issued Deliv. Reminder Line" = RIMD,
                  tabledata "Key Buffer" = RIMD,
                  tabledata "LSV Journal" = RIMD,
                  tabledata "LSV Journal Line" = RIMD,
                  tabledata "LSV Setup" = RIMD,
                  tabledata "Number Series Buffer" = RIMD,
                  tabledata "Phys. Inventory Comment Line" = RIMD,
                  tabledata "Phys. Inventory Order Header" = RIMD,
                  tabledata "Phys. Inventory Order Line" = RIMD,
                  tabledata "Phys. Invt. Diff. List Buffer" = RIMD,
                  tabledata "Phys. Invt. Recording Header" = RIMD,
                  tabledata "Phys. Invt. Recording Line" = RIMD,
                  tabledata "Phys. Invt. Tracking Buffer" = RIMD,
                  tabledata "Place of Dispatcher" = RIMD,
                  tabledata "Place of Receiver" = RIMD,
                  tabledata "Post. Exp. Ph. In. Track. Line" = RIMD,
                  tabledata "Post. Phys. Invt. Order Header" = RIMD,
                  tabledata "Posted Phys. Invt. Order Line" = RIMD,
                  tabledata "Posted Phys. Invt. Rec. Header" = RIMD,
                  tabledata "Posted Phys. Invt. Rec. Line" = RIMD,
                  tabledata "Posted Phys. Invt. Track. Line" = RIMD,
                  tabledata "Sales VAT Advance Notification" = RIMD,
                  tabledata "Transmission Log Entry" = RIMD,
                  tabledata "VAT Cipher Code" = RIMD,
                  tabledata "VAT Cipher Setup" = RIMD,
                  tabledata "VAT Currency Adjustment Buffer" = RIMD;
}
