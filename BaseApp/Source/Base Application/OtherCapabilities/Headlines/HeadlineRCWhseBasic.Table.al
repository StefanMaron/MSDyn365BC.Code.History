namespace System.Visualization;

table 1455 "Headline RC Whse. Basic"
{
    Caption = 'Headline RC Whse. Basic';
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

