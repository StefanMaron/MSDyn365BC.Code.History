tableextension 13701 "Payment Export Data DK" extends "Payment Export Data"
{
    fields
    {
        field(13650; "Recipient Giro Acc. No."; Code[8])
        {
            Caption = 'Recipient Giro Acc. No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: RecipientGiroAccNo';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}