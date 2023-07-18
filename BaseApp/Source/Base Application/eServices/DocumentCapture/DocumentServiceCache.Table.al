table 9551 "Document Service Cache"
{
    DataPerCompany = false;
    Extensible = false;
    ReplicateData = false;
    ObsoleteReason = 'No longer required';
#if not CLEAN23
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
#endif

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