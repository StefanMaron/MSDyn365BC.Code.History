codeunit 138920 "O365 Sales Discounts"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Discount] [UI]
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        Assert: Codeunit Assert;
        O365SalesDiscounts: Codeunit "O365 Sales Discounts";
        LibraryInventory: Codeunit "Library - Inventory";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ZeroDiscountAmountForCustomerWithoutDiscount()
    var
        Customer: Record Customer;
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 203615] Invoice page shows zero discount if customer does not have discount set
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Invoice is being created, where Total amount =200, Tax = 50.
        CreateNewSalesInvoice(O365SalesInvoice, Customer, TotalAmount, TotalAmountIncludingVAT);

        // [THEN] Net Total = 200
        // [THEN] Total including VAT = 250
        // [THEN] Invoice Discount Amount = 0
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, 0);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATNo_DiscountAmount()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = No. Invoice discount calculated after entering invoice discount amount
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        // [GIVEN] Invoice, where Total amount = 200, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerNoVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount amount = 20
        // [WHEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        O365SalesInvoice.DiscountLink.DrillDown;

        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 20
        CalcExpectedAmountsFromInvoiceDiscountAmount(
          GetLastInvoiceNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmount * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountPctOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATNo_DiscountPct()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = No. Invoice discount calculated after entering invoice discount %
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        // [GIVEN] Invoice, where Total amount =200, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerNoVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount % = 10
        // [WHEN] Button OK is being pressed
        InvoiceDiscountPct := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountPct);
        O365SalesInvoice.DiscountLink.DrillDown;

        // [THEN] Page "Set Invoice Discount Amount" is shown
        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 20
        CalcExpectedAmountsFromInvoiceDiscountPct(
          GetLastInvoiceNo, InvoiceDiscountPct, TotalAmount,
          TotalAmountIncludingVAT, InvoiceDiscountAmount);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountPct);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountTotalOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATNo_TotalAmount()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        LineAmountExclVAT: Decimal;
        LineAmountInclVAT: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = No. Invoice discount calculated after entering new total amount
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        // [GIVEN] Invoice, where Total amount =200, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerNoVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);
        LineAmountExclVAT := O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal;
        LineAmountInclVAT := O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal;

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Total Excluding VAT = 180
        // [WHEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(TotalAmount - InvoiceDiscountAmount);
        O365SalesInvoice.DiscountLink.DrillDown;
        Assert.AreEqual(LineAmountExclVAT, O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal, 'Line Amount Excl. VAT is wrong');
        Assert.AreEqual(LineAmountInclVAT, O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal, 'Line Amount Incl. VAT is wrong');

        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 20
        CalcExpectedAmountsFromInvoiceDiscountAmount(
          GetLastInvoiceNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmount * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATYes_DiscountAmount()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        LineAmountExclVAT: Decimal;
        LineAmountInclVAT: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = Yes. Invoice discount calculated after entering invoice discount amount
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = Yes
        // [GIVEN] Invoice, where Total amount = 250, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerWithVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);
        LineAmountExclVAT := O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal;
        LineAmountInclVAT := O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal;

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount amount = 20
        // [WHEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        O365SalesInvoice.DiscountLink.DrillDown;
        Assert.AreEqual(LineAmountExclVAT, O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal, 'Line Amount Excl. VAT is wrong');
        Assert.AreEqual(LineAmountInclVAT, O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal, 'Line Amount Incl. VAT is wrong');

        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 25
        CalcExpectedAmountsFromInvoiceDiscountAmount(
          GetLastInvoiceNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmountIncludingVAT * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountPctOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATYes_DiscountPct()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = Yes. Invoice discount calculated after entering invoice discount %
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        // [GIVEN] Invoice, where Total amount =200, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerWithVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount % = 10
        // [WHEN] Button OK is being pressed
        InvoiceDiscountPct := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountPct);
        O365SalesInvoice.DiscountLink.DrillDown;

        // [THEN] Page "Set Invoice Discount Amount" is shown
        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 25
        CalcExpectedAmountsFromInvoiceDiscountPct(
          GetLastInvoiceNo, InvoiceDiscountPct, TotalAmount,
          TotalAmountIncludingVAT, InvoiceDiscountAmount);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountPct);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountTotalOK_MPH')]
    [Scope('OnPrem')]
    procedure PricesInclVATYes_TotalAmount()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO 203615] Prices Including VAT = Yes. Invoice discount calculated after entering new total amount
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        // [GIVEN] Invoice, where Total amount =200, Tax = 50.
        CreateNewSalesInvoiceForNewCustomerWithVAT(O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Total Including VAT = 225
        // [WHEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(TotalAmountIncludingVAT - InvoiceDiscountAmount);
        O365SalesInvoice.DiscountLink.DrillDown;

        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 25
        CalcExpectedAmountsFromInvoiceDiscountAmount(
          GetLastInvoiceNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmountIncludingVAT * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH,O365EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountInPostedInvoicePage()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        InvoiceDiscountAmount: Decimal;
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 203621] Posted invoice page displays invoice discount
        Initialize;
        ClearSMTPMailSetup;

        // [GIVEN] Create customer XXX
        CreateCustomer(Customer, false);

        // [GIVEN] Create item YYY
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create invoice for customer XXX with item YYY
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        SalesHeader.FindLast;

        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        CreateInvoiceSalesLine(SalesLine, Item.Description);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount Amount = ZZZ
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        O365SalesInvoice.DiscountLink.DrillDown;

        // [WHEN] Invoice is being sent
        PostedInvoiceNo := SendInvoice(GetLastInvoiceNo);

        // [THEN] Posted invoice discount amount = ZZZ
        VerifyPostedInvoiceDiscount(PostedInvoiceNo, InvoiceDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountCancel_MPH')]
    [Scope('OnPrem')]
    procedure CancelOnSalesInvoiceDiscountPage()
    var
        Customer: Record Customer;
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 203615] Discount is not aplied to invoice if user press Cancel on Sales Invoice Discount page
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        CreateCustomer(Customer, false);

        // [GIVEN] Invoice, where Total amount = 200, Tax = 50.
        CreateNewSalesInvoice(O365SalesInvoice, Customer, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount amount = 20
        // [WHEN] Button Cancel is being pressed
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(100, 200, 2));
        O365SalesInvoice.DiscountLink.DrillDown;

        // [THEN] Total excluding tax/VAT = 200
        // [THEN] Total including tax/VAT = 250
        // [THEN] Tax amount = 50
        // [THEN] Invoice Discount Amount = 0
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, 0);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LineDiscountInPostedInvoicePage()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        LineDiscountAmount: Decimal;
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 203621] Posted invoice page displays line discount
        Initialize;
        ClearSMTPMailSetup;

        // [GIVEN] Create customer XXX
        CreateCustomer(Customer, false);

        // [GIVEN] Create item YYY
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create invoice for customer XXX with item YYY
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        SalesHeader.FindLast;
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);
        O365SalesInvoiceLineCard.Description.Value(Item.Description);
        O365SalesInvoiceLineCard.LineQuantity.SetValue(LibraryRandom.RandIntInRange(1, 10));
        O365SalesInvoiceLineCard."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 99999, 2));
        // [GIVEN] Set Line Discount Amount = ZZZ
        LineDiscountAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        O365SalesInvoiceLineCard."Line Discount Amount".SetValue(LineDiscountAmount);
        O365SalesInvoiceLineCard.Close;
        // [WHEN] Invoice is being sent
        PostedInvoiceNo := SendInvoice(GetLastInvoiceNo);

        // [THEN] Posted invoice discount amount = ZZZ
        VerifyPostedLineDiscount(PostedInvoiceNo, LineDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountInQuotePage()
    var
        Customer: Record Customer;
        O365SalesQuote: TestPage "O365 Sales Quote";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        QuoteNo: Code[20];
    begin
        // [SCENARIO 206981] Prices Including VAT = No. Invoice discount calculated after entering invoice discount amount in the Quote page
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        CreateCustomer(Customer, false);

        // [GIVEN] Quote, where Total amount = 200, Tax = 50.
        QuoteNo := CreateNewSalesQuote(O365SalesQuote, Customer, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount amount = 20
        // [WHEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        O365SalesQuote.DiscountLink.DrillDown;

        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 20
        CalcExpectedAmountsFromQuoteDiscountAmount(
          QuoteNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);
        VerifyQuoteCardPageAmounts(
          O365SalesQuote, QuoteNo, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmount * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountFromQuoteToInvoice()
    var
        Customer: Record Customer;
        O365SalesQuote: TestPage "O365 Sales Quote";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        TotalAmount: Decimal;
        TotalAmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        QuoteNo: Code[20];
    begin
        // [SCENARIO 206981] Discount amount defined in the Quote page transferred to Invoice whet quote turned to invoice
        Initialize;

        // [GIVEN] Customer 'X', that has no invoice discount defined, Prices Including VAT = No
        CreateCustomer(Customer, false);

        // [GIVEN] Quote, where Total amount = 200, Tax = 50.
        QuoteNo := CreateNewSalesQuote(O365SalesQuote, Customer, TotalAmount, TotalAmountIncludingVAT);

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount amount = 20
        // [GIVEN] Button OK is being pressed
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        O365SalesQuote.DiscountLink.DrillDown;
        CalcExpectedAmountsFromQuoteDiscountAmount(
          QuoteNo, InvoiceDiscountAmount, TotalAmount, TotalAmountIncludingVAT);

        // [WHEN] Quote is being transferred to invoice
        O365SalesInvoice.Trap;
        O365SalesQuote.MakeToInvoice.Invoke;

        // [THEN] Created invoice page opened
        // [THEN] Total excluding tax/VAT = 180
        // [THEN] Total including tax/VAT = 225
        // [THEN] Tax amount = 45
        // [THEN] Invoice Discount Amount = 20
        VerifyInvoiceCardPageAmounts(
          O365SalesInvoice, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount / TotalAmount * 100);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SalesInvoiceDiscountAmountOK_MPH,O365EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SubtotalAmountInPostInvoicePage()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        SubtotalAmount: Decimal;
        PostedInvoiceNo: Code[20];
        LineAmountInclVAT: Decimal;
        LineAmountExclVAT: Decimal;
    begin
        // [SCENARIO 208536] Posted invoice page displays subtotal amount
        Initialize;
        ClearSMTPMailSetup;

        // [GIVEN] Create customer XXX
        CreateCustomer(Customer, false);

        // [GIVEN] Create item YYY
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create invoice for customer XXX with item YYY
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindLast;

        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        CreateInvoiceSalesLine(SalesLine, Item.Description);
        O365SalesInvoice.GotoRecord(SalesHeader);
        LineAmountExclVAT := O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal;
        LineAmountInclVAT := O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal;

        // [GIVEN] Run 'Add Discount' action
        // [GIVEN] Set Invoice discount Amount, Subtotal = ZZZ
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        O365SalesInvoice.DiscountLink.DrillDown;
        SubtotalAmount := O365SalesInvoice.SubTotalAmount.AsDEcimal;
        Assert.AreEqual(LineAmountExclVAT, O365SalesInvoice.Lines.LineAmountExclVAT.AsDEcimal, 'Line Amount Excl. VAT is wrong');
        Assert.AreEqual(LineAmountInclVAT, O365SalesInvoice.Lines.LineAmountInclVAT.AsDEcimal, 'Line Amount Incl. VAT is wrong');

        // [WHEN] Invoice is being sent
        PostedInvoiceNo := SendInvoice(GetLastInvoiceNo);

        // [THEN] Posted invoice subtotal amount = ZZZ
        VerifyPostedInvoiceSubtotal(PostedInvoiceNo, SubtotalAmount);
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        BindActiveDirectoryMockEvents;

        EventSubscriberInvoicingApp.Clear;

        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        DisableStockoutWarning;
        DisableSendMails;
        EnableCalcInvDiscount;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;
    end;

    local procedure CalcExpectedAmountsFromInvoiceDiscountAmount(InvoiceNo: Code[20]; InvoiceDiscountAmount: Decimal; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FindInvoiceFirstSalesLine(InvoiceNo, SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        CalcTotalAmounts(SalesHeader, SalesLine, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount);
    end;

    local procedure CalcExpectedAmountsFromInvoiceDiscountPct(InvoiceNo: Code[20]; InvoiceDiscountPct: Decimal; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal; var InvoiceDiscountAmount: Decimal)
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FindInvoiceFirstSalesLine(InvoiceNo, SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.CalcSums("Line Amount");
        Currency.InitRoundingPrecision;
        InvoiceDiscountAmount := Round(SalesLine."Line Amount" * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");

        CalcTotalAmounts(SalesHeader, SalesLine, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount);
    end;

    local procedure CalcExpectedAmountsFromQuoteDiscountAmount(InvoiceNo: Code[20]; InvoiceDiscountAmount: Decimal; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FindQuoteFirstSalesLine(InvoiceNo, SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        CalcTotalAmounts(SalesHeader, SalesLine, TotalAmount, TotalAmountIncludingVAT, InvoiceDiscountAmount);
    end;

    local procedure CalcTotalAmounts(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal; InvoiceDiscountAmount: Decimal)
    begin
        if SalesHeader."Prices Including VAT" then begin
            TotalAmountIncludingVAT := SalesLine.Quantity * SalesLine."Unit Price" - InvoiceDiscountAmount;
            TotalAmount :=
              (SalesLine.Quantity * SalesLine."Unit Price" - InvoiceDiscountAmount) / (1 + SalesLine."VAT %" / 100);
        end else begin
            TotalAmount := SalesLine.Quantity * SalesLine."Unit Price" - InvoiceDiscountAmount;
            TotalAmountIncludingVAT :=
              (SalesLine.Quantity * SalesLine."Unit Price" - InvoiceDiscountAmount) * (1 + SalesLine."VAT %" / 100);
        end;
    end;

    local procedure ClearSMTPMailSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        SMTPMailSetup.DeleteAll;
    end;

    local procedure CreateCustomer(var Customer: Record Customer; PricesIncludingVAT: Boolean)
    begin
        LibrarySales.CreateCustomer(Customer);
        if PricesIncludingVAT then begin
            Customer.Validate("Prices Including VAT", true);
            Customer.Modify;
        end;
    end;

    local procedure CreateNewSalesInvoiceForNewCustomerNoVAT(var O365SalesInvoice: TestPage "O365 Sales Invoice"; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal)
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, false);
        CreateNewSalesInvoice(O365SalesInvoice, Customer, TotalAmount, TotalAmountIncludingVAT);
    end;

    local procedure CreateNewSalesInvoiceForNewCustomerWithVAT(var O365SalesInvoice: TestPage "O365 Sales Invoice"; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal)
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, true);
        CreateNewSalesInvoice(O365SalesInvoice, Customer, TotalAmount, TotalAmountIncludingVAT);
    end;

    local procedure CreateNewSalesInvoice(var O365SalesInvoice: TestPage "O365 Sales Invoice"; Customer: Record Customer; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        O365SalesInvoice.OpenNew;

        O365SalesInvoice."Sell-to Customer Name".Value(Customer.Name);
        SalesHeader.FindLast;

        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        CreateInvoiceSalesLine(SalesLine, Item.Description);

        O365SalesInvoice.GotoRecord(SalesHeader);
        TotalAmount := O365SalesInvoice.Amount.AsDEcimal;
        TotalAmountIncludingVAT := O365SalesInvoice."Amount Including VAT".AsDEcimal;
    end;

    local procedure CreateNewSalesQuote(var O365SalesQuote: TestPage "O365 Sales Quote"; Customer: Record Customer; var TotalAmount: Decimal; var TotalAmountIncludingVAT: Decimal): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        O365SalesQuote.OpenNew;
        O365SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.FindLast;

        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        CreateInvoiceSalesLine(SalesLine, Item.Description);
        TotalAmount := O365SalesQuote.Amount.AsDEcimal;
        TotalAmountIncludingVAT := O365SalesQuote."Amount Including VAT".AsDEcimal;

        exit(SalesHeader."No.");
    end;

    local procedure CreateInvoiceSalesLine(SalesLine: Record "Sales Line"; Description: Text)
    var
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);
        O365SalesInvoiceLineCard.Description.Value(Description);
        O365SalesInvoiceLineCard.LineQuantity.SetValue(LibraryRandom.RandIntInRange(1, 10));
        O365SalesInvoiceLineCard."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 99999, 2));
        O365SalesInvoiceLineCard.Close;
    end;

    local procedure DisableStockoutWarning()
    begin
        with SalesSetup do begin
            Get;
            Validate("Stockout Warning", false);
            Modify;
        end;
    end;

    local procedure DisableSendMails()
    begin
        BindSubscription(O365SalesDiscounts);
    end;

    local procedure EnableCalcInvDiscount()
    begin
        with SalesSetup do begin
            Get;
            Validate("Calc. Inv. Discount", true);
            Modify;
        end;
    end;

    local procedure FindInvoiceFirstSalesLine(InvoiceNo: Code[20]; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", InvoiceNo);
        SalesLine.FindFirst;
    end;

    local procedure FindQuoteFirstSalesLine(QuoteNo: Code[20]; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", QuoteNo);
        SalesLine.FindFirst;
    end;

    local procedure MockInvoicePageRefreshOnActivate(var O365SalesInvoice: TestPage "O365 Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindLast;
        O365SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure MockQuotePageRefreshOnActivate(var O365SalesQuote: TestPage "O365 Sales Quote"; QuoteNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Quote, QuoteNo);
        O365SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure SendInvoice(InvoiceNo: Code[20]) PostedInvoiceNo: Code[20]
    begin
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);
    end;

    local procedure GetLastInvoiceNo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindLast;
        exit(SalesHeader."No.");
    end;

    local procedure VerifyInvoiceCardPageAmounts(var O365SalesInvoice: TestPage "O365 Sales Invoice"; TotalAmount: Decimal; TotalAmountIncludingVAT: Decimal; InvDiscountPercent: Decimal)
    begin
        MockInvoicePageRefreshOnActivate(O365SalesInvoice);
        O365SalesInvoice.Amount2.AssertEquals(TotalAmount);
        O365SalesInvoice.AmountIncludingVAT2.AssertEquals(TotalAmountIncludingVAT);
        O365SalesInvoice."Invoice Discount Percent".AssertEquals(Round(InvDiscountPercent, 0.01));
    end;

    local procedure VerifyQuoteCardPageAmounts(var O365SalesQuote: TestPage "O365 Sales Quote"; QuoteNo: Code[20]; TotalAmount: Decimal; TotalAmountIncludingVAT: Decimal; InvDiscountPercent: Decimal)
    begin
        MockQuotePageRefreshOnActivate(O365SalesQuote, QuoteNo);
        O365SalesQuote.Amount2.AssertEquals(TotalAmount);
        O365SalesQuote.AmountIncludingVAT2.AssertEquals(TotalAmountIncludingVAT);
        O365SalesQuote."Invoice Discount Percent".AssertEquals(Round(InvDiscountPercent, 0.01));
    end;

    local procedure VerifyPostedInvoiceDiscount(PostedInvoiceNo: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        O365PostedSalesInvoice.InvoiceDiscountAmount.AssertEquals(InvoiceDiscountAmount);
    end;

    local procedure VerifyPostedLineDiscount(PostedInvoiceNo: Code[20]; LineDiscountAmount: Decimal)
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        O365PostedSalesInvoice.Lines."Line Discount Amount".AssertEquals(LineDiscountAmount);
    end;

    local procedure VerifyPostedInvoiceSubtotal(PostedInvoiceNo: Code[20]; SubtotalAmount: Decimal)
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        O365PostedSalesInvoice.SubTotalAmount.AssertEquals(SubtotalAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiscountAmountOK_MPH(var O365SalesInvoiceDiscount: TestPage "O365 Sales Invoice Discount")
    begin
        O365SalesInvoiceDiscount."Invoice Discount Amount".SetValue(LibraryVariableStorage.DequeueDecimal);
        O365SalesInvoiceDiscount.OK.Invoke
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiscountPctOK_MPH(var O365SalesInvoiceDiscount: TestPage "O365 Sales Invoice Discount")
    begin
        O365SalesInvoiceDiscount."Invoice Disc. Pct.".SetValue(LibraryVariableStorage.DequeueDecimal);
        O365SalesInvoiceDiscount.OK.Invoke
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiscountTotalOK_MPH(var O365SalesInvoiceDiscount: TestPage "O365 Sales Invoice Discount")
    begin
        O365SalesInvoiceDiscount.TotalAmount.SetValue(LibraryVariableStorage.DequeueDecimal);
        O365SalesInvoiceDiscount.OK.Invoke
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiscountAmountCancel_MPH(var O365SalesInvoiceDiscount: TestPage "O365 Sales Invoice Discount")
    begin
        O365SalesInvoiceDiscount."Invoice Discount Amount".SetValue(LibraryVariableStorage.DequeueDecimal);
        O365SalesInvoiceDiscount.Cancel.Invoke
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.SendToText.Value('test@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BCEmailSetupPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    var
        EmailProvider: Option "Office 365",Other;
    begin
        with BCO365EmailSetupWizard.EmailSettingsWizardPage do begin
            "Email Provider".SetValue(EmailProvider::"Office 365");
            FromAccount.SetValue('test@microsoft.com');
            Password.SetValue('pass');
        end;

        BCO365EmailSetupWizard.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 9520, 'OnBeforeDoSending', '', false, false)]
    local procedure DoNotSendMails(var CancelSending: Boolean)
    begin
        CancelSending := true;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

