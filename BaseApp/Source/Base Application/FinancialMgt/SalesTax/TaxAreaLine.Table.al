table 319 "Tax Area Line"
{
    Caption = 'Tax Area Line';

    fields
    {
        field(1; "Tax Area"; Code[20])
        {
            Caption = 'Tax Area';
            TableRelation = "Tax Area";
        }
        field(2; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        field(3; "Jurisdiction Description"; Text[100])
        {
            CalcFormula = Lookup ("Tax Jurisdiction".Description WHERE(Code = FIELD("Tax Jurisdiction Code")));
            Caption = 'Jurisdiction Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Calculation Order"; Integer)
        {
            Caption = 'Calculation Order';
        }
    }

    keys
    {
        key(Key1; "Tax Area", "Tax Jurisdiction Code")
        {
            Clustered = true;
        }
        key(Key2; "Tax Jurisdiction Code")
        {
        }
        key(Key3; "Tax Area", "Calculation Order")
        {
        }
    }

    fieldgroups
    {
    }
}

