namespace Microsoft.Sales.Reminder;

enum 298 "Reminder Text Position"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Beginning") { Caption = 'Beginning'; }
    value(1; "Ending") { Caption = 'Ending'; }
    value(2; "Email Body") { Caption = 'Email Body'; }
}