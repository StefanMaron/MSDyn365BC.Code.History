permissionset 6895 "Insurance - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read insurances and entries';

    Permissions = tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata Insurance = R,
                  tabledata "Insurance Type" = R,
                  tabledata Location = R,
                  tabledata Vendor = R;
}
