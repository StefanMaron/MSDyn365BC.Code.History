query 250 "G/L Entry Dimensions"
{
    Caption = 'G/L Entry Dimensions';

    elements
    {
        dataitem(G_L_Entry; "G/L Entry")
        {
            filter(G_L_Account_No; "G/L Account No.")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            filter(Business_Unit_Code; "Business Unit Code")
            {
            }
            filter(Global_Dimension_1_Code; "Global Dimension 1 Code")
            {
            }
            filter(Global_Dimension_2_Code; "Global Dimension 2 Code")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            column(Sum_Amount; Amount)
            {
                Method = Sum;
            }
            column(Sum_Debit_Amount; "Debit Amount")
            {
                Method = Sum;
            }
            column(Sum_Credit_Amount; "Credit Amount")
            {
                Method = Sum;
            }
        }
    }
}

