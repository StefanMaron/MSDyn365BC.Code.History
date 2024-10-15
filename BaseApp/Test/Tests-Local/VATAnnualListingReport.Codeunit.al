codeunit 144013 "VAT Annual Listing Report"
{
    // 1 ~ 3. Test basic functions for Annual Listing Report.
    // 4. Verify report Annual Listing shows right VAT Amount for posted Sales Credit Memo.
    // 
    // Cover Test Cases for BE
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // ReportShowsVATEntries
    // SwitchingWrongEntriesAndVATListingsOffReturnsEmptyReport
    // YearOlderThan1900ReturnsError
    // 
    // Cover Test Cases for BE Bug 105315
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // ReportAnnualListingForPostedSalesCreditMemo

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        NonEmptyReportErr: Label 'Expected empty report but found few rows.';
        IncludeCountry: Option All,Specific;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportShowsVATEntries()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        StartDate: Date;
    begin
        // Setup.
        Initialize;
        StartDate := CalcDate('<+CY+1D>', WorkDate);

        // Create customer, an item and post an invoice to that customer for the item
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);

        // Exercise.
        OpenAnnualListingRep(
            false, true, Date2DMY(StartDate, 3), 0, IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // Verify report datasaet against VATEntry table.
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst;
        VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(Abs(VATEntry.Amount), Abs(VATEntry.Base));
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SwitchingWrongEntriesAndVATListingsOffReturnsEmptyReport()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        StartDate: Date;
    begin
        // Setup.
        Initialize;
        StartDate := CalcDate('<+CY+1D>', WorkDate);

        // Create customer, an item and post an invoice to that customer for the item
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);

        // Exercise.
        OpenAnnualListingRep(
            false, false, Date2DMY(StartDate, 3), 0, IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // Verify report datasaet against VATEntry table.
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst;

        LibraryReportDataset.LoadDataSetFile;

        // Asserted against 1 because only header is in the report and no data
        Assert.AreEqual(1, LibraryReportDataset.RowCount, NonEmptyReportErr);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure YearOlderThan1900ReturnsError()
    begin
        // Setup.
        Initialize;

        // Exercise.
        asserterror OpenAnnualListingRep(true, true, 1899, 0, IncludeCountry::All, '', '');
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportAnnualListingForPostedSalesCreditMemo()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        SalesHeader: Record "Sales Header";
    begin
        // Verify report Annual Listing shows right VAT Amount for posted Sales Credit Memo.

        // Setup: Create and post Sales Credit Memo for Domestic Customer.
        Initialize;
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // Exercise: Run Report Annual Listing.
        OpenAnnualListingRep(
            false, true, Date2DMY(WorkDate(), 3), 0, IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // Verify: Verify VAT Base Amount and VAT Amount on report.
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst;
        VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(-VATEntry.Amount, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoices()
    var
        Customer: Record Customer;
        InvoiceAmount: Decimal;
        StartDate: Date;
    begin
        // [SCENARIO 264378] Report VAT Annual Listing does not print invoices which amount less than Minimum Amount
        Initialize;

        // [GIVEN] Create post invoice with amount X
        StartDate := CalcDate('<+CY+1D>', WorkDate);
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [WHEN] Report VAT Annual Listing is being printed with Minimum Amount = 2X
        OpenAnnualListingRep(
            false, true, Date2DMY(StartDate, 3), InvoiceAmount * 2, IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // [THEN] Invoice is not printed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('BufferVATRegistrationNo', FormatLocalEnterpriseNo(Customer."Enterprise No."));
        Assert.AreEqual(0, LibraryReportDataset.RowCount, NonEmptyReportErr);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForCreditMemos()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 264378] Report VAT Annual Listing does print credit memos which amount less than Minimum Amount
        Initialize;

        // [GIVEN] Create post credit memo with amount X
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        CrMemoAmount := FindLastCrMemoAmount(Customer."No.");

        // [WHEN] Report VAT Annual Listing is being printed with Minimum Amount = 2X
        OpenAnnualListingRep(
            false, true, Date2DMY(WorkDate(), 3), CrMemoAmount * 2, IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // [THEN] Credit memo is printed
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst;
        VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(-VATEntry.Amount, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoiceWithCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CrMemoAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 276034] Report Annual Listing does export amount less than Minimum Amount if credit memo exists in the reported period
        Initialize;

        // [GIVEN] Posted sales invoice with amount = 500 and VAT = 10%
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Customer."No.");
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [GIVEN] Posted sales credit memo with amount -100 and VAT = 10%
        CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        CrMemoAmount := FindLastCrMemoAmount(Customer."No.");

        // [WHEN] Report Annual Listing - Disk is being run with Minimum Amount = 600
        OpenAnnualListingRep(
          false, true, Date2DMY(WorkDate(), 3), InvoiceAmount + CrMemoAmount,
          IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // [THEN] Entry for the customer is printed with <TurnOver> = 400 and <VATAmount> = 40
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.CalcSums(Base, Amount);
        VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(-VATEntry.Amount, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoiceOverMin()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 264378] Report VAT Annual Listing prints invoice which amount is greater than Minimum Amount
        Initialize;

        // [GIVEN] Create post invoice with amount 100
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Customer."No.");
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [WHEN] Report VAT Annual Listing is being printed with Minimum Amount = 50
        OpenAnnualListingRep(
            false, true, Date2DMY(WorkDate(), 3), InvoiceAmount / 2,
            IncludeCountry::Specific, Customer."Country/Region Code", Customer."No.");

        // [THEN] Entry for the customer is printed with <TurnOver> = 100 and <VATAmount> = 10
        VATEntry.SetFilter("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst;
        VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(-VATEntry.Amount, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    procedure VATLiableIsPrinted()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [VAT Liable]
        // [SCENARIO 388486] Customer with "VAT Liable" = True is printed by the "VAT Annual Listing" report
        Initialize();

        // [GIVEN] Customer with "VAT Liable" = True
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        Customer.TestField("VAT Liable", true);

        // [WHEN] Print "VAT Annual Listing" report
        OpenAnnualListingRep(
          false, true, Date2DMY(WorkDate(), 3), 0, IncludeCountry::All, Customer."Country/Region Code", Customer."No.");

        // [THEN] The customer is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'BufferVATRegistrationNo', FormatLocalEnterpriseNo(Customer."Enterprise No."));
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRepRequestPageHandler')]
    procedure NonVATLiableIsNotPrinted()
    var
        Customer: array[2] of Record Customer;
    begin
        // [FEATURE] [VAT Liable]
        // [SCENARIO 388486] Customer with "VAT Liable" = False is not printed by the "VAT Annual Listing" report
        Initialize();

        // [GIVEN] Customer "A" with "VAT Liable" = True and customer "B" with "VAT Liable" = False
        LibraryBEHelper.CreateDomesticCustomer(Customer[1]);
        Customer[1].TestField("VAT Liable", true);

        LibraryBEHelper.CreateDomesticCustomer(Customer[2]);
        Customer[2].Validate("VAT Liable", false);
        Customer[2].Modify(true);

        // [WHEN] Print "VAT Annual Listing" report
        OpenAnnualListingRep(
          false, true, Date2DMY(WorkDate(), 3), 0, IncludeCountry::All, Customer[1]."Country/Region Code",
          StrSubstNo('%1|%2', Customer[1]."No.", Customer[2]."No."));

        // [THEN] The customer "A" is printed and customer "B" is not printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'BufferVATRegistrationNo', FormatLocalEnterpriseNo(Customer[1]."Enterprise No."));
        LibraryReportDataset.AssertElementWithValueNotExist(
          'BufferVATRegistrationNo', FormatLocalEnterpriseNo(Customer[2]."Enterprise No."));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Annual Listing Report");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Annual Listing Report");

        isInitialized := true;
        LibraryBEHelper.InitializeCompanyInformation;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Annual Listing Report");
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure FindLastInvoiceAmount(CustomerNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        with SalesInvoiceHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            FindLast;
            CalcFields(Amount);
            exit(Amount);
        end;
    end;

    local procedure FindLastCrMemoAmount(CustomerNo: Code[20]): Decimal
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with SalesCrMemoHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            FindLast;
            CalcFields(Amount);
            exit(Amount);
        end;
    end;

    local procedure FormatLocalEnterpriseNo(EtnerpriseNo: Text): Text
    begin
        exit(StrSubstNo('%1 %2', 'BE', DelChr(EtnerpriseNo, '=', DelChr(EtnerpriseNo, '=', '0123456789'))));
    end;

    local procedure OpenAnnualListingRep(WrongEnterpriseNo: Boolean; IsVATAnnualListing: Boolean; Year: Integer; MinimumAmount: Decimal; IncludeCountry: Option All,Specific; CountryCode: Code[10]; CustomerNoFilter: Text)
    var
        Customer: Record Customer;
        VATAnnualListing: Report "VAT Annual Listing";
    begin
        LibraryVariableStorage.Enqueue(WrongEnterpriseNo);
        LibraryVariableStorage.Enqueue(IsVATAnnualListing);
        LibraryVariableStorage.Enqueue(Year);
        LibraryVariableStorage.Enqueue(MinimumAmount);
        LibraryVariableStorage.Enqueue(IncludeCountry);
        LibraryVariableStorage.Enqueue(CountryCode);

        IF CustomerNoFilter <> '' THEN
            Customer.SetFilter("No.", CustomerNoFilter);
        VATAnnualListing.SetTableView(Customer);
        Commit();
        VATAnnualListing.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATAnnualListingRepRequestPageHandler(var VATAnnualListing: TestRequestPage "VAT Annual Listing")
    var
        DequeuedVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.WrongEntrNo.SetValue(DequeuedVar); // WrongEntrNo

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.VATAnnualList.SetValue(DequeuedVar); // VAT Annual Listing

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.Year.SetValue(DequeuedVar); // Year

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.Minimum.SetValue(DequeuedVar); // Minimum Amount

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.IncludeCountry.SetValue(DequeuedVar); // Include Country
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.Country.SetValue(DequeuedVar); // Country

        VATAnnualListing.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    local procedure VerifyVATBaseAmountAndVATAmountOnAnnualListingReport(VATAmount: Decimal; VATBaseAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('BufferAmount', VATAmount);
        LibraryReportDataset.AssertElementWithValueExists('BufferBase', VATBaseAmount);
    end;
}

