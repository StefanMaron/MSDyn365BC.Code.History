page 7010 "Get Price Line"
{
    Caption = 'Get Price Line';
    Editable = false;
    PageType = List;
    SourceTable = "Price List Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of price, either sale or purchase.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of the source that offers the price on the asset.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the customer or vendor who offers the line discount on the asset.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the price.';
                    Visible = false;
                }
                field("Asset No."; "Asset No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the asset that the price applies to.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; "Minimum Quantity")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy or sale in order to get the price.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the price of one unit of the selected asset.';
                }
                field("Direct Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cost of one unit of the selected asset.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date from which the purchase price is valid.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date to which the purchase price is valid.';
                }
            }
        }
    }

    actions
    {
    }
}

