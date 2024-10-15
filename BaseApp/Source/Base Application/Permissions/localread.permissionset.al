namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Bank.Ledger;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Finance.VAT.Reporting;
#if not CLEAN23
using Microsoft.Finance.Analysis;
#endif
using Microsoft.Foundation.Address;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Accounting Period GB" = R,
                  tabledata "BACS Ledger Entry" = R,
                  tabledata "BACS Register" = R,
                  tabledata "Fin. Charge Interest Rate" = R,
                  tabledata "GovTalk Message Parts" = R,
                  tabledata "GovTalk Setup" = r,
                  tabledata GovTalkMessage = R,
#if not CLEAN25
                  tabledata "MTD-Liability" = R,
                  tabledata "MTD-Payment" = R,
                  tabledata "MTD-Return Details" = R,
                  tabledata "MTD-Missing Fraud Prev. Hdr" = R,
                  tabledata "MTD-Session Fraud Prev. Hdr" = R,
                  tabledata "MTD-Default Fraud Prev. Hdr" = R,
#endif
#if not CLEAN23
                  tabledata "Payment Application Buffer" = R,
                  tabledata "Payment Period Setup" = R,
#endif
                  tabledata "Postcode Notification Memory" = R;
}
