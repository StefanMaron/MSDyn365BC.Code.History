namespace System.Environment;

table 6060 "Hybrid Deployment Setup"
{
    Caption = 'Hybrid Deployment Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Handler Codeunit ID"; Integer)
        {
            Caption = 'Handler Codeunit ID';
            DataClassification = SystemMetadata;
            InitValue = 6061;
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

