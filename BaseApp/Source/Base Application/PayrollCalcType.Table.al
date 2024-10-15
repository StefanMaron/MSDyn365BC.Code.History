table 17404 "Payroll Calc Type"
{
    Caption = 'Payroll Calc Type';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Payroll Calc Types";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(100; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(101; "Use in Calc"; Option)
        {
            Caption = 'Use in Calc';
            OptionCaption = 'Always,If Entry Exist';
            OptionMembers = Always,"If Entry Exist";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollCalcGroupLine.Reset;
        PayrollCalcGroupLine.SetCurrentKey("Payroll Calc Type");
        PayrollCalcGroupLine.SetRange("Payroll Calc Type", Code);
        if PayrollCalcGroupLine.FindFirst then
            Error(Text000,
              PayrollCalcGroupLine."Payroll Calc Group");

        PayrollCalcTypeLine.SetRange("Calc Type Code", Code);
        PayrollCalcTypeLine.DeleteAll;
    end;

    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
        Text000: Label 'This Calc Type is used by Calc. Group %1';
}

