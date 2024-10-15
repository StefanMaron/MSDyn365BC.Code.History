query 9153 "Non-Inventory Telemetry"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Item; Item)
        {
            filter(Type; Type)
            {
                ColumnFilter = Type = filter(<> Inventory);
            }

            column(NoOfNonInventory)
            {
                Method = Count;
            }

            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                SqlJoinType = InnerJoin;

                filter(Location_Code; "Location Code")
                {
                }
            }
        }
    }
}