table 18811 "TCS Nature Of Collection"
{
    Caption = 'TCS Nature Of Collection';
    DataCaptionFields = Code, Description;
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "TCS Nature of Collections";
    DrillDownPageId = "TCS Nature of Collections";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Code"; Code[10])
        {
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Description"; text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; code)
        {
            Clustered = true;
        }
    }
}