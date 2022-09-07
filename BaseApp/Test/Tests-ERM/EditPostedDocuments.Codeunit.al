codeunit 134658 "Edit Posted Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Sales Cr.Memo Header" = imd;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Update Document]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        UnexpectedQtyErr: Label 'Unexpected Quantity shown.';
        UnexpectedNetWeightErr: Label 'Unexpected Net Weight shown.';
        UnexpectedGrossWeightErr: Label 'Unexpected Gross Weight shown.';
        UnexpectedVolumeErr: Label 'Unexpected Volume shown.';

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentEditableFields()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Sales Shipment - Update".
        Initialize();

        // [WHEN] Open "Posted Sales Shipment - Update" page.
        PostedSalesShipment.OpenView;
        PostedSalesShipment."Update Document".Invoke;

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Shipping Agent Code", "Shipping Agent Service Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateSetValuesCancel()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Shipment - Update" modal page.
        Initialize();
        CreateAndPostSalesOrder();
        PrepareValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);

        // [GIVEN] Opened "Posted Sales Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);
        PostedSalesShipment.OpenView;
        PostedSalesShipment."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Invoice Header were not changed.
        Assert.AreNotEqual(SalesShptHeader."Shipping Agent Code", PostedSalesShipment."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Shipping Agent Service Code", PostedSalesShipment."Shipping Agent Service Code".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Package Tracking No.", PostedSalesShipment."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateSetValuesOK()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Sales Shipment - Update" modal page.
        Initialize();
        CreateAndPostSalesOrder();
        PrepareValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);

        // [GIVEN] Opened "Posted Sales Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);
        PostedSalesShipment.OpenView;
        PostedSalesShipment."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Invoice Header were changed.
        Assert.AreEqual(SalesShptHeader."Shipping Agent Code", PostedSalesShipment."Shipping Agent Code".Value, '');
        Assert.AreEqual(SalesShptHeader."Shipping Agent Service Code", PostedSalesShipment."Shipping Agent Service Code".Value, '');
        Assert.AreEqual(SalesShptHeader."Package Tracking No.", PostedSalesShipment."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdatePackageTrackingNo_MPH')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdatePackageTrackingNo()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 358316] "Package Tracking No." updated when only its value is changed
        Initialize();
        CreateAndPostSalesOrder();
        PrepareValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);

        // [GIVEN] Opened "Posted Sales Shipment - Update" page.
        // [GIVEN] Set "Package Tracking No." = "XXX"
        LibraryVariableStorage.Enqueue(SalesShptHeader."Package Tracking No.");
        PostedSalesShipment.OpenView();
        PostedSalesShipment."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of "Package Tracking No." in Sales Invoice Header was changed to "XXX" 
        Assert.AreEqual(SalesShptHeader."Package Tracking No.", PostedSalesShipment."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateEditableFields()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Purch. Invoice - Update".
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Posted Purch. Invoice - Update" page via PostedReturnShptUpdateGetEditablelModalPageHandler
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice."Update Document".Invoke;

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code", "Creditor No.", "Ship-to Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesCancel()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderNew: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchInvHeader.Get(CreateAndPostPurchaseInvoiceWithSellToCustomer(LibrarySales.CreateCustomerNo));
        PurchInvHeaderNew := PurchInvHeader;
        PrepareValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeaderNew);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader);
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoice."Update Document".Invoke;

        // [WHEN] Press Cancel on the page via PostedPurchInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Purch. Inv. Header were not changed to new values.
        Assert.AreEqual(PurchInvHeader."Payment Reference", PostedPurchaseInvoice."Payment Reference".Value, '');
        Assert.AreEqual(PurchInvHeader."Creditor No.", PostedPurchaseInvoice."Creditor No.".Value, '');
        Assert.AreEqual(PurchInvHeader."Ship-to Code", PostedPurchaseInvoice."Ship-to Code".Value, '');

        PostedPurchaseInvoice.Close;
        PurchInvHeader.Get(PurchInvHeader."No.");
        Assert.AreNotEqual(PurchInvHeaderNew."Payment Reference", PurchInvHeader."Payment Reference", '');
        Assert.AreNotEqual(PurchInvHeaderNew."Payment Method Code", PurchInvHeader."Payment Method Code", '');
        Assert.AreNotEqual(PurchInvHeaderNew."Creditor No.", PurchInvHeader."Creditor No.", '');
        Assert.AreNotEqual(PurchInvHeaderNew."Ship-to Code", PurchInvHeader."Ship-to Code", '');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesOK()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderNew: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchInvHeader.Get(CreateAndPostPurchaseInvoiceWithSellToCustomer(LibrarySales.CreateCustomerNo));
        PurchInvHeaderNew := PurchInvHeader;
        PrepareValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeaderNew);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeaderNew);
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoice."Update Document".Invoke;

        // [WHEN] Press OK on the page via PostedPurchInvoiceUpdateOKModalPageHandler

        // [THEN] Values of these fields in Purch. Inv. Header were changed to new values.
        Assert.AreEqual(PurchInvHeaderNew."Payment Reference", PostedPurchaseInvoice."Payment Reference".Value, '');
        Assert.AreEqual(PurchInvHeaderNew."Creditor No.", PostedPurchaseInvoice."Creditor No.".Value, '');
        Assert.AreEqual(PurchInvHeaderNew."Ship-to Code", PostedPurchaseInvoice."Ship-to Code".Value, '');

        PostedPurchaseInvoice.Close;
        PurchInvHeader.Get(PurchInvHeader."No.");
        PurchInvHeader.TestField("Payment Reference", PurchInvHeaderNew."Payment Reference");
        PurchInvHeader.TestField("Payment Method Code", PurchInvHeaderNew."Payment Method Code");
        PurchInvHeader.TestField("Creditor No.", PurchInvHeaderNew."Creditor No.");
        PurchInvHeader.TestField("Ship-to Code", PurchInvHeaderNew."Ship-to Code");

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateEditableFields()
    var
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Return Shpt. - Update".
        Initialize();

        // [WHEN] Open "Posted Return Shpt. - Update" page.
        PostedReturnShipment.OpenView;
        PostedReturnShipment."Update Document".Invoke;

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Fields "Ship-to County", "Ship-to Country/Region Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateSetValuesCancel()
    var
        ReturnShptHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Return Shpt. - Update" modal page.
        Initialize();
        CreateAndPostPurchaseReturnOrder();
        PrepareValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);

        // [GIVEN] Opened "Posted Return Shpt. - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);
        PostedReturnShipment.OpenView;
        PostedReturnShipment."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Return Shipment Header were not changed.
        Assert.AreNotEqual(ReturnShptHeader."Ship-to County", PostedReturnShipment."Ship-to County".Value, '');
        Assert.AreNotEqual(
          ReturnShptHeader."Ship-to Country/Region Code", PostedReturnShipment."Ship-to Country/Region Code".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateSetValuesOK()
    var
        ReturnShptHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Return Shpt. - Update" modal page.
        Initialize();
        CreateAndPostPurchaseReturnOrder();
        PrepareValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);

        // [GIVEN] Opened "Posted Return Shpt. - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);
        PostedReturnShipment.OpenView;
        PostedReturnShipment."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Return Shipment Header were changed.
        Assert.AreEqual(ReturnShptHeader."Ship-to County", PostedReturnShipment."Ship-to County".Value, '');
        Assert.AreEqual(ReturnShptHeader."Ship-to Country/Region Code", PostedReturnShipment."Ship-to Country/Region Code".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateEditableFields()
    var
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Return Receipt - Update".
        Initialize();

        // [WHEN] Open "Posted Return Receipt - Update" page.
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt."Update Document".Invoke;

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Bill-to County", "Bill-to Country/Region Code", "Shipping Agent Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateSetValuesCancel()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Return Receipt - Update" modal page.
        Initialize();
        CreateAndPostSalesReturnOrder();
        PrepareValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);

        // [GIVEN] Opened "Posted Return Receipt - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Return Receipt Header were not changed.
        Assert.AreNotEqual(ReturnRcptHeader."Bill-to County", PostedReturnReceipt."Bill-to County".Value, '');
        Assert.AreNotEqual(
          ReturnRcptHeader."Bill-to Country/Region Code", PostedReturnReceipt."Bill-to Country/Region Code".Value, '');
        Assert.AreNotEqual(ReturnRcptHeader."Shipping Agent Code", PostedReturnReceipt."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(ReturnRcptHeader."Package Tracking No.", PostedReturnReceipt."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateSetValuesOK()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Return Receipt - Update" modal page.
        Initialize();
        CreateAndPostSalesReturnOrder();
        PrepareValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);

        // [GIVEN] Opened "Posted Return Receipt - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Return Receipt Header were changed.
        Assert.AreEqual(ReturnRcptHeader."Bill-to County", PostedReturnReceipt."Bill-to County".Value, '');
        Assert.AreEqual(ReturnRcptHeader."Bill-to Country/Region Code", PostedReturnReceipt."Bill-to Country/Region Code".Value, '');
        Assert.AreEqual(ReturnRcptHeader."Shipping Agent Code", PostedReturnReceipt."Shipping Agent Code".Value, '');
        Assert.AreEqual(ReturnRcptHeader."Package Tracking No.", PostedReturnReceipt."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateEditableFields()
    var
        PostedPurchaseInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] Editable and non-editable fields on page "Posted Sales Invoice - Update".
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Posted Sales Invoice - Update" page
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice."Update Document".Invoke;

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesCancel()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderNew: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice);
        SalesInvoiceHeaderNew := SalesInvoiceHeader;
        PrepareEnqueueValuesForPostedSalesInvoice(SalesInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        PostedSalesInvoice."Update Document".Invoke;

        // [WHEN] Press Cancel on the page via PostedSalesInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Sales Invoice Header were not changed to new values.
        PostedSalesInvoice.Close;
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        Assert.AreNotEqual(SalesInvoiceHeaderNew."Payment Reference", SalesInvoiceHeader."Payment Reference", '');
        Assert.AreNotEqual(SalesInvoiceHeaderNew."Payment Method Code", SalesInvoiceHeader."Payment Method Code", '');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesOK()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderNew: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] New values for editable fields are set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice);
        SalesInvoiceHeaderNew := SalesInvoiceHeader;
        PrepareEnqueueValuesForPostedSalesInvoice(SalesInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        PostedSalesInvoice."Update Document".Invoke;

        // [WHEN] Press OK on the page via PostedSalesInvoiceUpdateOkModalPageHandler

        // [THEN] Values of these fields in Sales Invoice Header were changed to new values.
        PostedSalesInvoice.Close;
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        SalesInvoiceHeader.TestField("Payment Reference", SalesInvoiceHeaderNew."Payment Reference");
        SalesInvoiceHeader.TestField("Payment Method Code", SalesInvoiceHeaderNew."Payment Method Code");

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateEditableFields()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] Editable and non-editable fields on page "Posted Service Inv. - Update".
        Initialize();

        // [WHEN] Open "Posted Service Inv. - Update" page
        PostedServiceInvoice.OpenView;
        PostedServiceInvoice."Update Document".Invoke;

        // [THEN] Fields "No.", "Bill-to Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesCancel()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceHeaderNew: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();

        MockServiceInvoice(ServiceInvoiceHeader);
        ServiceInvoiceHeaderNew := ServiceInvoiceHeader;
        PrepareEnqueueValuesForPostedServiceInvoice(ServiceInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedServiceInvoice.OpenView;
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        PostedServiceInvoice."Update Document".Invoke;

        // [WHEN] Press Cancel on the page via PostedServiceInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Service Invoice Header were not changed to new values.
        PostedServiceInvoice.Close;
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        Assert.AreNotEqual(ServiceInvoiceHeaderNew."Payment Reference", ServiceInvoiceHeader."Payment Reference", '');
        Assert.AreNotEqual(ServiceInvoiceHeaderNew."Payment Method Code", ServiceInvoiceHeader."Payment Method Code", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesOK()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceHeaderNew: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] New values for editable fields are set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();

        MockServiceInvoice(ServiceInvoiceHeader);
        ServiceInvoiceHeaderNew := ServiceInvoiceHeader;
        PrepareEnqueueValuesForPostedServiceInvoice(ServiceInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Service - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedServiceInvoice.OpenView;
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        PostedServiceInvoice."Update Document".Invoke;

        // [WHEN] Press OK on the page via PostedServiceInvoiceUpdateOkModalPageHandler

        // [THEN] Values of these fields in Service Invoice Header were changed to new values.
        PostedServiceInvoice.Close;
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceHeader.TestField("Payment Reference", ServiceInvoiceHeaderNew."Payment Reference");
        ServiceInvoiceHeader.TestField("Payment Method Code", ServiceInvoiceHeaderNew."Payment Method Code");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoEditableFields()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] Editable and non-editable fields on page "Posted Sales Credit Memo - Update".
        Initialize();

        // [WHEN] Open "Posted Sales Credit Memo - Update" page.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo."Update Document".Invoke();

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Shipping Agent Code", "Shipping Agent Service Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Sell-to Customer Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Shipping Agent Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Shipping Agent Service Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Package Tracking No. must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoUpdateSetValuesCancel()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SavedSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader);
        SavedSalesCrMemoHeader := SalesCrMemoHeader;

        // [GIVEN] Opened "Posted Sales Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader);
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Credit Memo Header were not changed.
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.TestField("Shipping Agent Code", SavedSalesCrMemoHeader."Shipping Agent Code");
        SalesCrMemoHeader.TestField("Shipping Agent Service Code", SavedSalesCrMemoHeader."Shipping Agent Service Code");
        SalesCrMemoHeader.TestField("Package Tracking No.", SavedSalesCrMemoHeader."Package Tracking No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoUpdateSetValuesOK()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCrediMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] New values for editable fields are set in case Stan presses OK on "Posted Sales Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Posted Sales Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader);
        PostedSalesCrediMemo.OpenView();
        PostedSalesCrediMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Credit Memo Header were changed.
        SalesCrMemoHeader.TestField("Shipping Agent Code", PostedSalesCrediMemo."Shipping Agent Code".Value);
        SalesCrMemoHeader.TestField("Shipping Agent Service Code", PostedSalesCrediMemo."Shipping Agent Service Code".Value);
        SalesCrMemoHeader.TestField("Package Tracking No.", PostedSalesCrediMemo."Package Tracking No.".Value);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPostedReturnReceiptStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        ReturnReceiptStatistics: TestPage "Return Receipt Statistics";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 433838] The Return Receipt Statistics are reported in the Posted Return Receipt document.
        Initialize();

        // [GIVEN] Create and post sales return order.
        LibrarySales.CreateSalesDocumentWithItem(
                    SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
                    LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Click on statistics from opened "Posted Return Receipt" page.
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt.Filter.SetFilter("No.", DocumentNo);
        ReturnReceiptStatistics.Trap;
        PostedReturnReceipt.Statistics.Invoke();

        // [THEN] Verify data available on "Return Receipt Statistics" page
        Assert.AreEqual(ReturnReceiptStatistics.LineQty.AsDecimal(), SalesLine.Quantity, UnexpectedQtyErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalNetWeight.AsDecimal(), SalesLine.Quantity * SalesLine."Net Weight", UnexpectedNetWeightErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalGrossWeight.AsDecimal(), SalesLine.Quantity * SalesLine."Gross Weight", UnexpectedGrossWeightErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalVolume.AsDecimal(), SalesLine.Quantity * SalesLine."Unit Volume", UnexpectedVolumeErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Edit Posted Documents");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Edit Posted Documents");

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Edit Posted Documents");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithSellToCustomer(CustomerNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndPostSalesInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure MockServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Posting Date" := WorkDate();
        ServiceInvoiceHeader."Bill-to Name" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Insert();
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader: Record "Sales Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Package Tracking No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Package Tracking No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        LibraryVariableStorage.Enqueue(PurchInvHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Payment Method Code");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Creditor No.");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Ship-to Code");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader: Record "Return Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to County");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to Country/Region Code");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader: Record "Return Receipt Header")
    begin
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to County");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Package Tracking No.");
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesShipment(var SalesShptHeader: Record "Sales Shipment Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);

        SalesShptHeader.Init();
        SalesShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesShptHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);

        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateRandomCode(SalesCrMemoHeader.FieldNo("No."), Database::"Sales Cr.Memo Header");
        SalesCrMemoHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesCrMemoHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesCrMemoHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
    end;

    local procedure PrepareValuesForEditableFieldsPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        ShipToAddress: Record "Ship-to Address";
        PaymentMethod: Record "Payment Method";
        PaymentReference: Code[50];
    begin
        PaymentReference :=
          CopyStr(
            LibraryUtility.GenerateRandomNumericText(MaxStrLen(PurchInvHeader."Payment Reference")), 1,
            MaxStrLen(PurchInvHeader."Payment Reference"));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibrarySales.CreateShipToAddress(ShipToAddress, PurchInvHeader."Sell-to Customer No.");
        PurchInvHeader."Payment Reference" := PaymentReference;
        PurchInvHeader."Payment Method Code" := PaymentMethod.Code;
        PurchInvHeader."Creditor No." := LibraryUtility.GenerateGUID();
        PurchInvHeader."Ship-to Code" := ShipToAddress.Code;
    end;

    local procedure PrepareValuesForEditableFieldsPostedReturnShipment(var ReturnShptHeader: Record "Return Shipment Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);

        ReturnShptHeader.Init();
        ReturnShptHeader."Ship-to County" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Ship-to Country/Region Code" := CountryRegion.Code;
    end;

    local procedure PrepareValuesForEditableFieldsPostedReturnReceipt(var ReturnRcptHeader: Record "Return Receipt Header")
    var
        CountryRegion: Record "Country/Region";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        ReturnRcptHeader.Init();
        ReturnRcptHeader."Bill-to County" := LibraryUtility.GenerateGUID();
        ReturnRcptHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        ReturnRcptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnRcptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareEnqueueValuesForPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        SalesInvoiceHeader."Payment Reference" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Payment Method Code" := PaymentMethod.Code;

        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Payment Method Code");
    end;

    local procedure PrepareEnqueueValuesForPostedServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        ServiceInvoiceHeader."Payment Reference" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Payment Method Code" := PaymentMethod.Code;

        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Payment Method Code");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateOKModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdatePackageTrackingNo_MPH(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateCancelModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateGetEditablelModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Sell-to Customer Name".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Shipping Agent Code".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Shipping Agent Service Code".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Package Tracking No.".Editable);
        PostedSalesShipmentUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateGetEditablelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Sell-to Customer Name".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Shipping Agent Code".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Shipping Agent Service Code".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Package Tracking No.".Editable());
        PstdSalesCrMemoUpdate.Cancel.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateGetEditablelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Buy-from Vendor Name".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Payment Reference".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Payment Method Code".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Creditor No.".Editable);
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Ship-to Code".Editable);
        PostedPurchInvoiceUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateOKModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateCancelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateGetEditablelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Buy-from Vendor Name".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Ship-to County".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Ship-to Country/Region Code".Editable);
        PostedReturnShptUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateOKModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptUpdate."Bill-to County".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateCancelModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptUpdate."Bill-to County".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateGetEditablelModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Sell-to Customer Name".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Bill-to County".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Bill-to Country/Region Code".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Shipping Agent Code".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Package Tracking No.".Editable);
        PostedReturnReceiptUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateGetEditablelModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Sell-to Customer Name".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Payment Reference".Editable);
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Payment Method Code".Editable);
        PostedSalesInvUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOKModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesInvUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateCancelModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesInvUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateGetEditablelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."No.".Editable);
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Bill-to Name".Editable);
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Posting Date".Editable);
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Payment Reference".Editable);
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Payment Method Code".Editable);
        PostedServiceInvUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOKModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceInvUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateCancelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceInvUpdate.Cancel.Invoke;
    end;
}

