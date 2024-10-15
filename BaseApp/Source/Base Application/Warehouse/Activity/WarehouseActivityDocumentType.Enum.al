namespace Microsoft.Warehouse.Activity;

enum 5769 "Warehouse Activity Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Receipt") { Caption = 'Receipt'; }
    value(2; "Shipment") { Caption = 'Shipment'; }
    value(3; "Internal Put-away") { Caption = 'Internal Put-away'; }
    value(4; "Internal Pick") { Caption = 'Internal Pick'; }
    value(5; "Production") { Caption = 'Production'; }
    value(6; "Movement Worksheet") { Caption = 'Movement Worksheet'; }
    value(8; "Assembly") { Caption = 'Assembly'; }
    value(9; "Job") { Caption = 'Job'; }
}