codeunit 134770 "New Document from Vendor Card"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Vendor] [UI]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        VendorNoForEventSubscriber: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure NewBlanketPurchaseOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        BlanketPurchaseOrder.Trap();
        VendorCard.NewBlanketPurchaseOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, BlanketPurchaseOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(
          Vendor.Address, BlanketPurchaseOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", BlanketPurchaseOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(
          Vendor.Contact, BlanketPurchaseOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseQuote.Trap();
        VendorCard.NewPurchaseQuote.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseQuote."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseQuote."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseQuote."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseQuote."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendor()
    var
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);

        PurchaseInvoice."Vendor Invoice No.".SetValue(
          LibraryUtility.GenerateRandomText(MaxStrLen(DummyPurchaseHeader."Vendor Invoice No.")));
        PurchaseInvoice.Close();

        // Execute
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);
    end;

    local procedure VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    begin
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice."Buy-from Address".AssertEquals(Vendor.Address);
        PurchaseInvoice."Buy-from Post Code".AssertEquals(Vendor."Post Code");
        PurchaseInvoice."Buy-from Contact".AssertEquals(Vendor.Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseOrder.Trap();
        VendorCard.NewPurchaseOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseCreditMemoFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseCreditMemo.Trap();
        VendorCard.NewPurchaseCrMemo.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseCreditMemo."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseCreditMemo."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseCreditMemo."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseCreditMemo."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseReturnOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseReturnOrder.Trap();
        VendorCard.NewPurchaseReturnOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseReturnOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(
          Vendor.Address, PurchaseReturnOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseReturnOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(
          Vendor.Contact, PurchaseReturnOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrdersFromVendorCard_CreateNewOrderFromPurchaseOrderList_AutomaticOrderNos()
    var
        Vendor: Record Vendor;
        NewDocumentFromVendorCard: Codeunit "New Document from Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 504336] Simulate the scenario where new purchase order is created from the vendor card via Purchase Order list and New action.
        // [SCENARIO 504336] No. of Purchase Order is automatically assigned, so it is not visible in the page.
        Initialize();

        BindSubscription(NewDocumentFromVendorCard); // Uses OnOpenPurchaseOrder event subscriber to simulate page filters.

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        NewDocumentFromVendorCard.SetVendorNoForEventSubscriber(Vendor); // Set Vendor No. for event subscriber to simulate page filters.

        // [GIVEN] Create New Purchase Order, with "Buy-from Vendor No." filter in filtergroup = 2 to simulate page filters.
        PurchaseOrder.OpenNew();

        // [WHEN] Set any field on the page to insert record.
        PurchaseOrder."Buy-from Address".SetValue(Vendor.Address);

        // [THEN] Vendor No. and Vendor Name are carried over to the document
        Assert.AreEqual(Vendor."No.", PurchaseOrder."Buy-from Vendor No.".Value(), 'Vendor No. is not carried over to the document');
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value(), 'Vendor Name is not carried over to the document');

        UnbindSubscription(NewDocumentFromVendorCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrdersFromVendorCard_CreateNewOrderFromPurchaseOrderList_ManualOrderNos()
    var
        Vendor: Record Vendor;
        NewDocumentFromVendorCard: Codeunit "New Document from Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 504336] Simulate the scenario where new purchase order is created from the vendor card via Purchase Order list and New action.
        // [SCENARIO 504336] No. of Purchase Order can be manually set, so it is visible in the page.
        Initialize();

        // [GIVEN] Set Manual Nos. on Purchase Order No. Series
        UpdateManualNosOnPurchaseOrderNoSeries(true);

        BindSubscription(NewDocumentFromVendorCard); // Uses OnOpenPurchaseOrder event subscriber to simulate page filters.

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        NewDocumentFromVendorCard.SetVendorNoForEventSubscriber(Vendor); // Set Vendor No. for event subscriber to simulate page filters.

        // [GIVEN] Create New Purchase Order, with "Buy-from Vendor No." filter in filtergroup = 2 to simulate page filters.
        PurchaseOrder.OpenNew();

        // [WHEN] Set any field on the page to insert record.
        PurchaseOrder."Buy-from Address".SetValue(Vendor.Address);

        // [THEN] Vendor No. and Vendor Name are carried over to the document
        Assert.AreEqual(Vendor."No.", PurchaseOrder."Buy-from Vendor No.".Value(), 'Vendor No. is not carried over to the document');
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value(), 'Vendor Name is not carried over to the document');

        UnbindSubscription(NewDocumentFromVendorCard);
        UpdateManualNosOnPurchaseOrderNoSeries(false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Document from Vendor Card");

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Document from Vendor Card");

        Commit();
        isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Document from Vendor Card");
    end;

    local procedure UpdateManualNosOnPurchaseOrderNoSeries(ManualNos: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries.Get(PurchasesPayablesSetup."Order Nos.");
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    internal procedure SetVendorNoForEventSubscriber(Vendor: Record Vendor)
    begin
        VendorNoForEventSubscriber := Vendor."No.";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseOrder(var Rec: Record "Purchase Header")
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Document Type", Rec."Document Type"::Order);
        Rec.SetRange("Buy-from Vendor No.", VendorNoForEventSubscriber);
        Rec.FilterGroup(0);
    end;
}

