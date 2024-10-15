table 11702 "Bank Pmt. Appl. Rule Code"
{
    Caption = 'Bank Pmt. Appl. Rule Code';
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
        field(10; "Match Related Party Only"; Boolean)
        {
            Caption = 'Match Related Party Only';
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

