namespace Microsoft.Warehouse.Document;

enum 7303 "Warehouse Shipment Sorting Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { Caption = ' '; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Document") { Caption = 'Document'; }
    value(3; "Shelf or Bin") { Caption = 'Shelf or Bin'; }
    value(4; "Due Date") { Caption = 'Due Date'; }
    value(5; "Destination") { Caption = 'Destination'; }
}