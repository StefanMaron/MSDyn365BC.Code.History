#if not CLEAN23
codeunit 144564 "ERM Puch. Pmt. Practices"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    Subtype = Test;

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete. The tests will be moved to W1 App "Payment Practice"';
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Payment Practices]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";

    [Test]
    [Scope('OnPrem')]
    procedure BuildPmtApplicationBufferReturnsNothingIfVendorExcludedFromPmtPracticesReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] No purchase invoices includes into Payment Application Buffer by function BuildVendPmtApplicationBuffer of codeunit "Payment Reporting Mgt." for Vendor with "Exclude from Payment Reporting" option
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockSimpleVendLedgEntry(true, VendorLedgerEntry."Document Type"::Invoice, StartingDate, 0D, false);

        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildPmtApplicationBufferIncludesOnlyInvoicesWithinSpecifiedPeriod()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Only purchase invoices within specified period includes into Payment Application Buffer by function BuildVendPmtApplicationBuffer of codeunit "Payment Reporting Mgt."

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // 4 invoices are within StartingDate and Ending Date
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate + 1, StartingDate + 1, true);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate - 1, EndingDate - 1, true);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate, EndingDate, true);

        // 3 documents are outside period or with different document type
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate - 1, StartingDate - 1, true);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, EndingDate + 1, EndingDate + 1, true);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::"Credit Memo", StartingDate, StartingDate, true);

        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DaysSinceDueDateOfPmtApplicationBuffer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        DaysSinceDueDate: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] "Days Since Due Date" of Payment Application Buffer calculates as WORKDATE - "Due Date"

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        DaysSinceDueDate := LibraryRandom.RandInt(100);
        MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, WorkDate - DaysSinceDueDate, true);

        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.TestField("Days Since Due Date", DaysSinceDueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateWithinPeriodIncludesIfPaymentsWithinPeriodEnabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        InvLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Payment includes into calculation when "Posting Date" within period of report and "Payments Within Period" option is enabled

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate, 0, 0);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, true);

        Assert.RecordCount(TempPaymentApplicationBuffer, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateOutsidePeriodDoesNotIncludeIfPaymentsWithinPeriodEnabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        InvLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Payment does not include into calculation when "Posting Date" outside period of report and "Payments Within Period" option is enabled

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate + 1, 0, 0);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, true);

        Assert.RecordCount(TempPaymentApplicationBuffer, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateOutsidePeriodIncludesIfPaymentsWithinPeriodDisabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        InvLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Payment includes into calculation when "Posting Date" outside period of report but "Payments Within Period" option is disabled

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleVendLedgEntry(false, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate + 1, 0, 0);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDaysDelayedInPmtApplicationBufer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        DueDate: Date;
        PaymentDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] "Pmt. Days Delayed" is difference between the "Due Date" of invoice and "Posting Date" of payment

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        DueDate := StartingDate + 1;
        PaymentDate := EndingDate - 1;
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, DueDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PaymentDate, VendorLedgerEntry."Amount (LCY)", VendorLedgerEntry."Amount (LCY)");
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Pmt. Days Delayed", PaymentDate - DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtAmountInPmtApplicationBufer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        PaymentAmount: Decimal;
        AppliedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 278044] "Pmt. Amount (LCY)" is application amount of Payment

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        PaymentAmount := VendorLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(5, 10);
        AppliedAmount := VendorLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(10, 15);
        MockPaymentApplication(VendorLedgerEntry."Entry No.", StartingDate, PaymentAmount, AppliedAmount);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Pmt. Amount (LCY)", AppliedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryAmountCorrectedInPmtApplicationBufer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] "Entry Amount Corrected (LCY)" is invoice amount excluding applied credit memo amount

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        CrMemoAmount := -VendorLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(5, 10);
        MockCrMemoApplication(VendorLedgerEntry."Entry No.", StartingDate, CrMemoAmount, CrMemoAmount);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.", 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Entry Amount Corrected (LCY)", VendorLedgerEntry."Amount (LCY)" + CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountInPmtApplicationBufer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        CrMemoAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] "Remaining Amount (LCY)" is "Entry Amount Corrected (LCY)" amount excluding payment amount

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        CrMemoAmount := -VendorLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5);
        PmtAmount := -VendorLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5);
        MockCrMemoApplication(VendorLedgerEntry."Entry No.", StartingDate, CrMemoAmount, CrMemoAmount);
        MockPaymentApplication(VendorLedgerEntry."Entry No.", StartingDate, PmtAmount, PmtAmount);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.", 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Remaining Amount (LCY)", VendorLedgerEntry."Amount (LCY)" + CrMemoAmount + PmtAmount);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepDoesNotShowDetailsIfShowInvoicesIsDisabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Payment Practices Reporting does not show details is "Show Invoices option is disabled on Request Page

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Partial payment with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 without option "Show Invoices" and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] XML nodes 'NotPaidVendNo' and 'DelayedVendNo' related to invoice details does not exist
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist('NotPaidVendNo', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.AssertElementWithValueNotExist('DelayedVendNo', VendorLedgerEntry."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepShowsDetailsIfShowInvoicesIsEnabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Payment Practices Reporting shows details is "Show Invoices option is enabled on Request Page

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Partial payment with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 with option "Show Invoices" and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, true);

        // [THEN] XML nodes 'NotPaidVendNo' and 'DelayedVendNo' related to invoice details exists
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidVendNo', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.MoveToRow(4);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedVendNo', VendorLedgerEntry."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepPrintsTotalCountOfInvoices()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 271362] Payment Practices Reporting prints total count of invoices not paid and delayed

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Two invoices with "Due Date"  = January 4
        // [GIVEN] Three partial payments with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate);
        MockOverduePartialPaymentAppliedToInvoice(VendorLedgerEntry, StartingDate, EndingDate);
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", VendorLedgerEntry."Due Date" + 1,
          -VendorLedgerEntry."Amount (LCY)" / 3, -VendorLedgerEntry."Amount (LCY)" / 3);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] XML node 'NotPaidVendTotalInvoices' has value 2 and 'DelayedVendTotalInvoices' has value 3
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidVendTotalInvoices', 2);
        LibraryReportDataset.MoveToRow(5);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedVendTotalInvoices', 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PrepareNotPaidInDaysSourcePositiveWhenDaysToIsZero()
    var
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279015] Test function PrepareNotPaidInDaysSource from "Payment Reporting Mgt." codeunit in case of "Days Since Due Date" >= "Days From" and "Days To" = 0.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Temporary record Payment Application Buffer with "Days Since Due Date" = 92.
        MockTempPaymentApplicationBuffer(TempPaymentApplicationBuffer, 0, 92, 0, 0, 0);

        // [WHEN] Run PrepareNotPaidInDaysSource on this Payment Application Buffer with "Days From" = 91 and "Days To" = 0.
        // [THEN] The function returns TRUE.
        Assert.IsTrue(
          PaymentReportingMgt.PrepareNotPaidInDaysSource(TempPaymentApplicationBuffer, 91, 0), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PrepareNotPaidInDaysSourceNegativeWhenDaysToIsZero()
    var
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279015] Test function PrepareNotPaidInDaysSource from "Payment Reporting Mgt." codeunit in case of "Days Since Due Date" < "Days From" and "Days To" = 0.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Temporary record Payment Application Buffer with "Days Since Due Date" = 90.
        MockTempPaymentApplicationBuffer(TempPaymentApplicationBuffer, 0, 90, 0, 0, 0);

        // [WHEN] Run PrepareNotPaidInDaysSource on this Payment Application Buffer with "Days From" = 91 and "Days To" = 0.
        // [THEN] The function returns FALSE.
        Assert.IsFalse(
          PaymentReportingMgt.PrepareNotPaidInDaysSource(TempPaymentApplicationBuffer, 91, 0), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PrepareDelayedPmtInDaysSourcePositiveWhenDaysToIsZero()
    var
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279015] Test function PrepareDelayedPmtInDaysSource from "Payment Reporting Mgt." codeunit in case of "Pmt. Days Delayed" >= "Days From" and "Days To" = 0.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Temporary record Payment Application Buffer with "Pmt. Days Delayed" = 92.
        MockTempPaymentApplicationBuffer(
          TempPaymentApplicationBuffer, LibraryRandom.RandIntInRange(10, 20), 0, 92, 0, 0);

        // [WHEN] Run PrepareDelayedPmtInDaysSource on this Payment Application Buffer with "Days From" = 91 and "Days To" = 0.
        // [THEN] The function returns TRUE.
        Assert.IsTrue(
          PaymentReportingMgt.PrepareDelayedPmtInDaysSource(TempPaymentApplicationBuffer, 91, 0), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PrepareDelayedPmtInDaysSourceNegativeWhenDaysToIsZero()
    var
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279015] Test function PrepareDelayedPmtInDaysSource from "Payment Reporting Mgt." codeunit in case of "Pmt. Days Delayed" < "Days From" and "Days To" = 0.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Temporary record Payment Application Buffer with "Pmt. Days Delayed" = 90.
        MockTempPaymentApplicationBuffer(
          TempPaymentApplicationBuffer, LibraryRandom.RandIntInRange(10, 20), 0, 90, 0, 0);

        // [WHEN] Run PrepareDelayedPmtInDaysSource on this Payment Application Buffer with "Days From" = 91 and "Days To" = 0.
        // [THEN] The function returns FALSE.
        Assert.IsFalse(
          PaymentReportingMgt.PrepareDelayedPmtInDaysSource(TempPaymentApplicationBuffer, 91, 0), '');
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountOfInvoicesIsShownWhenNonZeroOnNotPaidInvoicesPage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 278906] Only nonzero total amount of invoices is shown on page with vendor invoices, that are not paid.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Vendor Ledger Entry with "Amount (LCY)" = "A" and Open = TRUE.
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");

        // [GIVEN] Run "Payment Practices Reporting" report.
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] "Total amount of invoices (Corrected)" is shown for unpaid vendor invoices page only.
        LibraryReportValidation.OpenExcelFile;
        VerifyTotalAmtExistsOnWorksheet(1, VendorLedgerEntry."Amount (LCY)");
        VerifyTotalAmtNotExistOnWorksheet(2);
        VerifyTotalAmtNotExistOnWorksheet(3);
        VerifyTotalAmtNotExistOnWorksheet(4);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountOfInvoicesIsShownWhenNonZeroOnDelayedInvoicesPage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 278906] Only nonzero total amount of invoices is shown on page with vendor invoices, that were delayed in payment.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Closed Vendor Ledger Entry with "Amount (LCY)" = "A".
        // [GIVEN] Payment with "Posting Date" > "Due Date" of invoice.
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, WorkDate - 1, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", WorkDate, -VendorLedgerEntry."Amount (LCY)", -VendorLedgerEntry."Amount (LCY)");

        // [GIVEN] Run "Payment Practices Reporting" report.
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] "Total amount of invoices (Corrected)" is shown for delayed in payment vendor invoices page only.
        LibraryReportValidation.OpenExcelFile;
        VerifyTotalAmtExistsOnWorksheet(2, VendorLedgerEntry."Amount (LCY)");
        VerifyTotalAmtNotExistOnWorksheet(1);
        VerifyTotalAmtNotExistOnWorksheet(3);
        VerifyTotalAmtNotExistOnWorksheet(4);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ClosedInvoicesAreConsideredInTotalAmountOfInvoicesForNotPaidInvoices()
    var
        StartingDate: Date;
        EndingDate: Date;
        TotalInvoiceAmount: Decimal;
        UnpaidAmount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 279080] Closed Vendor Ledger Entries are considered in calculation of "Total amount of invoices" for unpaid invoices.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] One opened Invoice with Amount = "A1".
        // [GIVEN] One opened Invoice with Amount = "A2" and with applied Payment with Amount = "A2" - 10.
        // [GIVEN] One closed Invoice with Amount = "A3" and with applied Payment with Amount = "A3".
        CreateInvoicesOpenedAndPartlyPaid(StartingDate, UnpaidAmount, TotalInvoiceAmount);

        // [GIVEN] Run "Payment Practices Reporting" report.
        RunPaymentPracticesReporting(StartingDate, EndingDate, true);

        // [THEN] "Total amount of invoices (Corrected)" = "A1" + "A2" + "A3"; "Total Amount" = "A1" + 10.
        // [THEN] "Total %" = "Total Amount" / "Total amount of invoices (Corrected)" * 100
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVendAmount', TotalInvoiceAmount);
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidVendAmount', UnpaidAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'NotPaidVendPct', Round(UnpaidAmount / TotalInvoiceAmount * 100));
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ClosedInvoicesAreConsideredInTotalAmountOfInvoicesForDelayedInvoices()
    var
        StartingDate: Date;
        EndingDate: Date;
        TotalInvoiceAmount: Decimal;
        DelayedAmount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 279080] Closed Vendor Ledger Entries are considered in calculation of "Total amount of invoices" for delayed in payment invoices.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] One closed Invoice with Amount = "A1" and with applied Payment with Amount = "A1", posted after "Due Date".
        // [GIVEN] One closed Invoice with Amount = "A2", two Payments applied to it: Amount = "A2 - 10 and posted before "Due Date"; Amount = 10 and posted after "Due Date".
        // [GIVEN] One closed Invoice with Amount = "A3" and with applied Payment with Amount = "A3", posted before "Due Date".
        CreateInvoicesOverdueAndPartlyOverdue(StartingDate, DelayedAmount, TotalInvoiceAmount);

        // [GIVEN] Run "Payment Practices Reporting" report.
        RunPaymentPracticesReporting(StartingDate, EndingDate, true);

        // [THEN] "Total amount of invoices (Corrected)" = "A1" + "A2" + "A3"; "Total Amount" = "A1" + 10.
        // [THEN] "Total %" = "Total Amount" / "Total amount of invoices (Corrected)" * 100
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVendAmount', TotalInvoiceAmount);
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedVendAmount', -DelayedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DelayedVendPct', Round(DelayedAmount / TotalInvoiceAmount * 100));
    end;

    local procedure Initialize()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Puch. Pmt. Practices");
        // Remove all existing Vendor/Customer Ledger Entries and Detailed Ledger Entries to make sure no more entries except generated by test will be considered
        VendorLedgerEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();
    end;

    local procedure SetStartingEndingDates(var StartingDate: Date; var EndingDate: Date)
    begin
        StartingDate := CalcDate('<-CM>', WorkDate);
        EndingDate := CalcDate('<CM>', WorkDate);
    end;

    local procedure CreateInvoicesOpenedAndPartlyPaid(PostingDate: Date; var UnpaidAmount: Decimal; var TotalInvoiceAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceUnpaidAmt: Decimal;
    begin
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
        UnpaidAmount += VendorLedgerEntry."Amount (LCY)";

        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceUnpaidAmt := LibraryRandom.RandDecInRange(10, 20, 2);
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate,
          -VendorLedgerEntry."Amount (LCY)" + InvoiceUnpaidAmt, -VendorLedgerEntry."Amount (LCY)" + InvoiceUnpaidAmt);
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
        UnpaidAmount += InvoiceUnpaidAmt;

        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate, -VendorLedgerEntry."Amount (LCY)", -VendorLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
    end;

    local procedure CreateInvoicesOverdueAndPartlyOverdue(PostingDate: Date; var DelayedAmount: Decimal; var TotalInvoiceAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentDelayedAmt: Decimal;
    begin
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate + 1, -VendorLedgerEntry."Amount (LCY)", -VendorLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
        DelayedAmount += VendorLedgerEntry."Amount (LCY)";

        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        PaymentDelayedAmt := LibraryRandom.RandDecInRange(10, 20, 2);
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate,
          -VendorLedgerEntry."Amount (LCY)" + PaymentDelayedAmt, -VendorLedgerEntry."Amount (LCY)" + PaymentDelayedAmt);
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate + 1, -PaymentDelayedAmt, -PaymentDelayedAmt);
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
        DelayedAmount += PaymentDelayedAmt;

        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", PostingDate, -VendorLedgerEntry."Amount (LCY)", -VendorLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += VendorLedgerEntry."Amount (LCY)";
    end;

    local procedure MockOverduePartialPaymentAppliedToInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var StartingDate: Date; var EndingDate: Date)
    begin
        SetStartingEndingDates(StartingDate, EndingDate);
        MockVendLedgEntryWithAmt(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate - 1, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          VendorLedgerEntry."Entry No.", VendorLedgerEntry."Due Date" + 1,
          -VendorLedgerEntry."Amount (LCY)" / 3, -VendorLedgerEntry."Amount (LCY)" / 3);
    end;

    local procedure MockSimpleVendLedgEntry(ExcludeFromPmtReporting: Boolean; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgEntry(VendorLedgerEntry, ExcludeFromPmtReporting, DocType, PostingDate, DueDate, IsOpen);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockVendLedgEntryWithAmt(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        MockVendLedgEntry(VendorLedgerEntry, false, DocType, PostingDate, DueDate, IsOpen);
        MockDtldVendLedgEntry(
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", PostingDate, VendorLedgerEntry."Entry No.", 0,
          VendorLedgerEntry."Document Type", LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    local procedure MockVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; ExcludeFromPmtReporting: Boolean; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    begin
        with VendorLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Posting Date" := PostingDate;
            "Vendor No." := MockVendor(ExcludeFromPmtReporting);
            "Due Date" := DueDate;
            Open := IsOpen;
            Insert;
        end;
    end;

    local procedure MockVendor(ExcludeFromPmtReporting: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."Exclude from Payment Reporting" := ExcludeFromPmtReporting;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure MockPaymentApplication(InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockEntryApplication(VendorLedgerEntry."Document Type"::Payment, InvLedgEntryNo, PostingDate, EntryAmount, AppliedAmount);
    end;

    local procedure MockCrMemoApplication(InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockEntryApplication(VendorLedgerEntry."Document Type"::"Credit Memo", InvLedgEntryNo, PostingDate, EntryAmount, AppliedAmount);
    end;

    local procedure MockEntryApplication(DocType: Enum "Gen. Journal Document Type"; InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
    begin
        EntryNo := MockSimpleVendLedgEntry(false, DocType, PostingDate, 0D, true);
        MockDtldVendLedgEntry(
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", PostingDate, EntryNo, 0, DocType, EntryAmount);
        MockDtldVendLedgEntry(
          DetailedVendorLedgEntry."Entry Type"::Application, PostingDate, EntryNo, InvLedgEntryNo,
          VendorLedgerEntry."Document Type"::Invoice, -AppliedAmount);
        MockDtldVendLedgEntry(
          DetailedVendorLedgEntry."Entry Type"::Application, PostingDate, InvLedgEntryNo, EntryNo,
          DocType, AppliedAmount);
    end;

    local procedure MockDtldVendLedgEntry(EntryType: Option; PostingDate: Date; LedgEntryNo: Integer; AppliedLedgEntryNo: Integer; DocType: Enum "Gen. Journal Document Type"; AppliedAmount: Decimal): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            Init;
            "Entry Type" := EntryType;
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Posting Date" := PostingDate;
            "Vendor Ledger Entry No." := LedgEntryNo;
            "Applied Vend. Ledger Entry No." := AppliedLedgEntryNo;
            "Amount (LCY)" := AppliedAmount;
            "Ledger Entry Amount" := EntryType = "Entry Type"::"Initial Entry";
            Insert;
            exit("Entry No.");
        end;
    end;

    local procedure MockTempPaymentApplicationBuffer(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; PmtEntryNo: Integer; DaysSinceDueDate: Integer; PmtDaysDelayed: Integer; PmtAmount: Decimal; RemainingAmount: Decimal)
    begin
        TempPaymentApplicationBuffer.Init();
        TempPaymentApplicationBuffer."Invoice Entry No." := LibraryRandom.RandIntInRange(1000, 9999);
        TempPaymentApplicationBuffer."Pmt. Entry No." := PmtEntryNo;
        TempPaymentApplicationBuffer."Posting Date" := WorkDate;
        TempPaymentApplicationBuffer."Document Type" := TempPaymentApplicationBuffer."Document Type"::Invoice;
        TempPaymentApplicationBuffer."Invoice Is Open" := true;
        TempPaymentApplicationBuffer."Days Since Due Date" := DaysSinceDueDate;
        TempPaymentApplicationBuffer."Pmt. Days Delayed" := PmtDaysDelayed;
        TempPaymentApplicationBuffer."Pmt. Amount (LCY)" := PmtAmount;
        TempPaymentApplicationBuffer."Remaining Amount (LCY)" := RemainingAmount;
        TempPaymentApplicationBuffer.Insert();
    end;

    local procedure RunPaymentPracticesReporting(StartingDate: Date; EndingDate: Date; ShowInvoices: Boolean)
    begin
        Commit();
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(ShowInvoices);
        REPORT.Run(REPORT::"Payment Practices Reporting", true, false);
    end;

    local procedure VerifyTotalAmtExistsOnWorksheet(WorksheetNo: Integer; ExpectedAmount: Decimal)
    var
        TotalAmountRowNo: Integer;
        ColumnNo: Integer;
    begin
        LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(
          'Total amount of invoices (Corrected)', WorksheetNo, TotalAmountRowNo, ColumnNo);
        Assert.AreEqual(
          Format(ExpectedAmount), LibraryReportValidation.GetValueFromNextColumn(TotalAmountRowNo, ColumnNo), '');
    end;

    local procedure VerifyTotalAmtNotExistOnWorksheet(WorksheetNo: Integer)
    begin
        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo, 'Total amount of invoices (Corrected)'), '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PmtPracticesReportingRequestPageHandler(var PaymentPracticesReporting: TestRequestPage "Payment Practices Reporting")
    begin
        PaymentPracticesReporting.StartingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPracticesReporting.EndingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPracticesReporting.ShowInvoices.SetValue(LibraryVariableStorage.DequeueBoolean);
        PaymentPracticesReporting.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PmtPracticesReportingExcelRequestPageHandler(var PaymentPracticesReporting: TestRequestPage "Payment Practices Reporting")
    begin
        PaymentPracticesReporting.StartingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPracticesReporting.EndingDate.SetValue(LibraryVariableStorage.DequeueDate);
        PaymentPracticesReporting.ShowInvoices.SetValue(LibraryVariableStorage.DequeueBoolean);

        PaymentPracticesReporting.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;
}
#endif
