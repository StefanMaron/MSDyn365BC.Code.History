codeunit 144054 "Test CH FCY"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate] [Currency]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCH: Codeunit "Library - CH";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        WrongNoOfEntriesErr: Label 'Number of VAT Entries is not %1.';
        ExchRateAdjustedMsg: Label 'One or more currency exchange rates have been adjusted.';
        UseAdjExchRateGLMsg: Label 'If you use foreign currencies in G/L, you have to run the report "Adjust Exchange Rates G/L".';
        NothingToAdjustMsg: Label 'There is nothing to adjust.';

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFCYEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        Initialize;

        // Setup.
        SetupFCYGLEntries(GenJournalLine,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst;
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");

        // Verify.
        GLEntry.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type");
        GLEntry.SetRange("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst;
        GLEntry.TestField(Amount, GenJournalLine."Amount (LCY)");
        GLEntry.TestField("Amount (FCY)", 0);

        GLEntry.SetRange("Bal. Account Type", GenJournalLine."Account Type");
        GLEntry.SetRange("Bal. Account No.", GenJournalLine."Account No.");
        GLEntry.FindFirst;
        GLEntry.TestField(Amount, -GenJournalLine."Amount (LCY)");
        GLEntry.TestField("Amount (FCY)", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressFCYEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        DateComprRegister: Record "Date Compr. Register";
        SourceCodeSetup: Record "Source Code Setup";
        DateCompressGeneralLedger: Report "Date Compress General Ledger";
    begin
        Initialize;

        // Setup.
        SetupFCYGLEntries(GenJournalLine,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(GenJournalLine2, GenJournalLine."Account No.", GenJournalLine."Bal. Account No.",
          CalcDate('<CM>', GenJournalLine."Posting Date"));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Exercise.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.", GenJournalLine2."Document No.");
        DateCompressGeneralLedger.InitializeRequest(GenJournalLine."Posting Date", GenJournalLine2."Posting Date",
          DateComprRegister."Period Length"::Month, '', false, false, false, true, false, '');
        DateCompressGeneralLedger.UseRequestPage(false);
        DateCompressGeneralLedger.SetTableView(GLEntry);
        DateCompressGeneralLedger.Run;

        // Verify.
        SourceCodeSetup.Get();
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst;
        GLEntry.TestField("Source Code", SourceCodeSetup."Compress G/L");
        GLEntry.TestField("Document Type", GLEntry."Document Type"::" ");
        GLEntry.TestField("Document No.", '');
        GLEntry.TestField("Amount (FCY)", -GenJournalLine.Amount - GenJournalLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,PreciseMsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjExchRateFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        Initialize;

        // [GIVEN] Posted Sales Invoice journal line in currency 'USD'
        SetupFCYGLEntries(GenJournalLine,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [GIVEN] Exchnage Rate is modified in currency 'USD'
        CurrencyExchangeRate.SetRange("Currency Code", GenJournalLine."Currency Code");
        CurrencyExchangeRate.ModifyAll("Relational Exch. Rate Amount",
          CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandDec(10, 2), true);
        CurrencyExchangeRate.ModifyAll("Relational Adjmt Exch Rate Amt",
          CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" + LibraryRandom.RandDec(10, 2), true);
        CurrencyExchangeRate.FindFirst;
        // [GIVEN] Unrealized Gain/Loss accounts are set for 'USD'
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Get(GenJournalLine."Currency Code");
        Currency.Validate("Unrealized Losses Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Gains Acc.", GLAccount."No.");
        Currency.Modify(true);

        // [WHEN] Run "Adjust Exchange Rates" report
        DocumentNo := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        LibraryVariableStorage.Enqueue(ExchRateAdjustedMsg);
        LibraryVariableStorage.Enqueue(UseAdjExchRateGLMsg);
        Currency.SetRange(Code, Currency.Code);
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);

        // [THEN] Message shown: "Exchange Rates have been adjusted."
        // [THEN] Message shown: "If you use foreign currencies in G/L, you have to run the report Adjust Exchange Rates G/L."
        // [THEN] Cust. Ledger Entry Amount and exchange rates are printed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Cust', GenJournalLine."Account No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('CurrCode_CustLedgEntry', GenJournalLine."Currency Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_CustLedgEntry', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmtLCY_CustLedgEntry', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('ExchRateAmt', CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('AdjmtExchRateAmt', CurrencyExchangeRate."Relational Adjmt Exch Rate Amt");
    end;

    [Normal]
    local procedure AdjVATSales(VATCalcType: Option)
    var
        Currency: Record Currency;
        DimensionValue: Record "Dimension Value";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DocumentNo: Code[20];
        GlobalDimCode: array[2] of Code[20];
    begin
        Initialize;

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, VATCalcType);

        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        Customer.Validate("Global Dimension 1 Code", DimensionValue.Code);
        GlobalDimCode[1] := DimensionValue.Code;
        Customer."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Document's VAT Entry, where "Unadjusted Exchange Rate" is 'Yes'
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, DocumentNo, Customer."No.", SalesLine.Amount, false);

        // Adjust.
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Document No."), DATABASE::"Sales Line"));
        LibraryVariableStorage.Enqueue(false);
        Commit();
        if VATCalcType = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            LibraryVariableStorage.Enqueue(NothingToAdjustMsg)
        else
            LibraryVariableStorage.Enqueue(ExchRateAdjustedMsg);
        LibraryVariableStorage.Enqueue(UseAdjExchRateGLMsg);
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);

        // [THEN] Document's VAT Entry, where "Unadjusted Exchange Rate" is 'No'
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, DocumentNo, Customer."No.", SalesLine.Amount,
          VATCalcType = VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [THEN] Adjustment VAT Entry, where "Exchange Rate Adjustment" is 'Yes', values of Base, Amount, "Document No." match the report's line
        if VATCalcType = VATPostingSetup."VAT Calculation Type"::"Normal VAT" then
            VerifyAdjmtVATEntryInReport(DocumentNo, CurrencyExchangeRate, GlobalDimCode, SalesLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,PreciseMsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseVATSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        AdjVATSales(VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,PreciseMsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NormalVATSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        AdjVATSales(VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [Normal]
    local procedure AdjVATPurchase(VATCalcType: Option)
    var
        DimensionValue: Record "Dimension Value";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DocumentNo: Code[20];
        GlobalDimCode: array[2] of Code[20];
    begin
        Initialize;

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, VATCalcType);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        Vendor.Validate("Global Dimension 2 Code", DimensionValue.Code);
        GlobalDimCode[2] := DimensionValue.Code;
        Vendor.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, DocumentNo, Vendor."No.", PurchaseLine.Amount, false);

        // Adjust.
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Document No."),
            DATABASE::"Purchase Line"));
        LibraryVariableStorage.Enqueue(false);
        Commit();
        LibraryVariableStorage.Enqueue(ExchRateAdjustedMsg);
        LibraryVariableStorage.Enqueue(UseAdjExchRateGLMsg);
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);
        Commit();
        // Verify.
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, DocumentNo, Vendor."No.", PurchaseLine.Amount, true);
        // [THEN] Adjustment VAT Entry, where "Exchange Rate Adjustment" is 'Yes', values of Base, Amount, "Document No." match the report's line
        VerifyAdjmtVATEntryInReport(DocumentNo, CurrencyExchangeRate, GlobalDimCode, PurchaseLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,PreciseMsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseVATPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        AdjVATPurchase(VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,PreciseMsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NormalVATPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        AdjVATPurchase(VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchJournalAndModifiedExchRate()
    var
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        // Verify that correct number of VAT Entries created after running Currency Adjustment.

        // Init
        Initialize;
        CurrencyCode := CreateCurrencyAndExchangeRate;

        // Exercize
        DocumentNo := CreateAndPostInvoicePurchaseJournal(CreateGLAccountWithFullVAT, CurrencyCode);
        ModifyExchangeRateAmount(CurrencyCode, false);
        RunAdjustExchangeRates(CurrencyCode, false);

        // Verify
        VerifyNumberOfFullVATEntry(DocumentNo, 2);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForFCYEntryWithDifferentARC()
    var
        CurrencyARC: Record Currency;
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 263230] VAT Exch. Rate Adjustment for FCY entry when ARC has different currency
        Initialize;
        GLRegister.FindLast();

        // [GIVEN] Additional Reporting Currency is 'EUR' with exch.rate = 0.9212
        CurrencyARC.Code := CreateCurrencyWithRelExchangeRates(0.9212);
        LibraryERM.SetAddReportingCurrency(CurrencyARC.Code);
        UpdateReportingOnGLSetup;

        // [GIVEN] Posted Gen. Journal Line in 'USD' with Amount = 23000 and exch. rate = 1.5
        Currency.Code := CreateCurrencyWithRelExchangeRates(0.9212);
        CreateAndPostGenJnlLineWithZeroVATAndCurrencyFactor(GenJournalLine, Currency.Code, 23000, 1.5);

        // [WHEN] Run Adjust Exch. Rates for 'EUR|USD'
        RunAdjustExchangeRates(StrSubstNo('%1|%2', Currency.Code, CurrencyARC.Code), true);

        // [THEN] Two VAT Entries with G/L Register for each one
        // [THEN] First VAT Entry has Base = 34500, "Base FCY" = 23000, "Additional-Currency Base" = 37451.15
        // [THEN] Second correction VAT Entry has Base = -13312.40, "Base FCY" = 0, "Additional-Currency Base" = -14451.15
        // [THEN] Adjust exch. rate G/L Register has filled "Creation Time", zeros From-To G\L Entry Nos and filled From-To VAT Entry Nos (TFS 371023)
        VerifyAdjmtBase(
          GenJournalLine."Document No.", 34500, 23000, 37451.15, -13312.4, 0, -14451.15, GLRegister."No." + 1);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForFCYEntryWithSameARC()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 263230] VAT Exch. Rate Adjustment for FCY entry when ARC has same currency
        Initialize;
        UpdateReportingOnGLSetup;
        GLRegister.FindLast();

        // [GIVEN] Additional Reporting Currency is 'EUR' with exch.rate = 0.9212
        Currency.Code := CreateCurrencyWithRelExchangeRates(0.9212);
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        // [GIVEN] Posted Gen. Journal Line in 'EUR' with Amount = 23000 and exch. rate = 1.5
        CreateAndPostGenJnlLineWithZeroVATAndCurrencyFactor(GenJournalLine, Currency.Code, 23000, 1.5);

        // [WHEN] Run Adjust Exch. Rates for for 'EUR'
        RunAdjustExchangeRates(Currency.Code, true);

        // [THEN] Two VAT Entries with G/L Register for each one
        // [THEN] First VAT Entry has Base = 34500, "Base FCY" = 23000, "Additional-Currency Base" = 23000
        // [THEN] Second correction VAT Entry has Base = -13312.40, "Base FCY" = 0, "Additional-Currency Base" = 0
        // [THEN] Adjust exch. rate G/L Register has filled "Creation Time", zeros From-To G\L Entry Nos and filled From-To VAT Entry Nos (TFS 371023)
        VerifyAdjmtBase(
          GenJournalLine."Document No.", 34500, 23000, 23000, -13312.4, 0, 0, GLRegister."No." + 1);
    end;

    [Test]
    [HandlerFunctions('AdjVATExchRatesRPH,ConfirmHandler,MessageHandler')]
    procedure AdjustVATExchRateFor2InvoicesWithForwardDateOrder()
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 371023] Adjust VAT exch. rates for two sales invoices with forward posting date order

        // [GIVEN] Create post USD sales invoice on "19-09-2020" (G/L Register No. = 10, From VAT Entry No. = To VAT Entry No. = 100)
        // [GIVEN] Create post USD sales invoice on "20-09-2020" (G/L Register No. = 11, From VAT Entry No. = To VAT Entry No. = 101)
        // [GIVEN] Change USD VAT exchange rates on "19-09-2020"

        // [WHEN] Run Adjust Exch. Rates for USD currency (adjust VAT = true)
        AdjustVATExchRateFor2InvoicesWithDateOrder(WorkDate(), WorkDate() + 1);

        // [THEN] There are two new G/L registers:
        // [THEN] G/L Register No. = 12, From VAT Entry No. = To VAT Entry No. = 102
        // [THEN] G/L Register No. = 13, From VAT Entry No. = To VAT Entry No. = 103
    end;

    [Test]
    [HandlerFunctions('AdjVATExchRatesRPH,ConfirmHandler,MessageHandler')]
    procedure AdjustVATExchRateFor2InvoicesWithReversedDateOrder()
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 371023] Adjust VAT exch. rates for two sales invoices with reversed posting date order

        // [GIVEN] Create post USD sales invoice on "20-09-2020" (G/L Register No. = 10, From VAT Entry No. = To VAT Entry No. = 100)
        // [GIVEN] Create post USD sales invoice on "19-09-2020" (G/L Register No. = 11, From VAT Entry No. = To VAT Entry No. = 101)
        // [GIVEN] Change USD VAT exchange rates on "19-09-2020"

        // [WHEN] Run Adjust Exch. Rates for USD currency (adjust VAT = true)
        AdjustVATExchRateFor2InvoicesWithDateOrder(WorkDate() + 1, WorkDate());

        // [THEN] There are two new G/L registers:
        // [THEN] G/L Register No. = 12, From VAT Entry No. = To VAT Entry No. = 102
        // [THEN] G/L Register No. = 13, From VAT Entry No. = To VAT Entry No. = 103
    end;

    local procedure AdjustVATExchRateFor2InvoicesWithDateOrder(Date1: Date; Date2: Date)
    var
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        CurrencyCode: Code[10];
        MinDate: Date;
        MaxDate: Date;
    begin
        Initialize();
        LibraryERM.SetInvRoundingPrecisionLCY(0.01);
        CurrencyCode := CreateCurrencyAndExchangeRate();
        GLRegister.FindLast();
        VATEntry.FindLast();

        IF Date1 < Date2 then begin
            MinDate := Date1;
            MaxDate := Date2;
        end else begin
            MinDate := Date2;
            MaxDate := Date1;
        end;

        CreatePostSalesInvoice(Date1, CurrencyCode);
        VerifyGLRegisterWithGLAndVAT(GLRegister."No." + 1, VATEntry."Entry No." + 1, VATEntry."Entry No." + 1);

        CreatePostSalesInvoice(Date2, CurrencyCode);
        VerifyGLRegisterWithGLAndVAT(GLRegister."No." + 2, VATEntry."Entry No." + 2, VATEntry."Entry No." + 2);

        ModifyExchangeRateAmount(CurrencyCode, TRUE);
        RunAdjustVATExchRates(CurrencyCode, MinDate, MaxDate, MaxDate);

        VerifyGLRegisterWithGLAndVAT(GLRegister."No." + 3, VATEntry."Entry No." + 3, VATEntry."Entry No." + 3);
        VerifyGLRegisterWithGLAndVAT(GLRegister."No." + 4, VATEntry."Entry No." + 4, VATEntry."Entry No." + 4);
    end;

    local procedure Initialize()
    var
        AnalysisView: Record "Analysis View";
        AccountingPeriod: Record "Accounting Period";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH FCY");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH FCY");

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        AnalysisView.DeleteAll();
        AccountingPeriod.ModifyAll("Date Locked", true);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH FCY");
    end;

    local procedure CreateCurrencyAndExchangeRate() CurrencyCode: Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyCode := CreateCurrency;
        LibraryERM.CreateRandomExchangeRate(CurrencyCode);

        with CurrencyExchangeRate do begin
            SetRange("Currency Code", CurrencyCode);
            FindFirst;
            Validate("VAT Exch. Rate Amount", "Exchange Rate Amount");
            Validate("Relational VAT Exch. Rate Amt", "Relational Exch. Rate Amount");
            Modify(true);
        end;
    end;

    local procedure CreateCurrencyWithRelExchangeRates(RelExchRateAmount: Decimal) CurrencyCode: Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyCode := CreateCurrency;
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate);
        with CurrencyExchangeRate do begin
            Validate("Exchange Rate Amount", 1);
            Validate("Relational Exch. Rate Amount", RelExchRateAmount);
            Validate("Adjustment Exch. Rate Amount", 1);
            Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount);
            Validate("VAT Exch. Rate Amount", 1);
            Validate("Relational VAT Exch. Rate Amt", RelExchRateAmount);
            Modify(true);
        end;
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with Currency do begin
            GeneralLedgerSetup.Get();
            LibraryERM.CreateCurrency(Currency);

            Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            Validate("Residual Gains Account", CreateGLAccount);
            Validate("Residual Losses Account", CreateGLAccount);
            Validate("Realized G/L Gains Account", CreateGLAccount);
            Validate("Realized G/L Losses Account", CreateGLAccount);
            Validate("Realized Gains Acc.", CreateGLAccount);
            Validate("Realized Losses Acc.", CreateGLAccount);
            Validate("Unrealized Gains Acc.", CreateGLAccount);
            Validate("Unrealized Losses Acc.", CreateGLAccount);
            Modify(true);

            exit(Code);
        end;
    end;

    local procedure ModifyExchangeRateAmount(CurrencyCode: Code[10]; IsRaise: Boolean)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RaiseValue: Decimal;
    begin
        if IsRaise then
            RaiseValue := 1 / 3
        else
            RaiseValue := 3;
        with CurrencyExchangeRate do begin
            SetRange("Currency Code", CurrencyCode);
            FindFirst;
            Validate("Relational Exch. Rate Amount", "Relational Exch. Rate Amount" * RaiseValue);
            Validate("Relational Adjmt Exch Rate Amt", "Relational Exch. Rate Amount" * RaiseValue);
            Validate("Relational VAT Exch. Rate Amt", "Relational Exch. Rate Amount" * RaiseValue);
            Modify(true);
        end;
    end;

    local procedure FindNoVATGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst;
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRate: Decimal)
    begin
        with CurrencyExchangeRate do begin
            Init;
            Validate("Currency Code", CurrencyCode);
            Validate("Starting Date", WorkDate);
            Insert(true);

            Validate("Exchange Rate Amount", 100);
            Validate("Adjustment Exch. Rate Amount", 100);
            Validate("Relational Exch. Rate Amount", ExchRate);
            Validate("Relational Adjmt Exch Rate Amt", ExchRate);
            Validate("VAT Exch. Rate Amount", 100);
            Validate("Relational VAT Exch. Rate Amt", ExchRate * (100 + LibraryRandom.RandIntInRange(1, 5)) / 100);
            Modify(true);
        end;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithFullVAT() GLAccountCode: Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GLAccountCode := CreateGLAccount;

        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        CreateVATPostingSetup(
          GLAccountCode, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code,
          VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        with GLAccount do begin
            Get(GLAccountCode);
            Validate("Gen. Posting Type", "Gen. Posting Type"::Purchase);
            Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
            Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
            Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
            Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
            Modify;
        end;
    end;

    local procedure CreateAndPostInvoicePurchaseJournal(GLAccountNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExtDocNo: Code[10];
        Amount: Decimal;
    begin
        FindGenJournalTemplateAndBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::Purchases);
        ExtDocNo := LibraryUtility.GenerateGUID;

        AddPurchaseInvJournalLine(
          GenJournalLine, GenJournalBatch, ExtDocNo, CurrencyCode, GenJournalLine."Account Type"::"G/L Account",
          FindNoVATGLAccount, LibraryRandom.RandDecInRange(100, 1000, 2));
        Amount := GenJournalLine.Amount;
        AddPurchaseInvJournalLine(
          GenJournalLine, GenJournalBatch, ExtDocNo, CurrencyCode, GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandDecInRange(10, 100, 2));
        AddPurchaseInvJournalLine(
          GenJournalLine, GenJournalBatch, ExtDocNo, CurrencyCode, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo, -(Amount + GenJournalLine.Amount));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJnlLineWithZeroVATAndCurrencyFactor(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; LineAmount: Decimal; CurrencyFactor: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LineAmount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Currency Factor", 1 / CurrencyFactor);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostSalesInvoice(PostingDate: Date; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FindGenJournalTemplateAndBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Option)
    begin
        GenJournalTemplate.SetRange(Type, TemplateType);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure AddPurchaseInvJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; ExtDocNo: Code[20]; CurrencyCode: Code[10]; AccountType: Option; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
        with GenJournalLine do begin
            Validate("Currency Code", CurrencyCode);
            Validate("External Document No.", ExtDocNo);
            Modify;
        end;
    end;

    local procedure CreateVATPostingSetup(GLAccountCode: Code[20]; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; VATCalculationType: Option; VATPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroupCode);
        with VATPostingSetup do begin
            Validate("VAT Calculation Type", VATCalculationType);
            Validate("VAT %", VATPercent);
            Validate("Purchase VAT Account", GLAccountCode);
            Modify;
        end;
    end;

    local procedure RunAdjustExchangeRates(CurrencyCode: Text; AdjustGLAcc: Boolean)
    var
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
    begin
        Currency.SetFilter(Code, CurrencyCode);
        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Document No."), DATABASE::"Purchase Line"));
        LibraryVariableStorage.Enqueue(AdjustGLAcc);
        Commit();
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);
    end;

    local procedure RunAdjustVATExchRates(CurrencyCode: Code[10]; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    var
        Currency: Record Currency;
    begin
        Currency.SetRange(Code, CurrencyCode);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        Commit();
        Report.Run(Report::"Adjust Exchange Rates", true, false, Currency);
    end;

    local procedure SetupFCYGLEntries(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Currency Code" := CurrencyCode;
        GLAccount.Modify(true);
        CreateGenJournalLine(GenJournalLine, Customer."No.", GLAccount."No.", WorkDate);
    end;

    local procedure SetupVATForFCY(var VATPostingSetup: Record "VAT Posting Setup"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; VATCalcType: Option)
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Validate("Realized Losses Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Gains Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Losses Acc.", GLAccount."No.");
        Currency.Modify(true);
        CreateExchangeRate(CurrencyExchangeRate, Currency.Code, LibraryRandom.RandDec(100, 2));
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATCalcType, '', '');
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; BalAccountNo: Code[20]; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateReportingOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Exchange Rate Adjustment", GeneralLedgerSetup."VAT Exchange Rate Adjustment"::"Adjust Amount");
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVATEntry(CurrencyExchangeRate: Record "Currency Exchange Rate"; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; CustomerNo: Code[20]; Amount: Decimal; IsAdjusted: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Exchange Rate Adjustment", false);
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        Assert.AreEqual(1, VATEntry.Count, 'Unexpected VAT entries.');
        VATEntry.FindFirst;
        VATEntry.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
        VATEntry.TestField("VAT %", VATPostingSetup."VAT %");
        VATEntry.TestField("Currency Factor", CurrencyExchangeRate.GetCurrentCurrencyFactor(CurrencyExchangeRate."Currency Code"));
        VATEntry.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
        Assert.AreEqual(Abs(VATEntry."Base (FCY)"), Abs(Amount), VATEntry.FieldName("Base (FCY)"));
        VATEntry.TestField("Unadjusted Exchange Rate", not IsAdjusted);
    end;

    local procedure VerifyNumberOfFullVATEntry(DocumentNo: Code[20]; ExpectedNoOfEntries: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("VAT Calculation Type", "VAT Calculation Type"::"Full VAT");
            Assert.AreEqual(ExpectedNoOfEntries, Count, StrSubstNo(WrongNoOfEntriesErr, ExpectedNoOfEntries));
        end;
    end;

    local procedure VerifyAdjmtBase(DocumentNo: Code[20]; InitialBase: Decimal; InitialBaseFCY: Decimal; InitialBaseARC: Decimal; CorrBase: Decimal; CorrBaseFCY: Decimal; CorrBaseARC: Decimal; StartingGLRegNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, 2);

        VATEntry.FindSet();
        VerifyGLRegisterWithGLAndVAT(StartingGLRegNo, VATEntry."Entry No.", VATEntry."Entry No.");
        VerifyAdjmtVATEntry(VATEntry, InitialBase, InitialBaseFCY, InitialBaseARC, false);

        VATEntry.Next();
        VerifyGLRegisterWithOnlyVAT(StartingGLRegNo + 1, VATEntry."Entry No.", VATEntry."Entry No.");
        VerifyAdjmtVATEntry(VATEntry, CorrBase, CorrBaseFCY, CorrBaseARC, true);
    end;

    local procedure VerifyAdjmtVATEntry(VATEntry: Record "VAT Entry"; Base: Decimal; BaseFCY: Decimal; BaseARC: Decimal; ExchRateAdjmt: Boolean)
    begin
        VATEntry.TestField(Base, Base);
        VATEntry.TestField(Amount, 0);
        VATEntry.TestField("Base (FCY)", BaseFCY);
        VATEntry.TestField("Amount (FCY)", 0);
        VATEntry.TestField("Additional-Currency Base", BaseARC);
        VATEntry.TestField("Additional-Currency Amount", 0);
        VATEntry.TestField("Exchange Rate Adjustment", ExchRateAdjmt);
    end;

    local procedure VerifyAdjmtVATEntryInReport(DocumentNo: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate"; GlobalDimCode: array[2] of Code[20]; DimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        Variant: Variant;
        Date: Date;
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Exchange Rate Adjustment", true);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst;

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('EntryNo_VATEntry', VATEntry."Entry No.");
        LibraryReportDataset.GetLastRow;
        LibraryReportDataset.FindCurrentRowValue('PostingDate_VATEntry', Variant);
        Assert.IsTrue(Evaluate(Date, CopyStr(Variant, 1, 10), 9), 'Posting date is not evaluated');
        Assert.AreEqual(VATEntry."Posting Date", Date, VATEntry.FieldName("Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentType_VATEntry', Format(VATEntry."Document Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_VATEntry', VATEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Base_VATEntry', VATEntry.Base);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_VATEntry', VATEntry.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATExchRateAmt', CurrencyExchangeRate."VAT Exch. Rate Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'RelationalVATExchRateAmt', CurrencyExchangeRate."Relational VAT Exch. Rate Amt");

        GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
        Assert.IsTrue(GLEntryVATEntryLink.FindFirst, 'missed link to G/L');
        GLEntry.Get(GLEntryVATEntryLink."G/L Entry No.");
        GLEntry.TestField("Global Dimension 1 Code", GlobalDimCode[1]);
        GLEntry.TestField("Global Dimension 2 Code", GlobalDimCode[2]);
        GLEntry.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyGLRegisterWithGLAndVAT(GLRegisterNo: Integer; FromVATEntryNo: Integer; ToVATEntryNo: Integer)
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.Get(GLRegisterNo);
        GLRegister.TestField("Creation Time");
        GLRegister.TestField("From Entry No.");
        GLRegister.TestField("To Entry No.");
        GLRegister.TestField("From VAT Entry No.", FromVATEntryNo);
        GLRegister.TestField("To VAT Entry No.", ToVATEntryNo);
    end;

    local procedure VerifyGLRegisterWithOnlyVAT(GLRegisterNo: Integer; FromVATEntryNo: Integer; ToVATEntryNo: Integer)
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.Get(GLRegisterNo);
        GLRegister.TestField("Creation Time");
        GLRegister.TestField("From Entry No.", 0);
        GLRegister.TestField("To Entry No.", 0);
        GLRegister.TestField("From VAT Entry No.", FromVATEntryNo);
        GLRegister.TestField("To VAT Entry No.", ToVATEntryNo);
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PreciseMsgHandler(Msg: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Msg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandler(var ReverseEntries: TestPage "Reverse Entries")
    begin
        ReverseEntries.Reverse.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesReqPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        DocNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocNo);
        AdjustExchangeRates.StartingDate.SetValue(WorkDate);
        AdjustExchangeRates.EndingDate.SetValue(WorkDate);
        AdjustExchangeRates.PostingDate.SetValue(WorkDate);
        AdjustExchangeRates.DocumentNo.SetValue(DocNo);
        AdjustExchangeRates.AdjCustomers.SetValue(true);
        AdjustExchangeRates.AdjVendors.SetValue(true);
        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.AdjGLAcc.SetValue(LibraryVariableStorage.DequeueBoolean);
        AdjustExchangeRates.AdjVAT.SetValue(true);
        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    procedure AdjVATExchRatesRPH(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates");
    begin
        AdjustExchangeRates.StartingDate.SetValue(LibraryVariableStorage.DequeueDate);
        AdjustExchangeRates.EndingDate.SetValue(LibraryVariableStorage.DequeueDate);
        AdjustExchangeRates.PostingDate.SetValue(LibraryVariableStorage.DequeueDate);
        AdjustExchangeRates.DocumentNo.SetValue(LibraryVariableStorage.DequeueText);
        AdjustExchangeRates.AdjCustomers.SetValue(false);
        AdjustExchangeRates.AdjVendors.SetValue(false);
        AdjustExchangeRates.AdjGLAcc.SetValue(false);
        AdjustExchangeRates.AdjVAT.SetValue(true);
        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.SAVEASXML(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

