table 17396 "Person Income FSI"
{
    Caption = 'Person Income FSI';

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(2; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                if PayrollPeriod.Get("Period Code") then
                    Year := Date2DMY(PayrollPeriod."Starting Date", 3);
            end;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(7; "Company Name"; Text[50])
        {
            Caption = 'Company Name';
        }
        field(8; Year; Integer)
        {
            Caption = 'Year';
        }
        field(9; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(10; Calculation; Boolean)
        {
            Caption = 'Calculation';
            Editable = false;
        }
        field(11; "Exclude from Calculation"; Boolean)
        {
            Caption = 'Exclude from Calculation';
        }
        field(12; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(13; "Excluded Days"; Decimal)
        {
            CalcFormula = Sum ("Person Excluded Days"."Calendar Days" WHERE("Person No." = FIELD("Person No."),
                                                                            "Period Code" = FIELD("Period Code"),
                                                                            "Document No." = FIELD("Document No.")));
            Caption = 'Excluded Days';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Person No.", "Period Code", "Document No.")
        {
            Clustered = true;
        }
        key(Key2; Year, Calculation)
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Person No.", Year)
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        if xRec.Calculation then
            TestField(Calculation);
    end;

    var
        PayrollPeriod: Record "Payroll Period";
        PersonIncomeFSI: Record "Person Income FSI";

    [Scope('OnPrem')]
    procedure Recalculate()
    var
        Employee: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        PstdPayrollDocHeader: Record "Posted Payroll Document";
        PstdPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollCalcGroup: Record "Payroll Calc Group";
        PersonIncomeMgt: Codeunit "Person Income Management";
    begin
        TestField(Year);
        TestField("Person No.");

        PersonIncomeFSI.Reset();
        PersonIncomeFSI.SetRange("Person No.", "Person No.");
        PersonIncomeFSI.SetRange(Year, Year);
        PersonIncomeFSI.SetRange(Calculation, true);
        PersonIncomeFSI.DeleteAll();

        Employee.SetRange("Person No.", "Person No.");
        if Employee.FindSet then
            repeat
                PayrollPeriod.Reset();
                PayrollPeriod.SetRange("Ending Date", DMY2Date(1, 1, Year), CalcDate('<+CY>', DMY2Date(1, 12, Year)));
                if PayrollPeriod.FindSet then
                    repeat
                        PstdPayrollDocHeader.Reset();
                        PstdPayrollDocHeader.SetRange("Employee No.", Employee."No.");
                        PstdPayrollDocHeader.SetRange("Period Code", PayrollPeriod.Code);
                        if PstdPayrollDocHeader.FindSet then
                            repeat
                                PayrollCalcGroup.Get(PstdPayrollDocHeader."Calc Group Code");
                                if PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between then begin
                                    PstdPayrollDocLine.Reset();
                                    PstdPayrollDocLine.SetRange("Document No.", PstdPayrollDocHeader."No.");
                                    if PstdPayrollDocLine.FindSet then
                                        repeat
                                            if PstdPayrollDocLine."FSI Base" or PstdPayrollDocLine."FSI Injury Base" then
                                                PersonIncomeMgt.CreateSocialTaxLine(PstdPayrollDocLine);
                                        until PstdPayrollDocLine.Next() = 0;
                                end;
                            until PstdPayrollDocHeader.Next() = 0;
                    until PayrollPeriod.Next() = 0;
            until Employee.Next() = 0;
    end;
}

