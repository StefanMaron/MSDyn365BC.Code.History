codeunit 144200 "HRP General"
{
    // 
    //  Tests
    // 
    //   1. DeductionPosting : NC 51941, test for several deductions G/L posting
    //   2. DimensionFromEmplJnlLineToPayrollDocLine
    //   3. EmplLedgEntryDimOverwriteDefaultDim : NC 51709, employee has default dimension, this value should be overwritten by the employee ledger entries' dimensions
    //   4. PayrollElementDefDimOverwriteDefEmloyeeDim : NC 51709, employee has default dimension value 1; payroll element has default dimension value 2; payroll element's dimension has higher priority
    //   5. DimFundsPosting : Funds should be grouped by acurals dimension combinations
    //   6. LaborContractLineCancelHire : Test case checks that after Cancelation of Hire Line, Labor Contract and Labor Contract Line has Status = Open
    //   7. LaborContractLineCancelHirePayrollPosted : Test case checks that Hire Line cannot be cancelled if there are posted payroll documents
    //   8. LaborContractLineCancelDismissal : Test case checks that after Cancelation of Hire Line, Labor Contract and Labor Contract Line has Status = Open, Position Filled Rate = 1.00
    //   9. Verify that Insured Service period is correctly calculated if an Employee has a Transfer within a one year period.
    //  10. Verify that AE Calculation gives correct results for Vacation if income from previous employer exists.
    //  11. Verify that AE Calculation gives correct results in AE Periods for Vacation if income from childcare vacation exists.
    //  12. Verify that cancel dismissal restore End Date for employee accural entry
    // 
    //  ---------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                               TFS ID
    //  ---------------------------------------------------------------------------------------------------------
    //  VerifyInsuredServiceValuesWithTransfer                                                             74890
    //  VerifyAECalculationForVacationWithPrevIncome                                                       74887
    //  VerifyAEPeriodForVacationWithChildcareIncome                                                       74886
    //  EndDateAccuralEntryAfterCancelDismissal                                                            85656
    //  RemoveEmployeeAfterLaborContractCancellation                                                       94060
    //  EmployeeDismissalAfterTheEndOfSickLeave                                                            94066
    //  CreateContractTermsForTransferLaborContractLine                                                    94061
    //  SickLeavePostedBetweenPeriods                                                                      94062

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        EntryNotFoundErr: Label 'Could not find entry.';
        DocumentNotFoundErr: Label 'Could not find payroll document';
        DocumentLineNotFoundErr: Label 'Could not find payroll document line';
        IncorrectAmountErr: Label 'Incorrect G/L Entry Amount.';
        DimSetIDNotFoundErr: Label 'Dimension Set ID is not found.';
        WrongDimValueErr: Label 'Incorrect dimension''s value';
        Employee: Record Employee;
        LibraryERM: Codeunit "Library - ERM";
        LibraryHRP: Codeunit "Library - HRP";
        Translate: Codeunit "Translate Payroll";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        DimMgt: Codeunit DimensionManagement;
        Assert: Codeunit Assert;
        DimSetEntryAbsentErr: Label 'Couldnot find dimension set entry.';
        EmployeeNotRemovedErr: Label 'Employee was not removed.';
        WrongValueErr: Label 'Wrong value of %1';
        LaborContrTermsExistsErr: Label 'Labor contract terms exists.';
        BonusMonthlyAmtTxt: Label 'BONUS MONTHLY AMT', Locked = true;
        ExecActAmtTxt: Label 'EXEC ACT AMT', Locked = true;
        DeductMealsTxt: Label 'DEDUCT MEALS', Locked = true;
        DeductProp313Txt: Label 'DEDUCT PROPERTY 313';
        ExtraPayHoursTxt: Label 'EXTRAPAY HOURS';
        StartBalanceTxt: Label 'START BALANCE';
        SalaryHourTxt: Label 'SALARY HOUR';
        WrongLaborContractStatusErr: Label 'Wrong labor contract status';
        WrongLaborContractLineStatusErr: Label 'Wrong labor contract line status';
        WrongPositionNoErr: Label 'Wrong position number value';
        WrongEmploymentDateErr: Label 'Wrong Employment Date value';
        WrongEmplymtContractCodeErr: Label 'Wrong Emplymt. Contract Code value';
        PayrollStatusNotPostedErr: Label 'Payroll Status must not be Posted';
        WrongPositionFilledRateErr: Label 'Position Filled Rate is Empty after Dismissal cancellation';
        WrongServicePeriodErr: Label 'Wrong Service Period for %1.';
        YearTxt: Label 'Year';
        MonthTxt: Label 'Month';
        DayTxt: Label 'Day';
        AETotalEarningsWrongErr: Label 'Wrong Total Earnings in AE Entries.';
        AEPeriodAverageDaysWrongErr: Label 'Wrong Average Days in AE Period.';
        WrongEndDateErr: Label 'Wrong End Date.';

    [Test]
    [Scope('OnPrem')]
    procedure DeductionPosting()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        DeductionElementGLAccount: array[2] of Code[20];
        DeductionAmount: array[2] of Decimal;
    begin
        // case for NC 51941
        // test for several deductions G/L posting

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);

        Post2Deductions(EmployeeNo, PayrollPeriod, DeductionElementGLAccount, DeductionAmount);

        // EXERCISE - post payroll document
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);

        // VERIFY
        VerifyDeductionEntries(EmployeeNo, DeductionElementGLAccount, DeductionAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFromEmplJnlLineToPayrollDocLine()
    var
        DimensionValue: Record "Dimension Value";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);

        CreateAndPostEmplJnlLineWithNewDim(EmployeeNo, PayrollPeriod, PayrollPeriod."Starting Date", DimensionValue);

        // EXERCISE - calculate payroll document
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);
        // VERIFY
        VerifyDocumentLineDimensions(EmployeeNo, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmplLedgEntryDimOverwriteDefaultDim()
    var
        EmplJnlLine: Record "Employee Journal Line";
        DefaultDim: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // case for NC 51709 test 2
        // employee has default dimension
        // this value should be overwritten by the employee ledger entries' dimensions

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        CreateNewDimensionAndValue(DimensionValue);

        LibraryDimension.CreateDefaultDimension(DefaultDim, DATABASE::Employee, EmployeeNo,
          DimensionValue."Dimension Code", DimensionValue.Code);

        // create second dimension value
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
          LibraryRandom.RandInt(100), PayrollPeriod."Starting Date", false);
        AddDimensionToEmplJnlLine(EmplJnlLine, DimensionValue);
        PostEmplJnlLine(EmplJnlLine);

        // EXERCISE - calculate payroll document
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);

        // VERIFY
        VerifyDocumentLineDimensions(EmployeeNo, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollElementDefDimOverwriteDefEmloyeeDim()
    var
        EmplJnlLine: Record "Employee Journal Line";
        DefaultDim: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // case for NC 51709 test 3
        // employee has default dimension value 1
        // payroll element has default dimension value 2
        // payroll element's dimension has higher priority

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        CreateNewDimensionAndValue(DimensionValue);

        LibraryDimension.CreateDefaultDimension(DefaultDim, DATABASE::Employee, EmployeeNo,
          DimensionValue."Dimension Code", DimensionValue.Code);

        // create second dimension value
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        LibraryDimension.CreateDefaultDimension(DefaultDim, DATABASE::"Payroll Element", Translate.ElementCode(BonusMonthlyAmtTxt),
          DimensionValue."Dimension Code", DimensionValue.Code);

        // EXERCISE
        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
          LibraryRandom.RandInt(100), PayrollPeriod."Starting Date", false);

        // VERIFY
        VerifyDimensionSetID(EmplJnlLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimFundsPosting()
    var
        DimensionValue: Record "Dimension Value";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Funds should be grouped by acurals dimension combinations

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);

        CreateAndPostEmplJnlLineWithNewDim(EmployeeNo, PayrollPeriod, PayrollPeriod."Starting Date", DimensionValue);
        CreateAndPostEmplJnlLineWithNewDim(EmployeeNo, PayrollPeriod, PayrollPeriod."Starting Date", DimensionValue);

        // EXERCISE - post payroll document
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);

        // VERIFY - G/L entries for each fund should be grouped by dimension combinations
        VerifyFundEntries(EmployeeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineCancelHire()
    var
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Test case checks that after Cancelation of Hire Line, Labor Contract and Labor Contract Line has Status = Open

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Hire);

        // EXERCISE
        LibraryHRP.CancelLaborContractLine(LaborContractLine);

        // VERIFY
        VerifyEmployeeDataAfterCancelHire(LaborContractLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineCancelHirePayrollPosted()
    var
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Test case checks that Hire Line cannot be cancelled if there are posted payroll documents

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Hire);

        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);

        // EXERCISE
        asserterror LibraryHRP.CancelLaborContractLine(LaborContractLine);

        // VERIFY
        Assert.ExpectedError(PayrollStatusNotPostedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LaborContractLineCancelDismissal()
    var
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Test case checks that after Cancelation of Hire Line, Labor Contract and Labor Contract Line has Status = Open,
        // Position Filled Rate = 1.00

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);

        LibraryHRP.DismissEmployee(EmployeeNo, PayrollPeriod."Ending Date", LibraryHRP.FindGroundOfTerminationCode, true);
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Dismissal);
        // EXERCISE - cancel employee dismissal
        LibraryHRP.CancelLaborContractLine(LaborContractLine);

        // VERIFY
        VerifyEmployeeDataAfterCancelDismissal(LaborContractLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ViewOrganizationalStructure()
    var
        OrganizationStructure: TestPage "Organization Structure";
    begin
        // Test organization structure page and collapse/expand  actions
        OrganizationStructure.OpenView;
        OrganizationStructure."Expand All".Invoke;
        OrganizationStructure."Collapse All".Invoke;
        OrganizationStructure.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyInsuredServiceValuesWithTransfer()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        StartingDate: Date;
        EndingDate: Date;
        TransferDate: Date;
    begin
        // Verify that Insured Service period is correctly calculated if an Employee has a Transfer within a one year period.

        // SETUP
        InitInsuredServiceScenario(PayrollPeriod, EmployeeNo, StartingDate, EndingDate, 1);
        LibraryHRP.CreatePayrollPeriodsUntil(EndingDate);

        // EXERCISE - create transfer
        TransferDate :=
          CalcDate('<+' + Format(LibraryRandom.RandIntInRange(2, 9)) + 'D>', StartingDate);
        LibraryHRP.TransferEmployee(
          EmployeeNo, TransferDate,
          CreatePosition(TransferDate, LibraryRandom.RandDecInDecimalRange(100, 10000, 2), ''), true);

        // VERIFY
        VerifyTotalInsuredService(EmployeeNo, EndingDate, 1, 0, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAECalculationForVacationWithPrevIncome()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        StartingDate: Date;
        EndingDate: Date;
    begin
        // Verify that AE Calculation gives correct results for Vacation if income from previous employer exists.

        // SETUP
        InitInsuredServiceScenario(PayrollPeriod, EmployeeNo, StartingDate, EndingDate, 1);
        LibraryHRP.CreatePayrollPeriodsUntil(EndingDate);
        CreatePreviousIncome(EmployeeNo, StartingDate);

        // EXERCISE - create transfer
        CreatePostPayrollAndNext(PayrollPeriod, EmployeeNo);
        CreatePostPayrollAndNext(PayrollPeriod, EmployeeNo);

        LibraryHRP.CreateVacation(
          EmployeeNo, LibraryHRP.FindRegularVacationTimeActivityCode, PayrollPeriod."Starting Date",
          CalcDate('<+' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', PayrollPeriod."Starting Date"),
          PayrollPeriod."Ending Date");
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");

        // VERIFY
        VerifyAETotalEarnings(
          EmployeeNo, PayrollPeriod, LibraryHRP.FindRegularVacationTimeActivityCode,
          GetTotalBaseSalary(EmployeeNo, StartingDate, PayrollPeriod."Ending Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAEPeriodForVacationWithChildcareIncome()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        StartingDate: Date;
        EndingDate: Date;
    begin
        // Verify that AE Calculation gives correct results in AE Periods for Vacation if income from childcare vacation exists.

        // SETUP
        InitInsuredServiceScenario(PayrollPeriod, EmployeeNo, StartingDate, EndingDate, 2);
        LibraryHRP.CreatePayrollPeriodsUntil(EndingDate);
        CreateChildcareVacation(EmployeeNo, PayrollPeriod, StartingDate, CalcDate('<+CY+1M>', StartingDate));

        // EXERCISE - create transfer
        CreatePostPayrollAndNext(PayrollPeriod, EmployeeNo); // february -> march

        LibraryHRP.CreateVacation(
          EmployeeNo, LibraryHRP.FindRegularVacationTimeActivityCode, PayrollPeriod."Starting Date",
          CalcDate('<+' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', PayrollPeriod."Starting Date"),
          PayrollPeriod."Ending Date");
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");

        // VERIFY
        VerifyAEPeriods(
          EmployeeNo, PayrollPeriod, LibraryHRP.FindRegularVacationTimeActivityCode, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndDateAccuralEntryAfterCancelDismissal()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Verify End Date of Employee Accural Entry afte cancel dismissal

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        LibraryHRP.DismissEmployee(EmployeeNo, PayrollPeriod."Ending Date", LibraryHRP.FindGroundOfTerminationCode, true);

        // EXERCISE - cancel dismissal
        CancelDismissal(EmployeeNo);

        // VERIFY
        VerifyAccuralEntry(EmployeeNo, CalcDate('<+1Y-1D>', PayrollPeriod."Starting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollDocPropertyDeductCheck()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        DeductionAmount: array[1] of Decimal;
    begin
        // Check Payroll Document Line Amount for Property Deduction Element
        InitScenario(PayrollPeriod, EmployeeNo);
        PostDeduction(EmployeeNo, PayrollPeriod, DeductionAmount, DeductProp313Txt);

        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);

        VerifyPayrollDocLine(EmployeeNo, PayrollPeriod.Code, DeductProp313Txt, DeductionAmount[1], false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollDocCalcExtraPayHours()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        EmployeeNo: Code[20];
        PayrollCalcType: Code[20];
        DeductionAmount: array[1] of Decimal;
    begin
        // Check Payroll Document Line Amount for EXTRAPAY HOURS Payroll Element (2239 Function)
        InitScenario(PayrollPeriod, EmployeeNo);
        Employee.Get(EmployeeNo);

        // Include Payroll Element in Payroll Calc Group so it will be calculated in Payroll Doc
        PayrollCalcType := UpdatePayrollCalcGroup(Employee."Payroll Calc Group", ExtraPayHoursTxt);

        PostDeduction(EmployeeNo, PayrollPeriod, DeductionAmount, ExtraPayHoursTxt);
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);

        VerifyPayrollDocLine(EmployeeNo, PayrollPeriod.Code, ExtraPayHoursTxt, DeductionAmount[1], false);
        DeletePayrollCalcGroupLine(Employee."Payroll Calc Group", PayrollCalcType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollDocCalcExtraPayHoursNextPeriod()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        EmployeeNo: Code[20];
        PayrollCalcType: Code[20];
        DeductionAmount: array[1] of Decimal;
    begin
        // Check Payroll Document Line Amount for EXTRAPAY HOURS Payroll Element (2239 Function)
        // Posted between Payroll Periods
        InitScenario(PayrollPeriod, EmployeeNo);
        Employee.Get(EmployeeNo);

        // Include Payroll Element in Payroll Calc Group so it will be calculated in Payroll Doc
        PayrollCalcType := UpdatePayrollCalcGroup(Employee."Payroll Calc Group", ExtraPayHoursTxt);

        PostDeductionWithDates(
          EmployeeNo, PayrollPeriod, DeductionAmount, ExtraPayHoursTxt,
          PayrollPeriod."Starting Date", CalcDate('<+1M>', PayrollPeriod."Ending Date"));
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);

        PayrollPeriod.Next;
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);

        VerifyPayrollDocLine(EmployeeNo, PayrollPeriod.Code, ExtraPayHoursTxt, DeductionAmount[1], false);
        DeletePayrollCalcGroupLine(Employee."Payroll Calc Group", PayrollCalcType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollDocCalcStartBalance()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        EmployeeNo: Code[20];
        PayrollCalcType: Code[20];
        StartBalance: array[1] of Decimal;
    begin
        // Check Payroll Document Line Amount for START BALANCE Payroll Element
        InitScenario(PayrollPeriod, EmployeeNo);
        Employee.Get(EmployeeNo);

        // Include Payroll Element in Payroll Calc Group so it will be calculated in Payroll Doc
        PayrollCalcType := UpdatePayrollCalcGroup(Employee."Payroll Calc Group", StartBalanceTxt);

        StartBalance[1] := CreatePostGenJnlLine(
            Employee."Person No.", CalcDate('<-2D>', PayrollPeriod."Starting Date"));
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, false);

        VerifyPayrollDocLine(EmployeeNo, PayrollPeriod.Code, StartBalanceTxt, StartBalance[1], true);
        DeletePayrollCalcGroupLine(Employee."Payroll Calc Group", PayrollCalcType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollDocCalcSalaryHour()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        Position: Record Position;
        Person: Record Person;
        LaborContract: Record "Labor Contract";
        PayrollCalcType: Code[20];
        SalaryAmount: array[1] of Decimal;
    begin
        // Check Payroll Document Line Amount for SALARY HOUR Payroll Element
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        SalaryAmount[1] := LibraryRandom.RandInt(40000);
        Position.Get(CreatePosition(PayrollPeriod."Starting Date", SalaryAmount[1], SalaryHourTxt));

        LibraryHRP.CreatePerson(Person);
        LibraryHRP.CreateLaborContractHire(
          LaborContract, Person."No.", PayrollPeriod."Starting Date", Position."No.", false, false);

        Employee.Get(LaborContract."Employee No.");

        // Include Payroll Element in Payroll Calc Group so it will be calculated in Payroll Doc
        PayrollCalcType := UpdatePayrollCalcGroup(Employee."Payroll Calc Group", SalaryHourTxt);
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, Employee."No.", false);

        VerifyPayrollDocLine(Employee."No.", PayrollPeriod.Code, SalaryHourTxt, SalaryAmount[1], true);
        DeletePayrollCalcGroupLine(Employee."Payroll Calc Group", PayrollCalcType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveEmployeeAfterLaborContractCancellation()
    var
        Employee: Record Employee;
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
    begin
        // Check that employee can be removed after labor contract is canceled

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Hire);

        // EXERCISE
        LibraryHRP.CancelLaborContractLine(LaborContractLine);
        Employee.Get(EmployeeNo);
        Employee.Delete(true);

        // VERIFY
        Assert.IsFalse(Employee.Find, EmployeeNotRemovedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeDismissalAfterTheEndOfSickLeave()
    var
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        SickLeaveSetup: Record "Sick Leave Setup";
        AbsenceLine: Record "Absence Line";
        EmployeeNo: Code[20];
    begin
        // Check that sick leave setup works correctly if the employee has terminated the labor contract before
        // the end of sick leave

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        LibraryHRP.DismissEmployee(EmployeeNo, PayrollPeriod."Ending Date", LibraryHRP.FindGroundOfTerminationCode, true);
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Dismissal);

        // EXERCISE
        CreateAbsenceLineWithStartDate(
          AbsenceLine, EmployeeNo, CalcDate('<-1D>', LaborContractLine."Ending Date"));
        SickLeaveSetup.GetPaymentPercent(AbsenceLine);

        // VERIFY
        Assert.AreEqual(
          GetPmtPctFromSickLeaveSetup(EmployeeNo, AbsenceLine."Start Date"), AbsenceLine."Payment Percent",
          StrSubstNo(WrongValueErr, AbsenceLine.FieldCaption("Payment Percent")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContractTermsForTransferLaborContractLine()
    var
        PayrollPeriod: Record "Payroll Period";
        Position: Record Position;
        LaborContractTerms: Record "Labor Contract Terms";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";
        EmployeeNo: Code[20];
    begin
        // Check that labor contract terms is created for the labor contract line with type "Transfer"

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);
        Position.Get(CreatePosition(WorkDate, LibraryRandom.RandDecInDecimalRange(100, 10000, 2), ''));
        LibraryHRP.TransferEmployee(
          EmployeeNo, WorkDate,
          Position."No.", false);

        // EXERCISE
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Transfer);
        LaborContractMgt.CreateContractTerms(LaborContractLine, true);

        // VERIFY
        Assert.IsTrue(
          LaborContractTerms.Get(
            LaborContractLine."Contract No.", LaborContractLine."Operation Type",
            LaborContractLine."Supplement No.", LaborContractTerms."Line Type"::"Payroll Element",
            Position."Base Salary Element Code"),
          LaborContrTermsExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SickLeavePostedBetweenPeriods()
    var
        LaborContractLine: Record "Labor Contract Line";
        PayrollPeriod: Record "Payroll Period";
        TimeActivity: Record "Time Activity";
        AbsenceLine: Record "Absence Line";
        EmpLedgEntry: Record "Employee Ledger Entry";
        EmployeeNo: Code[20];
        RelativeNo: Code[20];
        FromDate: Date;
        ToDate: Date;
    begin
        // Check that sick leave lasting between periods is correctly posted

        // SETUP
        InitScenario(PayrollPeriod, EmployeeNo);

        // EXERCISE
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Hire);
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);
        GetNextPeriodDates(FromDate, ToDate, PayrollPeriod);
        RelativeNo :=
          CreateChildRelativePerson(EmployeeNo,
            CalcDate('<-' + Format(LibraryRandom.RandIntInRange(30, 50)) + 'Y>', WorkDate));
        LibraryHRP.CreateSickLeaveOrder(
          EmployeeNo, FromDate, FromDate, ToDate,
          LibraryHRP.FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Family Member Care"),
          RelativeNo, LibraryRandom.RandDec(50, 2),
          AbsenceLine."Treatment Type"::"In-Patient", true);

        // VERIFY
        EmpLedgEntry.SetCurrentKey("Employee No.", "Element Code", "Action Starting Date");
        EmpLedgEntry.SetRange("Employee No.", EmployeeNo);
        EmpLedgEntry.CalcSums("Payment Days");
        Assert.AreEqual(
          ToDate - FromDate + 1, EmpLedgEntry."Payment Days", StrSubstNo(WrongValueErr, EmpLedgEntry.FieldCaption("Payment Days")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalarySetupLinesReport()
    var
        HRSetup: Record "Human Resources Setup";
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        Employee: Record Employee;
        SuggestSalarySetupLines: Report "Suggest Salary Setup Lines";
        EmployeeNo: Code[20];
        ElementCode: Code[20];
        ElementType: Option Salary,Bonus,Deduction;
        AmountType: Option Amount,Percent,Quantity;
        SalaryAmount: Decimal;
    begin
        // Verify Suggest Salary Setup Lines Report
        InitScenario(PayrollPeriod, EmployeeNo);
        FindInitEmplJnlLine(EmplJnlLine);
        HRSetup.Get();
        SalaryAmount := LibraryRandom.RandDecInDecimalRange(10000, 30000, 2);
        ElementCode := HRSetup."Element Code Salary Amount";

        Commit();
        Employee.SetRange("No.", EmployeeNo);
        SuggestSalarySetupLines.SetTableView(Employee);
        SuggestSalarySetupLines.SetJnlLine(EmplJnlLine);
        SuggestSalarySetupLines.Initialize(
          ElementType::Salary, ElementCode, AmountType::Amount, SalaryAmount,
          PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
        SuggestSalarySetupLines.UseRequestPage(false);
        SuggestSalarySetupLines.Run;

        EmplJnlLine.FindFirst;
        Assert.AreEqual(EmployeeNo, EmplJnlLine."Employee No.",
          StrSubstNo(WrongValueErr, EmplJnlLine.FieldCaption("Employee No.")));
        Assert.AreEqual(ElementCode, EmplJnlLine."Element Code",
          StrSubstNo(WrongValueErr, EmplJnlLine.FieldCaption("Element Code")));
        Assert.AreEqual(SalaryAmount, EmplJnlLine.Amount,
          StrSubstNo(WrongValueErr, EmplJnlLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestIncomeTaxPaymentsReport()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        SuggestIncomeTaxPayments: Report "Suggest Income Tax Payments";
        EmployeeNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAmount: Decimal;
    begin
        // Verify Suggest Income Tax Payments Report created payment for Income Tax
        InitScenario(PayrollPeriod, EmployeeNo);
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);
        FindInitGenJnlLine(GenJnlLine);

        Commit();
        LibraryERM.FindBankAccount(BankAccount);
        Employee.SetRange("No.", EmployeeNo);
        SuggestIncomeTaxPayments.SetTableView(Employee);
        SuggestIncomeTaxPayments.SetParameters(
          GenJnlLine, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", PayrollPeriod."Ending Date",
          BankAccount."No.", false);
        SuggestIncomeTaxPayments.UseRequestPage(false);
        SuggestIncomeTaxPayments.Run;

        CalcPayrollTaxAmount(TaxAccountNo, TaxAmount, EmployeeNo);
        GenJnlLine.FindFirst;
        Assert.AreEqual(TaxAccountNo, GenJnlLine."Account No.",
          StrSubstNo(WrongValueErr, GenJnlLine.FieldCaption("Account No.")));
        Assert.AreEqual(TaxAmount, GenJnlLine.Amount,
          StrSubstNo(WrongValueErr, GenJnlLine.FieldCaption(Amount)));
    end;

    [Test]
    [HandlerFunctions('EmployeeJournalTestHandler')]
    [Scope('OnPrem')]
    procedure EmployeeJournalTestReport()
    var
        HRSetup: Record "Human Resources Setup";
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        EmployeeJournalTest: Report "Employee Journal - Test";
        EmployeeNo: Code[20];
        JnlAmount: Decimal;
    begin
        // Verify Employee Journal - Test Report
        InitScenario(PayrollPeriod, EmployeeNo);
        FindInitEmplJnlLine(EmplJnlLine);

        HRSetup.Get();
        JnlAmount := LibraryRandom.RandDecInDecimalRange(100, 1000, 2);
        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, HRSetup."Element Code Salary Amount",
          JnlAmount, PayrollPeriod."Starting Date", false);

        Commit();
        Clear(EmployeeJournalTest);
        EmployeeJournalTest.SetTableView(EmplJnlLine);
        EmployeeJournalTest.Run;

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Employee_Journal_Line__Employee_No__', EmployeeNo);
        LibraryReportDataset.AssertElementWithValueExists('Employee_Journal_Line_Amount', JnlAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccrualAbsenceEntryIsDeletedWhenCancelSickLeaveOrder()
    var
        PayrollPeriod: Record "Payroll Period";
        LaborContractLine: Record "Labor Contract Line";
        TimeActivity: Record "Time Activity";
        AbsenceLine: Record "Absence Line";
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        PostedAbsenceHeader: Record "Posted Absence Header";
        AbsenceOrderPost: Codeunit "Absence Order-Post";
        EmployeeNo: Code[20];
        RelativeNo: Code[20];
        DocumentNo: Code[20];
        InitialAccrualEntryNo: Integer;
        FromDate: Date;
        ToDate: Date;
    begin
        // [FEATURE] [Absense]
        // [SCENARIO 214349]
        InitScenario(PayrollPeriod, EmployeeNo);

        // [GIVEN] A new employee with approved labor contract
        FindLaborContractLine(EmployeeNo, LaborContractLine, LaborContractLine."Operation Type"::Hire);
        ReleaseTSCreatePostPayrollDoc(PayrollPeriod, EmployeeNo, true);
        GetNextPeriodDates(FromDate, ToDate, PayrollPeriod);

        // [GIVEN] There is one Employee Absence Entry and it has "Entry No." = "X", "Entry Type" = "Accrual"
        EmployeeAbsenceEntry.SetRange("Employee No.", EmployeeNo);
        Assert.RecordCount(EmployeeAbsenceEntry, 1);
        EmployeeAbsenceEntry.FindFirst;
        EmployeeAbsenceEntry.TestField("Entry Type", EmployeeAbsenceEntry."Entry Type"::Accrual);
        InitialAccrualEntryNo := EmployeeAbsenceEntry."Entry No.";

        // [GIVEN] Create post Sick Leave Order ("Child Care 3 years")
        RelativeNo :=
          CreateChildRelativePerson(EmployeeNo, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(30, 50)) + 'Y>', WorkDate));
        LibraryHRP.CreateSickLeaveOrder(
          EmployeeNo, FromDate, FromDate, ToDate,
          LibraryHRP.FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Child Care 3 years"),
          RelativeNo, LibraryRandom.RandDec(50, 2),
          AbsenceLine."Treatment Type"::"In-Patient", true);

        // [GIVEN] There are 2 new Employee Absence Entries: Accrual and Usage
        EmployeeAbsenceEntry.SetFilter("Entry No.", '>%1', InitialAccrualEntryNo);
        Assert.RecordCount(EmployeeAbsenceEntry, 2);
        EmployeeAbsenceEntry.SetRange("Entry Type", EmployeeAbsenceEntry."Entry Type"::Accrual);
        Assert.RecordCount(EmployeeAbsenceEntry, 1);

        // [WHEN] Cancel the posted sick leave order
        PostedAbsenceHeader.SetRange("Employee No.", EmployeeNo);
        PostedAbsenceHeader.FindFirst;
        AbsenceOrderPost.CancelOrder(PostedAbsenceHeader, DocumentNo);

        // [THEN] Two posted Employee Absence Entries are deleted and there is only one initial Accrual with "Entry No" = "X"
        EmployeeAbsenceEntry.SetRange("Entry No.");
        EmployeeAbsenceEntry.SetRange("Entry Type");
        Assert.RecordCount(EmployeeAbsenceEntry, 1);
        EmployeeAbsenceEntry.FindFirst;
        EmployeeAbsenceEntry.TestField("Entry No.", InitialAccrualEntryNo);
    end;

    local procedure InitScenario(var PayrollPeriod: Record "Payroll Period"; var EmployeeNo: Code[20])
    begin
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", LibraryRandom.RandIntInRange(30000, 50000));
    end;

    local procedure InitInsuredServiceScenario(var PayrollPeriod: Record "Payroll Period"; var EmployeeNo: Code[20]; var StartingDate: Date; var EndingDate: Date; Years: Integer)
    var
        Person: Record Person;
        LaborContract: Record "Labor Contract";
    begin
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        StartingDate :=
          CalcDate('<-CY+' + Format(LibraryRandom.RandIntInRange(15, 25)) + 'D>', PayrollPeriod."Starting Date");
        EndingDate := CalcDate('<+' + Format(Years) + 'Y>', StartingDate);
        InitCalendars(PayrollPeriod."Starting Date", CalcDate('<+' + Format(Years) + 'Y>', PayrollPeriod."Starting Date"));
        LibraryHRP.CreatePerson(Person);
        LibraryHRP.CreateLaborContractHire(
          LaborContract, Person."No.", StartingDate,
          CreatePosition(StartingDate, LibraryRandom.RandIntInRange(30000, 50000), ''),
          true, true);
        EmployeeNo := LaborContract."Employee No.";
    end;

    local procedure InitCalendars(FromDate: Date; ToDate: Date)
    begin
        InitCalendar(LibraryHRP.GetOfficialCalendarCode, FromDate, ToDate);
        InitCalendar(LibraryHRP.GetDefaultCalendarCode, FromDate, ToDate);
    end;

    local procedure InitCalendar(CalendarCode: Code[10]; FromDate: Date; ToDate: Date)
    var
        PayrollCalendarLine: Record "Payroll Calendar Line";
        CreateCalendarLine: Report "Create Calendar Line";
    begin
        ToDate := CalcDate('<CM>', ToDate);
        with PayrollCalendarLine do begin
            SetRange("Calendar Code", CalendarCode);
            SetRange(Date, FromDate, ToDate);
            FindLast;
        end;
        if FromDate <= PayrollCalendarLine.Date then
            FromDate := PayrollCalendarLine.Date + 1;
        if FromDate > ToDate then
            exit;

        CreateCalendarLine.SetCalendar(CalendarCode, FromDate, ToDate, false);
        CreateCalendarLine.UseRequestPage := false;
        CreateCalendarLine.Run;

        with PayrollCalendarLine do begin
            SetRange(Status, Status::Open);
            FindSet();
            repeat
                Release;
                Modify;
            until Next = 0;
        end;
    end;

    local procedure GetDimensionSetID(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with TempDimSetEntry do begin
            "Dimension Code" := DimensionValue."Dimension Code";
            "Dimension Value Code" := DimensionValue.Code;
            "Dimension Value ID" := DimensionValue."Dimension Value ID";
            Insert;
        end;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure AddDimensionToEmplJnlLine(var EmplJnlLine: Record "Employee Journal Line"; DimensionValue: Record "Dimension Value")
    var
        DimensionSetIDArr: array[10] of Integer;
    begin
        with EmplJnlLine do begin
            DimensionSetIDArr[1] := "Dimension Set ID";
            DimensionSetIDArr[2] := GetDimensionSetID(DimensionValue);
            "Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            Modify;
        end;
    end;

    local procedure VerifyDimensionSetID(DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        Assert.IsTrue(DimSetEntry.Get(DimSetID, DimensionValue."Dimension Code"), DimSetEntryAbsentErr);
        Assert.AreEqual(DimensionValue.Code, DimSetEntry."Dimension Value Code", WrongDimValueErr);
    end;

    local procedure CreateNewDimensionAndValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateAndPostEmplJnlLineWithNewDim(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; PostingDate: Date; var DimensionValue: Record "Dimension Value")
    var
        EmplJnlLine: Record "Employee Journal Line";
    begin
        CreateNewDimensionAndValue(DimensionValue);

        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
          LibraryRandom.RandInt(100), PostingDate, false);
        AddDimensionToEmplJnlLine(EmplJnlLine, DimensionValue);
        PostEmplJnlLine(EmplJnlLine);
    end;

    local procedure CreatePosition(PositionDate: Date; Salary: Decimal; BaseSalaryElementCode: Code[20]): Code[20]
    var
        Position: Record Position;
    begin
        with Position do begin
            FindFirst;
            LibraryHRP.CopyPosition(Position, PositionDate, "No.", Salary);
            if BaseSalaryElementCode <> '' then begin
                "Base Salary Element Code" := BaseSalaryElementCode;
                Modify;
            end;
            exit("No.");
        end;
    end;

    local procedure CreatePreviousIncome(EmployeeNo: Code[20]; BeforeDate: Date)
    var
        PersonIncomeFSI: Record "Person Income FSI";
        PayrollPeriod: Record "Payroll Period";
        CurrentDocDate: Date;
        NumberOfMonths: Integer;
        CompanyName: Code[10];
    begin
        CurrentDocDate := CalcDate('<-1D>', BeforeDate);
        NumberOfMonths := 12;
        Employee.Get(EmployeeNo);
        CompanyName := LibraryUtility.GenerateGUID;
        with PersonIncomeFSI do begin
            SetRange("Person No.", Employee."Person No.");
            repeat
                PayrollPeriod.SetRange("Ending Date", CalcDate('<+CM>', CurrentDocDate));
                PayrollPeriod.FindFirst;
                Validate("Person No.", Employee."Person No.");
                Validate("Period Code", PayrollPeriod.Code);
                Validate(Year, Date2DMY(CurrentDocDate, 3));
                Validate("Document No.", 'TEST_' + "Period Code");
                Validate("Document Date", CurrentDocDate);
                Validate("Company Name", CompanyName);
                Validate(Amount, LibraryRandom.RandDecInDecimalRange(10000, 50000, 2));
                Insert(true);
                NumberOfMonths -= 1;
                CurrentDocDate := CalcDate('<-CM-1D>', CurrentDocDate);
            until NumberOfMonths > 0;
        end;
    end;

    local procedure CreateChildcareVacation(EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period"; FromDate: Date; ToDate: Date)
    var
        TimeActivity: Record "Time Activity";
    begin
        PayrollPeriod.SetRange("Starting Date", CalcDate('<-CM>', FromDate));
        PayrollPeriod.FindFirst;
        with LibraryHRP do begin
            CreateSickLeaveOrder(
              EmployeeNo, FromDate, FromDate, ToDate,
              FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Child Care 1.5 years"),
              EmployeeNo, 40,
              0, true);
            repeat
                CreatePostPayrollAndNext(PayrollPeriod, EmployeeNo);
            until PayrollPeriod."Starting Date" >= ToDate;
        end;
    end;

    local procedure CreateChildRelativePerson(EmployeeNo: Code[20]; BirthDate: Date): Code[20]
    var
        Employee: Record Employee;
        Relative: Record Relative;
    begin
        Employee.Get(EmployeeNo);
        Relative.SetRange("Relative Type", Relative."Relative Type"::Child);
        Relative.FindFirst;
        exit(LibraryHRP.CreateRelativePerson(Employee."Person No.", Relative.Code, BirthDate, BirthDate));
    end;

    local procedure CreateAbsenceLineWithStartDate(var AbsenceLine: Record "Absence Line"; EmployeeNo: Code[20]; StartDate: Date)
    begin
        with AbsenceLine do begin
            Init;
            "Employee No." := EmployeeNo;
            "Start Date" := StartDate;
            Insert;
        end;
    end;

    local procedure FindNextPayrollPeriod(var PayrollPeriod: Record "Payroll Period")
    begin
        with PayrollPeriod do begin
            Reset;
            SetFilter("Starting Date", '>%1', "Starting Date");
            FindFirst;
        end;
    end;

    local procedure FindPayrollDocLine(var PayrollDocumentLine: Record "Payroll Document Line"; EmployeeNo: Code[20]; PayrollPeriodCode: Code[20]; ElementCode: Code[20])
    begin
        with PayrollDocumentLine do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PayrollPeriodCode);
            SetRange("Element Code", ElementCode);
            FindFirst;
        end;
    end;

    local procedure GetTotalBaseSalary(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        Position: Record Position;
    begin
        Employee.Get(EmployeeNo);
        Position.Get(Employee."Position No.");
        with PayrollLedgerEntry do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Posting Date", FromDate, ToDate);
            SetRange("Element Code", Position."Base Salary Element Code");
            CalcSums("Payroll Amount");
        end;
        exit(PayrollLedgerEntry."Payroll Amount");
    end;

    local procedure CreatePostPayrollAndNext(var PayrollPeriod: Record "Payroll Period"; EmployeeNo: Code[20])
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
        FindNextPayrollPeriod(PayrollPeriod);
    end;

    local procedure Post2Deductions(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; var AccountNo: array[2] of Code[20]; var Amount: array[2] of Decimal)
    var
        EmplJnlLine: Record "Employee Journal Line";
        ElementCode: array[2] of Code[20];
        i: Integer;
    begin
        ElementCode[1] := Translate.ElementCode(ExecActAmtTxt);
        ElementCode[2] := Translate.ElementCode(DeductMealsTxt);

        for i := 1 to ArrayLen(Amount) do begin
            Amount[i] := LibraryRandom.RandDecInDecimalRange(1000, 2000, 2);
            AccountNo[i] := FindPayrollElementAccount(ElementCode[i]);
            LibraryHRP.CreateEmplJnlLine(
              EmplJnlLine, PayrollPeriod, EmployeeNo, ElementCode[i], Amount[i], PayrollPeriod."Starting Date", true);
        end;
    end;

    local procedure CancelDismissal(EmployeeNo: Code[20])
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";
    begin
        LaborContract.SetRange("Employee No.", EmployeeNo);
        LaborContract.FindFirst;
        LaborContractLine.SetRange("Contract No.", LaborContract."No.");
        LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Dismissal);
        LaborContractLine.FindFirst;
        LaborContractMgt.UndoApproval(LaborContractLine);
    end;

    local procedure FindPayrollElementAccount(ElementCode: Code[20]): Code[20]
    var
        PayrollPostingGroup: Record "Payroll Posting Group";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        PayrollCalcTypeLine.SetRange("Element Code", ElementCode);
        PayrollCalcTypeLine.FindFirst;
        PayrollPostingGroup.Get(PayrollCalcTypeLine."Payroll Posting Group");
        exit(PayrollPostingGroup."Account No.");
    end;

    local procedure PostEmplJnlLine(var EmplJnlLine: Record "Employee Journal Line")
    var
        EmployeeJournalPostLine: Codeunit "Employee Journal - Post Line";
    begin
        EmployeeJournalPostLine.RunWithCheck(EmplJnlLine);
    end;

    local procedure GetPmtPctFromSickLeaveSetup(EmployeeNo: Code[20]; StartDate: Date): Decimal
    var
        SickLeaveSetup: Record "Sick Leave Setup";
        CalendarMgt: Codeunit "Payroll Calendar Management";
    begin
        Employee.Get(EmployeeNo);
        with SickLeaveSetup do begin
            SetRange(Type, Type::"Payment Percent");
            SetRange(Dismissed, true);
            SetFilter("Days after Dismissal", '%1..',
              CalendarMgt.GetPeriodInfo(
                Employee."Calendar Code", StartDate, Employee."Termination Date", 1));
            FindFirst;
            exit("Payment %");
        end;
    end;

    local procedure GetNextPeriodDates(var FromDate: Date; var ToDate: Date; PayrollPeriod: Record "Payroll Period")
    begin
        PayrollPeriod.Next;
        FromDate :=
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(3, 5)) + 'D>', PayrollPeriod."Ending Date");
        PayrollPeriod.Next;
        ToDate :=
          CalcDate('<+' + Format(LibraryRandom.RandIntInRange(3, 5)) + 'D>', PayrollPeriod."Starting Date");
    end;

    local procedure FindInitEmplJnlLine(var EmplJnlLine: Record "Employee Journal Line")
    var
        EmplJournalTemplate: Record "Employee Journal Template";
        EmplJournalBatch: Record "Employee Journal Batch";
    begin
        LibraryHRP.FindEmplJnlTemplate(EmplJournalTemplate);
        LibraryHRP.FindEmplJnlBatch(EmplJournalBatch, EmplJournalTemplate.Name);
        EmplJnlLine.SetRange("Journal Template Name", EmplJournalTemplate.Name);
        EmplJnlLine.SetRange("Journal Batch Name", EmplJournalBatch.Name);
        EmplJnlLine.DeleteAll();

        EmplJnlLine."Journal Template Name" := EmplJournalTemplate.Name;
        EmplJnlLine."Journal Batch Name" := EmplJournalBatch.Name;
    end;

    local procedure FindInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure VerifyDeductionEntries(EmployeeNo: Code[20]; DeductionElementGLAccount: array[2] of Code[20]; DeductionAmount: array[2] of Decimal)
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
        i: Integer;
    begin
        PostedPayrollDocument.SetRange("Employee No.", EmployeeNo);
        PostedPayrollDocument.FindLast;
        for i := 1 to ArrayLen(DeductionAmount) do
            FindAndVerifyDeductGLEntry(PostedPayrollDocument."No.", DeductionElementGLAccount[i], -DeductionAmount[i]);
    end;

    local procedure VerifyFundEntries(EmployeeNo: Code[20])
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
        FundPostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        PostedPayrollDocument.SetRange("Employee No.", EmployeeNo);
        PostedPayrollDocument.FindLast;
        with FundPostedPayrollDocumentLine do begin
            SetRange("Document No.", PostedPayrollDocument."No.");
            SetRange("Element Type", "Element Type"::Funds);
            SetFilter("Payroll Amount", '<>0');
            FindSet();
            repeat
                FindVerifyAccuralLines(PostedPayrollDocument."No.", FindFundVendorNo("Element Code"));
            until Next = 0;
        end;
    end;

    local procedure VerifyEmployeeDataAfterCancelHire(LaborContractLine: Record "Labor Contract Line")
    var
        LaborContract: Record "Labor Contract";
        Employee: Record Employee;
    begin
        LaborContract.Get(LaborContractLine."Contract No.");
        Assert.AreEqual(LaborContract.Status::Open, LaborContract.Status, WrongLaborContractStatusErr);
        Assert.AreEqual(LaborContractLine.Status::Open, LaborContractLine.Status, WrongLaborContractLineStatusErr);

        Employee.Get(LaborContract."Employee No.");
        Assert.AreEqual('', Employee."Position No.", WrongPositionNoErr);
        Assert.AreEqual(0D, Employee."Employment Date", WrongEmploymentDateErr);
        Assert.AreEqual('', Employee."Emplymt. Contract Code", WrongEmplymtContractCodeErr);
    end;

    local procedure VerifyEmployeeDataAfterCancelDismissal(LaborContractLine: Record "Labor Contract Line")
    var
        LaborContract: Record "Labor Contract";
        Employee: Record Employee;
        Position: Record Position;
    begin
        LaborContract.Get(LaborContractLine."Contract No.");
        Assert.AreEqual(LaborContract.Status::Approved, LaborContract.Status, WrongLaborContractStatusErr);
        Assert.AreEqual(LaborContractLine.Status::Open, LaborContractLine.Status, WrongLaborContractLineStatusErr);

        Employee.Get(LaborContract."Employee No.");
        Position.Get(Employee."Position No.");
        Position.CalcFields("Filled Rate");
        Assert.AreEqual(1, Position."Filled Rate", WrongPositionFilledRateErr);
    end;

    local procedure VerifyDocumentLineDimensions(EmployeeNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        PayrollDocument: Record "Payroll Document";
        PayrollDocumentLine: Record "Payroll Document Line";
    begin
        PayrollDocument.SetRange("Employee No.", EmployeeNo);
        Assert.IsTrue(PayrollDocument.FindFirst, DocumentNotFoundErr);

        PayrollDocumentLine.SetRange("Document No.", PayrollDocument."No.");
        PayrollDocumentLine.SetRange("Element Code", Translate.ElementCode(BonusMonthlyAmtTxt));
        Assert.IsTrue(PayrollDocumentLine.FindFirst, DocumentLineNotFoundErr);
        VerifyDimensionSetID(PayrollDocumentLine."Dimension Set ID", DimensionValue);
    end;

    local procedure VerifyTotalInsuredService(EmployeeNo: Code[20]; ToDate: Date; ExpectedYears: Integer; ExpectedMonths: Integer; ExpectedDays: Integer)
    var
        RecordOfServiceMgt: Codeunit "Record of Service Management";
        ServicePeriod: array[3] of Integer;
    begin
        Employee.Get(EmployeeNo);
        RecordOfServiceMgt.CalcEmplInsuredService(Employee, ToDate, ServicePeriod);
        Assert.AreEqual(ExpectedYears, ServicePeriod[3], StrSubstNo(WrongServicePeriodErr, YearTxt));
        Assert.AreEqual(ExpectedMonths, ServicePeriod[2], StrSubstNo(WrongServicePeriodErr, MonthTxt));
        Assert.AreEqual(ExpectedDays, ServicePeriod[1], StrSubstNo(WrongServicePeriodErr, DayTxt));
    end;

    local procedure VerifyAETotalEarnings(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; ExpectedTotalEarnings: Decimal)
    var
        PayrollDocumentLine: Record "Payroll Document Line";
        PayrollDocumentLineAE: Record "Payroll Document Line AE";
        TimeActivity: Record "Time Activity";
        TotalEarnings: Decimal;
    begin
        TimeActivity.Get(TimeActivityCode);
        FindPayrollDocLine(PayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        with PayrollDocumentLineAE do begin
            SetRange("Document No.", PayrollDocumentLine."Document No.");
            SetRange("Document Line No.", PayrollDocumentLine."Line No.");
            FindSet();
            repeat
                TotalEarnings += Amount;
            until Next = 0;
        end;
        Assert.AreEqual(ExpectedTotalEarnings, TotalEarnings, AETotalEarningsWrongErr);
    end;

    local procedure VerifyAEPeriods(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; ExpectedAverageDays: Decimal)
    var
        PayrollDocumentLine: Record "Payroll Document Line";
        PayrollPeriodAE: Record "Payroll Period AE";
        TimeActivity: Record "Time Activity";
    begin
        TimeActivity.Get(TimeActivityCode);
        FindPayrollDocLine(PayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        with PayrollPeriodAE do begin
            SetRange("Document No.", PayrollDocumentLine."Document No.");
            SetRange("Line No.", PayrollDocumentLine."Line No.");
            FindLast;
            Assert.AreEqual(ExpectedAverageDays, "Average Days", AEPeriodAverageDaysWrongErr);
        end;
    end;

    local procedure VerifyAccuralEntry(EmployeeNo: Code[20]; ExpectedEndingDate: Date)
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
    begin
        EmployeeAbsenceEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeAbsenceEntry.FindFirst;
        Assert.AreEqual(ExpectedEndingDate, EmployeeAbsenceEntry."End Date", WrongEndDateErr);
    end;

    local procedure FindVerifyAccuralLines(DocumentNo: Code[20]; SourceNo: Code[20])
    var
        AccuralPostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        FundPostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        with AccuralPostedPayrollDocumentLine do begin
            SetRange("Document No.", DocumentNo);
            SetFilter("Element Type", '%1|%2',
              FundPostedPayrollDocumentLine."Element Type"::Wage,
              FundPostedPayrollDocumentLine."Element Type"::Bonus);
            SetFilter("Payroll Amount", '<>0');
            FindSet();
            repeat
                FindAndVerifyFundGLEntry(DocumentNo, SourceNo, "Dimension Set ID");
            until Next = 0;
        end;
    end;

    local procedure FindAndVerifyDeductGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntry.FindFirst, EntryNotFoundErr);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, IncorrectAmountErr);
    end;

    local procedure FindAndVerifyFundGLEntry(DocumentNo: Code[20]; SourceNo: Code[20]; ExpectedDimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Source No.", SourceNo);
            SetRange("Dimension Set ID", ExpectedDimSetID);

            Assert.IsTrue(FindFirst, DimSetIDNotFoundErr);
        end;
    end;

    local procedure FindFundVendorNo(ElementCode: Code[20]): Code[20]
    var
        PayrollElement: Record "Payroll Element";
        PayrollPostingGroup: Record "Payroll Posting Group";
    begin
        PayrollElement.Get(ElementCode);
        PayrollPostingGroup.Get(PayrollElement."Payroll Posting Group");
        exit(PayrollPostingGroup."Fund Vendor No.");
    end;

    local procedure FindLaborContractLine(EmployeeNo: Code[20]; var LaborContractLine: Record "Labor Contract Line"; OperationType: Option)
    var
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);
        with LaborContractLine do begin
            SetRange("Contract No.", Employee."Contract No.");
            SetRange("Operation Type", OperationType);
            FindFirst;
        end;
    end;

    local procedure PostDeduction(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; var Amount: array[1] of Decimal; DeductElement: Text)
    begin
        PostDeductionWithDates(
          EmployeeNo, PayrollPeriod, Amount, DeductElement, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
    end;

    local procedure PostDeductionWithDates(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; var Amount: array[1] of Decimal; DeductElement: Text; StartDate: Date; EndDate: Date)
    var
        EmplJnlLine: Record "Employee Journal Line";
        ElementCode: Code[20];
    begin
        ElementCode := Translate.ElementCode(DeductElement);
        Amount[1] := LibraryRandom.RandDecInDecimalRange(1000, 2000, 2);

        LibraryHRP.CreateEmplJnlLineExtended(
          EmplJnlLine,
          PayrollPeriod."Starting Date",
          LibraryUtility.GenerateGUID,
          LibraryUtility.GenerateGUID,
          EmployeeNo,
          ElementCode,
          StartDate,
          EndDate,
          Amount[1],
          PayrollPeriod.Code,
          PayrollPeriod.Code,
          true);
    end;

    local procedure UpdatePayrollCalcGroup(PayrollCalcGroupCode: Code[10]; ElementCode: Text): Code[20]
    var
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
        PayrollCalcType: Record "Payroll Calc Type";
    begin
        with PayrollCalcGroupLine do begin
            Init;
            "Payroll Calc Group" := PayrollCalcGroupCode;
            Validate(
              "Payroll Calc Type",
              LibraryHRP.CreatePayrollCalcType(
                ElementCode, PayrollCalcType."Use in Calc"::Always, PayrollCalcType));
            Insert(true);
            exit("Payroll Calc Type");
        end;
    end;

    local procedure ReleaseTSCreatePostPayrollDoc(PayrollPeriod: Record "Payroll Period"; EmployeeNo: Code[20]; Post: Boolean)
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        if Post then
            LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
    end;

    local procedure CreatePostGenJnlLine(PersonNo: Code[20]; PostingDate: Date): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Person: Record Person;
    begin
        Person.Get(PersonNo);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              "Document Type"::Payment, "Account Type"::Vendor, Person."Vendor No.",
              LibraryRandom.RandDec(1000, 2));
            Validate("Posting Date", PostingDate);
            "External Document No." := LibraryUtility.GenerateGUID;
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
            Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(-GenJournalLine.Amount);
    end;

    local procedure VerifyPayrollDocLine(EmployeeNo: Code[20]; PayrollPeriodCode: Code[10]; PayrollElementCode: Code[20]; Amount: Decimal; CheckPayrollAmount: Boolean)
    var
        PayrollDocLine: Record "Payroll Document Line";
    begin
        FindPayrollDocLine(PayrollDocLine, EmployeeNo, PayrollPeriodCode, PayrollElementCode);
        if CheckPayrollAmount then
            Assert.AreEqual(Amount, PayrollDocLine."Payroll Amount", DocumentLineNotFoundErr)
        else
            Assert.AreEqual(Amount, PayrollDocLine.Amount, DocumentLineNotFoundErr);
    end;

    local procedure DeletePayrollCalcGroupLine(PayrollCalcGroup: Code[10]; PayrollCalcType: Code[20])
    var
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
    begin
        with PayrollCalcGroupLine do begin
            SetRange("Payroll Calc Group", PayrollCalcGroup);
            SetRange("Payroll Calc Type", PayrollCalcType);
            FindFirst;
            Delete;
        end;
    end;

    local procedure CalcPayrollTaxAmount(var TaxAccountNo: Code[20]; var TaxAmount: Decimal; EmployeeNo: Code[20])
    var
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollElement: Record "Payroll Element";
        PayrollPostingGroup: Record "Payroll Posting Group";
    begin
        FilterTaxPayrollDocLine(PostedPayrollDocLine, EmployeeNo);
        with PostedPayrollDocLine do begin
            CalcSums("Payroll Amount");
            FindFirst;
            PayrollElement.Get("Element Code");
            PayrollPostingGroup.Get(PayrollElement."Payroll Posting Group");
            TaxAccountNo := PayrollPostingGroup."Account No.";
            TaxAmount := -"Payroll Amount";
        end;
    end;

    local procedure FilterTaxPayrollDocLine(var PostedPayrollDocLine: Record "Posted Payroll Document Line"; EmployeeNo: Code[20])
    var
        PostedPayrollDoc: Record "Posted Payroll Document";
    begin
        PostedPayrollDoc.SetRange("Employee No.", EmployeeNo);
        PostedPayrollDoc.FindFirst;
        with PostedPayrollDocLine do begin
            SetRange("Document No.", PostedPayrollDoc."No.");
            SetRange("Element Type", "Element Type"::"Income Tax");
            SetRange("Posting Type", "Posting Type"::Charge, "Posting Type"::Liability);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeJournalTestHandler(var EmployeeJournalTest: TestRequestPage "Employee Journal - Test")
    begin
        EmployeeJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

