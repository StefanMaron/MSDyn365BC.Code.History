page 620 "IC Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'IC Comment Sheet';
    DataCaptionFields = "Table Name", "Transaction No.", "IC Partner Code";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "IC Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the comment.';
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

