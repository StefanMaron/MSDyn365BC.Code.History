codeunit 144005 "ERM Annual Listing"
{
    // 
    //  1. Test that foreign customers are exported with 'Annual Listing - Disk' if option 'Export all countries' selected.
    //  2. Test that foreign customers are exported with 'Annual Listing - Disk' if option 'Export specific country' and Customer's Country/Region is selected.
    //  3. Test that foreign customers are not exported with 'Annual Listing - Disk' if option 'Export specific country' and Country/Region BE is selected.
    //  4. Test that foreign customer with only posted Credit Memo is exported with 'Annual Listing - Disk'.
    // 
    // BUG_ID = 58039
    // Cover Test cases:
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                       TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // ExportAnnualListingWithForeignCustomer                                                                   58039
    // ExportAnnualListingWithForeignCustomer2                                                                  58039
    // NoExportAnnualListingWithForeignCustomer                                                                 58039
    // 
    // BUG_ID = 105315
    // Cover Test cases:
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                       TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // ExportAnnualListingDiskForPostedSalesCreditMemo                                                          105315

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Annual Listing] [Export] [Enterprise No]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        FileMgt: Codeunit "File Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        isInitialized: Boolean;
        VatRegNoFormatNotFoundErr: Label 'VAT Registration Format not found.';
        FileExistenceErr: Label 'File existence error.';
        CompanyVATNumberCapTxt: Label '//CompanyVATNumber';
        TurnOverCapTxt: Label '//TurnOver';
        VATAmountCapTxt: Label '//VATAmount';
        IncludeCountry: Option All,Specific;
        TurnOverSumCapTxt: Label 'TurnOverSum';
        VATAmountSumCapTxt: Label 'VATAmountSum';
        ClientListingTxt: Label '//ClientListing';

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingWithForeignCustomer()
    begin
        // Test that foreign customers are exported with 'Annual Listing - Disk' if option 'Export all countries' selected.
        ExportAnnualListingAndVerify(IncludeCountry::All, true, '');
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingWithForeignCustomer2()
    begin
        // Test that foreign customers are exported with 'Annual Listing - Disk' if option 'Export specific country' selected and Customer's country selected.
        ExportAnnualListingAndVerify(IncludeCountry::Specific, true, '');
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoExportAnnualListingWithForeignCustomer()
    begin
        // Test that foreign customers are not exported with 'Annual Listing - Disk' if option 'Export specific country' and Country BE is selected.
        ExportAnnualListingAndVerify(IncludeCountry::Specific, false, '');
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingWithrepresentative()
    var
        Representative: Record Representative;
    begin
        // Test verifies that the Representative gets Exported
        LibraryBEHelper.CreateRepresentative(Representative);
        ExportAnnualListingAndVerify(IncludeCountry::All, true, Representative.ID);
    end;

    local procedure ExportAnnualListingAndVerify(InclCountry: Option All,Specific; FileMustExist: Boolean; RepresentativeId: Code[20])
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        FilePath: Text;
        StartDate: Date;
        CountryCode: Code[10];
    begin
        // Setup.
        Initialize;
        StartDate := CalcDate('<+CY+1D>', WorkDate);
        CountryCode :=
          InitInfoAndPostLinesInPeriod(
            SalesHeader."Document Type"::Invoice,
            CalcDate('<+' + Format(LibraryRandom.RandInt(CalcDate('<+CY+1D>', WorkDate) - StartDate)) + 'D>', StartDate));

        // Exercise.
        if (InclCountry = IncludeCountry::Specific) and (not FileMustExist) then begin
            CompanyInformation.Get();
            CountryRegion.Get(CompanyInformation."Country/Region Code");
            ExportAnnualListingDisk(Date2DMY(StartDate, 3), RepresentativeId, InclCountry, CountryRegion.Code, 0.01, FilePath, '');
        end else
            ExportAnnualListingDisk(Date2DMY(StartDate, 3), RepresentativeId, InclCountry, CountryCode, 0.01, FilePath, '');

        // Verify.
        Assert.AreEqual(FileMustExist, Exists(FilePath), FileExistenceErr);

        if RepresentativeId <> '' then
            GetPositionOfNameSpace(FilePath, StrSubstNo('>%1</common:RepresentativeID>', RepresentativeId));
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingDiskForPostedSalesCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        FileName: Text;
    begin
        // Test that foreign Customer with only posted Credit Memo is exported with 'Annual Listing - Disk'.

        // Setup: Create and post Sales Credit Memo.
        Initialize;
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::"Credit Memo", CalcDate('<+CY+2Y>', WorkDate));

        // Exercise: Run report Annual Listing - Disk.
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+2Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", 0.01, FileName, Customer."No.");

        // Verify: Verify the Enterprise No. VAT Amount Base and VAT Amount in report.
        VerifyAnnualListingDiskReportData(FileName, Customer."No.", DelStr(Customer."Enterprise No.", 1, 3));
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoice()
    var
        Customer: Record Customer;
        InvoiceAmount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 264378] Report Annual Listing - Disk does not export invoice which amount less than Minimum Amount
        Initialize;

        // [GIVEN] Create post invoice with amount X
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [WHEN] Report Annual Listing - Disk is being run with Minimum Amount = 2X
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+2Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", InvoiceAmount * 2, FileName, Customer."No.");

        // [THEN] File is not created
        Assert.IsFalse(Exists(FileName), FileExistenceErr);
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        FileName: Text;
        IncludeCountry: Option All,Specific;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 264378] Report Annual Listing - Disk does export credit memos which amount less than Minimum Amount
        Initialize;

        // [GIVEN] Create post credit memo with amount X
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::"Credit Memo", CalcDate('<+CY+2Y>', WorkDate));
        CrMemoAmount := FindLastCrMemoAmount(Customer."No.");

        // [WHEN] Report Annual Listing - Disk is being run with Minimum Amount = 2X
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+2Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", CrMemoAmount * 2, FileName, Customer."No.");

        // [THEN] Verify the Enterprise No. VAT Amount Base and VAT Amount in report.
        VerifyAnnualListingDiskReportData(FileName, Customer."No.", DelStr(Customer."Enterprise No.", 1, 3));
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoiceWithCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        FileName: Text;
        IncludeCountry: Option All,Specific;
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 276034] Report Annual Listing - Disk does export amount less than Minimum Amount if credit memo exists in the reported period
        Initialize;

        // [GIVEN] Posted sales invoice with amount = 500 and VAT = 10%
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::Invoice, CalcDate('<+CY+2Y>', WorkDate));
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [GIVEN] Posted sales credit memo with amount -100 and VAT = 10%
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::"Credit Memo", CalcDate('<+CY+2Y>', WorkDate));
        CrMemoAmount := FindLastCrMemoAmount(Customer."No.");

        // [WHEN] Report Annual Listing - Disk is being run with Minimum Amount = 600
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+2Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", InvoiceAmount + CrMemoAmount, FileName, Customer."No.");

        // [THEN] Entry for the customer exported with <TurnOver> = 400 and <VATAmount> = 40
        VerifyAnnualListingDiskReportData(FileName, Customer."No.", DelStr(Customer."Enterprise No.", 1, 3));
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinimumAmountForInvoiceOverMin()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        InvoiceAmount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 264378] Report Annual Listing - Disk exports invoice which amount is greater than Minimum Amount
        Initialize;

        // [GIVEN] Create post invoice with amount 100
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::Invoice, CalcDate('<+CY+2Y>', WorkDate));
        InvoiceAmount := FindLastInvoiceAmount(Customer."No.");

        // [WHEN] Report Annual Listing - Disk is being run with Minimum Amount = 50
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+2Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", InvoiceAmount / 2, FileName, Customer."No.");

        // [THEN] Entry for the customer exported with <TurnOver> = 100 and <VATAmount> = 10
        VerifyAnnualListingDiskReportData(FileName, Customer."No.", DelStr(Customer."Enterprise No.", 1, 3));
    end;

    [Test]
    [HandlerFunctions('VATAnnualListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingForLocalCustomerEnterpriseNoWithoutPrefix()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        IncludeCountry: Option All,Specific;
    begin
        // [SCENARIO 346489] Report Annual Listing does export credit memos for local Customer with "Enterprise No." wihtout prefixes
        Initialize();

        // [GIVEN] Create a Customer with "Enterprise No." wihtout prefixes
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        Customer.Validate("Enterprise No.", LibraryBEHelper.CreateMOD97CompliantCode());
        Customer.Modify(true);

        // [GIVEN] Create and post Credit Memo for Customer
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::"Credit Memo", CalcDate('<+CY+2Y>', WorkDate));

        // [WHEN] Report Annual Listing is being run
        ExportAnnualListing(
          false, Date2DMY(CalcDate('<+CY+2Y>', WorkDate), 3), 0.01, IncludeCountry::Specific, Customer."Country/Region Code");

        // [THEN] Verify VAT Amount Base and VAT Amount in report
        VerifyAnnualListingReportData(Customer."No.", Customer."Country/Region Code" + ' ' + Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAnnualListingDiskForLocalCustomerEnterpriseNoWithoutPrefix()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        FileName: Text;
        IncludeCountry: Option All,Specific;
    begin
        // [SCENARIO 346489] Report Annual Listing - Disk does export credit memos for local Customer with "Enterprise No." wihtout prefixes
        Initialize;

        // [GIVEN] Create a Customer with "Enterprise No." wihtout prefixes
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        Customer.Validate("Enterprise No.", LibraryBEHelper.CreateMOD97CompliantCode());
        Customer.Modify(true);

        // [GIVEN] Create and post Credit Memo for Customer
        CreateAndPostSalesDocumentInPeriod(Customer."No.", SalesHeader."Document Type"::"Credit Memo", CalcDate('<+CY+3Y>', WorkDate));

        // [WHEN] Report Annual Listing - Disk is being run
        ExportAnnualListingDisk(
            Date2DMY(CalcDate('<+CY+3Y>', WorkDate()), 3), '',
            IncludeCountry::Specific, Customer."Country/Region Code", FindLastCrMemoAmount(Customer."No."), FileName, Customer."No.");

        // [THEN] Verify the Enterprise No., VAT Amount Base and VAT Amount in report.
        VerifyAnnualListingDiskReportData(FileName, Customer."No.", Customer."Enterprise No.");
    end;

    [Test]
    procedure VATLiableDefaultValue()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [VAT Liable]
        // [SCENARIO 388486] Default customer "VAT Liable" value is True
        Customer.Init();
        Customer.TestField("VAT Liable", true);
    end;

    [Test]
    procedure VATLiableFieldOnCustomerPage()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [VAT Liable] [UI]
        // [SCENARIO 388486] "VAT Liable" value is shown on a customer card page
        CustomerCard.OpenView();
        Assert.IsTrue(CustomerCard."VAT Liable".Enabled(), '"VAT Liable".Enabled()');
        Assert.IsTrue(CustomerCard."VAT Liable".Visible(), '"VAT Liable".Visible()');
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    procedure VATLiableIsPrinted()
    var
        Customer: Record Customer;
        FileName: Text;
    begin
        // [FEATURE] [VAT Liable]
        // [SCENARIO 388486] Customer with "VAT Liable" = True is printed by the "Annual Listing - Disk" report
        Initialize();

        // [GIVEN] Customer with "VAT Liable" = True
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        Customer.TestField("VAT Liable", true);

        // [WHEN] Print "Annual Listing - Disk" report
        ExportAnnualListingDisk(
          Date2DMY(WorkDate(), 3), '', IncludeCountry::All, Customer."Country/Region Code", 0, FileName, Customer."No.");

        // [THEN] The customer is printed
        LibraryXPathXMLReader.Initialize(FileName, 'http://www.minfin.fgov.be/ClientListingConsignment');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Client', 1);
        LibraryXPathXMLReader.VerifyNodeValue(CompanyVATNumberCapTxt, DELSTR(Customer."Enterprise No.", 1, 3));
    end;

    [Test]
    [HandlerFunctions('VatAnnualListingDiskRequestPageHandler')]
    procedure NonVATLiableIsNotPrinted()
    var
        Customer: array[2] of Record Customer;
        FileName: Text;
    begin
        // [FEATURE] [VAT Liable]
        // [SCENARIO 388486] Customer with "VAT Liable" = False is not printed by the "Annual Listing - Disk" report
        Initialize();

        // [GIVEN] Customer "A" with "VAT Liable" = True and customer "B" with "VAT Liable" = False
        LibraryBEHelper.CreateDomesticCustomer(Customer[1]);
        Customer[1].TestField("VAT Liable", true);

        LibraryBEHelper.CreateDomesticCustomer(Customer[2]);
        Customer[2].Validate("VAT Liable", false);
        Customer[2].Modify(true);

        // [WHEN] Print "Annual Listing - Disk" report
        ExportAnnualListingDisk(
          Date2DMY(WorkDate(), 3), '', IncludeCountry::All, Customer[1]."Country/Region Code", 0, FileName,
          StrSubstNo('%1|%2', Customer[1]."No.", Customer[2]."No."));

        // [THEN] The customer "A" is printed and customer "B" is not printed
        LibraryXPathXMLReader.Initialize(FileName, 'http://www.minfin.fgov.be/ClientListingConsignment');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Client', 1);
        LibraryXPathXMLReader.VerifyNodeValue(CompanyVATNumberCapTxt, DelStr(Customer[1]."Enterprise No.", 1, 3));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Annual Listing");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Annual Listing");

        isInitialized := true;
        LibraryBEHelper.InitializeCompanyInformation;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Annual Listing");
    end;

    local procedure InitInfoAndPostLinesInPeriod(DocumentType: Enum "Sales Document Type"; DocDate: Date): Code[10]
    var
        Country: Record "Country/Region";
        Customer: Record Customer;
    begin
        PrepareCountry(Country);
        PrepareCustomer(Customer, Country.Code);
        CreateAndPostSalesDocumentInPeriod(Customer."No.", DocumentType, DocDate);
        exit(Country.Code);
    end;

    local procedure PrepareCountry(var Country: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(Country);
        CreateVATRegNoFormat(Country.Code, GetVATRegNoFormatText);
    end;

    local procedure PrepareCustomer(var Customer: Record Customer; CountryCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            "Country/Region Code" := CountryCode;
            "VAT Registration No." := CreateVatRegNo(CountryCode);
            "Enterprise No." := CreateEnterpriseNo;
            Modify;
        end;
    end;

    local procedure CreateAndPostSalesDocumentInPeriod(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; DocDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        with SalesHeader do begin
            Validate("Order Date", DocDate);
            Validate("Posting Date", DocDate);
            Validate("Shipment Date", DocDate);
            Modify(true);
        end;
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateVATRegNoFormat(CountryCode: Code[10]; FormatText: Text[20])
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        with VATRegistrationNoFormat do begin
            SetRange("Country/Region Code", CountryCode);
            if FindLast then;
            "Country/Region Code" := CountryCode;
            "Line No." += 10000;
            Format := FormatText;
            Insert;
        end;
    end;

    local procedure GetVATRegNoFormatText(): Text[20]
    begin
        exit('#########');
    end;

    local procedure CreateEnterpriseNo(): Code[20]
    begin
        exit('TVA' + CreateMOD97CompliantCode)
    end;

    local procedure CreateMOD97CompliantCode() CodeMod97Compliant: Code[10]
    var
        CompliantCodeBody: Integer;
    begin
        CompliantCodeBody := LibraryRandom.RandIntInRange(1, 100000000);
        CodeMod97Compliant := ConvertStr(Format(CompliantCodeBody, 8, '<Integer>'), ' ', '0');
        CodeMod97Compliant += ConvertStr(Format(97 - CompliantCodeBody mod 97, 2, '<Integer>'), ' ', '0');
    end;

    local procedure CreateVatRegNo(CountryCode: Code[10]) Result: Text[20]
    var
        VatRegNoFormat: Record "VAT Registration No. Format";
    begin
        VatRegNoFormat.SetRange("Country/Region Code", CountryCode);
        if VatRegNoFormat.FindFirst then
            Result := VatRegNoFormat.Format
        else
            Error(VatRegNoFormatNotFoundErr);
        Result := ConvertStr(Result, '#', '9');
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

    [Normal]
    local procedure GetPositionOfNameSpace(FileName: Text; NameSpace: Text): Integer
    var
        DataStream: InStream;
        XMLFile: File;
        Position: Integer;
        Txt: Text;
    begin
        XMLFile.Open(FileName);
        XMLFile.CreateInStream(DataStream);
        while not DataStream.EOS and (Position = 0) do begin
            DataStream.ReadText(Txt);
            Position := StrPos(Txt, NameSpace);
        end;
        XMLFile.Close;

        exit(Position)
    end;

    local procedure ExportAnnualListing(WrongEnterpriseNo: Boolean; Year: Integer; MinimumAmount: Decimal; IncludeCountry: Option All,Specific; CountryCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(WrongEnterpriseNo);
        LibraryVariableStorage.Enqueue(Year);
        LibraryVariableStorage.Enqueue(MinimumAmount);
        LibraryVariableStorage.Enqueue(IncludeCountry);
        LibraryVariableStorage.Enqueue(CountryCode);
        REPORT.Run(REPORT::"VAT Annual Listing", true);
    end;

    local procedure ExportAnnualListingDisk(Year: Integer; RepresentatveID: Code[20]; IncludeCountry: Option All,Specific; CountryCode: Code[10]; MinimumAmount: Decimal; var FileName: Text; CustomerNoFilter: Text)
    var
        Customer: Record Customer;
        VATAnnualListingDisk: Report "VAT Annual Listing - Disk";
    begin
        LibraryVariableStorage.Enqueue(Year);
        LibraryVariableStorage.Enqueue(RepresentatveID);
        LibraryVariableStorage.Enqueue(IncludeCountry);
        LibraryVariableStorage.Enqueue(CountryCode);
        LibraryVariableStorage.Enqueue(MinimumAmount);

        if CustomerNoFilter <> '' then
            Customer.SetFilter("No.", CustomerNoFilter);
        FileName := FileMgt.ServerTempFileName('xml');
        VATAnnualListingDisk.SetTableView(Customer);
        VATAnnualListingDisk.SetFileName(FileName);
        Commit();
        VATAnnualListingDisk.Run();
    end;

    local procedure VerifyAnnualListingReportData(CustomerNo: Code[20]; VATRegistrationNo: Code[71])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BufferVATRegistrationNo', VATRegistrationNo);
        LibraryReportDataset.AssertElementWithValueExists('BufferAmount', -VATEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('BufferBase', -VATEntry.Base);
    end;

    local procedure VerifyAnnualListingDiskReportData(FileName: Text; CustomerNo: Code[20]; EnterpriseNo: Code[50])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.CalcSums(Base, Amount);
        LibraryXPathXMLReader.Initialize(FileName, 'http://www.minfin.fgov.be/ClientListingConsignment');
        LibraryXPathXMLReader.VerifyNodeValue(CompanyVATNumberCapTxt, EnterpriseNo);
        LibraryXPathXMLReader.VerifyNodeValue(TurnOverCapTxt, Format(-VATEntry.Base));
        LibraryXPathXMLReader.VerifyNodeValue(VATAmountCapTxt, Format(-VATEntry.Amount));
        LibraryXPathXMLReader.VerifyAttributeValue(ClientListingTxt, TurnOverSumCapTxt, Format(-VATEntry.Base));
        LibraryXPathXMLReader.VerifyAttributeValue(ClientListingTxt, VATAmountSumCapTxt, Format(-VATEntry.Amount));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATAnnualListingRequestPageHandler(var VATAnnualListing: TestRequestPage "VAT Annual Listing")
    var
        DequeuedVar: Variant;
    begin
        VATAnnualListing.WrongEntrNo.SetValue(LibraryVariableStorage.DequeueBoolean()); // WrongEntrNo
        VATAnnualListing.Year.SetValue(LibraryVariableStorage.DequeueInteger()); // Year
        VATAnnualListing.Minimum.SetValue(LibraryVariableStorage.DequeueDecimal()); // Minimum Amount
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATAnnualListing.IncludeCountry.SetValue(DequeuedVar); // Include Country
        VATAnnualListing.Country.SetValue(LibraryVariableStorage.DequeueText()); // Country
        VATAnnualListing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VatAnnualListingDiskRequestPageHandler(var VatAnnualListingDisk: TestRequestPage "VAT Annual Listing - Disk")
    var
        DequeuedVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VatAnnualListingDisk.VYear.SetValue(DequeuedVar); // Year
        VatAnnualListingDisk.TestDeclaration.SetValue(false);
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VatAnnualListingDisk.AddRepresentative.SetValue(Format(DequeuedVar) <> ''); // Add representative
        if Format(DequeuedVar) <> '' then
            VatAnnualListingDisk.ID.SetValue(DequeuedVar); // Add representative
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VatAnnualListingDisk.IncludeCountry.SetValue(DequeuedVar); // Include Country
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VatAnnualListingDisk.Country.SetValue(DequeuedVar); // Country
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VatAnnualListingDisk.Minimum.SetValue(DequeuedVar); // Minimum Amount
        VatAnnualListingDisk.OK.Invoke;
    end;
}

