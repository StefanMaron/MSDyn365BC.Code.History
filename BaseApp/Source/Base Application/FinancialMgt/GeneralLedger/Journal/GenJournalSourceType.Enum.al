namespace Microsoft.Finance.GeneralLedger.Journal;

enum 82 "Gen. Journal Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Customer") { Caption = 'Customer'; }
    value(2; "Vendor") { Caption = 'Vendor'; }
    value(3; "Bank Account") { Caption = 'Bank Account'; }
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
    value(5; "IC Partner") { Caption = 'IC Partner'; }
    value(6; "Employee") { Caption = 'Employee'; }
}