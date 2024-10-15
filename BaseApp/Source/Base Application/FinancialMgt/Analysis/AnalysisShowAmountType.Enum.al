namespace Microsoft.Finance.Analysis;

enum 747 "Analysis Show Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Actual Amounts") { Caption = 'Actual Amounts'; }
    value(1; "Budgeted Amounts") { Caption = 'Budgeted Amounts'; }
    value(2; "Variance") { Caption = 'Variance'; }
    value(3; "Variance%") { Caption = 'Variance%'; }
    value(4; "Index%") { Caption = 'Index%'; }
}