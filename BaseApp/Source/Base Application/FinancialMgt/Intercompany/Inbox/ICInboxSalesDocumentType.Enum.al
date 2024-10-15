namespace Microsoft.Intercompany.Inbox;

enum 435 "IC Inbox Sales Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Order") { Caption = 'Order'; }
    value(1; "Invoice") { Caption = 'Invoice'; }
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    value(3; "Return Order") { Caption = 'Return Order'; }
}