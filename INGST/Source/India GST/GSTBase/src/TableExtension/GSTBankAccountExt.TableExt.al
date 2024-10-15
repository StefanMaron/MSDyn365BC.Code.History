tableextension 18000 "GST Bank Account Ext" extends "Bank Account"
{
    fields
    {
        field(18000; "State Code"; code[10])
        {
            Caption = 'State Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "state";
        }
        field(18001; "GST Registration Status"; Enum "Bank Registration Status")
        {
            Caption = 'GST Registration Status';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18002; "GST Registration No."; code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}