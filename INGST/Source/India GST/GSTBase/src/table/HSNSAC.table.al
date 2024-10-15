table 18009 "HSN/SAC"
{
    Caption = 'HSN/SAC';
    DataCaptionFields = "GST Group Code", Code;
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "GST Group Code"; Code[10])
        {
            Caption = 'GST Group Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(2; "Code"; code[10])
        {
            Caption = 'Code';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(3; "Description"; Text[50])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Type"; enum "GST Goods And Services Type")
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; "GST Group Code", Code)
        {
            Clustered = true;
        }
    }
}