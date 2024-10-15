namespace Microsoft.Manufacturing.Document;

page 99000840 "Prod. Order Rtng. Cmt. Sh."
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionExpression = Rec.Caption();
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Rtng Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual comment text.';
                }
                field("Code"; Rec.Code)
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
        Rec.SetUpNewLine();
    end;
}

