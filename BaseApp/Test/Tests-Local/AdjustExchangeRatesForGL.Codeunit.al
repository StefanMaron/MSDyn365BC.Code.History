codeunit 144221 "Adjust Exchange Rates For G/L"
{
    // // [FEATURE] [Adjust Exch. Rates]

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
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        KeyDateErr: Label 'The key date must be defined.';
        CorrectionInsertedMsg: Label 'exrate adjustment lines have been prepared in the G/L journal';
        isInitialised: Boolean;
        LinesExistErr: Label 'There are already entries in the G/L journal %1. Please post or delete them before you proceed.';
        CurrUpdateMsg: Label 'This feature is designed for bank accounts in foreign currency and should only be used for this purpose.';
        CurrUpdateErr: Label 'Currency codes are only allowed for assets and liabilities and linetype account.';
        CurrUpdateBalAccErr: Label 'In order to change the currency code, the balance of the account must be zero.';
        CurrMismatchErr: Label 'The currency code %1 on G/L journal line does not match with the currency code %2';
        AdjustExchangeRatesGLCaptionLbl: Label 'AdjustExchangeRatesGLCaption';

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
        CreateAccountWithCurrency(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);

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
        CreateAccountWithCurrency(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, -1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);

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
        CreateAccountWithCurrency(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);
        VerifyCorrectionlLinesData(GLAccount, GenJournalBatch, CurrencyExchangeRate);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);

        // Verify.
        VerifyCorrectionLineCount(GenJournalLine, GenJournalBatch, GLAccount, 0);
        VerifyReportData(GLAccount, 0, CurrencyExchangeRate."Starting Date");
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
        CreateAccountWithCurrency(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(0D);
        asserterror REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);

        // Verify.
        Assert.ExpectedError(KeyDateErr);
        asserterror LibraryReportDataset.LoadDataSetFile;
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
        CreateAccountWithCurrency(GLAccount);
        AddDifferentExchangeRate(CurrencyExchangeRate, GLAccount, 1);
        CreateFCYBalance(GLAccount);
        GetCorrectionBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 0);

        // Exercise.
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Starting Date");
        asserterror REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false, GLAccount);

        // Verify.
        Assert.ExpectedError(StrSubstNo(LinesExistErr, GenJournalBatch.Name));
        asserterror LibraryReportDataset.LoadDataSetFile;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ManualBatchAdjExchRatesReqPageHandler')]
    [Scope('OnPrem')]
    procedure SelectJournalBatchManually()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 379258] Manual input of Gen. Journal Batch in "Adjust Exchange Rate" report
        Initialize();

        // [GIVEN] Gen. Journal Batch named "B"
        GetCorrectionBatch(GenJournalBatch);

        // [GIVEN] Opened Request page of "Adjust Exchange Rate" report

        // [WHEN] Provide batch name "B" by manual input
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"Adjust Exchange Rates G/L", true, false);

        // [THEN] Report exported within specified batch "B"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagExists(AdjustExchangeRatesGLCaptionLbl);
    end;

    [Test]
    [HandlerFunctions('CurrUpdateMsgHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnGLAccount()
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);

        // Exercise.
        GLAccount.Validate("Currency Code", Currency.Code);

        // Verify: In message handler.
    end;

    [Test]
    [HandlerFunctions('CurrUpdateMsgHandler')]
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
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);

        // Exercise.
        asserterror GLAccount.Validate("Currency Code", Currency.Code);

        // Verify.
        Assert.ExpectedError(CurrUpdateErr);
    end;

    [Test]
    [HandlerFunctions('CurrUpdateMsgHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnGLAccountWBalance()
    var
        BalGLAccount: Record "G/L Account";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        LibraryERM.FindDirectPostingGLAccount(BalGLAccount);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateCurrency(Currency);
        PostFCYJournal(GLAccount, WorkDate(), GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.");

        // Exercise.
        asserterror GLAccount.Validate("Currency Code", Currency.Code);

        // Verify.
        Assert.ExpectedError(CurrUpdateBalAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithDiffCurrForBankAcc()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        CreateAccountWithCurrency(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2)));
        BankAccount.Modify(true);
        CreateFCYJournal(GenJournalLine, GLAccount."No.", WorkDate(), GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccount."No.", BankAccount."Currency Code");

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        Assert.ExpectedError(StrSubstNo(CurrMismatchErr, GenJournalLine."Currency Code", GLAccount."Currency Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithDiffCurrForCustomer()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        RecGLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup.
        CreateAccountWithCurrency(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        GetReceivablesAccForCustomer(RecGLAccount, Customer);
        RecGLAccount."Currency Code" :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        RecGLAccount.Modify(true);
        CreateFCYJournal(GenJournalLine, GLAccount."No.", WorkDate(), GenJournalLine."Bal. Account Type"::Customer,
          Customer."No.", GLAccount."Currency Code");

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        Assert.ExpectedError(StrSubstNo(CurrMismatchErr, GenJournalLine."Currency Code", RecGLAccount."Currency Code"));
    end;

    local procedure AddDifferentExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; GLAccount: Record "G/L Account"; GainsLossesFactor: Integer)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", GLAccount."Currency Code");
        CurrencyExchangeRate.FindLast();

        LibraryERM.CreateExchangeRate(GLAccount."Currency Code", WorkDate + LibraryRandom.RandInt(10),
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
        Correction: Decimal;
    begin
        GLAccount.SetRange("Date Filter", 0D, CurrencyExchangeRate."Starting Date");
        GLAccount.CalcFields("Balance at Date", "Balance at Date (FCY)");
        Currency.Get(CurrencyExchangeRate."Currency Code");
        Correction := Round(GLAccount."Balance at Date (FCY)" /
            CurrencyExchangeRate.ExchangeRateAdjmt(CurrencyExchangeRate."Starting Date", Currency.Code) - GLAccount."Balance at Date",
            GeneralLedgerSetup."Amount Rounding Precision");

        if Correction > 0 then
            BalGLAccountNo := Currency."Realized Gains Acc."
        else
            BalGLAccountNo := Currency."Realized Losses Acc.";

        exit(Correction);
    end;

    local procedure GetReceivablesAccForCustomer(var GLAccount: Record "G/L Account"; Customer: Record Customer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup."Receivables Account");
    end;

    local procedure CreateAccountWithCurrency(var GLAccount: Record "G/L Account")
    var
        Currency: Record Currency;
        GainsGLAccount: Record "G/L Account";
        LossesGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GainsGLAccount);
        LibraryERM.CreateGLAccount(LossesGLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", GainsGLAccount."No.");
        Currency.Validate("Realized Losses Acc.", LossesGLAccount."No.");
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(),
          LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));

        GLAccount."Currency Code" := Currency.Code;
        GLAccount.Modify(true);

        GLAccount.SetRange("No.", GLAccount."No.");
    end;

    local procedure PostFCYJournal(GLAccount: Record "G/L Account"; PostingDate: Date; BalAccType: Option; BalAccNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateFCYJournal(GenJournalLine, GLAccount."No.", PostingDate, BalAccType, BalAccNo, GLAccount."Currency Code");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFCYJournal(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; PostingDate: Date; BalAccType: Option; BalAccNo: Code[20]; CurrCode: Code[10])
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
        Customer: Record Customer;
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);

        CurrencyExchangeRate.SetRange("Currency Code", GLAccount."Currency Code");
        CurrencyExchangeRate.FindSet();
        repeat
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date",
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date", GenJournalLine."Bal. Account Type"::Customer, Customer."No.");
            PostFCYJournal(GLAccount, CurrencyExchangeRate."Starting Date", GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.");
        until CurrencyExchangeRate.Next() = 0;
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
        GenJournalLine.TestField("Source Code", SourceCodeSetup."Exchange Rate Adjmt.");
        GenJournalLine.TestField("Currency Code", '');
        Assert.AreNearlyEqual(GetCorrectionAmountAndAccount(BalAccountNo, CurrencyExchangeRate, GLAccount), GenJournalLine.Amount,
          GeneralLedgerSetup."Amount Rounding Precision", 'Wrong correction amount.');
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.TestField("Bal. Account No.", BalAccountNo);

        VerifyReportData(GLAccount, GenJournalLine.Amount, CurrencyExchangeRate."Starting Date");
    end;

    local procedure VerifyReportData(GLAccount: Record "G/L Account"; ExpCorrection: Decimal; KeyDate: Date)
    begin
        GLAccount.SetRange("Date Filter", 0D, KeyDate);
        GLAccount.CalcFields("Balance at Date", "Balance at Date (FCY)");

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('KeyDate', Format(KeyDate));
        LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAccount', GLAccount.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('CurrencyCode_GLAccount', GLAccount."Currency Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceatDateFCY_GLAccount', GLAccount."Balance at Date (FCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceatDate_GLAccount', GLAccount."Balance at Date");
        LibraryReportDataset.AssertCurrentRowValueEquals('AvgExRate',
          Round(GLAccount."Balance at Date" / GLAccount."Balance at Date (FCY)", 0.00001));
        LibraryReportDataset.AssertCurrentRowValueEquals('Correction', ExpCorrection);
        LibraryReportDataset.Reset();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjExchRatesReqPageHandler(var AdjustExchangeRatesGL: TestRequestPage "Adjust Exchange Rates G/L")
    var
        KeyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(KeyDate);
        AdjustExchangeRatesGL.PrepareGlLines.SetValue(true); // Prepare GL Lines.
        AdjustExchangeRatesGL.JournalBatchName.Lookup;
        AdjustExchangeRatesGL.KeyDate.SetValue(KeyDate); // Key Date.
        AdjustExchangeRatesGL.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ManualBatchAdjExchRatesReqPageHandler(var AdjustExchangeRatesGL: TestRequestPage "Adjust Exchange Rates G/L")
    begin
        AdjustExchangeRatesGL.JournalBatchName.SetValue(LibraryVariableStorage.DequeueText);
        AdjustExchangeRatesGL.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CurrUpdateMsgHandler(Message: Text[1024])
    begin
        Assert.AreEqual(Format(CurrUpdateMsg), Message, 'Unexpected message when updating currency code.');
    end;
}

