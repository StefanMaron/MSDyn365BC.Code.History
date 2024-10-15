tableextension 18014 "GST Tax Accounting Period Ext" extends "Tax Accounting Period"
{
    fields
    {
        field(18000; "Credit Memo Locking Date"; date)
        {
            Caption = 'Credit Memo Locking Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18001; "Annual Return Filed Date"; date)
        {
            Caption = 'Annual Return Filed Date';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}