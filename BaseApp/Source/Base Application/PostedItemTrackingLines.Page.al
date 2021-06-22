page 6511 "Posted Item Tracking Lines"
{
    Caption = 'Posted Item Tracking Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Item Ledger Entry";

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
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field("Shipped Qty. Not Returned"; "Shipped Qty. Not Returned")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                    Visible = false;
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last day of warranty for the item on the line.';
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last date that the item on the line can be used.';
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

    trigger OnOpenPage()
    var
        CaptionText1: Text[100];
        CaptionText2: Text[100];
    begin
        CaptionText1 := "Item No.";
        if CaptionText1 <> '' then begin
            CaptionText2 := CurrPage.Caption;
            CurrPage.Caption := StrSubstNo(Text001, CaptionText1, CaptionText2);
        end;
    end;

    var
        Text001: Label '%1 - %2', Locked = true;
}

