namespace Microsoft.Foundation.Enums;

enum 5400 "Transfer Direction"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; "Outbound") { Caption = 'Outbound'; }
    value(1; "Inbound") { Caption = 'Inbound'; }
}