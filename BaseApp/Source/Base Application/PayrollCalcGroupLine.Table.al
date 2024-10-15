table 17403 "Payroll Calc Group Line"
{
    Caption = 'Payroll Calc Group Line';
    LookupPageID = "Payroll Calc Group Lines";

    fields
    {
        field(1; "Payroll Calc Group"; Code[10])
        {
            Caption = 'Payroll Calc Group';
            NotBlank = true;
            TableRelation = "Payroll Calc Group";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Payroll Calc Type"; Code[20])
        {
            Caption = 'Payroll Calc Type';
            NotBlank = true;
            TableRelation = "Payroll Calc Type";

            trigger OnValidate()
            begin
                PayrollCalcType.Get("Payroll Calc Type");
                PayrollCalcType.TestField(Priority);
                "Line No." := PayrollCalcType.Priority;
            end;
        }
    }

    keys
    {
        key(Key1; "Payroll Calc Group", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Payroll Calc Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Line No.");
    end;

    var
        PayrollCalcType: Record "Payroll Calc Type";
}

