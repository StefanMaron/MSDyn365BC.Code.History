query 135 "OCR Vendor Bank Accounts"
{
    Caption = 'OCR Vendor Bank Accounts';

    elements
    {
        dataitem(Vendor_Bank_Account; "Vendor Bank Account")
        {
            column(Name; Name)
            {
            }
            column(Bank_Branch_No; "Bank Branch No.")
            {
            }
            column(Bank_Account_No; "Bank Account No.")
            {
            }
            column(SWIFT_Code; "SWIFT Code")
            {
            }
            column(IBAN; IBAN)
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "No." = Vendor_Bank_Account."Vendor No.";
                SqlJoinType = InnerJoin;
                column(Id; SystemId)
                {
                }
                column(No; "No.")
                {
                }
                column(ModifiedAt; SystemModifiedAt)
                {
                }
            }
        }
    }
}

