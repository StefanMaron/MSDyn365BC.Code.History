namespace Microsoft.Service.Item;

enum 5941 "Service Item Shipment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales") { Caption = 'Sales'; }
    value(1; "Service") { Caption = 'Service'; }
}