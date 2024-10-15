table 5217 "Grounds for Termination"
{
    Caption = 'Grounds for Termination';
    DrillDownPageID = "Grounds for Termination";
    LookupPageID = "Grounds for Termination";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
#pragma warning disable AS0080
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
#pragma warning restore AS0080
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

