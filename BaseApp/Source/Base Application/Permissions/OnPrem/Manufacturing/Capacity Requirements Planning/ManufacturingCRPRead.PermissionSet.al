permissionset 5058 "Manufacturing CRP - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read CRP';

    Permissions = tabledata "Calendar Absence Entry" = R,
                  tabledata "Calendar Entry" = R,
                  tabledata "Capacity Constrained Resource" = R,
                  tabledata "Capacity Ledger Entry" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Machine Center" = R,
                  tabledata "Manufacturing Comment Line" = R,
                  tabledata "Planning Component" = R,
                  tabledata "Planning Routing Line" = R,
                  tabledata "Prod. Order Capacity Need" = R,
                  tabledata "Prod. Order Component" = R,
                  tabledata "Prod. Order Line" = R,
                  tabledata "Prod. Order Routing Line" = R,
                  tabledata "Shop Calendar" = R,
                  tabledata Vendor = R,
                  tabledata "Work Center" = R,
                  tabledata "Work Center Group" = R;
}
