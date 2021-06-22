codeunit 134892 "Purch. Batch Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
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
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected invoice from Purchase Invoices page
        Initialize;

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Purchase Invoices page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Invoices "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        PurchaseInvoices.Trap;
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        InvokePostSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        VerifyInvoicePosted(PurchaseHeader[2]);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedCreditMemo()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected credit memo from Purchase Credit Memos page
        Initialize;

        // [GIVEN] Credit Memos "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Purchase Credit Memos page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Credit Memos "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        PurchaseCreditMemos.Trap;
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        InvokePostSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchCrMemoHdr, 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected order from Purchase Order List page
        Initialize;

        // [GIVEN] Orders "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        PurchaseOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        InvokePostSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 1);
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchRcptHeader, 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedReturnOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected return order from Purchase Reutrn Order List page
        Initialize;

        // [GIVEN] Return orders "X", "Y" and "Z" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Purchase Return Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Return orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        PurchaseReturnOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        InvokePostSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(ReturnShipmentHeader, 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePostBatchMgtRunWithUIPostsFilteredOutRecords()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderCreated: Record "Purchase Header";
        PurchaseHeaderToPost: Record "Purchase Header";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO] Cassie can post selected only invoices
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects "X" and "Y" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X" and "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] "Z" remains unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderCreated, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        MarkDocumentsToPost(PurchaseHeaderToPost, PurchaseHeader, PurchaseHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);
        PurchaseBatchPostMgt.RunWithUI(PurchaseHeaderToPost, PurchaseHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        VerifyInvoicePosted(PurchaseHeader[1]);
        VerifyInvoicePosted(PurchaseHeader[2]);
        VerifyInvoiceUnposted(PurchaseHeader[3]);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedInvoice()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Invoices page
        Initialize;

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects invoice "Y" on Purchase Invoices page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Invoices "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, 0);

        PurchaseInvoices.Trap;
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap;
        InvokePostSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedCreditMemo()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Credit Memos page
        Initialize;

        // [GIVEN] Credit Memos "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects credit memo "Y" on Purchase Credit Memos page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Credit memos "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", 0);

        PurchaseCreditMemos.Trap;
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap;
        InvokePostSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Order List page
        Initialize;

        // [GIVEN] Orders "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, 0);

        PurchaseOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        ErrorMessagesPage.Trap;
        InvokePostSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedReturnOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Return Order List page
        Initialize;

        // [GIVEN] Return orders "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Purchase Return Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Return orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", 0);

        PurchaseReturnOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        ErrorMessagesPage.Trap;
        InvokePostSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(PostingErrorMsg);
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Batch Document Posting");
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Batch Document Posting");

        LibraryPurchase.SetReturnOrderNoSeriesInSetup;
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryApplicationArea.DisableApplicationAreaSetup;

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Batch Document Posting");
    end;

    local procedure CreateThreeDocuments(var PurchaseHeader: array[3] of Record "Purchase Header"; var PurchaseHeaderUI: Record "Purchase Header"; DocumentType: Option; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchaseHeader) do
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeader[Index], PurchaseLine, DocumentType, LibraryPurchase.CreateVendorNo, '', Quantity, '', 0D);

        PurchaseHeaderUI.SetFilter("No.", '%1|%2|%3', PurchaseHeader[1]."No.", PurchaseHeader[2]."No.", PurchaseHeader[3]."No.");
        PurchaseHeaderUI.SetRange("Document Type", DocumentType);
    end;

    local procedure InvokePostSelectedInvoices(var PurchaseInvoices: TestPage "Purchase Invoices"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseInvoices.GotoRecord(PurchaseHeaderToPost);
        PurchaseInvoices.PostSelected.Invoke;
    end;

    local procedure InvokePostSelectedCreditMemos(var PurchaseCreditMemos: TestPage "Purchase Credit Memos"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseCreditMemos.GotoRecord(PurchaseHeaderToPost);
        PurchaseCreditMemos.Post.Invoke;
    end;

    local procedure InvokePostSelectedOrders(var PurchaseOrderList: TestPage "Purchase Order List"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseOrderList.GotoRecord(PurchaseHeaderToPost);
        PurchaseOrderList.Post.Invoke;
    end;

    local procedure InvokePostSelectedReturnOrders(var PurchaseReturnOrderList: TestPage "Purchase Return Order List"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseReturnOrderList.GotoRecord(PurchaseHeaderToPost);
        PurchaseReturnOrderList.Post.Invoke;
    end;

    local procedure MarkDocumentsToPost(var PurchaseHeaderToPost: Record "Purchase Header"; var PurchaseHeader: array[3] of Record "Purchase Header"; var PurchaseHeaderCreated: Record "Purchase Header")
    begin
        PurchaseHeaderToPost.CopyFilters(PurchaseHeaderCreated);
        PurchaseHeaderToPost.Get(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.");
        PurchaseHeaderToPost.Mark(true);
        PurchaseHeaderToPost.Get(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");
        PurchaseHeaderToPost.Mark(true);
        // to be sure the only filtered documents are posted
        PurchaseHeaderToPost.Get(PurchaseHeader[3]."Document Type", PurchaseHeader[3]."No.");
        PurchaseHeaderToPost.MarkedOnly(true);
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

    local procedure VerifyTwoOfThreeDocumentsUnposted(var PurchaseHeaderUI: Record "Purchase Header"; var PurchaseHeader: array[3] of Record "Purchase Header")
    begin
        Assert.RecordCount(PurchaseHeaderUI, ArrayLen(PurchaseHeader) - 1);
        PurchaseHeaderUI.FindFirst;
        PurchaseHeaderUI.TestField("No.", PurchaseHeader[1]."No.");
        PurchaseHeaderUI.Next;
        PurchaseHeaderUI.TestField("No.", PurchaseHeader[3]."No.");
    end;

    local procedure VerifyInvoicePosted(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 1);
        Assert.IsFalse(PurchaseHeader.Find, '');
    end;

    local procedure VerifyInvoiceUnposted(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 0);
        Assert.IsTrue(PurchaseHeader.Find, '');
    end;
}

