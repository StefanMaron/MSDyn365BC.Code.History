#if not CLEAN21
page 2112 "O365 Sales Item Lookup"
{
    Caption = 'Price List';
    CardPageID = "O365 Item Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Item;
    SourceTableView = SORTING(Description);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Price)
            {
                Caption = 'Price';
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies what you are selling. You can enter a maximum of 30 characters, both numbers and letters.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
#endif

