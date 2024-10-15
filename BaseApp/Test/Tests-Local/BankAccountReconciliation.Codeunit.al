#if not CLEAN20
codeunit 144015 "Bank Account Reconciliation"
{
    ObsoleteReason = 'Replaced by Standardized bank deposits and reconciliations feature.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    // Test cases of Bank Account Reconciliations.
    // 1. Verify Bank Account Reconciliation Details on Bank Reconciliations Test Report, while executing the Adjustments on Bank Account Reconciliations.
    // 2. Verify last No used on Number series, Create and Post Bank Account Reconciliations with Adjustment Lines.
    // 
    // Covers Test cases: for WI -  336093
    // -------------------------------------------------------------------
    // Test Function Name                                          TFS ID
    // -------------------------------------------------------------------
    // BankReconciliationTestReport                                308102
    // BankRecWithAdjustmentLineLastNoUsedOnNoSeries               298857

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account] [Reconciliation]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        DimMgt: Codeunit DimensionManagement;
        Assert: Codeunit Assert;
        WrongFieldValueErr: Label '%1 not updated correctly.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('BankReconciliationTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankReconciliationTestReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BalanceAccountNo: Code[20];
    begin
        // Verify Bank Account Reconciliation Details on Bank Reconciliations Test Report, while executing the Adjustments on Bank Account Reconciliations.

        // Setup: Create and Post Payment journal, Create Bank Reconciliation with Adjustment Lines.
        Initialize();
        BalanceAccountNo := CreateGeneralJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankReconciliationWithAdjustmentLine(BankRecHeader, BankRecLine, BalanceAccountNo, CreateGLAccount);

        // Exercise.
        LibraryLowerPermissions.SetBanking;
        RunBankReconciliationTestReport(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // Verify: Verify Bank Account Number, Negative Adjustment and Statement Balance on Report - Bank Reconciliations Test Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Bank_Rec__Header__Bank_Account_No__', BankRecHeader."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Negative_Adjustments_____Positive_Bal__Adjustments_', BankRecLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists(
          'Statement_Balance_____Outstanding_Deposits_', BankRecHeader."Statement Balance");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankRecWithAdjustmentLineLastNoUsedOnNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        BalanceAccountNo: Code[20];
        DocumentNo: Code[20];
        OldNoSeriesCode: Code[20];
    begin
        // Verify last No used on Number series, Create and Post Bank Account Reconciliations with Adjustment Lines.

        // Setup: Create Number Series, Create and Post Payment journal, Create Bank Reconciliation with Adjustment Lines.
        Initialize();
        CreateNoSeries(NoSeriesLine);
        DocumentNo := NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", WorkDate(), false);  // FALSE for Modify Series.
        UpdateGeneralLedgerSetup(OldNoSeriesCode, NoSeriesLine."Series Code");
        BalanceAccountNo := CreateGeneralJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankReconciliationWithAdjustmentLine(BankRecHeader, BankRecLine, BalanceAccountNo, CreateGLAccount);

        // Exercise: Post Bank Reconciliation.
        LibraryLowerPermissions.SetBanking;
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post", BankRecHeader);

        // Verify: Verify updated last No used on Number series after Posting Bank Account Reconciliations.
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        NoSeriesLine.TestField("Last No. Used", DocumentNo);

        // TearDown.
        LibraryLowerPermissions.SetO365Full;
        UpdateGeneralLedgerSetup(OldNoSeriesCode, OldNoSeriesCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankRecAdjustmentDimensions()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        BankAccNo: Code[20];
        GLAccNo: Code[20];
        DimSetID: Integer;
    begin
        Initialize();
        BankAccNo := CreateBankAccountWithDimension(DimensionValue);
        GLAccNo := CreateGLAccountWithDimension(DimensionValue2);

        // Exercise: Create Bank Reconciliation with Adjustment Lines.
        LibraryLowerPermissions.SetBanking;
        CreateBankReconciliationWithAdjustmentLine(BankRecHeader, BankRecLine,
          BankAccNo, GLAccNo);

        DimSetID := GetExpectedCombinedDimSetID(BankRecLine, DimensionValue, DimensionValue2);

        Assert.AreEqual(
          DimSetID, BankRecLine."Dimension Set ID", StrSubstNo(WrongFieldValueErr, BankRecLine.FieldCaption("Dimension Set ID")));
    end;

    [Test]
    [HandlerFunctions('BankReconciliationTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBankRecTestReportWithCollapsedDepositExtDocNo()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378134] Check Bank Rec. Test Report with Collapsed Outstanding Deposit
        Initialize();

        // [GIVEN] Create Bank Rec. Line with Collapse Status = Collapsed Deposit and Cleared = FALSE
        InsertBankRecLineCollapsedDeposit(BankRecHeader, false);

        // [WHEN] Run Bank Rec. Test report
        LibraryLowerPermissions.SetBanking;
        RunBankReconciliationTestReport(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // [THEN] "External Document No." = "X" on the dataset Bank Rec. Test Report
        VerifyBankRecLineCollapsedDeposit(BankRecHeader);
    end;

    [HandlerFunctions('PHBankRecTestReport')]
    [Scope('OnPrem')]
    procedure CheckBankRecTestReportWithCollapsedDepositAmount()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378134] Run Bank Rec. Test Report with Collapsed Outstanding Deposit
        Initialize();

        // [GIVEN] Create Bank Rec. Line with Collapse Status = Collapsed Deposit, Amount = 100, and Cleared = FALSE
        InsertBankRecLineCollapsedDeposit(BankRecHeader, false);

        // [WHEN] Run "Bank Rec. Test" report with Amount = 100 and  with "External Document No." = "X"
        // TODO: Uncomment LibraryLowerPermissions.SetBanking;
        RunBankReconciliationTestReport(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // [THEN] Amount = 100 in exported line
        VerifyBankRecLineCollapsedDepositAmount(BankRecHeader);
    end;

    [Test]
    [HandlerFunctions('BankReconciliationTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBankRecTestReportWithCollapsedDepositExtDocNoCleared()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378950] Check Bank Rec. Test Report with Collapsed Deposit Cleared
        Initialize();

        // [GIVEN] Create Bank Rec. Line with Collapse Status = Collapsed Deposit and Cleared = TRUE
        InsertBankRecLineCollapsedDeposit(BankRecHeader, true);

        // [WHEN] Run Bank Rec. Test report
        LibraryLowerPermissions.SetBanking;
        RunBankReconciliationTestReport(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // [THEN] "External Document No." = "X" on the dataset Bank Rec. Test Report
        VerifyBankRecLineCollapsedDepositCleared(BankRecHeader);
    end;

    [HandlerFunctions('PHBankRecTestReport')]
    [Scope('OnPrem')]
    procedure CheckBankRecTestReportWithCollapsedDepositAmountCleared()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 378950] Run Bank Rec. Test Report with Collapsed Deposit Cleared
        Initialize();

        // [GIVEN] Create Bank Rec. Line with Collapse Status = Collapsed Deposit, Amount = 100, and Cleared = TRUE
        InsertBankRecLineCollapsedDeposit(BankRecHeader, true);

        // [WHEN] Run "Bank Rec. Test" report with Amount = 100 and  with "External Document No." = "X"
        // TODO: Uncomment LibraryLowerPermissions.SetBanking;
        RunBankReconciliationTestReport(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // [THEN] Amount = 100 in exported line
        VerifyBankRecLineCollapsedDepositAmount(BankRecHeader);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if not IsInitialized then begin
            LibraryApplicationArea.EnableFoundationSetup();
            IsInitialized := true;
        end;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithDimension(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CreateGLAccount;

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo,
          Dimension.Code, DimensionValue.Code);

        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");

        exit(GLAccountNo);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountWithDimension(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        BankAccountNo: Code[20];
    begin
        BankAccountNo := CreateBankAccount;

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account", BankAccountNo,
          Dimension.Code, DimensionValue.Code);

        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
        exit(BankAccountNo);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount, LibraryRandom.RandDec(10, 2));  // Random value for Amount.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Bal. Account No.");
    end;

    local procedure CreateNoSeries(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);  // Use True for Default Numbers, Manual Numbers and False for Order Date.
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, NoSeries.Code + '000', NoSeries.Code + '999');  // Adding 000 for Starting Number and 999 for Ending Number.
        NoSeriesLine.Modify(true);
    end;

    local procedure CreateAdjustmentBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankRecHeader: Record "Bank Rec. Header"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateBankRecLine(BankRecLine, BankRecHeader);
        BankRecLine.Validate("Account Type", BankRecLine."Account Type"::"Bank Account");
        BankRecLine.Validate("Account No.", BankRecHeader."Bank Account No.");
        BankRecLine.Validate(Amount, -LibraryRandom.RandDec(10, 2));
        BankRecLine.Validate("Bal. Account Type", BankRecLine."Bal. Account Type"::"G/L Account");
        BankRecLine.Validate("Bal. Account No.", BalAccountNo);
        BankRecLine.Modify(true);
    end;

    local procedure CreateBankReconciliationWithAdjustmentLine(var BankRecHeader: Record "Bank Rec. Header"; var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccountNo);
        BankReconciliationProcessLines(BankRecHeader);
        CreateAdjustmentBankRecLine(BankRecLine, BankRecHeader, BalAccountNo);
        UpdateBankRecHeaderStatementBalance(BankRecHeader);
    end;

    local procedure CreateBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankRecHeader: Record "Bank Rec. Header"; DepositCleared: Boolean)
    begin
        with BankRecLine do begin
            Init();
            "Bank Account No." := BankRecHeader."Bank Account No.";
            "Statement No." := BankRecHeader."Statement No.";
            "Record Type" := "Record Type"::Deposit;
            "Line No." := LibraryRandom.RandInt(100);
            Commit();
            Insert(true);
            "Document Type" := 0;
            "Document No." := '';
            "Collapse Status" := "Collapse Status"::"Collapsed Deposit";
            Amount := LibraryRandom.RandDec(100, 2);
            Cleared := DepositCleared;
            "External Document No." := LibraryUtility.GenerateRandomCode(FieldNo("External Document No."), DATABASE::"Bank Rec. Line");
            Modify();
        end;
    end;

    local procedure InsertBankRecLineCollapsedDeposit(var BankRecHeader: Record "Bank Rec. Header"; DepositCleared: Boolean)
    var
        BankRecLine: Record "Bank Rec. Line";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := Format(LibraryRandom.RandInt(100));
        BankAccount.Modify();
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccount."No.");
        CreateBankRecLine(BankRecLine, BankRecHeader, DepositCleared);
    end;

    local procedure UpdateBankRecHeaderStatementBalance(var BankRecHeader: Record "Bank Rec. Header")
    begin
        BankRecHeader.CalcFields("Positive Adjustments", "Negative Bal. Adjustments", "Negative Adjustments", "Positive Bal. Adjustments");
        BankRecHeader.Validate(
          "Statement Balance",
          BankRecHeader."G/L Balance" +
          BankRecHeader."Positive Adjustments" -
          BankRecHeader."Negative Bal. Adjustments" + BankRecHeader."Negative Adjustments" - BankRecHeader."Positive Bal. Adjustments");
        BankRecHeader.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(var OldBankRecAdjDocNos: Code[20]; BankRecAdjDocNos: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldBankRecAdjDocNos := GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos.";
        GeneralLedgerSetup.Validate("Bank Rec. Adj. Doc. Nos.", BankRecAdjDocNos);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure BankReconciliationProcessLines(BankRecHeader: Record "Bank Rec. Header")
    var
        BankRecProcessLines: Report "Bank Rec. Process Lines";
    begin
        // Suggest and Mark Bank Reconciliations lines.
        Clear(BankRecProcessLines);
        BankRecProcessLines.SetDoSuggestLines(true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        BankRecProcessLines.SetDoMarkLines(true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        BankRecProcessLines.SetTableView(BankRecHeader);
        BankRecProcessLines.UseRequestPage(false);
        BankRecProcessLines.Run();
    end;

    local procedure FindBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankRecHeader: Record "Bank Rec. Header")
    begin
        BankRecLine.SetRange("Bank Account No.", BankRecHeader."Bank Account No.");
        BankRecLine.SetRange("Statement No.", BankRecHeader."Statement No.");
        BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Deposit);
        BankRecLine.SetRange("Collapse Status", BankRecLine."Collapse Status"::"Collapsed Deposit");
        BankRecLine.FindFirst();
    end;

    local procedure RunBankReconciliationTestReport(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecTestReport: Report "Bank Rec. Test Report";
    begin
        Commit();  // Commit is required as commit is explicitly used on function Code of Codeunit - Gen. Jnl.-Post Batch and LibraryERM - CreateBankRecLine.
        Clear(BankRecTestReport);
        BankRecHeader.SetRange("Bank Account No.", BankAccountNo);
        BankRecHeader.SetRange("Statement No.", StatementNo);
        BankRecTestReport.SetTableView(BankRecHeader);
        BankRecTestReport.Run();
    end;

    local procedure GetDimensionSetID(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with TempDimSetEntry do begin
            "Dimension Code" := DimensionValue."Dimension Code";
            "Dimension Value Code" := DimensionValue.Code;
            "Dimension Value ID" := DimensionValue."Dimension Value ID";
            Insert();
        end;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetExpectedCombinedDimSetID(BankRecLine: Record "Bank Rec. Line"; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value"): Integer
    var
        DimensionSetIDArr: array[10] of Integer;
    begin
        with BankRecLine do begin
            DimensionSetIDArr[1] := GetDimensionSetID(DimensionValue);
            DimensionSetIDArr[2] := GetDimensionSetID(DimensionValue2);
            exit(DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code"));
        end;
    end;

    local procedure VerifyBankRecLineCollapsedDeposit(BankRecHeader: Record "Bank Rec. Header")
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        LibraryReportDataset.LoadDataSetFile;
        FindBankRecLine(BankRecLine, BankRecHeader);
        LibraryReportDataset.SetRange('OutstandingDeposits_Bank_Account_No_', BankRecHeader."Bank Account No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Outstanding__External_Document_No__', BankRecLine."External Document No.");
    end;

    local procedure VerifyBankRecLineCollapsedDepositCleared(BankRecHeader: Record "Bank Rec. Header")
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        LibraryReportDataset.LoadDataSetFile;
        FindBankRecLine(BankRecLine, BankRecHeader);
        LibraryReportDataset.SetRange('Deposits_Bank_Account_No_', BankRecHeader."Bank Account No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Deposit__External_Document_No_', BankRecLine."External Document No.");
    end;

    local procedure VerifyBankRecLineCollapsedDepositAmount(BankRecHeader: Record "Bank Rec. Header")
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        FindBankRecLine(BankRecLine, BankRecHeader);
        LibraryReportValidation.OpenFile;
        LibraryReportValidation.VerifyCellValueByRef(
          'T', 38, 1, LibraryReportValidation.FormatDecimalValue(BankRecLine.Amount));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationTestReportRequestPageHandler(var BankRecTestReport: TestRequestPage "Bank Rec. Test Report")
    begin
        BankRecTestReport.PrintDetails.SetValue(true);
        BankRecTestReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PHBankRecTestReport(var BankRecTestReport: TestRequestPage "Bank Rec. Test Report")
    begin
        BankRecTestReport.PrintDetails.SetValue(true);
        BankRecTestReport.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;
}

#endif