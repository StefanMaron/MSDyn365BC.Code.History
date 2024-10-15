codeunit 134197 "Payment Practices UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Practices]
    end;

    var
        PaymentPracticesLibrary: Codeunit "Payment Practices Library";
        PaymentPractices: Codeunit "Payment Practices";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        CompanySizeCodes: array[3] of Code[20];
        Initialized: Boolean;

    [Test]
    procedure VendorPaymentPractices_SizeEmpty()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Generate payment practices for vendors by size with severals sizes and no entries in those dates. Report dataset will contain lines for each size with 0 entries.
        Initialize();

        // [GIVEN] Three vendors with different company size
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[2], false);
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[3], false);

        // [WHEN] Generate payment practices for vendors by size
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain 3 lines, but 0 entries
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 0, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure VendorExclFromPaymentPractices()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        VendorExcludedNo: Code[20];
    begin
        // [SCENARIO] Generate payment practices for vendor with excl. from payment practices = true and existing entries in those dates. Report dataset will contain entries only for vendor without excl.
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockInvoiceAndPayment_Vendor(VendorNo, WorkDate(), WorkDate(), WorkDate());

        // [GIVEN]Vendor with company size and an entry in the period, but with Excl. from Payment Practice = true
        VendorExcludedNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[2], true);
        MockInvoiceAndPayment_Vendor(VendorExcludedNo, WorkDate(), WorkDate(), WorkDate());

        // [WHEN] Generate payment practices for vendors by size
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain only 1 entry
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure CustomerExclFromPaymentPractices()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        Customer: Record Customer;
        CustomerExcluded: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] Generate payment practices for customers with excl. from payment practices = true and existing entries in those dates. Report dataset will contain entries only for vendor without excl.
        Initialize();

        // [GIVEN] Customer with an entry in the period
        LibrarySales.CreateCustomer(Customer);
        MockCustomerEntry(Customer."No.", CustLedgerEntry, "Gen. Journal Document Type"::Invoice, WorkDate(), WorkDate(), false);

        // [GIVEN] Customer with an entry in the period, but with Excl. from Payment Practice = true
        LibrarySales.CreateCustomer(CustomerExcluded);
        PaymentPracticesLibrary.SetExcludeFromPaymentPractices(CustomerExcluded, true);
        MockCustomerEntry(CustomerExcluded."No.", CustLedgerEntry, "Gen. Journal Document Type"::Invoice, WorkDate(), WorkDate(), false);

        // [WHEN] Generate payment practices for cust+vendors
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(PaymentPracticeHeader, PaymentPracticeHeader."Header Type"::"Vendor+Customer", PaymentPracticeHeader."Aggregation Type"::Period, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain only 1 entry
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Customer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure ConfirmToCleanUpOnAggrValidation_Yes()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When lines already exist on header and you change Aggregation Type you need to confirm that lines will be deleted
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockInvoiceAndPayment_Vendor(VendorNo, WorkDate(), WorkDate(), WorkDate());

        // [GIVEN] Lines were generated for Header
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Change Aggregation Type
        PaymentPracticeHeader.Validate("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::Period);
        // handled by Confirm handler

        // [THEN] Lines were deleted
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_No')]
    procedure ConfirmToCleanUpOnAggrValidation_No()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When lines already exist on header and you change Aggregation Type you need to confirm that lines will be deleted
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockInvoiceAndPayment_Vendor(VendorNo, WorkDate(), WorkDate(), WorkDate());

        // [GIVEN] Lines were generated for Header
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Change Aggregation Type
        PaymentPracticeHeader.Validate("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::Period);
        // handled by Confirm handler

        // [THEN] Lines were not deleted and aggregation type was not changed
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);
        PaymentPracticeHeader.TestField("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::"Company Size");
    end;

    [Test]
    procedure ConfirmToCleanUpOnTypeValidation()
    begin
        // test confirm to delete stuff when generated data and new type validation
    end;

    [Test]
    procedure ReportDataSetForVendorsByPeriod()
    begin
        // test report dataset for vendors by period
    end;

    [Test]
    procedure ReportDataSetForCustomersByPeriod()
    begin
        // test report dataset for customers by period
    end;

    [Test]
    procedure ReportDataSetForCustomersVendorsByPeriod()
    begin
        // test report dataset for customers+vendors by by period
    end;

    [Test]
    procedure AveragesCalculationInHeader()
    begin
        // test averages in header
    end;

    // more tests with complex scenarios for math

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Practices UT");

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Practices UT");

        PaymentPracticesLibrary.InitializeCompanySizes(CompanySizeCodes);
        // This is so demodata doesn't influence the tests
        PaymentPracticesLibrary.SetExcludeFromPaymentPracticesOnAllVendorsAndCustomers();
        Initialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Practices UT");
    end;

    local procedure MockInvoiceAndPayment_Vendor(VendorNo: Code[20]; PostingDate: Date; DueDate: Date; PaymentPostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgEntry(VendorNo, VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        MockPaymentApplication(VendorNo, VendorLedgerEntry."Entry No.", PaymentPostingDate, VendorLedgerEntry."Amount (LCY)", VendorLedgerEntry."Amount (LCY)");
    end;

    local procedure MockVendLedgEntry(VendorNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := DocType;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Date" := PostingDate;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry.Open := IsOpen;
        VendorLedgerEntry.Insert();
    end;

    local procedure MockCustomerEntry(CustomerNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := DocType;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Date" := PostingDate;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := IsOpen;
        CustLedgerEntry.Insert();
    end;

    local procedure MockSimpleVendLedgEntry(VendorNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; IsOpen: Boolean): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgEntry(VendorNo, VendorLedgerEntry, DocType, PostingDate, DueDate, IsOpen);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockPaymentApplication(VendorNo: Code[20]; InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    begin
        MockEntryApplication(VendorNo, InvLedgEntryNo, PostingDate, EntryAmount, AppliedAmount);
    end;

    local procedure MockEntryApplication(VendorNo: Code[20]; InvLedgEntryNo: Integer; PostingDate: Date; EntryAmount: Decimal; AppliedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := MockSimpleVendLedgEntry(VendorNo, "Gen. Journal Document Type"::Payment, PostingDate, 0D, true);
        MockDtldVendLedgEntry("Detailed CV Ledger Entry Type"::"Initial Entry", PostingDate, EntryNo, 0, "Gen. Journal Document Type"::Payment, EntryAmount);
        MockDtldVendLedgEntry("Detailed CV Ledger Entry Type"::Application, PostingDate, EntryNo, InvLedgEntryNo, VendorLedgerEntry."Document Type"::Invoice, -AppliedAmount);
        MockDtldVendLedgEntry("Detailed CV Ledger Entry Type"::Application, PostingDate, InvLedgEntryNo, EntryNo, "Gen. Journal Document Type"::Payment, AppliedAmount);
    end;

    local procedure MockDtldVendLedgEntry(EntryType: Enum "Detailed CV Ledger Entry Type"; PostingDate: Date; LedgEntryNo: Integer; AppliedLedgEntryNo: Integer; DocType: Enum "Gen. Journal Document Type"; AppliedAmount: Decimal): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Document Type" := DocType;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := LedgEntryNo;
        DetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedLedgEntryNo;
        DetailedVendorLedgEntry."Amount (LCY)" := AppliedAmount;
        DetailedVendorLedgEntry."Ledger Entry Amount" := EntryType = "Detailed CV Ledger Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Insert();
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler_Yes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler_No(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}