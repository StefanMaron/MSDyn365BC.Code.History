table 17395 "Person Tax Deduction"
{
    Caption = 'Person Tax Deduction';

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(2; Year; Integer)
        {
            Caption = 'Year';
        }
        field(3; "Deduction Code"; Code[10])
        {
            Caption = 'Deduction Code';
            TableRelation = "Payroll Directory".Code WHERE(Type = CONST("Tax Deduction"));
        }
        field(4; "Deduction Amount"; Decimal)
        {
            Caption = 'Deduction Amount';
        }
        field(5; Calculation; Boolean)
        {
            Caption = 'Calculation';
            Editable = false;
        }
        field(6; "Deduction Quantity"; Decimal)
        {
            Caption = 'Deduction Quantity';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Person Income Header";
        }
    }

    keys
    {
        key(Key1; "Document No.", "Person No.", "Deduction Code")
        {
            Clustered = true;
            SumIndexFields = "Deduction Amount";
        }
    }

    fieldgroups
    {
    }
}

