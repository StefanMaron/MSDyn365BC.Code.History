table 5202 Qualification
{
    Caption = 'Qualification';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = Qualifications;
    LookupPageID = Qualifications;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Qualified Employees"; Boolean)
        {
            CalcFormula = Exist ("Employee Qualification" WHERE("Qualification Code" = FIELD(Code),
                                                                "Employee Status" = CONST(Active)));
            Caption = 'Qualified Employees';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14700; "OKIN Group"; Code[10])
        {
            Caption = 'OKIN Group';
            TableRelation = "Classificator OKIN" WHERE(Code = CONST(''));
        }
        field(14701; "OKIN Code"; Code[10])
        {
            Caption = 'OKIN Code';
            TableRelation = "Classificator OKIN".Code WHERE(Group = FIELD("OKIN Group"));
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

