namespace Microsoft.Warehouse.Request;

enum 5771 "Warehouse Request Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Inbound") { Caption = 'Inbound'; }
    value(1; "Outbound") { Caption = 'Outbound'; }
}