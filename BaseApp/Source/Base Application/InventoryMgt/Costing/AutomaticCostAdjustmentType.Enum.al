namespace Microsoft.Inventory.Costing;

enum 30 "Automatic Cost Adjustment Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Never") { Caption = 'Never'; }
    value(1; "Day") { Caption = 'Day'; }
    value(2; "Week") { Caption = 'Week'; }
    value(3; "Month") { Caption = 'Month'; }
    value(4; "Quarter") { Caption = 'Quarter'; }
    value(5; "Year") { Caption = 'Year'; }
    value(6; "Always") { Caption = 'Always'; }
}