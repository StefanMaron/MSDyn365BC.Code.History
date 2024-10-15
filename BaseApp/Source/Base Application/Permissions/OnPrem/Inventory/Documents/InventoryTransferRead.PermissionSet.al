permissionset 2132 "Inventory Transfer - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read posted transfer orders';

    Permissions = tabledata "Inventory Comment Line" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata Location = R,
                  tabledata "Posted Whse. Receipt Header" = R,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Reservation Entry" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Tracking Specification" = R,
                  tabledata "Transfer Header" = R,
                  tabledata "Transfer Line" = R,
                  tabledata "Transfer Receipt Header" = R,
                  tabledata "Transfer Receipt Line" = R,
                  tabledata "Transfer Route" = R,
                  tabledata "Transfer Shipment Header" = R,
                  tabledata "Transfer Shipment Line" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "Value Entry" = r;
}
