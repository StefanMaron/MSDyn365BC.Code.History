page 5896 "Posted Exp. Phys. Invt. Track"
{
    Caption = 'Posted Exp. Phys. Invt. Track';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Exp. Phys. Invt. Track";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Serial No.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Lot No.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected quantity of Serial No. and Lot No. that relates to the Base Unit of Measure Code, in the Posted Inventory Order Line.';
                }
                field("Order No"; "Order No")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the document number of the Posted Inventory Order.';
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the line number of the Posted Inventory Order Line.';
                }
            }
        }
    }

    actions
    {
    }
}

