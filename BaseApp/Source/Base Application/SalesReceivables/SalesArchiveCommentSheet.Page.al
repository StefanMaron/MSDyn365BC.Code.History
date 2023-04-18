page 5180 "Sales Archive Comment Sheet"
{
    Caption = 'Comment Sheet';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Comment Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the version number of the archived document.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the document line number of the quote or order to which the comment applies.';
                    Visible = false;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the line number for the comment.';
                }
            }
        }
    }

    actions
    {
    }
}

