codeunit 134331 "ERM Purchase Payables"
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
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
#if not CLEAN25
        LibraryCosting: Codeunit "Library - Costing";
        LibraryApplicationArea: Codeunit "Library - Application Area";
#endif
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        IsInitialized: Boolean;
        MustNotBeEqualErr: Label 'Transaction No. %1 and %2 must not be equal.', Comment = '%1=Transaction1;%2=Transaction2';
        PostingDateErr: Label 'Enter the posting date.';
        UnknownErr: Label 'Unknown Error';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1=Field;%2=Value;%3=Table';
        FilterMsg: Label 'There should be record within the filter.';
        NoFilterMsg: Label 'There should be no record within the filter.';
        PurchOrderArchiveRespCenterErr: Label 'Purchase Order Archives displays documents for Responisbility Center that should not be shown for current user';
#if not CLEAN25
        MultipleVendorsSelectedErr: Label 'More than one vendor uses these purchase prices. To copy prices, the Vendor No. Filter field must contain one vendor only.';
        InvalidItemNoFilterErr: Label 'Invalid Item No. filter for page %1.', Comment = '%1 - page caption';
        InvalidValueErr: Label 'Invalid %1 value', Comment = '%1 - field name';
        ViewExistingTxt: Label 'View Existing Prices and Discounts...';
        CreateNewTxt: Label 'Create New...';
        FieldEnabledErr: Label 'Field %1 must be enabled.', Comment = '%1 - field name';
        IsNotFoundErr: Label 'is not found on the page';
#endif
        DateFormulaReverseErr: Label 'Date formula has been reversed incorrectly.';
        InvoiceMessageErr: Label 'Invoice Message must have a value in Purchase Header: Document Type=%1, No.=%2. It cannot be zero or empty.';
        NotificationBatchPurchHeaderMsg: Label 'An error or warning occured during operation Batch processing of Purchase Header records.';
        VendorInvNoErr: Label 'You need to enter the document number of the document from the vendor in the Vendor Invoice No. field';
        CannotRenameItemUsedInPurchaseLinesErr: Label 'You cannot rename %1 in a %2, because it is used in purchase document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvdBlnktPurchOrders()
    var
        PurchHeader: Record "Purchase Header";
        OrderPurchHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        BlanketPONumber: Code[20];
        expectedOrderNo: Code[20];
    begin
        // 1. Setup
        Initialize();
        CreateOneItemPurchDoc(PurchHeader, PurchHeader."Document Type"::"Blanket Order");

        // Find the number series used and gather the next value in advance.
        PurchasesPayablesSetup.Get();
        expectedOrderNo := NoSeries.PeekNextNo(PurchasesPayablesSetup."Order Nos.");

        // Make an order
        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchHeader);

        // Find the created order and ship and invoice it.
        OrderPurchHeader.SetRange("No.", expectedOrderNo);
        OrderPurchHeader.FindFirst();
        OrderPurchHeader.Validate("Vendor Invoice No.", OrderPurchHeader."No.");
        OrderPurchHeader.Modify(true);

        LibraryPurchase.PostPurchaseDocument(OrderPurchHeader, true, true);

        // Retrieve the Id so we can ensure it has been deleted.
        BlanketPONumber := PurchHeader."No.";

        // 2. Exercise
        // Since the purchase order has been posted and invoiced for all the quantity in the blanket purchase order, now the report should
        // delete the blanket purchase order we created.
        REPORT.Run(REPORT::"Delete Invd Blnkt Purch Orders", false);

        // 3. Verification
        Assert.IsFalse(PurchHeader.Get(PurchHeader."Document Type"::"Blanket Order", BlanketPONumber),
          'Invoiced Blanket Purchase Order shouldn''t exist.');

        // 4. Clean-up
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLineItem: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        PurchLineGLAcc: Record "Purchase Line";
        PurchLineFixedAsset: Record "Purchase Line";
        PurchLineChargeItem: Record "Purchase Line";
        PurchLineResource: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // 1. Setup
        Initialize();

        // Find an item, G/L account, Fixed Asset and (Charge) Item for an invoice
        FixedAsset.FindFirst();

        // Create a new invoiced blanket purchase order
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchLineItem, PurchHeader, PurchLineItem.Type::Item, '', LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(PurchLineGLAcc, PurchHeader, PurchLineGLAcc.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(PurchLineFixedAsset, PurchHeader, PurchLineFixedAsset.Type::"Fixed Asset", FixedAsset."No.",
          LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(PurchLineChargeItem, PurchHeader, PurchLineFixedAsset.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(
            PurchLineResource, PurchHeader, PurchLineResource.Type::Resource, LibraryResource.CreateResourceNo(), LibraryRandom.RandInt(100));

        // 2. Exercise
        ArchiveManagement.ArchivePurchDocument(PurchHeader);

        // 3. Verification
        // "No. of Archived Versions" is a flow field so we must force recalculate before checking the new value.
        PurchHeader.CalcFields("No. of Archived Versions");
        Assert.AreEqual(1, PurchHeader."No. of Archived Versions", 'No. of archived versions in PO archived once is not 1.');

        VerifyArchPurchaseOrderHeader(PurchHeader);

        VerifyArchPurchaseOrderLine(PurchLineItem);
        VerifyArchPurchaseOrderLine(PurchLineGLAcc);
        VerifyArchPurchaseOrderLine(PurchLineFixedAsset);
        VerifyArchPurchaseOrderLine(PurchLineChargeItem);
        VerifyArchPurchaseOrderLine(PurchLineResource);

        // 4. Clean-up
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchivePurchOrdersSeveralTimes()
    var
        PurchHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        counter: Integer;
        NumberOfArchivements: Integer;
    begin
        // 1. Setup
        Initialize();
        CreateOneItemPurchDoc(PurchHeader, PurchHeader."Document Type"::Order);
        NumberOfArchivements := LibraryRandom.RandInt(5) + 1;

        // 2. Exercise
        for counter := 1 to NumberOfArchivements do
            ArchiveManagement.ArchivePurchDocument(PurchHeader);

        // 3. Verification
        // "No. of Archived Versions" is a flow field so we must force recalculate before checking the new value.
        PurchHeader.CalcFields("No. of Archived Versions");
        Assert.AreEqual(NumberOfArchivements, PurchHeader."No. of Archived Versions",
          'No. of archived versions in PO archived multiple times is not as expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTransactionNo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // Verify Transaction Number Entries after posting Purchase Invoice.

        // Setup: Update Unrealized VAT on General Ledger Setup. Create G/L Accounts with VAT Posting Setup.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        CreateSetupForGLAccounts(VATPostingSetup, GLAccountNo);

        // Exercise: Create and post Purchase Invoice.
        PostedDocumentNo := CreateAndPostPurchaseInvoice(VATPostingSetup."VAT Bus. Posting Group", GLAccountNo);

        // Verify: Verify Transaction Number Entries.
        VerifyTransactionNoOnGLEntries(PostedDocumentNo);

        // Tear down: Rollback Unrealized VAT On General Ledger Setup.
        DeleteVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeveralLinesTransactionNo()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Verify Transaction Number Entries after posting several Journal Lines.

        // Setup: Find G/L Accounts.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        // Exercise: Create and post several Journal Lines with Random Amount.
        CreateGeneralJournalBatch(GenJournalBatch, true);
        Amount := CreateMultipleJournalLines(GenJournalLine, GenJournalBatch, GLAccount."No.");
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount2."No.", -Amount / 2);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount."No.", -Amount / 2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Transaction Number Entries.
        VerifyTransactionNoOnGLEntries(GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransactionNoForceBalanceOff()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Verify Transaction Number Entries after posting several Journal Lines with Force Document Balance Off.

        // Setup: Find G/L Accounts.
        Initialize();
        CreateGLAccountWithVAT(GLAccount);
        CreateGLAccountWithVAT(GLAccount2);

        // Exercise: Create and post Journal Lines with Force Document Balance Off and Random Amount.
        CreateGeneralJournalBatch(GenJournalBatch, false);
        Amount := CreateMultipleJournalLines(GenJournalLine, GenJournalBatch, GLAccount."No.");
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount2."No.", -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Transaction Number Entries.
        VerifyTransactionNoOnGLEntries(GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransactionNoForceBalanceOn()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Verify Transaction Number Entries after posting several Journal Lines with Force Document Balance On.

        // Setup: Find G/L Accounts.
        Initialize();
        CreateGLAccountWithVAT(GLAccount);
        CreateGLAccountWithVAT(GLAccount2);

        // Exercise: Create and post Journal Lines with Force Document Balance On and Random Amount.
        CreateGeneralJournalBatch(GenJournalBatch, true);
        Amount := CreateMultipleJournalLines(GenJournalLine, GenJournalBatch, GLAccount."No.");
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount2."No.", -Amount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount."No.", LibraryRandom.RandDec(100, 2));
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GLAccount2."No.", -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Transaction Number Entries.
        VerifyTransactionNoCalculation(GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchInvCountHandler,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBatchPostCount()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessages: TestPage "Error Messages";
        RecID: RecordID;
    begin
        // [SCENARIO] One of two invoices is posted by "Batch Post Purchase Invoices" report if errors occurred in the first document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader[1].RecordId;
        // [GIVEN] no unposted purchase invoices
        PurchaseHeader[1].SetRange("Document Type", PurchaseHeader[1]."Document Type"::Invoice);
        PurchaseHeader[1].DeleteAll();
        // [GIVEN] Created Purchase Invoice '1001', where "Vendor Invoice No." is blank
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseLine, PurchaseHeader[1]."Document Type"::Invoice);
        PurchaseHeader[1]."Vendor Invoice No." := '';
        PurchaseHeader[1].Modify();
        // [GIVEN] Created Purchase Invoice '1002'
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseLine, PurchaseHeader[2]."Document Type"::Invoice);

        // [WHEN] Run Batch Post Purchase Orders Report.
        ErrorMessages.Trap();
        BatchPostPurchaseInvoiceRun();

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Click "Details" - opened "Error Messages" page, where is one record:
        // [THEN] Description is 'You need to enter the document number...', "Record ID" is 'Invoice,1001'
        Assert.ExpectedMessage(VendorInvNoErr, ErrorMessages.Description.Value);
        ErrorMessages.Context.AssertEquals(Format(PurchaseHeader[1].RecordId));
        ErrorMessages.Close();
        // [THEN] Invoice '1001' is not posted, Invoice '1002' is posted
        Assert.IsTrue(PurchaseHeader[1].Find(), '1st Invoice does not exist');
        Assert.IsFalse(PurchaseHeader[2].Find(), '2nd Invoice is not posted');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchInvCountHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBatchPostCountBackground()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO] One of two invoices is posted (in background) by "Batch Post Purchase Invoices" report if errors occurred in the first document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        // [GIVEN] no unposted purchase invoices
        PurchaseHeader[1].SetRange("Document Type", PurchaseHeader[1]."Document Type"::Invoice);
        PurchaseHeader[1].DeleteAll();
        // [GIVEN] Created Purchase Invoice '1001', where "Vendor Invoice No." is blank
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseLine, PurchaseHeader[1]."Document Type"::Invoice);
        PurchaseHeader[1]."Vendor Invoice No." := '';
        PurchaseHeader[1].Modify();
        // [GIVEN] Created Purchase Invoice '1002'
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseLine, PurchaseHeader[2]."Document Type"::Invoice);

        // [WHEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseInvoiceRun();
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader[1].RecordId);
        JobQueueEntry.FindFirst();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 0);

        // [THEN] Invoice '1001' is not posted, Invoice '1002' is posted
        Assert.IsTrue(PurchaseHeader[1].Find(), '1st Invoice does not exist');
        Assert.IsFalse(PurchaseHeader[2].Find(), '2nd Invoice is not posted');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchInvCountHandler,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBatchPostCountSecondFailed()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessages: TestPage "Error Messages";
        RecID: RecordID;
    begin
        // [SCENARIO] The two of three invoices are posted by "Batch Post Purchase Invoices" report if errors occurred in the second document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader[1].RecordId;
        // [GIVEN] no unposted purchase invoices
        PurchaseHeader[1].SetRange("Document Type", PurchaseHeader[1]."Document Type"::Invoice);
        PurchaseHeader[1].DeleteAll();
        // [GIVEN] Created Purchase Invoice '1001'
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseLine, PurchaseHeader[1]."Document Type"::Invoice);
        // [GIVEN] Created Purchase Invoice '1002', where "Qty. to Receive" is 0
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseLine, PurchaseHeader[2]."Document Type"::Invoice);
        PurchaseLine.SetRange("Document Type", PurchaseHeader[2]."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader[2]."No.");
        PurchaseLine.ModifyAll("Qty. to Receive", 0, true);
        // [GIVEN] Created Purchase Invoice '1003'
        CreatePurchaseDocument(PurchaseHeader[3], PurchaseLine, PurchaseHeader[3]."Document Type"::Invoice);

        // [WHEN] Run Batch Post Purchase Orders Report.
        ErrorMessages.Trap();
        BatchPostPurchaseInvoiceRun();

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Click "Details" - opened "Error Messages" page, where is one record:
        // [THEN] Description is 'Qty. to Receive must be equal to...', "Record ID" is 'Invoice,1002'
        Assert.ExpectedMessage(PurchaseLine.FieldCaption("Qty. to Receive"), ErrorMessages.Description.Value);
        ErrorMessages.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));
        ErrorMessages.Close();
        // [THEN] Invoice '1002' is not posted, Invoices '1001' and '1003' are posted
        Assert.IsFalse(PurchaseHeader[1].Find(), '1st Invoice is not posted');
        Assert.IsTrue(PurchaseHeader[2].Find(), '2nd Order does not exist');
        Assert.IsFalse(PurchaseHeader[3].Find(), '3rd Invoice is not posted');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseOrderCHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchPostDate()
    begin
        // Test case to check error while running Batch Post Purchase Orders while giving a Blank Posting Date.

        // Setup.
        Initialize();

        // Exercise: Run Batch Post Purchase Orders Report.
        asserterror BatchPostPurchaseOrderRun();

        // Verify: Verify whether error is captured or not.
        Assert.AreEqual(StrSubstNo(PostingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCountHandler,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchPostCount()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessages: TestPage "Error Messages";
        RecID: RecordID;
    begin
        // [SCENARIO] Purchase Order is posted via Batch Post Purchase Orders Report.

        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader[1].RecordId;
        PurchaseHeader[1].DeleteAll();
        // [GIVEN] Created Purchase Document 'A', where is nothing to post
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseLine, PurchaseHeader[2]."Document Type"::Order);
        PurchaseLine.Validate(Quantity, 0);
        PurchaseLine.Modify(true);
        // [GIVEN] Created Purchase Document 'B', ready to post
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseLine, PurchaseHeader[2]."Document Type"::Order);

        // [WHEN] Run Batch Post Purchase Orders Report.
        ErrorMessages.Trap();
        BatchPostPurchaseOrderRun();

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Click "Details" - opened "Error Messages" page, where is one record:
        Assert.ExpectedMessage(DocumentErrorsMgt.GetNothingToPostErrorMsg(), ErrorMessages.Description.Value);
        ErrorMessages.Context.AssertEquals(Format(PurchaseHeader[1].RecordId));
        ErrorMessages.Close();

        // [THEN] Order 'A' is not posted, Order 'B' is posted
        Assert.IsTrue(PurchaseHeader[1].Find(), '1st Order does not exist');
        Assert.IsFalse(PurchaseHeader[2].Find(), '2nd Order is not posted');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCountHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchPostCountBackground()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessage: Record "Error Message";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // [SCENARIO] Purchase Order is posted (in background) via Batch Post Purchase Orders Report.

        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        PurchaseHeader[1].DeleteAll();
        // [GIVEN] Created Purchase Document 'A', where dimension error will be
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseLine, PurchaseHeader[2]."Document Type"::Order);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, PurchaseHeader[1]."Buy-from Vendor No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [GIVEN] Created Purchase Document 'B', ready to post
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseLine, PurchaseHeader[2]."Document Type"::Order);

        // [WHEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseOrderRun();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 0);

        // [THEN] Order 'A' is not posted, Order 'B' is posted
        Assert.IsTrue(PurchaseHeader[1].Find(), '1st Order does not exist');
        Assert.IsFalse(PurchaseHeader[2].Find(), '2nd Order is not posted');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCountHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchPostInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        RecID: RecordID;
        InvoiceDiscountAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Invoice Discount is calculated and flowed in Posted Purchase Invoice Line via batch posting.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader.RecordId;
        PurchaseHeader.DeleteAll();

        // [GIVEN] Turn on "Calc. Inv. Discount" in Purchases & Payables Setup
        LibraryPurchase.SetCalcInvDiscount(true);
        // [GIVEN] Released Purchase Order 'A' with invoice discount 'X'
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        InvoiceDiscountAmount := PurchaseLine."Inv. Discount Amount";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Created Purchase Order 'B', where is nothing to post
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate(Quantity, 0);
        PurchaseLine.Modify(true);

        // [GIVEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseOrderRun();

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();

        // Verify: Verify Posted Purchase Invoice Line.
        VerifyPurchaseInvoiceLine(PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCountHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchPostInvDiscBackground()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ErrorMessage: Record "Error Message";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        RecID: RecordID;
        InvoiceDiscountAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Invoice Discount is calculated and flowed in Posted Purchase Invoice Line via batch posting (in background).
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        PurchaseHeader.DeleteAll();

        // [GIVEN] Turn on "Calc. Inv. Discount" in Purchases & Payables Setup
        LibraryPurchase.SetCalcInvDiscount(true);
        // [GIVEN] Released Purchase Order 'A' with invoice discount 'X'
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        InvoiceDiscountAmount := PurchaseLine."Inv. Discount Amount";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        RecID := PurchaseHeader.RecordId;

        // [GIVEN] Created Purchase Order 'B', where is nothing to post
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, PurchaseHeader."Buy-from Vendor No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [GIVEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseOrderRun();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(RecID);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId, true);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 0);

        // Verify: Verify Posted Purchase Invoice Line.
        VerifyPurchaseInvoiceLine(PostedDocumentNo, InvoiceDiscountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchDocDateHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchReplaceDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecID: RecordID;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Replace Document Date option of Batch Post Purchase Orders Report.

        // [GIVEN] Create Purchase Document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader.RecordId;
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [WHEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseOrderRun();

        // [THEN] Verify Posted Purchase Invoice Header for modified Document Date.
        VerifyPurchaseInvoiceHeader(PostedDocumentNo, LibraryVariableStorage.DequeueDate());

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchDocDateHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderBatchReplaceDateBackground()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        RecID: RecordID;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Replace Document Date option of Batch Post Purchase Orders Report (in background).

        // [GIVEN] Create Purchase Document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        RecID := PurchaseHeader.RecordId;
        PostedDocumentNo := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [WHEN] Run Batch Post Purchase Orders Report.
        BatchPostPurchaseOrderRun();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Posted Purchase Invoice Header for modified Document Date.
        VerifyPurchaseInvoiceHeader(PostedDocumentNo, LibraryVariableStorage.DequeueDate());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Orders on the Vendor Hist. Pay-to FactBox after creating a new Purchase Order.

        // Setup: Create a new Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Orders on the Vendor Hist. Pay-to FactBox after creating a new Purchase Order.
        VendorHistPaytoFactBox.NoOfOrdersTile.AssertEquals(1);  // One Purchase Order have been created by the test function, so Number of Orders is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Invoices on the Vendor Hist. Pay-to FactBox after creating a new Purchase Invoice.

        // Setup: Create a new Purchase Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Invoices on the Vendor Hist. Pay-to FactBox after creating a new Purchase Invoice.
        VendorHistPaytoFactBox.NoOfInvoicesTile.AssertEquals(1);  // One Purchase Invoice have been created by the test function, so Number of Invoices is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Credit Memos on the Vendor Hist. Pay-to FactBox after creating a new Purchase Credit Memo.

        // Setup: Create a new Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Credit Memos on the Vendor Hist. Pay-to FactBox after creating a new Purchase Credit Memo.
        VendorHistPaytoFactBox.NoOfCreditMemosTile.AssertEquals(1);  // One Purchase Credit Memo have been created by the test function, so Number of Credit Memos is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPurchaseQuotes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Quotes on the Vendor Hist. Pay-to FactBox after creating a new Purchase Quote.

        // Setup: Create a new Purchase Quote.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Quotes on the Vendor Hist. Pay-to FactBox after creating a new Purchase Quote.
        VendorHistPaytoFactBox.NoOfQuotesTile.AssertEquals(1);  // One Purchase Quote have been created by the test function, so Number of Quotes is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Return Orders on the Vendor Hist. Pay-to FactBox after creating a new Purchase Return Order.

        // Setup: Create a new Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Return Orders on the Vendor Hist. Pay-to FactBox after creating a new Purchase Return Order.
        VendorHistPaytoFactBox.NoOfReturnOrdersTile.AssertEquals(1);  // One Purchase Return Order have been created by the test function, so Number of Return Orders is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPostedPurchaseInvoiceAndReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Posted Invoices and Number of Posted Receipts on the Vendor Hist. Pay-to FactBox after posting a new Purchase Order.

        // Setup: Create and post a new Purchase Order.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Posted Invoices and Number of Posted Receipts on the Vendor Hist. Pay-to FactBox after posting a new Purchase Order.
        VendorHistPaytoFactBox.NoOfPostedInvoicesTile.AssertEquals(1);  // One Posted Purchase Invoice have been created by the test function, so Number of Posted Invoices is taken as 1.
        VendorHistPaytoFactBox.NoOfPostedReceiptsTile.AssertEquals(1);  // One Posted Purchase Receipt have been created by the test function, so Number of Posted Receipts is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPostedPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Posted Credit Memos on the Vendor Hist. Pay-to FactBox after posting a new Purchase Credit Memo.

        // Setup: Create and post a new Purchase Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Posted Credit Memos on the Vendor Hist. Pay-to FactBox after posting a new Purchase Credit Memo.
        VendorHistPaytoFactBox.NoOfPostedCreditMemosTile.AssertEquals(1);  // One Posted Purchase Credit Memo have been created by the test function, so Number of Posted Credit Memos is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistoryForPostedPurchaseReturnShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox";
    begin
        // Check Number of Posted Return Shipments on the Vendor Hist. Pay-to FactBox after posting a new Purchase Return Order.

        // Setup: Create and post a new Purchase Return Order.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // Exercise.
        OpenVendorHistPaytoFactBox(VendorHistPaytoFactBox, PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Number of Posted Return Shipments on the Vendor Hist. Pay-to FactBox after posting a new Purchase Return Order.
        VendorHistPaytoFactBox.NoOfPostedReturnShipmentsTile.AssertEquals(1);  // One Posted Return Shipment have been created by the test function, so Number of Posted Return Shipments is taken as 1.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DefaultSafetyLeadTime: DateFormula;
    begin
        // Set Default Safety Lead Time in Manufacturing Setup and verify Expected Receipt Date on Purchase Order Line.

        // Setup: Set Default Safety Lead Time in Manufacturing Setup taking random value.
        Initialize();
        Evaluate(DefaultSafetyLeadTime, Format(LibraryRandom.RandInt(5)) + '<D>');  // Taking Random value.
        UpdateDefaultSafetyLeadTimeOnManufacturingSetup(DefaultSafetyLeadTime);

        // Exercise: Create a Purchase Order taking random values.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Verify: Validate that expected receipt date is equal to Default Safety Lead Time plus Order date of Purchase Order.
        PurchaseLine.TestField("Expected Receipt Date", CalcDate(DefaultSafetyLeadTime, PurchaseHeader."Order Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderByPage()
    var
        ItemNo: Code[20];
        PurchaseHeaderNo: Code[20];
        VendorNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify creation of Purchase Order by page.

        // Setup: Create a Vendor and an Item.
        Initialize();
        VendorNo := CreateVendor();
        ItemNo := CreateItem();

        // Exercise: Create a Purchase Order taking Random Quantity.
        Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseHeaderNo := CreatePurchaseOrderCard();
        CreatePurchaseLineFromPurchaseOrderPage(ItemNo, PurchaseHeaderNo, VendorNo, Quantity);

        // Verify: Verify data of newly created Purchase Order.
        VerifyPurchaseOrder(PurchaseHeaderNo, VendorNo, ItemNo, Quantity);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceAndLineDiscount()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Price and Line Discount.

        // Setup: Create Purchase Price and Purchase Line Discount.
        Initialize();
        CreatePurchasePrice(PurchasePrice);
        CreatePurchaseLineDiscount(PurchaseLineDiscount, PurchasePrice);

        // Exercise: Create Purchase Order.
        CopyAllPriceDiscToPriceListLine();
        CreatePurchaseOrder(PurchaseLine, PurchasePrice);

        // Verify: Verify Purchase Price and Line Discount on Purchase Line.
        VerifyPriceAndLineDiscountOnPurchaseLine(PurchaseLine, PurchasePrice."Minimum Quantity" / 2, 0, 0);
        VerifyPriceAndLineDiscountOnPurchaseLine(PurchaseLine, PurchasePrice."Minimum Quantity", PurchasePrice."Direct Unit Cost", 0);
        VerifyPriceAndLineDiscountOnPurchaseLine(
          PurchaseLine, PurchasePrice."Minimum Quantity" * 2, PurchasePrice."Direct Unit Cost", PurchaseLineDiscount."Line Discount %");
    end;

    local procedure CopyAllPriceDiscToPriceListLine()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
    begin
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UserSetup: Record "User Setup";
        ResponsibilityCenterCode: Code[10];
    begin
        // Check Responsibility Center on Purchase Order.

        // Setup: Create a User Setup.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();

        // Exercise.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Verify: Validate Responsibility Center on Purchase Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnPostedPurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        UserSetup: Record "User Setup";
        PostedDocumentNo: Code[20];
        ResponsibilityCenterCode: Code[10];
    begin
        // Check Responsibility Center on Posted Purchase Document.

        // Setup: Create a User Setup.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Validate Responsibility Center on Purchase Document.
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithChangedVATAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        DocumentNo: Code[20];
    begin
        // Verify Purchase Order Posting After Changing VAT Amount.

        // Setup: Modify GeneralLedger And PurchasesPayables Setup, Create Purchase Order, VAT Amount Modified Using Handler.
        Initialize();
        UpdateGeneralLedgerSetup(0);
        LibraryVariableStorage.Enqueue(
          UpdateGeneralLedgerSetup(LibraryRandom.RandDec(0, 1)));
        ModifyPurchasesPayablesSetup(true);
        CreatePurchaseOrderWithMultipleLines(PurchaseHeader);
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.Statistics.Invoke();

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify : Verify VAT Amount After Posting.
        VerifyVATAmount(DocumentNo);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure StartingDateAsWorkDateOnPurchasePrice()
    begin
        // Verify that correct date gets updated on Purchase Price window in "Starting Date Filter" field when user enters W.

        Initialize();
        StartingDateOnPurchasePrice('W', WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateAsTodayOnPurchasePrice()
    begin
        // Verify that correct date gets updated on Purchase Price window in "Starting Date Filter" field when user enters T.

        Initialize();
        StartingDateOnPurchasePrice('T', Today);
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    procedure SugVendPmtWithPosVendBal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify General Journal Line after Suggest Vendor Payments with Positive Balance.

        // Setup: Create Purchase invoice.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Exercise: Run Suggest Vendor Payment Report for Vendor.
        SuggestVendorPayment(GenJournalLine, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", true);

        // Verify: Verify General Journal Line for Suggested Vendor.
        Assert.IsTrue(FindGenJournalLine(GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No."), FilterMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SugVendPmtWithNegVendBal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 202185] General Journal Line exists after Suggest Vendor Payments for Vendor with Negative Balance.

        // [GIVEN] Vendor Balance is negative.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Run Suggest Vendor Payment Report.
        SuggestVendorPayment(GenJournalLine, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", true);

        // [THEN] General Journal Line exists for Suggested Vendor.
        Assert.IsTrue(FindGenJournalLine(GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No."), NoFilterMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineFactboxForPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLineFactboxForPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineFactboxForPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLineFactboxForPurchaseDocument(PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderArchiveUserRespCenterFilter()
    var
        ResponsibilityCenter: array[2] of Record "Responsibility Center";
        UserSetup: Record "User Setup";
        PurchOrderArchives: TestPage "Purchase Order Archives";
        VendorNo: array[2] of Code[20];
        OldPurchRespCtrFilter: Code[10];
    begin
        // [FEATURE] [Responsibility Center] [Archive]
        // [SCENARIO 375976] Purchase Order Archive shows entries depending on User's Responsibility Center
        Initialize();

        // [GIVEN] Responsibility Center "A" and "B"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        OldPurchRespCtrFilter := UpdateUserSetupPurchRespCtrFilter(UserSetup, '');
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter[1]);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter[2]);

        // [GIVEN] Archived Purchase Order for Responsibility Center "A"
        CreateAndArchivePurchOrderWithRespCenter(
          VendorNo[1], ResponsibilityCenter[1].Code);

        // [GIVEN] Archived Purchase Order for Responsibility Center "B"
        CreateAndArchivePurchOrderWithRespCenter(
          VendorNo[2], ResponsibilityCenter[2].Code);

        // [GIVEN] User is assigned to Responsibility Center "A"
        UpdateUserSetupPurchRespCtrFilter(UserSetup, ResponsibilityCenter[1].Code);

        // [WHEN] Purchase Order Archive page is opened
        PurchOrderArchives.OpenView();

        // [THEN] Only entries for Responsibility Center "A" are shown
        PurchOrderArchives."Buy-from Vendor No.".AssertEquals(VendorNo[1]);
        Assert.IsFalse(PurchOrderArchives.Next(), PurchOrderArchiveRespCenterErr);

        UpdateUserSetupPurchRespCtrFilter(UserSetup, OldPurchRespCtrFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithDiffVendPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        InvNo: Code[20];
    begin
        // [SCENARIO 380573] Purchase Invoice is posted with "Vendor Posting Group" from Purchase Header when "Vendor Posting Group" in Vendor Card is different

        Initialize();
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Vendor "X" with "Vendor Posting Group" "DOMESTIC"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        // [GIVEN] Purchase Invoice with Vendor "X" and "Vendor Posting Group" "FOREIGN"
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup.Code);
        PurchHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        PurchHeader.Modify(true);

        // [WHEN] Post Purchase Invoice
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        SetPurchAllowMultiplePostingGroups(false);

        // [THEN] Vendor Ledger Entry with "Vendor Posting Group" "FOREIGN" is posted
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, InvNo);
        VendLedgEntry.TestField("Vendor Posting Group", PurchHeader."Vendor Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceAndSuggestPaymentsWithDiffVendPostingGroup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // [SCENARIO 380573] Purchase Invoice is posted with alternative "Vendor Posting Group"
        // [WHEN] Suggest Payment job create Gen. Journal Line with same alternative posting group.

        Initialize();
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Vendor "X" with "Vendor Posting Group" "DOMESTIC"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Invoice with Vendor "X" and "Vendor Posting Group" "FOREIGN"
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Vendor Ledger Entry with "Vendor Posting Group" "FOREIGN" is posted
        SuggestVendorPayment(GenJournalLine, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", true);

        GenJournalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Group", PurchaseHeader."Vendor Posting Group");

        SetPurchAllowMultiplePostingGroups(false);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceMinimumQuantityWithMaxValue()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // [FEATURE] [Purchase Price] [UT] [UI]
        // [SCENARIO 381273] User should be able to input value with 5 decimals in "Minimum Quantity" field of Purchase Price table
        CreatePurchasePriceWithMinimumQuantity(PurchasePrice, 0.12345);
        PurchasePrices.OpenView();
        PurchasePrices.GotoRecord(PurchasePrice);
        Assert.AreEqual(Format(0.12345), PurchasePrices."Minimum Quantity".Value, PurchasePrice.FieldCaption("Minimum Quantity"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceMinimumQuantityOverMaxValue()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // [FEATURE] [Purchase Price] [UT] [UI]
        // [SCENARIO 381273] User should not be able to input value with more than 5 decimals in "Minimum Quantity" field of Purchase Price table
        CreatePurchasePriceWithMinimumQuantity(PurchasePrice, 0.123456);
        PurchasePrices.OpenView();
        PurchasePrices.GotoRecord(PurchasePrice);
        Assert.AreNotEqual(Format(0.123456), PurchasePrices."Minimum Quantity".Value, PurchasePrice.FieldCaption("Minimum Quantity"));
        Assert.AreEqual(Format(0.12346), PurchasePrices."Minimum Quantity".Value, PurchasePrice.FieldCaption("Minimum Quantity"));
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameItemVariantExistsInPurchaseInvoice()
    var
        Item: array[2] of Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 496448] Purchase Line with Item Variant updates when Item Variant "Code" is renamed.
        // [SCENARIO 496448] Purchase Line with Item Variant raises error when Item Variant "Item No." is renamed.
        Initialize();

        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItemVariant(ItemVariant, Item[1]."No.");

        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::"Item";
        PurchaseLine."No." := Item[1]."No.";
        PurchaseLine."Variant Code" := ItemVariant.Code;
        PurchaseLine.Insert();

        // [WHEN] Rename Item Variant "Code"
        ItemVariant.Rename(Item[1]."No.", LibraryUtility.GenerateRandomCode(ItemVariant.FieldNo(Code), Database::"Item Variant"));

        // [THEN] Purchase Line with Item Variant is updated to the new "Code"
        PurchaseLine.Find('=');
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);

        // [WHEN] Rename Item Variant "Item No."
        asserterror ItemVariant.Rename(Item[2]."No.", ItemVariant.Code);

        // [THEN] Error is raised
        Assert.ExpectedError(StrSubstNo(CannotRenameItemUsedInPurchaseLinesErr, ItemVariant.FieldCaption("Item No."), ItemVariant.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameStandardTextExistsInPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        DummyText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 203481] Purchase Line with Standard Text updates when Standard Text is renamed

        Initialize();

        LibrarySales.CreateStandardTextWithExtendedText(StandardText, DummyText);
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::" ";
        PurchaseLine."No." := StandardText.Code;
        PurchaseLine.Insert();

        StandardText.Rename(LibraryUtility.GenerateGUID());

        PurchaseLine.Find();
        PurchaseLine.TestField("No.", StandardText.Code);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure UI_CannotCopyPricesWhenVendorNoFilterHasMultipleVendors()
    var
        PurchasePrices: TestPage "Purchase Prices";
        CopyFromVendorNo: Code[20];
        CopyToVendorNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Purchase Price]
        // [SCENARIO 207389] Not possible to copy prices when multiple vendors specified in "Vendor No. Filter" on "Purchase Prices" page

        Initialize();

        // [GIVEN] Vendors "X" and "Y"
        CopyFromVendorNo := LibraryPurchase.CreateVendorNo();
        CopyToVendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Opened "Purchase Prices" page and "Vendor No. Filter" is "X|Y"
        PurchasePrices.OpenEdit();
        PurchasePrices.VendNoFilterCtrl.SetValue(StrSubstNo('%1|%2', CopyFromVendorNo, CopyToVendorNo));

        // [WHEN] Press action "Copy Prices" on "Purchase Prices" page
        asserterror PurchasePrices.CopyPrices.Invoke();

        // [THEN] Error message "There are more than one vendor selected by Vendor No. Filter. Specify a single Vendor No. by Vendor No. Filter to copy prices." is thrown
        Assert.ExpectedError(MultipleVendorsSelectedErr);
    end;

    [Test]
    [HandlerFunctions('PurchPricesSelectPriceOfVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CopyPriceOnPurchasePricesPage()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
        CopyFromVendorNo: Code[20];
        CopyToVendorNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Purchase Price]
        // [SCENARIO 207389] Copy price from one Vendor to another by "Copy Prices" action on "Purchase Prices" page

        Initialize();

        // [GIVEN] Vendors "X" and "Y"
        CopyToVendorNo := LibraryPurchase.CreateVendorNo();
        CopyFromVendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase Price for Vendor "Y", "Direct Unit Cost" = 50
        CreatePurchPrice(PurchasePrice, CopyFromVendorNo);

        // [GIVEN] Opened "Purchase Prices" page and "Vendor No. Filter" is "X"
        PurchasePrices.OpenEdit();
        PurchasePrices.VendNoFilterCtrl.SetValue(CopyToVendorNo);
        LibraryVariableStorage.Enqueue(CopyFromVendorNo); // pass to PurchPricesSelectPriceOfVendorModalPageHandler

        // [WHEN] Press action "Copy Prices" on "Purchase Prices" page and select price of Vendor "Y"
        PurchasePrices.CopyPrices.Invoke();

        // [THEN] Purchase Price for Vendor "X" with "Direct Unit Cost" = 50 is created
        VerifyCopiedPurchPrice(PurchasePrice, CopyToVendorNo);
    end;

    [Test]
    [HandlerFunctions('PurchPricesSelectPriceOfVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CopyExistingPriceOnPurchasePricesPage()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
        CopyFromVendorNo: Code[20];
        CopyToVendorNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Purchase Price]
        // [SCENARIO 207389] Price not copies if it's already exist when use "Copy Prices" action on "Purchase Prices" page

        Initialize();

        // [GIVEN] Vendors "X" and "Y"
        CopyToVendorNo := LibraryPurchase.CreateVendorNo();
        CopyFromVendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Two identical Purchase Prices for Vendors "X" and "Y"
        CreatePurchPrice(PurchasePrice, CopyFromVendorNo);
        PurchasePrice."Vendor No." := CopyToVendorNo;
        PurchasePrice.Insert();

        // [GIVEN] Opened "Purchase Prices" page and "Vendor No. Filter" is "X"
        PurchasePrices.OpenEdit();
        PurchasePrices.VendNoFilterCtrl.SetValue(CopyToVendorNo);
        LibraryVariableStorage.Enqueue(CopyFromVendorNo); // pass to PurchPricesSelectPriceOfVendorModalPageHandler

        // [WHEN] Press action "Copy Prices" on "Purchase Prices" page and select price of Vendor "Y"
        PurchasePrices.CopyPrices.Invoke();

        // [THEN] Existing Price not changed and no new Price was copied to Vendor "X"
        VerifyUnchangedPurchPrice(PurchasePrice);
    end;

    [Test]
    [HandlerFunctions('PurchPricesCancelPriceSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DoNotSelectPriceWhenCopyPricesOnPurchasePricesPage()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
        CopyFromVendorNo: Code[20];
        CopyToVendorNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Purchase Price]
        // [SCENARIO 207389] Price not copies if nothing is selected when use "Copy Prices" action on "Purchase Prices" page

        Initialize();

        // [GIVEN] Vendors "X" and "Y"
        CopyToVendorNo := LibraryPurchase.CreateVendorNo();
        CopyFromVendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase Price for Vendor "Y", "Direct Unit Cost" = 50
        CreatePurchPrice(PurchasePrice, CopyFromVendorNo);

        // [GIVEN] Opened "Purchase Prices" page and "Vendor No. Filter" is "X"
        PurchasePrices.OpenEdit();
        PurchasePrices.VendNoFilterCtrl.SetValue(CopyToVendorNo);
        LibraryVariableStorage.Enqueue(CopyFromVendorNo); // pass to PurchPricesSelectPriceOfVendorModalPageHandler

        // [WHEN] Press action "Copy Prices" on "Purchase Prices" page and cancel selection
        PurchasePrices.CopyPrices.Invoke();

        // [THEN] No price was copied to Vendor "X"
        PurchasePrice.SetRange("Vendor No.", CopyToVendorNo);
        Assert.RecordCount(PurchasePrice, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopyPurchPriceToVendorPurchPrice()
    var
        PurchasePrice: Record "Purchase Price";
        ExistingPurchasePrice: Record "Purchase Price";
        CopyFromVendorNo: Code[20];
        CopyToVendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Price] [Sales Price]
        // [SCENARIO 207389] Copy prices with CopySalesPriceToCustomersSalesPrice function in Sales Price table

        Initialize();

        CopyToVendorNo := LibraryPurchase.CreateVendorNo();
        CopyFromVendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchPrice(PurchasePrice, CopyFromVendorNo);

        CreatePurchPrice(PurchasePrice, CopyFromVendorNo);
        ExistingPurchasePrice := PurchasePrice;
        ExistingPurchasePrice."Vendor No." := CopyToVendorNo;
        ExistingPurchasePrice.Insert();

        PurchasePrice.SetRange("Vendor No.", CopyFromVendorNo);
        PurchasePrice.CopyPurchPriceToVendorsPurchPrice(PurchasePrice, CopyToVendorNo);

        PurchasePrice.SetRange("Vendor No.", CopyToVendorNo);
        Assert.RecordCount(PurchasePrice, 2);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsUpdateInvDiscontAndTotalVATHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithChangedVATAmountAndInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATDiffAmount: Decimal;
        InvDiscAmount: Decimal;
        ExpectedVATAmount: Decimal;
        AmountToPost: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Statistics] [VAT Difference] [Invoice Discount]
        // [SCENARIO 215643] Cassie can adjust Invoice Discount at invoice tab of Purchase Order statistics page and can update Total VAT amount on VAT Amount lines.
        // [SCENARIO 215643] Changed amounts are reflected on totals subform of purchase order and are reflected at posted VAT, Vendor Ledger Entries.
        Initialize();

        // [GIVEN] System setup allows Invoice Discount and Max. VAT Difference = 10
        VATDiffAmount := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(VATDiffAmount);
        LibraryPurchase.SetAllowVATDifference(true);
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Purchase Order with Amount = 100 and VAT % = 10
        CreatePurchaseOrderWithItem(PurchaseHeader, PurchaseLine);
        AmountToPost := Round(PurchaseLine.Amount / 10, 1);
        InvDiscAmount := PurchaseLine.Amount - AmountToPost;
        ExpectedVATAmount := Round(AmountToPost * PurchaseLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount;

        // [GIVEN] Cassie changed Invoice Discount to 90 => calculated VAT amount = 1 ((100 - 90) * VAT%)  at statistics page
        // [GIVEN] Cassie updated Total VAT = 4 => "VAT Difference" = 3
        LibraryVariableStorage.Enqueue(InvDiscAmount);
        LibraryVariableStorage.Enqueue(VATDiffAmount);

        UpdateInvoiceDiscountAndVATAmountOnPusrchaseOrderStatistics(
          PurchaseHeader, PurchaseLine, AmountToPost, ExpectedVATAmount, VATDiffAmount);

        // [WHEN] Post purchase order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Two VAT Entries posted
        // [THEN] "VAT Entry"[1].Base = -90 and "VAT Entry"[1].Amount = -9
        // [THEN] "VAT Entry"[2].Base = 100 and "VAT Entry"[2].Amount = 13 = 100 * 10 % + 3
        FindVATEntry(VATEntry, DocumentNo, VATEntry.Type::Purchase);
        VerifyVATEntryAmounts(
          VATEntry,
          -InvDiscAmount,
          -Round(InvDiscAmount * PurchaseLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()));
        VATEntry.Next();
        VerifyVATEntryAmounts(
          VATEntry,
          InvDiscAmount + AmountToPost,
          Round((InvDiscAmount + AmountToPost) * PurchaseLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount);
        Assert.RecordCount(VATEntry, 2);

        // [THEN] VLE with Amount = -14 = -(100 - 90 + 4), "Purchase (LCY)" = -10 and "Inv. Discount (LCY)" = -90 posted
        FindVLE(VendorLedgerEntry, DocumentNo, PurchaseHeader."Buy-from Vendor No.");

        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Amount, -PurchaseLine."Amount Including VAT");
        VendorLedgerEntry.TestField("Purchase (LCY)", -AmountToPost);
        VendorLedgerEntry.TestField("Inv. Discount (LCY)", -InvDiscAmount);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure PurchPricesAndDiscountsActionsFromItemCard()
    var
        ItemCard: TestPage "Item Card";
        PurchasePrices: TestPage "Purchase Prices";
        PurchaseLineDiscounts: TestPage "Purchase Line Discounts";
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI] [Price] [Discount]
        // [SCENARIO 220724] Purchase prices and discounts pages opened from item card with action Set Special Prices, Set Special Discounts
        Initialize();

        // [GIVEN] Item card opened with new item
        ItemNo := CreateItem();
        ItemCard.OpenEdit();
        ItemCard.GotoKey(ItemNo);

        // [WHEN] Press action Set Special Prices
        PurchasePrices.Trap();
        ItemCard.Action86.Invoke();

        // [THEN] Page Purchase prices opened with filter by Item No.
        Assert.AreEqual(
          ItemNo,
          PurchasePrices.FILTER.GetFilter("Item No."),
          StrSubstNo(InvalidItemNoFilterErr, PurchasePrices.Caption));

        // [WHEN] Press action Set Special Discounts
        PurchaseLineDiscounts.Trap();
        ItemCard.Action85.Invoke();

        // [THEN] Page Purchase Line Discounts opened with filter by Item No.
        Assert.AreEqual(
          ItemNo,
          PurchaseLineDiscounts.FILTER.GetFilter("Item No."),
          StrSubstNo(InvalidItemNoFilterErr, PurchaseLineDiscounts.Caption));
    end;

    [Test]
    [HandlerFunctions('PurchPricesAndLineDisc_MPH')]
    [Scope('OnPrem')]
    procedure PurchPriceAndDiscountOverviewByActionFromItemCard()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [UI] [Price] [Discount]
        // [SCENARIO 220724] Purchase price and discount displayed in Purchases Price and Line Disc on action Special Prices & Discounts Overview from Item Card page
        Initialize();

        // [GIVEN] Item card opened with new item which has purchase price A and discount line B
        CreatePurchasePrice(PurchasePrice);
        CreatePurchaseLineDiscount(PurchaseLineDiscount, PurchasePrice);
        ItemCard.OpenEdit();
        ItemCard.GotoKey(PurchasePrice."Item No.");

        // [WHEN] Press action Special Prices & Discounts Overview
        ItemCard.PurchPricesDiscountsOverview.Invoke();

        // [THEN] Page Purchases Price and Line Disc opened with purchase price A and discount line B
        Assert.AreEqual(
          PurchasePrice."Direct Unit Cost",
          LibraryVariableStorage.DequeueDecimal(),
          StrSubstNo(InvalidValueErr, PurchasePrice.FieldName("Direct Unit Cost")));
        Assert.AreEqual(
          PurchaseLineDiscount."Line Discount %",
          LibraryVariableStorage.DequeueDecimal(),
          StrSubstNo(InvalidValueErr, PurchaseLineDiscount.FieldName("Line Discount %")));
    end;

    [Test]
    [HandlerFunctions('PurchPricesAndLineDisc_MPH')]
    [Scope('OnPrem')]
    procedure PurchPriceAndDiscountOverviewByLookupFromItemCard()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [UI] [Price] [Discount]
        // [SCENARIO 220724] Purchase price and discount displayed in Purchases Price and Line Disc on drilldown for SpecialPurchPricesAndDiscountsTxt control from Item Card page
        Initialize();

        // [GIVEN] New item which has purchase price A and discount line B
        CreatePurchasePrice(PurchasePrice);
        CreatePurchaseLineDiscount(PurchaseLineDiscount, PurchasePrice);

        // [WHEN] Item card is being opened
        ItemCard.OpenEdit();
        ItemCard.GotoKey(PurchasePrice."Item No.");

        // [THEN] SpecialPurchPricesAndDiscountsTxt control = View Existing Prices and Discounts...
        ItemCard.SpecialPurchPricesAndDiscountsTxt.AssertEquals(ViewExistingTxt);

        // [WHEN] Press drilldown for View Existing Prices and Discounts
        ItemCard.SpecialPurchPricesAndDiscountsTxt.DrillDown();

        // [THEN] Page Purchases Price and Line Disc opened with purchase price A and discount line B
        Assert.AreEqual(
          PurchasePrice."Direct Unit Cost",
          LibraryVariableStorage.DequeueDecimal(),
          StrSubstNo(InvalidValueErr, PurchasePrice.FieldName("Direct Unit Cost")));
        Assert.AreEqual(
          PurchaseLineDiscount."Line Discount %",
          LibraryVariableStorage.DequeueDecimal(),
          StrSubstNo(InvalidValueErr, PurchaseLineDiscount.FieldName("Line Discount %")));
    end;

    [Test]
    [HandlerFunctions('CreateNewStrMenuHandler,NewPurchPriceMPH')]
    [Scope('OnPrem')]
    procedure CreatePurchasePriceFromItemCard()
    var
        ItemCard: TestPage "Item Card";
        ItemNo: Code[20];
        VendorNo: Code[20];
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [UI] [Price]
        // [SCENARIO 220724] Purchase price can be created from Item Card page by drilldown for SpecialPurchPricesAndDiscountsTxt
        Initialize();

        // [GIVEN] New item ITEM
        ItemNo := CreateItem();

        // [WHEN] Item card page is being opened
        ItemCard.OpenEdit();
        ItemCard.GotoKey(ItemNo);

        // [THEN] SpecialPurchPricesAndDiscountsTxt control = Create New...
        ItemCard.SpecialPurchPricesAndDiscountsTxt.AssertEquals(CreateNewTxt);

        // [WHEN] Press drilldown for Create New... and choose Create New Special Price... in string menu
        LibraryVariableStorage.Enqueue(1); // Create New Special Price... option
        VendorNo := CreateVendor();
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(DirectUnitCost);
        ItemCard.SpecialPurchPricesAndDiscountsTxt.DrillDown();

        // [WHEN] Specify Vendor No. = VEND, Direct Unit Cost = XXX and press OK
        // values filled in inside the NewPurchPriceMPH

        // [THEN] Purchase price created for item ITEM, vendor VEND with direct unit cost = XXX
        VerifyPurchasePrice(ItemNo, VendorNo, DirectUnitCost);
    end;

    [Test]
    [HandlerFunctions('CreateNewStrMenuHandler,NewPurchDiscountMPH')]
    [Scope('OnPrem')]
    procedure CreatePurchaseDiscountFromItemCard()
    var
        ItemCard: TestPage "Item Card";
        ItemNo: Code[20];
        VendorNo: Code[20];
        DiscountPct: Decimal;
    begin
        // [FEATURE] [UI] [Discount]
        // [SCENARIO 220724] Purchase discount can be created from Item Card page by drilldown for SpecialPurchPricesAndDiscountsTxt
        Initialize();

        // [GIVEN] New item ITEM
        ItemNo := CreateItem();

        // [WHEN] Item card page is being opened
        ItemCard.OpenEdit();
        ItemCard.GotoKey(ItemNo);

        // [THEN] SpecialPurchPricesAndDiscountsTxt control = Create New...
        ItemCard.SpecialPurchPricesAndDiscountsTxt.AssertEquals(CreateNewTxt);

        // [WHEN] Press drilldown for Create New... and choose Create New Special Discount... in string menu
        LibraryVariableStorage.Enqueue(2); // Create New Special Discount... option
        VendorNo := CreateVendor();
        DiscountPct := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(DiscountPct);
        ItemCard.SpecialPurchPricesAndDiscountsTxt.DrillDown();

        // [WHEN] Specify Vendor No. = VEND, Line Discount % = XXX and press OK
        // values filled in inside the NewPurchDiscountMPH

        // [THEN] Purchase line discount created for item ITEM, vendor VEND with Line Discount % = XXX
        VerifyPurchaseLineDiscount(ItemNo, VendorNo, DiscountPct);
    end;

    [Test]
    [HandlerFunctions('PurchPricesAndLineDisc_MPH_VerifyEnabled')]
    [Scope('OnPrem')]
    procedure PurchPricesAndDiscountControlsEnabledForSuite()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [UI] [Price] [Discount]
        // [SCENARIO 220724] Purchase price and discounts actions and controls for item card are enabled for #Suite

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup();

        // [WHEN] Item card page is being opened
        ItemCard.OpenEdit();
        ItemCard.GotoKey(CreateItem());

        // [THEN] Action "Set Special Prices" enabled
        Assert.IsTrue(ItemCard.Action86.Enabled(), 'Action Set Special Prices must be enabled');
        // [THEN] Action "Set Special Discounts" enabled
        Assert.IsTrue(ItemCard.Action85.Enabled(), 'Action Set Special Discounts must be enabled');
        // [THEN] Action "Special Prices & Discounts Overview" enabled
        Assert.IsTrue(ItemCard.PurchPricesDiscountsOverview.Enabled(), 'Action Set Special Prices & Discounts Overview must be enabled');
        // [THEN] Control SpecialPurchPricesAndDiscountsTxt enabled
        Assert.IsTrue(ItemCard.SpecialPurchPricesAndDiscountsTxt.Enabled(), 'Control SpecialPurchPricesAndDiscountsTxt must be enabled');

        // [WHEN] Click action "Special Prices & Discounts Overview" to open page Purchases Price and Line Disc
        ItemCard.PurchPricesDiscountsOverview.Invoke();

        // [THEN] All fields are enabled
        // Verification inside the PurchPricesAndLineDisc_MPH_VerifyEnabled

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPricesAndDiscountControlsDisabledForBasic()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [UI] [Price] [Discount]
        // [SCENARIO 220724] Purchase price and discounts actions and controls for item card are disabled for #Basic

        // [GIVEN] User experience set to Basic
        LibraryApplicationArea.EnableBasicSetupForCurrentCompany();

        // [WHEN] Item card page is being opened
        ItemCard.OpenEdit();
        ItemCard.GotoKey(CreateItem());

        // [THEN] Action "Set Special Prices" disabled
        asserterror ItemCard.Action86.Invoke();
        Assert.ExpectedError(IsNotFoundErr);
        // [THEN] Action "Set Special Discounts" disabled
        asserterror ItemCard.Action85.Invoke();
        Assert.ExpectedError(IsNotFoundErr);
        // [THEN] Action "Special Prices & Discounts Overview" disabled
        asserterror ItemCard.PurchPricesDiscountsOverview.Invoke();
        Assert.ExpectedError(IsNotFoundErr);
        // [THEN] Control SpecialPurchPricesAndDiscountsTxt disabled
        asserterror ItemCard.SpecialPurchPricesAndDiscountsTxt.Invoke();
        Assert.ExpectedError(IsNotFoundErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure CopyPartiallyPostedPurchOrderToOrderLastPostingNoIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Order] [Copy Document]
        // [SCENARIO 264555] When Purchase Order is partially posted and copied to new Purchase Order, then new Purchase Order has <blank> Last Posting No.
        Initialize();

        // [GIVEN] Partially posted Purchase Order "PO"
        PostPartialPurchOrder(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "PO" to Purchase Order "O"
        CopyPurchDocument(PurchaseHeader, "Purchase Document Type From"::Order, PurchaseHeaderNo);

        // [THEN] "Last Posting No." is <blank> in Purchase Order "O"
        PurchaseHeader.TestField("Last Posting No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPartiallyPostedPurchOrderToOrderLastPostingNoIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Order] [Copy Document]
        // [SCENARIO 264555] When partially posted Purchase Order is archived and then Archived Purchase Order is copied to new Purchase Order, then new Purchase Order has <blank> Last Posting No.
        Initialize();

        // [GIVEN] Partially posted Purchase Order "PO"
        PostPartialPurchOrder(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "PO" was archived
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Purchase Order to Purchase Order "O"
        CopyPurchDocumentFromArchived(PurchaseHeader, "Purchase Document Type From"::"Arch. Order", PurchaseHeaderNo, true, false, PurchaseHeader."Document Type");

        // [THEN] "Last Posting No." is <blank> in Purchase Order "O"
        PurchaseHeader.TestField("Last Posting No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrderToOrderLastPrepaymentNoSAreBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Order] [Prepayment] [Copy Document]
        // [SCENARIO 264555] When Purchase Order has Prepayment Invoice and Credit Memo posted and then Purchase Order is copied to new Purchase Order,
        // [SCENARIO 264555] then new Purchase Order has <blank> Last Prepayment No. and Last Prepmt. Cr. Memo No.
        Initialize();

        // [GIVEN] Prepayment Invoice and Prepayment Credit Memo were posted for Purchase Order "PO"
        PreparePurchOrderWithPrepaymentInvAndCrMemo(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "PO" to Purchase Order "O"
        CopyPurchDocument(PurchaseHeader, "Purchase Document Type From"::Order, PurchaseHeaderNo);

        // [THEN] "Last Prepayment No." and "Last Prepmt. Cr. Memo No." are both <blank> is Purchase Order "O"
        PurchaseHeader.TestField("Last Prepayment No.", '');
        PurchaseHeader.TestField("Last Prepmt. Cr. Memo No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPurchOrderToOrderLastPrepaymentNoSAreBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Order] [Prepayment] [Copy Document]
        // [SCENARIO 264555] When Purchase Order has Prepayment Invoice and Credit Memo posted and then Purchase Order is archived and then Archived Purchase Order is copied to new Purchase Order,
        // [SCENARIO 264555] then new Purchase Order has <blank> Last Prepayment No. and Last Prepmt. Cr. Memo No.
        Initialize();

        // [GIVEN] Prepayment Invoice and Prepayment Credit Memo were posted for Purchase Order "PO"
        PreparePurchOrderWithPrepaymentInvAndCrMemo(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "PO" was archived
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Purchase Order to Purchase Order "O"
        CopyPurchDocumentFromArchived(PurchaseHeader, "Purchase Document Type From"::"Arch. Order", PurchaseHeaderNo, true, false, PurchaseHeader."Document Type");

        // [THEN] "Last Prepayment No." and "Last Prepmt. Cr. Memo No." are both <blank> is Purchase Order "O"
        PurchaseHeader.TestField("Last Prepayment No.", '');
        PurchaseHeader.TestField("Last Prepmt. Cr. Memo No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPartiallyPostedPurchReturnOrderToOrderLastReturnShipmentNoIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Return Order] [Copy Document]
        // [SCENARIO 264555] When Purchase Return Order is partially posted and copied to new Purchase Order, then new Purchase Order has <blank> Last Return Shipment No.
        Initialize();

        // [GIVEN] Partially posted Purchase Return Order "PR" with "Return Qty. to Ship" < Quantity
        PostPartialPurchReturnOrder(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "PO" to Purchase Order "O"
        CopyPurchDocument(PurchaseHeader, "Purchase Document Type From"::"Return Order", PurchaseHeaderNo);

        // [THEN] "Last Return Shipment No." is <blank> in Purchase Order "O"
        PurchaseHeader.TestField("Last Return Shipment No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorListHasDefaultDateFilterUntilWorkDate()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI] [Vendor List] [Purchase]

        Initialize();
        // [GIVEN] Work date is 10.01.2018
        Vendor.SetRange("Date Filter", 0D, WorkDate());

        // [WHEN] Open "Customer List" page
        VendorList.OpenView();

        // [THEN] "Date Filter" is "..10.01.2018"
        Assert.AreEqual(Vendor.GetFilter("Date Filter"), VendorList.FILTER.GetFilter("Date Filter"), 'Incorrect default date filter');

        VendorList.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPartiallyPostedPurchReturnOrderToOrderLastReturnShipmentNoIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Return Order] [Copy Document]
        // [SCENARIO 264555] When Purchase Return Order is partially posted and archived and then Archived Purchase Order is copied to new Purchase Order,
        // [SCENARIO 264555] then new Purchase Order has <blank> Last Return Shipment No.
        Initialize();

        // [GIVEN] Partially posted Purchase Return Order "PR" with "Return Qty. to Ship" < Quantity
        PostPartialPurchReturnOrder(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [GIVEN] Purchase Order "PR" was archived
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [GIVEN] Purchase Order "O"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Purchase Order to Purchase Order "O"
        CopyPurchDocumentFromArchived(
          PurchaseHeader, "Purchase Document Type From"::"Arch. Return Order", PurchaseHeaderNo, true, false, PurchaseHeader."Document Type"::"Return Order");

        // [THEN] "Last Return Shipment No." is <blank> in Purchase Order "O"
        PurchaseHeader.TestField("Last Return Shipment No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreciseCalcOfPlannedReceiptDateBackFromExpectedReceiptDate()
    var
        PurchaseLine: Record "Purchase Line";
        NewExpectedReceiptDate: Date;
    begin
        // [FEATURE] [Calendar] [Order]
        // [SCENARIO 278667] The number of days between "Planned Receipt Date" and "Expected Receipt Date" should not depend on which field is validated first.
        Initialize();

        // [GIVEN] Purchase order line with "Safety Lead Time" = 1M, "Inbound Whse. Handling Time" = 5M.
        CreatePurchaseOrderWithSafetyLeadTimeAndWhseHandlingTime(PurchaseLine, '<1M>', '<5M>');

        // [WHEN] Set "Expected Receipt Date" = WORKDATE on the purchase line.
        NewExpectedReceiptDate := LibraryRandom.RandDate(30);
        PurchaseLine.Validate("Expected Receipt Date", NewExpectedReceiptDate);

        // [THEN] "Planned Receipt Date" = WorkDate() - 6M.
        PurchaseLine.TestField("Planned Receipt Date", CalcDate('<-6M>', NewExpectedReceiptDate));

        // [THEN] "Planned Receipt Date" recalculates "Expected Receipt Date", so it becomes equal to WorkDate() - 6M + 6M = WORKDATE.
        PurchaseLine.TestField("Expected Receipt Date", NewExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderOfApplyingDateFormulaeOnCalcPlannedRcptDateFromExpectedRcptDate()
    var
        PurchaseLine: Record "Purchase Line";
        NewExpectedReceiptDate: Date;
    begin
        // [FEATURE] [Calendar] [Order]
        // [SCENARIO 278667] While "Expected Receipt Date" is calculated by successively applying "Inbound Whse. Handling Time" and "Safety Lead Time" formulae, the "Planned Receipt Date" calculation should apply these formulae in the reversed order.
        Initialize();

        // [GIVEN] Purchase order line with "Safety Lead Time" = 1M, "Inbound Whse. Handling Time" = 2D.
        CreatePurchaseOrderWithSafetyLeadTimeAndWhseHandlingTime(PurchaseLine, '<1M>', '<2D>');

        // [WHEN] Set "Expected Receipt Date" = 01/06/20.
        NewExpectedReceiptDate := 20200601D;
        PurchaseLine.Validate("Expected Receipt Date", NewExpectedReceiptDate);

        // [THEN] "Planned Receipt Date" is calculated using the reversed formula "-1M-2D" applied to "Expected Receipt Date", and it is equal to 29/04/20.
        PurchaseLine.TestField("Planned Receipt Date", 20200429D);

        // [THEN] "Planned Receipt Date" recalculates "Expected Receipt Date" using the formula "2D+1M", so it becomes equal to 01/06/20.
        PurchaseLine.TestField("Expected Receipt Date", 20200601D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedDateFormulaForBlankFormula()
    var
        CalendarMgt: Codeunit "Calendar Management";
        DateFormula: DateFormula;
        ReversedDateFormula: DateFormula;
    begin
        // [FEATURE] [Calendar] [UT]
        // [SCENARIO 278667] Reversed blank date formula is blank.
        Initialize();

        Evaluate(DateFormula, '');
        CalendarMgt.ReverseDateFormula(ReversedDateFormula, DateFormula);

        Evaluate(DateFormula, '');
        Assert.AreEqual(DateFormula, ReversedDateFormula, DateFormulaReverseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedDateFormulaForSingleSummandFormula()
    var
        CalendarMgt: Codeunit "Calendar Management";
        DateFormula: DateFormula;
        ReversedDateFormula: DateFormula;
    begin
        // [FEATURE] [Calendar] [UT]
        // [SCENARIO 278667] Reversed '1M' date formula is '-1M' (changed sign).
        Initialize();

        Evaluate(DateFormula, '<1M>');
        CalendarMgt.ReverseDateFormula(ReversedDateFormula, DateFormula);

        Evaluate(DateFormula, '<-1M>');
        Assert.AreEqual(DateFormula, ReversedDateFormula, DateFormulaReverseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedDateFormulaForMultipleSummandFormula()
    var
        CalendarMgt: Codeunit "Calendar Management";
        DateFormula: DateFormula;
        ReversedDateFormula: DateFormula;
    begin
        // [FEATURE] [Calendar] [UT]
        // [SCENARIO 278667] Reversed '-2D+1Y+3M-4W' date formula is '+4M-3M-1Y+2D' (changed signs and order of summands).
        Initialize();

        Evaluate(DateFormula, '<-2D+1Y+3M-4W');
        CalendarMgt.ReverseDateFormula(ReversedDateFormula, DateFormula);

        Evaluate(DateFormula, '<+4W-3M-1Y+2D>');
        Assert.AreEqual(DateFormula, ReversedDateFormula, DateFormulaReverseErr);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure PurchPriceWithZeroDirectUnitCost()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePrice: Record "Purchase Price";
    begin
        // [FEATURE] [Purchase Price]
        // [SCENARIO 286702] Purchase prices with zero Direct Unit Cost can be used in purchase order
        Initialize();

        // [GIVEN] Create vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create item "ITEM" with "Last Direct Cost" = 100
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LibraryRandom.RandDecInRange(10, 100, 2);
        Item.Modify();

        // [GIVEN] Create purchase price for vendor "VEND" and item "ITEM" with Minimum Qty=0; Direct Unit Cost = 0;
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Vendor."No.", Item."No.", 0D, '', '', Item."Base Unit of Measure", 0);

        // [GIVEN] Create purchase order for vendor "VEND" with line Qty = 10
        CopyAllPriceDiscToPriceListLine();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Purchase line with Qty = 10 is being created
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Direct Unit Cost = 0
        PurchaseLine.TestField("Direct Unit Cost", 0);
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    procedure PostingNoAfterErrorOnPostInvoiceWithBlankInvMessage()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Invoice] [Post]
        // [SCENARIO 299919] "Posting No." is not modified on Purchase Invoice if posting aborted on "Invoice Message" check
        Initialize();

        // [GIVEN] Purchase Invoice "PI01" with blank "Invoice Message"
        // [GIVEN] Purchase Line for "PI01" with "Quantity" = 10
        CreatePurchaseDocumentWithEmptyInvoiceMessage(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Attempt to post "PI01"
        asserterror LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, false, true);

        // [THEN] Posting aborted with incorrect Invoice Message error
        Assert.ExpectedError(StrSubstNo(InvoiceMessageErr, PurchaseHeader."Document Type", PurchaseHeader."No."));

        // [THEN] "Posting No." blank on the Invoice "PI01"
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField("Posting No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingNoAfterErrorOnPostInvoiceOrderWithBlankInvMessage()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Order] [Post] [Invoice]
        // [SCENARIO 299919] "Posting No." is not modified on Purchase Order if "Post-Invoice" aborted on "Invoice Message" check
        Initialize();

        // [GIVEN] Purchase Order "PO01" with blank "Invoice Message"
        // [GIVEN] Purchase Line for "PO01" with "Quantity" = 10
        CreatePurchaseDocumentWithEmptyInvoiceMessage(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [WHEN] Attempt to post "PO01" with "Receive and Invoice"
        asserterror LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, true, true);

        // [THEN] Posting aborted with incorrect Invoice Message error
        Assert.ExpectedError(StrSubstNo(InvoiceMessageErr, PurchaseHeader."Document Type", PurchaseHeader."No."));

        // [THEN] "Posting No." blank on the Purchase Order "PO01"
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField("Posting No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorAfterPostReceiveOrderWithBlankInvMessage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedReceiptNo: Code[20];
    begin
        // [FEATURE] [Order] [Post] [Receive]
        // [SCENARIO 299919] Purchase Order with blank "Invoice Message" can be posted with Receive only
        Initialize();

        // [GIVEN] Purchase Order "PO01" with blank "Invoice Message"
        // [GIVEN] Purchase Line for "PO01" with "Quantity" = 10
        CreatePurchaseDocumentWithEmptyInvoiceMessage(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [WHEN] Attempt to post "PO01" with "Receive"
        PostedReceiptNo := LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, true, false);

        // [THEN] Purchase Receipt successfully posted
        PurchRcptHeader.Get(PostedReceiptNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorAfterPostCreditMemoWithBlankInvMessage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Credit Memo] [Post]
        // [SCENARIO 299919] Purchase Credit Memo with blank "Invoice Message" can be posted
        Initialize();

        // [GIVEN] Purchase Credit Memo "PCM01" with blank "Invoice Message"
        // [GIVEN] Purchase Line for "PCM01" with "Quantity" = 10
        CreatePurchaseDocumentWithEmptyInvoiceMessage(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Attempt to post "PCM01"
        PostedCreditMemoNo := LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, false, true);

        // [THEN] Purchase Credit Memo successfully posted
        PurchCrMemoHdr.Get(PostedCreditMemoNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TariffNumbersApplicationArea()
    var
        TariffNumbersPage: TestPage "Tariff Numbers";
    begin
        // [FEATURE] [UI] [Application Area]
        // [SCENARIO 343372] Tariff Numbers controls are enabled in SaaS
        Initialize();

        // [GIVEN] Enabled SaaS setup
        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Open Tariff Numbers page
        TariffNumbersPage.OpenNew();

        // [THEN] "No.", Description, "Supplementary Units" controls are enabled
        Assert.IsTrue(TariffNumbersPage."No.".Enabled(), '');
        Assert.IsTrue(TariffNumbersPage.Description.Enabled(), '');
        Assert.IsTrue(TariffNumbersPage."Supplementary Units".Enabled(), '');
        TariffNumbersPage.Close();
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatusStyleTextFavorable()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342484] GetStatusStyleText = 'Favorable' when Status = Open
        Initialize();

        // [WHEN] Function GetStatusStyleText is being run for Status = Open
        // [THEN] Return value is 'Favorable'
        Assert.AreEqual('Favorable', GetStatusStyleText("Purchase Document Status"::Open), 'Unexpected style text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatusStyleTextStrong()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342484] GetStatusStyleText = 'Strong' when Status <> Open
        // [WHEN] Function GetStatusStyleText is being run for Status <> Open
        // [THEN] Return value is 'Strong'
        Assert.AreEqual('Strong', GetStatusStyleText("Purchase Document Status"::"Pending Approval"), 'Unexpected style text');
        Assert.AreEqual('Strong', GetStatusStyleText("Purchase Document Status"::"Pending Prepayment"), 'Unexpected style text');
        Assert.AreEqual('Strong', GetStatusStyleText("Purchase Document Status"::Released), 'Unexpected style text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsAppliesToExtDocNoSummarizePerVendorTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 393756] "Applies-to Ext. Doc. No." should be blank when Suggest Vendor Payments with "Summarize per Vendor" = true
        Initialize();

        // [GIVEN] Two purchase invoices
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Run Suggest Vendor Payment report with "Summarize per Vendor" = true
        SuggestVendorPayment(GenJournalLine, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", true);

        // [THEN] "Applies-to Ext. Doc. No." in gen. jnl. line is blank
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsAppliesToExtDocNoSummarizePerVendorFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 393756] "Applies-to Ext. Doc. No." should not be blank when Suggest Vendor Payments with "Summarize per Vendor" = false
        Initialize();

        // [GIVEN] Two purchase invoices
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Run Suggest Vendor Payment report with "Summarize per Vendor" = false
        SuggestVendorPayment(GenJournalLine, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] "Applies-to Ext. Doc. No." in gen. jnl. line is not blank
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Applies-to Ext. Doc. No.");
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    procedure EditDescriptionVendorLedgerEntryLoggedInChangeLog()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        RecordRef: RecordRef;
        NewDescription, OldDescription : Text;
    begin
        Initialize();

        // [GIVEN] Create Vendor Ledger Entry
        LibraryPurchase.CreatePostVendorLedgerEntry(VendorLedgerEntry);
        OldDescription := LibraryRandom.RandText(MaxStrLen(VendorLedgerEntry.Description));
        VendorLedgerEntry.Description := OldDescription;
        VendorLedgerEntry.Modify();

        // [WHEN] Description is modified in vendor ledger entries
        NewDescription := LibraryRandom.RandText(MaxStrLen(VendorLedgerEntry.Description));
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntries.Description.Value(NewDescription);
        VendorLedgerEntries.Close();

        // [THEN] Description is changed & the change is logged in change log entry
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        Assert.AreEqual(NewDescription, VendorLedgerEntry.Description, VendorLedgerEntry.FieldCaption(Description));
        RecordRef.GetTable(VendorLedgerEntry);
        VerifyChangeLogFieldValue(RecordRef, VendorLedgerEntry.FieldNo(Description), OldDescription, NewDescription);
    end;

    [Test]
    [HandlerFunctions('ChangeLogEntriesModalPageHandler')]
    procedure ShowLoggedDescriptionChangesInVendorLedgerEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        NewDescription, OldDescription : Text;
    begin
        Initialize();

        // [GIVEN] Create Vendor Ledger Entry
        LibraryPurchase.CreatePostVendorLedgerEntry(VendorLedgerEntry);
        OldDescription := LibraryRandom.RandText(MaxStrLen(VendorLedgerEntry.Description));
        VendorLedgerEntry.Description := OldDescription;
        VendorLedgerEntry.Modify();

        // [GIVEN] Description is modified
        NewDescription := LibraryRandom.RandText(MaxStrLen(VendorLedgerEntry.Description));
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntries.Description.Value(NewDescription);
        VendorLedgerEntries.Close();

        LibraryVariableStorage.Enqueue(OldDescription);
        LibraryVariableStorage.Enqueue(NewDescription);

        // [WHEN] Show change log action is run
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntries.ShowChangeHistory.Invoke();

        // [THEN] Modal page Change Log Entries with logged changed is open
    end;

    [Test]
    procedure ValidateSalesPrepayAccountGLWhenPurchasePrepayPosted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 474502] It is not possible to change settings on a Sales Prepayment G/L Account if Purchase Prepayment invoices have been registered
        Initialize();

        // [GIVEN] Create Purchase Order
        CreatePurchaseDoc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Update Prepayment % on Purchase Header.
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseHeader.Modify(true);

        // [WHEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Create VAT posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Update "Sales Prepayments Account" with new GL Account.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Prepayments Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify();

        // [VERIFY] "VAT Prod. Posting Group does not give any error
        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceHavingAllocationAccountShouldPostGLEntriesWithCorrectDistributedAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: array[3] of Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GLEntry: Record "G/L Entry";
        AllocationAccountCode: Code[20];
        Share: array[3] of Decimal;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 494674] Allocation accounts and discount setup in a purchase document
        Initialize();

        // [GIVEN] Validate Discount Posting as All Discounts and Invoice Rounding as false in Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Discount Posting" := PurchasesPayablesSetup."Discount Posting"::"All Discounts";
        PurchasesPayablesSetup."Invoice Rounding" := false;
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Create Allocation Account with Fixed Distribution and save it in a Variable.
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();

        // [GIVEN] Generate and save Shares in three Variables.
        Share[1] := LibraryRandom.RandDecInDecimalRange(0.85, 0.85, 2);
        Share[2] := LibraryRandom.RandDecInDecimalRange(0.10, 0.10, 2);
        Share[3] := LibraryRandom.RandDecInDecimalRange(0.05, 0.05, 2);

        // [GIVEN] Add GL Accounts with Share in Fixed Account Distribution.
        for i := 1 to ArrayLen(GLAccount) do
            AddGLDestinationAccountForFixedDistribution(AllocationAccountCode, GLAccount[i], Share[i]);


        // [GIVEN] Create Purchase Invoice with Allocation Account.
        CreatePurchInvoiceWithAllocationAccount(PurchaseHeader, PurchaseLine, AllocationAccountCode);

        // [GIVEN] Generate and save distributed Amounts in three Variables.
        for i := 1 to ArrayLen(Amount) do
            Amount[i] := PurchaseLine.Amount * Share[i];

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Find GL Entry of GL Account 1.
        GLEntry.SetRange("G/L Account No.", GLAccount[1]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 1 and GL Entry Amount are same.
        Assert.AreEqual(Amount[1], GLEntry.Amount, StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount[1], GLEntry.TableCaption()));

        // [WHEN] Find GL Entry of GL Account 2.
        GLEntry.SetRange("G/L Account No.", GLAccount[2]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 2 and GL Entry Amount are same.
        Assert.AreEqual(Amount[2], GLEntry.Amount, StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount[2], GLEntry.TableCaption()));

        // [WHEN] Find GL Entry of GL Account 3.
        GLEntry.SetRange("G/L Account No.", GLAccount[3]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 3 and GL Entry Amount are same.
        Assert.AreEqual(Amount[3], GLEntry.Amount, StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount[3], GLEntry.TableCaption()));
    end;

    [Test]
    procedure DestinationAccountNumberTableRelationOnAllocationAccounts()
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        BankAccountNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        i: Integer;
        ExpectedErrorCodeLbl: Label 'DB:NothingInsideFilter', Locked = true;
        ValidateFieldErr: Label 'Validation field error.', Locked = true;
    begin
        // [SCENARIO 524460] "Destination Account Number" on "Alloc. Account Distribution" table has table relation filters:
        // for "Destination Account Type" = "G/L Account": "G/L Account" where "Account Type" = Posting and "Direct Posting" = true
        // for "Destination Account Type" = "Bank Account": "Bank Account"
        Initialize();

        // [GIVEN] Create a bank account
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Create two G/L accounts
        // [GIVEN] G/L account "A" has "Account Type" = "Begin Total" and "Direct Posting" = true
        GLAccountNo[1] := CreateGLAccount("G/L Account Type"::"Begin-Total", true);
        // [GIVEN] G/L account "B" has "Account Type" = "Posting" and "Direct Posting" = false
        GLAccountNo[2] := CreateGLAccount("G/L Account Type"::Posting, false);

        //[WHEN] Validate "Destination Account Number" on the "Alloc. Account Distribution" with created Bank account 
        AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"Bank Account");
        AllocAccountDistribution.Validate("Destination Account Number", BankAccountNo);

        //[THEN] Bank account no. is inserted on "Alloc. Account Distribution"
        Assert.IsTrue(AllocAccountDistribution."Destination Account Number" = BankAccountNo, ValidateFieldErr);

        //[WHEN] Validate "Destination Account Number" on the "Alloc. Account Distribution" with random code for bank account
        AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"Bank Account");
        asserterror AllocAccountDistribution.Validate("Destination Account Number", LibraryRandom.RandText(20));

        //[WHEN] Validate "Destination Account Number" on the "Alloc. Account Distribution" with G/L accounts 
        for i := 1 to ArrayLen(GLAccountNo) do begin
            AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"G/L Account");
            asserterror AllocAccountDistribution.Validate("Destination Account Number", GLAccountNo[i]);
        end;

        //[THEN] The errors "Bank Acount No. can't be found in Bank Account table" and "G/L Acount No. can't be found in G/L Account table" are executed
        Assert.ExpectedErrorCode(ExpectedErrorCodeLbl);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Payables");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.DisableExtendedPriceCalculation();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Payables");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Payables");
    end;

    local procedure PreparePurchOrderWithPrepaymentInvAndCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDoc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        ModifyPurchPrepaymentAccount(PurchaseLine);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
    end;

    local procedure ModifyPurchPrepaymentAccount(var PurchaseLine: Record "Purchase Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount.Validate("VAT Bus. Posting Group", PurchaseLine."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure PostPartialPurchOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDoc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPartialPurchReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDoc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CopyPurchDocument(var ToPurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20])
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc(DocType, DocNo, ToPurchaseHeader);
    end;

    local procedure CopyPurchDocumentFromArchived(var ToPurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalculateLines: Boolean; ArchivedDocType: Enum "Purchase Document Type")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DocNoOccurrence: Integer;
        DocVersionNo: Integer;
    begin
        CopyDocumentMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, false, false);
        GetPurchDocNoOccurenceAndVersionFromArchivedDoc(DocNoOccurrence, DocVersionNo, ArchivedDocType, DocNo);
        CopyDocumentMgt.SetArchDocVal(DocNoOccurrence, DocVersionNo);
        CopyDocumentMgt.CopyPurchDoc(DocType, DocNo, ToPurchaseHeader);
    end;

    local procedure BatchPostPurchaseOrderRun()
    var
        BatchPostPurchaseOrders: Report "Batch Post Purchase Orders";
    begin
        Commit(); // COMMIT is required here.
        Clear(BatchPostPurchaseOrders);
        BatchPostPurchaseOrders.Run();
    end;

    local procedure BatchPostPurchaseInvoiceRun()
    var
        BatchPostPurchaseInvoices: Report "Batch Post Purchase Invoices";
    begin
        Commit(); // COMMIT is required here.
        Clear(BatchPostPurchaseInvoices);
        BatchPostPurchaseInvoices.Run();
    end;

    local procedure CreateOneItemPurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type")
    var
        PurchLine: Record "Purchase Line";
    begin
        // Create a new invoiced blanket purchase order
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure UpdateDefaultSafetyLeadTimeOnManufacturingSetup(DefaultSafetyLeadTime: DateFormula)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Default Safety Lead Time", DefaultSafetyLeadTime);
        ManufacturingSetup.Modify(true);
    end;

    local procedure ModifyPurchasesPayablesSetup(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldAllowVATDifference := PurchasesPayablesSetup."Allow VAT Difference";
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure PurchaseLineFactboxForPurchaseDocument(PurchaseDocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify the error while opening the Availability from fact box in case the Type is G/L and the Account No. is same as Item No.

        // Setup: Create two new Purchase Order with Item and G/L Account with same code.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseDocType);
        CreatePurchaseDocumentforGLAcc(PurchaseHeader2, PurchaseLine2, PurchaseDocType, PurchaseLine."No.");

        // Exercise: Open Purchase line fact box and click on Availability option to shown Error.
        asserterror OpenPurchaseLinefactBox(PurchaseHeader2);

        // Verify: Verify Error when open purchase line fact box with created G/L Line purchase document.
        Assert.ExpectedTestFieldError(PurchaseLine2.FieldCaption(Type), Format(PurchaseLine2.Type::Item));
    end;

    local procedure UpdateGeneralLedgerSetup(VATDifferenceAllowed: Decimal): Decimal
    begin
        LibraryERM.SetMaxVATDifferenceAllowed(VATDifferenceAllowed);
        exit(VATDifferenceAllowed);
    end;

    local procedure CreateAndModifyGLAccount(GenProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithVAT(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; PurchaseVATAccount: Code[20]; PurchVATUnrealAccount: Code[20])
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAccount);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", PurchVATUnrealAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VATBusPostingGroup: Code[20]; No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateAndModifyVendor(VATBusPostingGroup));
        CreatePurchaseLine(PurchaseHeader, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndModifyVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Using Random value for Quantity and Direct Unit Cost because value is not important.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", No, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

#if not CLEAN25
    local procedure CreatePurchaseLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount"; PurchasePrice: Record "Purchase Price")
    begin
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, PurchasePrice."Item No.", PurchasePrice."Vendor No.", WorkDate(), '', '', PurchasePrice."Unit of Measure Code",
          PurchasePrice."Minimum Quantity" * 2);
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLineDiscount.Modify(true);
    end;
#endif

    local procedure CreatePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLineModified(PurchaseLine, PurchaseHeader);
        exit(NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series"));
    end;

    local procedure CreatePurchaseDocumentforGLAcc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLineforGLAcc(PurchaseLine, PurchaseHeader, ItemNo);
        exit(NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series"));
    end;

#if not CLEAN25
    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; PurchasePrice: Record "Purchase Price")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchasePrice."Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchasePrice."Item No.", PurchasePrice."Minimum Quantity" / 2);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchasePrice."Item No.", PurchasePrice."Minimum Quantity");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchasePrice."Item No.", PurchasePrice."Minimum Quantity" * 2);
    end;
#endif

    local procedure CreatePurchaseOrderWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderCard(): Code[20]
    var
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".Activate();
        PurchaseOrderNo := PurchaseOrder."No.".Value();
        PurchaseOrder.OK().Invoke();
        exit(PurchaseOrderNo);
    end;

#if not CLEAN25
    local procedure CreatePurchasePrice(var PurchasePrice: Record "Purchase Price")
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, CreateVendor(), Item."No.", WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Used Random Value for Direct Unit Cost.
        PurchasePrice.Modify(true);
    end;
#endif

    local procedure CreatePurchaseLineFromPurchaseOrderPage(ItemNo: Code[20]; PurchaseHeaderNo: Code[20]; VendorNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeaderNo);
        PurchaseOrder."Buy-from Vendor No.".SetValue(VendorNo);
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(ItemNo);
        PurchaseOrder.PurchLines.Quantity.SetValue(Quantity);
        PurchaseOrder.OK().Invoke();
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Header and Lines.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreateAndModifyPurchaseLine(PurchaseHeader, PurchaseLine, 1);
        CreateAndModifyPurchaseLine(PurchaseHeader, PurchaseLine, -1);
        PurchaseLine.Validate("Qty. to Receive", 0);  // Take Quantity to Receive as 0 on second line to Calculate VAT Amount for single Line.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithSafetyLeadTimeAndWhseHandlingTime(var PurchaseLine: Record "Purchase Line"; SafetyLeadTimeAsText: Text; InbdWhseHandlingTimeAsText: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        SafetyLeadTime: DateFormula;
        InbdWhseHandlingTime: DateFormula;
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());

        Evaluate(SafetyLeadTime, SafetyLeadTimeAsText);
        Evaluate(InbdWhseHandlingTime, InbdWhseHandlingTimeAsText);
        PurchaseLine.Validate("Safety Lead Time", SafetyLeadTime);
        PurchaseLine.Validate("Inbound Whse. Handling Time", InbdWhseHandlingTime);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndModifyPurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SignFactor: Integer)
    begin
        // Create Purchase Lines with Random Quantity And Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), SignFactor * LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure DeleteVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Delete();
    end;

    local procedure DeleteUserSetup(var UserSetup: Record "User Setup"; ResponsibilityCenterCode: Code[10])
    begin
        UserSetup.SetRange("Purchase Resp. Ctr. Filter", ResponsibilityCenterCode);
        UserSetup.FindFirst();
        UserSetup.Delete(true);
    end;

    local procedure GetPurchDocNoOccurenceAndVersionFromArchivedDoc(var DocNoOccurrence: Integer; var DocVersionNo: Integer; ArchivedDocType: Enum "Purchase Document Type"; DocNo: Code[20])
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", ArchivedDocType);
        PurchaseHeaderArchive.SetRange("No.", DocNo);
        PurchaseHeaderArchive.FindFirst();
        DocNoOccurrence := PurchaseHeaderArchive."Doc. No. Occurrence";
        DocVersionNo := PurchaseHeaderArchive."Version No.";
    end;

    local procedure FindGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        exit(GenJournalLine.FindFirst())
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; Type: Enum "General Posting Type")
    begin
        VATEntry.SetCurrentKey(Base);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange(Type, Type);
        VATEntry.FindSet();
    end;

    local procedure FindVLE(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CreateAndArchivePurchOrderWithRespCenter(var VendorNo: Code[20]; RespCenterCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreatePurchaseHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendor());
        VendorNo := PurchHeader."Buy-from Vendor No.";
        PurchHeader.Validate("Responsibility Center", RespCenterCode);
        PurchHeader.Modify(true);
        CreatePurchaseLineModified(PurchLine, PurchHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        ArchiveManagement.StorePurchDocument(PurchHeader, false);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type", AccountNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateMultipleJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]) Amount: Decimal
    var
        Counter: Integer;
    begin
        for Counter := 1 to LibraryRandom.RandInt(5) + 1 do begin
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, AccountNo, LibraryRandom.RandDec(100, 2) * 100);
            Amount += GenJournalLine.Amount;
        end;
    end;

    local procedure CreateSetupForGLAccounts(var VATPostingSetup: Record "VAT Posting Setup"; var GLAccountNo: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccountNo2: Code[20];
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GLAccountNo := CreateAndModifyGLAccount(GenProductPostingGroup.Code, '', VATProductPostingGroup.Code);
        GLAccountNo2 := CreateAndModifyGLAccount('', VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code, GLAccountNo, GLAccountNo2);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithEmptyInvoiceMessage(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Invoice Message", '');
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        Commit();
    end;

    local procedure CreatePurchaseLineModified(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseLineforGLAcc(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountAndRename(ItemNo),
          LibraryRandom.RandInt(10));
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGLAccountAndRename(ItemNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccountWithVAT(GLAccount);
        GLAccount.Rename(ItemNo);
        exit(GLAccount."No.");
    end;

    local procedure CreateResponsibilityCenterAndUserSetup(): Code[10]
    var
        Location: Record Location;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        ResponsibilityCenter.Validate("Location Code", LibraryWarehouse.CreateLocation(Location));
        ResponsibilityCenter.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify(true);
        exit(ResponsibilityCenter.Code);
    end;

#if not CLEAN25
    local procedure CreatePurchasePriceWithMinimumQuantity(var PurchasePrice: Record "Purchase Price"; MinQty: Decimal)
    begin
        PurchasePrice.Init();
        PurchasePrice.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchasePrice.Validate("Item No.", LibraryInventory.CreateItemNo());
        PurchasePrice.Validate("Minimum Quantity", MinQty);
        PurchasePrice.Insert(true);
    end;

    local procedure CreatePurchPrice(var PurchasePrice: Record "Purchase Price"; VendNo: Code[20])
    begin
        LibraryCosting.CreatePurchasePrice(PurchasePrice, VendNo, LibraryInventory.CreateItemNo(), WorkDate(), '', '', '', 0);
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchasePrice.Modify(true);
    end;
#endif
    local procedure GetStatusStyleText(Status: Enum "Purchase Document Status"): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Status := Status;
        exit(PurchaseHeader.GetStatusStyleText());
    end;

#if not CLEAN25
    local procedure OpenPurchasePricesPage(var PurchasePrices: TestPage "Purchase Prices"; VendorNo: Code[20]; StartingDateFilter: Text[30])
    var
        VendorList: TestPage "Vendor List";
    begin
        VendorList.OpenEdit();
        VendorList.FILTER.SetFilter("No.", VendorNo);
        PurchasePrices.Trap();
        VendorList.Prices.Invoke();
        PurchasePrices.StartingDateFilter.SetValue(StartingDateFilter);
    end;
#endif

    local procedure OpenPurchaseLinefactBox(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    PurchaseOrder.OpenEdit();
                    PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
                    PurchaseOrder.Control3.Availability.DrillDown();
                end;
            PurchaseHeader."Document Type"::Quote:
                begin
                    PurchaseQuote.OpenEdit();
                    PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
                    PurchaseQuote.Control5.Availability.DrillDown();
                end;
        end;
    end;

    local procedure OpenVendorHistPaytoFactBox(var VendorHistPaytoFactBox: TestPage "Vendor Hist. Pay-to FactBox"; No: Code[20])
    begin
        VendorHistPaytoFactBox.OpenView();
        VendorHistPaytoFactBox.FILTER.SetFilter("No.", No);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

#if not CLEAN25
    local procedure StartingDateOnPurchasePrice(StartingDateFilter: Text[1]; StartingDate: Date)
    var
        Vendor: Record Vendor;
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // Setup: Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Open Purchase Prices Page and Enter date code in Starting Date Filter.
        OpenPurchasePricesPage(PurchasePrices, Vendor."No.", StartingDateFilter);

        // Verify: Verify that correct date comes in "Starting Date Filter".
        PurchasePrices.StartingDateFilter.AssertEquals(StartingDate);
    end;
#endif

    local procedure SuggestVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; LastPmtDate: Date; VendorNo: Code[20]; SummarizePerVendor: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // Create General Journal Template and General Journal Batch.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        // Run Suggest Vendor Payments Report.
        Clear(SuggestVendorPayments);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.InitializeRequest(
            LastPmtDate, false, 0, false, LastPmtDate, VendorNo, SummarizePerVendor,
            "Gen. Journal Account Type"::"G/L Account", '', "Bank Payment Type"::" ");  // Blank value for Account No.
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.Run();
    end;

    local procedure SetPurchAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        PurchasesPayablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateUserSetupPurchRespCtrFilter(var UserSetup: Record "User Setup"; PurchRespCtrFilter: Code[10]) OldPurchRespCtrFilter: Code[10]
    begin
        OldPurchRespCtrFilter := UserSetup."Purchase Resp. Ctr. Filter";
        UserSetup.Validate("Purchase Resp. Ctr. Filter", PurchRespCtrFilter);
        UserSetup.Modify(true);
    end;

    local procedure UpdateInvoiceDiscountAndVATAmountOnPusrchaseOrderStatistics(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; AmountToPost: Decimal; VATAmount: Decimal; VATDiffAmount: Decimal)
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Statistics.Invoke();

        PurchaseOrder.PurchLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        PurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
        PurchaseOrder.PurchLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);

        PurchaseLine.Find();
        PurchaseLine.TestField("VAT Difference", VATDiffAmount);
    end;

    local procedure VerifyPurchaseInvoiceLine(DocumentNo: Code[20]; InvDiscAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Inv. Discount Amount", InvDiscAmount);
    end;

    local procedure VerifyPurchaseInvoiceHeader(No: Code[20]; DocumentDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("No.", No);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Document Date", DocumentDate);
    end;

    local procedure VerifyTransactionNoOnGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        TransactionNo := GLEntry."Transaction No.";

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Transaction No.", TransactionNo);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyTransactionNoCalculation(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
    begin
        FindGLEntry(GLEntry, DocumentNo);
        TransactionNo := GLEntry."Transaction No.";
        GLEntry.Next(-3);
        Assert.AreNotEqual(
          TransactionNo - GLEntry."Transaction No.", 1,
          StrSubstNo(MustNotBeEqualErr, TransactionNo - GLEntry."Transaction No.", 1));
    end;

    local procedure VerifyArchPurchaseOrderHeader(PurchHeader: Record "Purchase Header")
    var
        PurchHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchHeaderArchive.SetRange("Document Type", PurchHeader."Document Type");
        PurchHeaderArchive.SetRange("No.", PurchHeader."No.");
        PurchHeaderArchive.FindFirst();

        PurchHeaderArchive.TestField("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchHeaderArchive.TestField("Due Date", PurchHeader."Due Date");
        PurchHeaderArchive.TestField("Payment Terms Code", PurchHeader."Payment Terms Code");
        PurchHeaderArchive.TestField("Payment Discount %", PurchHeader."Payment Discount %");
        PurchHeaderArchive.TestField(Amount, PurchHeader.Amount);
        PurchHeaderArchive.TestField("Amount Including VAT", PurchHeader."Amount Including VAT");
    end;

    local procedure VerifyArchPurchaseOrderLine(PurchLine: Record "Purchase Line")
    var
        PurchLineArchive: Record "Purchase Line Archive";
    begin
        // Assumes only one line of each type exists in the archived purchase order.
        PurchLineArchive.SetRange("Document Type", PurchLine."Document Type");
        PurchLineArchive.SetRange("Document No.", PurchLine."Document No.");
        PurchLineArchive.SetRange(Type, PurchLine.Type);
        PurchLineArchive.FindFirst();

        // Check quantities are right
        PurchLineArchive.TestField(Quantity, PurchLine.Quantity);
        PurchLineArchive.TestField("Quantity Invoiced", PurchLine."Quantity Invoiced");
        PurchLineArchive.TestField("Quantity Received", PurchLine."Quantity Received");

        // Check prices are right
        PurchLineArchive.TestField("Unit Price (LCY)", PurchLine."Unit Price (LCY)");
        PurchLineArchive.TestField(Amount, PurchLine.Amount);
        PurchLineArchive.TestField("Amount Including VAT", PurchLine."Amount Including VAT");

        // Check discounts are right
        PurchLineArchive.TestField("Line Discount %", PurchLine."Line Discount %");
        PurchLineArchive.TestField("Line Discount Amount", PurchLine."Line Discount Amount");
    end;

    local procedure VerifyPurchaseOrder(DocumentNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", DocumentNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Buy-from Vendor No.", VendorNo);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("No.", ItemNo);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPriceAndLineDiscountOnPurchaseLine(PurchaseLine: Record "Purchase Line"; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscountPercentage: Decimal)
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine2.SetRange("No.", PurchaseLine."No.");
        PurchaseLine2.SetRange(Quantity, Quantity);
        PurchaseLine2.FindFirst();
        PurchaseLine2.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine2.TestField("Line Discount %", LineDiscountPercentage);
    end;

    local procedure VerifyVATAmount(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        VATAmount: Decimal;
    begin
        // Verifying VAT Entry fields.
        FindVATEntry(VATEntry, DocumentNo, VATEntry.Type::Purchase);
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        Assert.AreNearlyEqual(
          VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    begin
        VATEntry.TestField(Base, ExpectedBase);
        VATEntry.TestField(Amount, ExpectedAmount);
    end;

#if not CLEAN25
    local procedure VerifyCopiedPurchPrice(CopiedFromPurchasePrice: Record "Purchase Price"; VendNo: Code[20])
    var
        PurchasePrice: Record "Purchase Price";
    begin
        PurchasePrice := CopiedFromPurchasePrice;
        PurchasePrice."Vendor No." := VendNo;
        PurchasePrice.Find();
        PurchasePrice.TestField("Direct Unit Cost", CopiedFromPurchasePrice."Direct Unit Cost");
    end;

    local procedure VerifyUnchangedPurchPrice(PurchPrice: Record "Purchase Price")
    begin
        PurchPrice.Find(); // test that existing price remains unchanged
        PurchPrice.SetRange("Vendor No.", PurchPrice."Vendor No.");
        Assert.RecordCount(PurchPrice, 1);
    end;

    local procedure VerifyPurchasePrice(ItemNo: Code[20]; VendorNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchasePrice: Record "Purchase Price";
    begin
        PurchasePrice.SetRange("Item No.", ItemNo);
        PurchasePrice.SetRange("Vendor No.", VendorNo);
        PurchasePrice.FindFirst();
        PurchasePrice.TestField("Direct Unit Cost", DirectUnitCost);
    end;

    local procedure VerifyPurchaseLineDiscount(ItemNo: Code[20]; VendorNo: Code[20]; DiscountPct: Decimal)
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        PurchaseLineDiscount.SetRange("Item No.", ItemNo);
        PurchaseLineDiscount.SetRange("Vendor No.", VendorNo);
        PurchaseLineDiscount.FindFirst();
        PurchaseLineDiscount.TestField("Line Discount %", DiscountPct);
    end;
#endif

    local procedure VerifyChangeLogFieldValue(RecordRef: RecordRef; FieldNo: Integer; OldValue: Text; NewValue: Text)
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", RecordRef.Number);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", RecordRef.GetPosition(false));
        ChangeLogEntry.SetRange("Field No.", FieldNo);
        ChangeLogEntry.FindLast();
        Assert.AreEqual(ChangeLogEntry."Old Value", OldValue, 'Change Log Entry (old value) for field ' + Format(FieldNo));
        Assert.AreEqual(ChangeLogEntry."New Value", NewValue, 'Change Log Entry (new value) for field ' + Format(FieldNo));
    end;

    local procedure CreatePurchInvoiceWithAllocationAccount(
          var PurchaseHeader: Record "Purchase Header";
          var PurchaseLine: Record "Purchase Line";
          AllocationAccountCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", Format(LibraryRandom.RandInt(5)));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode,
            LibraryRandom.RandIntInRange(6, 6));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1500, 1500, 0));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
        AllocationAccountNo := Format(LibraryRandom.RandText(5));
        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Fixed);
        AllocationAccountPage.Name.SetValue(LibraryRandom.RandText(5));

        exit(AllocationAccountNo);
    end;

    local procedure CreateGLAccount(GLAccountType: Enum Microsoft.Finance.GeneralLedger.Account."G/L Account Type"; DirectPosting: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := PadStr(
            '1' + LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."),
            DATABASE::"G/L Account"), MaxStrLen(GLAccount."No."), '0');
        GLAccount."Account Type" := GLAccountType;
        GLAccount."Direct Posting" := DirectPosting;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount.Insert();

        exit(AllocationAccount."No.");
    end;

    local procedure AddGLDestinationAccountForFixedDistribution(AllocationAccountNo: Code[20]; var GLAccount: Record "G/L Account"; Shape: Decimal)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        AllocAccountDistribution."Allocation Account No." := AllocationAccountNo;
        AllocAccountDistribution."Line No." := LibraryUtility.GetNewRecNo(AllocAccountDistribution, AllocAccountDistribution.FieldNo("Line No."));
        AllocAccountDistribution."Account Type" := AllocAccountDistribution."Account Type"::Fixed;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"G/L Account";
        AllocAccountDistribution."Destination Account Number" := GLAccount."No.";
        AllocAccountDistribution.Validate(Share, Shape);
        AllocAccountDistribution.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrderCHandler(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    begin
        // Handles the Batch Post Purchase Orders Report.
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.PostingDate.SetValue('');
        BatchPostPurchaseOrders.ReplacePostingDate.SetValue(true);
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchCountHandler(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    begin
        // Handles the Batch Post Purchase Orders Report.
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.PostingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(20)) + 'D>', WorkDate()));
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchInvCountHandler(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices")
    begin
        // Handles the Batch Post Purchase Invoices Report.
        BatchPostPurchaseInvoices.PostingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(20)) + 'D>', WorkDate()));
        BatchPostPurchaseInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchDocDateHandler(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    var
        DocumentDate: Date;
    begin
        // Handles the Batch Post Purchase Orders Report.
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(20)) + 'D>', WorkDate());
        LibraryVariableStorage.Enqueue(DocumentDate);
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.PostingDate.SetValue(DocumentDate);
        BatchPostPurchaseOrders.ReplaceDocumentDate.SetValue(true);
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Modal Page Handler.
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsUpdateInvDiscontAndTotalVATHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_Invoicing.SetValue(LibraryVariableStorage.DequeueDecimal()); // Invoice Discount on Invoicing tab
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLine: TestPage "VAT Amount Lines")
    var
        VATAmount: Decimal;
    begin
        // Modal Page Handler.
        VATAmount := VATAmountLine."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.Enqueue(VATAmount);
        VATAmountLine."VAT Amount".SetValue(VATAmount);
    end;

#if not CLEAN25
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchPricesSelectPriceOfVendorModalPageHandler(var PurchasePrices: TestPage "Purchase Prices")
    begin
        PurchasePrices.VendNoFilterCtrl.SetValue(LibraryVariableStorage.DequeueText());
        PurchasePrices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchPricesCancelPriceSelectionModalPageHandler(var PurchasePrices: TestPage "Purchase Prices")
    begin
        PurchasePrices.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchPricesAndLineDisc_MPH(var PurchasesPriceandLineDisc: TestPage "Purchases Price and Line Disc.")
    var
        DummyPurchPriceLineDiscBuff: Record "Purch. Price Line Disc. Buff.";
    begin
        PurchasesPriceandLineDisc.FILTER.SetFilter(
          "Line Type",
          Format(DummyPurchPriceLineDiscBuff."Line Type"::"Purchase Price"));
        LibraryVariableStorage.Enqueue(PurchasesPriceandLineDisc."Direct Unit Cost".AsDecimal());

        PurchasesPriceandLineDisc.FILTER.SetFilter(
          "Line Type",
          Format(DummyPurchPriceLineDiscBuff."Line Type"::"Purchase Line Discount"));
        LibraryVariableStorage.Enqueue(PurchasesPriceandLineDisc."Line Discount %".AsDecimal());
        PurchasesPriceandLineDisc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchPricesAndLineDisc_MPH_VerifyEnabled(var PurchasesPriceandLineDisc: TestPage "Purchases Price and Line Disc.")
    begin
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Line Type".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Line Type".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Unit of Measure Code".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Unit of Measure Code".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Minimum Quantity".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Minimum Quantity".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Line Discount %".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Line Discount %".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Direct Unit Cost".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Direct Unit Cost".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Starting Date".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Starting Date".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Ending Date".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Ending Date".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Currency Code".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Currency Code".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Variant Code".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Variant Code".Caption));
        Assert.IsTrue(
          PurchasesPriceandLineDisc."Vendor No.".Enabled(),
          StrSubstNo(FieldEnabledErr, PurchasesPriceandLineDisc."Vendor No.".Caption));
    end;
#endif

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CreateNewStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

#if not CLEAN25
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewPurchPriceMPH(var PurchasePrices: TestPage "Purchase Prices")
    begin
        PurchasePrices."Vendor No.".SetValue(LibraryVariableStorage.DequeueText());
        PurchasePrices."Direct Unit Cost".SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchasePrices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewPurchDiscountMPH(var PurchaseLineDiscounts: TestPage "Purchase Line Discounts")
    begin
        PurchaseLineDiscounts."Vendor No.".SetValue(LibraryVariableStorage.DequeueText());
        PurchaseLineDiscounts."Line Discount %".SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseLineDiscounts.OK().Invoke();
    end;
#endif

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowErrorsNotificationHandler(var Notification: Notification): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        ErrorMessageMgt.ShowErrors(Notification); // simulate a click on notification's action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler(var PostBatchForm: TestRequestPage "Batch Post Purchase Orders")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.Receive.SetValue(true);
            PostBatchForm.Invoice.SetValue(true);
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.Receive.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.Invoice.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [ModalPageHandler]
    procedure ChangeLogEntriesModalPageHandler(var ChangeLogEntries: TestPage "Change Log Entries");
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ChangeLogEntries."Old Value".Value(), ChangeLogEntries."Old Value".Caption());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ChangeLogEntries."New Value".Value(), ChangeLogEntries."New Value".Caption());
        ChangeLogEntries.OK().Invoke();
    end;
}

