namespace Microsoft.Finance.Dimension;

table 353 "Dimension ID Buffer"
{
    Caption = 'Dimension ID Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Parent ID"; Integer)
        {
            Caption = 'Parent ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Dimension Value"; Code[20])
        {
            Caption = 'Dimension Value';
            DataClassification = SystemMetadata;
        }
        field(4; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Parent ID", "Dimension Code", "Dimension Value")
        {
            Clustered = true;
        }
        key(Key2; ID)
        {
        }
    }

    fieldgroups
    {
    }
}

