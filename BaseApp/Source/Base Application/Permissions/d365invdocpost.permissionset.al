permissionset 5267 "D365 INV DOC, POST"
{
    Assignable = true;

    Caption = 'Dyn. 365 Post inventory doc';
    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Item Register" = Rimd,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "Transfer Header" = RM,
                  tabledata "Transfer Line" = RM,
                  tabledata "Transfer Receipt Header" = RIMD,
                  tabledata "Transfer Receipt Line" = RIMD,
                  tabledata "Transfer Shipment Header" = RIMD,
                  tabledata "Transfer Shipment Line" = RIMD,
                  tabledata "Warehouse Activity Line" = RIMD,
                  tabledata "Warehouse Shipment Line" = RIMD;
}
