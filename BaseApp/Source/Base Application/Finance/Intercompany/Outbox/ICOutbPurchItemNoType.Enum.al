namespace Microsoft.Intercompany.Outbox;

enum 439 "IC Outb. Purch. Item No. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Internal No.") { Caption = 'Order'; }
    value(1; "Common Item No.") { Caption = 'Common Item No.'; }
    value(2; "Cross Reference") { Caption = 'Item Reference'; }
    value(3; "Vendor Item No.") { Caption = 'Vendor Item No.'; }
}