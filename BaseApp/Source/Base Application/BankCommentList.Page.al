page 10131 "Bank Comment List"
{
    Caption = 'Bank Comment List';
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the number of the account, bank account, customer, vendor or item to which the comment applies.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

