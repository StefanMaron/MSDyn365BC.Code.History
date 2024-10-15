﻿codeunit 144056 "ERM Cash Basis"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [Cash Basis]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Amount FieldCaption, %2 = Amount Value, %3 = Record TableCaption';

    [Test]
    [Scope('OnPrem')]
    procedure VATRealizedGainLossForCustomerLCYPaymentToFCYInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        PostingDate: Date;
        RateFactor: Decimal;
        RateFactor2: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] VAT Realized Gain/Loss for LCY payment to FCY invoice for Customer.

        // [GIVEN] Create Currency. Create Customer and Item with VAT Posting Group.
        Initialize();
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactor, RateFactor2);
        CustomerNo := CreateCustomer(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create and post Sales Order.
        InvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, CustomerNo, SalesLine."Document Type"::Order, SalesLine.Type::Item, ItemNo,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");

        // [WHEN] Create and post Payment Journal Line.
        CreateAndPostPaymentGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo,
          InvoiceNo, -CustLedgerEntry."Amount (LCY)" / RateFactor * RateFactor2, PostingDate);

        // [THEN] Verify VAT Realized Loss Amount for customer.
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", Currency."Realized Gains Acc.",
          Round(SalesLine.Amount * SalesLine."VAT %" / 100 * (RateFactor2 - RateFactor),
            Currency."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRealizedGainLossForVendorLCYPaymentToFCYInvoice()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
        RateFactor: Decimal;
        RateFactor2: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] VAT Realized Gain/Loss for LCY payment to FCY invoice for Vendor.

        // [GIVEN] Create Currency. Create Vendor and Item with VAT Posting Group.
        Initialize();
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactor, RateFactor2);
        VendorNo := CreateVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create and post Purchase Order.
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, ItemNo, PurchaseLine.Type::Item,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");

        // [WHEN] Create and post Payment Journal Line.
        CreateAndPostPaymentGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          InvoiceNo, Abs(VendorLedgerEntry."Amount (LCY)") / RateFactor * RateFactor2, PostingDate);

        // [THEN] Verify VAT Realized Gain Amount for vendor.
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", Currency."Realized Losses Acc.",
          Round(-PurchaseLine.Amount * PurchaseLine."VAT %" / 100 * (RateFactor2 - RateFactor),
            Currency."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedVATAmountInExchRateOfPaymentWhenFCYPaymentToFCYInvoice()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO TFS118222] Payment in FCY is applied to Invoice in FCY with unrealized VAT. Realized VAT is posted with the Exchange Rate of the Payment.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rates. Create Vendor with Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactorX, RateFactorY);
        VendorNo := CreateVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Posted Purchase Invoice in FCY (Exch Rate = X)
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, ItemNo, PurchaseLine.Type::Item,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [WHEN] Post Payment in FCY (Exch Rate = Y) and apply to Invoice
        CreateAndPostPaymentGenJournalLineWithCurrency(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          InvoiceNo, CalcVendInvoiceAmount(InvoiceNo), PostingDate, Currency.Code, 1 / RateFactorY);

        // [THEN] Realized VAT amount in LCY calculated with Exch Rate = Y.
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account",
          Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100 * RateFactorY, Currency."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedVATAmountInExchRateOfPaymentWhenFCYPaymentToFCYInvoiceUnapplyPurchase()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 381218] VAT Entries for unapplied Vendor Payment in FCY with unrealized VAT are posted with Exh.Rate of Payment.
        Initialize();

        // [GIVEN] Currency with Exchange Rates assigned to Vendor with Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactorX, RateFactorY);
        VendorNo := CreateVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Posted Purchase Invoice in FCY (Exch Rate = "X"), Unrealized VAT Amount = 10.22 Unrealized VAT Base = 102.24
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, ItemNo, PurchaseLine.Type::Item,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
        VATAmount := Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100 * RateFactorY, Currency."Amount Rounding Precision");
        FindVATEntry(VATEntry, VATEntry.Type::Purchase, VATEntry."Document Type"::Invoice, InvoiceNo);
        VATEntry.TestField("Realized Amount", 0);
        VATEntry.TestField("Realized Base", 0);

        // [GIVEN] Applied Payment in FCY (Exch Rate = "Y")
        CreateAndPostPaymentGenJournalLineWithCurrency(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          InvoiceNo, CalcVendInvoiceAmount(InvoiceNo), PostingDate, Currency.Code, 1 / RateFactorY);
        // [GIVEN] VAT Entry has Base and Amount calculated with Exch Rate = "Y", VAT Amount = 10.46, VAT Base = 104.64
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Purchase, GenJournalLine."Document No.",
          VATAmount, Round(PurchaseLine.Amount * RateFactorY, Currency."Amount Rounding Precision"));
        // [GIVEN] Invoice VAT Entry has Realized VAT Amount = -0.24(10.22 - 10.46), Realized VAT Base = -2.4 (102.24 - 104.64)
        VerifyRealizedVATAmountsInVATEntry(
          VATEntry.Type::Purchase, VATEntry."Document Type"::Invoice, InvoiceNo,
          VATEntry."Unrealized Amount" - VATAmount,
          VATEntry."Unrealized Base" - Round(PurchaseLine.Amount * RateFactorY, Currency."Amount Rounding Precision"),
          Currency."Amount Rounding Precision");

        // [WHEN] Unapply payment Vendor Ledger Entry
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [THEN] Unapplied G/L Entry for Purchase VAT Account has amount in LCY calculated with Exch Rate = "Y" = -10.46
        // [THEN] Unapplied G/L Entry for Realized Losses of VAT has amount = 0.24
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account", -VATAmount);
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", Currency."Realized Losses Acc.",
          -VATEntry."Unrealized Amount" + VATAmount);

        // [THEN] VAT Entry for unapplication is created with Exch Rate = "Y"
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Purchase, GenJournalLine."Document No.",
          -VATAmount, -Round(PurchaseLine.Amount * RateFactorY, Currency."Amount Rounding Precision"));
        // [THEN] VAT Entry of the Invoice has 'Remaining Unrealized Amount' = 10.22 and 'Remaining Unrealized Base' = 102.24
        VerifyRemainingUnrealizedVATAmountAndVATBase(InvoiceNo, VATEntry."Unrealized Amount", VATEntry."Unrealized Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedVATAmountInExchRateOfPaymentWhenFCYPaymentToFCYInvoiceUnapplySales()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 319666] VAT Entries for unapplied Customer Payment in FCY with unrealized VAT are posted with Exh.Rate of Payment.
        Initialize();

        // [GIVEN] Currency with Exchange Rates assigned to Customer with Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactorX, RateFactorY);
        CustomerNo := CreateCustomer(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Posted Sales Invoice in FCY (Exch Rate = "X"), Unrealized VAT Amount = -10.22 Unrealized VAT Base = -102.24
        InvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, CustomerNo, SalesLine."Document Type"::Order, SalesLine.Type::Item, ItemNo,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
        VATAmount := Round(SalesLine.Amount * SalesLine."VAT %" / 100 * RateFactorY, Currency."Amount Rounding Precision");
        FindVATEntry(VATEntry, VATEntry.Type::Sale, VATEntry."Document Type"::Invoice, InvoiceNo);
        VATEntry.TestField("Realized Amount", 0);
        VATEntry.TestField("Realized Base", 0);

        // [GIVEN] Applied Payment in FCY (Exch Rate = "Y")
        CreateAndPostPaymentGenJournalLineWithCurrency(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo,
          InvoiceNo, -CalcCustInvoiceAmount(InvoiceNo), PostingDate, Currency.Code, 1 / RateFactorY);

        // [GIVEN] VAT Entry has Base and Amount calculated with Exch Rate = "Y", VAT Amount = -10.46, VAT Base = -104.64
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Sale, GenJournalLine."Document No.",
          -VATAmount, -Round(SalesLine.Amount * RateFactorY, Currency."Amount Rounding Precision"));

        // [GIVEN] Invoice VAT Entry has Realized VAT Amount = 0.24(-10.22 + 10.46), Realized VAT Base = 2.4 (-102.24 + 104.64)
        VerifyRealizedVATAmountsInVATEntry(
          VATEntry.Type::Sale, VATEntry."Document Type"::Invoice, InvoiceNo,
          VATEntry."Unrealized Amount" + VATAmount,
          VATEntry."Unrealized Base" + Round(SalesLine.Amount * RateFactorY, Currency."Amount Rounding Precision"),
          Currency."Amount Rounding Precision");

        // [WHEN] Unapply payment Customer Ledger Entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [THEN] Unapplied G/L Entry for Sales VAT Account has amount in LCY calculated with Exch Rate = "Y" = 10.46
        // [THEN] Unapplied G/L Entry for Realized Gains of VAT has amount = -0.24
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", VATPostingSetup."Sales VAT Account", VATAmount);
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", Currency."Realized Gains Acc.",
          -VATEntry."Unrealized Amount" - VATAmount);

        // [THEN] VAT Entry for unapplication is created with Exch Rate = "Y"
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Sale, GenJournalLine."Document No.",
          VATAmount, Round(SalesLine.Amount * RateFactorY, Currency."Amount Rounding Precision"));
        // [THEN] VAT Entry of the Invoice has 'Remaining Unrealized Amount' = -10.22 and 'Remaining Unrealized Base' = -102.24
        VerifyRemainingUnrealizedVATAmountAndVATBase(InvoiceNo, VATEntry."Unrealized Amount", VATEntry."Unrealized Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedVATAmountInManualExchRateOfPaymentFCYToPurchaseInvoiceFCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
        RateFactorZ: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO TFS120394] Payment in FCY is applied to Purchase Invoice in FCY with unrealized VAT. Realized VAT is posted with the updated Exchange Rate of the Payment.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rates. Create Vendor with Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactorX, RateFactorY);
        VendorNo := CreateVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN]  Posted Purchase Invoice in FCY (Exch Rate = X)
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, ItemNo, PurchaseLine.Type::Item,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Rate Factor for Payment different from Exch Rate Y
        RateFactorZ := RateFactorY + LibraryRandom.RandDec(3, 2);

        // [WHEN] Post Payment in FCY (Exch Rate = Y) and apply to Invoice
        CreateAndPostPaymentGenJournalLineWithCurrency(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          InvoiceNo, CalcVendInvoiceAmount(InvoiceNo), PostingDate, Currency.Code, 1 / RateFactorZ);

        // [THEN] G/L Entry has Realized VAT amount in LCY calculated with Exch Rate = Z.
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account",
          Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100 * RateFactorZ, Currency."Amount Rounding Precision"));

        // [THEN] VAT Entry has Realized VAT Amount calculated with Exch Rate = Z. (TFS379865)
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Purchase, GenJournalLine."Document No.",
          Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100 * RateFactorZ, Currency."Amount Rounding Precision"),
          Round(PurchaseLine.Amount * RateFactorZ, Currency."Amount Rounding Precision"));

        // [THEN] Remaining Unrealized VAT in VAT Entry must be exhausted, (TFS379865)
        VerifyRemainingUnrealizedVATAmountAndVATBase(GenJournalLine."Document No.", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedVATAmountInManualExchRateOfPaymentFCYToSalesInvoiceFCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
        RateFactorZ: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO TFS120394] Payment in FCY is applied to Sales Invoice in FCY with unrealized VAT. Realized VAT is posted with the updated Exchange Rate of the Payment.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rates. Create Customer with Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Cash Basis", ItemNo, PostingDate, RateFactorX, RateFactorY);
        CustomerNo := CreateCustomer(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN]  Posted Purchase Invoice in FCY (Exch Rate = X)
        InvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, CustomerNo, SalesLine."Document Type"::Order, SalesLine.Type::Item, ItemNo,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Rate Factor for Payment different from Exch Rate Y
        RateFactorZ := RateFactorY + LibraryRandom.RandDec(3, 2);

        // [WHEN] Post Payment in FCY (Exch Rate = Z) and apply to Invoice
        CreateAndPostPaymentGenJournalLineWithCurrency(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo,
          InvoiceNo, -CalcCustInvoiceAmount(InvoiceNo), PostingDate, Currency.Code, 1 / RateFactorZ);

        // [THEN] G/L Entry has Realized VAT amount in LCY calculated with Exch Rate = Z.
        VerifyGLEntryForRealizedVAT(
          GenJournalLine."Document No.", VATPostingSetup."Sales VAT Account",
          -Round(SalesLine.Amount * SalesLine."VAT %" / 100 * RateFactorZ, Currency."Amount Rounding Precision"));

        // [THEN] VAT Entry has Realized VAT Amount calculated with Exch Rate = Z. (TFS379865)
        VerifyVATAmountsInLastPmtVATEntry(
          VATEntry.Type::Sale, GenJournalLine."Document No.",
          -Round(SalesLine.Amount * SalesLine."VAT %" / 100 * RateFactorZ, Currency."Amount Rounding Precision"),
          -Round(SalesLine.Amount * RateFactorZ, Currency."Amount Rounding Precision"));

        // [THEN] Remaining Unrealized VAT in VAT Entry must be exhausted. (TFS379865)
        VerifyRemainingUnrealizedVATAmountAndVATBase(GenJournalLine."Document No.", 0, 0);
    end;

    [Test]
    [HandlerFunctions('ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure RealizedPercentageVATAdjustExchPaymentFCYtoPurchInvoiceFCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATEntry: Record "VAT Entry";
        RealizedVATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 363848] Realized VAT is posted with original unrealized amounts after vendor payment with new adjusted exch. rate is applied to invoice in FCY.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create Currency with Exchange Rates. Create Vendor with Percentage Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, ItemNo, PostingDate, RateFactorX, RateFactorY);
        VendorNo := CreateVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN]  Post Purchase Invoice in FCY (Exch Rate = X)
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, ItemNo, PurchaseLine.Type::Item,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Run Adjust Exch. Rates report with new posting date (Exch Rate = Y)
#if not CLEAN23
        LibraryERM.RunAdjustExchangeRatesSimple(Currency.Code, PostingDate, PostingDate);
#else
        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, PostingDate, PostingDate);
#endif
        // [WHEN] Post Payment in FCY (Exch Rate = Y) and apply to Invoice (fully paid)
        CreatePaymentGenJournalLineWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceNo,
          Round(CalcVendInvoiceAmount(InvoiceNo)), PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FindVATEntry(
          UnrealizedVATEntry, UnrealizedVATEntry.Type::Purchase, UnrealizedVATEntry."Document Type"::Invoice, InvoiceNo);
        FindVATEntry(
          RealizedVATEntry, RealizedVATEntry.Type::Purchase, RealizedVATEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] Realized VAT Entry is posted with original Unrealized amounts
        Assert.AreNearlyEqual(
          UnrealizedVATEntry."Unrealized Base", RealizedVATEntry.Base,
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(
          UnrealizedVATEntry."Unrealized Amount", RealizedVATEntry.Amount,
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption(Amount));

        // [THEN] Unrealized VAT Entry has zero Remaining amounts
        Assert.AreNearlyEqual(
          0, UnrealizedVATEntry."Remaining Unrealized Base",
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption("Remaining Unrealized Base"));
        Assert.AreNearlyEqual(
          0, UnrealizedVATEntry."Remaining Unrealized Amount",
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption("Remaining Unrealized Amount"));
    end;

    [Test]
    [HandlerFunctions('ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure RealizedPercentageVATAdjustExchPaymentFCYtoSalesInvoiceFCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATEntry: Record "VAT Entry";
        RealizedVATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
        PostingDate: Date;
        RateFactorX: Decimal;
        RateFactorY: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363848] Realized VAT is posted with original unrealized amounts after customer payment with new adjusted exch. rate is applied to invoice in FCY.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create Currency with Exchange Rates. Create Customer with Percentage Unrealized VAT setup.
        GeneralSetupForRealizedVAT(
          Currency, VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, ItemNo, PostingDate, RateFactorX, RateFactorY);
        CustomerNo := CreateCustomer(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN]  Post Purchase Invoice in FCY (Exch Rate = X)
        InvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, CustomerNo, SalesLine."Document Type"::Order, SalesLine.Type::Item, ItemNo,
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Run Adjust Exch. Rates report with new posting date (Exch Rate = Y)
#if not CLEAN23
        LibraryERM.RunAdjustExchangeRatesSimple(Currency.Code, PostingDate, PostingDate);
#else
        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, PostingDate, PostingDate);
#endif
        // [WHEN] Post Payment in FCY (Exch Rate = Y) and apply to Invoice (fully paid)
        CreatePaymentGenJournalLineWithAppln(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, InvoiceNo,
          -CalcCustInvoiceAmount(InvoiceNo), PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FindVATEntry(
          UnrealizedVATEntry, UnrealizedVATEntry.Type::Sale, UnrealizedVATEntry."Document Type"::Invoice, InvoiceNo);
        FindVATEntry(
          RealizedVATEntry, RealizedVATEntry.Type::Sale, RealizedVATEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] Realized VAT Entry is posted with original Unrealized amounts
        Assert.AreNearlyEqual(
          UnrealizedVATEntry."Unrealized Base", RealizedVATEntry.Base,
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(
          UnrealizedVATEntry."Unrealized Amount", RealizedVATEntry.Amount,
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption(Amount));

        // [THEN] Unrealized VAT Entry has zero Remaining amounts
        Assert.AreNearlyEqual(
          0, UnrealizedVATEntry."Remaining Unrealized Base",
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption("Remaining Unrealized Base"));
        Assert.AreNearlyEqual(
          0, UnrealizedVATEntry."Remaining Unrealized Amount",
          LibraryERM.GetAmountRoundingPrecision, RealizedVATEntry.FieldCaption("Remaining Unrealized Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntryAfterApplication()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        CreditMemoNo: Code[20];
        UnitAmount: array[2] of Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO 477534] Wrong posted VAT Entries using Unrealized VAT and applying and Invoice against a partial Credit Memo in the Mexican version.
        Initialize();

        // [GIVEN] Create two VAT Posting Setup
        CreateVATPostingSetupWithUnrealizedVATDetail(VATPostingSetup);

        // [GIVEN] Create two Item with different "VAT Prod. Posting Group"
        ItemNo[1] := CreateItem(VATPostingSetup[1]."VAT Prod. Posting Group");
        ItemNo[2] := CreateItem(VATPostingSetup[2]."VAT Prod. Posting Group");

        // [GIVEN] Create customer
        CustomerNo := CreateCustomer('', VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Get two Unit amount for two Items
        UnitAmount[1] := LibraryRandom.RandInt(10);
        UnitAmount[2] := LibraryRandom.RandInt(20);

        // [GIVEN] Create Sales order
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesLine[1]."Document Type"::Order, CustomerNo);

        // [GIVEN] Create first Sales Line of Item1
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item, ItemNo[1], 1);
        SalesLine[1].Validate("Unit Price", UnitAmount[1]);
        SalesLine[1].Modify(true);

        // Create Second Sales Line of Item2
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item, ItemNo[2], 1);
        SalesLine[1].Validate("Unit Price", UnitAmount[2]);
        SalesLine[1].Modify(true);

        // [THEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader[1], true, true);

        // [GIVEN] Create Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesLine[2]."Document Type"::"Credit Memo", CustomerNo);

        // [GIVEN] Create Sales Line for Item1
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item, ItemNo[1], 1);
        SalesLine[2].Validate("Unit Price", UnitAmount[1]);
        SalesLine[2].Modify(true);

        // [GIVEN] Get VAT Amount of Item1
        VATAmount := SalesLine[2].Quantity * SalesLine[2]."Unit Price" * SalesLine[2]."VAT %" / 100;

        // [THEN] Post the Sales Credit Memo
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader[2], true, true);

        // [WHEN] Apply Invoice with Credit Memo
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::"Credit Memo", CreditMemoNo);

        // [VERIFY] Verify VAT Realized Amount for customer.
        VerifyVATEntryForPostApplication(VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntryForSameVATProdPostingGroupAfterApplication()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        CreditMemoNo: Code[20];
        UnitAmount: array[2] of Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO 492281] Verify posted VAT Entries using Unrealized VAT and applying and Invoice against a partial Credit Memo in the Mexican version with quantity 2
        Initialize();

        // [GIVEN] Create two VAT Posting Setup
        CreateVATPostingSetupWithUnrealizedVATDetail(VATPostingSetup);

        // [GIVEN] Create two Item with different "VAT Prod. Posting Group"
        ItemNo[1] := CreateItem(VATPostingSetup[1]."VAT Prod. Posting Group");
        ItemNo[2] := CreateItem(VATPostingSetup[2]."VAT Prod. Posting Group");

        // [GIVEN] Create customer
        CustomerNo := CreateCustomer('', VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Get two Unit amount for two Items
        UnitAmount[1] := LibraryRandom.RandInt(10);
        UnitAmount[2] := LibraryRandom.RandInt(20);

        // [GIVEN] Create Sales order
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesLine[1]."Document Type"::Order, CustomerNo);

        // [GIVEN] Create first Sales Line of Item1
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item, ItemNo[1], 2);
        SalesLine[1].Validate("Unit Price", UnitAmount[1]);
        SalesLine[1].Modify(true);

        // Create Second Sales Line of Item2
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item, ItemNo[2], 2);
        SalesLine[1].Validate("Unit Price", UnitAmount[2]);
        SalesLine[1].Modify(true);

        // [THEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader[1], true, true);

        // [GIVEN] Create Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesLine[2]."Document Type"::"Credit Memo", CustomerNo);

        // [GIVEN] Create Sales Line for Item1
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item, ItemNo[1], 1);
        SalesLine[2].Validate("Unit Price", UnitAmount[1]);
        SalesLine[2].Modify(true);

        // [GIVEN] Get VAT Amount of Item1
        VATAmount := SalesLine[2].Quantity * SalesLine[2]."Unit Price" * SalesLine[2]."VAT %" / 100;

        // [THEN] Post the Sales Credit Memo
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader[2], true, true);

        // [WHEN] Apply Invoice with Credit Memo
        ApplyAndPostCustomerEntry(CustLedgerEntry."Document Type"::"Credit Memo", CreditMemoNo);

        // [VERIFY] Verify VAT Realized Amount for customer.
        VerifyVATEntryForPostApplication(VATAmount);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        UpdateGenLedgerSetup('');
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateVATPostingSetupWithVAT(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; VATCalculationType: Option)
    var
        GLAccount: array[4] of Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        with VATPostingSetup do begin
            Validate("Unrealized VAT Type", UnrealizedVATType);
            Validate("Sales VAT Account", CreateGLAccount(GLAccount[1], "VAT Prod. Posting Group"));
            Validate("Sales VAT Unreal. Account", CreateGLAccount(GLAccount[2], "VAT Prod. Posting Group"));
            Validate("Purchase VAT Account", CreateGLAccount(GLAccount[3], "VAT Prod. Posting Group"));
            Validate("Purch. VAT Unreal. Account", CreateGLAccount(GLAccount[4], "VAT Prod. Posting Group"));
            Modify(true);
        end;
    end;

    local procedure CreateAndPostPaymentGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; ApplyToDocID: Code[20]; Amount: Decimal; PostingDate: Date)
    begin
        CreatePaymentGenJournalLineWithAppln(GenJournalLine, AccountType, AccountNo, ApplyToDocID, Amount, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentGenJournalLineWithAppln(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; ApplyToDocID: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreatePaymentGenJournal(
          GenJournalLine, AccountType, AccountNo, BankAccount."No.", GenJournalLine."Bank Payment Type"::" ",
          Amount, GenJournalTemplate.Type::Payments, GenJournalLine."Document Type"::Payment);
        with GenJournalLine do begin
            Validate("Posting Date", PostingDate);
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", ApplyToDocID);
            Modify(true);
        end;
    end;

    local procedure CreateAndPostPaymentGenJournalLineWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; ApplyToDocID: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    begin
        CreatePaymentGenJournalLineWithAppln(GenJournalLine, AccountType, AccountNo, ApplyToDocID, Amount, PostingDate);
        with GenJournalLine do begin
            Validate("Currency Code", CurrencyCode);
            Validate("Currency Factor", CurrencyFactor);
            Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; BuyfromVendorNo: Code[20]; No: Code[20]; Type: Option; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyfromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Option; Type: Option; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; MultiplicationFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 10 + LibraryRandom.RandDec(100, 2));  // Validate any random Exchange Rate Amount greater than 10.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" * MultiplicationFactor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCurrencyWithDifferentExchangeRate(var Currency: Record Currency; PostingDate: Date; RateFactor: Decimal; RateFactor2: Decimal)
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo);
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo);
        Currency.Modify(true);
        CreateCurrencyExchangeRate(Currency.Code, WorkDate(), RateFactor);
        CreateCurrencyExchangeRate(Currency.Code, PostingDate, RateFactor2);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; VATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        with GLAccount do begin
            Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
            Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            Modify(true);
        end;
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Option)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentGenJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Option; Amount: Decimal; Type: Option; DocumentType: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);  // Using Random value for Deposit Amount.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure GeneralSetupForRealizedVAT(var Currency: Record Currency; var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; var ItemNo: Code[20]; var PostingDate: Date; var RateFactor: Decimal; var RateFactor2: Decimal)
    begin
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(2, 6)) + 'M>', WorkDate());
        RateFactor := LibraryRandom.RandDec(3, 2); // Using Random Range value for Currency Exch. Rate factor.
        RateFactor2 := RateFactor + LibraryRandom.RandDec(3, 2);
        CreateCurrencyWithDifferentExchangeRate(Currency, PostingDate, RateFactor, RateFactor2);
        CreateVATPostingSetupWithVAT(
          VATPostingSetup, UnrealizedVATType, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure UpdateGenLedgerSetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode; // Validate is not required.
        GeneralLedgerSetup.Validate("Unrealized VAT", true); // Required for test.
        GeneralLedgerSetup.Validate("Deposit Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        GeneralLedgerSetup.Validate("Bank Rec. Adj. Doc. Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; VATType: Option; DocumentType: Option; DocumentNo: Code[20])
    begin
        with VATEntry do begin
            SetRange(Type, VATType);
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            FindFirst();
        end;
    end;

    local procedure CalcVendInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount);
        exit(Abs(VendorLedgerEntry.Amount));
    end;

    local procedure CalcCustInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
        exit(Abs(CustLedgerEntry.Amount));
    end;

    local procedure VerifyGLEntryForRealizedVAT(DocumentNo: Code[20]; GLAccountNo: Code[20]; GLAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            SetFilter("Gen. Posting Type", '<>%1', "Gen. Posting Type"::" ");
            FindLast();
            TestField(Amount, GLAmount);
        end;
    end;

    local procedure VerifyVATAmountsInLastPmtVATEntry(VATType: Option; DocumentNo: Code[20]; VATAmount: Decimal; VATBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATType, VATEntry."Document Type"::Payment, DocumentNo);
        VATEntry.FindLast();
        VATEntry.TestField(Amount, VATAmount);
        VATEntry.TestField(Base, VATBase);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Option; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyCustomerEntry(var ApplyCustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Option; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
        GEnJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyCustLedgerEntry, DocumentType, DocumentNo);
        ApplyCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyCustLedgerEntry, ApplyCustLedgerEntry."Remaining Amount");
        GLRegister.FindLast();
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No." - 1);
        CustLedgerEntry.SetRange("Applying Entry", false);
        CustLedgerEntry.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry)
    end;

    local procedure VerifyVATEntryForPostApplication(VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.FindSet();
        Assert.AreNearlyEqual(
          VATEntry.Amount, -VATAmount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
        VATEntry.Next();
        Assert.AreNearlyEqual(
          VATEntry.Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), -VATAmount, VATEntry.TableCaption()));
    end;

    local procedure CreateVATPostingSetupWithUnrealizedVATDetail(var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[1], VATBusPostingGroup.Code, VATProdPostingGroup[1].Code);
        UpdateVATPostingSetupWithGLAccount(VATPostingSetup[1]);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATBusPostingGroup.Code, VATProdPostingGroup[2].Code);
        UpdateVATPostingSetupWithGLAccount(VATPostingSetup[2]);
    end;

    local procedure UpdateVATPostingSetupWithGLAccount(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::"Cash Basis");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier",
         LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Tax Category", 'S');
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyRealizedVATAmountsInVATEntry(VATType: Option; DocumentType: Option; DocumentNo: Code[20]; RealizedVATAmount: Decimal; RealizedVATBase: Decimal; AmtRounding: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATType, DocumentType, DocumentNo);
        Assert.AreNearlyEqual(RealizedVATAmount, VATEntry."Realized Amount", AmtRounding, '');
        Assert.AreNearlyEqual(RealizedVATBase, VATEntry."Realized Base", AmtRounding, '');
    end;

    local procedure VerifyRemainingUnrealizedVATAmountAndVATBase(DocumentNo: Code[20]; VATAmount: Decimal; VATBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Document No.", DocumentNo);
            FindFirst();
            TestField("Remaining Unrealized Amount", VATAmount);
            TestField("Remaining Unrealized Base", VATBase);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExchRateAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

