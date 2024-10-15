table 27040 "DIOT-Concept"
{
    Caption = 'DIOT Concept';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Concept No."; Integer)
        {
            Caption = 'Concept No.';
            MaxValue = 17;
            MinValue = 1;
        }
        field(2; "Column No."; Integer)
        {
            MaxValue = 24;
            MinValue = 8;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "Column Type"; Option)
        {
            OptionCaption = 'None,VAT Base,VAT Amount';
            OptionMembers = "None","VAT Base","Vat Amount";
        }
        field(5; "Non-Deductible"; Boolean)
        {
            Caption = 'Non-Deductible';
        }
        field(6; "Non-Deductible Pct"; Decimal)
        {
            Caption = 'Non-Deductible percent';
            MinValue = 0;
        }
        field(7; "VAT Links Count"; Integer)
        {
            CalcFormula = Count ("DIOT-Concept Link" WHERE("DIOT Concept No." = FIELD("Concept No.")));
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Concept No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

