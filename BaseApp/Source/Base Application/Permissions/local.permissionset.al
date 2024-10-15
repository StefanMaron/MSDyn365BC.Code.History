namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Bank.Ledger;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Finance.VAT.Reporting;
#if not CLEAN23
using Microsoft.Finance.Analysis;
#endif
using Microsoft.Foundation.Address;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Accounting Period GB" = RIMD,
                  tabledata "BACS Ledger Entry" = RIMD,
                  tabledata "BACS Register" = RIMD,
                  tabledata "Fin. Charge Interest Rate" = RIMD,
                  tabledata "GovTalk Message Parts" = RIMD,
                  tabledata "GovTalk Setup" = r,
                  tabledata GovTalkMessage = RIMD,
#if not CLEAN25
                  tabledata "MTD-Liability" = RIMD,
                  tabledata "MTD-Payment" = RIMD,
                  tabledata "MTD-Return Details" = RIMD,
                  tabledata "MTD-Missing Fraud Prev. Hdr" = RIMD,
                  tabledata "MTD-Session Fraud Prev. Hdr" = RIMD,
                  tabledata "MTD-Default Fraud Prev. Hdr" = RIMD,
#endif
#if not CLEAN23
                  tabledata "Payment Application Buffer" = RIMD,
                  tabledata "Payment Period Setup" = RIMD,
#endif
                  tabledata "Postcode Notification Memory" = RIMD;
}
