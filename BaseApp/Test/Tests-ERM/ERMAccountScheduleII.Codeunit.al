codeunit 134994 "ERM Account Schedule II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        AccScheduleExportErr: Label 'Account Schedule has not been exported.';
        CopySuccessMsg: Label 'The new account schedule has been created successfully.';
        DimensionValueErr: Label 'Dimension Value record does not exist.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        DimFilterErr: Label 'Wrong Dimension filter.';
        DimFilterStrTok: Label '%1 FILTER';
        DimFilterStringTok: Label 'Dimension 1 Filter: %1, Dimension 2 Filter: %2, Dimension 3 Filter: %3, Dimension 4 Filter: %4';
        CopySourceNameMissingErr: Label 'You must specify a valid name for the source account schedule to copy from.';
        MultipleSourcesErr: Label 'You can only copy one account schedule at a time.';
        SystemGeneratedAccSchedQst: Label 'This account schedule may be automatically updated by the system, so any changes you make may be lost. Do you want to make a copy?';
        TargetExistsErr: Label 'The new account schedule already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new account schedule.';
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryCashFlow: Codeunit "Library - Cash Flow";

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure AccountScheduleReport25MaxColumns()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        RowCount: Integer;
        MaxColumnCount: Integer;
    begin
        // Test Account Schedule Report with max number of columns.
        // It compares column layout setup and report result; use this test to verify setup changing.
        // 1.Setup: Create new Account Schedule with lines and Column Layout with max number of columns.
        Initialize;
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(100);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        MaxColumnCount := 5;
        CreateColumns(ColumnLayoutName, Format(LibraryRandom.RandDec(9999, 2), 12, 0), MaxColumnCount);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify that names of columns are the same as they are in the Column Layout set.
        LibraryReportDataset.LoadDataSetFile;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        ColumnLayout.FindSet;
        repeat
            LibraryReportDataset.AssertElementWithValueExists('Header', ColumnLayout."Column Header");
        until ColumnLayout.Next = 0;
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure AccountScheduleReport25WithoutColumns()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        RowCount: Integer;
    begin
        // Test Account Schedule Report with 0 columns.
        // This report could be saved.
        // 1.Setup: Create new Account Schedule with lines and Column Layout without any columns.
        Initialize;
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(100);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify that the report was saved successfully.
        LibraryReportDataset.LoadDataSetFile;
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst;
        LibraryReportDataset.AssertElementWithValueExists('AccScheduleName_Name', AccScheduleLine."Schedule Name");
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure AccountScheduleReport25VerifyHeader()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        RowCount: Integer;
        ColumnCount: Integer;
    begin
        // Test that report header is correct.
        // It searches settings of report header in the Excel document (Account Schedule Name and Column Layout Name).
        // 1.Setup: Create new Account Schedule with lines and Column Layout with columns.
        Initialize;
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(10);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        ColumnCount := LibraryRandom.RandInt(4);
        CreateColumns(ColumnLayoutName, Format(LibraryRandom.RandDec(9999, 2), 12, 0), ColumnCount);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify report header.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('AccScheduleName_Name', AccScheduleName.Name);
        LibraryReportDataset.AssertElementWithValueExists('ColumnLayoutName', ColumnLayoutName.Name);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleHandler,LookUpDimensionValueListHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportDimensionFilterFromGLSetup()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // Setup
        Initialize;
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(LibraryERM.GetGlobalDimensionCode(1));

        // 2.Exercise: Run the 25th Report.
        Commit();
        REPORT.Run(REPORT::"Account Schedule");
    end;

    [Test]
    [HandlerFunctions('AccountScheduleHandler,LookUpDimensionValueListHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportDimensionFilterFromAnalysisView()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AnalysisView: Record "Analysis View";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize;

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAnalysisView(AnalysisView);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        AnalysisView.Validate("Dimension 1 Code", Dimension.Code);
        AnalysisView.Modify(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView.Code);
        AccScheduleName.Modify(true);

        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(Dimension.Code);
        // 2.Exercise: Run the 25th Report.
        Commit();
        REPORT.Run(REPORT::"Account Schedule");
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportGrouping()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::Formula, ColumnLayoutName.Name);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::Formula, ColumnLayoutName.Name);

        // 2.Exercise: Run the 25th Report.
        Commit();
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // Verify
        LibraryReportDataset.LoadDataSetFile;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        if ColumnLayout.FindSet then
            repeat
                LibraryReportDataset.AssertElementWithValueExists('Header', ColumnLayout."Column Header");
            until ColumnLayout.Next = 0;
    end;

    [Test]
    [HandlerFunctions('RPHAccountScheduleVerifyData')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportVerifyRequestPage()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Verify request page has data after setfilter and open page
        Initialize;

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayoutName.Name);

        // Run the 25th Report
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // Verify is done in Request Page Handler RPHAccountScheduleVerifyData
        // check that request page has correct data
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleExportToExcel()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify account schedule export to Excel can fill Excel Buffer
        Initialize;
        AccScheduleName.SetFilter("Analysis View Name", '<>%1', '');
        AccScheduleName.SetFilter("Default Column Layout", '<>%1', '');
        if AccScheduleName.FindFirst then begin
            LibraryReportValidation.SetFileName(AccScheduleName.Name);

            // Export to Excel buffer
            AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
            AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY>', WorkDate), CalcDate('<CY>', WorkDate));
            // Verify
            RunExportAccSchedule(AccScheduleLine, AccScheduleName);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleIndentation()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountSchedule: TestPage "Account Schedule";
    begin
        // [SCENARIO] Account schedule lines can be indented (individually) to provide a nicer layout.
        Initialize;

        // [GIVEN] An account schedule with one line
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::"Posting Accounts", '');
        Assert.AreEqual(0, AccScheduleLine.Indentation, '');

        // [WHEN] User clicks Indent / Outdent,
        // [THEN] Indentation value on the line increases/decreases by 1 and cannot become negative
        AccountSchedule.OpenEdit;
        AccountSchedule.CurrentSchedName.SetValue(AccScheduleName.Name);
        AccountSchedule.First;

        AccountSchedule.Indent.Invoke;
        AccScheduleLine.Find;
        Assert.AreEqual(1, AccScheduleLine.Indentation, '');

        AccountSchedule.Outdent.Invoke;
        AccScheduleLine.Find;
        Assert.AreEqual(0, AccScheduleLine.Indentation, '');

        AccountSchedule.Outdent.Invoke;
        AccScheduleLine.Find;
        Assert.AreEqual(0, AccScheduleLine.Indentation, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleNoIndentationAnyValue()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(0, ColumnLayout."Show Indented Lines"::All, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleNoIndentationUnindentedOnly()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(0, ColumnLayout."Show Indented Lines"::"Non-Indented Only", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleNoIndentationIndentedOnly()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(0, ColumnLayout."Show Indented Lines"::"Indented Only", true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleIndentationAnyValue()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(1, ColumnLayout."Show Indented Lines"::All, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleIndentationUnindentedOnly()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(1, ColumnLayout."Show Indented Lines"::"Non-Indented Only", true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleIndentationIndentedOnly()
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        VerifyAccSchedColumnIndentationCalc(1, ColumnLayout."Show Indented Lines"::"Indented Only", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineOptionShowYes()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Code[10];
        ColumnLayoutName: Code[10];
        LineDescription: array[4] of Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382369] Report 25 "Account Schedule" prints all lines when line option "Show" = "Yes"
        Initialize;

        // [GIVEN] G/L Account "GLNull" with zero Net Change value
        // [GIVEN] G/L Account "GLPos" with positive NetChange value
        // [GIVEN] G/L Account "GLNeg" with negative NetChange value
        // [GIVEN] Account schedule with four lines:
        // [GIVEN] Line1: "Description" = "1", "Totaling Type" = "Total Accounts", "Totaling" = "", "Show" = "Yes",
        // [GIVEN] Line2: "Description" = "2", "Totaling Type" = "Total Accounts", "Totaling" = "GLNull", "Show" = "Yes"
        // [GIVEN] Line3: "Description" = "3", "Totaling Type" = "Total Accounts", "Totaling" = "GLPos", "Show" = "Yes"
        // [GIVEN] Line4: "Description" = "4", "Totaling Type" = "Total Accounts", "Totaling" = "GLNeg", "Show" = "Yes"
        // [GIVEN] Column layout with one line with "Column Type" = "Net Change"
        CreateAccScheduleWithFourLines(AccScheduleName, ColumnLayoutName, LineDescription, AccScheduleLine.Show::Yes);

        // [WHEN] Print Account Schedule (Report 25)
        RunAccountScheduleReportSaveAsExcel(AccScheduleName, ColumnLayoutName);

        // [THEN] There are four lines (all) have been printed
        LibraryReportValidation.VerifyCellValue(20, 1, LineDescription[1]);
        LibraryReportValidation.VerifyCellValue(22, 1, LineDescription[2]);
        LibraryReportValidation.VerifyCellValue(24, 1, LineDescription[3]);
        LibraryReportValidation.VerifyCellValue(26, 1, LineDescription[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineOptionShowNo()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Code[10];
        ColumnLayoutName: Code[10];
        LineDescription: array[4] of Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382369] Report 25 "Account Schedule" doesn't print lines when line option "Show" = "No"
        Initialize;

        // [GIVEN] G/L Account "GLNull" with zero Net Change value
        // [GIVEN] G/L Account "GLPos" with positive NetChange value
        // [GIVEN] G/L Account "GLNeg" with negative NetChange value
        // [GIVEN] Account schedule with four lines:
        // [GIVEN] Line1: "Description" = "1", "Totaling Type" = "Total Accounts", "Totaling" = "", "Show" = "No",
        // [GIVEN] Line2: "Description" = "2", "Totaling Type" = "Total Accounts", "Totaling" = "GLNull", "Show" = "No"
        // [GIVEN] Line3: "Description" = "3", "Totaling Type" = "Total Accounts", "Totaling" = "GLPos", "Show" = "No"
        // [GIVEN] Line4: "Description" = "4", "Totaling Type" = "Total Accounts", "Totaling" = "GLNeg", "Show" = "No"
        // [GIVEN] Column layout with one line with "Column Type" = "Net Change"
        CreateAccScheduleWithFourLines(AccScheduleName, ColumnLayoutName, LineDescription, AccScheduleLine.Show::No);

        // [WHEN] Print Account Schedule (Report 25)
        RunAccountScheduleReportSaveAsExcel(AccScheduleName, ColumnLayoutName);

        // [THEN] There are no lines have been printed
        LibraryReportValidation.VerifyEmptyCellByRef('A', 20, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 22, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 24, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 26, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineOptionShowIfAnyColumnNotZero()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Code[10];
        ColumnLayoutName: Code[10];
        LineDescription: array[4] of Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382369] Report 25 "Account Schedule" prints only lines with non-zero amount when line option "Show" = "If Any Column Not Zero"
        Initialize;

        // [GIVEN] G/L Account "GLNull" with zero Net Change value
        // [GIVEN] G/L Account "GLPos" with positive NetChange value
        // [GIVEN] G/L Account "GLNeg" with negative NetChange value
        // [GIVEN] Account schedule with four lines:
        // [GIVEN] Line1: "Description" = "1", "Totaling Type" = "Total Accounts", "Totaling" = "", "Show" = "If Any Column Not Zero",
        // [GIVEN] Line2: "Description" = "2", "Totaling Type" = "Total Accounts", "Totaling" = "GLNull", "Show" = "If Any Column Not Zero"
        // [GIVEN] Line3: "Description" = "3", "Totaling Type" = "Total Accounts", "Totaling" = "GLPos", "Show" = "If Any Column Not Zero"
        // [GIVEN] Line4: "Description" = "4", "Totaling Type" = "Total Accounts", "Totaling" = "GLNeg", "Show" = "If Any Column Not Zero"
        // [GIVEN] Column layout with one line with "Column Type" = "Net Change"
        CreateAccScheduleWithFourLines(AccScheduleName, ColumnLayoutName, LineDescription, AccScheduleLine.Show::"If Any Column Not Zero");

        // [WHEN] Print Account Schedule (Report 25)
        RunAccountScheduleReportSaveAsExcel(AccScheduleName, ColumnLayoutName);

        // [THEN] There are only two lines (3rd, 4th) have been printed
        LibraryReportValidation.VerifyCellValue(20, 1, LineDescription[3]);
        LibraryReportValidation.VerifyCellValue(22, 1, LineDescription[4]);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 24, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 26, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineOptionShowWhenNegativeBalance()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Code[10];
        ColumnLayoutName: Code[10];
        LineDescription: array[4] of Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382369] Report 25 "Account Schedule" prints only lines with negative amount when line option "Show" = "When Negative Balance"
        Initialize;

        // [GIVEN] G/L Account "GLNull" with zero Net Change value
        // [GIVEN] G/L Account "GLPos" with positive NetChange value
        // [GIVEN] G/L Account "GLNeg" with negative NetChange value
        // [GIVEN] Account schedule with four lines:
        // [GIVEN] Line1: "Description" = "1", "Totaling Type" = "Total Accounts", "Totaling" = "", "Show" = "When Negative Balance",
        // [GIVEN] Line2: "Description" = "2", "Totaling Type" = "Total Accounts", "Totaling" = "GLNull", "Show" = "When Negative Balance"
        // [GIVEN] Line3: "Description" = "3", "Totaling Type" = "Total Accounts", "Totaling" = "GLPos", "Show" = "When Negative Balance"
        // [GIVEN] Line4: "Description" = "4", "Totaling Type" = "Total Accounts", "Totaling" = "GLNeg", "Show" = "When Negative Balance"
        // [GIVEN] Column layout with one line with "Column Type" = "Net Change"
        CreateAccScheduleWithFourLines(AccScheduleName, ColumnLayoutName, LineDescription, AccScheduleLine.Show::"When Negative Balance");

        // [WHEN] Print Account Schedule (Report 25)
        RunAccountScheduleReportSaveAsExcel(AccScheduleName, ColumnLayoutName);

        // [THEN] There is only one line (4th) has been printed
        LibraryReportValidation.VerifyCellValue(20, 1, LineDescription[4]);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 22, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 24, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 26, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineOptionShowWhenPositiveBalance()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Code[10];
        ColumnLayoutName: Code[10];
        LineDescription: array[4] of Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382369] Report 25 "Account Schedule" prints only lines with positive amount when line option "Show" = "When Positive Balance"
        Initialize;

        // [GIVEN] G/L Account "GLNull" with zero Net Change value
        // [GIVEN] G/L Account "GLPos" with positive NetChange value
        // [GIVEN] G/L Account "GLNeg" with negative NetChange value
        // [GIVEN] Account schedule with four lines:
        // [GIVEN] Line1: "Description" = "1", "Totaling Type" = "Total Accounts", "Totaling" = "", "Show" = "When Positive Balance",
        // [GIVEN] Line2: "Description" = "2", "Totaling Type" = "Total Accounts", "Totaling" = "GLNull", "Show" = "When Positive Balance"
        // [GIVEN] Line3: "Description" = "3", "Totaling Type" = "Total Accounts", "Totaling" = "GLPos", "Show" = "When Positive Balance"
        // [GIVEN] Line4: "Description" = "4", "Totaling Type" = "Total Accounts", "Totaling" = "GLNeg", "Show" = "When Positive Balance"
        // [GIVEN] Column layout with one line with "Column Type" = "Net Change"
        CreateAccScheduleWithFourLines(AccScheduleName, ColumnLayoutName, LineDescription, AccScheduleLine.Show::"When Positive Balance");

        // [WHEN] Print Account Schedule (Report 25)
        RunAccountScheduleReportSaveAsExcel(AccScheduleName, ColumnLayoutName);

        // [THEN] There is only one line (3rd) has been printed
        LibraryReportValidation.VerifyCellValue(20, 1, LineDescription[3]);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 22, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 24, 1);
        LibraryReportValidation.VerifyEmptyCellByRef('A', 26, 1);
    end;

    local procedure VerifyAccSchedColumnIndentationCalc(Indentation: Integer; ShowIndentation: Option; ExpectZero: Boolean)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        Result: Decimal;
        ExpectedResult: Decimal;
    begin
        Initialize;
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::"Posting Accounts", '');
        ExpectedResult := 1000;
        AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::Formula;
        AccScheduleLine.SetRange("Date Filter", WorkDate);
        AccScheduleLine.Totaling := Format(ExpectedResult);
        AccScheduleLine.Indentation := Indentation;
        AccScheduleLine.Modify();
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout."Show Indented Lines" := ShowIndentation;
        ColumnLayout.Modify();
        Result := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);
        if ExpectZero then
            ExpectedResult := 0;
        Assert.AreEqual(ExpectedResult, Result, '')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportAccScheduleToExcelWithDimFilter()
    var
        DimensionValue: array[4] of Record "Dimension Value";
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 208312] Account Schedule must be exported to excel values with filters of dimensions
        Initialize;

        // [GIVEN] 4 Dimensions with Dimension Values:
        // [GIVEN] First - "DIM1" with "DIMVALUE1"
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);

        // [GIVEN] First - "DIM2" with "DIMVALUE2"
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);

        // [GIVEN] First - "DIM3" with "DIMVALUE3"
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);

        // [GIVEN] First - "DIM4" with "DIMVALUE4"
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);

        // [GIVEN] Account Schedule with Analysis View with dimensions: "DIM1", "DIM2", "DIM3" and "DIM4"
        CreateAccScheduleNameWithViewAndDimensions(AccScheduleName, DimensionValue);
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel)
        RunExportAccScheduleToExcel(AccScheduleName, DimensionValue);

        // [THEN] Excel file contains values of dimensions filters
        VerifyDimensionsAndValueInExcel(DimensionValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportAccScheduleToExcelWithAnalysisViewWithoutDim()
    var
        DimensionValue: array[4] of Record "Dimension Value";
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 208852] Account Schedule must be exported to excel if Dimensions of Analysis View are not specified and Dimensions filtes are blank
        Initialize;

        // [GIVEN] Account Schedule with Analysis View without dimensions
        CreateAccScheduleNameWithViewAndDimensions(AccScheduleName, DimensionValue);
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel)
        RunExportAccScheduleToExcel(AccScheduleName, DimensionValue);

        // [THEN] Excel file exported
        Assert.IsTrue(FILE.Exists(LibraryReportValidation.GetFileName), AccScheduleExportErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportAccScheduleToExcelWithDimFilterWithoutAnalysisView()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        DimFilterValue: array[4] of Code[20];
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 211157] Account Schedule must be exported to excel values with filters of dimensions if "Analisys View Name" is blank
        Initialize;

        // [GIVEN] Account Schedule with "Analysis View Name" = ''
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName."Analysis View Name" := '';
        AccScheduleName.Modify();

        // [GIVEN] 4 Dimensions Code with Dimensions Value
        DimFilterValue[1] := LibraryUtility.GenerateGUID;
        DimFilterValue[2] := LibraryUtility.GenerateGUID;
        DimFilterValue[3] := LibraryUtility.GenerateGUID;
        DimFilterValue[4] := LibraryUtility.GenerateGUID;
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel) with Dimensions Filter
        RunExportAccScheduleWithDimFilter(AccScheduleName, DimFilterValue);

        // [THEN] Excel file contans values of dimensions filter
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(13, 1,
          StrSubstNo(DimFilterStringTok, DimFilterValue[1], DimFilterValue[2], DimFilterValue[3], DimFilterValue[4]));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportAccScheduleToExcelWithoutAnalysisViewWithoutGlobalDimensions()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        DimensionValue: array[4] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 217970] Account Schedule must be exported to excel values without filters of dimensions if "Analisys View Name" is blank and Global Dimensions are blank
        Initialize;

        // [GIVEN] Global Dimensions 1 and 2 are blank
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", '');
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", '');
        GeneralLedgerSetup.Modify();

        // [GIVEN] Account Schedule with "Analysis View Name" = ''
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName."Analysis View Name" := '';
        AccScheduleName.Modify();
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel)
        RunExportAccScheduleToExcel(AccScheduleName, DimensionValue);

        // [THEN] Excel file exported without error
        Assert.IsTrue(FILE.Exists(LibraryReportValidation.GetFileName), AccScheduleExportErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportAccScheduleToExcelWithAdditionalFilters()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AnalysisView: Record "Analysis View";
        AccScheduleLine: Record "Acc. Schedule Line";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 311088] Account Schedule must be exported to excel values with addtional filters
        Initialize;

        // [GIVEN] Cost Center "Center"
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        // [GIVEN] Cost Object "Object"
        LibraryCostAccounting.CreateCostObject(CostObject);
        // [GIVEN] Cashflow Forecast "CashFlow"
        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);

        // [GIVEN] Account Schedule Line has filters for "Center", "Object" and "CashFlow"
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAnalysisView(AnalysisView);
        AccScheduleName.Validate("Analysis View Name", AnalysisView.Code);
        AccScheduleName.Modify(true);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.SetFilter("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.SetFilter("Cost Center Filter", CostCenter.Code);
        AccScheduleLine.SetFilter("Cost Object Filter", CostObject.Code);
        AccScheduleLine.SetFilter("Cash Flow Forecast Filter", CashFlowForecast."No.");

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel)
        LibraryReportValidation.SetFileName(AccScheduleName.Name);
        RunExportAccSchedule(AccScheduleLine, AccScheduleName);

        // [THEN] Excel file contains filers for "Center", "Object" and "CashFlow"
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(2, 1, AccScheduleLine.FieldCaption("Cost Center Filter"));
        LibraryReportValidation.VerifyCellValue(2, 2, CostCenter.Code);
        LibraryReportValidation.VerifyCellValue(3, 1, AccScheduleLine.FieldCaption("Cost Object Filter"));
        LibraryReportValidation.VerifyCellValue(3, 2, CostObject.Code);
        LibraryReportValidation.VerifyCellValue(4, 1, AccScheduleLine.FieldCaption("Cash Flow Forecast Filter"));
        LibraryReportValidation.VerifyCellValue(4, 2, CashFlowForecast."No.");
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleWithNewNameRequestPageHandler,CopyAccountScheduleSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyExistingAccountScheduleWithNewName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        NewAccountScheduleName: Code[10];
    begin
        Initialize;

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo, AccScheduleLine.Show::Yes);
        NewAccountScheduleName := LibraryUtility.GenerateGUID;

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(NewAccountScheduleName);
        CopyAccountSchedule(AccScheduleName.Name);

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(NewAccountScheduleName, AccScheduleName.Name);
        AssertAccountScheduleLineCopyEqualsAccountScheduleLine(NewAccountScheduleName, AccScheduleName.Name);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleMissingNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyExistingAccountScheduleWithoutSpecifyingNewName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo, AccScheduleLine.Show::Yes);

        // Exercise
        Commit();
        asserterror CopyAccountSchedule(AccScheduleName.Name);

        // Verify
        Assert.ExpectedError(TargetNameMissingErr);
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyExistingAccountScheduleWithExistingName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo, AccScheduleLine.Show::Yes);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        asserterror CopyAccountSchedule(AccScheduleName.Name);

        // Verify
        Assert.ExpectedError(TargetExistsErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyAccountScheduleWithoutSpecifyingSource()
    var
        MissingAccountScheduleName: Code[10];
        NewAccountScheduleName: Code[10];
    begin
        Initialize;

        // Setup
        MissingAccountScheduleName := LibraryUtility.GenerateGUID;
        NewAccountScheduleName := LibraryUtility.GenerateGUID;

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(NewAccountScheduleName);
        asserterror CopyAccountSchedule(MissingAccountScheduleName);

        // Verify
        Assert.ExpectedError(CopySourceNameMissingErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyMultipleExistingAccountSchedulesIntoOne()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleName2: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleLine2: Record "Acc. Schedule Line";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo, AccScheduleLine.Show::Yes);

        LibraryERM.CreateAccScheduleName(AccScheduleName2);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine2, AccScheduleName2.Name, LibraryERM.CreateGLAccountNo, AccScheduleLine2.Show::Yes);

        // Exercise
        Commit();
        asserterror CopyMultipleAccountSchedule(AccScheduleName.Name, AccScheduleName2.Name);

        // Verify
        Assert.ExpectedError(MultipleSourcesErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('EditSystemAccountScheduleConfirmHandlerNo,OpenOriginalAccountSchedulePageHandler')]
    [Scope('OnPrem')]
    procedure StanSkipsCreatingCopyOfSystemAccountSchedule()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccountScheduleNames: TestPage "Account Schedule Names";
        OriginalCount: Integer;
    begin
        Initialize;

        // Setup
        OriginalCount := AccScheduleName.Count();
        GeneralLedgerSetup.Get();

        // Excecise
        Commit();
        LibraryVariableStorage.Enqueue(GeneralLedgerSetup."Acc. Sched. for Balance Sheet");

        AccountScheduleNames.OpenEdit;
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke;

        // Verify
        Assert.RecordCount(AccScheduleName, OriginalCount);
    end;

    [Test]
    [HandlerFunctions('MakeCopyOfSystemAccountScheduleConfirmHandlerYes,CopyAccountScheduleWithNewNameRequestPageHandler,CopyAccountScheduleSuccessMessageHandler,MakeCopyAccountSchedulePageHandler')]
    [Scope('OnPrem')]
    procedure StanConfirmsCreatingCopyOfSystemAccountSchedule()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccountScheduleNames: TestPage "Account Schedule Names";
        NewAccountScheduleName: Code[10];
    begin
        Initialize;

        // Setup
        GeneralLedgerSetup.Get();
        NewAccountScheduleName := LibraryUtility.GenerateGUID;

        // Excecise
        Commit();

        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Once for the Copy Account Schedule request page handler
        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Another for the Account Schedule page handler

        AccountScheduleNames.OpenEdit;
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke;

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(
          NewAccountScheduleName, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");
        AssertAccountScheduleLineCopyEqualsAccountScheduleLine(
          NewAccountScheduleName, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MakeCopyOfSystemAccountScheduleConfirmHandlerYes,CopyAccountScheduleWithNewNameRequestPageHandler,CopyAccountScheduleSuccessMessageHandler,ShowNothingAccountSchedulePageHandler')]
    [Scope('OnPrem')]
    procedure StanEditsCreatedCopyOfSystemAccountScheduleWithoutImpactOnSystemAccountSchedule()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccountScheduleNames: TestPage "Account Schedule Names";
        NewAccountScheduleName: Code[10];
    begin
        Initialize;

        // Setup
        GeneralLedgerSetup.Get();
        NewAccountScheduleName := LibraryUtility.GenerateGUID;

        // Excecise
        Commit();

        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Once for the Copy Account Schedule request page handler
        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Another for the Account Schedule page handler

        AccountScheduleNames.OpenEdit;
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke;

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(
          NewAccountScheduleName, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");
        AssertAccountScheduleLineCopyEqualsAccountScheduleLineExceptShow(
          NewAccountScheduleName, GeneralLedgerSetup."Acc. Sched. for Balance Sheet");

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure TotalingDimensionValuesCanBeUsedAsFiltersInAccountScheduleWithAnalysisViewReport()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        DimensionValue: array[4] of Record "Dimension Value";
        TotalingDimensionValue: array[4] of Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        DimSetID: Integer;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Analysis View]
        // [SCENARIO 297118] Totaling dimension values of dimensions set up in Analysis View can be used as filters in Account Schedule report.
        Initialize;

        // [GIVEN] Four custom dimensions.
        // [GIVEN] Each dimension has a standard value and a totaling value.
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue[i]);
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue[i]."Dimension Code", DimensionValue[i].Code);

            LibraryDimension.CreateDimensionValue(TotalingDimensionValue[i], DimensionValue[i]."Dimension Code");
            TotalingDimensionValue[i].Validate("Dimension Value Type", TotalingDimensionValue[i]."Dimension Value Type"::"End-Total");
            TotalingDimensionValue[i].Validate(Totaling, DimensionValue[i].Code);
            TotalingDimensionValue[i].Modify(true);
        end;

        // [GIVEN] Create gen. journal line with dimension set ID that includes all four dimensions.
        // [GIVEN] Post the gen. journal for "X" LCY to g/l account "A".
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Account schedule WITH an analysis view.
        // [GIVEN] Set up g/l account no. "A" on the account schedule line.
        CreateAccScheduleNameWithViewAndDimensions(AccScheduleName, DimensionValue);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, GenJournalLine."Account No.", AccScheduleLine.Show::Yes);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::"Net Change", '');

        // [GIVEN] Update the analysis view.
        AnalysisView.Get(AccScheduleName."Analysis View Name");
        LibraryERM.UpdateAnalysisView(AnalysisView);

        // [WHEN] Run Account Schedule report, use the totaling dimension values as filters.
        RunAccountScheduleReportWithDims(AccScheduleName.Name, ColumnLayoutName.Name, TotalingDimensionValue);

        // [THEN] The report shows the account schedule line with amount = "X".
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Acc__Schedule_Line_Description', AccScheduleLine.Description);
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', Format(GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure TotalingDimensionValuesCanBeUsedAsFiltersInAccountScheduleWithoutAnalysisViewReport()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        DimensionValue: array[4] of Record "Dimension Value";
        TotalingDimensionValue: array[4] of Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        DimSetID: Integer;
        i: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 297118] Totaling dimension values of global dimensions can be used as filters in Account Schedule report.
        Initialize;

        // [GIVEN] Create a new standard value to each of two global dimensions.
        // [GIVEN] Create a a new totaling value to each of two global dimensions.
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], LibraryERM.GetGlobalDimensionCode(i));
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue[i]."Dimension Code", DimensionValue[i].Code);
            LibraryDimension.CreateDimensionValue(TotalingDimensionValue[i], LibraryERM.GetGlobalDimensionCode(i));
            TotalingDimensionValue[i].Validate("Dimension Value Type", TotalingDimensionValue[i]."Dimension Value Type"::"End-Total");
            TotalingDimensionValue[i].Validate(Totaling, DimensionValue[i].Code);
            TotalingDimensionValue[i].Modify(true);
        end;

        // [GIVEN] Create gen. journal line with dimension set ID that includes both global dimensions.
        // [GIVEN] Post the gen. journal for "X" LCY to g/l account "A".
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Account schedule WITHOUT an analysis view.
        // [GIVEN] Set up g/l account no. "A" on the account schedule line.
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, GenJournalLine."Account No.", AccScheduleLine.Show::Yes);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::"Net Change", '');

        // [WHEN] Run Account Schedule report, use the totaling global dimension values as filters.
        RunAccountScheduleReportWithDims(AccScheduleName.Name, ColumnLayoutName.Name, TotalingDimensionValue);

        // [THEN] The report shows the account schedule line with amount = "X".
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Acc__Schedule_Line_Description', AccScheduleLine.Description);
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', Format(GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('AccScheduleLineRowFormulaMessageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleVarianceDrillDownPrintsColumnLayoutFormula()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 316821] Variance drill down shows column layout formula when both account schedule and column layout contains formula.
        Initialize;

        // [GIVEN] Account schedule with formula totaling type and column layout with formula column type.
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLine(
          AccScheduleLine,
          AccScheduleName.Name,
          AccScheduleLine."Totaling Type"::Formula,
          Format(LibraryRandom.RandInt(1000)));
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(
          ColumnLayout,
          ColumnLayoutName.Name,
          ColumnLayout."Column Type"::Formula,
          Format(LibraryRandom.RandInt(1000)));
        LibraryVariableStorage.Enqueue(ColumnLayout.Formula);

        // [WHEN] Invoke drill down on Acc. Schedule Line from Acc. Schedule Overview page (AccScheduleLineRowFormulaMessageHandler handler).
        AccSchedManagement.DrillDownFromOverviewPage(ColumnLayout, AccScheduleLine, PeriodType::Year);

        // [THEN] The message prints formula from column layout.
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldShowSetupForAlwaysValueCorrectlyInColumnLayout()
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        ColumnLayoutPage: TestPage "Column Layout";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350308] Change field Show in Column Layout to Always
        // [GIVEN] Created Column Layout Name
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        // [WHEN] Opened page ColumnLayoutPage and set Show = "When Negative"
        ColumnLayoutPage.OpenEdit();
        ColumnLayoutPage.CurrentColumnName.SetValue(ColumnLayoutName.Name);
        ColumnLayoutPage.Show.SetValue(ColumnLayout.Show::"When Negative");

        // [WHEN] Set Show = Always
        ColumnLayoutPage.Show.SetValue(ColumnLayout.Show::Always);

        // [THEN] Show validated correctly and equal to Always
        ColumnLayoutPage.Show.AssertEquals(ColumnLayout.Show::Always);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        Clear(LibraryReportValidation);
    end;

    local procedure CreateAccScheduleWithFourLines(var AccountScheduleName: Code[10]; var ColLayoutName: Code[10]; var LineDescription: array[4] of Text; ShowOption: Option)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountNo: array[4] of Code[20];
        i: Integer;
    begin
        GLAccountNo[1] := '';
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo;
        GLAccountNo[3] := CreateGLAccountWithNetChange(LibraryRandom.RandDecInRange(1000, 2000, 2));
        GLAccountNo[4] := CreateGLAccountWithNetChange(-LibraryRandom.RandDecInRange(1000, 2000, 2));

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        for i := 1 to ArrayLen(GLAccountNo) do begin
            CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, GLAccountNo[i], ShowOption);
            LineDescription[i] := AccScheduleLine.Description;
        end;

        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::"Net Change", '');

        AccountScheduleName := AccScheduleName.Name;
        ColLayoutName := ColumnLayoutName.Name;
    end;

    local procedure CreateAccScheduleLineWithGLAcc(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Code[10]; GLAccountNo: Code[20]; ShowValue: Option)
    begin
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName, AccScheduleLine."Totaling Type"::"Posting Accounts", GLAccountNo);
        with AccScheduleLine do begin
            Validate(Show, ShowValue);
            Modify(true);
        end;
    end;

    local procedure CreateAccScheduleNameWithViewAndDimensions(var AccScheduleName: Record "Acc. Schedule Name"; DimensionValue: array[4] of Record "Dimension Value")
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", DimensionValue[1]."Dimension Code");
        AnalysisView.Validate("Dimension 2 Code", DimensionValue[2]."Dimension Code");
        AnalysisView.Validate("Dimension 3 Code", DimensionValue[3]."Dimension Code");
        AnalysisView.Validate("Dimension 4 Code", DimensionValue[4]."Dimension Code");
        AnalysisView.Modify(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView.Code);
        AccScheduleName.Modify(true);
    end;

    local procedure CreateAccScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Code[10]; NewTotalingTypeValue: Enum "Acc. Schedule Line Totaling Type"; NewTotalingValue: Text[250])
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName);
        with AccScheduleLine do begin
            Validate("Row No.", LibraryUtility.GenerateGUID);
            Validate(Description, LibraryUtility.GenerateGUID);
            Validate("Totaling Type", NewTotalingTypeValue);
            Validate(Totaling, NewTotalingValue);
            Modify(true);
        end;
    end;

    local procedure CreateColumnLayoutLine(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Code[10]; NewColumnTypeValue: Option; NewFormulaValue: Code[80])
    begin
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName);
        with ColumnLayout do begin
            Validate("Column No.", LibraryUtility.GenerateGUID);
            Validate("Column Header", LibraryUtility.GenerateGUID);
            Validate("Column Type", NewColumnTypeValue);
            Validate(Formula, NewFormulaValue);
            Modify(true);
        end;
    end;

    local procedure CreateColumns(ColumnLayoutName: Record "Column Layout Name"; Formula: Code[80]; NumberOfColumns: Integer)
    var
        ColumnLayout: Record "Column Layout";
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfColumns do
            CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::Formula, Formula);
    end;

    local procedure CreateLines(AccScheduleName: Record "Acc. Schedule Name"; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; NumberOfRows: Integer)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfRows do
            CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, TotalingType, Totaling);
    end;

    local procedure CreateGLAccountWithNetChange(NetChange: Decimal) GLAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        with GenJournalLine do
            LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, "Document Type"::" ", "Account Type"::"G/L Account", GLAccountNo, NetChange);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CopyAccountSchedule(SourceAccountScheduleName: Code[10])
    var
        AccountScheduleNames: TestPage "Account Schedule Names";
    begin
        AccountScheduleNames.OpenView;
        AccountScheduleNames.FILTER.SetFilter(Name, SourceAccountScheduleName);
        AccountScheduleNames.CopyAccountSchedule.Invoke;
    end;

    local procedure CopyMultipleAccountSchedule(SourceAccountScheduleName1: Code[10]; SourceAccountScheduleName2: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.SetFilter(Name, StrSubstNo('%1 | %2', SourceAccountScheduleName1, SourceAccountScheduleName2));
        REPORT.RunModal(REPORT::"Copy Account Schedule", true, true, AccScheduleName);
    end;

    local procedure RunAccountScheduleReport(ScheduleName: Code[10]; ColumnLayoutName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetAccSchedName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(Format(WorkDate), '', '', '', '', '', '', '');
        Commit();
        AccountSchedule.Run;
    end;

    local procedure RunAccountScheduleReportWithDims(ScheduleName: Code[10]; ColumnLayoutName: Code[10]; DimensionValue: array[4] of Record "Dimension Value")
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetAccSchedName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(
          Format(WorkDate), '', '', '', DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code, DimensionValue[4].Code);
        Commit();
        AccountSchedule.Run;
    end;

    local procedure RunAccountScheduleReportSaveAsExcel(ScheduleName: Code[10]; ColumnLayoutName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetAccSchedName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(Format(WorkDate), '', '', '', '', '', '', '');
        AccountSchedule.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    local procedure RunExportAccScheduleToExcel(AccScheduleName: Record "Acc. Schedule Name"; DimensionValue: array[4] of Record "Dimension Value")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY>', WorkDate), CalcDate('<CY>', WorkDate));
        AccScheduleLine.SetRange("Dimension 1 Filter", DimensionValue[1].Code);
        AccScheduleLine.SetRange("Dimension 2 Filter", DimensionValue[2].Code);
        AccScheduleLine.SetRange("Dimension 3 Filter", DimensionValue[3].Code);
        AccScheduleLine.SetRange("Dimension 4 Filter", DimensionValue[4].Code);
        RunExportAccSchedule(AccScheduleLine, AccScheduleName);
    end;

    local procedure RunExportAccSchedule(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Record "Acc. Schedule Name")
    var
        ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
    begin
        ExportAccSchedToExcel.SetFileNameSilent(LibraryReportValidation.GetFileName);
        ExportAccSchedToExcel.SetOptions(AccScheduleLine, AccScheduleName."Default Column Layout", false);
        ExportAccSchedToExcel.SetTestMode(true);
        ExportAccSchedToExcel.UseRequestPage(false);
        ExportAccSchedToExcel.Run;
    end;

    [Scope('OnPrem')]
    procedure RunExportAccScheduleWithDimFilter(AccScheduleName: Record "Acc. Schedule Name"; DimFilterValue: array[4] of Code[20])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetAccSchedName(AccScheduleName.Name);
        AccountSchedule.SetFilters(Format(WorkDate), '', '', '', DimFilterValue[1], DimFilterValue[2], DimFilterValue[3], DimFilterValue[4]);
        AccountSchedule.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    local procedure VerifyDimensionsAndValueInExcel(DimensionValue: array[4] of Record "Dimension Value")
    begin
        LibraryReportValidation.OpenExcelFile;
        VerifyDimFilterAndDimValue(DimensionValue[1], 3);
        VerifyDimFilterAndDimValue(DimensionValue[2], 4);
        VerifyDimFilterAndDimValue(DimensionValue[3], 5);
        VerifyDimFilterAndDimValue(DimensionValue[4], 6);
    end;

    local procedure VerifyDimFilterAndDimValue(DimensionValue: Record "Dimension Value"; RowId: Integer)
    begin
        Assert.AreEqual(
          StrSubstNo(DimFilterStrTok, DimensionValue."Dimension Code"),
          UpperCase(LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(1, RowId, 1)), DimFilterErr);
        LibraryReportValidation.VerifyCellValue(RowId, 2, DimensionValue.Code);
    end;

    local procedure AssertAccountScheduleCopyEqualsAccountSchedule(AccountScheduleCopy: Code[10]; AccountScheduleSource: Code[10])
    var
        FromAccScheduleName: Record "Acc. Schedule Name";
        ToAccScheduleName: Record "Acc. Schedule Name";
    begin
        FromAccScheduleName.Get(AccountScheduleSource);
        ToAccScheduleName.Get(AccountScheduleCopy);

        ToAccScheduleName.TestField(Description, FromAccScheduleName.Description);
        ToAccScheduleName.TestField("Default Column Layout", FromAccScheduleName."Default Column Layout");
        ToAccScheduleName.TestField("Analysis View Name", FromAccScheduleName."Analysis View Name");
    end;

    local procedure AssertAccountScheduleLineCopyEqualsAccountScheduleLine(AccountScheduleCopy: Code[10]; AccountScheduleSource: Code[10])
    var
        FromAccScheduleLine: Record "Acc. Schedule Line";
        ToAccScheduleLine: Record "Acc. Schedule Line";
    begin
        AssertAccountScheduleLineCopyCountEqualsAccountScheduleLineCount(
          ToAccScheduleLine, FromAccScheduleLine, AccountScheduleCopy, AccountScheduleSource);
        AssertAccountScheduleLineCopyValuesEqualAccountScheduleLineValues(ToAccScheduleLine, FromAccScheduleLine);
    end;

    local procedure AssertAccountScheduleLineCopyEqualsAccountScheduleLineExceptShow(AccountScheduleCopy: Code[10]; AccountScheduleSource: Code[10])
    var
        FromAccScheduleLine: Record "Acc. Schedule Line";
        ToAccScheduleLine: Record "Acc. Schedule Line";
    begin
        AssertAccountScheduleLineCopyCountEqualsAccountScheduleLineCount(
          ToAccScheduleLine, FromAccScheduleLine, AccountScheduleCopy, AccountScheduleSource);
        AssertAccountScheduleLineCopyValuesEqualAccountScheduleLineValuesExceptShow(ToAccScheduleLine, FromAccScheduleLine);
    end;

    local procedure AssertAccountScheduleLineCopyCountEqualsAccountScheduleLineCount(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line"; AccountScheduleCopy: Code[10]; AccountScheduleSource: Code[10])
    begin
        FromAccScheduleLine.SetRange("Schedule Name", AccountScheduleSource);
        ToAccScheduleLine.SetRange("Schedule Name", AccountScheduleCopy);

        Assert.RecordCount(ToAccScheduleLine, FromAccScheduleLine.Count);
    end;

    local procedure AssertAccountScheduleLineCopyValuesEqualAccountScheduleLineValues(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line")
    begin
        FromAccScheduleLine.FindSet;
        ToAccScheduleLine.FindSet;

        repeat
            AssertAccountScheduleLineValuesAreEqual(ToAccScheduleLine, FromAccScheduleLine);
            ToAccScheduleLine.TestField(Show, FromAccScheduleLine.Show);
        until (ToAccScheduleLine.Next = 0) and (FromAccScheduleLine.Next = 0);
    end;

    local procedure AssertAccountScheduleLineCopyValuesEqualAccountScheduleLineValuesExceptShow(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line")
    var
        FirstLineIsChecked: Boolean;
    begin
        FromAccScheduleLine.FindSet;
        ToAccScheduleLine.FindSet;

        repeat
            AssertAccountScheduleLineValuesAreEqual(ToAccScheduleLine, FromAccScheduleLine);
            if FirstLineIsChecked then
                ToAccScheduleLine.TestField(Show, FromAccScheduleLine.Show)
            else begin
                ToAccScheduleLine.TestField(Show, ToAccScheduleLine.Show::No);
                Assert.AreNotEqual(FromAccScheduleLine.Show, ToAccScheduleLine.Show, 'The value of Show was not edited in the copy.');
                FirstLineIsChecked := true;
            end;
        until (ToAccScheduleLine.Next = 0) and (FromAccScheduleLine.Next = 0);
    end;

    local procedure AssertAccountScheduleLineValuesAreEqual(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line")
    begin
        ToAccScheduleLine.TestField("Line No.", FromAccScheduleLine."Line No.");
        ToAccScheduleLine.TestField("Row No.", FromAccScheduleLine."Row No.");
        ToAccScheduleLine.TestField(Description, FromAccScheduleLine.Description);
        ToAccScheduleLine.TestField(Totaling, FromAccScheduleLine.Totaling);
        ToAccScheduleLine.TestField("Totaling Type", FromAccScheduleLine."Totaling Type");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountSchedule(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        AccScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccScheduleName);
        AccountSchedule.AccSchedNam.SetValue(AccScheduleName);
        AccountSchedule.Dim1Filter.Lookup;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LookUpDimensionValueListHandler(var DimensionValueList: TestPage "Dimension Value List")
    var
        DimensionValue: Record "Dimension Value";
        DimensionFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionFilter);
        DimensionValue.SetRange("Dimension Code", DimensionFilter);
        DimensionValue.FindFirst;
        Assert.IsTrue(DimensionValueList.GotoRecord(DimensionValue), DimensionValueErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHAccountScheduleVerifyData(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        AccSchedNam: Variant;
        ColumnLayoutNames: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccSchedNam);
        LibraryVariableStorage.Dequeue(ColumnLayoutNames);
        AccountSchedule.AccSchedNam.AssertEquals(AccSchedNam);
        AccountSchedule.ColumnLayoutNames.AssertEquals(ColumnLayoutNames);
        AccountSchedule.StartDate.SetValue(WorkDate);
        AccountSchedule.EndDate.SetValue(WorkDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleWithNewNameRequestPageHandler(var CopyAccountSchedule: TestRequestPage "Copy Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        NewAccountScheduleName: Code[10];
    begin
        NewAccountScheduleName := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(AccScheduleName.Name));

        CopyAccountSchedule.NewAccountScheduleName.SetValue(NewAccountScheduleName);
        CopyAccountSchedule.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleMissingNewNameRequestPageHandler(var CopyAccountSchedule: TestRequestPage "Copy Account Schedule")
    begin
        CopyAccountSchedule.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OpenOriginalAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(AccScheduleName.Name)));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MakeCopyAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(AccScheduleName.Name)));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ShowNothingAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(AccScheduleName.Name)));
        AccountSchedule.Show.SetValue(AccScheduleLine.Show::No);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure EditSystemAccountScheduleConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(SystemGeneratedAccSchedQst, Question);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MakeCopyOfSystemAccountScheduleConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(SystemGeneratedAccSchedQst, Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleLineRowFormulaMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleSuccessMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CopySuccessMsg, Message);
    end;
}

