table 18814 "TCS Setup"
{
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Tax Type"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Tax Type";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}