namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Finance.FinancialReports;
#if not CLEAN23
using Microsoft.Finance.Analysis;
#endif
using Microsoft.Sales.Document;
using Microsoft.Finance.ReceivablesPayables;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Bank Account Buffer" = RIMD,
                  tabledata "FR Acc. Schedule Line" = RIMD,
                  tabledata "FR Acc. Schedule Name" = RIMD,
                  tabledata "Payment Address" = RIMD,
#if not CLEAN23
                  tabledata "Payment Application Buffer" = RIMD,
#endif
                  tabledata "Payment Class" = RIMD,
                  tabledata "Payment Header" = RIMD,
                  tabledata "Payment Header Archive" = RIMD,
                  tabledata "Payment Line" = RIMD,
                  tabledata "Payment Line Archive" = RIMD,
#if not CLEAN23
                  tabledata "Payment Period Setup" = RIMD,
#endif
                  tabledata "Payment Post. Buffer" = RIMD,
                  tabledata "Payment Status" = RIMD,
                  tabledata "Payment Step" = RIMD,
                  tabledata "Payment Step Ledger" = RIMD,
                  tabledata "Shipment Invoiced" = RIMD,
                  tabledata "Unreal. CV Ledg. Entry Buffer" = RIMD;
}
