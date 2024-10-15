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
        CopySuccessMsg: Label 'The new rows definition has been created successfully.';
        CopyColumnLayoutSuccessMsg: Label 'The new column layout has been created.';
        DimensionValueErr: Label 'Dimension Value record does not exist.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        DimFilterErr: Label 'Wrong Dimension filter.';
        DimFilterStrTok: Label '%1 FILTER';
        DimFilterStringTok: Label 'Dimension 1 Filter: %1, Dimension 2 Filter: %2, Dimension 3 Filter: %3, Dimension 4 Filter: %4';
        CopySourceNameMissingErr: Label 'You must specify a valid name for the source rows definition to copy from.';
        MultipleSourcesErr: Label 'You can only copy one rows definition at a time.';
        SystemGeneratedAccSchedQst: Label 'This account schedule may be automatically updated by the system, so any changes you make may be lost. Do you want to make a copy?';
        TargetExistsErr: Label 'The new rows definition already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new rows definition.';
        IsInitialized: Boolean;

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
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(100);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        MaxColumnCount := 5;
        CreateColumns(ColumnLayoutName, Format(LibraryRandom.RandDec(9999, 2), 12, 0), MaxColumnCount);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify that names of columns are the same as they are in the Column Layout set.
        LibraryReportDataset.LoadDataSetFile();
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        ColumnLayout.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('Header', ColumnLayout."Column Header");
        until ColumnLayout.Next() = 0;
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
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(100);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify that the report was saved successfully.
        LibraryReportDataset.LoadDataSetFile();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst();
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
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        RowCount := LibraryRandom.RandInt(10);
        CreateLines(AccScheduleName, Format(LibraryRandom.RandInt(10)), AccScheduleLine."Totaling Type"::Formula, RowCount);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        ColumnCount := LibraryRandom.RandInt(4);
        CreateColumns(ColumnLayoutName, Format(LibraryRandom.RandDec(9999, 2), 12, 0), ColumnCount);

        // 2.Exercise: Run the 25th Report.
        RunAccountScheduleReport(AccScheduleName.Name, ColumnLayoutName.Name);

        // 3.Verify: Verify report header.
        LibraryReportDataset.LoadDataSetFile();
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
        Initialize();
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
        Initialize();

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
        Initialize();

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
        LibraryReportDataset.LoadDataSetFile();
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        if ColumnLayout.FindSet() then
            repeat
                LibraryReportDataset.AssertElementWithValueExists('Header', ColumnLayout."Column Header");
            until ColumnLayout.Next() = 0;
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
        Initialize();

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
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        WithAnalysisViewFound: Boolean;
    begin
        // Verify account schedule export to Excel can fill Excel Buffer
        Initialize();
        FinancialReport.SetFilter("Financial Report Column Group", '<>%1', '');
        WithAnalysisViewFound := false;
        if FinancialReport.FindSet() then
            repeat
                AccScheduleName.Get(FinancialReport."Financial Report Row Group");
                if AccScheduleName."Analysis View Name" <> '' then
                    WithAnalysisViewFound := true;
            until (FinancialReport.Next() = 0) or WithAnalysisViewFound;
        if WithAnalysisViewFound then begin
            LibraryReportValidation.SetFileName(AccScheduleName.Name);

            // Export to Excel buffer
            AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
            AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
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
        Initialize();

        // [GIVEN] An account schedule with one line
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::"Posting Accounts", '');
        Assert.AreEqual(0, AccScheduleLine.Indentation, '');

        // [WHEN] User clicks Indent / Outdent,
        // [THEN] Indentation value on the line increases/decreases by 1 and cannot become negative
        AccountSchedule.OpenEdit();
        AccountSchedule.CurrentSchedName.SetValue(AccScheduleName.Name);
        AccountSchedule.First();

        AccountSchedule.Indent.Invoke();
        AccScheduleLine.Find();
        Assert.AreEqual(1, AccScheduleLine.Indentation, '');

        AccountSchedule.Outdent.Invoke();
        AccScheduleLine.Find();
        Assert.AreEqual(0, AccScheduleLine.Indentation, '');

        AccountSchedule.Outdent.Invoke();
        AccScheduleLine.Find();
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
        Initialize();

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
        Initialize();

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
        Initialize();

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
        Initialize();

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
        Initialize();

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
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::"Posting Accounts", '');
        ExpectedResult := 1000;
        AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::Formula;
        AccScheduleLine.SetRange("Date Filter", WorkDate());
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
        Initialize();

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
        Initialize();

        // [GIVEN] Account Schedule with Analysis View without dimensions
        CreateAccScheduleNameWithViewAndDimensions(AccScheduleName, DimensionValue);
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel)
        RunExportAccScheduleToExcel(AccScheduleName, DimensionValue);

        // [THEN] Excel file exported
        Assert.IsTrue(FILE.Exists(LibraryReportValidation.GetFileName()), AccScheduleExportErr);
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
        Initialize();

        // [GIVEN] Account Schedule with "Analysis View Name" = ''
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName."Analysis View Name" := '';
        AccScheduleName.Modify();

        // [GIVEN] 4 Dimensions Code with Dimensions Value
        DimFilterValue[1] := LibraryUtility.GenerateGUID();
        DimFilterValue[2] := LibraryUtility.GenerateGUID();
        DimFilterValue[3] := LibraryUtility.GenerateGUID();
        DimFilterValue[4] := LibraryUtility.GenerateGUID();
        LibraryReportValidation.SetFileName(AccScheduleName.Name);

        // [WHEN] Run export Account Schedule to Excel - Report 29 (Export Acc. Sched. to Excel) with Dimensions Filter
        RunExportAccScheduleWithDimFilter(AccScheduleName, DimFilterValue);

        // [THEN] Excel file contans values of dimensions filter
        LibraryReportValidation.OpenExcelFile();
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
        Initialize();

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
        Assert.IsTrue(FILE.Exists(LibraryReportValidation.GetFileName()), AccScheduleExportErr);
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
        Initialize();

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
        LibraryReportValidation.OpenExcelFile();
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
        Initialize();

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo(), AccScheduleLine.Show::Yes);
        NewAccountScheduleName := LibraryUtility.GenerateGUID();

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(NewAccountScheduleName);
        CopyAccountSchedule(AccScheduleName.Name);

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(NewAccountScheduleName, AccScheduleName.Name);
        AssertAccountScheduleLineCopyEqualsAccountScheduleLine(NewAccountScheduleName, AccScheduleName.Name);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleMissingNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyExistingAccountScheduleWithoutSpecifyingNewName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        Initialize();

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo(), AccScheduleLine.Show::Yes);

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
        Initialize();

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo(), AccScheduleLine.Show::Yes);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        asserterror CopyAccountSchedule(AccScheduleName.Name);

        // Verify
        Assert.ExpectedError(TargetExistsErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyAccountScheduleWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyAccountScheduleWithoutSpecifyingSource()
    var
        MissingAccountScheduleName: Code[10];
        NewAccountScheduleName: Code[10];
    begin
        Initialize();

        // Setup
        MissingAccountScheduleName := LibraryUtility.GenerateGUID();
        NewAccountScheduleName := LibraryUtility.GenerateGUID();

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(NewAccountScheduleName);
        asserterror CopyAccountSchedule(MissingAccountScheduleName);

        // Verify
        Assert.ExpectedError(CopySourceNameMissingErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
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
        Initialize();

        // Setup
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, LibraryERM.CreateGLAccountNo(), AccScheduleLine.Show::Yes);

        LibraryERM.CreateAccScheduleName(AccScheduleName2);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine2, AccScheduleName2.Name, LibraryERM.CreateGLAccountNo(), AccScheduleLine2.Show::Yes);

        // Exercise
        Commit();
        asserterror CopyMultipleAccountSchedule(AccScheduleName.Name, AccScheduleName2.Name);

        // Verify
        Assert.ExpectedError(MultipleSourcesErr);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
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
        Initialize();

        // Setup
        OriginalCount := AccScheduleName.Count();
        GeneralLedgerSetup.Get();

        // Excecise
        Commit();
        LibraryVariableStorage.Enqueue(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");

        AccountScheduleNames.OpenEdit();
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke();

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
        Initialize();

        // Setup
        GeneralLedgerSetup.Get();
        NewAccountScheduleName := LibraryUtility.GenerateGUID();

        // Excecise
        Commit();

        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Once for the Copy Account Schedule request page handler
        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Another for the Account Schedule page handler

        AccountScheduleNames.OpenEdit();
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke();

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(
          NewAccountScheduleName, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AssertAccountScheduleLineCopyEqualsAccountScheduleLine(
          NewAccountScheduleName, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");

        // Teardown
        LibraryVariableStorage.AssertEmpty();
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
        Initialize();

        // Setup
        GeneralLedgerSetup.Get();
        NewAccountScheduleName := LibraryUtility.GenerateGUID();

        // Excecise
        Commit();

        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Once for the Copy Account Schedule request page handler
        LibraryVariableStorage.Enqueue(NewAccountScheduleName); // Another for the Account Schedule page handler

        AccountScheduleNames.OpenEdit();
        AccountScheduleNames.FILTER.SetFilter(Name, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccountScheduleNames.EditAccountSchedule.Invoke();

        // Verify
        AssertAccountScheduleCopyEqualsAccountSchedule(
          NewAccountScheduleName, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AssertAccountScheduleLineCopyEqualsAccountScheduleLineExceptShow(
          NewAccountScheduleName, GeneralLedgerSetup."Fin. Rep. for Balance Sheet");

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure TotalingDimensionValuesCanBeUsedAsFiltersInAccountScheduleWithAnalysisViewReport()
    var
        FinancialReport: Record "Financial Report";
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
        Initialize();

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
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Account schedule WITH an analysis view.
        // [GIVEN] Set up g/l account no. "A" on the account schedule line.
        CreateAccScheduleNameWithViewAndDimensions(AccScheduleName, DimensionValue);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, GenJournalLine."Account No.", AccScheduleLine.Show::Yes);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::"Net Change", '');
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport."Financial Report Column Group" := ColumnLayout."Column Layout Name";
        FinancialReport.Modify();

        // [GIVEN] Update the analysis view.
        AnalysisView.Get(AccScheduleName."Analysis View Name");
        LibraryERM.UpdateAnalysisView(AnalysisView);

        // [WHEN] Run Account Schedule report, use the totaling dimension values as filters.
        RunAccountScheduleReportWithDims(AccScheduleName.Name, ColumnLayoutName.Name, TotalingDimensionValue);

        // [THEN] The report shows the account schedule line with amount = "X".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Acc__Schedule_Line_Description', AccScheduleLine.Description);
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', Format(GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure TotalingDimensionValuesCanBeUsedAsFiltersInAccountScheduleWithoutAnalysisViewReport()
    var
        FinancialReport: Record "Financial Report";
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
        Initialize();

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
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Account schedule WITHOUT an analysis view.
        // [GIVEN] Set up g/l account no. "A" on the account schedule line.
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLineWithGLAcc(AccScheduleLine, AccScheduleName.Name, GenJournalLine."Account No.", AccScheduleLine.Show::Yes);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::"Net Change", '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := ColumnLayout."Column Layout Name";
        FinancialReport.Modify();

        // [WHEN] Run Account Schedule report, use the totaling global dimension values as filters.
        RunAccountScheduleReportWithDims(AccScheduleName.Name, ColumnLayoutName.Name, TotalingDimensionValue);

        // [THEN] The report shows the account schedule line with amount = "X".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Acc__Schedule_Line_Description', AccScheduleLine.Description);
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', Format(GenJournalLine.Amount));
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
        Initialize();

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
        LibraryVariableStorage.AssertEmpty();
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

    [Test]
    [HandlerFunctions('AccountScheduleSetSkipEmptyLinesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportForEmptyTotalingSkipEmptyLinesYes()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 316070] Account Schedule report prints lines with empty Totaling and Show=Yes when SkipEmptyLines = true
        Initialize();

        // [GIVEN] Account Schedule Name 
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        // [GIVEN] Line 10000 with empty Totaling and Show=Yes
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.TestField(Totaling, '');
        AccScheduleLine.TestField(Show, "Acc. Schedule Line Show"::Yes);

        Commit();
        AccScheduleName.SetRecFilter();

        // [WHEN] Run Account Schedule report with "Show Zero Amount Lines" = yes
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] LineSkipped = false for line 10000
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineSkipped', false);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        LocalCurrencySymbol: Text[10];
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report prints currency symbol for the amounts if "Show Currency Symbol" = yes
        Initialize();

        // [GIVEN] GLSetup with local currency symbol '$' specified
        LocalCurrencySymbol := UpdateGLSetupLocalCurrencySymbol();

        // [GIVEN] Create G/L Account account "A" and post entry with amount 100
        Amount := LibraryRandom.RandDec(100, 2);
        AccountNo := CreateGLAccountWithNetChange(Amount);

        // [GIVEN] Create account schedule line for account "A"
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(false); // Use additionan currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "$100"
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', StrSubstNo('%1%2', LocalCurrencySymbol, Amount));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportAdditionalCurrencySymbol()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        ExchRate: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report prints currency symbol for the amounts if "Show Currency Symbol" = yes and "Show Amounts in Add. Reporting Currency" = yes
        Initialize();

        // [GIVEN] Additional currency "USD" with symbol "$" specified for GLSetup
        ExchRate := LibraryRandom.RandDecInRange(2, 10, 2);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));
        Currency.Validate(Symbol, '$');
        Currency.Modify();
        UpdateGLSetupAddReportingCurrency(Currency.Code);

        // [GIVEN] Create G/L Account account "A" and post entry with Add. Currency Amount = 100
        GLAccount.Get(CreateGLAccountWithNetChange(LibraryRandom.RandDec(100, 2)));
        GLAccount.CalcFields("Additional-Currency Net Change");

        // [GIVEN] Create account schedule line for account "A"
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, GLAccount."No.");
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes and "Show Amounts in Add. Reporting Currency" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(true); // Use additionan currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "$100"
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', StrSubstNo('%1%2', Currency.Symbol, GLAccount."Additional-Currency Net Change"));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintZeroAmountRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol_ZeroAmount_EmptyTotaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report does not Show Currency Symbol for empty Totaling line if "Show Currency Symbol" = yes and "Show Empty Amount Type" = Blank
        Initialize();

        // [GIVEN] Create account schedule line 1 with empty Totaling
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.TestField(Totaling, '');

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes and "Show Empty Amount Type" = Blank
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Blank);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints empty value
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', '');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintZeroAmountRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol_ZeroAmount_ShowEmptyAmountTypeBlank()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccountNo: Code[20];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report does not Show Currency Symbol for zero cell value line if "Show Currency Symbol" = yes and "Show Empty Amount Type" = Blank
        Initialize();

        // [GIVEN] Create account schedule line for account "A" with zero balance
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes and "Show Empty Amount Type" = Blank
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Blank);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints empty value for line 2
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', '');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintZeroAmountRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol_ZeroAmount_ShowEmptyAmountTypeDash()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccountNo: Code[20];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report does not Show Currency Symbol for zero cell value line if "Show Currency Symbol" = yes and "Show Empty Amount Type" = Dash
        Initialize();

        // [GIVEN] Create account schedule line for account "A" with zero balance
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes and "Show Empty Amount Type" = Dash
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Dash);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints dash for line 2
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', '-');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintZeroAmountRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol_ZeroAmount_ShowEmptyAmountTypeZero_EmptyTotaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report does not Show Currency Symbol for empty line if "Show Currency Symbol" = yes and "Show Empty Amount Type" = Zero
        Initialize();

        // [GIVEN] Create account schedule line 1 with empty Totaling
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.TestField(Totaling, '');

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes and "Show Empty Amount Type" = Zero
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Zero);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints empty value for line 1
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText', '');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintZeroAmountRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbol_ZeroAmount_ShowEmptyAmountTypeZero_CellValueZero()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        LocalCurrencySymbol: Text[10];
        MatrixMgt: Codeunit "Matrix Management";
        AccountNo: Code[20];
        ZeroDecimal: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report prints currency symbol for zero cell value line if "Show Currency Symbol" = yes and "Show Empty Amount Type" = Zero
        Initialize();

        // [GIVEN] GLSetup with local currency symbol '$' specified
        LocalCurrencySymbol := UpdateGLSetupLocalCurrencySymbol();

        // [GIVEN] Create account schedule line for account "A" with zero balance
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Zero);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "$0"
        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(
            'ColumnValuesAsText',
            StrSubstNo(
                '%1%2',
                LocalCurrencySymbol,
                Format(ZeroDecimal, 0, MatrixMgt.FormatRoundingFactor("Analysis Rounding Factor"::None, false))));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbolLineAmountFormula()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        LocalCurrencySymbol: Text[10];
        AccountNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report shows Currency Symbol for line simple formula which calculates amount
        Initialize();

        // [GIVEN] GLSetup with local currency symbol '$' specified
        LocalCurrencySymbol := UpdateGLSetupLocalCurrencySymbol();

        // [GIVEN] Create G/L Account accounts "A" and post entry with amount 100, "B" with amount 200
        for i := 1 to 2 do begin
            Amount[i] := LibraryRandom.RandDec(100, 2);
            AccountNo[i] := CreateGLAccountWithNetChange(Amount[i]);
        end;
        // [GIVEN] Create account schedule lines for account "A" and "B"
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        for i := 1 to 2 do begin
            LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
            AccScheduleLine."Row No." := Format(i);
            AccScheduleLine.Validate(Totaling, AccountNo[i]);
            AccScheduleLine.Modify();
        end;
        // [GIVEN] Create account schedule line with formula
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", "Acc. Schedule Line Totaling Type"::Formula);
        AccScheduleLine.Validate(Totaling, '-1-2');
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(false); // Use additionan currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "-$300" without currency symbol
        LibraryReportDataset.AssertElementWithValueExists(
            'ColumnValuesAsText',
            StrSubstNo(
                '%1%2',
                    LocalCurrencySymbol,
                    Format(-Amount[1] - Amount[2])));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSkipCurrencySymbolLineFormula()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccountNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report does not show Currency Symbol for line formula with "Hide Currency Symbol" = Yes
        Initialize();

        // [GIVEN] GLSetup with local currency symbol '$' specified
        UpdateGLSetupLocalCurrencySymbol();

        // [GIVEN] Create G/L Account accounts "A" and post entry with amount 100, "B" with amount 200
        for i := 1 to 2 do begin
            Amount[i] := LibraryRandom.RandDec(100, 2);
            AccountNo[i] := CreateGLAccountWithNetChange(Amount[i]);
        end;
        // [GIVEN] Create account schedule lines for account "A" and "B"
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        for i := 1 to 2 do begin
            LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
            AccScheduleLine."Row No." := Format(i);
            AccScheduleLine.Validate(Totaling, AccountNo[i]);
            AccScheduleLine.Modify();
        end;
        // [GIVEN] Create account schedule line with formula 1/2 and "Hide Currency Symbol" = Yes
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", "Acc. Schedule Line Totaling Type"::Formula);
        AccScheduleLine.Validate(Totaling, '1/2');
        AccScheduleLine.Validate("Hide Currency Symbol", true);
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(false); // Use additionan currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "0.5" without currency symbol
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', Format(Round(Amount[1] / Amount[2])));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSkipEmptyLinesShowEmptyAmountTypeRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSkipEmptyLinesYes_ShowEmptyAmountTypeZero()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 316070] Account Schedule report does not print line with zero balance when SkipEmptyLines = true and "Show Empty Amount Type" = Zero
        Initialize();

        // [GIVEN] Create account schedule line for account "A" wit zero balance
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, LibraryERM.CreateGLAccountNo());
        AccScheduleLine.Modify();

        // [WHEN] Run Account Schedule report with "Show Zero Amount Lines" = yes and "Show Empty Amount Type" = Zero
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue("Show Empty Amount Type"::Zero);
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] LineSkipped = true for line 10000
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Acc__Schedule_Line_Line_No', AccScheduleLine."Line No.") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineSkipped', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleResetColumnLayoutOnAccountScheduleChange()
    var
        AccScheduleName: array[2] of Record "Acc. Schedule Name";
        FinancialReport: array[2] of Record "Financial Report";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnHeader: Text[30];
        FinancialReports: Testpage "Financial Reports";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        AccountSchedule1CurrentColumnName: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 423715] Account Schedule Overview not show Column Layout from previous opened Account Schedule
        Initialize();

        // [GIVEN] Column Layout "CL"
        ColumnHeader := LibraryUtility.GenerateGUID();
        ColumnLayoutName.Get(CreateColumnLayoutWithName(ColumnHeader[1]));

        // [GIVEN] Account Schedule "AS1" with empty Default Column Layout, Account Schedule "AS2" with "Default Column Layout" = "CL"
        LibraryERM.CreateAccScheduleName(AccScheduleName[1]);
        LibraryERM.CreateAccScheduleName(AccScheduleName[2]);
        FinancialReport[1].Get(AccScheduleName[1].Name);
        FinancialReport[2].Get(AccScheduleName[2].Name);
        FinancialReport[2].Validate("Financial Report Column Group", ColumnLayoutName.Name);
        FinancialReport[2].Modify();

        // [GIVEN] Account Schedule Overview page is opened for "AS1"
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleName[1].Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [GIVEN] As "AS1" has empty "Default Column Layout", Current Column Name = "Default" (w1) 
        AccountSchedule1CurrentColumnName := AccScheduleOverview.CurrentColumnName.Value();
        AccScheduleOverview.Close();

        // [WHEN] Account Schedule Overview page is opened for "AS2"
        FinancialReports.Filter.SetFilter(Name, AccScheduleName[2].Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [THEN] As "AS2" has empty "Default Column Layout", Current Column Name = "CL" (w1) 
        AccScheduleOverview.CurrentColumnName.AssertEquals(ColumnLayoutName.Name);
        AccScheduleOverview.Close();

        // [WHEN] Account Schedule Overview page is reopened for "AS1"
        FinancialReports.Filter.SetFilter(Name, AccScheduleName[1].Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [GIVEN] Current Column Name has not changed and is equal to previous value = "Default" (w1) 
        AccScheduleOverview.CurrentColumnName.AssertEquals(AccountSchedule1CurrentColumnName);
        AccScheduleOverview.Close();
    end;

    [Test]
    [HandlerFunctions('CopyColumnLayoutWithNewNameRequestPageHandler,CopyColumnLayoutSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure CopyColumnLayoutWithNewName()
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        NewColumnLayoutName: Code[10];
        i: Integer;
    begin
        // [FEATURE] [Copy Column Layout]
        // [SCENARIO 427289] User is able to copy column layout name with related column layouts from "Column Layout Names" page
        Initialize();

        // [GIVEN] Column layout name "CLM"
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        // [GIVEN] 5 column layouts
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do
            CreateSimpleColumnLayout(ColumnLayout, ColumnLayoutName.Name);

        // [WHEN] Run "Copy Column Layout"
        NewColumnLayoutName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewColumnLayoutName);
        CopyColumnLayout(ColumnLayoutName.Name);

        // Verify
        VerifyColumnLayoutNameCopied(NewColumnLayoutName, ColumnLayoutName.Name);
    end;

    [Test]
    [HandlerFunctions('CopyColumnLayoutWithNewNameRequestPageHandler,CopyColumnLayoutSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure CopyColumnLayoutFromColumnLayoutPage()
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        NewColumnLayoutName: Code[10];
        i: Integer;
    begin
        // [FEATURE] [Copy Column Layout]
        // [SCENARIO 427289] User is able to copy column layout name with related column layouts from "Column Layout" page
        Initialize();

        // [GIVEN] Column layout name "CLM"
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        // [GIVEN] 5 column layouts
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do
            CreateSimpleColumnLayout(ColumnLayout, ColumnLayoutName.Name);

        // [WHEN] Run "Copy Column Layout"
        NewColumnLayoutName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewColumnLayoutName);
        CopyColumnLayoutFromColumnLayoutPage(ColumnLayoutName.Name);

        // Verify
        VerifyColumnLayoutNameCopied(NewColumnLayoutName, ColumnLayoutName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleResetColumnLayoutOnAccountScheduleChangeAccScheduleOverviewPage()
    var
        AccScheduleName: array[2] of Record "Acc. Schedule Name";
        FinancialReport: array[2] of Record "Financial Report";
        ColumnLayoutName: Record "Column Layout Name";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleCurrentColumnName: Text;
    begin
        // [SCENARIO 430774] Account Schedule Overview switch to Account Schedule with no Default Column Layout should assign 'Default" Column Layout
        Initialize();

        // [GIVEN] Column Layout "CL"
        ColumnLayoutName.GET(CreateColumnLayoutWithName(LibraryUtility.GenerateGUID()));

        // [GIVEN] Account Schedule "AS1" with with "Default Column Layout" = "CL", Account Schedule "AS2" with empty Default Column Layout
        LibraryERM.CreateAccScheduleName(AccScheduleName[1]);

        LibraryERM.CreateAccScheduleName(AccScheduleName[2]);
        FinancialReport[1].Get(AccScheduleName[1].Name);
        FinancialReport[2].Get(AccScheduleName[2].Name);

        FinancialReport[1].Validate("Financial Report Column Group", ColumnLayoutName.Name);
        AccScheduleName[1].Modify();


        // [GIVEN] Account Schedule Overview page is opened for "AS2"
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName[2].Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [GIVEN] As "AS" has empty "Default Column Layout", Current Column Name = "Default" (w1)
        AccountScheduleCurrentColumnName := AccScheduleOverview.CurrentColumnName.Value();
        AccScheduleOverview.Close();

        // [WHEN] Account Schedule Overview page is opened for "AS1"
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName[1].Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [WHEN] Set "Account Schedule Name" = "AS2"
        AccScheduleOverview.CurrentSchedName.SetValue(AccScheduleName[2].Name);

        // [THEN] Current Column Name = "Default" (w1)
        AccScheduleOverview.CurrentSchedName.AssertEquals(AccScheduleName[2].Name);
        AccScheduleOverview.CurrentColumnName.AssertEquals(AccountScheduleCurrentColumnName);
        AccScheduleOverview.Close();
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportCurrencySymbolColumnFormula()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        LocalCurrencySymbol: Text[10];
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report shows Currency Symbol for column formula 
        // Clear
        Initialize();
        // [GIVEN] GLSetup with local currency symbol '$' specified
        LocalCurrencySymbol := UpdateGLSetupLocalCurrencySymbol();
        // [GIVEN] Create G/L Account account "A" and post entry with amount 100
        Amount := LibraryRandom.RandDec(100, 2);
        AccountNo := CreateGLAccountWithNetChange(Amount);
        // [GIVEN] Create financial report for account "A"
        // Note that the CreateAccScheduleName procedure creates a Financial Report 
        // with the same name as sets the Account Schedule Name as a Row Group
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        FinancialReport.Get(AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();
        // [GIVEN] Create column "C1" with Net Change type
        CreateColumnLayout(ColumnLayout);
        ColumnLayout."Column No." := 'C1';
        ColumnLayout.Modify();
        // [GIVEN] Create column "C2" with formula -C1
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayout."Column Layout Name");
        ColumnLayout."Column Type" := "Column Layout Type"::Formula;
        ColumnLayout."Column No." := 'C2';
        ColumnLayout.Formula := '-C1';
        ColumnLayout.Modify();
        FinancialReport."Financial Report Column Group" := ColumnLayout."Column Layout Name";
        FinancialReport.Modify();
        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(false); // Use additional currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);
        // [THEN] The report prints "$-100" without currency symbol
        LibraryReportDataset.AssertElementWithValueExists(
            'ColumnValuesAsText',
            StrSubstNo(
                '%1%2',
                    LocalCurrencySymbol,
                    Format(-Amount)));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetPrintCurrSymbolRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSkipCurrencySymbolColumnFormula()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        LocalCurrencySymbol: Text[10];
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 365423] Account Schedule report shows Currency Symbol for simple column formula does not show Currency Symbol for column formula and "Hide Currency Symbol" = Yes
        Initialize();
        // [GIVEN] GLSetup with local currency symbol '$' specified
        LocalCurrencySymbol := UpdateGLSetupLocalCurrencySymbol();
        // [GIVEN] Create G/L Account account "A" and post entry with amount 100
        Amount := LibraryRandom.RandDec(100, 2);
        AccountNo := CreateGLAccountWithNetChange(Amount);
        // [GIVEN] Create account schedule line for account "A" 
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        FinancialReport.Get(AccScheduleName.Name);
        AccScheduleLine.Validate(Totaling, AccountNo);
        AccScheduleLine.Modify();
        // [GIVEN] Create column "C1" with Net Change type
        CreateColumnLayout(ColumnLayout);
        ColumnLayout."Column No." := 'C1';
        ColumnLayout.Modify();
        // [GIVEN] Create column "C2" with formula C1 / 100 * 18 and "Hide Currency Symbol" = Yes
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayout."Column Layout Name");

        ColumnLayout."Column Type" := "Column Layout Type"::Formula;
        ColumnLayout."Column No." := 'C2';
        ColumnLayout.Formula := 'C1 / 100 * 18';
        ColumnLayout.Validate("Hide Currency Symbol", true);
        ColumnLayout.Modify();
        FinancialReport."Financial Report Column Group" := ColumnLayout."Column Layout Name";
        FinancialReport.Modify();
        // [WHEN] Run Account Schedule report with "Show Currency Symbol" = yes
        Commit();
        AccScheduleName.SetRecFilter();
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(false); // Use additional currency amounts
        RunAccountScheduleReportAndLoad(AccScheduleName);

        // [THEN] The report prints "18" without currency symbol
        LibraryReportDataset.AssertElementWithValueExists(
            'ColumnValuesAsText', Format(Round(Amount * 0.18)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanRunFinancialReportEditRowDefinition_WithoutFinancialReportingSetupInGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReports: TestPage "Financial Reports";
        AccountSchedule: TestPage "Account Schedule";
    begin
        // [FEATURE] [Financial Report]
        // [SCENARIO 452575] Financial Report Edit Row Definition should run without General Ledger Setup Financial Reporting definition
        Initialize();

        // [GIVEN] Clear "General Ledger Setup" of Financial Reporting Codes definition
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Cash Flow Stmt", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Retained Earn.", '');
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create "Account Schedule" with at least one line in definition
        // CreateAccScheduleName first creates "Account Schedule" and then creates "Financial Report" with "Account Schedule" as Row Definition ("Financial Report Row Group").
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);

        // [GIVEN] Open "Financial Reports" page
        FinancialReports.OpenView();

        // [GIVEN] Position to created "Financial Report"        
        FinancialReports.GoToKey(AccScheduleName.Name);

        // [WHEN] Run "Edit Row Definition" action
        AccountSchedule.Trap();
        FinancialReports.EditRowGroup.Invoke();

        // [THEN] "Account Schedule" page for "Financial Report Row Group" is opened
        AccountSchedule.CurrentSchedName.AssertEquals(FinancialReports."Financial Report Row Group".Value());
        AccountSchedule.Close();
    end;

    local procedure Initialize()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        FinancialReportMgt.Initialize();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateAccScheduleWithFourLines(var AccountScheduleName: Code[10]; var ColLayoutName: Code[10]; var LineDescription: array[4] of Text; ShowOption: Enum "Acc. Schedule Line Show")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountNo: array[4] of Code[20];
        i: Integer;
    begin
        GLAccountNo[1] := '';
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
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

    local procedure CreateAccScheduleLineWithGLAcc(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Code[10]; GLAccountNo: Code[20]; ShowValue: Enum "Acc. Schedule Line Show")
    begin
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName, AccScheduleLine."Totaling Type"::"Posting Accounts", GLAccountNo);
        AccScheduleLine.Validate(Show, ShowValue);
        AccScheduleLine.Modify(true);
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
        AccScheduleLine.Validate("Row No.", LibraryUtility.GenerateGUID());
        AccScheduleLine.Validate(Description, LibraryUtility.GenerateGUID());
        AccScheduleLine.Validate("Totaling Type", NewTotalingTypeValue);
        AccScheduleLine.Validate(Totaling, NewTotalingValue);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateColumnLayout(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
    end;

    local procedure CreateColumnLayoutLine(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Code[10]; NewColumnTypeValue: Enum "Column Layout Type"; NewFormulaValue: Code[80])
    begin
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName);
        ColumnLayout.Validate("Column No.", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Header", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Type", NewColumnTypeValue);
        ColumnLayout.Validate(Formula, NewFormulaValue);
        ColumnLayout.Modify(true);
    end;

    local procedure CreateColumns(ColumnLayoutName: Record "Column Layout Name"; Formula: Code[80]; NumberOfColumns: Integer)
    var
        ColumnLayout: Record "Column Layout";
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfColumns do
            CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayout."Column Type"::Formula, Formula);
    end;

    local procedure CreateSimpleColumnLayout(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Code[10])
    begin
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName);
        ColumnLayout.Validate("Column No.", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Header", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Type", "Column Layout Type"::"Net Change");
        ColumnLayout.Modify(true);
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
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo, NetChange);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CopyAccountSchedule(SourceAccountScheduleName: Code[10])
    var
        AccountScheduleNames: TestPage "Account Schedule Names";
    begin
        AccountScheduleNames.OpenView();
        AccountScheduleNames.FILTER.SetFilter(Name, SourceAccountScheduleName);
        AccountScheduleNames.CopyAccountSchedule.Invoke();
    end;

    local procedure CopyMultipleAccountSchedule(SourceAccountScheduleName1: Code[10]; SourceAccountScheduleName2: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.SetFilter(Name, StrSubstNo('%1 | %2', SourceAccountScheduleName1, SourceAccountScheduleName2));
        REPORT.RunModal(REPORT::"Copy Account Schedule", true, true, AccScheduleName);
    end;

    local procedure CopyColumnLayout(SourceColumnLayoutName: Code[10])
    var
        ColumnLayoutNames: TestPage "Column Layout Names";
    begin
        Commit();
        ColumnLayoutNames.OpenView();
        ColumnLayoutNames.Filter.SetFilter(Name, SourceColumnLayoutName);
        ColumnLayoutNames.CopyColumnLayout.Invoke();
    end;

    local procedure CopyColumnLayoutFromColumnLayoutPage(SourceColumnLayoutName: Code[10])
    var
        ColumnLayout: TestPage "Column Layout";
    begin
        Commit();
        ColumnLayout.OpenView();
        ColumnLayout.CurrentColumnName.SetValue(SourceColumnLayoutName);
        ColumnLayout.CopyColumnLayout.Invoke();
    end;

    local procedure RunAccountScheduleReport(ScheduleName: Code[10]; ColumnLayoutName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetFinancialReportName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(Format(WorkDate()), '', '', '', '', '', '', '');
        Commit();
        AccountSchedule.Run();
    end;

    local procedure RunAccountScheduleReportWithDims(ScheduleName: Code[10]; ColumnLayoutName: Code[10]; DimensionValue: array[4] of Record "Dimension Value")
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetFinancialReportName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(
          Format(WorkDate()), '', '', '', DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code, DimensionValue[4].Code);
        Commit();
        AccountSchedule.Run();
    end;

    local procedure RunAccountScheduleReportSaveAsExcel(ScheduleName: Code[10]; ColumnLayoutName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetFinancialReportName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(Format(WorkDate()), '', '', '', '', '', '', '');
        AccountSchedule.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure RunExportAccScheduleToExcel(AccScheduleName: Record "Acc. Schedule Name"; DimensionValue: array[4] of Record "Dimension Value")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        AccScheduleLine.SetRange("Dimension 1 Filter", DimensionValue[1].Code);
        AccScheduleLine.SetRange("Dimension 2 Filter", DimensionValue[2].Code);
        AccScheduleLine.SetRange("Dimension 3 Filter", DimensionValue[3].Code);
        AccScheduleLine.SetRange("Dimension 4 Filter", DimensionValue[4].Code);
        RunExportAccSchedule(AccScheduleLine, AccScheduleName);
    end;

    local procedure RunExportAccSchedule(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Record "Acc. Schedule Name")
    var
        FinancialReport: Record "Financial Report";
        ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
    begin
        FinancialReport.Get(AccScheduleName.Name);
        ExportAccSchedToExcel.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ExportAccSchedToExcel.SetOptions(AccScheduleLine, FinancialReport."Financial Report Column Group", false);
        ExportAccSchedToExcel.SetTestMode(true);
        ExportAccSchedToExcel.UseRequestPage(false);
        ExportAccSchedToExcel.Run();
    end;

    [Scope('OnPrem')]
    procedure RunExportAccScheduleWithDimFilter(AccScheduleName: Record "Acc. Schedule Name"; DimFilterValue: array[4] of Code[20])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetFinancialReportName(AccScheduleName.Name);
        AccountSchedule.SetFilters(Format(WorkDate()), '', '', '', DimFilterValue[1], DimFilterValue[2], DimFilterValue[3], DimFilterValue[4]);
        AccountSchedule.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure RunAccountScheduleReportAndLoad(AccScheduleName: Record "Acc. Schedule Name")
    var
        RequestPageXMLDocument: XMLDocument;
        FinancialReportXMLNode: XMLNode;
        NewFinancialReportXMLElement: XmlElement;
        RequestPageXML: Text;
    begin
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Account Schedule", RequestPageXML);
        XmlDocument.ReadFrom(RequestPageXML, RequestPageXMLDocument);
        NewFinancialReportXMLElement := XMLElement.Create('Field');
        NewFinancialReportXMLElement.SetAttribute('name', 'FinancialReportName');
        NewFinancialReportXMLElement.Add(XmlText.Create(AccScheduleName.Name));
        RequestPageXMLDocument.AsXmlNode().SelectSingleNode('//Field[@name=''FinancialReportName'']', FinancialReportXMLNode);
        FinancialReportXMLNode.ReplaceWith(NewFinancialReportXMLElement);
        RequestPageXMLDocument.WriteTo(RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Account Schedule", AccScheduleName, RequestPageXML);
    end;

    local procedure UpdateGLSetupAddReportingCurrency(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateGLSetupLocalCurrencySymbol(): Text[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Local Currency Symbol" := '$';
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."Local Currency Symbol");
    end;

    local procedure VerifyDimensionsAndValueInExcel(DimensionValue: array[4] of Record "Dimension Value")
    begin
        LibraryReportValidation.OpenExcelFile();
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
        FromAccScheduleLine.FindSet();
        ToAccScheduleLine.FindSet();

        repeat
            AssertAccountScheduleLineValuesAreEqual(ToAccScheduleLine, FromAccScheduleLine);
            ToAccScheduleLine.TestField(Show, FromAccScheduleLine.Show);
        until (ToAccScheduleLine.Next() = 0) and (FromAccScheduleLine.Next() = 0);
    end;

    local procedure AssertAccountScheduleLineCopyValuesEqualAccountScheduleLineValuesExceptShow(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line")
    var
        FirstLineIsChecked: Boolean;
    begin
        FromAccScheduleLine.FindSet();
        ToAccScheduleLine.FindSet();

        repeat
            AssertAccountScheduleLineValuesAreEqual(ToAccScheduleLine, FromAccScheduleLine);
            if FirstLineIsChecked then
                ToAccScheduleLine.TestField(Show, FromAccScheduleLine.Show)
            else begin
                ToAccScheduleLine.TestField(Show, ToAccScheduleLine.Show::No);
                Assert.AreNotEqual(FromAccScheduleLine.Show, ToAccScheduleLine.Show, 'The value of Show was not edited in the copy.');
                FirstLineIsChecked := true;
            end;
        until (ToAccScheduleLine.Next() = 0) and (FromAccScheduleLine.Next() = 0);
    end;

    local procedure AssertAccountScheduleLineValuesAreEqual(var ToAccScheduleLine: Record "Acc. Schedule Line"; var FromAccScheduleLine: Record "Acc. Schedule Line")
    begin
        ToAccScheduleLine.TestField("Line No.", FromAccScheduleLine."Line No.");
        ToAccScheduleLine.TestField("Row No.", FromAccScheduleLine."Row No.");
        ToAccScheduleLine.TestField(Description, FromAccScheduleLine.Description);
        ToAccScheduleLine.TestField(Totaling, FromAccScheduleLine.Totaling);
        ToAccScheduleLine.TestField("Totaling Type", FromAccScheduleLine."Totaling Type");
    end;

    local procedure VerifyColumnLayoutNameCopied(ColumnLayoutCopy: Code[10]; ColumnLayoutSource: Code[10])
    var
        FromColumnLayoutName: Record "Column Layout Name";
        ToColumnLayoutName: Record "Column Layout Name";
        FromColumnLayout: Record "Column Layout";
        ToColumnLayout: Record "Column Layout";
    begin
        FromColumnLayoutName.Get(ColumnLayoutSource);
        ToColumnLayoutName.Get(ColumnLayoutCopy);

        ToColumnLayoutName.TestField(Description, FromColumnLayoutName.Description);
        ToColumnLayoutName.TestField("Analysis View Name", FromColumnLayoutName."Analysis View Name");

        FromColumnLayout.SetRange("Column Layout Name", ColumnLayoutSource);
        FromColumnLayout.FindSet();
        repeat
            ToColumnLayout.Get(ColumnLayoutCopy, FromColumnLayout."Line No.");
            ToColumnLayout.TestField("Column No.", FromColumnLayout."Column No.");
            ToColumnLayout.TestField("Column Header", FromColumnLayout."Column Header");
            ToColumnLayout.TestField("Column Type", FromColumnLayout."Column Type");
        until FromColumnLayout.Next() = 0;
    end;

    local procedure CreateColumnLayoutWithName(ColumnHeader: Text[30]): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Column No.", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Header", ColumnHeader);
        ColumnLayout.Modify(true);
        exit(ColumnLayoutName.Name);
    end;

    local procedure OpenAccountScheduleOverviewPage(Name: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        FinancialReports.Overview.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountSchedule(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        AccScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccScheduleName);
        AccountSchedule.AccSchedNam.SetValue(AccScheduleName);
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.Dim1Filter.Lookup();
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
        DimensionValue.FindFirst();
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
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleWithNewNameRequestPageHandler(var CopyAccountSchedule: TestRequestPage "Copy Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        NewAccountScheduleName: Code[10];
    begin
        NewAccountScheduleName := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(AccScheduleName.Name));

        CopyAccountSchedule.NewAccountScheduleName.SetValue(NewAccountScheduleName);
        CopyAccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyColumnLayoutWithNewNameRequestPageHandler(var CopyColumnLayout: TestRequestPage "Copy Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
        NewAccountScheduleName: Code[10];
    begin
        NewAccountScheduleName := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ColumnLayoutName.Name));

        CopyColumnLayout.NewColumnLayout.SetValue(NewAccountScheduleName);
        CopyColumnLayout.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleMissingNewNameRequestPageHandler(var CopyAccountSchedule: TestRequestPage "Copy Account Schedule")
    begin
        CopyAccountSchedule.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OpenOriginalAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(AccScheduleName.Name)));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MakeCopyAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(AccScheduleName.Name)));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ShowNothingAccountSchedulePageHandler(var AccountSchedule: TestPage "Account Schedule")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccountSchedule.CurrentSchedName.AssertEquals(CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(AccScheduleName.Name)));
        AccountSchedule.Show.SetValue(AccScheduleLine.Show::No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetSkipEmptyLinesRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.AccSchedNam.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.ColumnLayoutNames.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.SkipEmptyLines.SetValue(true);
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSkipEmptyLinesShowEmptyAmountTypeRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.AccSchedNam.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.ColumnLayoutNames.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.ShowEmptyAmountTypeCtrl.SetValue(LibraryVariableStorage.DequeueInteger());
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.SkipEmptyLines.SetValue(true);
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetPrintCurrSymbolRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.AccSchedNam.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.ColumnLayoutNames.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.UseAmtsInAddCurr.SetValue(LibraryVariableStorage.DequeueBoolean());
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.ShowCurrencySymbolCtrl.SetValue(true);
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetPrintZeroAmountRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.AccSchedNam.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.ColumnLayoutNames.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.ShowEmptyAmountTypeCtrl.SetValue(LibraryVariableStorage.DequeueInteger());
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.ShowCurrencySymbolCtrl.SetValue(true);
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.OK().Invoke();
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
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyAccountScheduleSuccessMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CopySuccessMsg, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyColumnLayoutSuccessMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CopyColumnLayoutSuccessMsg, Message);
    end;
}

