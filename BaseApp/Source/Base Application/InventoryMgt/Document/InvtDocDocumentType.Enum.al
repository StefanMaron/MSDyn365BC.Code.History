namespace Microsoft.Inventory.Document;

enum 5850 "Invt. Doc. Document Type"
{
    Extensible = true;

    value(0; "Receipt") { Caption = 'Receipt'; }
    value(1; "Shipment") { Caption = 'Shipment'; }
}