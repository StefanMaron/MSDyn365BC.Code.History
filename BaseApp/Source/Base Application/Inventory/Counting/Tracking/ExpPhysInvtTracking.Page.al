#if not CLEAN24
namespace Microsoft.Inventory.Counting.Tracking;

page 5895 "Exp. Phys. Invt. Tracking"
{
    Caption = 'Exp. Phys. Invt. Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Exp. Phys. Invt. Tracking";
    ObsoleteReason = 'Replaced by page Exp.Invt.Order.Tracking';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Serial No.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Lot No.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected quantity of Serial No., Lot No. and Package No. that relates to the Base Unit of Measure Code, in the Inventory Order Line.';
                }
                field("Order No"; Rec."Order No")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the Inventory Order.';
                }
                field("Order Line No."; Rec."Order Line No.")
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
#endif
