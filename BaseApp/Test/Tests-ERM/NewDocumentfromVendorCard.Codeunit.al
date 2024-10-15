codeunit 134770 "New Document from Vendor Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

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
}

