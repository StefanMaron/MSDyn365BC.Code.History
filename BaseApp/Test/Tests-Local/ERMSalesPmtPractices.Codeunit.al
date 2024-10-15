#if not CLEAN23
codeunit 144565 "ERM Sales Pmt. Practices"
{
    Permissions = TableData "Cust. Ledger Entry" = id,
                  TableData "Detailed Cust. Ledg. Entry" = id,
                  TableData "Vendor Ledger Entry" = id,
                  TableData "Detailed Vendor Ledg. Entry" = id;
    Subtype = Test;

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete. The tests will be moved to W1 App "Payment Practice"';
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Payment Practices]
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
    procedure BuildPmtApplicationBufferReturnsNothingIfCustomerrExcludedFromPmtPracticesReport()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] No sales invoices includes into Payment Application Buffer by function BuildCustPmtApplicationBuffer of codeunit "Payment Reporting Mgt." for Customer with "Exclude from Payment Reporting" option

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockSimpleCustLedgEntry(true, CustLedgerEntry."Document Type"::Invoice, StartingDate, 0D, false);

        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildPmtApplicationBufferIncludesOnlyInvoicesWithinSpecifiedPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257582] Only sales invoices within specified period includes into Payment Application Buffer by function BuildCustPmtApplicationBuffer of codeunit "Payment Reporting Mgt."

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // 4 invoices are within StartingDate and Ending Date
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate + 1, StartingDate + 1, true);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, EndingDate - 1, EndingDate - 1, true);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, EndingDate, EndingDate, true);

        // 3 documents are outside period or with different document type
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate - 1, StartingDate - 1, true);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, EndingDate + 1, EndingDate + 1, true);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::"Credit Memo", StartingDate, StartingDate, true);

        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DaysSinceDueDateOfPmtApplicationBuffer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        DaysSinceDueDate := LibraryRandom.RandInt(100);
        MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate, WorkDate - DaysSinceDueDate, true);

        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.TestField("Days Since Due Date", DaysSinceDueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateWithinPeriodIncludesIfPaymentsWithinPeriodEnabled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate, 0, 0);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, true);

        Assert.RecordCount(TempPaymentApplicationBuffer, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateOutsidePeriodDoesNotIncludeIfPaymentsWithinPeriodEnabled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate + 1, 0, 0);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, true);

        Assert.RecordCount(TempPaymentApplicationBuffer, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithPostingDateOutsidePeriodIncludesIfPaymentsWithinPeriodDisabled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        InvLedgEntryNo := MockSimpleCustLedgEntry(false, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        MockPaymentApplication(InvLedgEntryNo, EndingDate + 1, 0, 0);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        Assert.RecordCount(TempPaymentApplicationBuffer, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDaysDelayedInPmtApplicationBufer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        DueDate := StartingDate + 1;
        PaymentDate := EndingDate - 1;
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, DueDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PaymentDate, CustLedgerEntry."Amount (LCY)", CustLedgerEntry."Amount (LCY)");
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Pmt. Days Delayed", PaymentDate - DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtAmountInPmtApplicationBufer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        PaymentAmount := CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(5, 10);
        AppliedAmount := CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(10, 15);
        MockPaymentApplication(CustLedgerEntry."Entry No.", StartingDate, PaymentAmount, AppliedAmount);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Pmt. Amount (LCY)", AppliedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryAmountCorrectedInPmtApplicationBufer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        CrMemoAmount := -CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(5, 10);
        MockCrMemoApplication(CustLedgerEntry."Entry No.", StartingDate, CrMemoAmount, CrMemoAmount);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.", 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Entry Amount Corrected (LCY)", CustLedgerEntry."Amount (LCY)" + CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountInPmtApplicationBufer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        CrMemoAmount := -CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5);
        PmtAmount := -CustLedgerEntry."Amount (LCY)" / LibraryRandom.RandIntInRange(3, 5);
        MockCrMemoApplication(CustLedgerEntry."Entry No.", StartingDate, CrMemoAmount, CrMemoAmount);
        MockPaymentApplication(CustLedgerEntry."Entry No.", StartingDate, PmtAmount, PmtAmount);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate, false);

        TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.", 0);
        TempPaymentApplicationBuffer.FindFirst();
        TempPaymentApplicationBuffer.TestField("Remaining Amount (LCY)", CustLedgerEntry."Amount (LCY)" + CrMemoAmount + PmtAmount);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepDoesNotShowDetailsIfShowInvoicesIsDisabled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Payment Practices Reporting does not show details is "Show Invoices option is disabled on Request Page

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Partial payment with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(CustLedgerEntry, StartingDate, EndingDate);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 without option "Show Invoices" and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] XML nodes 'NotPaidCustNo' and 'DelayedCustNo' related to invoice details does not exist
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist('NotPaidCustNo', CustLedgerEntry."Customer No.");
        LibraryReportDataset.AssertElementWithValueNotExist('DelayedCustNo', CustLedgerEntry."Customer No.");
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepShowsDetailsIfShowInvoicesIsEnabled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Payment Practices Reporting shows details is "Show Invoices option is enabled on Request Page

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Invoice with "Due Date"  = January 4
        // [GIVEN] Partial payment with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(CustLedgerEntry, StartingDate, EndingDate);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 with option "Show Invoices" and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, true);

        // [THEN] XML nodes 'NotPaidCustNo' and 'DelayedCustNo' related to invoice details exists
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(4);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidCustNo', CustLedgerEntry."Customer No.");
        LibraryReportDataset.MoveToRow(6);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedCustNo', CustLedgerEntry."Customer No.");
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtPracticesRepPrintsTotalCountOfInvoices()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 271362] Payment Practices Reporting prints total count of invoices not paid and delayed

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // [GIVEN] Work Date is January 3
        // [GIVEN] Two invoices with "Due Date"  = January 4
        // [GIVEN] Three partial payments with "Posting Date" = January 5
        MockOverduePartialPaymentAppliedToInvoice(CustLedgerEntry, StartingDate, EndingDate);
        MockOverduePartialPaymentAppliedToInvoice(CustLedgerEntry, StartingDate, EndingDate);
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", CustLedgerEntry."Due Date" + 1,
          -CustLedgerEntry."Amount (LCY)" / 3, -CustLedgerEntry."Amount (LCY)" / 3);

        // [WHEN] Run "Payment Practices Reporting" report from January 1 to January 31 and save as XML
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] XML node 'NotPaidCustTotalInvoices' has value 2 and 'DelayedCustTotalInvoices' has value 3
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(5);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidCustTotalInvoices', 2);
        LibraryReportDataset.MoveToRow(7);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedCustTotalInvoices', 3);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountOfInvoicesIsShownWhenNonZeroOnNotPaidInvoicesPage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 278906] Only nonzero total amount of invoices is shown on page with customer invoices, that are not paid.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Customer Ledger Entry with "Amount (LCY)" = "A" and Open = TRUE.
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");

        // [GIVEN] Run "Payment Practices Reporting" report.
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] "Total amount of invoices (Corrected)" is shown for unpaid customer invoices page only.
        LibraryReportValidation.OpenExcelFile;
        VerifyTotalAmtExistsOnWorksheet(3, CustLedgerEntry."Amount (LCY)");
        VerifyTotalAmtNotExistOnWorksheet(1);
        VerifyTotalAmtNotExistOnWorksheet(2);
        VerifyTotalAmtNotExistOnWorksheet(4);
    end;

    [Test]
    [HandlerFunctions('PmtPracticesReportingExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountOfInvoicesIsShownWhenNonZeroOnDelayedInvoicesPage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 278906] Only nonzero total amount of invoices is shown on page with customer invoices, that were delayed in payment.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] Closed Customer Ledger Entry with "Amount (LCY)" = "A".
        // [GIVEN] Payment with "Posting Date" > "Due Date" of invoice.
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, WorkDate - 1, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", WorkDate, -CustLedgerEntry."Amount (LCY)", -CustLedgerEntry."Amount (LCY)");

        // [GIVEN] Run "Payment Practices Reporting" report.
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        RunPaymentPracticesReporting(StartingDate, EndingDate, false);

        // [THEN] "Total amount of invoices (Corrected)" is shown for delayed in payment customer invoices page only.
        LibraryReportValidation.OpenExcelFile;
        VerifyTotalAmtExistsOnWorksheet(4, CustLedgerEntry."Amount (LCY)");
        VerifyTotalAmtNotExistOnWorksheet(1);
        VerifyTotalAmtNotExistOnWorksheet(2);
        VerifyTotalAmtNotExistOnWorksheet(3);
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
        // [SCENARIO 279080] Closed Customer Ledger Entries are considered in calculation of "Total amount of invoices" for unpaid invoices.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
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
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustAmount', TotalInvoiceAmount);
        LibraryReportDataset.MoveToRow(4);
        LibraryReportDataset.AssertCurrentRowValueEquals('NotPaidCustAmount', UnpaidAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'NotPaidCustPct', Round(UnpaidAmount / TotalInvoiceAmount * 100));
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
        // [SCENARIO 279080] Closed Customer Ledger Entries are considered in calculation of "Total amount of invoices" for delayed in payment invoices.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SetStartingEndingDates(StartingDate, EndingDate);

        // [GIVEN] One closed Invoice with Amount = "A1" and with applied Payment with Amount = "A1", posted after "Due Date".
        // [GIVEN] One closed Invoice with Amount = "A2", two Payments applied to it: Amount = "A2 - 10 and posted before "Due Date"; Amount = 10 and posted after "Due Date".
        // [GIVEN] One closed Invoice with Amount = "A3" and with applied Payment with Amount = "A3", posted before "Due Date".
        CreateInvoicesOverdueAndPartlyOverdue(StartingDate, DelayedAmount, TotalInvoiceAmount);

        // [GIVEN] Run "Payment Practices Reporting" report.
        RunPaymentPracticesReporting(StartingDate, EndingDate, true);

        // [THEN] "Total amount of invoices (Corrected)" = "A1" + "A2" + "A3"; "Total Amount" = "A1" + 10.
        // [THEN] "Total %" = "Total Amount" / "Total amount of invoices (Corrected)" * 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustAmount', TotalInvoiceAmount);
        LibraryReportDataset.MoveToRow(5);
        LibraryReportDataset.AssertCurrentRowValueEquals('DelayedCustAmount', -DelayedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DelayedCustPct', Round(DelayedAmount / TotalInvoiceAmount * 100));
    end;

    local procedure Initialize()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Sales Pmt. Practices");
        // Remove all existing Vendor/Customer Ledger Entries and Detailed Ledger Entries to make sure no more entries except generated by test will be considered
        VendorLedgerEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
    end;

    local procedure SetStartingEndingDates(var StartingDate: Date; var EndingDate: Date)
    begin
        StartingDate := CalcDate('<-CM>', WorkDate);
        EndingDate := CalcDate('<CM>', WorkDate);
    end;

    local procedure CreateInvoicesOpenedAndPartlyPaid(PostingDate: Date; var UnpaidAmount: Decimal; var TotalInvoiceAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceUnpaidAmt: Decimal;
    begin
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
        UnpaidAmount += CustLedgerEntry."Amount (LCY)";

        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceUnpaidAmt := LibraryRandom.RandDecInRange(10, 20, 2);
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate,
          -CustLedgerEntry."Amount (LCY)" + InvoiceUnpaidAmt, -CustLedgerEntry."Amount (LCY)" + InvoiceUnpaidAmt);
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
        UnpaidAmount += InvoiceUnpaidAmt;

        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate, -CustLedgerEntry."Amount (LCY)", -CustLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
    end;

    local procedure CreateInvoicesOverdueAndPartlyOverdue(PostingDate: Date; var DelayedAmount: Decimal; var TotalInvoiceAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentDelayedAmt: Decimal;
    begin
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate + 1, -CustLedgerEntry."Amount (LCY)", -CustLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
        DelayedAmount += CustLedgerEntry."Amount (LCY)";

        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        PaymentDelayedAmt := LibraryRandom.RandDecInRange(10, 20, 2);
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate,
          -CustLedgerEntry."Amount (LCY)" + PaymentDelayedAmt, -CustLedgerEntry."Amount (LCY)" + PaymentDelayedAmt);
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate + 1, -PaymentDelayedAmt, -PaymentDelayedAmt);
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
        DelayedAmount += PaymentDelayedAmt;

        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostingDate, PostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", PostingDate, -CustLedgerEntry."Amount (LCY)", -CustLedgerEntry."Amount (LCY)");
        TotalInvoiceAmount += CustLedgerEntry."Amount (LCY)";
    end;

    local procedure MockOverduePartialPaymentAppliedToInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; var StartingDate: Date; var EndingDate: Date)
    begin
        SetStartingEndingDates(StartingDate, EndingDate);
        MockCustLedgEntryWithAmt(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, StartingDate, StartingDate - 1, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(
          CustLedgerEntry."Entry No.", CustLedgerEntry."Due Date" + 1,
          -CustLedgerEntry."Amount (LCY)" / 3, -CustLedgerEntry."Amount (LCY)" / 3);
    end;

    local procedure MockSimpleCustLedgEntry(ExcludeFromPmtReporting: Boolean; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgEntry(CustLedgerEntry, ExcludeFromPmtReporting, DocType, PostingDate, DueDate, IsOpen);
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockCustLedgEntryWithAmt(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockCustLedgEntry(CustLedgerEntry, false, DocType, PostingDate, DueDate, IsOpen);
        MockDtldCustLedgEntry(
          DetailedCustLedgEntry."Entry Type"::"Initial Entry", PostingDate, CustLedgerEntry."Entry No.", 0,
          CustLedgerEntry."Document Type", LibraryRandom.RandDec(100, 2));
    end;

    local procedure MockCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; ExcludeFromPmtReporting: Boolean; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    begin
        with CustLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Posting Date" := PostingDate;
            "Customer No." := MockCustomer(ExcludeFromPmtReporting);
            "Due Date" := DueDate;
            Open := IsOpen;
            Insert;
        end;
    end;

    local procedure MockCustomer(ExcludeFromPmtReporting: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer."Exclude from Payment Reporting" := ExcludeFromPmtReporting;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure MockPaymentApplication(InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockEntryApplication(CustLedgerEntry."Document Type"::Payment, InvLedgEntryNo, PostingDate, EntryAmount, AppliedAmount);
    end;

    local procedure MockCrMemoApplication(InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockEntryApplication(CustLedgerEntry."Document Type"::"Credit Memo", InvLedgEntryNo, PostingDate, EntryAmount, AppliedAmount);
    end;

    local procedure MockEntryApplication(DocType: Enum "Gen. Journal Document Type"; InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
    begin
        EntryNo := MockSimpleCustLedgEntry(false, DocType, PostingDate, 0D, true);
        MockDtldCustLedgEntry(
          DetailedCustLedgEntry."Entry Type"::"Initial Entry", PostingDate, EntryNo, 0, CustLedgerEntry."Document Type", EntryAmount);
        MockDtldCustLedgEntry(
          DetailedCustLedgEntry."Entry Type"::Application, PostingDate, EntryNo, InvLedgEntryNo,
          CustLedgerEntry."Document Type"::Invoice, -AppliedAmount);
        MockDtldCustLedgEntry(
          DetailedCustLedgEntry."Entry Type"::Application, PostingDate, InvLedgEntryNo, EntryNo,
          DocType, AppliedAmount);
    end;

    local procedure MockDtldCustLedgEntry(EntryType: Option; PostingDate: Date; LedgEntryNo: Integer; AppliedLedgEntryNo: Integer; DocType: Enum "Gen. Journal Document Type"; AppliedAmount: Decimal): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            Init;
            "Entry Type" := EntryType;
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Document Type" := DocType;
            "Posting Date" := PostingDate;
            "Cust. Ledger Entry No." := LedgEntryNo;
            "Applied Cust. Ledger Entry No." := AppliedLedgEntryNo;
            "Amount (LCY)" := AppliedAmount;
            "Ledger Entry Amount" := EntryType = "Entry Type"::"Initial Entry";
            Insert;
            exit("Entry No.");
        end;
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
