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

    [Test]
    [HandlerFunctions('AdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjAmountForVendorEntryClosedPriorAdjustment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        AdjustmentDate: array[2] of Date;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 379603] Adjusted amount printed for vendor entry which was closed prior adjustment

        Initialize();
        // [GIVEN] Currency with exchange rates for the end of "Octomer", "November" and "December"
        CurrencyCode := CreateCurrencyWithSpecificExchangeRates(AdjustmentDate);

        // [GIVEN] Foreign Vendor with created currency
        VendorNo := CreateForeignVendorNoWithVATPostingSetup(CurrencyCode, VATPostingSetup);

        // [GIVEN] Posted vendor invoice on the mid of "November"
        InvoiceAmount := 1000;
        InvoiceNo :=
          CreatePostJournalInvoice(
            VendorNo, LibraryRandom.RandDateFrom(AdjustmentDate[1], -10), InvoiceAmount, VATPostingSetup);

        // [GIVEN] Adjusted posted invoice in the end of "November" with Valuation Method "BilMoG (Germany)"
        RunAdjExchRatesForVendorByDateBilMog(CurrencyCode, AdjustmentDate[1]);

        // [GIVEN] Posted payment in "January" applied to invoice
        CreatePostPaymentAppliedToInvoice(VendorNo, WorkDate(), InvoiceAmount, InvoiceNo);

        // [WHEN] Adjust Exchange Rate report is being printed in the end of "December" with Valuation Method "BilMoG (Germany)"
        RunAdjExchRatesForVendorByDateBilMog(CurrencyCode, AdjustmentDate[2]);

        // [THEN] Verify Invoice Adjusted amount
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DtldVendorLedgEntry.SetRange("Document No.", 'DocumentNo');
        asserterror DtldVendorLedgEntry.FindLast();
        // Assert.AreEqual(DtldVendorLedgEntry.Amount, -163.04, 'Adjusted amount is not correct.');
        Assert.KnownFailure('There is no Detailed Vendor Ledg. Entry within the filter', 425199);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NothingToAdjustMessageHandler')]
    procedure AdjustExchRatesGeneratesOnlyTotalRegisterPerBankAccPostingGroup()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankAccount: array[2] of Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
        TotalAmount: Decimal;
        StartingDate: Date;
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 210882] "Exch. Rate Adjustment" report generates the only total entry in "Exch. Rate Adjmt. Reg." for multiple bank accounts with the same bank account posting group

        // [GIVEN] Currency "C" with exchange rate = 1.3 at "01/01/17"
        StartingDate := CalcDate('<-CY+1D>', WorkDate());

        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(StartingDate, 1, LibraryRandom.RandInt(5));

        // [GIVEN] Bank accounts "A" and "B" with "Currency Code" = "C" and "Bank Acc. Posting Group" = "G"
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroup.Modify(true);

        CreateBankAccountWithCurrencyAndGroup(BankAccount[1], CurrencyCode, BankAccountPostingGroup.Code);
        CreateBankAccountWithCurrencyAndGroup(BankAccount[2], CurrencyCode, BankAccountPostingGroup.Code);

        // [GIVEN] Posted journal lines for "A" and "B" at "01/02/17" with amounts 100 and 200
        PostGenJournalLineForBankAccount(GenJournalLine, StartingDate, BankAccount[1]);
        TotalAmount += GenJournalLine.Amount;
        PostGenJournalLineForBankAccount(GenJournalLine, StartingDate, BankAccount[2]);
        TotalAmount += GenJournalLine.Amount;

        // [GIVEN] Added exchange rate = 1.5 at "21/01/17"
        LibraryERM.CreateExchangeRate(CurrencyCode, StartingDate + 1, 1, LibraryRandom.RandIntInRange(10, 15));

        // [WHEN] Run "Exch. Rate Adjustment" for bank account with posting
        Commit();
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, CalcDate('<CY>', StartingDate), StartingDate);

        // [THEN] The only total entry inserted into "Exch. Rate Adjmt. Reg." table
        ExchRateAdjmtReg.SetRange("Posting Group", BankAccountPostingGroup.Code);
        asserterror Assert.RecordCount(ExchRateAdjmtReg, 1);
        Assert.KnownFailure('Expected number of Exch. Rate Adjmt. Reg. entries: 1. Actual: 0.', 425199);

        // [THEN] The adjusted base amount = 100 + 200;
        // ExchRateAdjmtReg.FindFirst();
        // ExchRateAdjmtReg.TestField("Adjusted Base", TotalAmount);
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

