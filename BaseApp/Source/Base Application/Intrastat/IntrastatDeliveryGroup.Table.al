table 31064 "Intrastat Delivery Group"
{
    Caption = 'Intrastat Delivery Group';
#if CLEAN18
    ObsoleteState = Removed;
#else
    DrillDownPageID = "Intrastat Delivery Group";
    LookupPageID = "Intrastat Delivery Group";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

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

