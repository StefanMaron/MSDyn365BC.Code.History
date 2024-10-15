permissionset 6148 "Manufacturing Design - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read Production BOM & Routing';

    Permissions = tabledata "Capacity Constrained Resource" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata Item = R,
                  tabledata "Machine Center" = R,
                  tabledata "Manufacturing Comment Line" = R,
                  tabledata "Production BOM Comment Line" = R,
                  tabledata "Production BOM Header" = R,
                  tabledata "Production BOM Line" = R,
                  tabledata "Production BOM Version" = R,
                  tabledata "Production Matrix  BOM Entry" = Rimd,
                  tabledata "Production Matrix BOM Line" = Rimd,
                  tabledata "Quality Measure" = R,
                  tabledata "Routing Comment Line" = R,
                  tabledata "Routing Header" = R,
                  tabledata "Routing Line" = R,
                  tabledata "Routing Link" = R,
                  tabledata "Routing Personnel" = R,
                  tabledata "Routing Quality Measure" = R,
                  tabledata "Routing Tool" = R,
                  tabledata "Routing Version" = R,
                  tabledata "Standard Task" = R,
                  tabledata "Standard Task Description" = R,
                  tabledata "Standard Task Personnel" = R,
                  tabledata "Standard Task Quality Measure" = R,
                  tabledata "Standard Task Tool" = R,
                  tabledata "Where-Used Line" = Rimd,
                  tabledata "Work Center" = R;
}
