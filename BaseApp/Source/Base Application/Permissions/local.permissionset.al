permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Bank Account Buffer" = RIMD,
                  tabledata "FR Acc. Schedule Line" = RIMD,
                  tabledata "FR Acc. Schedule Name" = RIMD,
                  tabledata "Payment Address" = RIMD,
                  tabledata "Payment Application Buffer" = RIMD,
                  tabledata "Payment Class" = RIMD,
                  tabledata "Payment Header" = RIMD,
                  tabledata "Payment Header Archive" = RIMD,
                  tabledata "Payment Line" = RIMD,
                  tabledata "Payment Line Archive" = RIMD,
                  tabledata "Payment Period Setup" = RIMD,
                  tabledata "Payment Post. Buffer" = RIMD,
                  tabledata "Payment Status" = RIMD,
                  tabledata "Payment Step" = RIMD,
                  tabledata "Payment Step Ledger" = RIMD,
                  tabledata "Shipment Invoiced" = RIMD,
                  tabledata "Unreal. CV Ledg. Entry Buffer" = RIMD;
}
