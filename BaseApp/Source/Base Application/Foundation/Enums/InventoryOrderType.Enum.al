namespace Microsoft.Foundation.Enums;

enum 90 "Inventory Order Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Production") { Caption = 'Production'; }
    value(2; "Transfer") { Caption = 'Transfer'; }
    value(3; "Service") { Caption = 'Service'; }
    value(4; "Assembly") { Caption = 'Assembly'; }
}