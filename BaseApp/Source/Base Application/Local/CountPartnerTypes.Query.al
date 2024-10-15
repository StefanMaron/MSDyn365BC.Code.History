query 11401 CountPartnerTypes
{
    Caption = 'CountPartnerTypes';

    elements
    {
        dataitem(Proposal_Line; "Proposal Line")
        {
            column(Our_Bank_No; "Our Bank No.")
            {
            }
            dataitem(Transaction_Mode; "Transaction Mode")
            {
                DataItemLink = Code = Proposal_Line."Transaction Mode";
                DataItemTableFilter = "Account Type" = CONST(Customer);
                column(Partner_Type; "Partner Type")
                {
                }
                column(Count_)
                {
                    Method = Count;
                }
            }
        }
    }
}

