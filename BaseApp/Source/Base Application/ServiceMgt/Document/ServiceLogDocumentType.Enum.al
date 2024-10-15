namespace Microsoft.Service.Document;

enum 5914 "Service Log Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Shipment") { Caption = 'Shipment'; }
    value(5; "Posted Invoice") { Caption = 'Posted Invoice'; }
    value(6; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
}