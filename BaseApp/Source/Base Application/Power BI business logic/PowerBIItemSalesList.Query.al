query 57 "Power BI Item Sales List"
{
    Caption = 'Power BI Item Sales List';

    elements
    {
        dataitem(Item; Item)
        {
            column(Item_No; "No.")
            {
            }
            column(Search_Description; "Search Description")
            {
            }
            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                DataItemTableFilter = "Item Ledger Entry Type" = CONST(Sale);
                column(Sales_Post_Date; "Posting Date")
                {
                }
                column(Sold_Quantity; "Invoiced Quantity")
                {
                    ReverseSign = true;
                }
                column(Sales_Entry_No; "Entry No.")
                {
                }
            }
        }
    }
}

