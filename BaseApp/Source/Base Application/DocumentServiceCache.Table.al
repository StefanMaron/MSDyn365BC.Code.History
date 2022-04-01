table 9551 "Document Service Cache"
{
    DataPerCompany = false;
    Extensible = false;
    ReplicateData = false;

    fields
    {
        field(1; "Document Service Id"; Guid)
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Use Cached Token"; Boolean)
        {
            Caption = 'Use Cached Token';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Document Service Id")
        {
            Clustered = true;
        }
    }
}