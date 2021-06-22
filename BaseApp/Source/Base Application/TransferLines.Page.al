page 5749 "Transfer Lines"
{
    Caption = 'Transfer Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the document number that is associated with the line or entry.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that is transferred.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Qty. in Transit"; "Qty. in Transit")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the item that is in transit.';
                }
                field("Outstanding Quantity"; "Outstanding Quantity")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
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
                action("Show Document")
                {
                    ApplicationArea = Location;
                    Caption = 'Show Document';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        TransferHeader: Record "Transfer Header";
                    begin
                        TransferHeader.Get("Document No.");
                        PAGE.Run(PAGE::"Transfer Order", TransferHeader);
                    end;
                }
            }
        }
    }
}

