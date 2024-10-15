#if not CLEAN20
permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';
    Permissions =
                  tabledata "Acc. Schedule Filter Line" = R,
                  tabledata "Bank Acc. Adjustment Buffer" = R,
                  tabledata "Detailed Fin. Charge Memo Line" = R,
                  tabledata "Detailed Iss.Fin.Ch. Memo Line" = R,
                  tabledata "Detailed Issued Reminder Line" = R,
                  tabledata "Detailed Reminder Line" = R,
                  tabledata "Enhanced Currency Buffer" = R,
                  tabledata "Export Acc. Schedule" = R,
                  tabledata "G/L Account Adjustment Buffer" = R,
                  tabledata "Multiple Interest Calc. Line" = R,
                  tabledata "Multiple Interest Rate" = R;
}
#endif