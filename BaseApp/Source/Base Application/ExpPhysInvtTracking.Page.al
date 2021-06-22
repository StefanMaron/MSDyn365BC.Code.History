page 5895 "Exp. Phys. Invt. Tracking"
{
    Caption = 'Exp. Phys. Invt. Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Exp. Phys. Invt. Tracking";

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
                    ToolTip = 'Specifies the expected quantity of Serial No. and Lot No. that relates to the Base Unit of Measure Code, in the Inventory Order Line.';
                }
                field("Order No"; "Order No")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the Inventory Order.';
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the line number of the Inventory Order Line.';
                }
            }
        }
    }

    actions
    {
    }
}

