table 31095 Commodity
{
    Caption = 'Commodity';
    DataCaptionFields = "Code";
#if CLEAN17
    ObsoleteState = Removed;
#else
    DrillDownPageID = Commodities;
    LookupPageID = Commodities;
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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

