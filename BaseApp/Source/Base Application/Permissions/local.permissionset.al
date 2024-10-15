namespace System.Security.AccessControl;

using Microsoft.Finance.VAT.Reporting;
using Microsoft;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.History;
using Microsoft.Purchases.History;
using Microsoft.EServices.EDocument;
#if not CLEAN22
using Microsoft.Purchases.Reports;
#endif

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "340 Declaration Line" = RIMD,
                  tabledata "Acc. Schedule Buffer" = RIMD,
                  tabledata "AEAT Transference Format" = RIMD,
                  tabledata "AEAT Transference Format XML" = RIMD,
                  tabledata "BG/PO Comment Line" = RIMD,
                  tabledata "BG/PO Post. Buffer" = RIMD,
                  tabledata "Bill Group" = RIMD,
                  tabledata "Cartera Doc." = RIMd,
                  tabledata "Cartera Report Selections" = RIMD,
                  tabledata "Cartera Setup" = RIMD,
                  tabledata "Category Code" = RIMD,
                  tabledata "Closed Bill Group" = RIMd,
                  tabledata "Closed Cartera Doc." = RIMd,
                  tabledata "Closed Payment Order" = RIMd,
                  tabledata "Customer Cash Buffer" = RIMD,
#if not CLEAN22
                  tabledata "Customer Pmt. Address" = RIMD,
#endif
                  tabledata "Customer Rating" = RIMD,
                  tabledata "Customer/Vendor Warning 349" = RIMD,
                  tabledata "Doc. Post. Buffer" = RIMD,
                  tabledata "Fee Range" = RIMD,
                  tabledata "G/L Acc. Equiv. Tool Setup" = RIMD,
                  tabledata "G/L Account Buffer" = RIMD,
                  tabledata "G/L Accounts Equivalence Tool" = RIMD,
                  tabledata "Gen. Prod. Post. Group Buffer" = RIMD,
                  tabledata "Hist. G/L Account (An. View)" = RIMD,
                  tabledata "Historic G/L Account" = RIMD,
                  tabledata "History of Equivalences COA" = RIMD,
                  tabledata "Inc. Stmt. Clos. Buffer" = RIMD,
                  tabledata Installment = RIMD,
                  tabledata "New G/L Account" = RIMD,
                  tabledata "No Taxable Entry" = Rimd,
                  tabledata "Non-Payment Period" = RIMD,
                  tabledata "Operation Code" = RIMD,
                  tabledata "Operation Fee" = RIMD,
                  tabledata "Payment Day" = RIMD,
                  tabledata "Payment Order" = RIMD,
                  tabledata "Posted Bill Group" = RIMd,
                  tabledata "Posted Cartera Doc." = RIMd,
                  tabledata "Posted Payment Order" = RIMd,
                  tabledata "Sales/Purch. Book VAT Buffer" = RIMD,
                  tabledata "Selected G/L Accounts" = RIMD,
                  tabledata "Selected Gen. Prod. Post. 340" = RIMD,
                  tabledata "Selected Gen. Prod. Post. Gr." = RIMD,
                  tabledata "Selected Rev. Charge Grp. 340" = RIMD,
                  tabledata "SII Doc. Upload State" = RIMD,
                  tabledata "SII History" = RIMD,
                  tabledata "SII Purch. Doc. Scheme Code" = RIMD,
                  tabledata "SII Sales Document Scheme Code" = RIMD,
                  tabledata "SII Missing Entries State" = RIMD,
                  tabledata "SII Session" = RIMD,
                  tabledata "SII Setup" = RIMD,
                  tabledata "SII Sending State" = RIMD,
                  tabledata "Statistical Code" = RIMD,
#if not CLEAN22
                  tabledata Suffix = RIMD,
                  tabledata "Vendor Pmt. Address" = RIMD;
#else
                  tabledata Suffix = RIMD;
#endif
}
