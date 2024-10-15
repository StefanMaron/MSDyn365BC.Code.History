﻿codeunit 134762 "Test Purchase Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Purchase] [UI]
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        ExpectedCost: Decimal;
        ExpectedQuantity: Decimal;
        PurchHeaderPostingNo: Code[20];
        NoRecordsErr: Label 'There are no preview records to show.';
        RecordRestrictedTxt: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        PostingPreviewNoTok: Label '***', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Invoice opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ExpectedCost, ExpectedQuantity);

        // Execute the page
        PurchaseInvoice.Trap;
        PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);

        GLPostingPreview.Trap;
        PurchaseInvoice.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, ExpectedCost, ExpectedQuantity);

        // Execute the page
        PurchaseOrder.Trap;
        PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);

        GLPostingPreview.Trap;
        PurchaseOrder.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Credit Memo opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", ExpectedCost, ExpectedQuantity);

        PurchaseHeader."Vendor Cr. Memo No." := '98771337';
        PurchaseHeader.Modify(true);

        // Execute the page
        PurchaseCreditMemo.Trap;
        PAGE.Run(PAGE::"Purchase Credit Memo", PurchaseHeader);

        Commit();
        GLPostingPreview.Trap;
        PurchaseCreditMemo.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Return Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ExpectedCost, ExpectedQuantity);

        PurchaseHeader."Vendor Cr. Memo No." := '98771337';
        PurchaseHeader.Modify(true);

        // Execute the page
        PurchaseReturnOrder.Trap;
        PAGE.Run(PAGE::"Purchase Return Order", PurchaseHeader);

        Commit();
        GLPostingPreview.Trap;
        PurchaseReturnOrder.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('PaymentRegistrationSetup')]
    [Scope('OnPrem')]
    procedure PaymentRegistrationErrorsWhenNothingToPost()
    var
        PaymentRegistration: TestPage "Payment Registration";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Posting preview of empty Payment Registration shows error "Nothing to post"
        Initialize();
        DeletePaymentRegistrationSetup;
        PaymentRegistration.Trap;
        PAGE.Run(PAGE::"Payment Registration");
        Commit();
        ErrorMessagesPage.Trap;
        PaymentRegistration.PreviewPayments.Invoke;
        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('PaymentRegistrationSetup')]
    [Scope('OnPrem')]
    procedure PaymentRegistrationLumpErrorsWhenNothingToPost()
    var
        PaymentRegistration: TestPage "Payment Registration";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Posting preview of empty Payment Registration Lump shows error "Nothing to post"
        Initialize();
        DeletePaymentRegistrationSetup;
        PaymentRegistration.Trap;
        PAGE.Run(PAGE::"Payment Registration");
        Commit();
        ErrorMessagesPage.Trap;
        PaymentRegistration.PreviewLump.Invoke;
        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceListOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Invoice List Order opens G/L Posting Preview with the navigatable entries to be posted.
        // Initialize the purchase header
        Initialize();
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ExpectedCost, ExpectedQuantity);

        // Execute the page
        PurchaseInvoices.Trap;
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeader);

        GLPostingPreview.Trap;
        PurchaseInvoices.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderListOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Order List Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize the purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, ExpectedCost, ExpectedQuantity);

        // Execute the page
        PurchaseOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeader);

        GLPostingPreview.Trap;
        PurchaseOrderList.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoListOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Credit Memo List Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", ExpectedCost, ExpectedQuantity);

        PurchaseHeader."Vendor Cr. Memo No." := '98771337';
        PurchaseHeader.Modify(true);

        // Execute the page
        PurchaseCreditMemos.Trap;
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeader);

        Commit();
        GLPostingPreview.Trap;
        PurchaseCreditMemos.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderListOpensPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Return Order List Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ExpectedCost, ExpectedQuantity);

        PurchaseHeader."Vendor Cr. Memo No." := '98771337';
        PurchaseHeader.Modify(true);

        // Execute the page
        PurchaseReturnOrderList.Trap;
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeader);

        Commit();
        GLPostingPreview.Trap;
        PurchaseReturnOrderList.Preview.Invoke;

        if not GLPostingPreview.First then
            Error(NoRecordsErr);
        GLPostingPreview.OK.Invoke;

        // Cleanup
        PurchaseHeader.Delete();
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePreviewCorrectResults()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        ValueEntriesPreview: TestPage "Value Entries Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Invoice opens G/L Posting Preview with the navigatable Value Entries
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ExpectedCost, ExpectedQuantity);

        // Execute the preview
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview. Actual error: ' + GetLastErrorText);
        // Show the pages. Verification done in page handlers.
        ValueEntriesPreview.Trap;
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Value Entry"));
        GLPostingPreview.Show.Invoke;
        // Verify results
        Assert.AreEqual(ExpectedQuantity,
          ValueEntriesPreview."Valued Quantity".AsInteger, 'Valued quantity is not as expected.');
        Assert.AreEqual(
          ExpectedQuantity * ExpectedCost,
          ValueEntriesPreview."Cost Amount (Actual)".AsDEcimal,
          'Posted cost amount is not as expected.');
        Assert.AreEqual(0, ValueEntriesPreview."Cost Amount (Non-Invtbl.)".AsDEcimal, 'Non-inventoriable cost amount is non-zero.');

        GLPostingPreview.Close();

        // Cleanup
        PurchaseHeader.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderPreviewCorrectResults()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        ItemLedgerEntriesPreview: TestPage "Item Ledger Entries Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Purchase Order opens G/L Posting Preview with the navigatable Item Ledger Entries
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, ExpectedCost, ExpectedQuantity);

        // Execute the preview
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview. Actual error: ' + GetLastErrorText);

        // Show the pages. Verification done in page handlers.
        ItemLedgerEntriesPreview.Trap;
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Item Ledger Entry"));
        GLPostingPreview.Show.Invoke;

        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntriesPreview.Quantity.AsInteger, 'Posted quantity is not as expected.');
        Assert.AreEqual(
          ExpectedQuantity * ExpectedCost,
          ItemLedgerEntriesPreview.CostAmountActual.AsDEcimal,
          'Posted cost amount is not as expected.');
        Assert.AreEqual(0, ItemLedgerEntriesPreview.CostAmountNonInvtbl.AsDEcimal, 'Non-inventoriable cost amount is non-zero.');

        GLPostingPreview.Close();

        // Cleanup
        PurchaseHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoicePreviewWorksWithApprovals()
    var
        PurchaseHeader: Record "Purchase Header";
        RestrictedRecord: Record "Restricted Record";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
        ExpectedErrorMessage: Text;
        ActualErrorMessage: Text;
    begin
        // [SCENARIO] Preview action on Purchase Invoice should work even if Invoice is under Approval Workflow.
        Initialize();
        // Initialize
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        // [GIVEN] Purchase Invoice that is under an approval workflow.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ExpectedCost, ExpectedQuantity);
        RecordRestrictionMgt.RestrictRecordUsage(PurchaseHeader, '');
        Commit();
        RestrictedRecord.SetRange("Record ID", PurchaseHeader.RecordId);
        Assert.IsTrue(RestrictedRecord.FindFirst, 'Missing RestrictedRecord');

        // [WHEN] Preview is executed.
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        // [THEN] GETLASTERRORTEXT should be null
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview. Actual error: ' + GetLastErrorText);
        GLPostingPreview.Close();

        ClearLastError();
        Clear(PurchPostYesNo);

        ExpectedErrorMessage := StrSubstNo(RecordRestrictedTxt,
            Format(Format(RestrictedRecord."Record ID", 0, 1)));

        // [WHEN] Post is executed.
        asserterror PurchPostYesNo.Run(PurchaseHeader);
        // [THEN] GETLASTERRORTEXT should be non-null
        ActualErrorMessage := CopyStr(GetLastErrorText, 1, StrLen(ExpectedErrorMessage));
        Assert.AreEqual(ExpectedErrorMessage, ActualErrorMessage, 'Unexpected error message.');

        // Cleanup
        PurchaseHeader.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPartialPurchaseOrderPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        ItemNo: Code[20];
    begin
        // [SCENARIO 263954] Preview action can be opened for Purchase Order with FIFO Item, if was before posted partially several times.
        Initialize();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // [GIVEN] Inventory Setup: Automatic Cost Posting = TRUE, Expected Cost Posting = TRUE
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Item with Lot Tracking and Costing Method FIFO
        ItemNo := CreateItemWithFIFO;
        CreateAndPostItemJournalLine(ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Create Purchase Order, Receive and Invoice partially
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(5, 10));
        PostPartialQuantity(PurchaseHeader, true);

        // [GIVEN] Receive Purchase Order again partially
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        PostPartialQuantity(PurchaseHeader, false);

        // [WHEN] Open Post Preview
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);

        // [THEN] Preview is open
        Assert.ExpectedError('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCalcInvAndDiscPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 381357] Stan can see posting preview of released purchase invoice when "Calc. Inv. and Pmt. Discount" is set in setup.
        // [GIVEN] "Calc. Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        // [GIVEN] Released purchase invoice where "Payment Discount %" = 5%
        Initialize();
        CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Stan calls "Post Preview" from invoice
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors.
        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithCalcInvAndDiscPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 202205] Stan can see posting preview of released purchase order when "Calc. Inv. and Pmt. Discount" is set in setup.
        // [GIVEN] "Calc. Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        // [GIVEN] Released purchase order where "Payment Discount %" = 5%
        Initialize();
        CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [WHEN] Stan calls "Post Preview" from invoice
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors.
        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithCalcInvAndDiscPreviewPartialInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 263954] Stan can see posting preview of released purchase order when "Calc. Inv. and Pmt. Discount" is set in setup.
        // [GIVEN] "Calc. Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        // [GIVEN] "Qty. to Invoice" = 90, "Quantity" = 100
        // [GIVEN] Released purchase order where "Payment Discount %" = 5%
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandIntInRange(5, 10));
        PurchaseHeader.Modify(true);

        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 3);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();

        // [WHEN] Stan calls "Post Preview" from invoice
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors.
        GLPostingPreview.Close();
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscToleranceConsidersOnPostingPreview()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Payment Discount] [Payment Discount Tolerance]
        // [SCENARIO 277573] Payment Discount Tolerance considers when preview application of payment to invoice

        Initialize();

        // [GIVEN] Posted payment and invoice with possible payment discount tolerance
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText(Format(LibraryRandom.RandIntInRange(3, 10)) + 'D');
        PostPaidInvWithPmtDiscTol(InvNo, PmtNo);
        FindEntriesAndSetAppliesToID(ApplyingVendLedgerEntry, VendLedgerEntry, InvNo, PmtNo);
        Commit();
        LibraryVariableStorage.Enqueue(DATABASE::"Detailed Vendor Ledg. Entry");

        // [WHEN] Preview application of payment to invoice
        ApplyingVendLedgerEntry."Document No." := ApplyingVendLedgerEntry."Document No.";
        ApplyingVendLedgerEntry."Posting Date" := VendEntryApplyPostedEntries.GetApplicationDate(ApplyingVendLedgerEntry);
        asserterror VendEntryApplyPostedEntries.PreviewApply(ApplyingVendLedgerEntry, ApplyUnapplyParameters);

        // [THEN] Three entries expected in "G/L Posting Preview" page for table "Detailed Vendor Ledger Entry"
        // [THEN] Payment Discount Tolerance and two applications (invoice -> payment and payment -> invoice)
        // Verification done in DtldVendLedgEntryPageHandler
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgerEntryIsClosedInPostingPreview()
    var
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 328755] Invoice Vendor Ledger Entry is Closed in Posting Preview when Purchase Invoice has "Payment Method Code" with Bal. Account No. filled.
        Initialize();

        // [GIVEN] Purchase Invoice has "Payment Method Code" with Bal. Account No. filled.
        LibraryInventory.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        PaymentMethod.Modify(true);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify(true);
        Commit();

        // [WHEN] Vendor Ledger Entries Preview is opened from Posting Preview of Purchase Invoice.
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        VendLedgEntriesPreview.Trap;
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Vendor Ledger Entry"));
        GLPostingPreview.Show.Invoke;

        // [THEN] Vendor Ledger Entry with "Document Type" = Invoice has Open = False.
        VendLedgEntriesPreview.FILTER.SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));
        VendLedgEntriesPreview.Open.AssertEquals(false);
        VendLedgEntriesPreview.OK.Invoke;
        GLPostingPreview.OK.Invoke;
    end;

    [Test]
    procedure PurchaseInvoiceInvAndDiscPreview()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLPostingPreview: TestPage "G/L Posting Preview";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 379797] Stan can preview posting of Purchase Invoice when invoice discount is specified for the invoice
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        PurchaseLine.Modify(true);

        Commit();

        PurchaseHeader.CalcFields(Amount);
        PurchaseHeader.TestField(Amount);

        GLPostingPreview.Trap();

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(PurchaseHeader.Amount / 10);
        Commit();
        PurchaseInvoice.Preview.Invoke();

        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedPostingPreviewPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview";
    begin
        // [SCENARIO 354973] "Extended G/L Posting Preview" page shows Vendor related entries
        Initialize();

        // [GIVEN] Set GLSetup."Posting Preview Type" = Extended
        UpdateGLSetupPostingPreviewType("Posting Preview Type"::Extended);

        // [GIVEN] Create gen. journal line
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));

        // [WHEN] Run posting preview 
        Commit();
        ExtendedGLPostingPreview.Trap();
        asserterror PurchPostYesNo.Preview(PurchaseHeader);

        // [THEN] "Extended G/L Posting Preview" page shows Vendor related entries
        VerifyExtendedPostingPreviewVendorRelatedEntriesExist(ExtendedGLPostingPreview);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedPostingPreviewVATHierarchicalView()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview";
        TotalVATAmount: array[2] of Decimal;
        TotalBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 354973] Extended posting preview shows grouped VAT entries 
        Initialize();

        // [GIVEN] Set GLSetup."Posting Preview Type" = Extended
        UpdateGLSetupPostingPreviewType("Posting Preview Type"::Extended);
        // [GIVEN] Create 2 VAT Posting Setups: VBG, VPG1 and VBG, VPG2
        CreateTwoVATPostingSetups(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20), 0);

        // [GIVEN] Create purchase order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        // [GIVEN] Create purchase line with VAT Posting Setups: VBG, VPG1
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, TotalVATAmount[1], TotalBaseAmount[1], VATPostingSetup[1]);

        // [GIVEN] Create purchase line with VAT Posting Setups: VBG, VPG2
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, TotalVATAmount[2], TotalBaseAmount[2], VATPostingSetup[2]);

        // [GIVEN] Run posting preview 
        Commit();
        ExtendedGLPostingPreview.Trap();
        asserterror PurchPostYesNo.Preview(PurchaseHeader);

        // [WHEN] Set Show Hierarchical Veiw = true on "Extended G/L Posting Preview" page
        ExtendedGLPostingPreview.ShowHierarchicalViewControl.SetValue(true);

        // [THEN] Extended G/L Posting Preview page shows grouped VAT Entries: VBG, VPG1 and VBG, VPG2
        VerifyVATEntriesExtendedGrouped(ExtendedGLPostingPreview, VATPostingSetup, TotalVATAmount, TotalBaseAmount);
    end;

    procedure PreviewPurchInvoiceWithSameInvoiceAndPostingInvoiceNos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TestPurchPostPreview: Codeunit "Test Purchase Preview";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 406700] When PurchSetup has same values for Invoice Nos. and Posted Invoice Nos. the creating PurchInvoiceHeader.No. = "***"
        Initialize();
        BindSubscription(TestPurchPostPreview);

        // [GIVEN] Set Purch Setup "Invoice Nos." = "III" and "Posted Invoice Nos." = "III"
        UpdatePurchSetupPostedInvoiceNos();

        // [GIVEN] Create purchase invoice
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        Commit();

        // [WHEN] Run posting preview
        GLPostingPreview.Trap;
        asserterror PurchPostYesNo.Preview(PurchaseHeader);
        GLPostingPreview.Close();

        // [THEN] Purch Header "Posting No." = "***"
        Assert.AreEqual(PostingPreviewNoTok, TestPurchPostPreview.GetPurchHeaderPostingNo(), 'Invalid Posting No.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Purchase Preview");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Purchase Preview");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Purchase Preview");
    end;

    local procedure DeletePaymentRegistrationSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if PaymentRegistrationSetup.Get(UserId) then begin
            PaymentRegistrationSetup.Delete();
            Commit();
        end
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemCost: Decimal; Quantity: Decimal)
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", ItemCost);
        Item.Modify(true);

        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        Commit();
    end;

    local procedure CreatePurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.SetCalcInvDiscount(true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandIntInRange(5, 10));
        PurchaseHeader.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();
    end;

    local procedure CreatePurchaseOrderWithPrepayment(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prepayment %", LibraryRandom.RandInt(10));
        Vendor.Modify();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", '', 1, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));
        PurchaseLine.Modify(true);

        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        Commit();
    end;

    local procedure CreatePurchLineWithVATPostingSetup(PurchaseHeader: Record "Purchase Header"; var TotalVATAmount: Decimal; var TotalBaseAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandInt(5) do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
                LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), 1);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
            PurchaseLine.Modify(true);
            TotalBaseAmount := TotalBaseAmount + PurchaseLine."VAT Base Amount";
            TotalVATAmount := TotalVATAmount + PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        end;
    end;

    local procedure CreateItemWithFIFO(): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            LibraryInventory.CreateItem(Item);
            Validate("Costing Method", "Costing Method"::FIFO);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDecInRange(10, 100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; VATPercent1: Decimal; VATPercent2: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATPercent1);

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup[2].Validate("VAT Calculation Type", VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup[2].Validate("VAT %", VATPercent2);
        VATPostingSetup[2].Modify(true);
    end;

    local procedure PostPartialQuantity(var PurchaseHeader: Record "Purchase Header"; Invoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            FindFirst();
            Validate("Qty. to Receive", 1); // specific value needed for test
            Modify(true);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure PostPaidInvWithPmtDiscTol(var InvNo: Code[20]; var PmtNo: Code[20])
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        PmtDiscTol: Decimal;
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);

        PmtDiscTol := PaymentTerms."Discount %" / LibraryRandom.RandDec(3, 5);
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtAmount := Round(InvoiceAmount * PmtDiscTol / 100 - InvoiceAmount);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -InvoiceAmount);
        InvNo := GenJournalLine."Document No.";
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, -PmtAmount);
        GenJournalLine.Validate("Posting Date", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1); // date after "Pmt. Disc. Posting Date"
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PmtNo := GenJournalLine."Document No.";
    end;

    local procedure UpdatePurchSetupPostedInvoiceNos()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Posted Invoice Nos." := PurchSetup."Invoice Nos.";
        PurchSetup.Modify();
    end;

    procedure GetPurchHeaderPostingNo(): Code[20]
    begin
        exit(PurchHeaderPostingNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterUpdatePostingNos', '', false, false)]
    local procedure OnAfterUpdatePostingNos(var PurchaseHeader: Record "Purchase Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSupressed: Boolean)
    begin
        PurchHeaderPostingNo := PurchaseHeader."Posting No.";
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentRegistrationSetup(var PaymentRegistrationSetup: TestPage "Payment Registration Setup")
    begin
        PaymentRegistrationSetup.OK.Invoke;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure FindEntriesAndSetAppliesToID(var ApplyingVendLedgerEntry: Record "Vendor Ledger Entry"; var VendLedgerEntry: Record "Vendor Ledger Entry"; InvNo: Code[20]; PmtNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(
          ApplyingVendLedgerEntry, ApplyingVendLedgerEntry."Document Type"::Payment, PmtNo);
        ApplyingVendLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendLedgerEntry, ApplyingVendLedgerEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, InvNo);
        LibraryERM.SetAppliestoIdVendor(VendLedgerEntry);
    end;

    local procedure UpdateGLSetupPostingPreviewType(PostingPreviewType: Enum "Posting Preview Type")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Posting Preview Type", PostingPreviewType);
        GLSetup.Modify(true);
    end;

    local procedure VerifyExtendedPostingPreviewVendorRelatedEntriesExist(var ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview")
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
        DummyDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        ExtendedGLPostingPreview.DocEntriesPreviewSubform.Filter.SetFilter("Table Name", DummyVendorLedgerEntry.TableCaption());
        ExtendedGLPostingPreview.DocEntriesPreviewSubform.First();
        ExtendedGLPostingPreview.DocEntriesPreviewSubform.Filter.SetFilter("Table Name", DummyDetailedVendorLedgEntry.TableCaption());
        ExtendedGLPostingPreview.DocEntriesPreviewSubform.First();
    end;

    local procedure VerifyVATEntriesExtendedGrouped(var ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview"; VATPostingSetup: array[2] of Record "VAT Posting Setup"; TotalVATAmount: array[2] of Decimal; TotalBaseAmount: array[2] of Decimal)
    begin
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Filter.SetFilter("VAT Bus. Posting Group", VATPostingSetup[1]."VAT Bus. Posting Group");
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Filter.SetFilter("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.First();
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Amount.AssertEquals(TotalVATAmount[1]);
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Base.AssertEquals(TotalBaseAmount[1]);
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Filter.SetFilter("VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group");
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Filter.SetFilter("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.First();
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Amount.AssertEquals(TotalVATAmount[2]);
        ExtendedGLPostingPreview.VATEntriesPreviewHierarchical.Base.AssertEquals(TotalBaseAmount[2]);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendEntriesPreview: TestPage "Detailed Vend. Entries Preview";
    begin
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(LibraryVariableStorage.DequeueInteger));
        LibraryVariableStorage.Enqueue(GLPostingPreview."No. of Records".Value);
        DetailedVendEntriesPreview.Trap;
        GLPostingPreview."No. of Records".DrillDown;
        DetailedVendEntriesPreview.FILTER.SetFilter(
          "Entry Type", Format(DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance"));
        Assert.IsTrue(
          DetailedVendEntriesPreview.Amount.AsDEcimal <> 0, 'Payment Discount Tolerance does not exist');
        DetailedVendEntriesPreview.FILTER.SetFilter("Entry Type", Format(DetailedVendorLedgEntry."Entry Type"::Application));
        Assert.IsTrue(
          DetailedVendEntriesPreview.Amount.AsDEcimal <> 0, 'Application does not exist');
        DetailedVendEntriesPreview.Next();
        Assert.IsTrue(
          DetailedVendEntriesPreview.Amount.AsDEcimal <> 0, 'Application does not exist');
    end;
}

