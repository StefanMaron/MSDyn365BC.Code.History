codeunit 134391 "ERM Sales Batch Posting"
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Batch Post] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageCounter: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BatchCompletedMsg: Label 'All the documents were processed.';
        NotificationMsg: Label 'An error or warning occured during operation Batch processing of Sales Header records.';

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceDiffPostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", CalcDate('<1D>', WorkDate), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", CalcDate('<1D>', WorkDate), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDiscAndReplacePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 204056] Batch Posting of Sales Invoice with Replace Posting Date and Calc. Inv. Discount options for special Sales Setup
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Sales Setup has "Posted Invoice Nos." = "Invoice Nos." and "Shipment on Invoice" = No
        UpdateShipmentOnInvoiceOnSalesReceivablesSetup;

        // [GIVEN] Released Sales Invoice with posting nos are already assigned
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Run Batch Post Sales Invoice with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 1, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date" + 1, true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);
        VerifyPostedSalesInvoice(SalesHeader2."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Credit Memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Credit Memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemoDiffPostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", CalcDate('<1D>', WorkDate), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", CalcDate('<1D>', WorkDate), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemoCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemos()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Credit Memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Credit Memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);
        VerifyPostedSalesCrMemo(SalesHeader2."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode);

        // Create a sales invoice.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification;

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesInvoice(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemosWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales cr. memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode);

        // Create a sales cr. memo.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales cr. memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification;

        // Verify that Posted Sales cr. memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesCrMemo(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales order.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode);

        // Create a sales order.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Order, false);

        // Batch Post Sales Order.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification;

        // Verify that Posted Sales Order Exists.
        VerifyPostedSalesOrder(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesOrder(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesReturnOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdersWithApprovals()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);

        // Create and release Sales return order.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode);

        // Create a sales return order.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Return Order", false);

        // Batch Post Sales return order.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification;

        // Verify that Posted Sales return order Exists.
        VerifyPostedSalesReturnOrder(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesReturnOrder(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderWithInvoiceDiscountAndJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Index: Integer;
    begin
        // [FEATURE] [Order] [Job  Queue] [Invoice Discount]
        // [SCENARIO 268223] Stan can post with job queue multiple orders in a batch when "Calc. Invoice Discount" is turned on
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Sales setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear;
        LibraryWorkflow.DisableAllWorkflows;
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(SalesHeader) do
            CreateSalesDocument(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, true);

        // [WHEN] Post them via "Batch Post Sales Orders" report
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, true);

        // [THEN] Two Job Queue Entries created and their ID stored in orders
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesHeader[Index].Find;
            SalesHeader[Index].TestField("Job Queue Entry ID");
        end;

        // [THEN] Messages of Job Queue Entry creation have been omitted
        Assert.ExpectedMessage(Format(BatchCompletedMsg), LibraryVariableStorageCounter.DequeueText);
        LibraryVariableStorageCounter.AssertEmpty;

        // [THEN] Invoices has been posted after queues execution
        for Index := 1 to ArrayLen(SalesHeader) do begin
            RunJobQueueFromSalesHeader(SalesHeader[Index]);
            VerifyPostedSalesInvoiceByOrderNo(SalesHeader[Index]."No.", SalesHeader[Index]."Posting Date", true);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostRetrySalesOrderWithJobQueueAndZeroQuantity()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ErrorMessages: TestPage "Error Messages";
        Index: Integer;
        NullGUID: Guid;
    begin
        // [FEATURE] [Order] [Job  Queue]
        // [SCENARIO 275869] Stan can try post with job queue multiple time bad orders without error 'Batch Processing Parameter Map already exists.'
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Sales setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear;
        LibraryWorkflow.DisableAllWorkflows;
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(SalesHeader) do
            CreateSalesDocumentWithQuantity(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, false, 0);

        // [WHEN] Post two times them via "Batch Post Sales Orders" report

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        // [THEN] Click on 'Details' action: opened "Error Messages" page with list of bad documents each time
        for Index := 1 to ArrayLen(SalesHeader) do begin
            ErrorMessages.Trap;
            RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, true);
            VerifySalesHeaderNotification;
            LibraryNotificationMgt.RecallNotificationsForRecordID(SalesHeader[1].RecordId);

            // Bug: 306600
            ErrorMessages.Source.AssertEquals(Format(SalesHeader[1].RecordId));
            ErrorMessages.Next;
            ErrorMessages.Source.AssertEquals(Format(SalesHeader[2].RecordId));
            ErrorMessages.Close;
        end;

        // [THEN] Job Queue Entries are not created.
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesHeader[Index].Find;
            SalesHeader[Index].TestField("Job Queue Entry ID", NullGUID);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceWithConcurrentBatch()
    var
        SalesHeader: Record "Sales Header";
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        BatchID: array[2] of Guid;
        BatchSessionID: array[2] of Integer;
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 306600] Stan can run "Batch Post Sales Invoices" report when concurrent batch is active having the same document
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        BatchSessionID[1] := SessionId;
        BatchSessionID[2] := SessionId - 1;

        PostingDate[1] := WorkDate - 1;
        PostingDate[2] := WorkDate;

        BatchID[1] := CreateGuid;
        BatchID[2] := CreateGuid;

        // [GIVEN] Sales invoice "I" to be posted via batch
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // [GIVEN] Batch "B[1]" processing "I". Batch is lost in current session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          SalesHeader, BatchPostParameterTypes.PostingDate, PostingDate[1], BatchSessionID[1], BatchID[1]);

        // [GIVEN] Batch "B[2]" processing "I". Batch is live in other session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          SalesHeader, BatchPostParameterTypes.PostingDate, PostingDate[1], BatchSessionID[2], BatchID[2]);

        // [WHEN] Stan run "Batch Post Sales Invoices" report with "Replace Posting Date" = TRUE and "Posting Date" = March 2nd, 2019 and "I" in filter
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", PostingDate[2], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] "I" is posted with "Posting Date" = March 2nd, 2019.
        VerifyPostedSalesInvoice(SalesHeader."No.", PostingDate[2], false);

        // [THEN] "B[1]" removed
        VerifyBatchParametersDoNoExist(BatchID[1]);

        // [THEN] "B[2]" remains unchanged
        VerifyBatchParametersExist(BatchID[2]);

        // [THEN] "Batch Processing Parameter" table empty after cleaning B[2]
        BatchProcessingParameter.SetRange("Batch ID", BatchID[2]);
        BatchProcessingParameter.DeleteAll();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostAndPrintWithJobQueueSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibrarySales.SetPostWithJobQueue(false);
        LibrarySales.SetPostAndPrintWithJobQueue(false);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        SalesReceivablesSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        Assert.IsTrue(SalesReceivablesSetup."Post with Job Queue", 'Setup is not correct.');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueueSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibrarySales.SetPostWithJobQueue(true);
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        SalesReceivablesSetup.Validate("Post with Job Queue", FALSE);
        // [THEN] "Post & Print with Job Queue" = FALSE
        Assert.IsFalse(SalesReceivablesSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        ASSERTERROR SalesReceivablesSetup.Validate("Report Output Type", SalesReceivablesSetup."Report Output Type"::Print);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedError('Report Output Type must be equal to ''PDF''  in Sales & Receivables Setup');
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostSalesInvoices()
    var
        SalesHeader: array[2] of Record "Sales Header";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Standard Sales - Invoice" when batch post sales invoices
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);
        CreateInvoiceReportSelection();

        // [GIVEN] Two sales invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two sales invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostSales(
          SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);

        // [THEN] 'Print' checkbox is not visible, so number "Sales - Invoice" report runs = 0 (calculated in StandardSalesInvoiceReportHandler)
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger, 'Number of printed invoice is not correct');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should not be invisible');
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostSalesInvoicesBackground()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Standard Sales - Invoice" when batch post sales invoices in background
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateInvoiceReportSelection();

        // [GIVEN] Two sales invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two sales invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostSales(
          SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[2].RecordId);

        // [THEN] There are two records in the "Job Queue Entry" with "PDF" output type
        VerifyPrintJobQueueEntries(SalesHeader);
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should be visible');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDiscAndReplacePostingDateJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 316670] Batch Posting of Sales Invoice with "Replace Posting Date", "Calc. Inv. Discount" and "backgroud posting" in Purchase Setup
        Initialize;

        // [GIVEN] Sales Setup with "Calc. Inv. Discount" = TRUE;
        UpdateCalcInvDiscSalesReceivablesSetup(true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" enabled in Sales setup
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Released Sales Invoice "A"
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, true);
        PostingDate[1] := SalesHeader[1]."Posting Date";
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] "Batch Post Sales Invoice" report ran with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No.", PostingDate[1] + 1, true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" disabled in Sales setup
        LibrarySales.SetPostAndPrintWithJobQueue(false);
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] Released Sales Invoice "B" and post via Batch Postig without background job
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, true);
        PostingDate[2] := SalesHeader[2]."Posting Date";
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);
        SalesHeader[2].SetRecFilter;
        RunBatchPostSales(SalesHeader[2]."Document Type", SalesHeader[2]."No.", PostingDate[2] + 2, true);

        // [GIVEN] Job Queue Entries created for Invoice 'A'. 
        SalesHeader[1].Find;
        JobQueueEntry.Get(SalesHeader[1]."Job Queue Entry ID");

        // [WHEN] Run Job Queue Entries for Invoice "A"
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        // [THEN] Invoice 'B' is posted directly. 
        Assert.IsFalse(SalesHeader[2].Find, 'Second Invoice should be posted');

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoices "A"
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", PostingDate[1] + 1, true);
        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoice "B"
        VerifyPostedSalesInvoice(SalesHeader[2]."No.", PostingDate[2] + 2, true);

        // [THEN] Batch Processing Map Table cleaned after job queue execution
        BatchProcessingSessionMap.SetRange("Record ID", SalesHeader[1].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);

        BatchProcessingSessionMap.SetRange("Record ID", SalesHeader[2].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Batch Posting");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Batch Posting");

        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        isInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Batch Posting");
    end;

    local procedure CreateCustomer(InvDisc: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        if InvDisc then
            CreateCustomerDiscount(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerDiscount(CustomerNo: Code[20])
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.Init();
        CustInvDisc.Validate(Code, CustomerNo);
        CustInvDisc.Validate("Discount %", LibraryRandom.RandIntInRange(10, 20));
        CustInvDisc.Insert(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option; InvDisc: Boolean)
    begin
        CreateSalesDocumentWithQuantity(SalesHeader, DocumentType, InvDisc, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateSalesDocumentWithQuantity(var SalesHeader: Record "Sales Header"; DocumentType: Option; InvDisc: Boolean; DocQuantity: Decimal)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(InvDisc));
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", DocQuantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure AddBatchProcessParameters(SalesHeader: Record "Sales Header"; ParameterId: Integer; ParameterValue: Variant; BachSessionID: Integer; BatchID: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId;
        BatchProcessingParameter."Parameter Value" := Format(ParameterValue);
        BatchProcessingParameter.Insert();

        BatchProcessingSessionMap."Record ID" := SalesHeader.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchProcessingParameter."Batch ID";
        BatchProcessingSessionMap."User ID" := UserSecurityId;
        BatchProcessingSessionMap."Session ID" := BachSessionID;
        BatchProcessingSessionMap.Insert();
    end;

    local procedure RunBatchPostSales(DocumentType: Option; DocumentNoFilter: Text; PostingDate: Date; CalcInvDisc: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        UpdateCalcInvDiscSalesReceivablesSetup(CalcInvDisc);
        LibraryVariableStorage.Enqueue(DocumentNoFilter);
        LibraryVariableStorage.Enqueue(PostingDate);

        Commit();
        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                REPORT.RunModal(REPORT::"Batch Post Sales Invoices", true, true, SalesHeader);
            SalesHeader."Document Type"::"Credit Memo":
                REPORT.RunModal(REPORT::"Batch Post Sales Credit Memos", true, true, SalesHeader);
            SalesHeader."Document Type"::Order:
                REPORT.RunModal(REPORT::"Batch Post Sales Orders", true, true, SalesHeader);
            SalesHeader."Document Type"::"Return Order":
                REPORT.RunModal(REPORT::"Batch Post Sales Return Orders", true, true, SalesHeader);
        end;
    end;

    local procedure RunJobQueueFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(SalesHeader."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Finished);
    end;

    local procedure UpdateCalcInvDiscSalesReceivablesSetup(CalcInvDisc: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDisc);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateShipmentOnInvoiceOnSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", SalesReceivablesSetup."Invoice Nos.");
        SalesReceivablesSetup."Shipment on Invoice" := false;
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateInvoiceReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"S.Invoice";
        ReportSelections."Report ID" := REPORT::"Standard Sales - Invoice";
        If ReportSelections.Insert() Then;
    end;

    local procedure VerifyPostedSalesInvoice(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesInvoiceByOrderNo(OrderNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesCrMemo(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst;
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
        SalesCrMemoLine.SetFilter("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst;
        Assert.AreEqual(InvDisc, SalesCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Order No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesReturnOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetFilter("Return Order No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst;
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
        SalesCrMemoLine.SetFilter("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst;
        Assert.AreEqual(InvDisc, SalesCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
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

    local procedure VerifySalesHeaderNotification()
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.ExpectedMessage(NotificationMsg, LibraryVariableStorage.DequeueText); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty;
        Clear(SalesHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    local procedure VerifyPrintJobQueueEntries(var SalesHeader: array[2] of Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Standard Sales - Invoice");
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::PDF);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader[1]."No.");
        SalesInvoiceHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader[2]."No.");
        SalesInvoiceHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesInvoices(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        RunReplacePostingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesInvoices."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesInvoices."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));

        BatchPostSalesInvoices.PostingDate.SetValue(PostingDate);
        RunReplacePostingDate := Format(PostingDate) <> '';
        BatchPostSalesInvoices.ReplaceDocumentDate.SetValue(RunReplacePostingDate);
        BatchPostSalesInvoices.ReplacePostingDate.SetValue(RunReplacePostingDate);
        // CalcInvDiscount is set from Sales Setup
        BatchPostSalesInvoices.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesCrMemos(var BatchPostSalesCrMemos: TestRequestPage "Batch Post Sales Credit Memos")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesCrMemos."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesCrMemos."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::"Credit Memo"));

        BatchPostSalesCrMemos.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostSalesCrMemos.ReplacePostingDate.SetValue(true)
        else
            BatchPostSalesCrMemos.ReplacePostingDate.SetValue(false);
        // CalcInvDiscount is set from Sales Setup
        BatchPostSalesCrMemos.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesOrders(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesOrders."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesOrders."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));

        BatchPostSalesOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostSalesOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostSalesOrders.ReplacePostingDate.SetValue(false);
        BatchPostSalesOrders.Ship.SetValue(true);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesReturnOrders(var BatchPostSalesReturnOrders: TestRequestPage "Batch Post Sales Return Orders")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesReturnOrders."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesReturnOrders."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::"Return Order"));

        BatchPostSalesReturnOrders.PostingDateReq.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(false);
        BatchPostSalesReturnOrders.ReceiveReq.SetValue(true);
        BatchPostSalesReturnOrders.InvReq.SetValue(true);
        BatchPostSalesReturnOrders.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesPrintRequestPageHandler(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        PrintVisible: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesInvoices."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesInvoices."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));

        PrintVisible := BatchPostSalesInvoices.PrintDoc.Visible();
        if PrintVisible then
            BatchPostSalesInvoices.PrintDoc.SetValue(true);
        BatchPostSalesInvoices.OK.Invoke;

        LibraryVariableStorage.Enqueue(PrintVisible);
        LibraryVariableStorage.Enqueue(0); // initialize report run counter
    end;

    [ReportHandler]
    procedure StandardSalesInvoiceReportHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger + 1);
    end;

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

