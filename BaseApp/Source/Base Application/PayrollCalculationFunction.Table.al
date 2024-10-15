table 17408 "Payroll Calculation Function"
{
    Caption = 'Payroll Calculation Function';
    LookupPageID = "Payroll Calculation Functions";

    fields
    {
        field(1; "Code"; Text[30])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; "Function No."; Integer)
        {
            Caption = 'Function No.';
            MinValue = 0;
        }
        field(5; "Range Type"; Option)
        {
            Caption = 'Range Type';
            OptionCaption = ' ,Deduction,Tax Deduction,Exclusion,Deduct. Benefit,Tax Abatement,Limit + Tax %,Frequency,Coordination,Increase Salary,Quantity';
            OptionMembers = " ",Deduction,"Tax Deduction",Exclusion,"Deduct. Benefit","Tax Abatement","Limit + Tax %",Frequency,Coordination,"Increase Salary",Quantity;
        }
        field(6; Used; Integer)
        {
            CalcFormula = Count ("Payroll Calculation Line" WHERE("Function Code" = FIELD(Code)));
            Caption = 'Used';
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
        key(Key2; "Function No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollCalculationLine.Reset();
        PayrollCalculationLine.SetRange("Function Code", Code);
        if PayrollCalculationLine.FindFirst then
            Error(Text000, PayrollCalculationLine."Element Code");
    end;

    var
        PayrollCalculationLine: Record "Payroll Calculation Line";
        Text000: Label 'This step is used by calculation for Payrol Element %1.';
}

