table 17457 "Payroll Status"
{
    Caption = 'Payroll Status';

    fields
    {
        field(1; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(6; "Payroll Status"; Option)
        {
            Caption = 'Payroll Status';
            OptionCaption = ' ,Calculated,Posted,Paid';
            OptionMembers = " ",Calculated,Posted,Paid;
        }
        field(7; "Advance Status"; Option)
        {
            Caption = 'Advance Status';
            OptionCaption = ' ,Calculated,Posted,Paid';
            OptionMembers = " ",Calculated,Posted,Paid;
        }
        field(8; "Tax Status"; Option)
        {
            Caption = 'Tax Status';
            OptionCaption = ' ,Calculated,Posted,Paid';
            OptionMembers = " ",Calculated,Posted,Paid;
        }
        field(10; Wages; Decimal)
        {
            Caption = 'Wages';
            Editable = false;
        }
        field(11; Bonuses; Decimal)
        {
            Caption = 'Bonuses';
            Editable = false;
        }
        field(12; Deductions; Decimal)
        {
            Caption = 'Deductions';
            Editable = false;
        }
        field(13; "Tax Deductions"; Decimal)
        {
            Caption = 'Tax Deductions';
            Editable = false;
        }
        field(14; "Income Tax Base"; Decimal)
        {
            Caption = 'Income Tax Base';
            Editable = false;
        }
        field(15; "Income Tax Amount"; Decimal)
        {
            Caption = 'Income Tax Amount';
        }
        field(16; "FSS Contributions"; Decimal)
        {
            Caption = 'FSS Contributions';
        }
        field(17; "FSS Injury Contributions"; Decimal)
        {
            Caption = 'FSS Injury Contributions';
        }
        field(18; "Territorial FMI Contributions"; Decimal)
        {
            Caption = 'Territorial FMI Contributions';
        }
        field(19; "Federal FMI Contributions"; Decimal)
        {
            Caption = 'Federal FMI Contributions';
        }
        field(20; "PF Accum. Part Contributions"; Decimal)
        {
            Caption = 'PF Accum. Part Contributions';
        }
        field(21; "PF Insur. Part Contributions"; Decimal)
        {
            Caption = 'PF Insur. Part Contributions';
        }
        field(30; "Posted Wages"; Decimal)
        {
            Caption = 'Posted Wages';
            Editable = false;
        }
        field(31; "Posted Bonuses"; Decimal)
        {
            Caption = 'Posted Bonuses';
            Editable = false;
        }
        field(32; "Posted Deductions"; Decimal)
        {
            Caption = 'Posted Deductions';
            Editable = false;
        }
        field(33; "Posted Tax Deductions"; Decimal)
        {
            Caption = 'Posted Tax Deductions';
            Editable = false;
        }
        field(34; "Posted Income Tax Base"; Decimal)
        {
            Caption = 'Posted Income Tax Base';
            Editable = false;
        }
        field(35; "Posted Income Tax Amount"; Decimal)
        {
            Caption = 'Posted Income Tax Amount';
        }
        field(36; "Posted FSS Contributions"; Decimal)
        {
            Caption = 'Posted FSS Contributions';
        }
        field(37; "Posted FSS Injury Contrib."; Decimal)
        {
            Caption = 'Posted FSS Injury Contrib.';
        }
        field(38; "Posted Territ. FMI Contrib."; Decimal)
        {
            Caption = 'Posted Territ. FMI Contrib.';
        }
        field(39; "Posted Federal FMI Contrib."; Decimal)
        {
            Caption = 'Posted Federal FMI Contrib.';
        }
        field(40; "Posted PF Accum. Part Contrib."; Decimal)
        {
            Caption = 'Posted PF Accum. Part Contrib.';
        }
        field(41; "Posted PF Insur. Part Contrib."; Decimal)
        {
            Caption = 'Posted PF Insur. Part Contrib.';
        }
    }

    keys
    {
        key(Key1; "Period Code", "Employee No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PayrollPeriod: Record "Payroll Period";
        HumanResSetup: Record "Human Resources Setup";
        PayrollDocCalculate: Codeunit "Payroll Document - Calculate";

    [Scope('OnPrem')]
    procedure UpdateCalculated(var PayrollStatus: Record "Payroll Status")
    begin
        PayrollPeriod.Get("Period Code");

        HumanResSetup.Get();

        with PayrollStatus do begin
            if HumanResSetup."Wages Element Code" <> '' then
                Wages :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Wages Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Bonus Element Code" <> '' then
                Bonuses :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Bonus Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Deductions Element Code" <> '' then
                "Tax Deductions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Deductions Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Tax Deductions Element Code" <> '' then
                "Tax Deductions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Tax Deductions Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Income Tax Element Code" <> '' then
                "Income Tax Amount" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Income Tax Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."FSI Element Code" <> '' then
                "FSS Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."FSI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."FSI Injury Element Code" <> '' then
                "FSS Injury Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."FSI Injury Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Territorial FMI Element Code" <> '' then
                "Territorial FMI Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Territorial FMI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Federal FMI Element Code" <> '' then
                "Federal FMI Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."Federal FMI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."PF Accum. Part Element Code" <> '' then
                "PF Accum. Part Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."PF Accum. Part Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."PF Insur. Part Element Code" <> '' then
                "PF Insur. Part Contributions" :=
                  PayrollDocCalculate.CalcElementByPayrollDocs(
                    HumanResSetup."PF Insur. Part Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePosted(var PayrollStatus: Record "Payroll Status")
    begin
        PayrollPeriod.Get("Period Code");

        HumanResSetup.Get();
        with PayrollStatus do begin
            if HumanResSetup."Wages Element Code" <> '' then
                "Posted Wages" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Wages Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Bonus Element Code" <> '' then
                "Posted Bonuses" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Bonus Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Deductions Element Code" <> '' then
                "Posted Deductions" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Deductions Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Tax Deductions Element Code" <> '' then
                "Posted Tax Deductions" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Tax Deductions Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Income Tax Element Code" <> '' then
                "Posted Income Tax Amount" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Income Tax Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."FSI Element Code" <> '' then
                "Posted FSS Contributions" :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."FSI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."FSI Injury Element Code" <> '' then
                "Posted FSS Injury Contrib." :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."FSI Injury Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Territorial FMI Element Code" <> '' then
                "Posted Territ. FMI Contrib." :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Territorial FMI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."Federal FMI Element Code" <> '' then
                "Posted Federal FMI Contrib." :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."Federal FMI Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."PF Accum. Part Element Code" <> '' then
                "Posted PF Accum. Part Contrib." :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."PF Accum. Part Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');

            if HumanResSetup."PF Insur. Part Element Code" <> '' then
                "Posted PF Insur. Part Contrib." :=
                  PayrollDocCalculate.CalcElementByPostedEntries(
                    HumanResSetup."PF Insur. Part Element Code", "Employee No.",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckPayrollStatus(PeriodCode: Code[10]; EmployeeNo: Code[20])
    var
        PayrollStatus: Record "Payroll Status";
    begin
        PayrollStatus.Get(PeriodCode, EmployeeNo);
        if PayrollStatus."Payroll Status" <> PayrollStatus."Payroll Status"::" " then
            PayrollStatus.FieldError("Payroll Status");
    end;

    [Scope('OnPrem')]
    procedure HasSalaryIndexation(var IndexationFactor: Decimal): Boolean
    var
        LaborContractLine: Record "Labor Contract Line";
    begin
        if FindSalaryIndexation(LaborContractLine) then begin
            IndexationFactor := CalcIndexationFactor(LaborContractLine);
            exit(true);
        end;

        exit(false);
    end;

    local procedure FindSalaryIndexation(var LaborContractLine: Record "Labor Contract Line"): Boolean
    var
        LaborContract: Record "Labor Contract";
        LaborContractTerms: Record "Labor Contract Terms";
    begin
        PayrollPeriod.Get("Period Code");
        HumanResSetup.Get();
        LaborContract.SetRange("Employee No.", "Employee No.");
        if not LaborContract.FindFirst then
            exit(false);

        LaborContractLine.SetRange("Contract No.", LaborContract."No.");
        LaborContractLine.SetRange(Status, LaborContractLine.Status::Approved);
        LaborContractLine.SetRange("Starting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
        if not LaborContractLine.FindLast then
            exit(false);
        if LaborContractLine."Operation Type" <> LaborContractLine."Operation Type"::Transfer then
            exit(false);

        LaborContractTerms.SetRange("Labor Contract No.", LaborContractLine."Contract No.");
        LaborContractTerms.SetRange("Operation Type", LaborContractLine."Operation Type");
        LaborContractTerms.SetRange("Supplement No.", LaborContractLine."Supplement No.");
        LaborContractTerms.SetRange("Line Type", LaborContractTerms."Line Type"::"Payroll Element");
        LaborContractTerms.SetFilter("Element Code", '%1|%2|%3', HumanResSetup."Element Code Salary Days",
          HumanResSetup."Element Code Salary Hours", HumanResSetup."Element Code Salary Amount");
        if not LaborContractTerms.FindFirst then
            exit(false);

        exit(LaborContractTerms."Salary Indexation");
    end;

    local procedure CalcIndexationFactor(var LaborContractLine: Record "Labor Contract Line"): Decimal
    var
        OldPosition: Record Position;
        NewPosition: Record Position;
    begin
        NewPosition.Get(LaborContractLine."Position No.");
        LaborContractLine.SetRange("Starting Date");
        LaborContractLine.Next(-1);
        OldPosition.Get(LaborContractLine."Position No.");
        exit(1 + (NewPosition."Base Salary" - OldPosition."Base Salary") / OldPosition."Base Salary");
    end;
}

