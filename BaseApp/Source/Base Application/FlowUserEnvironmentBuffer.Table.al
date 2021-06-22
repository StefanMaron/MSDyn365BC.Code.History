table 1544 "Flow User Environment Buffer"
{
    Caption = 'Flow User Environment Buffer';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "Environment ID"; Text[50])
        {
            Caption = 'Environment ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Environment Display Name"; Text[100])
        {
            Caption = 'Environment Display Name';
            DataClassification = SystemMetadata;
        }
        field(3; Default; Boolean)
        {
            Caption = 'Default';
            DataClassification = SystemMetadata;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Environment ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

