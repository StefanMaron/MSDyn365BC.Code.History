﻿#if not CLEAN23
#pragma warning disable AS0072
codeunit 134080 "ERM Adjust Exch Rate Cust/Bank"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;
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
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AmountErr: Label '%1 field must be %2 in %3 table for %4 field %5.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        ReversalSuccessfullTxt: Label 'The entries were successfully reversed.';
        GLEntryAmountErr: Label '%1 must be %2 in %3.';
        PostingDate: Date;
        SetHandler: Boolean;
        DocTypeReversalErr: Label 'You cannot reverse the entry %1 because it''s an %2 Document.';

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CustAdjustExchRateForHigher()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Check that after Modify Higher Exchange rate and run Adjust Exchange rate batch job Unrealized Gain entry created
        // Customer's Detailed Ledger Entry.
        Initialize();
        AdjustExchRateForCustomer(LibraryRandom.RandInt(50), DetailedCustLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CustAdjustExchRateForLower()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Check that after Modify Lower Exchange rate and run Adjust Exchange rate batch job Unrealized Loss entry created on
        // Customer's Detailed Ledger Entry.
        Initialize();
        AdjustExchRateForCustomer(-LibraryRandom.RandInt(50), DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAdjustExchRateForHigher()
    begin
        // Check that after Modify Higher Exchange rate and run Adjust Exchange rate batch job GL entry created on for Bank Account.
        Initialize();
        AdjustExchRateForBank(LibraryRandom.RandInt(50));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAdjustExchRateForLower()
    begin
        // Check that after Modify Lower Exchange rate and run Adjust Exchange rate batch job GL entry created on for Bank Account.
        Initialize();
        AdjustExchRateForBank(-LibraryRandom.RandInt(50));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedGainCreditMemoCust()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Check Customer Entry for Unrealized Gain with Apply Credit Memo and Refund.

        // Setup: Modify Exchange Rate and Run Adjust Exchange Rate Batch after Create and Post General Journal Line for Customer.
        Initialize();
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CreateCurrency()),
          GenJournalLine."Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2), -LibraryRandom.RandInt(50));
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());
        Amount :=
          Round(
            GenJournalLine."Amount (LCY)" - LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate()));
        CreateGeneralJournalLine(
          GenJournalLine2, GenJournalLine."Account Type", GenJournalLine."Account No.", GenJournalLine2."Document Type"::Refund,
          -GenJournalLine.Amount / 2);  // Take partial amount for Refund Entry.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Exercise: Apply Customer Entry for Credit Memo.
        ApplyAndPostCustomerEntry(
          GenJournalLine2."Document No.", GenJournalLine2.Amount, GenJournalLine."Document No.", CustLedgerEntry."Document Type"::Refund,
          CustLedgerEntry."Document Type"::"Credit Memo");

        // Verify: Verify Detailed Ledger Entry for correct entry after made from running Adjust Exchange Rate Batch Job.
        VerifyDetailedLedgerEntry(GenJournalLine2."Currency Code", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain", -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        // Verify program allows to create General journal line with a Balancing Account Type Bank with presetup Currency.

        // Setup: Create General Journal Line with Random value and update Bal. Account No.
        Initialize();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount(CreateCurrency()));
        GenJournalLine.Modify(true);
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount on G/L Entry.
        FindGLEntry(GLEntry, GenJournalLine."Document No.", BankAccountPostingGroup."G/L Account No.", GLEntry."Document Type"::" ");
        Currency.Get(GenJournalLine."Currency Code");
        Assert.AreNearlyEqual(
          -GenJournalLine."Amount (LCY)", GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErr, GLEntry.FieldCaption(Amount), GenJournalLine."Amount (LCY)", GLEntry.TableCaption(),
            GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAdjmtWithNegativeAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        SecondStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Check GL Entry after Run Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate with Negative Amount on General Line.

        // Setup: Create Currency with three different exchange Rate and Starting Date. Custom 1 and 2 M is required for difference only 1 Month.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(FirstStartingDate, SecondStartingDate);

        // Create and Post General Line. Amount 1 is required.
        CreateAndModifyGeneralLine(GenJournalLine, -1, CurrencyCode, FirstStartingDate);
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate());
        Amount := Amount - LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', FirstStartingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", SecondStartingDate);

        // Verify: Verify GL Entry for Adjusted Negative Amount with Currency.
        VerifyGLEntryAmountAdjmtExchangeRate(GenJournalLine."Account No.", Amount, GenJournalLine."Currency Code");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAdjmtWithPositiveAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        SecondStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Check GL Entry after Run Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate with Positive Amount on General Line.

        // Setup: Create Currency with different exchange Rate and Starting Date.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(FirstStartingDate, SecondStartingDate);

        // Create and Post General Line. Amount 1 is Required.
        CreateAndModifyGeneralLine(GenJournalLine, 1, CurrencyCode, FirstStartingDate);
        Amount := FindRelationalExchRateAmount(CurrencyCode, WorkDate(), SecondStartingDate);
        Amount := Amount + FindRelationalExchRateAmount(CurrencyCode, FirstStartingDate, SecondStartingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", SecondStartingDate);

        // Verify: Verify GL Entry for Adjusted Postitive Amount with Currency.
        VerifyGLEntryAmountAdjmtExchangeRate(GenJournalLine."Account No.", Amount, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAdjustExchRateForGainOrLoss()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
        ExchRateAmount: Decimal;
        GLEntryAmount2: Decimal;
        GLEntryAmount: Decimal;
    begin
        // Check GL Entry for Currency Gain/Loss after running Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate.

        // Setup: Create Currency with different Exchange Rate and Starting Date. Taken Random value to set Exchange rate amount and next Date.
        Initialize();
        CurrencyCode := CreateCurrency();
        ExchRateAmount := LibraryRandom.RandDec(100, 2);
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        DeleteExistingExchangeRates(CurrencyCode);
        CreateExchangeRateWithFixRelationalAmount(CurrencyCode, WorkDate(), ExchRateAmount);
        CreateExchangeRateWithFixRelationalAmount(CurrencyCode, FirstStartingDate, ExchRateAmount + LibraryRandom.RandDec(10, 2));

        // Create, modify and Post General Line with Random Amount.
        Currency.Get(CurrencyCode);
        Amount :=
          CreateModifyAndPostGeneralLine(
            GenJournalLine, CreateBankAccount(CurrencyCode), FirstStartingDate, LibraryRandom.RandDec(1000, 2));
        GLEntryAmount := CalculateGLEntryBaseAmount(Currency."Realized Gains Acc.", Amount);

        Amount2 :=
          CreateModifyAndPostGeneralLine(GenJournalLine, CreateBankAccount(CurrencyCode), FirstStartingDate, -GenJournalLine.Amount / 2);
        GLEntryAmount2 := CalculateGLEntryBaseAmount(Currency."Realized Losses Acc.", Amount2);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", FirstStartingDate);

        // Verify: Verify GL Entry for Currency Gain/Loss.
        FindGLEntry(GLEntry, Currency.Code, Currency."Realized Gains Acc.", GLEntry."Document Type"::" ");
        Assert.AreNearlyEqual(
          -GLEntryAmount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
        FindGLEntry(GLEntry, Currency.Code, Currency."Realized Losses Acc.", GLEntry."Document Type"::" ");
        Assert.AreNearlyEqual(
          -GLEntryAmount2, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), -Amount2, GLEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceAndPaymentWithDiffExchangeRates()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
        FirstStartingDate: Date;
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry after running Adjust Exchange Rate batch job with posting of Customer Invoice and Payment With Different Exchange Rates.

        // Setup: Create and post Customer Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostSalesOrderAndPayment(SalesLine, FirstStartingDate, RelExchRateAmount);
        Amount := Round(LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT", SalesLine."Currency Code", '', FirstStartingDate));
        Amount -= Round(LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT", SalesLine."Currency Code", '', WorkDate()));

        // Exercise.
        RunAdjustExchRate(SalesLine."Currency Code", FirstStartingDate);

        // Verify: Verify GL Entry for Currency Unrealized Gain.
        Currency.Get(SalesLine."Currency Code");
        VerifyGLEntry(
          SalesLine."Currency Code", SalesLine."Currency Code", -Amount, Currency."Unrealized Gains Acc.", GLEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithDiffExchangeRates()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
        FirstStartingDate: Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry after applying Payment to Customer Invoice With Different Exchange Rates.

        // Setup: Create and post Customer Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        DocumentNo := PostSalesOrderAndPayment(SalesLine, FirstStartingDate, RelExchRateAmount);
        Currency.Get(SalesLine."Currency Code");

        // Create new Exchange Rate for Currency on a different Date with Random value.
        CreateExchangeRateWithFixExchRateAmount(SalesLine."Currency Code", PostingDate, (RelExchRateAmount + RelExchRateAmount / 2));
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(
              Round(SalesLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              SalesLine."Currency Code", '', FirstStartingDate));
        Amount -=
          Round(
            LibraryERM.ConvertCurrency(
              Round(SalesLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              SalesLine."Currency Code", '', WorkDate()));

        // Exercise : Apply Customer Payment to Invoice on a different Posting Date.
        OpenCustomerLedgerEntries(SalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify GL Entry for Currency Realized Gain.
        VerifyGLEntry(SalesLine."Currency Code", DocumentNo, -Amount, Currency."Realized Gains Acc.", GLEntry."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateAfterApplyingCustomerEntries()
    begin
        AdjustExchRateOnCustomerEntries(false);
    end;

    local procedure AdjustExchRateOnCustomerEntries(AdjustExchRate: Boolean)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
        FirstStartingDate: Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry for Adjust Exchange Rate batch job after unapplying Customer Entries.

        // Setup: Create and post Customer Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        DocumentNo := PostSalesOrderAndPayment(SalesLine, FirstStartingDate, RelExchRateAmount);
        Currency.Get(SalesLine."Currency Code");

        // Create new Exchange Rate for Currency on a different Date with Random value and Apply Customer Payment to Invoice.
        CreateExchangeRateWithFixExchRateAmount(
          SalesLine."Currency Code", PostingDate, (RelExchRateAmount + LibraryRandom.RandInt(100)));
        OpenCustomerLedgerEntries(SalesLine."Sell-to Customer No.", DocumentNo);

        if AdjustExchRate then begin
            RunAdjustExchRate(SalesLine."Currency Code", PostingDate);
            SetHandler := true; // Taken Global variable to use in handler.
            OpenCustomerLedgerEntries(SalesLine."Sell-to Customer No.", DocumentNo);
        end;
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(
              SalesLine."Amount Including VAT" - Round(SalesLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              SalesLine."Currency Code", '', PostingDate));
        Amount -=
          Round(
            LibraryERM.ConvertCurrency(
              SalesLine."Amount Including VAT" - Round(SalesLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              SalesLine."Currency Code", '', WorkDate()));

        // Exercise.
        RunAdjustExchRate(SalesLine."Currency Code", PostingDate);

        // Verify: Verify GL Entry for Currency Unrealized Gain.
        VerifyGLEntry(
          SalesLine."Currency Code", SalesLine."Currency Code", -Amount, Currency."Unrealized Gains Acc.", GLEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAndPaymentWithDiffExchangeRates()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        FirstStartingDate: Date;
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry after posting Vendor Invoice and Payment With Different Exchange Rates.

        // Setup: Create and post Vendor Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostPurchaseOrderAndPayment(PurchaseLine, FirstStartingDate, RelExchRateAmount);
        Amount :=
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Amount Including VAT", PurchaseLine."Currency Code", '', FirstStartingDate));
        Amount -= Round(LibraryERM.ConvertCurrency(PurchaseLine."Amount Including VAT", PurchaseLine."Currency Code", '', WorkDate()));

        // Exercise.
        RunAdjustExchRate(PurchaseLine."Currency Code", FirstStartingDate);

        // Verify: Verify GL Entry for Currency Unrealized Loss.
        Currency.Get(PurchaseLine."Currency Code");
        VerifyGLEntry(
          PurchaseLine."Currency Code", PurchaseLine."Currency Code", Amount, Currency."Unrealized Losses Acc.",
          GLEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithDiffExchangeRates()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        FirstStartingDate: Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry after applying Payment to Vendor Invoice With Different Exchange Rates.

        // Setup: Create and post Vendor Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        DocumentNo := PostPurchaseOrderAndPayment(PurchaseLine, FirstStartingDate, RelExchRateAmount);
        Currency.Get(PurchaseLine."Currency Code");

        // Create new Exchange Rate for Currency on a different Date with Random value.
        CreateExchangeRateWithFixExchRateAmount(PurchaseLine."Currency Code", PostingDate, (RelExchRateAmount + RelExchRateAmount / 2));
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(
              Round(PurchaseLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              PurchaseLine."Currency Code", '', FirstStartingDate));
        Amount -=
          Round(
            LibraryERM.ConvertCurrency(
              Round(PurchaseLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              PurchaseLine."Currency Code", '', WorkDate()));

        // Exercise : Apply Vendor Payment to Invoice on a different Posting Date.
        OpenVendorLedgerEntries(PurchaseLine."Buy-from Vendor No.", DocumentNo);

        // Verify: Verify GL Entry for Currency Realized Loss.
        VerifyGLEntry(PurchaseLine."Currency Code", DocumentNo, Amount, Currency."Realized Losses Acc.", GLEntry."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateAfterApplyingVendorEntries()
    begin
        AdjustExchRateOnVendorEntries(false)
    end;

    local procedure AdjustExchRateOnVendorEntries(AdjustExchRate: Boolean)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        FirstStartingDate: Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        RelExchRateAmount: Decimal;
    begin
        // Check GL Entry for Adjust Exchange Rate batch job after unapplying Vendor Entries.

        // Setup: Create and post Vendor Invoice and Payment. Take Integer value to handle entries through Adjust Exchange Rate batch job.
        Initialize();
        RelExchRateAmount := LibraryRandom.RandInt(100) * 2;
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        DocumentNo := PostPurchaseOrderAndPayment(PurchaseLine, FirstStartingDate, RelExchRateAmount);
        Currency.Get(PurchaseLine."Currency Code");

        // Create new Exchange Rate for Currency on a different Date with Random value and Apply Vendor Payment to Invoice.
        CreateExchangeRateWithFixExchRateAmount(
          PurchaseLine."Currency Code", PostingDate, (RelExchRateAmount + LibraryRandom.RandInt(100)));
        OpenVendorLedgerEntries(PurchaseLine."Buy-from Vendor No.", DocumentNo);

        if AdjustExchRate then begin
            RunAdjustExchRate(PurchaseLine."Currency Code", PostingDate);
            SetHandler := true; // Taken Global variable to use in handler.
            OpenVendorLedgerEntries(PurchaseLine."Buy-from Vendor No.", DocumentNo);
        end;

        Amount :=
          Round(
            LibraryERM.ConvertCurrency(
              PurchaseLine."Amount Including VAT" - Round(PurchaseLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              PurchaseLine."Currency Code", '', PostingDate));
        Amount -=
          Round(
            LibraryERM.ConvertCurrency(
              PurchaseLine."Amount Including VAT" - Round(PurchaseLine."Amount Including VAT" / 2, Currency."Amount Rounding Precision"),
              PurchaseLine."Currency Code", '', WorkDate()));

        // Exercise.
        RunAdjustExchRate(PurchaseLine."Currency Code", PostingDate);

        // Verify: Verify GL Entry for Currency Unrealized Loss.
        VerifyGLEntry(
          PurchaseLine."Currency Code", PurchaseLine."Currency Code", Amount, Currency."Unrealized Losses Acc.",
          GLEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReversePaymentWithUnrealizedGainLossforVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse] [Purchase]
        // [SCENARIO] Program doesn't allow to reverse the payment transaction when Realized gain or loss entries associated with Vendor Receipt transaction.

        // [GIVEN] Create Currency, Vendor, Apply Payment on Invoice using Gen. Journal Line.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostPaymentWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(CurrencyCode), CurrencyCode, 1, StartingDate);

        // [GIVEN] Unapply Payment
        UnapplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Validation of succesful reversal in message handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReversePaymentWithUnrealizedGainLossforCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse] [Sales]
        // [SCENARIO] Program doesn't allow to reverse the payment transaction when Realized gain or loss entries associated with Customer Receipt transaction.

        // [GIVEN] Create Currency, Customer, Apply Payment on Invoice using Gen. Journal Line.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostPaymentWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CurrencyCode), CurrencyCode, -1, StartingDate);

        // [GIVEN] Unapply Payment
        UnapplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Validation of succesful reversal in message handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedLCYPaymentWithGainLossforVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse] [Purchase]
        // [SCENARIO 201007] It is not allowed to reverse purchase payment transaction when LCY Payment is posted and applied to FCY Invoice
        Initialize();

        // [GIVEN] Create Currency, Vendor, Apply LCY Payment on Invoice using Gen. Journal Line.
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostPaymentWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(CurrencyCode), '', 1, StartingDate);

        // [GIVEN] Unapply Payment
        UnapplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Validation of succesful reversal in message handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReversalMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedLCYPaymentWithGainLossforCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse] [Sales]
        // [SCENARIO 201007] It is not allowed to reverse sales payment transaction when LCY Payment is posted and applied to FCY Invoice
        Initialize();

        // [GIVEN] Create Currency, Customer, Apply LCY Payment on Invoice using Gen. Journal Line.
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostPaymentWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CurrencyCode), '', -1, StartingDate);

        // [GIVEN] Unapply Payment
        UnapplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Validation of succesful reversal in message handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedLCYPaymentWithGainLossforVendorAppliedFromPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Reverse] [Purchase]
        // [SCENARIO 201007] Reversed Purchase LCY Payment that was applied to FCY invoice in different transaction should have zero balance
        Initialize();

        // [GIVEN] Create Currency, Vendor, Apply Payment to Invoice
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostApplyTwoPurchDocuments(
          GenJournalLine, InvoiceNo, CurrencyCode, StartingDate,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice);

        // [GIVEN] Unapply Payment
        UnapplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Payment Document Balance for Vendor Posting Account and Currency Gain/Loss Account is zero
        VerifyGLEntryReverseBalance(
          CurrencyCode, GetVendorPostingAccount(GenJournalLine."Account No."),
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedFCYInvoiceWithGainLossforVendorAppliedFromInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Reverse] [Purchase]
        // [SCENARIO 201007] Reversed Purchase FCY Invoice that was applied to LCY payment in different transaction should have zero balance
        Initialize();

        // [GIVEN] Create Currency, Vendor, Apply Invoice To Payment
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostApplyTwoPurchDocuments(
          GenJournalLine, InvoiceNo, CurrencyCode, StartingDate,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);

        // [GIVEN] Unapply Invoice
        UnapplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [WHEN] Reverse Invoice
        asserterror LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // [THEN] Invoice Document Balance for Vendor Posting Account and Currency Gain/Loss Account is zero
        GLEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
        GLEntry.FindFirst();
        Assert.ExpectedError(
          StrSubstNo(DocTypeReversalErr, GLEntry."Entry No.", GLEntry."Document Type"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedLCYPaymentWithGainLossforCustomerAppliedFromPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Reverse] [Sales]
        // [SCENARIO 201007] Reversed Sales LCY Payment that was applied to FCY invoice in different transaction should have zero balance
        Initialize();

        // [GIVEN] Create Currency, Customer, Apply Payment to Invoice
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostApplyTwoSalesDocuments(
          GenJournalLine, InvoiceNo, CurrencyCode, StartingDate,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice);

        // [GIVEN] Unapply Payment
        UnapplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Reverse Payment
        LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Payment Document Balance for Customer Posting Account and Currency Gain/Loss Account is zero
        VerifyGLEntryReverseBalance(
          CurrencyCode, GetCustomerPostingAccount(GenJournalLine."Account No."),
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReverseUnappliedFCYInvoiceWithGainLossforCustomerAppliedFromInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        StartingDate: Date;
        StartingDate2: Date;
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Reverse] [Sales]
        // [SCENARIO 201007] Reversed Sales FCY Invoice that was applied to LCY payment in different transaction should have zero balance
        Initialize();

        // [GIVEN] Create Currency, Customer, Apply Invoice To Payment
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(StartingDate, StartingDate2);
        CreatePostApplyTwoSalesDocuments(
          GenJournalLine, InvoiceNo, CurrencyCode, StartingDate,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);

        // [GIVEN] Unapply Invoice
        UnapplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [WHEN] Reverse Invoice
        asserterror LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // [THEN] Invoice Document Balance for Customer Posting Account and Currency Gain/Loss Account is zero
        GLEntry.SetRange("Transaction No.", CustLedgerEntry."Transaction No.");
        GLEntry.FindFirst();
        Assert.ExpectedError(
          StrSubstNo(DocTypeReversalErr, GLEntry."Entry No.", GLEntry."Document Type"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForCustomerTwiceGainsLosses()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for customer entries from gains to losses
        Initialize();

        // [GIVEN] Sales Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CreateCurrency()),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), 2 * ExchRateAmt);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [GIVEN] Dtld. Cust. Ledger Entry is created with amount = 1176,09 for Unrealized Gain type
        VerifyDtldCLEGain(
          GenJournalLine."Currency Code",
          -CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));

        // [GIVEN] Exch. rates is changed to 1,0666
        ModifyExchangeRate(GenJournalLine."Currency Code", -ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [THEN] Dtld. Cust. Ledger Entry is created with amount = -433,69 for Unrealized Loss type
        VerifyDtldCLELoss(
          GenJournalLine."Currency Code",
          CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForCustomerTwiceLossesGains()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for customer entries from losses to gains
        Initialize();

        // [GIVEN] Sales Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CreateCurrency()),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), -2 * ExchRateAmt);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [GIVEN] Dtld. Cust. Ledger Entry is created with amount = -1176,09 for Unrealized Loss type
        VerifyDtldCLELoss(
          GenJournalLine."Currency Code",
          -CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));

        // [GIVEN] Exch. rates is changed to 1,0666
        ModifyExchangeRate(GenJournalLine."Currency Code", ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [THEN] Dtld. Cust. Ledger Entry is created with amount = 742,4 for Unrealized Gain type
        VerifyDtldCLEGain(
          GenJournalLine."Currency Code",
          CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForCustomerTwiceGainsToHigherLosses()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        ExchRateAmt: Decimal;
        AdjDocNo: Code[20];
        LossesAmount: Decimal;
        k: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 365816] Run Adjust Exchange Rate report twice when exch.rate is changed upper and then lower than invoice's exch.rate
        Initialize();

        // [GIVEN] Sales Invoice with Amount = 4000, Amount LCY = 4720 is posted with exch.rate = 1.18
        Currency.Get(CreateCurrency());
        FindCurrencyExchRate(CurrencyExchangeRate, Currency.Code);
        ExchRateAmt := CurrencyExchangeRate."Relational Exch. Rate Amount";
        k := 0.1;
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(Currency.Code),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2),
          ExchRateAmt * k);

        // [GIVEN] Exch. rates is changed to 1.2 (delta = 0.02) and adjustment completed.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [GIVEN] Dtld. Cust. Ledger Entry is created with amount = 80 (4000 * 0.02) for Unrealized Gain type
        VerifyDtldCLEGain(
          GenJournalLine."Currency Code",
          -CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));

        // [GIVEN] Exch. rates is changed to 1.15 (delta = -0.05)
        ModifyExchangeRate(GenJournalLine."Currency Code", -ExchRateAmt * 2 * k);
        AdjDocNo := LibraryUtility.GenerateGUID();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LossesAmount := CustLedgerEntry."Amount (LCY)";

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchRateForDocNo(AdjDocNo, GenJournalLine."Currency Code", WorkDate());

        // [THEN] Dtld. Cust. Ledger Entry is created with amount = -200 (4000 * -0.05) for Unrealized Loss type
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LossesAmount := CustLedgerEntry."Amount (LCY)" - LossesAmount;
        VerifyDtldCLELoss(AdjDocNo, LossesAmount);
        VerifyGLEntryForDocument(AdjDocNo, Currency."Unrealized Losses Acc.", -LossesAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForCustomerTwiceLossesToHigherGains()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        ExchRateAmt: Decimal;
        AdjDocNo: Code[20];
        GainsAmount: Decimal;
        k: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 365816] Run Adjust Exchange Rates report twice when exch.rate is changed lower and then upper than invoice's exch.rate
        Initialize();

        // [GIVEN] Sales Invoice with Amount = 4000, Amount LCY = 4720 is posted with exch.rate = 1.18
        Currency.Get(CreateCurrency());
        FindCurrencyExchRate(CurrencyExchangeRate, Currency.Code);
        ExchRateAmt := CurrencyExchangeRate."Relational Exch. Rate Amount";
        k := 0.1;
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(Currency.Code),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2),
          -ExchRateAmt * k);

        // [GIVEN] Exch. rates is changed to 1.16 (delta = -0.02) and adjustment completed.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [GIVEN] Dtld. Cust. Ledger Entry is created with amount = -80 (4000 * -0.02) for Unrealized Loss type
        VerifyDtldCLELoss(
          GenJournalLine."Currency Code",
          -CalcGainLossAmount(GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code"));

        // [GIVEN] Exch. rates is changed to 1.21 (delta = 0.05)
        ModifyExchangeRate(GenJournalLine."Currency Code", ExchRateAmt * 2 * k);
        AdjDocNo := LibraryUtility.GenerateGUID();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Amount (LCY)");
        GainsAmount := CustLedgerEntry."Amount (LCY)";

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchRateForDocNo(AdjDocNo, GenJournalLine."Currency Code", WorkDate());

        // [THEN] Dtld. Cust. Ledger Entry is created with amount = 200 (4000 * 0.05) for Unrealized Gain type
        CustLedgerEntry.CalcFields("Amount (LCY)");
        GainsAmount := CustLedgerEntry."Amount (LCY)" - GainsAmount;
        VerifyDtldCLEGain(AdjDocNo, GainsAmount);
        VerifyGLEntryForDocument(AdjDocNo, Currency."Unrealized Gains Acc.", -GainsAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(PostingDate);
        Clear(SetHandler);
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure AdjustExchRateForBank(ExchRateAmt: Decimal)
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Setup: Modify Exchange Rate after Create and Post General Journal Line for Bank.
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CreateCurrency()),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), ExchRateAmt);
        FindCurrencyExchRate(CurrencyExchangeRate, GenJournalLine."Currency Code");
        Amount := GenJournalLine.Amount * ExchRateAmt / CurrencyExchangeRate."Exchange Rate Amount";
        BankAccount.Get(GenJournalLine."Account No.");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");

        // Exercise:  Run Adjust Exchange Rate batch job on Posted Entries.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // Verify: Verify G/L Entry for correct entry after made from running Adjust Exchange Rate Batch Job.
        VerifyGLEntry(
          GenJournalLine."Currency Code", GenJournalLine."Currency Code", Amount, BankAccountPostingGroup."G/L Account No.",
          GenJournalLine."Document Type"::" ");
    end;

    local procedure AdjustExchRateForCustomer(ExchRateAmt: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Setup: Modify Exchange Rate after Create and Post General Journal Line for Customer.
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(CreateCurrency()),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), ExchRateAmt);
        FindCurrencyExchRate(CurrencyExchangeRate, GenJournalLine."Currency Code");
        Amount :=
          GenJournalLine."Amount (LCY)" -
          GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount";

        // Exercise: Run Adjust Exchange Rate batch job on Posted Entries.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // Verify: Verify Detailed Ledger Entry for correct entry after made from running Adjust Exchange Rate Batch Job.
        VerifyDetailedLedgerEntry(GenJournalLine."Currency Code", EntryType, -Amount);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateAndModifyGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Line and Modify Posting Date in Second Line. Amount 1 is Required.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CurrencyCode), 1);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type", CreateBankAccount(CurrencyCode), Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateModifyAndPostGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; FirstStartingDate: Date; Amount: Decimal) AmountLCY: Decimal
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Document Type"::" ", Amount);
        GenJournalLine.Validate("Currency Code", BankAccount."Currency Code");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        AmountLCY := Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate()));
        AmountLCY -= Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', FirstStartingDate));
    end;

    local procedure CreateCurrencyWithMultipleExchangeRate(var FirstStartingDate: Date; var SecondStartingDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        // Create Currency with different starting date and Exchange Rate. Taken Random value to calculate Date.
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        SecondStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        CreateExchangeRate(Currency.Code, WorkDate());
        CreateExchangeRate(Currency.Code, FirstStartingDate);
        CreateExchangeRate(Currency.Code, SecondStartingDate);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyAndExchRates(FirstStartingDate: Date; RelExchRateAmount: Decimal) CurrencyCode: Code[10]
    begin
        // Create Currency with different exchange Rate and Starting Date. Take Random for Relational Exchange Rate Amount.
        CurrencyCode := CreateCurrency();
        DeleteExistingExchangeRates(CurrencyCode);
        CreateExchangeRateWithFixExchRateAmount(CurrencyCode, WorkDate(), RelExchRateAmount);
        CreateExchangeRateWithFixExchRateAmount(CurrencyCode, FirstStartingDate, 2 * RelExchRateAmount);
    end;

    local procedure CreateExchangeRateWithFixRelationalAmount(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take 1 to fix the Relational amounts for Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateExchangeRateWithFixExchRateAmount(CurrencyCode: Code[10]; StartingDate: Date; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take 1 to fix the Exchange Rate amounts for Currency Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.SetFilter("G/L Account No.", '<>''''');
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Modify(true);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take Random Value for Exchange Rate Fields.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for Invoice on General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGenAndModifyExchRate(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; ExchangeRateAmount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, DocumentType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ModifyExchangeRate(GenJournalLine."Currency Code", ExchangeRateAmount);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order with Random Quantity and Unit Price. Taken Integer value to handle Rounding on Amounts after multiple Adjust Exchange rate.
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(CurrencyCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Order with Random Quantity and Unit Price. Taken Integer value to handle Rounding on Amounts after multiple Adjust Exchange rate.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(CurrencyCode));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPaymentLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, DocumentType, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPaymentWithAppln(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Sign: Integer; PmtPostingDate: Date)
    var
        InvoiceNo: Code[20];
    begin
        CreateGeneralJournalLine(
          GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::Invoice, -Sign * LibraryRandom.RandDec(100, 2));
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, AccountType, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          Sign * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        ModifyGeneralLine(GenJournalLine, InvoiceNo, PmtPostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostInvoiceAndPayment(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Sign: Integer; PmtPostingDate: Date)
    begin
        CreateGeneralJournalLine(
          GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::Invoice, -Sign * LibraryRandom.RandDec(100, 2));
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::Payment, Sign * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PmtPostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostApplyTwoPurchDocuments(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: Code[20]; CurrencyCode: Code[10]; StartingDate: Date; ApplyDocTypeFrom: Enum "Gen. Journal Document Type"; ApplyDocTypeTo: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntryApplyFrom: Record "Vendor Ledger Entry";
        VendorLedgerEntryApplyTo: Record "Vendor Ledger Entry";
    begin
        CreatePostInvoiceAndPayment(
          GenJournalLine, InvoiceNo, GenJournalLine."Account Type"::Vendor, CreateVendor(CurrencyCode), '', 1, StartingDate);

        FindVendorLedgerEntryByDocType(VendorLedgerEntryApplyFrom, GenJournalLine."Account No.", ApplyDocTypeFrom);
        FindVendorLedgerEntryByDocType(VendorLedgerEntryApplyTo, GenJournalLine."Account No.", ApplyDocTypeTo);

        LibraryERM.ApplyVendorLedgerEntries(
          ApplyDocTypeFrom, ApplyDocTypeTo,
          VendorLedgerEntryApplyFrom."Document No.", VendorLedgerEntryApplyTo."Document No.");
    end;

    local procedure CreatePostApplyTwoSalesDocuments(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: Code[20]; CurrencyCode: Code[10]; StartingDate: Date; ApplyDocTypeFrom: Enum "Gen. Journal Document Type"; ApplyDocTypeTo: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntryApplyFrom: Record "Cust. Ledger Entry";
        CustLedgerEntryApplyTo: Record "Cust. Ledger Entry";
    begin
        CreatePostInvoiceAndPayment(
          GenJournalLine, InvoiceNo, GenJournalLine."Account Type"::Customer, CreateCustomer(CurrencyCode), '', -1, StartingDate);

        FindCustLedgerEntryByDocType(CustLedgerEntryApplyFrom, GenJournalLine."Account No.", ApplyDocTypeFrom);
        FindCustLedgerEntryByDocType(CustLedgerEntryApplyTo, GenJournalLine."Account No.", ApplyDocTypeTo);

        LibraryERM.ApplyCustomerLedgerEntries(
          ApplyDocTypeFrom, ApplyDocTypeTo,
          CustLedgerEntryApplyFrom."Document No.", CustLedgerEntryApplyTo."Document No.");
    end;

    local procedure GetVendorPostingAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetCustomerPostingAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure ModifyGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure PostSalesOrderAndPayment(var SalesLine: Record "Sales Line"; FirstStartingDate: Date; RelExchRateAmount: Decimal) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post Sales Order.
        DocumentNo := CreateAndPostSalesDocument(SalesLine, CreateCurrencyAndExchRates(FirstStartingDate, RelExchRateAmount));

        // Create and post Customer Partial Payment.
        CreateAndPostPaymentLine(
          GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment,
          -SalesLine."Amount Including VAT" / 2, FirstStartingDate);
    end;

    local procedure PostPurchaseOrderAndPayment(var PurchaseLine: Record "Purchase Line"; FirstStartingDate: Date; RelExchRateAmount: Decimal) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post Purchase Order.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseLine, CreateCurrencyAndExchRates(FirstStartingDate, RelExchRateAmount));

        // Create and post Vendor Partial Payment.
        CreateAndPostPaymentLine(
          GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment,
          PurchaseLine."Amount Including VAT" / 2, FirstStartingDate);
    end;

    local procedure DeleteExistingExchangeRates(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.DeleteAll(true);
    end;

    local procedure FindCurrencyExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindRelationalExchRateAmount(CurrencyCode: Code[10]; StartingDate: Date; StartingDate2: Date): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
    begin
        Currency.Get(CurrencyCode);
        CurrencyExchangeRate.Get(CurrencyCode, StartingDate);
        Amount := CurrencyExchangeRate."Relational Exch. Rate Amount";
        CurrencyExchangeRate.Get(CurrencyCode, StartingDate2);
        exit(CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" - Amount);
    end;

    local procedure FindVendorLedgerEntryByDocType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocType);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindCustLedgerEntryByDocType(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocType);
        CustLedgerEntry.FindFirst();
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10]; ExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        FindCurrencyExchRate(CurrencyExchangeRate, CurrencyCode);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmt);
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" + ExchRateAmt);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure OpenCustomerLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        if SetHandler then
            CustomerLedgerEntries.UnapplyEntries.Invoke()
        else
            CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure OpenVendorLedgerEntries(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        if SetHandler then
            VendorLedgerEntries.UnapplyEntries.Invoke()
        else
            VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure RunAdjustExchRate("Code": Code[10]; EndDate: Date)
    begin
        RunAdjustExchRateForDocNo(Code, Code, EndDate); // Using Currency Code for Document No. parameter.
    end;

    local procedure RunAdjustExchRateForDocNo(DocumentNo: Code[20]; CurrencyCode: Code[10]; EndDate: Date)
    var
        Currency: Record Currency;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        Currency.SetRange(Code, CurrencyCode);
        AdjustExchangeRates.SetTableView(Currency);
        AdjustExchangeRates.InitializeRequest2(0D, EndDate, 'Test', EndDate, DocumentNo, true, false);
        AdjustExchangeRates.UseRequestPage(false);
        AdjustExchangeRates.Run();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure UnapplyVendorEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UnapplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure VerifyGLEntryAmountAdjmtExchangeRate(BankAccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        GLEntryAmount: Decimal;
    begin
        BankAccount.Get(BankAccountNo);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", BankAccountPostingGroup."G/L Account No.");
        GLEntry.FindSet();
        repeat
            GLEntryAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Currency.Get(DocumentNo);
        Assert.AreNearlyEqual(
          Amount, GLEntryAmount, Currency."Invoice Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField("Ledger Entry Amount", true);
        DetailedCustLedgEntry.TestField("Exch. Rate Adjmt. Reg. No.");
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");
        Currency.Get(DetailedCustLedgEntry."Currency Code");
        Assert.AreNearlyEqual(
          Amount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErr, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedCustLedgEntry.TableCaption(),
            DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyDtldCLEGain(DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        VerifyDetailedLedgerEntry(DocumentNo, DetailedCustLedgEntry."Entry Type"::"Unrealized Gain", Amount);
    end;

    local procedure VerifyDtldCLELoss(DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        VerifyDetailedLedgerEntry(DocumentNo, DetailedCustLedgEntry."Entry Type"::"Unrealized Loss", Amount);
    end;

    local procedure VerifyGLEntry(CurrencyCode: Code[10]; DocumentNo: Code[20]; Amount: Decimal; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, DocumentType);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyGLEntryForDocument(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, GLEntry."Document Type"::" ");
        GLEntry.TestField(Amount, EntryAmount);
    end;

    local procedure VerifyGLEntryReverseBalance(CurrencyCode: Code[10]; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, DocumentType);
        GLEntry.SetRange("Document Type"); // Unapply creates entries with empty Document Type
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);

        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);

        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Realized Losses Acc.");
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
    end;

    local procedure CalculateGLEntryBaseAmount(GLAccountNo: Code[20]; Amount: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        VATAmount: Decimal;
    begin
        // function calculates VAT Base Amount based on VAT Posting Setup applied for input account
        GLAccount.Get(GLAccountNo);
        if VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then
            VATAmount :=
              Round(
                Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), Currency."Amount Rounding Precision",
                Currency.VATRoundingDirection());
        exit(Round(Amount - VATAmount, Currency."Amount Rounding Precision"));
    end;

    local procedure CalcGainLossAmount(Amount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        FindCurrencyExchRate(CurrencyExchangeRate, CurrencyCode);
        exit(
          AmountLCY -
          Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.PostingDate.SetValue(Format(PostingDate));
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // To handle the message.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReversalMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ReversalSuccessfullTxt, Message);
    end;
}
#endif
