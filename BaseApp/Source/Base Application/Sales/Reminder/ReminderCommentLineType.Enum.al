namespace Microsoft.Sales.Reminder;

enum 299 "Reminder Comment Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Reminder") { Caption = 'Reminder'; }
    value(1; "Issued Reminder") { Caption = 'Issued Reminder'; }
}