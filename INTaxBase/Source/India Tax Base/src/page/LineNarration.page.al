page 18551 "Line Narration"
{
    AutoSplitKey = true;
    Caption = 'Line Narration';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Gen. Journal Narration";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            field("Document No."; "Document No.")
            {
                Editable = false;
                ApplicationArea = Basic, Suite;
                Caption = 'Document No.';
            }
            repeater(Control1500000)
            {
                field(Narration; Narration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Narration';
                }
            }
        }
    }
}