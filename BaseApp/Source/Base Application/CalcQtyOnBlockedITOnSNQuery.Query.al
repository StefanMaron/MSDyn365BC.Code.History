query 7315 CalcQtyOnBlockedITOnSNQuery
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(Serial_No__Information; "Serial No. Information")
        {
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Blocked; Blocked) { }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Serial No." = Serial_No__Information."Serial No.";
                SqlJoinType = InnerJoin;

                filter(ILE_Item_No_; "Item No.") { }
                filter(ILE_Variant_Code; "Variant Code") { }
                filter(ILE_Location_Code; "Location Code") { }
                column(Lot_No_; "Lot No.") { }
                column(Package_No_; "Package No.") { }

                column(Quantity; Quantity)
                {
                    Method = Sum;
                }
            }
        }
    }
}