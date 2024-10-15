table 5719 "Nonstock Item Setup"
{
    Caption = 'Nonstock Item Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "No. Format"; Enum "Nonstock Item No. Format")
        {
            Caption = 'No. Format';
        }
        field(3; "No. Format Separator"; Code[1])
        {
            Caption = 'No. Format Separator';
        }
        field(31070; "No. From No. Series"; Boolean)
        {
            Caption = 'No. From No. Series';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
            ObsoleteTag = '18.0';
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

