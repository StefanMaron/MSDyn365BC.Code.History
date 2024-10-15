codeunit 142056 "UT REP Bank Reconciliation"
{
    // Validate feature Bank Reconciliation.
    //  1. Verify values updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
    //  2. Verify error text value updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
    //  3. Verify Bank Account No. on Bank Reconciliation Report after creating Posted Bank Rec. Header and Line.
    //  4. Verify Bank Account No. on Bank Account - Reconcile Report after creating Bank Account Ledger Entry.
    //  5. Purpose of the test is to validate Push Action for Page 10120 Bank Rec.Worksheet.
    // 
    //  Covers Test Cases for WI - 336180,336609
    //  -----------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                             TFS ID
    //  -----------------------------------------------------------------------------------------------------
    //  OnAfterGetRecordAdjustmentBankRecTest, OnAfterGetRecordBankRecHeaderBankRecTest   171129,171130,171131
    //  OnAfterGetRecordPostedBankRecHeaderPositiveTrueBankReconciliation                 266821
    //  OnAfterGetRecordPostedBankRecHeaderPositiveFalseBankReconciliation                266821
    //  OnAfterGetRecordBankAccountLedgerEntryBankAccountReconcile                        266821
    // 
    //  Covers Test Cases for WI - 338943
    //  -----------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                             TFS ID
    //  -----------------------------------------------------------------------------------------------------
    //  ValidateTestReportActionOnPageBankRecWorkSheet

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        AdjustmentBankAccountNoTxt: Label 'Adjustments_Bank_Account_No_';
        AdjustmentAmountTxt: Label 'Adjustments_Amount_Control1020131';
        WrongFilterSetErr: Label 'Wrong Filter value on Report request form';

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAdjustmentBankRecTest()
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate trigger Adjustment - OnAfterGetRecord of Report 10407.

        // Setup.
        Initialize();
        CreateBankReconciliation(BankRecLine);

        // Exercise.
        REPORT.Run(REPORT::"Bank Rec. Test Report");

        // Verify: Verify values updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(AdjustmentBankAccountNoTxt, BankRecLine."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists(AdjustmentAmountTxt, BankRecLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankRecHeaderBankRecTest()
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate trigger Bank Rec. Header - OnAfterGetRecord of Report 10407.

        // Setup.
        Initialize();
        CreateBankReconciliation(BankRecLine);

        // Exercise.
        REPORT.Run(REPORT::"Bank Rec. Test Report");

        // Verify: Verify error text value updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', 'Warning!  ' + 'Statement date must be entered!');
    end;

    [Test]
    [HandlerFunctions('BankReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPostedBankRecHeaderPositiveTrueBankReconciliation()
    begin
        // Positive True is used to calculate Positive Adjustment.
        OnAfterGetRecordPostedBankRecHeaderBankReconciliation(true);
    end;

    [Test]
    [HandlerFunctions('BankReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPostedBankRecHeaderPositiveFalseBankReconciliation()
    begin
        // Positive False is used to calculate Negative Adjustment.
        OnAfterGetRecordPostedBankRecHeaderBankReconciliation(false);
    end;

    local procedure OnAfterGetRecordPostedBankRecHeaderBankReconciliation(Positive: Boolean)
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to validate Bank Rec. Header - OnAfterGetRecord trigger of Report ID - 10408.
        // Setup: Create Posted Bank Rec. Document.
        Initialize();
        CreatePostedBankRecDocument(PostedBankRecHeader, Positive);
        Commit();  // Codeunit 10124 Bank-Rec Printed - On Run trigger Call commit.

        // Exercise.
        REPORT.Run(REPORT::"Bank Reconciliation");  // Opens BankReconciliationRequestPageHandler.

        // Verify: Verify Bank Account No. after report generation.
        PostedBankRecHeader.CalcFields("Positive Adjustments", "Negative Adjustments");
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Bank_Rec__Header__Bank_Account_No__', PostedBankRecHeader."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Bank_Rec__Header__Positive_Adjustments_', PostedBankRecHeader."Positive Adjustments");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Bank_Rec__Header__Negative_Adjustments_', PostedBankRecHeader."Negative Adjustments");
    end;

    [Test]
    [HandlerFunctions('BankAccountReconcileRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountLedgerEntryBankAccountReconcile()
    var
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Ledger Entry - OnAfterGetRecord trigger of Report ID - 10409.
        // Setup: Create Bank Account Ledger Entry.
        Initialize();
        BankAccountNo := CreateBankAccountLedgerEntry;

        // Exercise.
        REPORT.Run(REPORT::"Bank Account - Reconcile");  // Opens BankAccountReconcileRequestPageHandler;

        // Verify: Verify Bank Account No. after report generation.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_BankAccount', BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateTestReportActionOnPageBankRecWorkSheet()
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate Push Action for Page 10120 Bank Rec.Worksheet.
        // Setup.
        Initialize();
        CreateBankReconciliation(BankRecLine);

        // Pre-Exercise
        SetBankReconciliationReports;

        // Exercise.
        OpenPageBankRecWorkSheetTestReport(BankRecLine."Bank Account No.");

        // Verify: Verify values updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(AdjustmentBankAccountNoTxt, BankRecLine."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists(AdjustmentAmountTxt, BankRecLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BankReconciliationTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankRecTestReportFiltersCalledFromBankRecWorksheet()
    var
        BankRecLine1: Record "Bank Rec. Line";
        BankRecLine2: Record "Bank Rec. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 362540] Filters on Bank Rec. Test Report set according to page Bank Reconciliation Worksheet from which report is called.
        Initialize();

        // [GIVEN] Bank Reconciliations X and Y.
        CreateBankReconciliation(BankRecLine1);
        LibraryVariableStorage.Clear();
        CreateBankReconciliation(BankRecLine2);
        LibraryVariableStorage.Enqueue(BankRecLine2."Statement No.");

        // [WHEN] Bank Rec. Test Report called from Bank Reconciliation Y Page
        OpenPageBankRecTestReport(BankRecLine2."Bank Account No.");

        // [THEN] Report request page filters set to Bank Account No. and Statement No. of Bank Reconciliation Y.
        // checked in BankReconciliationTestReportRequestPageHandler
    end;

    [HandlerFunctions('BankReconciliationExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedBankRecLineWithEmptyDocumentNoIsVisibleInDepositsAndOutDeposits()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedBankRecLine2: Record "Posted Bank Rec. Line";
    begin
        // [SCENARIO 260490] Stan runs "Bank Reconciliation" report. Posted Bank Reconciliation Lines with empty "Document No." are visible in the Deposits and Outstanding deposits sections.
        Initialize();

        // [GIVEN] Two Posted Bank Reconciliation Lines with empty "Document No." field, "Record Type" = Deposit. For the first line Cleared = TRUE, for the second line Cleared = FALSE.
        MockPostedBankRecHeader(PostedBankRecHeader, LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);
        MockPostedBankRecLine(
          PostedBankRecLine, PostedBankRecHeader."Bank Account No.", PostedBankRecHeader."Statement No.",
          PostedBankRecLine."Record Type"::Deposit, 0, '', 0, '', LibraryRandom.RandText(50), LibraryRandom.RandDec(100, 2), true);
        MockPostedBankRecLine(
          PostedBankRecLine2, PostedBankRecHeader."Bank Account No.", PostedBankRecHeader."Statement No.",
          PostedBankRecLine2."Record Type"::Deposit, 0, '', 0, '', LibraryRandom.RandText(50), LibraryRandom.RandDec(100, 2), false);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();

        // [WHEN] Run "Bank Reconciliation" report, "Print Deposits" and "Print Outstanding Deposits" flags are set.
        RunBankReconciliationReport(
          PostedBankRecHeader."Bank Account No.", PostedBankRecHeader."Statement No.",
          true, false, true, false, false, true);

        // [THEN] Lines with empty "Document No." are visible in the Deposits/Outstanding Deposits sections.
        // [THEN] Header and footer of the these sections are visible.
        VerifyPostedBankRecLineVisible(PostedBankRecLine, 32, 34);
        LibraryReportValidation.VerifyCellValue(33, 1, 'Deposits');
        LibraryReportValidation.VerifyCellValue(35, 1, 'Total Deposits');

        VerifyPostedBankRecLineVisible(PostedBankRecLine2, 32, 37);
        LibraryReportValidation.VerifyCellValue(36, 1, 'Outstanding Deposits');
        LibraryReportValidation.VerifyCellValue(38, 1, 'Total Outstanding Deposits');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler,BankAccountReconcileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountReconcileForPaymentWithCheck()
    var
        BankAccount: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        Amount: Integer;
    begin
        // [SCENARIO 375775] Check Amount is negative in report "Bank Account - Reconcile". 
        Initialize();

        // [GIVEN] Bank Account "B" with Last Check No.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", BankAccount."No.");
        BankAccount.Modify(true);

        // [GIVEN] Payment Journal line with Amount = 100, "Bal. Account No" = "B" and "Bank Payment Type" = "Computer Check".
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        Amount := LibraryRandom.RandInt(100);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.", Amount);
        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Computer Check");
        GenJnlLine.Modify(true);

        // [GIVEN] Check printed for Payment Journal line.
        Commit();
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        REPORT.Run(REPORT::"Check", true, true, GenJnlLine);

        // [GIVEN] Payment Journal Line posted.
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Report "Bank Account - Reconcile" is run for Bank Account "B".
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        REPORT.Run(REPORT::"Bank Account - Reconcile");

        // [THEN] In result dataset Amount_CheckLedgEntry = -100, WithdrawAmount = -100.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_CheckLedgEntry', -Amount);
        LibraryReportDataset.AssertElementWithValueExists('WithdrawAmount', -Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankReconciliation(var BankRecLine: Record "Bank Rec. Line")
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        BankRecHeader."Bank Account No." := CreateBankAccount;
        BankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        BankRecHeader.Insert();

        // Create Bank Rec. Line.
        BankRecLine."Record Type" := BankRecLine."Record Type"::Adjustment;
        BankRecLine.Cleared := true;
        BankRecLine."Cleared Amount" := LibraryRandom.RandDec(10, 2);
        BankRecLine."Statement No." := BankRecHeader."Statement No.";
        BankRecLine."Bank Account No." := BankRecHeader."Bank Account No.";
        BankRecLine.Amount := LibraryRandom.RandDec(10, 2);
        BankRecLine.Insert();
        LibraryVariableStorage.Enqueue(BankRecLine."Bank Account No.");  // Enqueue values for BankRecTestReportRequestPageHandler.
    end;

    local procedure CreatePostedBankRecDocument(var PostedBankRecHeader: Record "Posted Bank Rec. Header"; Positive: Boolean)
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        PostedBankRecHeader."Bank Account No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader.Insert();
        PostedBankRecLine."Bank Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine."Statement No." := PostedBankRecHeader."Statement No.";
        PostedBankRecLine."Record Type" := PostedBankRecLine."Record Type"::Adjustment;
        PostedBankRecLine."Account Type" := PostedBankRecLine."Account Type"::"Bank Account";
        PostedBankRecLine."Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine.Amount := LibraryRandom.RandDec(10, 2);
        PostedBankRecLine.Positive := Positive;
        PostedBankRecLine.Insert();

        // Enqueue required inside BankReconciliationRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostedBankRecHeader."Bank Account No.");
    end;

    local procedure CreateBankAccountLedgerEntry(): Code[20]
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountLedgerEntry2: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry2.FindLast();
        BankAccountLedgerEntry."Entry No." := BankAccountLedgerEntry2."Entry No." + 1;
        BankAccountLedgerEntry."Bank Account No." := CreateBankAccount;
        BankAccountLedgerEntry."Document Type" := BankAccountLedgerEntry."Document Type"::Payment;
        BankAccountLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);

        // Enqueue required inside BankAccountReconcileRequestPageHandler.
        LibraryVariableStorage.Enqueue(BankAccountLedgerEntry."Bank Account No.");
        exit(BankAccountLedgerEntry."Bank Account No.");
    end;

    local procedure MockPostedBankRecHeader(var PostedBankRecHeader: Record "Posted Bank Rec. Header"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        PostedBankRecHeader.Init();
        PostedBankRecHeader."Bank Account No." := BankAccountNo;
        PostedBankRecHeader."Statement No." := StatementNo;
        PostedBankRecHeader.Insert();
    end;

    local procedure MockPostedBankRecLine(var PostedBankRecLine: Record "Posted Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20]; RecordType: Option; DocumentType: Option; DocumentNo: Code[20]; AccountType: Option; AccountNo: Code[20]; Description: Text; Amount: Decimal; Cleared: Boolean)
    var
        PostedBankRecLine2: Record "Posted Bank Rec. Line";
        LineNo: Integer;
    begin
        PostedBankRecLine2.Reset();
        PostedBankRecLine2.SetRange("Bank Account No.", BankAccountNo);
        PostedBankRecLine2.SetRange("Statement No.", StatementNo);
        PostedBankRecLine2.SetRange("Record Type", RecordType);
        if PostedBankRecLine2.FindLast() then;
        LineNo := PostedBankRecLine2."Line No." + 10000;

        PostedBankRecLine.Init();
        PostedBankRecLine."Bank Account No." := BankAccountNo;
        PostedBankRecLine."Statement No." := StatementNo;
        PostedBankRecLine."Line No." := LineNo;
        PostedBankRecLine."Record Type" := RecordType;
        PostedBankRecLine."Posting Date" := LibraryRandom.RandDate(10);
        PostedBankRecLine."Document Type" := DocumentType;
        PostedBankRecLine."Document No." := DocumentNo;
        PostedBankRecLine."Account Type" := AccountType;
        PostedBankRecLine."Account No." := AccountNo;
        PostedBankRecLine.Description := CopyStr(Description, 1, MaxStrLen(PostedBankRecLine.Description));
        PostedBankRecLine.Amount := Amount;
        PostedBankRecLine.Cleared := Cleared;
        PostedBankRecLine.Insert();
    end;

    local procedure OpenPageBankRecWorkSheetTestReport(BankAccountNo: Code[20])
    var
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        BankRecWorksheet.TestReport.Invoke;
        BankRecWorksheet.Close();
    end;

    local procedure OpenPageBankRecTestReport(BankAccountNo: Code[20])
    var
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        BankRecWorksheet.BankRecTestReport.Invoke;
        BankRecWorksheet.Close();
    end;

    local procedure SetBankReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt", ReportSelections.Usage::"B.Recon.Test");
        ReportSelections.DeleteAll();

        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
    end;

    local procedure AddReconciliationReport(Usage: Option; Sequence: Integer; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Format(Sequence);
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure RunBankReconciliationReport(BankAccountNo: Code[20]; StatementNo: Code[20]; PrintDetails: Boolean; PrintChecks: Boolean; PrintDeposits: Boolean; PrintAdj: Boolean; PrintOutChecks: Boolean; PrintOutDeposits: Boolean)
    begin
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(StatementNo);
        LibraryVariableStorage.Enqueue(PrintDetails);
        LibraryVariableStorage.Enqueue(PrintChecks);
        LibraryVariableStorage.Enqueue(PrintDeposits);
        LibraryVariableStorage.Enqueue(PrintAdj);
        LibraryVariableStorage.Enqueue(PrintOutChecks);
        LibraryVariableStorage.Enqueue(PrintOutDeposits);
        REPORT.Run(REPORT::"Bank Reconciliation");
    end;

    local procedure VerifyPostedBankRecLineVisible(PostedBankRecLine: Record "Posted Bank Rec. Line"; TableHeaderRowNo: Integer; LineRowNo: Integer)
    var
        DescriptionColNo: Integer;
        AmountColNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile;
        DescriptionColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea('Description', Format(TableHeaderRowNo), '');
        AmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea('Amount', Format(TableHeaderRowNo), '');

        LibraryReportValidation.VerifyCellValue(LineRowNo, DescriptionColNo, PostedBankRecLine.Description);
        LibraryReportValidation.VerifyCellValue(LineRowNo, AmountColNo, Format(PostedBankRecLine.Amount));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecTestReportRequestPageHandler(var BankRecTestReport: TestRequestPage "Bank Rec. Test Report")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankRecTestReport."Bank Rec. Header".SetFilter("Bank Account No.", BankAccountNo);
        BankRecTestReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationRequestPageHandler(var BankReconciliation: TestRequestPage "Bank Reconciliation")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankReconciliation."Posted Bank Rec. Header".SetFilter("Bank Account No.", BankAccountNo);
        BankReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationExcelRequestPageHandler(var BankReconciliation: TestRequestPage "Bank Reconciliation")
    var
        FileName: Variant;
    begin
        FileName := LibraryVariableStorage.DequeueText;
        BankReconciliation."Posted Bank Rec. Header".SetFilter("Bank Account No.", LibraryVariableStorage.DequeueText);
        BankReconciliation."Posted Bank Rec. Header".SetFilter("Statement No.", LibraryVariableStorage.DequeueText);
        BankReconciliation.PrintDetails.SetValue(LibraryVariableStorage.DequeueBoolean);  // PrintDetails
        BankReconciliation.PrintChecks.SetValue(LibraryVariableStorage.DequeueBoolean);
        BankReconciliation.PrintDeposits.SetValue(LibraryVariableStorage.DequeueBoolean);
        BankReconciliation.PrintAdj.SetValue(LibraryVariableStorage.DequeueBoolean);
        BankReconciliation.PrintOutChecks.SetValue(LibraryVariableStorage.DequeueBoolean);
        BankReconciliation.PrintOutDeposits.SetValue(LibraryVariableStorage.DequeueBoolean);
        BankReconciliation.SaveAsExcel(FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountReconcileRequestPageHandler(var BankAccountReconcile: TestRequestPage "Bank Account - Reconcile")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankAccountReconcile."Bank Account".SetFilter("No.", No);
        BankAccountReconcile.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationTestReportRequestPageHandler(var BankRecTestReport: TestRequestPage "Bank Rec. Test Report")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText,
          BankRecTestReport."Bank Rec. Header".GetFilter("Bank Account No."),
          WrongFilterSetErr);
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText,
          BankRecTestReport."Bank Rec. Header".GetFilter("Statement No."),
          WrongFilterSetErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        Check.BankAccount.SetValue(LibraryVariableStorage.DequeueText());
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

