namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
#if not CLEAN25
using Microsoft.Foundation.Reporting;
#endif
using Microsoft.Finance.AuditFileExport;
using Microsoft.Purchases.Document;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Bank Directory" = RIMD,
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
                  tabledata "ESR Setup" = RIMD,
#if not CLEAN25
                  tabledata "DACH Report Selections" = RIMD,
#endif
                  tabledata "Issued Deliv. Reminder Header" = RIMD,
                  tabledata "Issued Deliv. Reminder Line" = RIMD,
                  tabledata "Key Buffer" = RIMD,
                  tabledata "LSV Journal" = RIMD,
                  tabledata "LSV Journal Line" = RIMD,
                  tabledata "LSV Setup" = RIMD,
                  tabledata "Number Series Buffer" = RIMD,
                  tabledata "Place of Dispatcher" = RIMD,
                  tabledata "Place of Receiver" = RIMD,
                  tabledata "VAT Cipher Code" = RIMD,
                  tabledata "VAT Cipher Setup" = RIMD,
                  tabledata "VAT Currency Adjustment Buffer" = RIMD;
}