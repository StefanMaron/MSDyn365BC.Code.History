namespace Microsoft.Service.Item;

enum 5944 "Service Item Log Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Quote") { Caption = 'Quote'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Contract") { Caption = 'Contract'; }
}