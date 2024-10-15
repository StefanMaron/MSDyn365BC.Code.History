#if not CLEAN23
codeunit 142068 "UT REP LOWVAL"
{
    // // FEATURE [Adjust Exchange Rates]

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '20.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Adjust Exchange Rates report is obsoleted.';

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        FieldMustEnabledMsg: Label 'Field must be enabled';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJournals: Codeunit "Library - Journals";
        RefValuationMethod: Option Standard,"Lowest Value","BilMoG (Germany)";
        RatesAdjustedMsg: Label 'One or more currency exchange rates have been adjusted.';

    [Test]
    [HandlerFunctions('AdjustExchangeRatesRequestPageHandler,ConfirmHandlerFALSE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAdjustExchangeRatesPostSettlementError()
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 595 Adjust Exchange Rates.

        // Setup: Run report Adjust Exchange Rates to verify Error Code, Actual error message: The adjustment of exchange rates has been canceled.
        Initialize();
        AdjustExchangeRatesReportErrors(WorkDate(), true, false, 'Dialog');  // Posting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesRequestPageHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAdjustExchangeRatesDocumentNoError()
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 595 Adjust Exchange Rates.

        // Setup: Run report Adjust Exchange Rates to verify Error Code, Actual error message: Document No. must be entered.
        Initialize();
        AdjustExchangeRatesReportErrors(WorkDate(), true, false, 'Dialog');  // Posting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPostingDateAdjustExchangeRatesStartDateError()
    begin
        // Purpose of the test is to validate CheckPostingDate function of Report ID - 595   Adjust Exchange Rates.

        // Setup: Run report Adjust Exchange Rates to verify Error Code, Actual error message: This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.
        Initialize();
        AdjustExchangeRatesReportErrors(CalcDate('<-CM>', WorkDate()), false, false, 'TestValidation');  // Posting Date less than Starting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPostingDateAdjustExchangeRatesEndDateError()
    begin
        // Purpose of the test is to validate CheckPostingDate function of Report ID -  Adjust Exchange Rates.

        // Setup: Run report Adjust Exchange Rates to verify Error Code, Actual error message: This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.
        Initialize();
        AdjustExchangeRatesReportErrors(CalcDate('<+CM>', WorkDate()), false, false, 'TestValidation');  // Posting Date more than Ending Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesDueDateLimitRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDueDateLimitAdjustExchangeRatesError()
    begin
        // Purpose of the test is to validate DueDateLimit - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run report Adjust Exchange Rates to verify Error Code, Actual error message: Short term liabilities until must not be before Valuation Reference Date.
        Initialize();
        AdjustExchangeRatesReportErrors(WorkDate(), false, false, 'TestValidation');  // Posting Date, Post, Adjust G/L Accounts for Add.-Reporting Currency and Expected Error Code.
    end;

    local procedure AdjustExchangeRatesReportErrors(PostingDate: Date; PostSettlement: Boolean; AdjGLAcc: Boolean; Expected: Text[1024])
    begin
        // Enqueue Required inside AdjustExchangeRatesRequestPageHandler and AdjustExchangeRatesDueDateLimitRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostSettlement);
        LibraryVariableStorage.Enqueue(AdjGLAcc);
        LibraryVariableStorage.Enqueue(PostingDate);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Adjust Exchange Rates");

        // Verify: Verify Error Code.
        Assert.ExpectedErrorCode(Expected);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesPostingDescRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageAdjExchRatesPostingDescriptionBlank()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Posting Description is updated automatically on Report Adjust Exchange Rates inside AdjustExchangeRatesPostingDescRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesValPerEndRequestPageHandler,NothingToAdjustMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateEndingDateAdjExchRatesUpdateControls()
    begin
        // Purpose of the test is to validate EndingDate - OnValidate Trigger of Report ID -  Adjust Exchange Rates.

        // Setup: Run Report to verify Valuation Reference Date is automatically updated as last day of the month of Ending Date on Report Adjust Exchange Rates inside AdjustExchangeRatesValPerEndRequestPageHandler.
        Initialize();
        AdjustExchangeRatesReport();
    end;

    local procedure AdjustExchangeRatesReport()
    begin
        // Exercise.
        REPORT.Run(REPORT::"Adjust Exchange Rates");

        // Verify: Verify various Fields in AdjustExchangeRatesPostingDescRequestPageHandler, AdjustExchangeRatesValPerEndRequestPageHandler and  AdjustExchangeRatesValuationMethodRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesCurrencyRequestPageHandler,ConfirmHandlerTRUE,NothingToAdjustMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyAdjustExchangeRates()
    var
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate Currency - OnAfterGetRecord Trigger of Report ID -  Adjust Exchange Rates.
        // Setup.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchangeRate();

        // Exercise.
        REPORT.Run(REPORT::"Adjust Exchange Rates");  // Opens AdjustExchangeRatesCurrencyRequestPageHandler.

        // Verify: Verify Posting Date of Report Adjust Exchange Rates is updated on Last Date Adjusted field of Currency.
        Currency.Get(CurrencyCode);
        Currency.TestField("Last Date Adjusted", WorkDate());
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesForCurrencyAndPostingDateRPH,ConfirmHandlerTRUE,AdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure PrintAdjAmountForVendorEntryClosedPriorAdjustment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
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

        // [THEN] Invoice Adjusted amount printed in report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendLedgEntryAdjAmt', -163.04);
    end;

    [Test]
    [HandlerFunctions('AdjustMessageHandler,AdjustExchangeRatesValuePerEndRequestPageHandler,ConfirmHandlerTRUE')]
    procedure AdjustExchangeRatesOnLowestValueForUnrealizedGainForVendor()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempCurrencyToAdjust: Record Currency temporary;
        CurrAdjAmount: Decimal;
        ExchangeDate: Date;
        ExchangeRateAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 522827] Adjust Exchange Rates should calculate Unrealized gain on Lowest Value on Currency gains original local currency value of the transaction.
        Initialize();

        // [GIVEN] Create a Currency.
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Set Gain and Loss Accounts in Currency.
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // [GIVEN] Validate Residual Gains Account, Residual Losses Account and Appln. Rounding Precision on Currency.
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Appln. Rounding Precision", 0);
        Currency.Modify(true);

        // [GIVEN] Store Exchange Date and Exchange Amount.
        ExchangeDate := LibraryRandom.RandDate(1) - LibraryRandom.RandIntInRange(1000, 1100);
        ExchangeRateAmount := LibraryRandom.RandDec(1, 3);

        // [GIVEN] Create Exchange Rate for Different Dates.
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 6, 1, ExchangeRateAmount + 2);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 5, 1, ExchangeRateAmount + 1.05);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 3, 1, 1);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate, 1, ExchangeRateAmount + 0.856);

        // [GIVEN] Create a Vendor and Validate Currency.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        // [GIVEN] Create a Purchase Invoice and Validate Posting Date to Exchange Date.
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", ExchangeDate);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Post Purchase Invoice.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Commit();

        // [GIVEN] Store the value of Closing Date, Vendor No. and Currency Code.
        LibraryVariableStorage.Enqueue(ExchangeDate + 5);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(Currency.Code);

        // [GIVEN] Find the Vendor Ledger Entry of the posted Purchase Invoice.
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)", "Remaining Amount");
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        VendorLedgerEntry.FindLast();

        // [GIVEN] Find the Currency Exchange Rate on the Starting Date.
        CurrencyExchangeRate.SetRange("Starting Date", ExchangeDate + 5);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // [GIVEN] Insert The Currency into temporary table and Validate Adjustment Exch Rate Amount.
        TempCurrencyToAdjust.Init();
        TempCurrencyToAdjust.Copy(Currency);
        TempCurrencyToAdjust.Validate("Currency Factor", CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        TempCurrencyToAdjust.Insert(true);

        // [GIVEN] Calculate the Current Adjustment Amount.
        CurrAdjAmount :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCYAdjmt(
                    ExchangeDate + 5, TempCurrencyToAdjust.Code, VendorLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                VendorLedgerEntry."Remaining Amt. (LCY)";

        // [GIVEN] Run Report Adjust Exchange Rates on Gain Date.
        Report.Run(Report::"Adjust Exchange Rates");

        // [THEN] Adjust Exchange Rates should calculate Unrealized gain on Lowest Value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendLedgEntryAdjAmt', CurrAdjAmount);
    end;

    [Test]
    [HandlerFunctions('AdjustMessageHandler,AdjustExchangeRatesValuePerEndRequestPageHandlerForCustomer,ConfirmHandlerTRUE')]
    procedure AdjustExchangeRatesOnLowestValueForUnrealizedGainForCustomer()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        TempCurrencyToAdjust: Record Currency temporary;
        CurrAdjAmount: Decimal;
        ExchangeDate: Date;
        ExchangeRateAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 522827] Adjust Exchange Rates should calculate Unrealized gain on Lowest Value on Currency gains original local currency value of the transaction.
        Initialize();

        // [GIVEN] Create a Currency.
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Set Gain and Loss Accounts in Currency.
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // [GIVEN] Validate Residual Gains Account, Residual Losses Account and Appln. Rounding Precision on Currency.
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Appln. Rounding Precision", 0);
        Currency.Modify(true);

        // [GIVEN] Store Exchange Date and Exchange Amount.
        ExchangeDate := LibraryRandom.RandDate(1) - LibraryRandom.RandIntInRange(1000, 1100);
        ExchangeRateAmount := LibraryRandom.RandDec(1, 3);

        // [GIVEN] Create Exchange Rate for Different Dates.
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 6, 1, ExchangeRateAmount + 2);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 5, 1, ExchangeRateAmount + 1.05);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate + 3, 1, 1);
        LibraryERM.CreateExchangeRate(Currency.Code, ExchangeDate, 1, ExchangeRateAmount + 0.856);

        // [GIVEN] Create a Customer and Validate Currency.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        // [GIVEN] Create a Sales Invoice and Validate Posting Date to Exchange Date.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader.Validate("Posting Date", ExchangeDate);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Post Sales Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        // [GIVEN] Store the value of Closing Date, Customer No. and Currency Code.
        LibraryVariableStorage.Enqueue(ExchangeDate + 5);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Currency.Code);

        // [GIVEN] Find the Customer Ledger Entry of the Posted Sales Invoice.
        CustomerLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)", "Remaining Amount");
        CustomerLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustomerLedgerEntry.SetRange("Document No.", InvoiceNo);
        CustomerLedgerEntry.FindLast();

        // [GIVEN] Find the Currency Exchange Rate on the Starting Date.
        CurrencyExchangeRate.SetRange("Starting Date", ExchangeDate + 5);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // [GIVEN] Insert The Currency into temporary table and Validate Adjustment Exch Rate Amount.
        TempCurrencyToAdjust.Init();
        TempCurrencyToAdjust.Copy(Currency);
        TempCurrencyToAdjust.Validate("Currency Factor", CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        TempCurrencyToAdjust.Insert(true);

        // [GIVEN] Calculate the Current Adjustment Amount.
        CurrAdjAmount :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCYAdjmt(
                    ExchangeDate + 5, TempCurrencyToAdjust.Code, CustomerLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                CustomerLedgerEntry."Remaining Amt. (LCY)";

        // [GIVEN] Run Report Adjust Exchange Rates on Gain Date.
        Report.Run(Report::"Adjust Exchange Rates");

        // [THEN] Adjust Exchange Rates should calculate Unrealized gain on Lowest Value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AdjAmt', CurrAdjAmount);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesBankAccounts,ConfirmHandlerTRUE,AdjustedMessageHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO 210882] "Adjust Exchange Rates" report generates the only total entry in "Exch. Rate Adjmt. Reg." for multiple bank accounts with the same bank account posting group

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

        // [WHEN] Run "Adjust Exchange Rates" for bank account with posting
        Commit();
        RunAdjExchRatesForVendorByDateBilMog(CurrencyCode, CalcDate('<CY>', StartingDate));

        // [THEN] The only total entry inserted into "Exch. Rate Adjmt. Reg." table
        ExchRateAdjmtReg.SetRange("Posting Group", BankAccountPostingGroup.Code);
        Assert.RecordCount(ExchRateAdjmtReg, 1);
        // [THEN] The adjusted base amount = 100 + 200;
        ExchRateAdjmtReg.FindFirst();
        ExchRateAdjmtReg.TestField("Adjusted Base", TotalAmount);
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
        LibraryVariableStorage.Enqueue(Currency.Code);  // Required inside AdjustExchangeRatesCurrencyRequestPageHandler.
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
        with GenJournalLine do begin
            LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, "Document Type"::Invoice,
              "Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "Gen. Posting Type"::Purchase),
              InvoiceAmount);
            Validate("Bal. Account Type", "Bal. Account Type"::Vendor);
            Validate("Bal. Account No.", VendorNo);
            Validate("Posting Date", PostingDate);
            Modify();
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            exit("Document No.");
        end;
    end;

    local procedure CreatePostPaymentAppliedToInvoice(VendorNo: Code[20]; PostingDate: Date; PaymentAmount: Decimal; InvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, "Document Type"::Payment,
              "Account Type"::Vendor, VendorNo, PaymentAmount);
            Validate("Posting Date", PostingDate);
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", InvoiceNo);
            Modify();
        end;
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

    local procedure RunAdjExchRatesForVendorByDateBilMog(CurrencyCode: Code[10]; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(RatesAdjustedMsg);
        REPORT.Run(REPORT::"Adjust Exchange Rates");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        PostSettlement: Variant;
        AdjGLAcc: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostSettlement);
        LibraryVariableStorage.Dequeue(AdjGLAcc);
        LibraryVariableStorage.Dequeue(PostingDate);
        AdjustExchangeRates.Post.SetValue(PostSettlement);
        AdjustExchangeRates.AdjGLAcc.SetValue(AdjGLAcc);
        AdjustExchangeRates.StartingDate.SetValue(WorkDate());
        AdjustExchangeRates.EndingDate.SetValue(WorkDate());
        AdjustExchangeRates.PostingDate.SetValue(PostingDate);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesDueDateLimitRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    begin
        AdjustExchangeRates.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        AdjustExchangeRates.ValPerEnd.SetValue(CalcDate('<+CM>', WorkDate()));
        AdjustExchangeRates.DueDateLimit.SetValue(WorkDate());  // Less than ValPerEnd.
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesPostingDescRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    begin
        AdjustExchangeRates.PostingDescription.AssertEquals('Adjmt. of %1 %2, Ex.Rate Adjust.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValPerEndRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    begin
        AdjustExchangeRates.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        AdjustExchangeRates.EndingDate.SetValue(WorkDate());
        AdjustExchangeRates.PostingDate.AssertEquals(WorkDate());
        AdjustExchangeRates.ValPerEnd.AssertEquals(CalcDate('<+CM>', WorkDate()));  // ValPerEnd is equal to Last day of month of Posting Date.
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesValuationMethodRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    begin
        AdjustExchangeRates.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        AdjustExchangeRates.ValPerEnd.SetValue(WorkDate());
        AdjustExchangeRates.DueDateLimit.AssertEquals(CalcDate('<+1Y>', WorkDate()));  // DueDateLimit is equal to same day of next year of ValPerEnd.
        Assert.IsTrue(AdjustExchangeRates.DueDateLimit.Enabled(), FieldMustEnabledMsg);
        Assert.IsTrue(AdjustExchangeRates.ValPerEnd.Enabled(), FieldMustEnabledMsg);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesCurrencyRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        AdjustExchangeRates.AdjustBankAccounts.SetValue(true);
        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.DocumentNo.SetValue('DocumentNo');
        AdjustExchangeRates.EndingDate.SetValue(WorkDate());
        AdjustExchangeRates.PostingDate.SetValue(WorkDate());
        AdjustExchangeRates.Currency.SetFilter(Code, CurrencyCode);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesForCurrencyAndPostingDateRPH(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        PostingDate: Variant;
    begin
        AdjustExchangeRates.Currency.SetFilter(Code, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Dequeue(PostingDate);
        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.AdjVendors.SetValue(true);
        AdjustExchangeRates.EndingDate.SetValue(PostingDate);
        AdjustExchangeRates.DocumentNo.SetValue('DocumentNo');
        AdjustExchangeRates.PostingDate.SetValue(PostingDate);
        AdjustExchangeRates.Method.SetValue(RefValuationMethod::"BilMoG (Germany)");
        AdjustExchangeRates.ValPerEnd.SetValue(PostingDate);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesBankAccounts(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        PostingDate: Variant;
    begin
        AdjustExchangeRates.Currency.SetFilter(Code, LibraryVariableStorage.DequeueText());

        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.AdjustBankAccounts.SetValue(true);

        LibraryVariableStorage.Dequeue(PostingDate);
        AdjustExchangeRates.StartingDate.SetValue(CalcDate('<-CY>', PostingDate));
        AdjustExchangeRates.EndingDate.SetValue(PostingDate);
        AdjustExchangeRates.PostingDate.SetValue(PostingDate);
        AdjustExchangeRates.DocumentNo.SetValue(LibraryUtility.GenerateRandomText(10));
        AdjustExchangeRates.Method.SetValue(RefValuationMethod::Standard);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure AdjustExchangeRatesValuePerEndRequestPageHandler(var ExchRateAdjustment: TestRequestPage "Adjust Exchange Rates")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"Lowest Value");
        ExchRateAdjustment.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        ExchRateAdjustment.AdjVendors.SetValue(true);
        ExchRateAdjustment.DocumentNo.SetValue(LibraryRandom.RandText(3));
        ExchRateAdjustment.Post.SetValue(true);
        ExchRateAdjustment.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.Currency.SetFilter("Code", LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure AdjustExchangeRatesValuePerEndRequestPageHandlerForCustomer(var ExchRateAdjustment: TestRequestPage "Adjust Exchange Rates")
    begin
        ExchRateAdjustment.Method.SetValue(RefValuationMethod::"Lowest Value");
        ExchRateAdjustment.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        ExchRateAdjustment.AdjustCustomer.SetValue(true);
        ExchRateAdjustment.DocumentNo.SetValue(LibraryRandom.RandText(3));
        ExchRateAdjustment.Post.SetValue(true);
        ExchRateAdjustment.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.Currency.SetFilter("Code", LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFALSE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
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
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    procedure AdjustMessageHandler(Message: Text[1024])
    begin
    end;
}
#endif