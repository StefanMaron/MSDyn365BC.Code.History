page 5702 "Stockkeeping Unit Comment List"
{
    AutoSplitKey = true;
    Caption = 'Stockkeeping Unit Comment List';
    DataCaptionFields = "Location Code", "Item No.", "Variant Code";
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Stockkeeping Unit Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number to which the SKU refers to.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the location code (for example, warehouse of distribution center) to which the SKU applies.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Planning;
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

