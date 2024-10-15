namespace Microsoft.Finance.ReceivablesPayables;

enum 426 "Payment Tolerance Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Customer")
    {
        Caption = 'Customer';
    }
    value(1; "Vendor")
    {
        Caption = 'Vendor';
    }
}