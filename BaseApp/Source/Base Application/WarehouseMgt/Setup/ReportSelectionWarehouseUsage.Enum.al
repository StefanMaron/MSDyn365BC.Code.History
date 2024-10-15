namespace Microsoft.Warehouse.Setup;

enum 7355 "Report Selection Warehouse Usage"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Put-away") { Caption = 'Put-away'; }
    value(1; "Pick") { Caption = 'Pick'; }
    value(2; "Movement") { Caption = 'Movement'; }
    value(3; "Invt. Put-away") { Caption = 'Invt. Put-away'; }
    value(4; "Invt. Pick") { Caption = 'Invt. Pick'; }
    value(5; "Invt. Movement") { Caption = 'Invt. Movement'; }
    value(6; "Receipt") { Caption = 'Receipt'; }
    value(7; "Shipment") { Caption = 'Shipment'; }
    value(8; "Posted Receipt") { Caption = 'Posted Receipt'; }
    value(9; "Posted Shipment") { Caption = 'Posted Shipment'; }
}