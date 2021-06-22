page 505 "Reservation Summary"
{
    Caption = 'Reservation Summary';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Entry Summary";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Summary Type"; "Summary Type")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies which type of line or entry is summarized in the entry summary.';
                }
                field("Total Quantity"; "Total Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';
                }
                field("Total Reserved Quantity"; "Total Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the total quantity of the relevant item that is reserved on documents or entries of the type on the line.';
                }
                field("Total Available Quantity"; "Total Available Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity available for the user to request, in entries of the type on the line.';
                }
                field("Current Reserved Quantity"; "Current Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of items in the entry that are reserved for the line that the Reservation window is opened from.';
                }
            }
        }
    }

    actions
    {
    }
}

