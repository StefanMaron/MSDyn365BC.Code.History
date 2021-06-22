table 62 "Record Export Buffer"
{
    Caption = 'Record Export Buffer';
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; RecordID; RecordID)
        {
            Caption = 'RecordID';
            DataClassification = SystemMetadata;
        }
        field(3; ServerFilePath; Text[250])
        {
            Caption = 'ServerFilePath';
            DataClassification = SystemMetadata;
        }
        field(4; ClientFileName; Text[250])
        {
            Caption = 'ClientFileName';
            DataClassification = SystemMetadata;
        }
        field(5; ZipFileName; Text[250])
        {
            Caption = 'ZipFileName';
            DataClassification = SystemMetadata;
        }
        field(6; "Electronic Document Format"; Code[20])
        {
            Caption = 'Electronic Document Format';
            DataClassification = SystemMetadata;
            TableRelation = "Electronic Document Format";
        }
        field(7; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            DataClassification = SystemMetadata;
            TableRelation = "Document Sending Profile";
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

