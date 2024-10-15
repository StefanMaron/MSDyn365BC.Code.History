codeunit 144204 "HRP AE Pregnancy Leave"
{
    // --------------------------------------------------
    // #   Test Function Name                     TFS ID
    // --------------------------------------------------
    // 1.  PersonExcludedDaysSickLeave            339286
    // 2.  PersonExcludedDays2SickLeave           339286
    // 3.  PersonExcludedDaysVacation             339286
    // 4.  PersonExcludedDaysBusiness             339286
    // 5.  PersonExcludedDaysOther                339286
    // 6.  AECalcForPregnIncomeTwoYears           339286
    // 7.  AECalcForPregnIncomeOneYears           339286
    // 8.  PregnLeaveCalc                         339285
    // 9.  TFS339285Scenario                      339285

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryHRP: Codeunit "Library - HRP";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Translate: Codeunit "Translate Payroll";
        PersonPregnDays: Integer;
        IsInitialized: Boolean;
        DocNotFoundErr: Label 'Payroll document for period %1 cannot be found.';
        IncorrectElementBenefitErr: Label 'Incorrect Benefit.';
        WrongExcludedDaysErr: Label 'Wrong number of Excluded Days';
        WrongAEDaysErr: Label 'Wrong number of AE Days';
        PayGovernDutiesTxt: Label 'PAY GOVERN DUTIES', Locked = true;
        PaySLPregDaysTxt: Label 'PAY SL PREG DAYS', Locked = true;
        AECalcForPregIncomeMode: Option OneYear,TwoYears;

    [Test]
    [Scope('OnPrem')]
    procedure PersonExcludedDaysSickLeave()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        PersonAbsDays: Integer;
        PeriodCounter: Integer;
    begin
        // Verify Excluded Days for Person Income FSI when having Sick Leave Order.
        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 2);
        PersonAbsDays := LibraryRandom.RandInt(14);
        repeat
            PeriodCounter += 1;
            if PeriodCounter = 2 then
                LibraryHRP.CreateSickLeaveOrder(
                  EmployeeNo, PayrollPeriod."Ending Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonAbsDays - 1,
                  LibraryHRP.FindCommonDiseaseTimeActivityCode, '', 60, 0, true);

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyPersonIncomeAbsDays(EmployeeNo, PayrollPeriod.Code, PersonAbsDays);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonExcludedDays2SickLeave()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        StartDate: Date;
        PersonAbsDays: array[2] of Integer;
    begin
        // Verify Excluded Days for Person Income FSI when having two Sick Leave Orders
        // in one Payroll Period.
        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 2);

        PersonAbsDays[1] := LibraryRandom.RandInt(14);
        PersonAbsDays[2] := LibraryRandom.RandInt(14);
        repeat
            PeriodCounter += 1;
            if PeriodCounter = 2 then begin
                StartDate := PayrollPeriod."Starting Date";
                LibraryHRP.CreateSickLeaveOrder(
                  EmployeeNo, PayrollPeriod."Ending Date", StartDate, StartDate + PersonAbsDays[1] - 1,
                  LibraryHRP.FindCommonDiseaseTimeActivityCode, '', 60, 0, true);

                StartDate := StartDate + PersonAbsDays[1];
                LibraryHRP.CreateSickLeaveOrder(
                  EmployeeNo, PayrollPeriod."Ending Date", StartDate, StartDate + PersonAbsDays[2] - 1,
                  LibraryHRP.FindCommonDiseaseTimeActivityCode, '', 60, 0, true);
            end;

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyPersonIncomeAbsDays(EmployeeNo, PayrollPeriod.Code, PersonAbsDays[1] + PersonAbsDays[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonExcludedDaysVacation()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        PersonAbsDays: Integer;
    begin
        // Verify Excluded Days for Person Income FSI when having Vacation Order.

        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 2);
        PersonAbsDays := LibraryRandom.RandInt(14);

        repeat
            PeriodCounter += 1;
            if PeriodCounter = 2 then
                LibraryHRP.CreateVacation(
                  EmployeeNo, LibraryHRP.FindRegularVacationTimeActivityCode, PayrollPeriod."Starting Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonAbsDays);

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyPersonIncomeAbsDays(EmployeeNo, PayrollPeriod.Code, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonExcludedDaysBusiness()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        PersonAbsDays: Integer;
    begin
        // Verify Excluded Days for Person Income FSI when having Business Order.
        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 2);
        PersonAbsDays := LibraryRandom.RandInt(14);
        repeat
            PeriodCounter += 1;
            if PeriodCounter = 2 then
                LibraryHRP.CreateTravelOrder(
                  EmployeeNo, PayrollPeriod."Ending Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonAbsDays,
                  LibraryHRP.FindBusTravelTimeActivityCode, true);

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyPersonIncomeAbsDays(EmployeeNo, PayrollPeriod.Code, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonExcludedDaysOther()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        PersonAbsDays: Integer;
    begin
        // Verify Excluded Days for Person Income FSI when having Other Absence Order.
        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 2);
        PersonAbsDays := LibraryRandom.RandInt(14);
        repeat
            PeriodCounter += 1;
            if PeriodCounter = 2 then
                LibraryHRP.CreateOtherAbsenceOrder(
                  EmployeeNo, PayrollPeriod."Ending Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonAbsDays,
                  LibraryHRP.FindOtherAbsenceTimeActivityCode, Translate.ElementCode(PayGovernDutiesTxt), true);

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyPersonIncomeAbsDays(EmployeeNo, PayrollPeriod.Code, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AECalcForPregnIncomeTwoYears()
    begin
        // Verify calculation of Pregnancy sick leave when having Salary reference
        // from two previous years.
        AECalcForPregnIncome(AECalcForPregIncomeMode::TwoYears)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AECalcForPregnIncomeOneYear()
    begin
        // Verify calculation of Pregnancy sick leave when having Salary reference
        // from two previous years.
        AECalcForPregnIncome(AECalcForPregIncomeMode::OneYear)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PregnLeaveCalc()
    var
        PayrollPeriod: Record "Payroll Period";
        GLSetup: Record "General Ledger Setup";
        PeriodCounter: Integer;
        NumberOfDaysPrevTwoYears: Integer;
        EmployeeNo: Code[20];
        SalaryAmt: Decimal;
    begin
        // Verify calculation of Pregnancy sick leave.
        GLSetup.Get();
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        SalaryAmt :=
          LibraryRandom.RandDecInRange(
            LibraryHRP.GetMROT(PayrollPeriod.Code), Round(LibraryHRP.GetFSILimit(PayrollPeriod.Code) / 12, 1), 2);
        InitCommonScenario(EmployeeNo, PayrollPeriod, 25, SalaryAmt);

        PayrollPeriod.FindSet();
        repeat
            PeriodCounter += 1;
            if PeriodCounter = 25 then begin
                LibraryHRP.CreateSickLeaveOrder(
                  EmployeeNo, PayrollPeriod."Ending Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonPregnDays - 1,
                  LibraryHRP.FindPregnancyTimeActivityCode, '', 100, 0, true);
                NumberOfDaysPrevTwoYears := GetNumberOfPrevTwoYearsDays(PayrollPeriod.Code);
            end;

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyExcludedDays(EmployeeNo, PayrollPeriod.Code, 0);
        VerifyAETotalDays(EmployeeNo, PayrollPeriod.Code, NumberOfDaysPrevTwoYears);
        VerifyPregnBenefit(
          EmployeeNo,
          PayrollPeriod.Code,
          Round((SalaryAmt * 24) / NumberOfDaysPrevTwoYears, GLSetup."Amount Rounding Precision") * PersonPregnDays);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS339285Scenario()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        SickLeaveDays: array[2] of Integer;
    begin
        // Verify calculation of Pregnancy sick leave when having Vacation, Business
        // trip and Sick Leave for the period.
        InitCommonScenario(EmployeeNo, PayrollPeriod, 25, 35000);
        SickLeaveDays[1] := 7; // first sick leave length
        SickLeaveDays[2] := 12; // second sick leave length

        PayrollPeriod.FindSet();
        repeat
            PeriodCounter += 1;
            case PeriodCounter of
                5: // May of first year - vacation (28 days).
                    LibraryHRP.CreateVacation(EmployeeNo, LibraryHRP.FindRegularVacationTimeActivityCode, PayrollPeriod."Starting Date",
                      PayrollPeriod."Starting Date", CalcDate('<+27D>', PayrollPeriod."Starting Date"));
                8: // August of first year -  sick leave (7 days).
                    LibraryHRP.CreateSickLeaveOrder(EmployeeNo, PayrollPeriod."Ending Date",
                      PayrollPeriod."Starting Date", CalcDate(StrSubstNo('<+%1D>', SickLeaveDays[1] - 1), PayrollPeriod."Starting Date"),
                      LibraryHRP.FindCommonDiseaseTimeActivityCode, '', 60, 0, true);
                15: // March of second year - business trip (10 days).
                    LibraryHRP.CreateTravelOrder(EmployeeNo, PayrollPeriod."Ending Date",
                      PayrollPeriod."Starting Date", CalcDate('<+9D>', PayrollPeriod."Starting Date"),
                      LibraryHRP.FindBusTravelTimeActivityCode, true);
                18: // June of second year - childcare sick leave (12 days) (Treatment Type = Out-Patient).
                    LibraryHRP.CreateSickLeaveOrder(
                      EmployeeNo, PayrollPeriod."Ending Date",
                      PayrollPeriod."Starting Date", CalcDate(StrSubstNo('<+%1D>', SickLeaveDays[2] - 1), PayrollPeriod."Starting Date"),
                      LibraryHRP.FindFamilyMemberCareSickLeaveTimeActivityCode,
                      CreateRelativeChild(GetPersonNo(EmployeeNo), 20110215D), 60, 1, true);
                25: // January of third year - pregnancy leave (140 days).
                    LibraryHRP.CreateSickLeaveOrder(EmployeeNo, PayrollPeriod."Ending Date",
                      PayrollPeriod."Starting Date", CalcDate('<+139D>', PayrollPeriod."Starting Date"),
                      LibraryHRP.FindPregnancyTimeActivityCode, '', 100, 0, true);
            end;

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        VerifyExcludedDays(EmployeeNo, PayrollPeriod.Code, SickLeaveDays[1] + SickLeaveDays[2]);
    end;

    local procedure Init()
    var
        AECalcSetup: Record "AE Calculation Setup";
        PayrollPeriod: Record "Payroll Period";
        UntilDate: Date;
    begin
        if IsInitialized then
            exit;

        PayrollPeriod.FindFirst;
        UpdateHRSetupExclDaysGroupCode(PayrollPeriod."Starting Date");
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        UntilDate := CalcDate('<+2Y+CY>', PayrollPeriod."Starting Date");
        CreatePayrollCalendLines(LibraryHRP.GetDefaultCalendarCode, UntilDate);
        CreatePayrollCalendLines(LibraryHRP.GetOfficialCalendarCode, UntilDate);
        LibraryHRP.CreatePayrollPeriodsUntil(UntilDate);

        SetAECalcSetup(AECalcSetup."AE Calc Type"::"Pregnancy Leave", true);
        SetAECalcSetup(AECalcSetup."AE Calc Type"::"Sick Leave", false);
        SetFSILimit(PayrollPeriod.Code, 463000);
        SetFSILimit(
          LibraryHRP.CalcPayrollPeriodCodeByDate(
            CalcDate('<+1Y>', PayrollPeriod."Starting Date")), 512000);
        PersonPregnDays := 140; // Number of days for pregnancy sick leave
        IsInitialized := true;
    end;

    local procedure InitCommonScenario(var EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period"; NumberOfPeriodsInTheLoop: Integer; SalaryAmount: Decimal)
    var
        LastPayrollPeriod: Record "Payroll Period";
    begin
        Init;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", SalaryAmount);
        LastPayrollPeriod.Copy(PayrollPeriod);
        LastPayrollPeriod.Next(NumberOfPeriodsInTheLoop - 1);
        PayrollPeriod.Reset();
        PayrollPeriod.SetRange(Code, PayrollPeriod.Code, LastPayrollPeriod.Code);
    end;

    local procedure InitExcludeDaysScenario(var EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period"; NumberOfPeriodsInTheLoop: Integer)
    begin
        InitCommonScenario(EmployeeNo, PayrollPeriod, NumberOfPeriodsInTheLoop, LibraryRandom.RandDec(50000, 2));
    end;

    local procedure InitAECalcForPregnIncomeScenario(Mode: Option; var PayrollPeriod: Record "Payroll Period"; var EmployeeNo: Code[20]; var PersonIncome: array[2] of Decimal; var PersonAbsDays: array[2] of Integer; var DismissalDate: Date)
    var
        i: Integer;
        PeriodCodeFilter: Code[100];
        PrevYearPeriodCode: array[2] of Code[10];
    begin
        InitExcludeDaysScenario(EmployeeNo, PayrollPeriod, 10);
        // save period code filter
        PeriodCodeFilter := CopyStr(PayrollPeriod.GetFilter(Code), 1, MaxStrLen(PeriodCodeFilter));
        DismissalDate := CalcDate('<+15M>', PayrollPeriod."Starting Date");

        // find payroll period codes for 2 previous years
        PrevYearPeriodCode[1] := LibraryHRP.FindPayrollPeriodCodeByDate(CalcDate('<-2Y-CY>', PayrollPeriod."Starting Date"));
        PrevYearPeriodCode[2] := LibraryHRP.FindPayrollPeriodCodeByDate(CalcDate('<-1Y-CY>', PayrollPeriod."Starting Date"));

        // create person income for 2 previous years
        for i := 1 to 2 do
            if not ((i = 1) and (Mode = AECalcForPregIncomeMode::OneYear)) then begin
                PersonAbsDays[i] := LibraryRandom.RandInt(14);
                PersonIncome[i] := LibraryRandom.RandDecInRange(
                  LibraryHRP.GetMROT(PrevYearPeriodCode[i]) * 12, LibraryHRP.GetFSILimit(PrevYearPeriodCode[i]), 2);
                CreatePersonIncome(GetPersonNo(EmployeeNo), PrevYearPeriodCode[i], PersonIncome[i], PersonAbsDays[i]);
            end;

        // created payroll periods for the next 2 years
        LibraryHRP.PreparePayrollPeriods(PayrollPeriod, PayrollPeriod.Code,
          LibraryHRP.CalcPayrollPeriodCodeByDate(CalcDate('<+2Y>', PayrollPeriod."Starting Date")));

        // prepare payroll period for loop
        PayrollPeriod.SetFilter(Code, PeriodCodeFilter);
        PayrollPeriod.FindSet();
    end;

    local procedure AECalcForPregnIncome(Mode: Option)
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodCounter: Integer;
        EmployeeNo: Code[20];
        PersonIncome: array[2] of Decimal;
        PersonAbsDays: array[2] of Integer;
        NumberOfDaysPrevTwoYears: Integer;
        DismissalDate: Date;
    begin
        // Verify calculation of Pregnancy sick leave when having Salary reference
        // from two previous years.
        InitAECalcForPregnIncomeScenario(Mode, PayrollPeriod, EmployeeNo, PersonIncome, PersonAbsDays, DismissalDate);

        repeat
            PeriodCounter += 1;
            if PeriodCounter = 10 then begin
                LibraryHRP.CreateSickLeaveOrder(
                  EmployeeNo, PayrollPeriod."Ending Date",
                  PayrollPeriod."Starting Date", PayrollPeriod."Starting Date" + PersonPregnDays - 1,
                  LibraryHRP.FindPregnancyTimeActivityCode, '', 100, 0, true);
                NumberOfDaysPrevTwoYears := GetNumberOfPrevTwoYearsDays(PayrollPeriod.Code);
            end;

            CalcAndPostPayrollDoc(EmployeeNo, PayrollPeriod);
        until PayrollPeriod.Next = 0;

        LibraryHRP.DismissEmployee(EmployeeNo, DismissalDate, LibraryHRP.FindGroundOfTerminationCode, true);

        VerifyAECalcForPregIncome(EmployeeNo, PayrollPeriod.Code, NumberOfDaysPrevTwoYears, PersonIncome, PersonAbsDays);
    end;

    local procedure SetAECalcSetup(AECalcType: Option; UseExcludedDays: Boolean)
    var
        AECalcSetup: Record "AE Calculation Setup";
    begin
        with AECalcSetup do begin
            SetRange(Type, Type::Calculation);
            SetRange("AE Calc Type", AECalcType);
            if FindLast then begin
                Validate("Use FSI Limits", true);
                Validate("Exclude Current Period", true);
                if UseExcludedDays then
                    Validate("Use Excluded Days", true);
                Modify(true);
            end;
        end;
    end;

    local procedure SetFSILimit(Period: Code[10]; Amt: Decimal)
    var
        PayrollLimit: Record "Payroll Limit";
    begin
        with PayrollLimit do begin
            SetRange(Type, Type::"FSI Limit");
            SetRange("Payroll Period", Period);
            if FindFirst then begin
                Validate(Amount, Amt);
                Modify(true);
            end else begin
                Init;
                Type := Type::"FSI Limit";
                "Payroll Period" := Period;
                Amount := Amt;
                Insert;
            end;
        end;
    end;

    local procedure CalcAndPostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period")
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
    end;

    local procedure CalcPayrollAmt(var PostedPayrollDocumentLine: Record "Posted Payroll Document Line") Amt: Decimal
    begin
        with PostedPayrollDocumentLine do
            if FindSet then
                repeat
                    Amt += "Payroll Amount";
                until Next = 0;
    end;

    local procedure CreatePersonIncome(PersonNo: Code[20]; PeriodCode: Code[10]; Amt: Decimal; ExcludedDays: Decimal)
    var
        PersonIncomeFSI: Record "Person Income FSI";
    begin
        with PersonIncomeFSI do begin
            Init;
            "Person No." := PersonNo;
            Validate("Period Code", PeriodCode);
            "Document No." := LibraryUtility.GenerateGUID;
            Amount := Amt;
            Insert(true);
        end;

        CreateExcludedDays(PersonIncomeFSI, ExcludedDays);
    end;

    local procedure CreateExcludedDays(PersonIncomeFSI: Record "Person Income FSI"; ExcludedDays: Decimal)
    var
        PersonExcludedDays: Record "Person Excluded Days";
    begin
        with PersonExcludedDays do begin
            "Person No." := PersonIncomeFSI."Person No.";
            "Period Code" := PersonIncomeFSI."Period Code";
            "Document No." := PersonIncomeFSI."Document No.";
            "Calendar Days" := ExcludedDays;
            Insert(true);
        end;
    end;

    local procedure CreateRelativeChild(PersonNo: Code[20]; RelativeFrom: Date): Code[20]
    var
        Relative: Record Relative;
        RelativePersonNo: Code[20];
    begin
        Relative.SetRange("Relative Type", Relative."Relative Type"::Child);
        if Relative.FindFirst then
            RelativePersonNo := LibraryHRP.CreateRelativePerson(PersonNo, Relative.Code, RelativeFrom, RelativeFrom);
        exit(RelativePersonNo);
    end;

    local procedure CreatePayrollCalendLines(CalendarCode: Code[10]; UntilDate: Date)
    var
        PayrollCalLine: Record "Payroll Calendar Line";
        CreateCalLines: Report "Create Calendar Line";
        StartDate: Date;
    begin
        PayrollCalLine.SetRange("Calendar Code", CalendarCode);
        PayrollCalLine.FindLast;
        StartDate := PayrollCalLine.Date;

        if StartDate < UntilDate then begin
            StartDate := CalcDate('<1D>', StartDate);
            CreateCalLines.SetCalendar(CalendarCode, StartDate, UntilDate, false);
            CreateCalLines.UseRequestPage(false);
            CreateCalLines.RunModal;

            ReleaseCalendarLine(CalendarCode, StartDate, UntilDate);
        end;
    end;

    local procedure CreatePrepareExclDaysTimeActGroupCode(StartingDate: Date): Code[20]
    var
        TimeActivityGroup: Record "Time Activity Group";
        TimeActivityFilter: Record "Time Activity Filter";
        TimeActivity: Record "Time Activity";
    begin
        // create time activity group and assign it to HRSetup
        LibraryHRP.CreateTimeActivityGroup(TimeActivityGroup);

        // filter consits of activities B and R
        TimeActivityFilter.Code := TimeActivityGroup.Code;
        TimeActivityFilter."Starting Date" := StartingDate;
        // loop through the all paid sick leaves
        TimeActivity.SetRange("Time Activity Type", TimeActivity."Time Activity Type"::"Sick Leave");
        TimeActivity.SetRange("Paid Activity", true);
        TimeActivity.FindSet();
        repeat
            if TimeActivityFilter."Activity Code Filter" = '' then
                TimeActivityFilter."Activity Code Filter" := TimeActivity.Code
            else
                TimeActivityFilter."Activity Code Filter" += '|' + TimeActivity.Code;
        until TimeActivity.Next = 0;
        TimeActivityFilter.Insert();

        exit(TimeActivityGroup.Code);
    end;

    local procedure UpdateHRSetupExclDaysGroupCode(StartingDate: Date)
    var
        HRSetup: Record "Human Resources Setup";
    begin
        with HRSetup do begin
            Get;
            if "Excl. Days Group Code" = '' then begin
                "Excl. Days Group Code" := CreatePrepareExclDaysTimeActGroupCode(StartingDate);
                Modify;
            end;
        end;
    end;

    local procedure GetPersonNo(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        with Employee do begin
            Get(EmployeeNo);
            exit("Person No.");
        end;
    end;

    local procedure GetNumberOfPrevTwoYearsDays(DocumentPeriodCode: Code[10]): Integer
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        // calculate the number of days in the two years previous to DocumentPeriodCode
        PayrollPeriod.Get(DocumentPeriodCode);
        PeriodEndDate := CalcDate('<-CY-1D>', PayrollPeriod."Starting Date");
        PeriodStartDate := CalcDate('<-CY-1Y>', PeriodEndDate);
        exit(PeriodEndDate - PeriodStartDate + 1);
    end;

    local procedure ReleaseCalendarLine(CalendarCode: Code[10]; DateFrom: Date; DateTo: Date)
    var
        CalendarLine: Record "Payroll Calendar Line";
    begin
        with CalendarLine do begin
            SetRange("Calendar Code", CalendarCode);
            SetRange(Date, DateFrom, DateTo);
            FindSet();
            repeat
                if Status = Status::Open then
                    Release;
            until Next = 0;
        end;
    end;

    local procedure FilterPostedPayrollDocLine(var PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; EmployeeNo: Code[20]; ElementCode: Code[20]; PeriodCode: Code[10])
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
    begin
        PostedPayrollDocument.SetRange("Employee No.", EmployeeNo);
        PostedPayrollDocument.SetRange("Period Code", PeriodCode);
        Assert.IsTrue(PostedPayrollDocument.FindFirst, StrSubstNo(DocNotFoundErr, PeriodCode));

        PostedPayrollDocumentLine.SetRange("Document No.", PostedPayrollDocument."No.");
        PostedPayrollDocumentLine.SetRange("Element Code", ElementCode);
    end;

    local procedure VerifyPersonIncomeAbsDays(EmployeeNo: Code[20]; PeriodCode: Code[10]; ExclDays: Decimal)
    var
        PersonIncomeFSI: Record "Person Income FSI";
    begin
        with PersonIncomeFSI do begin
            SetRange("Person No.", GetPersonNo(EmployeeNo));
            SetRange("Period Code", PeriodCode);
            FindFirst;
            CalcFields("Excluded Days");
            Assert.AreEqual(ExclDays, "Excluded Days", WrongExcludedDaysErr);
        end;
    end;

    local procedure VerifyPregnBenefit(EmployeeNo: Code[20]; PeriodCode: Code[10]; Amount: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        PayrollAmt: Decimal;
    begin
        FilterPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, Translate.ElementCode(PaySLPregDaysTxt), PeriodCode);
        PostedPayrollDocumentLine.FindFirst;
        PayrollAmt := CalcPayrollAmt(PostedPayrollDocumentLine);

        GLSetup.Get();
        Assert.AreNearlyEqual(Amount, PayrollAmt, GLSetup."Amount Rounding Precision", IncorrectElementBenefitErr);
    end;

    local procedure VerifyAETotalDays(EmployeeNo: Code[20]; PeriodCode: Code[10]; ExpectedDays: Decimal)
    var
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        with PostedPayrollDocumentLine do begin
            FilterPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, Translate.ElementCode(PaySLPregDaysTxt), PeriodCode);
            FindSet();
            repeat
                CalcFields("AE Total Days");
                Assert.AreEqual(ExpectedDays, "AE Total Days", WrongAEDaysErr);
            until Next = 0;
        end;
    end;

    local procedure VerifyExcludedDays(EmployeeNo: Code[20]; PeriodCode: Code[10]; ExpectedDays: Decimal)
    var
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        with PostedPayrollDocumentLine do begin
            FilterPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, Translate.ElementCode(PaySLPregDaysTxt), PeriodCode);
            FindSet();
            repeat
                Assert.AreEqual(ExpectedDays, "Excluded Days", WrongAEDaysErr);
            until Next = 0;
        end;
    end;

    local procedure VerifyAECalcForPregIncome(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; NumberOfDaysPrevTwoYears: Integer; PersonIncome: array[2] of Decimal; PersonAbsDays: array[2] of Integer)
    var
        ExpectedPregBenefitAmount: Decimal;
    begin
        ExpectedPregBenefitAmount :=
          Round(
            (PersonIncome[1] + PersonIncome[2]) /
            (NumberOfDaysPrevTwoYears - PersonAbsDays[1] - PersonAbsDays[2])) * PersonPregnDays;
        VerifyExcludedDays(EmployeeNo, PayrollPeriodCode, PersonAbsDays[1] + PersonAbsDays[2]);
        VerifyPregnBenefit(EmployeeNo, PayrollPeriodCode, ExpectedPregBenefitAmount);
    end;
}

