table 18690 "TDS Nature Of Remittance"
{
    Caption = 'TDS Nature of Remittance';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "TDS Nature of Remittances";
    LookupPageId = "TDS Nature of Remittances";
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