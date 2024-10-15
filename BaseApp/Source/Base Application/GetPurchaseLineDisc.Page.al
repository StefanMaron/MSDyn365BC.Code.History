page 7189 "Get Purchase Line Disc."
{
    Caption = 'Get Purchase Line Disc.';
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Line Discount";

    layout
    {
        area(content)
        {
            repeater(Control1102628000)
            {
                ShowCaption = false;
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the vendor who offers the line discount on the item.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the purchase line discount price.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item that the purchase line discount applies to.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; "Minimum Quantity")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy from the vendor in order to receive the purchase line discount.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount percentage to use to calculate the purchase line discount.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date from which the purchase line discount is valid.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date to which the purchase line discount is valid.';
                }
            }
        }
    }

    actions
    {
    }
}

