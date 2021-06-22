permissionset 4784 "D365 WHSE, SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Setup warehouse';
    Permissions = tabledata "Warehouse Activity Header" = rmD,
                  tabledata "Warehouse Activity Line" = rmD,
                  tabledata "Warehouse Employee" = rD,
                  tabledata "Warehouse Register" = D,
                  tabledata "Warehouse Request" = rmD,
                  tabledata "Warehouse Setup" = RIMD,
                  tabledata "Warehouse Shipment Line" = rmD,
                  tabledata "Warehouse Source Filter" = D,
                  tabledata "Whse. Pick Request" = D,
                  tabledata "Whse. Put-away Request" = D,
                  tabledata "Whse. Worksheet Line" = rD;
}
