namespace Microsoft.Assembly.Comment;

enum 906 "Assembly Comment Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Assembly Order") { Caption = 'Assembly Order'; }
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    value(5; "Posted Assembly") { Caption = 'Posted Assembly'; }
}