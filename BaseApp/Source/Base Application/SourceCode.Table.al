table 230 "Source Code"
{
    Caption = 'Source Code';
    LookupPageID = "Source Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10620; "SAFT Source Code"; Code[9])
        {
            Caption = 'SAF-T Source Code';
            ObsoleteReason = 'Moved to extension';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }
}

