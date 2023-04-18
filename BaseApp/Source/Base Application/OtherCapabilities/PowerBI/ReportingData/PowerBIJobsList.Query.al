query 54 "Power BI Jobs List"
{
    Caption = 'Power BI Jobs List';

    elements
    {
        dataitem(Job; Job)
        {
            column(Job_No; "No.")
            {
            }
            column(Search_Description; "Search Description")
            {
            }
            column(Complete; Complete)
            {
            }
            column(Status; Status)
            {
            }
            dataitem(Job_Ledger_Entry; "Job Ledger Entry")
            {
                DataItemLink = "Job No." = Job."No.";
                column(Posting_Date; "Posting Date")
                {
                }
                column(Total_Cost; "Total Cost")
                {
                }
                column(Entry_No; "Entry No.")
                {
                }
                column(Entry_Type; "Entry Type")
                {
                }
            }
        }
    }
}

