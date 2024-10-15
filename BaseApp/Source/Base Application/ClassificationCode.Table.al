table 31040 "Classification Code"
{
    Caption = 'Classification Code';
#if not CLEAN18
    LookupPageID = "Classification Codes";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Classification Type"; Option)
        {
            BlankZero = true;
            Caption = 'Classification Type';
            NotBlank = true;
            OptionCaption = ',CZ-CPA,CZ-CC,DNM';
            OptionMembers = ,"CZ-CPA","CZ-CC",DNM;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Classification Type", "Code")
        {
        }
    }

    fieldgroups
    {
    }
}

