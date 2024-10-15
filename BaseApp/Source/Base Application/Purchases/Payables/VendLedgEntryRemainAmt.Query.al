namespace Microsoft.Purchases.Payables;

query 25 "Vend. Ledg. Entry Remain. Amt."
{
    Caption = 'Vend. Ledg. Entry Remain. Amt.';

    elements
    {
        dataitem(Vendor_Ledger_Entry; "Vendor Ledger Entry")
        {
            filter(Document_Type; "Document Type")
            {
            }
            filter(IsOpen; Open)
            {
            }
            filter(Due_Date; "Due Date")
            {
            }
            filter(Vendor_No; "Vendor No.")
            {
            }
            filter(Vendor_Posting_Group; "Vendor Posting Group")
            {
            }
            column(Sum_Remaining_Amt_LCY; "Remaining Amt. (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

