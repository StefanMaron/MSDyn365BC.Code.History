tableextension 18157 "GST Ship-to Address Ext" extends "Ship-to Address"
{
    fields
    {
        field(18141; State; code[10])
        {
            Caption = 'State';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
        }
        field(18142; Consignee; Boolean)
        {
            Caption = 'Consignee';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18143; "GST Registration No."; code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18144; "ARN No."; code[20])
        {
            Caption = 'ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}