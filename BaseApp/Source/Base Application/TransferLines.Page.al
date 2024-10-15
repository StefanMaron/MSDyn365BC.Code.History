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
                field("Return Order"; "Return Order")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies if a component of the transfer line is a return.';
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that you are transferring items from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that you are transferring items to.';
                }
                field("Qty. in Transit"; "Qty. in Transit")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the item that is in transit.';
                }
                field("Quantity Received"; "Quantity Received")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of items that have been received.';
                }
                field("Outstanding Quantity"; "Outstanding Quantity")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped.';
                }
                field("WIP Qty. Shipped"; "WIP Qty. Shipped")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of work in process (WIP) items that have shipped on a subcontractor transfer order.';
                }
                field("WIP Outstanding Qty."; "WIP Outstanding Qty.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of work in process (WIP) items that will be shipped on a subcontractor transfer order.';
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
                    ToolTip = 'Show the related source document.';

                    trigger OnAction()
                    var
                        TransferHeader: Record "Transfer Header";
                    begin
                        TransferHeader.Get("Document No.");
                        TransferHeader.CalcFields("Subcontracting Order");
                        if TransferHeader."Subcontracting Order" then
                            PAGE.Run(PAGE::"Subcontr. Transfer Order", TransferHeader)
                        else
                            PAGE.Run(PAGE::"Transfer Order", TransferHeader);
                    end;
                }
            }
        }
    }
}

