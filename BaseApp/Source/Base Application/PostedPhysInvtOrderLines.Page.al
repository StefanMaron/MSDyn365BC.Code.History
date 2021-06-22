page 5886 "Posted Phys. Invt. Order Lines"
{
    Caption = 'Posted Phys. Invt. Order Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Order Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the physical inventory order that the line exists on.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line on the physical inventory order line.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item on the physical inventory order line.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the variant of the item on the physical inventory order line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item on the physical inventory order line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an additional part of the description of the item on the physical inventory order line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location of the item on the physical inventory order line.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure, such as bottle or piece, that is used for the item on the physical inventory order line.';
                    Visible = false;
                }
                field("Base Unit of Measure Code"; "Base Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the base unit of measure that is set up for the item on the physical inventory order line.';
                }
                field("Qty. Expected (Base)"; "Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure on the physical inventory order line.';
                }
                field("Qty. Recorded (Base)"; "Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Qty. Recorded (Base) of the physical inventory order line.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Entry Type of the physical inventory order line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in the base unit of measure on the physical inventory order line.';
                }
                field("No. Finished Rec.-Lines"; "No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many finished physical inventory recording lines exist for the physical inventory order line.';
                }
                field("Recorded Without Order"; "Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that no physical inventory order lines existed for the recorded item, and that the line was generated based on the related recording.';
                    Visible = false;
                }
                field("Unit Amount"; "Unit Amount")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the sum of unit costs of the item quantity on the line.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the cost of one unit of the item on the line.';
                    Visible = false;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item on the physical inventory order line.';
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
                    RunObject = Page "Posted Phys. Invt. Order";
                    RunPageLink = "No." = FIELD("Document No.");
                    RunPageView = SORTING("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';
                }
            }
        }
    }
}

