codeunit 144012 "ERM Payment Tolerance FR"
{
    // // [FEATURE] [Payment Tolerance]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ConfirmMessageForPaymentQst: Label 'Do you want to change all open entries for every customer and vendor that are not blocked';

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyCustomerEntriesPageHandler,PaymentToleranceWarningPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtToleranceWarningPaymentLineCustomer()
    var
        Customer: Record Customer;
        PaymentLine: Record "Payment Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 121976] Posted Sales Invoice with Amount "A" and Possible Payment Tolerance "PT"
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Posted Sales Invoice with Amount "A" and Possible Payment Tolerance "PT"
        UpdateGeneralLedgerSetup();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Created Payment Slip with Payment line where "Credit Amount" = "A"
        CreatePaymentSlipWithAmount(PaymentLine, PaymentLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        // [GIVEN] Same "Applies-to-ID" is set on Payment Line and Sales Invoice
        SetAppliesToIDPaymentLine(PaymentLine, Customer."No.", GenJournalLine."Document No.");

        // [WHEN] Set "Credit Amount" = "A" - "PT" on Payment Line
        PaymentLine.Validate("Credit Amount", CalcPaymentAmountWithToleranceCustomer(InvoiceAmount, Customer."No."));

        // [THEN] Warning dialog appeared and accepted
        // [THEN] "Credit Amount"  = "A" - "PT" on Payment Line
        Assert.AreEqual(
          CalcPaymentAmountWithToleranceCustomer(InvoiceAmount, Customer."No."),
          PaymentLine."Credit Amount",
          PaymentLine.FieldCaption("Credit Amount"));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyVendorEntriesPageHandler,PaymentToleranceWarningPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtToleranceWarningPaymentLineVendor()
    var
        Vendor: Record Vendor;
        PaymentLine: Record "Payment Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 121976] Posted Purchase Invoice with Amount "A" and Possible Payment Tolerance "PT"
        Initialize();
        InvoiceAmount := -LibraryRandom.RandDec(100, 2);

        // [GIVEN] Posted Purchase Invoice with Amount "A" and Possible Payment Tolerance "PT"
        UpdateGeneralLedgerSetup();
        CreateVendorWithPaymentTerm(Vendor);
        UpdateVendorPostingGroup(Vendor."Vendor Posting Group");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Created Payment Slip with Payment line where "Credit Amount" = "A"
        CreatePaymentSlipWithAmount(PaymentLine, PaymentLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        // [GIVEN] Same "Applies-to-ID" is set on Payment Line and Purchase Invoice
        SetAppliesToIDPaymentLine(PaymentLine, Vendor."No.", GenJournalLine."Document No.");

        // [WHEN] Set "Credit Amount" = "A" - "PT" on Payment Line
        PaymentLine.Validate("Credit Amount", CalcPaymentAmountWithToleranceVendor(InvoiceAmount, Vendor."No."));

        // [THEN] Warning dialog appeared and accepted
        // [THEN] "Credit Amount"  = "A" - "PT" on Payment Line
        Assert.AreEqual(
          CalcPaymentAmountWithToleranceVendor(InvoiceAmount, Vendor."No."),
          PaymentLine."Credit Amount",
          PaymentLine.FieldCaption("Credit Amount"));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyCustomerEntriesPageHandler,PaymentToleranceWarningPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtTolWarningOnPmntLineAfterAppliesToIdCustomer()
    var
        Customer: Record Customer;
        PaymentLine: Record "Payment Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Payment Slip] [Application] [Sales]
        // [SCENARIO 363455] Accept Payment Tolerance Warning dialog on applying customer entries
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Posted Sales Invoice with Amount "A" and Possible Payment Tolerance "PT"
        UpdateGeneralLedgerSetup();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Created Payment Slip with Payment line where "Credit Amount" = "A"
        CreatePaymentSlipWithAmount(PaymentLine, PaymentLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        // [GIVEN] Set "Credit Amount" = "A" - "PT" on Payment Line
        PaymentLine.Validate("Credit Amount", CalcPaymentAmountWithToleranceCustomer(InvoiceAmount, Customer."No."));
        // [WHEN] Same "Applies-to-ID" is set on Payment Line and Sales Invoice
        SetAppliesToIDPaymentLine(PaymentLine, Customer."No.", GenJournalLine."Document No.");

        // [THEN] Warning dialog appeared and accepted
        // [THEN] "Credit Amount"  = "A" - "PT" on Payment Line
        Assert.AreEqual(
          CalcPaymentAmountWithToleranceCustomer(InvoiceAmount, Customer."No."),
          PaymentLine."Credit Amount",
          PaymentLine.FieldCaption("Credit Amount"));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyVendorEntriesPageHandler,PaymentToleranceWarningPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtTolWarningOnPmntLineAfterAppliesToIdVendor()
    var
        Vendor: Record Vendor;
        PaymentLine: Record "Payment Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Payment Slip] [Application] [Purchases]
        // [SCENARIO 363455] Accept Payment Tolerance Warning dialog on applying vendor entries in Payment Slip
        Initialize();
        InvoiceAmount := -LibraryRandom.RandDec(100, 2);

        // [GIVEN] Posted Purchase Invoice with Amount "A" and Possible Payment Tolerance "PT"
        UpdateGeneralLedgerSetup();
        CreateVendorWithPaymentTerm(Vendor);
        UpdateVendorPostingGroup(Vendor."Vendor Posting Group");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Created Payment Slip with Payment line where "Credit Amount" = "A"
        CreatePaymentSlipWithAmount(PaymentLine, PaymentLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        // [GIVEN] Set "Credit Amount" = "A" - "PT" on Payment Line
        PaymentLine.Validate("Credit Amount", CalcPaymentAmountWithToleranceVendor(InvoiceAmount, Vendor."No."));
        // [WHEN] Same "Applies-to-ID" is set on Payment Line and Purchase Invoice
        SetAppliesToIDPaymentLine(PaymentLine, Vendor."No.", GenJournalLine."Document No.");

        // [THEN] Warning dialog appeared and accepted
        // [THEN] "Credit Amount"  = "A" - "PT" on Payment Line
        Assert.AreEqual(
          CalcPaymentAmountWithToleranceVendor(InvoiceAmount, Vendor."No."),
          PaymentLine."Credit Amount",
          PaymentLine.FieldCaption("Credit Amount"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningPageHandler,VendorBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorDetaiTriallBalanceOnPmtTolerance()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntryInv: Record "Vendor Ledger Entry";
        VendorLedgerEntryPmt: Record "Vendor Ledger Entry";
        ApplicationDate: Date;
        PostedInvoiceNo: Code[20];
        PostedPmtNo: Code[20];
        InvoiceAmount: Decimal;
        AmountToApply: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [FEATURE] [Application] [Purchases]
        // [SCENARIO 379007] Print Vendor Detail Trial Balance Report in case of Payment Tolerance
        Initialize();

        // [GIVEN] Setup Max Payment Tolerance Amount
        InvoiceAmount := LibraryRandom.RandDecInRange(10, 500, 2);
        MaxPaymentToleranceAmt := GetMaxPaymentTolerance(InvoiceAmount);

        // [GIVEN] Posted Purchase Invoice
        LibraryPurchase.CreateVendor(Vendor);
        ApplicationDate := LibraryRandom.RandDate(10);
        PostedInvoiceNo := PostPurchaseInvoiceWithTolerance(Vendor."No.", InvoiceAmount, ApplicationDate);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInv, VendorLedgerEntryInv."Document Type"::Invoice, PostedInvoiceNo);

        // [GIVEN] Posted Payment
        AmountToApply := Round(InvoiceAmount - MaxPaymentToleranceAmt / 2);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        PostedPmtNo := CreateAndPostPayment(GenJournalLine, Vendor."No.", ApplicationDate, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryPmt, VendorLedgerEntryPmt."Document Type"::Payment, PostedPmtNo);

        // [GIVEN] Apply Vendor Payment to Vendor Invoice using Payment Tolerance
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryInv);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryPmt);
        VendorLedgerEntryPmt.Validate("Accepted Payment Tolerance", MaxPaymentToleranceAmt);
        VendorLedgerEntryPmt.Modify(true);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryPmt);

        // [WHEN] Vendor Detail Trial Balance Report Run on Next Period
        RunVendorDetailedBalance(Vendor."No.", ApplicationDate);

        // [THEN] Report shows the zero balance - Nothing to Output
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'Balance is Not Zero');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningPageHandler,CustomerBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetaiTriallBalanceOnPmtTolerance()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryInv: Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        ApplicationDate: Date;
        PostedInvoiceNo: Code[20];
        PostedPmtNo: Code[20];
        InvoiceAmount: Decimal;
        AmountToApply: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [FEATURE] [Application] [Sales]
        // [SCENARIO 379007] Print Customer Detail Trial Balance Report in case of Payment Tolerance
        Initialize();

        // [GIVEN] Setup Max Payment Tolerance Amount
        InvoiceAmount := LibraryRandom.RandDecInRange(10, 500, 2);
        MaxPaymentToleranceAmt := GetMaxPaymentTolerance(InvoiceAmount);

        // [GIVEN] Posted Sales Invoice
        LibrarySales.CreateCustomer(Customer);
        ApplicationDate := LibraryRandom.RandDate(10);
        PostedInvoiceNo := PostSalesInvoiceWithTolerance(Customer."No.", InvoiceAmount, ApplicationDate);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryInv, CustLedgerEntryInv."Document Type"::Invoice, PostedInvoiceNo);

        // [GIVEN] Posted Payment
        AmountToApply := Round(InvoiceAmount - MaxPaymentToleranceAmt / 2);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        PostedPmtNo := CreateAndPostPayment(GenJournalLine, Customer."No.", ApplicationDate, -AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryPmt, CustLedgerEntryPmt."Document Type"::Payment, PostedPmtNo);

        // [GIVEN] Apply Customer Payment to Sales Invoice using Payment Tolerance
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInv);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPmt);
        CustLedgerEntryPmt.Validate("Accepted Payment Tolerance", MaxPaymentToleranceAmt);
        CustLedgerEntryPmt.Modify(true);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryPmt);

        // [WHEN] Customer Detail Trial Balance Report Run on Next Period
        RunCustomerDetailedBalance(Customer."No.", ApplicationDate);

        // [THEN] Report shows the zero balance - Nothing to Output
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'Balance is Not Zero');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance FR");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance FR");

        IsInitialized := true;
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance FR");
    end;

    local procedure CreateAndPostPayment(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20]; ApplicationDate: Date; Amount: Decimal): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type", DocNo,
          Amount);
        GenJournalLine.Validate("Posting Date", ApplicationDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateCustomerWithPaymentTerm(var Customer: Record Customer) DiscountDays: Integer
    begin
        LibrarySales.CreateCustomer(Customer);
        DiscountDays := LibraryRandom.RandInt(5);  // Using Random Value for Days.
        Customer.Validate("Payment Terms Code", CreatePaymentTerms(DiscountDays));
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTerm(var Vendor: Record Vendor) DiscountDays: Integer
    begin
        LibraryPurchase.CreateVendor(Vendor);
        DiscountDays := LibraryRandom.RandInt(5);  // Using Random Value for Days.
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms(DiscountDays));
        Vendor.Modify(true);
    end;

    local procedure CreatePaymentTerms(DiscountDateCalculationDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        with PaymentTerms do begin
            LibraryERM.CreatePaymentTerms(PaymentTerms);
            Evaluate("Due Date Calculation", '<' + Format(LibraryRandom.RandInt(2)) + 'M>');
            Evaluate("Discount Date Calculation", '<' + Format(DiscountDateCalculationDays) + 'D>');
            Validate("Due Date Calculation", "Due Date Calculation");
            Validate("Discount Date Calculation", "Discount Date Calculation");
            Validate("Discount %", LibraryRandom.RandDec(5, 2));
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreatePaymentSlip(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Integer
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", AccountType);
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify(true);
        exit(PaymentLine."Dimension Set ID");
    end;

    local procedure CreatePaymentSlipWithAmount(var PaymentLine: Record "Payment Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentAmount: Decimal)
    begin
        CreatePaymentSlip(AccountType, AccountNo);
        FindPaymentLine(PaymentLine, AccountType, AccountNo);
        PaymentLine.Validate("Credit Amount", PaymentAmount);
        PaymentLine.Validate("Posting Date", PaymentLine."Due Date" - 5);
        PaymentLine.Modify(true);
    end;

    local procedure EnqueueValuesForRequestPageHandler(No: Variant; DateFilter: Variant)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(DateFilter);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        with CustLedgerEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Customer No.", CustomerNo);
            FindFirst();
            CalcFields("Remaining Amount", Amount);
        end;
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        with VendorLedgerEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Vendor No.", VendorNo);
            FindFirst();
            CalcFields("Remaining Amount", Amount);
        end;
    end;

    local procedure FindPaymentLine(var PaymentLine: Record "Payment Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        PaymentLine.SetRange("Account Type", AccountType);
        PaymentLine.SetRange("Account No.", AccountNo);
        PaymentLine.FindFirst();
    end;

    local procedure GetMaxPaymentTolerance(InvoiceAmount: Decimal) MaxPaymentToleranceAmount: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdateGeneralLedgerSetup();
        RunChangePaymentTolerance('', LibraryRandom.RandDecInRange(2, 10, 2), LibraryRandom.RandDecInRange(2, 10, 2));
        GeneralLedgerSetup.Get();
        MaxPaymentToleranceAmount := Round(InvoiceAmount * GeneralLedgerSetup."Payment Tolerance %" / 100);
        GeneralLedgerSetup."Max. Payment Tolerance Amount" := MaxPaymentToleranceAmount;
        GeneralLedgerSetup.Modify();
        exit(MaxPaymentToleranceAmount);
    end;

    local procedure PostPurchaseInvoiceWithTolerance(VendorNo: Code[20]; var InvoiceAmount: Decimal; ApplicationDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandIntInRange(2, 10));
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", ApplicationDate);
        PurchaseLine.Validate("Direct Unit Cost", InvoiceAmount);
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields("Amount Including VAT");
        InvoiceAmount := PurchaseHeader."Amount Including VAT";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure PostSalesInvoiceWithTolerance(CustomerNo: Code[20]; var InvoiceAmount: Decimal; ApplicationDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandIntInRange(2, 10));
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", ApplicationDate);
        SalesLine.Validate("Unit Price", InvoiceAmount);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Amount Including VAT");
        InvoiceAmount := SalesHeader."Amount Including VAT";
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunChangePaymentTolerance(CurrencyCode: Code[10]; PaymentTolerance: Decimal; MaxPmtToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(false, CurrencyCode, PaymentTolerance, MaxPmtToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure RunVendorDetailedBalance(VendorNo: Code[20]; ApplicationDate: Date)
    var
        DateFilter: Code[30];
    begin
        DateFilter := StrSubstNo('%1..%2', CalcDate('<CY+1Y>', ApplicationDate), CalcDate('<CY+2Y-1D>', ApplicationDate));
        EnqueueValuesForRequestPageHandler(VendorNo, DateFilter);
        REPORT.Run(REPORT::"Vendor Detail Trial Balance FR");
    end;

    local procedure RunCustomerDetailedBalance(CustomerNo: Code[20]; ApplicationDate: Date)
    var
        DateFilter: Code[30];
    begin
        DateFilter := StrSubstNo('%1..%2', CalcDate('<CY+1Y>', ApplicationDate), CalcDate('<CY+2Y-1D>', ApplicationDate));
        EnqueueValuesForRequestPageHandler(CustomerNo, DateFilter);
        REPORT.Run(REPORT::"Customer Detail Trial Balance");
    end;

    local procedure CalcPaymentAmountWithToleranceCustomer(InvoiceAmount: Decimal; AccountNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        MaxPaymentTolerance: Decimal;
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, AccountNo, CustLedgerEntry."Document Type"::Invoice);
        MaxPaymentTolerance := CustLedgerEntry."Max. Payment Tolerance" / 2;  // Use for Verify partial Payment Tolerance Amount.
        exit(InvoiceAmount - MaxPaymentTolerance)
    end;

    local procedure CalcPaymentAmountWithToleranceVendor(InvoiceAmount: Decimal; AccountNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        MaxPaymentTolerance: Decimal;
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, AccountNo, VendorLedgerEntry."Document Type"::Invoice);
        MaxPaymentTolerance := VendorLedgerEntry."Max. Payment Tolerance" / 2;  // Use for Verify partial Payment Tolerance Amount.
        exit(InvoiceAmount - MaxPaymentTolerance)
    end;

    local procedure CreateGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure SetAppliesToIDPaymentLine(var PaymentLine: Record "Payment Line"; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(AccountNo);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CODEUNIT.Run(CODEUNIT::"Payment-Apply", PaymentLine);
        PaymentLine.Modify(true);
    end;

    local procedure UpdateCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        with CustomerPostingGroup do begin
            Get(PostingGroupCode);
            Validate("Payment Disc. Debit Acc.", CreateGLAccountNo());
            Validate("Payment Disc. Credit Acc.", CreateGLAccountNo());
            Validate("Payment Tolerance Debit Acc.", CreateGLAccountNo());
            Validate("Payment Tolerance Credit Acc.", CreateGLAccountNo());
            Modify(true);
        end;
    end;

    local procedure UpdateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with VendorPostingGroup do begin
            Get(PostingGroupCode);
            Validate("Payment Disc. Debit Acc.", CreateGLAccountNo());
            Validate("Payment Disc. Credit Acc.", CreateGLAccountNo());
            Validate("Payment Tolerance Debit Acc.", CreateGLAccountNo());
            Validate("Payment Tolerance Credit Acc.", CreateGLAccountNo());
            Modify(true);
        end;
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);

        // Using Random Number for Payment Tolerance Percentage and Maximum Payment Tolerance Amount.
        RunChangePaymentTolerance('', LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ConfirmMessageForPaymentQst);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningPageHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(1);
        Response := ACTION::Yes
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassListPageHandler(var PaymentClassList: TestPage "Payment Class List")
    begin
        PaymentClassList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryVariableStorage.Dequeue(DocumentNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();

        ApplyCustomerEntries.GotoRecord(CustLedgerEntry);
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorrEntries: TestPage "Apply Vendor Entries")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryVariableStorage.Dequeue(DocumentNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();

        ApplyVendorrEntries.GotoRecord(VendorLedgerEntry);
        ApplyVendorrEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorrEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBalanceRequestPageHandler(var CustomerDetailTrialBalance: TestRequestPage "Customer Detail Trial Balance")
    begin
        CustomerDetailTrialBalance.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerDetailTrialBalance.Customer.SetFilter("Date Filter", LibraryVariableStorage.DequeueText());
        CustomerDetailTrialBalance.ExcludeBalanceOnly.SetValue(false);
        CustomerDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBalanceRequestPageHandler(var VendorDetailTrialBalance: TestRequestPage "Vendor Detail Trial Balance FR")
    begin
        VendorDetailTrialBalance.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorDetailTrialBalance.Vendor.SetFilter("Date Filter", LibraryVariableStorage.DequeueText());
        VendorDetailTrialBalance.ExcludeBalanceOnly.SetValue(false);
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

