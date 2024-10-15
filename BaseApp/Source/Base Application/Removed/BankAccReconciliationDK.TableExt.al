tableextension 13663 "Bank Acc. Reconciliation DK" extends "Bank Acc. Reconciliation"
{
    fields
    {
        field(13600; "FIK Payment Reconciliation"; Boolean)
        {
            Caption = 'FIK Payment Reconciliation';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: FIKPaymentReconciliation';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}