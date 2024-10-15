permissionset 4445 "Resources - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read res./res.gr. and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "Res. Ledger Entry" = R,
                  tabledata Resource = R,
                  tabledata "Resource Group" = R,
                  tabledata "Resource Unit of Measure" = R;
}
