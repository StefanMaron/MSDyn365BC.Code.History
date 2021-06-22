query 1311 "Top 10 Customer Sales"
{
    Caption = 'Top 10 Customer Sales';
    OrderBy = Descending(Sum_Sales_LCY);
    TopNumberOfRows = 10;

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            filter(Posting_Date; "Posting Date")
            {
            }
            column(Customer_No; "Customer No.")
            {
            }
            column(Sum_Sales_LCY; "Sales (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

