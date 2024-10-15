tableextension 18016 "GST Customer Ext" extends Customer
{
    fields
    {
        field(18000; "GST Registration No."; code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18001; "GST Registration Type"; Enum "GST Registration Type")
        {
            Caption = 'GST Registration Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18002; "GST Customer Type"; Enum "GST Customer Type")
        {
            Caption = 'GST Customer Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18003; "E-Commerce Operator"; Boolean)
        {
            Caption = 'E-Commerce Operator';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18004; "ARN No."; Code[20])
        {
            Caption = 'ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}