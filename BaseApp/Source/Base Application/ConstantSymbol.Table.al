table 11701 "Constant Symbol"
{
    Caption = 'Constant Symbol';
#if CLEAN18
    ObsoleteState = Removed;
#else
    LookupPageID = "Constant Symbols";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            CharAllowed = '09';
            NotBlank = true;
            Numeric = true;
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

