namespace Microsoft.Inventory.Comment;

page 5751 "Inventory Comment List"
{
    Caption = 'Comment List';
    DataCaptionFields = "Document Type", "No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Inventory Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies when the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the actual comment text.';
                }
            }
        }
    }

    actions
    {
    }
}

