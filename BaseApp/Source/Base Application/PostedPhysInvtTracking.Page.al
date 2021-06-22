page 5894 "Posted Phys. Invt. Tracking"
{
    Caption = 'Posted Phys. Invt. Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Tracking";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the appropriate field of the physical inventory tracking line.';
                }
                field("Item Tracking No."; "Item Tracking No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
            }
        }
    }

    actions
    {
    }
}

