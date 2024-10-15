table 17392 "Person Income Header"
{
    Caption = 'Person Income Header';
    LookupPageID = "Person Income Documents";

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
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HRSetup.Get();
                    NoSeriesMgt.TestManual(HRSetup."Person Income Document Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(5; Calculation; Boolean)
        {
            Caption = 'Calculation';
            Editable = false;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(40; "Total Taxable Income"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("No."),
                                                                "Entry Type" = CONST("Taxable Income"),
                                                                "Tax Code" = FILTER(<> ''),
                                                                "Advance Payment" = CONST(false)));
            Caption = 'Total Taxable Income';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Total Tax Deductions"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry"."Tax Deduction Amount" WHERE("Person Income No." = FIELD("No."),
                                                                                  "Entry Type" = CONST("Tax Deduction")));
            Caption = 'Total Tax Deductions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Total Annual Tax Deductions"; Decimal)
        {
            CalcFormula = Sum ("Person Tax Deduction"."Deduction Amount" WHERE("Document No." = FIELD("No.")));
            Caption = 'Total Annual Tax Deductions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Total Accrued Tax"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  Interim = CONST(false)));
            Caption = 'Total Accrued Tax';
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Total Paid to Budget"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Paid Income Tax")));
            Caption = 'Total Paid to Budget';
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Total Accrued Tax 13%"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  "Tax %" = FILTER("13"),
                                                                  Interim = CONST(false)));
            Caption = 'Total Accrued Tax 13%';
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Total Accrued Tax 30%"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  "Tax %" = FILTER("30"),
                                                                  Interim = CONST(false)));
            Caption = 'Total Accrued Tax 30%';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Total Accrued Tax 35%"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  "Tax %" = FILTER("35"),
                                                                  Interim = CONST(false)));
            Caption = 'Total Accrued Tax 35%';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Total Accrued Tax 9%"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Amount WHERE("Person Income No." = FIELD("No."),
                                                                  "Entry Type" = CONST("Accrued Income Tax"),
                                                                  "Tax %" = FILTER("9"),
                                                                  Interim = CONST(false)));
            Caption = 'Total Accrued Tax 9%';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Annual Tax Deductions"; Boolean)
        {
            CalcFormula = Exist ("Person Tax Deduction" WHERE("Document No." = FIELD("No.")));
            Caption = 'Annual Tax Deductions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Total Income (Doc)"; Decimal)
        {
            Caption = 'Total Income (Doc)';
        }
        field(52; "Taxable Income (Doc)"; Decimal)
        {
            Caption = 'Taxable Income (Doc)';
        }
        field(53; "Income Tax Accrued (Doc)"; Decimal)
        {
            Caption = 'Income Tax Accrued (Doc)';
        }
        field(54; "Income Tax Paid (Doc)"; Decimal)
        {
            Caption = 'Income Tax Paid (Doc)';
        }
        field(55; "Income Tax Return LY (Doc)"; Decimal)
        {
            Caption = 'Income Tax Return LY (Doc)';
        }
        field(56; "Tax Return Settled LY (Doc)"; Decimal)
        {
            Caption = 'Tax Return Settled LY (Doc)';
        }
        field(57; "Tax Return Paid LY (Doc)"; Decimal)
        {
            Caption = 'Tax Return Paid LY (Doc)';
        }
        field(58; "Income Tax Due (Doc)"; Decimal)
        {
            Caption = 'Income Tax Due (Doc)';
        }
        field(59; "Income Tax Overpaid (Doc)"; Decimal)
        {
            Caption = 'Income Tax Overpaid (Doc)';
        }
        field(60; "Income Tax for Withdraw. (Doc)"; Decimal)
        {
            Caption = 'Income Tax for Withdraw. (Doc)';
        }
        field(61; "Total Paid to Person"; Decimal)
        {
            CalcFormula = Sum ("Person Income Entry".Base WHERE("Person Income No." = FIELD("No."),
                                                                "Entry Type" = CONST("Paid Taxable Income")));
            Caption = 'Total Paid to Person';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Person No.", Year)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PersonIncomeLine: Record "Person Income Line";
    begin
        PersonIncomeLine.Reset();
        PersonIncomeLine.SetRange("Document No.", "No.");
        PersonIncomeLine.DeleteAll();

        PersonIncomeEntry.Reset();
        PersonIncomeEntry.SetRange("Person Income No.", "No.");
        PersonIncomeEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            HRSetup.Get();
            TestNoSeries;
            NoSeriesMgt.InitSeries(
              HRSetup."Person Income Document Nos.", xRec."No. Series", "Document Date",
              "No.", "No. Series");
        end;

        if GetFilter("Person No.") <> '' then
            if GetRangeMin("Person No.") = GetRangeMax("Person No.") then
                Validate("Person No.", GetRangeMin("Person No."));
    end;

    var
        HRSetup: Record "Human Resources Setup";
        PersonIncomeHeader: Record "Person Income Header";
        PersonIncomeLine: Record "Person Income Line";
        PersonIncomeEntry: Record "Person Income Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    [Scope('OnPrem')]
    procedure AssistEdit(OldPersonIncomeHeader: Record "Person Income Header"): Boolean
    begin
        PersonIncomeHeader.Copy(Rec);
        HRSetup.Get();
        TestNoSeries;
        if NoSeriesMgt.SelectSeries(HRSetup."Person Income Document Nos.", OldPersonIncomeHeader."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            Rec := PersonIncomeHeader;
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        HRSetup.TestField("Person Income Document Nos.");
    end;

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
        TestField(Calculation);
        TestField(Year);
        TestField("Person No.");

        PersonIncomeLine.Reset();
        PersonIncomeLine.SetRange("Document No.", "No.");
        PersonIncomeLine.SetRange(Calculation, true);
        PersonIncomeLine.DeleteAll();

        PersonIncomeEntry.Reset();
        PersonIncomeEntry.SetRange("Person Income No.", "No.");
        PersonIncomeEntry.SetRange(Calculation, true);
        PersonIncomeEntry.DeleteAll();

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
                                PstdPayrollDocLine.Reset();
                                PstdPayrollDocLine.SetRange("Document No.", PstdPayrollDocHeader."No.");
                                if PstdPayrollDocLine.FindSet then
                                    repeat
                                        PersonIncomeMgt.SetDocNo("No.");
                                        PersonIncomeMgt.CreateIncomeTaxLine(
                                          PstdPayrollDocLine, PstdPayrollDocHeader."Posting Date", PstdPayrollDocHeader.Correction);
                                    until PstdPayrollDocLine.Next = 0;
                                PersonIncomeMgt.CreatePaidToPerson("Person No.", PayrollPeriod);
                            until PstdPayrollDocHeader.Next = 0;
                    until PayrollPeriod.Next = 0;
            until Employee.Next = 0;
    end;
}

