table 2000011 "IBS Contract"
{
    Caption = 'IBS Contract';
    ObsoleteReason = 'Legacy ISABEL';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "Contract ID"; Code[50])
        {
            Caption = 'Contract ID';
        }
        field(23; "Bank ID"; Code[50])
        {
            Caption = 'Bank ID';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract ID")
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}

