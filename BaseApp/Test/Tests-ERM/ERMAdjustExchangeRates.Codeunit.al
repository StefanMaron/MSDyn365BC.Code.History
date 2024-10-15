#if not CLEAN23
#pragma warning disable AS0072
codeunit 134083 "ERM Adjust Exchange Rates"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;
    ObsoleteReason = 'Not Used.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ExpectNoAdjustmentErr: Label 'Expect no adjustment for entries before %1';
        ExchangeRateAdjmtTxt: Label 'Exchange Rate Adjmt. of %1 %2';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        MakeInconsistent: Boolean;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRates()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test run the Adjust Exchange Rate and check the corresponding ledger entries.

        // 1. Setup: Create a new Currency with Exchange Rate, create another Exchange Rate for the Currency having greater
        // Relational Exch Rate Amount.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");

        // Create two GL Entries for two different GL Accounts having different Exchange Rate Adjustment.
        CreateGLEntryForAccount(
          GLAccount, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Amount", WorkDate());
        CreateGLEntryForAccount(
          GLAccount2, CurrencyExchangeRate."Currency Code", GLAccount2."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          WorkDate());
        CreateNewExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run the report Adjust Exchange Rate.
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunAdjustExchangeRates(
          CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate(), ExchangeRateAdjmtTxt, WorkDate(), DocumentNo, true);

        // 3. Verification: Verify that the amount in GL Entry is populated as per the adjustment exchange rate for both GL Accounts.
        VerifyGLEntryAdjustAmount(GLAccount, DocumentNo, CurrencyExchangeRate."Currency Code");
        VerifyGLEntry(DocumentNo, GLAccount2."No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateACYStartDate()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test Start Date Field is Used for  Additional Reporting Currency Adjustment.

        // 1. Setup: Create a new Currency with Exchange Rate.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Setup: Configure Additional Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");

        // Setup: Create two GL Entries for two different GL Accounts with Different Posting Date.
        CreateGLEntryForAccount(
          GLAccount, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          LibraryRandom.RandDate(-7));  // Random Date in the Past.
        CreateGLEntryForAccount(
          GLAccount2, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          WorkDate());

        // Setup: Create new Exchange Rate for a WORKDATE.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyExchangeRate."Currency Code", WorkDate());
        UpdateExchangeRate(CurrencyExchangeRate, 100 * LibraryRandom.RandInt(4), 200 * LibraryRandom.RandInt(4));

        // 2. Exercise: Run the report Adjust Exchange Rate.
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunAdjustExchangeRates(
          CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate(), ExchangeRateAdjmtTxt, WorkDate(), DocumentNo, true);

        // 3. Verification: Verify that Entries with Posting Date Less than WORKDATE Were Not Adjusted.
        Assert.IsFalse(VerifyGLEntryFound(DocumentNo, GLAccount."No."), StrSubstNo(ExpectNoAdjustmentErr, WorkDate()));

        // 4. Verification: Verify that Entries with Posting Date Equal to WORKDATE Were Adjusted.
        VerifyGLEntry(DocumentNo, GLAccount2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoErrorOnCurrenciesPage()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currencies: TestPage Currencies;
    begin
        // Check that there is no error exist on currencies page when exchange rate is defined with starting date only.

        // Setup:Create currency and create Exchange Rate with starting date only.
        Initialize();
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());

        // Exercise: Open Currencies page.
        Currencies.OpenEdit();
        Currencies.FILTER.SetFilter(Code, Currency.Code);

        // Verify: Verifying that Currency Code exist on page and no error exist when open the page.
        Currencies.Code.AssertEquals(Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InconsistentAdjustmentPreview()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        ERMAdjustExchangeRates: Codeunit "ERM Adjust Exchange Rates";
        GLEntriesPreview: TestPage "G/L Entries Preview";
        DocumentNo: Code[20];
        TotalBalance: Decimal;
        Amount: Decimal;
    begin
        // [SCENARIO] G/L Entry Posting preview of inconsistent exchange rate adjustment
        Initialize();

        // [GIVEN] Subscribe on OnPostGenJnlLineOnBeforeGenJnlPostLineRun to cause inconsintence
        BindSubscription(ERMAdjustExchangeRates);
        ERMAdjustExchangeRates.SetMakeInconsistent();

        // [GIVEN] Create gen. journal line
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");

        // Create two GL Entries for two different GL Accounts having different Exchange Rate Adjustment.
        CreateGLEntryForAccount(
          GLAccount, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Amount", WorkDate());
        CreateGLEntryForAccount(
          GLAccount2, CurrencyExchangeRate."Currency Code", GLAccount2."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          WorkDate());
        CreateNewExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run the report Adjust Exchange Rate.
        GLEntriesPreview.Trap();
        DocumentNo := Format(LibraryRandom.RandInt(100));
        RunAdjustExchangeRatesReport(
            CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate(), ExchangeRateAdjmtTxt, WorkDate(), DocumentNo, true);

        // [THEN] Check Document No. in G/L Entries Preview
        TotalBalance := 0;
        GLEntriesPreview.First();
        repeat
            Assert.AreEqual(DocumentNo, Format(GLEntriesPreview."Document No."), 'Wrong Document No. in G/L Entries Preview');
            Evaluate(Amount, GLEntriesPreview.Amount.Value);
            TotalBalance := TotalBalance + Amount;
        until not GLEntriesPreview.Next();
        GLEntriesPreview.Close();
        Assert.AreNotEqual(0, TotalBalance, 'Total balance should not be 0');

        asserterror Commit();
        Assert.IsTrue(
            StrPos(
                GetLastErrorText(),
                'The transaction cannot be completed because it will cause inconsistencies') > 0, 'Missing inconsistency error');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        SetupAccountOnCurrency(Currency);
        Currency.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, 0D);
        UpdateExchangeRate(CurrencyExchangeRate, 100 * LibraryRandom.RandInt(4), 200 * LibraryRandom.RandInt(4));
    end;

    local procedure CreateGLEntryForAccount(var GLAccount: Record "G/L Account"; CurrencyCode: Code[10]; ExchangeRateAdjustment: Enum "Exch. Rate Adjustment Type"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Exchange Rate Adjustment", ExchangeRateAdjustment);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        CreateGeneralJournalLine(GenJournalLine, GLAccount."No.", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Using Random Number Generator to Generate the Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandInt(200));

        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateNewExchangeRate(CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate2, CurrencyExchangeRate."Currency Code", WorkDate());
        UpdateExchangeRate(
          CurrencyExchangeRate2, CurrencyExchangeRate."Exchange Rate Amount", 2 * CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure SetupAccountOnCurrency(var Currency: Record Currency)
    begin
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Realized G/L Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
    end;

    procedure SetMakeInconsistent()
    begin
        MakeInconsistent := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Exchange Rates", 'OnPostGenJnlLineOnBeforeGenJnlPostLineRun', '', false, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if MakeInconsistent then
            if GenJnlLine.Amount > 0 then
                GenJnlLine.Amount := Round(GenJnlLine.Amount * 1.1);
    end;

    local procedure RunAdjustExchangeRatesReport(CurrencyCode: Code[10]; StartDate: Date; EndDate: Date; PostingDescription: Text[50]; PostingDate: Date; PostingDocNo: Code[20]; AdjGLAcc: Boolean)
    var
        Currency: Record Currency;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        Currency.SetRange(Code, CurrencyCode);
        AdjustExchangeRates.SetTableView(Currency);
        AdjustExchangeRates.InitializeRequest2(StartDate, EndDate, PostingDescription, PostingDate, PostingDocNo, true, AdjGLAcc);
        AdjustExchangeRates.UseRequestPage(false);
        AdjustExchangeRates.Run();
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyGLEntryAdjustAmount(GLAccount: Record "G/L Account"; DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
    begin
        CurrencyExchangeRate.Get(CurrencyCode, WorkDate());
        GLAccount.CalcFields("Add.-Currency Balance at Date");
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(
          Amount,
          GLAccount."Add.-Currency Balance at Date" * (CurrencyExchangeRate."Relational Exch. Rate Amount" / 2) /
          CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, 0);  // Entry will be created with zero amount.
        GLEntry.TestField("System-Created Entry", true);
    end;

    local procedure VerifyGLEntryFound(DocumentNo: Code[20]; GLAccountNo: Code[20]): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        exit(GLEntry.FindFirst())
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}
#endif
