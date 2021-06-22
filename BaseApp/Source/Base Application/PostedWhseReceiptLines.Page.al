page 7363 "Posted Whse. Receipt Lines"
{
    Caption = 'Posted Whse. Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Whse. Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                    Visible = false;
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Source Line No."; "Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the items were received.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone on this posted receipt line.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was received and posted.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item in the line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a second description of the item in the line, if any.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that was received.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that was received, in the base unit of measure.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure, in the unit of measure, specified for the item on the line.';
                }
                field("Posted Source Document"; "Posted Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of posted source document referred to by the receipt line.';
                }
                field("Posted Source No."; "Posted Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the document number of the posted source document.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date that the receipt line was due.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line in the posted receipt.';
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
                action("Show Posted Whse. Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Posted Whse. Document';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the related completed warehouse shipment.';

                    trigger OnAction()
                    var
                        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
                    begin
                        PostedWhseRcptHeader.Get("No.");
                        PAGE.Run(PAGE::"Posted Whse. Receipt", PostedWhseRcptHeader);
                    end;
                }
            }
        }
    }
}

