tableextension 18156 "GST Shipping Agent Ext" extends "Shipping Agent"
{
    fields
    {
        field(18141; "GST Registration No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Registration No.';
        }
    }

}