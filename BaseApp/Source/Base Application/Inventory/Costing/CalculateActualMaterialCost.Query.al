namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

query 5896 "Calculate Actual Material Cost"
{
    Access = Internal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemLedgEntry; "Item Ledger Entry")
        {
            column(Entry_No_; "Entry No.")
            {

            }
            column(Positive; Positive)
            {

            }
            filter(Entry_Type; "Entry Type")
            {

            }
            filter(Order_No_; "Order No.")
            {

            }
            filter(Order_Type; "Order Type")
            {

            }
            filter(Order_Line_No_; "Order Line No.")
            {

            }

            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Item Ledger Entry No." = ItemLedgEntry."Entry No.";
                SqlJoinType = InnerJoin;

                filter(Value_Entry_Type; "Entry Type")
                {

                }
                filter(Inventoriable; Inventoriable)
                {

                }
                column(Cost_Amount__Actual_; "Cost Amount (Actual)")
                {
                    Method = Sum;
                }
                column(Cost_Amount__Actual___ACY_; "Cost Amount (Actual) (ACY)")
                {
                    Method = Sum;
                }
                column(Cost_Amount__Non_Invtbl__; "Cost Amount (Non-Invtbl.)")
                {
                    Method = Sum;
                }
                column(Cost_Amount__Non_Invtbl___ACY_; "Cost Amount (Non-Invtbl.)(ACY)")
                {
                    Method = Sum;
                }
            }

        }
    }
}