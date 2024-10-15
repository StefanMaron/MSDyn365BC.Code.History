namespace Microsoft.Foundation.Enums;

enum 364 "Analysis Rounding Factor"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "None") { Caption = 'None'; }
    value(1; "1") { Caption = '1'; }
    value(2; "1000") { Caption = '1000'; }
    value(3; "1000000") { Caption = '1000000'; }
}