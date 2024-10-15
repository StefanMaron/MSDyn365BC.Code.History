table 31062 "Statistic Indication"
{
    Caption = 'Statistic Indication';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            NotBlank = true;
            TableRelation = "Tariff Number";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Full Name"; Text[250])
        {
            Caption = 'Full Name';
            ObsoleteState = Removed;
            ObsoleteReason = 'This field should not be used and will be removed.';
            ObsoleteTag = '20.0';
        }
        field(20; "Full Name ENG"; Text[250])
        {
            Caption = 'Full Name ENG';
            ObsoleteState = Removed;
            ObsoleteReason = 'This field should not be used and will be removed.';
            ObsoleteTag = '20.0';
        }
    }

    keys
    {
        key(Key1; "Tariff No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
