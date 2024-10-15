namespace Microsoft.Sales.Reminder;

enum 6753 "Reminder Action Schedule"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Manual") { Caption = 'Manual'; }
    value(1; "Weekly") { Caption = 'Weekly'; }
    value(2; "Monthly") { Caption = 'Monthly'; }
    value(3; "Custom schedule") { Caption = 'Custom schedule'; }
}