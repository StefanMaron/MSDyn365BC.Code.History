tableextension 13666 "Company Information DK" extends "Company Information"
{
    fields
    {
        field(13600; "Bank Creditor No."; Code[8])
        {
            Caption = 'Bank Creditor No.';
            DataClassification = SystemMetadata;
            Numeric = true;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: BankCreditorNo';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}