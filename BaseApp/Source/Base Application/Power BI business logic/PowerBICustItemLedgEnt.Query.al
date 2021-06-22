query 61 "Power BI Cust. Item Ledg. Ent."
{
    Caption = 'Power BI Cust. Item Ledg. Ent.';

    elements
    {
        dataitem(Customer; Customer)
        {
            column(No; "No.")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Source No." = Customer."No.";
                DataItemTableFilter = "Source Type" = CONST(Customer);
                column(Item_No; "Item No.")
                {
                }
                column(Quantity; Quantity)
                {
                }
            }
        }
    }
}

