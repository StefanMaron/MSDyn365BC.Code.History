#if not CLEAN17
codeunit 145002 "Balance Sheet Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1=FIELDCAPTION,%2=Amount,%3=TABLECAPTION';
        FiscalPostingDateTok: Label 'C%1', Locked = true;

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
    [HandlerFunctions('YesConfirmHandler,RequestPageCloseBalanceSheetHandler')]
    [Scope('OnPrem')]
    procedure FiscalYearAdditionalCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostingDate: Date;
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Amount on GL Entry After Running Close Balance Sheet with Closing Fiscal Year.

        // 1. Setup: Close Already Opened Fiscal Year. Create New One, Update New currency on General Ledger Setup.
        // Create General Line and Post them with Random Values.
        Initialize;
        LibraryFiscalYear.CloseFiscalYear;
        LibraryFiscalYear.CreateFiscalYear;
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates;
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        AdditionalCurrencyAmount := Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear;
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // 2. Exercise: Run Close Balance Sheet Batch Report.
        RunCloseBalanceSheetBatchJob(GenJournalLine, PostingDate);

        // 3. Verify: Verify GL Entry for Fiscal Year Ending Date.
        Evaluate(PostingDate, StrSubstNo(FiscalPostingDateTok, PostingDate));
        VerifyGLEntryForFiscalYear(PostingDate, GenJournalLine."Account No.", -GenJournalLine.Amount, -AdditionalCurrencyAmount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageOpenBalanceSheetHandler')]
    [Scope('OnPrem')]
    procedure OpeningBalanceSheet()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // 1. Setup
        Initialize;

        SelectGenJournalBatch(GenJournalBatch);

        // 2. Exercise
        RunOpenBalanceSheetBatchJob(GenJournalBatch);

        // 3. Verify
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror GenJournalLine.FindFirst;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageCloseIncomeStatementReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NotRequiredMandatoryDimensionsForCloseIncome()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        PostingDate: Date;
    begin
        // 1. Setup
        Initialize;

        CreateGLAccountWithDefaultDimensions(GLAccount);

        LibraryFiscalYear.CloseFiscalYear;
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        MakeGenJournalLine(GenJnlLine, GenJnlBatch);

        // 2. Exercise
        RunCloseIncomeStatementBatchJob(GenJnlLine, PostingDate);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // 3. Verify
        // posting is successfully
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageCloseBalanceSheetHandler')]
    [Scope('OnPrem')]
    procedure NotRequiredMandatoryDimensionsForCloseBalance()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        PostingDate: Date;
    begin
        // 1. Setup
        Initialize;

        CreateGLAccountWithDefaultDimensions(GLAccount);

        LibraryFiscalYear.CloseFiscalYear;
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        MakeGenJournalLine(GenJnlLine, GenJnlBatch);

        // 2. Exercise
        RunCloseBalanceSheetBatchJob(GenJnlLine, PostingDate);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // 3. Verify
        // posting is successfully
    end;

    local procedure CreateGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode);
        GenJnlBatch.Modify();
    end;

    local procedure CreateGLAccountWithDefaultDimensions(var GLAccount: Record "G/L Account")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", GetDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Rounding Precision");
    end;

    local procedure GetDimensionCode(DimensionNo: Integer): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        case DimensionNo of
            1:
                exit(GLSetup."Shortcut Dimension 1 Code");
            2:
                exit(GLSetup."Shortcut Dimension 2 Code");
        end;
    end;

    local procedure MakeGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        CreateGenJournalBatch(GenJnlBatch);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Document No." :=
          LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
    end;

    local procedure RunCloseBalanceSheetBatchJob(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        CloseBalanceSheet: Report "Close Balance Sheet";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit();  // Required to commit changes done.
        Clear(CloseBalanceSheet);
        CloseBalanceSheet.Run;
    end;

    local procedure RunCloseIncomeStatementBatchJob(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit();  // Required to commit changes done.
        Clear(CloseIncomeStatement);
        CloseIncomeStatement.Run;
    end;

    local procedure RunOpenBalanceSheetBatchJob(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
        OpenBalanceSheet: Report "Open Balance Sheet";
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit();  // Required to commit changes done.
        Clear(OpenBalanceSheet);
        OpenBalanceSheet.Run;
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure VerifyAdditionalCurrencyAmount(var GLEntry: Record "G/L Entry"; AdditionalCurrencyAmount: Decimal)
    begin
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, GLEntry.TableCaption));
    end;

    local procedure VerifyGLEntryForFiscalYear(PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        VerifyAdditionalCurrencyAmount(GLEntry, AdditionalCurrencyAmount);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCloseBalanceSheetHandler(var CloseBalanceSheet: TestRequestPage "Close Balance Sheet")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseBalanceSheet.EndDateReq.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseBalanceSheet."GenJnlLine.""Journal Template Name""".SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseBalanceSheet."GenJnlLine.""Journal Batch Name""".SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseBalanceSheet.DocNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseBalanceSheet."ClosingBalanceSheetGLAcc.""No.""".SetValue(FieldValue);
        CloseBalanceSheet.PostingDescription.SetValue('Test');
        CloseBalanceSheet.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCloseIncomeStatementReportHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalTemplate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalBatch.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.DocumentNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(FieldValue);
        CloseIncomeStatement.PostingDescription.SetValue('Test');
        CloseIncomeStatement.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageOpenBalanceSheetHandler(var OpenBalanceSheet: TestRequestPage "Open Balance Sheet")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        OpenBalanceSheet."GenJnlLine.""Journal Template Name""".SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        OpenBalanceSheet."GenJnlLine.""Journal Batch Name""".SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        OpenBalanceSheet."OpeningBalanceSheetGLAcc.""No.""".SetValue(FieldValue);
        OpenBalanceSheet.PostingDescription.SetValue('Test');
        OpenBalanceSheet.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

#endif