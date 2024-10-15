codeunit 144049 "VAT Statement Summery Report T"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        VATEntryOneAmount: Decimal;
        VATEntryTwoAmount: Decimal;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportHasNoDataInControls()
    begin
        ExecuteAndSelectTestRow(false, 2, false);

        Assert.AreEqual(-1,
          LibraryReportDataset.FindRow('COMPANYNAME_Control36', CompanyName),
          'Did not expect the company name control to have data');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportHasDataInControls()
    begin
        ExecuteAndSelectTestRow(true, 2, false);

        Assert.AreNotEqual(-1,
          LibraryReportDataset.FindRow('COMPANYNAME_Control36', CompanyName),
          'Expected the company name control to have data');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDoesNotRoundNumbers()
    begin
        Assert.IsTrue(ExecuteAndFindAddNumbers(false), 'Expected to find at least number with decimals');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDoesRoundNumbers()
    begin
        Assert.IsFalse(ExecuteAndFindAddNumbers(true), 'Expected to all amounts to end with ,00');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportOnlyIncludesClosedEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::Closed, VATEntryTwoAmount, 'Expected only closed entries');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportOnlyIncludesOpenEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::Open, VATEntryOneAmount, 'Expected dataset only to include open entries');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportIncludesAllEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::"Open and Closed", VATEntryOneAmount + VATEntryTwoAmount, 'Expected dataset to include open and closed entries');
    end;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Statement Summery Report T");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Statement Summery Report T");

        VATEntryOneAmount := 1101.01; // Has to be a fraction to test rounding
        VATEntryTwoAmount := 1102.02;
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Statement Summery Report T");
    end;

    [Normal]
    local procedure PrepareDeclarationSummaryReport(): Date
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementMonth: Date;
    begin
        VATStatementMonth := CalcDate('<-CM>', WorkDate());
        VATStatementTemplate.FindFirst();
        VATStatementName.FindFirst();
        with VATStatementLine do begin
            SetRange("Line No.", 9990000);
            DeleteAll();
            Init();
            "Statement Template Name" := VATStatementTemplate.Name;
            "Statement Name" := VATStatementName.Name;
            "Line No." := 9990000;
            "Row No." := '110';
            Description := 'Test Line';
            Type := Type::"VAT Entry Totaling";
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "VAT Bus. Posting Group" := 'TEST';
            "VAT Prod. Posting Group" := '';
            "Amount Type" := "Amount Type"::Amount;
            Print := true;
            "Print with" := "Print with"::Sign;
            "Document Type" := "Document Type"::"All except Credit Memo";
            "Print on Official VAT Form" := true;
            Insert();
        end;

        with VATEntry do begin
            if Get(990000) then
                Delete();
            Init();
            "Entry No." := 990000;
            "Posting Date" := WorkDate();
            Amount := VATEntryOneAmount;
            Closed := false;
            "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
            "VAT Bus. Posting Group" := 'TEST';
            "VAT Prod. Posting Group" := '';
            Type := Type::Sale;
            "Document Type" := "Document Type"::Invoice;
            Insert(true);

            if Get(990001) then
                Delete();
            Init();
            "Entry No." := 990001;
            "Posting Date" := WorkDate();
            Type := Type::Sale;
            Amount := VATEntryTwoAmount;
            Closed := true;
            "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
            "VAT Bus. Posting Group" := 'TEST';
            "VAT Prod. Posting Group" := '';
            Type := Type::Sale;
            "Document Type" := "Document Type"::Invoice;
            Insert(true);
        end;

        exit(VATStatementMonth);
    end;

    [Normal]
    local procedure ExecuteAndSelectTestRow(UseLogicalControl: Boolean; VATEntriesType: Enum "VAT Statement Report Selection"; RoundToWholeNumbers: Boolean)
    var
        ReportStartDate: Date;
    begin
        Initialize();

        ReportStartDate := PrepareDeclarationSummaryReport;

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(ReportStartDate);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(UseLogicalControl);
        LibraryVariableStorage.Enqueue(VATEntriesType);
        LibraryVariableStorage.Enqueue(RoundToWholeNumbers);
        LibraryVariableStorage.Enqueue(false);

        RunAndAssertReportHasData;
    end;

    [Normal]
    local procedure ExecuteAndFindAddNumbers(EnqueueRounding: Boolean) FoundOddNumbers: Boolean
    var
        ElementValue: Variant;
        Amount: Decimal;
        I: Integer;
    begin
        ExecuteAndSelectTestRow(false, 2, EnqueueRounding);

        for I := 1 to 13 do begin
            LibraryReportDataset.GetElementValueInCurrentRow(StrSubstNo('TotalAmount_%1_', I), ElementValue);
            Amount := ElementValue;
            if not (Round(Amount, 1) = Amount) then
                FoundOddNumbers := true;
        end;
    end;

    [Normal]
    local procedure ExecuteAndValidateAmount1(VATEntriesType: Integer; AmountToExpect: Decimal; AssertMessage: Text)
    var
        ElementValue: Variant;
    begin
        ExecuteAndSelectTestRow(false, VATEntriesType, false);
        LibraryReportDataset.GetElementValueInCurrentRow('TotalAmount_1_', ElementValue);
        Assert.AreEqual(AmountToExpect, ElementValue, AssertMessage);
    end;

    [Normal]
    local procedure RunAndAssertReportHasData()
    var
        TestStatementLineIndex: Integer;
    begin
        Commit();
        REPORT.Run(REPORT::"VAT Statement Summary", true);

        LibraryReportDataset.LoadDataSetFile;
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount, 'Expected more than one row');

        TestStatementLineIndex := LibraryReportDataset.FindRow('VAT_Statement_Line_Line_No_', 9990000);
        Assert.AreNotEqual(-1, TestStatementLineIndex, 'Expected to find the test statement line');
        LibraryReportDataset.MoveToRow(TestStatementLineIndex + 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationSummaryReportRequestPageHandler(var VATStatementSummary: TestRequestPage "VAT Statement Summary")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.StartDate.SetValue(VariantValue); // Start Date

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.NoOfPeriods.SetValue(VariantValue); // Number of periods

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.ReportErrors.SetValue(VariantValue); // Use logical controls

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.Selection.SetValue(VariantValue); // Include VAT Statements

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.PrintInIntegers.SetValue(VariantValue); // Round whole numbers

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.UseAmtsInAddCurr.SetValue(VariantValue); // Show amounts in add. reporting currency

        VATStatementSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

