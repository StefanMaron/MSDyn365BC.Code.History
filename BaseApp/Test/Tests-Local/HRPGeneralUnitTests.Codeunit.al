codeunit 144208 "HRP General Unit Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryHRP: Codeunit "Library - HRP";
        LibraryUtility: Codeunit "Library - Utility";
        LaborContractManagement: Codeunit "Labor Contract Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        OrgUnitStatus: Option Open,Approved,Closed;
        VeteranType: Option Chernobyl,Afganistan,Pensioneer;
        IsInitialized: Boolean;
        WrongOrgUnitStateErr: Label 'Organizational Unit State is incorrect';
        ErrMsgShouldAppearErr: Label 'Error message should appear';
        WrongLevelErr: Label 'Wrong %1 Level value';
        WrongIdentityDocErr: Label 'Wrong Identity Document';
        IsVeteranErr: Label 'Person is not Veteran';
        PositionStatusErr: Label 'Position Status is incorrect';
        PositionRateErr: Label 'Rate can exceed 1 for budget positions only.';
        StartDateErr: Label 'Position Ending Date should be earlier than Organizational Unit Ending Date.';
        EntriesShouldBeDeletedErr: Label '%1 entries should be deleted after %2 No. %3 deleted.';
        FieldValueErr: Label 'Field %1 value is incorrect';
        ChildCountErr: Label 'Incorrect child count';
        PayrollPeriodStateErr: Label 'Payroll Period Closed value is incorrect. Should be Closed = %1';
        EmployeeAbsenceEntryErr: Label 'Employee Absence Entry not found';
        RecordNotDeletedErr: Label '%1 record not deleted';
        YouCannotEnterErr: Label 'You cannot enter %1 if %2 is %3.';
        FieldCannotBeChangedErr: Label '%1 cannot be changed if %2 is %3.';
        PersonNameHistoryCountErr: Label 'The number of %1 entries incorrect';
        CannotBeGreaterThanErr: Label '%1 can not be greater than %2.';
        WrongDayErr: Label 'Wrong day of the %1.';
        CannotBeEmptyErr: Label '%1 cannot be empty';
        IncorrectBaseSalaryAmountErr: Label 'Incorrect Base Salary Amount';

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitApprove()
    var
        OrgUnit: Record "Organizational Unit";
    begin
        // Check Org. Unit status after Approval
        Initialize;
        CheckOrgUnitStatus(CreateApproveOrgUnit(OrgUnit.Type::Unit), OrgUnit.Status::Approved);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitClose()
    var
        OrgUnit: Record "Organizational Unit";
        OrgUnitCode: Code[10];
    begin
        // Check Org. Unit status after Closing
        Initialize;
        OrgUnitCode := CreateApproveOrgUnit(OrgUnit.Type::Unit);

        LibraryHRP.ChangeOrgUnitStatus(OrgUnitCode, OrgUnitStatus::Closed, false);
        CheckOrgUnitStatus(OrgUnitCode, OrgUnit.Status::Closed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitReopen()
    var
        OrgUnit: Record "Organizational Unit";
        OrgUnitCode: Code[10];
    begin
        // Check Org. Unit status after Reopening
        Initialize;
        OrgUnitCode := CreateApproveOrgUnit(OrgUnit.Type::Unit);

        LibraryHRP.ChangeOrgUnitStatus(OrgUnitCode, OrgUnitStatus::Open, false);
        CheckOrgUnitStatus(OrgUnitCode, OrgUnit.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitHeadingEmptyDelete()
    var
        OrgUnit: Record "Organizational Unit";
    begin
        // Check Org. Unit with Heading type can be deleted
        Initialize;
        CheckOrgUnitDelete(LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Heading));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitHeadingDelete()
    var
        OrgUnit: Record "Organizational Unit";
        OrgUnitCode1: Code[10];
        OrgUnitCode2: Code[10];
    begin
        // Check Org. Unit with Heading type can be deleted
        Initialize;
        OrgUnitCode1 := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Heading);
        OrgUnitCode2 := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Unit);

        OrgUnitSetParentCode(OrgUnitCode1, OrgUnitCode2);
        asserterror CheckOrgUnitDelete(OrgUnitCode1);
        Assert.AreEqual('', GetLastErrorText, ErrMsgShouldAppearErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrgUnitIndent()
    var
        OrgUnit: Record "Organizational Unit";
        OrgUnitCode1: Code[10];
        OrgUnitCode2: Code[10];
        OldLevel: Integer;
    begin
        // Check Org. Unit Level is increased after assigning Parent
        Initialize;
        OrgUnitCode1 := CreateApproveOrgUnit(OrgUnit.Type::Heading);
        OrgUnitCode2 := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Unit);

        with OrgUnit do begin
            Get(OrgUnitCode2);
            OldLevel := Level;
            Validate("Parent Code", OrgUnitCode1);
            Modify(true);
            Assert.AreEqual(
              OldLevel + 1, Level,
              StrSubstNo(WrongLevelErr, TableCaption));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonIdentityDoc()
    var
        Person: Record Person;
        PersonDoc: Record "Person Document";
    begin
        // Check GetIdentityDoc points to correct document
        Initialize;
        LibraryHRP.CreatePerson(Person);
        with Person do begin
            "Identity Document Type" := FindTaxPayerDocType;
            Modify(true);
            LibraryHRP.CreateIdentityDoc(
              "No.", FindTaxPayerDocType, CalcDate('<-CY>', WorkDate));
            GetIdentityDoc(WorkDate, PersonDoc);
            Assert.AreEqual("No.", PersonDoc."Person No.", WrongIdentityDocErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonMedicalInfo()
    var
        Person: Record Person;
        PersonMedicalInfo: Record "Person Medical Info";
    begin
        // Check IsVeteran returns correct status
        Initialize;
        LibraryHRP.CreatePerson(Person);
        LibraryHRP.CreatePersonMedicalInfo(
          PersonMedicalInfo, Person."No.", PersonMedicalInfo.Type::Privilege,
          PersonMedicalInfo.Privilege::Pensioner, PersonMedicalInfo."Disability Group"::" ", CalcDate('<-CY>', WorkDate));
        Assert.IsTrue(Person.IsVeteran(VeteranType::Pensioneer, WorkDate), IsVeteranErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonChildCount()
    var
        EmployeeRelative: Record "Employee Relative";
        Person: Record Person;
        LibraryHR: Codeunit "Library - Human Resource";
        RelativeChildCode: Code[10];
        ChildCount: Integer;
    begin
        // Check Person table ChildNumber function
        Initialize;
        LibraryHRP.CreatePerson(Person);
        RelativeChildCode := FindChildRelativeType;
        for ChildCount := 1 to LibraryRandom.RandInt(10) do begin
            LibraryHR.CreateEmployeeRelative(EmployeeRelative, Person."No.");
            with EmployeeRelative do begin
                "Relative Person No." := CreatePerson;
                "Birth Date" :=
                  CalcDate('<-' + Format(LibraryRandom.RandInt(17)) + 'Y>', WorkDate);
                "Relative Code" := RelativeChildCode;
                Modify(true);
            end;
        end;
        Assert.AreEqual(ChildCount, Person.ChildrenNumber(WorkDate), ChildCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonGenderModify()
    var
        Person: Record Person;
        Employee: Record Employee;
        EmployeeNo: Code[20];
    begin
        // Check Employee Gender changed after Person Gender changed
        Initialize;
        with Person do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Gender := Gender::Male;
            Insert(true);
            EmployeeNo := CreateEmployee("No.");

            Validate(Gender, Gender::Female);
            Modify(true);

            Employee.Get(EmployeeNo);
            Assert.AreEqual(
              Gender, Employee.Gender,
              StrSubstNo(FieldValueErr, Employee.FieldCaption(Gender)));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonCitizenShipModify()
    var
        Person: Record Person;
        Employee: Record Employee;
        CountryRegion: Record "Country/Region";
        EmployeeNo: Code[20];
    begin
        // Check Employee Country/Region changed after Person Country/Region changed
        Initialize;
        LibraryHRP.CreatePerson(Person);
        CountryRegion.FindFirst;
        EmployeeNo := CreateEmployee(Person."No.");
        with Person do begin
            Validate("Citizenship Country/Region", CountryRegion.Code);
            Modify(true);
            Employee.Get(EmployeeNo);
            Assert.AreEqual(
              "Citizenship Country/Region", Employee."Country/Region Code",
              StrSubstNo(FieldValueErr, Employee.FieldCaption("Country/Region Code")));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClosePosition()
    var
        Position: Record Position;
    begin
        // Check Position Status after closing
        Initialize;
        with Position do begin
            Get(CreatePosition(WorkDate, false));
            Close(false);
            Assert.AreEqual(Status::Closed, Status, PositionStatusErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenPosition()
    var
        Position: Record Position;
    begin
        // Check Position Status after reopening
        Initialize;
        Position.Get(CreatePosition(WorkDate, true));
        Assert.AreEqual(Position.Status::Planned, Position.Status, PositionStatusErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositionSetOrgUnit()
    var
        Position: Record Position;
        OrgUnit: Record "Organizational Unit";
    begin
        // Check Position Org. Unit Name after assigning Org. Unit Code
        Initialize;
        OrgUnit.Get(CreateApproveOrgUnit(OrgUnit.Type::Unit));
        with Position do begin
            Get(CreatePosition(WorkDate, true));
            Validate("Starting Date", CalcDate('<+1D>', WorkDate));
            Validate("Org. Unit Code", OrgUnit.Code);
            Modify(true);
            Assert.AreEqual(
              OrgUnit.Name, "Org. Unit Name",
              StrSubstNo(FieldValueErr, FieldCaption("Org. Unit Name")));
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PositionDelete()
    var
        Position: Record Position;
        LaborContractTermsSetup: Record "Labor Contract Terms Setup";
        PositionNo: Code[20];
    begin
        // Check Labor Contract Terms Setup deleted after Position deleted
        Initialize;
        PositionNo := CreatePosition(WorkDate, true);
        CreateLaborContractTermsSetup(PositionNo);
        Position.Get(PositionNo);
        Position.Delete(true);
        with LaborContractTermsSetup do begin
            SetRange("Table Type", "Table Type"::Position);
            SetRange("No.", PositionNo);
            Assert.IsTrue(IsEmpty,
              StrSubstNo(EntriesShouldBeDeletedErr, TableCaption, Position.TableCaption, PositionNo));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositionSetParentPosition()
    var
        Position: Record Position;
        PositionNo1: Code[20];
        PositionNo2: Code[20];
        OldLevel: Integer;
    begin
        // Check Level increased after assigned Parent Position
        Initialize;
        PositionNo1 := CreatePosition(WorkDate, true);
        PositionNo2 := CreatePosition(WorkDate, false);
        with Position do begin
            Get(PositionNo1);
            OldLevel := Level;
            Validate("Parent Position No.", PositionNo2);
            Modify(true);
            Assert.AreEqual(
              OldLevel + 1, Level,
              StrSubstNo(WrongLevelErr, TableCaption));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositionRateExceed()
    var
        Position: Record Position;
    begin
        // Check error message on Position rate > 1
        Initialize;
        with Position do begin
            Get(CreatePosition(WorkDate, true));
            asserterror Validate(Rate, LibraryRandom.RandIntInRange(2, 10));
            Assert.ExpectedError(PositionRateErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositionEndingDateCheck()
    var
        OrgUnit: Record "Organizational Unit";
        Position: Record Position;
    begin
        // Check Position Ending Date should not be later than Org. Unit Ending Date
        Initialize;
        OrgUnit.Get(CreateApproveOrgUnit(OrgUnit.Type::Unit));
        OrgUnit."Ending Date" := CalcDate('<-2W>', WorkDate);
        OrgUnit.Modify(true);
        with Position do begin
            Get(CreatePosition(WorkDate, true));
            Validate("Starting Date", CalcDate('<+1D>', WorkDate));
            Validate("Org. Unit Code", OrgUnit.Code);
            asserterror Validate("Ending Date", CalcDate('<+1W>', OrgUnit."Ending Date"));
            Assert.ExpectedError(StartDateErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositionJobTitleChange()
    var
        JobTitle: Record "Job Title";
        Position: Record Position;
    begin
        // Check Position fields values assigned by Job Title defining
        Initialize;
        JobTitle.FindFirst;
        with Position do begin
            Get(CreatePosition(WorkDate, true));
            Validate("Job Title Code", JobTitle.Code);
            Modify(true);
            Assert.AreEqual(
              JobTitle.Name, "Job Title Name",
              StrSubstNo(FieldValueErr, FieldCaption("Job Title Name")));
            Assert.AreEqual(
              JobTitle."Base Salary Element Code", "Base Salary Element Code",
              StrSubstNo(FieldValueErr, FieldCaption("Base Salary Element Code")));
            Assert.AreEqual(
              JobTitle."Base Salary Amount", "Base Salary Amount",
              StrSubstNo(FieldValueErr, FieldCaption("Base Salary Amount")));
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PayrollPeriodClose()
    var
        PayrollPeriod: Record "Payroll Period";
        PeriodStartDate: Date;
    begin
        // Check Period State after closing
        Initialize;
        PeriodStartDate := PayrollPeriodStartDate;
        PayrollPeriod.Get(
          CreatePayrollPeriod(PeriodStartDate, CalcDate('<+1M>', PeriodStartDate)));
        ClosePeriod(PayrollPeriod);

        PayrollPeriod.Get(PayrollPeriod.Code);
        Assert.IsTrue(PayrollPeriod.Closed, StrSubstNo(PayrollPeriodStateErr, true));
        PayrollPeriod.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PayrollPeriodCloseEmplLedgerEntr()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        CalendarDays: Integer;
        PeriodStartDate: Date;
    begin
        // Check created Employee Absence Entry after Period Closing
        Initialize;
        EmployeeNo := CreateEmployee(CreateSimplePerson);
        PeriodStartDate := PayrollPeriodStartDate;
        PayrollPeriod.Get(
          CreatePayrollPeriod(PeriodStartDate, CalcDate('<+1M>', PeriodStartDate)));
        CalendarDays := CreateEmployeeAbsEntry(EmployeeNo, PayrollPeriod);
        CreateTimeSheetDetail(EmployeeNo, PeriodStartDate, PeriodStartDate);
        ClosePeriod(PayrollPeriod);

        VerifyEmployeeAbsenceEntry(
          EmployeeNo, 0,
          CalcDate('<+2D>', PayrollPeriod."Ending Date"));

        VerifyEmployeeAbsenceEntry(
          EmployeeNo, CalendarDays,
          CalcDate('<+1Y+2D>', PayrollPeriod."Ending Date"));
        PayrollPeriod.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PayrollPeriodReopen()
    var
        PayrollPeriod: Record "Payroll Period";
        PayrollPeriodClose: Codeunit "Payroll Period-Close";
        PeriodStartDate: Date;
    begin
        // Check Period State after Reopening
        Initialize;
        PeriodStartDate := PayrollPeriodStartDate;
        PayrollPeriod.Get(
          CreatePayrollPeriod(PeriodStartDate, CalcDate('<+1M>', PeriodStartDate)));
        ClosePeriod(PayrollPeriod);

        PayrollPeriodClose.Reopen(PayrollPeriod);
        PayrollPeriod.Get(PayrollPeriod.Code);
        Assert.IsFalse(PayrollPeriod.Closed, StrSubstNo(PayrollPeriodStateErr, false));
        PayrollPeriod.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalcTypeDelete()
    var
        PayrollCalcType: Record "Payroll Calc Type";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        Initialize;
        LibraryHRP.CreatePayrollCalcType(
          CreatePayrollElement, PayrollCalcType."Use in Calc"::Always, PayrollCalcType);
        PayrollCalcType.Delete(true);
        PayrollCalcTypeLine.SetRange("Calc Type Code", PayrollCalcType.Code);
        Assert.IsTrue(
          PayrollCalcTypeLine.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, PayrollCalcTypeLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalcTypeElementAssign()
    var
        PayrollCalcType: Record "Payroll Calc Type";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
        PayrollElement: Record "Payroll Element";
    begin
        Initialize;
        PayrollElement.Get(CreatePayrollElement);
        LibraryHRP.CreatePayrollCalcType(
          PayrollElement.Code, PayrollCalcType."Use in Calc"::Always, PayrollCalcType);
        with PayrollCalcTypeLine do begin
            SetRange("Calc Type Code", PayrollCalcType.Code);
            FindFirst;
            Assert.AreEqual(
              "Element Code", PayrollElement.Code, StrSubstNo(FieldValueErr, FieldCaption("Element Code")));
            Assert.AreEqual(
              Calculate, PayrollElement.Calculate, StrSubstNo(FieldValueErr, FieldCaption(Calculate)));
            Assert.AreEqual(
              "Element Type", PayrollElement.Type, StrSubstNo(FieldValueErr, FieldCaption("Element Type")));
            Assert.AreEqual(
              "Element Name", PayrollElement."Element Group",
              StrSubstNo(FieldValueErr, FieldCaption("Element Name")));
            Assert.AreEqual(
              "Posting Type", PayrollElement."Posting Type",
              StrSubstNo(FieldValueErr, FieldCaption("Posting Type")));
            Assert.AreEqual(
              "Payroll Posting Group", PayrollElement."Payroll Posting Group",
              StrSubstNo(FieldValueErr, FieldCaption("Payroll Posting Group")));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AbsenceHeaderDelete()
    var
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
    begin
        // Check Absence lines deleted after Absence Header deleted
        Initialize;
        CreateAbsenceHeaderWithLine(AbsenceHeader, AbsenceHeader."Document Type"::Vacation);
        AbsenceHeader.Delete(true);
        FilterAbsenceLine(AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine);
        Assert.IsTrue(AbsenceLine.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, AbsenceLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AbsenceHeaderAssignDim()
    var
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        DimensionValue: Record "Dimension Value";
    begin
        // Check Absence lines updated Dimension after Absence Header assigned Dimension
        Initialize;
        CreateAbsenceHeaderWithLine(AbsenceHeader, AbsenceHeader."Document Type"::Vacation);
        CreateDimensionValue(DimensionValue);

        AbsenceHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        AbsenceHeader.Modify(true);

        FilterAbsenceLine(AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine);
        AbsenceLine.FindFirst;
        Assert.AreEqual(DimensionValue.Code, AbsenceLine."Shortcut Dimension 1 Code",
          StrSubstNo(FieldValueErr, AbsenceLine.FieldCaption("Shortcut Dimension 1 Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AbsenceHeaderReopen()
    var
        AbsenceHeader: Record "Absence Header";
        ReleaseAbsenceOrder: Codeunit "Release Absence Order";
    begin
        // Check Absence Header status after reopening
        Initialize;
        CreateAbsenceHeader(AbsenceHeader, AbsenceHeader."Document Type"::Vacation);
        with AbsenceHeader do begin
            Status := Status::Released;
            Modify;
            ReleaseAbsenceOrder.Reopen(AbsenceHeader);
            Assert.AreEqual(Status::Open, Status, StrSubstNo(FieldValueErr, FieldCaption(Status)));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AbsenceLineCalendarDaysSet()
    var
        AbsenceLine: Record "Absence Line";
        AbsenceHeader: Record "Absence Header";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        CalendarDays: Integer;
    begin
        // Check End Date Value after setting Start Date and Calendar Days fields values
        Initialize;
        EmployeeNo := CreateEmployee(CreatePerson);
        CreateSimpleEmployeeJobEntry(EmployeeNo, WorkDate);
        CreateAbsenceHeaderWithLine(AbsenceHeader, AbsenceHeader."Document Type"::Vacation);
        FilterAbsenceLine(AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine);
        CalendarDays := LibraryRandom.RandInt(10);
        with AbsenceLine do begin
            FindFirst;
            "Employee No." := EmployeeNo;
            "Time Activity Code" :=
              LibraryHRP.FindVacationTimeActivityCode(TimeActivity."Vacation Type"::Regular);
            "Start Date" := WorkDate;
            Validate("Calendar Days", CalendarDays);
            Assert.AreEqual(
              CalcDate(StrSubstNo('<%1D>', "Calendar Days" - 1), "Start Date"), "End Date",
              StrSubstNo(FieldValueErr, FieldCaption("End Date")));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AbsenceLineRelativePersNonSickLeave()
    var
        AbsenceLine: Record "Absence Line";
        AbsenceHeader: Record "Absence Header";
    begin
        // Check Error message when assigning Relative Person No. for
        // Absence Line with Sick Leave without Relative Person allowed
        Initialize;
        CreateAbsenceHeaderWithLine(
          AbsenceHeader, AbsenceHeader."Document Type"::"Sick Leave");

        FilterAbsenceLine(AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine);
        with AbsenceLine do begin
            FindFirst;
            "Sick Leave Type" := "Sick Leave Type"::"Common Injury";
            asserterror Validate("Relative Person No.", CreatePerson);
            Assert.AreEqual(
              StrSubstNo(YouCannotEnterErr,
                FieldCaption("Relative Person No."),
                FieldCaption("Sick Leave Type"),
                "Sick Leave Type"),
              GetLastErrorText, ErrMsgShouldAppearErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollElementDeleteCheck()
    var
        PayrollElement: Record "Payroll Element";
        PayrollCalcType: Record "Payroll Calc Type";
        PayrollBaseAmount: Record "Payroll Base Amount";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
        PayrollRangeHeader: Record "Payroll Range Header";
        PayrollCalculation: Record "Payroll Calculation";
        ElementCode: Code[20];
    begin
        // Check deletion of specific records when Payroll Element is deleted
        Initialize;
        ElementCode := CreatePayrollElement;
        CreatePayrollBaseAmount(ElementCode, PayrollBaseAmount);
        LibraryHRP.CreatePayrollCalcType(
          ElementCode, PayrollCalcType."Use in Calc"::Always, PayrollCalcType);
        CreatePayrollRangeHeader(ElementCode);
        CreatePayrollCalculation(ElementCode);

        PayrollElement.Get(ElementCode);
        PayrollElement.Delete(true);

        Assert.IsFalse(PayrollBaseAmount.Get(ElementCode, PayrollBaseAmount.Code),
          StrSubstNo(RecordNotDeletedErr, PayrollBaseAmount.TableCaption));
        PayrollCalcTypeLine.SetRange("Calc Type Code", PayrollCalcType.Code);
        Assert.IsTrue(PayrollCalcTypeLine.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, PayrollCalcTypeLine.TableCaption));
        PayrollRangeHeader.SetRange("Element Code", ElementCode);
        Assert.IsTrue(PayrollRangeHeader.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, PayrollRangeHeader.TableCaption));
        PayrollCalculation.SetRange("Element Code", ElementCode);
        Assert.IsTrue(PayrollCalculation.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, PayrollCalculation.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollElementTypeChange()
    var
        PayrollElement: Record "Payroll Element";
    begin
        // Check Posting Type/Normal Sign values when Payroll Element type changed
        Initialize;
        with PayrollElement do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Insert;
            CheckPayrollElementTypeChange(
              PayrollElement, Type::"Income Tax", "Posting Type"::Liability, "Normal Sign"::Negative);
            CheckPayrollElementTypeChange(
              PayrollElement, Type::Wage, "Posting Type"::Charge, "Normal Sign"::Positive);
            CheckPayrollElementTypeChange(
              PayrollElement, Type::Funds, "Posting Type"::"Liability Charge", "Normal Sign"::Negative);
            CheckPayrollElementTypeChange(
              PayrollElement, Type::"Netto Salary", "Posting Type"::"Not Post", "Normal Sign"::Negative);
            CheckPayrollElementTypeChange(
              PayrollElement, Type::"Tax Deduction", "Posting Type"::"Not Post", "Normal Sign"::Negative);
            CheckPayrollElementTypeChange(
              PayrollElement, Type::Other, "Posting Type"::"Not Post", "Normal Sign"::Negative);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineDelete()
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContractTerms: Record "Labor Contract Terms";
    begin
        // Check Labor Contract Terms deleted when Labor Contract Line is deleted
        with LaborContractLine do begin
            CreateSimpleLaborContractLine(
              CreateLaborContract, "Operation Type"::Hire,
              LibraryUtility.GenerateGUID, LaborContractLine);
            CreateLaborContractTerms(
              "Contract No.",
              "Operation Type",
              "Supplement No.");

            Delete(true);
            LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
        end;
        Assert.IsTrue(
          LaborContractTerms.IsEmpty,
          StrSubstNo(RecordNotDeletedErr, LaborContractTerms.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineValidateFieldValue()
    var
        LaborContractLine: Record "Labor Contract Line";
        GroundsForTermination: Record "Grounds for Termination";
    begin
        // Check Error message on incorrect Labor Contract Line field values
        GroundsForTermination.FindFirst;
        with LaborContractLine do begin
            CreateSimpleLaborContractLine(
              CreateLaborContract, "Operation Type"::Hire,
              LibraryUtility.GenerateGUID, LaborContractLine);
            "Dismissal Reason" := GroundsForTermination.Code;
            "Starting Date" := WorkDate;
            CheckLaborContractLineValidateFieldValue(
              LaborContractLine, "Operation Type"::Hire,
              FieldNo("Dismissal Reason"), FieldCaption("Dismissal Reason"));
            CheckLaborContractLineValidateFieldValue(
              LaborContractLine, "Operation Type"::Combination,
              FieldNo("Dismissal Reason"), FieldCaption("Dismissal Reason"));
            CheckLaborContractLineValidateFieldValue(
              LaborContractLine, "Operation Type"::Dismissal,
              FieldNo("Starting Date"), FieldCaption("Starting Date"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineCombineApprove()
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContract: Record "Labor Contract";
    begin
        // Verify Employee Job Entries generated by Combination
        CreateApproveEmployeeCombination(LaborContract, LaborContractLine);
        VerifyEmployeeJobEntry(LaborContractLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineTransferCalCodeChange()
    var
        LaborContractLine: Record "Labor Contract Line";
        TimesheetLine: Record "Timesheet Line";
        EmployeeNo: Code[20];
    begin
        // Check Timesheet Lines change Calendar Code when Transferred to other Position
        CreateApproveEmployeeTransfer(LaborContractLine, EmployeeNo);
        TimesheetLine.Get(EmployeeNo, LaborContractLine."Starting Date");
        Assert.AreEqual(
          TimesheetLine."Calendar Code", LibraryHRP.GetOfficialCalendarCode,
          StrSubstNo(FieldValueErr, TimesheetLine."Calendar Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineTerminateCombination()
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContract: Record "Labor Contract";
        EmployeeJobEntry: Record "Employee Job Entry";
        TerminationDate: Date;
    begin
        // Verify Employee Job Entries generated by Terminate Combination action
        CreateApproveEmployeeCombination(LaborContract, LaborContractLine);
        TerminationDate := CalcDate('<-1D>', LaborContractLine."Ending Date");
        SetLaborContractLineEndDate(LaborContractLine, TerminationDate);
        LaborContractManagement.TerminateCombination(LaborContractLine);
        EmployeeJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
        EmployeeJobEntry.FindSet;
        Assert.AreEqual(
          EmployeeJobEntry."Ending Date", TerminationDate,
          StrSubstNo(FieldValueErr, EmployeeJobEntry."Ending Date"));
        EmployeeJobEntry.Next;
        Assert.AreEqual(
          EmployeeJobEntry."Position Rate", -LaborContractLine."Position Rate",
          StrSubstNo(FieldValueErr, EmployeeJobEntry."Position Rate"));
        Assert.AreEqual(
          EmployeeJobEntry."Position Changed", false,
          StrSubstNo(FieldValueErr, EmployeeJobEntry."Position Changed"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineUndoTransfer()
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContract: Record "Labor Contract";
    begin
        // Check Labor Contract Line status after undo approval of Combination
        CreateLaborContractWithLine(
          LaborContract, LaborContractLine."Operation Type"::Transfer);
        ApproveLaborContractLine(LaborContractLine, LaborContract."No.");
        LaborContractManagement.UndoApproval(LaborContractLine);
        Assert.AreEqual(
          LaborContractLine.Status::Open, LaborContractLine.Status,
          StrSubstNo(FieldValueErr, LaborContractLine.Status));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineUndoCombine()
    var
        LaborContractLine: Record "Labor Contract Line";
        LaborContract: Record "Labor Contract";
        EmployeeJobEntry: Record "Employee Job Entry";
    begin
        // Check Labor Contract Line status after undo approval of Combination
        CreateLaborContractWithLine(
          LaborContract, LaborContractLine."Operation Type"::Combination);
        ApproveLaborContractLine(LaborContractLine, LaborContract."No.");

        with EmployeeJobEntry do begin
            Get(CreateSimpleEmployeeJobEntry(LaborContract."Employee No.", WorkDate));
            "Contract No." := LaborContract."No.";
            "Document No." := LaborContractLine."Order No.";
            "Document Date" := LaborContractLine."Order Date";
            Modify;
        end;

        LaborContractManagement.UndoApproval(LaborContractLine);
        Assert.AreEqual(
          LaborContractLine.Status::Open, LaborContractLine.Status,
          StrSubstNo(FieldValueErr, LaborContractLine.Status));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePersonName()
    var
        PersonNo: Code[20];
        OrderNos: array[2] of Code[20];
        OrderDates: array[2] of Date;
        OldNames: array[3] of Text[30];
        NewNames: array[3] of Text[30];
    begin
        // Check Person Name History after Person Name changed
        CreatePersonChangeName(OldNames, NewNames, OrderNos, OrderDates, PersonNo);

        VerifyPersonNameHistory(PersonNo, WorkDate, OldNames, OrderNos[1], OrderDates[1]);
        VerifyPersonNameHistory(PersonNo, OrderDates[2], NewNames, OrderNos[2], WorkDate);
        VerifyPersonNames(PersonNo, NewNames);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelChangePersonName()
    var
        PersonNameHistory: Record "Person Name History";
        ChangePersonName: Codeunit "Change Person Name";
        OrderNos: array[2] of Code[20];
        PersonNo: Code[20];
        OrderDates: array[2] of Date;
        OldNames: array[3] of Text[30];
        NewNames: array[3] of Text[30];
    begin
        // Check Person Name History Cancel Changes correcty returns original names
        CreatePersonChangeName(OldNames, NewNames, OrderNos, OrderDates, PersonNo);

        with PersonNameHistory do begin
            SetRange("Person No.", PersonNo);
            FindLast;
            ChangePersonName.CancelChanges(PersonNameHistory);
            Assert.IsTrue(IsEmpty, StrSubstNo(PersonNameHistoryCountErr, TableCaption));
        end;
        VerifyPersonNames(PersonNo, OldNames);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalSetupWeekPeriodNo()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
    begin
        // Check Period No. OnValidate trigger - Week
        with PayrollCalendarSetup do begin
            ValidatePayrollCalSetupPeriodNo(PayrollCalendarSetup, "Period Type"::Week, LibraryRandom.RandIntInRange(1, 53));
            Assert.AreEqual(Format("Period No."), "Period Name", StrSubstNo(FieldValueErr, FieldCaption("Period Name")));
            ValidatePayrollCalSetupPeriodNo(PayrollCalendarSetup, "Period Type"::Week, 0);
            Assert.AreEqual('', "Period Name", StrSubstNo(FieldValueErr, FieldCaption("Period Name")));
            asserterror ValidatePayrollCalSetupPeriodNo(
                PayrollCalendarSetup, "Period Type"::Week, LibraryRandom.RandIntInRange(53, 100));
            Assert.ExpectedError(StrSubstNo(CannotBeGreaterThanErr, FieldCaption("Period No."), 52));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalSetupMonthPeriodNo()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
        LocMgt: Codeunit "Localisation Management";
    begin
        // Check Period No. OnValidate trigger - Month
        with PayrollCalendarSetup do begin
            ValidatePayrollCalSetupPeriodNo(PayrollCalendarSetup, "Period Type"::Month, LibraryRandom.RandIntInRange(1, 12));
            Assert.AreEqual(
              LocMgt.GetMonthName(DMY2Date(1, "Period No.", 2000), false),
              "Period Name", StrSubstNo(FieldValueErr, FieldCaption("Period Name")));
            ValidatePayrollCalSetupPeriodNo(PayrollCalendarSetup, "Period Type"::Month, 0);
            Assert.AreEqual('', "Period Name", StrSubstNo(FieldValueErr, FieldCaption("Period Name")));
            asserterror ValidatePayrollCalSetupPeriodNo(
                PayrollCalendarSetup, "Period Type"::Month, LibraryRandom.RandIntInRange(13, 100));
            Assert.ExpectedError(StrSubstNo(CannotBeGreaterThanErr, FieldCaption("Period No."), 12));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalSetupWeekDayNo()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
    begin
        // Check Day No. OnValidate trigger - Week
        with PayrollCalendarSetup do begin
            ValidatePayrollCalSetupDayNo(PayrollCalendarSetup, "Period Type"::Week, 0, 0, false);
            Assert.AreEqual('', "Period Name", StrSubstNo(FieldValueErr, FieldCaption("Period Name")));
            ValidatePayrollCalSetupDayNo(
              PayrollCalendarSetup, "Period Type"::Week, LibraryRandom.RandIntInRange(1, 7), 0, false);
            Assert.AreEqual("Day No.", "Week Day", StrSubstNo(FieldValueErr, FieldCaption("Week Day")));
            Assert.AreEqual(Format("Week Day"), Description, StrSubstNo(FieldValueErr, FieldCaption(Description)));
            asserterror ValidatePayrollCalSetupDayNo(
                PayrollCalendarSetup, "Period Type"::Week, LibraryRandom.RandIntInRange(8, 50), 0, false);
            Assert.ExpectedError(StrSubstNo(WrongDayErr, Format("Period Type"::Week)));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalSetupMonthDayNo()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
        LocMgt: Codeunit "Localisation Management";
    begin
        // Check Day No. OnValidate trigger - Month
        with PayrollCalendarSetup do begin
            ValidatePayrollCalSetupDayNo(PayrollCalendarSetup, "Period Type"::Month,
              LibraryRandom.RandIntInRange(1, 28), LibraryRandom.RandIntInRange(1, 12), true);
            Assert.AreEqual(
              Format("Day No.") + ' ' + LocMgt.GetMonthName(DMY2Date(1, "Period No.", 2000), true),
              Description, StrSubstNo(FieldValueErr, FieldCaption(Description)));

            asserterror ValidatePayrollCalSetupDayNo(PayrollCalendarSetup, "Period Type"::Month, 32, 1, false);
            Assert.ExpectedError(StrSubstNo(WrongDayErr, Format("Period Type"::Month)));
            asserterror ValidatePayrollCalSetupDayNo(PayrollCalendarSetup, "Period Type"::Month, 30, 2, false);
            Assert.ExpectedError(StrSubstNo(WrongDayErr, Format("Period Type"::Month)));
            asserterror ValidatePayrollCalSetupDayNo(PayrollCalendarSetup, "Period Type"::Month, 31, 4, false);
            Assert.ExpectedError(StrSubstNo(WrongDayErr, Format("Period Type"::Month)));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollCalNonWorkingValidate()
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
    begin
        // Check OnValidate triggers for "Work Hours" and NonWorking fields.
        with PayrollCalendarSetup do begin
            Init;
            Validate("Work Hours", LibraryRandom.RandInt(10));
            Assert.IsFalse(Nonworking, StrSubstNo(FieldValueErr, FieldCaption(Nonworking)));
            "Starting Time" := Time;
            Validate(Nonworking, true);
            Assert.AreEqual(0, "Work Hours", StrSubstNo(FieldValueErr, FieldCaption("Work Hours")));
            Assert.AreEqual(0T, "Starting Time", StrSubstNo(FieldValueErr, FieldCaption("Starting Time")));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGroupOrder()
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        GroupOrderHeader: Record "Group Order Header";
        GroupOrderLine: Record "Group Order Line";
        EmployeeJobEntry: Record "Employee Job Entry";
    begin
        // Check Employee Job Entry created successfully with correct Contract No. after Group Order approved
        CreateLaborContractWithLine(LaborContract, LaborContractLine."Operation Type"::Hire);

        LaborContractLine.SetRange("Contract No.", LaborContract."No.");
        LaborContractLine.FindFirst;
        CreateSalaryTerms(LaborContract."No.", LaborContractLine."Operation Type", LaborContractLine."Supplement No.");
        CreateVacationTerms(LaborContract."No.", LaborContractLine."Operation Type", LaborContractLine."Supplement No.");

        with GroupOrderHeader do begin
            Init;
            Validate("Document Type", "Document Type"::Hire);
            Validate("Document Date", WorkDate);
            Validate("Posting Date", WorkDate);
            Insert(true);
        end;

        with GroupOrderLine do begin
            Init;
            Validate("Document Type", GroupOrderHeader."Document Type");
            Validate("Document No.", GroupOrderHeader."No.");
            Validate("Contract No.", LaborContract."No.");
            Validate("Supplement No.", LaborContractLine."Supplement No.");
            Insert(true);
        end;

        CODEUNIT.Run(CODEUNIT::"Approve Group Order", GroupOrderHeader);

        EmployeeJobEntry.SetRange("Employee No.", LaborContract."Employee No.");
        EmployeeJobEntry.FindFirst;
        Assert.AreEqual(
          EmployeeJobEntry."Contract No.", LaborContract."No.",
          StrSubstNo(FieldValueErr, EmployeeJobEntry.FieldCaption("Contract No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStaffList()
    var
        Position: Record Position;
        StaffList: Record "Staff List";
        TempStaffList: Record "Staff List" temporary;
        OldUseStaffList: Boolean;
    begin
        // Check generation of Staff List for Organizational Unit and Position
        Initialize;
        OldUseStaffList := UpdateHRSetupForStaffList(true);

        PrepareTempStaffList(TempStaffList, StaffList, Position);

        Assert.AreEqual(
          TempStaffList."Job Title Code", Position."Job Title Code",
          StrSubstNo(FieldValueErr, Position.FieldCaption("Job Title Code")));

        UpdateHRSetupForStaffList(OldUseStaffList);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ArchiveStaffList()
    var
        Position: Record Position;
        StaffList: Record "Staff List";
        TempStaffList: Record "Staff List" temporary;
        OrgUnitCode: Code[10];
        DocumentNo: Code[20];
        OldUseStaffList: Boolean;
    begin
        // Check Archive of Staff List for Organizational Unit and Position
        Initialize;
        OldUseStaffList := UpdateHRSetupForStaffList(true);

        OrgUnitCode := PrepareTempStaffList(TempStaffList, StaffList, Position);

        DocumentNo := GetNextHROrderNo;
        TempStaffList.SetFilter("Date Filter", Format(Position."Starting Date"));
        StaffList.SetFilter("Date Filter", Format(Position."Starting Date"));
        StaffList.CreateArchive(TempStaffList);

        VerifyStaffArchive(DocumentNo, OrgUnitCode, Position."Job Title Code");

        UpdateHRSetupForStaffList(OldUseStaffList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStaffOrder()
    var
        StaffListOrderHeader: Record "Staff List Order Header";
        StaffListOrderLine: Record "Staff List Order Line";
        PositionNo: Code[20];
        OldUseStaffList: Boolean;
    begin
        // Verify release of Staff List Order with new Position
        Initialize;
        OldUseStaffList := UpdateHRSetupForStaffList(true);

        PositionNo := CreatePosition(WorkDate, true);

        CreateStaffListOrder(StaffListOrderHeader, StaffListOrderLine.Type::Position, StaffListOrderLine.Action::Approve, PositionNo);
        CODEUNIT.Run(CODEUNIT::"Release Staff List Order", StaffListOrderHeader);

        Assert.AreEqual(StaffListOrderHeader.Status::Released, StaffListOrderHeader.Status,
          StrSubstNo(FieldValueErr, StaffListOrderHeader.FieldCaption(Status)));

        UpdateHRSetupForStaffList(OldUseStaffList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePostStaffOrder()
    var
        OrgUnit: Record "Organizational Unit";
        StaffListOrderHeader: Record "Staff List Order Header";
        StaffListOrderLine: Record "Staff List Order Line";
        OrgUnitCode: Code[10];
        OldUseStaffList: Boolean;
    begin
        // Verify posting of Staff List Order with new Organizational Unit
        Initialize;
        OldUseStaffList := UpdateHRSetupForStaffList(true);

        OrgUnitCode := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Unit);

        CreateStaffListOrder(StaffListOrderHeader, StaffListOrderLine.Type::"Org. Unit", StaffListOrderLine.Action::Approve, OrgUnitCode);
        CODEUNIT.Run(CODEUNIT::"Staff List Order-Post", StaffListOrderHeader);

        VerifyPostedStaffListOrder(StaffListOrderHeader."No.", OrgUnitCode);

        UpdateHRSetupForStaffList(OldUseStaffList);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateSalaryIndexationDocsHandler')]
    [Scope('OnPrem')]
    procedure CreateSalaryIndexationDocs()
    var
        OrgUnit: Record "Organizational Unit";
        Employee: Record Employee;
        OrgUnitCode: Code[10];
        OrderNo: Code[20];
        SalaryAmount: Decimal;
        Index: Decimal;
    begin
        // Verify Salary Indexation in Labor Contract
        Initialize;
        SalaryAmount := LibraryRandom.RandDecInRange(10000, 40000, 2);
        OrgUnitCode := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnit.Type::Unit);
        Employee.Get(LibraryHRP.CreateNewEmployee(WorkDate, SalaryAmount));
        Employee.Validate("Org. Unit Code", OrgUnitCode);
        Employee.Modify(true);

        Index := LibraryRandom.RandDecInRange(11, 15, 1) / 10;
        OrderNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(Index);
        LibraryVariableStorage.Enqueue(OrderNo);
        Commit();
        OrgUnit.SetRange(Code, OrgUnitCode);
        REPORT.Run(REPORT::"Create Salary Indexation Docs.", true, false, OrgUnit);

        Assert.AreEqual(Round(SalaryAmount * Index), GetBaseSalaryFromPosition(Employee."No."),
          IncorrectBaseSalaryAmountErr);
    end;

    local procedure CheckOrgUnitStatus(OrgUnitCode: Code[10]; OrgUnitStatus: Option)
    var
        OrgUnit: Record "Organizational Unit";
    begin
        with OrgUnit do begin
            Get(OrgUnitCode);
            Assert.AreEqual(OrgUnitStatus, Status, WrongOrgUnitStateErr);
        end;
    end;

    local procedure CreateApproveOrgUnit(OrgUnitType: Option) OrgUnitCode: Code[10]
    begin
        OrgUnitCode := LibraryHRP.CreateOrgUnit(WorkDate, OrgUnitType);
        LibraryHRP.ChangeOrgUnitStatus(OrgUnitCode, OrgUnitStatus::Approved, false);
    end;

    local procedure CheckOrgUnitDelete(OrgUnitCode: Code[10])
    var
        OrgUnit: Record "Organizational Unit";
    begin
        with OrgUnit do begin
            Get(OrgUnitCode);
            Delete(true);
            SetRange(Code, Code);
            Assert.IsTrue(IsEmpty,
              StrSubstNo(RecordNotDeletedErr, TableCaption));
        end;
    end;

    local procedure OrgUnitSetParentCode(ParentOrgUnitCode: Code[10]; ChildOrgUnitCode: Code[10])
    var
        OrgUnit: Record "Organizational Unit";
    begin
        OrgUnit.Get(ChildOrgUnitCode);
        OrgUnit.Validate("Parent Code", ParentOrgUnitCode);
        OrgUnit.Modify(true);
    end;

    local procedure FindTaxPayerDocType(): Code[2]
    var
        TaxpayerDocType: Record "Taxpayer Document Type";
    begin
        TaxpayerDocType.FindFirst;
        exit(TaxpayerDocType.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreatePosition(PositionDate: Date; Reopen: Boolean): Code[20]
    var
        Position: Record Position;
    begin
        Position.FindFirst;
        LibraryHRP.CopyPosition(
          Position, PositionDate, Position."No.", LibraryRandom.RandInt(10000));
        if Reopen then
            Position.Reopen(true);
        exit(Position."No.");
    end;

    local procedure CreateLaborContractTermsSetup(PositionNo: Code[20])
    var
        LaborContractTermsSetup: Record "Labor Contract Terms Setup";
    begin
        with LaborContractTermsSetup do begin
            Init;
            "Table Type" := "Table Type"::Position;
            "No." := PositionNo;
            Insert(true);
        end;
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure FindChildRelativeType(): Code[10]
    var
        Relative: Record Relative;
    begin
        Relative.SetRange("Relative Type", Relative."Relative Type"::Child);
        Relative.FindFirst;
        exit(Relative.Code);
    end;

    local procedure CreatePerson(): Code[20]
    var
        Person: Record Person;
    begin
        LibraryHRP.CreatePerson(Person);
        exit(Person."No.");
    end;

    local procedure CreateEmployee(PersonNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        with Employee do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Validate("Person No.", PersonNo);
            Insert;
            exit("No.");
        end;
    end;

    local procedure CreateSimplePerson(): Code[20]
    var
        Person: Record Person;
    begin
        with Person do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Gender := Gender::Male;
            Insert(true);
            exit("No.");
        end;
    end;

    local procedure CreateEmployeeAbsEntry(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period") CalendarDays: Integer
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        RecRef: RecordRef;
    begin
        CalendarDays := LibraryRandom.RandInt(30);
        with EmployeeAbsenceEntry do begin
            Init;
            "Employee No." := EmployeeNo;
            "Start Date" := PayrollPeriod."Starting Date";
            "End Date" := PayrollPeriod."Ending Date";
            "Entry Type" := "Entry Type"::Accrual;
            "Calendar Days" := CalendarDays;
            "Time Activity Code" := FindTimeActivityCode;
            RecRef.GetTable(EmployeeAbsenceEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            Insert;
        end;
    end;

    local procedure CreatePayrollPeriod(StartingDate: Date; EndingDate: Date): Code[10]
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        with PayrollPeriod do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            "Starting Date" := StartingDate;
            "Ending Date" := EndingDate;
            Insert;
            exit(Code);
        end;
    end;

    local procedure CreateTimeSheetDetail(EmployeeNo: Code[20]; TimesheetDetailDate: Date; StartDate: Date)
    var
        TimesheetDetail: Record "Timesheet Detail";
        TimesheetLine: Record "Timesheet Line";
        TimeActivity: Record "Time Activity";
    begin
        TimeActivity.SetFilter(Code, FindTimeActivityFilter(StartDate));
        TimeActivity.FindFirst;

        with TimesheetDetail do begin
            Init;
            "Employee No." := EmployeeNo;
            Date := TimesheetDetailDate;
            "Time Activity Code" := TimeActivity.Code;
            Insert;
        end;

        with TimesheetLine do begin
            Init;
            "Employee No." := EmployeeNo;
            Date := TimesheetDetail.Date;
            Insert;
        end;
    end;

    local procedure ClosePeriod(var PayrollPeriod: Record "Payroll Period")
    begin
        CODEUNIT.Run(CODEUNIT::"Payroll Period-Close", PayrollPeriod);
    end;

    local procedure CreateStaffListOrder(var StaffListOrderHeader: Record "Staff List Order Header"; LineType: Option; LineAction: Option; LineCode: Code[20])
    var
        StaffListOrderLine: Record "Staff List Order Line";
    begin
        StaffListOrderHeader.Init();
        StaffListOrderHeader.Validate("Document Date", WorkDate);
        StaffListOrderHeader.Validate("Posting Date", WorkDate);
        StaffListOrderHeader.Insert(true);
        with StaffListOrderLine do begin
            Init;
            Validate("Document No.", StaffListOrderHeader."No.");
            Validate(Type, LineType);
            Validate(Action, LineAction);
            Validate(Code, LineCode);
            Insert(true);
        end;
    end;

    local procedure PrepareTempStaffList(var TempStaffList: Record "Staff List" temporary; var StaffList: Record "Staff List"; var Position: Record Position): Code[10]
    var
        OrgUnit: Record "Organizational Unit";
    begin
        with Position do begin
            Get(CreatePosition(WorkDate, true));
            OrgUnit.Get(LibraryHRP.CreateOrgUnit("Starting Date", OrgUnit.Type::Unit));
            Validate("Org. Unit Code", OrgUnit.Code);
            Modify(true);
        end;
        LibraryHRP.ChangeOrgUnitStatus(OrgUnit.Code, OrgUnitStatus::Approved, true);

        StaffList.Create(TempStaffList, Position."Starting Date", Position."Starting Date");

        TempStaffList.SetRange("Org. Unit Code", OrgUnit.Code);
        TempStaffList.FindFirst;
        exit(OrgUnit.Code);
    end;

    local procedure UpdateHRSetupForStaffList(NewValue: Boolean) OldValue: Boolean
    var
        HRSetup: Record "Human Resources Setup";
    begin
        HRSetup.Get();
        OldValue := HRSetup."Use Staff List Change Orders";
        HRSetup.Validate("Use Staff List Change Orders", NewValue);
        HRSetup.Modify(true);
    end;

    local procedure GetNextHROrderNo(): Code[20]
    var
        HRSetup: Record "Human Resources Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        HRSetup.Get();
        HRSetup.TestField("HR Order Nos.");

        exit(NoSeriesMgt.GetNextNo(HRSetup."HR Order Nos.", Today, false));
    end;

    local procedure VerifyPostedStaffListOrder(DocumentNo: Code[20]; OrgUnitCode: Code[10])
    var
        PostedStaffListOrderHeader: Record "Posted Staff List Order Header";
        PostedStaffListOrderLine: Record "Posted Staff List Order Line";
    begin
        Assert.IsTrue(PostedStaffListOrderHeader.Get(DocumentNo),
          StrSubstNo(CannotBeEmptyErr, PostedStaffListOrderHeader.TableCaption));
        PostedStaffListOrderLine.SetRange("Document No.", DocumentNo);
        PostedStaffListOrderLine.FindFirst;
        Assert.AreEqual(OrgUnitCode, PostedStaffListOrderLine.Code,
          StrSubstNo(FieldValueErr, PostedStaffListOrderLine.FieldCaption(Code)));
    end;

    local procedure VerifyStaffArchive(DocumentNo: Code[20]; OrgUnitCode: Code[10]; JobTitleCode: Code[10])
    var
        StaffListArchive: Record "Staff List Archive";
        StaffListLineArchive: Record "Staff List Line Archive";
    begin
        StaffListArchive.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(StaffListArchive.IsEmpty, StrSubstNo(CannotBeEmptyErr, StaffListArchive.TableCaption));
        StaffListLineArchive.SetRange("Document No.", DocumentNo);
        StaffListLineArchive.FindFirst;
        Assert.AreEqual(
          OrgUnitCode, StaffListLineArchive."Org. Unit Code",
          StrSubstNo(FieldValueErr, StaffListLineArchive.FieldCaption("Org. Unit Code")));
        Assert.AreEqual(
          JobTitleCode, StaffListLineArchive."Job Title Code",
          StrSubstNo(FieldValueErr, StaffListLineArchive.FieldCaption("Job Title Code")));
    end;

    local procedure VerifyEmployeeAbsenceEntry(EmployeeNo: Code[20]; CalendarDays: Integer; EndingDate: Date)
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
    begin
        with EmployeeAbsenceEntry do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Calendar Days", CalendarDays);
            SetRange("End Date", EndingDate);
            Assert.IsFalse(IsEmpty, EmployeeAbsenceEntryErr);
        end;
    end;

    local procedure FindTimeActivityCode(): Code[10]
    var
        TimeActivity: Record "Time Activity";
    begin
        with TimeActivity do begin
            SetRange("Time Activity Type", "Time Activity Type"::Vacation);
            SetRange("Vacation Type", "Vacation Type"::Regular);
            FindFirst;
            exit(Code);
        end;
    end;

    local procedure FindTimeActivityFilter(StartDate: Date): Text[250]
    var
        HRSetup: Record "Human Resources Setup";
        TimeActivityFilter: Record "Time Activity Filter";
    begin
        HRSetup.Get();
        with TimeActivityFilter do begin
            Reset;
            SetRange(Code, HRSetup."Change Vacation Accr. Periodic");
            SetFilter("Starting Date", '..%1', StartDate);
            FindFirst;
            exit("Activity Code Filter");
        end;
    end;

    local procedure PayrollPeriodStartDate(): Date
    begin
        exit(
          DMY2Date(
            LibraryRandom.RandIntInRange(10, 20),
            1,
            Date2DMY(CalcDate('<+1Y>', WorkDate), 3)));
    end;

    local procedure CreatePayrollElement(): Code[20]
    var
        PayrollElement: Record "Payroll Element";
    begin
        with PayrollElement do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Calculate := true;
            Type := Type::Wage;
            "Element Group" := LibraryUtility.GenerateGUID;
            "Payroll Posting Group" := FindPayrollPostingGroup;
            Insert;
            exit(Code);
        end;
    end;

    local procedure CreateAbsenceHeader(var AbsenceHeader: Record "Absence Header"; Type: Option)
    begin
        with AbsenceHeader do begin
            Init;
            "Document Type" := Type;
            Validate("No.", LibraryUtility.GenerateGUID);
            Insert(true);
        end;
    end;

    local procedure CreateAbsenceLine(AbsenceHeaderType: Option; AbsenceHeaderNo: Code[20])
    var
        AbsenceLine: Record "Absence Line";
        RecRef: RecordRef;
    begin
        with AbsenceLine do begin
            Init;
            "Document Type" := AbsenceHeaderType;
            "Document No." := AbsenceHeaderNo;
            RecRef.GetTable(AbsenceLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Insert;
        end;
    end;

    local procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        GLSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 1 Code");
    end;

    local procedure FilterAbsenceLine(AbsenceHeaderType: Option; AbsenceHeaderNo: Code[20]; var AbsenceLine: Record "Absence Line")
    begin
        AbsenceLine.SetRange("Document Type", AbsenceHeaderType);
        AbsenceLine.SetRange("Document No.", AbsenceHeaderNo);
    end;

    local procedure CreateSimpleEmployeeJobEntry(EmployeeNo: Code[20]; StartingDate: Date): Integer
    var
        EmployeeJobEntry: Record "Employee Job Entry";
        RecRef: RecordRef;
    begin
        with EmployeeJobEntry do begin
            Init;
            RecRef.GetTable(EmployeeJobEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Employee No." := EmployeeNo;
            "Starting Date" := StartingDate;
            "Position Changed" := true;
            "Calendar Code" := LibraryHRP.GetDefaultCalendarCode;
            Insert;
            exit("Entry No.");
        end;
    end;

    local procedure CreateAbsenceHeaderWithLine(var AbsenceHeader: Record "Absence Header"; Type: Option)
    begin
        CreateAbsenceHeader(AbsenceHeader, Type);
        CreateAbsenceLine(AbsenceHeader."Document Type", AbsenceHeader."No.");
    end;

    local procedure CreatePayrollBaseAmount(ElementCode: Code[20]; var PayrollBaseAmount: Record "Payroll Base Amount")
    begin
        with PayrollBaseAmount do begin
            Init;
            "Element Code" := ElementCode;
            Code := LibraryUtility.GenerateGUID;
            Insert;
        end;
    end;

    local procedure CreatePayrollRangeHeader(ElementCode: Code[20])
    var
        PayrollRangeHeader: Record "Payroll Range Header";
    begin
        with PayrollRangeHeader do begin
            Init;
            "Element Code" := ElementCode;
            Code := LibraryUtility.GenerateGUID;
            Insert;
        end;
    end;

    local procedure CreatePayrollCalculation(ElementCode: Code[20])
    var
        PayrollCalculation: Record "Payroll Calculation";
    begin
        with PayrollCalculation do begin
            Init;
            Validate("Element Code", ElementCode);
            Insert;
        end;
    end;

    local procedure CheckPayrollElementTypeChange(var PayrollElement: Record "Payroll Element"; ElementType: Option; PostingType: Option; NormalSign: Option)
    begin
        with PayrollElement do begin
            Validate(Type, ElementType);
            Modify;
            Get(Code);
            Assert.AreEqual(
              PostingType, "Posting Type", StrSubstNo(FieldValueErr, "Posting Type"));
            Assert.AreEqual(
              NormalSign, "Normal Sign", StrSubstNo(FieldValueErr, "Normal Sign"));
        end;
    end;

    local procedure CreateLaborContract(): Code[20]
    var
        LaborContract: Record "Labor Contract";
    begin
        with LaborContract do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            exit("No.");
        end;
    end;

    local procedure CreateSimpleLaborContractLine(ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10]; var LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            Init;
            "Contract No." := ContractNo;
            "Operation Type" := OperationType;
            "Supplement No." := SupplementNo;
            Insert;
        end;
    end;

    local procedure CreateLaborContractTerms(ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10])
    var
        LaborContractTerms: Record "Labor Contract Terms";
    begin
        CreateSimpleContractTerms(
          LaborContractTerms, ContractNo, OperationType, SupplementNo, LaborContractTerms."Line Type"::"Payroll Element");
    end;

    local procedure CreateSalaryTerms(ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10])
    var
        LaborContractTerms: Record "Labor Contract Terms";
    begin
        CreateContractTerms(
          LaborContractTerms, ContractNo, OperationType, SupplementNo, LaborContractTerms."Line Type"::"Payroll Element");
    end;

    local procedure CreateVacationTerms(ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10])
    var
        LaborContractTerms: Record "Labor Contract Terms";
    begin
        CreateContractTerms(
          LaborContractTerms, ContractNo, OperationType, SupplementNo, LaborContractTerms."Line Type"::"Vacation Accrual");
    end;

    local procedure CreateSimpleContractTerms(var LaborContractTerms: Record "Labor Contract Terms"; ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10]; LineType: Option)
    begin
        with LaborContractTerms do begin
            Init;
            "Labor Contract No." := ContractNo;
            "Operation Type" := OperationType;
            "Supplement No." := SupplementNo;
            "Line Type" := LineType;
            "Element Code" := CreatePayrollElement;
            Insert;
        end;
    end;

    local procedure CreateContractTerms(var LaborContractTerms: Record "Labor Contract Terms"; ContractNo: Code[20]; OperationType: Option; SupplementNo: Code[10]; LineType: Option)
    begin
        CreateSimpleContractTerms(LaborContractTerms, ContractNo, OperationType, SupplementNo, LineType);
        with LaborContractTerms do begin
            Validate("Element Code");
            Validate("Starting Date", WorkDate);
            Validate(Quantity, LibraryRandom.RandDecInRange(1000, 10000, 2));
            Modify(true);
        end;
    end;

    local procedure FindPayrollPostingGroup(): Code[20]
    var
        PayrollPostingGroup: Record "Payroll Posting Group";
    begin
        PayrollPostingGroup.FindFirst;
        exit(PayrollPostingGroup.Code);
    end;

    local procedure CheckLaborContractLineValidateFieldValue(LaborContractLine: Record "Labor Contract Line"; OperationType: Option; FieldNoValue: Integer; FieldCaptionValue: Text)
    begin
        with LaborContractLine do begin
            "Operation Type" := OperationType;
            asserterror ValidateFieldValue(FieldNoValue);
            Assert.ExpectedError(
              StrSubstNo(
                FieldCannotBeChangedErr, FieldCaptionValue,
                FieldCaption("Operation Type"), "Operation Type"));
        end;
    end;

    local procedure VerifyEmployeeJobEntry(LaborContractLine: Record "Labor Contract Line")
    var
        EmployeeJobEntry: Record "Employee Job Entry";
    begin
        with EmployeeJobEntry do begin
            SetRange("Supplement No.", LaborContractLine."Supplement No.");
            FindFirst;
            Assert.AreEqual("Contract No.", LaborContractLine."Contract No.",
              StrSubstNo(FieldValueErr, "Contract No."));
            Assert.AreEqual("Person No.", LaborContractLine."Person No.",
              StrSubstNo(FieldValueErr, "Person No."));
            Assert.AreEqual("Position No.", LaborContractLine."Position No.",
              StrSubstNo(FieldValueErr, "Position No."));
            Assert.AreEqual("Starting Date", LaborContractLine."Starting Date",
              StrSubstNo(FieldValueErr, "Starting Date"));
            Assert.AreEqual("Ending Date", LaborContractLine."Ending Date",
              StrSubstNo(FieldValueErr, "Ending Date"));
            Assert.AreEqual("Insured Period Starting Date", LaborContractLine."Starting Date",
              StrSubstNo(FieldValueErr, "Insured Period Starting Date"));
            Assert.AreEqual("Insured Period Ending Date", LaborContractLine."Ending Date",
              StrSubstNo(FieldValueErr, "Insured Period Ending Date"));
        end;
    end;

    local procedure CreateLaborContractWithLine(var LaborContract: Record "Labor Contract"; OperationType: Option)
    var
        LaborContractLine: Record "Labor Contract Line";
    begin
        CreateSimpleLaborContractLine(
          CreateLaborContract, OperationType,
          LibraryUtility.GenerateGUID, LaborContractLine);
        UpdateLaborContractLine(LaborContractLine, WorkDate, CreatePerson);

        with LaborContract do begin
            Get(LaborContractLine."Contract No.");
            "Person No." := LaborContractLine."Person No.";
            "Starting Date" := WorkDate;
            "Insured Service" := true;
            "Employee No." := CreateEmployee("Person No.");
            Modify;
        end;
    end;

    local procedure CreateLaborContractLine(var LaborContractLine: Record "Labor Contract Line"; Type: Option; LaborContract: Record "Labor Contract"; StartDate: Date)
    begin
        CreateSimpleLaborContractLine(
          LaborContract."No.", Type,
          LibraryUtility.GenerateGUID, LaborContractLine);
        UpdateLaborContractLine(LaborContractLine, StartDate, LaborContract."Person No.");
    end;

    local procedure UpdateLaborContractLine(var LaborContractLine: Record "Labor Contract Line"; StartingDate: Date; PersonNo: Code[20])
    begin
        with LaborContractLine do begin
            "Starting Date" := StartingDate;
            "Order No." := LibraryUtility.GenerateGUID;
            "Order Date" := WorkDate;
            "Person No." := PersonNo;
            "Position No." := CreatePosition(WorkDate, false);
            "Position Rate" := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 2);
            Modify;
        end;
    end;

    local procedure SetLaborContractLineEndDate(var LaborContractLine: Record "Labor Contract Line"; EndDate: Date)
    begin
        LaborContractLine."Ending Date" := EndDate;
        LaborContractLine.Modify();
    end;

    local procedure CreateApproveEmployeeTransfer(var LaborContractLine: Record "Labor Contract Line"; var EmployeeNo: Code[20])
    var
        LaborContract: Record "Labor Contract";
        Employee: Record Employee;
        PayrollPeriod: Record "Payroll Period";
        Position: Record Position;
        TimesheetMgt: Codeunit "Timesheet Management RU";
        TransferStartDate: Date;
    begin
        CreateLaborContractWithLine(
          LaborContract, LaborContractLine."Operation Type"::Hire);
        CreateSimpleEmployeeJobEntry(LaborContract."Employee No.", WorkDate);
        Employee.Get(LaborContract."Employee No.");
        EmployeeNo := LaborContract."Employee No.";
        TransferStartDate := CalcDate('<CM+1D>', WorkDate);
        PayrollPeriod.Get(
          LibraryHRP.FindPayrollPeriodCodeByDate(TransferStartDate));
        TimesheetMgt.CreateTimesheet(Employee, PayrollPeriod);
        CreateLaborContractLine(
          LaborContractLine, LaborContractLine."Operation Type"::Transfer,
          LaborContract, TransferStartDate);
        Position.Get(LaborContractLine."Position No.");
        Position."Calendar Code" := LibraryHRP.GetOfficialCalendarCode;
        Position.Modify();

        LaborContractManagement.DoApprove(LaborContractLine);
    end;

    local procedure CreateApproveEmployeeCombination(var LaborContract: Record "Labor Contract"; var LaborContractLine: Record "Labor Contract Line")
    begin
        CreateLaborContractWithLine(
          LaborContract, LaborContractLine."Operation Type"::Hire);
        CreateLaborContractLine(
          LaborContractLine, LaborContractLine."Operation Type"::Combination,
          LaborContract, WorkDate);
        SetLaborContractLineEndDate(LaborContractLine, CalcDate('<+1Y>', WorkDate));
        LaborContractManagement.DoApprove(LaborContractLine);
    end;

    local procedure ApproveLaborContractLine(var LaborContractLine: Record "Labor Contract Line"; ContractNo: Code[10])
    begin
        with LaborContractLine do begin
            SetRange("Contract No.", ContractNo);
            FindFirst;
            Status := Status::Approved;
            Modify;
        end;
    end;

    local procedure VerifyPersonNameHistory(PersonNo: Code[20]; StartDate: Date; Names: array[3] of Text[30]; OrderNo: Code[20]; OrderDate: Date)
    var
        PersonNameHistory: Record "Person Name History";
    begin
        with PersonNameHistory do begin
            Get(PersonNo, StartDate);
            Assert.AreEqual(Names[1], "First Name", StrSubstNo(FieldValueErr, "First Name"));
            Assert.AreEqual(Names[2], "Middle Name", StrSubstNo(FieldValueErr, "Middle Name"));
            Assert.AreEqual(Names[3], "Last Name", StrSubstNo(FieldValueErr, "Last Name"));
            Assert.AreEqual(OrderNo, "Order No.", StrSubstNo(FieldValueErr, "Order No."));
            Assert.AreEqual(OrderDate, "Order Date", StrSubstNo(FieldValueErr, "Order Date"));
        end;
    end;

    local procedure VerifyPersonNames(PersonNo: Code[20]; Names: array[3] of Text[30])
    var
        Person: Record Person;
    begin
        with Person do begin
            Get(PersonNo);
            Assert.AreEqual(Names[1], "First Name", StrSubstNo(FieldValueErr, "First Name"));
            Assert.AreEqual(Names[2], "Middle Name", StrSubstNo(FieldValueErr, "Middle Name"));
            Assert.AreEqual(Names[3], "Last Name", StrSubstNo(FieldValueErr, "Last Name"));
        end;
    end;

    local procedure CreatePersonChangeName(var OldNames: array[3] of Text[30]; var NewNames: array[3] of Text[30]; var OrderNos: array[2] of Code[20]; var OrderDates: array[2] of Date; var PersonNo: Code[20])
    var
        Person: Record Person;
        LaborContractLine: Record "Labor Contract Line";
        LaborContract: Record "Labor Contract";
        ChangePersonName: Codeunit "Change Person Name";
        i: Integer;
    begin
        CreateLaborContractWithLine(
          LaborContract, LaborContractLine."Operation Type"::Hire);
        ApproveLaborContractLine(LaborContractLine, LaborContract."No.");
        PersonNo := LaborContractLine."Person No.";
        OrderNos[1] := LaborContractLine."Order No.";
        OrderDates[1] := LaborContractLine."Order Date";
        with Person do begin
            Get(LaborContract."Person No.");
            OldNames[1] := "First Name";
            OldNames[2] := "Middle Name";
            OldNames[3] := "Last Name";
            for i := 1 to 3 do
                NewNames[i] := LibraryUtility.GenerateGUID;
            OrderNos[2] := LibraryUtility.GenerateGUID;
            OrderDates[2] := CalcDate('<+1D>', WorkDate);
            ChangePersonName.ChangeName(
              "No.", NewNames[1], NewNames[2], NewNames[3],
              OrderNos[2], WorkDate, OrderDates[2], LibraryUtility.GenerateGUID);
        end;
    end;

    local procedure ValidatePayrollCalSetupPeriodNo(var PayrollCalendarSetup: Record "Payroll Calendar Setup"; PeriodType: Option; PeriodNo: Integer)
    begin
        with PayrollCalendarSetup do begin
            Init;
            Validate("Period Type", PeriodType);
            Validate("Period No.", PeriodNo);
            Insert;
        end;
    end;

    local procedure ValidatePayrollCalSetupDayNo(var PayrollCalendarSetup: Record "Payroll Calendar Setup"; PeriodType: Option; DayNo: Integer; PeriodNo: Integer; FillYear: Boolean)
    begin
        with PayrollCalendarSetup do begin
            Init;
            Validate("Period Type", PeriodType);
            "Period No." := PeriodNo;
            if FillYear then
                Validate(Year, Date2DMY(WorkDate, 3))
            else
                Validate(Year, 0);
            Validate("Day No.", DayNo);
            Insert;
        end;
    end;

    local procedure GetBaseSalaryFromPosition(EmployeeNo: Code[20]): Decimal
    var
        Position: Record Position;
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
    begin
        LaborContract.SetRange("Employee No.", EmployeeNo);
        LaborContract.FindFirst;
        LaborContractLine.SetRange("Contract No.", LaborContract."No.");
        LaborContractLine.FindLast;

        Position.Get(LaborContractLine."Position No.");
        exit(Position."Base Salary");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateSalaryIndexationDocsHandler(var CreateSalaryIndexationDocs: TestRequestPage "Create Salary Indexation Docs.")
    var
        DequeueVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        CreateSalaryIndexationDocs.Coefficient.SetValue(DequeueVar); // Coefficient
        LibraryVariableStorage.Dequeue(DequeueVar);
        CreateSalaryIndexationDocs.HROrderNo.SetValue(DequeueVar); // HR Order No.
        CreateSalaryIndexationDocs.HROrderDate.SetValue(WorkDate); // HR Order Date
        CreateSalaryIndexationDocs.StartingDate.SetValue(WorkDate); // Starting Date
        CreateSalaryIndexationDocs.OK.Invoke;
    end;
}

