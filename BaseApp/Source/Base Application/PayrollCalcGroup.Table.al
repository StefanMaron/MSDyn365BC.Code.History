table 17402 "Payroll Calc Group"
{
    Caption = 'Payroll Calc Group';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Payroll Calc Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Disabled Persons"; Boolean)
        {
            Caption = 'Disabled Persons';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Between';
            OptionMembers = " ",Between;
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

    trigger OnDelete()
    begin
        PayrollCalcGroupLine.Reset;
        PayrollCalcGroupLine.SetRange("Payroll Calc Group", Code);
        PayrollCalcGroupLine.DeleteAll;
    end;

    var
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
}

