codeunit 134421 "Report Selections Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Report Selection]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CustomMessageTypeTxt: Text;
        FromEmailBodyTemplateTxt: Text;
        Initialized: Boolean;
        TemplateIdentificationTxt: Label 'a';
        CustomerEmailTxt: Label 'Customer@contoso.com';
        CustomLayoutEmailTxt: Label 'CustomLayout@contoso.com';
        WrongEmailAddressErr: Label 'Email Address is wrong on Send Email Dialog';
        NoSalesInvHdrTok: Label 'No_SalesInvHdr';
        DocumentNoTok: Label 'DocumentNo';
        ReportIDMustHaveValueErr: Label 'Report ID must have a value';
        NoOutputErr: Label 'No data exists for the specified report filters.';
        EmailAddressErr: Label 'Destination email address does not match expected address.';
        StatementTitlePdfTxt: Label 'Statement for %1 as of %2.pdf';

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintEmailTemplateDefined()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        // Setup
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);
        Commit();
        // Exercise
        PostedSalesInvoice.Print.Invoke;

        // Verify
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTok, PostedSalesInvoice."No.".Value);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TesteEmailNoBodyNoAttachmentRaisesError()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize;

        OpenNewPostedSalesInvoice(PostedSalesInvoice);
        SetupReportSelections(false, false);

        // Exercise
        asserterror PostedSalesInvoice.Email.Invoke;

        // Verify
        Assert.ExpectedError('email body or attachment');
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAttachmentOnly()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        // Setup
        Initialize;

        UseForAttachment := true;
        UseForBody := false;
        SetupReportSelections(UseForAttachment, UseForBody);

        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(CustomMessageTypeTxt, '', PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestEmailBodyOnly()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize;

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := false;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAttachmentAndBody()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize;

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := true;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailAttachment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        SetupReportSelections(false, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        UpdateCustomReportSelections(SalesInvoiceHeader."Sell-to Customer No.", true, false, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(CustomMessageTypeTxt, '', PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailBody()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        SetupReportSelections(false, false);
        UpdateCustomReportSelections(SalesInvoiceHeader."Bill-to Customer No.", false, true, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailAttachmentAndBody()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        // Setup
        SetupReportSelections(false, false);

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        UpdateCustomReportSelections(SalesInvoiceHeader."Bill-to Customer No.", true, true, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('TestChangingTypeEMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestChangingMessageType()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize;

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := true;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);

        // Exercise
        PostedSalesInvoice.Email.Invoke;

        // Verify is within handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHTMLEmailBodyLoad()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        FileName: Text[250];
        DummyEmailAddress: Text[250];
    begin
        // Validates that EmailItem loads the body from the HTML file
        Initialize;

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetupReportSelections(true, true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetEmailBody(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", DummyEmailAddress);
        GetEmailItem(TempEmailItem, TempEmailItem."Message Type"::"From Email Body Template", FileName, false);

        // Verify
        Assert.IsTrue(TempEmailItem.GetBodyText <> '', 'Expected text in the body of the EmailItem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailAddressSelectionDefaultLayout()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        FileManagement: Codeunit "File Management";
        FileName: Text[250];
        EmailAddress: Text[80];
    begin
        // Validates that EmailItem gathers the customer's email address when one is not defined in the custom layouts
        Initialize;

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetupReportSelections(true, true);

        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."E-Mail" := CustomerEmailTxt;
        Customer.Modify(true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetEmailBody(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", EmailAddress);

        // Verify
        Assert.IsTrue(
          EmailAddress = CustomerEmailTxt, StrSubstNo('Destination email address does not match expected address %1', CustomerEmailTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailAddressSelectionCustomLayout()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FileManagement: Codeunit "File Management";
        FileName: Text[250];
        EmailAddress: Text[80];
    begin
        // Validates that EmailItem gathers the custom layout email address when one is defined.
        Initialize;

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetUpCustomEmail(SalesInvoiceHeader, CustomLayoutEmailTxt, true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetEmailBody(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", EmailAddress);

        // Verify
        Assert.IsTrue(
          EmailAddress = CustomLayoutEmailTxt,
          StrSubstNo('Destination email address does not match expected address %1', CustomLayoutEmailTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailAddressSelectionCustomAddressNoLayout()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FileManagement: Codeunit "File Management";
        FileName: Text[250];
        EmailAddress: Text[80];
    begin
        // Validates that the email address in the dialog is from the Customer when set in a custom report selection
        // and when the custom report selection does not specify the email body.
        Initialize;

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetUpCustomEmail(SalesInvoiceHeader, CustomLayoutEmailTxt, false);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetEmailBody(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", EmailAddress);

        // Verify
        Assert.IsTrue(
          EmailAddress = CustomLayoutEmailTxt,
          StrSubstNo('Destination email address does not match expected address %1', CustomLayoutEmailTxt));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintEmailShipAgentAndTrackingNo()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 171020] Susan will be able to view the Package Tracking No. and Shipping Agent Code on sales invoices
        Initialize;

        // [GIVEN] Sales Invoice is Posted with Package Tracking No and Shipping Agent Code
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // [WHEN] Sales Invoice report is printed
        PostedSalesInvoice.Print.Invoke;

        // [THEN] Shipping Agent and Package Tracking No is verified on the Report
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('ShippingAgentCode', PostedSalesInvoice."Shipping Agent Code".Value);
        LibraryReportDataset.AssertElementWithValueExists('PackageTrackingNo', PostedSalesInvoice."Package Tracking No.".Value);

        LibraryVariableStorage.AssertEmpty;
    end;

    [HandlerFunctions('ReportSelectionPrintSelectSecondHandler,InvoicePrintHandler')]
    [Scope('OnPrem')]
    procedure TestPrintWithSelections()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Validates that printing with multiple report selections respects the user's selection.
        Initialize;

        // Setup
        CreateSecondaryReportSelection;
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        Commit();

        // Invoke and verify that the appropriate handler executes.
        ReportSelections.PrintWithGUIYesNo(
          ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, true, SalesInvoiceHeader.FieldNo("Sell-to Customer No."));
    end;

    [Test]
    [HandlerFunctions('EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteSendByEmailWhenArchivingIsOn()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentPrint: Codeunit "Document-Print";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Quote] [Archive] [UI]
        // [SCENARIO 218547] One entry per Send by Email press in Sales Quote Archives and in Interaction Log Entries
        Initialize;
        LibrarySales.SetArchiveQuoteAlways;

        // [GIVEN] New Sales Quote and Archiving is on
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibrarySales.SetArchiveOrders(true);

        // [WHEN] EmailSalesHeader is called
        SalesHeader.SetRecFilter;
        DocumentPrint.EmailSalesHeader(SalesHeader);

        // [THEN] One entry appears in Sales Quote Archives and one entry appears in Interaction Log Entries
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.RecordCount(SalesHeaderArchive, 1);
        InteractionLogEntry.SetRange("Contact No.", SalesHeader."Bill-to Contact No.");
        Assert.RecordCount(InteractionLogEntry, 1);

        LibraryVariableStorage.Clear;
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,TestAddressEMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendorWithOrderAddress()
    var
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Email] [Purchase] [Order Address]
        // [SCENARIO 235250] The Email Address from the Order Address is used for the Send function for an Email from a Purchase Order.
        Initialize;
        SetupReportSelectionsVendor(true, true);
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Vendor "V" with "E-mail" = "v@a.com"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateRandomEmail);
        Vendor.Modify(true);

        // [GIVEN] Order address "OA" for "V" with "E-mail" = "oa@a.com"
        LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");
        OrderAddress.Validate("E-Mail", LibraryUtility.GenerateRandomEmail);
        OrderAddress.Modify(true);

        // [GIVEN] Purchase order "PO" for "V" with "Order Address Code" = "OA"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", '', 0, '', 0D);
        PurchaseHeader.Validate("Order Address Code", OrderAddress.Code);
        PurchaseHeader.Modify(true);

        // [WHEN] Send "PO" by E-mail
        PurchaseHeader.SetRecFilter;
        PurchaseHeader.SendRecords;

        // [THEN] Email Address on Email Dialog Page is equal to "oa@a.com"
        Assert.AreEqual(OrderAddress."E-Mail", LibraryVariableStorage.DequeueText, WrongEmailAddressErr);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBodyCustomer()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        BindSubscription(MailManagement);
        Assert.IsTrue(MailManagement.IsHandlingGetEmailBodyCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBodyVendor()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        BindSubscription(MailManagement);
        Assert.IsTrue(MailManagement.IsHandlingGetEmailBodyVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBodyCustomerFalse()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        Assert.IsFalse(MailManagement.IsHandlingGetEmailBodyCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBodyVendorFalse()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        Assert.IsFalse(MailManagement.IsHandlingGetEmailBodyVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBody()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        BindSubscription(MailManagement);
        Assert.IsTrue(MailManagement.IsHandlingGetEmailBody, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagemetIsHandlingGetEmailBodyFalse()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        Assert.IsFalse(MailManagement.IsHandlingGetEmailBody, '');
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestBatchPrintWithMixedLayout()
    var
        SalesInvoiceHeader: array[3] of Record "Sales Invoice Header";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [Sales] [Invoice] [Report] [Print]
        // [SCENARIO 263088] System prints multiple documents with different layout setup.

        Initialize;

        // [GIVEN] Report selection where Usage = "S.Invoice" and "Report ID" = 1306 ("Standard Sales - Invoice")
        SetupReportSelections(false, false);

        // [GIVEN] Customers "A", "B" and "C"
        // [GIVEN] Posted sales invoice "InvoiceA" for "A"
        CreateAndPostSalesInvoice(SalesInvoiceHeader[1]);
        // [GIVEN] Posted sales invoice "InvoiceB" for "B"
        CreateAndPostSalesInvoice(SalesInvoiceHeader[2]);
        // [GIVEN] Posted sales invoice "InvoiceC" for "C"
        CreateAndPostSalesInvoice(SalesInvoiceHeader[3]);

        // [GIVEN] Custom Report Selection where Usage = "Inv1" and "Report ID" = 124 ("Sales Invoice Nos."), "Source No." = "B"
        InsertCustomReportSelectionCustomer(
          CustomReportSelection, SalesInvoiceHeader[2]."Sell-to Customer No.",
          GetSalesInvoiceNosReportID, false, false, '', '', CustomReportSelection.Usage::Inv1);
        // [GIVEN] Custom Report Selection where Usage = "S.Invoice" and "Report ID" = 206 ("Sales - Invoice"), "Source No." = "A"
        InsertCustomReportSelectionCustomer(
          CustomReportSelection, SalesInvoiceHeader[1]."Sell-to Customer No.",
          GetSalesInvoiceReportID, false, false, '', '', CustomReportSelection.Usage::"S.Invoice");
        Commit();

        // [WHEN] Send to print "InvoiceA", "InvoiceB" and "InvoiceC" within single selection
        SalesInvoiceHeader[1].SetFilter(
          "No.", '%1|%2|%3', SalesInvoiceHeader[1]."No.", SalesInvoiceHeader[2]."No.", SalesInvoiceHeader[3]."No.");
        SalesInvoiceHeader[1].PrintRecords(true);

        // [THEN] "Sales - Invoice" report prints "InvoiceA" only
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(NoSalesInvHdrTok, SalesInvoiceHeader[1]."No.");
        LibraryReportDataset.AssertElementWithValueNotExist(NoSalesInvHdrTok, SalesInvoiceHeader[2]."No.");
        LibraryReportDataset.AssertElementWithValueNotExist(NoSalesInvHdrTok, SalesInvoiceHeader[3]."No.");

        // [THEN] System prints the only single document (SETSELECTIONFILTER in COD229)
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RestrictEmptyReportID_OnInsert()
    var
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270795] User is unable to insert a line into the "Report Selection2" table with a blank "Report ID".
        Initialize;

        ReportSelections.Init();
        ReportSelections.Validate("Report ID", 0);
        asserterror ReportSelections.Insert(true);
        Assert.ExpectedError(ReportIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RestrictEmptyReportID_OnModify()
    var
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270795] User is unable to change "Report ID" to blank in the "Report Selection2" table.
        Initialize;

        ReportSelections.Init();
        ReportSelections.Validate("Report ID", LibraryRandom.RandIntInRange(20, 30));
        ReportSelections.Insert(true);

        ReportSelections.Validate("Report ID", 0);
        asserterror ReportSelections.Modify(true);
        Assert.ExpectedError(ReportIDMustHaveValueErr);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendorWithSpecialSymbolsInNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 290802] Purchase Header SendRecords works correctly when Vendor No. has special symbols in it
        Initialize;

        // [GIVEN] Report Selection was setup
        SetupReportSelectionsVendor(true, true);

        // [GIVEN] Vendor with special symbol in "No."
        CreateVendorWithCustomNo(Vendor, GenerateGUIDWithSpecialSymbol);

        // [GIVEN] Purchase Order for this Vendor
        CreatePurchaseOrderForVendor(PurchaseHeader, Vendor."No.");

        // [WHEN] SendRecords was executed for this one order
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst;
        PurchaseHeader.SendRecords;

        // [THEN] No error and files were successfully created
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseReturnShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedReturnShipmentForVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 300028] Print Posted Return Shipment in case a Vendor has Custom Report Selection for Posted Return Shipment.
        Initialize;

        // [GIVEN] Posted Return Shipment for Vendor "V".
        CreateAndPostPurchaseReturnOrder(PurchaseHeader);
        LibraryPurchase.FindReturnShipmentHeader(ReturnShipmentHeader, PurchaseHeader."No.");

        // [GIVEN] Custom Report Selection with Vendor "V", Usage "Posted Return Shipment".
        InsertCustomReportSelectionVendor(
          CustomReportSelection, ReturnShipmentHeader."Buy-from Vendor No.", GetPurchaseReturnShipmentReportID,
          false, false, '', CustomReportSelection.Usage::"P.Ret.Shpt.");
        Commit();

        // [WHEN] Print Posted Return Shipment.
        ReturnShipmentHeader.SetRecFilter;
        ReturnShipmentHeader.PrintRecords(false);

        // [THEN] Chosen report is used for printing.
        LibraryXMLRead.Initialize(LibraryVariableStorage.DequeueText);
        LibraryXMLRead.VerifyAttributeValue('ReportDataSet', 'id', Format(GetPurchaseReturnShipmentReportID));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('VendorReportSelectionsPRetShptModalPageHandler')]
    [Scope('OnPrem')]
    procedure SelectPostedReturnShipmentOnVendorReportSelections()
    var
        CustomReportSelection: Record "Custom Report Selection";
        VendorCard: TestPage "Vendor Card";
        Usage: Option "Purchase Order","Vendor Remittance","Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 300028] Select Posted Return Shipment value on the Vendor Report Selections page.
        Initialize;

        // [WHEN] Open page "Vendor Report Selections" for selected Vendor, set Usage to "Posted Return Shipment", close page.
        LibraryVariableStorage.Enqueue(Usage::"Posted Return Shipment");
        VendorCard.OpenEdit;
        VendorCard.FILTER.SetFilter("No.", LibraryPurchase.CreateVendorNo);
        VendorCard.VendorReportSelections.Invoke;

        // [THEN] Usage is "P.Ret.Shpt." for Custom Report Selection for this Vendor.
        CustomReportSelection.SetRange("Source Type", DATABASE::Vendor);
        CustomReportSelection.SetRange("Source No.", VendorCard."No.".Value);
        CustomReportSelection.FindFirst;
        CustomReportSelection.TestField(Usage, CustomReportSelection.Usage::"P.Ret.Shpt.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StatementOKRequestPageHandler,DownloadAttachmentNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmailCustomerStatement()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        CustomerCard: TestPage "Customer Card";
        ReportOutput: Option Print,Preview,PDF,Email,Excel,XML;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Statement]
        // [SCENARIO 300470] Send to email Customer Statement in case a document layout is used for email body.
        Initialize;

        // [GIVEN] Custom Report Selection with Customer "C", Usage "Customer Statement", Report ID = 116 (Statement), "Use for Email Body" = TRUE.
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";

        InsertReportSelections(
          ReportSelections, GetCustomerStatementReportID, false, false, '', ReportSelections.Usage::"C.Statement");

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, CustomerNo, GetCustomerStatementReportID, true, true,
          CustomReportLayout.InitBuiltInLayout(GetCustomerStatementReportID, CustomReportLayout.Type::Word),
          'abc@abc.abc', CustomReportSelection.Usage::"C.Statement");
        Commit();

        // [WHEN] Run Statement report for the Customer "C" with "Report Output" = Email.
        LibraryVariableStorage.Enqueue(ReportOutput::Email);
        LibraryVariableStorage.Enqueue(CustomerNo);
        CustomerCard.OpenEdit;
        CustomerCard."Report Statement".Invoke;

        // [THEN] "Last Statement No." for Customer "C" increases by 1.
        // [THEN] Only one Interaction Log Entry is inserted.
        Customer.Get(CustomerNo);
        Customer.TestField("Last Statement No.", 1);
        FindInteractionLogEntriesByCustomerNo(InteractionLogEntry, CustomerNo, InteractionLogEntry."Document Type"::"Sales Stmnt.");
        Assert.RecordCount(InteractionLogEntry, 1);
    end;
    
    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmailStandardStatementCustomerWithoutEntries()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ErrorMessages: TestPage "Error Messages";
        CustomerNo: Code[20];
        StandardStatementReportOutput: Option Print,Preview,Word,PDF,Email,XML;
    begin
        // [FEATURE] [Sales] [Standard Statement] [Email]
        // [SCENARIO 313487] Stan gets error when send to email "Standard Statement" for customer without entries
        Initialize;

        // [GIVEN] Custom Report Selection with Customer "C", Usage "Customer Statement", Report ID = 1316 (Standard Statement), "Use for Email Body" = FALSE and "Send To Email" is not blank.
        CustomerNo := LibrarySales.CreateCustomerNo;

        InsertReportSelections(
          ReportSelections, GetStandardStatementReportID, false, true, '', ReportSelections.Usage::"C.Statement");

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, CustomerNo, GetStandardStatementReportID, false, false,
          '',
          'abc@abc.abc', CustomReportSelection.Usage::"C.Statement");
        Commit();

        // [WHEN] Run "Customer Statement" report for the Customer "C" with "Report Output" = Email.
        LibraryVariableStorage.Enqueue(StandardStatementReportOutput::Email);
        LibraryVariableStorage.Enqueue(CustomerNo);
        ErrorMessages.Trap;
        CustomerCard.OpenEdit;
        CustomerCard."Report Statement".Invoke;
        Commit();

        // [THEN] Error "No data exists for specified report filter"
        ErrorMessages.Description.AssertEquals(NoOutputErr);
        ErrorMessages.Close;

        // [THEN] "Last Statement No." for Customer "C" remains 0.
        // [THEN] Only one Interaction Log Entry is inserted.
        Customer.Get(CustomerNo);
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ValidateEmailAddresses()
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [UT] [Email]
        // [SCENARIO 320367] "Send to Email" on CustomReportSelection can't contain invalid addresses

        // [GIVEN] Custom Report Selection
        CustomReportSelection.Init();

        // [WHEN] Set "Send to Email" to a string with valid address "test@email.com" and invalid "newtest@"
        asserterror CustomReportSelection.Validate("Send To Email", 'test@email.com;newtest@');

        // [THEN] Error is shown than "newtest@" is not a valid email address
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('The email address "newtest@" is not valid.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestReportSelectionsUsageValues_W1()
    var
        ReportSelections: Record "Report Selections";
    begin
        Assert.AreEqual(ReportSelections.Usage::"S.Quote", 0, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Order", 1, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Invoice", 2, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Cr.Memo", 3, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Test", 4, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Quote", 5, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Order", 6, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Invoice", 7, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Cr.Memo", 8, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Receipt", 9, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Ret.Shpt.", 10, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Test", 11, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"B.Stmt", 12, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"B.Recon.Test", 13, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"B.Check", 14, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::Reminder, 15, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Fin.Charge", 16, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Rem.Test", 17, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"F.C.Test", 18, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Prod.Order", 19, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Blanket", 20, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Blanket", 21, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::M1, 22, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::M2, 23, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::M3, 24, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::M4, 25, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::Inv1, 26, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::Inv2, 27, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::Inv3, 28, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Quote", 29, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Order", 30, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Invoice", 31, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Credit Memo", 32, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Contract Quote", 33, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Contract", 34, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Test", 35, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Return", 36, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Return", 37, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Shipment", 38, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Ret.Rcpt.", 39, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Work Order", 40, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Invt.Period Test", 41, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SM.Shipment", 42, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Test Prepmt.", 43, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Test Prepmt.", 44, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Arch.Quote", 45, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Arch.Order", 46, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Arch.Quote", 47, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Arch.Order", 48, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Arch.Return", 49, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Arch.Return", 50, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Asm.Order", 51, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Asm.Order", 52, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Order Pick Instruction", 53, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.V.Remit.", 84, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"C.Statement", 85, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"V.Remittance", 86, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::JQ, 87, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Invoice Draft", 88, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Pro Forma S. Invoice", 89, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"S.Arch.Blanket", 90, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Arch.Blanket", 91, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Phys.Invt.Order Test", 92, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Phys.Invt.Order", 93, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Phys.Invt.Order", 94, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"Phys.Invt.Rec.", 95, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"P.Phys.Invt.Rec.", 96, 'Wrong Usage option value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestReportSelectionsUsageValues_Local()
    var
        ReportSelections: Record "Report Selections";
    begin

        Assert.AreEqual(ReportSelections.Usage::"USI", 97, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"USCM", 98, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UCI", 99, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UCO", 100, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"CB", 101, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"CI", 102, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"CO", 103, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UAS", 104, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"AS", 105, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UIS", 106, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UIR", 107, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"IS", 109, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"IR", 110, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UFAW", 112, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UFAR", 113, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UFAM", 114, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"FAW", 115, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"FAR", 116, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"FAM", 117, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"FAJ", 118, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"FARJ", 119, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"PIJ", 120, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UPI", 121, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"IRJ", 122, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UPCM", 123, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"DT", 124, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"SOPI", 125, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"UCSD", 126, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"CSI", 127, 'Wrong Usage option value.');
        Assert.AreEqual(ReportSelections.Usage::"CSCM", 128, 'Wrong Usage option value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromReportSelectionsCustomerUT()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] Copy "Report Selections" setup to "Custom Report Selection" for customer
        Initialize();

        // [GIVEN] Report Selections: Quote, Customer Statement,Reminder ("R1", "R2", "R3")
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"S.Quote", 1304);
        LibraryERM.SetupReportSelection(ReportSelections.Usage::Reminder, 117);
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"S.Shipment", 208);
        ReportSelections.SetFilter(Usage, '%1|%2|%3', ReportSelections.Usage::"S.Quote", ReportSelections.Usage::Reminder, ReportSelections.Usage::"S.Shipment");
        // [GIVEN] Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Custom report selection "CR" for "C"
        InsertCustomReportSelectionCustomer(CustomReportSelection, CustomerNo, 204, false, false, '', '', CustomReportSelection.Usage::"S.Quote");
        // [WHEN] Copy Report Selections to Custom Report Selection
        CustomReportSelection.CopyFromReportSelections(ReportSelections, Database::Customer, CustomerNo);
        // [THEN] Custom Report Selection contains 4 records with "R1", "R2", "R3", "CR" reports for "C"
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Customer, CustomerNo, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromReportSelectionsVendorUT()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] Copy "Report Selections" setup to "Custom Report Selection" for vendor
        Initialize();

        // [GIVEN] Report Selections: Order, Vendor Remittance, Vendor Remittance - Posted Entries, Return Shipment ("R1", "R2", "R3")
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", 1322);
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"V.Remittance", 399);
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Ret.Shpt.", 6636);
        ReportSelections.SetFilter(
            Usage, '%1|%2|%3',
            ReportSelections.Usage::"P.Order", ReportSelections.Usage::"V.Remittance", ReportSelections.Usage::"P.Ret.Shpt.");
        // [GIVEN] Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [WHEN] Copy Report Selections to Custom Report Selection
        CustomReportSelection.CopyFromReportSelections(ReportSelections, Database::Vendor, VendorNo);
        // [THEN] Custom Report Selection contains 3 records with "R1", "R2", "R3" reports for "V"
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Vendor, VendorNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSendToEmailFromContactsUT()
    var
        Contact: Record Contact;
        CustomReportSelection: Record "Custom Report Selection";
        CompanyContactNo: Code[20];
        i: Integer;
        EmailList: Text;
        ContactFilter: Text;
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] Get "Send to Email" from contacts
        Initialize();

        // [GIVEN] Person contact "CP" with email "E"
        CreatePersonContactWithEmail('', false);
        // [GIVEN] Company contact "CC1" with person contacts "CP1".."CP3" with emails "E1".."E3"
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();
        for i := 1 to 3 do
            EmailList += CreatePersonContactWithEmail(CompanyContactNo, false) + ';';
        EmailList := DelChr(EmailList, '>', ';');
        // [GIVEN] Sales quote custom report selection
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, LibrarySales.CreateCustomerNo());
        // [WHEN] Get emails from contacts "CP1".."CP3"
        Contact.SetRange("Company No.", CompanyContactNo);
        Contact.FindSet();
        repeat
            ContactFilter += Contact."No." + '|';
        until Contact.Next() = 0;
        ContactFilter := DelChr(ContactFilter, '>', '|');
        Contact.Reset();
        Contact.SetFilter("No.", ContactFilter);
        CustomReportSelection.GetSendToEmailFromContacts(Contact);
        // [THEN] Custom report selection "Send to Email" = "E1;E2;E3"
        Assert.AreEqual(CustomReportSelection."Send To Email", EmailList, 'Wrong email list.');
        Assert.IsTrue(CustomReportSelection."Use Email from Contact", 'Wrong use email from contact.');
        Assert.IsTrue(CustomReportSelection."Selected Contacts Filter".HasValue, 'Wrong selected contacts filter.');
    end;

    [Test]
    [HandlerFunctions('ExceededContactsNotification')]
    [Scope('OnPrem')]
    procedure GetSendToEmailFromContactsWithNotificationUT()
    var
        Contact: Record Contact;
        CustomReportSelection: Record "Custom Report Selection";
        CompanyContactNo: Code[20];
        i: Integer;
        EmailList: Text;
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] Get "Send to Email" from contacts and show notification on exceeding the field length
        Initialize();

        // [GIVEN] Person contact "CP" with email "E"
        CreatePersonContactWithEmail('', false);
        // [GIVEN] Company contact "CC1" with person contacts "CP1".."CP3" with emails "E1".."E3"
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();
        for i := 1 to 3 do
            EmailList += CreatePersonContactWithEmail(CompanyContactNo, true) + ';';
        EmailList := CopyStr(EmailList, 1, 162);
        EmailList := DelChr(EmailList, '>', ';');
        // [GIVEN] Sales quote custom report selection
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, LibrarySales.CreateCustomerNo());
        // [WHEN] Get emails from contacts "CP1".."CP3"
        Contact.SetRange("Company No.", CompanyContactNo);
        CustomReportSelection.GetSendToEmailFromContacts(Contact);
        // [THEN] Custom report selection "Send to Email" = "E1;E2"
        Assert.AreEqual(CustomReportSelection."Send To Email", EmailList, 'Wrong email list.');
    end;

    [Test]
    [HandlerFunctions('TestAddressEMailDialogHandler')]
    [Scope('OnPrem')]
    procedure GetSendToEmailFromContactsFilter()
    var
        SalesHeader: Record "Sales Header";
        CustomReportSelection: Record "Custom Report Selection";
        SalesQuote: TestPage "Sales Quote";
        CompanyContactNo: Code[20];
        i: Integer;
        EmailList: Text;
        TempEmail: Text;
    begin
        // [FEATURE] [UT] [UI] [Custom Report Selection]
        // [SCENARIO 275947] Verify "Send To Email" from contacts filter via EmailDialog
        Initialize();

        // [GIVEN] Company contact "CC1" with person contacts "CP1".."CP3" with emails "E1".."E3"
        // [GIVEN] Send to email = "E1"|"E2"
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();
        for i := 1 to 3 do begin
            TempEmail := CreatePersonContactWithEmail(CompanyContactNo, false) + ';';
            if (i = 1) or (i = 2) then
                EmailList += TempEmail;
        end;
        EmailList := DelChr(EmailList, '>', ';');
        // [GIVEN] Sales quote with custom report selection
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        SalesHeader.Find();
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, SalesHeader."Sell-to Customer No.");
        FillCustomReportSelectionContactsFilter(CustomReportSelection, CompanyContactNo);
        CustomReportSelection.Modify();
        // [WHEN] Invoke "Send by Emai" action on the sales quote page
        SalesQuote.OpenEdit;
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Email.Invoke();
        // [THEN] EmailDialog appeared, "Send to" = "E1";"E2"
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), EmailList, 'Wrong send to email dialog.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearSendToEmail()
    var
        SalesHeader: Record "Sales Header";
        CustomReportSelection: Record "Custom Report Selection";
        CompanyContactNo: Code[20];
        i: Integer;
        EmailList: Text;
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 275947] Clear "Send To Email" clears also selected contacts filter 
        Initialize();

        // [GIVEN] Company contact "CC1" with person contacts "CP1".."CP3" with emails "E1".."E3"
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();
        for i := 1 to 3 do
            CreatePersonContactWithEmail(CompanyContactNo, true);
        // [GIVEN] Sales quote custom report selection
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, LibrarySales.CreateCustomerNo());
        // [GIVEN] Custom report selection with 2 contacts
        FillCustomReportSelectionContactsFilter(CustomReportSelection, CompanyContactNo);
        // [WHEN] Clear "Send to Emai" in custom report selection
        CustomReportSelection.Validate("Send To Email", '');
        CustomReportSelection.Modify();
        // [THEN] "Selected Contacts Filter" doesn't have a value
        Assert.IsFalse(CustomReportSelection."Selected Contacts Filter".HasValue, 'Wrong selected contacts filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSendToEmailOnOpenPage()
    var
        Contact: Record Contact;
        CustomReportSelection: Record "Custom Report Selection";
        CustomerReportSelections: TestPage "Customer Report Selections";
        CompanyContactNo: Code[20];
        i: Integer;
        EmailList: Text;
        ContactFilter: Text;
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] "Send to Email" field updated from contacts after "Customer Report Selections" page opened
        Initialize();

        // [GIVEN] Person contact "CP" with email "E"
        CreatePersonContactWithEmail('', false);
        // [GIVEN] Company contact "CC1" with person contacts "CP1".."CP3" with emails "E1".."E3"
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();
        for i := 1 to 3 do
            EmailList += CreatePersonContactWithEmail(CompanyContactNo, false) + ';';
        // [GIVEN] Sales quote custom report selection
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, LibrarySales.CreateCustomerNo());
        Contact.SetRange("Company No.", CompanyContactNo);
        Contact.FindSet();
        repeat
            ContactFilter += Contact."No." + '|';
        until Contact.Next() = 0;
        ContactFilter := DelChr(ContactFilter, '>', '|');
        Contact.Reset();
        Contact.SetFilter("No.", ContactFilter);
        CustomReportSelection.GetSendToEmailFromContacts(Contact);
        CustomReportSelection.Modify();
        // [WHEN] "Email" in contact updated later
        if Contact.FindLast() then begin
            Contact."E-Mail" := 'testcase@testcase.com';
            Contact.Modify();
        end;
        // [THEN] Customer Report Selection "Sent To Email" updated when page opened
        CustomerReportSelections.OpenEdit();
        CustomerReportSelections.GoToRecord(CustomReportSelection);
        Assert.IsTrue(StrPos(CustomerReportSelections.SendToEmail.Value, 'testcase@testcase.com') <> 0, 'Wrong email after contact update.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceEmailHasMorePriorityThanCustomerEmail()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        FileManagement: Codeunit "File Management";
        FileName: Text[250];
        EmailAddress: Text[80];
    begin
        // [SCENARIO 338446] E-mail address specified in posted Sales Invoice has more priority than customer's e-mail address.
        Initialize;

        // [GIVEN] Posted Sales Invoice "A" with the "Sell-to Email" = "a@a.com; b@b.com; c@c.com".
        // [GIVEN] Customer's email address = "x@x.com; y@y.com; z@z.com".
        CreateSalesInvoice(SalesHeader);
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmails);
        Customer.Modify(true);

        SalesHeader.Validate("Sell-to E-Mail", LibraryUtility.GenerateRandomEmails);
        SalesHeader.Modify(true);
        PostSalesInvoice(SalesHeader, SalesInvoiceHeader);

        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetupReportSelections(true, true);

        // [GIVEN] When send sales invoice by e-mail.
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetEmailBody(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", EmailAddress);

        // [THEN] The "a@a.com; b@b.com; c@c.com" address is used as target email address.
        Assert.AreEqual(SalesHeader."Sell-to E-Mail", EmailAddress, EmailAddressErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSendToEmailFromContactWithoutEmailUT()
    var
        Contact: Record Contact;
        CustomReportSelection: Record "Custom Report Selection";
        CompanyContactNo: Code[20];
    begin
        // [FEATURE] [UT] [Custom Report Selection]
        // [SCENARIO 275947] Get "Send to Email" from contact with empty email
        Initialize();

        // [GIVEN] Company contact with empty email
        CompanyContactNo := LibraryMarketing.CreateCompanyContactNo();

        // [GIVEN] Sales quote custom report selection
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, LibrarySales.CreateCustomerNo());

        // [WHEN] Get emails from contact
        Contact.SetRange("No.", CompanyContactNo);
        CustomReportSelection.GetSendToEmailFromContacts(Contact);

        // [THEN] Custom report selection "Send to Email" = " "
        Assert.AreEqual(CustomReportSelection."Send To Email", '', 'Wrong email list.');
        Assert.IsFalse(CustomReportSelection."Use Email from Contact", 'Wrong use email from contact.');
    end;

    [Test]
    [HandlerFunctions('StatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewCustomerStatement_WebClient()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        CustomerCard: TestPage "Customer Card";
        ReportOutput: Option Print,Preview,PDF,Email,Excel,XML;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Statement]
        // [SCENARIO 300470] Stan gets pdf file when he calls Statement report with "Preview" output type in web client.
        Initialize();

        // [GIVEN] Report Selection where Usage = "Customer Statement", Report ID = 116 (Statement)
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";

        InsertReportSelections(
          ReportSelections, GetCustomerStatementReportID, false, false, '', ReportSelections.Usage::"C.Statement");

        Commit();

        // [WHEN] Run Statement report for the Customer "C" with "Report Output" = Preview in Web Client context.
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        LibraryVariableStorage.Enqueue(ReportOutput::Preview);
        LibraryVariableStorage.Enqueue(CustomerNo);
        CustomerCard.OpenEdit();
        CustomerCard."Report Statement".Invoke();

        // [THEN] "Last Statement No." for Customer "C" increases by 1.
        // [THEN] Only one Interaction Log Entry is inserted.
        Customer.Get(CustomerNo);
        Customer.TestField("Last Statement No.", 1);
        FindInteractionLogEntriesByCustomerNo(InteractionLogEntry, CustomerNo, InteractionLogEntry."Document Type"::"Sales Stmnt.");
        Assert.RecordCount(InteractionLogEntry, 1);

        // [THEN] Pdf file generated as preview file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer));
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        DummyEmailItem: Record "Email Item";
        InventorySetup: Record "Inventory Setup";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Report Selections Tests");

        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.AssertEmpty();
        CustomReportSelection.DeleteAll();
        ReportSelections.DeleteAll();
        ReportLayoutSelection.DeleteAll();
        CreateDefaultReportSelection();
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;

        Initialized := true;

        SetupInvoiceReportLayoutSelection();
        CustomMessageTypeTxt := Format(DummyEmailItem."Message Type"::"Custom Message");
        FromEmailBodyTemplateTxt := Format(DummyEmailItem."Message Type"::"From Email Body Template");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibraryWorkflow.SetUpSMTPEmailSetup();

        Commit();
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryInventory.CreateShippingAgent(ShippingAgent);
        SalesHeader.Validate("Package Tracking No.", GenerateRandomPackageTrackingNo);
        SalesHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          1);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoice(SalesHeader);
        PostSalesInvoice(SalesHeader, SalesInvoiceHeader);
    end;

    local procedure CreateAndPostPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate(Name, 'A');
        Customer.Validate(Address, 'A');
        CountryRegion.FindFirst;
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate(City, 'A');
        Customer.Validate("Post Code", 'A');
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithCustomNo(var Vendor: Record Vendor; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Delete();
        Vendor."No." := VendorNo;
        Vendor.Insert(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 1000 + LibraryRandom.RandDec(100, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrderForVendor(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure FindInteractionLogEntriesByCustomerNo(var InteractionLogEntry: Record "Interaction Log Entry"; CustomerNo: Code[20]; DocumentType: Enum "Interaction Log Entry Document Type")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
        InteractionLogEntry.SetRange("Contact No.", ContactBusinessRelation."Contact No.");
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.FindSet;
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; CustomerNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage")
    begin
        with CustomReportSelection do begin
            Init;
            Validate("Source Type", DATABASE::Customer);
            Validate("Source No.", CustomerNo);
            Validate(Usage, ReportUsage);
            Validate(Sequence, Count + 1);
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Email Body Layout Code", EmailBodyLayoutCode);
            Validate("Send To Email", SendToAddress);
            Insert(true);
        end;
    end;

    local procedure InsertCustomReportSelectionVendor(var CustomReportSelection: Record "Custom Report Selection"; VendorNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage")
    begin
        with CustomReportSelection do begin
            Init;
            Validate("Source Type", DATABASE::Vendor);
            Validate("Source No.", VendorNo);
            Validate(Usage, ReportUsage);
            Validate(Sequence, Count + 1);
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Send To Email", SendToAddress);
            Insert(true);
        end;
    end;

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage")
    begin
        with ReportSelections do begin
            Init;
            Validate(Usage, ReportUsage);
            Validate(Sequence, Format(Count + 1));
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Email Body Layout Code", EmailBodyLayoutCode);
            Insert(true);
        end;
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetAutoCalcFields(Closed);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure OpenNewPostedSalesInvoice(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
    end;

    local procedure SetupReportSelections(UseForEmailAttachment: Boolean; UseForEmailBody: Boolean)
    var
        OldReportSelections: Record "Report Selections";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        GetCustomBodyLayout(CustomReportLayout);

        OldReportSelections.FilterPrintUsage(OldReportSelections.Usage::"S.Invoice");
        OldReportSelections.FindFirst;

        UpdateReportSelections(
          OldReportSelections.Usage::"S.Invoice", CustomReportLayout."Report ID", UseForEmailAttachment, UseForEmailBody,
          CustomReportLayout.Code);
    end;

    local procedure SetupReportSelectionsVendor(UseForEmailAttachment: Boolean; UseForEmailBody: Boolean)
    var
        OldReportSelections: Record "Report Selections";
        DummyCustomReportLayout: Record "Custom Report Layout";
    begin
        OldReportSelections.FilterPrintUsage(OldReportSelections.Usage::"P.Order");
        if not OldReportSelections.FindFirst then
            CreateReportSelection(OldReportSelections.Usage::"P.Order", '2', REPORT::Order);

        UpdateReportSelections(
          OldReportSelections.Usage::"P.Order", GetReportIDForPurchaseOrder, UseForEmailAttachment, UseForEmailBody,
          DummyCustomReportLayout.Code);
    end;

    local procedure SetupInvoiceReportLayoutSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Sales - Invoice";
        ReportLayoutSelection.Insert();
    end;

    local procedure CreateDefaultReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
        CreateReportSelection(ReportSelections.Usage::"S.Quote", '3', REPORT::"Standard Sales - Quote");
    end;

    local procedure CreateSecondaryReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", '2', REPORT::"Sales - Invoice");
    end;

    local procedure CreateReportSelection(Usage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Default := true;
        ReportSelections.Insert();
    end;

    local procedure UpdateReportSelections(NewUsage: Enum "Report Selection Usage"; NewReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; NewEmailBodyLayout: Code[20])
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.FilterPrintUsage(NewUsage);
        ReportSelections.FindFirst;
        ReportSelections.Validate("Report ID", NewReportID);
        ReportSelections.Validate("Use for Email Attachment", UseForEmailAttachment);
        ReportSelections.Validate("Use for Email Body", UseForEmailBody);
        ReportSelections.Validate(Default, true);

        if UseForEmailBody then
            ReportSelections.Validate("Email Body Layout Code", NewEmailBodyLayout)
        else
            ReportSelections.Validate("Email Body Layout Code", '');

        ReportSelections.Modify(true);
    end;

    local procedure UpdateCustomReportSelections(NewCustNo: Code[20]; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200])
    var
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        GetCustomBodyLayout(CustomReportLayout);
        InsertCustomReportSelectionCustomer(
          CustomReportSelection, NewCustNo, CustomReportLayout."Report ID", UseForEmailAttachment, UseForEmailBody, '', SendToAddress,
          CustomReportSelection.Usage::"S.Invoice");

        if UseForEmailAttachment then
            CustomReportSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);

        if UseForEmailBody then
            CustomReportSelection.Validate("Email Body Layout Code", CustomReportLayout.Code);

        CustomReportSelection.Modify(true);
    end;

    local procedure GenerateGUIDWithSpecialSymbol(): Code[20]
    begin
        exit(LibraryUtility.GenerateGUID + '&');
    end;

    local procedure GetStandardSalesInvoiceReportID(): Integer
    begin
        exit(REPORT::"Standard Sales - Invoice");
    end;

    local procedure GetSalesInvoiceReportID(): Integer
    begin
        exit(REPORT::"Sales - Invoice");
    end;

    local procedure GetSalesInvoiceNosReportID(): Integer
    begin
        exit(REPORT::"Sales Invoice Nos.");
    end;

    local procedure GetReportIDForPurchaseOrder(): Integer
    begin
        exit(REPORT::"Standard Purchase - Order");
    end;

    local procedure GetPurchaseReturnShipmentReportID(): Integer
    begin
        exit(REPORT::"Purchase - Return Shipment");
    end;

    local procedure GetCustomerStatementReportID(): Integer
    begin
        exit(REPORT::Statement);
    end;

    local procedure GetStandardStatementReportID(): Integer
    begin
        exit(REPORT::"Standard Statement");
    end;

    local procedure GetCustomBodyLayout(var CustomReportLayout: Record "Custom Report Layout")
    begin
        CustomReportLayout.SetRange("Report ID", GetStandardSalesInvoiceReportID);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        CustomReportLayout.FindLast;
    end;

    local procedure GetEmailItem(var EmailItem: Record "Email Item"; MessageType: Integer; BodyFilePath: Text[250]; Plaintext: Boolean)
    begin
        EmailItem.Validate("Plaintext Formatted", Plaintext);
        EmailItem.Validate("Message Type", MessageType);
        EmailItem.Validate("Body File Path", BodyFilePath);
    end;

    local procedure SetUpCustomEmail(var SalesInvoiceHeader: Record "Sales Invoice Header"; EmailAddress: Text[80]; UseCustomForEmailBody: Boolean)
    var
        Customer: Record Customer;
    begin
        SetupReportSelections(true, true);

        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."E-Mail" := EmailAddress;
        Customer.Modify(true);

        UpdateCustomReportSelections(SalesInvoiceHeader."Bill-to Customer No.", true, UseCustomForEmailBody, EmailAddress);
    end;

    local procedure GenerateRandomPackageTrackingNo(): Text[30]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummySalesHeader."Package Tracking No.")),
            1, MaxStrLen(DummySalesHeader."Package Tracking No.")));
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    local procedure GetStatementTitlePdf(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitlePdfTxt, Customer.Name, Format(WorkDate, 0, 9)));
    end;

    local procedure VerifySendEmailPage(ExpectedType: Text; ExpectedBodyText: Text; ExpectedAttachmentName: Text)
    var
        ActualType: Text;
        ActualBodyText: Text;
        ActualAttachmentFileName: Text;
        BodyTextOK: Boolean;
        AttachmentNameOK: Boolean;
    begin
        ActualType := LibraryVariableStorage.DequeueText;
        ActualBodyText := LibraryVariableStorage.DequeueText;
        ActualAttachmentFileName := LibraryVariableStorage.DequeueText;

        if ExpectedBodyText = '' then
            BodyTextOK := ExpectedBodyText = ActualBodyText
        else
            BodyTextOK := StrPos(ActualBodyText, ExpectedBodyText) > 0;

        if ExpectedAttachmentName = '' then
            AttachmentNameOK := ExpectedAttachmentName = ActualAttachmentFileName
        else
            AttachmentNameOK := StrPos(ActualAttachmentFileName, ExpectedAttachmentName) > 0;

        Assert.AreEqual(ExpectedType, ActualType, 'Message type is wrong on Send Email Dialog');
        Assert.IsTrue(BodyTextOK, 'Email Body text is wrong on Send Email Dialog, check if the right template was selected');
        Assert.IsTrue(AttachmentNameOK, 'Attachment File Name text is wrong on Send Email Dialog');
    end;

    local procedure VerifyCopiedCustomReportSelection(var ReportSelections: Record "Report Selections"; SourceType: Integer; SourceNo: Code[20]; CustomReportSelectionRecordCount: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomReportSelection.SetRange("Source Type", SourceType);
        CustomReportSelection.SetRange("Source No.", SourceNo);
        Assert.RecordCount(CustomReportSelection, CustomReportSelectionRecordCount);

        ReportSelections.FindSet();
        repeat
            CustomReportSelection.SetRange(Usage, ReportSelections.Usage);
            CustomReportSelection.SetRange("Report ID", ReportSelections."Report ID");
            Assert.RecordCount(CustomReportSelection, 1);
        until ReportSelections.Next() = 0;
    end;

    local procedure CreatePersonContactWithEmail(CompanyContactNo: Code[20]; UseMaxFieldLength: Boolean): Text
    var
        Contact: Record Contact;
        i: Integer;
        EMail: Text;
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", CompanyContactNo);
        if UseMaxFieldLength then
            Contact.Validate("E-Mail", CreateEmail(MaxStrLen(Contact."E-Mail")))
        else
            Contact.Validate("E-Mail", CreateEmail(20));
        Contact.Modify();
        exit(Contact."E-Mail");
    end;

    local procedure CreateSalesQuoteCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; SourceNo: Code[20])
    begin
        CustomReportSelection.Init();
        CustomReportSelection."Source Type" := Database::Customer;
        CustomReportSelection."Source No." := SourceNo;
        CustomReportSelection.Usage := CustomReportSelection.Usage::"S.Quote";
        CustomReportSelection."Report ID" := 1304;
        CustomReportSelection.Insert();
    end;

    local procedure CreateEmail(MaxLength: Integer): Text
    var
        i: Integer;
        Email: Text;
    begin
        Email := LibraryUtility.GenerateGUID + '@';
        for i := 1 to MaxLength DIV 10 - 1 do
            Email += LibraryUtility.GenerateGUID;

        exit(CopyStr(Email, 1, MaxLength));
    end;

    local procedure FillCustomReportSelectionContactsFilter(var CustomReportSelection: Record "Custom Report Selection"; CompanyContactNo: Code[20])
    var
        Contact: Record Contact;
        OStream: OutStream;
        ContactFilter: Text;
    begin
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetRange("Company No.", CompanyContactNo);
        Contact.FindFirst();
        ContactFilter := Contact."No.";
        Contact.Next();
        ContactFilter += '|' + Contact."No.";
        Contact.Reset();
        Contact.SetFilter("No.", ContactFilter);
        CustomReportSelection.GetSendToEmailFromContacts(Contact);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName;
        LibraryVariableStorage.Enqueue(FileName);
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName;
        LibraryVariableStorage.Enqueue(FileName);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementOKRequestPageHandler(var Statement: TestRequestPage Statement)
    begin
        Statement."Start Date".SetValue(WorkDate);
        Statement."End Date".SetValue(WorkDate);
        Statement.ReportOutput.SetValue(LibraryVariableStorage.DequeueInteger);
        Statement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText);
        Statement.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementOKRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(WorkDate);
        StandardStatement."End Date".SetValue(WorkDate);
        StandardStatement.ReportOutput.SetValue(LibraryVariableStorage.DequeueInteger);
        StandardStatement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText);
        StandardStatement.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionHandler(var SelectSendingOption: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOption."E-Mail".SetValue(DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        SelectSendingOption.Disk.SetValue(DocumentSendingProfile.Disk::PDF);
        SelectSendingOption.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EMailDialogHandler(var EMailDialog: TestPage "Email Dialog")
    begin
        LibraryVariableStorage.Enqueue(EMailDialog.MessageContents.Value);
        LibraryVariableStorage.Enqueue(EMailDialog.BodyText.Value);
        LibraryVariableStorage.Enqueue(EMailDialog."Attachment Name".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestAddressEMailDialogHandler(var EMailDialog: TestPage "Email Dialog")
    begin
        LibraryVariableStorage.Enqueue(EMailDialog.SendTo.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestChangingTypeEMailDialogHandler(var EMailDialog: TestPage "Email Dialog")
    var
        EmailItem: Record "Email Item";
        TestText: Text;
    begin
        EMailDialog.MessageContents.SetValue(EmailItem."Message Type"::"Custom Message");
        Assert.IsTrue(EMailDialog.BodyText.Visible, 'Body text should become visible');

        TestText := 'Test message text';
        EMailDialog.BodyText.SetValue(TestText);
        EMailDialog.MessageContents.SetValue(EmailItem."Message Type"::"From Email Body Template");
        Assert.IsFalse(EMailDialog.BodyText.Visible, 'Body text should become invisible');

        EMailDialog.MessageContents.SetValue(EmailItem."Message Type"::"Custom Message");
        Assert.IsTrue(EMailDialog.BodyText.Visible, 'Body text should become visible');
        Assert.AreEqual(TestText, EMailDialog.BodyText.Value, 'Body text should have a value assigned');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportSelectionPrintSelectSecondHandler(var ReportSelectionPrint: TestPage "Report Selection - Print")
    begin
        // Given two reports, select the second one
        ReportSelectionPrint.First;
        ReportSelectionPrint.Default.SetValue(true);
        ReportSelectionPrint.Next;
        ReportSelectionPrint.Default.SetValue(false);
        ReportSelectionPrint.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvoicePrintHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        // We only need to validate that the handler is called, it's fine if we don't print.
        StandardSalesInvoice.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorReportSelectionsPRetShptModalPageHandler(var VendorReportSelections: TestPage "Vendor Report Selections")
    begin
        VendorReportSelections.Usage2.SetValue(LibraryVariableStorage.DequeueInteger);
        VendorReportSelections.ReportID.SetValue(GetPurchaseReturnShipmentReportID);
        VendorReportSelections.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PurchaseReturnShipmentReportHandler(var PurchaseReturnShipment: Report "Purchase - Return Shipment")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName;
        LibraryVariableStorage.Enqueue(FileName);
        PurchaseReturnShipment.SaveAsXml(FileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DownloadAttachmentNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ExceededContactsNotification(var Notification: Notification): Boolean
    begin
        Assert.IsTrue(StrPos(Notification.Message, 'Too many contacts were selected.') > 0, 'Exceeding contacts notification is expected');
    end;
}

