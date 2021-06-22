query 65 "Power BI Vend. Item Ledg. Ent."
{
    Caption = 'Vendor Item Ledger Entries';

    elements
    {
        dataitem(Vendor; Vendor)
        {
            column(No; "No.")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Source No." = Vendor."No.";
                DataItemTableFilter = "Source Type" = CONST(Vendor);
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

