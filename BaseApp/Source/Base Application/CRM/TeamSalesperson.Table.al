table 5084 "Team Salesperson"
{
    Caption = 'Team Salesperson';

    fields
    {
        field(1; "Team Code"; Code[10])
        {
            Caption = 'Team Code';
            NotBlank = true;
            TableRelation = Team;
        }
        field(2; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            NotBlank = true;
            TableRelation = "Salesperson/Purchaser";
        }
        field(3; "Team Name"; Text[50])
        {
            CalcFormula = Lookup (Team.Name WHERE(Code = FIELD("Team Code")));
            Caption = 'Team Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Salesperson Name"; Text[50])
        {
            CalcFormula = Lookup ("Salesperson/Purchaser".Name WHERE(Code = FIELD("Salesperson Code")));
            Caption = 'Salesperson Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Team Code", "Salesperson Code")
        {
            Clustered = true;
        }
        key(Key2; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
    }
}

