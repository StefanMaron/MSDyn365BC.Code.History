namespace Microsoft.Sales.Receivables;

query 1310 "Cust. Ledg. Entry Sales"
{
    Caption = 'Cust. Ledg. Entry Sales';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            filter(Document_Type; "Document Type")
            {
            }
            filter(IsOpen; Open)
            {
            }
            filter(Customer_No; "Customer No.")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            column(Sum_Sales_LCY; "Sales (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

