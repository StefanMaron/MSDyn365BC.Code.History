page 7397 "Posted Invt. Pick Lines"
{
    Caption = 'Posted Invt. Pick Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Posted Invt. Pick Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the posted inventory pick line.';
                }
                field("Action Type"; "Action Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the action type for the inventory pick line. For posted inventory pick lines, the action type is always Take, meaning that the items are being taken out of the bin.';
                    Visible = false;
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was picked.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item that was picked.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number for the item that was picked.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number for the item that was picked.';
                    Visible = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expiration date for the item that was picked.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location at which the items were pick.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item that was picked.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity, in the base unit of measure, of the item that was picked.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity per unit of measure of the item that was picked.';
                    Visible = false;
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of destination associated with the posted inventory pick line.';
                    Visible = false;
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number or the code of the customer or vendor linked to the line.';
                    Visible = false;
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the special equipment code for the item that was picked.';
                    Visible = false;
                }
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
                    ApplicationArea = Warehouse;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        PostedInvtPickHeader.Get("No.");
                        PAGE.Run(PAGE::"Posted Invt. Pick", PostedInvtPickHeader);
                    end;
                }
            }
        }
    }

    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
}

