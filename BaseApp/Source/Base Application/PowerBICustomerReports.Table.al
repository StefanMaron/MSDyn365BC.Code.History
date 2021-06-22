table 6310 "Power BI Customer Reports"
{
    Caption = 'Power BI Customer Reports';
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Blob File"; BLOB)
        {
            Caption = 'Blob File';
            DataClassification = SystemMetadata;
        }
        field(3; Name; Text[200])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(4; Version; Integer)
        {
            Caption = 'Version';
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

    fieldgroups
    {
    }
}

