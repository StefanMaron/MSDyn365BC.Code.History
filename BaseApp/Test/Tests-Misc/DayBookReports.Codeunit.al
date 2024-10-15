codeunit 139351 "Day Book Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PSREPORTING]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('DayBookCustLedgerEntryExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryExcel()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        ExpectedValueDiscount: Text;
        ExpectedValueAmount: Text;
    begin
        // [FEATURE] [Report] [Sales] [Day Book]
        // [SCENARIO 254499] "Day Book Cust. Ledger Entry" report shows payment discount amounts on "Discount Given" and "Actual Amount" columns

        Initialize();

        // [GIVEN] Customer ledger entry with "Pmt. Disc. Given (LCY)" = 50 and "Amount (LCY)" = 1000 for customer "C"
        MockCustomerLedgerEntry(CustLedgerEntry);
        MockVATEntry(VATEntry, CustLedgerEntry."Transaction No.");
        MockDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Transaction No.");

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        LibraryVariableStorage.Enqueue(true); // Print details
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());

        // [WHEN] Run "Day Book Cust. Ledger Entry" report for customer "C"
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");

        CustLedgerEntry.CalcFields("Amount (LCY)");
        ExpectedValueDiscount := LibraryReportValidation.FormatDecimalValue(-CustLedgerEntry."Pmt. Disc. Given (LCY)");
        CustLedgerEntry.TestField("Pmt. Disc. Given (LCY)");
        ExpectedValueAmount :=
          LibraryReportValidation.FormatDecimalValue(CustLedgerEntry."Amount (LCY)" + CustLedgerEntry."Pmt. Disc. Given (LCY)");

        LibraryReportValidation.OpenFile();

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by document type
        LibraryReportValidation.VerifyCellValueOnWorksheet(18, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(18, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by date
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by customer
        LibraryReportValidation.VerifyCellValueOnWorksheet(21, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(21, 9, ExpectedValueAmount, '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DayBookVendorLedgerEntryExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryExcel()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ExpectedValueDiscount: Text;
        ExpectedValueAmount: Text;
    begin
        // [FEATURE] [Report] [Purchases] [Day Book]
        // [SCENARIO 254499] "Day Book Venfor Ledger Entry" report shows payment discount amounts on "Discount Rcd." and "Actual Amount" columns

        Initialize();

        // [GIVEN] Vendor ledger entry with "Pmt. Disc. Rcd.(LCY)" = 50 and "Amount (LCY)" = 1000 for vendor "V"
        MockVendorLedgerEntry(VendorLedgerEntry);
        MockVATEntry(VATEntry, VendorLedgerEntry."Transaction No.");
        MockDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Transaction No.");

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
        LibraryVariableStorage.Enqueue(true); // Print details
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());

        // [WHEN] Run "Day Book Vendor Ledger Entry" report for vendor "V"
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");

        VendorLedgerEntry.CalcFields("Amount (LCY)");
        ExpectedValueDiscount := LibraryReportValidation.FormatDecimalValue(-VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
        VendorLedgerEntry.TestField("Pmt. Disc. Rcd.(LCY)");
        ExpectedValueAmount :=
          LibraryReportValidation.FormatDecimalValue(VendorLedgerEntry."Amount (LCY)" + VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");

        LibraryReportValidation.OpenFile();

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by document type
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by date
        LibraryReportValidation.VerifyCellValueOnWorksheet(23, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(23, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by vendor
        LibraryReportValidation.VerifyCellValueOnWorksheet(24, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(24, 9, ExpectedValueAmount, '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        MockGLEntry(GLEntry);

        with CustLedgerEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            Insert();

            "Document Type" := "Document Type"::Invoice;
            "Customer No." := MockCustomer();
            Open := true;
            Positive := true;
            "Pmt. Disc. Given (LCY)" := LibraryRandom.RandDec(10, 2);
            "Due Date" := WorkDate();
            "Posting Date" := WorkDate();
            "Transaction No." := GLEntry."Transaction No.";
            "Closed by Entry No." := "Entry No.";
            Modify();
        end;
    end;

    local procedure MockDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            Insert();

            "Cust. Ledger Entry No." := CustLedgerEntryNo;
            "Entry Type" := "Entry Type"::"Realized Loss";
            "Amount (LCY)" := LibraryRandom.RandDec(10, 2);
            "Transaction No." := TransactionNo;
            Modify();

            exit("Entry No.");
        end;
    end;

    local procedure MockCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        MockGLEntry(GLEntry);

        with VendorLedgerEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, FieldNo("Entry No."));
            Insert();

            "Vendor No." := MockVendor();
            "Posting Date" := WorkDate();
            "Remaining Pmt. Disc. Possible" := LibraryRandom.RandDecInRange(10, 20, 2);
            "Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDecInRange(10, 20, 2);
            "Pmt. Discount Date" := WorkDate();

            "Document Type" := "Document Type"::Invoice;
            "Transaction No." := GLEntry."Transaction No.";
            Open := true;
            "Closed by Entry No." := "Entry No.";
            Modify();
        end;
    end;

    local procedure MockDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            "Entry No." :=
              LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, FieldNo("Entry No."));
            Insert();

            "Vendor Ledger Entry No." := VendorLedgerEntryNo;
            "Entry Type" := "Entry Type"::"Realized Loss";
            Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
            "Amount (LCY)" := Amount;
            "Transaction No." := TransactionNo;
            Modify();

            exit("Entry No.");
        end;
    end;

    local procedure MockVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry")
    begin
        with GLEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(GLEntry, FieldNo("Entry No."));
            "G/L Account No." := LibraryUTUtility.GetNewCode();
            "Document No." := LibraryUTUtility.GetNewCode();
            "Transaction No." := LibraryUtility.GetLastTransactionNo() + 1;
            Insert();
        end;
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; TransactionNo: Integer)
    begin
        with VATEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(VATEntry, FieldNo("Entry No."));
            "Transaction No." := TransactionNo;
            Amount := LibraryRandom.RandDec(10, 2);
            Base := LibraryRandom.RandDec(10, 2);
            Insert();
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryExcelRequestPageHandler(var DayBookCustLedgerEntry: TestRequestPage "Day Book Cust. Ledger Entry")
    var
        CustomerNo: Variant;
        PrintCustLedgerDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintCustLedgerDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintGLEntryDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Customer No.", CustomerNo);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookCustLedgerEntry.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryExcelRequestPageHandler(var DayBookVendorLedgerEntry: TestRequestPage "Day Book Vendor Ledger Entry")
    var
        VendorNo: Variant;
        PrintVendLedgerDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintVendLedgerDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintGLEntryDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Vendor No.", VendorNo);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVendorLedgerEntry.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;
}

