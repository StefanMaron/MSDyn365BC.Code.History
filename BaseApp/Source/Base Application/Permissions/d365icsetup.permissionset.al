permissionset 3239 "D365 IC, SETUP"
{
    Assignable = true;

    Caption = 'Dyn. 365 Intercompany Setup';
    Permissions = tabledata "IC Dimension" = RIMD,
                  tabledata "IC Dimension Value" = RIMD,
                  tabledata "IC G/L Account" = RIMD,
                  tabledata "IC Partner" = RIMD;
}
