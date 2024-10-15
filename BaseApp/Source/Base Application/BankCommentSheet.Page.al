page 10130 "Bank Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Bank Comment Sheet';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Bank Comment Line";

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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine;
    end;
}

