page 6507 "Item Tracking List"
{
    Caption = 'Item Tracking List';
    Editable = false;
    PageType = List;
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number of the item that is being handled with the associated document line.';
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last day of the serial/lot number''s warranty.';
                    Visible = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expiration date of the lot or serial number on the item tracking line.';
                    Visible = false;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item that has been reserved in the entry.';
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
    }
}

