namespace Microsoft.Finance.FinancialReports;

enum 334 "Column Layout Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Always") { Caption = 'Always'; }
    value(1; "Never") { Caption = 'Never'; }
    value(2; "When Positive") { Caption = 'When Positive'; }
    value(3; "When Negative") { Caption = 'When Negative'; }
}