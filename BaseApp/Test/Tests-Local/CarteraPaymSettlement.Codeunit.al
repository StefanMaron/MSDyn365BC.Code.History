codeunit 147501 "Cartera Paym. Settlement"
{
    // Cartera scenarios having as setup posted payment orders.
    // The scenarios exercise closing payment orders with opened cartera documents.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        IsInitialized: Boolean;
        NotPrintedPaymentOrderQst: Label 'This %1 has not been printed. Do you want to continue?';
        PaymentOrderSuccessfullyPostedMsg: Label 'The %1 %2 was successfully posted.', Comment = '%1=Table,%2=Field';
        BatchSettlementPOMsg: Label '%1 Documents in %2 Payment Orders totaling %3 (LCY) have been settled.';
        PartialSettlementPOMsg: Label '%1 payable documents totaling %2 have been partially settled in Payment Order %3 by an amount of %4.';
        UnexpectedCartDocStatusErr: Label 'Unexpected closed Cartera Document status.';
        InvalidStatusPartiallySettledCarteraDocErr: Label 'Invalid status of partially settled Cartera document.';
        UnexpectedCartDocRemAmountErr: Label 'Unexpected remaining amount for closed Cartera Document.';
        UnexpectedPartSettledCartDocRemAmountErr: Label 'Unexpected remaining amount on partially settled payable Cartera doc.';
        LocalCurrencyCode: Code[10];
        SettlementCompletedSuccessfullyMsg: Label '%1 documents totaling %2 have been settled.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderTest()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        PostedPaymentOrder: Record "Posted Payment Order";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        // Setup - Exercise
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Pre-Verify
        LibraryCarteraPayables.FindInvoiceVendorLedgerEntry(
          VendorLedgerEntry, Vendor."No.", CarteraDoc."Document No.", VendorLedgerEntry."Document Situation"::"Posted BG/PO");

        // Verify
        PostedPaymentOrder.SetRange("Bank Account No.", BankAccount."No.");
        PostedPaymentOrder.FindLast();
        VendorLedgerEntry.TestField(Amount, PostedPaymentOrder.Amount);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementNonLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        CurrencyCode: Code[10];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, CurrencyCode);
        PostPaymentOrderNonLCY(PaymentOrder."No.");

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
    begin
        Initialize();

        // Pre-Setup
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView;

        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke;
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementNonLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
        CurrencyCode: Code[10];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);
        PreparePaymentOrder(Vendor, BankAccount, CarteraDoc, PaymentOrder, CurrencyCode);
        PostPaymentOrderNonLCY(PaymentOrder."No.");

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView;
        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke;
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOPartialSettlementWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PostPaymentOrderWithUnrealizedVAT(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, InitialAmount, ExpectedVATAmount, DocumentNo, LocalCurrencyCode);
        LibraryCarteraPayables.ValidatePostedInvoiceUnrVATGLEntries(DocumentNo, PurchUnrVATAccount, InitialAmount);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, 0);
        ExpectedVATAmount := Round(ExpectedVATAmount * SettledAmount / InitialAmount, LibraryERM.GetAmountRoundingPrecision);

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        LibraryCarteraPayables.ValidatePaymentUnrVATGLEntries(
          CarteraDoc."Bill Gr./Pmt. Order No.", PurchUnrVATAccount, InitialAmount, ExpectedVATAmount, SettledAmount);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,BatchSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPOBatchSettlementWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders Select.";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        TotalAmount: Decimal;
        ExpectedVATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PostPaymentOrderWithUnrealizedVAT(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, TotalAmount, ExpectedVATAmount, DocumentNo, LocalCurrencyCode);

        LibraryCarteraPayables.ValidatePostedInvoiceUnrVATGLEntries(DocumentNo, PurchUnrVATAccount, TotalAmount);

        // Setup - Open Posted Payment Orders page, from Cartera - Periodic Activities section and invoke 'Batch Settlement' action
        PostedPaymentOrdersTestPage.OpenView;
        PostedPaymentOrder.Get(PaymentOrder."No.");
        PostedPaymentOrdersTestPage.GotoRecord(PostedPaymentOrder);

        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementPOMsg, 1, 1, CarteraDoc."Remaining Amt. (LCY)"));

        // Exercise - Verify
        PostedPaymentOrdersTestPage.BatchSettlement.Invoke;

        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        LibraryCarteraPayables.ValidatePaymentUnrVATGLEntries(
          CarteraDoc."Bill Gr./Pmt. Order No.", PurchUnrVATAccount, TotalAmount, ExpectedVATAmount, TotalAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementOfPrepaymentOrderWithAdjustForPaymentDisc()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        DiscountAmount: Decimal;
        InvoiceAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();

        // Setup
        PreparePaymentOrderWithPaymentTermsDiscountLCY(Vendor, BankAccount, CarteraDoc, PaymentOrder, DiscountAmount, InitialAmount);
        PostPaymentOrderLCY(PaymentOrder);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(
          PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, DiscountAmount);
        InvoiceAmount := InitialAmount - DiscountAmount;
        RemainingAmount := InvoiceAmount - SettledAmount;

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Excercise - Settle Remaining part
        LibraryVariableStorage.Enqueue(RemainingAmount);
        LibraryVariableStorage.Enqueue(StrSubstNo(PartialSettlementPOMsg, 1, RemainingAmount, PaymentOrder."No.", RemainingAmount));
        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke;

        VerifyGLEntriesForPartialSettlementsWithDiscount(
          PaymentOrder."No.", DiscountAmount, InitialAmount, SettledAmount, false, 0);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementOfPrepaymentOrderWithAdjustForPaymentDiscWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        DiscountAmount: Decimal;
        InvoiceAmount: Decimal;
        RemainingAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();

        // Setup
        PostPaymentOrderWithUnrealizedVATAndDiscountLCY(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, InitialAmount, ExpectedVATAmount, DocumentNo, DiscountAmount);

        // Exercise - Invoke partial settlement
        InvokePartialSettlementOnPaymentOrder(
          PostedPaymentOrdersTestPage, PaymentOrder."No.", CarteraDoc, SettledAmount, InitialAmount, DiscountAmount);
        InvoiceAmount := InitialAmount - DiscountAmount;
        RemainingAmount := InvoiceAmount - SettledAmount;

        // Verify
        VerifyPartialSettlementOnPaymentOrder(CarteraDoc, InitialAmount, SettledAmount, PaymentOrder);

        // Excercise - Settle Remaining part
        LibraryVariableStorage.Enqueue(RemainingAmount);
        LibraryVariableStorage.Enqueue(StrSubstNo(PartialSettlementPOMsg, 1, RemainingAmount, PaymentOrder."No.", RemainingAmount));

        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke;

        VerifyGLEntriesForPartialSettlementsWithDiscount(
          PaymentOrder."No.", DiscountAmount, InitialAmount, SettledAmount, true, ExpectedVATAmount);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementOfOrderWithAdjustForPaymentDiscount()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        TotalAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        PreparePaymentOrderWithPaymentTermsDiscountLCY(Vendor, BankAccount, CarteraDoc, PaymentOrder, DiscountAmount, TotalAmount);
        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
        VerifyGLEntriesForTotalSettlementWithDiscount(PaymentOrder."No.", DiscountAmount, TotalAmount, false, 0);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementOfOrderWithAdjustForPaymentDiscountAndUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        TotalAmount: Decimal;
        DiscountAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        PostPaymentOrderWithUnrealizedVATAndDiscountLCY(
          Vendor, BankAccount, CarteraDoc, PaymentOrder, TotalAmount, ExpectedVATAmount, DocumentNo, DiscountAmount);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
        VerifyGLEntriesForTotalSettlementWithDiscount(PaymentOrder."No.", DiscountAmount, TotalAmount, true, ExpectedVATAmount);
        VerifyCarteraDocIsClosedAsHonored(CarteraDoc);

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVATPositiveNegativeLinesInDocument()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 416820] Stan can settle Payment Order for Invoice containing NO VAT self balancing zero VAT Entries within Cash Regime and Unrealized VAT
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
          Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 0);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", -1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"07 Special Cash");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,SettleDocsinPostedPORequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVATRealizesAllVATEntries()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentOrder: Record "Payment Order";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 427600] System settles all VAT entries associated with a Cartera document.
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        LibraryERM.SetUnrealizedVAT(true);

        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, '');
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
            Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 10);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Vendor."VAT Bus. Posting Group", 21);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"07 Special Cash");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter("Unrealized Base", '>0');
        Assert.RecordCount(VATEntry, 2);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, '');

        PostPaymentOrderLCY(PaymentOrder);

        InvokeTotalSettlementOnPaymentOrder(PaymentOrder."No.");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.TestField(Open, false);

        VATEntry.Reset();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        Assert.RecordCount(VATEntry, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();

        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);

        if IsInitialized then
            exit;

        LocalCurrencyCode := '';
        IsInitialized := true;
    end;

    local procedure PostPaymentOrderLCY(var PaymentOrder: Record "Payment Order")
    var
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(NotPrintedPaymentOrderQst, PaymentOrder.TableCaption));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption, PaymentOrder."No."));
        POPostAndPrint.PayablePostOnly(PaymentOrder);
    end;

    local procedure PostPaymentOrderNonLCY(PaymentOrderNo: Code[20])
    var
        PaymentOrder: Record "Payment Order";
        PaymentOrders: TestPage "Payment Orders";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(NotPrintedPaymentOrderQst, PaymentOrder.TableCaption));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption, PaymentOrderNo));

        PaymentOrders.OpenEdit;
        PaymentOrders.GotoKey(PaymentOrderNo);
        PaymentOrders.Post.Invoke;
    end;

    local procedure PostPaymentOrderWithUnrealizedVAT(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal; var DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, CurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        TotalAmount :=
          -1 * LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);

        CalculateExpectedVATAmount(DocumentNo, TotalAmount, ExpectedVATAmount);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, CurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);
    end;

    local procedure PostPaymentOrderWithUnrealizedVATAndDiscountLCY(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal; var DocumentNo: Code[20]; var DiscountAmount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DiscountPct: Decimal;
    begin
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, LocalCurrencyCode);
        DiscountPct := LibraryRandom.RandIntInRange(10, 90);
        AddDiscountToPaymentTerms(PaymentTerms, Vendor, DiscountPct);

        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        TotalAmount :=
          -1 * LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);
        CalculateExpectedVATAmount(DocumentNo, TotalAmount, ExpectedVATAmount);

        DiscountAmount := Round(TotalAmount * DiscountPct / 100, LibraryERM.GetAmountRoundingPrecision);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, LocalCurrencyCode);
        PostPaymentOrderLCY(PaymentOrder);
    end;

    local procedure PreparePaymentOrderWithPaymentTermsDiscountLCY(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; var DiscountAmount: Decimal; var TotalAmount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, LocalCurrencyCode);
        DiscountPct := LibraryRandom.RandIntInRange(10, 90);
        AddDiscountToPaymentTerms(PaymentTerms, Vendor, DiscountPct);

        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, LocalCurrencyCode);

        TotalAmount := CarteraDoc."Remaining Amount";
        DiscountAmount := Round(TotalAmount * DiscountPct / 100, LibraryERM.GetAmountRoundingPrecision);
    end;

    local procedure PreparePaymentOrder(var Vendor: Record Vendor; var BankAccount: Record "Bank Account"; var CarteraDoc: Record "Cartera Doc."; var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10])
    var
        DocumentNo: Code[20];
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        CreatePaymentOrder(BankAccount, PaymentOrder, CarteraDoc, DocumentNo, Vendor, CurrencyCode);
    end;

    local procedure CreatePaymentOrder(var BankAccount: Record "Bank Account"; var PaymentOrder: Record "Payment Order"; var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        if CurrencyCode = LocalCurrencyCode then
            LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode)
        else begin
            LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
            CreatePaymentOrderThroughPage(CurrencyCode, BankAccount."No.", PaymentOrder);
        end;

        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, Vendor."No.", PaymentOrder."No.");

        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Validate("Elect. Pmts Exported", true);
        PaymentOrder.Modify(true);
    end;

    local procedure CreatePaymentOrderThroughPage(CurrencyCode: Code[10]; BankAccountNo: Code[20]; var PaymentOrder: Record "Payment Order")
    var
        PaymentOrders: TestPage "Payment Orders";
        PaymentOrderNo: Text;
    begin
        PaymentOrders.OpenNew();

        LibraryVariableStorage.Enqueue(CurrencyCode);
        PaymentOrders."Currency Code".Activate;
        PaymentOrders."Currency Code".Lookup;

        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentOrders."Bank Account No.".Activate;
        PaymentOrders."Bank Account No.".Lookup;

        PaymentOrderNo := PaymentOrders."No.".Value;

        PaymentOrders.OK.Invoke;

        PaymentOrder.Get(PaymentOrderNo);
    end;

    local procedure CreateVATPostingSetupVATCashRegime(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CalculateExpectedVATAmount(DocumentNo: Code[20]; TotalAmount: Decimal; var ExpectedVATAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();

        VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");
        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision);
    end;

    local procedure AddDiscountToPaymentTerms(var PaymentTerms: Record "Payment Terms"; Vendor: Record Vendor; var DiscountPct: Decimal)
    begin
        PaymentTerms.Get(Vendor."Payment Terms Code");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Due Date Calculation");
        DiscountPct := LibraryRandom.RandIntInRange(5, 90);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
    end;

    local procedure InvokeTotalSettlementOnPaymentOrder(PostedPaymentOrderNo: Code[20])
    var
        PostedPaymentOrderTestPage: TestPage "Posted Payment Orders";
    begin
        PostedPaymentOrderTestPage.OpenEdit;
        PostedPaymentOrderTestPage.FILTER.SetFilter("No.", PostedPaymentOrderNo);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, PostedPaymentOrderTestPage.Docs."Remaining Amount".AsDEcimal));

        PostedPaymentOrderTestPage.Docs.TotalSettlement.Invoke;
    end;

    local procedure InvokePartialSettlementOnPaymentOrder(var PostedPaymentOrdersTestPage: TestPage "Posted Payment Orders"; PostedPaymentOrderNo: Code[20]; CarteraDoc: Record "Cartera Doc."; var SettledAmount: Decimal; var InitialAmount: Decimal; DiscountAmount: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        PostedPaymentOrdersTestPage.OpenView;
        PostedPaymentOrdersTestPage.GotoKey(PostedPaymentOrderNo);

        GLSetup.Get();
        InitialAmount := CarteraDoc."Remaining Amount";
        SettledAmount := LibraryRandom.RandDecInDecimalRange(0, InitialAmount / 2,
            LibraryCarteraPayables.GetRandomAllowedNumberOfDecimals(GLSetup."Amount Decimal Places"));

        LibraryVariableStorage.Enqueue(SettledAmount);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(PartialSettlementPOMsg, 1, InitialAmount - DiscountAmount, PostedPaymentOrderNo, SettledAmount));

        PostedPaymentOrdersTestPage.Docs.PartialSettlement.Invoke;
    end;

    local procedure VerifyPartialSettlementOnPaymentOrder(CarteraDoc: Record "Cartera Doc."; InitialAmount: Decimal; SettledAmount: Decimal; PaymentOrder: Record "Payment Order")
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedPaymentOrder: Record "Closed Payment Order";
    begin
        PostedCarteraDoc.SetFilter("Document No.", CarteraDoc."Document No.");
        PostedCarteraDoc.SetFilter(Type, Format(CarteraDoc.Type));
        PostedCarteraDoc.FindFirst();

        Assert.AreNearlyEqual(InitialAmount - SettledAmount, PostedCarteraDoc."Remaining Amount", LibraryERM.GetAmountRoundingPrecision,
          UnexpectedPartSettledCartDocRemAmountErr);
        Assert.AreEqual(PostedCarteraDoc.Status::Open, PostedCarteraDoc.Status, InvalidStatusPartiallySettledCarteraDocErr);

        ClosedPaymentOrder.SetFilter("No.", PaymentOrder."No.");
        Assert.IsTrue(ClosedPaymentOrder.IsEmpty, 'Payment order should not be closed');
    end;

    local procedure VerifyCarteraDocIsClosedAsHonored(CarteraDoc: Record "Cartera Doc.")
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ClosedCarteraDoc.SetRange("Document No.", CarteraDoc."Document No.");
        ClosedCarteraDoc.FindFirst();
        Assert.AreEqual(ClosedCarteraDoc.Status::Honored, ClosedCarteraDoc.Status, UnexpectedCartDocStatusErr);
        Assert.AreEqual(0, ClosedCarteraDoc."Remaining Amt. (LCY)", UnexpectedCartDocRemAmountErr);

        VendorLedgerEntry.SetRange("Entry No.", ClosedCarteraDoc."Entry No.");
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, 'There should be vendor ledger entries present in the system');
    end;

    local procedure VerifyGLEntriesForPartialSettlementsWithDiscount(DocumentNo: Code[20]; DiscountAmount: Decimal; InitialAmount: Decimal; SettledAmount: Decimal; HasUnrealizedVAT: Boolean; ExpectedVATamount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        FirstSettlementVATAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);

        GLEntry.Find('-');
        Assert.AreNearlyEqual(InitialAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line');

        GLEntry.Next();
        Assert.AreNearlyEqual(InitialAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line');

        if HasUnrealizedVAT then begin
            FirstSettlementVATAmount := ExpectedVATamount * SettledAmount / InitialAmount;

            GLEntry.Next();
            Assert.AreNearlyEqual(
              FirstSettlementVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision,
              'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              FirstSettlementVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision,
              'Wrong amount for Unrealized VAT Amount');
        end;

        // Check Settlement Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line for Settlement Amount');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line for Settlement Amount');

        if HasUnrealizedVAT then begin
            FirstSettlementVATAmount := ExpectedVATamount * SettledAmount / InitialAmount;

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount - FirstSettlementVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision,
              'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount - FirstSettlementVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision,
              'Wrong amount for Unrealized VAT Amount');
        end;

        // Check invoice Discount Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line for Settlement Amount');

        // Check Remaining Amount with Discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          InitialAmount - SettledAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision,
          'Wrong amount on G/L Line for Remaining Amount');

        // Check remainging amount without discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          InitialAmount - SettledAmount - DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision,
          'Wrong amount on G/L line without discount');

        Assert.IsTrue(GLEntry.Next() = 0, 'There should not be any more G/L Entries');
    end;

    local procedure VerifyGLEntriesForTotalSettlementWithDiscount(DocumentNo: Code[20]; DiscountAmount: Decimal; TotalAmount: Decimal; HasUnrealizedVAT: Boolean; ExpectedVATamount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);

        GLEntry.Find('-');
        Assert.AreNearlyEqual(TotalAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line');

        GLEntry.Next();
        Assert.AreNearlyEqual(TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line');

        if HasUnrealizedVAT then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount for Unrealized VAT Amount');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATamount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount for Unrealized VAT Amount');
        end;

        // Check invoice Discount Amount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line for Settlement Amount');

        // Check Remaining Amount with Discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong amount on G/L Line for Remaining Amount');

        // Check remainging amount without discount
        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount - DiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision,
          'Wrong amount on G/L line without discount');

        Assert.IsTrue(GLEntry.Next() = 0, 'There should not be any more G/L Entries');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedPOModalPageHandler(var SettleDocsInPostedPOModalPageHandler: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsInPostedPOModalPageHandler.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrenciesPageHandler(var Currencies: TestPage Currencies)
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        Currencies.GotoKey(CurrencyCode);
        Currencies.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListPageHandler(var BankAccountList: TestPage "Bank Account List")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountList.GotoKey(BankAccountNo);
        BankAccountList.OK.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.ExpectedMessage(Format(ExpectedMessageText), Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.ExpectedMessage(Format(ExpectedMessageText), Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchSettlementRequestPageHandler(var BatchSettlPostedPO: TestRequestPage "Batch Settl. Posted POs")
    begin
        BatchSettlPostedPO.OK.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettlPayableRequestPageHandler(var PartialSettlPayable: TestRequestPage "Partial Settl. - Payable")
    var
        SettledAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(SettledAmount);

        // Set applied amount
        PartialSettlPayable.AppliedAmt.SetValue(SettledAmount);
        PartialSettlPayable.OK.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsinPostedPORequestPageHandler(var SettleDocsinPostedPO: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsinPostedPO.PostingDate.SetValue(WorkDate());

        SettleDocsinPostedPO.OK.Invoke();
    end;
}

