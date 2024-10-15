table 17356 "HR Field Group"
{
    Caption = 'HR Field Group';
    LookupPageID = "HR Field Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Print Order"; Integer)
        {
            Caption = 'Print Order';
        }
        field(5; "No. of Fields"; Integer)
        {
            CalcFormula = Count ("HR Field Group Line" WHERE("Field Group Code" = FIELD(Code)));
            Caption = 'No. of Fields';
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
        key(Key2; "Print Order")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField(Code)
    end;
}

