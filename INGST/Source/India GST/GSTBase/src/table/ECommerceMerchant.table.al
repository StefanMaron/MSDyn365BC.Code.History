table 18015 "E-Commerce Merchant"
{
    Caption = 'E-Commerce Merchant';
    DataCaptionFields = "Customer No.", "Merchant Id";

    fields
    {
        field(1; "Customer No."; code[10])
        {
            Caption = 'Customer No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Customer;
            NotBlank = true;
        }
        field(2; "Merchant Id"; code[30])
        {
            Caption = 'Merchant Id';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(3; "Company GST Reg. No."; code[20])
        {
            Caption = 'Company GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Registration Nos.";
        }
    }
    keys
    {
        key(PK; "Customer No.", "Merchant Id")
        {
            Clustered = true;
        }
    }
}
