page 5882 "Phys. Invt. Recording Lines"
{
    Caption = 'Phys. Invt. Recording Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Phys. Invt. Record Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the order number.';
                }
                field("Recording No."; "Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a number that is assigned to the physical inventory recording.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Line No. of the linked physical inventory order line.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was counted when taking the physical inventory.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the additional description of the item.';
                    Visible = false;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location where the item was counted during taking the physical inventory.';
                }
                field("Use Item Tracking"; "Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if it is necessary to record the item using serial numbers or lot numbers.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the serial number of the entered item.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number of the entered item.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item of the physical inventory recording line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field(Recorded; Recorded)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if a value was entered in Quantity of the physical inventory recording line.';
                }
                field("Date Recorded"; "Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                    Visible = false;
                }
                field("Time Recorded"; "Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when the physical inventory was taken.';
                    Visible = false;
                }
                field("Person Recorded"; "Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who performed the physical inventory.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Phys. Inventory Recording";
                    RunPageLink = "Order No." = FIELD("Order No."),
                                  "Recording No." = FIELD("Recording No.");
                    RunPageView = SORTING("Order No.", "Recording No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Show inventory count recording.';
                }
            }
        }
    }
}

