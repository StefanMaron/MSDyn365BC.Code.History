codeunit 17370 "Labor Contract Management"
{
    Permissions = TableData "Employee Job Entry" = rim,
                  TableData "Employee Absence Entry" = rim,
                  TableData "Employee Ledger Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        Position: Record Position;
        Person: Record Person;
        Employee: Record Employee;
        LaborContract: Record "Labor Contract";
        LaborContractTerms: Record "Labor Contract Terms";
        LaborContractTermsSetup: Record "Labor Contract Terms Setup";
        HumanResSetup: Record "Human Resources Setup";
        EmplJobEntry: Record "Employee Job Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        PayrollPeriod: Record "Payroll Period";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        TimesheetStatus: Record "Timesheet Status";
        PayrollElement: Record "Payroll Element";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NextEntryNo: Integer;
        Text001: Label '%1 already exists. Recalculate?';
        Text002: Label '%1 and %2 should not be 0 at the same time.';
        Text003: Label 'Do you want to approve %1?';
        OrderNo: Code[20];
        OrderDate: Date;
        Text004: Label 'Accrual for %1 %2 for period %3 %4 already exist.';
        SkipSalTermsCheck: Boolean;
        SkipVacTermsCheck: Boolean;
        Text005: Label 'Do you want to cancel %1 approval?';
        Text006: Label '%1 should not be %2 for period %3.';
        Text007: Label '%1 has already been terminated.';
        Text008: Label 'The Middle Name is not specified in Person No.=%1\Do you want to continue?';

    [Scope('OnPrem')]
    procedure CreateContractTerms(LaborContractLine: Record "Labor Contract Line"; HideDialog: Boolean)
    begin
        with LaborContractLine do begin
            if not LaborContract.Get("Contract No.") then
                exit;

            if LaborContract.Status = LaborContract.Status::Closed then
                LaborContract.FieldError(Status);

            LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
            LaborContractTerms.SetRange("Operation Type", "Operation Type");
            LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
            if LaborContractTerms.FindFirst then begin
                if not HideDialog then
                    if Confirm(Text001, true, LaborContractTerms.TableCaption) then
                        LaborContractTerms.DeleteAll
                    else
                        exit
                else
                    LaborContractTerms.DeleteAll();
            end;

            Position.Get("Position No.");
            Position.TestField("Category Code");
            Position.TestField("Base Salary Element Code");

            LaborContract.Get("Contract No.");
            LaborContract.TestField("Person No.");
            Person.Get(LaborContract."Person No.");

            // add base salary for new position
            if "Operation Type" in ["Operation Type"::Hire, "Operation Type"::Transfer] then begin
                LaborContractTerms.Init();
                LaborContractTerms."Labor Contract No." := "Contract No.";
                LaborContractTerms."Operation Type" := "Operation Type";
                LaborContractTerms."Supplement No." := "Supplement No.";
                LaborContractTerms."Line Type" := LaborContractTerms."Line Type"::"Payroll Element";
                LaborContractTerms.Validate("Element Code", Position."Base Salary Element Code");
                LaborContractTerms."Starting Date" := "Starting Date";
                LaborContractTerms."Ending Date" := "Ending Date";
                LaborContractTerms."Posting Group" := Position."Posting Group";
                LaborContractTerms.Amount := Position."Base Salary";
                if not LaborContractTerms.Insert() then
                    LaborContractTerms.Modify();
            end;

            // add other position payroll elements
            LaborContractTermsSetup.Reset();
            LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Position);
            LaborContractTermsSetup.SetRange("No.", Position."No.");
            LaborContractTermsSetup.SetFilter("Operation Type", '%1|%2',
              "Operation Type" + 1, LaborContractTermsSetup."Operation Type"::All);
            if "Ending Date" <> 0D then
                LaborContractTermsSetup.SetRange("Start Date", 0D, "Ending Date");
            LaborContractTermsSetup.SetFilter("End Date", '%1|%2..', 0D, "Starting Date");
            if LaborContractTermsSetup.FindSet then
                repeat
                    InsertContractTerms(LaborContractLine, LaborContractTermsSetup);
                until LaborContractTermsSetup.Next = 0;

            // add personal payroll elements
            LaborContractTermsSetup.Reset();
            LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Person);
            LaborContractTermsSetup.SetRange("No.", Person."No.");
            LaborContractTermsSetup.SetFilter("Operation Type", '%1|%2',
              "Operation Type" + 1, LaborContractTermsSetup."Operation Type"::All);
            if "Ending Date" <> 0D then
                LaborContractTermsSetup.SetRange("Start Date", 0D, "Ending Date");
            LaborContractTermsSetup.SetFilter("End Date", '%1|%2..', 0D, "Starting Date");
            if LaborContractTermsSetup.FindSet then
                repeat
                    InsertContractTerms(LaborContractLine, LaborContractTermsSetup);
                until LaborContractTermsSetup.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertContractTerms(LaborContractLine2: Record "Labor Contract Line"; LaborContractTermsSetup2: Record "Labor Contract Terms Setup")
    begin
        with LaborContractTerms do begin
            Init;
            SetRange("Labor Contract No.", LaborContractLine2."Contract No.");
            SetRange("Operation Type", LaborContractLine2."Operation Type");
            SetRange("Supplement No.", LaborContractLine2."Supplement No.");
            SetRange("Line Type", LaborContractTermsSetup2.Type);
            SetRange("Element Code", LaborContractTermsSetup2."Element Code");
            SetRange("Starting Date", LaborContractTermsSetup2."Start Date");
            if FindFirst then begin
                if Amount < LaborContractTermsSetup.Amount then begin
                    Amount := LaborContractTermsSetup.Amount;
                    Modify;
                end;
            end else begin
                Init;
                "Labor Contract No." := LaborContractLine2."Contract No.";
                "Operation Type" := LaborContractLine2."Operation Type";
                "Supplement No." := LaborContractLine2."Supplement No.";
                "Starting Date" := LaborContractLine2."Starting Date";
                if "Starting Date" < LaborContractTermsSetup2."Start Date" then
                    "Starting Date" := LaborContractTermsSetup2."Start Date";
                "Ending Date" := LaborContractLine2."Ending Date";
                if "Ending Date" = 0D then
                    "Ending Date" := LaborContractTermsSetup2."End Date"
                else
                    if ("Ending Date" > LaborContractTermsSetup2."End Date") and (LaborContractTermsSetup2."End Date" <> 0D) then
                        "Ending Date" := LaborContractTermsSetup2."End Date";
                case LaborContractTermsSetup.Type of
                    LaborContractTermsSetup.Type::"Payroll Element":
                        begin
                            "Line Type" := "Line Type"::"Payroll Element";
                            LaborContractTermsSetup.TestField("Element Code");
                            Validate("Element Code", LaborContractTermsSetup."Element Code");
                            Validate("Posting Group", Position."Posting Group");
                            Validate(Amount, LaborContractTermsSetup.Amount);
                            Validate(Quantity, LaborContractTermsSetup.Quantity);
                            Validate(Percent, LaborContractTermsSetup.Percent);
                        end;
                    LaborContractTermsSetup.Type::"Vacation Accrual":
                        begin
                            "Line Type" := "Line Type"::"Vacation Accrual";
                            LaborContractTermsSetup.TestField("Element Code");
                            Validate("Element Code", LaborContractTermsSetup."Element Code");
                            if "Starting Date" <> 0D then begin
                                "Starting Date" := "Starting Date";
                                "Ending Date" := CalcDate('<1Y-1D>', "Starting Date");
                            end;
                            Validate(Quantity, LaborContractTermsSetup.Quantity);
                        end;
                end;
                if not Insert then
                    Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PostContractTerms(LaborContractLine: Record "Labor Contract Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        EmplJnlLine: Record "Employee Journal Line";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        EmplJnlPostLine: Codeunit "Employee Journal - Post Line";
        AECalcMgt: Codeunit "AE Calc Management";
    begin
        with LaborContractLine do begin
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Employee Journal");

            LaborContractTerms.Reset();
            LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
            LaborContractTerms.SetRange("Operation Type", "Operation Type");
            LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
            LaborContractTerms.SetRange("Line Type", LaborContractTerms."Line Type"::"Vacation Accrual");
            if not LaborContractTerms.IsEmpty then begin
                EmplAbsenceEntry.Reset();
                NextEntryNo := EmplAbsenceEntry.GetLastEntryNo() + 1;
            end;
            LaborContractTerms.SetRange("Line Type");
            if LaborContractTerms.FindSet then
                repeat
                    case LaborContractTerms."Line Type" of
                        LaborContractTerms."Line Type"::"Payroll Element":
                            begin
                                EmplJnlLine.Init();
                                EmplJnlLine."Employee No." := LaborContract."Employee No.";
                                EmplJnlLine."Posting Date" := "Order Date";
                                EmplJnlLine."Starting Date" := LaborContractTerms."Starting Date";
                                EmplJnlLine."Ending Date" := LaborContractTerms."Ending Date";
                                if EmplJnlLine."Period Code" = '' then
                                    EmplJnlLine."Period Code" :=
                                      PayrollPeriod.PeriodByDate(EmplJnlLine."Starting Date");
                                EmplJnlLine.Description := LaborContractTerms.Description;
                                EmplJnlLine.Validate("Element Code", LaborContractTerms."Element Code");
                                if (LaborContractTerms.Amount = 0) and (LaborContractTerms.Quantity = 0) then
                                    Error(Text002,
                                      LaborContractTerms.FieldCaption(Amount),
                                      LaborContractTerms.FieldCaption(Quantity));
                                EmplJnlLine.Amount := LaborContractTerms.Amount;
                                EmplJnlLine.Quantity := LaborContractTerms.Quantity;
                                if LaborContractTerms.Percent <> 0 then
                                    EmplJnlLine.Quantity := LaborContractTerms.Percent;
                                Position.Get("Position No.");
                                EmplJnlLine.Validate("Posting Group", LaborContractTerms."Posting Group");
                                EmplJnlLine.Validate("Currency Code", LaborContractTerms."Currency Code");
                                EmplJnlLine.Validate("Calendar Code", Position."Calendar Code");
                                EmplJnlLine.Validate("Payroll Calc Group", Position."Calc Group Code");
                                EmplJnlLine.Validate("Contract No.", LaborContract."No.");
                                EmplJnlLine."HR Order No." := "Order No.";
                                EmplJnlLine."HR Order Date" := "Order Date";
                                EmplJnlLine."Source Code" := SourceCodeSetup."Employee Journal";
                                EmplJnlLine."Salary Indexation" := LaborContractTerms."Salary Indexation";
                                EmplJnlLine."Depends on Salary Element" := LaborContractTerms."Depends on Salary Element";
                                PayrollElement.Get(LaborContractTerms."Element Code");
                                if PayrollElement.IsAECalc then begin
                                    EmplJnlLine."Document Type" := EmplJnlLine."Document Type"::Vacation;
                                    AECalcMgt.FillDismissalAEDates(EmplJnlLine);
                                end;
                                EmplJnlPostLine.RunWithCheck(EmplJnlLine);
                            end;
                        LaborContractTerms."Line Type"::"Vacation Accrual":
                            begin
                                EmplAbsenceEntry.Reset();
                                EmplAbsenceEntry.SetCurrentKey("Employee No.");
                                EmplAbsenceEntry.SetRange("Employee No.", LaborContract."Employee No.");
                                EmplAbsenceEntry.SetRange("Time Activity Code", LaborContractTerms."Time Activity Code");
                                EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Accrual);
                                EmplAbsenceEntry.SetRange("Start Date",
                                  LaborContractTerms."Starting Date", CalcDate('<1Y-1D>', LaborContractTerms."Starting Date"));
                                if not EmplAbsenceEntry.IsEmpty then
                                    Error(Text004,
                                      LaborContract."Employee No.", LaborContractTerms."Time Activity Code",
                                      LaborContractTerms."Starting Date", CalcDate('<1Y-1D>', LaborContractTerms."Starting Date"));

                                EmplAbsenceEntry.Init();
                                EmplAbsenceEntry."Entry No." := NextEntryNo;
                                NextEntryNo := NextEntryNo + 1;
                                EmplAbsenceEntry."Entry Type" := EmplAbsenceEntry."Entry Type"::Accrual;
                                EmplAbsenceEntry."Employee No." := LaborContract."Employee No.";
                                EmplAbsenceEntry."Element Code" := LaborContractTerms."Element Code";
                                EmplAbsenceEntry."Time Activity Code" := LaborContractTerms."Time Activity Code";
                                EmplAbsenceEntry."Position No." := "Position No.";
                                EmplAbsenceEntry."Person No." := "Person No.";
                                EmplAbsenceEntry."Start Date" := LaborContractTerms."Starting Date";
                                EmplAbsenceEntry."End Date" := CalcDate('<1Y-1D>', EmplAbsenceEntry."Start Date");
                                LaborContractTerms.TestField(Quantity);
                                EmplAbsenceEntry."Calendar Days" := LaborContractTerms.Quantity;
                                EmplAbsenceEntry.Insert();
                            end;
                    end;
                until LaborContractTerms.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ConfirmApprove(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField(Status, Status::Open);
            if Confirm(Text003, true, "Operation Type") then
                DoApprove(LaborContractLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure DoApprove(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField(Status, Status::Open);

            case "Operation Type" of
                "Operation Type"::Hire:
                    Hire(LaborContractLine, '');
                "Operation Type"::Transfer:
                    Transfer(LaborContractLine);
                "Operation Type"::Combination:
                    Combine(LaborContractLine);
                "Operation Type"::Dismissal:
                    Dismiss(LaborContractLine);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure Hire(var LaborContractLine: Record "Labor Contract Line"; PersonNo: Code[20])
    var
        AltAddrReg: Record "Alternative Address";
        AltAddrPerm: Record "Alternative Address";
        RegAddrExist: Boolean;
        PermAddrExist: Boolean;
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Hire);
            CalcFields("Salary Terms", "Vacation Terms");
            if not SkipSalTermsCheck then
                TestField("Salary Terms", true);

            LaborContract.Get("Contract No.");
            case LaborContract."Contract Type" of
                LaborContract."Contract Type"::"Labor Contract":
                    if not SkipVacTermsCheck then
                        TestField("Vacation Terms", true);
                LaborContract."Contract Type"::"Civil Contract":
                    LaborContract.TestField("Ending Date");
            end;

            CheckLine;
            CheckPosition(LaborContractLine);

            Person.Get(LaborContract."Person No.");
            Person.TestField("First Name");
            if Person."Middle Name" = '' then
                if not Confirm(Text008, false, Person."No.") then
                    exit;
            Person.TestField("Last Name");
            Person.TestField("Birth Date");
            Person.TestField(Gender);

            Position.Get("Position No.");

            // create Employee card
            if LaborContract."Employee No." <> '' then
                Employee.Get(LaborContract."Employee No.")
            else begin
                Employee.Init();
                Employee."No." := PersonNo;
            end;
            Employee.Validate("Person No.", LaborContract."Person No.");
            Employee.Validate("Position No.", "Position No.");
            Employee."Contract No." := "Contract No.";

            AltAddrReg.Reset();
            AltAddrReg.SetRange("Person No.", Person."No.");
            AltAddrReg.SetRange("Address Type", AltAddrReg."Address Type"::Registration);
            RegAddrExist := AltAddrReg.FindLast;

            AltAddrPerm.Reset();
            AltAddrPerm.SetRange("Person No.", Person."No.");
            AltAddrPerm.SetRange("Address Type", AltAddrPerm."Address Type"::Permanent);
            PermAddrExist := AltAddrPerm.FindLast;

            if RegAddrExist then begin
                CopyAltAddr(Employee, AltAddrReg);
                if PermAddrExist then begin
                    Employee."Alt. Address Code" := AltAddrPerm.Code;
                    Employee."Alt. Address Start Date" := AltAddrPerm."Valid from Date";
                end;
            end else
                if PermAddrExist then
                    CopyAltAddr(Employee, AltAddrPerm);

            if LaborContract."Employee No." = '' then
                Employee.Insert(true);

            LaborContract."Employee No." := Employee."No.";
            LaborContract.Status := LaborContract.Status::Approved;
            LaborContract.Modify();

            // Update Job History
            EmplJobEntry.Reset();
            NextEntryNo := EmplJobEntry.GetLastEntryNo() + 1;

            if OrderNo <> '' then
                "Order No." := OrderNo;
            if OrderDate <> 0D then
                "Order Date" := OrderDate;

            if "Order No." = '' then begin
                HumanResSetup.Get();
                HumanResSetup.TestField("HR Order Nos.");
                "Order No." := NoSeriesMgt.GetNextNo(HumanResSetup."HR Order Nos.", WorkDate, true);
            end;
            if "Order Date" = 0D then
                "Order Date" := WorkDate;

            EmplJobEntry.Init();
            EmplJobEntry."Entry No." := NextEntryNo;
            EmplJobEntry.Validate("Employee No.", Employee."No.");
            EmplJobEntry.Type := EmplJobEntry.Type::Hire;
            EmplJobEntry."Contract No." := "Contract No.";
            EmplJobEntry."Supplement No." := "Supplement No.";
            EmplJobEntry.Validate("Person No.", LaborContract."Person No.");
            EmplJobEntry.Validate("Position No.", "Position No.");
            EmplJobEntry."Position Rate" := "Position Rate";
            EmplJobEntry."Starting Date" := "Starting Date";
            EmplJobEntry."Ending Date" := "Ending Date";
            if LaborContract."Insured Service" then begin
                EmplJobEntry."Insured Period Starting Date" := "Starting Date";
                EmplJobEntry."Insured Period Ending Date" := "Ending Date";
            end;
            EmplJobEntry."Uninterrupted Service" := LaborContract."Uninterrupted Service";
            EmplJobEntry."Document No." := "Order No.";
            EmplJobEntry."Document Date" := "Order Date";
            EmplJobEntry."Position Changed" := true;
            EmplJobEntry."Territorial Conditions" := "Territorial Conditions";
            EmplJobEntry."Special Conditions" := "Special Conditions";
            EmplJobEntry."Record of Service Reason" := "Record of Service Reason";
            EmplJobEntry."Record of Service Additional" := "Record of Service Additional";
            EmplJobEntry."Service Years Reason" := "Service Years Reason";
            EmplJobEntry.Insert();

            PostContractTerms(LaborContractLine);

            Status := Status::Approved;
            Modify;
            Commit();

            Employee.Validate("Employment Date", "Starting Date");
            Employee.Validate("Emplymt. Contract Code", LaborContract."Contract Type Code");
            Employee.Modify();
        end;
    end;

    local procedure Combine(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Combination);
            TestField("Ending Date");

            CheckLine;
            CheckPosition(LaborContractLine);

            LaborContract.Get("Contract No.");
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            if "Order No." = '' then begin
                HumanResSetup.Get();
                HumanResSetup.TestField("HR Order Nos.");
                "Order No." := NoSeriesMgt.GetNextNo(HumanResSetup."HR Order Nos.", WorkDate, true);
            end;
            if "Order Date" = 0D then
                "Order Date" := WorkDate;

            EmplJobEntry.Reset();
            NextEntryNo := EmplJobEntry.GetLastEntryNo() + 1;

            EmplJobEntry.Init();
            EmplJobEntry."Entry No." := NextEntryNo;
            EmplJobEntry.Validate("Employee No.", Employee."No.");
            EmplJobEntry."Contract No." := "Contract No.";
            EmplJobEntry."Supplement No." := "Supplement No.";
            EmplJobEntry.Validate("Person No.", LaborContract."Person No.");
            EmplJobEntry.Validate("Position No.", "Position No.");
            EmplJobEntry."Position Rate" := "Position Rate";
            EmplJobEntry."Starting Date" := "Starting Date";
            EmplJobEntry."Ending Date" := "Ending Date";
            if LaborContract."Insured Service" then begin
                EmplJobEntry."Insured Period Starting Date" := "Starting Date";
                EmplJobEntry."Insured Period Ending Date" := "Ending Date";
            end;
            EmplJobEntry."Uninterrupted Service" := LaborContract."Uninterrupted Service";
            EmplJobEntry."Document No." := "Order No.";
            EmplJobEntry."Document Date" := "Order Date";
            EmplJobEntry."Position Changed" := true;
            EmplJobEntry."Territorial Conditions" := "Territorial Conditions";
            EmplJobEntry."Special Conditions" := "Special Conditions";
            EmplJobEntry."Record of Service Reason" := "Record of Service Reason";
            EmplJobEntry."Record of Service Additional" := "Record of Service Additional";
            EmplJobEntry."Service Years Reason" := "Service Years Reason";
            EmplJobEntry.Insert();

            PostContractTerms(LaborContractLine);

            Status := Status::Approved;
            Modify;
            Commit();
        end;
    end;

    local procedure Transfer(var LaborContractLine: Record "Labor Contract Line")
    var
        EmplJobEntry2: Record "Employee Job Entry";
        Position2: Record Position;
        TimesheetMgt: Codeunit "Timesheet Management RU";
        NextEntryNo: Integer;
        CalendarChanged: Boolean;
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Transfer);
            TestField("Supplement No.");

            LaborContract.Get("Contract No.");
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            CheckLine;
            if LaborContract."Contract Type" = LaborContract."Contract Type"::"Civil Contract" then
                TestField("Ending Date");

            CheckPosition(LaborContractLine);

            // Update Job History
            EmplJobEntry.Reset();
            NextEntryNo := EmplJobEntry.GetLastEntryNo() + 1;

            // close job enties for previous position
            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Position No.", Employee."Position No.");
            EmplJobEntry.SetRange("Position Changed", true);
            if EmplJobEntry.FindLast then begin
                CheckTransferDate(EmplJobEntry."Supplement No.", EmplJobEntry."Document No.", EmplJobEntry."Document Date");
                EmplJobEntry."Ending Date" := CalcDate('<-1D>', "Starting Date");
                if LaborContract."Insured Service" then
                    EmplJobEntry."Insured Period Ending Date" := EmplJobEntry."Ending Date";
                EmplJobEntry.Modify();
                EmplJobEntry2 := EmplJobEntry;
                EmplJobEntry2."Entry No." := NextEntryNo;
                NextEntryNo := NextEntryNo + 1;
                EmplJobEntry2."Document No." := "Order No.";
                EmplJobEntry2."Document Date" := "Order Date";
                EmplJobEntry2."Position Rate" := -EmplJobEntry2."Position Rate";
                EmplJobEntry2."Position Changed" := false;
                EmplJobEntry2."Starting Date" := "Starting Date";
                EmplJobEntry2."Insured Period Starting Date" := 0D;
                EmplJobEntry2."Insured Period Ending Date" := 0D;
                EmplJobEntry2.Insert();
            end;

            // Update parent positions
            Position2.Reset();
            Position2.SetCurrentKey("Parent Position No.");
            Position2.SetRange("Parent Position No.", Employee."Position No.");
            Position2.ModifyAll("Parent Position No.", "Position No.");

            // update Employee card
            Employee.Get(LaborContract."Employee No.");
            if Employee."Position No." <> "Position No." then begin
                CalendarChanged := false;
                if Employee."Calendar Code" <> Position."Calendar Code" then
                    CalendarChanged := true;
                Employee.Validate("Position No.", "Position No.");
                Employee.Modify();
            end;

            // Update Job History
            EmplJobEntry.Reset();
            NextEntryNo := EmplJobEntry.GetLastEntryNo() + 1;

            if OrderNo <> '' then
                "Order No." := OrderNo;
            if OrderDate <> 0D then
                "Order Date" := OrderDate;

            if "Order No." = '' then begin
                HumanResSetup.Get();
                HumanResSetup.TestField("HR Order Nos.");
                "Order No." := NoSeriesMgt.GetNextNo(HumanResSetup."HR Order Nos.", WorkDate, true);
            end;
            if "Order Date" = 0D then
                "Order Date" := WorkDate;

            // create new job entry
            EmplJobEntry.Init();
            EmplJobEntry."Entry No." := NextEntryNo;
            EmplJobEntry.Validate("Employee No.", Employee."No.");
            EmplJobEntry."Contract No." := "Contract No.";
            EmplJobEntry."Supplement No." := "Supplement No.";
            EmplJobEntry.Validate("Person No.", LaborContract."Person No.");
            EmplJobEntry.Validate("Position No.", "Position No.");
            EmplJobEntry."Position Rate" := "Position Rate";
            EmplJobEntry."Starting Date" := "Starting Date";
            EmplJobEntry."Ending Date" := "Ending Date";
            EmplJobEntry.Type := EmplJobEntry.Type::Transfer;
            if LaborContract."Insured Service" then begin
                EmplJobEntry."Insured Period Starting Date" := "Starting Date";
                EmplJobEntry."Insured Period Ending Date" := "Ending Date";
            end;
            EmplJobEntry."Uninterrupted Service" := LaborContract."Uninterrupted Service";
            EmplJobEntry."Document No." := "Order No.";
            EmplJobEntry."Document Date" := "Order Date";
            EmplJobEntry."Position Changed" := true;
            EmplJobEntry."Territorial Conditions" := "Territorial Conditions";
            EmplJobEntry."Special Conditions" := "Special Conditions";
            EmplJobEntry.Insert();

            PostContractTerms(LaborContractLine);

            // update timesheet
            if CalendarChanged then begin
                // IMPORTANT: Calendar change is only possible for new payroll period
                if Date2DMY("Starting Date", 1) <> 1 then
                    FieldError("Starting Date");

                Employee."Calendar Code" := Position."Calendar Code";
                TimesheetStatus.SetRange("Employee No.", Employee."No.");
                if "Ending Date" = 0D then
                    TimesheetStatus.SetFilter("Period Code", '%1..',
                      PayrollPeriod.PeriodByDate("Starting Date"))
                else
                    TimesheetStatus.SetRange("Period Code",
                      PayrollPeriod.PeriodByDate("Starting Date"),
                      PayrollPeriod.PeriodByDate("Ending Date"));
                if TimesheetStatus.FindSet then
                    repeat
                        PayrollPeriod.Get(TimesheetStatus."Period Code");
                        if PayrollPeriod.Code = PayrollPeriod.PeriodByDate("Starting Date") then
                            TimesheetMgt.UpdateTimesheet(
                              Employee, "Starting Date", PayrollPeriod."Ending Date", Position."Calendar Code", true)
                        else
                            TimesheetMgt.UpdateTimesheet(
                              Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
                              Position."Calendar Code", true);
                    until TimesheetStatus.Next = 0;
            end;

            Status := Status::Approved;
            Modify;
            Commit();
        end;
    end;

    local procedure Dismiss(LaborContractLine: Record "Labor Contract Line")
    var
        EmplJobEntry2: Record "Employee Job Entry";
        TimesheetLine: Record "Timesheet Line";
        PayrollStatus: Record "Payroll Status";
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Dismissal);
            TestField("Starting Date");
            TestField("Ending Date");
            TestField("Dismissal Reason");

            CheckDateOrder;

            // close main contract and line
            LaborContract.Get("Contract No.");
            Employee.Get(LaborContract."Employee No.");
            LaborContract.Status := LaborContract.Status::Closed;
            LaborContract.Modify();

            // check payroll status
            PayrollStatus.Get(
              PayrollPeriod.PeriodByDate("Ending Date"), Employee."No.");
            if PayrollStatus."Payroll Status" > PayrollStatus."Payroll Status"::Calculated then
                Error(Text006,
                  PayrollStatus.TableCaption,
                  PayrollStatus."Payroll Status",
                  PayrollPeriod.PeriodByDate("Ending Date"));

            // Update Job History
            EmplJobEntry.Reset();
            NextEntryNo := EmplJobEntry.GetLastEntryNo() + 1;

            if OrderNo <> '' then
                "Order No." := OrderNo;
            if OrderDate <> 0D then
                "Order Date" := OrderDate;

            if "Order No." = '' then begin
                HumanResSetup.Get();
                HumanResSetup.TestField("HR Order Nos.");
                "Order No." := NoSeriesMgt.GetNextNo(HumanResSetup."HR Order Nos.", WorkDate, true);
            end;
            if "Order Date" = 0D then
                "Order Date" := WorkDate;

            // close job entry for current position
            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Position No.", Employee."Position No.");
            EmplJobEntry.SetRange("Position Changed", true);
            if EmplJobEntry.FindLast then begin
                EmplJobEntry."Ending Date" := "Ending Date";
                EmplJobEntry.Modify();
                EmplJobEntry2 := EmplJobEntry;
                EmplJobEntry2."Entry No." := NextEntryNo;
                NextEntryNo := NextEntryNo + 1;
                EmplJobEntry2."Document No." := "Order No.";
                EmplJobEntry2."Document Date" := "Order Date";
                EmplJobEntry2."Position Rate" := -EmplJobEntry2."Position Rate";
                EmplJobEntry2."Position Changed" := false;
                EmplJobEntry2."Starting Date" := "Ending Date";
                EmplJobEntry2.Insert();
            end;

            // update Employee card
            Employee.Get(LaborContract."Employee No.");
            Employee.Validate("Termination Date", "Ending Date");
            Employee.Validate("Grounds for Term. Code", "Dismissal Reason");
            Employee.Status := Employee.Status::Terminated;
            Employee.Modify();

            // remove timesheets after dismissal period
            TimesheetStatus.Reset();
            TimesheetStatus.SetRange("Employee No.", Employee."No.");
            TimesheetStatus.SetFilter("Period Code", '%1..',
              PayrollPeriod.PeriodByDate(CalcDate('<CM +1D>', Employee."Termination Date")));
            TimesheetStatus.DeleteAll(true);

            TimesheetLine.Reset();
            TimesheetLine.SetRange("Employee No.", Employee."No.");
            TimesheetLine.SetFilter(Date, '>%1', Employee."Termination Date");
            TimesheetLine.DeleteAll(true);

            // remove payroll status after dismissal period
            PayrollStatus.Reset();
            PayrollStatus.SetRange("Employee No.", Employee."No.");
            PayrollStatus.SetFilter("Period Code", '%1..',
              PayrollPeriod.PeriodByDate(CalcDate('<CM +1D>', Employee."Termination Date")));
            PayrollStatus.DeleteAll(true);

            // close line

            // close existing salary records
            EmplLedgEntry.Reset();
            EmplLedgEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplLedgEntry.SetRange("Action Ending Date", 0D);
            EmplLedgEntry.ModifyAll("Action Ending Date", "Starting Date");

            // update last vacation period calculation entry
            UpdateLastVacPeriodCalcEntry(LaborContract."Employee No.", "Ending Date", false);

            PostContractTerms(LaborContractLine);

            Status := Status::Approved;
            Modify;
            Commit();
        end;
    end;

    [Scope('OnPrem')]
    procedure TerminateCombination(LaborContractLine: Record "Labor Contract Line")
    var
        EmplJobEntry2: Record "Employee Job Entry";
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Combination);
            TestField(Status, Status::Approved);
            TestField("Ending Date");

            LaborContract.Get("Contract No.");
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Contract No.", LaborContract."No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Position No.", "Position No.");
            EmplJobEntry.SetRange("Position Changed", true);
            EmplJobEntry.SetRange(Type, EmplJobEntry.Type::" ");
            EmplJobEntry.SetRange("Supplement No.", "Supplement No.");
            EmplJobEntry.SetRange("Document No.", "Order No.");
            EmplJobEntry.SetRange("Document Date", "Order Date");
            if EmplJobEntry.FindLast then begin
                NextEntryNo := EmplJobEntry."Entry No." + 1;
                EmplJobEntry."Ending Date" := "Ending Date";
                EmplJobEntry.Modify();
                EmplJobEntry2 := EmplJobEntry;
                EmplJobEntry2."Entry No." := NextEntryNo;
                EmplJobEntry2."Position Rate" := -EmplJobEntry2."Position Rate";
                EmplJobEntry2."Position Changed" := false;
                EmplJobEntry2.Insert();
            end;

            EmplLedgEntry.Reset();
            EmplLedgEntry.SetRange("Contract No.", "Contract No.");
            EmplLedgEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplLedgEntry.SetRange("HR Order No.", "Order No.");
            EmplLedgEntry.SetRange("HR Order Date", "Order Date");
            EmplLedgEntry.ModifyAll("Action Ending Date", "Ending Date");

            Modify;
            Commit();
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertContracts(var GroupOrderLine: Record "Group Order Line")
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContracts: Page "Labor Contracts";
        ChangeLogMgt: Codeunit "Change Log Management";
        RecRef: RecordRef;
        LaborContractCount: Integer;
        GroupOrderLineNo: Integer;
        i: Integer;
    begin
        LaborContract.FilterGroup(2);
        if GroupOrderLine."Document Type" = GroupOrderLine."Document Type"::Hire then
            LaborContract.SetRange(Status, LaborContract.Status::Open)
        else
            LaborContract.SetRange(Status, LaborContract.Status::Open, LaborContract.Status::Approved);
        LaborContract.FilterGroup(0);
        if LaborContract.FindSet then
            repeat
                LaborContractLine.SetRange("Contract No.", LaborContract."No.");
                LaborContractLine.SetRange(Status, LaborContractLine.Status::Open);
                case GroupOrderLine."Document Type" of
                    GroupOrderLine."Document Type"::Hire:
                        LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Hire);
                    GroupOrderLine."Document Type"::Dismissal:
                        LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Dismissal);
                    GroupOrderLine."Document Type"::Transfer:
                        LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Transfer);
                end;
                if not LaborContractLine.IsEmpty then
                    LaborContract.Mark(true);
            until LaborContract.Next = 0;

        LaborContract.MarkedOnly(true);
        LaborContracts.SetTableView(LaborContract);
        LaborContracts.LookupMode(true);

        if LaborContracts.RunModal = ACTION::LookupOK then begin
            LaborContracts.SetSelection(LaborContract);
            LaborContractCount := LaborContract.Count();
            if LaborContractCount > 0 then begin
                GroupOrderLineNo := GroupOrderLine."Line No.";
                GroupOrderLine.SetRange("Document Type", GroupOrderLine."Document Type");
                GroupOrderLine.SetRange("Document No.", GroupOrderLine."Document No.");
                if GroupOrderLine.FindLast then
                    repeat
                        i := GroupOrderLine."Line No.";
                        if i >= GroupOrderLineNo then begin
                            GroupOrderLine.Delete();
                            GroupOrderLine."Line No." := i + 10000 * LaborContractCount;
                            GroupOrderLine.Insert();
                        end;
                    until (i <= GroupOrderLineNo) or (GroupOrderLine.Next(-1) = 0);

                if GroupOrderLineNo = 0 then
                    GroupOrderLineNo := 10000;

                if LaborContract.FindSet then
                    repeat
                        GroupOrderLine.Init();
                        GroupOrderLine."Line No." := GroupOrderLineNo;
                        GroupOrderLineNo := GroupOrderLineNo + 10000;
                        GroupOrderLine.Validate("Contract No.", LaborContract."No.");
                        GroupOrderLine.Insert();
                        RecRef.GetTable(GroupOrderLine);
                        ChangeLogMgt.LogInsertion(RecRef);
                    until LaborContract.Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetOrderNoDate(OrderNo2: Code[20]; OrderDate2: Date)
    begin
        OrderNo := OrderNo2;
        OrderDate := OrderDate2;
    end;

    [Scope('OnPrem')]
    procedure CopyAltAddr(var Employee: Record Employee; AltAddr: Record "Alternative Address")
    begin
        Employee.Address := CopyStr(AltAddr.Address, 1, 50);
        Employee.City := AltAddr.City;
        Employee."Post Code" := AltAddr."Post Code";
        Employee."Country/Region Code" := AltAddr."Country/Region Code";
        Employee."Phone No." := AltAddr."Phone No.";
        Employee."Fax No." := AltAddr."Fax No.";
        Employee."E-Mail" := AltAddr."E-Mail"
    end;

    [Scope('OnPrem')]
    procedure ConfirmCancelApproval(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField(Status, Status::Approved);
            if Confirm(Text005, false, "Operation Type") then
                UndoApproval(LaborContractLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure UndoApproval(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField(Status, Status::Approved);

            case "Operation Type" of
                "Operation Type"::Hire:
                    UndoHire(LaborContractLine, '');
                "Operation Type"::Transfer:
                    UndoTransfer(LaborContractLine);
                "Operation Type"::Combination:
                    UndoCombine(LaborContractLine);
                "Operation Type"::Dismissal:
                    UndoDismiss(LaborContractLine);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UndoHire(var LaborContractLine: Record "Labor Contract Line"; PersonNo: Code[20])
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Hire);

            LaborContract.Get("Contract No.");
            if LaborContract.Status = LaborContract.Status::Closed then
                LaborContract.FieldError(Status);
            Employee.Get(LaborContract."Employee No.");

            EmplJobEntry.Reset();
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Document No.", "Order No.");
            EmplJobEntry.SetRange("Document Date", "Order Date");
            EmplJobEntry.ModifyAll("Position Rate", 0);
            EmplJobEntry.ModifyAll("Employee No.", '');

            CancelPostedContractTerms(LaborContractLine);

            Employee.Validate("Position No.", '');
            Employee.Validate("Employment Date", 0D);
            Employee.Validate("Emplymt. Contract Code", '');
            Employee.Modify();

            TimesheetStatus.Reset();
            TimesheetStatus.SetRange("Employee No.", Employee."No.");
            TimesheetStatus.DeleteAll(true);

            LaborContract.Status := LaborContract.Status::Open;
            LaborContract.Modify();

            Status := Status::Open;
            Modify;
            Commit();
        end;
    end;

    local procedure UndoTransfer(var LaborContractLine: Record "Labor Contract Line")
    var
        CalendarChanged: Boolean;
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Transfer);
            TestField("Supplement No.");

            LaborContract.Get("Contract No.");
            if LaborContract.Status = LaborContract.Status::Closed then
                LaborContract.FieldError(Status);
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Document No.", "Order No.");
            EmplJobEntry.SetRange("Document Date", "Order Date");
            if EmplJobEntry.FindFirst then
                if Employee."Position No." <> EmplJobEntry."Position No." then begin
                    Position.Get(EmplJobEntry."Position No.");
                    Position.TestField(Status, Position.Status::Approved);
                    CalendarChanged := false;
                    if Employee."Calendar Code" <> Position."Calendar Code" then
                        CalendarChanged := true;
                    Employee.Validate("Position No.", Position."No.");
                    Employee.Modify();
                end;
            EmplJobEntry.ModifyAll("Position Rate", 0);
            EmplJobEntry.ModifyAll("Employee No.", '');

            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Position No.", Position."No.");
            EmplJobEntry.SetRange("Position Changed", true);
            if EmplJobEntry.FindLast then begin
                EmplJobEntry."Ending Date" := 0D;
                EmplJobEntry.Modify();
            end;

            CancelPostedContractTerms(LaborContractLine);

            Status := Status::Open;
            Modify;
            Commit();
        end;
    end;

    local procedure UndoDismiss(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Dismissal);

            LaborContract.Get("Contract No.");
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Document No.", "Order No.");
            EmplJobEntry.SetRange("Document Date", "Order Date");
            EmplJobEntry.ModifyAll("Position Rate", 0);
            EmplJobEntry.ModifyAll("Employee No.", '');

            EmplJobEntry.Reset();
            EmplJobEntry.SetCurrentKey("Employee No.");
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Position No.", Employee."Position No.");
            EmplJobEntry.SetRange("Position Changed", true);
            if EmplJobEntry.FindLast then begin
                EmplJobEntry."Ending Date" := 0D;
                EmplJobEntry.Modify();
            end;

            CancelPostedContractTerms(LaborContractLine);

            // update last vacation period calculation entry
            UpdateLastVacPeriodCalcEntry(LaborContract."Employee No.", "Ending Date", true);

            Employee.Validate("Termination Date", 0D);
            Employee.Validate("Grounds for Term. Code", '');
            Employee.Status := Employee.Status::Active;
            Employee.Modify();

            LaborContract.Status := LaborContract.Status::Approved;
            LaborContract.Modify();
            Status := Status::Open;
            Modify;
            Commit();
        end;
    end;

    [Scope('OnPrem')]
    procedure UndoCombine(var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            TestField("Operation Type", "Operation Type"::Combination);

            LaborContract.Get("Contract No.");
            if LaborContract.Status = LaborContract.Status::Closed then
                LaborContract.FieldError(Status);
            Employee.Get(LaborContract."Employee No.");

            EmplJobEntry.Reset();
            EmplJobEntry.SetRange("Contract No.", "Contract No.");
            EmplJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
            EmplJobEntry.SetRange("Document No.", "Order No.");
            EmplJobEntry.SetRange("Document Date", "Order Date");
            if EmplJobEntry.Count <> 1 then
                Error(Text007, "Operation Type");
            EmplJobEntry.ModifyAll("Position Rate", 0);
            EmplJobEntry.ModifyAll("Employee No.", '');

            CancelPostedContractTerms(LaborContractLine);

            Status := Status::Open;
            Modify;
            Commit();
        end;
    end;

    [Scope('OnPrem')]
    procedure CancelPostedContractTerms(LaborContractLine: Record "Labor Contract Line")
    var
        EmplAbsenceEntry: Record "Employee Absence Entry";
        PayrollStatus: Record "Payroll Status";
    begin
        with LaborContractLine do begin
            LaborContractTerms.Reset();
            LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
            LaborContractTerms.SetRange("Operation Type", "Operation Type");
            LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
            LaborContractTerms.SetRange("Line Type", LaborContractTerms."Line Type"::"Vacation Accrual");
            if LaborContractTerms.FindSet then
                repeat
                    EmplAbsenceEntry.Reset();
                    EmplAbsenceEntry.SetCurrentKey("Employee No.");
                    EmplAbsenceEntry.SetRange("Employee No.", LaborContract."Employee No.");
                    EmplAbsenceEntry.SetRange("Time Activity Code", LaborContractTerms."Time Activity Code");
                    EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Accrual);
                    EmplAbsenceEntry.SetRange(
                      "Start Date",
                      LaborContractTerms."Starting Date",
                      CalcDate('<1Y-1D>', LaborContractTerms."Starting Date"));
                    EmplAbsenceEntry.ModifyAll("Employee No.", '');
                until LaborContractTerms.Next = 0;

            LaborContractTerms.SetRange("Line Type", LaborContractTerms."Line Type"::"Payroll Element");
            if not LaborContractTerms.IsEmpty then begin
                EmplLedgEntry.Reset();
                EmplLedgEntry.SetRange("Contract No.", "Contract No.");
                EmplLedgEntry.SetRange("Employee No.", LaborContract."Employee No.");
                EmplLedgEntry.SetRange("HR Order No.", "Order No.");
                EmplLedgEntry.SetRange("HR Order Date", "Order Date");
                if EmplLedgEntry.FindSet then begin
                    repeat
                        PayrollStatus.CheckPayrollStatus(EmplLedgEntry."Period Code", EmplLedgEntry."Employee No.");
                        EmplLedgEntry."Employee No." := '';
                        EmplLedgEntry.Modify();
                    until EmplLedgEntry.Next = 0;
                end;
            end;

            if "Operation Type" = "Operation Type"::Dismissal then begin
                EmplLedgEntry.Reset();
                EmplLedgEntry.SetRange("Employee No.", LaborContract."Employee No.");
                EmplLedgEntry.SetRange("Action Ending Date", "Starting Date");
                EmplLedgEntry.ModifyAll("Action Ending Date", 0D);
            end;
        end;
    end;

    local procedure UpdateLastVacPeriodCalcEntry(EmployeeNo: Code[20]; EndingDate: Date; RestoreEndingDate: Boolean)
    var
        EmplAbsenceEntry: Record "Employee Absence Entry";
    begin
        with EmplAbsenceEntry do begin
            SetRange("Employee No.", LaborContract."Employee No.");
            SetRange("Entry Type", "Entry Type"::Accrual);
            SetFilter("Start Date", '..%1', EndingDate);
            SetFilter("End Date", '%1..', EndingDate);
            if FindFirst then begin
                if RestoreEndingDate then
                    "End Date" := CalcDate('<1Y-1D>', "Start Date")
                else
                    "End Date" := EndingDate;
                Modify;
            end;
        end;
    end;
}

