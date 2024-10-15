table 17410 "Payroll Range Header"
{
    Caption = 'Payroll Range Header';
    LookupPageID = "Payroll Ranges";

    fields
    {
        field(1; "Code"; Text[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(5; "Range Type"; Option)
        {
            Caption = 'Range Type';
            OptionCaption = ' ,Deduction,Tax Deduction,Exclusion,Deduct. Benefit,Tax Abatement,Limit + Tax %,Frequency,Coordination,Increase Salary,Quantity';
            OptionMembers = " ",Deduction,"Tax Deduction",Exclusion,"Deduct. Benefit","Tax Abatement","Limit + Tax %",Frequency,Coordination,"Increase Salary",Quantity;
        }
        field(6; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(14; "Allow Employee Gender"; Boolean)
        {
            Caption = 'Allow Employee Gender';
        }
        field(15; "Allow Employee Age"; Boolean)
        {
            Caption = 'Allow Employee Age';
        }
        field(16; "Consider Relative"; Boolean)
        {
            Caption = 'Consider Relative';
        }
    }

    keys
    {
        key(Key1; "Element Code", "Code", "Period Code")
        {
            Clustered = true;
        }
        key(Key2; "Element Code", "Range Type", "Period Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollRangeLine.Reset();
        PayrollRangeLine.SetRange("Element Code", "Element Code");
        PayrollRangeLine.SetRange("Range Code", Code);
        PayrollRangeLine.SetRange("Period Code", "Period Code");
        PayrollRangeLine.DeleteAll();
    end;

    trigger OnModify()
    begin
        PayrollRangeLine.Reset();
        PayrollRangeLine.SetRange("Element Code", "Element Code");
        PayrollRangeLine.SetRange("Range Code", Code);
        PayrollRangeLine.SetRange("Period Code", "Period Code");
        if "Range Type" <> xRec."Range Type" then
            PayrollRangeLine.ModifyAll("Range Type", "Range Type");
    end;

    var
        PayrollRangeLine: Record "Payroll Range Line";
}

