codeunit 134891 "Sales Batch Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ReadyToPostInvoicesTemplateTok: Label '%1 out of %2 selected invoices are ready for post. \Do you want to continue and post them?';
        ReadyToPostTwoInvoicesQst: Label '2 out of 3 selected invoices are ready for post. \Do you want to continue and post them?';
        LibraryRandom: Codeunit "Library - Random";
        BatchCompletedMsg: Label 'All the documents were processed.';
        PostingErrorMsg: Label 'There is nothing to post.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        DoYouWantToPostQst: Label 'Do you want to post the %1?';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedInvoice()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Cassie can post selected invoice from Sales Invoice List page
        Initialize;

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Sales Invoice List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Invoices "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        SalesInvoiceList.Trap;
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        InvokePostSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        VerifyInvoicePosted(SalesHeader[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedCreditMemo()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Cassie can post selected credit memo from Sales Credit Memos page
        Initialize;

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Sales Credit Memos page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Credit Memos "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        SalesCreditMemos.Trap;
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        InvokePostSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesCrMemoHeader, 1);
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Cassie can post selected order from Sales Order List page
        Initialize;

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        SalesOrderList.Trap;
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        InvokePostSelectedOrders(SalesOrderList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesShipmentHeader, 1);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedReturnOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO] Cassie can post selected return order from Sales Return Order List page
        Initialize;

        // [GIVEN] Return orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Sales Return Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Return orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        SalesReturnOrderList.Trap;
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        InvokePostSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(ReturnReceiptHeader, 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesPostBatchMgtRunWithUIPostsFilteredOutRecords()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderCreated: Record "Sales Header";
        SalesHeaderToPost: Record "Sales Header";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO] Cassie can post selected only invoices
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "X" and "Y" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X" and "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] "Z" remains unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderCreated, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        MarkDocumentsToPost(SalesHeaderToPost, SalesHeader, SalesHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);
        SalesBatchPostMgt.RunWithUI(SalesHeaderToPost, SalesHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[2].RecordId);

        VerifyInvoicePosted(SalesHeader[1]);
        VerifyInvoicePosted(SalesHeader[2]);
        VerifyInvoiceUnposted(SalesHeader[3]);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedInvoice()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Invoice List page
        Initialize;

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects invoice "Y" on Sales Invocie List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Invoices "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, 0);

        SalesInvoiceList.Trap;
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap;
        InvokePostSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedCreditMemo()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Credit Memos page
        Initialize;

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects credit memo "Y" on Sales Credit Memos page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Credit memos "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", 0);

        SalesCreditMemos.Trap;
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap;
        InvokePostSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Order List page
        Initialize;

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, 0);

        SalesOrderList.Trap;
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        ErrorMessagesPage.Trap;
        InvokePostSelectedOrders(SalesOrderList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedReturnOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Return Order List page
        Initialize;

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects return order "Y" on Sales Return Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Return orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", 0);

        SalesReturnOrderList.Trap;
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        ErrorMessagesPage.Trap;
        InvokePostSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Batch Document Posting");
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Batch Document Posting");

        LibrarySales.SetReturnOrderNoSeriesInSetup;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryApplicationArea.DisableApplicationAreaSetup;

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Batch Document Posting");
    end;

    local procedure CreateThreeDocuments(var SalesHeader: array[3] of Record "Sales Header"; var SalesHeaderUI: Record "Sales Header"; DocumentType: Option; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[Index], SalesLine, DocumentType, LibrarySales.CreateCustomerNo, '', Quantity, '', 0D);
            SalesHeader[Index].CalcFields("Amount Including VAT");
        end;

        SalesHeaderUI.SetFilter("No.", '%1|%2|%3', SalesHeader[1]."No.", SalesHeader[2]."No.", SalesHeader[3]."No.");
        SalesHeaderUI.SetRange("Document Type", DocumentType);
    end;

    local procedure InvokePostSelectedInvoices(var SalesInvoiceList: TestPage "Sales Invoice List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesInvoiceList.GotoRecord(SalesHeaderToPost);
        SalesInvoiceList.Post.Invoke;
    end;

    local procedure InvokePostSelectedCreditMemos(var SalesCreditMemos: TestPage "Sales Credit Memos"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesCreditMemos.GotoRecord(SalesHeaderToPost);
        SalesCreditMemos.Post.Invoke;
    end;

    local procedure InvokePostSelectedOrders(var SalesOrderList: TestPage "Sales Order List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesOrderList.GotoRecord(SalesHeaderToPost);
        SalesOrderList.Post.Invoke;
    end;

    local procedure InvokePostSelectedReturnOrders(var SalesReturnOrderList: TestPage "Sales Return Order List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesReturnOrderList.GotoRecord(SalesHeaderToPost);
        SalesReturnOrderList.Post.Invoke;
    end;

    local procedure MarkDocumentsToPost(var SalesHeaderToPost: Record "Sales Header"; var SalesHeader: array[3] of Record "Sales Header"; var SalesHeaderCreated: Record "Sales Header")
    begin
        SalesHeaderToPost.CopyFilters(SalesHeaderCreated);
        SalesHeaderToPost.Get(SalesHeader[1]."Document Type", SalesHeader[1]."No.");
        SalesHeaderToPost.Mark(true);
        SalesHeaderToPost.Get(SalesHeader[2]."Document Type", SalesHeader[2]."No.");
        SalesHeaderToPost.Mark(true);
        // to be sure the only filtered documents are posted
        SalesHeaderToPost.Get(SalesHeader[3]."Document Type", SalesHeader[3]."No.");
        SalesHeaderToPost.MarkedOnly(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Question);
        Reply := true; // precal forces to set any value to VAR parameter
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, MessageText);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;

    local procedure VerifyTwoOfThreeDocumentsUnposted(var SalesHeaderUI: Record "Sales Header"; var SalesHeader: array[3] of Record "Sales Header")
    begin
        Assert.RecordCount(SalesHeaderUI, ArrayLen(SalesHeader) - 1);
        SalesHeaderUI.FindFirst;
        SalesHeaderUI.TestField("No.", SalesHeader[1]."No.");
        SalesHeaderUI.Next;
        SalesHeaderUI.TestField("No.", SalesHeader[3]."No.");
    end;

    local procedure VerifyInvoicePosted(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 1);
        Assert.IsFalse(SalesHeader.Find, '');
    end;

    local procedure VerifyInvoiceUnposted(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 0);
        Assert.IsTrue(SalesHeader.Find, '');
    end;
}

