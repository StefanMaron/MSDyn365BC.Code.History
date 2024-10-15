codeunit 134301 "Workflow Notification Test"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        EmailWasNotSentErr: Label 'The email was not sent.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        InvalidUriErr: Label 'The URI is not valid.';
        UserEmailAddressTxt: Label 'test@contoso.com';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        TitleTxt: Label 'Hello';
        VendorTxt: Label 'Vendor';
        CustomerTxt: Label 'Customer';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        NoSubstituteFoundErr: Label 'There is no substitute, direct approver, or approval administrator for user ID %1 in the Approval User Setup window.', Locked = true;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        NotificationManagement: Codeunit "Notification Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPermissions: Codeunit "Library - Permissions";
        IsInitialized: Boolean;
        PurchaseOrderTxt: Label 'Purchase Order';
        SalesOrderTxt: Label 'Sales Order';
        UserSetupNotExistErr: Label 'The User Setup does not exist. Identification fields and values: User ID=''%1''';
        URLFilterNotFoundErr: Label 'URL filter is not found in RecordLink.';
        CreatedByUserTxt: Label 'Created By %1', Comment = 'Created By User1';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNotificationSetupCreated()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationManagement: Codeunit "Notification Management";
    begin
        // [SCENARIO] A default notification setup is created, if non exist.
        // [WHEN] The CreateDefaultNotificationSetup function is called and no notification setup exist.
        // [THEN] A default notification setup is created.

        // Setup
        Initialize;
        NotificationSetup.DeleteAll;

        // Execute
        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::"New Record");

        // Verify
        Assert.AreEqual(1, NotificationSetup.Count, 'Notification Setup was not created');
        NotificationSetup.FindFirst;
        NotificationSetup.TestField("User ID", ''); // Default User
        NotificationSetup.TestField("Notification Type", NotificationSetup."Notification Type"::"New Record");
        NotificationSetup.TestField("Notification Method", NotificationSetup."Notification Method"::Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomNotificationPageID()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO] Creating a notification entry with a specified page id.
        // [WHEN] A Notification Entry is created.
        // [THEN] The message related to the notifications entry contains the specified page.

        // Setup
        Initialize;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        CreateResponseArgumentForNotifications(WorkflowStepArgument);
        WorkflowStepArgument."Link Target Page" := PAGE::"Sales Order List";
        WorkflowStepArgument.Modify;

        // Exercise
        RecRef.GetTable(SalesHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record",
          UserId, RecRef, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Validate
        ExpectedValues[1] := 'page=' + Format(PAGE::"Sales Order List") + '&amp;bookmark=';
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJournalLineNotification()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        NotificationEntry: Record "Notification Entry";
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Journal]
        // [SCENARIO] Create a notification entry based on an journal line.
        // [WHEN] A journal line is passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.

        // Setup.
        Initialize;

        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"Bank Account", '', 100);

        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", WorkflowStepArgument."Notification User ID",
          GenJournalLine, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(GenJournalLine);

        ExpectedValues[1] := GenJournalLine."Journal Template Name" + ',' +
          GenJournalLine."Journal Batch Name" + ',' + Format(GenJournalLine."Line No.");
        ExpectedValues[2] := Format(GenJournalLine.Amount);
        ExpectedValues[3] := 'page=' + Format(PAGE::"General Journal") + '&amp;bookmark=';
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenPurchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Purchase]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestPurchaseApprovalNotification(ApprovalEntry.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedPurchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Purchase]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected
        // [WHEN] An Approval entry (Status = Rejected) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestPurchaseApprovalNotification(ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledPurchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Purchase]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled
        // [WHEN] An Approval entry (Status = Canceled) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestPurchaseApprovalNotification(ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseApprovalNotificationForMultibleApprovals()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Approval] [Purchase]
        // [SCENARIO] Create a 2 notification entry based the same document the use seperated approval amounts.
        // [WHEN] 2 Approval entries are passed into the notification engine.
        // [THEN] 2 notification entries are created with differant amounts.

        // Setup.
        Initialize;
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        CreatePurchaseApprovalEntry(ApprovalEntry, PurchaseHeader, ApprovalEntry.Status::Open);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
        CreatePurchaseApprovalEntry(ApprovalEntry2, PurchaseHeader, ApprovalEntry.Status::Open);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry2, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(ApprovalEntry.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);

        RecRef.GetTable(ApprovalEntry2);
        ExpectedValues[2] := Format(ApprovalEntry2.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenSalesApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open and "Limit Type" = "Approval Limits"
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestSalesApprovalNotification(ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenSalesApprovalEntryWithCreditLimits()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open and "Limit Type" = "Credit Limits"
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestSalesApprovalNotification(ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Credit Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedSalesApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected and "Limit Type" = "Approval Limits"
        // [WHEN] An Approval entry (Status = Rejected) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestSalesApprovalNotification(ApprovalEntry.Status::Rejected, ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledSalesApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled and "Limit Type" = "Approval Limits"
        // [WHEN] An Approval entry (Status = Canceled) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestSalesApprovalNotification(ApprovalEntry.Status::Canceled, ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesApprovalNotificationForMultibleApprovals()
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] Create a 2 notification entry based the same document the use seperated approval amounts.
        // [WHEN] 2 Approval entries are passed into the notification engine.
        // [THEN] 2 notification entries are created with differant amounts.

        // Setup.
        Initialize;
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateSalesApprovalEntry(ApprovalEntry, SalesHeader, ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits");
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        CreateSalesApprovalEntry(ApprovalEntry2, SalesHeader, ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits");

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry2, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(ApprovalEntry.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);

        RecRef.GetTable(ApprovalEntry2);
        ExpectedValues[2] := Format(ApprovalEntry2.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenItemApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Item]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestItemApprovalNotification(ApprovalEntry.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedItemApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Item]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected
        // [WHEN] An Approval entry (Status = Rejected) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestItemApprovalNotification(ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledItemApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Item]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled
        // [WHEN] An Approval entry (Status = Canceled) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestItemApprovalNotification(ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCreatedItemApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Item]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Created
        // [WHEN] An Approval entry (Status = Created) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestItemApprovalNotification(ApprovalEntry.Status::Created);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForApprovedItemApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Item]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Approved
        // [WHEN] An Approval entry (Status = Approved) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestItemApprovalNotification(ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestOverdueApprovalsGenerateNotificationEntry()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        ApprovalEntry: Record "Approval Entry";
        NotificationManagement: Codeunit "Notification Management";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Approval] [Overdue]
        // [SCENARIO] Send a Notification Email for Overdue Approval Entries
        // [GIVEN] Approval Entry with Due Date less than or equal to the check date.
        // [WHEN] CreateOverdueNotifications function is invoked.
        // [THEN] Notification Entry is created. The email message related to the entry is created.
        Initialize;

        // Setup
        CreateOverdueApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", Today - 10);
        CreateOverdueApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", Today - 10);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise
        NotificationManagement.CreateOverdueNotifications(WorkflowStepArgument);

        // Verify
        ApprovalEntry.Init;
        RecRef.GetTable(ApprovalEntry);

        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := PurchaseOrderTxt;
        ExpectedValues[3] := SalesOrderTxt;

        VerifyNotificationEntry(RecRef, ExpectedValues, false);
        VerifyOverdueLogEntry(PurchApprovalEntry);
        VerifyOverdueLogEntry(SalesApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestNotDueApprovalsDoesNotGenerateNotificationEntry()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        NotificationManagement: Codeunit "Notification Management";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [Approval] [Overdue]
        // [SCENARIO] There is no notification for not Overdue Approval Entries
        // [GIVEN] Approval Entry with Due Date more than the check date.
        // [WHEN] CreateOverdueNotifications function is invoked.
        // [THEN] No Notification Entry is created.
        Initialize;

        // Setup
        CreateOverdueApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", Today + 10);
        CreateOverdueApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", Today + 10);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise
        NotificationManagement.CreateOverdueNotifications(WorkflowStepArgument);

        // Verify
        RecRef.GetTable(PurchApprovalEntry);
        ExpectedValues[1] := '';
        asserterror VerifyNotificationEntry(RecRef, ExpectedValues, true);
        Assert.AssertNothingInsideFilter;

        RecRef.GetTable(SalesApprovalEntry);
        asserterror VerifyNotificationEntry(RecRef, ExpectedValues, true);
        Assert.AssertNothingInsideFilter;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNotificationArgumentWithInvalidUri()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Initialize;

        // Setup
        WorkflowStepArgument.Init;

        // Exercise
        asserterror WorkflowStepArgument.Validate("Custom Link", LibraryUtility.GenerateGUID);

        // Verify
        Assert.ExpectedError(InvalidUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationMethodNote()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
        JobQueueEntry: Record "Job Queue Entry";
        NotificationEntryDispatcher: Codeunit "Notification Entry Dispatcher";
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] When Notifications Method is Note then Record Link is created
        // [GIVEN] Workflow is setup to notify a specific user and Notification Method is Note
        // [WHEN] A Notification Entry record is created
        // [THEN] Record Link is created
        // Setup
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, SalesHeader, 0, '');

        LibraryWorkflow.CreateNotificationSetup(NotificationSetup, UserId,
          NotificationSetup."Notification Type"::"New Record", NotificationSetup."Notification Method"::Note);

        Commit;

        // Exercise
        if not NotificationEntryDispatcher.Run(JobQueueEntry) then
            Error(EmailWasNotSentErr);

        // Validate
        VerifyRecordLinkCreated(NotificationEntry, SalesHeader, UserId)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenCustomerApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Customer]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestCustomerApprovalNotification(ApprovalEntry.Status::Open,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedCustomerApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Customer]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected
        // [WHEN] An Approval entry (Status = Rejected) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestCustomerApprovalNotification(ApprovalEntry.Status::Rejected,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledCustomerApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Customer]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled
        // [WHEN] An Approval entry (Status = Canceled) is passed into the notification engine
        // [THEN] A notification entry is created with the expected information
        TestCustomerApprovalNotification(ApprovalEntry.Status::Canceled,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenGenJnlLineApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open
        // [WHEN] An Approval entry (Status = Open) is passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlLineApprovalNotification(ApprovalEntry.Status::Open,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedGenJnlLineApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected
        // [WHEN] An Approval entry (Status = Rejected) is passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlLineApprovalNotification(ApprovalEntry.Status::Rejected,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledGenJnlLineApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled
        // [WHEN] An Approval entry (Status = Canceled) is passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlLineApprovalNotification(ApprovalEntry.Status::Canceled,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlLineApprovalNotificationForMultibleApprovals()
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", '', 100);
        CreateGenJournalLineApprovalEntry(
          ApprovalEntry, GenJournalLine, ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits");
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);
        GenJournalLine.Amount := 200;
        GenJournalLine.Modify;
        CreateGenJournalLineApprovalEntry(
          ApprovalEntry2, GenJournalLine, ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits");

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry2, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(ApprovalEntry.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);

        RecRef.GetTable(ApprovalEntry2);
        ExpectedValues[2] := Format(ApprovalEntry2.Amount);
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForOpenGenJnlBatchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal] [Batch]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Open
        // [WHEN] An Approval entry (Status = Open) iis passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlBatchApprovalNotification(ApprovalEntry.Status::Open,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForRejectedGenJnlBatchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal] [Batch]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Rejected
        // [WHEN] An Approval entry (Status = Rejected) iis passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlBatchApprovalNotification(ApprovalEntry.Status::Rejected,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationForCanceledGenJnlBatchApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [Approval] [Journal] [Batch]
        // [SCENARIO] Create a notification entry based on an approval entry with Status = Canceled
        // [WHEN] An Approval entry (Status = Canceled) iis passed into the notification engine.
        // [THEN] A notification entry is created with the expected information.
        TestGenJnlBatchApprovalNotification(ApprovalEntry.Status::Canceled,
          ApprovalEntry."Limit Type"::"Approval Limits");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstituteDelegatedApprovals()
    var
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        SecondApproverUserSetup: Record "User Setup";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Approval]
        // [SCENARIO] Change the approver id for a delegated Approval Entries in case of substitute
        // [GIVEN] Approval Entry with Delegate date less than or equal to the check date.
        // [WHEN] The Delegate function is invoked.
        // [THEN] The approval entry has a new approver set.
        Initialize;
        UserSetup.Get(UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(SecondApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(UserSetup, SecondApproverUserSetup);

        // Setup
        CreateDelegateApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", '-2D');
        CreateDelegateApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", '-2D');

        // Exercise
        REPORT.Run(REPORT::"Delegate Approval Requests", false);

        // Verify
        ApprovalEntry.Init;
        RecRef.GetTable(ApprovalEntry);

        VerifyDelegatedApprovalEntry(PurchApprovalEntry, SecondApproverUserSetup);
        VerifyDelegatedApprovalEntry(SalesApprovalEntry, SecondApproverUserSetup);

        // Tear-down
        Clear(UserSetup);
        UserSetup.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDirectApproverDelegatedApprovals()
    var
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        SecondApproverUserSetup: Record "User Setup";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Approval]
        // [SCENARIO] Change the approver id for a delegated Approval Entries in case of direct approver
        // [GIVEN] Approval Entry with Delegate date less than or equal to the check date.
        // [WHEN] The Delegate function is invoked.
        // [THEN] The approval entry has a new approver set.
        Initialize;
        UserSetup.Get(UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(SecondApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(UserSetup, SecondApproverUserSetup);

        // Setup
        CreateDelegateApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", '-2D');
        CreateDelegateApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", '-2D');

        // Exercise
        REPORT.Run(REPORT::"Delegate Approval Requests", false);

        // Verify
        ApprovalEntry.Init;
        RecRef.GetTable(ApprovalEntry);

        VerifyDelegatedApprovalEntry(PurchApprovalEntry, SecondApproverUserSetup);
        VerifyDelegatedApprovalEntry(SalesApprovalEntry, SecondApproverUserSetup);

        // Tear-down
        Clear(UserSetup);
        UserSetup.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApproverAdminDelegatedApprovals()
    var
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        SecondApproverUserSetup: Record "User Setup";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Approval]
        // [SCENARIO] Change the approver id for a delegated Approval Entries in case of approval administrator
        // [GIVEN] Approval Entry with Delegate date less than or equal to the check date.
        // [WHEN] The Delegate function is invoked.
        // [THEN] The approval entry has a new approver set.
        Initialize;
        UserSetup.Get(UserId);
        UserSetup."Approval Administrator" := false;
        UserSetup.Modify(true);
        LibraryDocumentApprovals.CreateMockupUserSetup(SecondApproverUserSetup);
        SecondApproverUserSetup."Approval Administrator" := true;
        SecondApproverUserSetup.Modify(true);

        // Setup
        CreateDelegateApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", '-2D');
        CreateDelegateApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", '-2D');

        // Exercise
        REPORT.Run(REPORT::"Delegate Approval Requests", false);

        // Verify
        ApprovalEntry.Init;
        RecRef.GetTable(ApprovalEntry);

        VerifyDelegatedApprovalEntry(PurchApprovalEntry, SecondApproverUserSetup);
        VerifyDelegatedApprovalEntry(SalesApprovalEntry, SecondApproverUserSetup);

        // Tear-down
        Clear(UserSetup);
        UserSetup.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorNoDelegationPathFoundApprovals()
    var
        PurchApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        // [FEATURE] [Approval]
        // [SCENARIO] Error trying change the approver id for a delegated Approval Entries in case of no found approval path
        // [GIVEN] Approval Entry with Delegate date less than or equal to the check date.
        // [WHEN] The Delegate function is invoked.
        // [THEN] The approval entry has a new approver set.
        Initialize;
        UserSetup.Get(UserId);
        UserSetup."Approval Administrator" := false;
        UserSetup.Modify(true);

        // Setup
        CreateDelegateApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", '-2D');

        // Exercise
        RequeststoApprove.OpenView;
        RequeststoApprove.GotoRecord(PurchApprovalEntry);
        asserterror RequeststoApprove.Delegate.Invoke;

        // Verify
        Assert.ExpectedError(StrSubstNo(NoSubstituteFoundErr, UserId));

        // Tear-down
        Clear(UserSetup);
        UserSetup.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationEntryWithoutRecordIDDeleted()
    var
        ApprovalEntry: Record "Approval Entry";
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
        JobQueueEntry: Record "Job Queue Entry";
        NotificationEntryDispatcher: Codeunit "Notification Entry Dispatcher";
        DummyRecId: RecordID;
    begin
        // [FEATURE] [Approval] [Sales]
        // [SCENARIO] When Notification entry is not linked to Record ID, it should be deleted.
        // [GIVEN] Workflow is setup to notify a specific user
        // [GIVEN] A Notification Entry record with empty Triggered By Record is created
        // [WHEN] Notification dispatcher is run.
        // [THEN] Notification entry is deleted
        // Setup
        Initialize;

        LibraryDocumentApprovals.CreateApprovalEntryBasic(ApprovalEntry, DATABASE::"Sales Header",
          ApprovalEntry."Document Type"::Invoice, LibraryUtility.GenerateGUID, ApprovalEntry.Status::Open,
          ApprovalEntry."Limit Type"::"Approval Limits", DummyRecId, ApprovalEntry."Approval Type"::Approver, 0D, 0);

        NotificationEntry.CreateNewEntry(NotificationEntry.Type::"New Record", UserId, ApprovalEntry, 0, '', UserId);
        NotificationEntry.FindLast;
        NotificationEntry."Triggered By Record" := DummyRecId;
        NotificationEntry.Modify;

        LibraryWorkflow.CreateNotificationSetup(NotificationSetup, UserId,
          NotificationSetup."Notification Type"::"New Record", NotificationSetup."Notification Method"::Note);

        Commit;

        // Exercise
        Assert.IsTrue(NotificationEntryDispatcher.Run(JobQueueEntry), 'No errors expected.');

        // Validate
        Assert.IsFalse(NotificationEntry.Get(NotificationEntry.ID), 'Record should have been deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotDelegatedApprovalsDoesNotGenerateNotificationEntry()
    var
        PurchApprovalEntry: Record "Approval Entry";
        SalesApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        SecondApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A Notification Email is not sent for not delegated Approval Entries
        // [GIVEN] Approval Entry with Delegate Date more than the check date.
        // [WHEN] Delegate function is invoked.
        // [THEN] The approver is not changed in the approval entry.
        Initialize;
        UserSetup.Get(UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(SecondApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(UserSetup, SecondApproverUserSetup);

        // Setup
        CreateDelegateApprovalEntry(PurchApprovalEntry, DATABASE::"Purchase Header", '10D');
        CreateDelegateApprovalEntry(SalesApprovalEntry, DATABASE::"Sales Header", '10D');

        // Exercise
        REPORT.Run(REPORT::"Delegate Approval Requests", false);

        // Verify
        VerifyDelegatedApprovalEntry(PurchApprovalEntry, UserSetup);
        VerifyDelegatedApprovalEntry(SalesApprovalEntry, UserSetup);

        // Tear-down
        Clear(UserSetup);
        UserSetup.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyNotificationEntryToSentNotificationEntryDuplicateID()
    var
        NotificationEntry: Record "Notification Entry";
        SentNotificationEntry: Record "Sent Notification Entry";
        NotificationSetup: Record "Notification Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 202828] TAB1514.NewRecord can copy "Notification Entry" with ID = 100 to "Sent Notification Entry" table that already has entry with ID = 100
        SentNotificationEntry.DeleteAll;
        SentNotificationEntry.ID := 100;
        SentNotificationEntry."Recipient User ID" := UserId;
        SentNotificationEntry.Insert;

        NotificationEntry.ID := 100;
        NotificationEntry."Recipient User ID" := UserId;
        NotificationEntry.Insert;

        SentNotificationEntry.NewRecord(NotificationEntry, 'New text', NotificationSetup."Notification Method"::Email);

        SentNotificationEntry.TestField(ID, 101);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSenderNotificationOnAprovalRequestRejection()
    var
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        NotificationEntry: Record "Notification Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ExpectedValues: array[20] of Text;
    begin
        // [SCENARIO 205129] When approval request is rejected, a notification is sent to both approver and request sender.
        Initialize;

        // [GIVEN] Two users for approval process where the second one is a Direct Approver for the first one.
        // [GIVEN] Sales Document Approval Workflow "WF" where notification should be sent on a document rejection.
        // [GIVEN] "WF" has Approver as Approver Type and Direct Approver as Approver Limit Type.
        // [GIVEN] Sales Invoice "SI" created by initial user send for approval.
        PrepareRejectScenario(CurrentUserSetup, SalesHeader);

        // [WHEN] "SI" is rejected by the second user.
        ApprovalsMgmt.RejectRecordApprovalRequest(SalesHeader.RecordId);

        // [THEN] Notication is not sent to Approver
        // [THEN] Notication sent to approval Sender
        ExpectedValues[1] := 'Sales Invoice';
        ExpectedValues[2] := Format(SalesHeader."No.");
        ExpectedValues[3] := 'approval has been rejected.';

        Assert.RecordCount(NotificationEntry, 1);
        VerifyNotificationsForRecipient(CurrentUserSetup."Approver ID", ExpectedValues);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendNotificationDoesNotFailWhenUserSetupIsNotFound()
    var
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        NotificationEntry: Record "Notification Entry";
        DeletedUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 210514] Send notification does not fail when User Setup is not found.
        Initialize;

        // [GIVEN] Two users for approval process where the second one is a Direct Approver for the first one.
        // [GIVEN] Sales Document Approval Workflow "WF" where notification should be sent on a document rejection.
        // [GIVEN] "WF" has Approver as Approver Type and Direct Approver as Approver Limit Type.
        // [GIVEN] Sales Invoice "SI" created by initial user send for approval.
        // [GIVEN] User setup for approval sender has been deleted
        PrepareRejectScenario(CurrentUserSetup, SalesHeader);
        DeletedUserSetup.Get(CurrentUserSetup."Approver ID");
        DeletedUserSetup.Delete;

        // [WHEN] "SI" is rejected by the second user.
        ApprovalsMgmt.RejectRecordApprovalRequest(SalesHeader.RecordId);

        // [THEN] There is no notification created
        Assert.RecordCount(NotificationEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_SalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 218080] Notification Message for the open sales invoice
        Initialize;

        // [GIVEN] Sales Invoice "X" for Customer "C" (with name "N") with Amount = "A"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        Customer.Get(SalesHeader."Sell-to Customer No.");
        SalesHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the sales invoice "X"
        RecRef.GetTable(SalesHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Invoice X"
        // [THEN] "Amount A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Invoice', SalesHeader."No.", SalesHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_SalesInvoice_FCY()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Invoice] [Currency]
        // [SCENARIO 218080] Notification Message for the open sales invoice with currency
        Initialize;

        // [GIVEN] Sales Invoice "X" for Customer "C" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, LibraryERM.CreateCurrencyWithRandomExchRates);
        Customer.Get(SalesHeader."Sell-to Customer No.");
        SalesHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the sales invoice "X"
        RecRef.GetTable(SalesHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Invoice X"
        // [THEN] "Amount EUR A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Invoice', SalesHeader."No.", SalesHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_SalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 218080] Notification Message for the open sales credit memo
        Initialize;

        // [GIVEN] Sales Credit Memo "X" for Customer "C" (with name "N") with Amount = "A"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        Customer.Get(SalesHeader."Sell-to Customer No.");
        SalesHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the sales credit memo "X"
        RecRef.GetTable(SalesHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Credit Memo X"
        // [THEN] "Amount A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Credit Memo', SalesHeader."No.", SalesHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_SalesCrMemo_FCY()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Currency]
        // [SCENARIO 218080] Notification Message for the open sales credit memo with currency
        Initialize;

        // [GIVEN] Sales Credit Memo "X" for Customer "C" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibraryERM.CreateCurrencyWithRandomExchRates);
        Customer.Get(SalesHeader."Sell-to Customer No.");
        SalesHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the sales credit memo "X"
        RecRef.GetTable(SalesHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Credit Memo X"
        // [THEN] "Amount EUR A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Credit Memo', SalesHeader."No.", SalesHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 218080] Notification Message for the posted sales invoice
        Initialize;

        // [GIVEN] Posted Sales Invoice "X" for Customer "C" (with name "N") with Amount = "A"
        SalesInvoiceHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, ''));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        SalesInvoiceHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted sales invoice "X"
        RecRef.GetTable(SalesInvoiceHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Invoice X"
        // [THEN] "Amount A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Invoice', SalesInvoiceHeader."No.", SalesInvoiceHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesInvoiceHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedSalesInvoice_FCY()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Invoice] [Currency]
        // [SCENARIO 218080] Notification Message for the posted sales invoice with currency
        Initialize;

        // [GIVEN] Posted Sales Invoice "X" for Customer "C" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(SalesHeader."Document Type"::Invoice, LibraryERM.CreateCurrencyWithRandomExchRates));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        SalesInvoiceHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted sales invoice "X"
        RecRef.GetTable(SalesInvoiceHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Invoice X"
        // [THEN] "Amount EUR A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Invoice', SalesInvoiceHeader."No.", SalesInvoiceHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesInvoiceHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 218080] Notification Message for the posted sales credit memo
        Initialize;

        // [GIVEN] Posted Sales Credit Memo "X" for Customer "C" (with name "N") with Amount = "A"
        SalesCrMemoHeader.Get(CreatePostSalesDoc(SalesHeader."Document Type"::"Credit Memo", ''));
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        SalesCrMemoHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted sales credit memo "X"
        RecRef.GetTable(SalesCrMemoHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Credit Memo X"
        // [THEN] "Amount A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Credit Memo', SalesCrMemoHeader."No.", SalesCrMemoHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesCrMemoHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedSalesCrMemo_FCY()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Currency]
        // [SCENARIO 218080] Notification Message for the posted sales credit memo with currency
        Initialize;

        // [GIVEN] Posted Sales Credit Memo "X" for Customer "C" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(SalesHeader."Document Type"::"Credit Memo", LibraryERM.CreateCurrencyWithRandomExchRates));
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        SalesCrMemoHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted sales credit memo "X"
        RecRef.GetTable(SalesCrMemoHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Sales Credit Memo X"
        // [THEN] "Amount EUR A"
        // [THEN] "Customer N (#C)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Sales Credit Memo', SalesCrMemoHeader."No.", SalesCrMemoHeader."Currency Code",
          'Customer', Customer.Name, Customer."No.", SalesCrMemoHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 218080] Notification Message for the open purchase invoice
        Initialize;

        // [GIVEN] Purchase Invoice "X" for Vendor "V" (with name "N") with Amount = "A"
        CreatePurchaseDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the purchase invoice "X"
        RecRef.GetTable(PurchaseHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Invoice X"
        // [THEN] "Amount A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Invoice', PurchaseHeader."No.", PurchaseHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PurchaseInvoice_FCY()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Invoice] [Currency]
        // [SCENARIO 218080] Notification Message for the open purchase invoice with currency
        Initialize;

        // [GIVEN] Purchase Invoice "X" for Vendor "V" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        CreatePurchaseDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryERM.CreateCurrencyWithRandomExchRates);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the purchase invoice "X"
        RecRef.GetTable(PurchaseHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Invoice X"
        // [THEN] "Amount EUR A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Invoice', PurchaseHeader."No.", PurchaseHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 218080] Notification Message for the open purchase credit memo
        Initialize;

        // [GIVEN] Purchase Credit Memo "X" for Vendor "V" (with name "N") with Amount = "A"
        CreatePurchaseDoc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '');
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the purchase credit memo "X"
        RecRef.GetTable(PurchaseHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Credit Memo X"
        // [THEN] "Amount A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Credit Memo', PurchaseHeader."No.", PurchaseHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PurchaseCrMemo_FCY()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Currency]
        // [SCENARIO 218080] Notification Message for the open purchase credit memo with currency
        Initialize;

        // [GIVEN] Purchase Credit Memo "X" for Vendor "V" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        CreatePurchaseDoc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryERM.CreateCurrencyWithRandomExchRates);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the purchase credit memo "X"
        RecRef.GetTable(PurchaseHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Credit Memo X"
        // [THEN] "Amount EUR A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Credit Memo', PurchaseHeader."No.", PurchaseHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 218080] Notification Message for the posted purchase invoice
        Initialize;

        // [GIVEN] Posted Purchase Invoice "X" for Vendor "V" (with name "N") with Amount = "A"
        PurchInvHeader.Get(CreatePostPurchaseDoc(PurchaseHeader."Document Type"::Invoice, ''));
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        PurchInvHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted purchase invoice "X"
        RecRef.GetTable(PurchInvHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Invoice X"
        // [THEN] "Amount A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Invoice', PurchInvHeader."No.", PurchInvHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchInvHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedPurchaseInvoice_FCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Invoice] [Currency]
        // [SCENARIO 218080] Notification Message for the posted purchase invoice with currency
        Initialize;

        // [GIVEN] Posted Purchase Invoice "X" for Vendor "V" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        PurchInvHeader.Get(
          CreatePostPurchaseDoc(
            PurchaseHeader."Document Type"::Invoice, LibraryERM.CreateCurrencyWithRandomExchRates));
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        PurchInvHeader.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted purchase invoice "X"
        RecRef.GetTable(PurchInvHeader);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Invoice X"
        // [THEN] "Amount EUR A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Invoice', PurchInvHeader."No.", PurchInvHeader."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchInvHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 218080] Notification Message for the posted purchase credit memo
        Initialize;

        // [GIVEN] Posted Purchase Credit Memo "X" for Vendor "V" (with name "N") with Amount = "A"
        PurchCrMemoHdr.Get(CreatePostPurchaseDoc(PurchaseHeader."Document Type"::"Credit Memo", ''));
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        PurchCrMemoHdr.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted purchase credit memo "X"
        RecRef.GetTable(PurchCrMemoHdr);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Credit Memo X"
        // [THEN] "Amount A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Credit Memo', PurchCrMemoHdr."No.", PurchCrMemoHdr."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchCrMemoHdr.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationMessage_PostedPurchaseCrMemo_FCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Currency]
        // [SCENARIO 218080] Notification Message for the posted purchase credit memo with currency
        Initialize;

        // [GIVEN] Posted Purchase Credit Memo "X" for Vendor "V" (with name "N") with Amount = "A" and "Currency Code" = "EUR"
        PurchCrMemoHdr.Get(
          CreatePostPurchaseDoc(
            PurchaseHeader."Document Type"::"Credit Memo", LibraryERM.CreateCurrencyWithRandomExchRates));
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        PurchCrMemoHdr.CalcFields(Amount);

        // [WHEN] Notification Entry with Type = "New Record" for the posted purchase credit memo "X"
        RecRef.GetTable(PurchCrMemoHdr);
        NotificationEntry.CreateNew(NotificationEntry.Type::"New Record", UserId, RecRef, 0, '');

        // [THEN] The message related to the notifications entry contains:
        // [THEN] "Purchase Credit Memo X"
        // [THEN] "Amount EUR A"
        // [THEN] "Vendor N (#V)"
        VerifyNotifyMessageForSalesPurchDocs(
          RecRef, 'Purchase Credit Memo', PurchCrMemoHdr."No.", PurchCrMemoHdr."Currency Code",
          'Vendor', Vendor.Name, Vendor."No.", PurchCrMemoHdr.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendCorrectNotificationEntriesWhenBatchIsProceeded()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
        JobQueueEntry: Record "Job Queue Entry";
        DeletedUserSetup: Record "User Setup";
    begin
        // [FEATURE] [Approval]
        // [SCENARIO 229462] When there are invalid Notification Entries in a batch, correct Entries are still processed by Notification Entry Dispatcher
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Workflow is setup to notify an existing user "U1"
        CreateNotificationEntryWithSetup(NotificationEntry, SalesHeader, UserId,
          NotificationSetup."Notification Type"::"New Record", NotificationSetup."Notification Method"::Note);

        // [GIVEN] Workflow is setup to notify a non-existing user "U2"
        LibraryDocumentApprovals.CreateMockupUserSetup(DeletedUserSetup);
        CreateNotificationEntryWithSetup(NotificationEntry, SalesHeader, DeletedUserSetup."User ID",
          NotificationSetup."Notification Type"::"New Record", NotificationSetup."Notification Method"::Note);
        DeletedUserSetup.Delete;

        Commit;

        // [WHEN] Run Notification Entry Dispatcher
        asserterror CODEUNIT.Run(CODEUNIT::"Notification Entry Dispatcher", JobQueueEntry);

        // [WHEN]  Error message "The User Setup does not exist" raised
        Assert.ExpectedError(StrSubstNo(UserSetupNotExistErr, DeletedUserSetup."User ID"));

        // [THEN] Record Link for "U1" was still created
        VerifyRecordLinkCreated(NotificationEntry, SalesHeader, UserId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAndModifySentNotificationEntryViaNotificationMgtWithoutDirectPermissions()
    var
        NotificationEntry: Record "Notification Entry";
        SentNotificationEntry: Record "Sent Notification Entry";
        UniqueCode1: Code[50];
        UniqueCode2: Code[50];
    begin
        // [FEATURE] [UT] [Permissions]
        // [SCENARIO 263714] Stan is able to insert a record and modify it in Sent Notification Entry table using Notification Management codeunit if he have no direct permissions to insert/modify for this table.
        Initialize;

        // [GIVEN] Two Notification Entry records
        UniqueCode1 := CopyStr(LibraryRandom.RandText(MaxStrLen(UniqueCode1)), 1, MaxStrLen(UniqueCode1));
        UniqueCode2 := CopyStr(LibraryRandom.RandText(MaxStrLen(UniqueCode1)), 1, MaxStrLen(UniqueCode1));
        MockNotificationEntry(NotificationEntry, NotificationEntry.Type::Approval, UniqueCode1);
        MockNotificationEntry(NotificationEntry, NotificationEntry.Type::Approval, UniqueCode2);
        NotificationEntry.Reset;
        NotificationEntry.FindSet;

        // [WHEN] Stan uses Notification Management codeunit to insert Sent Notification Entry records and modify them without direct permissions to insert/modify them.
        LibraryLowerPermissions.SetO365Basic;
        NotificationManagement.MoveNotificationEntryToSentNotificationEntries(
          NotificationEntry, LibraryRandom.RandText(20), true, SentNotificationEntry."Notification Method"::Email);

        // [THEN] Sent Notification Entry records are inserted.
        // [THEN] Second record is modified.
        VerifySentNotificationEntryInsertedAndModified(UniqueCode1, UniqueCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetNotificationSetupForUser_SetupExistsForRecipient()
    var
        UserSetup: Record "User Setup";
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 269111] GetNotificationSetupForUser returns setup for a certain user.
        Initialize;

        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);

        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserSetup."User ID",
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Email);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserSetup."Approver ID",
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);

        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserSetup."Approver ID");

        VerifyNotificationSetup(NotificationSetup, UserSetup."Approver ID", NotificationSetup."Notification Method"::Note);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetNotificationSetupForUser_SetupExistsForWrongUser()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 269111] GetNotificationSetupForUser returns setup for the current user if not found for a certain user.
        Initialize;

        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserId,
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);

        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, LibraryUtility.GenerateGUID);

        VerifyNotificationSetup(NotificationSetup, UserId, NotificationSetup."Notification Method"::Note);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetNotificationSetupForUser_SetupExistsForCurrentUser()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        NotificationManagement: Codeunit "Notification Management";
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 269111] GetNotificationSetupForUser returns setup for the current user.
        Initialize;

        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserId,
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);

        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserId);

        VerifyNotificationSetup(NotificationSetup, UserId, NotificationSetup."Notification Method"::Note);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetNotificationSetupForUser_SetupDefault()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 269111] GetNotificationSetupForUser return default setup when no setup found for the current user.
        Initialize;

        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);

        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserId);

        VerifyNotificationSetup(NotificationSetup, '', NotificationSetup."Notification Method"::Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetNotificationSetupForUser_SetupEmpty()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 269111] GetNotificationSetupForUser create and return default setup when no other setup found.
        Initialize;

        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserId);

        VerifyNotificationSetup(NotificationSetup, '', NotificationSetup."Notification Method"::Email);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SendersNotMixedWhenTwoUsersNotifyBySingleJobQueueEntry()
    var
        Item: Record Item;
        UserSetup: array[4] of Record "User Setup";
        User: array[4] of Record User;
        NotificationEntry: array[3] of Record "Notification Entry";
        ApprovalEntry: Record "Approval Entry";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowNotificationTest: Codeunit "Workflow Notification Test";
        Index: Integer;
        ExpectedValues: array[20] of Text;
    begin
        // [FEATURE] [SMTP] [Workflow] [Notification]
        // [SCENARIO 290651] Email Sender Name and Email are fetched from Approval Entry for Job Queue Entries with Job Queue Category = NOTIFYNOW
        Initialize;

        // [GIVEN] "User1" "User2" "User3" "User4" Users with emails
        for Index := 1 to ArrayLen(User) do
            CreateUserWithUserSetupWithEmail(User[Index], UserSetup[Index]);

        // [GIVEN] SMTP Mail Setup with Anonymous authentication and User ID is blank
        CreateAnonymousSMTPMailSetup;

        // [GIVEN] Item and Approval Entry for it
        LibraryInventory.CreateItem(Item);
        LibraryDocumentApprovals.CreateApprovalEntryBasic(
          ApprovalEntry, DATABASE::Item, 0, Item."No.",
          ApprovalEntry.Status::Created, ApprovalEntry."Limit Type"::"Approval Limits",
          Item.RecordId, ApprovalEntry."Approval Type"::Approver, 0D, 0);

        // [WHEN] Three Notification Entries created at the same time: 1 sent from "User1" to "User2", 2 sent from "User3" to "User4", 3 sent from "User1" to "User4"
        NotificationEntry[1].CreateNewEntry(
          NotificationEntry[1].Type::Approval, UserSetup[2]."User ID", ApprovalEntry, 1, '', UserSetup[1]."User ID");
        NotificationEntry[2].CreateNewEntry(
          NotificationEntry[2].Type::Approval, UserSetup[4]."User ID", ApprovalEntry, 1, '', UserSetup[3]."User ID");
        NotificationEntry[3].CreateNewEntry(
          NotificationEntry[3].Type::Approval, UserSetup[4]."User ID", ApprovalEntry, 1, '', UserSetup[1]."User ID");

        // [THEN] Email Body Text for three Notification Entries contains "User1" and "User3" names respectively for 'Created By' information
        ExpectedValues[1] := StrSubstNo(CreatedByUserTxt, User[1]."Full Name");
        VerifyNotificationBodyText(NotificationEntry[1], ExpectedValues);

        ExpectedValues[1] := StrSubstNo(CreatedByUserTxt, User[3]."Full Name");
        VerifyNotificationBodyText(NotificationEntry[2], ExpectedValues);

        ExpectedValues[1] := StrSubstNo(CreatedByUserTxt, User[1]."Full Name");
        VerifyNotificationBodyText(NotificationEntry[3], ExpectedValues);

        // [THEN] 1 Job Queue Entry created for Two Notification Entries
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategory.NotifyNowCode);
        JobQueueEntry.FindFirst;
        Assert.RecordCount(JobQueueEntry, 1);

        // [WHEN] Notification Entry Dispatcher executed for Job Queue Entry - SubscriberOnBeforeQualifyFromAddress catch sender Email and Name
        BindSubscription(WorkflowNotificationTest);
        CODEUNIT.Run(CODEUNIT::"Notification Entry Dispatcher", JobQueueEntry);

        // [THEN] Three emails generated: 2 from "User1" Email and Full Name, 1 from "User3" Email and Full Name
        VerifyDataTypeBuffer(User[1]."Full Name");
        VerifyDataTypeBuffer(UserSetup[1]."E-Mail");
        VerifyDataTypeBuffer(User[1]."Full Name");
        VerifyDataTypeBuffer(UserSetup[1]."E-Mail");

        VerifyDataTypeBuffer(User[3]."Full Name");
        VerifyDataTypeBuffer(UserSetup[3]."E-Mail");

        Assert.RecordIsEmpty(DataTypeBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenNotificationSetupPageNoFilterNoUser()
    var
        NotificationSetupPage: TestPage "Notification Setup";
    begin
        // [FEATURE] [Notification Setup] [UI]
        // [SCENARIO 319022] Filter for "User ID" is applied on Notification Setup page only when there are no filters on the record and no record selected.
        // [SCENARIO 319022] No record-filters, no record selected - empty "User ID" filters applied.
        Initialize;

        // [WHEN] Open Notification Setup page with no record-filters and no record selected
        NotificationSetupPage.OpenView;

        // [THEN] Empty "User ID" filters applied on Notification Setup page
        Assert.AreEqual('''''', NotificationSetupPage.FILTER.GetFilter("User ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenNotificationSetupPageNoFilterUser()
    var
        UserSetup: Record "User Setup";
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        NotificationSetupPage: TestPage "Notification Setup";
    begin
        // [FEATURE] [Notification Setup] [UI]
        // [SCENARIO 319022] Filter for "User ID" is applied on Notification Setup page only when there are no filters on the record and no record selected.
        // [SCENARIO 319022] No record-filters, a record selected - "User ID" filter's applied.
        Initialize;

        // [GIVEN] Created User Setup and Notification Setup for that User
        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserSetup."User ID",
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Email);
        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserSetup."Approver ID");

        // [GIVEN] Select a Notification Setup record
        NotificationSetup.Get(UserSetup."User ID", NotificationSetup."Notification Type"::Approval);

        // [WHEN] Open Notification Setup page with no record-filters and a record selected
        NotificationSetupPage.Trap;
        PAGE.Run(PAGE::"Notification Setup", NotificationSetup);

        // [THEN] "User ID" filter's applied on Notification Setup page
        Assert.AreEqual(UserSetup."User ID", NotificationSetupPage.FILTER.GetFilter("User ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenNotificationSetupPageFilterNoUser()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationSetupPage: TestPage "Notification Setup";
    begin
        // [FEATURE] [Notification Setup] [UI]
        // [SCENARIO 319022] Filter for "User ID" is applied on Notification Setup page only when there are no filters on the record and no record selected.
        // [SCENARIO 319022] Record-filters enabled, no record selected - no "User ID" filters applied.
        Initialize;

        // [GIVEN] Set a filter on an empty Notification Setup record
        NotificationSetup.SetRange("Notification Type", NotificationSetup."Notification Type"::Approval);

        // [WHEN] Open Notification Setup page with record-filters and no record selected
        NotificationSetupPage.Trap;
        PAGE.Run(PAGE::"Notification Setup", NotificationSetup);

        // [THEN] No "User ID" filters applied on Notification Setup page
        Assert.AreEqual('', NotificationSetupPage.FILTER.GetFilter("User ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenNotificationSetupPageFilterAndUser()
    var
        UserSetup: Record "User Setup";
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        NotificationSetupPage: TestPage "Notification Setup";
    begin
        // [FEATURE] [Notification Setup] [UI]
        // [SCENARIO 319022] Filter for "User ID" is applied on Notification Setup page only when there are no filters on the record and no record selected.
        // [SCENARIO 319022] Record-filters enabled, a record selected - no "User ID" filters applied.
        Initialize;

        // [GIVEN] Created User Setup and Notification Setup for that User
        NotificationManagement.CreateDefaultNotificationSetup(NotificationSetup."Notification Type"::Approval);
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserSetup."User ID",
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Email);
        NotificationSetup.GetNotificationSetupForUser(NotificationEntry.Type::Approval, UserSetup."Approver ID");

        // [GIVEN] Set a filter on a selected Notification Setup record
        NotificationSetup.SetRange("Notification Type", NotificationSetup."Notification Type"::Approval);

        // [WHEN] Open Notification Setup page with record-filters and a record selected
        NotificationSetupPage.Trap;
        PAGE.Run(PAGE::"Notification Setup", NotificationSetup);

        // [THEN] No "User ID" filters applied on Notification Setup page
        Assert.AreEqual('', NotificationSetupPage.FILTER.GetFilter("User ID"), '');
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        NotificationEntry: Record "Notification Entry";
        SentNotificationEntry: Record "Sent Notification Entry";
        ApprovalEntry: Record "Approval Entry";
        NotificationSetup: Record "Notification Setup";
        DataTypeBuffer: Record "Data Type Buffer";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryWorkflow.SetUpSMTPEmailSetup;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        if not UserSetup.Get(UserId) then begin
            UserSetup."User ID" := UserId;
            UserSetup."E-Mail" := UserEmailAddressTxt;
            UserSetup.Insert;
        end else
            if UserSetup."E-Mail" = '' then begin
                UserSetup."E-Mail" := UserEmailAddressTxt;
                UserSetup.Modify;
            end;

        LibraryWorkflow.DeleteAllExistingWorkflows;
        ApprovalEntry.DeleteAll;
        NotificationEntry.DeleteAll;
        SentNotificationEntry.DeleteAll;
        NotificationSetup.DeleteAll;
        DataTypeBuffer.DeleteAll(true);
        SetupApprovalAdministrator;

        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure TestPurchaseApprovalNotificationBase(Status: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        ApprovalCommentLine: Record "Approval Comment Line";
        NotificationEntry: Record "Notification Entry";
        RecRefPurchaseHeader: RecordRef;
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        CreatePurchaseApprovalEntry(ApprovalEntry, PurchaseHeader, Status);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        RecRefPurchaseHeader.GetTable(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(PurchaseHeader."Document Type");
        ExpectedValues[3] := Format(PurchaseHeader."No.");
        ExpectedValues[4] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[6] := WorkflowStepArgument."Custom Link";
        ExpectedValues[7] := ApprovalEntry.FieldCaption(Amount);
        ExpectedValues[8] := VendorTxt;
        ExpectedValues[9] := ApprovalEntry.FieldCaption("Due Date");
        ExpectedValues[10] := PurchaseHeader."Pay-to Vendor No.";
        ExpectedValues[11] := Format(PurchaseHeader.Amount);
    end;

    local procedure TestPurchaseApprovalNotification(Status: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestPurchaseApprovalNotificationBase(Status, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestSalesApprovalNotificationBase(Status: Option; LimitType: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateSalesApprovalEntry(ApprovalEntry, SalesHeader, Status, LimitType);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        SalesHeader.CalcFields(Amount);

        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(SalesHeader."Document Type");
        ExpectedValues[3] := SalesHeader."No.";
        ExpectedValues[4] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[5] := WorkflowStepArgument."Custom Link";
        ExpectedValues[6] := ApprovalEntry.FieldCaption(Amount);
        ExpectedValues[7] := CustomerTxt;
        ExpectedValues[8] := ApprovalEntry.FieldCaption("Due Date");
        ExpectedValues[9] := SalesHeader."Bill-to Customer No.";
        ExpectedValues[10] := Format(SalesHeader.Amount);
    end;

    local procedure TestSalesApprovalNotification(Status: Option; LimitType: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestSalesApprovalNotificationBase(Status, LimitType, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestItemApprovalNotificationBase(Status: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        Item: Record Item;
        NotificationEntry: Record "Notification Entry";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemApprovalEntry(ApprovalEntry, Item, Status);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval,
          WorkflowStepArgument."Notification User ID", ApprovalEntry, WorkflowStepArgument."Link Target Page",
          WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[3] := WorkflowStepArgument."Custom Link";
        ExpectedValues[4] := ApprovalEntry.FieldCaption("Due Date");
    end;

    local procedure TestItemApprovalNotification(Status: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestItemApprovalNotificationBase(Status, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestCustomerApprovalNotification(Status: Option; LimitType: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestCustomerApprovalNotificationBase(Status, LimitType, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestCustomerApprovalNotificationBase(Status: Option; LimitType: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerApprovalEntry(ApprovalEntry, Customer, Status, LimitType);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := Format(Customer."No.");
        ExpectedValues[3] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[4] := WorkflowStepArgument."Custom Link";
        ExpectedValues[5] := CustomerTxt;
        ExpectedValues[6] := ApprovalEntry.FieldCaption("Due Date");
    end;

    local procedure TestGenJnlLineApprovalNotification(Status: Option; LimitType: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestGenJnlLineApprovalNotificationBase(Status, LimitType, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestGenJnlLineApprovalNotificationBase(Status: Option; LimitType: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", '', 100);
        CreateGenJournalLineApprovalEntry(ApprovalEntry, GenJournalLine, Status, LimitType);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);

        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := GenJournalLine."Journal Template Name" + ',' +
          GenJournalLine."Journal Batch Name" + ',' + Format(GenJournalLine."Line No.");
        ExpectedValues[3] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[4] := WorkflowStepArgument."Custom Link";
        ExpectedValues[5] := ApprovalEntry.FieldCaption(Amount);
        ExpectedValues[6] := ApprovalEntry.FieldCaption("Due Date");
        ExpectedValues[7] := Format(GenJournalLine.Amount);
    end;

    local procedure TestGenJnlBatchApprovalNotification(Status: Option; LimitType: Option)
    var
        RecRef: RecordRef;
        ExpectedValues: array[20] of Text;
    begin
        // Setup.
        Initialize;

        // Exercise
        TestGenJnlBatchApprovalNotificationBase(Status, LimitType, RecRef, ExpectedValues);

        // Verify
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure TestGenJnlBatchApprovalNotificationBase(Status: Option; LimitType: Option; var RecRef: RecordRef; var ExpectedValues: array[20] of Text)
    var
        NotificationEntry: Record "Notification Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", '',
          GenJournalLine."Account Type"::"G/L Account", '', 100);

        CreateGenJournalBatchApprovalEntry(ApprovalEntry, GenJournalBatch, Status, LimitType);
        AddApprovalComment(ApprovalCommentLine, ApprovalEntry);
        SetupArgumentForNotifications(WorkflowStepInstance, WorkflowStepArgument);

        // Exercise.
        NotificationEntry.CreateNew(NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link");

        // Verify.
        RecRef.GetTable(ApprovalEntry);
        ExpectedValues[1] := TitleTxt;
        ExpectedValues[2] := GenJournalBatch."Journal Template Name" + ',' + GenJournalBatch.Name;
        ExpectedValues[3] := NotificationManagement.GetActionTextFor(NotificationEntry);
        ExpectedValues[4] := WorkflowStepArgument."Custom Link";
        ExpectedValues[6] := ApprovalEntry.FieldCaption("Due Date");
    end;

    local procedure CreateResponseArgumentForNotifications(var WorkflowStepArgument: Record "Workflow Step Argument")
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          UserId, '', '', 0, true);
    end;

    local procedure SetupArgumentForNotifications(var WorkflowStepInstance: Record "Workflow Step Instance"; var WorkflowStepArgument: Record "Workflow Step Argument")
    begin
        CreateResponseArgumentForNotifications(WorkflowStepArgument);
        WorkflowStepArgument."Custom Link" := LibraryUtility.GenerateGUID;
        WorkflowStepArgument.Modify;
        WorkflowStepInstance.Argument := WorkflowStepArgument.ID;
        WorkflowStepInstance.Type := WorkflowStepInstance.Type::Response;
    end;

    local procedure SetupApprovalAdministrator()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId);
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify;
    end;

    local procedure SetupCurrentUserAndApproverWithNotificationSetup(var CurrentUserSetup: Record "User Setup")
    var
        ApproverUserSetup: Record "User Setup";
        NotificationSetup: Record "Notification Setup";
    begin
        LibraryDocumentApprovals.SetupUserWithApprover(CurrentUserSetup);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserId,
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);
        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, ApproverUserSetup."User ID",
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);
    end;

    local procedure PrepareRejectScenario(var CurrentUserSetup: Record "User Setup"; var SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        SetupCurrentUserAndApproverWithNotificationSetup(CurrentUserSetup);
        CreateApprovalWorkflowForSalesDocWithRejectNotification;

        LibrarySales.CreateSalesInvoice(SalesHeader);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Notification Entry Dispatcher");
        JobQueueEntry.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Notification Entry Dispatcher", JobQueueEntry);
    end;

    local procedure CreatePurchaseApprovalEntry(var ApprovalEntry: Record "Approval Entry"; PurchaseHeader: Record "Purchase Header"; ApprovalStatus: Option)
    begin
        PurchaseHeader.CalcFields(Amount);
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.",
              ApprovalStatus, "Limit Type"::"Approval Limits", PurchaseHeader.RecordId,
              "Approval Type"::Approver, 0D, PurchaseHeader.Amount);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateOverdueApprovalEntry(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DueDate: Date)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        RecRef.FindFirst;
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, TableID, "Document Type"::Invoice, LibraryUtility.GenerateGUID,
              Status::Open, "Limit Type"::"Approval Limits", RecRef.RecordId, "Approval Type"::Approver, DueDate, 0);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateDelegateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DelegateFormula: Text)
    var
        DummyRecId: RecordID;
    begin
        with ApprovalEntry do begin
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, TableID, "Document Type"::Invoice, LibraryUtility.GenerateGUID,
              Status::Open, "Limit Type"::"Approval Limits", DummyRecId,
              "Approval Type"::Approver, 0D, 0);
            Evaluate("Delegation Date Formula", DelegateFormula);
            Modify(true);
        end;
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateSalesApprovalEntry(var ApprovalEntry: Record "Approval Entry"; SalesHeader: Record "Sales Header"; ApprovalStatus: Option; LimitType: Option)
    begin
        SalesHeader.CalcFields(Amount);
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
              ApprovalStatus, LimitType, SalesHeader.RecordId,
              "Approval Type"::Approver, WorkDate, SalesHeader.Amount);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateItemApprovalEntry(var ApprovalEntry: Record "Approval Entry"; Item: Record Item; StatusOption: Option)
    begin
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::Item, "Document Type"::" ", "Document No.",
              StatusOption, "Limit Type"::"No Limits", Item.RecordId,
              "Approval Type"::Approver, WorkDate, 0);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateCustomerApprovalEntry(var ApprovalEntry: Record "Approval Entry"; Customer: Record Customer; StatusOption: Option; LimitType: Option)
    begin
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::Customer, "Document Type"::" ", "Document No.",
              StatusOption, LimitType, Customer.RecordId,
              "Approval Type"::Approver, WorkDate, 0);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateGenJournalLineApprovalEntry(var ApprovalEntry: Record "Approval Entry"; GenJournalLine: Record "Gen. Journal Line"; StatusOption: Option; LimitType: Option)
    begin
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::"Gen. Journal Line", GenJournalLine."Document Type", GenJournalLine."Document No.",
              StatusOption, LimitType, GenJournalLine.RecordId,
              "Approval Type"::Approver, WorkDate, GenJournalLine.Amount);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateGenJournalBatchApprovalEntry(var ApprovalEntry: Record "Approval Entry"; GenJournalBatch: Record "Gen. Journal Batch"; StatusOption: Option; LimitType: Option)
    begin
        with ApprovalEntry do
            LibraryDocumentApprovals.CreateApprovalEntryBasic(
              ApprovalEntry, DATABASE::"Gen. Journal Batch", "Document Type", "Document No.",
              StatusOption, LimitType, GenJournalBatch.RecordId,
              "Approval Type"::Approver, WorkDate, 0);
        SetApprovalEntryData(ApprovalEntry);
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Option; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostSalesDoc(DocumentType: Option; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, DocumentType, CurrencyCode);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostPurchaseDoc(DocumentType: Option; CurrencyCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDoc(PurchaseHeader, DocumentType, CurrencyCode);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateNotificationEntryWithSetup(var NotificationEntry: Record "Notification Entry"; SalesHeader: Record "Sales Header"; UserID: Code[50]; NotificationType: Option; NotificationMethod: Option)
    var
        NotificationSetup: Record "Notification Setup";
    begin
        NotificationEntry.CreateNew(NotificationType, UserID, SalesHeader, 0, '');
        LibraryWorkflow.CreateNotificationSetup(NotificationSetup, UserID, NotificationType, NotificationMethod);
    end;

    local procedure CreateUserWithUserSetupWithEmail(var User: Record User; var UserSetup: Record "User Setup")
    begin
        LibraryPermissions.CreateUser(User, LibraryUtility.GenerateGUID, true);

        UserSetup.Init;
        UserSetup."User ID" := User."User Name";
        UserSetup."E-Mail" := LibraryUtility.GenerateGUID + '@cronusus.com';
        UserSetup.Insert;
    end;

    local procedure CreateAnonymousSMTPMailSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        SMTPMailSetup.DeleteAll;
        SMTPMailSetup.Init;
        SMTPMailSetup."SMTP Server" := 'localhost';
        SMTPMailSetup."SMTP Server Port" := 25;
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Anonymous;
        SMTPMailSetup."Allow Sender Substitution" := TRUE;
        SMTPMailSetup.Insert;
    end;

    local procedure MockNotificationEntry(var NotificationEntry: Record "Notification Entry"; Type: Option; UserId: Code[50])
    begin
        NotificationEntry.Init;
        NotificationEntry.ID := 0;
        NotificationEntry.Type := Type;
        NotificationEntry."Recipient User ID" := UserId;
        NotificationEntry.Insert;
    end;

    local procedure GetSalesDocumentURLFilter(DocumentType: Integer; DocumentNo: Code[20]) URLFilter: Text
    var
        Regex: DotNet Regex;
    begin
        URLFilter := StrSubstNo('''Document Type'' IS ''%1'' AND ''No.'' IS ''%2''', DocumentType, DocumentNo);
        Regex := Regex.Regex(' ');
        URLFilter := Regex.Replace(URLFilter, '%20');
    end;

    local procedure SetApprovalEntryData(var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry."Date-Time Sent for Approval" := CreateDateTime(Today, Time);
        ApprovalEntry."Last Date-Time Modified" := CreateDateTime(Today, Time);
        ApprovalEntry."Last Modified By User ID" := UserId;
        ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::Approver;
        ApprovalEntry."Available Credit Limit (LCY)" := LibraryRandom.RandDec(1000, 2);
        ApprovalEntry.Modify(true);
    end;

    local procedure AddApprovalComment(var ApprovalCommentLine: Record "Approval Comment Line"; ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalCommentLine.Init;
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        ApprovalCommentLine.Insert(true);
        ApprovalCommentLine.Comment := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ApprovalCommentLine.Comment)), 1,
            MaxStrLen(ApprovalCommentLine.Comment));
        ApprovalCommentLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertDataTypeBuffer(EventText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        if DataTypeBuffer.FindLast then;

        DataTypeBuffer.Init;
        DataTypeBuffer.ID += 1;
        DataTypeBuffer.Text := CopyStr(EventText, 1, MaxStrLen(DataTypeBuffer.Text));
        DataTypeBuffer.Insert;
    end;

    [Scope('OnPrem')]
    procedure VerifyDataTypeBuffer(VerifyText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, VerifyText);
        Assert.RecordIsNotEmpty(DataTypeBuffer);
        DataTypeBuffer.FindFirst;
        DataTypeBuffer.Delete;
    end;

    local procedure VerifyNotificationEntry(var RecRef: RecordRef; ExpectedValues: array[20] of Text; IndividualNotifications: Boolean)
    var
        NotificationEntry: Record "Notification Entry";
    begin
        if IndividualNotifications then
            NotificationEntry.SetRange("Triggered By Record", RecRef.RecordId);
        NotificationEntry.SetCurrentKey("Recipient User ID");
        NotificationEntry.SetRange("Recipient User ID", UserId);
        NotificationEntry.FindFirst;

        VerifyNotificationBodyText(NotificationEntry, ExpectedValues);
    end;

    local procedure VerifyNotificationBodyText(NotificationEntry: Record "Notification Entry"; ExpectedValues: array[20] of Text)
    var
        NotificationEntryDispatcher: Codeunit "Notification Entry Dispatcher";
        HtmlBodyText: Text;
        index: Integer;
    begin
        NotificationEntryDispatcher.GetHTMLBodyText(NotificationEntry, HtmlBodyText);

        for index := 1 to ArrayLen(ExpectedValues) do
            if ExpectedValues[index] <> '' then
                Assert.AreNotEqual(0, StrPos(HtmlBodyText, ExpectedValues[index]),
                  'Value ' + ExpectedValues[index] + ' not found in body.');
    end;

    local procedure VerifyNotificationsForRecipient(RecipientID: Code[50]; ExpectedValues: array[20] of Text)
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Recipient User ID", RecipientID);
        NotificationEntry.FindSet;
        repeat
            VerifyNotificationBodyText(NotificationEntry, ExpectedValues);
        until NotificationEntry.Next = 0;
    end;

    local procedure VerifyNotificationSetup(var NotificationSetup: Record "Notification Setup"; UserCode: Code[50]; NotificationMethod: Option)
    begin
        NotificationSetup.TestField("Notification Type", NotificationSetup."Notification Type"::Approval);
        NotificationSetup.TestField("Notification Method", NotificationMethod);
        NotificationSetup.TestField("User ID", UserCode);
    end;

    local procedure VerifyOverdueLogEntry(ApprovalEntry: Record "Approval Entry")
    var
        OverdueApprovalEntry: Record "Overdue Approval Entry";
    begin
        OverdueApprovalEntry.SetRange("Table ID", ApprovalEntry."Table ID");
        OverdueApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type");
        OverdueApprovalEntry.SetRange("Document No.", ApprovalEntry."Document No.");
        OverdueApprovalEntry.SetRange("Sequence No.", ApprovalEntry."Sequence No.");
        Assert.AreEqual(1, OverdueApprovalEntry.Count, 'Unexpected log entries');
        OverdueApprovalEntry.FindFirst;
        OverdueApprovalEntry.TestField("Sent to ID", ApprovalEntry."Approver ID");
        OverdueApprovalEntry.TestField("Approver ID", ApprovalEntry."Approver ID");
        OverdueApprovalEntry.TestField("Due Date", ApprovalEntry."Due Date");
        OverdueApprovalEntry.TestField("Approval Type", ApprovalEntry."Approval Type");
        OverdueApprovalEntry.TestField("Limit Type", ApprovalEntry."Limit Type");
    end;

    local procedure VerifyDelegatedApprovalEntry(ApprovalEntry: Record "Approval Entry"; NewApproverUserSetup: Record "User Setup")
    var
        DelegatedApprovalEntry: Record "Approval Entry";
    begin
        DelegatedApprovalEntry.SetRange("Table ID", ApprovalEntry."Table ID");
        DelegatedApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type");
        DelegatedApprovalEntry.SetRange("Document No.", ApprovalEntry."Document No.");
        DelegatedApprovalEntry.SetRange("Sequence No.", ApprovalEntry."Sequence No.");
        Assert.AreEqual(1, DelegatedApprovalEntry.Count, 'Unexpected log entries');
        DelegatedApprovalEntry.FindFirst;
        DelegatedApprovalEntry.TestField("Approver ID", NewApproverUserSetup."User ID");
        DelegatedApprovalEntry.TestField("Due Date", ApprovalEntry."Due Date");
        DelegatedApprovalEntry.TestField("Approval Type", ApprovalEntry."Approval Type");
        DelegatedApprovalEntry.TestField("Limit Type", ApprovalEntry."Limit Type");
    end;

    local procedure VerifyRecordLinkCreated(NotificationEntry: Record "Notification Entry"; SalesHeader: Record "Sales Header"; UserID: Code[50])
    var
        RecordLink: Record "Record Link";
        TriggeredByRecRef: RecordRef;
        LinkFilter: Text;
    begin
        RecordLink.SetRange("User ID", UserID);
        RecordLink.SetRange("Record ID", NotificationEntry."Triggered By Record");
        RecordLink.FindFirst;

        TriggeredByRecRef.Get(NotificationEntry."Triggered By Record");
        LinkFilter := GetSalesDocumentURLFilter(SalesHeader."Document Type", SalesHeader."No.");

        Assert.AreNotEqual(0, StrPos(RecordLink.URL1, LinkFilter), URLFilterNotFoundErr);
    end;

    local procedure CreateApprovalWorkflowForSalesDocWithRejectNotification()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointStepID: Integer;
        FirstResponse: Integer;
        RejectResponse: Integer;
        SecondResponse: Integer;
        SecondStepID: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointStepID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode);

        FirstResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode, EntryPointStepID);

        SecondResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode, FirstResponse);

        WorkflowStep.SetRange(ID, FirstResponse);
        WorkflowStep.FindFirst;
        LibraryWorkflow.UpdateWorkflowStepArgumentApproverLimitType(
          WorkflowStep.Argument, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", '', '');

        SecondStepID :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode, SecondResponse);

        RejectResponse :=
            LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode, SecondStepID);
        LibraryWorkflow.SetNotifySenderInResponse(Workflow.Code, RejectResponse);

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure VerifyNotifyMessageForSalesPurchDocs(RecRef: RecordRef; DocTitle: Text; DocNo: Text; CurrencyCode: Text; CVTitle: Text; CVName: Text; CVNo: Text; Amount: Decimal)
    var
        ExpectedValues: array[20] of Text;
    begin
        ExpectedValues[1] := DocTitle + ' ' + DocNo;
        ExpectedValues[2] := 'Amount';
        ExpectedValues[3] := CurrencyCode;
        ExpectedValues[4] := Format(Amount, 0, '<Precision,2><Standard Format,0>');
        ExpectedValues[5] := CVTitle;
        ExpectedValues[6] := CVName + ' (#' + CVNo + ')';
        VerifyNotificationEntry(RecRef, ExpectedValues, true);
    end;

    local procedure VerifySentNotificationEntryInsertedAndModified(UniqueCode1: Code[50]; UniqueCode2: Code[50])
    var
        SentNotificationEntry: Record "Sent Notification Entry";
        InitialSentNotificationEntryID: Integer;
    begin
        SentNotificationEntry.Reset;
        SentNotificationEntry.SetRange("Recipient User ID", UniqueCode1);
        Assert.IsTrue(
          SentNotificationEntry.FindFirst, 'Sent Notification Entry record was not inserted.');

        InitialSentNotificationEntryID := SentNotificationEntry.ID;
        SentNotificationEntry.SetRange("Recipient User ID", UniqueCode2);
        SentNotificationEntry.FindFirst;
        SentNotificationEntry.TestField("Aggregated with Entry", InitialSentNotificationEntryID);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, 9520, 'OnBeforeQualifyFromAddress', '', false, false)]
    [Scope('OnPrem')]
    procedure SubscriberOnBeforeQualifyFromAddress(var TempEmailItem: Record "Email Item" temporary)
    begin
        InsertDataTypeBuffer(TempEmailItem."From Address");
        InsertDataTypeBuffer(TempEmailItem."From Name");
    end;
}

