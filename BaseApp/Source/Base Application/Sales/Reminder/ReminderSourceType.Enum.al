namespace Microsoft.Sales.Reminder;

enum 296 "Reminder Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; "Customer Ledger Entry") { Caption = 'Customer Ledger Entry'; }
    value(3; "Line Fee") { Caption = 'Line Fee'; }
}