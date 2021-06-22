page 5893 "Phys. Invt. Item Track. List"
{
    Caption = 'Phys. Invt. Item Track. List';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Item Tracking Information';
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
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
                    ToolTip = 'Specifies the location of the traced item.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the location of the traced item.';
                }
                field(Positive; Positive)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the difference is positive.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies how many of the base unit of measure are contained in one unit of the item.';
                    Visible = false;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of item, in the base unit of measure, to be handled in a warehouse activity.';
                    Visible = false;
                }
                field("Qty. to Invoice (Base)"; "Qty. to Invoice (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity, in the base unit of measure, that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
                    Visible = false;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Reservation Status"; "Reservation Status")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the status of the reservation.';
                }
                field("Created By"; "Created By")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the user who created the traced record.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Created By");
                    end;
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies when the traced record was created.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number that is assigned to the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ItemTracking)
            {
                Caption = 'Item &Tracking Information';
                Image = Line;
                action("Serial No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'Show Serial No. Information Card';
                }
                action("Lot No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'Show Lot No. Information Card';
                }
            }
        }
    }
}

