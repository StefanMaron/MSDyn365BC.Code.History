query 1252 "Bank Rec. Match Candidates"
{
    Caption = 'Bank Rec. Match Candidates';

    elements
    {
        dataitem(Bank_Acc_Reconciliation_Line; "Bank Acc. Reconciliation Line")
        {
            DataItemTableFilter = Difference = FILTER(<> 0), Type = FILTER(= "Bank Account Ledger Entry");
            column(Rec_Line_Bank_Account_No; "Bank Account No.")
            {
            }
            column(Rec_Line_Statement_No; "Statement No.")
            {
            }
            column(Rec_Line_Statement_Line_No; "Statement Line No.")
            {
            }
            column(Rec_Line_Transaction_Date; "Transaction Date")
            {
            }
            column(Rec_Line_Description; Description)
            {
            }
            column(Rec_Line_RltdPty_Name; "Related-Party Name")
            {
            }
            column(Rec_Line_Transaction_Info; "Additional Transaction Info")
            {
            }
            column(Rec_Line_Statement_Amount; "Statement Amount")
            {
            }
            column(Rec_Line_Applied_Amount; "Applied Amount")
            {
            }
            column(Rec_Line_Difference; Difference)
            {
            }
            column(Rec_Line_Type; Type)
            {
            }
            column(Rec_Line_Applied_Entries; "Applied Entries")
            {
            }
            dataitem(Bank_Account_Ledger_Entry; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = Bank_Acc_Reconciliation_Line."Bank Account No.";
                DataItemTableFilter = "Remaining Amount" = FILTER(<> 0), Open = CONST(true), "Statement Status" = FILTER(Open), Reversed = CONST(false);
                column(Entry_No; "Entry No.")
                {
                }
                column(Bank_Account_No; "Bank Account No.")
                {
                }
                column(Posting_Date; "Posting Date")
                {
                }
                column(Document_No; "Document No.")
                {
                }
                column(Description; Description)
                {
                }
                column(Remaining_Amount; "Remaining Amount")
                {
                }
                column(Bank_Ledger_Entry_Open; Open)
                {
                }
                column(Statement_Status; "Statement Status")
                {
                }
                column(External_Document_No; "External Document No.")
                {
                }
            }
        }
    }
}

