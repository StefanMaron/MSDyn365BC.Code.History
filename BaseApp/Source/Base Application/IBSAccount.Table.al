table 2000012 "IBS Account"
{
    Caption = 'IBS Account';
    ObsoleteReason = 'Legacy ISABEL';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(21; "Contract ID"; Code[50])
        {
            Caption = 'Contract ID';
        }
        field(22; "Bank ID"; Code[50])
        {
            Caption = 'Bank ID';
        }
        field(23; Account; Code[50])
        {
            Caption = 'Account';
        }
        field(24; "Account Type"; Code[50])
        {
            Caption = 'Account Type';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Account)
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}

