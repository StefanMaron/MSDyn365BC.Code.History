permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Automatic Acc. Header" = RIMD,
                  tabledata "Automatic Acc. Line" = RIMD,
                  tabledata "Depr. Diff. Posting Buffer" = RIMD,
                  tabledata "Foreign Payment Types" = RIMD,
                  tabledata "Intrastat - File Setup" = RIMD,
                  tabledata "Ref. Payment - Exported" = RIMD,
                  tabledata "Ref. Payment - Exported Buffer" = RIMD,
                  tabledata "Ref. Payment - Imported" = RIMD,
                  tabledata "Reference File Setup" = RIMD;
}
