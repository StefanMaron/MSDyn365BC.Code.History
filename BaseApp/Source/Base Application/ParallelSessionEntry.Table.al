table 491 "Parallel Session Entry"
{
    DataClassification = SystemMetadata;
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034

    fields
    {
        field(1; ID; GUID)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Object ID to Run"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Record ID to Process"; RecordId)
        {
            DataClassification = CustomerContent;
        }
        field(4; "File Exists"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(5; Parameter; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Session ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(7; Processed; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

}