table 136 "Acc. Sched. KPI Web Srv. Line"
{
    Caption = 'Acc. Sched. KPI Web Srv. Line';

    fields
    {
        field(1; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Acc. Schedule Name';
            NotBlank = true;
            TableRelation = "Acc. Schedule Name";
        }
        field(2; "Acc. Schedule Description"; Text[80])
        {
            CalcFormula = Lookup ("Acc. Schedule Name".Description WHERE(Name = FIELD("Acc. Schedule Name")));
            Caption = 'Acc. Schedule Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Acc. Schedule Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

