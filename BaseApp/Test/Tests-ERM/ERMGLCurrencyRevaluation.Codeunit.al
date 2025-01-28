codeunit 134887 "ERM G/L Currency Revaluation"
{
    // // [FEATURE] [G/L Currency Revaluation]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        PostingDateErr: Label 'Please enter posting date.';
        isInitialised: Boolean;
        LinesExistErr: Label 'There are already entries in the G/L journal %1. Please post or delete them before you proceed.', Comment = '%1 - batch name';
        CorrectionInsertedMsg: Label 'currency revaluation lines have been created in the general journal';
        CurrUpdateBalAccErr: Label 'In order to change the currency code, the balance of the account must be zero.';

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Clear();
        GenJournalLine.DeleteAll();

        if isInitialised then
            exit;

        GeneralLedgerSetup.Get();
        isInitialised := true;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesLossCorrectionInserted()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);

        // Verify.
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler,GeneralJournalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesOpenGeneralJournalPage()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, false);

        // Verify.
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
    end;


    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesUnrealizedLossCorrectionInserted()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        GLAccount."Unrealized Revaluation" := true;
        GLAccount.Modify();
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);

        // Verify.
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesGainCorrectionInserted()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, -1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);

        // Verify.
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesUnrealizedGainCorrectionInserted()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        GLAccount."Unrealized Revaluation" := true;
        GLAccount.Modify();
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, -1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);

        // Verify.
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesTwice()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        RunRevaluation(GLAccount, true);

        // Verify.
        VerifyCorrectionLineCount(GenJournalLine, GenJournalBatch, GLAccount, 0);
    end;

    [Test]
    [HandlerFunctions('AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesNoKeyDate()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(0D);
        asserterror REPORT.Run(REPORT::"G/L Currency Revaluation", true, false, GLAccount);

        // Verify.
        Assert.ExpectedError(PostingDateErr);
    end;

    [Test]
    [HandlerFunctions('AdjExchRatesReqPageHandler,GenJnlBatchModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRatesJnlLinesAlreadyExist()
    var
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 0);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        asserterror REPORT.Run(REPORT::"G/L Currency Revaluation", true, false, GLAccount);

        // Verify.
        Assert.ExpectedError(StrSubstNo(LinesExistErr, GenJournalBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnGLAccountWithSameCurrencySetup()
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        Initialize();

        // Setup.
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);

        // Exercise.
        GLAccount.Validate("Source Currency Code", Currency.Code);

        // Verify: no error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnGLAccountWithMultipleCurrencySetup()
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        Initialize();

        // Setup.
        CreateAccountWithMultipleSourceCurrenciesSetup(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);

        // Exercise.
        asserterror GLAccount.Validate("Source Currency Code", Currency.Code);

        // Verify: error - cannot enter Source Currency Code for multiple currencies posting
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnNonBalanceGLAccount()
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Source Currency Posting", GLAccount."Source Currency Posting"::"Same Currency");
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);

        // Exercise.
        GLAccount.Validate("Source Currency Code", Currency.Code);

        // Verify - no error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnGLAccountWithBalance()
    var
        BalGLAccount: Record "G/L Account";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        LibraryERM.FindDirectPostingGLAccount(BalGLAccount);
        CreateAccountWithSameSourceCurrencySetup(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        PostFCYJournal(GLAccount, WorkDate(), GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.");

        // Exercise.
        LibraryERM.CreateCurrency(Currency);
        asserterror GLAccount.Validate("Source Currency Code", Currency.Code);

        // Verify.
        Assert.ExpectedError(CurrUpdateBalAccErr);
    end;

    local procedure AddDifferentExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; GLAccount: Record "G/L Account"; GainsLossesFactor: Integer)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", GLAccount."Source Currency Code");
        CurrencyExchangeRate.FindLast();
        LibraryERM.CreateExchangeRate(GLAccount."Source Currency Code", WorkDate() + LibraryRandom.RandInt(10),
          CurrencyExchangeRate."Exchange Rate Amount" + GainsLossesFactor * LibraryRandom.RandDec(10, 2),
          CurrencyExchangeRate."Adjustment Exch. Rate Amount" + GainsLossesFactor * LibraryRandom.RandDec(10, 2));
    end;

    local procedure GetCorrectionBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.DeleteAll();

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure GetCorrectionAmountAndAccount(var BalGLAccountNo: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate"; GLAccount: Record "G/L Account"): Decimal
    var
        Currency: Record Currency;
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
        Correction: Decimal;
    begin
        Currency.Get(CurrencyExchangeRate."Currency Code");
        GLAccountSourceCurrency."G/L Account No." := GLAccount."No.";
        GLAccountSourceCurrency."Currency Code" := Currency.Code;
        GLAccountSourceCurrency.SetRange("Date Filter", 0D, CurrencyExchangeRate."Starting Date");
        GLAccountSourceCurrency.CalcFields("Balance at Date", "Source Curr. Balance at Date");

        Correction :=
            Round(
                GLAccountSourceCurrency."Source Curr. Balance at Date" /
                CurrencyExchangeRate.ExchangeRateAdjmt(CurrencyExchangeRate."Starting Date", Currency.Code) - GLAccountSourceCurrency."Balance at Date",
                GeneralLedgerSetup."Amount Rounding Precision");

        if Correction > 0 then
            BalGLAccountNo := GetGainsAccount(Currency, GLAccount."Unrealized Revaluation")
        else
            BalGLAccountNo := GetLossesAccount(Currency, GLAccount."Unrealized Revaluation");

        exit(Correction);
    end;

    local procedure GetGainsAccount(Currency: Record Currency; Unrealized: Boolean): Code[20]
    begin
        if Unrealized then
            exit(Currency.GetUnrealizedGainsAccount());

        exit(Currency.GetRealizedGainsAccount());
    end;

    local procedure GetLossesAccount(Currency: Record Currency; Unrealized: Boolean): Code[20]
    begin
        if Unrealized then
            exit(Currency.GetUnrealizedLossesAccount());

        exit(Currency.GetRealizedLossesAccount());
    end;

    local procedure CreateAccountWithSameSourceCurrencySetup(var GLAccount: Record "G/L Account")
    begin
        CreateAccountWithSourceCurrencySetup(GLAccount, "G/L Source Currency Posting"::"Same Currency");
    end;

    local procedure CreateAccountWithMultipleSourceCurrenciesSetup(var GLAccount: Record "G/L Account")
    begin
        CreateAccountWithSourceCurrencySetup(GLAccount, "G/L Source Currency Posting"::"Multiple Currencies");
    end;

    local procedure CreateAccountWithSourceCurrencySetup(var GLAccount: Record "G/L Account"; SourceCurrencuPosting: Enum "G/L Source Currency Posting")
    var
        Currency: Record Currency;
        Currency2: Record Currency;
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(
            Currency.Code, WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));

        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Source Currency Revaluation", true);
        GLAccount.Validate("Source Currency Posting", SourceCurrencuPosting);
        case SourceCurrencuPosting of
            SourceCurrencuPosting::"Same Currency":
                GLAccount.Validate("Source Currency Code", Currency.Code);
            SourceCurrencuPosting::"Multiple Currencies":
                begin
                    GLAccount."Source Currency Code" := '';
                    GLAccountSourceCurrency.InsertRecord(GLAccount."No.", Currency.Code);
                    LibraryERM.CreateCurrency(Currency2);
                    GLAccountSourceCurrency.InsertRecord(GLAccount."No.", Currency2.Code);
                end;
        end;
        GLAccount.Modify(true);

        GLAccount.SetRange("No.", GLAccount."No.");
    end;

    local procedure PostFCYJournal(GLAccount: Record "G/L Account"; PostingDate: Date; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateFCYJournal(GenJournalLine, GLAccount."No.", PostingDate, BalAccType, BalAccNo, GLAccount."Source Currency Code");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFCYJournal(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; PostingDate: Date; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; CurrCode: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
          BalAccType, BalAccNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateFCYBalance(GLAccount: Record "G/L Account")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        // Replace existing account by new one
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        BankAccountPostingGroup."G/L Account No." := LibraryERM.CreateGLAccountNo();
        BankAccountPostingGroup.Modify();

        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);

        CurrencyExchangeRate.SetRange("Currency Code", GLAccount."Source Currency Code");
        CurrencyExchangeRate.FindSet();
        repeat
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date", GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date", GenJournalLine."Bal. Account Type"::Customer, Customer."No.");
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date", GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.");
        until CurrencyExchangeRate.Next() = 0;
    end;

    local procedure RunRevaluation(var GLAccount: Record "G/L Account"; SkipShowBatch: Boolean)
    var
        GLCurrencyRevaluation: Report "G/L Currency Revaluation";
    begin
        Clear(GLCurrencyRevaluation);
        GLCurrencyRevaluation.SetSkipShowBatch(SkipShowBatch);
        GLCurrencyRevaluation.SetTableView(GLAccount);
        GLCurrencyRevaluation.Run();
    end;

    local procedure VerifyCorrectionLineCount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account"; ExpCount: Integer)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        Assert.AreEqual(ExpCount, GenJournalLine.Count, 'Unexpected correction entries.');
    end;

    local procedure VerifyCorrectionlLinesData(GLAccount: Record "G/L Account"; GenJournalBatch: Record "Gen. Journal Batch"; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        BalAccountNo: Code[20];
    begin
        SourceCodeSetup.Get();

        VerifyCorrectionLineCount(GenJournalLine, GenJournalBatch, GLAccount, 1);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", CurrencyExchangeRate."Starting Date");
        GenJournalLine.TestField("Source Code", SourceCodeSetup."G/L Currency Revaluation");
        GenJournalLine.TestField("Currency Code", '');
        Assert.AreNearlyEqual(GetCorrectionAmountAndAccount(BalAccountNo, CurrencyExchangeRate, GLAccount), GenJournalLine.Amount,
          GeneralLedgerSetup."Amount Rounding Precision", 'Wrong correction amount.');
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.TestField("Bal. Account No.", BalAccountNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjExchRatesReqPageHandler(var GLCurrencyRevaluation: TestRequestPage "G/L Currency Revaluation")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        GLCurrencyRevaluation.JournalBatchName.Lookup();
        GLCurrencyRevaluation.PostingDate.SetValue(PostingDate); // Posting Date.
        GLCurrencyRevaluation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ManualBatchAdjExchRatesReqPageHandler(var GLCurrencyRevaluation: TestRequestPage "G/L Currency Revaluation")
    begin
        GLCurrencyRevaluation.JournalBatchName.SetValue(LibraryVariableStorage.DequeueText());
        GLCurrencyRevaluation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, CorrectionInsertedMsg) > 0, 'Unexpected message.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlBatchModalPageHandler(var GeneralJournalBatches: Page "General Journal Batches"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHandler(var GeneralJournal: Page "General Journal")
    begin
        GeneralJournal.Close();
    end;
}

