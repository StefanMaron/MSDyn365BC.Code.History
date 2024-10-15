namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.Foundation.Reporting;
using Microsoft.Finance.AuditFileExport;
using Microsoft.Purchases.Document;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Inventory.Counting;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

#if not CLEAN22
    Permissions = tabledata Certificate = R,
                  tabledata "DACH Report Selections" = R,
#else
    Permissions = tabledata "DACH Report Selections" = R,
#endif
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
                  tabledata "Electronic VAT Decl. Setup" = R,
                  tabledata "Expect. Phys. Inv. Track. Line" = R,
                  tabledata "Issued Deliv. Reminder Header" = R,
                  tabledata "Issued Deliv. Reminder Line" = R,
                  tabledata "Key Buffer" = R,
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
                  tabledata "Transmission Log Entry" = R;
}
