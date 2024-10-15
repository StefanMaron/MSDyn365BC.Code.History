table 18004 "GST Group"
{
    Caption = 'GST Group';
    DataCaptionFields = Code, Description;
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "GST Place Of Supply"; enum "GST Place Of Supply")
        {
            Caption = 'GST Place Of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Description"; Code[250])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Reverse Charge"; Boolean)
        {
            Caption = 'Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}