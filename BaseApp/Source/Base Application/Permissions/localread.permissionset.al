permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Automatic Acc. Header" = R,
                  tabledata "Automatic Acc. Line" = R,
                  tabledata "Depr. Diff. Posting Buffer" = R,
                  tabledata "Foreign Payment Types" = R,
                  tabledata "Intrastat - File Setup" = R,
                  tabledata "Ref. Payment - Exported" = R,
                  tabledata "Ref. Payment - Exported Buffer" = R,
                  tabledata "Ref. Payment - Imported" = R,
                  tabledata "Reference File Setup" = R;
}
