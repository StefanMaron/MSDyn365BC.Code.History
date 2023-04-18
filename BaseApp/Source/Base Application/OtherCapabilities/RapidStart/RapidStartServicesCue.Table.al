table 9061 "RapidStart Services Cue"
{
    Caption = 'RapidStart Services Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Not Started"; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      Status = CONST(" ")));
            Caption = 'Not Started';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "In Progress"; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      Status = CONST("In Progress")));
            Caption = 'In Progress';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; Completed; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      Status = CONST(Completed)));
            Caption = 'Completed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Ignored; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      Status = CONST(Ignored)));
            Caption = 'Ignored';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; Promoted; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      "Promoted Table" = CONST(true)));
            Caption = 'Promoted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; Blocked; Integer)
        {
            CalcFormula = Count ("Config. Line" WHERE("Line Type" = CONST(Table),
                                                      Status = CONST(Blocked)));
            Caption = 'Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
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

