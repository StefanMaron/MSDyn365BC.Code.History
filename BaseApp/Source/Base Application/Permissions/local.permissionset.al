permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Automatic Acc. Header" = RIMD,
                  tabledata "Automatic Acc. Line" = RIMD,
                  tabledata "SIE Dimension" = RIMD,
                  tabledata "SIE Import Buffer" = RIMD;
}
