codeunit 142069 "Exch. Rate Adjmt. Low Value"
{
    // // FEATURE [Adjust Exchange Rates]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        FieldMustEnabledMsg: Label 'Field must be enabled';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJournals: Codeunit "Library - Journals";
        RefValuationMethod: Option Standard,"Lowest Value","BilMoG (Germany)";

    [Test]
    [HandlerFunctions('AdjustExchangeRatesDueDateLimitRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateDueDateLimitAdjustExchangeRatesError()
    begin
        // Purpose of the test is to validate DueDateLimit - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run report Exchange Rate Adjustment to verify Error Code, Actual error message: Short term liabilities until must not be before Valuation Reference Date.
        Initialize();
        AdjustExchangeRatesReportErrors(WorkDate(), false, 'TestValidation');  // Posting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    local procedure AdjustExchangeRatesReportErrors(PostingDate: Date; AdjGLAcc: Boolean; Expected: Text[1024])
    begin
        // Enqueue Required inside AdjustExchangeRatesRequestPageHandler and AdjustExchangeRatesDueDateLimitRequestPageHandler.
        LibraryVariableStorage.Enqueue(AdjGLAcc);
        LibraryVariableStorage.Enqueue(PostingDate);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Exch. Rate Adjustment");

        // Verify: Verify Error Code.
        Assert.ExpectedErrorCode(Expected);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesPostingDescRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnOpenPageAdjExchRatesPostingDescriptionBlank()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Posting Description is updated automatically on Report Adjust Exchange Rates inside AdjustExchangeRatesPostingDescRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValPerEndRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateEndingDateAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate EndingDate - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Valuation Reference Date is automatically updated as last day of the month of Ending Date on Report Adjust Exchange Rates inside AdjustExchangeRatesValPerEndRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValuationMethodRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateValPerEndAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate ValPerEnd - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify DueDateLimit is automatically updated as next year of same date of Valuation Reference Date on Report Adjust Exchange Rates inside AdjustExchangeRatesValuationMethodRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValuationMethodRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateValnMethodAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate ValuationMethod - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Valuation Reference Date and Short term liabilities until is enabled when Valuation Method Type is BilMoG (Germany) on Report Adjust Exchange Rates inside AdjustExchangeRatesValuationMethodRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    local procedure AdjustExchangeRatesReport()
    begin
        // Exercise.
        REPORT.Run(REPORT::"Exch. Rate Adjustment");

        // Verify: Verify various Fields in AdjustExchangeRatesPostingDescRequestPageHandler, AdjustExchangeRatesValPerEndRequestPageHandler and  AdjustExchangeRatesValuationMethodRequestPageHandler.
    end;
    
    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccountWithCurrencyAndGroup(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10]; BankAccountPostingGroupCode: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroupCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate();
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := 1;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := 1;
        CurrencyExchangeRate.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyWithSpecificExchangeRates(var AdjustmentDate: array[2] of Date) CurrencyCode: Code[10]
    begin
        // Exchange rate for "October"
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<CM - 3M>', WorkDate()), 1.2368, 1.2368);

        // Exchange rate for "November"
        AdjustmentDate[1] := CalcDate('<CM - 2M>', WorkDate());
        LibraryERM.CreateExchangeRate(CurrencyCode, AdjustmentDate[1], 0.92, 0.92);

        // Exchange rate for "December"
        AdjustmentDate[2] := CalcDate('<CM - 1M>', WorkDate());
        LibraryERM.CreateExchangeRate(CurrencyCode, AdjustmentDate[2], 0.8, 0.8);
    end;

    local procedure CreateForeignVendorNoWithVATPostingSetup(CurrencyCode: Code[10]; var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreatePostJournalInvoice(VendorNo: Code[20]; PostingDate: Date; InvoiceAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Purchase),
            InvoiceAmount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", VendorNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostPaymentAppliedToInvoice(VendorNo: Code[20]; PostingDate: Date; PaymentAmount: Decimal; InvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, PaymentAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostGenJournalLineForBankAccount(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; BankAccount: Record "Bank Account")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account", BankAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunAdjExchRatesForVendorByDateBilMog(CurrencyCode: Code[10]; AdjustmentDate: Date)
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyCode);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
            AdjustmentDate, AdjustmentDate, '', AdjustmentDate, 'DocumentNo', true, false);
        ExchRateAdjustment.SetValuationMethod(RefValuationMethod::"BilMoG (Germany)", 0D, AdjustmentDate);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    var
        AdjGLAcc: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(AdjGLAcc);
        LibraryVariableStorage.Dequeue(PostingDate);
        ExchRateAdjustment.AdjGLAccount.SetValue(AdjGLAcc);
        ExchRateAdjustment.StartingDate.SetValue(WorkDate());
        ExchRateAdjustment.EndingDate.SetValue(WorkDate());
        ExchRateAdjustment.PostingDateReq.SetValue(PostingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesDueDateLimitRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.ValPerEnd.SetValue(CalcDate('<+CM>', WorkDate()));
        ExchRateAdjustment.DueDateLimit.SetValue(WorkDate());  // Less than ValPerEnd.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesPostingDescRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.PostingDescriptionReq.AssertEquals('Adjmt. of %1 %2, Ex.Rate Adjust.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValPerEndRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.EndingDate.SetValue(WorkDate());
        ExchRateAdjustment.PostingDateReq.AssertEquals(WorkDate());
        ExchRateAdjustment.ValPerEnd.AssertEquals(CalcDate('<+CM>', WorkDate()));  // ValPerEnd is equal to Last day of month of Posting Date.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValuationMethodRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        ExchRateAdjustment.ValPerEnd.SetValue(WorkDate());
        ExchRateAdjustment.DueDateLimit.AssertEquals(CalcDate('<+1Y>', WorkDate()));  // DueDateLimit is equal to same day of next year of ValPerEnd.
        Assert.IsTrue(ExchRateAdjustment.DueDateLimit.Enabled(), FieldMustEnabledMsg);
        Assert.IsTrue(ExchRateAdjustment.ValPerEnd.Enabled(), FieldMustEnabledMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToAdjustMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure AdjustedMessageHandler(Message: Text[1024])
    begin
    end;
}

