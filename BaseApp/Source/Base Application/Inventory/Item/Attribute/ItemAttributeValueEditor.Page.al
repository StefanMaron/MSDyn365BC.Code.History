namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;

page 7510 "Item Attribute Value Editor"
{
    Caption = 'Item Attribute Values';
    PageType = StandardDialog;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            part(ItemAttributeValueList; "Item Attribute Value List")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.ItemAttributeValueList.PAGE.LoadAttributes(Rec."No.");
    end;
}

