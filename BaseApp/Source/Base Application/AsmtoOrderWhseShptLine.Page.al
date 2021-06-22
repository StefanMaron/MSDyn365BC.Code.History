page 915 "Asm.-to-Order Whse. Shpt. Line"
{
    Caption = 'Asm.-to-Order Whse. Shpt. Line';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Warehouse Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Lines';
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the warehouse shipment line.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the table that is the source of the receipt line.';
                    Visible = false;
                }
                field("Source Subtype"; "Source Subtype")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the source subtype of the document to which the line relates.';
                    Visible = false;
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field("Source Line No."; "Source Line No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location from which the items on the line are being shipped.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code of the zone where the bin on this shipment line is located.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin in which the items will be placed before shipment.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity that should be shipped.';
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                    Visible = false;
                }
                field("Qty. to Ship"; "Qty. to Ship")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                }
                field("Qty. to Ship (Base)"; "Qty. to Ship (Base)")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity, in base units of measure, that will be shipped when the warehouse shipment is posted.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the related warehouse activity, such as a pick, must be completed to ensure items can be shipped by the shipment date.';
                    Visible = false;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the type of destination associated with the warehouse shipment line.';
                    Visible = false;
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the customer, vendor, or location to which the items should be shipped.';
                    Visible = false;
                }
                field("Assemble to Order"; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the warehouse shipment line is for items that are assembled to a sales order before it is shipped.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

