page 99000838 "Prod. Order Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionFields = "Prod. Order No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the comment.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Manufacturing;
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
        SetupNewLine;
    end;
}

