table 11703 "Text-to-Account Mapping Code"
{
    Caption = 'Text-to-Account Mapping Code';
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'The table will no longer be used.';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

