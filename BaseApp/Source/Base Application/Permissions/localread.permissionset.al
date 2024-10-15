permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access';

    Permissions = tabledata "Automatic Acc. Header" = R,
                  tabledata "Automatic Acc. Line" = R,
                  tabledata "SIE Dimension" = R,
                  tabledata "SIE Import Buffer" = R;
}
