page 18935 "Posted Narration"
{
    Caption = 'Posted Narration';
    PageType = List;
    SourceTable = "Posted Narration";
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Document Type"; "Document Type")
                {
                    Caption = 'Document Type';
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    Caption = 'Document No.';
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; "Posting Date")
                {
                    Caption = 'Posting Date';
                    ApplicationArea = Basic, Suite;
                }
                field(Narration; Narration)
                {
                    Caption = 'Narration';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}