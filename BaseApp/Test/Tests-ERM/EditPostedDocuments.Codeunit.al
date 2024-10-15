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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
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
        Assert.AreNotEqual(Format(PurchInvHeader."Special Scheme Code"), PostedPurchaseInvoice."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(PurchInvHeader."Invoice Type"), PostedPurchaseInvoice."Invoice Type".Value, '');
        Assert.AreNotEqual(Format(PurchInvHeader."ID Type"), PostedPurchaseInvoice."ID Type".Value, '');
        Assert.AreNotEqual(PurchInvHeader."Succeeded Company Name", PostedPurchaseInvoice."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          PurchInvHeader."Succeeded VAT Registration No.", PostedPurchaseInvoice."Succeeded VAT Registration No.".Value, '');

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
        Assert.AreEqual(Format(PurchInvHeader."Special Scheme Code"), PostedPurchaseInvoice."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(PurchInvHeader."Invoice Type"), PostedPurchaseInvoice."Invoice Type".Value, '');
        Assert.AreEqual(Format(PurchInvHeader."ID Type"), PostedPurchaseInvoice."ID Type".Value, '');
        Assert.AreEqual(PurchInvHeader."Succeeded Company Name", PostedPurchaseInvoice."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          PurchInvHeader."Succeeded VAT Registration No.", PostedPurchaseInvoice."Succeeded VAT Registration No.".Value, '');

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
        // [THEN] Fields "Bill-to Country/Region Code", "Shipping Agent Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, '');
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
        Assert.AreEqual(ReturnRcptHeader."Bill-to Country/Region Code", PostedReturnReceipt."Bill-to Country/Region Code".Value, '');
        Assert.AreEqual(ReturnRcptHeader."Shipping Agent Code", PostedReturnReceipt."Shipping Agent Code".Value, '');
        Assert.AreEqual(ReturnRcptHeader."Package Tracking No.", PostedReturnReceipt."Package Tracking No.".Value, '');

        LibraryVariableStorage.AssertEmpty;
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
        LibraryVariableStorage.Enqueue(PurchInvHeader."Creditor No.");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Ship-to Code");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Invoice Type");
        LibraryVariableStorage.Enqueue(PurchInvHeader."ID Type");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader: Record "Return Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to County");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to Country/Region Code");
    end;

    local procedure EnqueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader: Record "Return Receipt Header")
    begin
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
        SalesShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID;
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
        PurchInvHeader."Special Scheme Code" := LibraryRandom.RandIntInRange(1, 10);
        PurchInvHeader."Invoice Type" := LibraryRandom.RandIntInRange(1, 5);
        PurchInvHeader."ID Type" := LibraryRandom.RandIntInRange(1, 5);
        PurchInvHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID;
        PurchInvHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID;
    end;

    local procedure PrepareValuesForEditableFieldsPostedReturnShipment(var ReturnShptHeader: Record "Return Shipment Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);

        ReturnShptHeader.Init();
        ReturnShptHeader."Ship-to County" := LibraryUtility.GenerateGUID;
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
        ReturnRcptHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        ReturnRcptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnRcptHeader."Package Tracking No." := LibraryUtility.GenerateGUID;
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
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText);
        PostedPurchInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText);
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
        PostedReturnReceiptUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText);
        PostedReturnReceiptUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateCancelModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
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
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Bill-to Country/Region Code".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Shipping Agent Code".Editable);
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Package Tracking No.".Editable);
        PostedReturnReceiptUpdate.Cancel.Invoke;
    end;
}

