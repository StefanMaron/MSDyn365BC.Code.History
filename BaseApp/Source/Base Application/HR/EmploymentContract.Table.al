table 5211 "Employment Contract"
{
    Caption = 'Employment Contract';
    DrillDownPageID = "Employment Contracts";
    LookupPageID = "Employment Contracts";

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
        field(3; "No. of Contracts"; Integer)
        {
            CalcFormula = Count (Employee WHERE(Status = CONST(Active),
                                                "Emplymt. Contract Code" = FIELD(Code)));
            Caption = 'No. of Contracts';
            Editable = false;
            FieldClass = FlowField;
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

