codeunit 138905 "O365 Combined Sales Doc. Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Sales Document]
    end;

    var
        FindParamTxt: Label '=><';
        Assert: Codeunit Assert;
        CustomerNotFoundErr: Label 'Customer %1 cannot be found.\\To send the invoice, you must recreate the customer.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UnexpectedDocumentOpenedTxt: Label 'Unexpected document is opened';
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindFirstDraftInvoice()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        // Verify
        Assert.AreEqual(O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'Document is not an invoice');
        Assert.AreEqual(false, O365SalesDocument.Posted, 'Invoice is not a draft');

        SetSalesHeaderKey(SalesHeader);
        SalesHeader.Find(FindParamTxt);

        Assert.AreEqual(SalesHeader."No.", O365SalesDocument."No.", 'Draft invoice is not the first one');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindFirstSentInvoice()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        SalesHeader.DeleteAll; // remove drafts

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        // Verify
        Assert.AreEqual(O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'Document is not an invoice');
        Assert.AreEqual(true, O365SalesDocument.Posted, 'Invoice is not posted');

        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);
        SalesInvoiceHeader.FindFirst;
        Assert.AreEqual(SalesInvoiceHeader."No.", O365SalesDocument."No.", 'Posted invoice is not the first one');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindExistingDraftInvoice()
    var
        TargetSalesHeader: Record "Sales Header";
        O365SalesDocument: Record "O365 Sales Document";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        TargetSalesHeader.Get(TargetSalesHeader."Document Type"::Invoice, CreateDraftInvoice);

        ApplySalesHeaderKeysToDocument(O365SalesDocument, TargetSalesHeader);

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        // Verify
        Assert.AreEqual(TargetSalesHeader."No.", O365SalesDocument."No.", 'Found a different record');
        Assert.AreEqual(TargetSalesHeader."Document Date", O365SalesDocument."Document Date", 'Invoice data was not transferred');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindExistingSentInvoice()
    var
        TargetSalesInvoiceHeader: Record "Sales Invoice Header";
        O365SalesDocument: Record "O365 Sales Document";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        TargetSalesInvoiceHeader.Get(CreateSentInvoice);

        ApplySalesInvoiceHeaderKeysToDocument(O365SalesDocument, TargetSalesInvoiceHeader);

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        // Verify
        Assert.AreEqual(TargetSalesInvoiceHeader."No.", O365SalesDocument."No.", 'Found a different record');
        Assert.AreEqual(TargetSalesInvoiceHeader."Document Date", O365SalesDocument."Document Date", 'Invoice data was not transferred');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindNearestDraftInvoice()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        // Remove the sales header
        SalesHeader.Get(O365SalesDocument."Document Type", O365SalesDocument."No.");
        SalesHeader.Delete;

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find another document');

        // Verify
        Assert.AreEqual(O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'Document is not an invoice');
        Assert.AreEqual(false, O365SalesDocument.Posted, 'Invoice is not a draft');
        Assert.AreNotEqual(SalesHeader."No.", O365SalesDocument."No.", 'Found document did not change');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindNearestDraftInvoiceNoDrafts()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
        SalesHeader.DeleteAll;

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find another document');

        // Verify
        Assert.AreEqual(O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'Document is not an invoice');
        Assert.AreEqual(true, O365SalesDocument.Posted, 'Invoice is a draft');

        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);
        SalesInvoiceHeader.FindFirst;
        Assert.AreEqual(SalesInvoiceHeader."No.", O365SalesDocument."No.", 'Found document is not expected document');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindNearestDraftInvoiceNoInvoice()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
        SalesHeader.DeleteAll;
        SalesInvoiceHeader.DeleteAll;

        // Execute and Verify
        Assert.IsFalse(O365SalesDocument.OnFind(FindParamTxt), 'A document was found when none exist');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindNearestDraftInvoiceAnotherDraft()
    var
        TargetSalesHeader: Record "Sales Header";
        O365SalesDocument: Record "O365 Sales Document";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        TargetSalesHeader.Get(TargetSalesHeader."Document Type"::Invoice, CreateDraftInvoice);

        ApplySalesHeaderKeysToDocument(O365SalesDocument, TargetSalesHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        TargetSalesHeader.Delete;

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find another document');

        // Verify
        Assert.AreNotEqual(TargetSalesHeader."No.", O365SalesDocument."No.", 'Could not find a different record');
        Assert.IsFalse(O365SalesDocument.Posted, 'Invoice should be a draft');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure FindNearestSentInvoiceAnotherSent()
    var
        O365SalesDocument: Record "O365 Sales Document";
        TargetSalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        TargetSalesInvoiceHeader.Get(CreateSentInvoice);

        ApplySalesInvoiceHeaderKeysToDocument(O365SalesDocument, TargetSalesInvoiceHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        TargetSalesInvoiceHeader.Delete;

        // Execute
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find another document');

        // Verify
        Assert.AreNotEqual(TargetSalesInvoiceHeader."No.", O365SalesDocument."No.", 'Could not find a different record');
        Assert.IsTrue(O365SalesDocument.Posted, 'Invoice should be sent');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceNoInvoice()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');

        SalesHeader.DeleteAll;
        SalesInvoiceHeader.DeleteAll;

        // Execute and verify
        Assert.AreEqual(0, O365SalesDocument.OnNext(1), 'Expected no more invoices');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceCurrentDraftNextDraft()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetFirstDraftDocument(SalesHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(1, O365SalesDocument.OnNext(1), 'Expected to move 1 invoice');

        // Verify
        SalesHeader.Next(1); // get 2nd invoice

        Assert.AreEqual(SalesHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsFalse(O365SalesDocument.Posted, 'The invoice should be a draft');
        Assert.AreEqual(SalesHeader."Document Type", O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceCurrentDraftNextSent()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetLastDraftDocument(SalesHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(1, O365SalesDocument.OnNext(1), 'Expected to move 1 invoice');

        // Verify
        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);
        SalesInvoiceHeader.FindFirst;

        Assert.AreEqual(SalesInvoiceHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsTrue(O365SalesDocument.Posted, 'The invoice should be sent');
        Assert.AreEqual(
          O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceCurrentSentNextSent()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetFirstSentDocument(SalesInvoiceHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(1, O365SalesDocument.OnNext(1), 'Expected to move 1 invoice');

        // Verify
        SalesInvoiceHeader.Next(1);
        Assert.AreEqual(SalesInvoiceHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsTrue(O365SalesDocument.Posted, 'The invoice should be sent');
        Assert.AreEqual(
          O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceCurrentDraftNextNone()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetLastDraftDocument(SalesHeader, O365SalesDocument);

        SalesInvoiceHeader.DeleteAll;

        // Execute and verify
        Assert.AreEqual(0, O365SalesDocument.OnNext(1), 'There should be no more invoices');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetNextInvoiceCurrentSentNextNone()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetLastSentDocument(SalesInvoiceHeader, O365SalesDocument);

        // Execute and verify
        Assert.AreEqual(0, O365SalesDocument.OnNext(1), 'There should be no more invoices');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetPreviousInvoiceCurrentDraftNextNone()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetFirstDraftDocument(SalesHeader, O365SalesDocument);

        SalesInvoiceHeader.DeleteAll;

        // Execute and verify
        Assert.AreEqual(0, O365SalesDocument.OnNext(-1), 'There should be no more invoices');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetPreviousInvoiceCurrentSentNextNone()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetFirstSentDocument(SalesInvoiceHeader, O365SalesDocument);

        SalesHeader.DeleteAll;

        // Execute and verify
        Assert.AreEqual(0, O365SalesDocument.OnNext(-1), 'There should be no more invoices');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetPreviousInvoiceCurrentDraftNextDraft()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetLastDraftDocument(SalesHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(-1, O365SalesDocument.OnNext(-1), 'Expected to move 1 invoice');

        // Verify
        SalesHeader.Next(-1); // get 2nd invoice

        Assert.AreEqual(SalesHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsFalse(O365SalesDocument.Posted, 'The invoice should be a draft');
        Assert.AreEqual(SalesHeader."Document Type", O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetPreviousInvoiceCurrentSentNextDraft()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetFirstSentDocument(SalesInvoiceHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(-1, O365SalesDocument.OnNext(-1), 'There should be no more invoices');

        // Verify
        SetSalesHeaderKey(SalesHeader);
        SalesHeader.FindLast;

        Assert.AreEqual(SalesHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsFalse(O365SalesDocument.Posted, 'The invoice should be a draft');
        Assert.AreEqual(SalesHeader."Document Type", O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure GetPreviousInvoiceCurrentSentNextSent()
    var
        O365SalesDocument: Record "O365 Sales Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        GetLastSentDocument(SalesInvoiceHeader, O365SalesDocument);

        // Execute
        Assert.AreEqual(-1, O365SalesDocument.OnNext(-1), 'There should be no more invoices');

        // Verify
        SalesInvoiceHeader.Next(-1); // get 2nd invoice

        Assert.AreEqual(SalesInvoiceHeader."No.", O365SalesDocument."No.", 'Not the correct invoice');
        Assert.IsTrue(O365SalesDocument.Posted, 'The invoice should be a draft');
        Assert.AreEqual(
          O365SalesDocument."Document Type"::Invoice, O365SalesDocument."Document Type", 'The document should be an invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DeletedCustomerThrowsError()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        SalesInvoiceNo: Code[20];
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        SalesInvoiceNo := CreateDraftInvoice;
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceNo);
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // Execute
        Customer.Delete;
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);
        asserterror O365SalesInvoice.Post.Invoke;

        // Verify
        Assert.ExpectedError(StrSubstNo(CustomerNotFoundErr, SalesHeader."Sell-to Customer No."));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DeletedCustomerThrowsErrorInWeb()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        SalesInvoiceNo: Code[20];
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        SalesInvoiceNo := CreateDraftInvoice;
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceNo);
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // Execute
        Customer.Delete;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        asserterror BCO365SalesInvoice.Post.Invoke;

        // Verify
        Assert.ExpectedError(StrSubstNo(CustomerNotFoundErr, SalesHeader."Sell-to Customer No."));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365SalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure OpenDraftInvoice()
    var
        O365InvoicingSalesDocList: TestPage "O365 Invoicing Sales Doc. List";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 197381] O365 Sales Document page opened for draft invoice from O365 Invoicing Sales Doc. List
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Draft (not posted) sales invoice INV
        InvoiceNo := CreateDraftInvoice;

        // [GIVEN] Invoice INV displayed in the O365 Invoicing Sales Doc. List page
        O365InvoicingSalesDocList.OpenView;
        O365InvoicingSalesDocList.FILTER.SetFilter("No.", InvoiceNo);
        O365InvoicingSalesDocList.FILTER.SetFilter(Posted, Format(false));

        // [WHEN] Action Open is beging invoked
        // [THEN] O365 Sales Document page opened with invoice INV
        // Verification is done in the O365SalesInvoiceHandler
        LibraryVariableStorage.Enqueue(InvoiceNo);
        O365InvoicingSalesDocList.Open.Invoke;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365PostedSalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure OpenSentInvoice()
    var
        O365InvoicingSalesDocList: TestPage "O365 Invoicing Sales Doc. List";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 197381] O365 Posted Sales Document page opened for sent invoice from O365 Invoicing Sales Doc. List
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent (posted) sales invoice INV
        InvoiceNo := CreateSentInvoice;

        // [GIVEN] Invoice INV displayed in the O365 Invoicing Sales Doc. List page
        O365InvoicingSalesDocList.OpenView;
        O365InvoicingSalesDocList.FILTER.SetFilter("No.", InvoiceNo);
        O365InvoicingSalesDocList.FILTER.SetFilter(Posted, Format(false));

        // [WHEN] Action Open is beging invoked
        // [THEN] O365 Posted Sales Document page opened with invoice INV
        // Verification is done in the O365PostedSalesInvoiceHandler
        LibraryVariableStorage.Enqueue(InvoiceNo);
        O365InvoicingSalesDocList.Open.Invoke;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365CustomerSalesDocumentsHandler')]
    [Scope('OnPrem')]
    procedure DrillDownDraftInvoicesFromCustFactBox()
    var
        SalesHeader: Record "Sales Header";
        O365CustomerLookup: TestPage "O365 Customer Lookup";
    begin
        // [SCENARIO 197381] O365 Customer Sales Documents page opened for draft invoices field from O365 Sales Hist.Sell-toFactBox
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Draft sales invoice INV
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, CreateDraftInvoice);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] O365 Customer Lookup page opened with focus on invoice's customer
        OpenO365CustomerLookupAndSetCustomerFocus(O365CustomerLookup, SalesHeader."Sell-to Customer No.");

        // [WHEN] Drill down from No. of Invoices field is being invoked
        // [THEN] O365 Customer Sales Documents page opened with invoice INV
        // Verification is done in the O365CustomerSalesDocumentsHandler
        O365CustomerLookup.Control3."No. of Invoices".DrillDown;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365CustomerSalesDocumentsHandler')]
    [Scope('OnPrem')]
    procedure DrillDownSentInvoicesFromCustFactBox()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365CustomerLookup: TestPage "O365 Customer Lookup";
    begin
        // [SCENARIO 197381] O365 Posted Sales Document page opened for sent invoice from O365 Sales Hist.Sell-toFactBox
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent (posted) sales invoice INV
        SalesInvoiceHeader.Get(CreateSentInvoice);
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");

        // [GIVEN] O365 Customer Lookup page opened with focus on invoice's customer
        OpenO365CustomerLookupAndSetCustomerFocus(O365CustomerLookup, SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Drill down from No. of Invoices field is being invoked
        // [THEN] O365 Customer Sales Documents page opened with invoice INV
        // Verification is done in the O365CustomerSalesDocumentsHandler
        O365CustomerLookup.Control3."No. of Pstd. Invoices".DrillDown;
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        TotalInvoices: Integer;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Combined Sales Doc. Tests");

        LibraryVariableStorage.Clear;
        SalesHeader.DeleteAll;
        SalesInvoiceHeader.DeleteAll;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;

        for TotalInvoices := 1 to 3 do begin
            CreateDraftInvoice();
            CreateSentInvoice();
        end;

        EventSubscriberInvoicingApp.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"O365 Combined Sales Doc. Tests");

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"O365 Combined Sales Doc. Tests");
    end;

    local procedure CreateDraftInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSentInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibrarySales: Codeunit "Library - Sales";
        SalesPost: Codeunit "Sales-Post";
        InvoiceVariant: Variant;
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesPost.GetPostedDocumentRecord(SalesHeader, InvoiceVariant);
        SalesInvoiceHeader := InvoiceVariant;
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure SetSalesHeaderKey(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetCurrentKey("Document Date", "No.");
        SalesHeader.SetAscending("No.", false);
        SalesHeader.SetAscending("Document Date", false);
        SalesHeader.SetFilter(
          "Document Type", StrSubstNo('%1|%2', SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Quote));
    end;

    local procedure SetSalesInvoiceHeaderKey(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetCurrentKey("Document Date", "Due Date", "No.");
        SalesInvoiceHeader.SetAscending("Due Date", false);
        SalesInvoiceHeader.SetAscending("Document Date", false);
        SalesInvoiceHeader.SetAscending("No.", false);
    end;

    local procedure ApplySalesHeaderKeysToDocument(var O365SalesDocument: Record "O365 Sales Document"; SalesHeader: Record "Sales Header")
    begin
        O365SalesDocument."Document Type" := O365SalesDocument."Document Type"::Invoice;
        O365SalesDocument."No." := SalesHeader."No.";
        O365SalesDocument.Posted := false;
        O365SalesDocument."Document Date" := SalesHeader."Document Date";
    end;

    local procedure ApplySalesInvoiceHeaderKeysToDocument(var O365SalesDocument: Record "O365 Sales Document"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        O365SalesDocument."Document Type" := O365SalesDocument."Document Type"::Invoice;
        O365SalesDocument."No." := SalesInvoiceHeader."No.";
        O365SalesDocument.Posted := true;
        O365SalesDocument."Document Date" := SalesInvoiceHeader."Document Date";
        O365SalesDocument."Due Date" := SalesInvoiceHeader."Due Date";
    end;

    local procedure GetFirstDraftDocument(var SalesHeader: Record "Sales Header"; var O365SalesDocument: Record "O365 Sales Document")
    begin
        SetSalesHeaderKey(SalesHeader);
        SalesHeader.FindFirst;

        ApplySalesHeaderKeysToDocument(O365SalesDocument, SalesHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
    end;

    local procedure GetLastDraftDocument(var SalesHeader: Record "Sales Header"; var O365SalesDocument: Record "O365 Sales Document")
    begin
        SetSalesHeaderKey(SalesHeader);
        SalesHeader.FindLast;

        ApplySalesHeaderKeysToDocument(O365SalesDocument, SalesHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
    end;

    local procedure GetFirstSentDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var O365SalesDocument: Record "O365 Sales Document")
    begin
        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);
        SalesInvoiceHeader.FindFirst;

        ApplySalesInvoiceHeaderKeysToDocument(O365SalesDocument, SalesInvoiceHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
    end;

    local procedure GetLastSentDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var O365SalesDocument: Record "O365 Sales Document")
    begin
        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);
        SalesInvoiceHeader.FindLast;

        ApplySalesInvoiceHeaderKeysToDocument(O365SalesDocument, SalesInvoiceHeader);
        Assert.IsTrue(O365SalesDocument.OnFind(FindParamTxt), 'Could not find a document');
    end;

    local procedure OpenO365CustomerLookupAndSetCustomerFocus(var O365CustomerLookup: TestPage "O365 Customer Lookup"; CustomerNo: Code[20])
    begin
        O365CustomerLookup.OpenView;
        O365CustomerLookup.FILTER.SetFilter("No.", CustomerNo);
        O365CustomerLookup.First;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure O365SalesInvoiceHandler(var BCO365SalesInvoice: Page "BC O365 Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        BCO365SalesInvoice.GetRecord(SalesHeader);
        Assert.AreEqual(LibraryVariableStorage.DequeueText, SalesHeader."No.", UnexpectedDocumentOpenedTxt);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure O365PostedSalesInvoiceHandler(var BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, BCO365PostedSalesInvoice."No.".Value, UnexpectedDocumentOpenedTxt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365CustomerSalesDocumentsHandler(var O365CustomerSalesDocuments: TestPage "O365 Customer Sales Documents")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, O365CustomerSalesDocuments."No.".Value, UnexpectedDocumentOpenedTxt);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

