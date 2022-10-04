query 7317 CalcQtyOnBlockedITOnPNQuery
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(Package_No__Information; "Package No. Information")
        {
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Blocked; Blocked) { }
            column(Package_No_; "Package No.") { }

            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Package No." = Package_No__Information."Package No.";
                SqlJoinType = InnerJoin;

                filter(ILE_Item_No_; "Item No.") { }
                filter(ILE_Variant_Code; "Variant Code") { }
                filter(ILE_Location_Code; "Location Code") { }
                column(Quantity; Quantity)
                {
                    Method = Sum;
                }
            }
        }
    }
}