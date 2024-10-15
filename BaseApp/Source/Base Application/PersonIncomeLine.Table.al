table 17393 "Person Income Line"
{
    Caption = 'Person Income Line';

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
        field(3; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                PersonIncomeHeader.Get("Document No.");
                "Person No." := PersonIncomeHeader."Person No.";
                Year := PersonIncomeHeader.Year;
            end;
        }
        field(7; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(8; Calculation; Boolean)
        {
            Caption = 'Calculation';
            Editable = false;
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Person Income Header";
        }
        field(50; "Taxable Income (Calc)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = FILTER(<> ''),
                                                                Interim = CONST(false),
                                                                "Advance Payment" = CONST(false)));
            Caption = 'Taxable Income (Calc)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Taxable Income (Interim)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = FILTER(<> ''),
                                                                Interim = CONST(true),
                                                                "Advance Payment" = CONST(false)));
            Caption = 'Taxable Income (Interim)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Non-Taxable Income (Calc)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = CONST(''),
                                                                Interim = CONST(false)));
            Caption = 'Non-Taxable Income (Calc)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Non-Taxable Income (Interim)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = CONST(''),
                                                                Interim = CONST(true)));
            Caption = 'Non-Taxable Income (Interim)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Tax Deductions"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry"."Tax Deduction Amount" WHERE("Person Income No." = FIELD("Document No."),
                                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                                  "Entry Type" = CONST("Tax Deduction")));
            Caption = 'Tax Deductions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Accrued Tax"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("Document No."),
                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  Interim = CONST(false)));
            Caption = 'Accrued Tax';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Accrued Tax (Interim)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("Document No."),
                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  Interim = CONST(true)));
            Caption = 'Accrued Tax (Interim)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Taxable Income"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = FILTER(<> ''),
                                                                "Advance Payment" = CONST(false)));
            Caption = 'Taxable Income';
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "Non-Taxable Income"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = CONST('')));
            Caption = 'Non-Taxable Income';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Advance Income"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = FILTER(<> ''),
                                                                "Advance Payment" = CONST(true)));
            Caption = 'Advance Income';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Paid to Budget"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("Document No."),
                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                  "Entry Type" = CONST("Paid Income Tax")));
            Caption = 'Paid to Budget';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Paid to Budget (Interim)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("Document No."),
                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                  "Entry Type" = CONST("Paid Income Tax"),
                                                                  Interim = CONST(true)));
            Caption = 'Paid to Budget (Interim)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Paid to Budget (Calc)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("Document No."),
                                                                  "Person Income Line No." = FIELD("Line No."),
                                                                  "Entry Type" = CONST("Paid Income Tax"),
                                                                  Interim = CONST(false)));
            Caption = 'Paid to Budget (Calc)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Paid to Person"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Paid Taxable Income")));
            Caption = 'Paid to Person';
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Paid to Person (Interim)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Paid Taxable Income"),
                                                                Interim = CONST(true)));
            Caption = 'Paid to Person (Interim)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Paid to Person (Calc)"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("Document No."),
                                                                "Person Income Line No." = FIELD("Line No."),
                                                                "Entry Type" = CONST("Paid Taxable Income"),
                                                                Interim = CONST(false)));
            Caption = 'Paid to Person (Calc)';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if xRec.Calculation then
            TestField(Calculation, false);

        PersonIncomeEntry.Reset();
        PersonIncomeEntry.SetRange("Person Income No.", "Document No.");
        PersonIncomeEntry.SetRange("Person Income Line No.", "Line No.");
        PersonIncomeEntry.DeleteAll();
    end;

    trigger OnModify()
    begin
        if xRec.Calculation then
            TestField(Calculation, false);
    end;

    var
        PersonIncomeHeader: Record "Person Income Header";
        PersonIncomeEntry: Record "Person Income Entry";

    [Scope('OnPrem')]
    procedure EditLine()
    var
        PersonIncomeEntry: Record "Person Income Entry";
        PersonIncomeEntries: Page "Person Income Entries";
    begin
        Clear(PersonIncomeEntries);
        PersonIncomeEntry.Reset();
        PersonIncomeEntry.SetRange("Person Income No.", "Document No.");
        PersonIncomeEntry.SetRange("Person Income Line No.", "Line No.");
        PersonIncomeEntry.SetRange("Period Code", "Period Code");
        PersonIncomeEntries.SetTableView(PersonIncomeEntry);
        PersonIncomeEntries.Set(true);
        PersonIncomeEntries.RunModal;
    end;
}

