table 18008 "GST Registration Nos."
{
    Caption = 'GST Registration Nos.';
    DataCaptionFields = Code;
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "GST Registration Nos.";
    DrillDownPageId = "GST Registration Nos.";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "State Code"; Code[10])
        {
            Caption = 'State Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = state;
        }
        field(3; "Description"; text[50])
        {
            Caption = 'Description';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Input Service Distributor"; Boolean)
        {
            Caption = 'Input Service Distributor';
            NotBlank = true;
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