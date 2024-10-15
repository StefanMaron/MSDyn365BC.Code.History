#if not CLEAN20
permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';
    Permissions =
                  tabledata "Acc. Schedule Filter Line" = RIMD,
                  tabledata "Bank Acc. Adjustment Buffer" = RIMD,
                  tabledata "Detailed Fin. Charge Memo Line" = RIMD,
                  tabledata "Detailed Iss.Fin.Ch. Memo Line" = RIMD,
                  tabledata "Detailed Issued Reminder Line" = RIMD,
                  tabledata "Detailed Reminder Line" = RIMD,
                  tabledata "Enhanced Currency Buffer" = RIMD,
                  tabledata "Export Acc. Schedule" = RIMD,
                  tabledata "G/L Account Adjustment Buffer" = RIMD,
                  tabledata "Multiple Interest Calc. Line" = RIMD,
                  tabledata "Multiple Interest Rate" = RIMD;
}

#endif