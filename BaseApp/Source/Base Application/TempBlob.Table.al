#pragma warning disable AS0018
namespace System.Utilities;

table 99008535 TempBlob
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by BLOB Storage Module.';
    ObsoleteTag = '19.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Blob; BLOB)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#pragma warning restore AS0018

