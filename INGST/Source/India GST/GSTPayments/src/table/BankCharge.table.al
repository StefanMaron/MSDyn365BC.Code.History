table 18243 "Bank Charge"
{
    Caption = 'Bank Charge';
    DataCaptionFields = Code, Description;

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Description; text[50])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; Account; code[20])
        {
            Caption = 'Account';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "G/L Account";
        }
        field(4; "Foreign Exchange"; Boolean)
        {
            Caption = 'Foreign Exchange';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "GST Group Code"; code[10])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(6; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(7; "GST Credit"; Enum "GST Credit")
        {
            Caption = 'GST Credit Availment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Exempted; boolean)
        {
            Caption = 'Exempted';
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