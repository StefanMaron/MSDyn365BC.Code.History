namespace Microsoft.Sales.Document;

page 6670 "Returns-Related Documents"
{
    Caption = 'Returns-Related Documents';
    PageType = List;
    SourceTable = "Returns-Related Document";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                    ObsoleteReason = 'Replaced by "Show Document" action';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnAction()
                    begin
                        Rec.ShowDocumentCard();
                    end;
                }
                action(ShowDocument)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocumentCard();
                    end;
                }
            }
        }
    }
}

