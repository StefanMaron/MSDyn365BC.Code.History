table 31064 "Intrastat Delivery Group"
{
    Caption = 'Intrastat Delivery Group';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '21.0';

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
