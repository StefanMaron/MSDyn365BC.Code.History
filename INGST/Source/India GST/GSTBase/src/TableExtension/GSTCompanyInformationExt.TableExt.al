tableextension 18001 "GST Company Information Ext" extends "Company Information"
{
    fields
    {
        field(18000; "GST Registration No."; code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Registration Nos." WHERE("State Code" = FIELD("State Code"));
        }
        field(18001; "ARN No."; code[20])
        {
            Caption = 'ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18002; "Trading Co."; Boolean)
        {
            Caption = 'Trading Co.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}
