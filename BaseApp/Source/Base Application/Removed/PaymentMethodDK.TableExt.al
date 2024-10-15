tableextension 13677 "Payment Method DK" extends "Payment Method"
{
    fields
    {
        field(13600; "Payment Channel"; Option)
        {
            Caption = 'Payment Channel';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Deprecated.';
            ObsoleteState = Removed;
            OptionCaption = ' ,Payment Slip,Account Transfer,National Clearing,Direct Debit';
            OptionMembers = " ","Payment Slip","Account Transfer","National Clearing","Direct Debit";
            ObsoleteTag = '15.0';
        }
        field(13601; "Payment Type Validation"; Option)
        {
            Caption = 'Payment Type Validation';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: PaymentTypeValidation';
            ObsoleteState = Removed;
            OptionCaption = ' ,FIK 71,FIK 73,FIK 01,FIK 04,Domestic,International';
            OptionMembers = " ","FIK 71","FIK 73","FIK 01","FIK 04",Domestic,International;
            ObsoleteTag = '15.0';
        }
    }
}