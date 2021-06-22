codeunit 134253 "Match Bank Rec. Scenarios"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AddToMatchPartialBRL()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1.5);
        BankAccReconciliationPage.MatchManually.Invoke;
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst;

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last;
        BankAccReconciliationPage.MatchManually.Invoke;

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 2, 2 * Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddToMatchPartialBLE()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 2.5);
        BankAccReconciliationPage.MatchManually.Invoke;
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst;

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last;
        BankAccReconciliationPage.MatchManually.Invoke;

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 2, 2 * Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        BankAccReconciliationPage.MatchManually.Invoke;
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindLast;

        // Exercise: Replace Match.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.StmtLine.GotoRecord(BankAccReconciliationLine);
        BankAccReconciliationPage.ApplyBankLedgerEntries.First;
        BankAccReconciliationPage.MatchManually.Invoke;

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 1, Amount);
        BankAccReconciliationLine.FindFirst;
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        VerifyBalance(BankAccReconciliationPage, BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveManyToMany()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        BankAccReconciliationPage.MatchManually.Invoke;
        BankAccReconciliationPage.StmtLine.Last;
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last;
        BankAccReconciliationPage.MatchManually.Invoke;

        // Exercise: Remove Match.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.StmtLine.First;
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last;
        BankAccReconciliationPage.RemoveMatch.Invoke;

        // Verify.
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindLast;
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        BankAccReconciliationLine.FindFirst;
        VerifyOneToManyMatch(BankAccReconciliation, BankAccReconciliationLine."Statement Line No.", 0, 0);
        VerifyBalance(BankAccReconciliationPage, BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnl()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1.5);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        // For running the report:
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        // For page validation:
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(BankAccReconciliation."Bank Account No.");

        // Exercise: Transfer to Gen Jnl.
        Commit();
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage."Transfer to General Journal".Invoke;

        // Verify: In the page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterMatchedEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);

        // Exercise: Filter.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.NotMatched.Invoke;

        // Verify.
        Assert.AreEqual('<>0', BankAccReconciliationPage.StmtLine.FILTER.GetFilter(Difference), 'Wrong filter.');
        Assert.AreEqual('''''', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement No."), 'Wrong filter.');
        Assert.AreEqual('0', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement Line No."), 'Wrong filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveFilters()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);

        // Exercise: Filter.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.NotMatched.Invoke;
        BankAccReconciliationPage.All.Invoke;

        // Verify.
        Assert.AreEqual('', BankAccReconciliationPage.StmtLine.FILTER.GetFilter(Difference), 'Wrong filter.');
        Assert.AreEqual('', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement No."), 'Wrong filter.');
        Assert.AreEqual('', BankAccReconciliationPage.ApplyBankLedgerEntries.FILTER.GetFilter("Statement Line No."), 'Wrong filter.');
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        Initialize;

        // Setup.
        SetupManualMatch(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        Commit();
        BankAccReconciliationPage.MatchAutomatically.Invoke;
        BankAccReconciliationPage.StatementEndingBalance.SetValue(BankAccReconciliationPage.StmtLine.TotalBalance.AsDEcimal);

        // Exercise: Add to Match.
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationPage.Post.Invoke;

        // Verify.
        VerifyPosting(BankAccReconciliation, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAccAndPositiveAmount()
    begin
        // [SCENARIO 374756] GLEntry."Document Type"=Payment after posting Payment Reconciliation Journal with GLAccount and positive Statement Amount
        // [GIVEN] Payment Reconciliation Journal with GLAccount and positive amount
        // [WHEN] Post Reconciliation Journal
        // [THEN] Posted GLEntry."Document Type" = Payment
        GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(0.01);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAccAndNegativeAmount()
    begin
        // [SCENARIO 374756] GLEntry."Document Type"=Payment after posting Payment Reconciliation Journal with GLAccount and positive Statement Amount
        // [GIVEN] Payment Reconciliation Journal with GLAccount and negative amount
        // [WHEN] Post Reconciliation Journal
        // [THEN] Posted GLEntry."Document Type" = Payment
        GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(-0.01);
    end;

    local procedure GLEntryPaymentDocTypeAfterPostPmtReconJnlWithGLAcc(AmountToApply: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
    begin
        Initialize;

        GLAccountNo := LibraryERM.CreateGLAccountNo;
        CreateBankAccReconLineWithGLAcc(BankAccReconciliation, BankAccReconciliationLine, GLAccountNo, AmountToApply);
        CreatePaymentApplication(BankAccReconciliationLine, AmountToApply);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        VerifyGLEntryDocType(GLAccountNo, BankAccReconciliation."Statement No.", GLEntry."Document Type"::Payment);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match Bank Rec. Scenarios");
        LibraryApplicationArea.EnableFoundationSetup;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Match Bank Rec. Scenarios");

        LibraryERMCountryData.UpdateLocalData;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateLocalPostingSetup;
        LibraryVariableStorage.Clear;

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Match Bank Rec. Scenarios");
    end;

    local procedure CreatePaymentApplication(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AmountToApply: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        with AppliedPaymentEntry do begin
            Init;
            "Statement Type" := BankAccReconLine."Statement Type";
            "Bank Account No." := BankAccReconLine."Bank Account No.";
            "Statement No." := BankAccReconLine."Statement No.";
            "Statement Line No." := BankAccReconLine."Statement Line No.";
            "Account Type" := BankAccReconLine."Account Type";
            "Account No." := BankAccReconLine."Account No.";
            "Applied Amount" := AmountToApply;
            Insert;
        end;

        BankAccReconLine."Applied Amount" := AmountToApply;
        BankAccReconLine.Modify();
    end;

    local procedure CreateBankAccReconLineWithGLAcc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; GLAccountNo: Code[20]; StmtAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        with BankAccReconciliationLine do begin
            Validate("Transaction Date", WorkDate);
            Validate("Account Type", "Account Type"::"G/L Account");
            Validate("Account No.", GLAccountNo);
            Validate(Description, "Account No.");
            Validate("Statement Amount", StmtAmount);
            Modify;
        end;
    end;

    local procedure CreateBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Bank Account No.", BankAccountNo);
        BankAccReconciliation.Validate("Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliation.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation"));
        BankAccReconciliation.Validate("Statement Date", WorkDate);
        BankAccReconciliation.Insert(true);
    end;

    local procedure SetupManualMatch(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; var ExpectedAmount: Decimal; MatchFactor: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        "count": Integer;
    begin
        ExpectedAmount := LibraryRandom.RandDec(100, 2);

        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        for count := 1 to 2 do begin
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -ExpectedAmount);
            GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
            GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        for count := 1 to 2 do begin
            LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
            BankAccReconciliationLine.Validate(Type, BankAccReconciliationLine.Type::"Bank Account Ledger Entry");
            BankAccReconciliationLine.Validate("Statement Amount", MatchFactor * ExpectedAmount);
            BankAccReconciliationLine.Modify(true);
        end;

        BankAccReconciliationPage.OpenEdit;
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.First;
        BankAccReconciliationPage.ApplyBankLedgerEntries.First;
    end;

    local procedure VerifyOneToManyMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryMatches: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(ExpBankEntryMatches, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(ExpBankEntryMatches, BankAccountLedgerEntry.Count, 'Wrong no of applied entries.');
    end;

    local procedure VerifyBalance(var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; BankAccNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        BankAccount.CalcFields(Balance, "Total on Checks");
        Assert.AreEqual(BankAccount.Balance, BankAccReconciliationPage.ApplyBankLedgerEntries.Balance.AsDEcimal, 'Wrong acc. balance');
        Assert.AreEqual(BankAccount."Total on Checks", BankAccReconciliationPage.ApplyBankLedgerEntries.CheckBalance.AsDEcimal,
          'Wrong check balance');
        Assert.AreEqual(BankAccount.Balance + BankAccount."Total on Checks",
          BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.AsDEcimal, 'Wrong remaining balance');
    end;

    local procedure VerifyPosting(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpEntriesNo: Integer)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Closed);
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Remaining Amount", 0);
        BankAccountLedgerEntry.SetRange(Open, false);
        Assert.AreEqual(ExpEntriesNo, BankAccountLedgerEntry.Count, 'Wrong no of bank entries.');

        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty, 'There should be no entries left.');

        asserterror BankAccReconciliation.Find;
    end;

    local procedure VerifyGLEntryDocType(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedDocType: Option)
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("G/L Account No.", GLAccountNo);
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        DummyGLEntry.SetRange("Document Type", ExpectedDocType);
        Assert.RecordIsNotEmpty(DummyGLEntry);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToGenJnlReqPageHandler(var TransBankRecToGenJnl: TestRequestPage "Trans. Bank Rec. to Gen. Jnl.")
    var
        TemplateName: Variant;
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Template Name""".SetValue(TemplateName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Batch Name""".SetValue(BatchName);
        TransBankRecToGenJnl.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandler(var GeneralJournal: TestPage "General Journal")
    var
        GenJnlLine: Record "Gen. Journal Line";
        BatchName: Variant;
        BankAccNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        LibraryVariableStorage.Dequeue(BankAccNo);
        GeneralJournal.CurrentJnlBatchName.AssertEquals(BatchName);
        GeneralJournal."Bal. Account Type".AssertEquals(GenJnlLine."Bal. Account Type"::"Bank Account");
        GeneralJournal."Bal. Account No.".AssertEquals(BankAccNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MatchRecLinesReqPageHandler(var MatchBankAccReconciliation: TestRequestPage "Match Bank Entries")
    begin
        MatchBankAccReconciliation.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

