namespace Microsoft.CRM.Outlook;

table 1601 "Office Add-in Setup"
{
    Caption = 'Office Add-in Setup';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Office Host Codeunit ID"; Integer)
        {
            Caption = 'Office Host Codeunit ID';
            InitValue = 1633;
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

