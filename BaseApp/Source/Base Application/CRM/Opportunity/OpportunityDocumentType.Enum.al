namespace Microsoft.CRM.Opportunity;

enum 5096 "Opportunity Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Quote") { Caption = 'Quote'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Posted Invoice") { Caption = 'Posted Invoice'; }
}