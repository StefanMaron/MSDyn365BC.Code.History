codeunit 147330 "Edit Posted Documents ES"
{
    Permissions = TableData "Sales Invoice Header" = ri,
                  TableData "Purch. Inv. Header" = ri;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesCancel()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Invoice Header were not changed.
        Assert.AreNotEqual(Format(SalesInvoiceHeader."Special Scheme Code"), PostedSalesInvoice."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(SalesInvoiceHeader."Invoice Type"), PostedSalesInvoice."Invoice Type".Value, '');
        Assert.AreNotEqual(Format(SalesInvoiceHeader."ID Type"), PostedSalesInvoice."ID Type".Value, '');
        Assert.AreNotEqual(SalesInvoiceHeader."Succeeded Company Name", PostedSalesInvoice."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          SalesInvoiceHeader."Succeeded VAT Registration No.", PostedSalesInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesOK()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);
        PostedDocNo := CreateAndPostSalesInvoice();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Invoice Header were changed.
        Assert.AreEqual(Format(SalesInvoiceHeader."Special Scheme Code"), PostedSalesInvoice."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(SalesInvoiceHeader."Invoice Type"), PostedSalesInvoice."Invoice Type".Value, '');
        Assert.AreEqual(Format(SalesInvoiceHeader."ID Type"), PostedSalesInvoice."ID Type".Value, '');
        Assert.AreEqual(SalesInvoiceHeader."Succeeded Company Name", PostedSalesInvoice."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          SalesInvoiceHeader."Succeeded VAT Registration No.", PostedSalesInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateInvDetailsCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateSetValuesCancel()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Pstd. Sales Cr. Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Cr.Memo Header were not changed.
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Special Scheme Code"), PostedSalesCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Cr. Memo Type"), PostedSalesCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Correction Type"), PostedSalesCreditMemo."Correction Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateInvDetailsOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateSetValuesOK()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Pstd. Sales Cr. Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);
        PostedDocNo := CreateAndPostSalesCreditMemo();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Cr.Memo Header were changed.
        Assert.AreEqual(Format(SalesCrMemoHeader."Special Scheme Code"), PostedSalesCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(SalesCrMemoHeader."Cr. Memo Type"), PostedSalesCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreEqual(Format(SalesCrMemoHeader."Correction Type"), PostedSalesCreditMemo."Correction Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesCancel()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Purch. Cr.Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Purch. Cr. Memo Hdr. were not changed.
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Special Scheme Code"), PostedPurchaseCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Cr. Memo Type"), PostedPurchaseCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Correction Type"), PostedPurchaseCreditMemo."Correction Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesOK()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Purch. Cr.Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page. A user with "D365 Purch Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();
        LibraryLowerPermissions.SetPurchDocsPost();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Purch. Cr. Memo Hdr. were changed.
        Assert.AreEqual(Format(PurchCrMemoHdr."Special Scheme Code"), PostedPurchaseCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(PurchCrMemoHdr."Cr. Memo Type"), PostedPurchaseCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreEqual(Format(PurchCrMemoHdr."Correction Type"), PostedPurchaseCreditMemo."Correction Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesCancel()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 373682] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Invoice Header were not changed.
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Country/Region Code"), PostedServiceInvoice."Country/Region Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Bill-to Country/Region Code"), PostedServiceInvoice."Bill-to Country/Region Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Ship-to Country/Region Code"), PostedServiceInvoice."Ship-to Country/Region Code".Value, '');

        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Special Scheme Code"), PostedServiceInvoice."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Invoice Type"), PostedServiceInvoice."Invoice Type".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."ID Type"), PostedServiceInvoice."ID Type".Value, '');
        Assert.AreNotEqual(ServiceInvoiceHeader."Succeeded Company Name", PostedServiceInvoice."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          ServiceInvoiceHeader."Succeeded VAT Registration No.", PostedServiceInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesOK()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Invoice] [Permissions]
        // [SCENARIO 373682] New values for editable fields are set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set. This set allows user to Modify all service related tables.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);
        PostedDocNo := CreateAndPostServiceInvoice();
        LibraryLowerPermissions.SetO365ServiceMgtRead();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Invoice Header were changed.
        Assert.AreEqual(Format(ServiceInvoiceHeader."Country/Region Code"), PostedServiceInvoice."Country/Region Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Bill-to Country/Region Code"), PostedServiceInvoice."Bill-to Country/Region Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Ship-to Country/Region Code"), PostedServiceInvoice."Ship-to Country/Region Code".Value, '');

        Assert.AreEqual(Format(ServiceInvoiceHeader."Special Scheme Code"), PostedServiceInvoice."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Invoice Type"), PostedServiceInvoice."Invoice Type".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."ID Type"), PostedServiceInvoice."ID Type".Value, '');
        Assert.AreEqual(ServiceInvoiceHeader."Succeeded Company Name", PostedServiceInvoice."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          ServiceInvoiceHeader."Succeeded VAT Registration No.", PostedServiceInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateSetValuesCancel()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 373682] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Credit Memo Header were not changed.
        Assert.AreNotEqual(Format(ServiceCrMemoHeader."Special Scheme Code"), PostedServiceCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(ServiceCrMemoHeader."Cr. Memo Type"), PostedServiceCreditMemo."Cr. Memo Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateSetValuesOK()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Credit Memo] [Permissions]
        // [SCENARIO 373682] New values for editable fields are set in case Stan presses OK on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set. This set allows user to Modify all service related tables.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);
        PostedDocNo := CreateAndPostServiceCreditMemo();
        LibraryLowerPermissions.SetO365ServiceMgtRead();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Credit Memo Header were changed.
        Assert.AreEqual(Format(ServiceCrMemoHeader."Special Scheme Code"), PostedServiceCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(ServiceCrMemoHeader."Cr. Memo Type"), PostedServiceCreditMemo."Cr. Memo Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescriptionCancel()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Invoice. Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Sales Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedSalesInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescriptionOK()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Invoice. Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Sales Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedSalesInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescriptionCancel()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Sales Cr. Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Credit Memo. Opened "Posted Sales Cr. Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Sales Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedSalesCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescriptionOK()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Sales Cr. Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Credit Memo. Opened "Posted Sales Cr. Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Sales Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedSalesCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceUpdateOperationDescriptionCancel()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Purchase Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Invoice. Opened "Posted Purchase Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseInvoice();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Purchase Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedPurchaseInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceUpdateOperationDescriptionOK()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Purchase Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Invoice. Opened "Posted Purchase Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseInvoice();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Purchase Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedPurchaseInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoUpdateOperationDescriptionCancel()
    var
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Purchase Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Credit Memo. Opened "Posted Purchase Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Purchase Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedPurchaseCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoUpdateOperationDescriptionOK()
    var
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Purchase Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Credit Memo. Opened "Posted Purchase Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Purchase Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedPurchaseCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOperationDescrCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescriptionCancel()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Service Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedServiceInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOperationDescrOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescriptionOK()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Service Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedServiceInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOperationDescrCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoUpdateOperationDescriptionCancel()
    var
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Service Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedServiceCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOperationDescrOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoUpdateOperationDescriptionOK()
    var
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Service Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedServiceCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedSalesInvoicesCheckLookupValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupCorrectedInvoiceNoFromPostedSalesCreditMemoPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 405655] Stan can lookup posted sales invoices from the "Corrected Invoice No." field of the "Posted Sales Credit Memo - Edit"chec page

        Initialize;
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice);
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemoForCustomer(SalesInvoiceHeader."Bill-to Customer No."));

        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        PostedSalesCreditMemo.OpenView;
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        PostedSalesCreditMemo."Update Document".Invoke;

        // Verification performs withing handlers: PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedSalesInvoicesCheckLookupValueModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedPurchInvoicesCheckLookupValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupCorrectedInvoiceNoFromPostedPurchCreditMemoPage()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 405655] Stan can lookup posted purchase invoices from the "Corrected Invoice No." field of the "Posted Purchase Credit Memo - Edit" page

        Initialize;
        PurchInvHeader.Get(CreateAndPostPurchaseInvoice);
        PurchCrMemoHdr.Get(CreateAndPostPurchaseCreditMemoForVendor(PurchInvHeader."Pay-to Vendor No."));

        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        PostedPurchaseCreditMemo.OpenView;
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");
        PostedPurchaseCreditMemo."Update Document".Invoke;

        // Verification performs withing handlers: PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedPurchInvoicesCheckLookupValueModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCorrInvNoCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoCancel()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 405655] Corrected Invoice No. is not set in case Stan presses Cancel on "Pstd. Sales Cr. Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Corrected Invoice No.");
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.
        // [THEN] Corrected Invoice No. is not changed
        Assert.AreNotEqual(SalesCrMemoHeader."Corrected Invoice No.", PostedSalesCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCorrInvNoOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoOK()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo] [Permissions]
        // [SCENARIO 405655] Corrected Invoice No. is set in case Stan presses OK on "Pstd. Sales Cr. Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Corrected Invoice No.");
        PostedDocNo := CreateAndPostSalesCreditMemo();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.
        // [THEN] Corrected Invoice No. is changed
        Assert.AreEqual(SalesCrMemoHeader."Corrected Invoice No.", PostedSalesCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCorrInvNoCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoCancel()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 405655] Corrected Invoice No. not set in case Stan presses Cancel on "Posted Purch. Cr.Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Corrected Invoice No.");
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.
        // [THEN] Corrected Invoice No. is not changed
        Assert.AreNotEqual(PurchCrMemoHdr."Corrected Invoice No.", PostedPurchaseCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCorrInvNoOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoOK()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo] [Permissions]
        // [SCENARIO 405655] Corrected Invoice No. is set in case Stan presses OK on "Posted Purch. Cr.Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page. A user with "D365 Purch Doc, Post" permission set.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Corrected Invoice No.");
        PostedDocNo := CreateAndPostPurchaseCreditMemo();
        LibraryLowerPermissions.SetPurchDocsPost();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.
        // [THEN] Corrected Invoice No. is changed
        Assert.AreEqual(PurchCrMemoHdr."Corrected Invoice No.", PostedPurchaseCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Edit Posted Documents ES");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Edit Posted Documents ES");

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Edit Posted Documents ES");
    end;

    local procedure CreateAndPostSalesInvoice() PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostSalesCreditMemo() PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostSalesCreditMemoForCustomer(CustNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, CustNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateAndPostPurchaseInvoice() PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostPurchaseCreditMemo() PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostPurchaseCreditMemoForVendor(VendNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, VendNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateAndPostServiceInvoice() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        PostedDocNo := ServiceInvoiceHeader."No.";
    end;

    local procedure CreateAndPostServiceCreditMemo() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader."Posting No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        ServiceHeader.Modify();
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        PostedDocNo := ServiceCrMemoHeader."No.";
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Invoice Type");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."ID Type");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Cr. Memo Type");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Correction Type");
    end;

    local procedure EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Special Scheme Code");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Cr. Memo Type");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Correction Type");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Country/Region Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Bill-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Ship-to Country/Region Code");

        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Invoice Type");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."ID Type");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."Cr. Memo Type");
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        SalesInvoiceHeader."Invoice Type" := "SII Sales Invoice Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        SalesInvoiceHeader."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        SalesInvoiceHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        SalesCrMemoHeader."Cr. Memo Type" := "SII Sales Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        SalesCrMemoHeader."Correction Type" := LibraryRandom.RandIntInRange(1, 3);
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." :=
          LibraryUtility.GenerateRandomCode(SalesInvoiceHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        SalesInvoiceHeader.Insert();
        SalesCrMemoHeader."Corrected Invoice No." := SalesInvoiceHeader."No.";
    end;

    local procedure PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."Special Scheme Code" := "SII Purch. Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        PurchCrMemoHdr."Cr. Memo Type" := "SII Purch. Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        PurchCrMemoHdr."Correction Type" := LibraryRandom.RandIntInRange(1, 3);
        PurchInvHeader.Init();
        PurchInvHeader."No." :=
          LibraryUtility.GenerateRandomCode(PurchInvHeader.FieldNo("No."), DATABASE::"Purch. Inv. Header");
        PurchInvHeader.Insert();
        PurchCrMemoHdr."Corrected Invoice No." := PurchInvHeader."No.";
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CountryRegion: Record "Country/Region";
        BillToCountryRegion: Record "Country/Region";
        ShipToCountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegion(BillToCountryRegion);
        LibraryERM.CreateCountryRegion(ShipToCountryRegion);

        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."Country/Region Code" := CountryRegion.Code;
        ServiceInvoiceHeader."Bill-to Country/Region Code" := BillToCountryRegion.Code;
        ServiceInvoiceHeader."Ship-to Country/Region Code" := ShipToCountryRegion.Code;

        ServiceInvoiceHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        ServiceInvoiceHeader."Invoice Type" := "SII Sales Invoice Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        ServiceInvoiceHeader."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        ServiceInvoiceHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceCreditMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        ServiceCrMemoHeader."Cr. Memo Type" := "SII Sales Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOKModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateCancelModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateInvDetailsOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateInvDetailsCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOKModalPageHandler(var PostedServInvoiceUpdate: TestPage "Posted Serv. Invoice - Update")
    begin
        PostedServInvoiceUpdate."Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());

        PostedServInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateCancelModalPageHandler(var PostedServInvoiceUpdate: TestPage "Posted Serv. Invoice - Update")
    begin
        PostedServInvoiceUpdate."Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());

        PostedServInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOKModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateCancelModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescrOKModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescrOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescrCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".Lookup();
        PstdSalesCrMemoUpdate."Corrected Invoice No.".AssertEquals(LibraryVariableStorage.DequeueText);
        PstdSalesCrMemoUpdate.Cancel.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOperationDescrOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOperationDescrOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOperationDescrCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".Lookup();
        PostedPurchCrMemoUpdate."Corrected Invoice No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescrOKModalPageHandler(var PostedServInvoiceUpdate: TestPage "Posted Serv. Invoice - Update")
    begin
        PostedServInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedServInvoiceUpdate: TestPage "Posted Serv. Invoice - Update")
    begin
        PostedServInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOperationDescrOKModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOperationDescrCancelModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesCheckLookupValueModalPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    var
        InvNo: Text;
    begin
        InvNo := LibraryVariableStorage.PeekText(1);
        PostedSalesInvoices."No.".AssertEquals(InvNo);
        PostedSalesInvoices.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicesCheckLookupValueModalPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    var
        InvNo: Text;
    begin
        InvNo := LibraryVariableStorage.PeekText(1);
        PostedPurchaseInvoices."No.".AssertEquals(InvNo);
        PostedPurchaseInvoices.OK.Invoke();
    end;
}
