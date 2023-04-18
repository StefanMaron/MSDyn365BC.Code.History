page 5777 "Warehouse Comment List"
{
    Caption = 'Comment List';
    DataCaptionExpression = FormCaption();
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Warehouse Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the comment.';
                }
            }
        }
    }

    actions
    {
    }
}

