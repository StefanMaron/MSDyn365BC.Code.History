codeunit 134099 "Purchase Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
    end;

    var
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Assert: Codeunit Assert;
        PurchaseAlreadyExistsTxt: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type; %2 = Document No.';
        IsInitialized: Boolean;
        WrongReportInvokedErr: Label 'Wrong report invoked.';
        ZeroQuantityInLineErr: Label 'One or more document lines with a value in the No. field do not have a quantity specified.';
        PurchLinesNotUpdatedMsg: Label 'You have changed %1 on the purchase header, but it has not been changed on the existing purchase lines.', Comment = 'You have changed Posting Date on the purchase header, but it has not been changed on the existing purchase lines.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the purchase lines.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.';
        UpdateManuallyMsg: Label 'You must update the existing purchase lines manually.';

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationForInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notificaiton appears it the purchase invoice page in case of Vendor Invoice No. already used for another invoice
        Initialize();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" notificaiton
        EnableShowExternalDocAlreadyExistNotification;

        // [GIVEN] Create and post purchase invoice with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Invoice, PurchaseHeader);

        // [GIVEN] Create new invoice and open it in the Purchase Invoice page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseInvoice."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationForOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrder: TestPage "Purchase Order";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notificaiton appears it the purchase order page in case of Vendor Invoice No. already used for another invoice
        Initialize();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" notificaiton
        EnableShowExternalDocAlreadyExistNotification;

        // [GIVEN] Create and post purchase order with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Order, PurchaseHeader);

        // [GIVEN] Create new order and open it in the Purchase Order page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseOrder."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notificaiton appears it the purchase credit memo page in case of Vendor Cr. Memo No. already used for another credit memo
        Initialize();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" notificaiton
        EnableShowExternalDocAlreadyExistNotification;

        // [GIVEN] Create and post purchase credit memo with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader);

        // [GIVEN] Create new credit memo and open it in the Purchase Credit Memo page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notificaiton appears it the purchase return order page in case of Vendor Cr. Memo No. already used for another return order
        Initialize();
        UpdateNoSeriesOnPurchaseSetup;

        // [GIVEN] Enable "Show purchase document with same external document number already exists" notificaiton
        EnableShowExternalDocAlreadyExistNotification;

        // [GIVEN] Create and post purchase return order with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Return Order", PurchaseHeader);

        // [GIVEN] Create new return order and open it in the Purchase Return Order page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseReturnOrder.OpenEdit;
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseReturnOrder."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationNoMyNotifications()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 300997] Notificaiton appears it the purchase invoice page in case of Vendor Invoice No. already used for another invoice when there are no My Notification records
        Initialize();

        // [GIVEN] Delete all My Notificaiton records
        ClearMyNotification();

        // [GIVEN] Create and post purchase invoice with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Invoice, PurchaseHeader);

        // [GIVEN] Create new invoice and open it in the Purchase Invoice page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseInvoice."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForCreditMemoNoMyNotifications()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 300997] Notificaiton appears it the purchase credit memo page in case of Vendor Cr. Memo No. already used for another credit memo when there are no My Notification records
        Initialize();

        // [GIVEN] Delete all My Notificaiton records
        ClearMyNotification();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" notificaiton
        EnableShowExternalDocAlreadyExistNotification;

        // [GIVEN] Create and post purchase credit memo with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader);

        // [GIVEN] Create new credit memo and open it in the Purchase Credit Memo page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchLinesByNo_UT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Purchase Lines can be updated using the PurchHeader.UpdatePurchLinesByNo method.
        Initialize();

        CreatePurchaseOrderWithLineTypeItem(PurchaseHeader, PurchaseLine);
        PurchaseHeader."Expected Receipt Date" := LibraryRandom.RandDateFrom(WorkDate, 100);
        PurchaseHeader.Modify(true);
        PurchaseHeader.UpdatePurchLinesByFieldNo(PurchaseHeader.FieldNo("Expected Receipt Date"), false);

        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchLines_UT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Purchase Lines can be updated using the PurchHeader.UpdatePurchLines method.
        Initialize();

        CreatePurchaseOrderWithLineTypeItem(PurchaseHeader, PurchaseLine);
        PurchaseHeader."Expected Receipt Date" := LibraryRandom.RandDateFrom(WorkDate, 100);
        PurchaseHeader.Modify(true);
        PurchaseHeader.UpdatePurchLines(PurchaseHeader.FieldCaption("Expected Receipt Date"), false);

        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseCreditMemoWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseReturnOrderWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Return Order]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseInvoiceWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseOrderWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoice.OpenView;
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Post.Invoke;

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoices.OpenView;
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        PurchaseInvoices.PostSelected.Invoke;

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuote.OpenView;
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.Print.Invoke;

        PurchaseHeader.Find();

        Assert.AreEqual(REPORT::"Purchase - Quote", LibraryVariableStorage.DequeueInteger, WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuotes.OpenView;
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        PurchaseQuotes.Print.Invoke;

        PurchaseHeader.Find();

        Assert.AreEqual(REPORT::"Purchase - Quote", LibraryVariableStorage.DequeueInteger, WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        PurchaseOrder.OpenView;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Post.Invoke;

        PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        PurchaseOrderList.OpenView;
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        PurchaseOrderList.Post.Invoke;

        PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemo.OpenView;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Post.Invoke;

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemos.OpenView;
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        PurchaseCreditMemos.Post.Invoke;

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoice.OpenView;
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoice.Post.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoices.OpenView;
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.PostSelected.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuote.OpenView;
        PurchaseQuote.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuote.Print.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuotes.OpenView;
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuotes.Print.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        PurchaseOrder.OpenView;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrder.Post.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        PurchaseOrderList.OpenView;
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Post.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemo.OpenView;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemo.Post.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup;

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemos.OpenView;
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.Post.Invoke;

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithoutCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated do not unclude currency related text when currency is not used
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseHeader.Validate("Posting Date", WorkDate + 1);

        // A message is captured by MessageCaptureHandler
        Assert.ExpectedMessage(
          StrSubstNo(PurchLinesNotUpdatedMsg, PurchaseHeader.FieldCaption("Posting Date")),
          LibraryVariableStorage.DequeueText);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        Currency: Record Currency;
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated including currency related text when currency is applied
        Initialize();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate + 1);

        // A message is captured by MessageCaptureHandler
        MessageText := StrSubstNo(PurchLinesNotUpdatedMsg, PurchaseHeader.FieldCaption("Posting Date"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenLanguageCodeIsUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated including text for manual update
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Language Code", LibraryERM.CreateLanguage);

        MessageText := StrSubstNo(PurchLinesNotUpdatedMsg, PurchaseHeader.FieldCaption("Language Code"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdateManuallyMsg);

        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeClearedOnChangedVendorWithoutPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Purchaser Code" cleared when "Buy-from Vendor No." changed to Vendor with blank "Purchaser Code"
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Vendor "V01" with "Purchaser Code" = "SP01"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" cleared on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedOnChangedVendorWithPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Purchaser Code" updated when "Buy-from Vendor No." changed to Vendor with non-blank "Purchaser Code"
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Vendor "V01" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedFromUserSetupWhenVendorWithPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Vendor with blank "Purchaser Code" and Purchaser Code empty - use Purchaser from UserSetup
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] User Setup with Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        UserSetup.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V01" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDateOnPurchaseDocumentIsInitializedWithWorkDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocType: Option;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 327504] Order Date on purchase documents is initialized with WORKDATE. This is required to pick the current purchase price.
        Initialize();

        for DocType := PurchaseHeader."Document Type"::Quote to PurchaseHeader."Document Type"::"Return Order" do begin
            Clear(PurchaseHeader);
            CreatePurchaseDocument(PurchaseHeader, DocType, '');

            PurchaseHeader.TestField("Order Date", WorkDate);

            LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
            PurchaseLine.TestField("Order Date", WorkDate);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedFromVendorWithSalesperson()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Vendor with "Purchaser Code" but UserSetup Purchaser Code empty - updated from Vendor
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] User Setup without Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", '');
        UserSetup.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeOnInsert()
    var
        VendorWithLocation: Record Vendor;
        VendorWithoutLocation: Record Vendor;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Location]
        // [SCENARIO 333156] Location Code is not reset on record insertion
        Initialize();

        // [GIVEN] Vendor "V1" with blank "Location Code"
        LibraryPurchase.CreateVendorWithLocationCode(VendorWithoutLocation, '');

        // [GIVEN] Vendor "V2" with "Location Code" = "WHITE" and "Pay-to Vendor No." = "V1"
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendorWithLocationCode(VendorWithLocation, Location.Code);
        VendorWithLocation.Validate("Pay-to Vendor No.", VendorWithoutLocation."No.");
        VendorWithLocation.Modify(true);

        // [GIVEN] New Purchase Order with "Buy-from Vendor No." set to "V2"
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorWithLocation."No.");

        // [WHEN] Insert Purchase Order
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "WHITE" on the Purchase Order
        PurchaseHeader.TestField("Location Code", Location.Code);
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
        ReportSelections: Record "Report Selections";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Purchase Documents");

        LibraryApplicationArea.DisableApplicationAreaSetup;
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Purchase Documents");

        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        if not IntrastatSetup.Get then begin
            IntrastatSetup.Init();
            IntrastatSetup.Insert();
        end;
        LibraryERM.SetDefaultTransactionTypesInIntrastatSetup;

        LibrarySetupStorage.Save(DATABASE::"Intrastat Setup");

        ReportSelections.SetRange(Usage, LibraryERMCountryData.GetReportSelectionsUsagePurchaseQuote);
        ReportSelections.ModifyAll("Report ID", REPORT::"Purchase - Quote");

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Purchase Documents");
    end;

    local procedure ClearMyNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.DeleteAll();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Integer; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseOrderWithLineTypeItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePostPurchDocWithExternalDocNo(var ExternalDocumentNo: Code[35]; var VendorNo: Code[20]; DocumentType: Integer; var PurchaseHeader: Record "Purchase Header")
    begin
        ExternalDocumentNo := LibraryUtility.GenerateGUID;
        VendorNo := LibraryPurchase.CreateVendorNo;
        CreatePurchaseDocument(PurchaseHeader, DocumentType, VendorNo);
        case DocumentType of
            PurchaseHeader."Document Type"::Invoice,
          PurchaseHeader."Document Type"::Order:
                PurchaseHeader."Vendor Invoice No." := ExternalDocumentNo;
            PurchaseHeader."Document Type"::"Credit Memo",
          PurchaseHeader."Document Type"::"Return Order":
                PurchaseHeader."Vendor Cr. Memo No." := ExternalDocumentNo;
        end;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo, 0);
        PurchaseHeader.SetRecFilter;
    end;

    local procedure GetLastVendorLedgerEntryNo(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendorLedgerEntry.FindLast then;
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure EnableShowExternalDocAlreadyExistNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.Get(UserId, PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId) then
            MyNotifications.Delete();
        PurchaseHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(true);
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode;
        PurchasesPayablesSetup."Posted Return Shpt. Nos." := LibraryERM.CreateNoSeriesCode;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure VerifyTransactionTypeWhenInsertPurchaseDocument(DocumentType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        PurchaseHeader.Delete();

        PurchaseHeader."Transaction Type" := '';
        PurchaseHeader.Insert();

        PurchaseHeader.TestField("Transaction Type", '');
    end;

    local procedure VerifyNotificationData(ExternalDocumentNo: Code[35]; VendorLedgerEntryNo: Integer; DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund)
    begin
        Assert.AreEqual(VendorLedgerEntryNo, LibraryVariableStorage.DequeueInteger, 'Unexpected vendor ledger entry no.');
        Assert.AreEqual(
          StrSubstNo(PurchaseAlreadyExistsTxt, DocumentType, ExternalDocumentNo),
          LibraryVariableStorage.DequeueText,
          'Unexpected notificaiton message');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Enqueue(Notification.GetData(VendorLedgerEntry.FieldName("Entry No.")));
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    begin
        PurchaseQuote.Cancel.Invoke;
        LibraryVariableStorage.Enqueue(REPORT::"Purchase - Quote");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageCaptureHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

