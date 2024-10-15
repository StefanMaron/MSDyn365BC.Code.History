#pragma warning disable AS0074
#if not CLEAN21
codeunit 141050 "Bank Recon. with Matching"
{
    ObsoleteReason = 'Replaced by Standardized bank deposits and reconciliations feature.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#if not CLEAN21
    Permissions = TableData "Bank Rec. Header" = r;
#endif
#pragma warning restore AS0074
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account] [Bank Account Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        PageNotRefreshedErr: Label '%1 was not refreshed.', Comment = '%1=PageName';
        RecordNotCreatedErr: Label '%1 was not created.', Comment = '%1=TableCaption';
        RecordNotDeletedErr: Label '%1 was not deleted.', Comment = '%1=TableCaption';
        RecordNotFoundErr: Label '%1 was not found.', Comment = '%1=TableCaption';
        WrongFilterErr: Label 'The filter on %1 is wrong.', Comment = '%1=FieldCaption';
        WrongValueErr: Label '%1 has a wrong value.', Comment = '%1=FieldCaption';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        OpenBankStatementPageQst: Label 'Do you want to open the bank account statement?';

    [Test]
    [HandlerFunctions('BankAccountListPageHandler,ConfirmHandlerYes,NewBankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationCardMissingLastStmtNo()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 1] Create New Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] No Bank Acc. Reconciliation records in the database
        // [GIVEN] Bank Account with no value in the Last Statement No. field
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation card is opened

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);
        Assert.IsTrue(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankAccReconciliation.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        ActivateAutoMatchPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No."); // First handler
        LibraryVariableStorage.Enqueue(BankAccount."No."); // Second handler
        LibraryVariableStorage.Enqueue('1'); // Second handler

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.NewRecProcess.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotCreatedErr, BankAccReconciliation.TableCaption()));

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure ActivateAutoMatchPages()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Bank Recon. with Auto. Match" := true;
        GeneralLedgerSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListPageHandler(var BankAccountList: TestPage "Bank Account List")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountList.GotoKey(BankAccountNo);
        BankAccountList.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        if (Question.Contains(OpenBankStatementPageQst)) then
            Reply := false
        else
            Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationPageHandler(var BankAccReconciliation: TestPage "Bank Acc. Reconciliation")
    var
        BankAccountNo: Variant;
        StatementNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(StatementNo);

        BankAccReconciliation.BankAccountNo.AssertEquals(BankAccountNo);
        BankAccReconciliation.StatementNo.AssertEquals(StatementNo);

        BankAccReconciliation.StatementDate.SetValue(WorkDate());
        BankAccReconciliation.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('BankAccountListPageHandler,ConfirmHandlerYes,NewBankRecWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankReciliationHeaderCardMissingLastStmtNo()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 2] Create New Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] No Bank Rec. Header records in the database
        // [GIVEN] Bank Account with no value in the Last Statement No. field
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Worksheet card is opened

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);
        Assert.IsTrue(BankRecHeader.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankRecHeader.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        ActivateLocalPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        BankAccReconciliationList.OpenEdit;
        asserterror BankAccReconciliationList.NewRecProcess.Invoke;

        // Verify
        Assert.ExpectedErrorCode('TestWrapped:CSide');

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure ActivateLocalPages()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Bank Recon. with Auto. Match" := false;
        GeneralLedgerSetup.Modify();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NewBankRecWorksheetPageHandler(var BankRecWorksheet: TestPage "Bank Rec. Worksheet")
    begin
    end;

    [Test]
    [HandlerFunctions('BankAccountListPageHandler,NewBankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationCardWithLastStmtNo()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 3] Create New Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] No Bank Acc. Reconciliation records in the database
        // [GIVEN] Bank Account with a value in the Last Statement No. field
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation card is opened

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);
        Assert.IsTrue(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankAccReconciliation.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := '1';
        BankAccount.Modify();
        ActivateAutoMatchPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No."); // First handler
        LibraryVariableStorage.Enqueue(BankAccount."No."); // Second handler
        LibraryVariableStorage.Enqueue('2'); // Second handler

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.NewRecProcess.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotCreatedErr, BankAccReconciliation.TableCaption()));

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('BankAccountListPageHandler,NewBankRecWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankReciliationHeaderCardWithLastStmtNo()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 4] Create New Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] No Bank Rec. Header records in the database
        // [GIVEN] Bank Account with a value in the Last Statement No. field
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Worksheet card is opened

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);
        Assert.IsTrue(BankRecHeader.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankRecHeader.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := '1';
        BankAccount.Modify();
        ActivateLocalPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        BankAccReconciliationList.OpenEdit;
        asserterror BankAccReconciliationList.NewRecProcess.Invoke;

        // Verify
        Assert.ExpectedErrorCode('TestWrapped:CSide');

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('NewBankAccReconciliationListPageHandler,ConfirmHandlerYes,NewBankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationWithBankAccFilter()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 5] Create New Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] No Bank Acc. Reconciliation records in the database
        // [GIVEN] Bank Account with no value in the Last Statement No. field
        // [WHEN] User clicks the Bank Account Reconciliations action on the Bank Account Card
        // [WHEN] Bank Account No. filter is applied from the Bank Account Card
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation card is opened

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);
        Assert.IsTrue(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankAccReconciliation.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        ActivateAutoMatchPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No."); // First handler
        LibraryVariableStorage.Enqueue(BankAccount."No."); // Second handler
        LibraryVariableStorage.Enqueue('1'); // Second handler

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);
        OpenBankReconciliationList(BankAccountCard."No.".Value);

        // Verify
        Assert.IsFalse(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotCreatedErr, BankAccReconciliation.TableCaption()));

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationListPageHandler(var BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        Assert.AreEqual(BankAccountNo, BankAccReconciliationList.FILTER.GetFilter("Bank Account No."),
          StrSubstNo(WrongFilterErr, BankAccReconciliation.FieldCaption("Bank Account No.")));
        BankAccReconciliationList.NewRecProcess.Invoke;
    end;

    [Test]
    [HandlerFunctions('NewBankAccReconciliationListWithErrorPageHandler,ConfirmHandlerYes,NewBankRecWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure NewBankReconciliationHeaderWithBankAccFilter()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 6] Create New Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] No Bank Rec. Header records in the database
        // [GIVEN] Bank Account with no value in the Last Statement No. field
        // [WHEN] User clicks the Bank Account Reconciliations action on the Bank Account Card
        // [WHEN] Bank Account No. filter is applied from the Bank Account Card
        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Worksheet card is opened

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);
        Assert.IsTrue(BankRecHeader.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankRecHeader.TableCaption()));

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        ActivateLocalPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);
        OpenBankReconciliationList(BankAccountCard."No.".Value);
        // Verify
        Assert.ExpectedErrorCode('TestWrapped:CSide');

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NewBankAccReconciliationListWithErrorPageHandler(var BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        Assert.AreEqual(BankAccountNo, BankAccReconciliationList.FILTER.GetFilter("Bank Account No."),
          StrSubstNo(WrongFilterErr, BankAccReconciliation.FieldCaption("Bank Account No.")));
        asserterror BankAccReconciliationList.NewRecProcess.Invoke;
    end;

    [Test]
    [HandlerFunctions('BankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure EditBankAccReconciliationCard()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 7] Open Bank Acc. Reconciliation Card in Edit Mode
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [WHEN] User clicks the Edit action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation card is opened

        Initialize();

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation,
          BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        // Setup
        ActivateAutoMatchPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.EditRec.Invoke;

        // Verify
        // Implemented in the Page Handler!

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankAccReconciliationPageHandler(var BankAccReconciliation: TestPage "Bank Acc. Reconciliation")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccReconciliation.BankAccountNo.AssertEquals(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('BankRecWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure EditBankReciliationHeaderCard()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 8] Open Bank Reconc. Worksheet Card in Edit Mode
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [WHEN] User clicks the Edit action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Worksheet card is opened

        Initialize();

        // Pre-Setup
        CreateBankAccount(BankAccount);
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccount."No.");

        // Setup
        ActivateLocalPages;

        // Post-Setup
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation, BankRecHeader);

        // Pre-Exercise
        Commit();
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.EditRec.Invoke;

        // Verify
        // Implemented in the Page Handler!

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", CreateReconciliationGLAccount);
        BankAccountPostingGroup.Modify(true);

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"));
        BankAccount.Modify(true);
    end;

    local procedure CreateReconciliationGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Reconciliation Account", true);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateBankAccReconFromBankRecHeader(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankRecHeader: Record "Bank Rec. Header")
    begin
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Bank Reconciliation";
        BankAccReconciliation."Bank Account No." := BankRecHeader."Bank Account No.";
        BankAccReconciliation."Statement No." := BankRecHeader."Statement No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankRecWorksheetPageHandler(var BankRecWorksheet: TestPage "Bank Rec. Worksheet")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankRecWorksheet."Bank Account No.".AssertEquals(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('SuggestBankAccReconLinesReqPageHandler,BankAccountStatementListPageHandler')]
    [Scope('OnPrem')]
    procedure ViewBankAccountStatementCard()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 9] Open Bank Account Statement Card from Bank Account Card
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [WHEN] User clicks the Statements action on the Bank Account
        // [WHEN] User clicks the View action on the Bank Statement List
        // [THEN] Bank Account Statement List is opened
        // [THEN] Bank Account Statement card is opened

        Initialize();

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccount(BankAccReconciliation, BankAccount."No.");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Setup
        ActivateAutoMatchPages;

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);
        BankAccountCard.Statements.Invoke;
        // Verify
        // Implemented in the Page Handler!

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure PayToVendorFromBankAccount(AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalBatch."Bal. Account Type"::"Bank Account", AccountNo, LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ReconcilePaymentToVendorFromBankAccount(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation,
          BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);

        Commit();
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.RunModal();

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliation.Validate("Statement Ending Balance", BankAccReconciliationLine."Statement Amount");
        BankAccReconciliation.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestBankAccReconLinesReqPageHandler(var SuggestBankAccReconLines: TestRequestPage "Suggest Bank Acc. Recon. Lines")
    begin
        SuggestBankAccReconLines.StartingDate.SetValue(WorkDate());
        SuggestBankAccReconLines.EndingDate.SetValue(WorkDate());
        SuggestBankAccReconLines.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankAccountStatementListPageHandler(var BankAccountStatementList: TestPage "Bank Account Statement List")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountStatementList.First;
        BankAccountStatementList."Bank Account No.".AssertEquals(BankAccountNo);
    end;

    local procedure ReconcilePaymentToVendorFromBankAccountNA(var BankRecHeader: Record "Bank Rec. Header"; BankAccountNo: Code[20])
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccountNo);
        BankRecHeader.CalcFields("G/L Balance (LCY)");
        BankRecHeader.Validate("Statement Balance", BankRecHeader."G/L Balance (LCY)");
        BankRecHeader.Modify(true);

        LibraryERM.CreateBankRecLine(BankRecLine, BankRecHeader);
        BankRecLine.Validate(Cleared, true);
        BankRecLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('SuggestBankAccReconLinesReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostBankAccReconciliationFromList()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 11] Post Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] Only one Bank Acc. Reconciliation record exists in the database
        // [WHEN] User clicks the Post action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation is posted
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);

        LibraryERM.CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccount(BankAccReconciliation, BankAccount."No.");

        // Setup
        ActivateAutoMatchPages;

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenView;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.Post.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure PostBankRecHeaderFromList()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 12] Post Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] Only one Bank Rec. Header record exists in the database
        // [WHEN] User clicks the Post action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Header is posted
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);

        CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccountNA(BankRecHeader, BankAccount."No.");

        // Setup
        ActivateLocalPages;

        // Post-Setup
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation, BankRecHeader);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccReconciliationList.OpenView;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.Post.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SuggestBankAccReconLinesReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostBankAccReconciliationFromCard()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccReconciliationCard: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 13] Post Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] Only one Bank Acc. Reconciliation record exists in the database
        // [WHEN] User clicks the Post action on the Bank Acc. Reconciliation card
        // [THEN] Bank Acc. Reconciliation is posted
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);

        LibraryERM.CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccount(BankAccReconciliation, BankAccount."No.");

        // Setup
        ActivateAutoMatchPages;

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationCard.OpenView;
        BankAccReconciliationCard.GotoRecord(BankAccReconciliation);
        BankAccReconciliationCard.Post.Invoke;

        // Verify
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure PostBankRecHeaderFromCard()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 14] Post Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] Only one Bank Rec. Header record exists in the database
        // [WHEN] User clicks the Post action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Header is posted
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);

        CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccountNA(BankRecHeader, BankAccount."No.");

        // Setup
        ActivateLocalPages;

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankRecWorksheet.OpenView;
        BankRecWorksheet.GotoRecord(BankRecHeader);
        BankRecWorksheet.Post.Invoke;

        // Verify
        PostedBankRecHeader.Get(BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SuggestBankAccReconLinesReqPageHandler,ConfirmHandlerYes,BankAccountStatementReportHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintBankAccReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        ReportSelections: Record "Report Selections";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 15] Post & Print Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] Only one Bank Acc. Reconciliation record exists in the database
        // [WHEN] User clicks the Post and Print action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation is posted and printed
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);

        LibraryERM.CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccount(BankAccReconciliation, BankAccount."No.");

        // Setup
        ActivateAutoMatchPages;
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Account Statement");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenView;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.PostAndPrint.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Tear Down
        RestoreReconciliationReports;
    end;

    local procedure DeselectReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt", ReportSelections.Usage::"B.Recon.Test");
        ReportSelections.DeleteAll(true);
    end;

    local procedure AddReconciliationReport(Usage: Enum "Report Selection Usage"; Sequence: Integer; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Format(Sequence);
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure BankAccountStatementReportHandler(var BankAccountStatement: Report "Bank Account Statement")
    var
        FileMgt: Codeunit "File Management";
    begin
        BankAccountStatement.SaveAsPdf(FileMgt.ServerTempFileName('pdf'));
    end;

    local procedure RestoreReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
    end;

    [HandlerFunctions('ConfirmHandlerYes,BankReconciliationReportHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintBankRecHeader()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecHeader: Record "Bank Rec. Header";
        ReportSelections: Record "Report Selections";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 16] Post & Print Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] Only one Bank Rec. Header record exists in the database
        // [WHEN] User clicks the Post and Print action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Header is posted and printed
        // [THEN] Bank Acc. Reconciliation List becomes empty

        Initialize();

        // Pre-Setup
        BankRecHeader.DeleteAll(true);

        CreateBankAccount(BankAccount);
        PayToVendorFromBankAccount(BankAccount."No.");
        ReconcilePaymentToVendorFromBankAccountNA(BankRecHeader, BankAccount."No.");

        // Setup
        ActivateLocalPages;
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");

        // Post-Setup
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation, BankRecHeader);

        // Exercise
        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccReconciliationList.OpenView;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);
        BankAccReconciliationList.PostAndPrint.Invoke;

        // Verify
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
        RestoreReconciliationReports;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationReportHandler(var BankReconciliation: Report "Bank Reconciliation")
    var
        FileMgt: Codeunit "File Management";
    begin
        BankReconciliation.SaveAsPdf(FileMgt.ServerTempFileName('pdf'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableAutoMatchMissingReportSelection()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 17] Activate W1 Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] No reports with Usage equal to B.Stmt (i.e., Bank Statement)
        // [WHEN] User sets the Auto. Match checkbox to checked
        // [THEN] Bank Account Statement report is added to Report Selections

        Initialize();

        // Pre-Setup
        ActivateLocalPages;

        // Setup
        DeselectReconciliationReports;

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", true);

        // Verify
        CheckSelectedReport(ReportSelections.Usage::"B.Stmt", REPORT::"Bank Account Statement");
        CheckSelectedReport(ReportSelections.Usage::"B.Recon.Test", REPORT::"Bank Acc. Recon. - Test");

        // Tear Down
        RestoreReconciliationReports;
    end;

    local procedure CheckSelectedReport(Usage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.SetRange(Sequence, '1');
        ReportSelections.SetRange("Report ID", ReportID);
        Assert.IsFalse(ReportSelections.IsEmpty, StrSubstNo(RecordNotCreatedErr, ReportSelections.TableCaption()));
    end;

    local procedure GetSelectedReport(Usage: Enum "Report Selection Usage"; ReportID: Integer; var ReportSelections: Record "Report Selections"): Boolean
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.SetRange(Sequence, '1');
        ReportSelections.SetRange("Report ID", ReportID);
        ReportSelections.SetAutoCalcFields("Report Caption");
        exit(ReportSelections.FindFirst());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableAutoMatchMissingReportSelection()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 18] Activate Local Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] No reports with Usage equal to B.Stmt (i.e., Bank Statement)
        // [WHEN] User sets the Auto. Match checkbox to unchecked
        // [THEN] Bank Reconciliation report is added to Report Selections

        Initialize();

        // Pre-Setup
        ActivateAutoMatchPages;

        // Setup
        DeselectReconciliationReports;

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", false);

        // Verify
        CheckSelectedReport(ReportSelections.Usage::"B.Stmt", REPORT::"Bank Reconciliation");
        CheckSelectedReport(ReportSelections.Usage::"B.Recon.Test", REPORT::"Bank Rec. Test Report");

        // Tear Down
        RestoreReconciliationReports;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableAutoMatchSingleReportSelected()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
        AutoMatchingEnabled: Boolean;
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 19] Activate W1 Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] Bank Reconciliation report is selected
        // [WHEN] User sets the Auto. Match checkbox to checked
        // [THEN] Bank Account Statement report is added to Report Selections

        Initialize();

        // Pre-Setup
        ActivateLocalPages;

        // Setup
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
        AutoMatchingEnabled := true;
        LibraryVariableStorage.Enqueue(AutoMatchingEnabled);

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", true);

        // Verify
        CheckSelectedReport(ReportSelections.Usage::"B.Stmt", REPORT::"Bank Account Statement");
        CheckSelectedReport(ReportSelections.Usage::"B.Recon.Test", REPORT::"Bank Acc. Recon. - Test");

        // Tear Down
        RestoreReconciliationReports;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableAutoMatchSingleReportSelected()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
        AutoMatchingEnabled: Boolean;
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 20] Activate Local Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] Bank Account Statement report is selected
        // [WHEN] User sets the Auto. Match checkbox to unchecked
        // [THEN] Bank Reconciliation report is added to Report Selections

        Initialize();

        // Pre-Setup
        ActivateAutoMatchPages;

        // Setup
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Account Statement");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Acc. Recon. - Test");
        AutoMatchingEnabled := false;
        LibraryVariableStorage.Enqueue(AutoMatchingEnabled);

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", false);

        // Verify
        CheckSelectedReport(ReportSelections.Usage::"B.Stmt", REPORT::"Bank Reconciliation");
        CheckSelectedReport(ReportSelections.Usage::"B.Recon.Test", REPORT::"Bank Rec. Test Report");

        // Tear Down
        RestoreReconciliationReports;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableAutoMatchMultipleReportsSelected()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 21] Activate W1 Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] Bank Reconciliation report is selected
        // [GIVEN] An additional report is selected
        // [WHEN] User sets the Auto. Match checkbox to checked
        // [THEN] No change to Report Selections

        Initialize();

        // Pre-Setup
        ActivateLocalPages;

        // Setup
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 2, REPORT::"Bank Account - List");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 2, REPORT::"Bank Account - List");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", true);
        // Verify
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt");
        Assert.AreEqual(2, ReportSelections.Count, StrSubstNo(RecordNotCreatedErr, ReportSelections.TableCaption()));

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Recon.Test");
        Assert.AreEqual(2, ReportSelections.Count, StrSubstNo(RecordNotCreatedErr, ReportSelections.TableCaption()));

        // Tear Down
        RestoreReconciliationReports;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableAutoMatchMultipleReportsSelected()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 22] Activate Local Pages without Printing Report Selection
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] Bank Account Statement report is selected
        // [GIVEN] An additional report is selected
        // [WHEN] User sets the Auto. Match checkbox to unchecked
        // [THEN] No change to Report Selections

        Initialize();

        // Pre-Setup
        ActivateAutoMatchPages;

        // Setup
        DeselectReconciliationReports;
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Account Statement");
        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 2, REPORT::"Bank Account - List");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 2, REPORT::"Bank Account - List");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", false);

        // Verify
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt");
        Assert.AreEqual(2, ReportSelections.Count, StrSubstNo(RecordNotCreatedErr, ReportSelections.TableCaption()));

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Recon.Test");
        Assert.AreEqual(2, ReportSelections.Count, StrSubstNo(RecordNotCreatedErr, ReportSelections.TableCaption()));

        // Tear Down
        RestoreReconciliationReports;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteBankAccReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliation3: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 23] Delete Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] More than one Bank Acc. Reconciliation exist
        // [WHEN] User clicks the Delete action on the Bank Acc. Reconciliation List
        // [THEN] Selected Bank Acc. Reconciliation is deleted
        // [THEN] Other Bank Acc. Reconciliations remain on the Bank Acc. Reconciliation List

        Initialize();

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation1,
          BankAccount."No.", BankAccReconciliation1."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation2,
          BankAccount."No.", BankAccReconciliation2."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation3,
          BankAccount."No.", BankAccReconciliation3."Statement Type"::"Bank Reconciliation");

        // Setup
        ActivateAutoMatchPages;

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation2);
        BankAccReconciliationList.DeleteRec.Invoke;

        // Verify
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation3),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation3.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteBankRecHeader()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliation3: Record "Bank Acc. Reconciliation";
        BankRecHeader1: Record "Bank Rec. Header";
        BankRecHeader2: Record "Bank Rec. Header";
        BankRecHeader3: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 24] Delete Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] More than one Bank Rec. Header exist
        // [WHEN] User clicks the Delete action on the Bank Acc. Reconciliation List
        // [THEN] Selected Bank Rec. Header is deleted
        // [THEN] Other Bank Rec. Headers remain on the Bank Acc. Reconciliation List

        Initialize();

        // Pre-Setup
        CreateBankAccount(BankAccount);
        CreateBankRecHeader(BankRecHeader1, BankAccount);
        CreateBankRecHeader(BankRecHeader2, BankAccount);
        CreateBankRecHeader(BankRecHeader3, BankAccount);

        // Setup
        ActivateLocalPages;

        // Post-Setup
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation1, BankRecHeader1);
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation2, BankRecHeader2);
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation3, BankRecHeader3);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation2);
        BankAccReconciliationList.DeleteRec.Invoke;

        // Verify
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation3),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation3.TableCaption()));
    end;

    local procedure CreateBankRecHeader(var BankRecHeader: Record "Bank Rec. Header"; var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccount."No.");
        BankAccount.Validate("Last Statement No.", IncStr(BankAccount."Last Statement No."));
        BankAccount.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBankAccReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 25] Refresh Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] One Bank Acc. Reconciliation exists
        // [GIVEN] Another Bank Acc. Reconciliation created after the Bank Acc. Reconciliation List is opened
        // [WHEN] User clicks the Refresh action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliations get re-fetched from the database

        Initialize();

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation1,
          BankAccount."No.", BankAccReconciliation1."Statement Type"::"Bank Reconciliation");

        // Setup
        ActivateAutoMatchPages;
        BankAccReconciliationList.OpenEdit;

        // Post-Setup
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Pre-Exercise
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation2,
          BankAccount."No.", BankAccReconciliation2."Statement Type"::"Bank Reconciliation");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.RefreshList.Invoke;

        // Verify
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBankAccReconciliationWrongStmtType()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 26] Refresh Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] One Bank Acc. Reconciliation with Statement Type as Bank Reconciliation
        // [GIVEN] Another Bank Acc. Reconciliation with Statement Type as Payment Application
        // [WHEN] User clicks the Refresh action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation with Statement Type as Bank Reconciliation gets re-fetched from the database

        Initialize();

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation1,
          BankAccount."No.", BankAccReconciliation1."Statement Type"::"Bank Reconciliation");

        // Setup
        ActivateAutoMatchPages;
        BankAccReconciliationList.OpenEdit;

        // Post-Setup
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Pre-Exercise
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation2,
          BankAccount."No.", BankAccReconciliation2."Statement Type"::"Payment Application");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.RefreshList.Invoke;

        // Verify
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBankRecHeader()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankRecHeader1: Record "Bank Rec. Header";
        BankRecHeader2: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 27] Refresh Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] One Bank Rec. Header exists
        // [GIVEN] One Bank Rec. Header created after the Bank Acc. Reconciliation List is opened
        // [WHEN] User clicks the Refresh action on the Bank Acc. Reconciliation List
        // [THEN] Bank Rec. Headers get re-fetched from the database

        Initialize();

        // Pre-Setup
        CreateBankAccount(BankAccount);
        CreateBankRecHeader(BankRecHeader1, BankAccount);
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation1, BankRecHeader1);

        // Setup
        ActivateLocalPages;
        BankAccReconciliationList.OpenEdit;

        // Post-Setup
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsFalse(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));

        // Pre-Exercise
        CreateBankRecHeader(BankRecHeader2, BankAccount);
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation2, BankRecHeader2);
        Commit();

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccReconciliationList.RefreshList.Invoke;

        // Verify
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation1),
          StrSubstNo(RecordNotFoundErr, BankAccReconciliation1.TableCaption()));
        Assert.IsTrue(BankAccReconciliationList.GotoRecord(BankAccReconciliation2),
          StrSubstNo(PageNotRefreshedErr, BankAccReconciliationList.Caption));
    end;

    [Test]
    [HandlerFunctions('RefreshBankAccReconciliationListPageHandler')]
    [Scope('OnPrem')]
    procedure RefreshBankAccReconciliationWithFilter()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 28] Refresh Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] One Bank Acc. Reconciliation exists
        // [WHEN] User clicks the Bank Account Reconciliations action on the Bank Account card
        // [WHEN] User clicks the Refresh action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation List gets displayed with the Bank Account No. used as a filter
        // [THEN] Bank Acc. Reconciliations get re-fetched from the database

        Initialize();

        // Setup
        ActivateAutoMatchPages;

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation,
          BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);
        OpenBankReconciliationList(BankAccountCard."No.".Value);

        // Verify
        // Implemented in the Page Handler!

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure RefreshBankAccReconciliationListPageHandler(var BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        Assert.AreEqual(BankAccountNo, BankAccReconciliationList.FILTER.GetFilter("Bank Account No."),
          StrSubstNo(WrongFilterErr, BankAccReconciliation.FieldCaption("Bank Account No.")));
        BankAccReconciliationList.RefreshList.Invoke;
    end;

    [Test]
    [HandlerFunctions('RefreshBankAccReconciliationListPageHandler')]
    [Scope('OnPrem')]
    procedure RefreshBankRecHeaderWithFilter()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 29] Refresh Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] One Bank Rec. Headers exists
        // [WHEN] User clicks the Bank Account Reconciliations action on the Bank Account card
        // [WHEN] User clicks the Refresh action on the Bank Acc. Reconciliation List
        // [THEN] Bank Acc. Reconciliation List gets displayed with the Bank Account No. used as a filter
        // [THEN] Bank Rec. Headers get re-fetched from the database

        Initialize();

        // Setup
        ActivateLocalPages;

        CreateBankAccount(BankAccount);
        CreateBankRecHeader(BankRecHeader, BankAccount);

        // Pre-Exercise
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);
        OpenBankReconciliationList(BankAccountCard."No.".Value);

        // Verify
        // Implemented in the Page Handler!

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ModifiedBankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure RefreshBankAccReconciliationOnModify()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
        StatementEndingBalance: Decimal;
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 30] Refresh Bank Acc. Reconciliation
        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        // [GIVEN] One Bank Acc. Reconciliation exists
        // [WHEN] User clicks the Edit action on the Bank Acc. Reconciliation List
        // [WHEN] User changes a value on the Bank Acc. Reconciliation
        // [WHEN] User closes the Bank Acc. Reconciliation card
        // [THEN] Bank Acc. Reconciliations get re-fetched from the database

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);
        LibraryERM.CreateBankAccount(BankAccount);

        // Setup
        ActivateAutoMatchPages;

        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation,
          BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");

        // Post-Setup
        Commit();

        // Pre-Exercise
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);

        BankAccReconciliationList.StatementDate.AssertEquals(0D);
        BankAccReconciliationList.BalanceLastStatement.AssertEquals(0);
        BankAccReconciliationList.StatementEndingBalance.AssertEquals(0);

        StatementEndingBalance := LibraryRandom.RandDec(1000, 2);
        LibraryVariableStorage.Enqueue(StatementEndingBalance);

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.EditRec.Invoke;

        // Verify
        BankAccReconciliationList.StatementDate.AssertEquals(WorkDate());
        BankAccReconciliationList.BalanceLastStatement.AssertEquals(0);
        BankAccReconciliationList.StatementEndingBalance.AssertEquals(StatementEndingBalance);

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ModifiedBankAccReconciliationPageHandler(var BankAccReconciliation: TestPage "Bank Acc. Reconciliation")
    var
        StatementEndingBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementEndingBalance);

        BankAccReconciliation.StatementDate.SetValue(WorkDate());
        BankAccReconciliation.StatementEndingBalance.SetValue(StatementEndingBalance);
        BankAccReconciliation.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('ModifiedBankRecWorksheetPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure RefreshBankRecHeaderOnModify()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecHeader: Record "Bank Rec. Header";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 31] Refresh Bank Rec. Header
        // [GIVEN] Bank Recon. with Auto. Match checkbox is unchecked on General Ledger Setup
        // [GIVEN] One Bank Rec. Headers exists
        // [WHEN] User clicks the Edit action on the Bank Acc. Reconciliation List
        // [WHEN] User changes a value on the Bank Rec. Header
        // [WHEN] User closes the Bank Rec. Worksheet card
        // [THEN] Bank Acc. Reconciliations get re-fetched from the database

        Initialize();

        // Pre-Setup
        CreateBankAccount(BankAccount);

        // Setup
        ActivateLocalPages;
        CreateBankRecHeader(BankRecHeader, BankAccount);

        // Post-Setup
        CreateBankAccReconFromBankRecHeader(BankAccReconciliation, BankRecHeader);
        Commit();

        // Pre-Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.GotoRecord(BankAccReconciliation);

        BankAccReconciliationList.StatementDate.AssertEquals(WorkDate());
        BankAccReconciliationList.BalanceLastStatement.AssertEquals(0);
        BankAccReconciliationList.StatementEndingBalance.AssertEquals(0);

        // Exercise
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.EditRec.Invoke;

        // Verify
        BankAccReconciliationList.StatementDate.AssertEquals(WorkDate());
        BankAccReconciliationList.BalanceLastStatement.AssertEquals(BankRecHeader.CalculateEndingBalance);
        BankAccReconciliationList.StatementEndingBalance.AssertEquals(BankRecHeader.CalculateEndingBalance);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ModifiedBankRecWorksheetPageHandler(var BankRecWorksheet: TestPage "Bank Rec. Worksheet")
    begin
        BankRecWorksheet.BalanceOnStatement.SetValue(BankRecWorksheet.Difference.Value);
        BankRecWorksheet.RecalculateGLBalance.Invoke;
        BankRecWorksheet.OK.Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountBankAccReconciliations()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliation3: Record "Bank Acc. Reconciliation";
        BankRecHeader: Record "Bank Rec. Header";
        FinanceCue: Record "Finance Cue";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 32] Display Number of Pending Bank Acc. Reconciliations
        // [GIVEN] Two Bank Acc. Reconciliations with Statement Type as Bank Reconciliation
        // [GIVEN] Bank Acc. Reconciliation with Statement Type as Payment Application
        // [WHEN] User starts NAV with Accounting Manager or Bookkeeper role centers
        // [THEN] Number of Bank Acc. Reconciliations shown on Finance Cue equals two

        Initialize();

        // Pre-Setup
        BankAccReconciliation1.DeleteAll(true);
        BankRecHeader.DeleteAll(true);

        // Setup
        ActivateAutoMatchPages;

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation1,
          BankAccount."No.", BankAccReconciliation1."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation2,
          BankAccount."No.", BankAccReconciliation2."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation3,
          BankAccount."No.", BankAccReconciliation3."Statement Type"::"Payment Application");

        // Pre-Exercise
        Commit();

        // Exercise
        LibraryLowerPermissions.SetBanking;
        FinanceCue.Init();
        FinanceCue.CalcFields("Bank Reconciliations to Post", "Bank Acc. Reconciliations");

        // Verify
        Assert.AreEqual(0, FinanceCue."Bank Reconciliations to Post",
          StrSubstNo(WrongValueErr, FinanceCue.FieldCaption("Bank Reconciliations to Post")));
        Assert.AreEqual(2, FinanceCue."Bank Acc. Reconciliations",
          StrSubstNo(WrongValueErr, FinanceCue.FieldCaption("Bank Acc. Reconciliations")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountBankRecHeaders()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecHeader1: Record "Bank Rec. Header";
        BankRecHeader2: Record "Bank Rec. Header";
        FinanceCue: Record "Finance Cue";
    begin
        // [FEATURE] Enable W1 Bank Reconciliation Pages in NA
        // [SCENARIO 33] Display Number of Pending Bank Rec. Headers
        // [GIVEN] Two Bank Rec. Headers
        // [WHEN] User starts NAV with Accounting Manager or Bookkeeper role centers
        // [THEN] Number of Bank Rec. Headers shown on Finance Cue equals one

        Initialize();

        // Pre-Setup
        BankAccReconciliation.DeleteAll(true);
        BankRecHeader1.DeleteAll(true);

        // Setup
        ActivateLocalPages;

        CreateBankAccount(BankAccount);
        CreateBankRecHeader(BankRecHeader1, BankAccount);
        CreateBankRecHeader(BankRecHeader2, BankAccount);

        // Pre-Exercise
        Commit();

        // Exercise
        LibraryLowerPermissions.SetBanking;
        FinanceCue.Init();
        FinanceCue.CalcFields("Bank Reconciliations to Post", "Bank Acc. Reconciliations");

        // Verify
        Assert.AreEqual(2, FinanceCue."Bank Reconciliations to Post",
          StrSubstNo(WrongValueErr, FinanceCue.FieldCaption("Bank Reconciliations to Post")));
        Assert.AreEqual(0, FinanceCue."Bank Acc. Reconciliations",
          StrSubstNo(WrongValueErr, FinanceCue.FieldCaption("Bank Acc. Reconciliations")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedBankRecListFromBankAccountCard()
    var
        BankAccount: Record "Bank Account";
        BankAccountCard: TestPage "Bank Account Card";
        PostedBankRecList: TestPage "Posted Bank Rec. List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 224588] "Posted Bank Reconciliations" opens on button PostedReconciliations from "Bank Account Card"
        Initialize();

        // [GIVEN] Bank Account "A"
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] "Bank Account Card" opened for "A" Bank Account
        BankAccountCard.OpenEdit;
        BankAccountCard.GotoRecord(BankAccount);

        // [WHEN] Click PostedReconciliations action
        PostedBankRecList.Trap;
        BankAccountCard.PostedReconciliations.Invoke;

        // [THEN] "Posted Bank Reconciliations" page opened with filter on "Bank Account No." = "A"
        Assert.AreEqual(BankAccount."No.", PostedBankRecList.FILTER.GetFilter("Bank Account No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeStatementNoInvisible()
    var
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 437832] Action "Change Statement No." is invisible on "Bank Account Reconciliation List" page if GLSetup."Bank Recon. With Auto-match" = No
        Initialize();

        // [GIVEN] GLSetup."Bank Recon. With Auto-match" = No
        ActivateLocalPages();

        // [WHEN] Open "Bank Account Reconciliation List" page
        BankAccReconciliationList.OpenEdit();

        // [THEN] Aciton "Change Statement No." is invisible
        Assert.IsFalse(BankAccReconciliationList.ChangeStatementNo.Visible(), 'Action must be invisible');
    end;

    [Test]
    procedure ChangeStatementNoVisible()
    var
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 437832] Action "Change Statement No." is visible on "Bank Account Reconciliation List" page if GLSetup."Bank Recon. With Auto-match" = Yes
        Initialize();

        // [GIVEN] GLSetup."Bank Recon. With Auto-match" = Yes
        ActivateAutoMatchPages();

        // [WHEN] Open "Bank Account Reconciliation List" page
        BankAccReconciliationList.OpenEdit();

        // [THEN] Aciton "Change Statement No." is invisible
        Assert.IsTrue(BankAccReconciliationList.ChangeStatementNo.Visible(), 'Action must be visible');
    end;

    [Test]
    [HandlerFunctions('BankAccountListPageHandler,NewBankAccReconciliationPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyStmtNoInNewBankAccReconciliationCard()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
    begin
        // [SCENARIO 442279] Check Statement No. is incremented while Creating New Bank Acc. Reconciliation
        Initialize();

        // [GIVEN] No Bank Acc. Reconciliation records in the database
        BankAccReconciliation.DeleteAll(true);
        Assert.IsTrue(BankAccReconciliation.IsEmpty, StrSubstNo(RecordNotDeletedErr, BankAccReconciliation.TableCaption()));

        // [GIVEN] Bank Account with a value in the Last Statement No. field
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := '1';
        BankAccount.Modify();

        // [GIVEN] Bank Recon. with Auto. Match checkbox is checked on General Ledger Setup
        ActivateAutoMatchPages;
        LibraryVariableStorage.Enqueue(BankAccount."No."); // First handler
        LibraryVariableStorage.Enqueue(BankAccount."No."); // Second handler
        LibraryVariableStorage.Enqueue('2'); // Second handler

        // [WHEN] User clicks the New action on the Bank Acc. Reconciliation List
        LibraryLowerPermissions.SetBanking;
        BankAccReconciliationList.OpenEdit;
        BankAccReconciliationList.NewRecProcess.Invoke;

        // [THEN] Bank Acc. Reconciliation card is opened and Verify the Statement No. is incremented
        // Implemented in the Page Handler!

        // Tear Down
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryVariableStorage.Clear();

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos." = '' then begin
            GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos." := LibraryERM.CreateNoSeriesCode;
            GeneralLedgerSetup.Modify();
        end;
    end;

    local procedure OpenBankReconciliationList(No: Code[20])
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationList: Page "Bank Acc. Reconciliation List";
    begin
        BankAccReconciliation.SetRange("Bank Account No.", No);
        BankAccReconciliationList.SetTableView(BankAccReconciliation);
        BankAccReconciliationList.Run();
        if BankAccReconciliationList.Caption <> '' then;
    end;
}

#endif