page 7000025 "BG/PO Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'BG/PO Comment Sheet';
    DataCaptionExpression = Caption;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "BG/PO Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the comment was entered.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment text to include in the comment line for the bill group/payment order.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code identifying this comment line to include in a bill group/payment order.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
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

