table 58 "Batch Processing Artifact"
{
    Caption = 'Batch Processing Artifact';
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Artifact Type"; enum "Batch Processing Artifact Type")
        {
            Caption = 'Batch Processing Artifact Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Artifact Name"; Text[1024])
        {
            Caption = 'Artifact Name';
            DataClassification = SystemMetadata;
        }
        field(4; "Artifact Value"; Blob)
        {
            Caption = 'Artifact Value';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Artifact Type")
        {
        }
    }

    fieldgroups
    {
    }
}

