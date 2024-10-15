codeunit 145011 "General Journals"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('PageReconciliationHandler')]
    [Scope('OnPrem')]
    procedure ReconciliationGeneralJournals()
    var
        GenJnlLn: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        GLAccountNo := LibraryERM.CreateGLAccountNo;
        CreateGenJnlLine(GenJnlLn, GenJnlLn."Account Type"::"G/L Account", GLAccountNo);

        // 2.Exercise
        LibraryVariableStorage.Enqueue(GenJnlLn."Account No.");
        LibraryVariableStorage.Enqueue(GenJnlLn."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJnlLn.Amount);
        RunReconciliation(GenJnlLn);

        // 3. Verify in PageReconciliationHandler
    end;

    local procedure CreateGenJnlLine(var GenJnlLn: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          AccountType, AccountNo, LibraryRandom.RandDec(1000, 2));
    end;

    local procedure RunReconciliation(GenJnlLn: Record "Gen. Journal Line")
    var
        Reconciliation: Page Reconciliation;
    begin
        GenJnlLn.SetRecFilter;
        Reconciliation.SetGenJnlLine(GenJnlLn);
        Reconciliation.Run;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageReconciliationHandler(var Reconciliation: TestPage Reconciliation)
    var
        Amount: Decimal;
        GLAccountNo: Code[20];
        BalGlAccountNo: Code[20];
    begin
        GLAccountNo := CopyStr(LibraryVariableStorage.DequeueText, 1, 20);
        BalGlAccountNo := CopyStr(LibraryVariableStorage.DequeueText, 1, 20);
        Amount := LibraryVariableStorage.DequeueDecimal;
        Reconciliation.First;
        Reconciliation."No.".AssertEquals(GLAccountNo);
        Reconciliation."Net Change in Jnl.".AssertEquals(Amount);
        Reconciliation."Balance after Posting".AssertEquals(Amount);
        Reconciliation.Next;
        Reconciliation."No.".AssertEquals(BalGlAccountNo);
        Reconciliation."Net Change in Jnl.".AssertEquals(-Amount);
        Reconciliation."Balance after Posting".AssertEquals(-Amount);
        Reconciliation.OK.Invoke;
    end;
}

