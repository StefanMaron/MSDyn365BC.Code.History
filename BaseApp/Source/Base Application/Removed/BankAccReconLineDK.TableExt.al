tableextension 13664 "Bank Acc. Recon. Line DK" extends "Bank Acc. Reconciliation Line"
{
    fields
    {
        field(13600; "Payment Reference"; Code[20])
        {
            Caption = 'Payment Reference';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: PaymentReference';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}