codeunit 144038 "ERM Cost Regulation"
{
    //  1. Verify Amount in Intrastat Journal when posting a purchase order with a invoice discount and payment discount shipping and invoicing in same month with Currency.
    //  2. Verify Amount in Intrastat Journal when posting a purchase order with a invoice discount and payment discount shipping and invoicing in different months with Currency.
    //  3. Verify Amount in Intrastat Journal when posting a purchase order with a payment and invoice discount shipping and invoicing in different months without Currency.
    //  4. Verify Amount in Intrastat Journal when posting a purchase order with a payment and invoice discount shipping and invoicing in same months without Currency.
    //  5. Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in same month with Currency.
    //  6. Verify Amount in Intrastat Journal when posting a sales order with a invoice discount and payment discount shipping and invoicing in different months with Currency.
    //  7. Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in different months without Currency.
    //  8. Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in same months without Currency.
    // 
    // Covers Test Cases for WI:351157
    // -----------------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // -----------------------------------------------------------------------------------------
    // PurchaseIntrastatJournalWithInvDiscSameMonth                              156311,156302
    // PurchaseIntrastatJournalWithInvDiscNextMonth                              156310,156309
    // PurchaseIntrastatJournalWithoutCurrencyInvDiscNextMonth                   156312
    // PurchaseIntrastatJournalWithoutCurrencyInvDiscSameMonth                   156313
    // SalesIntrastatJournalWithInvDiscSameMonth                                 156308,156306
    // SalesIntrastatJournalWithInvDiscNextMonth                                 156307,156305
    // SalesIntrastatJournalWithoutCurrencyInvDiscNextMonth                      156303
    // SalesIntrastatJournalWithoutCurrencyInvDiscSameMonth                      156304

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ValidationError: Label '%1 must be %2 in %3.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseIntrastatJournalWithInvDiscSameMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a purchase order with a invoice discount and payment discount shipping and invoicing in same month with Currency.
        Initialize();
        PurchaseIntrastatJournal(
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), CreateCurrencyWithExchangeRate);  // Using Random value for NewPostingDate.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseIntrastatJournalWithInvDiscNextMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a purchase order with a invoice discount and payment discount shipping and invoicing in different months with Currency.
        Initialize();
        PurchaseIntrastatJournal(
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), CreateCurrencyWithExchangeRate);  // Using Random value for NewPostingDate.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseIntrastatJournalWithoutCurrencyInvDiscNextMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a purchase order with a payment and invoice discount shipping and invoicing in different months without Currency.
        Initialize();
        PurchaseIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), '');  // Using Random value for NewPostingDate and blank Currency Code.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseIntrastatJournalWithoutCurrencyInvDiscSameMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a purchase order with a payment and invoice discount shipping and invoicing in same months without Currency.
        Initialize();
        PurchaseIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), '');  // Using Random value for NewPostingDate and blank Currency Code.
    end;

    local procedure PurchaseIntrastatJournal(NewPostingDate: Date; CurrencyCode: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        DiscountPct: Decimal;
    begin
        // Setup.
        PurchasesPayablesSetup.Get();
        UpdateCalcInvDiscountInPurchasesPayablesSetup(true);
        DiscountPct := LibraryRandom.RandDec(10, 2);
        DocumentNo := CreateAndPostPurchaseOrder(PurchaseLine, WorkDate(), DiscountPct, CurrencyCode);
        UpdateAndPostPurchaseOrder(PurchaseLine, NewPostingDate);
        CreateIntrastatJnlLine(IntrastatJnlLine);
        EnqueueValueForGetItemLedgerEntriesReportHandler(NewPostingDate);  // Enqueue value for GetItemLedgerEntriesReportHandler.
        Amount :=
          LibraryERM.ConvertCurrency(
            PurchaseLine.Amount - (PurchaseLine.Amount * DiscountPct / 100), PurchaseLine."Currency Code", '', WorkDate());  // Using blank for ToCur.

        // Exercise.
        RunGetItemEntries;

        // Verify.
        VerifyIntrastatLine(DocumentNo, PurchaseLine."No.", PurchaseLine.Quantity, Round(Amount), IntrastatJnlLine.Type::Receipt);

        // TearDown.
        UpdateCalcInvDiscountInPurchasesPayablesSetup(PurchasesPayablesSetup."Calc. Inv. Discount");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesIntrastatJournalWithInvDiscSameMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in same month with Currency.
        Initialize();
        SalesIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), CreateCurrencyWithExchangeRate);  // Using Random value for NewPostingDate.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesIntrastatJournalWithInvDiscNextMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a sales order with a invoice discount and payment discount shipping and invoicing in different months with Currency.
        Initialize();
        SalesIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), CreateCurrencyWithExchangeRate);  // Using Random value for NewPostingDate.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesIntrastatJournalWithoutCurrencyInvDiscNextMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in different months without Currency.
        Initialize();
        SalesIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), '');  // Using Random value for NewPostingDate and blank Currency Code.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesIntrastatJournalWithoutCurrencyInvDiscSameMonth()
    begin
        // Verify Amount in Intrastat Journal when posting a sales order with a payment and invoice discount shipping and invoicing in same months without Currency.
        Initialize();
        SalesIntrastatJournal(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), '');  // Using Random value for NewPostingDate and blank Currency Code.
    end;

    local procedure SalesIntrastatJournal(NewPostingDate: Date; CurrencyCode: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        DiscountPct: Decimal;
    begin
        // Setup.
        SalesReceivablesSetup.Get();
        UpdateCalcInvDiscountInSalesReceivablesSetup(true);
        DiscountPct := LibraryRandom.RandDec(10, 2);
        DocumentNo := CreateAndPostSalesOrder(SalesLine, WorkDate(), DiscountPct, CurrencyCode);
        UpdateAndPostSalesOrder(SalesLine, NewPostingDate);
        CreateIntrastatJnlLine(IntrastatJnlLine);
        EnqueueValueForGetItemLedgerEntriesReportHandler(NewPostingDate);  // Enqueue value for GetItemLedgerEntriesReportHandler.
        Amount :=
          LibraryERM.ConvertCurrency(
            SalesLine.Amount - (SalesLine.Amount * DiscountPct / 100), SalesLine."Currency Code", '', WorkDate());  // Using blank for ToCur.

        // Exercise.
        RunGetItemEntries;

        // Verify.
        VerifyIntrastatLine(DocumentNo, SalesLine."No.", SalesLine.Quantity, Round(Amount), IntrastatJnlLine.Type::Shipment);

        // TearDown.
        UpdateCalcInvDiscountInSalesReceivablesSetup(SalesReceivablesSetup."Calc. Inv. Discount");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        UpdateIntrastatCodeInCountryRegion;
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        IntrastatJournal.OpenEdit;  // Required to set Intrastat Journal Template through record.
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateAndUpdateIntrastatBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name, Format(Today, 0, LibraryFiscalYear.GetStatisticsPeriod));
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
    end;

    local procedure CreateCustomerWithInvDiscountSetup(CurrencyCode: Code[10]; DiscountPct: Decimal): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryRegionCode);
        Customer.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);  // Using blank for Currency Code and 0 for Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentTermsWithDiscount(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);  // Using False for CalcPmtDiscOnCrMemos.
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; PostingDate: Date; DiscountPct: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithInvDiscountSetup(DiscountPct, CurrencyCode));
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));  // Using True for Receive and False for Invoice.
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; PostingDate: Date; DiscountPct: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithInvDiscountSetup(CurrencyCode, DiscountPct));
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Using True for Ship and False for Invoice.
    end;

    local procedure CreateAndUpdateIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; JournalTemplateName: Code[10]; StatisticsPeriod: Code[10])
    begin
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, JournalTemplateName);
        IntrastatJnlBatch.Validate("Statistics Period", StatisticsPeriod);
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateVendorWithInvDiscountSetup(DiscountPct: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryRegionCode);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", '', 0);  // Using blank for Currency Code and 0 for Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValueForGetItemLedgerEntriesReportHandler(NewPostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', WorkDate()));
        LibraryVariableStorage.Enqueue(NewPostingDate);
    end;

    local procedure GetCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>''''');
        CountryRegion.FindFirst();
        exit(CountryRegion.Code);
    end;

    local procedure RunGetItemEntries()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        Commit();  // Commit required.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.GetEntries.Invoke;
    end;

    local procedure UpdateAndPostPurchaseOrder(PurchaseLine: Record "Purchase Line"; NewPostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Posting Date", NewPostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Using False for Receive and True for Invoice.
    end;

    local procedure UpdateAndPostSalesOrder(SalesLine: Record "Sales Line"; NewPostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Posting Date", NewPostingDate);
        SalesHeader.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Using False for Receive and True for Invoice.
    end;

    local procedure UpdateCalcInvDiscountInPurchasesPayablesSetup(CalcInvDiscount: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateCalcInvDiscountInSalesReceivablesSetup(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateIntrastatCodeInCountryRegion()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure VerifyIntrastatLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Amount: Decimal; Type: Option)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        IntrastatJnlLine.FindFirst();
        Assert.AreEqual(
          Type, IntrastatJnlLine.Type,
          StrSubstNo(ValidationError, IntrastatJnlLine.FieldCaption(Type), Type, IntrastatJnlLine.TableCaption()));
        Assert.AreEqual(
          Quantity, IntrastatJnlLine.Quantity,
          StrSubstNo(ValidationError, IntrastatJnlLine.FieldCaption(Quantity), Quantity, IntrastatJnlLine.TableCaption()));
        Assert.AreEqual(
          GetCountryRegionCode, IntrastatJnlLine."Country/Region Code", StrSubstNo(ValidationError,
            IntrastatJnlLine.FieldCaption("Country/Region Code"), GetCountryRegionCode, IntrastatJnlLine.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, IntrastatJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision, StrSubstNo(ValidationError,
            IntrastatJnlLine.FieldCaption(Amount), Amount, IntrastatJnlLine.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatJnlTemplateListModalPageHandler(var IntrastatJnlTemplateList: TestPage "Intrastat Jnl. Template List")
    begin
        IntrastatJnlTemplateList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    var
        StartingDate: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        GetItemLedgerEntries.StartingDate.SetValue(StartingDate);
        GetItemLedgerEntries.EndingDate.SetValue(EndingDate);
        GetItemLedgerEntries.OK.Invoke;
    end;
}

