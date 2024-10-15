codeunit 144062 "ERM Payment Terms Reporting"
{
    // // [FEATURE] [Payment Terms] [Purchase]

    Permissions = TableData "Vendor Ledger Entry" = id,
                  TableData "Detailed Vendor Ledg. Entry" = i;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DocumentTypeMustBeInvErr: Label 'Document Type must be equal to ''Invoice''';
        IncorrectAvgNumToMakePmtErr: Label 'Incorrect average number of days to make payment', Locked = true;
        IncorrectPctOfPmtsPaidInDaysErr: Label 'Incorrect percent of payments paid in days', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateOnPurchOrder()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Order] [UI]
        // [SCENARIO 212351] Field "Invoice Receipt Date" exists in Purchase Order

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        PurchaseOrder.OpenNew;
        Assert.IsTrue(PurchaseOrder."Invoice Receipt Date".Visible, 'Field Invoice Receipt Date is not visible');
        PurchaseOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateOnPurchInvoice()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO 212351] Field "Invoice Receipt Date" exists in Purchase Invoice

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        PurchaseInvoice.OpenNew;
        Assert.IsTrue(PurchaseInvoice."Invoice Receipt Date".Visible, 'Field Invoice Receipt Date is not visible');
        PurchaseInvoice.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateOnPurchOrderUnderSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Order] [UI] [SaaS]
        // [SCENARIO 212351] Field "Invoice Receipt Date" exists in Purchase Order under SaaS version of NAV

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PurchaseOrder.OpenNew;
        Assert.IsTrue(PurchaseOrder."Invoice Receipt Date".Visible, 'Field Invoice Receipt Date is not visible');
        PurchaseOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateOnPurchInvoiceUnderSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI] [SaaS]
        // [SCENARIO 212351] Field "Invoice Receipt Date" exists in Purchase Invoice under SaaS version of NAV

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PurchaseInvoice.OpenNew;
        Assert.IsTrue(PurchaseInvoice."Invoice Receipt Date".Visible, 'Field Invoice Receipt Date is not visible');
        PurchaseInvoice.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateEqualsDocDateOnPurchOrderCreation()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" equals "Document Date" when create Purchase Order

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        PurchaseHeader.Init;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        PurchaseHeader.TestField("Invoice Receipt Date");
        PurchaseHeader.TestField("Invoice Receipt Date", PurchaseHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateEqualsDocDateOnPurchInvoiceCreation()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" equals "Document Date" when create Purchase Invoice

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        PurchaseHeader.Init;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Insert(true);
        PurchaseHeader.TestField("Invoice Receipt Date");
        PurchaseHeader.TestField("Invoice Receipt Date", PurchaseHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateBlankOnPurchCrMemoCreation()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" is blank when create Purchase Credit Memo

        Initialize;
        LibraryLowerPermissions.SetPurchDocsCreate;
        PurchaseHeader.Init;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
        PurchaseHeader.Insert(true);
        PurchaseHeader.TestField("Invoice Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateEqualsDocDateOnInvGenJnlLineCreation()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" equals "Document Date" when create General Journal Line with "Document Type" = Invoice

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, '', 0);
        GenJournalLine.TestField("Invoice Receipt Date");
        GenJournalLine.TestField("Invoice Receipt Date", GenJournalLine."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateBlankOnPmtGenJnlLineCreation()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" is blank when create General Journal Line with "Document Type" = Payment

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment, 0, '', 0);
        GenJournalLine.TestField("Invoice Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateEqualsDocWhenSwitchDocTypeToInvoiceOnGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" equals "Document Date" when switch "Document Type" to Invoice on General Journal Line

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', 0);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.TestField("Invoice Receipt Date");
        GenJournalLine.TestField("Invoice Receipt Date", GenJournalLine."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotValidateInvoiceReceiptDateOnPmtGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Cannot validate "Invoice Receipt Date" in General Journal Line with "Document Type" = Payment

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', 0);
        asserterror GenJournalLine.Validate("Invoice Receipt Date", WorkDate);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(DocumentTypeMustBeInvErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateNotChangedOnDocDateValidationOnPurchDocCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" not changes on "Document Date" validation of General Journal Line

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddAccountPayables;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        ExpectedDate := PurchaseHeader."Invoice Receipt Date";
        PurchaseHeader.Validate("Document Date", WorkDate + 1);
        PurchaseHeader.TestField("Invoice Receipt Date", ExpectedDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateNotChangedOnDocDateValidatioOnGenJnlLineCreation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Field "Invoice Receipt Date" not changes on "Document Date" validation of General Journal Line

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice, 0, '', 0);
        ExpectedDate := GenJournalLine."Invoice Receipt Date";
        GenJournalLine.Validate("Document Date", WorkDate + 1);
        GenJournalLine.TestField("Invoice Receipt Date", ExpectedDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateInVendLedgEntryAfterPurchDocPost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 212351] Field "Invoice Receipt Date" inherits to Vendor Ledger Entry after posting Purchase Document

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddAccountPayables;

        // [GIVEN] Purchase Invoice with "Invoice Receipt Date" = "X"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);

        // [WHEN] Post Purchase Invoice
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Vendor Ledger Entry created with "Invoice Receipt Date" = "X"
        VendorLedgerEntry.TestField("Invoice Receipt Date");
        VendorLedgerEntry.TestField("Invoice Receipt Date", PurchaseHeader."Invoice Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceReceiptDateInVendLedgEntryAfterGenJnlDocPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 212351] Field "Invoice Receipt Date" inherits to Vendor Ledger Entry after posting General Journal Line with "Document Type" = Invoice

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddJournalsPost;

        // [GIVEN] General Journal Line with "Document Type" = Invoice and "Invoice Receipt Date" = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo, -1);

        // [WHEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Vendor Ledger Entry created with "Invoice Receipt Date" = "X"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Invoice Receipt Date");
        VendorLedgerEntry.TestField("Invoice Receipt Date", GenJournalLine."Invoice Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeInvoiceReceiptDateInVendorLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Stan can change "Invoice Receipt Date" in Vendor Ledger Entry

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddJournalsPost;

        // [GIVEN] Posted Vendor Ledger Entry "Document Type" = Invoice and "Invoice Receipt Date" = 01.01.2017
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry."Invoice Receipt Date" += 1;
        ExpectedDate := VendorLedgerEntry."Invoice Receipt Date";

        // [WHEN] Change "Invoice Receipt Date" to 02.01.2017 on Vendor Ledger Entry
        VendEntryEdit.Run(VendorLedgerEntry);

        // [THEN] Vendor Ledger Entry has "Invoice Receipt Date" = 02.01.2017
        VendorLedgerEntry.Find;
        VendorLedgerEntry.TestField("Invoice Receipt Date", ExpectedDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildPmtApplicationBufferReturnsNothingIfVendorExcludedFromPmtPracticesReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] No purchase invoices includes into Payment Application Buffer by function BuildPmtApplicationBuffer of codeunit "Payment Terms Reporting Mgt." for Vendor with "Exclude from Pmt. Pract. Rep." option

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        MockVendLedEntryNo(true, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, 0D, false);

        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        Assert.RecordCount(TempPaymentApplicationBuffer, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildPmtApplicationBufferIncludesOnlyInvoicesWithinSpecifiedPeriod()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Only purchase invoices within specified period includes into Payment Application Buffer by function BuildPmtApplicationBuffer of codeunit "Payment Terms Reporting Mgt."

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // 4 invoices are within StartingDate and Ending Date
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, 0D, true);
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate + 1, 0D, 0D, 0D, true);
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate - 1, 0D, 0D, 0D, true);
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate, 0D, 0D, 0D, true);

        // 3 documents are outside period or with different document type
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate - 1, 0D, 0D, 0D, true);
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate + 1, 0D, 0D, 0D, true);
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::"Credit Memo", StartingDate, 0D, 0D, 0D, true);

        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        Assert.RecordCount(TempPaymentApplicationBuffer, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocDateUsesForInvoiceReceiptDateWhenItsBlankOnBuildPmtApplicationBuffer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] "Document Date" uses for "Invoice Receipt Date" when it's blank on bulding Payment Application Buffer by function BuildPmtApplicationBuffer of codeunit "Payment Terms Reporting Mgt."

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Vendor Ledger Entry with blank "Invoice Receipt Date" and "Document Date" = "X"
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, 0D, 0D, true);

        // [WHEN] Invoke function BuildPmtApplicationBuffer
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [THEN] "Invoice Receipt Date" is "Document Date" in Payment Application Buffer for associated Vendor Ledger Entry
        TempPaymentApplicationBuffer.TestField("Invoice Receipt Date", StartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsNotOverdueWhenWorkDateBeforeDueDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Invoice does not count as overdue if "Due Date" is after Work Date when invoke function GetPctOfPmtsNotPaid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 5
        // [GIVEN] Invoice with "Due Date"  = January 6
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, WorkDate + 1, true);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsOverdueWhenWorkDateAfterDueDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Invoice counts as overdue if "Due Date" is before Work Date when invoke function GetPctOfPmtsNotPaid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 5
        // [GIVEN] Invoice with "Due Date"  = January 4
        MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, WorkDate - 1, true);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 100% of payments are overdue
        Assert.AreEqual(
          100, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsNotOverdueWhenPartialPmtAppliedBeforeDueDateAndWorkDateBefore()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Invoice does not count as overdue if Partial Payment before "Due Date" and "Work Date" before "Due Date"

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 4
        // [GIVEN] Invoice with "Due Date"  = January 5
        DueDate := LibraryRandom.RandDateFrom(WorkDate, LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 3
        MockPmtWithApplication(InvLedgEntryNo, DueDate - 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsOverdueWhenPartialPmtAppliedBeforeDueDateAndWorkDateAfter()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Invoice counts as overdue if Partial Payment before "Due Date" and "Work Date" after "Due Date"
        // [SCENARIO 253950] Partial payments does not affect the percantage of payments not paid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 5
        // [GIVEN] Invoice with "Due Date"  = January 4
        DueDate := LibraryRandom.RandDateFrom(WorkDate, -LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 3
        MockPmtWithApplication(InvLedgEntryNo, DueDate - 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 100% of payments are overdue
        Assert.AreEqual(
          100, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsNotOverdueWhenPartialPmtAppliedAfterDueDateAndWorkDateBefore()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] Invoice with "Due Date" after "Work Date" that is not paid does not consider in overdue payments calculation
        // [SCENARIO 253950] Partial payments does not affect the percantage of payments not paid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        DueDate := LibraryRandom.RandDateFrom(WorkDate, LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 5
        MockPmtWithApplication(InvLedgEntryNo, DueDate + 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsOverdueWhenFullPmtAppliedAfterDueDateAndWorkDateBefore()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Invoice counts as overdue if Full Payment after "Due Date" and "Work Date" before "Due Date"

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        DueDate := LibraryRandom.RandDateFrom(WorkDate, LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, false);

        // [GIVEN] Full Payment with "Posting Date" = January 5
        MockPmtWithApplication(InvLedgEntryNo, DueDate + 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          100, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAvgNumberOfDaysToMakePmtIfPmtDateLessThanInvRcptDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] When calculate average number of days to make payment by function GetAvgNumberOfDaysToMakePmt of codeunit "Payment Terms Reporting Mgt." the payments with "Posting Date" less than "Invoice Receipt Date" does not count
        // [SCENARIO 252313] When calculate average number of days to make payment by function GetAvgNumberOfDaysToMakePmt of codeunit "Payment Terms Reporting Mgt." only the payments with "Posting Date" after "Invoice Receipt Date" considers for calculati

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 5
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 1);

        // [GIVEN] Partial Payment with "Posting Date" = January 3
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate - 1);

        // [GIVEN] Partial Payment with "Posting Date" = January 2
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate - 2);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetAvgNumberOfDaysToMakePmt
        // [THEN] Function returns 1, excluding second payment with "Posting Date" less than "Invoice Receipt Date"
        Assert.AreEqual(
          1, PaymentPracticesMgt.GetAvgNumberOfDaysToMakePmt(TempPaymentApplicationBuffer),
          IncorrectAvgNumToMakePmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPctOfPmtsPaidInDaysAllPayments()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        LastPmtDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] All payments considered by function GetPctOfPmtsPaidInDays of codeunit Payment Terms Reporting Mgt.

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 5
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 1);

        // [GIVEN] Partial Payment with "Posting Date" = January 10
        LastPmtDate := LibraryRandom.RandDateFromInRange(StartingDate, 3, 5);
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", LastPmtDate);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsPaidInDays for days from 0 to 6
        // [THEN] Function returns 100
        Assert.AreEqual(
          100, PaymentPracticesMgt.GetPctOfPmtsPaidInDays(TempPaymentApplicationBuffer, 0, LastPmtDate - StartingDate),
          IncorrectPctOfPmtsPaidInDaysErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPctOfPmtsPaidInDaysHalfPayments()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        LastPmtDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] Half of payments considered by function GetPctOfPmtsPaidInDays of codeunit Payment Terms Reporting Mgt.

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 5
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 1);

        // [GIVEN] Partial Payment with "Posting Date" = January 10
        LastPmtDate := LibraryRandom.RandDateFromInRange(StartingDate, 3, 5);
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", LastPmtDate);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsPaidInDays for days from 0 to 1
        // [THEN] Function returns 50
        Assert.AreEqual(
          50, PaymentPracticesMgt.GetPctOfPmtsPaidInDays(TempPaymentApplicationBuffer, 0, 1),
          IncorrectPctOfPmtsPaidInDaysErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPctOfPmtsPaidInDaysNoPayments()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212351] No payments considered by function GetPctOfPmtsPaidInDays of codeunit Payment Terms Reporting Mgt.

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 9
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", LibraryRandom.RandDateFromInRange(StartingDate, 3, 5));

        // [GIVEN] Partial Payment with "Posting Date" = January 10
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", LibraryRandom.RandDateFromInRange(StartingDate, 3, 5));
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetAvgNumberOfDaysToMakePmt for days from 0 to 1
        // [THEN] Function returns 0
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsPaidInDays(TempPaymentApplicationBuffer, 0, 1),
          IncorrectPctOfPmtsPaidInDaysErr);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepDoesNotShowDetailsIfShowInvoicesIsOff()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvRcptDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 212351] Payment Practices report do not show details if "Show Invoices" option is off on Request Page

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Full Payment with "Posting Date" = January 5
        MockOverdueFullPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate, InvRcptDate);

        // [WHEN] Run "Payment Practices" report from January 1 to January 31 and save as XML
        RunPaymentPracticesReport(StartingDate, EndingDate, false);

        // [THEN] XML nodes 'AvgVendorNo' and 'OverdueVendorNo' related to Invoice Details does not exist
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist('AvgVendorNo', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.AssertElementWithValueNotExist('OverdueVendorNo', VendorLedgerEntry."Vendor No.");

        // [THEN] XML nodes with totals exists
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('AverageDays', InvRcptDate - StartingDate);
        LibraryReportDataset.AssertCurrentRowValueEquals('PctOfPmtsDue', 100);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepShowDetailsIfShowInvoicesIsOn()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvRcptDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 212351] Payment Practices report shows details if "Show Invoices" option is on on Request Page

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Partial Payment with "Posting Date" = January 5
        MockOverdueFullPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate, InvRcptDate);

        // [WHEN] Run "Payment Practices" report from January 1 to January 31 and save as XML
        RunPaymentPracticesReport(StartingDate, EndingDate, true);

        // [THEN] XML nodes 'AvgVendorNo' and 'OverdueVendorNo' related to Invoice Details exists
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals('AvgVendorNo', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OverdueVendorNo', VendorLedgerEntry."Vendor No.");

        // [THEN] XML nodes with totals exists
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('AverageDays', InvRcptDate - StartingDate);
        LibraryReportDataset.AssertCurrentRowValueEquals('PctOfPmtsDue', 100);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesPaymentsPaidInDays()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
        i: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 212351] Payment Practices shows percent of payments paid in days per each Payment Period Setup

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 5
        // [GIVEN] Partial Payment with "Posting Date" = January 6
        // [GIVEN] Partial Payment with "Posting Date" = January 7
        for i := 1 to 3 do
            MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + i);

        // [GIVEN] Payment Period Setup
        // [GIVEN] From 0 days to 1
        // [GIVEN] From 2 days to 3
        // [GIVEN] From 3 days to 4
        MockThreePmtPeriodSetup;
        Commit;

        // [WHEN] Run "Payment Practices" report from January 1 to January 31 and save as XML
        RunPaymentPracticesReport(StartingDate, EndingDate, false);

        // [THEN] Three XML nodes per each Payment Period Setup generated with 33,33 % of payments paid in days each
        LibraryReportDataset.LoadDataSetFile;
        for i := 1 to 3 do begin
            LibraryReportDataset.MoveToRow(i + 1);
            LibraryReportDataset.AssertCurrentRowValueEquals('PctOfPmtsPaidInDays', 33.33);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceIsNotOverdueWhenPartialPmtAppliedAfterDueDateAndWorkDateEqualInvPostingDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] Invoice with "Due Date" equals "Work Date" that is not paid does not consider in overdue payments calculation
        // [SCENARIO 253950] Partial payments does not affect the percantage of payments not paid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 3
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, WorkDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 4
        MockPmtWithApplication(InvLedgEntryNo, WorkDate + 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPctOfPmtsPaidInDaysInvPaidBeforeInvReceiptDateDoesNotCount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] Invoice paid before "Invoice Receipt Date" does not consider by function GetPctOfPmtsPaidInDays of codeunit Payment Terms Reporting Mgt.

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] First Partial Payment with "Posting Date" = January 6
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 2);

        // [GIVEN] Second Partial Payment with "Posting Date" = January 5
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 1);

        // [GIVEN] Third artial Payment with "Posting Date" = January 3
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate - 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsPaidInDays for days from 0 to 1 days
        // [THEN] Function returns 66.67 (2/3 payments paid in 0 to 1 days; First and second counts)
        Assert.AreEqual(
          66.67, PaymentPracticesMgt.GetPctOfPmtsPaidInDays(TempPaymentApplicationBuffer, 0, 1),
          IncorrectPctOfPmtsPaidInDaysErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAvgNumberOfDaysToMakePmtIfPmtDateEqualsInvRcptDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] When calculate average number of days to make payment by function GetAvgNumberOfDaysToMakePmt of codeunit "Payment Terms Reporting Mgt." the payments with "Posting Date" equals "Invoice Receipt Date" considers for calculation

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 6
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate + 2);

        // [GIVEN] Partial Payment with "Posting Date" = January 3
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetAvgNumberOfDaysToMakePmt
        // [THEN] Function returns 1, excluding second payment with "Posting Date" equals than "Invoice Receipt Date"
        Assert.AreEqual(
          1, PaymentPracticesMgt.GetAvgNumberOfDaysToMakePmt(TempPaymentApplicationBuffer),
          IncorrectAvgNumToMakePmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAvgNumberOfDaysToMakePmtAllPmtsBeforeInvRcptDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] Function GetAvgNumberOfDaysToMakePmt of codeunit "Payment Terms Reporting Mgt." returns zero when all payments with "Posting Date" before "Invoice Receipt Date"

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] Invoice with "Invoice Receipt Date"  = January 4
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, StartingDate, true);

        // [GIVEN] Partial Payment with "Posting Date" = January 3
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", StartingDate - 1);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetAvgNumberOfDaysToMakePmt
        // [THEN] Function returns 0, excluding  payment with "Posting Date" before "Invoice Receipt Date"
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetAvgNumberOfDaysToMakePmt(TempPaymentApplicationBuffer),
          IncorrectAvgNumToMakePmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPctOfPmtsNotPaidIsZeroWhenNoOverduePmts()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252313] Function GetPctOfPmtsNotPaid returns zero when all payments paid in time

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 4
        // [GIVEN] Invoice with "Due Date"  = January 5
        DueDate := LibraryRandom.RandDateFrom(WorkDate, LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, false);

        // [GIVEN] Full Payment with "Posting Date" = January 5
        MockPmtWithApplication(InvLedgEntryNo, DueDate);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 0% of payments are overdue
        Assert.AreEqual(
          0, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPaymentDoesNotAffectPctOfPmtsNotPaid()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        InvLedgEntryNo: Integer;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 253950] Partial payments does not affect the percantage of payments not paid

        Initialize;
        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsPost;
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Work Date is January 4
        // [GIVEN] Invoice "A" with "Due Date"  = January 3
        DueDate := LibraryRandom.RandDateFrom(WorkDate, -LibraryRandom.RandIntInRange(3, 5));
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, true);

        // [GIVEN] Full Payment for the invoice "A" with "Posting Date" = January 3
        MockPmtWithApplication(InvLedgEntryNo, DueDate);

        // [GIVEN] Invoice "B" with "Due Date"  = January 3
        InvLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, 0D, DueDate, false);

        // [GIVEN] Two partial payments for the invoice "B" with "Posting Date" = January 3
        MockPmtWithApplication(InvLedgEntryNo, DueDate);
        MockPmtWithApplication(InvLedgEntryNo, DueDate);
        PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);

        // [WHEN] Invoke function GetPctOfPmtsNotPaid
        // [THEN] 50% of payments are overdue. First invoice - paid, second invoice - not paid. Partial payments are not considered.
        Assert.AreEqual(
          50, PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer), 'Incorrect percent of payments not paid');
    end;

    local procedure Initialize()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Terms Reporting");
        // Remove all existing Vendor Ledger Entries to make sure no more entries except generated by test will be considered
        VendorLedgerEntry.DeleteAll;
    end;

    local procedure MockPmtWithApplication(InvLedgEntryNo: Integer; PostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtLedgEntryNo: Integer;
    begin
        PmtLedgEntryNo := MockVendLedEntryNo(false, VendorLedgerEntry."Document Type"::Payment, PostingDate, 0D, 0D, 0D, true);
        MockApplDtldVendLedgEntry(InvLedgEntryNo, InvLedgEntryNo, VendorLedgerEntry."Document Type"::Invoice);
        MockApplDtldVendLedgEntry(PmtLedgEntryNo, InvLedgEntryNo, DetailedVendorLedgEntry."Document Type"::Payment);
    end;

    local procedure MockOverdueFullPaymentAppliedToInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var StartingDate: Date; var EndingDate: Date; var InvRcptDate: Date)
    var
        DueDate: Date;
    begin
        SetStartingEndingDates(StartingDate, EndingDate);
        DueDate := LibraryRandom.RandDateFrom(WorkDate, LibraryRandom.RandIntInRange(3, 5));
        MockVendLedEntry(
          VendorLedgerEntry, false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, StartingDate, DueDate, false);

        InvRcptDate := DueDate + 1;
        MockPmtWithApplication(VendorLedgerEntry."Entry No.", InvRcptDate);
        Commit;
    end;

    local procedure MockVendor(ExcludeFromPmtPracticesReport: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init;
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."Exclude from Pmt. Pract. Rep." := ExcludeFromPmtPracticesReport;
        Vendor.Insert;
        exit(Vendor."No.");
    end;

    local procedure MockVendLedEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; ExcludeFromPmtPracticesReport: Boolean; DocType: Option; PostingDate: Date; DocumentDate: Date; InvoiceReceiptDate: Date; DueDate: Date; IsOpen: Boolean): Integer
    begin
        with VendorLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Posting Date" := PostingDate;
            "Document Date" := DocumentDate;
            "Vendor No." := MockVendor(ExcludeFromPmtPracticesReport);
            "Invoice Receipt Date" := InvoiceReceiptDate;
            "Due Date" := DueDate;
            Open := IsOpen;
            Insert;
            exit("Entry No.");
        end;
    end;

    local procedure MockVendLedEntryNo(ExcludeFromPmtPracticesReport: Boolean; DocType: Option; PostingDate: Date; DocumentDate: Date; InvoiceReceiptDate: Date; DueDate: Date; IsOpen: Boolean): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedEntry(
          VendorLedgerEntry, ExcludeFromPmtPracticesReport, DocType, PostingDate, DocumentDate, InvoiceReceiptDate, DueDate, IsOpen);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockApplDtldVendLedgEntry(VendLedgEntryNo: Integer; AppliedVendLedgEntryNo: Integer; DocType: Option): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            Init;
            "Entry Type" := "Entry Type"::Application;
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Vendor Ledger Entry No." := VendLedgEntryNo;
            "Applied Vend. Ledger Entry No." := AppliedVendLedgEntryNo;
            Insert;
            exit("Entry No.");
        end;
    end;

    local procedure MockThreePmtPeriodSetup()
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
        i: Integer;
    begin
        PaymentPeriodSetup.DeleteAll;
        for i := 1 to 3 do begin
            PaymentPeriodSetup.Init;
            PaymentPeriodSetup.Validate(ID, i);
            PaymentPeriodSetup.Validate("Days From", i);
            PaymentPeriodSetup.Validate("Days To", i);
            PaymentPeriodSetup.Insert(true);
        end;
    end;

    local procedure SetStartingEndingDates(var StartingDate: Date; var EndingDate: Date)
    begin
        StartingDate := CalcDate('<-CM>', WorkDate);
        EndingDate := CalcDate('<CM>', WorkDate);
    end;

    local procedure RunPaymentPracticesReport(StartingDate: Date; EndingDate: Date; ShowInvoices: Boolean)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(ShowInvoices);
        REPORT.Run(REPORT::"Payment Practices", true, false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PmtPracticesRequestPageHandler(var PaymentPractices: TestRequestPage "Payment Practices")
    begin
        PaymentPractices.StartingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPractices.EndingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPractices.ShowInvoices.SetValue(LibraryVariableStorage.DequeueBoolean);
        PaymentPractices.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

