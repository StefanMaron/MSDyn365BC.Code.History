permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access';

#if not CLEAN22
    Permissions = tabledata "SIE Dimension" = R,
                  tabledata "Automatic Acc. Header" = R,
                  tabledata "Automatic Acc. Line" = R,
                  tabledata "SIE Import Buffer" = R;
#endif
}


