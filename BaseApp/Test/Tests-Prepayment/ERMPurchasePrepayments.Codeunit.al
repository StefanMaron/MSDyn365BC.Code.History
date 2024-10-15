codeunit 134333 "ERM Purchase Prepayments"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        LCYCode: Code[10];
        NoAmtFoundToBePostedErr: Label 'No amount found to be posted.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Prepayments");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Prepayments");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LCYCode := '';
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Prepayments");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorDefaultPrepaymentDisc()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // 1. Setup
        Initialize();

        // Create a vendor with prepayment discount
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prepayment %", LibraryRandom.RandInt(100));
        Vendor.Modify(true);

        // 2. Exercise - Create a purchase order for the vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // 3. Validation - Check prepayment in the purchase order is the same we defined in the vendor
        PurchaseHeader.TestField("Prepayment %", Vendor."Prepayment %");

        // 4. Clean-up
    end;

    local procedure PostPurchasePrepaymentHelper(CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPrepaymentAmount: Decimal;
    begin
        // 1. Setup
        Initialize();

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandInt(100));
        CreatePurchOrder(PurchaseHeader, Vendor, Item, CurrencyCode);

        // 2. Exercise - Post prepayment invoice in foreign currency order.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // 3. Validation
        ForceAmountRecalculation(PurchaseHeader);

        // Check vendor only has one ledger entry (the prepayment).
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 1);

        // And check the prepayment amount is right.
        ExpectedPrepaymentAmount := -CalculatePrepaymentAmount(PurchaseHeader, CurrencyCode);

        VendorLedgerEntry.FindFirst();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedPrepaymentAmount, CurrencyCode);

        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchasePrepayment()
    begin
        PostPurchasePrepaymentHelper(LCYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchasePrepayment()
    var
        ForeignCurrency: Record Currency;
    begin
        FindForeignCurrency(ForeignCurrency);
        PostPurchasePrepaymentHelper(ForeignCurrency.Code);
    end;

    local procedure PostPurchPrepayCrMemoHelper(CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedCreditMemoAmount: Decimal;
    begin
        // 1. Setup
        Initialize();

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandInt(100));
        CreatePurchOrder(PurchaseHeader, Vendor, Item, CurrencyCode);

        // Post the prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // release the PO, required to update amount fields in the purchase lines, which is required before calculating the
        // Amount including VAT (flow field based on them).
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");

        // Prepare data to post credit memo.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo());
        PurchaseHeader.Modify(true);

        // 2. Exercise - Post the credit memo
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);

        // 3. Validation
        // Check vendor only has two ledger entries -  one entry the prepayment, the other one the credit memo.
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 2);

        // And check the prepayment amount is right.
        ExpectedCreditMemoAmount := CalculatePrepaymentAmount(PurchaseHeader, CurrencyCode);

        VendorLedgerEntry.FindLast();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedCreditMemoAmount, CurrencyCode);
        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchPrepCreditMemo()
    begin
        PostPurchPrepayCrMemoHelper(LCYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchPrepCreditMemo()
    var
        ForeignCurrency: Record Currency;
    begin
        FindForeignCurrency(ForeignCurrency);
        PostPurchPrepayCrMemoHelper(ForeignCurrency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoPurchasePrepayments()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPrepaymentAmount: Decimal;
        FirstPrepaymentPercentage: Decimal;
        SecondPrepaymentPercentage: Decimal;
        MaximumPrepaymentPercentage: Integer;
        MinimumPrepaymentPercentage: Integer;
    begin
        // 1. Setup
        Initialize();

        MaximumPrepaymentPercentage := 100;

        // First prepayment should can't be the maximum because then there would be no room for the second one.
        FirstPrepaymentPercentage := LibraryRandom.RandInt(MaximumPrepaymentPercentage - 1);

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, FirstPrepaymentPercentage);
        CreatePurchOrder(PurchaseHeader, Vendor, Item, LCYCode);

        // Post the prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Reopen Doc
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Change prepayment to higher percentage.
        MinimumPrepaymentPercentage := Vendor."Prepayment %" + 1;
        SecondPrepaymentPercentage := LibraryRandom.RandIntInRange(MinimumPrepaymentPercentage, MaximumPrepaymentPercentage);
        PurchaseHeader.Validate("Prepayment %", SecondPrepaymentPercentage);

        // New Vendor Invoice no. otherwise it can't be posted.
        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);

        // 2. Exercise - Post the 2nd prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // 3. Validation
        ForceAmountRecalculation(PurchaseHeader);

        // Check vendor only has two ledger entries (one for each prepayment).
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 2);

        // And check the 2nd prepayment amount is right.
        PurchaseHeader.CalcFields("Amount Including VAT");
        ExpectedPrepaymentAmount := Round(-SecondPrepaymentPercentage * PurchaseHeader."Amount Including VAT" / 100);
        ExpectedPrepaymentAmount -= Round(-FirstPrepaymentPercentage * PurchaseHeader."Amount Including VAT" / 100);

        VendorLedgerEntry.FindLast();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedPrepaymentAmount, LCYCode);

        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSecondPrepaymentInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentType: Option Invoice,"Credit Memo",Statistic;
        TempDecToHaveItEqual: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379850] Prepayment Invoice should be posted if one line of Purchase Invoice has amount to be posted and the last line has not

        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        VATPostingSetup.SetRange("VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", '');
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDecInRange(101, 200, 2));
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);

        Assert.IsTrue(PurchasePostPrepayments.CheckOpenPrepaymentLines(PurchaseHeader, DocumentType::Invoice), NoAmtFoundToBePostedErr);
    end;

    local procedure PreparePrepaymentsPostingSetup(var GLAccount: Record "G/L Account")
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          GLAccount, PrepmtGLAccount, GLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Normal VAT");
    end;

    local procedure PrepareItemAccordingToSetup(var Item: Record Item; GLAccount: Record "G/L Account")
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Create an Item that uses this setup (finding was not possible in all cases).
        InventoryPostingGroup.FindFirst();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, LibraryRandom.RandInt(0));

        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure PrepareVendorAccordingToSetup(var Vendor: Record Vendor; GLAccount: Record "G/L Account"; PrepaymentPercentage: Integer)
    begin
        // Create a vendor with prepayment discount according to the GL Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Vendor.Validate("Prepayment %", PrepaymentPercentage);
        Vendor.Modify();
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; Item: Record Item; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create a purchase order for the vendor with the Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithPrepmtAmts(var PurchaseHeader: Record "Purchase Header"; PrepmtLineAmount: Decimal; PrepmtAmtInv: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandInt(10));
        PurchaseLine."Prepmt. Line Amount" := PrepmtLineAmount;
        PurchaseLine."Prepmt. Amt. Inv." := PrepmtAmtInv;
        PurchaseLine.Modify();
    end;

    local procedure CheckNumOfVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; NumExpectedLedgerEntries: Integer)
    begin
        VendorLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        Assert.AreEqual(NumExpectedLedgerEntries, VendorLedgerEntry.Count,
          StrSubstNo('Expected to find exactly %1 Vendor ledger entry.', NumExpectedLedgerEntries));
    end;

    local procedure ForceAmountRecalculation(var PurchaseHeader: Record "Purchase Header")
    begin
        // Release the PO, required to update amount fields in the purchase lines.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // After that Amount including VAT can be properly recalculated
        PurchaseHeader.CalcFields("Amount Including VAT");
    end;

    local procedure CalculatePrepaymentAmount(PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[20]) PrepaymentAmount: Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);

        PrepaymentAmount := Round(PurchaseHeader."Amount Including VAT" * PurchaseHeader."Prepayment %" / 100,
            Currency."Invoice Rounding Precision", '=');
    end;

    local procedure ValidateVendorLedgerEntries(VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedPrepaymentAmount: Decimal; CurrencyCode: Code[20])
    begin
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(ExpectedPrepaymentAmount, VendorLedgerEntry.Amount, 'Posted prepayment amount is not the expected one');
        Assert.AreEqual(CurrencyCode, VendorLedgerEntry."Currency Code", 'Currency in posted vendor ledger entry is not the expected one');
    end;

    local procedure FindForeignCurrency(var Currency: Record Currency)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        GeneralLedgerSetup.Get();
        Currency.SetFilter(Code, '<>%1', GeneralLedgerSetup."LCY Code");
        LibraryERM.FindCurrency(Currency);

        // Find if a valid exchange rate exists for the currency
        CurrencyExchangeRate.SetFilter("Currency Code", Currency.Code);
        CurrencyExchangeRate.SetFilter("Starting Date", '<=%1', WorkDate());
        if CurrencyExchangeRate.Count = 0 then
            // Create exchange rate so we're sure there's one
            LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;
}

