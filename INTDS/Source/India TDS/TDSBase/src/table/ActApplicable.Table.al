table 18686 "Act Applicable"
{
    Caption = 'Act Applicable';
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "Act Applicable";
    DrillDownPageId = "Act Applicable";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
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