table 18013 "Tax Type Setup"
{
    Caption = 'GST Setup';
    DataCaptionFields = Code;
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Code"; Code[10])
        {
            caption = 'Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Tax Type";
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
