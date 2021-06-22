codeunit 134344 "Document Totals Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Document Totals]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        InvoiceDiscountAmountErr: Label 'Invoice discount amount';
        InvoiceDiscountPercentErr: Label 'Invoice discount percent';
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure SalesQuoteUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Quote] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Quote card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote);

        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        SalesQuote.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesQuote.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := SalesQuote.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesQuote."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Invoice card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Invoice);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        SalesInvoice.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesInvoice.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesInvoice."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesInvoice.Release.Invoke;
        SalesInvoice."Posting Date".SetValue(SalesInvoice."Posting Date".AsDate + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Order);

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        SalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesOrder.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := SalesOrder.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesOrder."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesOrder.Release.Invoke;
        SalesOrder."Posting Date".SetValue(SalesOrder."Posting Date".AsDate + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [FCY]
        // [SCENARIO 280259] Invoice discount amount remains unchanged after Currency Factor updated on Sales Credit Memo card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        SalesCreditMemo.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesCreditMemo."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesCreditMemo.Release.Invoke;
        SalesCreditMemo."Posting Date".SetValue(SalesCreditMemo."Posting Date".AsDate + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Return Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Return Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Return Order");

        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);

        SalesReturnOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesReturnOrder."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesReturnOrder.Release.Invoke;
        SalesReturnOrder."Posting Date".SetValue(SalesReturnOrder."Posting Date".AsDate + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Blanket Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Return Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        BlanketSalesOrder."Currency Code".AssistEdit;

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Quote] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Quote card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Quote);

        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseQuote.PurchLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseQuote."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Invoice card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        PurchaseInvoice.PurchLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDEcimal;
        InvoiceDiscountPercent := PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseInvoice."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseInvoice."Re&lease".Invoke; // Release
        PurchaseInvoice."Posting Date".SetValue(PurchaseInvoice."Posting Date".AsDate + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseOrder.PurchLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseOrder."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseOrder.Release.Invoke;
        PurchaseOrder."Posting Date".SetValue(PurchaseOrder."Posting Date".AsDate + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [FCY]
        // [SCENARIO 280259] Invoice discount amount remains unchanged after Currency Factor updated on Purchase Credit Memo card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseCreditMemo."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseCreditMemo.Release.Invoke;
        PurchaseCreditMemo."Posting Date".SetValue(PurchaseCreditMemo."Posting Date".AsDate + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Return Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseReturnOrder."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseReturnOrder."Re&lease".Invoke; // Release
        PurchaseReturnOrder."Posting Date".SetValue(PurchaseReturnOrder."Posting Date".AsDate + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Blanket Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Return Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDEcimal;
        InvoiceDiscountPercent := BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDEcimal;
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        BlanketPurchaseOrder."Currency Code".AssistEdit;

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SQ_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Quote]
        // [SCENARIO 296939] Stan can change posistion on sales quote lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        Commit(); // It is important to COMMIT changes

        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesQuote.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Order]
        // [SCENARIO 296939] Stan can change posistion on sales order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        Commit(); // It is important to COMMIT changes

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesOrder.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SI_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Invoice]
        // [SCENARIO 296939] Stan can change posistion on sales invoice lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        Commit(); // It is important to COMMIT changes

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesInvoice.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCrM_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Credit Memo]
        // [SCENARIO 296939] Stan can change posistion on sales credit memo lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");
        Commit(); // It is important to COMMIT changes

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesCreditMemo.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SRO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Return Order]
        // [SCENARIO 296939] Stan can change posistion on sales return order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
        Commit(); // It is important to COMMIT changes

        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesReturnOrder.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SBO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Blanket Order]
        // [SCENARIO 296939] Stan can change posistion on blanket sales order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order");
        Commit(); // It is important to COMMIT changes

        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(BlanketSalesOrder.SalesLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PQ_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Quote]
        // [SCENARIO 296939] Stan can change posistion on purchase quote lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);

        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseQuote.PurchLines."No.".SetValue(Item."No.");
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseQuote.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Order]
        // [SCENARIO 296939] Stan can change posistion on purchase order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseOrder.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PI_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Invoice]
        // [SCENARIO 296939] Stan can change posistion on purchase invoice lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseInvoice.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCrM_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Credit Memo]
        // [SCENARIO 296939] Stan can change posistion on purchase credit memo lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PRO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Return Order]
        // [SCENARIO 296939] Stan can change posistion on purchase return order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseReturnOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseReturnOrder.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PBO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Blanket Order]
        // [SCENARIO 296939] Stan can change posistion on blanket purchase order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order");

        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        BlanketPurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(BlanketPurchaseOrder.PurchLines.Next, 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdatesInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 378462] "Invoice Discount Amount" on Sales Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Sales Order with two Sales Lines with Unit Price = 5 and 10000.
        CreateSalesHeaderWithTwoLines(
            SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Sales Order is opened on Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Sales Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        SalesOrder.Statistics.Invoke();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Sales Order page.
        SalesHeader.Find();
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(SalesHeader."Invoice Discount Value");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsUpdatesInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 378462] "Invoice Discount Amount" on Purchase Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Purchase Order with two Purchase Lines with Direct Unit Cost = 5 and 10000.
        CreatePurchaseHeaderWithTwoLines(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Purchase Order is opened on Purchase Order page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Purchase Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        PurchaseOrder.Statistics.Invoke();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Purchase Order page.
        PurchaseHeader.Find();
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(PurchaseHeader."Invoice Discount Value");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Document Totals Pages");

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Totals Pages");

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Totals Pages");
    end;

    local procedure AddInvoiceDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", Percentage);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        AddInvoiceDiscToCustomer(
          Customer, LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
    end;

    local procedure AddInvoiceDiscToVendor(Vendor: Record Vendor; MinimumAmount: Decimal; Percentage: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", MinimumAmount);
        VendorInvoiceDisc.Validate("Discount %", Percentage);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        AddInvoiceDiscToVendor(
          Vendor, LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateGUID);
        ExtendedTextLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);

        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate(
          "Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        SalesHeader.SetHideValidationDialog(false);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithTwoLines(var SalesHeader: Record "Sales Header"; Type: Option; Qty1: Decimal; UnitPrice1: Decimal; Qty2: Decimal; UnitPrice2: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, Type, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', Qty1);
        SalesLine.Validate("Unit Price", UnitPrice1);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', Qty2);
        SalesLine.Validate("Unit Price", UnitPrice2);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);

        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate(
          "Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        PurchaseHeader.SetHideValidationDialog(false);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);

        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure CreatePurchaseHeaderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; Type: Option; Qty1: Decimal; UnitPrice1: Decimal; Qty2: Decimal; UnitPrice2: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Type, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', Qty1);
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice1);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', Qty2);
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice2);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithCustInvDiscItemExtText(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateCustomerWithDiscount(Customer);
        CreateItemWithExtendedText(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
    end;

    local procedure CreatePurchaseDocumentWithCustInvDiscItemExtText(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateVendorWithDiscount(Vendor);
        CreateItemWithExtendedText(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeExchangeRateMPH(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    begin
        ChangeExchangeRate.CurrentExchRate.SetValue(LibraryVariableStorage.DequeueDecimal());
        ChangeExchangeRate.OK.Invoke();
    end;

    local procedure VerifySalesHeaderInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    begin
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", InvoiceDiscountAmount);
    end;

    local procedure VerifyPurchaseHeaderInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    begin
        PurchaseHeader.CalcFields("Invoice Discount Amount");
        PurchaseHeader.TestField("Invoice Discount Amount", InvoiceDiscountAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(MessageText: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStatistics.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseOrderStatistics.OK.Invoke();
    end;
}

