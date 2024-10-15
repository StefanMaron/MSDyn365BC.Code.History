namespace System.Visualization;

table 1457 "Headline RC Whse. Worker WMS"
{
    Caption = 'Headline RC Whse. Worker WMS';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced with "RC Headlines User Data" table';
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[10])
        {
            Caption = 'Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Workdate for computations"; Date)
        {
            Caption = 'Workdate for computations';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

}

