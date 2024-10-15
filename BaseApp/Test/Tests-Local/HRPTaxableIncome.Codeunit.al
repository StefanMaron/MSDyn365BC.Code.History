codeunit 144203 "HRP Taxable Income"
{
    // Covers Hotfix Requests:
    // --------------------------------------------------
    // #   Test Function Name                     TFS ID
    // --------------------------------------------------
    // 1.  TFS335822_Scenario                       335822
    // 2.  TFS335822_NightWork                      335822
    // 3.  TFS335822_TwoNightsWork                  335822
    // 4.  TFS335822_WeekendWork                    335822
    // 5.  TFS335822_MonthBonus                     335822
    // 6.  TFS335822_OtherBonus                     335822
    // 7.  TFS335848                                335848
    // 8.  TFS335893_VacationDays                   335893
    // 9.  PersonIncomeFSIForTwoPayrollDocs         88484
    // 10. PersonIncomeCorrDocumentPosting          88573
    // 11. TaxableAmountAfterReverseDoc             87933
    // 12. TaxableAmountAfterReverseAndRecalculate  88258,89396

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        CreateCalendarLine: Report "Create Calendar Line";
        Assert: Codeunit Assert;
        LibraryHRP: Codeunit "Library - HRP";
        NIGHTWORKTxt: Label 'N';
        WEEKENDWORKTxt: Label 'RV2';
        BONUSTxt: Label 'BONUS';
        BONUSMONTHLYAMTTxt: Label 'BONUS MONTHLY AMT';
        TaxableIncomeErr: Label 'Incorrect taxable Income Base Amount';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AccruedTaxAmounrErr: Label 'Incorrect accrued tax amount';
        WORKDAY: Label 'YA';
        DAYOFF: Label 'V1';
        NotCorrectCalDaysValueErr: Label 'Actual value of the CalendarDays is not correct';
        IncorrectPaidToPersonAmountErr: Label 'Paid To Persone amount is incorrect.';
        VacationRegularTxt: Label 'VACATION REGULAR';
        Income13PercentTxt: Label 'INCOME TAX 13%', Locked = true;
        IncorrectPersonIncomeFSIAmountErr: Label 'Incorrect amount for person income FSI.';
        IncorrectPersonIncomeFSIExcludedDaysErr: Label 'Incorrect excluded days number for person income FSI.';
        PlannedAdvanceTxt: Label 'PLANNED ADVANCE';
        IncorrectVacationDaysErr: Label 'Incorrect count for Vacation Days';
        TranslatePayroll: Codeunit "Translate Payroll";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335822_Scenario()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        NonWorkingDay: Date;
    begin
        // Verify the Taxable Income Base when having a Nightwork and a Weekend Work.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        AddTimeSheetDetails(EmployeeNo, NIGHTWORKTxt, LibraryHRP.FindFirstWorkingDate(PayrollPeriod), 3, false);  // Nightwork.

        NonWorkingDay := LibraryHRP.FindFirstNonWorkingDate(PayrollPeriod);
        DeleteTimeSheetDetail(EmployeeNo, NonWorkingDay);
        AddTimeSheetDetails(EmployeeNo, WEEKENDWORKTxt, NonWorkingDay, 8, true); // Weekend Work.

        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo,
          CalcPayrollDocumentAmount(EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335822_NightWork()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Verify the Taxable Income Base when having a Nightwork.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", 35000);
        AddTimeSheetDetails(EmployeeNo, NIGHTWORKTxt, LibraryHRP.FindFirstWorkingDate(PayrollPeriod), 3, false);

        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo,
          CalcPayrollDocumentAmount(EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335822_TwoNightsWork()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        NightDate: Date;
    begin
        // Verify the Taxable Income Base when having two Nightworks.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        NightDate := LibraryHRP.FindFirstWorkingDate(PayrollPeriod);
        AddTimeSheetDetails(EmployeeNo, NIGHTWORKTxt, NightDate, 3, false);
        AddTimeSheetDetails(EmployeeNo, NIGHTWORKTxt, CalcDate('<1W>', NightDate), 3, false);

        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo,
          CalcPayrollDocumentAmount(EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335822_WeekendWork()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        NonWorkingDay: Date;
    begin
        // Verify the Taxable Income Base when having a Weekend Work.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        NonWorkingDay := LibraryHRP.FindFirstNonWorkingDate(PayrollPeriod);
        DeleteTimeSheetDetail(EmployeeNo, NonWorkingDay);
        AddTimeSheetDetails(EmployeeNo, WEEKENDWORKTxt, NonWorkingDay, 8, true);

        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo,
          CalcPayrollDocumentAmount(EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335822_MonthBonus()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Verify the Taxable Income Base when having a Nightork and a Monthly Bonus.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        AddTimeSheetDetails(EmployeeNo, NIGHTWORKTxt, LibraryHRP.FindFirstWorkingDate(PayrollPeriod), 3, false);

        CreatePostEmpJnlLine(EmployeeNo, PayrollPeriod, BONUSMONTHLYAMTTxt, 5000); // Create Mounthly Bonus.
        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo,
          CalcPayrollDocumentAmount(EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
    end;

    [Test]
    [HandlerFunctions('CopyPayrollElementHandler')]
    [Scope('OnPrem')]
    procedure TFS335822_OtherBonus()
    var
        PayrollPeriod: Record "Payroll Period";
        PayrollElement: Record "Payroll Element";
        EmployeeNo: Code[20];
        ElementCode: Code[20];
        LineNo: Integer;
    begin
        // Verify the Taxable Income Base when having a Bonus with 'Other' Type.

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        ElementCode := CopyPayrollElemAndChangeType(BONUSMONTHLYAMTTxt, PayrollElement.Type::Other);
        LineNo := AddPayrollElementToCalc(ElementCode, BONUSTxt);

        CreatePostEmpJnlLine(EmployeeNo, PayrollPeriod, ElementCode, 5000); // Create Bonus.
        CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");

        VerifyPersonTaxableIncome(EmployeeNo, 40000);

        DeletePayrollElementToCalc(BONUSTxt, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335848()
    var
        PayrollPeriod: Record "Payroll Period";
        NewPosition: Record Position;
        PersonNo: Code[20];
        EmployeeNo: array[2] of Code[20];
        BeginningPeriodCode: Code[10];
        DismissalPeriodCode: Code[10];
        LastWorkingPeriodCode: Code[10];
    begin
        // Verify "Paid to Person" in Taxable Income are correct
        // in case of two Labor Contracts in one year

        BasicScenarioSetup(EmployeeNo[1], PayrollPeriod);
        PersonNo := GetPersonNo(EmployeeNo[1]);

        DismissalPeriodCode := FindPayrollPeriodCodeByPeriodShift(PayrollPeriod, 4);
        // dismiss in the end of May
        BeginningPeriodCode := PayrollPeriod.Code;
        PayrollPeriod.Get(DismissalPeriodCode);
        LibraryHRP.DismissEmployee(EmployeeNo[1], PayrollPeriod."Ending Date", LibraryHRP.FindGroundOfTerminationCode, true);
        CalcPostEmployeePeriodPayments(EmployeeNo[1], BeginningPeriodCode, DismissalPeriodCode);

        // hire person on new position
        NewPosition.FindFirst;
        PayrollPeriod.Get(FindPayrollPeriodCodeByPeriodShift(PayrollPeriod, 1));
        LastWorkingPeriodCode := FindPayrollPeriodCodeByPeriodShift(PayrollPeriod, 6);
        EmployeeNo[2] := CreatePersonLaborContractHire(PersonNo, PayrollPeriod."Starting Date", NewPosition."No.",
            LibraryRandom.RandIntInRange(30000, 50000));
        CalcPostEmployeePeriodPayments(EmployeeNo[2], PayrollPeriod.Code, LastWorkingPeriodCode);

        PersonIncomeRecalculate(PersonNo);
        VerifyPaidToPerson(PersonNo, DismissalPeriodCode,
          CalcPayrollAmountByPeriod(EmployeeNo[1], BeginningPeriodCode, DismissalPeriodCode));
        VerifyPaidToPerson(PersonNo, LastWorkingPeriodCode,
          CalcPayrollAmountByPeriod(EmployeeNo[2], PayrollPeriod.Code, LastWorkingPeriodCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS335893_VacationDays()
    var
        PayrollPeriod: Record "Payroll Period";
        Position: Record Position;
        Calendar: Code[10];
        VacOrderNo: Code[20];
        EmployeeNo: Code[20];
        StartVacDate: Date;
        EndVacDate: Date;
        WorkDays: Integer;
        HoliDays: Integer;
    begin
        // Verify calculation "Calendar Days" for Vacation if use 'shift work calendar'

        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        Position.FindFirst;

        CalcDates(PayrollPeriod, StartVacDate, EndVacDate, WorkDays, HoliDays);
        Calendar := LibraryHRP.CreatePayrollCalendarHeader;
        CreateCalendarLines(Calendar, PayrollPeriod."Starting Date", CalcDate('<CY>', PayrollPeriod."Starting Date"), WorkDays, HoliDays);

        EmployeeNo := CreateUpdPosAndLabContractHire(PayrollPeriod."Starting Date", Position."No.",
            LibraryRandom.RandIntInRange(30000, 50000), Calendar);
        VacOrderNo := CreateVacationOrder(
            EmployeeNo, StartVacDate, StartVacDate, EndVacDate, LibraryHRP.FindRegularVacationTimeActivityCode);

        VerifyVacDaysInVacWithHoliday(VacOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonIncomeFSIForTwoPayrollDocs()
    var
        PayrollPeriod: Record "Payroll Period";
        VacationStartDate: Date;
        VacationEndDate: Date;
        EmployeeNo: Code[20];
    begin
        // Verify person income FSI amount in case of posting 2 payroll documents - advance and main salary

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);

        // vacation for a few days in the beginning of the month
        VacationStartDate := LibraryHRP.FindFirstWorkingDate(PayrollPeriod);
        VacationEndDate := VacationStartDate + LibraryRandom.RandIntInRange(10, 15);
        LibraryHRP.CreateVacation(EmployeeNo, LibraryHRP.FindRegularVacationTimeActivityCode,
          VacationStartDate, VacationStartDate, VacationEndDate);

        // EXCERCISE
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, CreateAdvanceCalcGroup(VacationRegularTxt)); // advance
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, ''); // main salary

        // VERIFY
        VerifyPersonIncomeFSI(
          EmployeeNo, PayrollPeriod.Code, CalcPayrollDocumentAmount(
            EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter), 0);
    end;

    [Test]
    [HandlerFunctions('CopyPayrollDocHandler')]
    [Scope('OnPrem')]
    procedure PersonIncomeCorrDocumentPosting()
    var
        PayrollPeriod: Record "Payroll Period";
        PayrollDocument: Record "Payroll Document";
        EmployeeNo: Code[20];
        SickLeaveStartDate: Date;
        SickLeaveEndDate: Date;
    begin
        // Verify that correction document containing sick leave can be posted
        // and person income data inserted with negative sign

        // SETUP
        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        SickLeaveStartDate := LibraryHRP.FindFirstWorkingDate(PayrollPeriod);
        SickLeaveEndDate := SickLeaveStartDate + LibraryRandom.RandInt(5);

        LibraryHRP.CreateSickLeaveOrder(EmployeeNo, SickLeaveEndDate, SickLeaveStartDate, SickLeaveEndDate,
          LibraryHRP.FindCommonDiseaseTimeActivityCode, '', 100, 0, true);
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, '');

        CreateCorrectionPayrollDocFromLastPostedDoc(EmployeeNo, PayrollPeriod.Code, PayrollDocument);

        // EXERCISE - post correction document
        CODEUNIT.Run(CODEUNIT::"Payroll Document - Post", PayrollDocument);

        // VERIFY - excluded days number has to be 0
        VerifyPersonTaxableIncome(EmployeeNo, 0);
        VerifyPersonIncomeFSI(EmployeeNo, PayrollPeriod.Code, 0, 0);
    end;

    [Test]
    [HandlerFunctions('CopyPayrollDocHandler')]
    [Scope('OnPrem')]
    procedure TaxableAmountAfterReverseDoc()
    var
        PayrollPeriod: Record "Payroll Period";
        PayrollDocument: Record "Payroll Document";
        EmployeeNo: Code[20];
    begin
        // Verify that reverse payroll document correctly fills base amount in person income entry

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        // Post advance payment
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, CreateAdvanceCalcGroup(PlannedAdvanceTxt));
        CreateCorrectionPayrollDocFromLastPostedDoc(EmployeeNo, PayrollPeriod.Code, PayrollDocument);

        // Exercise - post correction document
        CODEUNIT.Run(CODEUNIT::"Payroll Document - Post", PayrollDocument);

        // Verify - Income tax base amount is completely reverted
        VerifyPersonTaxableIncome(EmployeeNo, 0);
    end;

    [Test]
    [HandlerFunctions('CopyPayrollDocHandler')]
    [Scope('OnPrem')]
    procedure TaxableAmountAfterReverseAndRecalculate()
    var
        PayrollPeriod: Record "Payroll Period";
        PayrollDocument: Record "Payroll Document";
        EmployeeNo: Code[20];
        AdvanceCalcGroupCode: Code[20];
    begin
        // Verify that reverse payroll document correctly fills base amount in person income entry

        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        // Post advance payment
        AdvanceCalcGroupCode := CreateAdvanceCalcGroup(PlannedAdvanceTxt);
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, AdvanceCalcGroupCode);
        CreateCorrectionPayrollDocFromLastPostedDoc(EmployeeNo, PayrollPeriod.Code, PayrollDocument);
        CODEUNIT.Run(CODEUNIT::"Payroll Document - Post", PayrollDocument);

        // Exercise - Recalculate reverted document
        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod, AdvanceCalcGroupCode);

        // Verify - Person income entries for the recalculated document are correct
        VerifyPersonTaxableIncome(EmployeeNo, CalcPayrollDocumentAmount(
            EmployeeNo, PayrollPeriod.Code, FormatTaxableAmtElementTypeFilter));
        VerifyPersonIncomeTaxAmount(EmployeeNo, -CalcPayrollDocumentAmount(
            EmployeeNo, PayrollPeriod.Code, FormatIncomeTaxElementTypeFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVacationDays()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        VacationDaysCalculation: Codeunit "Vacation Days Calculation";
        EmployeeNo: Code[20];
        VacationDays: Decimal;
        Months: Integer;
    begin
        // Verify Calculation of Vacation Days for Employee
        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        Months := CalcMultiplePayrollPeriods(EmployeeNo, PayrollPeriod);

        VacationDays := Round(VacationDaysCalculation.CalculateVacationDays(EmployeeNo, PayrollPeriod."Ending Date", ''));

        EmployeeAbsenceEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeAbsenceEntry.FindFirst;
        Assert.AreEqual(Round(EmployeeAbsenceEntry."Calendar Days" / 12 * Months), VacationDays, IncorrectVacationDaysErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportNDFL1Form()
    var
        Employee: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        PersonIncomeHeader: Record "Person Income Header";
        Form1NDFL: Report "Form 1-NDFL";
        EmployeeNo: Code[20];
    begin
        // Verify export of NDFL-1 form
        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        CalcMultiplePayrollPeriods(EmployeeNo, PayrollPeriod);

        LibraryReportValidation.SetFileName(EmployeeNo);
        Employee.Get(EmployeeNo);
        PersonIncomeHeader.SetRange("Person No.", Employee."Person No.");
        PersonIncomeHeader.FindLast;

        Form1NDFL.SetTestMode(true);
        Form1NDFL.SetTableView(PersonIncomeHeader);
        Form1NDFL.UseRequestPage(false);
        Form1NDFL.Run;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportNDFL2Form()
    var
        Employee: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        PersonIncomeHeader: Record "Person Income Header";
        Form2NDFL: Report "Form 2-NDFL";
        EmployeeNo: Code[20];
    begin
        // Verify export of NDFL-2 form
        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        CalcMultiplePayrollPeriods(EmployeeNo, PayrollPeriod);

        LibraryReportValidation.SetFileName(EmployeeNo);
        Employee.Get(EmployeeNo);
        PersonIncomeHeader.SetRange("Person No.", Employee."Person No.");
        PersonIncomeHeader.FindLast;

        Form2NDFL.SetTestMode(true);
        Form2NDFL.SetTableView(PersonIncomeHeader);
        Form2NDFL.UseRequestPage(false);
        Form2NDFL.Run;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportNDFL2FormToXML()
    var
        Employee: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        PersonIncomeHeader: Record "Person Income Header";
        ExportForm2NDFLToXML: Report "Export Form 2-NDFL to XML";
        EmployeeNo: Code[20];
    begin
        // Verify export of NDFL-2 form to XML file
        BasicScenarioSetup(EmployeeNo, PayrollPeriod);
        CalcMultiplePayrollPeriods(EmployeeNo, PayrollPeriod);

        LibraryReportValidation.SetFileName(EmployeeNo);
        Employee.Get(EmployeeNo);
        PersonIncomeHeader.SetRange("Person No.", Employee."Person No.");
        PersonIncomeHeader.FindLast;

        ExportForm2NDFLToXML.SetFileName(LibraryReportValidation.GetFileName);
        ExportForm2NDFLToXML.SetTableView(PersonIncomeHeader);
        ExportForm2NDFLToXML.UseRequestPage(false);
        ExportForm2NDFLToXML.Run;
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure BasicScenarioSetup(var EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period")
    begin
        Initialize;
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", 35000);
    end;

    local procedure AddTimeSheetDetails(EmployeeNo: Code[20]; TimeActCode: Code[10]; StartDate: Date; Hours: Decimal; IsOvertime: Boolean)
    var
        TimesheetLine: Record "Timesheet Line";
    begin
        with TimesheetLine do begin
            SetRange("Calendar Code", LibraryHRP.GetDefaultCalendarCode);
            SetRange("Employee No.", EmployeeNo);
            SetRange(Date, StartDate);
            FindFirst;
            CreateTimeSheetDetail(TimesheetLine, TimeActCode, Hours, IsOvertime);
        end;
    end;

    local procedure CreateTimeSheetDetail(TimesheetLine: Record "Timesheet Line"; TimeActCode: Code[10]; Hours: Decimal; IsOvertime: Boolean)
    var
        TimeSheetDetail: Record "Timesheet Detail";
    begin
        with TimeSheetDetail do begin
            Init;
            "Employee No." := TimesheetLine."Employee No.";
            Date := TimesheetLine.Date;
            "Calendar Code" := TimesheetLine."Calendar Code";
            Validate("Time Activity Code", TranslatePayroll.TimeActivityCode(TimeActCode));
            Validate("Actual Hours", Hours);
            Validate(Overtime, IsOvertime);
            Insert(true);
        end;
    end;

    local procedure DeleteTimeSheetDetail(EmployeeNo: Code[20]; OnDate: Date)
    var
        TimeSheetDetail: Record "Timesheet Detail";
    begin
        with TimeSheetDetail do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange(Date, OnDate);
            DeleteAll(true);
        end;
    end;

    local procedure CopyPayrollElemAndChangeType(PayrollCodeCopyFrom: Code[20]; ElementType: Option): Code[20]
    var
        PayrollElement: Record "Payroll Element";
    begin
        with PayrollElement do begin
            Get(CopyPayrollElement(PayrollCodeCopyFrom));
            Validate(Type, ElementType);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure AddPayrollElementToCalc(ElementCode: Code[20]; CalcTypeCode: Code[20]): Integer
    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        with PayrollCalcTypeLine do begin
            Init;
            "Calc Type Code" := TranslatePayroll.ElementGroup(CalcTypeCode);
            "Line No." := FindLastLineInPayrollCalcType(CalcTypeCode) + 10000;
            Validate("Element Code", TranslatePayroll.ElementCode(ElementCode));
            Insert(true);
            exit("Line No.");
        end;
    end;

    local procedure DeletePayrollElementToCalc(CalcTypeCode: Code[20]; LineNo: Integer)
    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        with PayrollCalcTypeLine do begin
            SetRange("Calc Type Code", TranslatePayroll.ElementGroup(CalcTypeCode));
            SetRange("Line No.", LineNo);
            DeleteAll(true);
        end;
    end;

    local procedure AddPayrollCalcGroupLine(CalcGroupCode: Code[10]; PayrollCalcType: Code[20])
    var
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
    begin
        with PayrollCalcGroupLine do begin
            SetRange("Payroll Calc Group", CalcGroupCode);
            if FindLast then;
            Init;
            "Payroll Calc Group" := CalcGroupCode;
            "Line No." := "Line No." + 1;
            "Payroll Calc Type" := PayrollCalcType;
            Insert;
        end;
    end;

    local procedure CopyPayrollElement(PayrollCodeCopyFrom: Code[20]) NewElementCode: Code[20]
    var
        PayrollElement: Record "Payroll Element";
        CopyPayrollElementReport: Report "Copy Payroll Element";
    begin
        PayrollElement.Get(TranslatePayroll.ElementCode(PayrollCodeCopyFrom));
        NewElementCode := LibraryUtility.GenerateRandomCode(
            PayrollElement.FieldNo(Code), DATABASE::"Payroll Element");
        LibraryVariableStorage.Enqueue(NewElementCode);
        Commit();
        CopyPayrollElementReport.SetPayrollElement(PayrollElement);
        CopyPayrollElementReport.RunModal;
    end;

    local procedure CreatePostEmpJnlLine(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; ElementCode: Code[20]; Amount: Decimal)
    var
        EmplJnlLine: Record "Employee Journal Line";
    begin
        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, TranslatePayroll.ElementCode(ElementCode),
          Amount, PayrollPeriod."Ending Date", false);
        LibraryHRP.PostEmplJnlLine(EmplJnlLine);
    end;

    local procedure CalcPostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; CalcDate: Date)
    var
        Employee: Record Employee;
        PayrollDocument: Record "Payroll Document";
        TimesheetStatus: Record "Timesheet Status";
        SuggestPayrollDocuments: Report "Suggest Payroll Documents";
    begin
        // Release Timesheet.
        TimesheetStatus.Get(PayrollPeriodCode, EmployeeNo);
        TimesheetStatus.Release;

        // Calculate Payroll Document.
        SuggestPayrollDocuments.Set(PayrollPeriodCode, '', CalcDate, true);
        Employee.SetRange("No.", EmployeeNo);
        SuggestPayrollDocuments.SetTableView(Employee);
        SuggestPayrollDocuments.UseRequestPage(false);
        SuggestPayrollDocuments.Run;

        // Post Payroll Document.
        with PayrollDocument do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PayrollPeriodCode);
            FindFirst;
            CODEUNIT.Run(CODEUNIT::"Payroll Document - Post", PayrollDocument);
        end;
    end;

    local procedure FindLastLineInPayrollCalcType(CalcTypeCode: Code[20]): Integer
    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        with PayrollCalcTypeLine do begin
            SetRange("Calc Type Code", TranslatePayroll.ElementGroup(CalcTypeCode));
            if FindLast then
                exit("Line No.");
            exit(0);
        end;
    end;

    local procedure FindPostedPayrollDoc(var PostedPayrollDocument: Record "Posted Payroll Document"; EmployeeNo: Code[20]; PayrollPeriodCode: Code[10])
    begin
        PostedPayrollDocument.SetRange("Employee No.", EmployeeNo);
        PostedPayrollDocument.SetRange("Period Code", PayrollPeriodCode);
        PostedPayrollDocument.FindLast;
    end;

    local procedure CreatePerson(): Code[20]
    var
        Person: Record Person;
    begin
        LibraryHRP.CreatePerson(Person);
        exit(Person."No.");
    end;

    local procedure CreatePersonLaborContractHire(PersonNo: Code[20]; StartDate: Date; PositionNo: Code[10]; BaseSalary: Decimal): Code[20]
    var
        Position: Record Position;
        LaborContract: Record "Labor Contract";
    begin
        LibraryHRP.CopyPosition(Position, StartDate, PositionNo, BaseSalary);
        LibraryHRP.CreateLaborContractHire(LaborContract, PersonNo, StartDate, Position."No.", true, true);
        exit(LaborContract."Employee No.");
    end;

    local procedure CalcPostEmployeePeriodPayments(EmployeeNo: Code[20]; StartPeriodCode: Code[10]; EndPeriodCode: Code[10])
    var
        Employee: Record Employee;
        StartPeriod: Record "Payroll Period";
        EndPeriod: Record "Payroll Period";
    begin
        CalcPostPayrollPeriod(EmployeeNo, StartPeriodCode, EndPeriodCode);
        Employee.Get(EmployeeNo);
        StartPeriod.Get(StartPeriodCode);
        EndPeriod.Get(EndPeriodCode);
        SuggestPostPayrollPayJnlLine(
          Employee."Person No.", StartPeriod."Starting Date", EndPeriod."Ending Date", EndPeriod."Ending Date");
    end;

    local procedure CalcPostPayrollPeriod(EmployeeNo: Code[20]; StartPeriodCode: Code[10]; EndPeriodCode: Code[10])
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        with PayrollPeriod do begin
            SetRange(Code, StartPeriodCode, EndPeriodCode);
            FindSet();
            repeat
                CalcPostPayrollDoc(EmployeeNo, Code, "Ending Date");
            until Next = 0;
        end;
    end;

    local procedure CalcMultiplePayrollPeriods(EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period") Months: Integer
    var
        i: Integer;
    begin
        Months := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to Months do begin
            CalcPostPayrollDoc(EmployeeNo, PayrollPeriod.Code, PayrollPeriod."Ending Date");
            PayrollPeriod.Next;
        end;
        PayrollPeriod.Next(-1);
    end;

    local procedure SuggestPostPayrollPayJnlLine(PersonNo: Code[20]; StartDate: Date; EndDate: Date; PostDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        Person: Record Person;
        SuggestPersonPayments: Report "Suggest Person Payments";
    begin
        with SuggestPersonPayments do begin
            CreatePayrollPaymentJnlLine(GenJnlLine);
            SetParameters(GenJnlLine, StartDate, EndDate, PostDate, FindBankAccount, false);
            Person.SetRange("No.", PersonNo);
            SetTableView(Person);
            UseRequestPage(false);
            Run;
        end;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreatePayrollPaymentJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        with GenJnlLine do begin
            FindGenJnlBatch(GenJnlBatch);
            LibraryERM.ClearGenJournalLines(GenJnlBatch);
            "Journal Template Name" := GenJnlBatch."Journal Template Name";
            "Journal Batch Name" := GenJnlBatch.Name;
        end;
    end;

    local procedure CreatePostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; CalcGroupCode: Code[10])
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, CalcGroupCode, PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
    end;

    local procedure CreateCorrectionPayrollDocFromLastPostedDoc(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; var PayrollDocument: Record "Payroll Document")
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
        CopyPayrollDocument: Report "Copy Payroll Document";
    begin
        FindPostedPayrollDoc(PostedPayrollDocument, EmployeeNo, PayrollPeriodCode);
        LibraryVariableStorage.Enqueue(PostedPayrollDocument."No.");
        CreateBlankPayrollDocument(PayrollDocument, EmployeeNo);
        Commit();
        CopyPayrollDocument.SetPayrollDoc(PayrollDocument);
        CopyPayrollDocument.Run;

        PayrollDocument.Find;
        PayrollDocument.Validate(Correction, true);
        PayrollDocument.Validate("Reversing Document No.", PostedPayrollDocument."No.");
        PayrollDocument.Modify(true);
    end;

    local procedure CreateBlankPayrollDocument(var PayrollDocument: Record "Payroll Document"; EmployeeNo: Code[20])
    begin
        PayrollDocument.Init();
        PayrollDocument.Insert(true);
        PayrollDocument.Validate("Employee No.", EmployeeNo);
        PayrollDocument.Modify(true);
    end;

    local procedure FindGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        with GenJnlBatch do begin
            SetRange("Template Type", "Template Type"::Payments);
            SetRange(Recurring, false);
            FindFirst;
        end;
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            SetRange("Currency Code", '');
            SetRange("Account Type", "Account Type"::"Bank Account");
            LibraryERM.FindBankAccount(BankAccount);
            Validate("Bank Payment Order No. Series", LibraryERM.CreateNoSeriesCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure PersonIncomeRecalculate(PersonNo: Code[20])
    var
        PersonIncomeHeader: Record "Person Income Header";
    begin
        with PersonIncomeHeader do begin
            SetRange("Person No.", PersonNo);
            FindFirst;
            Recalculate;
        end;
    end;

    local procedure CalcDates(PayrollPeriod: Record "Payroll Period"; var StartVacDate: Date; var EndVacDate: Date; var WorkDays: Integer; var HoliDays: Integer)
    var
        FirstHolAfterDate: Date;
        VacHalfInterval: Integer;
    begin
        VacHalfInterval := LibraryRandom.RandInt(7);
        WorkDays := LibraryRandom.RandInt(7);
        HoliDays := LibraryRandom.RandInt(7);
        FirstHolAfterDate := LibraryHRP.FindFirstWorkingDate(PayrollPeriod);
        StartVacDate := CalcDate('<-' + Format(VacHalfInterval) + 'D>', FirstHolAfterDate);
        EndVacDate := CalcDate('<+' + Format(VacHalfInterval) + 'D>', FirstHolAfterDate);
    end;

    local procedure CreateCalendarLines(CalendarCode: Code[10]; StartDate: Date; EndDate: Date; WorkDays: Integer; HoliDays: Integer)
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
        i: Integer;
        WorkHours: Integer;
    begin
        CreateCalendarLine.SetCalendar(CalendarCode, StartDate, EndDate, false);
        CreateCalendarLine.Run;

        WorkHours := LibraryRandom.RandInt(12);

        with PayrollCalendarLine do begin
            SetRange("Calendar Code", CalendarCode);
            FindSet(true, true);
            i := 1;
            repeat
                if (i mod (WorkDays + HoliDays)) <= WorkDays then begin
                    Nonworking := false;
                    "Work Hours" := WorkHours;
                    "Time Activity Code" := TranslatePayroll.TimeActivityCode(WORKDAY);
                end else begin
                    Nonworking := true;
                    "Time Activity Code" := TranslatePayroll.TimeActivityCode(DAYOFF);
                end;
                Modify(true);
                i := i + 1;
            until Next = 0;
        end;

        ReleaseCalendarLines(CalendarCode);
    end;

    local procedure ReleaseCalendarLines(CalendarCode: Code[10])
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
    begin
        with PayrollCalendarLine do begin
            SetRange("Calendar Code", CalendarCode);
            FindSet();
            repeat
                Release;
            until Next = 0;
        end;
    end;

    local procedure CreateUpdPosAndLabContractHire(StartDate: Date; PositionNoCopyFrom: Code[20]; BaseSalary: Decimal; CalendarCode: Code[10]): Code[20]
    var
        Position: Record Position;
        LaborContract: Record "Labor Contract";
        PersonNo: Code[20];
    begin
        PersonNo := CreatePerson;
        CopyModifyPosition(Position, CalendarCode, StartDate, PositionNoCopyFrom, BaseSalary);
        LibraryHRP.CreateLaborContractHire(LaborContract, PersonNo, StartDate, Position."No.", true, true);
        exit(LaborContract."Employee No.");
    end;

    local procedure CreateVacationOrder(EmployeeNo: Code[20]; OrderDate: Date; StartDate: Date; EndDate: Date; TimeActivityCode: Code[10]): Code[20]
    var
        PostedAbsenceHeader: Record "Posted Absence Header";
    begin
        LibraryHRP.CreateVacation(EmployeeNo, TimeActivityCode, OrderDate, StartDate, EndDate);
        with PostedAbsenceHeader do begin
            SetRange("Employee No.", EmployeeNo);
            FindFirst;
            exit("No.");
        end;
    end;

    local procedure CreateAdvanceCalcGroup(PayrollCalcType: Code[20]): Code[10]
    var
        PayrollCalcGroup: Record "Payroll Calc Group";
    begin
        with PayrollCalcGroup do begin
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Payroll Calc Group");
            Type := Type::Between;
            Insert;
            AddPayrollCalcGroupLine(Code, PayrollCalcType);
            AddPayrollCalcGroupLine(Code, Income13PercentTxt);
            exit(Code);
        end;
    end;

    local procedure GetCntDayOffInIntWithOutHol(CalendarNo: Code[10]; StartDate: Date; EndDate: Date): Integer
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
    begin
        with PayrollCalendarLine do begin
            SetRange("Calendar Code", CalendarNo);
            SetRange(Date, StartDate, EndDate);
            SetRange("Day Status", "Day Status"::Holiday);
            FindFirst;
            exit((EndDate - StartDate) + 1 - Count);
        end;
    end;

    local procedure CopyModifyPosition(var Position: Record Position; CalendarCode: Code[10]; StartDate: Date; PositionNoCopyFrom: Code[20]; BaseSalary: Decimal)
    var
        PositionNo: Code[20];
    begin
        with Position do begin
            Get(PositionNoCopyFrom);
            PositionNo := CopyPosition(StartDate);
            Get(PositionNo);
            Validate("Base Salary", BaseSalary);
            Validate("Calendar Code", CalendarCode);
            Modify(true);
            Approve(true);
        end;
    end;

    local procedure FilterPersonIncomeEntry(var PersonIncomeEntry: Record "Person Income Entry"; EntryType: Option; EmployeeNo: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);

        with PersonIncomeEntry do begin
            SetRange("Entry Type", EntryType);
            SetRange("Advance Payment", false);
            SetRange("Person No.", Employee."Person No.");
        end;
    end;

    local procedure VerifyPersonTaxableIncome(EmployeeNo: Code[20]; ExpectedAmt: Decimal)
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            FilterPersonIncomeEntry(PersonIncomeEntry, "Entry Type"::"Taxable Income", EmployeeNo);
            SetFilter("Tax Code", '<>%1', '');
            CalcSums(Base);
            Assert.AreEqual(ExpectedAmt, Base, TaxableIncomeErr);
        end;
    end;

    local procedure VerifyPersonIncomeTaxAmount(EmployeeNo: Code[20]; ExpectedAmt: Decimal)
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            FilterPersonIncomeEntry(PersonIncomeEntry, "Entry Type"::"Accrued Income Tax", EmployeeNo);
            CalcSums(Amount);
            Assert.AreEqual(ExpectedAmt, Amount, AccruedTaxAmounrErr);
        end;
    end;

    local procedure VerifyPaidToPerson(PersonNo: Code[20]; PeriodCode: Code[10]; ExpectedAmount: Decimal)
    var
        PersonIncomeLine: Record "Person Income Line";
    begin
        with PersonIncomeLine do begin
            SetRange("Person No.", PersonNo);
            SetRange("Period Code", PeriodCode);
            FindFirst;
            CalcFields("Paid to Person");
            Assert.AreEqual(ExpectedAmount, "Paid to Person", IncorrectPaidToPersonAmountErr);
        end;
    end;

    local procedure VerifyVacDaysInVacWithHoliday(VacOrderNo: Code[20])
    var
        PostedAbsenceLine: Record "Posted Absence Line";
    begin
        with PostedAbsenceLine do begin
            SetRange("Document Type", "Document Type"::Vacation);
            SetRange("Document No.", VacOrderNo);
            FindFirst;
            Assert.AreEqual(
              GetCntDayOffInIntWithOutHol(LibraryHRP.GetOfficialCalendarCode, "Start Date", "End Date"),
              "Calendar Days", NotCorrectCalDaysValueErr);
        end;
    end;

    local procedure VerifyPersonIncomeFSI(EmployeeNo: Code[20]; PeriodCode: Code[10]; ExpectedAmt: Decimal; ExpectedExcludedDays: Decimal)
    var
        PersonIncomeFSI: Record "Person Income FSI";
        Employee: Record Employee;
        ExcludedDays: Decimal;
    begin
        Employee.Get(EmployeeNo);

        with PersonIncomeFSI do begin
            SetRange("Period Code", PeriodCode);
            SetRange("Person No.", Employee."Person No.");
            CalcSums(Amount);
            Assert.AreEqual(ExpectedAmt, Amount, IncorrectPersonIncomeFSIAmountErr);
            SetAutoCalcFields("Excluded Days");
            FindSet();
            repeat
                ExcludedDays += "Excluded Days";
            until Next = 0;
            Assert.AreEqual(ExpectedExcludedDays, ExcludedDays, IncorrectPersonIncomeFSIExcludedDaysErr);
        end;
    end;

    local procedure GetPersonNo(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);
        exit(Employee."Person No.");
    end;

    local procedure FindPayrollPeriodCodeByPeriodShift(PayrollPeriod: Record "Payroll Period"; NumberOfPeriodsShift: Integer): Code[10]
    begin
        PayrollPeriod.Next(NumberOfPeriodsShift);
        exit(PayrollPeriod.Code);
    end;

    local procedure CalcPayrollAmountByPeriod(EmployeeNo: Code[20]; PeriodCodeFrom: Code[10]; PeriodCodeTo: Code[10]) PayrollAmount: Decimal
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
    begin
        with PostedPayrollDocument do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PeriodCodeFrom, PeriodCodeTo);
            FindSet();
            repeat
                PayrollAmount += CalcPayrollAmount;
            until Next = 0;
        end;
    end;

    local procedure CalcPayrollDocumentAmount(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; PayrollElementTypeFilter: Text): Decimal
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        FindPostedPayrollDoc(PostedPayrollDocument, EmployeeNo, PayrollPeriodCode);

        with PostedPayrollDocumentLine do begin
            SetRange("Document No.", PostedPayrollDocument."No.");
            SetFilter("Element Type", PayrollElementTypeFilter);
            CalcSums("Payroll Amount");
            exit("Payroll Amount");
        end;
    end;

    local procedure FormatIncomeTaxElementTypeFilter(): Text
    var
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        exit(StrSubstNo('%1', PostedPayrollDocumentLine."Element Type"::"Income Tax"));
    end;

    local procedure FormatTaxableAmtElementTypeFilter(): Text
    var
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        exit(StrSubstNo('%1|%2', PostedPayrollDocumentLine."Element Type"::Wage, PostedPayrollDocumentLine."Element Type"::Bonus));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPayrollElementHandler(var CopyPayrollElementReport: TestRequestPage "Copy Payroll Element")
    var
        Value: Variant;
        NewPayrollElementCode: Code[20];
    begin
        LibraryVariableStorage.Dequeue(Value);
        NewPayrollElementCode := Value;
        CopyPayrollElementReport.NewPayrollElementCode.Value := NewPayrollElementCode;
        CopyPayrollElementReport.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPayrollDocHandler(var CopyPayrollDocument: TestRequestPage "Copy Payroll Document")
    var
        Value: Variant;
    begin
        CopyPayrollDocument.DocumentTypeTextBox.SetValue(1); // Posted Payroll Document
        LibraryVariableStorage.Dequeue(Value);
        CopyPayrollDocument.DocumentNoTextBox.SetValue(Value);
        CopyPayrollDocument.IncludeHeaderCheckBox.SetValue(true);
        CopyPayrollDocument.OK.Invoke;
    end;
}

