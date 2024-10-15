namespace Microsoft.Finance.Deferral;

enum 1700 "Deferral Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Straight-Line") { Caption = 'Straight-Line'; }
    value(1; "Equal per Period") { Caption = 'Equal per Period'; }
    value(2; "Days per Period") { Caption = 'Days per Period'; }
    value(3; "User-Defined") { Caption = 'User-Defined'; }
}