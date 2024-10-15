permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    IncludedPermissionSets = "LOCAL READ";

#if not CLEAN22
    Permissions = tabledata "SIE Dimension" = IMD,
                  tabledata "Automatic Acc. Header" = IMD,
                  tabledata "Automatic Acc. Line" = IMD,
                  tabledata "SIE Import Buffer" = IMD;
#endif
}
