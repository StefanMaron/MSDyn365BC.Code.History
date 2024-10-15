namespace Microsoft.Service.Setup;

enum 5932 "Report Selection Usage Service"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Invoice") { Caption = 'Invoice'; }
    value(6; "Credit Memo") { Caption = 'Credit Memo'; }
    value(7; "Contract Quote") { Caption = 'Contract Quote'; }
    value(8; "Contract") { Caption = 'Contract'; }
    value(9; "Service Document - Test") { Caption = 'Service Document - Test'; }
    value(10; "Shipment") { Caption = 'Shipment'; }
    value(15; "Item Worksheet") { Caption = 'Item Worksheet'; }
}
