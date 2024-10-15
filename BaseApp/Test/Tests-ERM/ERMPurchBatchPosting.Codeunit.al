codeunit 134337 "ERM Purch. Batch Posting"
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Batch Post] [Purchase]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageCounter: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BatchCompletedMsg: Label 'All the documents were processed.';
        NotificationMsg: Label 'An error or warning occured during operation Batch processing of Purchase Header records.';

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceDiffPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", CalcDate('<1D>', WorkDate), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", CalcDate('<1D>', WorkDate), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDiscAndReplacePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 204056] Batch Posting of Purchase Invoice with Replace Posting Date and Calc. Inv. Discount options for special Purchase Setup
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Purchase Setup has "Posted Invoice Nos." = "Invoice Nos." and "Receipt on Invoice" = No
        UpdateReceiptOnInvoiceOnPurchasePayablesSetup;

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Run Batch Post Purchase Invoice with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        VerifyPostedPurchaseInvoice(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Credit Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemoDiffPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", CalcDate('<1D>', WorkDate), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", CalcDate('<1D>', WorkDate), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemoCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", true);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Credit Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        VerifyPostedPurchaseCrMemo(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification;

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseInvoice(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemosWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release cr. memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode);

        // Create Purchase Cr. Memo.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Cr. Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification;

        // Verify that Posted Purchase Cr. Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseCrMemo(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode);

        // Create Purchase Order.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Order, false);

        // Batch Post Purchase Order.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification;

        // Verify that Posted Purchase Order Exists.
        VerifyPostedPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseOrder(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseReturnOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseReturnOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release return order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode);

        // Create Purchase return order.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", false);

        // Batch Post Purchase return order.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification;

        // Verify that Posted Purchase return order Exists.
        VerifyPostedPurchaseReturnOrder(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseReturnOrder(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrderWithInvoiceDiscountAndJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Index: Integer;
    begin
        // [FEATURE] [Order] [Job  Queue] [Invoice Discount]
        // [SCENARIO 268223] Stan can post multiple orders in a batch when "Calc. Invoice Discount" and "Post with Job Queue" are enabled in setup
        Initialize;

        // [GIVEN] Purchase setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear;
        LibraryWorkflow.DisableAllWorkflows;
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(PurchaseHeader) do
            CreatePurchaseDocument(PurchaseHeader[Index], PurchaseHeader[Index]."Document Type"::Order, true);

        // [WHEN] Post them via "Batch Post Purchase Orders" report
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, true);

        // [THEN] Two Job Queue Entries created and their ID stored in orders
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchaseHeader[Index].Get(PurchaseHeader[Index]."Document Type", PurchaseHeader[Index]."No.");
            PurchaseHeader[Index].TestField("Job Queue Entry ID");
        end;

        // [THEN] Messages of Job Queue Entry creation have been omitted
        Assert.ExpectedMessage(Format(BatchCompletedMsg), LibraryVariableStorageCounter.DequeueText);
        LibraryVariableStorageCounter.AssertEmpty;

        // [THEN] Invoices has been posted after queues execution
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            RunJobQueueFromPurchaseHeader(PurchaseHeader[Index]);
            VerifyPostedPurchaseInvoiceByOrderNo(PurchaseHeader[Index]."No.", PurchaseHeader[Index]."Posting Date", true);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostRetryPurchaseOrderWithJobQueueAndZeroQuantity()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ErrorMessages: TestPage "Error Messages";
        Index: Integer;
        NullGUID: Guid;
    begin
        // [FEATURE] [Order] [Job  Queue]
        // [SCENARIO 275869] Stan can try post with job queue multiple time bad orders without error 'Batch Processing Parameter Map already exists.'
        Initialize;

        // [GIVEN] Purchase setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear;
        LibraryWorkflow.DisableAllWorkflows;
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(PurchaseHeader) do
            CreatePurchaseDocumentWithQuantity(
              PurchaseHeader[Index], PurchaseHeader[Index]."Document Type"::Order, false, 0);

        // [WHEN] Post two times them via "Batch Post Sales Orders" report

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        // [THEN] Click on 'Details' action: opened "Error Messages" page with list of bad documents each time
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            ErrorMessages.Trap;
            RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, true);

            VerifyPurchHeaderNotification;
            LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseHeader[1].RecordId);
            // Bug: 306600
            ErrorMessages.Source.AssertEquals(Format(PurchaseHeader[1].RecordId));
            ErrorMessages.Next;
            ErrorMessages.Source.AssertEquals(Format(PurchaseHeader[2].RecordId));
            ErrorMessages.Close;
        end;

        // [THEN] Job Queue Entries are not created.
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchaseHeader[Index].Get(PurchaseHeader[Index]."Document Type", PurchaseHeader[Index]."No.");
            PurchaseHeader[Index].TestField("Job Queue Entry ID", NullGUID);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceWithConcurrentBatch()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        BatchID: array[2] of Guid;
        BatchSessionID: array[2] of Integer;
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 306600] Stan can run "Batch Post Purchase Invoices" report when concurrent batch is active having the same document
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        BatchSessionID[1] := SessionId;
        BatchSessionID[2] := SessionId - 1;

        PostingDate[1] := WorkDate - 1;
        PostingDate[2] := WorkDate;

        BatchID[1] := CreateGuid;
        BatchID[2] := CreateGuid;

        // [GIVEN] Purchase invoice "I" to be posted via batch
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // [GIVEN] Batch "B[1]" processing "I". Batch is lost in current session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          PurchaseHeader, BatchPostParameterTypes.PostingDate, PostingDate[1], BatchSessionID[1], BatchID[1]);

        // [GIVEN] Batch "B[2]" processing "I". Batch is live in other session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          PurchaseHeader, BatchPostParameterTypes.PostingDate, PostingDate[1], BatchSessionID[2], BatchID[2]);

        // [WHEN] Stan run "Batch Post Purchase Invoices" report with "Replace Posting Date" = TRUE and "Posting Date" = March 2nd, 2019 and "I" in filter
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PostingDate[2], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] "I" is posted with "Posting Date" = March 2nd, 2019.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PostingDate[2], false);

        // [THEN] "B[1]" removed
        VerifyBatchParametersDoNoExist(BatchID[1]);

        // [THEN] "B[2]" remains unchanged
        VerifyBatchParametersExist(BatchID[2]);

        // [THEN] "Batch Processing Parameter" table empty after cleaning B[2]
        BatchProcessingParameter.SetRange("Batch ID", BatchID[2]);
        BatchProcessingParameter.DeleteAll;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostAndPrintWithJobQueuePurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibraryPurchase.SetPostWithJobQueue(false);
        LibraryPurchase.SetPostAndPrintWithJobQueue(false);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        PurchasesPayablesSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        Assert.IsTrue(PurchasesPayablesSetup."Post with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueuePurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibraryPurchase.SetPostWithJobQueue(true);
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        PurchasesPayablesSetup.Validate("Post with Job Queue", false);
        // [THEN] "Post & Print with Job Queue" = FALSE
        Assert.IsFalse(PurchasesPayablesSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSPurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        ASSERTERROR PurchasesPayablesSetup.Validate("Report Output Type", PurchasesPayablesSetup."Report Output Type"::Print);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedError('Report Output Type must be equal to ''PDF''  in Purchases & Payables Setup');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostPurchaseInvoices()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Purchase - Invoice" when batch post purchase invoices
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateInvoiceReportSelection();

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, FALSE);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, FALSE);

        // [WHEN] Batch post two invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostPurchase(
          PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, FALSE);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        // [THEN] There are two records in the "Job Queue Entry" with "PDF" output type
        VerifyPrintJobQueueEntries(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDiscAndReplacePostingDateJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 316670] Batch Posting of Purchase Invoice with "Replace Posting Date", "Calc. Inv. Discount" and "backgroud posting" in Purchase Setup
        Initialize;

        // [GIVEN] Purchase Setup has "Posted Invoice Nos." = "Invoice Nos." and "Receipt on Invoice" = No
        UpdateReceiptOnInvoiceOnPurchasePayablesSetup;

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" enabled in Purchase setup
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, true);
        PostingDate[1] := PurchaseHeader[1]."Posting Date";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[1]);

        // [GIVEN] "Batch Post Purchase Invoice" ran with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.", PostingDate[1] + 1, true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" disabled in Purchase setup
        LibraryPurchase.SetPostAndPrintWithJobQueue(false);
        LibraryPurchase.SetPostWithJobQueue(false);

        // [GIVEN] Released Purchase Invoice "B" and post via Batch Postig without background job
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, true);
        PostingDate[2] := PurchaseHeader[2]."Posting Date";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[2]);
        PurchaseHeader[2].SetRecFilter;
        PurchaseBatchPostMgt.RunBatch(PurchaseHeader[2], true, PostingDate[2] + 2, true, true, false, true);
        //LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        // [WHEN] Job queue for Invoice "A" ran
        PurchaseHeader[1].Find;
        JobQueueEntry.Get(PurchaseHeader[1]."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        PurchaseHeader[2].Find;
        JobQueueEntry.Get(PurchaseHeader[2]."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoices "A"
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PostingDate[1] + 1, true);
        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoice "B"
        VerifyPostedPurchaseInvoice(PurchaseHeader[2]."No.", PostingDate[2] + 2, true);

        // [THEN] Batch tables cleaned after job queue execution
        BatchProcessingSessionMap.SetRange("Record ID", PurchaseHeader[1].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);

        BatchProcessingSessionMap.SetRange("Record ID", PurchaseHeader[2].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch. Batch Posting");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch. Batch Posting");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Commit;
        isInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch. Batch Posting");
    end;

    local procedure CreateVendor(InvDisc: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if InvDisc then
            CreateVendorDiscount(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreateVendorDiscount(VendorNo: Code[20])
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.Init;
        VendInvDisc.Validate(Code, VendorNo);
        VendInvDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendInvDisc.Insert(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; InvDisc: Boolean)
    begin
        CreatePurchaseDocumentWithQuantity(PurchaseHeader, DocumentType, InvDisc, LibraryRandom.RandIntInRange(5, 10));
    end;

    local procedure CreatePurchaseDocumentWithQuantity(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; InvDisc: Boolean; DocQuantity: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(InvDisc));
        if DocumentType = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
            PurchaseHeader.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, DocQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure AddBatchProcessParameters(PurchaseHeader: Record "Purchase Header"; ParameterId: Integer; ParameterValue: Variant; BachSessionID: Integer; var BatchID: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.Init;
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId;
        BatchProcessingParameter."Parameter Value" := Format(ParameterValue);
        BatchProcessingParameter.Insert;

        BatchProcessingSessionMap."Record ID" := PurchaseHeader.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchProcessingParameter."Batch ID";
        BatchProcessingSessionMap."User ID" := UserSecurityId;
        BatchProcessingSessionMap."Session ID" := BachSessionID;
        BatchProcessingSessionMap.Insert;
    end;

    local procedure RunBatchPostPurchase(DocumentType: Option; DocumentNoFilter: Text; PostingDate: Date; CalcInvDisc: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        UpdateCalcInvDiscPurchasePayablesSetup(CalcInvDisc);
        LibraryVariableStorage.Enqueue(DocumentNoFilter);
        LibraryVariableStorage.Enqueue(PostingDate);

        Commit;
        case DocumentType of
            PurchaseHeader."Document Type"::Invoice:
                REPORT.RunModal(REPORT::"Batch Post Purchase Invoices", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::"Credit Memo":
                REPORT.RunModal(REPORT::"Batch Post Purch. Credit Memos", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::Order:
                REPORT.RunModal(REPORT::"Batch Post Purchase Orders", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::"Return Order":
                REPORT.RunModal(REPORT::"Batch Post Purch. Ret. Orders", true, true, PurchaseHeader);
        end;
    end;

    local procedure RunJobQueueFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(PurchaseHeader."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);
    end;

    local procedure UpdateCalcInvDiscPurchasePayablesSetup(CalcInvDisc: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDisc);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateReceiptOnInvoiceOnPurchasePayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", PurchasesPayablesSetup."Invoice Nos.");
        PurchasesPayablesSetup."Receipt on Invoice" := false;
        PurchasesPayablesSetup.Modify;
    end;

    local procedure CreateInvoiceReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"P.Invoice";
        ReportSelections."Report ID" := REPORT::"Purchase - Invoice";
        If ReportSelections.Insert() Then;
    end;

    local procedure VerifyPostedPurchaseInvoice(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst;
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst;
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseInvoiceByOrderNo(OrderNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst;
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvHeader.TestField("Document Date", PostingDate);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst;
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseCrMemo(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst;
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst;
        Assert.AreEqual(InvDisc, PurchCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", PreAssignedNo);
        PurchInvHeader.FindFirst;
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst;
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseReturnOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst;
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst;
        Assert.AreEqual(InvDisc, PurchCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyBatchParametersExist(BatchId: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.SetRange("Batch ID", BatchId);
        Assert.RecordIsNotEmpty(BatchProcessingParameter);

        BatchProcessingSessionMap.SetRange("Batch ID", BatchId);
        Assert.RecordIsNotEmpty(BatchProcessingSessionMap);
    end;

    local procedure VerifyBatchParametersDoNoExist(BatchId: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.SetRange("Batch ID", BatchId);
        Assert.RecordIsEmpty(BatchProcessingParameter);

        BatchProcessingSessionMap.SetRange("Batch ID", BatchId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);
    end;

    local procedure VerifyPurchHeaderNotification()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.ExpectedMessage(NotificationMsg, LibraryVariableStorage.DequeueText); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty;
        Clear(PurchaseHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    local procedure VerifyPrintJobQueueEntries(var PurchaseHeader: array[2] of Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Purchase - Invoice");
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::PDF);

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader[1]."No.");
        PurchInvHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", PurchInvHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader[2]."No.");
        PurchInvHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", PurchInvHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseInvoices(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        RunReplacePostingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseInvoices."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseInvoices."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));

        BatchPostPurchaseInvoices.PostingDate.SetValue(PostingDate);
        RunReplacePostingDate := Format(PostingDate) <> '';
        BatchPostPurchaseInvoices.ReplacePostingDate.SetValue(RunReplacePostingDate);
        BatchPostPurchaseInvoices.ReplaceDocumentDate.SetValue(RunReplacePostingDate);
        // CalcInvDiscount is set from Purchase Setup
        BatchPostPurchaseInvoices.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseCrMemos(var BatchPostPurchaseCrMemos: TestRequestPage "Batch Post Purch. Credit Memos")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseCrMemos."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseCrMemos."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Credit Memo"));

        BatchPostPurchaseCrMemos.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchaseCrMemos.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchaseCrMemos.ReplacePostingDate.SetValue(false);
        // CalcInvDiscount is set from Purchase Setup
        BatchPostPurchaseCrMemos.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseOrders(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseOrders."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseOrders."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Order));

        BatchPostPurchaseOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchaseOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchaseOrders.ReplacePostingDate.SetValue(false);
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseReturnOrders(var BatchPostPurchRetOrders: TestRequestPage "Batch Post Purch. Ret. Orders")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchRetOrders."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchRetOrders."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Return Order"));

        BatchPostPurchRetOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchRetOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchRetOrders.ReplacePostingDate.SetValue(false);
        BatchPostPurchRetOrders.Ship.SetValue(true);
        BatchPostPurchRetOrders.Invoice.SetValue(true);
        BatchPostPurchRetOrders.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesPrintRequestPageHandler(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices");
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    BEGIN
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseInvoices."Purchase Header".SETFILTER("No.", DocumentNoFilter);
        BatchPostPurchaseInvoices."Purchase Header".SETFILTER("Document Type", FORMAT(PurchaseHeader."Document Type"::Invoice));

        BatchPostPurchaseInvoices.PrintDoc.SETVALUE(TRUE);
        BatchPostPurchaseInvoices.OK.INVOKE;

        LibraryVariableStorage.Enqueue(0); // initialize report run counter
    END;

    [ReportHandler]
    [Scope('OnPrem')]
    PROCEDURE PurchaseInvoiceReportHandler(var PurchaseInvoice: Report "Purchase - Invoice");
    BEGIN
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger + 1);
    END;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CountingMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorageCounter.Enqueue(Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowErrorsNotificationHandler(var Notification: Notification): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        ErrorMessageMgt.ShowErrors(Notification); // simulate a click on notification's action
    end;
}

