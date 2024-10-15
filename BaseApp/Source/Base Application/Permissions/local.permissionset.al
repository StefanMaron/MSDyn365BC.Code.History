namespace System.Security.AccessControl;

#if not CLEAN22
using Microsoft;
#endif
using Microsoft.Foundation.Reporting;
using Microsoft.Finance.AuditFileExport;
using Microsoft.Purchases.Document;
#if not CLEAN24
using Microsoft.Inventory.Counting;
#endif
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

#if not CLEAN22
    Permissions = tabledata Certificate = RIMD,
                  tabledata "DACH Report Selections" = RIMD,
#else
    Permissions = tabledata "DACH Report Selections" = RIMD,
#endif
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
#if not CLEAN24
                  tabledata "Expect. Phys. Inv. Track. Line" = RIMD,
#endif
                  tabledata "Issued Deliv. Reminder Header" = RIMD,
                  tabledata "Issued Deliv. Reminder Line" = RIMD,
                  tabledata "Key Buffer" = RIMD,
                  tabledata "Number Series Buffer" = RIMD,
#if not CLEAN24
                  tabledata "Phys. Inventory Comment Line" = RIMD,
                  tabledata "Phys. Inventory Order Header" = RIMD,
                  tabledata "Phys. Inventory Order Line" = RIMD,
                  tabledata "Phys. Invt. Diff. List Buffer" = RIMD,
                  tabledata "Phys. Invt. Recording Header" = RIMD,
                  tabledata "Phys. Invt. Recording Line" = RIMD,
                  tabledata "Phys. Invt. Tracking Buffer" = RIMD,
#endif
                  tabledata "Place of Dispatcher" = RIMD,
#if not CLEAN24
                  tabledata "Place of Receiver" = RIMD,
                  tabledata "Post. Exp. Ph. In. Track. Line" = RIMD,
                  tabledata "Post. Phys. Invt. Order Header" = RIMD,
                  tabledata "Posted Phys. Invt. Order Line" = RIMD,
                  tabledata "Posted Phys. Invt. Rec. Header" = RIMD,
                  tabledata "Posted Phys. Invt. Rec. Line" = RIMD,
                  tabledata "Posted Phys. Invt. Track. Line" = RIMD;
#else
                  tabledata "Place of Receiver" = RIMD;
#endif
}