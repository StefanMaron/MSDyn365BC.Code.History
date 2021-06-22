query 58 "Power BI GL Budgeted Amount"
{
    Caption = 'Power BI GL Budgeted Amount';

    elements
    {
        dataitem(G_L_Account; "G/L Account")
        {
            column(GL_Account_No; "No.")
            {
            }
            column(Name; Name)
            {
            }
            column(Account_Type; "Account Type")
            {
                ColumnFilter = Account_Type = CONST(Posting);
            }
            column(Debit_Credit; "Debit/Credit")
            {
            }
            dataitem(G_L_Budget_Entry; "G/L Budget Entry")
            {
                DataItemLink = "G/L Account No." = G_L_Account."No.";
                column(Amount; Amount)
                {
                }
                column(Date; Date)
                {
                }
            }
        }
    }
}

