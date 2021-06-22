permissionset 7052 "Fixed Assets - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read fixed assets and entries';

    Permissions = tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Depreciation Table Header" = R,
                  tabledata "Depreciation Table Line" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Depreciation Book" = R,
                  tabledata "FA Ledger Entry" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Posting Type Setup" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = Rm,
                  tabledata Location = R,
                  tabledata "Main Asset Component" = R,
                  tabledata Maintenance = R,
                  tabledata "Maintenance Ledger Entry" = R,
                  tabledata "Maintenance Registration" = R,
                  tabledata Vendor = R;
}
