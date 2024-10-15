namespace Microsoft.Inventory.Costing;

enum 106 "Cost Variance Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Purchase") { Caption = 'Purchase'; }
    value(2; "Material") { Caption = 'Material'; }
    value(3; "Capacity") { Caption = 'Capacity'; }
    value(4; "Capacity Overhead") { Caption = 'Capacity Overhead'; }
    value(5; "Manufacturing Overhead") { Caption = 'Manufacturing Overhead'; }
    value(6; "Subcontracted") { Caption = 'Subcontracted'; }
}