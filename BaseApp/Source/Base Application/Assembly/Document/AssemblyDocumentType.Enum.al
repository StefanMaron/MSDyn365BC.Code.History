namespace Microsoft.Assembly.Document;

enum 901 "Assembly Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
}