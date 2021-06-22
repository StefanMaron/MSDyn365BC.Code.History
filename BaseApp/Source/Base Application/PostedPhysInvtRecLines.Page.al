page 5890 "Posted Phys. Invt. Rec. Lines"
{
    Caption = 'Posted Phys. Invt. Rec. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Record Line";

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
                    ToolTip = 'Specifies the Order No. of the table physical inventory recording line.';
                }
                field("Recording No."; "Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Recording No. of the table physical inventory recording line.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Line No. of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Order Line No. of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Item No. of the table physical inventory recording line.';
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
                    ToolTip = 'Specifies the Description of the table physical inventory recording line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Description 2 of the table physical inventory recording line.';
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
                    ToolTip = 'Specifies the Location Code of the table physical inventory recording line.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Serial No. of the table physical inventory recording line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Lot No. of the table physical inventory recording line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity of the table physical inventory recording line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity (Base) of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Date Recorded"; "Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Date Recorded of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Time Recorded"; "Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Time Recorded of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Person Recorded"; "Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Person Recorded of the table physical inventory recording line.';
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Posted Phys. Invt. Recording";
                    RunPageLink = "Order No." = FIELD("Order No."),
                                  "Recording No." = FIELD("Recording No.");
                    RunPageView = SORTING("Order No.", "Recording No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Show posted inventory count order recording.';
                }
            }
        }
    }
}

