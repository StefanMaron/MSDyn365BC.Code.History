namespace Microsoft.Inventory.Planning;

enum 5520 "Unplanned Demand Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Production") { Caption = 'Production'; }
    value(2; "Sales") { Caption = 'Sales'; }
    value(3; "Service") { Caption = 'Service'; }
    value(4; "Job") { Caption = 'Project'; }
    value(5; "Assembly") { Caption = 'Assembly'; }
}