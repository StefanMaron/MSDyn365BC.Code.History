table 500 "Deposits Page Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Enum "Deposits Page Setup Key")
        {
            DataClassification = SystemMetadata;
        }
        field(2; ObjectId; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
}