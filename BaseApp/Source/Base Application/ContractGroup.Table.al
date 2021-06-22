table 5966 "Contract Group"
{
    Caption = 'Contract Group';
    DrillDownPageID = "Service Contract Groups";
    LookupPageID = "Service Contract Groups";

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
        field(3; "Disc. on Contr. Orders Only"; Boolean)
        {
            Caption = 'Disc. on Contr. Orders Only';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Contract Gain/Loss Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Contract Gain/Loss Entry".Amount WHERE("Contract Group Code" = FIELD(Code),
                                                                       "Change Date" = FIELD("Date Filter")));
            Caption = 'Contract Gain/Loss Amount';
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

