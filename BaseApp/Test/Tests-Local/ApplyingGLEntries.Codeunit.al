#if not CLEAN19
codeunit 145007 "Applying G/L Entries"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        UnexpectedRemAmtErr: Label 'Unexpected Remaining Amount.';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [Test]
    [HandlerFunctions('ModalApplyGeneralLedgerEntriesHandler,ModalPostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyingGLEntriesPartially()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: array[2] of Code[20];
        GLAccountNo: array[2] of Code[20];
        Amount: Decimal;
        AmountToApply: Decimal;
    begin
        // 1. Setup
        Initialize();

        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        Amount := LibraryRandom.RandDec(1000, 2);
        AmountToApply := LibraryRandom.RandDec(Round(Amount, 1, '<'), 2);

        SelectGenJournalBatch(GenJnlBatch);

        // create G/L Entries
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLn."Document Type"::Invoice,
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[1],
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[2],
          Amount);

        DocumentNo[1] := GenJnlLn."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJnlLn);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[2],
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[1],
          Amount);

        DocumentNo[2] := GenJnlLn."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJnlLn);

        // 2. Exercise
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", GLAccountNo[1]);
        GLEntry.SetRange("Document No.", DocumentNo[1]);
        GLEntry.FindFirst();

        LibraryVariableStorage.Enqueue(DocumentNo[2]);
        LibraryVariableStorage.Enqueue(-AmountToApply);
        ApplyGLEntryFromGLEntry(GLEntry);

        // 3. Verify
        GLEntry.SetRange("Document No.", DocumentNo[1]);
        GLEntry.SetRange("G/L Account No.", GLAccountNo[1]);
        GLEntry.FindFirst();
        GLEntry.CalcFields("Applied Amount");
        GLEntry.TestField(Closed, false);
        GLEntry.TestField("Applied Amount", AmountToApply);
        Assert.AreEqual(Amount - AmountToApply, GLEntry.RemainingAmount, UnexpectedRemAmtErr);
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [Test]
    [HandlerFunctions('RequestPageGLEntryApplyingHandler')]
    [Scope('OnPrem')]
    procedure ApplyingGLEntriesAutomatically()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: array[2] of Code[20];
        GLAccountNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // 1. Setup
        Initialize();

        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        Amount := LibraryRandom.RandDec(1000, 2);

        SelectGenJournalBatch(GenJnlBatch);

        // create G/L Entries
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLn."Document Type"::Invoice,
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[1],
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[2],
          Amount);

        DocumentNo[1] := GenJnlLn."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJnlLn);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[2],
          GenJnlLn."Account Type"::"G/L Account", GLAccountNo[1],
          Amount);

        DocumentNo[2] := GenJnlLn."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJnlLn);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(GLAccountNo[2]);
        ApplyGLEntries;

        // 3. Verify
        GLEntry.SetRange("Document No.", DocumentNo[1]);
        GLEntry.SetRange("G/L Account No.", GLAccountNo[2]);
        GLEntry.FindFirst();
        GLEntry.TestField(Closed, true);

        GLEntry.SetRange("Document No.", DocumentNo[2]);
        GLEntry.SetRange("G/L Account No.", GLAccountNo[2]);
        GLEntry.FindFirst();
        GLEntry.TestField(Closed, true);
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    local procedure ApplyGenJournalLine(var GenJnlLn: Record "Gen. Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJnlLn);
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    local procedure ApplyGLEntryFromGLEntry(var GLEntry: Record "G/L Entry")
    var
        GLEntryPostApplication: Codeunit "G/L Entry -Post Application";
    begin
        GLEntryPostApplication.xApplyEntryformEntry(GLEntry);
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    local procedure ApplyGLEntries()
    begin
        Commit();
        REPORT.Run(REPORT::"G/L Entry Applying");
    end;

    local procedure CreateBankAccountPostingGroup(var BankAccPostingGroup: Record "Bank Account Posting Group"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccPostingGroup);
        BankAccPostingGroup."G/L Account No." := GLAccountNo;
        BankAccPostingGroup.Modify(true);
    end;


    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    local procedure SelectGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch)
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalApplyGeneralLedgerEntriesHandler(var ApplyGeneralLedgerEntries: TestPage "Apply General Ledger Entries")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        ApplyGeneralLedgerEntries.FILTER.SetFilter("Document No.", FieldValue);
        ApplyGeneralLedgerEntries.First;
        LibraryVariableStorage.Dequeue(FieldValue);
        if FieldValue.IsCode then begin
            ApplyGeneralLedgerEntries."Set Applies-to ID".Invoke;
            ApplyGeneralLedgerEntries."Applies-to ID".AssertEquals(FieldValue);
        end;
        if FieldValue.IsDecimal then begin
            ApplyGeneralLedgerEntries."Amount to Apply".SetValue(FieldValue);
            ApplyGeneralLedgerEntries."Post Application".Invoke;
        end;
        ApplyGeneralLedgerEntries.OK.Invoke;
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK.Invoke;
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageGLEntryApplyingHandler(var GLEntryApplying: TestRequestPage "G/L Entry Applying")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        GLEntryApplying.ByAmount.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        GLEntryApplying.Applying.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        GLEntryApplying."G/L Account".SetFilter("No.", FieldValue);
        GLEntryApplying.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
#endif