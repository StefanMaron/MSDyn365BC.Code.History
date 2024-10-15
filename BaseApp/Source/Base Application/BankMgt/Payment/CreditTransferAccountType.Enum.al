namespace Microsoft.Bank.Payment;

enum 1207 "Credit Transfer Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Customer") { Caption = 'Customer'; }
    value(1; "Vendor") { Caption = 'Vendor'; }
    value(2; "Employee") { Caption = 'Employee'; }
}