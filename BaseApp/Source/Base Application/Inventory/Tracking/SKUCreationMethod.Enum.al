namespace Microsoft.Inventory.Tracking;

enum 5702 "SKU Creation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Location") { Caption = 'Location'; }
    value(1; "Variant") { Caption = 'Variant'; }
    value(2; "Location & Variant") { Caption = 'Location & Variant'; }
}