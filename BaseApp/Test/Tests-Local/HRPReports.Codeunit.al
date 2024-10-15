codeunit 144206 "HRP Reports"
{
    // // [FEATURE] [HRP] [Report]
    //  Tests
    // 
    //   1. EmployeePaysheetPostedDoc : Verify Employee Paysheet for Posted Payroll Document
    //   2. EmployeePaysheetPayrollDoc: Verify Employee Paysheet for Payroll Document
    //   3. Staff List T-3            : Verify staff list for whole organization

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryHRP: Codeunit "Library - HRP";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ExecActAmtTxt: Label 'EXEC ACT AMT', Locked = true;
        DeductMealsTxt: Label 'DEDUCT MEALS', Locked = true;
        TranslatePayroll: Codeunit "Translate Payroll";
        Assert: Codeunit Assert;
        DataSource: Option "Posted Entries","Payroll Documents";

    [Test]
    [Scope('OnPrem')]
    procedure EmployeePaysheetPostedDoc()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        PayAmount: Decimal;
        DeductionAmount: Decimal;
        IncomeTaxAmount: Decimal;
    begin
        // Create Employee, Post Payroll Document with Deductions, Verify Employee Paysheet
        Initialize;
        CreateEmployeePaysheet(PayrollPeriod, EmployeeNo, DataSource::"Posted Entries", PayAmount, DeductionAmount, IncomeTaxAmount);

        // Verify
        VerifyEmployeePaysheet(PayAmount, DeductionAmount, IncomeTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeePaysheetPayrollDoc()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        PayAmount: Decimal;
        DeductionAmount: Decimal;
        IncomeTaxAmount: Decimal;
    begin
        // Create Employee, Create Payroll Document with Deductions, Verify Employee Paysheet
        Initialize;
        CreateEmployeePaysheet(PayrollPeriod, EmployeeNo, DataSource::"Payroll Documents", PayAmount, DeductionAmount, IncomeTaxAmount);

        // Verify
        VerifyEmployeePaysheet(PayAmount, DeductionAmount, IncomeTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaysheetT51PostedDoc()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        PayAmount: Decimal;
        DeductionAmount: Decimal;
        IncomeTaxAmount: Decimal;
    begin
        // Create Employee, Post Payroll Document with Deductions, Verify Employee Paysheet
        Initialize;
        CreatePaysheetT51(PayrollPeriod, EmployeeNo, DataSource::"Posted Entries", PayAmount, DeductionAmount, IncomeTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaysheetT51PayrollDoc()
    var
        PayrollPeriod: Record "Payroll Period";
        EmployeeNo: Code[20];
        PayAmount: Decimal;
        DeductionAmount: Decimal;
        IncomeTaxAmount: Decimal;
    begin
        // Create Employee, Post Payroll Document with Deductions, Verify Employee Paysheet
        Initialize;
        CreatePaysheetT51(PayrollPeriod, EmployeeNo, DataSource::"Payroll Documents", PayAmount, DeductionAmount, IncomeTaxAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintStaffingListT3()
    var
        StaffList: Record "Staff List";
        TempStaffList: Record "Staff List" temporary;
        StaffListArchive: Record "Staff List Archive";
        StaffingListT3: Report "Staffing List T-3";
    begin
        // Verify export of Staffing List T-3 form to Excel for organization
        Initialize;

        StaffList.SetRange("Date Filter", 0D, WorkDate);
        StaffList.Create(TempStaffList, 0D, WorkDate);
        TempStaffList.SetRange("Date Filter", 0D, WorkDate);
        TempStaffList.CreateArchive(TempStaffList);
        StaffListArchive.FindLast;

        StaffingListT3.SetTestMode(true);
        StaffingListT3.SetTableView(StaffListArchive);
        StaffingListT3.UseRequestPage(false);
        StaffingListT3.Run;
        Clear(StaffingListT3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintTimesheetT13()
    var
        TimesheetT13: Report "Timesheet T-13";
    begin
        // Verify export of Staffing List T-3 form to Excel for organization
        Initialize;

        TimesheetT13.SetTestMode(true);
        TimesheetT13.UseRequestPage(false);
        TimesheetT13.Run;
        Clear(TimesheetT13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintAverageEmployeeCount()
    var
        AverageEmployeeCount: Report "Average Employee Count";
    begin
        // Verify export of Average Employee Count report to Excel
        Initialize;

        AverageEmployeeCount.SetTestMode(true);
        AverageEmployeeCount.UseRequestPage(false);
        AverageEmployeeCount.Run;
        Clear(AverageEmployeeCount);
    end;

    [Test]
    [HandlerFunctions('AverageHeadcountByEmployeeHandler')]
    [Scope('OnPrem')]
    procedure AverageHeadcountByEmployee()
    var
        AverageHeadcountByEmployees: Report "Average Headcount by Employees";
    begin
        // Verify print of Average Headcount Report by Employee
        Initialize;
        LibraryReportValidation.SetFileName('HCBYEMP');

        AverageHeadcountByEmployees.UseRequestPage(false);
        AverageHeadcountByEmployees.Run;
        Clear(AverageHeadcountByEmployees);
    end;

    [Test]
    [HandlerFunctions('AverageHeadcountByOrgUnitHandler')]
    [Scope('OnPrem')]
    procedure AverageHeadcountByOrgUnit()
    var
        AverageHeadcountByOrgUnit: Report "Average Headcount by Org. Unit";
    begin
        // [FEATURE] [Average Headcount by Org. Unit]
        // [SCENARIO 215212] RU HRP REP 17375 "Average Headcount by Org. Unit" base layout view
        Initialize;

        Clear(AverageHeadcountByOrgUnit);
        AverageHeadcountByOrgUnit.UseRequestPage(false);
        AverageHeadcountByOrgUnit.Run;

        LibraryReportValidation.VerifyCellValueByRef('V', 2, 1, 'Page');
        LibraryReportValidation.VerifyCellValueByRef('W', 2, 1, '1');
        LibraryReportValidation.VerifyCellValueByRef('C', 17, 1, 'Average employee headcount');
        Assert.ExpectedMessage('for first quarter', LibraryReportValidation.GetValueByRef('C', 18, 1));
        LibraryReportValidation.VerifyCellValueByRef('C', 33, 1, 'Engineer for labour organization and norming');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatDateForLocalReports()
    var
        LocalReportManagement: Codeunit "Local Report Management";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 214489] A function "Format Date" of "Local Report Management" codeunit returns the date in "dd.mm.yyyy" format

        Initialize;
        ExpectedDate := DMY2Date(20, 2, 2002);
        Assert.AreEqual('20.02.2002', LocalReportManagement.FormatDate(ExpectedDate), '');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);
    end;

    local procedure CreateEmployeePaysheet(var PayrollPeriod: Record "Payroll Period"; var EmployeeNo: Code[20]; DataSource: Option "Posted Entries","Payroll Documents"; var PayAmount: Decimal; var DeductedAmount: Decimal; var IncomeTaxAmount: Decimal)
    var
        DeductionElementGLAccount: array[2] of Code[20];
        DeductionAmount: array[2] of Decimal;
        i: Integer;
    begin
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo :=
          LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", LibraryRandom.RandIntInRange(30000, 50000));

        Post2Deductions(EmployeeNo, PayrollPeriod, DeductionElementGLAccount, DeductionAmount);

        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");

        if DataSource = DataSource::"Posted Entries" then begin
            LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
            EmployeePaysheetExcelExport(
              EmployeeNo, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", DataSource);
            IncomeTaxAmount := Abs(GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code, true));
            PayAmount := GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code, false);
        end else begin
            EmployeePaysheetExcelExport(
              EmployeeNo, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", DataSource);
            IncomeTaxAmount := Abs(GetPayrollDocAmount(EmployeeNo, PayrollPeriod.Code, true));
            PayAmount := GetPayrollDocAmount(EmployeeNo, PayrollPeriod.Code, false);
        end;

        for i := 1 to ArrayLen(DeductionAmount) do
            DeductedAmount += DeductionAmount[i];
    end;

    local procedure CreatePaysheetT51(var PayrollPeriod: Record "Payroll Period"; var EmployeeNo: Code[20]; DataSource: Option "Posted Entries","Payroll Documents"; var PayAmount: Decimal; var DeductedAmount: Decimal; var IncomeTaxAmount: Decimal)
    var
        DeductionElementGLAccount: array[2] of Code[20];
        DeductionAmount: array[2] of Decimal;
        i: Integer;
    begin
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        EmployeeNo :=
          LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", LibraryRandom.RandIntInRange(30000, 50000));

        Post2Deductions(EmployeeNo, PayrollPeriod, DeductionElementGLAccount, DeductionAmount);

        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");

        if DataSource = DataSource::"Posted Entries" then begin
            LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
            PaysheetT51ExcelExport(PayrollPeriod.Code, DataSource);
            IncomeTaxAmount := Abs(GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code, true));
            PayAmount := GetPostedPayrollDocPayrollAmount(EmployeeNo, PayrollPeriod.Code, false);
        end else begin
            PaysheetT51ExcelExport(PayrollPeriod.Code, DataSource);
            IncomeTaxAmount := Abs(GetPayrollDocAmount(EmployeeNo, PayrollPeriod.Code, true));
            PayAmount := GetPayrollDocAmount(EmployeeNo, PayrollPeriod.Code, false);
        end;

        for i := 1 to ArrayLen(DeductionAmount) do
            DeductedAmount += DeductionAmount[i];
    end;

    local procedure VerifyEmployeePaysheet(PayAmount: Decimal; DeductionAmount: Decimal; IncomeTaxAmount: Decimal)
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(11, 83, LocalReportMgt.FormatReportValue(PayAmount, 2));
        LibraryReportValidation.VerifyCellValue(10, 100, LocalReportMgt.FormatReportValue(DeductionAmount + IncomeTaxAmount, 2));
    end;

    local procedure Post2Deductions(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; var AccountNo: array[2] of Code[20]; var Amount: array[2] of Decimal)
    var
        EmplJnlLine: Record "Employee Journal Line";
        ElementCode: array[2] of Code[20];
        i: Integer;
    begin
        ElementCode[1] := TranslatePayroll.ElementCode(ExecActAmtTxt);
        ElementCode[2] := TranslatePayroll.ElementCode(DeductMealsTxt);

        for i := 1 to ArrayLen(Amount) do begin
            Amount[i] := LibraryRandom.RandDecInDecimalRange(1000, 2000, 2);
            AccountNo[i] := FindPayrollElementAccount(ElementCode[i]);
            LibraryHRP.CreateEmplJnlLine(
              EmplJnlLine, PayrollPeriod, EmployeeNo, ElementCode[i], Amount[i], PayrollPeriod."Starting Date", true);
        end;
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

    local procedure EmployeePaysheetExcelExport(EmployeeNo: Code[20]; StartingDate: Date; EndingDate: Date; DataSource: Option)
    var
        Employee: Record Employee;
        EmployeePaysheet: Report "Employee Paysheet";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(EmployeeNo);
        FileName := LibraryReportValidation.GetFileName;
        Employee.SetRange("No.", EmployeeNo);
        EmployeePaysheet.SetTableView(Employee);
        EmployeePaysheet.InitializeRequest(StartingDate, EndingDate, DataSource);
        EmployeePaysheet.SetFileNameSilent(FileName);
        EmployeePaysheet.UseRequestPage(false);
        EmployeePaysheet.Run;
        Clear(EmployeePaysheet);
    end;

    local procedure PaysheetT51ExcelExport(PeriodCode: Code[10]; DataSource: Option)
    var
        PaysheetT51: Report "Paysheet T-51";
    begin
        PaysheetT51.SetTestMode(true, PeriodCode, DataSource);
        PaysheetT51.UseRequestPage(false);
        PaysheetT51.Run;
        Clear(PaysheetT51);
    end;

    local procedure GetPostedPayrollDocPayrollAmount(EmployeeNo: Code[20]; PeriodCode: Code[10]; CalcIncomeTax: Boolean): Decimal
    var
        PostedPayrollDocument: Record "Posted Payroll Document";
    begin
        with PostedPayrollDocument do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PeriodCode);
            FindLast;
            if CalcIncomeTax then
                exit(CalcPostedPayrollDocAmount("No."));
            exit(CalcPayrollAmount)
        end;
    end;

    local procedure GetPayrollDocAmount(EmployeeNo: Code[20]; PeriodCode: Code[10]; CalcIncomeTax: Boolean): Decimal
    var
        PayrollDocument: Record "Payroll Document";
    begin
        with PayrollDocument do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PeriodCode);
            FindLast;
        end;
        exit(
          CalcPayrollDocAmount(PayrollDocument."No.", GetElementFilter(CalcIncomeTax)));
    end;

    local procedure CalcPostedPayrollDocAmount(DocumentNo: Code[20]): Decimal
    var
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
    begin
        with PostedPayrollDocLine do begin
            Reset;
            SetRange("Document No.", DocumentNo);
            SetRange("Element Type", "Element Type"::"Income Tax");
            SetRange(
              "Posting Type",
              "Posting Type"::Charge,
              "Posting Type"::Liability);
            CalcSums("Payroll Amount");
        end;
        exit(PostedPayrollDocLine."Payroll Amount");
    end;

    local procedure CalcPayrollDocAmount(DocumentNo: Code[20]; ElementType: Text): Decimal
    var
        PayrollDocLine: Record "Payroll Document Line";
    begin
        with PayrollDocLine do begin
            Reset;
            SetRange("Document No.", DocumentNo);
            SetFilter("Element Type", ElementType);
            SetRange(
              "Posting Type",
              "Posting Type"::Charge,
              "Posting Type"::Liability);
            CalcSums("Payroll Amount");
        end;
        exit(PayrollDocLine."Payroll Amount");
    end;

    local procedure GetElementFilter(CalcIncomeTax: Boolean): Text
    var
        PayrollDocLine: Record "Payroll Document Line";
    begin
        with PayrollDocLine do begin
            if CalcIncomeTax then
                exit(Format("Element Type"::"Income Tax"));
            exit(
              StrSubstNo(
                '%1|%2|%3|%4|%5',
                "Element Type"::Wage,
                "Element Type"::Bonus,
                "Element Type"::Deduction,
                "Element Type"::Other,
                "Element Type"::"Income Tax"));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure AverageHeadcountByEmployeeHandler(var AverageHeadcountByEmployees: Report "Average Headcount by Employees")
    begin
        AverageHeadcountByEmployees.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure AverageHeadcountByOrgUnitHandler(var AverageHeadcountByOrgUnit: Report "Average Headcount by Org. Unit")
    begin
        AverageHeadcountByOrgUnit.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;
}

