codeunit 17480 "AE Calc Management"
{
    Permissions = TableData "Payroll Period AE" = rimd;

    trigger OnRun()
    begin
    end;

    var
        PayrollDocLineAE: Record "Payroll Document Line AE";
        AECalcSetup: Record "AE Calculation Setup";
        AEBonusSetup: Record "AE Calculation Setup";
        PayrollPeriod: Record "Payroll Period";
        PayrollPeriodAE: Record "Payroll Period AE";
        Employee: Record Employee;
        PayrollElement: Record "Payroll Element";
        PayrollElement2: Record "Payroll Element";
        HRSetup: Record "Human Resources Setup";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        PayrollDocCalculate: Codeunit "Payroll Document - Calculate";
        Text001: Label 'You should define FSI Limit for period %1.';

    [Scope('OnPrem')]
    procedure FillAbsenceLineAEDates(var AbsenceLine: Record "Absence Line")
    var
        PreviousOrderLine: Record "Posted Absence Line";
        PayrollCalc: Record "Payroll Calculation";
        PayrollCalcLine: Record "Payroll Calculation Line";
        HRSetup: Record "Human Resources Setup";
        AESetupCode: Code[10];
        Step: Integer;
    begin
        with AbsenceLine do begin
            TestField("Start Date");
            TestField("Employee No.");

            Employee.Get("Employee No.");

            AECalcSetup.Reset();
            AECalcSetup.SetRange(Type, AECalcSetup.Type::Calculation);
            case "Document Type" of
                "Document Type"::Vacation:
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Vacation);
                "Document Type"::"Sick Leave":
                    case "Sick Leave Type" of
                        "Sick Leave Type"::"Child Care 1.5 years":
                            AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Child Care 1");
                        "Sick Leave Type"::"Child Care 3 years":
                            AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Child Care 2");
                        "Sick Leave Type"::"Pregnancy Leave":
                            AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Pregnancy Leave");
                        else
                            AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Sick Leave");
                    end;
                "Document Type"::Travel:
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Others);
            end;
            AECalcSetup.SetRange("Period Code", '', PayrollPeriod.PeriodByDate("Start Date"));
            HRSetup.Get();
            HRSetup.TestField("AE Calculation Function Code");
            PayrollCalc.SetRange("Element Code", "Element Code");
            PayrollCalc.SetRange("Period Code", '', PayrollPeriod.PeriodByDate("Start Date"));
            if PayrollCalc.FindLast then begin
                PayrollCalcLine.Reset();
                PayrollCalcLine.SetRange("Element Code", "Element Code");
                PayrollCalcLine.SetRange("Period Code", PayrollCalc."Period Code");
                PayrollCalcLine.SetRange("Function Code", HRSetup."AE Calculation Function Code");
                if PayrollCalcLine.FindFirst then
                    AESetupCode := PayrollCalcLine."AE Setup Code";
            end;
            if AESetupCode <> '' then
                AECalcSetup.SetRange("Setup Code", AESetupCode);
            if AECalcSetup.FindLast then begin
                AECalcSetup.TestField("AE Calc Months");
                if AECalcSetup."Days for Calc Type" = AECalcSetup."Days for Calc Type"::"Whole Year" then
                    PayrollPeriod.Get(PayrollPeriod.PeriodByDate(CalcDate('<-CY>', "Start Date")))
                else
                    PayrollPeriod.Get(PayrollPeriod.PeriodByDate("Start Date"));
                Step := -1;
                PayrollPeriod.Next(Step);
                "AE Period To" := PayrollPeriod.Code;
                Step := -(AECalcSetup."AE Calc Months" - 1);
                PayrollPeriod.Next(Step);
                "AE Period From" := PayrollPeriod.Code;
                if AECalcSetup."Days for Calc Type" <> AECalcSetup."Days for Calc Type"::"Whole Year" then
                    if PayrollPeriod.PeriodByDate(Employee."Employment Date") > "AE Period From" then
                        "AE Period From" := PayrollPeriod.PeriodByDate(Employee."Employment Date");
            end;
            if ("Document Type" = "Document Type"::"Sick Leave") and FindPreviousAbsenceHeader(PreviousOrderLine) then begin
                "AE Period To" := PreviousOrderLine."AE Period To";
                "AE Period From" := PreviousOrderLine."AE Period From";
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDismissalAEDates(var EmplJnlLine: Record "Employee Journal Line")
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
        Step: Integer;
        LastDateOfMonth: Boolean;
    begin
        with EmplJnlLine do begin
            TestField("Ending Date");
            TestField("Employee No.");

            Employee.Get("Employee No.");

            // check if Action Ending Date is a last month's day
            LastDateOfMonth := "Ending Date" = CalcDate('<CM>', "Ending Date");

            AECalcSetup.Reset();
            AECalcSetup.SetRange(Type, AECalcSetup.Type::Calculation);
            case "Document Type" of
                "Document Type"::Vacation:
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Vacation);
                "Document Type"::"Other Absence":
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Others);
            end;
            AECalcSetup.SetRange("Period Code", '', PayrollPeriod.PeriodByDate("Ending Date"));
            if AECalcSetup.FindLast then begin
                AECalcSetup.TestField("AE Calc Months");
                PayrollPeriod.Get(PayrollPeriod.PeriodByDate("Ending Date"));
                if not LastDateOfMonth then begin
                    Step := -1;
                    PayrollPeriod.Next(Step);
                end;
                "AE Period To" := PayrollPeriod.Code;
                Step := -(AECalcSetup."AE Calc Months" - 1);
                PayrollPeriod.Next(Step);
                "AE Period From" := PayrollPeriod.Code;
                if PayrollPeriod.PeriodByDate(Employee."Employment Date") > "AE Period From" then
                    "AE Period From" := PayrollPeriod.PeriodByDate(Employee."Employment Date");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDocLineAEData(var PayrollDocLine: Record "Payroll Document Line"; AESetupCode: Code[10]): Decimal
    var
        DtldPayrollLedgEntry: Record "Detailed Payroll Ledger Entry";
        ElementInclusion: Record "Payroll Element Inclusion";
        EmplLedgEntry: Record "Employee Ledger Entry";
        PersonIncomeLine: Record "Person Income FSI";
        PrevAEPeriodFrom: Code[10];
        PrevAEPeriodTo: Code[10];
        SkipCurrentPeriod: Boolean;
    begin
        HRSetup.Get();
        with PayrollDocLine do begin
            TestField("Action Starting Date");
            TestField("Element Code");

            // Find actual salary
            PayrollPeriod.Get("Period Code");
            "Original Amount" :=
              PayrollDocCalculate.GetBaseSalary("Employee No.", PayrollPeriod);

            // Find AE setup
            PayrollElement.Get("Element Code");

            PayrollDocLineAE.Reset();
            PayrollDocLineAE.SetRange("Document No.", "Document No.");
            PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
            if not PayrollDocLineAE.IsEmpty then
                PayrollDocLineAE.DeleteAll();

            PayrollPeriodAE.Reset();
            PayrollPeriodAE.SetRange("Document No.", "Document No.");
            PayrollPeriodAE.SetRange("Line No.", "Line No.");
            if not PayrollPeriodAE.IsEmpty then
                PayrollPeriodAE.DeleteAll();

            AECalcSetup.Reset();
            AECalcSetup.SetRange(Type, AECalcSetup.Type::Calculation);
            case "Document Type" of
                "Document Type"::Vacation:
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Vacation);
                "Document Type"::"Sick Leave":
                    begin
                        EmplLedgEntry.Get("Employee Ledger Entry No.");
                        case EmplLedgEntry."Sick Leave Type" of
                            EmplLedgEntry."Sick Leave Type"::"Child Care 1.5 years":
                                AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Child Care 1");
                            EmplLedgEntry."Sick Leave Type"::"Child Care 3 years":
                                AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Child Care 2");
                            EmplLedgEntry."Sick Leave Type"::"Pregnancy Leave":
                                AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Pregnancy Leave");
                            else
                                AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::"Sick Leave");
                        end;
                    end;
                "Document Type"::"Other Absence",
              "Document Type"::Travel:
                    AECalcSetup.SetRange("AE Calc Type", AECalcSetup."AE Calc Type"::Others);
            end;
            AECalcSetup.SetRange("Period Code", '', "Period Code");
            if AESetupCode <> '' then
                AECalcSetup.SetRange("Setup Code", AESetupCode);
            AECalcSetup.FindLast;
            AECalcSetup.TestField("AE Calc Months");
            if AECalcSetup."Month Days Calc Method" = AECalcSetup."Month Days Calc Method"::Average then
                AECalcSetup.TestField("Average Month Days");

            AEBonusSetup.Reset();
            AEBonusSetup.SetRange(Type, AEBonusSetup.Type::"Bonus Setup");
            case "Document Type" of
                "Document Type"::Vacation:
                    AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::Vacation);
                "Document Type"::"Sick Leave":
                    begin
                        EmplLedgEntry.Get("Employee Ledger Entry No.");
                        case EmplLedgEntry."Sick Leave Type" of
                            EmplLedgEntry."Sick Leave Type"::"Child Care 1.5 years":
                                AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::"Child Care 1");
                            EmplLedgEntry."Sick Leave Type"::"Child Care 3 years":
                                AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::"Child Care 2");
                            EmplLedgEntry."Sick Leave Type"::"Pregnancy Leave":
                                AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::"Pregnancy Leave");
                            else
                                AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::"Sick Leave");
                        end;
                    end;
                "Document Type"::"Other Absence":
                    AEBonusSetup.SetRange("AE Calc Type", AEBonusSetup."AE Calc Type"::Others);
            end;
            AEBonusSetup.SetRange("Period Code", '', "Period Code");
            if AESetupCode <> '' then
                AEBonusSetup.SetRange("Setup Code", AESetupCode);

            ElementInclusion.Reset();
            case "Document Type" of
                "Document Type"::Vacation:
                    ElementInclusion.SetRange(Type, ElementInclusion.Type::Vacation);
                "Document Type"::"Sick Leave":
                    ElementInclusion.SetRange(Type, ElementInclusion.Type::"Sick Leave");
                "Document Type"::Travel:
                    ElementInclusion.SetRange(Type, ElementInclusion.Type::Travel);
                "Document Type"::"Other Absence":
                    ElementInclusion.SetRange(Type, ElementInclusion.Type::Other);
            end;
            ElementInclusion.SetRange("Period Code", '', "Period Code");

            // Insert entries from AE period
            DtldPayrollLedgEntry.Reset();
            DtldPayrollLedgEntry.SetCurrentKey("Employee No.");
            DtldPayrollLedgEntry.SetRange("Employee No.", "Employee No.");
            DtldPayrollLedgEntry.SetRange("Period Code", "AE Period From", "AE Period To");
            if DtldPayrollLedgEntry.FindSet then
                repeat
                    CreateDocLineAEfromEntry(DtldPayrollLedgEntry, ElementInclusion, "Document No.", "Line No.");
                until DtldPayrollLedgEntry.Next = 0;

            SkipCurrentPeriod := AECalcSetup."Exclude Current Period" or
              (AECalcSetup."Days for Calc Type" = AECalcSetup."Days for Calc Type"::"Whole Year");

            if not SkipCurrentPeriod then begin
                PayrollDocLineAE.Reset();
                PayrollDocLineAE.SetRange("Document No.", "Document No.");
                PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
                if PayrollDocLineAE.IsEmpty then begin
                    PayrollPeriod.Get("AE Period From");
                    PrevAEPeriodFrom := PayrollPeriod.PeriodByDate(CalcDate('<-1Y>', PayrollPeriod."Ending Date"));
                    PayrollPeriod.Get("AE Period To");
                    PrevAEPeriodTo := PayrollPeriod.PeriodByDate(CalcDate('<-1Y>', PayrollPeriod."Ending Date"));
                    DtldPayrollLedgEntry.SetRange("Period Code", PrevAEPeriodFrom, PrevAEPeriodTo);
                    if DtldPayrollLedgEntry.FindSet then
                        repeat
                            CreateDocLineAEfromEntry(DtldPayrollLedgEntry, ElementInclusion, "Document No.", "Line No.");
                        until DtldPayrollLedgEntry.Next = 0;
                    "AE Period From" := PrevAEPeriodFrom;
                    "AE Period To" := PrevAEPeriodTo;
                end;

                if "Period Code" = "AE Period To" then
                    CreateDocLinesAEfromDocument(ElementInclusion, "Document No.", "Line No.");
            end;

            // Process bonus entries
            CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Monthly, false);
            CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Quarterly, false);
            CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::"Semi-Annual", false);
            CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Annual, false);

            // Insert current period entries if no other AE entries found
            if not SkipCurrentPeriod then begin
                PayrollDocLineAE.Reset();
                PayrollDocLineAE.SetRange("Document No.", "Document No.");
                PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
                if PayrollDocLineAE.IsEmpty then begin
                    CreateDocLinesAEfromDocument(ElementInclusion, "Document No.", "Line No.");
                    "AE Period From" := "Period Code";
                    "AE Period To" := "Period Code";
                    // Process bonus entries for current period
                    CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Monthly, true);
                    CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Quarterly, true);
                    CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::"Semi-Annual", true);
                    CalcAEBonusEntries(PayrollDocLine, AEBonusSetup, PayrollDocLineAE."Bonus Type"::Annual, true);
                end;

                // Insert base salary entry if no other AE entries found
                PayrollDocLineAE.Reset();
                PayrollDocLineAE.SetRange("Document No.", "Document No.");
                PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
                if PayrollDocLineAE.IsEmpty then begin
                    PayrollDocLineAE.Init();
                    PayrollDocLineAE."Document No." := "Document No.";
                    PayrollDocLineAE."Document Line No." := "Line No.";
                    PayrollDocLineAE."Source Type" := PayrollDocLineAE."Source Type"::Salary;
                    PayrollDocLineAE."Ledger Entry No." := 0;
                    PayrollDocLineAE."Element Type" := PayrollDocLineAE."Element Type"::Wage;
                    HRSetup.TestField("Element Code Salary Days");
                    PayrollDocLineAE."Element Code" := HRSetup."Element Code Salary Days";
                    PayrollPeriod.Get("Period Code");
                    PayrollDocLineAE.Amount :=
                      PayrollDocCalculate.GetBaseSalary("Employee No.", PayrollPeriod) +
                      PayrollDocCalculate.GetExtraSalary("Employee No.", PayrollPeriod);
                    PayrollDocLineAE."Inclusion Factor" := 1;
                    PayrollDocLineAE."Amount for AE" :=
                      Round(PayrollDocLineAE.Amount * PayrollDocLineAE."Inclusion Factor");
                    PayrollDocLineAE."Wage Period Code" := "Period Code";
                    PayrollDocLineAE."Period Code" := "Period Code";
                    PayrollElement2.Get(PayrollDocLineAE."Element Code");
                    PayrollDocLineAE."Salary Indexation" := PayrollElement2."Use Indexation";
                    PayrollDocLineAE.Insert();

                    "AE Period From" := "Period Code";
                    "AE Period To" := "Period Code";
                end;
            end;

            // Process external income if any
            if "Document Type" = "Document Type"::"Sick Leave" then begin
                Employee.Get("Employee No.");
                PersonIncomeLine.Reset();
                PersonIncomeLine.SetRange("Person No.", Employee."Person No.");
                PersonIncomeLine.SetRange("Period Code", "AE Period From", "AE Period To");
                PersonIncomeLine.SetRange(Calculation, false);
                PersonIncomeLine.SetRange("Exclude from Calculation", false);
                if PersonIncomeLine.FindSet then
                    repeat
                        CreateDocLineAEfromIncome(PersonIncomeLine, "Document No.", "Line No.");
                        if AECalcSetup."Use Excluded Days" then begin
                            PersonIncomeLine.CalcFields("Excluded Days");
                            "Excluded Days" += PersonIncomeLine."Excluded Days";
                            Modify;
                        end;
                    until PersonIncomeLine.Next = 0;
            end;

            exit(CalcDocLineAEPeriods(PayrollDocLine, AECalcSetup));
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcAEBonusEntries(PayrollDocLine: Record "Payroll Document Line"; var AEBonusSetup: Record "AE Calculation Setup"; BonusType: Option " ",Monthly,Quarterly,"Semi-Annual",Annual; CurrentPeriod: Boolean)
    var
        TempAEBuffer: Record "Payroll AE Buffer" temporary;
        BonusAmt: Decimal;
        BonusQty: Decimal;
    begin
        // Process bonus entries
        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineAE.SetRange("Bonus Type", BonusType);
        if CurrentPeriod then
            PayrollDocLineAE.SetRange("Period Code", PayrollDocLine."Period Code");
        if PayrollDocLineAE.IsEmpty then
            exit;

        AEBonusSetup.SetRange("Bonus Type", BonusType);
        AEBonusSetup.FindLast;
        case AEBonusSetup."AE Bonus Calc Method" of
            AEBonusSetup."AE Bonus Calc Method"::Full:
                // Set factor 1 to all
                PayrollDocLineAE.ModifyAll("Inclusion Factor", 1, true);
            AEBonusSetup."AE Bonus Calc Method"::Average:
                begin
                    BonusAmt := 0;
                    BonusQty := 0;
                    if PayrollDocLineAE.FindSet then
                        repeat
                            BonusAmt += PayrollDocLineAE.Amount;
                            BonusQty += 1;
                        until PayrollDocLineAE.Next = 0;
                    if PayrollDocLineAE.FindLast then begin
                        PayrollDocLineAE.Validate("Amount for AE",
                          Round(BonusAmt / BonusQty));
                        PayrollDocLineAE.Modify();
                    end;
                end;
            AEBonusSetup."AE Bonus Calc Method"::Minimum:
                begin
                    TempAEBuffer.DeleteAll();
                    if PayrollDocLineAE.FindSet then
                        repeat
                            if not TempAEBuffer.Get(
                                 PayrollDocLineAE."Period Code", PayrollDocLineAE."Element Code")
                            then begin
                                TempAEBuffer.Init();
                                TempAEBuffer."Period Code" := PayrollDocLineAE."Period Code";
                                TempAEBuffer."Element Code" := PayrollDocLineAE."Element Code";
                                TempAEBuffer.Amount := PayrollDocLineAE.Amount;
                                TempAEBuffer."Entry No." := PayrollDocLineAE."Ledger Entry No.";
                                TempAEBuffer.Insert();
                            end else
                                if PayrollDocLineAE.Amount < TempAEBuffer.Amount then begin
                                    TempAEBuffer.Amount := PayrollDocLineAE.Amount;
                                    TempAEBuffer."Entry No." := PayrollDocLineAE."Ledger Entry No.";
                                    TempAEBuffer.Modify();
                                end;
                        until PayrollDocLineAE.Next = 0;

                    if TempAEBuffer.FindSet then
                        repeat
                            PayrollDocLineAE.SetRange("Period Code", TempAEBuffer."Period Code");
                            PayrollDocLineAE.SetRange("Element Code", TempAEBuffer."Element Code");
                            if PayrollDocLineAE.FindSet then
                                repeat
                                    if PayrollDocLineAE."Ledger Entry No." = TempAEBuffer."Entry No." then begin
                                        PayrollDocLineAE.Validate("Amount for AE", TempAEBuffer.Amount);
                                        PayrollDocLineAE.Modify();
                                    end else
                                        PayrollDocLineAE.Delete();
                                until PayrollDocLineAE.Next = 0;
                        until TempAEBuffer.Next = 0;
                end;
            AEBonusSetup."AE Bonus Calc Method"::Maximum:
                begin
                    TempAEBuffer.DeleteAll();
                    if PayrollDocLineAE.FindSet then
                        repeat
                            if not TempAEBuffer.Get(
                                 PayrollDocLineAE."Period Code", PayrollDocLineAE."Element Code")
                            then begin
                                TempAEBuffer.Init();
                                TempAEBuffer."Period Code" := PayrollDocLineAE."Period Code";
                                TempAEBuffer."Element Code" := PayrollDocLineAE."Element Code";
                                TempAEBuffer.Amount := PayrollDocLineAE.Amount;
                                TempAEBuffer."Entry No." := PayrollDocLineAE."Ledger Entry No.";
                                TempAEBuffer.Insert();
                            end else
                                if PayrollDocLineAE.Amount > TempAEBuffer.Amount then begin
                                    TempAEBuffer.Amount := PayrollDocLineAE.Amount;
                                    TempAEBuffer."Entry No." := PayrollDocLineAE."Ledger Entry No.";
                                    TempAEBuffer.Modify();
                                end;
                        until PayrollDocLineAE.Next = 0;

                    if TempAEBuffer.FindSet then
                        repeat
                            PayrollDocLineAE.SetRange("Period Code", TempAEBuffer."Period Code");
                            PayrollDocLineAE.SetRange("Element Code", TempAEBuffer."Element Code");
                            if PayrollDocLineAE.FindSet then
                                repeat
                                    if PayrollDocLineAE."Ledger Entry No." = TempAEBuffer."Entry No." then begin
                                        PayrollDocLineAE.Validate("Amount for AE", TempAEBuffer.Amount);
                                        PayrollDocLineAE.Modify();
                                    end else
                                        PayrollDocLineAE.Delete();
                                until PayrollDocLineAE.Next = 0;
                        until TempAEBuffer.Next = 0;
                end;
            AEBonusSetup."AE Bonus Calc Method"::Last:
                if PayrollDocLineAE.FindLast then begin
                    PayrollDocLineAE.Validate("Amount for AE", PayrollDocLineAE.Amount);
                    PayrollDocLineAE.Modify();
                end;
            AEBonusSetup."AE Bonus Calc Method"::"Match by Period":
                if PayrollDocLineAE.FindSet then
                    repeat
                        PayrollPeriod.Get(PayrollDocLine."Period Code");
                        if (PayrollDocLineAE."Wage Period Code" >=
                            PayrollPeriod.PeriodByDate(CalcDate(
                                StrSubstNo('<-%1M>', AECalcSetup."AE Calc Months"), PayrollPeriod."Ending Date"))) and
                           (PayrollDocLineAE."Wage Period Code" <= PayrollDocLine."Period Code")
                        then begin
                            PayrollDocLineAE.Validate("Amount for AE", PayrollDocLineAE.Amount);
                            PayrollDocLineAE.Modify();
                        end;
                    until PayrollDocLineAE.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcDocLineAEPeriods(var PayrollDocLine: Record "Payroll Document Line"; AECalcSetup: Record "AE Calculation Setup"): Decimal
    var
        DtldPayrollLedgerEntry: Record "Detailed Payroll Ledger Entry";
        PayrollDocLineAE2: Record "Payroll Document Line AE";
        TempPayrollDocumentLineAE: Record "Payroll Document Line AE" temporary;
        PeriodNo: Integer;
        PayrollLedgEntryNo: Integer;
        BaseSalary: Decimal;
        ExtraSalary: Decimal;
        BonusAmount: Decimal;
        AddPeriod: Integer;
        NoYears: Integer;
        I: Integer;
        PeriodCodeFrom: Code[10];
        PeriodCodeTo: Code[10];
    begin
        HRSetup.Get();
        HRSetup.TestField("Excl. Days Group Code");
        Employee.Get(PayrollDocLine."Employee No.");

        // Find current salary
        PayrollPeriod.Get(PayrollDocLine."Period Code");
        BaseSalary := PayrollDocCalculate.GetBaseSalary(PayrollDocLine."Employee No.", PayrollPeriod);
        ExtraSalary := PayrollDocCalculate.GetExtraSalary(PayrollDocLine."Employee No.", PayrollPeriod);

        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineAE.SetRange("Period Code", PayrollDocLine."Period Code");
        if not PayrollDocLineAE.IsEmpty then begin
            PeriodNo := 0;
            AddPeriod := 1;
            PayrollPeriod.Reset();
            PayrollPeriod.SetFilter(Code, '%1..%2|%3',
              PayrollDocLine."AE Period From", PayrollDocLine."AE Period To", PayrollPeriod.Code);
        end else begin
            PeriodNo := 1;
            AddPeriod := 0;
            PayrollPeriod.Reset();
            PayrollPeriod.SetRange(Code, PayrollDocLine."AE Period From", PayrollDocLine."AE Period To");
        end;
        PayrollDocLineAE.SetRange("Period Code");

        if PayrollPeriod.Find('+') then
            repeat
                PayrollPeriodAE.Init();
                PayrollPeriodAE."Document No." := PayrollDocLine."Document No.";
                PayrollPeriodAE."Line No." := PayrollDocLine."Line No.";
                PayrollPeriodAE."Period Code" := PayrollPeriod.Code;
                PayrollPeriodAE."Period No." := PeriodNo;
                PayrollPeriodAE.Month := Date2DMY(PayrollPeriod."Ending Date", 2);
                PayrollPeriodAE.Year := Date2DMY(PayrollPeriod."Ending Date", 3);
                PeriodNo := PeriodNo + 1;
                if (Employee."Termination Date" <> 0D) and
                   (Employee."Termination Date" >= PayrollPeriod."Starting Date") and
                   (Employee."Termination Date" <= PayrollPeriod."Ending Date")
                then
                    PayrollPeriodAE."Period End Date" := Employee."Termination Date"
                else
                    PayrollPeriodAE."Period End Date" := PayrollPeriod."Ending Date";
                if (Employee."Employment Date" >= PayrollPeriod."Starting Date") and
                   (Employee."Employment Date" <= PayrollPeriod."Ending Date")
                then
                    PayrollPeriodAE."Period Start Date" := Employee."Employment Date"
                else
                    PayrollPeriodAE."Period Start Date" := PayrollPeriod."Starting Date";
                PayrollDocLineAE.SetRange("Period Code", PayrollPeriod.Code);
                if PayrollDocLineAE.FindSet then
                    repeat
                        if PayrollDocLineAE."Bonus Type" = 0 then begin
                            if PayrollDocLineAE."Source Type" <> PayrollDocLineAE."Source Type"::"External Income" then
                                PayrollElement2.Get(PayrollDocLineAE."Element Code");
                            PayrollPeriodAE."Salary Amount" += PayrollDocLineAE."Amount for AE";
                            if PayrollElement2."Depends on Salary Element" <> '' then
                                PayrollPeriodAE."Extra Salary" += PayrollDocLineAE."Amount for AE";
                        end else
                            PayrollPeriodAE."Bonus Amount" += PayrollDocLineAE."Amount for AE";
                    until PayrollDocLineAE.Next = 0;

                CalcPeriodAEDays(PayrollPeriodAE, PayrollDocLine, AECalcSetup."Use Excluded Days");

                // Update bonus amount
                if PayrollPeriodAE."Planned Work Days" <> PayrollPeriodAE."Actual Work Days" then
                    PayrollDocLineAE.SetRange("Bonus Type", PayrollDocLineAE."Bonus Type"::Monthly);
                if PayrollDocLineAE.FindSet then
                    repeat
                        PayrollElement.Get(PayrollDocLineAE."Element Code");
                        if not PayrollElement."Fixed Amount Bonus" and
                          (AEBonusSetup."AE Bonus Calc Method" <> AEBonusSetup."AE Bonus Calc Method"::Full)
                        then begin
                            BonusAmount := PayrollDocLineAE."Amount for AE";
                            PayrollDocLineAE.Validate("Inclusion Factor",
                              PayrollPeriodAE."Actual Work Days" / PayrollPeriodAE."Planned Work Days");
                            PayrollDocLineAE.Modify();
                            PayrollPeriodAE."Bonus Amount" := PayrollPeriodAE."Bonus Amount" -
                              BonusAmount + PayrollDocLineAE."Amount for AE";
                        end;
                    until PayrollDocLineAE.Next = 0;
                PayrollDocLineAE.SetRange("Bonus Type");

                PayrollPeriodAE."Base Salary" :=
                  PayrollDocCalculate.GetBaseSalary(PayrollDocLine."Employee No.", PayrollPeriod);
                PayrollPeriodAE."Indexation Factor" := 1;
                PeriodCodeFrom := PayrollPeriod.Code;
                PayrollPeriodAE.Insert();
            until (PayrollPeriod.Next(-1) = 0) or (PeriodNo > AECalcSetup."AE Calc Months" + AddPeriod);

        CalcIndexationFactor(PeriodCodeFrom, PayrollDocLine);

        // Update out of AE period bonus amount
        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineAE.SetFilter("Wage Period Code", '<%1', PayrollDocLine."AE Period From");
        PayrollDocLineAE.SetRange("Element Type", PayrollDocLineAE."Element Type"::Bonus);
        if PayrollDocLineAE.FindSet then begin
            // calculate whole AE period planned and fact days
            PayrollPeriodAE.Reset();
            PayrollPeriodAE.SetRange("Document No.", PayrollDocLine."Document No.");
            PayrollPeriodAE.SetRange("Line No.", PayrollDocLine."Line No.");
            PayrollPeriodAE.CalcSums("Planned Work Days", "Actual Work Days");

            repeat
                DtldPayrollLedgerEntry.Get(PayrollDocLineAE."Ledger Entry No.");
                PayrollLedgEntryNo := DtldPayrollLedgerEntry."Payroll Ledger Entry No.";

                // look for the lines with the same Payroll Ledger Entry No.
                PayrollDocLineAE2.SetRange("Document No.", PayrollDocLine."Document No.");
                PayrollDocLineAE2.SetRange("Document Line No.", PayrollDocLine."Line No.");
                PayrollDocLineAE2.SetRange("Element Type", PayrollDocLineAE2."Element Type"::Bonus);
                PayrollDocLineAE2.SetRange("Source Type", PayrollDocLineAE2."Source Type"::"Ledger Entry");
                if PayrollDocLineAE2.FindSet then
                    repeat
                        if DtldPayrollLedgerEntry.Get(PayrollDocLineAE2."Ledger Entry No.") then
                            if DtldPayrollLedgerEntry."Payroll Ledger Entry No." = PayrollLedgEntryNo then
                                if not TempPayrollDocumentLineAE.Get(
                                     PayrollDocLineAE2."Document No.", PayrollDocLineAE2."Document Line No.", PayrollDocLineAE2."Wage Period Code",
                                     PayrollDocLineAE2."Source Type", PayrollDocLineAE2."Ledger Entry No.")
                                then begin
                                    TempPayrollDocumentLineAE := PayrollDocLineAE2;
                                    TempPayrollDocumentLineAE.Insert();
                                end;
                    until PayrollDocLineAE2.Next = 0;
            until PayrollDocLineAE.Next = 0;

            if TempPayrollDocumentLineAE.FindSet then
                repeat
                    PayrollDocLineAE.Get(
                      TempPayrollDocumentLineAE."Document No.",
                      TempPayrollDocumentLineAE."Document Line No.",
                      TempPayrollDocumentLineAE."Wage Period Code",
                      TempPayrollDocumentLineAE."Source Type",
                      TempPayrollDocumentLineAE."Ledger Entry No.");
                    PayrollDocLineAE.Validate("Inclusion Factor",
                      PayrollPeriodAE."Actual Work Days" / PayrollPeriodAE."Planned Work Days");
                    PayrollDocLineAE.Modify();
                until TempPayrollDocumentLineAE.Next = 0;
        end;

        // Updated indexed amounts
        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
        if PayrollDocLineAE.FindSet then
            repeat
                PayrollPeriodAE.SetRange("Document No.", PayrollDocLine."Document No.");
                PayrollPeriodAE.SetRange("Line No.", PayrollDocLine."Line No.");
                PayrollPeriodAE.SetRange("Period Code", PayrollDocLineAE."Period Code");
                if PayrollPeriodAE.FindFirst then begin
                    PayrollElement.Get(PayrollDocLineAE."Element Code");
                    if (PayrollElement.Type = PayrollElement.Type::Bonus) and PayrollElement."Fixed Amount Bonus" then
                        PayrollDocLineAE."Indexed Amount for AE" := PayrollDocLineAE."Amount for AE"
                    else
                        PayrollDocLineAE."Indexed Amount for AE" :=
                          PayrollPeriodAE."Indexation Factor" * PayrollDocLineAE."Amount for AE";
                    PayrollDocLineAE.Modify();
                end;
            until PayrollDocLineAE.Next = 0;

        // update amount for FSI
        if AECalcSetup."Days for Calc Type" = AECalcSetup."Days for Calc Type"::"Whole Year" then begin
            NoYears := AECalcSetup."AE Calc Months" / 12;
            I := 0;
            while I < NoYears do begin
                PayrollPeriod.Get(PayrollDocLine."AE Period From");
                PayrollPeriod.Next(I * 12);
                PeriodCodeFrom := PayrollPeriod.Code;
                PayrollPeriod.Next(I * 12 + 11);
                PeriodCodeTo := PayrollPeriod.Code;
                UpdateFSIAmounts(PayrollDocLine, PeriodCodeFrom, PeriodCodeTo, AECalcSetup."Use FSI Limits");
                I := I + 1;
            end;
        end;

        // calculate average earnings
        CalcExcludedDays(PayrollDocLine, AECalcSetup."Use Excluded Days");
        if AECalcSetup."Days for Calc Type" <> AECalcSetup."Days for Calc Type"::"Whole Year" then begin
            PayrollDocLine.CalcFields("AE Total Earnings", "AE Total Days", "AE Total Earnings Indexed");
            if PayrollDocLine."AE Total Days" <> 0 then
                PayrollDocLine.Validate("AE Daily Earnings",
                  Round(
                    PayrollDocLine."AE Total Earnings Indexed" /
                    (PayrollDocLine."AE Total Days" - PayrollDocLine."Excluded Days")));
        end else begin
            PayrollDocLine.CalcFields("AE Total FSI Earnings", "AE Total Days");
            if PayrollDocLine."AE Total Days" <> 0 then
                PayrollDocLine.Validate(
                  "AE Daily Earnings",
                  Round(
                    PayrollDocLine."AE Total FSI Earnings" /
                    (PayrollDocLine."AE Total Days" - PayrollDocLine."Excluded Days")));
        end;
        PayrollDocLine.Modify();

        exit(PayrollDocLine."AE Daily Earnings");
    end;

    [Scope('OnPrem')]
    procedure CalcPeriodAEDays(var PayrollPeriodAE: Record "Payroll Period AE"; PayrollDocLine: Record "Payroll Document Line"; UseExcludedDays: Boolean)
    begin
        PayrollPeriodAE."Planned Calendar Days" :=
          CalendarMgt.GetPeriodInfo(
            HRSetup."Official Calendar Code",
            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 1);
        PayrollPeriodAE."Absence Days" :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", HRSetup."Absence Group Code",
            PayrollPeriodAE."Period Start Date", PayrollPeriodAE."Period End Date", 2);
        PayrollPeriodAE."Actual Calendar Days" :=
          CalendarMgt.GetPeriodInfo(
            HRSetup."Official Calendar Code",
            PayrollPeriodAE."Period Start Date", PayrollPeriodAE."Period End Date", 1) -
          PayrollPeriodAE."Absence Days";
        PayrollPeriodAE."Planned Work Days" :=
          CalendarMgt.GetPeriodInfo(
            HRSetup."Official Calendar Code",
            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 2);
        PayrollPeriodAE."Actual Work Days" :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", HRSetup."Work Time Group Code",
            PayrollPeriodAE."Period Start Date", PayrollPeriodAE."Period End Date", 4);

        case PayrollDocLine."Document Type" of
            PayrollDocLine."Document Type"::Vacation:
                begin
                    AECalcSetup.TestField("Average Month Days");
                    if PayrollPeriodAE."Actual Calendar Days" <> 0 then
                        PayrollPeriodAE."Average Days" :=
                          Round(AECalcSetup."Average Month Days" *
                            (PayrollPeriodAE."Actual Calendar Days" / PayrollPeriodAE."Planned Calendar Days"))
                    else
                        if PayrollPeriodAE."Salary Amount" = 0 then
                            PayrollPeriodAE."Average Days" := 0
                        else
                            PayrollPeriodAE."Average Days" :=
                              Round(AECalcSetup."Average Month Days");
                end;
            PayrollDocLine."Document Type"::"Sick Leave":
                begin
                    if AECalcSetup."Days for Calc Type" = AECalcSetup."Days for Calc Type"::"Whole Year" then begin
                        PayrollPeriodAE."Average Days" := PayrollPeriodAE."Planned Calendar Days";
                        if not UseExcludedDays and (Date2DMY(PayrollPeriodAE."Period End Date", 1) = 29) then
                            PayrollPeriodAE."Average Days" := 28;
                    end else
                        if PayrollPeriodAE."Planned Calendar Days" = PayrollPeriodAE."Actual Calendar Days" then
                            PayrollPeriodAE."Average Days" := PayrollPeriodAE."Planned Calendar Days"
                        else
                            if (PayrollPeriodAE."Actual Calendar Days" <> 0) or
                               (PayrollPeriodAE."Salary Amount" = 0)
                            then
                                PayrollPeriodAE."Average Days" :=
                                  PayrollPeriodAE."Actual Calendar Days"
                            else
                                if PayrollPeriodAE."Salary Amount" <> 0 then
                                    PayrollPeriodAE."Average Days" :=
                                      PayrollPeriodAE."Planned Calendar Days"
                                else
                                    PayrollPeriodAE."Average Days" := 0;
                end;
            PayrollDocLine."Document Type"::Travel,
            PayrollDocLine."Document Type"::"Other Absence":
                begin
                    if PayrollPeriodAE."Actual Work Days" <> 0 then
                        PayrollPeriodAE."Average Days" := PayrollPeriodAE."Actual Work Days"
                    else
                        PayrollPeriodAE."Average Days" := PayrollPeriodAE."Planned Work Days";
                end;
            PayrollDocLine."Document Type"::" ": // Dismissal
                PayrollPeriodAE."Average Days" := PayrollPeriodAE."Planned Work Days";
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDocLineAEfromEntry(DtldPayrollLedgEntry: Record "Detailed Payroll Ledger Entry"; var ElementInclusion: Record "Payroll Element Inclusion"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        ElementInclusion.SetRange("Element Code", DtldPayrollLedgEntry."Element Code");
        if ElementInclusion.FindLast then begin
            PayrollDocLineAE.Init();
            PayrollDocLineAE."Document No." := DocumentNo;
            PayrollDocLineAE."Document Line No." := LineNo;
            PayrollDocLineAE."Source Type" := PayrollDocLineAE."Source Type"::"Ledger Entry";
            PayrollDocLineAE."Ledger Entry No." := DtldPayrollLedgEntry."Entry No.";
            PayrollDocLineAE."Element Type" := DtldPayrollLedgEntry."Element Type";
            PayrollDocLineAE."Element Code" := DtldPayrollLedgEntry."Element Code";
            PayrollDocLineAE.Amount := DtldPayrollLedgEntry."Payroll Amount";
            if DtldPayrollLedgEntry."Element Type" = DtldPayrollLedgEntry."Element Type"::Wage then
                PayrollDocLineAE."Inclusion Factor" := 1;
            PayrollDocLineAE."Amount for AE" := Round(PayrollDocLineAE.Amount * PayrollDocLineAE."Inclusion Factor");
            PayrollDocLineAE."Wage Period Code" := DtldPayrollLedgEntry."Wage Period Code";
            PayrollDocLineAE."Period Code" := DtldPayrollLedgEntry."Period Code";
            PayrollDocLineAE."Bonus Type" := DtldPayrollLedgEntry."Bonus Type";
            PayrollDocLineAE."Salary Indexation" := DtldPayrollLedgEntry."Salary Indexation";
            PayrollDocLineAE."Depends on Salary Element" := DtldPayrollLedgEntry."Depends on Salary Element";
            PayrollDocLineAE.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDocLinesAEfromDocument(var ElementInclusion: Record "Payroll Element Inclusion"; DocumentNo: Code[20]; LineNo: Integer)
    var
        PayrollDocLine: Record "Payroll Document Line";
    begin
        PayrollDocLine.Reset();
        PayrollDocLine.SetRange("Document No.", DocumentNo);
        PayrollDocLine.SetFilter("Payroll Amount", '<>%1', 0);
        if PayrollDocLine.FindSet then
            repeat
                ElementInclusion.SetRange("Element Code", PayrollDocLine."Element Code");
                if ElementInclusion.FindLast then begin
                    PayrollDocLineAE.Init();
                    PayrollDocLineAE."Document No." := DocumentNo;
                    PayrollDocLineAE."Document Line No." := LineNo;
                    PayrollDocLineAE."Source Type" := PayrollDocLineAE."Source Type"::"Payroll Document";
                    PayrollDocLineAE."Ledger Entry No." := PayrollDocLine."Line No.";
                    PayrollDocLineAE."Element Type" := PayrollDocLine."Element Type";
                    PayrollDocLineAE."Element Code" := PayrollDocLine."Element Code";
                    PayrollDocLineAE.Amount := PayrollDocLine."Payroll Amount";
                    PayrollDocLineAE."Inclusion Factor" := 1;
                    PayrollDocLineAE."Amount for AE" :=
                      Round(PayrollDocLineAE.Amount * PayrollDocLineAE."Inclusion Factor");
                    PayrollDocLineAE."Wage Period Code" := PayrollDocLine."Wage Period From";
                    PayrollDocLineAE."Period Code" := PayrollDocLine."Period Code";
                    PayrollDocLineAE."Salary Indexation" := PayrollDocLine."Salary Indexation";
                    PayrollDocLineAE."Depends on Salary Element" := PayrollDocLine."Depends on Salary Element";
                    PayrollDocLineAE.Insert();
                end;
            until PayrollDocLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateDocLineAEfromIncome(PersonIncomeLine: Record "Person Income FSI"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        PayrollDocLineAE.Init();
        PayrollDocLineAE."Document No." := DocumentNo;
        PayrollDocLineAE."Document Line No." := LineNo;
        PayrollDocLineAE."Source Type" := PayrollDocLineAE."Source Type"::"External Income";
        PayrollDocLineAE."Ledger Entry No." := 0;
        PayrollDocLineAE."Element Type" := PayrollDocLineAE."Element Type"::Wage;
        HRSetup.TestField("Element Code Salary Days");
        PayrollDocLineAE."Element Code" := HRSetup."Element Code Salary Days";
        PayrollDocLineAE.Amount := PersonIncomeLine.Amount;
        PayrollDocLineAE."Inclusion Factor" := 1;
        PayrollDocLineAE."Amount for AE" := Round(PayrollDocLineAE.Amount * PayrollDocLineAE."Inclusion Factor");
        PayrollDocLineAE."Wage Period Code" := PersonIncomeLine."Period Code";
        PayrollDocLineAE."Period Code" := PersonIncomeLine."Period Code";
        PayrollDocLineAE.Insert();
    end;

    [Scope('OnPrem')]
    procedure UpdateFSIAmounts(PayrollDocLine: Record "Payroll Document Line"; PeriodCodeFrom: Code[10]; PeriodCodeTo: Code[10]; UseFSILimit: Boolean)
    var
        FSILimit: Decimal;
    begin
        PayrollPeriodAE.Reset();
        PayrollPeriodAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollPeriodAE.SetRange("Line No.", PayrollDocLine."Line No.");

        if UseFSILimit then begin
            FSILimit := PayrollDocCalculate.GetFSILimit(PeriodCodeFrom, 1);
            if FSILimit = 0 then
                Error(Text001, PeriodCodeFrom);
        end;

        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineAE.SetRange("Period Code", PeriodCodeFrom, PeriodCodeTo);
        if PayrollDocLineAE.FindSet(true, false) then
            repeat
                if not ((PayrollDocLineAE."Element Type" = PayrollDocLineAE."Element Type"::Bonus) and
                   (PayrollDocLineAE.Amount < 0)) then begin
                    if UseFSILimit then begin
                        if PayrollDocLineAE.Amount <= FSILimit then begin
                            PayrollDocLineAE."Amount for FSI" := PayrollDocLineAE.Amount;
                            FSILimit -= PayrollDocLineAE.Amount;
                        end else begin
                            PayrollDocLineAE."Amount for FSI" := FSILimit;
                            FSILimit := 0;
                        end;
                    end else
                        PayrollDocLineAE."Amount for FSI" := PayrollDocLineAE.Amount;
                    PayrollPeriodAE.SetRange("Period Code", PayrollDocLineAE."Period Code");
                    if PayrollPeriodAE.FindFirst then begin
                        PayrollPeriodAE."Amount for FSI" += PayrollDocLineAE."Amount for FSI";
                        PayrollPeriodAE.Modify();
                    end;
                    PayrollDocLineAE.Modify();
                end;
            until PayrollDocLineAE.Next = 0;
    end;

    local procedure CalcIndexationFactor(PeriodFrom: Code[10]; PayrollDocLine: Record "Payroll Document Line")
    var
        PayrollStatus: Record "Payroll Status";
        IndexationFactor: Decimal;
        PrevPeriodCode: Code[10];
    begin
        PayrollPeriod.Reset();
        PayrollPeriod.SetRange(Code, PeriodFrom, PayrollDocLine."Period Code");
        if PayrollPeriod.FindSet then
            repeat
                if PayrollStatus.Get(PayrollPeriod.Code, PayrollDocLine."Employee No.") then
                    if PayrollStatus.HasSalaryIndexation(IndexationFactor) then
                        if PayrollPeriod.GetPrevPeriod(PrevPeriodCode) then begin
                            PayrollPeriodAE.SetRange("Document No.", PayrollDocLine."Document No.");
                            PayrollPeriodAE.SetRange("Line No.", PayrollDocLine."Line No.");
                            PayrollPeriodAE.SetRange("Period Code", PeriodFrom, PrevPeriodCode);
                            if PayrollPeriodAE.FindSet(true) then
                                repeat
                                    PayrollPeriodAE."Indexation Factor" *= IndexationFactor;
                                    PayrollPeriodAE.Modify();
                                until PayrollPeriodAE.Next = 0;
                        end;
            until PayrollPeriod.Next = 0
    end;

    [Scope('OnPrem')]
    procedure CalcExcludedDays(var PayrollDocLine: Record "Payroll Document Line"; UseExcludedDays: Boolean)
    begin
        PayrollDocLine."Days To Exclude" :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", HRSetup."Excl. Days Group Code",
            PayrollDocLine."Action Starting Date", PayrollDocLine."Action Ending Date", 2);

        if UseExcludedDays then
            PayrollDocLine."Excluded Days" +=
              TimesheetMgt.GetTimesheetInfo(
                PayrollDocLine."Employee No.", HRSetup."Excl. Days Group Code",
                PayrollPeriod.PeriodStartDateByPeriodCode(PayrollDocLine."AE Period From"),
                PayrollPeriod.PeriodEndDateByPeriodCode(PayrollDocLine."AE Period To"), 2);
        PayrollDocLine.Modify();
    end;
}

