namespace Microsoft.Sales.Setup;

enum 9657 "Custom Report Selection Sales"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Confirmation Order") { Caption = 'Confirmation Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Customer Statement") { Caption = 'Customer Statement'; }
    value(5; "Job Quote") { Caption = 'Job Quote'; }
    value(6; "Reminder") { Caption = 'Reminder'; }
    value(7; "Shipment") { Caption = 'Shipment'; }
    value(8; "Pro Forma Invoice") { Caption = 'Pro Forma Invoice'; }
}
