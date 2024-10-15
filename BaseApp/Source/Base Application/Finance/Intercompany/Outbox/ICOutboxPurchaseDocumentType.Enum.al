namespace Microsoft.Intercompany.Outbox;

#pragma warning disable AL0659
enum 429 "IC Outbox Purchase Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Order") { Caption = 'Order'; }
    value(1; "Invoice") { Caption = 'Invoice'; }
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    value(3; "Return Order") { Caption = 'Return Order'; }
}