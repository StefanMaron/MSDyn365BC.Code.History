codeunit 134761 "Test Custom Reports"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Custom Report Selection]
    end;

    var
        CustomerFullMod: Record Customer;
        CustomerPartialMod: Record Customer;
        CustomerNoMod: Record Customer;
        CustomReportLayout: Record "Custom Report Layout";
        QuoteSalesHeaderFullMod: Record "Sales Header";
        OrderSalesHeaderFullMod: Record "Sales Header";
        InvoiceSalesHeaderFullMod: Record "Sales Header";
        InvoiceSalesHeaderFullModEmail: Record "Sales Header";
        CreditMemoSalesHeaderFullMod: Record "Sales Header";
        CreditMemoSalesHeaderFullModEmail: Record "Sales Header";
        QuoteSalesHeaderParitalMod: Record "Sales Header";
        OrderSalesHeaderPartialMod: Record "Sales Header";
        InvoiceSalesHeaderPartialMod: Record "Sales Header";
        InvoiceSalesHeaderPartialModEmail: Record "Sales Header";
        CreditMemoSalesHeaderPartialMod: Record "Sales Header";
        CreditMemoSalesHeaderPartialModEmail: Record "Sales Header";
        QuoteSalesHeaderNoMod: Record "Sales Header";
        OrderSalesHeaderNoMod: Record "Sales Header";
        InvoiceSalesHeaderNoMod: Record "Sales Header";
        InvoiceSalesHeaderNoModEmail: Record "Sales Header";
        CreditMemoSalesHeaderNoMod: Record "Sales Header";
        CreditMemoSalesHeaderNoModEmail: Record "Sales Header";
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERM: Codeunit "Library - ERM";
        FormatDocument: Codeunit "Format Document";
        Usage: Option Quote,"Confirmation Order",Invoice,"Credit Memo","Customer Statement";
        ReportSelectionUsage: Enum "Report Selection Usage";
        IsInitialized: Boolean;
        ExpectedFilesErr: Label 'Expected files as report output in temporary directory. None found.', Comment = '%1, filename.';
        ExpectedMissingFilePathErr: Label 'Expected files to not be present in output directory. Found %1', Comment = '%1 - filename';
        ExpectedFilePathErr: Label 'Expected files as report output in temporary directory. None found. Expected file %1.', Comment = '%1, filename.';
        ExpectedSingleFileErr: Label 'Expected a single output file, found .zip file.';
        TempFolderIndex: Integer;
        StandardStatementModTxt: Label 'Standard Statement Mod';
        StatementModTxt: Label 'Statement Mod';
        StandardStatementFullModTxt: Label 'Standard Statement Full Mod';
        InvoiceDiscountTxt: Label 'Invoice Discount';
        SubtotalTxt: Label 'Subtotal';
        DescriptionReportTotalsLineTxt: Label 'Description_ReportTotalsLine';
        NoOutputErr: Label 'No data exists for the specified report filters.';
        BlankStartDateErr: Label 'Start Date must have a value.';
        ReportIDMustHaveValueErr: Label 'Report ID must have a value';
        TargetEmailErr: Label 'The target email address has not been specified on the document layout for %1, %2';
        PmtDiscTxt: Label 'If we receive the payment before %1, you are eligible for a %2% payment discount.', Comment = '%1 Discount Due Date %2 = value of Payment Discount % ';

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletionOfVendor()
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        CreateCustomReportLayout(REPORT::"Standard Sales - Quote", CustomReportLayout.Type::Word, 'Quote Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Vendor, Vendor."No.", CustomReportSelection.Usage::"S.Quote", REPORT::"Standard Sales - Quote",
          CustomReportLayout.Code);

        CustomReportSelection.SetRange("Source Type", DATABASE::Vendor);
        CustomReportSelection.SetRange("Source No.", Vendor."No.");
        Assert.IsTrue(CustomReportSelection.FindFirst(), 'CustomReportSelection was not found.');

        Vendor.SetRange("No.", Vendor."No.");
        Vendor.DeleteAll(true);  // Vendor.OnDelete should remove CustomReportSelection

        Clear(CustomReportSelection);
        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", CustomerFullMod."No.");
        Assert.IsFalse(CustomReportSelection.FindFirst(), 'Vendor.OnDelete failed to remove CustomReportSelection');

        Clear(CustomReportSelection);
        CustomReportLayout.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletionOfCustomer()
    begin
        LibrarySales.CreateCustomer(CustomerFullMod);

        CreateCustomReportLayout(REPORT::"Standard Sales - Quote", CustomReportLayout.Type::Word, 'Quote Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"S.Quote", REPORT::"Standard Sales - Quote",
          CustomReportLayout.Code);

        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", CustomerFullMod."No.");
        Assert.IsTrue(CustomReportSelection.FindFirst(), 'CustomReportSelection was not found.');

        CustomerFullMod.SetRange("No.", CustomerFullMod."No.");
        CustomerFullMod.DeleteAll(true);  // Customer.OnDelete should remove CustomReportSelection

        Clear(CustomReportSelection);
        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", CustomerFullMod."No.");
        Assert.IsFalse(CustomReportSelection.FindFirst(), 'Customer.OnDelete failed to remove CustomReportSelection');

        Clear(CustomReportSelection);
        CustomReportLayout.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('CustomerReportSelectionHandler,CustomReportLayoutHandler')]
    [Scope('OnPrem')]
    procedure TestAssignCustomReportToCustomer()
    var
        CustomerCard: TestPage "Customer Card";
        CustomReportSelections: TestPage "Customer Report Selections";
    begin
        LibrarySales.CreateCustomer(CustomerFullMod);

        CreateCustomReportLayout(REPORT::"Standard Sales - Invoice", CustomReportLayout.Type::Word, 'Customer Report Customer 1');

        CreateCustomReportLayout(REPORT::"Standard Sales - Invoice", CustomReportLayout.Type::Word, 'Customer Report Customer 2');
        LibraryVariableStorage.Enqueue(CustomReportLayout.Code);
        Commit();

        CustomerCard.Trap();
        PAGE.Run(PAGE::"Customer Card", CustomerFullMod);

        CustomReportSelections.Trap();
        CustomerCard.CustomerReportSelections.Invoke();

        CustomerFullMod.SetRange("No.", CustomerFullMod."No.");
        CustomerFullMod.DeleteAll(true);
        Clear(CustomReportSelection);
        CustomReportLayout.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('StandardQuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintQuotes()
    begin
        Initialize();

        PrintCustomReportSelectionFullMod(
            QuoteSalesHeaderFullMod, REPORT::"Standard Sales - Quote", "Report Selection Usage"::"S.Quote");

        PrintCustomReportSelectionPartMod(
            QuoteSalesHeaderParitalMod, REPORT::"Standard Sales - Quote", "Report Selection Usage"::"S.Quote");

        PrintCustomReportSelectionNoMod(
            QuoteSalesHeaderNoMod, 0, QuoteSalesHeaderNoMod.FieldNo("Bill-to Customer No."), "Report Selection Usage"::"S.Quote");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailQuotes()
    var
        CustomReportID: Integer;
    begin
        Initialize();

        Clear(CustomReportSelection);
        QuoteSalesHeaderFullMod.SetRecFilter();
        CustomReportID :=
          CustomReportSelectionPrint(
            QuoteSalesHeaderFullMod, "Report Selection Usage"::"S.Quote", true, false, QuoteSalesHeaderFullMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Quote", CustomReportID, 'Emailing a Modified Custom Quote failed.');

        Clear(CustomReportSelection);
        QuoteSalesHeaderParitalMod.SetRecFilter();
        CustomReportID :=
          CustomReportSelectionPrint(
            QuoteSalesHeaderParitalMod, "Report Selection Usage"::"S.Quote", true, false, QuoteSalesHeaderParitalMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Quote", CustomReportID, 'Emailing a Standard Quote failed.');

        Clear(CustomReportSelection);
        CustomReportID := 0;
        QuoteSalesHeaderNoMod.SetRecFilter();
        asserterror
          CustomReportID :=
            CustomReportSelectionPrint(
              QuoteSalesHeaderNoMod, "Report Selection Usage"::"S.Quote", true, false, QuoteSalesHeaderNoMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(0, CustomReportID, 'Emailing a Sales Quote failed.');
    end;

    [Test]
    [HandlerFunctions('OrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintOrders()
    begin
        Initialize();

        PrintCustomReportSelectionFullMod(
            OrderSalesHeaderFullMod, REPORT::"Standard Sales - Order Conf.", "Report Selection Usage"::"S.Order");

        PrintCustomReportSelectionPartMod(
            OrderSalesHeaderPartialMod, REPORT::"Standard Sales - Order Conf.", "Report Selection Usage"::"S.Order");

        PrintCustomReportSelectionNoMod(
            OrderSalesHeaderNoMod, 0, OrderSalesHeaderNoMod.FieldNo("Bill-to Customer No."), "Report Selection Usage"::"S.Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailOrders()
    var
        CustomReportID: Integer;
    begin
        Initialize();

        OrderSalesHeaderFullMod.SetRecFilter();
        CustomReportID :=
          CustomReportSelectionPrint(
            OrderSalesHeaderFullMod, "Report Selection Usage"::"S.Order", true, false, OrderSalesHeaderFullMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Order Conf.", CustomReportID, 'Emailing a Custom Order failed.');

        Clear(CustomReportSelection);
        OrderSalesHeaderPartialMod.SetRecFilter();
        CustomReportID :=
          CustomReportSelectionPrint(
            OrderSalesHeaderPartialMod, "Report Selection Usage"::"S.Order", true, false, OrderSalesHeaderPartialMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Order Conf.", CustomReportID, 'Emailing a Custom Order failed.');

        Clear(CustomReportSelection);
        OrderSalesHeaderNoMod.SetRecFilter();
        CustomReportID := 0;
        asserterror
          CustomReportID :=
            CustomReportSelectionPrint(OrderSalesHeaderNoMod, "Report Selection Usage"::"S.Order", true, false, OrderSalesHeaderNoMod.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(0, CustomReportID, 'Emailing a Sales Quote failed.');
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomReportID: Integer;
    begin
        Initialize();

        SalesInvoiceHeader.Get(InvoiceSalesHeaderFullMod."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(
              SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice", false, true, SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Invoice", CustomReportID, 'Printing a Modified Custom Invoice failed.');

        SalesInvoiceHeader.Get(InvoiceSalesHeaderPartialMod."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(
              SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice", false, true, SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Invoice", CustomReportID, 'Printing a Custom Invoice failed.');

        SalesInvoiceHeader.Get(InvoiceSalesHeaderNoMod."Last Posting No.");

        PrintCustomReportSelectionNoMod(
            SalesInvoiceHeader, 0, SalesInvoiceHeader.FieldNo("Bill-to Customer No."), "Report Selection Usage"::"S.Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomReportID: Integer;
    begin
        Initialize();

        SalesInvoiceHeader.Get(InvoiceSalesHeaderFullModEmail."Last Posting No.");
        SalesInvoiceHeader.SetRecFilter();
        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice", true, true, SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Invoice", CustomReportID, 'Emailing a Modified Custom Invoice failed.');

        SalesInvoiceHeader.Get(InvoiceSalesHeaderPartialModEmail."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice", true, true, SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Invoice", CustomReportID, 'Emailing a Custom Invoice failed.');

        SalesInvoiceHeader.Get(InvoiceSalesHeaderNoModEmail."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID := 0;
        asserterror
          CustomReportID :=
            CustomReportSelectionPrint(
              InvoiceSalesHeaderNoModEmail, "Report Selection Usage"::"S.Invoice", false, true, InvoiceSalesHeaderNoModEmail.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(0, CustomReportID, 'Emailing an Invoice failed.');
    end;

    [Test]
    [HandlerFunctions('CreditMemoReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustomReportID: Integer;
    begin
        Initialize();

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderFullMod."Last Posting No.");
        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", false, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Credit Memo", CustomReportID, 'Printing a Modified Custom Credit Memo failed.');

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderPartialMod."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", false, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Credit Memo", CustomReportID, 'Printing a Custom Credit Memo failed.');

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderNoMod."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID := 0;
        asserterror
          CustomReportID :=
            CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", false, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(0, CustomReportID, 'Printing an Invoice failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustomReportID: Integer;
    begin
        Initialize();

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderFullModEmail."Last Posting No.");
        SalesCrMemoHeader.SetRecFilter();
        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", true, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Credit Memo", CustomReportID, 'Printing a Modified Custom Credit Memo failed.');

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderPartialModEmail."Last Posting No.");
        SalesCrMemoHeader.SetRecFilter();
        Clear(CustomReportSelection);
        CustomReportID :=
          CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", true, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(REPORT::"Standard Sales - Credit Memo", CustomReportID, 'Printing a Modified Custom Credit Memo failed.');

        SalesCrMemoHeader.Get(CreditMemoSalesHeaderNoModEmail."Last Posting No.");

        Clear(CustomReportSelection);
        CustomReportID := 0;
        asserterror
          CustomReportID :=
            CustomReportSelectionPrint(SalesCrMemoHeader, "Report Selection Usage"::"S.Cr.Memo", false, true, SalesCrMemoHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(0, CustomReportID, 'Printing an Invoice failed.');
    end;

    [Test]
    [HandlerFunctions('StandardStatementDirectRunReportHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementDirectRun()
    var
        StandardStatement: Report "Standard Statement";
    begin
        Initialize();

        // Clear to avoid 'unused var' precal error
        Clear(StandardStatement);

        StandardStatement.Run();
    end;

    [Test]
    [HandlerFunctions('StandardStatementDirectRunReportHandlerAllOff')]
    [Scope('OnPrem')]
    procedure StandardStatementDirectRunOptionsOff()
    var
        StandardStatement: Report "Standard Statement";
    begin
        Initialize();

        // Clear to avoid 'unused var' precal error
        Clear(StandardStatement);

        StandardStatement.Run();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPrintHandler')]
    [Scope('OnPrem')]
    procedure PrintStandardStatementReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        // Ensure that the report path runs without errors. Suppress output.
        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, true);
    end;

    [Test]
    [HandlerFunctions('StatementPrintHandler')]
    [Scope('OnPrem')]
    procedure PrintStatementReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        // Ensure that the report path runs without errors. Suppress output.
        RunStatementReport(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, true);
    end;

    [Test]
    [HandlerFunctions('StatementPrintHandler')]
    [Scope('OnPrem')]
    procedure PrintStatementReportWithDifferentIterator()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        // Ensure that the report path runs without errors. Suppress output.
        RunStatementReport(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, false);
    end;

    [Test]
    [HandlerFunctions('StatementPrintHandler')]
    [Scope('OnPrem')]
    procedure PrintStatementReportWebClient()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        TestCustomReports: Codeunit "Test Custom Reports";
        DataCompression: Codeunit "Data Compression";
        EntryList: List of [Text];
        AllReportsFile: File;
        AllReportsInStream: InStream;
        AllReportsPath: Text;
        TestPath: Text;
        OutputPath: Text;
    begin
        // Validate that running multiple statement reports generates a .zip file that contains reports.
        Initialize();
        OutputPath := GetOutputFolder();
        BindSubscription(TestCustomReports);
        CustomLayoutReporting.SetTestModeWebClient(true);
        CustomLayoutReporting.SetOutputFileBaseName('Test Report');

        RunStatementReport(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Look for the AllReports.zip file in the temp directory
        AllReportsPath := FileManagement.CombinePath(OutputPath, 'AllReports.zip');
        Assert.IsTrue(Exists(AllReportsPath), ExpectedFilesErr);

        // Read the entries of the AllReports.zip
        AllReportsFile.Open(AllReportsPath);
        AllReportsFile.CreateInStream(AllReportsInStream);
        DataCompression.OpenZipArchive(AllReportsInStream, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        AllReportsFile.Close();
        if Exists(AllReportsPath) then
            Erase(AllReportsPath);

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath := StrSubstNo('Test Report for %1 as of %2.pdf', CustomReportLayout.Description, Format(CalcDate('<CD+5Y>'), 0, 9));

        Assert.IsTrue(EntryList.Contains(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [HandlerFunctions('StatementPrintHandler')]
    [Scope('OnPrem')]
    procedure PrintSingleStatementReportWebClient()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        TestCustomReports: Codeunit "Test Custom Reports";
        AllReportsPath: Text;
        TestPath: Text;
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        AllReportsPath := FileManagement.CombinePath(OutputPath, 'AllReports.zip');
        if Exists(AllReportsPath) then
            Erase(AllReportsPath);

        BindSubscription(TestCustomReports);
        CustomLayoutReporting.SetTestModeWebClient(true);
        CustomLayoutReporting.SetOutputFileBaseName('Test Report');

        // Run customer statement for a single customer
        Customer.Copy(CustomerFullMod);
        Customer.SetRecFilter();
        Customer.SetRange("No.", Customer."No.");
        Customer.FindFirst();

        RunStatementReport(Customer, CustomLayoutReporting, OutputPath, false, true);

        // Look for the AllReports.zip file in the temp directory
        Assert.IsFalse(Exists(AllReportsPath), ExpectedSingleFileErr);

        // Get the report selection for the first test data customer
        CustomReportSelection.SetRange("Source No.", Customer."No.");
        CustomReportSelection.SetRange(Usage, "Report Selection Usage"::"C.Statement");
        CustomReportSelection.SetRange("Report ID", REPORT::Statement);
        CustomReportSelection.FindFirst();
        CustomReportLayout.Get(CustomReportSelection."Custom Report Layout Code");

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath :=
          FileManagement.CombinePath(
            OutputPath,
            StrSubstNo('Test Report for %1 as of %2.pdf', CustomReportLayout.Description, Format(CalcDate('<CD+5Y>'), 0, 9)));

        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
        Erase(TestPath);
    end;

    [Test]
    [HandlerFunctions('StandardStatementDefaultLayoutHandler')]
    [Scope('OnPrem')]
    procedure DefaultLayoutReportWebClient()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        CustomLayoutReporting.SetTestModeWebClient(true);
        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, true);
    end;

    [Test]
    [HandlerFunctions('StandardStatementEmailHandler')]
    [Scope('OnPrem')]
    procedure EmailReport()
    var
        CustomerLocal: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        Initialize();

        CustomerLocal.Copy(CustomerFullMod);
        ErrorMessages.Trap();
        CustomerLocal.SetRecFilter();
        asserterror RunStatementReportWithStandardSelection(CustomerLocal, CustomLayoutReporting, TemporaryPath, true, true);

        AssertErrorMessageOnPage(
            ErrorMessages, ErrorMessages.First(), StrSubstNo(TargetEmailErr, CustomerLocal.RecordId, ReportSelectionUsage::"C.Statement"));
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
    end;

    [Test]
    [HandlerFunctions('StandardStatementEmailPrintRemainingHandler')]
    [Scope('OnPrem')]
    procedure EmailReportPrintRemaining()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, true);
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure PDFReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        TestPath: Text;
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // Get the report selection for the first test data customer
        CustomReportSelection.SetRange("Source No.", CustomerFullMod."No.");
        CustomReportSelection.SetRange(Usage, "Report Selection Usage"::"C.Statement");
        CustomReportSelection.SetRange("Report ID", REPORT::"Standard Statement");
        CustomReportSelection.FindFirst();
        CustomReportLayout.SetRange(Code, CustomReportSelection."Custom Report Layout Code");
        CustomReportLayout.FindFirst();

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath :=
          FileManagement.CombinePath(
            OutputPath,
            StrSubstNo(
              'Report for %1_%2 as of %3.pdf', CustomerFullMod.Name, CustomReportLayout.Description, Format(CalcDate('<CD+5Y>'), 0, 9)));

        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure PDFReportWithDifferentIterator()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        TestPath: Text;
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, false);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath :=
          FileManagement.CombinePath(
            OutputPath,
            StrSubstNo(
              'Report for %1_%2 as of %3.pdf', CustomerFullMod.Name, StandardStatementModTxt, Format(CalcDate('<CD+5Y>'), 0, 9)));

        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure PDFReportSeparateDataInitialize()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        CustRecRef: RecordRef;
        TestPath: Text;
        OptionText: Text;
        CalculatedDate: Date;
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        SetStandardStatementSelection();

        InitializeCustomLayoutReporting(CustomLayoutReporting, OutputPath, false);

        CustRecRef.Open(DATABASE::Customer);
        LibraryVariableStorage.Enqueue(GetStartDate());
        CustomLayoutReporting.InitializeReportData(
          "Report Selection Usage"::"C.Statement", CustRecRef, CustomerFullMod.FieldName("No."), DATABASE::Customer,
          CustomerFullMod.FieldName("No."), true);

        // Assert that request page options are present filled out
        Assert.AreEqual(
          CustomLayoutReporting.GetOutputOption(REPORT::"Standard Statement"), CustomLayoutReporting.GetPDFOption(),
          'Output option mismatch, expcted PDF output selection');

        // Test other request page items:
        CalculatedDate := CalcDate('<CD-1Y>');
        OptionText := CustomLayoutReporting.GetOptionValueFromRequestPageForReport(REPORT::"Standard Statement", 'StartDate');
        Assert.AreEqual(Format(CalculatedDate, 0, 9), OptionText, 'Request page: Start Date does not match expected value');

        CalculatedDate := CalcDate('<CD+5Y>');
        OptionText := CustomLayoutReporting.GetOptionValueFromRequestPageForReport(REPORT::"Standard Statement", 'EndDate');
        Assert.AreEqual(Format(CalculatedDate, 0, 9), OptionText, 'Request page: End Date does not match expected value');

        CustomLayoutReporting.ProcessReport();

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath :=
          FileManagement.CombinePath(
            OutputPath,
            StrSubstNo(
              'Report for %1_%2 as of %3.pdf', CustomerFullMod.Name, StandardStatementModTxt, Format(CalcDate('<CD+5Y>'), 0, 9)));

        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [HandlerFunctions('StandardStatementWordHandler')]
    [Scope('OnPrem')]
    procedure WordReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        TestPath: Text;
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
        TestPath :=
          FileManagement.CombinePath(
            OutputPath,
            StrSubstNo(
              'Report for %1_%2 as of %3.docx', CustomerFullMod.Name, StandardStatementModTxt, Format(CalcDate('<CD+5Y>'), 0, 9)));

        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [HandlerFunctions('StatementExcelHandler')]
    [Scope('OnPrem')]
    procedure ExcelReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        RunStatementReport(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);
    end;

    [Test]
    [HandlerFunctions('StatementXMLHandler')]
    [Scope('OnPrem')]
    procedure XMLReport()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        RunStatementReport(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure MultipleReportSelections()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        // Ensure that both reports run
        LibraryVariableStorage.Enqueue(GetStartDate());
        RunStatementReportWithAllSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // CustomerNoMod should have default reports for each selection - statement and mini statement
        VerifyReportSelections(REPORT::"Standard Statement", REPORT::Statement, OutputPath);
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementCancelHandler')]
    [Scope('OnPrem')]
    procedure MultipleReportSelectionsCancelStatement()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        // Ensure that both reports run
        RunStatementReportWithAllSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // CustomerNoMod should have default reports for Mini Statement only, Statement should not have a report
        VerifyReportSelections(REPORT::"Standard Statement", 0, OutputPath);
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementCancelHandler')]
    [Scope('OnPrem')]
    procedure MultipleReportSelectionsVerifyOutputOptions()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        OutputPath: Text;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        // Ensure that both reports run
        RunStatementReportWithAllSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that an output file exists
        Assert.IsFalse(FileManagement.IsServerDirectoryEmpty(OutputPath), ExpectedFilesErr);

        // Should be able to assert that 'no output' is associated with report 'Statement' since it was cancelled
        Assert.IsFalse(
          CustomLayoutReporting.HasRequestParameterData(REPORT::Statement), 'Statement report has request parameter data, expected it to not have data.');
        Assert.AreEqual(
          CustomLayoutReporting.GetOutputOption(REPORT::"Standard Statement"), CustomLayoutReporting.GetPDFOption(),
          'Expected PDF output option for Standard Statement report.');
        Assert.AreEqual(
          CustomLayoutReporting.GetOutputOption(REPORT::Statement), -1, 'Expected invalid output option for Statement report.');
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure ValidateOutputOptionSetting()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        Initialize();

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, TemporaryPath, true, true);

        // Validate that the output option is '2' - PDF - set by handler
        Assert.AreEqual(
          CustomLayoutReporting.GetPDFOption(), CustomLayoutReporting.GetOutputOption(REPORT::"Standard Statement"),
          'Output option not set to PDF');
    end;

    [Test]
    [HandlerFunctions('CustomerReportSelectionAllUsageTypesAddHandler')]
    [Scope('OnPrem')]
    procedure MultipleReportSelectionWithoutUsageValidationOnPage()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 376417] Customer Report Selection entries not corrupt when user not validates Usage value on page
        // [GIVEN] Customer Report Selection page opened from Customer Card
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);
        CustomerCard.CustomerReportSelections.Invoke();

        // [WHEN] Lines with different Usage options are added to Customer Report Selection Page:
        // [WHEN] 1 Quote, 1 Invoice, 1 Order, 2 Credit Memo, 1 Customer Statement
        // [THEN] Customer Report Selection table contains all records entered with correct Usage values
        CustomReportSelection.Reset();
        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", Customer."No.");
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Quote", 1);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Invoice", 1);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Order", 1);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Cr.Memo", 2);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"C.Statement", 1);
    end;

    [Test]
    [HandlerFunctions('CustomerReportSelectionInsertFromRepordIdHandler')]
    [Scope('OnPrem')]
    procedure MultipleReportSelectionReportIdFirstValidateOnPage()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 376417] Customer Report Selection entries not corrupt when user fills Report No. and then Usage
        // [GIVEN] Customer Report Selection page opened from Customer Card
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);
        CustomerCard.CustomerReportSelections.Invoke();

        // [WHEN] Lines with different Usage options are added to Customer Report Selection Page: Quote, Invoice and Credit Memo
        // [THEN] Customer Report Selection table contains all records entered with correct Usage values
        CustomReportSelection.Reset();
        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", Customer."No.");
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Quote", 1);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Invoice", 1);
        CountReportSelectionEntriesByUsage(CustomReportSelection, CustomReportSelection.Usage::"S.Cr.Memo", 1);
    end;

    local procedure VerifyReportSelections(ExpectedReportID: Integer; ExpectedReportID2: Integer; Path: Text)
    var
        ReportSelections: Record "Report Selections";
        AllObjWithCaption: Record AllObjWithCaption;
        FileManagement: Codeunit "File Management";
        ReportCaption: Text;
        TestPath: Text;
    begin
        if ReportSelections.FindSet() then
            repeat
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportSelections."Report ID");
                ReportCaption := AllObjWithCaption."Object Caption";
                // The end date that's added to the file name is run through the request page, NAV re-formats it in that process, so we need to format it here in the same way
                TestPath :=
                  FileManagement.CombinePath(
                    Path,
                    StrSubstNo(
                      'Report for %1_%2 as of %3.pdf', CustomerNoMod.Name, ReportCaption, Format(CalcDate('<CD+5Y>'), 0, 9)));

                if ReportSelections."Report ID" in [ExpectedReportID, ExpectedReportID2] then
                    Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath))
                else
                    Assert.IsFalse(Exists(TestPath), StrSubstNo(ExpectedMissingFilePathErr, TestPath));
            until ReportSelections.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TestFilterGroups()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        OutputPath: Text;
        FilterGroup: Integer;
    begin
        // Setup
        Initialize();
        OutputPath := GetOutputFolder();

        // Execute
        FilterGroup := CustomerFullMod.FilterGroup;
        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, true);

        // Validate that the filter group is set back to the original
        Assert.AreEqual(
          FilterGroup, CustomerFullMod.FilterGroup, StrSubstNo('Filtergroup changed from %1 to %2', FilterGroup, CustomerFullMod.FilterGroup));
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TestFilterGroupsDifferentIterator()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        OutputPath: Text;
        FilterGroup: Integer;
    begin
        Initialize();
        OutputPath := GetOutputFolder();
        FilterGroup := CustomerFullMod.FilterGroup;

        RunStatementReportWithStandardSelection(CustomerFullMod, CustomLayoutReporting, OutputPath, false, false);

        // Validate that the filter group is set back to the original
        Assert.AreEqual(
          FilterGroup, CustomerFullMod.FilterGroup, StrSubstNo('Filtergroup changed from %1 to %2', FilterGroup, CustomerFullMod.FilterGroup));
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TestFilterGroupsSeparateDataInitialize()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        CustRecRef: RecordRef;
        OutputPath: Text;
        FilterGroup: Integer;
        RecRefFilterGroup: Integer;
    begin
        Initialize();
        OutputPath := GetOutputFolder();

        SetStandardStatementSelection();

        InitializeCustomLayoutReporting(CustomLayoutReporting, OutputPath, false);

        CustRecRef.Open(DATABASE::Customer);

        FilterGroup := CustomerFullMod.FilterGroup;
        RecRefFilterGroup := CustRecRef.FilterGroup;

        LibraryVariableStorage.Enqueue(CalcDate('<CD-1Y>'));
        CustomLayoutReporting.InitializeReportData(
          "Report Selection Usage"::"C.Statement", CustRecRef, CustomerFullMod.FieldName("No."), DATABASE::Customer,
          CustomerFullMod.FieldName("No."), true);

        CustomLayoutReporting.ProcessReport();

        // Validate that the filter group is set back to the original
        Assert.AreEqual(
          FilterGroup, CustomerFullMod.FilterGroup, StrSubstNo('Filtergroup changed from %1 to %2', FilterGroup, CustomerFullMod.FilterGroup));
        Assert.AreEqual(
          RecRefFilterGroup, CustRecRef.FilterGroup,
          StrSubstNo('Filtergroup changed from %1 to %2', RecRefFilterGroup, CustRecRef.FilterGroup));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_TotalLine_PricesExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
    begin
        // [FEATURE] [Standard Sales - Invoice] [Prices Excl. VAT]
        // [SCENARIO 203437] REP 1306 "Standard Sales - Invoice" prints total line as "Total GBP Incl. VAT" in case of "Prices Including VAT" = FALSE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = FALSE, Unit Price = 4000, VAT Amount = 1000, Amount Incl. VAT = 5000
        CreateSalesInvoice(SalesHeader, SalesLine, false);

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] There is a total line with caption and amount: "Total GBP Incl. VAT  5000"
        FormatDocument.SetTotalLabels(SalesHeader.GetCurrencySymbol(), TotalText, TotalInclVATText, TotalExclVATText);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('TotalAmountExclInclVATText', TotalExclVATText);
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('TotalAmountExclInclVATText', TotalInclVATText) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountExclInclVAT', SalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_TotalLine_PricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
    begin
        // [FEATURE] [Standard Sales - Invoice] [Prices Incl. VAT]
        // [SCENARIO 203437] REP 1306 "Standard Sales - Invoice" prints total line as "Total GBP Excl. VAT" in case of "Prices Including VAT" = TRUE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = TRUE, Unit Price = 5000, VAT Amount = 1000, Amount Excl. VAT = 4000
        CreateSalesInvoice(SalesHeader, SalesLine, true);

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] There is a total line with caption and amount: "Total GBP Excl. VAT  4000"
        FormatDocument.SetTotalLabels(SalesHeader.GetCurrencySymbol(), TotalText, TotalInclVATText, TotalExclVATText);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('TotalAmountExclInclVATText', TotalExclVATText) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountExclInclVAT', SalesLine.Amount);
        LibraryReportDataset.AssertElementWithValueNotExist('TotalAmountExclInclVATText', TotalExclVATText);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_ReportTotals_InvoiceDiscount_PricesExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
    begin
        // [FEATURE] [Standard Sales - Invoice] [Prices Excl. VAT] [Invoice Discount]
        // [SCENARIO 203437] REP 1306 "Standard Sales - Invoice" prints subtotal discount line as "Total GBP Excl. VAT" in case of "Prices Including VAT" = FALSE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = FALSE, Unit Price = 5000, Invoice Discount = 1000, VAT Amount = 1000, Amount Incl. VAT = 5000
        CreateSalesInvoice(SalesHeader, SalesLine, false);
        SetSalesInvoiceDiscount(SalesHeader, SalesLine);

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] There are report total lines:
        // [THEN] "Subtotal" = 5000
        // [THEN] "Invoice Discount" = 1000
        // [THEN] "Total GBP Excl. VAT" = 4000
        // [THEN] "25% VAT" = 1000
        FormatDocument.SetTotalLabels(SalesHeader.GetCurrencySymbol(), TotalText, TotalInclVATText, TotalExclVATText);
        VerifyStdSalesInvoiceReportTotalsLines(SalesLine, TotalExclVATText, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_ReportTotals_InvoiceDiscount_PricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
        CurrencySymbol: Text[10];
    begin
        // [FEATURE] [Standard Sales - Invoice] [Prices Incl. VAT] [Invoice Discount]
        // [SCENARIO 203437] REP 1306 "Standard Sales - Invoice" prints subtotal discount line as "Total GBP Incl. VAT" in case of "Prices Including VAT" = TRUE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = TRUE, Unit Price = 6000, Invoice Discount = 1000, VAT Amount = 1000, Amount Excl. VAT = 4000
        CreateSalesInvoice(SalesHeader, SalesLine, true);
        SetSalesInvoiceDiscount(SalesHeader, SalesLine);

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] There are report total lines:
        // [THEN] "Subtotal" = 6000
        // [THEN] "Invoice Discount" = 1000
        // [THEN] "Total GBP Incl. VAT" = 5000
        // [THEN] "25% VAT" = 1000
        CurrencySymbol := SalesHeader.GetCurrencySymbol();
        FormatDocument.SetTotalLabels(CurrencySymbol, TotalText, TotalInclVATText, TotalExclVATText);
        VerifyStdSalesInvoiceReportTotalsLines(SalesLine, TotalInclVATText, SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerStandardStatementAgingTotalsByDueDate()
    var
        Customer: Record Customer;
        LineAmount: Decimal;
        OutputPath: Text;
    begin
        // [SCENARIO 208380] Standard Statement Aging totals must include only amounts that already overdue when Aging by Due Date.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount := LibraryRandom.RandDec(99, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount, LibraryRandom.RandDec(99, 2));

        // [WHEN] Standard Statement Report executed for "CUS" with BeginDate = 01/02/2017, EndDate = 22/02/2017, Aging Band by Due Date.
        SaveStandardStatementAsXML(Customer, OutputPath, 0, CalcDate('<-CM>', GetDate()), GetDate());

        // [THEN] Report Aging amount for the previous month = Entry1.Amount
        VerifyStandardStatementAging(OutputPath, LineAmount, 12);

        // [THEN] Report Aging amount for the current month = 0
        VerifyStandardStatementAging(OutputPath, 0, 13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerStandardStatementAgingTotalsByDueDateNextMonth()
    var
        Customer: Record Customer;
        LineAmount: array[2] of Decimal;
        OutputPath: Text;
    begin
        // [SCENARIO 208380] Standard Statement Aging totals must include only amounts that already overdue when Aging by Due Date for a next month.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount[1] := LibraryRandom.RandDec(99, 2);
        LineAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount[1], LineAmount[2]);

        // [WHEN] Mini Statement Report executed for "CUS" with BeginDate = 01/03/2017, EndDate = 31/03/2017, Aging Band by Due Date.
        SaveStandardStatementAsXML(Customer, OutputPath, 0, CalcDate('<-CM+1M>', GetDate()), CalcDate('<CM+1M>', GetDate()));

        // [THEN] Report Aging amount for the previous month = Entry1.Amount
        VerifyStandardStatementAging(OutputPath, LineAmount[1], 11);

        // [THEN] Report Aging amount for the current month = 0
        VerifyStandardStatementAging(OutputPath, LineAmount[2], 12);

        // [THEN] Report Overdue section contains both Entries
        VerifyStandardStatementOverdue(OutputPath, LineAmount[1] + LineAmount[2], 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerStandardStatementAgingTotalsByPostingDate()
    var
        Customer: Record Customer;
        LineAmount: array[2] of Decimal;
        OutputPath: Text;
    begin
        // [SCENARIO 213673] Standard Statement Aging totals must include all earlier entries amounts when Aging is set by the Posting Date.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount[1] := LibraryRandom.RandDec(99, 2);
        LineAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount[1], LineAmount[2]);

        // [WHEN] Mini Statement Report executed for "CUS" with BeginDate = 01/02/2017, EndDate = 28/02/2017, Aging Band by Posting Date.
        SaveStandardStatementAsXML(Customer, OutputPath, 1, CalcDate('<-CM>', GetDate()), GetDate());

        // [THEN] Report Aging amount for previous month = Entry1."Amount" + Entry2."Amount"
        VerifyStandardStatementAging(OutputPath, LineAmount[1] + LineAmount[2], 12);

        // [THEN] Report Aging amount for the current month = 0
        VerifyStandardStatementAging(OutputPath, 0, 13);
    end;

    [Test]
    [HandlerFunctions('StatementXMLToFileHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerStatementAgingTotalsByDueDate()
    var
        Customer: Record Customer;
        LineAmount: Decimal;
    begin
        // [SCENARIO 208380] Statement Aging totals must include only amounts that already overdue when Aging by Due Date.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount := LibraryRandom.RandDec(99, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount, LibraryRandom.RandDec(99, 2));

        // [WHEN] Statement Report executed for "CUS" with BeginDate = 01/02/2017, EndDate = 22/02/2017, Aging Band by Due Date.
        Commit();
        SaveStatementAsXML(Customer, 0, CalcDate('<CD-1M>', GetDate()), GetDate());
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report Aging amount for the previous month = Entry1.Amount
        VerifyStatementAging(LineAmount, 4);

        // [THEN] Report Aging amount for the current month = 0
        VerifyStatementAging(0, 5);
    end;

    [Test]
    [HandlerFunctions('StatementXMLToFileHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerStatementAgingTotalsByDueDateNextMonth()
    var
        Customer: Record Customer;
        LineAmount: array[2] of Decimal;
    begin
        // [SCENARIO 208380] Statement Aging totals must include only amounts that already overdue when Aging by Due Date for a next month.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount[1] := LibraryRandom.RandDec(99, 2);
        LineAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount[1], LineAmount[2]);

        // [WHEN] Statement Report executed for "CUS" with BeginDate = 01/03/2017, EndDate = 22/03/2017, Aging Band by Due Date.
        Commit();
        SaveStatementAsXML(Customer, 0, CalcDate('<-CM+1M>', GetDate()), CalcDate('<CM+1M>', GetDate()));
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report Aging amount for the previous month = Entry1.Amount
        VerifyStatementAging(LineAmount[1], 3);

        // [THEN] Report Aging amount for the current month = Entry2.Amount
        VerifyStatementAging(LineAmount[2], 4);

        // [THEN] Report Aging amount for the next month = 0
        VerifyStatementAging(0, 5);

        // [THEN] Report Overdue section contains Entry1 and Entry2 Amount
        VerifyStatementOverdue(LineAmount[1]);
        VerifyStatementOverdue(LineAmount[2]);
    end;

    [Test]
    [HandlerFunctions('StatementXMLToFileHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerStatementAgingTotalsByPostingDate()
    var
        Customer: Record Customer;
        LineAmount: array[2] of Decimal;
    begin
        // [SCENARIO 213673] Statement Aging totals must include all earlier entries amounts when Aging is set by the Posting Date.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        LineAmount[1] := LibraryRandom.RandDec(99, 2);
        LineAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Two Customer Ledger Entries for "CUS" where each has "Amount", "PostingDate" and "DueDate".
        // [GIVEN] Entry1 "PostingDate" = 08/01/2017, "DueDate" = 22/01/2017, is overdue.
        // [GIVEN] Entry2 "PostingDate" = 22/01/2017, "DueDate" = 22/02/2017, is NOT overdue.
        CreateTwoCustomerLedgerEntries(Customer."No.", LineAmount[1], LineAmount[2]);

        // [WHEN] Statement Report executed for "CUS" with BeginDate = 01/02/2017, EndDate = 28/02/2017, Aging Band by Posting Date.
        Commit();
        SaveStatementAsXML(Customer, 1, CalcDate('<-CM>', GetDate()), GetDate());
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report Aging amount for the previous month = Entry1.Amount + Entry2.Amount
        VerifyStatementAging(LineAmount[1] + LineAmount[2], 4);

        // [THEN] Report Aging amount for the current month = 0
        VerifyStatementAging(0, 5);
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StatementPDF_FilteredByNotExistingCustomer()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 116 "Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::Statement);

        // [WHEN] Run "Statement" (SaveAs PDF) report filtered by customer "No." = "X" (not existing one customer)
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        ErrorMessages.Trap();
        asserterror RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate());

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters."
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPDF_FilteredByNotExistingCustomer()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (SaveAs PDF) report filtered by customer "No." = "X" (not existing one customer)
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        ErrorMessages.Trap();
        asserterror RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate());

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters."
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StatementPDF_FilteredByNotExistingCustomer_SuppressOutput()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] There is no output and no error
        // [SCENARIO 218263] in case of SaveAs PDF REP 116 "Statement" filtered by not existing customer "No." and suppress output
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::Statement);

        // [WHEN] Run "Statement" (SaveAs PDF using suppress output) report filtered by customer "No." = "X" (not existing one customer)
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, true, true, WorkDate());

        // [THEN] There is no output/error
        // StatementPDFHandler

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPDF_FilteredByNotExistingCustomer_SuppressOutput()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] There is no output and no error
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No." and suppress output
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (SaveAs PDF using suppress output) report filtered by customer "No." = "X" (not existing one customer)
        Customer.SetRange("No.", LibraryUtility.GenerateGUID());
        RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, true, true, WorkDate());

        // [THEN] There is no output/error
        // StandardStatementPDFHandler

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StatementPDF_BlankedStartDate()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "Start Date must have a value."
        // [SCENARIO 218263] in case of SaveAs PDF REP 116 "Statement" with blanked "Start Date"
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::Statement);

        // [WHEN] Run "Statement" (SaveAs PDF) report with blanked "Start Date"
        Customer.SetRange("No.", LibrarySales.CreateCustomerNo());
        ErrorMessages.Trap();
        asserterror RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, false, true, 0D);

        // [THEN] An error has been thrown: "Start Date must have a value."
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPDF_BlankedStartDate()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "Start Date must have a value."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" with blanked "Start Date"
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement"
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (SaveAs PDF) report with blanked "Start Date"
        Customer.SetRange("No.", LibrarySales.CreateCustomerNo());
        ErrorMessages.Trap();
        asserterror RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, false, true, 0D);

        // [THEN] An error has been thrown: "Start Date must have a value."
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoStatementsPDF_OnlyOneHasOutput()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileMgt: Codeunit "File Management";
        ErrorMessages: TestPage "Error Messages";
        TestPath: Text;
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] There is no error in case of SaveAs PDF two Statements (REP116 and REP1316) when only one has output
        Initialize();

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement"
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement"

        // [WHEN] Run "Statement" (SaveAs PDF) report (use normal "Start Date" for "Standard Statement" and blanked for "Statement")
        LibrarySales.CreateCustomer(Customer);
        InsertCustLedgerEntry(Customer."No.", LibraryRandom.RandDec(1000, 2), WorkDate(), WorkDate());
        Customer.SetRecFilter();
        LibraryVariableStorage.Enqueue(WorkDate());
        ErrorMessages.Trap();
        asserterror RunCustomerStatement(Customer, CustomLayoutReporting, TemporaryPath, false, true, 0D);

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // [THEN] There is no error (blanked "Start Date" doesn't stop packet reporting) and PDF file has been created
        // StatementPDFHandler, StandardStatementPDFHandler
        TestPath :=
          FileMgt.CombinePath(
            TemporaryPath, StrSubstNo('Report for %1_Standard Statement as of %2.pdf', Customer.Name, Format(CalcDate('<CD+5Y>'), 0, 9)));
        Assert.IsTrue(Exists(TestPath), StrSubstNo(ExpectedFilePathErr, TestPath));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RestrictEmptyReportID_OnInsert()
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270795] User is unable to insert a line into the "Custom Report Selection" table with a blank "Report ID".
        Initialize();

        CustomReportSelection.Init();
        CustomReportSelection.Validate("Report ID", 0);
        asserterror CustomReportSelection.Insert(true);
        Assert.ExpectedError(ReportIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RestrictEmptyReportID_OnModify()
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270795] User is unable to change "Report ID" to blank in the "Custom Report Selection" table.
        Initialize();

        CustomReportSelection.Init();
        CustomReportSelection.Validate("Report ID", LibraryRandom.RandIntInRange(20, 30));
        CustomReportSelection.Insert(true);

        CustomReportSelection.Validate("Report ID", 0);
        asserterror CustomReportSelection.Insert(true);
        Assert.ExpectedError(ReportIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CleanEmailBodyLayoutCode_OnReportIdValidate()
    var
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        ReportId: array[2] of Integer;
        LayoutCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 319160] Clean "Email Body Layout Code" on "Report Id" field validation with new value
        Initialize();
        ReportID[1] := Report::"Standard Statement";
        ReportID[2] := Report::"Statement";

        LayoutCode := CustomReportLayout.InitBuiltInLayout(ReportId[1], CustomReportLayout.Type::Word.AsInteger());

        CustomReportSelection.Init();
        CustomReportSelection.Validate("Report ID", ReportId[1]);
        CustomReportSelection.Validate("Use for Email Body", true);
        CustomReportSelection.Validate("Custom Report Layout Code", LayoutCode);
        CustomReportSelection.Validate("Email Body Layout Code", LayoutCode);
        CustomReportSelection.Insert(true);

        CustomReportSelection.Validate("Report ID", ReportId[1]);
        CustomReportSelection.TestField("Use for Email Body", true);
        CustomReportSelection.TestField("Custom Report Layout Code", LayoutCode);
        CustomReportSelection.TestField("Email Body Layout Code", LayoutCode);

        CustomReportSelection.Validate("Report ID", ReportId[2]);
        CustomReportSelection.TestField("Email Body Layout Code", '');
        CustomReportSelection.TestField("Custom Report Layout Code", '');
        CustomReportSelection.TestField("Use for Email Body", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDocSetSalesLineTypeBlank()
    var
        SalesLine: Record "Sales Line";
        FormattedQty: Text;
        FormattedUnitPrice: Text;
        FormattedVATPct: Text;
        FormattedLineAmt: Text;
    begin
        // [FEATURE] [UT] [Format Document] [Sales]
        // [SCENARIO 278732] SetSalesLine in codeunit Format Document when Sales Line Type is <blank>
        Initialize();

        // [GIVEN] Sales Line with Type = <blank>
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::" ";

        // [WHEN] SetSalesInvoiceLine in Format Document
        FormatDocument.SetSalesLine(SalesLine, FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);

        // [THEN] All Formatted Text Values are <blank>
        VerifyFormattedTextValuesBlank(FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDocSetSalesInvoiceLineTypeBlank()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        FormattedQty: Text;
        FormattedUnitPrice: Text;
        FormattedVATPct: Text;
        FormattedLineAmt: Text;
    begin
        // [FEATURE] [UT] [Format Document] [Sales] [Invoice]
        // [SCENARIO 278732] SetSalesInvoiceLine in codeunit Format Document when Sales Invoice Line Type is <blank>
        Initialize();

        // [GIVEN] Sales Invoice Line with Type = <blank>
        SalesInvoiceLine.Init();
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::" ";

        // [WHEN] SetSalesInvoiceLine in Format Document
        FormatDocument.SetSalesInvoiceLine(SalesInvoiceLine, FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);

        // [THEN] All Formatted Text Values are <blank>
        VerifyFormattedTextValuesBlank(FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDocSetSalesCrMemoLineTypeBlank()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        FormattedQty: Text;
        FormattedUnitPrice: Text;
        FormattedVATPct: Text;
        FormattedLineAmt: Text;
    begin
        // [FEATURE] [UT] [Format Document] [Sales] [Credit Memo]
        // [SCENARIO 278732] SetSalesCrMemoLine in codeunit Format Document when Sales Cr. Memo Line Type is <blank>
        Initialize();

        // [GIVEN] Sales Cr. Memo Line with Type = <blank>
        SalesCrMemoLine.Init();
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::" ";

        // [WHEN] SetSalesCrMemoLine in Format Document
        FormatDocument.SetSalesCrMemoLine(SalesCrMemoLine, FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);

        // [THEN] All Formatted Text Values are <blank>
        VerifyFormattedTextValuesBlank(FormattedQty, FormattedUnitPrice, FormattedVATPct, FormattedLineAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDocSetPurchaseLineTypeBlank()
    var
        PurchaseLine: Record "Purchase Line";
        FormattedQty: Text;
        FormattedDirectUnitCost: Text;
        FormattedVATPercentage: Text;
        FormattedLineAmount: Text;
    begin
        // [FEATURE] [UT] [Format Document] [Purchase]
        // [SCENARIO 278732] SetPurchaseLine in codeunit Format Document when Purchase Line Type is <blank>
        Initialize();

        // [GIVEN] Purchase Line with Type = <blank>
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::" ";

        // [WHEN] SetPurchaseLine in Format Document
        FormatDocument.SetPurchaseLine(PurchaseLine, FormattedQty, FormattedDirectUnitCost, FormattedVATPercentage, FormattedLineAmount);

        // [THEN] All Formatted Text Values are <blank>
        VerifyFormattedTextValuesBlank(FormattedQty, FormattedDirectUnitCost, FormattedVATPercentage, FormattedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Sales Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        SalesLine.Init();

        SalesLine.Type := SalesLine.Type::" ";
        Assert.IsFalse(SalesLine.HasTypeToFillMandatoryFields(), '');

        SalesLine.Type := SalesLine.Type::"Charge (Item)";
        Assert.IsTrue(SalesLine.HasTypeToFillMandatoryFields(), '');

        SalesLine.Type := SalesLine.Type::"Fixed Asset";
        Assert.IsTrue(SalesLine.HasTypeToFillMandatoryFields(), '');

        SalesLine.Type := SalesLine.Type::"G/L Account";
        Assert.IsTrue(SalesLine.HasTypeToFillMandatoryFields(), '');

        SalesLine.Type := SalesLine.Type::Item;
        Assert.IsTrue(SalesLine.HasTypeToFillMandatoryFields(), '');

        SalesLine.Type := SalesLine.Type::Resource;
        Assert.IsTrue(SalesLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsSalesInvLine()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [FEATURE] [UT] [Sales] [Invoice]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Sales Invoice Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        SalesInvoiceLine.Init();

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::" ";
        Assert.IsFalse(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"Charge (Item)";
        Assert.IsTrue(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"Fixed Asset";
        Assert.IsTrue(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"G/L Account";
        Assert.IsTrue(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        Assert.IsTrue(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');

        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Resource;
        Assert.IsTrue(SalesInvoiceLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsSalesCrMemoLine()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // [FEATURE] [UT] [Sales] [Credit Memo]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Sales Cr. Memo Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        SalesCrMemoLine.Init();

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::" ";
        Assert.IsFalse(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"Charge (Item)";
        Assert.IsTrue(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"Fixed Asset";
        Assert.IsTrue(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"G/L Account";
        Assert.IsTrue(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        Assert.IsTrue(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');

        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Resource;
        Assert.IsTrue(SalesCrMemoLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsPurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Purchase Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        PurchaseLine.Init();

        PurchaseLine.Type := PurchaseLine.Type::" ";
        Assert.IsFalse(PurchaseLine.HasTypeToFillMandatoryFields(), '');

        PurchaseLine.Type := PurchaseLine.Type::"Charge (Item)";
        Assert.IsTrue(PurchaseLine.HasTypeToFillMandatoryFields(), '');

        PurchaseLine.Type := PurchaseLine.Type::"Fixed Asset";
        Assert.IsTrue(PurchaseLine.HasTypeToFillMandatoryFields(), '');

        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        Assert.IsTrue(PurchaseLine.HasTypeToFillMandatoryFields(), '');

        PurchaseLine.Type := PurchaseLine.Type::Item;
        Assert.IsTrue(PurchaseLine.HasTypeToFillMandatoryFields(), '');

        PurchaseLine.Type := PurchaseLine.Type::Resource;
        Assert.IsTrue(PurchaseLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsPurchInvLine()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // [FEATURE] [UT] [Purchase] [Invoice]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Purch. Inv. Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        PurchInvLine.Init();

        PurchInvLine.Type := PurchInvLine.Type::" ";
        Assert.IsFalse(PurchInvLine.HasTypeToFillMandatoryFields(), '');

        PurchInvLine.Type := PurchInvLine.Type::"Charge (Item)";
        Assert.IsTrue(PurchInvLine.HasTypeToFillMandatoryFields(), '');

        PurchInvLine.Type := PurchInvLine.Type::"Fixed Asset";
        Assert.IsTrue(PurchInvLine.HasTypeToFillMandatoryFields(), '');

        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        Assert.IsTrue(PurchInvLine.HasTypeToFillMandatoryFields(), '');

        PurchInvLine.Type := PurchInvLine.Type::Item;
        Assert.IsTrue(PurchInvLine.HasTypeToFillMandatoryFields(), '');

        PurchInvLine.Type := PurchInvLine.Type::Resource;
        Assert.IsTrue(PurchInvLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasTypeToFillMandatoryFieldsPurchCrMemoLine()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // [FEATURE] [UT] [Purchase] [Credit Memo]
        // [SCENARIO 278732] HasTypeToFillMandatoryFields in Purch. Cr. Memo Line returns FALSE for <blank> Type and TRUE for all other Types
        Initialize();
        PurchCrMemoLine.Init();

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::" ";
        Assert.IsFalse(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"Charge (Item)";
        Assert.IsTrue(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"Fixed Asset";
        Assert.IsTrue(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"G/L Account";
        Assert.IsTrue(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Item;
        Assert.IsTrue(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');

        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Resource;
        Assert.IsTrue(PurchCrMemoLine.HasTypeToFillMandatoryFields(), '');
    end;

    [Test]
    [HandlerFunctions('StandardStatementDefaultLayoutHandler,StatementCancelHandler')]
    [Scope('OnPrem')]
    procedure RunGetLayoutIteratorKeyFilterForCustomerConsecutiveRecords()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        CustomReportSelection: Record "Custom Report Selection";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CustomerNo: array[7] of Code[20];
        CustomerNoFilter: Text;
        i: Integer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 319005] Run GetLayoutIteratorKeyFilter function of "Custom Layout Reporting" on consequtive Customer numbers.
        Initialize();

        // [GIVEN] Customers C1, C2,...,C7, that are added both to database and temporary table "T1".
        for i := 1 to ArrayLen(CustomerNo) do begin
            LibrarySales.CreateCustomer(Customer);
            TempCustomer := Customer;
            TempCustomer.Insert();
            CustomerNo[i] := Customer."No.";
        end;
        CreateCustomReportLayout(REPORT::"Standard Statement", CustomReportLayout.Type::RDLC, 'Standard Statement');

        // [GIVEN] Customers C1..C3|C5|C7 has Custom Layout "L1" for Usage "C.Statement".
        CustomerNoFilter := StrSubstNo('%1..%2|%3|%4', CustomerNo[1], CustomerNo[3], CustomerNo[5], CustomerNo[7]);
        TempCustomer.SetFilter("No.", CustomerNoFilter);
        TempCustomer.FindSet();
        repeat
            AssignCustomLayoutToCustomer(
              DATABASE::Customer, TempCustomer."No.", CustomReportSelection.Usage::"C.Statement", REPORT::"Standard Statement",
              CustomReportLayout.Code);
        until TempCustomer.Next() = 0;
        TempCustomer.Reset();
        RecRef.GetTable(TempCustomer);
        FieldRef := RecRef.Field(Customer.FieldNo("No."));

        // [WHEN] Run GetLayoutIteratorKeyFilter function of "Custom Layout Reporting" on temporary table "T1" and Custom Layout "L1".
        LibraryVariableStorage.Enqueue(WorkDate());
        CustomLayoutReporting.InitializeReportData(
          CustomReportSelection.Usage::"C.Statement", RecRef, Customer.FieldName("No."), DATABASE::Customer, Customer.FieldName("No."), true);
        CustomLayoutReporting.GetLayoutIteratorKeyFilter(RecRef, FieldRef, CustomReportLayout.Code);

        // [THEN] "T1" was filtered to "C1..C3|C5|C7" inside filtergroup 10.
        RecRef.SetTable(TempCustomer);
        TempCustomer.FilterGroup(10);
        Assert.AreEqual(CustomerNoFilter, TempCustomer.GetFilter("No."), '');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunGetLayoutIteratorKeyFilterForVendorConsecutiveRecords()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        CustomReportSelection: Record "Custom Report Selection";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        VendorNo: array[7] of Code[20];
        VendorNoFilter: Text;
        i: Integer;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 319005] Run GetLayoutIteratorKeyFilter function of "Custom Layout Reporting" on consequitive Vendor numbers.
        Initialize();
        LibraryERM.SetupReportSelection("Report Selection Usage"::"P.Invoice", REPORT::"Purchase - Invoice");

        // [GIVEN] Vendors V1, V2,...,V7, that are added both to database and temporary table "T1".
        for i := 1 to ArrayLen(VendorNo) do begin
            LibraryPurchase.CreateVendor(Vendor);
            TempVendor := Vendor;
            TempVendor.Insert();
            VendorNo[i] := Vendor."No.";
        end;

        CreateCustomReportLayout(REPORT::"Purchase - Invoice", CustomReportLayout.Type::RDLC, 'Purchase - Invoice');

        // [GIVEN] Vendors V1..V3|V5|V7 has Custom Layout "L1" for Usage "P.Invoice".
        VendorNoFilter := StrSubstNo('%1..%2|%3|%4', VendorNo[1], VendorNo[3], VendorNo[5], VendorNo[7]);
        TempVendor.SetFilter("No.", VendorNoFilter);
        TempVendor.FindSet();
        repeat
            AssignCustomLayoutToCustomer(
              DATABASE::Vendor, TempVendor."No.", CustomReportSelection.Usage::"P.Invoice", REPORT::"Purchase - Invoice",
              CustomReportLayout.Code);
        until TempVendor.Next() = 0;
        TempVendor.Reset();
        RecRef.GetTable(TempVendor);
        FieldRef := RecRef.Field(Vendor.FieldNo("No."));

        // [WHEN] Run GetLayoutIteratorKeyFilter function of "Custom Layout Reporting" on temporary table "T1" and Custom Layout "L1".
        LibraryVariableStorage.Enqueue(WorkDate());
        CustomLayoutReporting.InitializeReportData(
          CustomReportSelection.Usage::"P.Invoice", RecRef, Vendor.FieldName("No."), DATABASE::Vendor, Vendor.FieldName("No."), true);
        CustomLayoutReporting.GetLayoutIteratorKeyFilter(RecRef, FieldRef, CustomReportLayout.Code);

        // [THEN] "T1" was filtered to "V1..V3|V5|V7" inside filtergroup 10.
        RecRef.SetTable(TempVendor);
        TempVendor.FilterGroup(10);
        Assert.AreEqual(VendorNoFilter, TempVendor.GetFilter("No."), '');

        // Tear down
        InitReportSelections();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDocSetPurchaseFormattedVATPctAndLineAmount()
    var
        PurchaseLine: Record "Purchase Line";
        FormattedQty: Text;
        FormattedDirectUnitCost: Text;
        FormattedVATPercentage: Text;
        FormattedLineAmount: Text;
    begin
        // [FEATURE] [UT] [Format Document] [Purchase]
        // [SCENARIO 344208] Parameters FormattedVATPct and FormattedLineAmount for SetPurchaseLine in codeunit Format Document 
        Initialize();

        // [GIVEN] Purchase Line with "VAT %" = 25, "Line Amount" = 100
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."VAT %" := LibraryRandom.RandInt(10);
        PurchaseLine."Line Amount" := LibraryRandom.RandDec(100, 2);

        // [WHEN] SetPurchaseLine in Format Document
        FormatDocument.SetPurchaseLine(PurchaseLine, FormattedQty, FormattedDirectUnitCost, FormattedVATPercentage, FormattedLineAmount);

        // [THEN] FormattedVATPercentage = "25", FormattedLineAmount = "100.00"
        Assert.AreEqual(Format(PurchaseLine."VAT %"), FormattedVATPercentage, 'Invalid value');
        Assert.AreEqual(Format(PurchaseLine."Line Amount"), FormattedLineAmount, 'Invalid value');
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForEmptyCustomerWithBothInclude()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (Preview) report filtered by empty Customer, "Include All Customers with a Balance" = true, "Include All Customers with Ledger Entries" = true.
        Customer.SetRange("No.", LibrarySales.CreateCustomerNo());
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), true, true);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForEmptyCustomerWithIncludeBalance()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (Preview) report filtered by empty Customer, "Include All Customers with a Balance" = true, "Include All Customers with Ledger Entries" = false.
        Customer.SetRange("No.", LibrarySales.CreateCustomerNo());
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), true, false);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForEmptyCustomerWithIncludeLE()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [WHEN] Run "Statement" (Preview) report filtered by empty Customer, "Include All Customers with a Balance" = false, "Include All Customers with Ledger Entries" = true.
        Customer.SetRange("No.", LibrarySales.CreateCustomerNo());
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), false, true);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForCustomerWithBothInclude()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by customer with ledger entries after filtered date.
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [GIVEN] Customer has ledger entries for 02/02/2020.
        LibrarySales.CreateCustomer(Customer);
        InsertCustLedgerEntry(Customer."No.", LibraryRandom.RandDec(100, 2), CalcDate('<CD+6Y>'), CalcDate('<CD+6Y>'));

        // [WHEN] Run "Statement" (Preview) report filtered by Customer and with End Date = 01/01/2019, "Include All Customers with a Balance" = true, "Include All Customers with Ledger Entries" = true.
        Customer.SetRange("No.", Customer."No.");
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), true, true);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForCustomerWithIncludeBalance()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [GIVEN] Customer has ledger entries for 02/02/2020.
        LibrarySales.CreateCustomer(Customer);
        InsertCustLedgerEntry(Customer."No.", LibraryRandom.RandDec(100, 2), CalcDate('<CD+6Y>'), CalcDate('<CD+6Y>'));

        // [WHEN] Run "Statement" (Preview) report filtered by Customer and with End Date = 01/01/2019, "Include All Customers with a Balance" = true, "Include All Customers with Ledger Entries" = false.
        Customer.SetRange("No.", Customer."No.");
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), true, false);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementPreviewForCustomerWithIncludeLE()
    var
        Customer: Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] An error has been thrown "No data was returned for the report using the selected data filters."
        // [SCENARIO 218263] in case of SaveAs PDF REP 1316 "Standard Statement" filtered by not existing customer "No."
        Initialize();

        // [GIVEN] Report Selections setup: Usage = "C.Statement", Report ID = "Standard Statement".
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        // [GIVEN] Customer has ledger entries for 02/02/2020.
        LibrarySales.CreateCustomer(Customer);
        InsertCustLedgerEntry(Customer."No.", LibraryRandom.RandDec(100, 2), CalcDate('<CD+6Y>'), CalcDate('<CD+6Y>'));

        // [WHEN] Run "Statement" (Preview) report filtered by Customer and with End Date = 01/01/2019, "Include All Customers with a Balance" = false, "Include All Customers with Ledger Entries" = true.
        Customer.SetRange("No.", Customer."No.");
        ErrorMessages.Trap();
        asserterror RunCustomerStatementSetInclude(Customer, CustomLayoutReporting, TemporaryPath, false, true, WorkDate(), false, true);

        // [THEN] An error has been thrown: "No data was returned for the report using the selected data filters.".
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);

        // Tear Down
        InitReportSelections();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_PmtDiscTxt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Standard Sales - Invoice]
        // [SCENARIO 391271] REP 1306 "Standard Sales - Invoice" prints PmtDiscText correctly
        Initialize();

        // [GIVEN] Posted sales invoice with "Pmt. Discount Date" and "Payment Discount %"
        CreateSalesInvoice(SalesHeader, SalesLine, false);
        SalesHeader."Pmt. Discount Date" := WorkDate();
        SalesHeader."Payment Discount %" := LibraryRandom.RandIntInRange(3, 5);
        SalesHeader.Modify();

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] There is "If we receive the payment before %1, you are eligible for a %2% payment discount." in PmtDiscText
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PmtDiscText', StrSubstNo(PmtDiscTxt, WorkDate(), SalesHeader."Payment Discount %"));
    end;

    [Test]
    [HandlerFunctions('OrderReporXMLtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConf_PmtDiscTxt()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Standard Sales - Order Conf.]
        // [SCENARIO 391271] REP 1305 "Standard Sales - Order Conf." prints PmtDiscText correctly
        Initialize();

        // [GIVEN] Posted Sales Order with "Pmt. Discount Date" and "Payment Discount %"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader."Pmt. Discount Date" := WorkDate();
        SalesHeader."Payment Discount %" := LibraryRandom.RandIntInRange(3, 5);
        SalesHeader.Modify();
        Commit();
        SalesHeader.SetRecFilter();

        // [WHEN] Print the invoice using REP1305 "Standard Sales - Order Conf."
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);

        // [THEN] There is "If we receive the payment before %1, you are eligible for a %2% payment discount." in PmtDiscText
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PmtDiscText', StrSubstNo(PmtDiscTxt, WorkDate(), SalesHeader."Payment Discount %"));
    end;

    [Test]
    [HandlerFunctions('StandardQuoteReporXMLtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesQuote_PmtDiscTxt()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Standard Sales - Quote]
        // [SCENARIO 391271] REP1304 "Standard Sales - Quote" prints PmtDiscText correctly
        Initialize();

        // [GIVEN] Posted Salse Quote with "Pmt. Discount Date" and "Payment Discount %"
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesHeader."Pmt. Discount Date" := WorkDate();
        SalesHeader."Payment Discount %" := LibraryRandom.RandIntInRange(3, 5);
        SalesHeader.Modify();
        Commit();
        SalesHeader.SetRecFilter();

        // [WHEN] Print the invoice using REP1304 "Standard Sales - Quote"
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] There is "If we receive the payment before %1, you are eligible for a %2% payment discount." in PmtDiscText
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PmtDiscText', StrSubstNo(PmtDiscTxt, WorkDate(), SalesHeader."Payment Discount %"));
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    procedure PDFPrintForSeveralCustomersWithSameName()
    var
        Customer: array[3] of Record Customer;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        TestCustomReports: Codeunit "Test Custom Reports";
        CustRecRef: RecordRef;
        ReportSelectionsUsage: Enum "Report Selection Usage";
        FilesList: List of [Text];
        OutputPath: Text;
        CustomerName: Text;
        ReportName: Text;
        DateText: Text;
        i: Integer;
    begin
        // [SCENARIO 401532] Print PDF for several customers with the same Name produces several files with different names
        Initialize();
        OutputPath := GetOutputFolder();
        ReportName := LibraryUtility.GenerateGUID();
        CustomerName := LibraryUtility.GenerateGUID();
        BindSubscription(TestCustomReports);

        // [GIVEN] 3 customers with the same Name = "X"
        SetStandardStatementSelection();
        CustomLayoutReporting.SetOutputFileBaseName(ReportName);
        InitializeCustomLayoutReporting(CustomLayoutReporting, OutputPath, false);

        for i := 1 to ArrayLen(Customer) do begin
            LibrarySales.CreateCustomer(Customer[i]);
            Customer[i].Validate(Name, CopyStr(CustomerName, 1, MaxStrLen(Customer[i].Name)));
            Customer[i].Modify(true);
            CreateTwoCustomerLedgerEntries(Customer[i]."No.", 1, 1);
        end;
        Customer[1].SetFilter("No.", '%1|%2|%3', Customer[1]."No.", Customer[2]."No.", Customer[3]."No.");

        CustRecRef.Open(Database::Customer);
        CustRecRef.SetView(Customer[1].GetView());
        LibraryVariableStorage.Enqueue(GetStartDate());
        CustomLayoutReporting.InitializeData(
          ReportSelectionsUsage::"C.Statement".AsInteger(), CustRecRef, CustomerFullMod.FieldName("No."),
          Database::Customer, CustomerFullMod.FieldName("No."), true);

        // [WHEN] Run "Statement" report for 3 selected customers and print as PDF
        CustomLayoutReporting.ProcessReport();

        // [THEN] zip has been created with 3 files:
        // [THEN] "Report for X as of 2026-06-06.pdf"
        // [THEN] "Report for X as of 2026-06-06 (1).pdf"
        // [THEN] "Report for X as of 2026-06-06 (2).pdf"
        GetFilesListFromZip(FilesList, OutputPath);
        Assert.AreEqual(3, FilesList.Count(), '');

        DateText := Format(CalcDate('<CD+5Y>'), 0, 9);
        Assert.IsTrue(FilesList.Contains(StrSubstNo('%1 for %2 as of %3.pdf', ReportName, CustomerName, DateText)), '');
        Assert.IsTrue(FilesList.Contains(StrSubstNo('%1 for %2 as of %3 (1).pdf', ReportName, CustomerName, DateText)), '');
        Assert.IsTrue(FilesList.Contains(StrSubstNo('%1 for %2 as of %3 (2).pdf', ReportName, CustomerName, DateText)), '');
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoice_SaveAsXML_RPH')]
    [Scope('OnPrem')]
    procedure VerifySubTotalsOnStandardSalesInvoice_ReportTotalsWithCorrectDecimalPlaces()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 463222] Sales Invoice report does not print subtotals with correct number of decimals
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Create sales invoice with "Prices Including VAT" = false and Currency
        CreateSalesInvoiceWithCurrencyCode(SalesHeader, SalesLine, false, CurrencyCode);

        // [WHEN] Print the invoice using REP1306 "Standard Sales - Invoice"
        RunStandardSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [VERIFY] Verify: Sub Total Amount on Report Total Lines
        VerifySubTotalAmtStdSalesInvoiceReportTotalsLines(SalesLine."Line Amount")
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Custom Reports");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetInvoiceRounding(false);

        CompanyInformation.Get();
        CompanyInformation."Allow Blank Payment Info." := true;
        CompanyInformation.Modify(false);

        // Clean out existing data and set up new
        ReportLayoutSelection.DeleteAll();
        CustomReportSelection.DeleteAll();
        CustomReportLayout.DeleteAll();

        InitReportSelections();

        LibrarySales.CreateCustomer(CustomerFullMod);
        LibrarySales.CreateCustomer(CustomerPartialMod);
        LibrarySales.CreateCustomer(CustomerNoMod);
        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Sales - Quote", CustomReportLayout.Type::Word, 'Quote Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"S.Quote", REPORT::"Standard Sales - Quote",
          CustomReportLayout.Code);

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Sales - Order Conf.", CustomReportLayout.Type::Word, 'Order Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.",
          CustomReportLayout.Code);

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Sales - Invoice", CustomReportLayout.Type::Word, 'Invoice Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice",
          CustomReportLayout.Code);

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Sales - Credit Memo", CustomReportLayout.Type::Word,
          'Credit Memo Customer Full Mod');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"S.Cr.Memo",
          REPORT::"Standard Sales - Credit Memo", CustomReportLayout.Code);

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Statement", CustomReportLayout.Type::Word, StandardStatementFullModTxt);
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"C.Statement", REPORT::"Standard Statement",
          CustomReportLayout.Code);
        CustomReportSelection."Send To Email" := 'test@contoso.com';
        CustomReportSelection.Modify();

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::Statement, CustomReportLayout.Type::RDLC, StatementModTxt);
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"C.Statement", REPORT::Statement,
          CustomReportLayout.Code);

        Clear(CustomReportSelection);
        CreateCustomReportLayout(REPORT::"Standard Statement", CustomReportLayout.Type::Word, StandardStatementModTxt);
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerFullMod."No.", CustomReportSelection.Usage::"C.Statement", REPORT::"Standard Statement",
          CustomReportLayout.Code);

        CreateSalesRecord(QuoteSalesHeaderFullMod, QuoteSalesHeaderFullMod."Document Type"::Quote, CustomerFullMod);
        CreateSalesRecord(OrderSalesHeaderFullMod, QuoteSalesHeaderFullMod."Document Type"::Order, CustomerFullMod);
        CreateSalesRecord(InvoiceSalesHeaderFullMod, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerFullMod);
        CreateSalesRecord(InvoiceSalesHeaderFullModEmail, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerFullMod);
        CreateSalesRecord(CreditMemoSalesHeaderFullMod, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerFullMod);
        CreateSalesRecord(
          CreditMemoSalesHeaderFullModEmail, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerFullMod);

        LibrarySales.PostSalesDocument(InvoiceSalesHeaderFullMod, false, true);
        LibrarySales.PostSalesDocument(InvoiceSalesHeaderFullModEmail, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderFullMod, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderFullModEmail, false, true);

        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerPartialMod."No.", CustomReportSelection.Usage::"S.Quote", REPORT::"Standard Sales - Quote", '');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerPartialMod."No.", CustomReportSelection.Usage::"S.Order",
          REPORT::"Standard Sales - Order Conf.", '');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerPartialMod."No.", CustomReportSelection.Usage::"S.Invoice",
          REPORT::"Standard Sales - Invoice", '');
        AssignCustomLayoutToCustomer(
          DATABASE::Customer, CustomerPartialMod."No.", CustomReportSelection.Usage::"S.Cr.Memo",
          REPORT::"Standard Sales - Credit Memo", '');

        CreateSalesRecord(QuoteSalesHeaderParitalMod, QuoteSalesHeaderFullMod."Document Type"::Quote, CustomerPartialMod);
        CreateSalesRecord(OrderSalesHeaderPartialMod, QuoteSalesHeaderFullMod."Document Type"::Order, CustomerPartialMod);
        CreateSalesRecord(InvoiceSalesHeaderPartialMod, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerPartialMod);
        CreateSalesRecord(InvoiceSalesHeaderPartialModEmail, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerPartialMod);
        CreateSalesRecord(
          CreditMemoSalesHeaderPartialMod, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerPartialMod);
        CreateSalesRecord(
          CreditMemoSalesHeaderPartialModEmail, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerPartialMod);

        LibrarySales.PostSalesDocument(InvoiceSalesHeaderPartialMod, false, true);
        LibrarySales.PostSalesDocument(InvoiceSalesHeaderPartialModEmail, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderPartialMod, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderPartialModEmail, false, true);

        CreateSalesRecord(QuoteSalesHeaderNoMod, QuoteSalesHeaderFullMod."Document Type"::Quote, CustomerNoMod);
        CreateSalesRecord(OrderSalesHeaderNoMod, QuoteSalesHeaderFullMod."Document Type"::Order, CustomerNoMod);
        CreateSalesRecord(InvoiceSalesHeaderNoMod, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerNoMod);
        CreateSalesRecord(InvoiceSalesHeaderNoModEmail, QuoteSalesHeaderFullMod."Document Type"::Invoice, CustomerNoMod);
        CreateSalesRecord(CreditMemoSalesHeaderNoMod, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerNoMod);
        CreateSalesRecord(CreditMemoSalesHeaderNoModEmail, QuoteSalesHeaderFullMod."Document Type"::"Credit Memo", CustomerNoMod);

        LibrarySales.PostSalesDocument(InvoiceSalesHeaderNoMod, false, true);
        LibrarySales.PostSalesDocument(InvoiceSalesHeaderNoModEmail, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderNoMod, false, true);
        LibrarySales.PostSalesDocument(CreditMemoSalesHeaderNoModEmail, false, true);

        Commit();

        IsInitialized := true;
    end;

    local procedure InitReportSelections()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        LibraryERM.SetupReportSelection("Report Selection Usage"::"C.Statement", REPORT::"Standard Statement");

        ReportSelections.Init();
        ReportSelections.Usage := "Report Selection Usage"::"C.Statement";
        ReportSelections.Sequence := '2';
        ReportSelections."Report ID" := REPORT::Statement;
        ReportSelections."Report Caption" := 'Statement';
        ReportSelections.Insert();
    end;

    local procedure AddNextCustomerReportSelection(var CustomerReportSelections: TestPage "Customer Report Selections"; Usage: Option; ReportId: Integer)
    begin
        CustomerReportSelections.Usage2.SetValue(Usage);
        CustomerReportSelections.ReportID.SetValue(ReportId);
        CustomerReportSelections.Next();
    end;

    local procedure AddNewCustomerReportSelection(var CustomerReportSelections: TestPage "Customer Report Selections"; Usage: Option; ReportId: Integer)
    begin
        CustomerReportSelections.New();
        CustomerReportSelections.ReportID.SetValue(ReportId);
        CustomerReportSelections.Usage2.SetValue(Usage);
    end;

    local procedure CreateCustomReportLayout(ReportID: Integer; LayoutType: Enum "Custom Report Layout Type"; Description: Text[80])
    begin
        CustomReportLayout.Init();
        CustomReportLayout.InitBuiltInLayout(ReportID, LayoutType.AsInteger());
        CustomReportLayout.SetFilter(Code, StrSubstNo('%1-*', ReportID));
        CustomReportLayout.FindLast();
        CustomReportLayout.Description := Description;
        CustomReportLayout.Modify();
    end;

    local procedure CreateSalesRecord(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; Customer: Record Customer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1.0);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PricesIncludingVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateTwoCustomerLedgerEntries(CustomerNo: Code[20]; Amount1: Decimal; Amount2: Decimal)
    begin
        InsertCustLedgerEntry(
          CustomerNo, Amount1, CalcDate('<-CM-1M+1W>', GetDate()), CalcDate('<-CM-1M+3W>', GetDate()));
        InsertCustLedgerEntry(
          CustomerNo, Amount2, CalcDate('<-CM-1M+3W>', GetDate()), GetDate());
    end;

    local procedure PrintCustomReportSelectionFullMod(SalesHeader: Record "Sales Header"; ExpectedReportID: Integer; ReportUsage: Enum "Report Selection Usage")
    var
        CustomReportID: Integer;
    begin
        Clear(CustomReportSelection);
        SalesHeader.SetRecFilter();
        CustomReportID := CustomReportSelectionPrint(SalesHeader, ReportUsage, false, true, SalesHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(ExpectedReportID, CustomReportID, 'Print fully modified customer failed');
    end;

    local procedure PrintCustomReportSelectionPartMod(SalesHeader: Record "Sales Header"; ExpectedReportID: Integer; ReportUsage: Enum "Report Selection Usage")
    var
        CustomReportID: Integer;
    begin
        Clear(CustomReportSelection);
        SalesHeader.SetRecFilter();
        CustomReportID := CustomReportSelectionPrint(SalesHeader, ReportUsage, false, true, SalesHeader.FieldNo("Bill-to Customer No."));
        Assert.AreEqual(ExpectedReportID, CustomReportID, 'Print partially modified customer failed');
    end;

    local procedure PrintCustomReportSelectionNoMod(DocumentRecVar: Variant; ExpectedReportID: Integer; AccountNoFieldNo: Integer; ReportUsage: Enum "Report Selection Usage")
    begin
        Clear(CustomReportSelection);
        asserterror CustomReportSelectionPrint(DocumentRecVar, ReportUsage, false, true, AccountNoFieldNo);
        Assert.AreEqual(ExpectedReportID, 0, 'Print not modified customer failed');
    end;

    local procedure InsertCustLedgerEntry(CustomerNo: Code[20]; EntryAmount: Decimal; PostingDate: Date; DueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgerEntry do begin
            Init();
            "Entry No." :=
              LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            "Customer No." := CustomerNo;
            "Document No." := LibraryUtility.GenerateGUID();
            "Document Type" := "Document Type"::Invoice;
            "Posting Date" := PostingDate;
            "Due Date" := DueDate;
            Amount := EntryAmount;
            "Amount (LCY)" := EntryAmount;
            Open := true;
            Insert();
        end;
        InsertDetailedCustLedgerEntry(
          CustLedgerEntry."Entry No.", CustomerNo, CustLedgerEntry."Document No.", EntryAmount, PostingDate);
    end;

    local procedure InsertDetailedCustLedgerEntry(CustLedgerEntryNo: Integer; CustomerNo: Code[20]; DocumentNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            Init();
            "Entry No." :=
              LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Customer No." := CustomerNo;
            "Document No." := DocumentNo;
            "Document Type" := "Document Type"::Invoice;
            "Cust. Ledger Entry No." := CustLedgerEntryNo;
            Amount := EntryAmount;
            "Amount (LCY)" := EntryAmount;
            "Posting Date" := PostingDate;
            "Ledger Entry Amount" := true;
            Insert();
        end;
    end;

    local procedure CountReportSelectionEntriesByUsage(var CustomReportSelection: Record "Custom Report Selection"; UsageValue: Enum "Report Selection Usage"; RecordCount: Integer)
    begin
        CustomReportSelection.SetRange(Usage, UsageValue);
        Assert.RecordCount(CustomReportSelection, RecordCount);
    end;

    local procedure AssignCustomLayoutToCustomer(SourceType: Integer; SourceNo: Code[20]; Usage: Enum "Report Selection Usage"; ReportID: Integer; CustomReportLayoutCode: Code[20])
    begin
        CustomReportSelection.Init();
        CustomReportSelection."Source Type" := SourceType;
        CustomReportSelection."Source No." := SourceNo;
        CustomReportSelection.Usage := Usage;
        CustomReportSelection."Report ID" := ReportID;
        CustomReportSelection."Custom Report Layout Code" := CustomReportLayoutCode;
        CustomReportSelection.Insert();
        Commit();
    end;

    local procedure SetStandardStatementSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        // Sequence 1 is Standard statement, set other items to a different usage to exclude them from statement print runs
        SetAllSelectionUsages("Report Selection Usage"::Reminder);

        ReportSelections.Get("Report Selection Usage"::Reminder, '1');
        ReportSelections.Rename("Report Selection Usage"::"C.Statement", '1');
        Commit();
    end;

    local procedure SetStatementSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        // Sequence 2 is Statement, set other items to a different usage to exclude them from statement print runs
        SetAllSelectionUsages("Report Selection Usage"::Reminder);

        ReportSelections.Get("Report Selection Usage"::Reminder, '2');
        ReportSelections.Rename("Report Selection Usage"::"C.Statement", '2');
        Commit();
    end;

    local procedure SetAllSelectionUsages(ReportSelectionUsage: Enum "Report Selection Usage")
    var
        ReportSelections: Record "Report Selections";
    begin
        if ReportSelections.FindSet(true) then
            repeat
                ReportSelections.Rename(ReportSelectionUsage, ReportSelections.Sequence);
            until ReportSelections.Next() = 0;
    end;

    local procedure SetSalesInvoiceDiscount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(
          Round(SalesLine.Amount / LibraryRandom.RandIntInRange(5, 10)), SalesHeader);
        SalesLine.Find();
    end;

    local procedure CleanAndCreateDirectory(Directory: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.ServerRemoveDirectory(Directory, true);
        FileManagement.ServerCreateDirectory(Directory);
    end;

    [Scope('OnPrem')]
    procedure StandardStatementSetRequestOptions(var RequestPage: TestRequestPage "Standard Statement")
    begin
        RequestPage."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);
    end;

    local procedure InitializeCustomLayoutReporting(var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SaveSubpath: Text; SuppressOutput: Boolean)
    begin
        CustomLayoutReporting.SetOutputSupression(SuppressOutput);
        if SaveSubpath <> TemporaryPath then
            CleanAndCreateDirectory(SaveSubpath);
        CustomLayoutReporting.SetSavePath(SaveSubpath);
    end;

    local procedure RunCustStatement(var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; var Customer: Record Customer; SameIterator: Boolean)
    var
        CustRecRef: RecordRef;
    begin
        CustRecRef.GetTable(Customer);
        CustRecRef.SetView(Customer.GetView());
        CustomLayoutReporting.ProcessReportData(
          "Report Selection Usage"::"C.Statement",
          CustRecRef,
          Customer.FieldName("No."),
          DATABASE::Customer,
          Customer.FieldName("No."),
          SameIterator);
    end;

    local procedure RunStandardSalesInvoice(SalesInvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", SalesInvoiceNo);
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
    end;

    local procedure RunStatementReport(var Customer: Record Customer; var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SavePath: Text; SuppressOutput: Boolean; UseSameIterator: Boolean)
    begin
        SetStatementSelection();
        RunCustomerStatement(Customer, CustomLayoutReporting, SavePath, SuppressOutput, UseSameIterator, GetStartDate());
    end;

    local procedure RunStatementReportWithStandardSelection(var Customer: Record Customer; var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SavePath: Text; SuppressOutput: Boolean; UseSameIterator: Boolean)
    begin
        SetStandardStatementSelection();
        RunCustomerStatement(Customer, CustomLayoutReporting, SavePath, SuppressOutput, UseSameIterator, GetStartDate());
    end;

    local procedure RunStatementReportWithAllSelection(var Customer: Record Customer; var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SavePath: Text; SuppressOutput: Boolean; UseSameIterator: Boolean)
    begin
        SetAllSelectionUsages("Report Selection Usage"::"C.Statement");
        RunCustomerStatement(Customer, CustomLayoutReporting, SavePath, SuppressOutput, UseSameIterator, GetStartDate());
    end;

    local procedure RunCustomerStatement(var Customer: Record Customer; var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SavePath: Text; SuppressOutput: Boolean; UseSameIterator: Boolean; StartDate: Date)
    begin
        InitializeCustomLayoutReporting(CustomLayoutReporting, SavePath, SuppressOutput);

        // Customer table is still active, so we need to commit before running the statement report to allow request
        // page handlers to work as expected.
        Commit();
        LibraryVariableStorage.Enqueue(StartDate);
        RunCustStatement(CustomLayoutReporting, Customer, UseSameIterator);
    end;

    local procedure RunCustomerStatementSetInclude(var Customer: Record Customer; var CustomLayoutReporting: Codeunit "Custom Layout Reporting"; SavePath: Text; SuppressOutput: Boolean; UseSameIterator: Boolean; StartDate: Date; IncludeAllCustomerswithBalance: Boolean; IncludeAllCustomerswithLE: Boolean)
    begin
        InitializeCustomLayoutReporting(CustomLayoutReporting, SavePath, SuppressOutput);
        Commit();
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(IncludeAllCustomerswithBalance);
        LibraryVariableStorage.Enqueue(IncludeAllCustomerswithLE);
        RunCustStatement(CustomLayoutReporting, Customer, UseSameIterator);
    end;

    local procedure GetNextTempFolder(): Text
    begin
        TempFolderIndex := TempFolderIndex + 1;
        exit(StrSubstNo('%1', TempFolderIndex));
    end;

    local procedure GetOutputFolder(): Text
    var
        Path: Text;
    begin
        Path := StrSubstNo('%1\%2', TemporaryPath, GetNextTempFolder());
        if Exists(Path) then
            Erase(Path);
        exit(Path);
    end;

    local procedure GetDate(): Date
    begin
        exit(CalcDate('<CD>'));
    end;

    local procedure GetStartDate(): Date
    begin
        exit(CalcDate('<CD-1Y>'));
    end;

    local procedure GetFilesListFromZip(var FilesList: List of [Text]; OutputPath: Text)
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ZipFile: File;
        ZipInStream: InStream;
        ZipPath: Text;
    begin
        ZipPath := FileManagement.CombinePath(OutputPath, 'AllReports.zip');
        Assert.IsTrue(Exists(ZipPath), ExpectedFilesErr);
        ZipFile.Open(ZipPath);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(FilesList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
        if Exists(ZipPath) then
            Erase(ZipPath);
    end;

    local procedure CustomReportSelectionPrint(Document: Variant; ReportUsage: Enum "Report Selection Usage"; Email: Boolean; ShowRequestPage: Boolean; CustomerNoFieldNo: Integer): Integer
    var
        ReportSelections: Record "Report Selections";
        TempReportSelections: Record "Report Selections" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        RecRef.GetTable(Document);
        FieldRef := RecRef.Field(CustomerNoFieldNo);
        CustomerNo := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(CustomerNo));

        RecRef.SetRecFilter();
        RecRef.SetTable(Document);
        if Email then begin
            ReportSelections.FindEmailAttachmentUsageForCust(ReportUsage, CustomerNo, TempReportSelections);
            ReportSelections.SendEmailToCust(Usage, Document, '', '', true, CustomerNo);
        end else begin
            ReportSelections.FindReportUsageForCust(ReportUsage, CustomerNo, TempReportSelections);
            ReportSelections.PrintWithDialogForCust(ReportUsage, Document, ShowRequestPage, CustomerNoFieldNo);
        end;

        exit(TempReportSelections."Report ID");
    end;

    local procedure AssertErrorMessageOnPage(var ErrorMessages: TestPage "Error Messages"; HasRecord: Boolean; ExpectedErrorMessage: Text)
    begin
        Assert.IsTrue(HasRecord, 'Error Messages page does not have record');
        Assert.ExpectedMessage(ExpectedErrorMessage, ErrorMessages.Description.Value);
    end;

    local procedure AssertNoMoreErrorMessageOnPage(var ErrorMessages: TestPage "Error Messages")
    begin
        if ErrorMessages.Next() then
            Assert.Fail(StrSubstNo('Unexpected error: %1', ErrorMessages.Description.Value));
    end;

    local procedure VerifyFormattedTextValuesBlank(FormattedQty: Text; FormattedUnitPriceOrCost: Text; FormattedVATPct: Text; FormattedLineAmt: Text)
    begin
        Assert.AreEqual('', FormattedQty, '');
        Assert.AreEqual('', FormattedUnitPriceOrCost, '');
        Assert.AreEqual('', FormattedVATPct, '');
        Assert.AreEqual('', FormattedLineAmt, '');
    end;

    local procedure VerifyStdSalesInvoiceReportTotalsLines(SalesLine: Record "Sales Line"; SubtotalDiscountText: Text; SubtotalDiscountValue: Decimal)
    var
        Row: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Row := LibraryReportDataset.FindRow(DescriptionReportTotalsLineTxt, SubtotalTxt) + 1;
        VerifyStdSalesInvoiceReportTotalsLine(Row, SubtotalTxt, SalesLine."Line Amount");
        VerifyStdSalesInvoiceReportTotalsLine(Row + 1, InvoiceDiscountTxt, -SalesLine."Inv. Discount Amount");
        VerifyStdSalesInvoiceReportTotalsLine(Row + 2, SubtotalDiscountText, SubtotalDiscountValue);
        VerifyStdSalesInvoiceReportTotalsLine(
          Row + 3, StrSubstNo('%1% VAT', SalesLine."VAT %"),
          SalesLine."Amount Including VAT" - Round(SalesLine."Amount Including VAT" / (1 + SalesLine."VAT %" / 100)));
    end;

    local procedure VerifyStdSalesInvoiceReportTotalsLine(RowNo: Integer; ExpectedDescription: Text; ExpectedValue: Decimal)
    begin
        LibraryReportDataset.MoveToRow(RowNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(DescriptionReportTotalsLineTxt, ExpectedDescription);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_ReportTotalsLine', ExpectedValue);
    end;

    local procedure SaveStandardStatementAsXML(var Customer: Record Customer; var OutputPath: Text; DateChoice: Option; DateBegin: Date; DateEnd: Date)
    var
        StandardStatement: Report "Standard Statement";
        FileManagement: Codeunit "File Management";
    begin
        OutputPath := FileManagement.CombinePath(TemporaryPath, LibraryUtility.GenerateGUID() + '.xml');
        Clear(StandardStatement);
        StandardStatement.SetTableView(Customer);
        StandardStatement.InitializeRequest(
          true, false, true, false, true, true, '1M+CM', DateChoice, true, DateBegin, DateEnd);
        StandardStatement.SaveAsXml(OutputPath);
    end;

    local procedure SaveStatementAsXML(var Customer: Record Customer; DateChoice: Option; DateBegin: Date; DateEnd: Date)
    var
        Statement: Report Statement;
    begin
        Clear(Statement);
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          true, false, true, false, true, true, '1M+CM', DateChoice, true, DateBegin, DateEnd);
        Statement.Run();
    end;

    local procedure VerifyStandardStatementAging(OutputPath: Text; VerifyAmount: Decimal; ColumnNo: Integer)
    var
        XMLPath: Text;
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(true);
        LibraryXPathXMLReader.Initialize(OutputPath, '');
        XMLPath :=
          '//ReportDataSet/DataItems/DataItem/DataItems/DataItem/DataItems/DataItem[2]/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XMLPath, Format(VerifyAmount), ColumnNo);
    end;

    local procedure VerifyStandardStatementOverdue(OutputPath: Text; VerifyAmount: Decimal; ColumnNo: Integer)
    var
        XMLPath: Text;
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(true);
        LibraryXPathXMLReader.Initialize(OutputPath, '');
        XMLPath :=
          '//ReportDataSet/DataItems/DataItem/DataItems/DataItem/DataItems/DataItem[1]/DataItems/DataItem[3]/DataItems/DataItem[3]/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XMLPath, Format(VerifyAmount), ColumnNo);
    end;

    local procedure VerifyStatementAging(VerifyAmount: Decimal; RowNo: Integer)
    begin
        LibraryReportDataset.AssertElementTagWithValueExists(
          'AgingBandBufCol' + Format(RowNo) + 'Amt', Format(VerifyAmount, 0, 2));
    end;

    local procedure VerifyStatementOverdue(VerifyAmount: Decimal)
    begin
        LibraryReportDataset.AssertElementTagWithValueExists(
          'RemainAmt_CustLedgEntry2', Format(VerifyAmount, 0, 2));
    end;

    local procedure CreateCurrencyWithDecimalPlaces(): Code[10]
    var
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Currency.Get(CurrencyCode);
        Currency.Validate("Amount Decimal Places", '3:3');
        Currency.Validate("Amount Rounding Precision", 0.001);
        Currency.Validate("Invoice Rounding Precision", 0.001);
        Currency.Modify(true);
        exit(CurrencyCode);
    end;

    local procedure CreateSalesInvoiceWithCurrencyCode(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        PricesIncludingVAT: Boolean;
        CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            LibraryInventory.CreateItemNo(),
            1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 3));
        SalesLine.Modify(true);
    end;

    local procedure VerifySubTotalAmtStdSalesInvoiceReportTotalsLines(SubTotalAmt: Decimal)
    var
        Row: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Row := LibraryReportDataset.FindRow(DescriptionReportTotalsLineTxt, SubtotalTxt) + 1;
        VerifyStdSalesInvoiceReportTotalsLine(Row, SubtotalTxt, SubTotalAmt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomReportLayoutHandler(var CustomReportLayouts: TestPage "Custom Report Layouts")
    var
        ExpectedCustomLayoutDescription: Text;
        ExpectedCustomLayoutReportID: Text;
        RowFound: Boolean;
    begin
        ExpectedCustomLayoutReportID := LibraryVariableStorage.DequeueText();
        ExpectedCustomLayoutDescription := LibraryVariableStorage.DequeueText();

        CustomReportLayouts.Last();

        repeat
            if (CustomReportLayouts.Description.Value = ExpectedCustomLayoutDescription) and
               (CustomReportLayouts."Report ID".Value = ExpectedCustomLayoutReportID)
            then
                RowFound := true;
        until (not CustomReportLayouts.Previous()) or RowFound;

        CustomReportLayouts.Next();
        Assert.IsTrue(RowFound, StrSubstNo('Could not find %1 on Custom Report Layouts page', ExpectedCustomLayoutDescription));
        CustomReportLayouts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardQuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderReportRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvoiceReportRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoice_SaveAsXML_RPH(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreditMemoReportRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementPrintHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.IncludeAllCustomerswithBalance.SetValue(false);
        RequestPage.ReportOutput.SetValue('Print');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementDefaultLayoutHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.IncludeAllCustomerswithBalance.SetValue(false);
        RequestPage.ReportOutput.SetValue('Preview');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementEmailHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.ReportOutput.SetValue('Email');
        RequestPage.PrintMissingAddresses.SetValue(false);
        RequestPage.ShowOverdueEntries.SetValue(false);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementEmailPrintRemainingHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.ReportOutput.SetValue('Email');
        RequestPage.PrintMissingAddresses.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(false);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementPDFHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('PDF');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementWordHandler(var RequestPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementSetRequestOptions(RequestPage);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('Word');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementXMLHandler(var RequestPage: TestRequestPage Statement)
    begin
        // This page should look almost identical to the mini statement page
        RequestPage."Start Date".SetValue(CalcDate('<CD-1Y>'));
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('XML');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementXMLToFileHandler(var Statement: TestRequestPage Statement)
    begin
        Statement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementExcelHandler(var RequestPage: TestRequestPage Statement)
    begin
        // This page should look almost identical to the mini statement page
        RequestPage."Start Date".SetValue(CalcDate('<CD-1Y>'));
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('Excel');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementPrintHandler(var RequestPage: TestRequestPage Statement)
    begin
        // This page should look almost identical to the mini statement page
        RequestPage."Start Date".SetValue(CalcDate('<CD-1Y>'));
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('Print');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementPDFHandler(var RequestPage: TestRequestPage Statement)
    begin
        // This page should look almost identical to the mini statement page
        RequestPage."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('PDF');
        RequestPage.Customer.SetFilter("No.", ''); // reset saved page filter values
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementCancelHandler(var RequestPage: TestRequestPage Statement)
    begin
        // This page should look almost identical to the mini statement page
        RequestPage."Start Date".SetValue(CalcDate('<CD-1Y>'));
        RequestPage."End Date".SetValue(CalcDate('<CD+5Y>'));
        RequestPage.IncludeAgingBand.SetValue(true);
        RequestPage.ShowOverdueEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithLE.SetValue(true);
        RequestPage.IncludeReversedEntries.SetValue(true);
        RequestPage.IncludeUnappliedEntries.SetValue(true);
        RequestPage.IncludeAllCustomerswithBalance.SetValue(true);

        RequestPage.IncludeUnappliedEntries.SetValue(false);
        RequestPage.ReportOutput.SetValue('PDF');
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCancelRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.Cancel().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure StandardStatementDirectRunReportHandler(var StandardStatement: Report "Standard Statement")
    begin
        StandardStatement.InitializeRequest(true, true, true, true, true, true, '30D', 0, true, CalcDate('<CD-1Y>'), CalcDate('<CD+5Y>'));
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure StandardStatementDirectRunReportHandlerAllOff(var StandardStatement: Report "Standard Statement")
    begin
        StandardStatement.InitializeRequest(false, false, false, false, false, false, '0D', 0, false, CalcDate('<CD-1Y>'), CalcDate('<CD+5Y>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerReportSelectionAllUsageTypesAddHandler(var CustomerReportSelections: TestPage "Customer Report Selections")
    begin
        AddNextCustomerReportSelection(CustomerReportSelections, Usage::Quote, REPORT::"G/L Register");
        AddNextCustomerReportSelection(CustomerReportSelections, Usage::Invoice, REPORT::"G/L Register");
        AddNextCustomerReportSelection(CustomerReportSelections, Usage::"Confirmation Order", REPORT::"G/L Register");
        AddNextCustomerReportSelection(CustomerReportSelections, Usage::"Credit Memo", REPORT::"G/L Register");
        CustomerReportSelections.ReportID.SetValue(REPORT::"Detail Trial Balance");
        CustomerReportSelections.Next();
        AddNextCustomerReportSelection(CustomerReportSelections, Usage::"Customer Statement", REPORT::"G/L Register");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerReportSelectionInsertFromRepordIdHandler(var CustomerReportSelections: TestPage "Customer Report Selections")
    begin
        CustomerReportSelections.New();
        CustomerReportSelections.Usage2.SetValue(Usage::Quote);
        CustomerReportSelections.ReportID.SetValue(REPORT::"G/L Register");
        AddNewCustomerReportSelection(CustomerReportSelections, Usage::Invoice, REPORT::"G/L Register");
        AddNewCustomerReportSelection(CustomerReportSelections, Usage::"Credit Memo", REPORT::"G/L Register");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerReportSelectionHandler(var CustomerReportSelections: TestPage "Customer Report Selections")
    var
        ExpectedCustomReportLayout: Record "Custom Report Layout";
    begin
        ExpectedCustomReportLayout.Get(LibraryVariableStorage.DequeueText());

        CustomerReportSelections.New();
        CustomerReportSelections.Usage2.SetValue(2);
        CustomerReportSelections.ReportID.SetValue(REPORT::"Standard Sales - Invoice");

        LibraryVariableStorage.Enqueue(ExpectedCustomReportLayout."Report ID");
        LibraryVariableStorage.Enqueue(ExpectedCustomReportLayout.Description);
        CustomerReportSelections."Custom Report Description".Lookup();

        CustomerReportSelections.OK().Invoke();

        CustomReportSelection.SetCurrentKey("Source Type", "Source No.", Usage, Sequence);
        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", CustomerFullMod."No.");
        CustomReportSelection.FindFirst();

        Assert.AreEqual(
          ExpectedCustomReportLayout.Code, CustomReportSelection."Custom Report Layout Code",
          'Incorrect Value in Customer Report Selections');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardQuoteReporXMLtRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderReporXMLtRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnIsTestMode(var TestMode: Boolean)
    begin
        TestMode := true
    end;
}

