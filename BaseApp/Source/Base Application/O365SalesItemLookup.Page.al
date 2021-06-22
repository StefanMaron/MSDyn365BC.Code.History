page 2112 "O365 Sales Item Lookup"
{
    Caption = 'Price List';
    CardPageID = "O365 Item Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Item;
    SourceTableView = SORTING(Description);

    layout
    {
        area(content)
        {
            repeater(Price)
            {
                Caption = 'Price';
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies what you are selling. You can enter a maximum of 30 characters, both numbers and letters.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '2';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

