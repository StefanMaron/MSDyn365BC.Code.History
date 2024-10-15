namespace Microsoft.Finance.Analysis;

enum 7133 "Analysis Account Source"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "G/L Account") { Caption = 'G/L Account'; }
    value(1; "Cash Flow Account") { Caption = 'Cash Flow Account'; }
}