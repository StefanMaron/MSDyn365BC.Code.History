query 7345 "Avail Qty. (Base) In QC Bins"
{
    Caption = 'Avail Qty. (Base) In QC Bins';

    elements
    {
        dataitem(Location; Location)
        {
            DataItemTableFilter = "Directed Put-away and Pick" = CONST(true);
            dataitem(Warehouse_Entry; "Warehouse Entry")
            {
                DataItemLink = "Location Code" = Location.Code;
                SqlJoinType = InnerJoin;
                column(Location_Code; "Location Code")
                {
                }
                filter(Item_No; "Item No.")
                {
                }
                filter(Variant_Code; "Variant Code")
                {
                }
                column(Bin_Type_Code; "Bin Type Code")
                {
                }
                column(Sum_Qty_Base; "Qty. (Base)")
                {
                    ColumnFilter = Sum_Qty_Base = FILTER(> 0);
                    Method = Sum;
                }
                dataitem(Bin_Type; "Bin Type")
                {
                    DataItemLink = Code = Warehouse_Entry."Bin Type Code";
                    SqlJoinType = InnerJoin;
                    DataItemTableFilter = Receive = CONST(false), Ship = CONST(false), Pick = CONST(false);
                }
            }
        }
    }
}

