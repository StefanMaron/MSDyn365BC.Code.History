#if not CLEAN22
codeunit 144003 "ERM Apply GL Entries"
{
    // // [FEATURE] [Apply]
    // 1-2 Verify Balance, Remaining Amount for Fully Applied and Partial Applied GL Entries.
    // 
    // Covers Test Cases for WI - 342253
    // --------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                       TFS ID
    // --------------------------------------------------------------------------------------------------------
    // GLEntryApplicationFull, GLEntryApplicationPartial                                        216878,216879

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RemainingAmountMsg: Label '%1 must be %2 in %3.', Comment = '%1: FieldCaption;%2: FieldValue;%3:TableCaption';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('ApplyGeneralLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryApplicationFull()
    var
        Amount: Decimal;
    begin
        // [SCENARIO] Verify Balance, Remaining Amount for Fully Applied GL Entries.
        Amount := LibraryRandom.RandDec(100, 2);  // Taking Random Amount.
        GLEntryApplication(Amount, -Amount);  // Full Invoice Amount.
    end;

    [Test]
    [HandlerFunctions('ApplyGeneralLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryApplicationPartial()
    var
        Amount: Decimal;
    begin
        // [SCENARIO] Verify Balance,Remaining Amount for Partial Applied GL Entries.
        Amount := LibraryRandom.RandDec(100, 2);  // Taking Random Amount.
        GLEntryApplication(Amount, -Amount / 2);  // Partial Invoice Amount.
    end;

    [Test]
    [HandlerFunctions('ApplyGeneralLedgerEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLEntryPostedAndAppliedInDiffTransaction()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLEntry: Record "G/L Entry";
        GLAccountNoX: Code[20];
        GLAccountNoY: Code[20];
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [Reverse]
        // [SCENARIO 202197] Reverse G/L Entries should unapply related entries first
        Initialize();

        // [GIVEN] Posted G/L Entries:
        // [GIVEN] "Doc1" / G/L Account "X" with Amount = 200
        // [GIVEN] "Doc1" / G/L Account "Y" with Amount = -200
        // [GIVEN] "Doc2" / G/L Account "X" with Amount = -150
        // [GIVEN] "Doc2" / G/L Account "Y" with Amount = 150
        GLAccountNoX := CreateGLAccount;
        GLAccountNoY := CreateGLAccount;
        Amount1 := LibraryRandom.RandDecInRange(10, 20, 2);
        Amount2 := Amount1 / 2;
        SelectGeneralJournalBatch(GenJournalBatch);
        DocumentNo1 := CreateAndPostTwoGLEntries(GenJournalBatch, Amount1, GLAccountNoX, GLAccountNoY);

        // [GIVEN] Posted G/L Entries "Doc2" for G/L Account "X" with Amount = -150 and "Y" with Amount = 150
        DocumentNo2 := CreateAndPostTwoGLEntries(GenJournalBatch, -Amount2, GLAccountNoX, GLAccountNoY);

        // [GIVEN] G/L Entries are applied for both G/L Accounts "X" and "Y"
        LibraryVariableStorage.Enqueue(Amount1 - Amount2); // Enqueue value for ApplyGeneralLedgerEntriesPageHandler.
        LibraryVariableStorage.Enqueue(Amount2 - Amount1); // Enqueue value for ApplyGeneralLedgerEntriesPageHandler.
        ApplyGeneralLedgerEntriesToGLAccount(GLAccountNoX);
        ApplyGeneralLedgerEntriesToGLAccount(GLAccountNoY);
        VerifyRemainingAmountOnDocument(DocumentNo2, 0);

        // [WHEN] Reverse Transaction for "Doc1"
        GLEntry.SetRange("Document No.", DocumentNo1);
        GLEntry.FindFirst();
        LibraryERM.ReverseTransaction(GLEntry."Transaction No.");

        // [THEN] 2 initial entries and 2 reversal entries for "Doc1" are marked as reversed
        GLEntry.SetRange(Reversed, true);
        Assert.RecordCount(GLEntry, 4);

        // [THEN] "Doc2" has "Remaining Amount = 150 in G/L Entries
        VerifyRemainingAmountOnDocument(DocumentNo2, Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEntriesCalculatesBalanceProperlySecondInvokeOnFirstLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        Amount1: Integer;
        Amount2: Integer;
        ActualResult: Integer;
    begin
        // [SCENARIO 225647] When "Apply Entries" is invoked for the first time on page "Apply General Ledger Entries" for two lines 1 & 2 and then invoked for the second time on only 1st line, then field "Balance" is populated with Amount from 2nd line.
        // [SCENARIO 402200] Page cursor remains with same position when invoke "Set Applied-to ID" action
        Initialize();

        Amount1 := LibraryRandom.RandIntInRange(1, 100);
        Amount2 := LibraryRandom.RandIntInRange(1, 100);
        GLAccountNo := CreateGLAccount;

        // [GIVEN] Two General Journal Lines: Line[1].Amount = "XX"; Line[2].Amount = "YY"
        CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::" ", Amount1, GLAccountNo);
        CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::" ", Amount2, GLAccountNo);

        // [WHEN] On page "Apply General Ledger Entries" "Apply Entries" invoked on both lines 1 & 2, which is followed by invoking "Apply Entries" on the 1st line only
        ActualResult := ApplyGeneralLedgerEntriesOnTwoLinesAndThenOnFirstLine(GLAccountNo, Amount1, Amount2);

        // [THEN] On page "Apply General Ledger Entries" Balance = "YY"
        Assert.AreEqual(Amount2, ActualResult, 'Balance is calculated improperly');
    end;

    [Test]
    [HandlerFunctions('ApplyGeneralLedgerEntriesClosePageHandler')]
    [Scope('OnPrem')]
    procedure RunApplyEntriesForGLEntryWithLongDescription()
    var
        GLEntry: Record "G/L Entry";
        GLEntryApplicationBuffer: Record "G/L Entry Application Buffer";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 312667] Description fields of "G/L Entry" and "G/L Entry Application Buffer" tables have the same length.

        // [GIVEN] General Ledger Entry with Descirption of maximum length.
        EntryNo := MockGLEntryWithDescription(LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description)));

        // [GIVEN] Opened General Ledger Entries page.
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));

        // [WHEN] Invoke "Apply Entries".
        GeneralLedgerEntries.ApplyEntries.Invoke;

        // [THEN] Page "Apply General Ledger Entries" is opened without any error.
        // [THEN] Description fields of "G/L Entry" and "G/L Entry Application Buffer" tables have the same length.
        Assert.AreEqual(MaxStrLen(GLEntry.Description), MaxStrLen(GLEntryApplicationBuffer.Description), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply GL Entries");
        LibraryVariableStorage.Clear();
    end;

    local procedure GLEntryApplication(Amount: Decimal; AppliedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // Setup: Create General Ledger Account, Create And Post General Journal.
        Initialize();
        GLAccountNo := CreateGLAccount;
        CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::Invoice, Amount, GLAccountNo);
        CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::Payment, AppliedAmount, GLAccountNo);
        LibraryVariableStorage.Enqueue(Amount + AppliedAmount);  // Enqueue value for ApplyGeneralLedgerEntriesPageHandler.

        // Exercise.
        ApplyGeneralLedgerEntriesToGLAccount(GLAccountNo);

        // Verify: Verify General Ledger Account and Remaining Amount.
        VerifyRemainingAmountOnGLEntry(GenJournalLine."Document Type"::Invoice, GLAccountNo, Amount + AppliedAmount);
    end;

    local procedure ApplyGeneralLedgerEntriesToGLAccount(GLAccountNo: Code[20])
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        GeneralLedgerEntries.ApplyEntries.Invoke;
    end;

    local procedure ApplyGeneralLedgerEntriesOnTwoLinesAndThenOnFirstLine(GLAccountNo: Code[20]; Amount1: Decimal; Amount2: Decimal): Integer
    var
        GeneralLedgerEntriesApply: TestPage "General Ledger Entries Apply";
    begin
        GeneralLedgerEntriesApply.Trap;
        ApplyGeneralLedgerEntriesToGLAccount(GLAccountNo);

        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.SetAppliesToID.Invoke();
        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowAmount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowAppliedAmount.AssertEquals(0);
        GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AssertEquals(Amount1);

        GeneralLedgerEntriesApply.Next();
        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount2);
        GeneralLedgerEntriesApply.SetAppliesToID.Invoke();
        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount2);
        GeneralLedgerEntriesApply.ShowAmount.AssertEquals(Amount2);
        GeneralLedgerEntriesApply.ShowAppliedAmount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AssertEquals(Amount1 + Amount2);

        GeneralLedgerEntriesApply.First();
        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowAmount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowAppliedAmount.AssertEquals(Amount2);
        GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AssertEquals(Amount1 + Amount2);

        GeneralLedgerEntriesApply.SetAppliesToID.Invoke();
        GeneralLedgerEntriesApply.Amount.AssertEquals(Amount1);
        GeneralLedgerEntriesApply.ShowAmount.AssertEquals(0);
        GeneralLedgerEntriesApply.ShowAppliedAmount.AssertEquals(0);
        GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AssertEquals(Amount2);

        exit(GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AsInteger);
    end;

    local procedure CreateAndPostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, DocumentType, Amount, GLAccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", CreateBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostTwoGLEntries(GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal; GLAccountNo1: Code[20]; GLAccountNo2: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", Amount, GLAccountNo1,
          GenJournalLine."Bal. Account Type"::"G/L Account", '');
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", -Amount, GLAccountNo2,
          GenJournalLine."Bal. Account Type"::"G/L Account", '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; GLAccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]): Code[20]
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure MockGLEntryWithDescription(Descirption: Text): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry.Description := CopyStr(Descirption, 1, MaxStrLen(GLEntry.Description));
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure SelectGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure VerifyRemainingAmountOnGLEntry(DocumentType: Enum "Gen. Journal Document Type"; GLAccountNo: Code[20]; RemainingAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          RemainingAmount, GLEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(RemainingAmountMsg, GLEntry.FieldCaption("Remaining Amount"), RemainingAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyRemainingAmountOnDocument(DocumentNo: Code[20]; RemAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Remaining Amount", RemAmount * GLEntry.Amount / Abs(GLEntry.Amount));
        until GLEntry.Next() = 0;
    end;

    [PageHandler]
    procedure ApplyGeneralLedgerEntriesPageHandler(var GeneralLedgerEntriesApply: TestPage "General Ledger Entries Apply")
    var
        ShowTotalAppliedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowTotalAppliedAmount);
        GeneralLedgerEntriesApply.SetAppliesToID.Invoke();
        GeneralLedgerEntriesApply.Next();
        GeneralLedgerEntriesApply.SetAppliesToID.Invoke();
        GeneralLedgerEntriesApply.ShowTotalAppliedAmount.AssertEquals(ShowTotalAppliedAmount);  // Verifying Balance Amount.
        GeneralLedgerEntriesApply.First();
        GeneralLedgerEntriesApply.PostApplication.Invoke();
    end;

    [PageHandler]
    procedure ApplyGeneralLedgerEntriesClosePageHandler(var GeneralLedgerEntriesApply: TestPage "General Ledger Entries Apply")
    begin
        GeneralLedgerEntriesApply.Close();
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
#endif
