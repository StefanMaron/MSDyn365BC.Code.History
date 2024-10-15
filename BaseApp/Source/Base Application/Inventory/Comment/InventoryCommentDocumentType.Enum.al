namespace Microsoft.Inventory.Comment;

enum 5748 "Inventory Comment Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Transfer Order") { Caption = 'Transfer Order'; }
    value(2; "Posted Transfer Shipment") { Caption = 'Posted Transfer Shipment'; }
    value(3; "Posted Transfer Receipt") { Caption = 'Posted Transfer Receipt'; }
    value(4; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(5; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(6; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(7; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    value(8; "Posted Direct Transfer") { Caption = 'Posted Direct Transfer'; }
}