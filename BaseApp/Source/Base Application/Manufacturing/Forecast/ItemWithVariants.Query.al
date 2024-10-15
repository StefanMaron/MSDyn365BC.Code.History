namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Inventory.Item;

query 2900 "Item With Variants"
{
    QueryType = Normal;
    ReadState = ReadUncommitted;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Item; Item)
        {
            column(No_; "No.")
            { }
            column(Description; Description)
            { }
            column(Type; Type)
            { }
            dataitem(Item_Variant; "Item Variant")
            {
                DataItemLink = "Item No." = Item."No.";
                column(VariantCode; Code)
                { }
            }
        }
    }
}