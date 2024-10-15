codeunit 134658 "Edit Posted Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

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
        Assert.AreNotEqual(SalesShptHeader."Additional Information", PostedSalesShipment."Additional Information".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Additional Notes", PostedSalesShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Additional Instructions", PostedSalesShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(SalesShptHeader."TDD Prepared By", PostedSalesShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(Format(SalesShptHeader."3rd Party Loader Type"), PostedSalesShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(SalesShptHeader."3rd Party Loader No.", PostedSalesShipment."3rd Party Loader No.".Value, '');

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
        Assert.AreEqual(SalesShptHeader."Additional Information", PostedSalesShipment."Additional Information".Value, '');
        Assert.AreEqual(SalesShptHeader."Additional Notes", PostedSalesShipment."Additional Notes".Value, '');
        Assert.AreEqual(SalesShptHeader."Additional Instructions", PostedSalesShipment."Additional Instructions".Value, '');
        Assert.AreEqual(SalesShptHeader."TDD Prepared By", PostedSalesShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(Format(SalesShptHeader."3rd Party Loader Type"), PostedSalesShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(SalesShptHeader."3rd Party Loader No.", PostedSalesShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
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

        // [WHEN] Open "Posted Purch. Invoice - Update" page.
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice."Update Document".Invoke;

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Creditor No.", "Ship-to Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesCancel()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader);
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoice."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Purch. Inv. Header were not changed.
        Assert.AreNotEqual(PurchInvHeader."Payment Reference", PostedPurchaseInvoice."Payment Reference".Value, '');
        Assert.AreNotEqual(PurchInvHeader."Creditor No.", PostedPurchaseInvoice."Creditor No.".Value, '');
        Assert.AreNotEqual(PurchInvHeader."Ship-to Code", PostedPurchaseInvoice."Ship-to Code".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesOK()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader);
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoice."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Purch. Inv. Header were changed.
        Assert.AreEqual(PurchInvHeader."Payment Reference", PostedPurchaseInvoice."Payment Reference".Value, '');
        Assert.AreEqual(PurchInvHeader."Creditor No.", PostedPurchaseInvoice."Creditor No.".Value, '');
        Assert.AreEqual(PurchInvHeader."Ship-to Code", PostedPurchaseInvoice."Ship-to Code".Value, '');

        LibraryVariableStorage.AssertEmpty;
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
        Assert.AreNotEqual(ReturnShptHeader."Additional Information", PostedReturnShipment."Additional Information".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Additional Notes", PostedReturnShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Additional Instructions", PostedReturnShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."TDD Prepared By", PostedReturnShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Shipment Method Code", PostedReturnShipment."Shipment Method Code".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Shipping Agent Code", PostedReturnShipment."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(Format(ReturnShptHeader."3rd Party Loader Type"), PostedReturnShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."3rd Party Loader No.", PostedReturnShipment."3rd Party Loader No.".Value, '');

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
        Assert.AreEqual(ReturnShptHeader."Additional Information", PostedReturnShipment."Additional Information".Value, '');
        Assert.AreEqual(ReturnShptHeader."Additional Notes", PostedReturnShipment."Additional Notes".Value, '');
        Assert.AreEqual(ReturnShptHeader."Additional Instructions", PostedReturnShipment."Additional Instructions".Value, '');
        Assert.AreEqual(ReturnShptHeader."TDD Prepared By", PostedReturnShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(ReturnShptHeader."Shipment Method Code", PostedReturnShipment."Shipment Method Code".Value, '');
        Assert.AreEqual(ReturnShptHeader."Shipping Agent Code", PostedReturnShipment."Shipping Agent Code".Value, '');
        Assert.AreEqual(Format(ReturnShptHeader."3rd Party Loader Type"), PostedReturnShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(ReturnShptHeader."3rd Party Loader No.", PostedReturnShipment."3rd Party Loader No.".Value, '');

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
    [HandlerFunctions('PostedTransferShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateSetValuesCancel()
    var
        TransferShptHeader: Record "Transfer Shipment Header";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
    begin
        // [FEATURE] [Transfer Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Transfer Shipment - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);

        // [GIVEN] Opened "Posted Transfer Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);
        PostedTransferShipment.OpenView;
        PostedTransferShipment."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Transfer Shipment Header were not changed.
        Assert.AreNotEqual(TransferShptHeader."Transport Reason Code", PostedTransferShipment."Transport Reason Code".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Goods Appearance", PostedTransferShipment."Goods Appearance".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Gross Weight", PostedTransferShipment."Gross Weight".AsDEcimal, '');
        Assert.AreNotEqual(TransferShptHeader."Net Weight", PostedTransferShipment."Net Weight".AsDEcimal, '');
        Assert.AreNotEqual(TransferShptHeader."Parcel Units", PostedTransferShipment."Parcel Units".AsDEcimal, '');
        Assert.AreNotEqual(TransferShptHeader.Volume, PostedTransferShipment.Volume.AsDEcimal, '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Notes", PostedTransferShipment."Shipping Notes".Value, '');
        Assert.AreNotEqual(Format(TransferShptHeader."3rd Party Loader Type"), PostedTransferShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(TransferShptHeader."3rd Party Loader No.", PostedTransferShipment."3rd Party Loader No.".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Starting Date", PostedTransferShipment."Shipping Starting Date".AsDate, '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Starting Time", PostedTransferShipment."Shipping Starting Time".AsTime, '');
        Assert.AreNotEqual(TransferShptHeader."Package Tracking No.", PostedTransferShipment."Package Tracking No.".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Information", PostedTransferShipment."Additional Information".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Notes", PostedTransferShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Instructions", PostedTransferShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(TransferShptHeader."TDD Prepared By", PostedTransferShipment."TDD Prepared By".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedTransferShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateSetValuesOK()
    var
        TransferShptHeader: Record "Transfer Shipment Header";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
    begin
        // [FEATURE] [Transfer Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Transfer Shipment - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);

        // [GIVEN] Opened "Posted Transfer Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);
        PostedTransferShipment.OpenView;
        PostedTransferShipment."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Transfer Shipment Header were changed.
        Assert.AreEqual(TransferShptHeader."Transport Reason Code", PostedTransferShipment."Transport Reason Code".Value, '');
        Assert.AreEqual(TransferShptHeader."Goods Appearance", PostedTransferShipment."Goods Appearance".Value, '');
        Assert.AreEqual(TransferShptHeader."Gross Weight", PostedTransferShipment."Gross Weight".AsDEcimal, '');
        Assert.AreEqual(TransferShptHeader."Net Weight", PostedTransferShipment."Net Weight".AsDEcimal, '');
        Assert.AreEqual(TransferShptHeader."Parcel Units", PostedTransferShipment."Parcel Units".AsDEcimal, '');
        Assert.AreEqual(TransferShptHeader.Volume, PostedTransferShipment.Volume.AsDEcimal, '');
        Assert.AreEqual(TransferShptHeader."Shipping Notes", PostedTransferShipment."Shipping Notes".Value, '');
        Assert.AreEqual(Format(TransferShptHeader."3rd Party Loader Type"), PostedTransferShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(TransferShptHeader."3rd Party Loader No.", PostedTransferShipment."3rd Party Loader No.".Value, '');
        Assert.AreEqual(TransferShptHeader."Shipping Starting Date", PostedTransferShipment."Shipping Starting Date".AsDate, '');
        Assert.AreEqual(TransferShptHeader."Shipping Starting Time", PostedTransferShipment."Shipping Starting Time".AsTime, '');
        Assert.AreEqual(TransferShptHeader."Package Tracking No.", PostedTransferShipment."Package Tracking No.".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Information", PostedTransferShipment."Additional Information".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Notes", PostedTransferShipment."Additional Notes".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Instructions", PostedTransferShipment."Additional Instructions".Value, '');
        Assert.AreEqual(TransferShptHeader."TDD Prepared By", PostedTransferShipment."TDD Prepared By".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedServiceShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateSetValuesCancel()
    var
        ServiceShptHeader: Record "Service Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        OrderNo: Code[20];
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Shipment - Update" modal page.
        Initialize();
        OrderNo := CreateAndPostServiceOrder;
        PrepareValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);

        // [GIVEN] Opened "Posted Service Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);
        PostedServiceShipment.OpenView;
        PostedServiceShipment.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceShipment."Update Document".Invoke;

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Shipment Header were not changed.
        Assert.AreNotEqual(ServiceShptHeader."Additional Information", PostedServiceShipment."Additional Information".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Additional Notes", PostedServiceShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Additional Instructions", PostedServiceShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."TDD Prepared By", PostedServiceShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Shipment Method Code", PostedServiceShipment."Shipment Method Code".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Shipping Agent Code", PostedServiceShipment."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(Format(ServiceShptHeader."3rd Party Loader Type"), PostedServiceShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."3rd Party Loader No.", PostedServiceShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedServiceShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateSetValuesOK()
    var
        ServiceShptHeader: Record "Service Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        OrderNo: Code[20];
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Service Shipment - Update" modal page.
        Initialize();
        OrderNo := CreateAndPostServiceOrder;
        PrepareValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);

        // [GIVEN] Opened "Posted Service Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);
        PostedServiceShipment.OpenView;
        PostedServiceShipment.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceShipment."Update Document".Invoke;

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Shipment Header were changed.
        Assert.AreEqual(ServiceShptHeader."Additional Information", PostedServiceShipment."Additional Information".Value, '');
        Assert.AreEqual(ServiceShptHeader."Additional Notes", PostedServiceShipment."Additional Notes".Value, '');
        Assert.AreEqual(ServiceShptHeader."Additional Instructions", PostedServiceShipment."Additional Instructions".Value, '');
        Assert.AreEqual(ServiceShptHeader."TDD Prepared By", PostedServiceShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(ServiceShptHeader."Shipment Method Code", PostedServiceShipment."Shipment Method Code".Value, '');
        Assert.AreEqual(ServiceShptHeader."Shipping Agent Code", PostedServiceShipment."Shipping Agent Code".Value, '');
        Assert.AreEqual(Format(ServiceShptHeader."3rd Party Loader Type"), PostedServiceShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(ServiceShptHeader."3rd Party Loader No.", PostedServiceShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Edit Posted Documents");

        LibraryVariableStorage.Clear;
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

    local procedure CreateAndPostServiceOrder() OrderNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        OrderNo := ServiceHeader."No.";
    end;

    local procedure CreateShipmentMethodWith3rdPartyLoader(var ShipmentMethod: Record "Shipment Method")
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateGUID;
        ShipmentMethod."3rd-Party Loader" := true;
        ShipmentMethod.Insert();
    end;

    local procedure CreateTransportReasonCode(var TransportReasonCode: Record "Transport Reason Code")
    begin
        TransportReasonCode.Init();
        TransportReasonCode.Code := LibraryUtility.GenerateGUID;
        TransportReasonCode.Insert();
    end;

    local procedure CreateGoodsAppearance(var GoodsAppearance: Record "Goods Appearance")
    begin
        GoodsAppearance.Init();
        GoodsAppearance.Code := LibraryUtility.GenerateGUID;
        GoodsAppearance.Insert();
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader: Record "Sales Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Package Tracking No.");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(SalesShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(SalesShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(SalesShptHeader."3rd Party Loader No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        LibraryVariableStorage.Enqueue(PurchInvHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Creditor No.");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Ship-to Code");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader: Record "Return Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to County");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Shipment Method Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."3rd Party Loader No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader: Record "Return Receipt Header")
    begin
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to County");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Package Tracking No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader: Record "Transfer Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(TransferShptHeader."Transport Reason Code");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Goods Appearance");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Gross Weight");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Net Weight");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Parcel Units");
        LibraryVariableStorage.Enqueue(TransferShptHeader.Volume);
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Notes");
        LibraryVariableStorage.Enqueue(TransferShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(TransferShptHeader."3rd Party Loader No.");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Starting Date");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Starting Time");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Package Tracking No.");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(TransferShptHeader."TDD Prepared By");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader: Record "Service Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Shipment Method Code");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."3rd Party Loader No.");
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesShipment(var SalesShptHeader: Record "Sales Shipment Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShipmentMethod: Record "Shipment Method";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo;
        ShippingAgent.Modify();

        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        SalesShptHeader.FindFirst;
        SalesShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        SalesShptHeader.Modify();

        SalesShptHeader.Init();
        SalesShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesShptHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID;
        SalesShptHeader."Additional Information" := LibraryUtility.GenerateGUID;
        SalesShptHeader."Additional Notes" := LibraryUtility.GenerateGUID;
        SalesShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID;
        SalesShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID;
        SalesShptHeader."3rd Party Loader Type" := SalesShptHeader."3rd Party Loader Type"::Vendor;
        SalesShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo;
    end;

    local procedure PrepareValuesForEditableFieldsPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        ShipToAddress: Record "Ship-to Address";
        Customer: Record Customer;
        PaymentReference: Code[50];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        PostedPurchaseInvoiceNo := CreateAndPostPurchaseInvoiceWithSellToCustomer(Customer."No.");
        PaymentReference :=
          CopyStr(
            LibraryUtility.GenerateRandomNumericText(MaxStrLen(PurchInvHeader."Payment Reference")), 1,
            MaxStrLen(PurchInvHeader."Payment Reference"));
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        PurchInvHeader."No." := PostedPurchaseInvoiceNo;
        PurchInvHeader."Sell-to Customer No." := Customer."No.";
        PurchInvHeader."Payment Reference" := PaymentReference;
        PurchInvHeader."Creditor No." := LibraryUtility.GenerateGUID;
        PurchInvHeader."Ship-to Code" := ShipToAddress.Code;
    end;

    local procedure PrepareValuesForEditableFieldsPostedReturnShipment(var ReturnShptHeader: Record "Return Shipment Header")
    var
        CountryRegion: Record "Country/Region";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo;
        ShippingAgent.Modify();

        ReturnShptHeader.Init();
        ReturnShptHeader."Ship-to County" := LibraryUtility.GenerateGUID;
        ReturnShptHeader."Ship-to Country/Region Code" := CountryRegion.Code;
        ReturnShptHeader."Additional Information" := LibraryUtility.GenerateGUID;
        ReturnShptHeader."Additional Notes" := LibraryUtility.GenerateGUID;
        ReturnShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID;
        ReturnShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID;
        ReturnShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        ReturnShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnShptHeader."3rd Party Loader Type" := ReturnShptHeader."3rd Party Loader Type"::Vendor;
        ReturnShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo;
    end;

    local procedure PrepareValuesForEditableFieldsPostedReturnReceipt(var ReturnRcptHeader: Record "Return Receipt Header")
    var
        CountryRegion: Record "Country/Region";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        ReturnRcptHeader.Init();
        ReturnRcptHeader."Bill-to County" := LibraryUtility.GenerateGUID;
        ReturnRcptHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        ReturnRcptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnRcptHeader."Package Tracking No." := LibraryUtility.GenerateGUID;
    end;

    local procedure PrepareValuesForEditableFieldsPostedTransferShipment(var TransferShptHeader: Record "Transfer Shipment Header")
    var
        ShipmentMethod: Record "Shipment Method";
        GoodsAppearance: Record "Goods Appearance";
        TransportReasonCode: Record "Transport Reason Code";
    begin
        CreateTransportReasonCode(TransportReasonCode);
        CreateGoodsAppearance(GoodsAppearance);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        TransferShptHeader.FindFirst;
        TransferShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        TransferShptHeader.Modify();

        TransferShptHeader.Init();
        TransferShptHeader."Transport Reason Code" := TransportReasonCode.Code;
        TransferShptHeader."Goods Appearance" := GoodsAppearance.Code;
        TransferShptHeader."Gross Weight" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Net Weight" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Parcel Units" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader.Volume := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Shipping Notes" := LibraryUtility.GenerateGUID;
        TransferShptHeader."3rd Party Loader Type" := TransferShptHeader."3rd Party Loader Type"::Vendor;
        TransferShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo;
        TransferShptHeader."Shipping Starting Date" := LibraryRandom.RandDate(1000);
        TransferShptHeader."Shipping Starting Time" := 123456T;
        TransferShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID;
        TransferShptHeader."Additional Information" := LibraryUtility.GenerateGUID;
        TransferShptHeader."Additional Notes" := LibraryUtility.GenerateGUID;
        TransferShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID;
        TransferShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID;
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceShipment(var ServiceShptHeader: Record "Service Shipment Header")
    var
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
    begin
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo;
        ShippingAgent.Modify();

        ServiceShptHeader.Init();
        ServiceShptHeader."Additional Information" := LibraryUtility.GenerateGUID;
        ServiceShptHeader."Additional Notes" := LibraryUtility.GenerateGUID;
        ServiceShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID;
        ServiceShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID;
        ServiceShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        ServiceShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ServiceShptHeader."3rd Party Loader Type" := ServiceShptHeader."3rd Party Loader Type"::Vendor;
        ServiceShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateOKModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateCancelModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedSalesShipmentUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
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
    procedure PostedPurchInvoiceUpdateOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
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
        PostedReturnShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateCancelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
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
    procedure PostedTransferShipmentUpdateOKModalPageHandler(var PostedTransferShptUpdate: TestPage "Posted Transfer Shpt. - Update")
    begin
        PostedTransferShptUpdate."Transport Reason Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Goods Appearance".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Gross Weight".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Net Weight".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Parcel Units".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate.Volume.SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Shipping Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Shipping Starting Date".SetValue(LibraryVariableStorage.DequeueDate);
        PostedTransferShptUpdate."Shipping Starting Time".SetValue(LibraryVariableStorage.DequeueTime);
        PostedTransferShptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateCancelModalPageHandler(var PostedTransferShptUpdate: TestPage "Posted Transfer Shpt. - Update")
    begin
        PostedTransferShptUpdate."Transport Reason Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Goods Appearance".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Gross Weight".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Net Weight".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Parcel Units".SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate.Volume.SetValue(LibraryVariableStorage.DequeueDecimal);
        PostedTransferShptUpdate."Shipping Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Shipping Starting Date".SetValue(LibraryVariableStorage.DequeueDate);
        PostedTransferShptUpdate."Shipping Starting Time".SetValue(LibraryVariableStorage.DequeueTime);
        PostedTransferShptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedTransferShptUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateOKModalPageHandler(var PostedServiceShptUpdate: TestPage "Posted Service Shpt. - Update")
    begin
        PostedServiceShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateCancelModalPageHandler(var PostedServiceShptUpdate: TestPage "Posted Service Shpt. - Update")
    begin
        PostedServiceShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedServiceShptUpdate.Cancel.Invoke;
    end;
}

