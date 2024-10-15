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
        EmailAddressErr: Label 'Destination email address does not match expected address.';
        StatementTitlePdfTxt: Label 'Statement';
        ReportTitleTemplatePdfTxt: Label '%1 for %2 as of %3.pdf';
        InvalidCustomReportSelectionErr: Label 'Invalid Custom Report Selection';
        LayoutCodeShouldNotChangedErr: Label 'Layout code should not change.';

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintEmailTemplateDefined()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Exercise
        PostedSalesInvoice.Print.Invoke();

        // Verify
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTok, PostedSalesInvoice."No.".Value);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDF()
    begin
        SendToEMailAndPDF();
    end;

    procedure SendToEMailAndPDF()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Exercise
        PostedSalesInvoice.SendCustom.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendor()
    begin
        SendToEMailAndPDFVendor();
    end;

    procedure SendToEMailAndPDFVendor()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        // Setup
        SetupReportSelectionsVendor(true, true);
        OpenNewPurchaseOrder(PurchaseOrder);

        // Execute
        PurchaseOrder.SendCustom.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PurchaseOrder."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TesteEmailNoBodyNoAttachmentRaisesError()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();

        OpenNewPostedSalesInvoice(PostedSalesInvoice);
        SetupReportSelections(false, false);

        // Exercise
        asserterror PostedSalesInvoice.Email.Invoke();

        // Verify
        Assert.ExpectedError('email body or attachment');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler')]
    [Scope('OnPrem')]
    procedure TestEmailNoBodyNoAttachmentRaisesErrorVendor()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup
        Initialize();

        OpenNewPurchaseOrder(PurchaseOrder);
        SetupReportSelectionsVendor(false, false);

        // Exercise
        asserterror PurchaseOrder.SendCustom.Invoke();

        // Verify
        Assert.ExpectedError('email body or attachment');
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandlerCustomMessage,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAttachmentOnly()
    begin
        EmailAttachmentOnly();
    end;

    procedure EmailAttachmentOnly()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        // Setup
        Initialize();

        UseForAttachment := true;
        UseForBody := false;
        SetupReportSelections(UseForAttachment, UseForBody);

        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Exercise
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(CustomMessageTypeTxt, '', PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailBodyOnly()
    begin
        EmailBodyOnly();
    end;

    procedure EmailBodyOnly()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize();

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := false;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, '') // the attachemnt name will not be added if the attachment file path is ''
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailAttachmentAndBody()
    begin
        EmailAttachmentAndBody();
    end;

    procedure EmailAttachmentAndBody()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize();

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := true;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);

        // Exercise
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandlerCustomMessage,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailAttachment()
    begin
        CustomEmailAttachment();
    end;

    procedure CustomEmailAttachment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        SetupReportSelections(false, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        UpdateCustomReportSelections(SalesInvoiceHeader."Sell-to Customer No.", true, false, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(CustomMessageTypeTxt, '', PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailBody()
    begin
        CustomEmailBody();
    end;

    procedure CustomEmailBody()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        SetupReportSelections(false, false);
        UpdateCustomReportSelections(SalesInvoiceHeader."Bill-to Customer No.", false, true, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, '') // the attachemnt name will not be added if the attachment file path is ''
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestCustomEmailAttachmentAndBody()
    begin
        CustomEmailAttachmentAndBody();
    end;

    procedure CustomEmailAttachmentAndBody()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        SetupReportSelections(false, false);

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        UpdateCustomReportSelections(SalesInvoiceHeader."Bill-to Customer No.", true, true, '');

        // Exercise
        PostedSalesInvoice.Email.Invoke();

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('TestEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestChangingMessageType()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        UseForAttachment: Boolean;
        UseForBody: Boolean;
    begin
        Initialize();

        // Setup
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        UseForAttachment := true;
        UseForBody := true;
        SetupReportSelections(UseForAttachment, UseForBody);

        // Exercise
        PostedSalesInvoice.Email.Invoke();

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
        Initialize();

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetupReportSelections(true, true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetEmailBodyForCust(
          FileName, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.", DummyEmailAddress);
        GetEmailItem(TempEmailItem, TempEmailItem."Message Type"::"From Email Body Template", FileName, false);

        // Verify
        Assert.IsTrue(TempEmailItem.GetBodyText() <> '', 'Expected text in the body of the EmailItem');
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
        Initialize();

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetupReportSelections(true, true);

        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."E-Mail" := CustomerEmailTxt;
        Customer.Modify(true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetEmailBodyForCust(
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
        Initialize();

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetUpCustomEmail(SalesInvoiceHeader, CustomLayoutEmailTxt, true);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetEmailBodyForCust(
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
        Initialize();

        // Setup
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        FileName := Format(FileManagement.ServerTempFileName('.html'), 250);
        SetUpCustomEmail(SalesInvoiceHeader, CustomLayoutEmailTxt, false);

        // Save a report to get some HTML to test the email item with
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetEmailBodyForCust(
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
        Initialize();

        // [GIVEN] Sales Invoice is Posted with Package Tracking No and Shipping Agent Code
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // [WHEN] Sales Invoice report is printed
        PostedSalesInvoice.Print.Invoke();

        // [THEN] Shipping Agent and Package Tracking No is verified on the Report
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ShippingAgentCode', PostedSalesInvoice."Shipping Agent Code".Value);
        LibraryReportDataset.AssertElementWithValueExists('PackageTrackingNo', PostedSalesInvoice."Package Tracking No.".Value);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandlerPrint,PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintPurchaseOrderVendor()
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseOrder: TestPage "Purchase Order";
        VendorInvoiceNo: Code[35];
        VendorOrderNo: Code[35];
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 258015] REP1322 "Standard Purchase - Order" now shows "Vendor Invoice No." and "Vendor Order No." fields.
        Initialize();

        // [GIVEN] Setup Report Selections to run REP1322 as default for Purchase Order.
        SetupReportSelectionsVendor(true, true);
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Purchase Order "PO" with filled "Vendor Invoice No." = "AAA" and "Vendor Order No." = "BBB".
        // [GIVEN] "PO" card page is opened.
        OpenNewPurchaseOrder(PurchaseOrder);
        VendorInvoiceNo := LibraryUtility.GenerateGUID();
        VendorOrderNo := LibraryUtility.GenerateGUID();
        PurchaseOrder."Vendor Invoice No.".SetValue(VendorInvoiceNo);
        PurchaseOrder."Vendor Order No.".SetValue(VendorOrderNo);

        // [WHEN] "Send" ActionButton invoked and printing is selected in SelectSendingOptionHandlerPrint.
        PurchaseOrder.SendCustom.Invoke();

        // [THEN] Printed report dataset contains "AAA" and "BBB" values for "Vendor Invoice No" and "Vendor Order No." fields respectively.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchHeader', PurchaseOrder."No.".Value);
        LibraryReportDataset.AssertElementWithValueExists('VendorInvoiceNo', VendorInvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('VendorOrderNo', VendorOrderNo);

        // [THEN] Two Archive entries created due to "Send to Disk" and "Print"
        PurchaseHeaderArchive.SetRange("No.", PurchaseOrder."No.".Value);
        Assert.RecordCount(PurchaseHeaderArchive, 2);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintSalesOrderCustomer()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        SetupReportSelections(true, true);

        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Execute
        PostedSalesInvoice.Print.Invoke();

        // Verify
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo', PostedSalesInvoice."No.".Value);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteSendByEmailWhenArchivingIsOn()
    begin
        QuoteSendByEmailWhenArchivingIsOn();
    end;

    procedure QuoteSendByEmailWhenArchivingIsOn()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentPrint: Codeunit "Document-Print";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Quote] [Archive] [UI]
        // [SCENARIO 218547] One entry per Send by Email press in Sales Quote Archives and in Interaction Log Entries
        Initialize();
        LibrarySales.SetArchiveQuoteAlways;

        // [GIVEN] New Sales Quote and Archiving is on
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibrarySales.SetArchiveOrders(true);

        // [WHEN] EmailSalesHeader is called
        SalesHeader.SetRecFilter();
        DocumentPrint.EmailSalesHeader(SalesHeader);

        // [THEN] One entry appears in Sales Quote Archives and one entry appears in Interaction Log Entries
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.RecordCount(SalesHeaderArchive, 1);
        InteractionLogEntry.SetRange("Contact No.", SalesHeader."Bill-to Contact No.");
        Assert.RecordCount(InteractionLogEntry, 1);

        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,TestAddressEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendorWithOrderAddress()
    begin
        SendToEMailAndPDFVendorWithOrderAddress();
    end;

    procedure SendToEMailAndPDFVendorWithOrderAddress()
    var
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Email] [Purchase] [Order Address]
        // [SCENARIO 235250] The Email Address from the Order Address is used for the Send function for an Email from a Purchase Order.
        Initialize();
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
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] Email Address on Email Dialog Page is equal to "oa@a.com"
        Assert.AreEqual(OrderAddress."E-Mail", LibraryVariableStorage.DequeueText(), WrongEmailAddressErr);

        LibraryVariableStorage.AssertEmpty();
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
    [Scope('OnPrem')]
    procedure UT_RestrictEmptyReportID_OnInsert()
    var
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270795] User is unable to insert a line into the "Report Selection2" table with a blank "Report ID".
        Initialize();

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
        Initialize();

        ReportSelections.Init();
        ReportSelections.Validate("Report ID", LibraryRandom.RandIntInRange(20, 30));
        ReportSelections.Insert(true);

        ReportSelections.Validate("Report ID", 0);
        asserterror ReportSelections.Modify(true);
        Assert.ExpectedError(ReportIDMustHaveValueErr);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendorWithSpecialSymbolsInNo()
    begin
        SendToEMailAndPDFVendorWithSpecialSymbolsInNo();
    end;

    procedure SendToEMailAndPDFVendorWithSpecialSymbolsInNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 290802] Purchase Header SendRecords works correctly when Vendor No. has special symbols in it
        Initialize();

        // [GIVEN] Report Selection was setup
        SetupReportSelectionsVendor(true, true);

        // [GIVEN] Vendor with special symbol in "No."
        CreateVendorWithCustomNo(Vendor, GenerateGUIDWithSpecialSymbol);

        // [GIVEN] Purchase Order for this Vendor
        CreatePurchaseOrderForVendor(PurchaseHeader, Vendor."No.");

        // [WHEN] SendRecords was executed for this one order
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.SendRecords();

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
        Initialize();

        // [GIVEN] Posted Return Shipment for Vendor "V".
        CreateAndPostPurchaseReturnOrder(PurchaseHeader);
        LibraryPurchase.FindReturnShipmentHeader(ReturnShipmentHeader, PurchaseHeader."No.");

        // [GIVEN] Custom Report Selection with Vendor "V", Usage "Posted Return Shipment".
        InsertCustomReportSelectionVendor(
          CustomReportSelection, ReturnShipmentHeader."Buy-from Vendor No.", GetPurchaseReturnShipmentReportID,
          false, false, '', CustomReportSelection.Usage::"P.Ret.Shpt.");
        Commit();

        // [WHEN] Print Posted Return Shipment.
        ReturnShipmentHeader.SetRecFilter();
        ReturnShipmentHeader.PrintRecords(false);

        // [THEN] Chosen report is used for printing.
        LibraryXMLRead.Initialize(LibraryVariableStorage.DequeueText());
        LibraryXMLRead.VerifyAttributeValue('ReportDataSet', 'id', Format(GetPurchaseReturnShipmentReportID));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorReportSelectionsPRetShptModalPageHandler')]
    [Scope('OnPrem')]
    procedure SelectPostedReturnShipmentOnVendorReportSelections()
    var
        CustomReportSelection: Record "Custom Report Selection";
        VendorCard: TestPage "Vendor Card";
        Usage: Option "Purchase Order","Vendor Remittance","Vendor Remittance - Posted Entries","Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 300028] Select Posted Return Shipment value on the Vendor Report Selections page.
        Initialize();

        // [WHEN] Open page "Vendor Report Selections" for selected Vendor, set Usage to "Posted Return Shipment", close page.
        LibraryVariableStorage.Enqueue(Usage::"Posted Return Shipment");
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", LibraryPurchase.CreateVendorNo);
        VendorCard.VendorReportSelections.Invoke();

        // [THEN] Usage is "P.Ret.Shpt." for Custom Report Selection for this Vendor.
        CustomReportSelection.SetRange("Source Type", DATABASE::Vendor);
        CustomReportSelection.SetRange("Source No.", VendorCard."No.".Value);
        CustomReportSelection.FindFirst();
        CustomReportSelection.TestField(Usage, CustomReportSelection.Usage::"P.Ret.Shpt.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementOKRequestPageHandler,DownloadAttachmentNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmailCustomerStatement()
    begin
        EmailCustomerStatementInternal();
    end;

    procedure EmailCustomerStatementInternal()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        ConnectorMock: Codeunit "Connector Mock";
        CustomerCard: TestPage "Customer Card";
        ReportOutput: Option Print,Preview,PDF,Email,Excel,XML;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Statement]
        // [SCENARIO 300470] Send to email Customer Statement in case a document layout is used for email body.
        Initialize();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] Custom Report Selection with Customer "C", Usage "Customer Statement", Report ID = 116 (Statement), "Use for Email Body" = TRUE.
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";

        InsertReportSelections(
          ReportSelections, GetCustomerStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, CustomerNo, GetCustomerStatementReportID(), true, true,
          CustomReportLayout.InitBuiltInLayout(GetCustomerStatementReportID(), CustomReportLayout.Type::Word.AsInteger()),
          'abc@abc.abc', CustomReportSelection.Usage::"C.Statement");
        Commit();

        // [WHEN] Run Statement report for the Customer "C" with "Report Output" = Email.
        LibraryVariableStorage.Enqueue(ReportOutput::Email);
        LibraryVariableStorage.Enqueue(CustomerNo);
        CustomerCard.OpenEdit();
        CustomerCard."Report Statement".Invoke();

        // [THEN] "Last Statement No." for Customer "C" increases by 1.
        // [THEN] Only one Interaction Log Entry is inserted.
        Customer.Get(CustomerNo);
        Customer.TestField("Last Statement No.", 1);
        FindInteractionLogEntriesByCustomerNo(InteractionLogEntry, CustomerNo, InteractionLogEntry."Document Type"::"Sales Stmnt.");
        Assert.RecordCount(InteractionLogEntry, 1);
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
        InsertCustomReportSelectionCustomer(CustomReportSelection, CustomerNo, 1306, false, false, '', '', CustomReportSelection.Usage::"S.Invoice");
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
    [HandlerFunctions('TestAddressEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure GetSendToEmailFromContactsFilter()
    begin
        GetSendToEmailFromContactsFilterInternal();
    end;

    procedure GetSendToEmailFromContactsFilterInternal()
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
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Email.Invoke();
        // [THEN] EmailDialog appeared, "Send to" = "E1";"E2"
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), EmailList, 'Wrong send to email dialog.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearSendToEmail()
    var
        CustomReportSelection: Record "Custom Report Selection";
        CompanyContactNo: Code[20];
        i: Integer;
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
        Initialize();

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
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetEmailBodyForCust(
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
          ReportSelections, GetCustomerStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

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
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(StatementTitlePdfTxt, Customer.Name));
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomBaseFileName_Single()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        CustomReportTitle: Text;
    begin
        // [SCENARIO 364825] Codeunit "Custom Layout Reporting".SetOutputFileBaseName() in case of single PDF print
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Report Selection where Usage = "Customer Statement", Report ID = 116 (Statement)
        // [GIVEN] Customer (Name = "A") with posted invoice
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        Customer.SetFilter("No.", SalesInvoiceHeader."Sell-to Customer No.");

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [WHEN] Run Statement report for the customer "A" using EndDate = "22-07-2020" and SetOutputFileBaseName("X")
        CustomReportTitle := LibraryUtility.GenerateGUID();
        RunCStatementViaCustomLayoutReporting(Customer, CustomReportTitle);

        // [THEN] One pdf file is generated with name "X for A as of 2020-07-22.pdf"
        LibraryTempNVBufferHandler.AssertEntry(
            GetStatementTitlePdf(CustomReportTitle, SalesInvoiceHeader."Sell-to Customer Name"));
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomBaseFileName_Multi()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: array[2] of Record "Sales Invoice Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        CustomReportTitle: Text;
    begin
        // [SCENARIO 364825] Codeunit "Custom Layout Reporting".SetOutputFileBaseName() in case of multi PDF print
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Report Selection where Usage = "Customer Statement", Report ID = 116 (Statement)
        // [GIVEN] Two customers (Name = "A", "B") with posted invoices
        CreateAndPostSalesInvoice(SalesInvoiceHeader[1]);
        CreateAndPostSalesInvoice(SalesInvoiceHeader[2]);
        Customer.SetFilter(
            "No.", '%1|%2',
            SalesInvoiceHeader[1]."Sell-to Customer No.",
            SalesInvoiceHeader[2]."Sell-to Customer No.");

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [WHEN] Run Statement report for both customers "A, "B"" using EndDate = "22-07-2020" and SetOutputFileBaseName("X")
        CustomReportTitle := LibraryUtility.GenerateGUID();
        RunCStatementViaCustomLayoutReporting(Customer, CustomReportTitle);

        // [THEN] Two pdf file is generated with names:
        // [THEN] "X for A as of 2020-07-22.pdf"
        // [THEN] "X for B as of 2020-07-22.pdf"
        LibraryTempNVBufferHandler.AssertEntry(
            GetStatementTitlePdf(CustomReportTitle, SalesInvoiceHeader[1]."Sell-to Customer Name"));
        LibraryTempNVBufferHandler.AssertEntry(
            GetStatementTitlePdf(CustomReportTitle, SalesInvoiceHeader[2]."Sell-to Customer Name"));
        LibraryTempNVBufferHandler.AssertQueueEmpty();
    end;

    [Test]
    [HandlerFunctions('TestAddressEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestEmailBodyOnlyWithOrderAddress()
    begin
        EmailBodyOnlyWithOrderAddress();
    end;

    procedure EmailBodyOnlyWithOrderAddress()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO 357821] Sell-to E-mail field value is not populated to the Send Email dialog
        Initialize();

        // [GIVEN] New Customer with Contact is created. Email field is specified.
        LibraryMarketing.CreateCompanyContact(Contact);
        UpdateContactEmail(Contact, LibraryUtility.GenerateRandomEmail());
        CreateCustomerWithContact(Customer, Contact);
        Customer.TestField("E-Mail");

        // [GIVEN] New Sales Invoice is created and posted for the created Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        SalesHeader.TestField("Sell-to E-Mail");

        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Report selection for Invoice is not used for email attachment
        SetupReportSelections(false, true);

        // [WHEN] Invoke Send by Email
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice.Email.Invoke();

        // [THEN] 'To' field on the Send Email dialog have to be filled
        Assert.AreEqual(SalesHeader."Sell-to E-Mail", LibraryVariableStorage.DequeueText(), WrongEmailAddressErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ContactListHandler')]
    procedure GetSendToEmailContactListWithBillToCustomerContacts()
    var
        Customer: array[2] of Record Customer;
        CustomReportSelection: Record "Custom Report Selection";
        ContBusRel: Record "Contact Business Relation";
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        i: Integer;
    begin
        // [SCENARIO 369122] Contacts from "Bill-to Customer No." are added to the list of contacts of original customer while select emails for document layout
        Initialize();

        // [GIVEN] Customer "C1", contacts "CC11".."CC13", sales quote customer report selection
        LibrarySales.CreateCustomer(Customer[1]);
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, Customer[1]."No.");
        ContBusRel.FindContactsByRelation(CompanyContact, ContBusRel."Link to Table"::Customer, Customer[1]."No.");
        LibraryVariableStorage.Enqueue(CompanyContact."No.");
        for i := 1 to 2 do begin
            Clear(PersonContact);
            LibraryMarketing.CreatePersonContact(PersonContact);
            PersonContact.Validate("Company No.", CompanyContact."No.");
            PersonContact.Modify(true);
        end;

        // [GIVEN] Customer "C2", contacts "CC21".."CC22"
        LibrarySales.CreateCustomer(Customer[2]);
        ContBusRel.FindContactsByRelation(CompanyContact, ContBusRel."Link to Table"::Customer, Customer[2]."No.");
        LibraryVariableStorage.Enqueue(CompanyContact."No.");
        Clear(PersonContact);
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify(true);

        // [GIVEN] Customer "C1"."Bill-to Customer No." = "C2"
        Customer[1].Validate("Bill-to Customer No.", Customer[2]."No.");
        Customer[1].Modify(true);

        // [WHEN] Select contacts to get emails
        CustomReportSelection.GetSendToEmailFromContactsSelection(ContBusRel."Link to Table"::Customer.AsInteger(), Customer[1]."No.");

        // [THEN] Contact list page contains 5 records with "CC11".."CC13" and "CC21".."CC22" contacts (verified in ContactListHandler)

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ContactListHandler')]
    procedure GetSendToEmailContactListWithPayToVendorContacts()
    var
        Vendor: array[2] of Record Vendor;
        CustomReportSelection: Record "Custom Report Selection";
        ContBusRel: Record "Contact Business Relation";
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        i: Integer;
    begin
        // [SCENARIO 369122] Contacts from "Pay-to Vendor No." are added to the list of contacts of original vendor while select emails for document layout
        Initialize();

        // [GIVEN] Vendor "V1", contacts "VC11".."VC13", sales quote customer report selection
        LibraryPurchase.CreateVendor(Vendor[1]);
        CreatePurchaseQuoteCustomReportSelection(CustomReportSelection, Vendor[1]."No.");
        ContBusRel.FindContactsByRelation(CompanyContact, ContBusRel."Link to Table"::Vendor, Vendor[1]."No.");
        LibraryVariableStorage.Enqueue(CompanyContact."No.");
        for i := 1 to 2 do begin
            Clear(PersonContact);
            LibraryMarketing.CreatePersonContact(PersonContact);
            PersonContact.Validate("Company No.", CompanyContact."No.");
            PersonContact.Modify(true);
        end;

        // [GIVEN] Vendor "V2", contacts "VC21".."VC22"
        LibraryPurchase.CreateVendor(Vendor[2]);
        ContBusRel.FindContactsByRelation(CompanyContact, ContBusRel."Link to Table"::Vendor, Vendor[2]."No.");
        LibraryVariableStorage.Enqueue(CompanyContact."No.");
        Clear(PersonContact);
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify(true);

        // [GIVEN] Vendor "V1"."Pay-to Vendor No." = "V2"
        Vendor[1].Validate("Pay-to Vendor No.", Vendor[2]."No.");
        Vendor[1].Modify(true);

        // [WHEN] Select contacts to get emails
        CustomReportSelection.GetSendToEmailFromContactsSelection(ContBusRel."Link to Table"::Vendor.AsInteger(), Vendor[1]."No.");

        // [THEN] Contact list page contains 5 records with "VC11".."VC13" and "VC21".."VC22" contacts (verified in ContactListHandler)

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SelectSendingOptionHandler,TestAddressEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure BuyFromContactNoEmailWhenSendingPurchaseDocument()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Email] [Purchase]
        // [SCENARIO 372081] Purchase document Send suggests E-mail of "Buy-from Contact No.".
        Initialize();
        SetupReportSelectionsVendor(true, true);

        // [GIVEN] Vendor with E-mail "e1@v.com".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Vendor.Modify(true);

        // [GIVEN] Person Contact "C" with Email "e2@v.com" for Vendor.
        LibraryMarketing.CreatePersonContact(Contact);
        Commit();
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
        Contact.Validate("Company No.", ContactBusinessRelation."Contact No.");
        Contact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Contact.Modify(true);

        // [GIVEN] Purchase Order with "Buy-from Contact No." = "C".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Buy-from Contact No.", Contact."No.");
        PurchaseHeader.Modify(true);

        // [WHEN] Choosing Send for Purchase Order.
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] In opened Email Dialog field Email is equal to e2@v.com".
        Assert.AreEqual(Contact."E-Mail", LibraryVariableStorage.DequeueText(), WrongEmailAddressErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerReportSelectionsHandler,CustomReportLayoutsHandler')]
    [Scope('OnPrem')]
    procedure CustomerDocumentLayoutsSelectCustomReportLayout()
    var
        Customer: Record Customer;
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI] [Custom Report Layout]
        // [SCENARIO 380458] User is able to select custom report layout in the customer document layouts
        Initialize();

        // [GIVEN] Customer with custom report selection "CRS" and new custom report layout "CRL"
        LibrarySales.CreateCustomer(Customer);
        CreateSalesQuoteCustomReportSelection(CustomReportSelection, Customer."No.");
        CreateSalesQuoteCustomLayout(CustomReportLayout);
        LibraryVariableStorage.Enqueue(CustomReportLayout.Code);
        LibraryVariableStorage.Enqueue(CustomReportLayout.Description);

        // [WHEN] Select custom report layout from document layouts (CustomerReportSelectionsHandler, CustomReportLayoutsHandler)
        CustomerCard.OpenView();
        CustomerCard.GoToRecord(Customer);
        CustomerCard.CustomerReportSelections.Invoke();

        // [THEN] CRS."Customer Layout Description" = CRL."Description" (verified in CustomerReportSelectionsHandler)
        // [THEN] CRS."Custom Report Layout Code" = CRL."Code"
        CustomReportSelection.Get(CustomReportSelection."Source Type", CustomReportSelection."Source No.", CustomReportSelection.Usage, CustomReportSelection.Sequence);
        Assert.AreEqual(CustomReportLayout.Code, CustomReportSelection."Custom Report Layout Code", 'Wrong custom report layout code');
    end;

    [Test]
    [HandlerFunctions('VendorReportSelectionsHandler,CustomReportLayoutsHandler')]
    [Scope('OnPrem')]
    procedure VendorDocumentLayoutsSelectCustomReportLayout()
    var
        Vendor: Record Vendor;
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [UI] [Custom Report Layout]
        // [SCENARIO 380458] User is able to select custom report layout in the vendor document layouts
        Initialize();

        // [GIVEN] Vendor with custom report selection "CRS" and new custom report layout "CRL"
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseQuoteCustomReportSelection(CustomReportSelection, Vendor."No.");
        CreatePurchaseQuoteCustomLayout(CustomReportLayout);
        LibraryVariableStorage.Enqueue(CustomReportLayout.Code);
        LibraryVariableStorage.Enqueue(CustomReportLayout.Description);

        // [WHEN] Select custom report layout from document layouts (VendorReportSelectionsHandler, CustomReportLayoutsHandler)
        VendorCard.OpenView();
        VendorCard.GoToRecord(Vendor);
        VendorCard.VendorReportSelections.Invoke();

        // [THEN] CRS."Vendor Layout Description" = CRL."Description" (verified in VendorReportSelectionsHandler)
        // [THEN] CRS."Custom Report Layout Code" = CRL."Code"
        CustomReportSelection.Get(CustomReportSelection."Source Type", CustomReportSelection."Source No.", CustomReportSelection.Usage, CustomReportSelection.Sequence);
        Assert.AreEqual(CustomReportLayout.Code, CustomReportSelection."Custom Report Layout Code", 'Wrong custom report layout code');
    end;

    [Test]
    [HandlerFunctions('CustReportSelectionsCopyFromModalPageHandler')]
    procedure CopyFromReportSelectionOnDocumentLayoutPageForCustomer()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 423000] Run "Copy from Report Selection" action from Document Layouts page for customer.
        Initialize();

        // [GIVEN] Report Selections: Quote, Customer Statement,Reminder ("R1", "R2", "R3").
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Quote", 1304);
        LibraryERM.SetupReportSelection("Report Selection Usage"::Reminder, 117);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Shipment", 208);
        ReportSelections.SetFilter(Usage, '%1|%2|%3', "Report Selection Usage"::"S.Quote", "Report Selection Usage"::Reminder, "Report Selection Usage"::"S.Shipment");

        // [GIVEN] Customer with custom report selection "CR".
        LibrarySales.CreateCustomer(Customer);
        InsertCustomReportSelectionCustomer(CustomReportSelection, Customer."No.", 1306, false, false, '', '', CustomReportSelection.Usage::"S.Invoice");

        // [WHEN] Open Document Layouts page from Customer Card, run "Copy from Report Selection" using modal page handler.
        CustomerCard.OpenEdit();
        CustomerCard.GoToKey(Customer."No.");
        CustomerCard.CustomerReportSelections.Invoke();

        // [THEN] Custom Report Selection contains 4 records with "R1", "R2", "R3", "CR" reports for Customer.
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Customer, Customer."No.", 4);
    end;

    [Test]
    [HandlerFunctions('CustReportSelectionsCopyFromModalPageHandler')]
    procedure CopyFromReportSelectionOnDocumentLayoutPageForCustomerWithSpecialChars()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 423000] Run "Copy from Report Selection" action from Document Layouts page for customer with special characters in No. field.
        Initialize();

        // [GIVEN] Report Selections: Quote, Customer Statement,Reminder ("R1", "R2", "R3").
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Quote", 1304);
        LibraryERM.SetupReportSelection("Report Selection Usage"::Reminder, 117);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"S.Shipment", 208);
        ReportSelections.SetFilter(Usage, '%1|%2|%3', "Report Selection Usage"::"S.Quote", "Report Selection Usage"::Reminder, "Report Selection Usage"::"S.Shipment");

        // [GIVEN] Customer with No. "ABC&d^" and with custom report selection "CR".
        Customer.Validate("No.", 'ABC&d^');
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Insert(true);
        InsertCustomReportSelectionCustomer(CustomReportSelection, Customer."No.", 1306, false, false, '', '', CustomReportSelection.Usage::"S.Invoice");

        // [WHEN] Open Document Layouts page from Customer Card, run "Copy from Report Selection" using modal page handler.
        CustomerCard.OpenEdit();
        CustomerCard.GoToKey(Customer."No.");   // Filter.SetFilter does not work for No. with special chars
        CustomerCard.CustomerReportSelections.Invoke();

        // [THEN] Custom Report Selection contains 4 records with "R1", "R2", "R3", "CR" reports for Customer.
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Customer, Customer."No.", 4);
    end;

    [Test]
    [HandlerFunctions('VendorReportSelectionsCopyFromModalPageHandler')]
    procedure CopyFromReportSelectionOnDocumentLayoutPageForVendor()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 423000] Run "Copy from Report Selection" action from Document Layouts page for vendor.
        Initialize();

        // [GIVEN] Report Selections: Order, Vendor Remittance, Vendor Remittance - Posted Entries, Return Shipment ("R1", "R2", "R3").
        LibraryERM.SetupReportSelection("Report Selection Usage"::"P.Order", 1322);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"V.Remittance", 399);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"P.Ret.Shpt.", 6636);
        ReportSelections.SetFilter(Usage, '%1|%2|%3', "Report Selection Usage"::"P.Order", "Report Selection Usage"::"V.Remittance", "Report Selection Usage"::"P.Ret.Shpt.");

        // [GIVEN] Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Open Document Layouts page from Vendor Card, run "Copy from Report Selection" using modal page handler.
        VendorCard.OpenEdit();
        VendorCard.GoToKey(Vendor."No.");
        VendorCard.VendorReportSelections.Invoke();

        // [THEN] Custom Report Selection contains 3 records with "R1", "R2", "R3" reports for Vendor.
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Vendor, Vendor."No.", 3);
    end;

    [Test]
    [HandlerFunctions('VendorReportSelectionsCopyFromModalPageHandler')]
    procedure CopyFromReportSelectionOnDocumentLayoutPageForVendorWithSpecialChars()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 423000] Run "Copy from Report Selection" action from Document Layouts page for vendor with special characters in No. field.
        Initialize();

        // [GIVEN] Report Selections: Order, Vendor Remittance, Vendor Remittance - Posted Entries, Return Shipment ("R1", "R2", "R3").
        LibraryERM.SetupReportSelection("Report Selection Usage"::"P.Order", 1322);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"V.Remittance", 399);
        LibraryERM.SetupReportSelection("Report Selection Usage"::"P.Ret.Shpt.", 6636);
        ReportSelections.SetFilter(Usage, '%1|%2|%3', "Report Selection Usage"::"P.Order", "Report Selection Usage"::"V.Remittance", "Report Selection Usage"::"P.Ret.Shpt.");

        // [GIVEN] Vendor with No. "&bc$".
        Vendor.Validate("No.", '&bc$');
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Insert(true);

        // [WHEN] Open Document Layouts page from Vendor Card, run "Copy from Report Selection" using modal page handler.
        VendorCard.OpenEdit();
        VendorCard.GoToKey(Vendor."No.");
        VendorCard.VendorReportSelections.Invoke();

        // [THEN] Custom Report Selection contains 3 records with "R1", "R2", "R3" reports for Vendor.
        VerifyCopiedCustomReportSelection(ReportSelections, Database::Vendor, Vendor."No.", 3);
    end;

    [Test]
    [HandlerFunctions('ProFormInvoiceCustomerReportSelectionsHandler')]
    procedure VerifyProFormaInvoiceIsAvailableInDocumentLayouts()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Custom Report Selection]
        // [SCENARIO 449768] Verify Pro forma invoice report is available in Customer Documents Layout
        Initialize();

        // [GIVEN] Report Selections: Pro Forma Invoice
        LibraryERM.SetupReportSelection("Report Selection Usage"::"Pro Forma S. Invoice", 1302);
        ReportSelections.SetFilter(Usage, '%1', "Report Selection Usage"::"Pro Forma S. Invoice");

        // [GIVEN] Customer with custom report selection "CR".
        LibrarySales.CreateCustomer(Customer);
        InsertCustomReportSelectionCustomer(CustomReportSelection, Customer."No.", 1302, false, false, '', '', CustomReportSelection.Usage::"Pro Forma S. Invoice");

        // [WHEN] Open Document Layouts page from Customer Card using modal page handler and assign Usage as Pro Forma Invoice
        CustomerCard.OpenEdit();
        CustomerCard.GoToKey(Customer."No.");
        CustomerCard.CustomerReportSelections.Invoke();

        // [THEN] Verify Pro Forma S. Invoice is available in Custom Report Selection
        CustomReportSelection.Reset();
        CustomReportSelection.SetRange("Source Type", Database::Customer);
        CustomReportSelection.SetRange("Source No.", Customer."No.");
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"Pro Forma S. Invoice");
        Assert.RecordIsNotEmpty(CustomReportSelection);
    end;

    [Test]
    [HandlerFunctions('CustomReportLayoutsHandlerCancel')]
    [Scope('OnPrem')]
    procedure VerifySalesInvoiceCustomReportNotRevertsBackToRdlc()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
        LayoutCode: Code[20];
    begin
        // [SCENARIO 466237] D365 BC - Custom report reverts back to RDLC when using Select Layout without making a choice (click Cancel).
        Initialize();

        // [GIVEN] Delete and create new Custom Report Layouts
        CustomReportLayout.SetRange("Report ID", StandardSalesInvoiceReportID());
        CustomReportLayout.DeleteAll();

        if ReportLayoutSelection.Get(StandardSalesInvoiceReportID(), CompanyName) then
            ReportLayoutSelection.Delete();

        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID(), CustomReportLayout.Type::RDLC.AsInteger());
        CustomReportLayout.Get(LayoutCode);

        // [THEN] Create report layout selection with new custom layout 
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := StandardSalesInvoiceReportID();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
        ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
        ReportLayoutSelection.Insert(true);

        // [WHEN] Invoke Select Layout from Report Layout Selection Page
        ReportLayoutSelectionPage.OpenEdit;
        ReportLayoutSelectionPage.Filter.SetFilter("Report ID", Format(StandardSalesInvoiceReportID()));
        ReportLayoutSelectionPage.SelectLayout.Invoke();
        ReportLayoutSelectionPage.Close();

        // [VERIFY] Verify: Report Layout Selection should not change back to RDLC
        ReportLayoutSelection.Get(StandardSalesInvoiceReportID(), CompanyName);
        Assert.AreEqual(LayoutCode, ReportLayoutSelection."Custom Report Layout Code", LayoutCodeShouldNotChangedErr);
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        DummyEmailItem: Record "Email Item";
        InventorySetup: Record "Inventory Setup";
        CompanyInformation: Record "Company Information";
        ReportLayoutSelection: Record "Report Layout Selection";
        LibraryWorkflow: Codeunit "Library - Workflow";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Report Selections Tests");

        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.AssertEmpty();
        CustomReportSelection.DeleteAll();
        ReportSelections.DeleteAll();
        ReportLayoutSelection.DeleteAll();
        CreateDefaultReportSelection();
        LibrarySetupStorage.Restore();
        LibraryWorkflow.SetUpEmailAccount();

        if Initialized then
            exit;

        Initialized := true;

        SetupInvoiceReportLayoutSelection();
        CustomMessageTypeTxt := Format(DummyEmailItem."Message Type"::"Custom Message");
        FromEmailBodyTemplateTxt := Format(DummyEmailItem."Message Type"::"From Email Body Template");

        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();

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

    [Scope('OnPrem')]
    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor);
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
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Validate(Address, 'A');
        CountryRegion.FindFirst();
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate(City, 'A');
        Customer.Validate("Post Code", 'A');
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, 'A');
        Vendor.Validate(Address, 'A');
        CountryRegion.FindFirst();
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate(City, 'A');
        Vendor.Validate("Post Code", 'A');
        Vendor.Modify(true);
        exit(Vendor."No.");
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
        InteractionLogEntry.FindSet();
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; CustomerNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage")
    begin
        with CustomReportSelection do begin
            Validate("Source Type", DATABASE::Customer);
            Validate("Source No.", CustomerNo);
            Validate(Usage, ReportUsage);
            Validate(Sequence, Count + 1);
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Email Body Layout Code", EmailBodyLayoutCode);
            Validate("Send To Email", SendToAddress);
            Insert();
        end;
    end;

    local procedure InsertCustomReportSelectionVendor(var CustomReportSelection: Record "Custom Report Selection"; VendorNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage")
    begin
        with CustomReportSelection do begin
            Validate("Source Type", DATABASE::Vendor);
            Validate("Source No.", VendorNo);
            Validate(Usage, ReportUsage);
            Validate(Sequence, Count + 1);
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Send To Email", SendToAddress);
            Insert();
        end;
    end;

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage")
    begin
        with ReportSelections do begin
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

    [Scope('OnPrem')]
    procedure OpenNewPurchaseOrder(var PurchaseOrderPage: TestPage "Purchase Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.GotoRecord(PurchaseHeader);
    end;

    local procedure SetupReportSelections(UseForEmailAttachment: Boolean; UseForEmailBody: Boolean)
    var
        OldReportSelections: Record "Report Selections";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        GetCustomBodyLayout(CustomReportLayout);

        OldReportSelections.Reset();
        OldReportSelections.SetRange(Usage, OldReportSelections.Usage::"S.Invoice");
        OldReportSelections.FindFirst();

        UpdateReportSelections(
          OldReportSelections.Usage::"S.Invoice", CustomReportLayout."Report ID", UseForEmailAttachment, UseForEmailBody,
          CustomReportLayout.Code);
    end;

    local procedure SetupReportSelectionsVendor(UseForEmailAttachment: Boolean; UseForEmailBody: Boolean)
    var
        OldReportSelections: Record "Report Selections";
        DummyCustomReportLayout: Record "Custom Report Layout";
    begin
        OldReportSelections.Reset();
        OldReportSelections.SetRange(Usage, OldReportSelections.Usage::"P.Order");
        OldReportSelections.FindFirst();

        UpdateReportSelections(
          OldReportSelections.Usage::"P.Order", GetReportIDForPurchaseOrder, UseForEmailAttachment, UseForEmailBody,
          DummyCustomReportLayout.Code);
    end;

    local procedure SetupInvoiceReportLayoutSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Company Name" := CompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Sales - Invoice";
        ReportLayoutSelection.Insert();

        // Setup for purchase order
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Company Name" := CompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Word (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Purchase - Order";
        ReportLayoutSelection.Insert();
    end;

    local procedure CreateDefaultReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
        CreateReportSelection(ReportSelections.Usage::"P.Order", '2', REPORT::"Standard Purchase - Order");
        CreateReportSelection(ReportSelections.Usage::"S.Quote", '3', REPORT::"Standard Sales - Quote");
    end;

    local procedure CreateReportSelection(Usage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure UpdateReportSelections(NewUsage: Enum "Report Selection Usage"; NewReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; NewEmailBodyLayout: Code[20])
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, NewUsage);
        ReportSelections.FindFirst();
        ReportSelections.Validate("Report ID", NewReportID);
        ReportSelections.Validate("Use for Email Attachment", UseForEmailAttachment);
        ReportSelections.Validate("Use for Email Body", UseForEmailBody);

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
    var
        ReportLayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        CustomReportLayout.SetRange("Report ID", GetStandardSalesInvoiceReportID());
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if not CustomReportLayout.FindLast() then begin
            ReportLayoutList.SetRange("Report ID", GetStandardSalesInvoiceReportID());
            ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
            ReportLayoutList.FindFirst();

            TempBlob.CreateOutStream(OutStr);
            ReportLayoutList.Layout.ExportStream(OutStr);
            TempBlob.CreateInStream(InStr);

            CustomReportLayout.Init();
            CustomReportLayout."Report ID" := GetStandardSalesInvoiceReportID();
            CustomReportLayout.Code := CopyStr(StrSubstNo('MS-X%1', Random(9999)), 1, 10);
            CustomReportLayout."File Extension" := 'docx';
            CustomReportLayout.Description := 'Test report layout';
            CustomReportLayout.Type := CustomReportLayout.Type::Word;
            CustomReportLayout.Layout.CreateOutStream(OutStr);

            CopyStream(OutStr, InStr);

            CustomReportLayout.Insert();
        end;
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

    local procedure RunCStatementViaCustomLayoutReporting(var Customer: Record Customer; OutputFileBaseName: Text)
    var
        ReportSelections: Record "Report Selections";
        RecRef: RecordRef;
        ReportOutput: Option Print,Preview,PDF,Email,Excel,XML;
    begin
        InsertReportSelections(
          ReportSelections, GetCustomerStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");
        LibraryVariableStorage.Enqueue(ReportOutput::PDF);
        LibraryVariableStorage.Enqueue(Customer.GetFilter("No."));
        RecRef.GetTable(Customer);
        RecRef.SetView(Customer.GetView());
        RunReportViaCustomLayoutReporting(
            ReportSelections.Usage::"C.Statement", OutputFileBaseName, RecRef, Customer.FieldName("No."),
            Database::Customer, Customer.FieldName("No."), true);
    end;

    local procedure RunReportViaCustomLayoutReporting(ReportUsage: Enum "Report Selection Usage"; OutputFileBaseName: Text; var DataRecordRef: RecordRef; SourceJoinFieldName: Text; DataRecordJoinTable: Integer; IteratorTableFieldName: Text; DataItemTableSameAsIterator: Boolean)
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        CustomLayoutReporting.InitializeReportData(
            ReportUsage, DataRecordRef, SourceJoinFieldName,
            DataRecordJoinTable, IteratorTableFieldName, DataItemTableSameAsIterator);
        CustomLayoutReporting.SetOutputFileBaseName(OutputFileBaseName);
        CustomLayoutReporting.ProcessReport();
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;

    local procedure GetStatementTitlePdf(ReportTitle: Text; CustomerName: Text): Text
    begin
        exit(StrSubstNo(ReportTitleTemplatePdfTxt, ReportTitle, CustomerName, Format(WorkDate(), 0, 9)));
    end;

    local procedure VerifySendEmailPage(ExpectedType: Text; ExpectedBodyText: Text; ExpectedAttachmentName: Text)
    var
        ActualType: Text;
        ActualBodyText: Text;
        ActualAttachmentFileName: Text;
        BodyTextOK: Boolean;
        AttachmentNameOK: Boolean;
    begin
        ActualType := LibraryVariableStorage.DequeueText();
        ActualBodyText := LibraryVariableStorage.DequeueText();
        ActualAttachmentFileName := LibraryVariableStorage.DequeueText();

        if ExpectedBodyText = '' then
            BodyTextOK := ExpectedBodyText = ActualBodyText
        else
            BodyTextOK := StrPos(ActualBodyText, ExpectedBodyText) > 0;

        if ExpectedAttachmentName = '' then
            AttachmentNameOK := ExpectedAttachmentName = ActualAttachmentFileName
        else
            AttachmentNameOK := StrPos(ActualAttachmentFileName, ExpectedAttachmentName) > 0;

        Assert.AreEqual(ExpectedType, ActualType, 'Message type is wrong on Email Editor');
        Assert.IsTrue(BodyTextOK, 'Email Body text is wrong on Email Editor, check if the right template was selected');
        Assert.IsTrue(AttachmentNameOK, 'Attachment File Name text is wrong on Email Editor');
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

    local procedure CreatePurchaseQuoteCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; SourceNo: Code[20])
    begin
        CustomReportSelection.Init();
        CustomReportSelection."Source Type" := Database::Vendor;
        CustomReportSelection."Source No." := SourceNo;
        CustomReportSelection.Usage := CustomReportSelection.Usage::"P.Quote";
        CustomReportSelection."Report ID" := 404;
        CustomReportSelection.Insert();
    end;

    local procedure CreateEmail(MaxLength: Integer): Text
    var
        i: Integer;
        Email: Text;
    begin
        Email := LibraryUtility.GenerateGUID + '@';
        for i := 1 to MaxLength DIV 10 - 1 do
            Email += LibraryUtility.GenerateGUID();

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

    local procedure UpdateContactEmail(var Contact: Record Contact; Email: Text[45])
    begin
        Contact.Validate("E-Mail", Email);
        Contact.Modify();
    end;

    local procedure CreateCustomerWithContact(var Customer: Record Customer; Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, Contact."No.", Customer."No.");
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify();
    end;

    local procedure CreateSalesQuoteCustomLayout(var CustomReportLayout: Record "Custom Report Layout")
    begin
        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := 1304;
        CustomReportLayout.Type := CustomReportLayout.Type::Word;
        CustomReportLayout.Description := LibraryUtility.GenerateGUID();
        CustomReportLayout.Insert(true);
    end;

    local procedure CreatePurchaseQuoteCustomLayout(var CustomReportLayout: Record "Custom Report Layout")
    begin
        Clear(CustomReportLayout);
        CustomReportLayout."Report ID" := 404;
        CustomReportLayout.Type := CustomReportLayout.Type::Word;
        CustomReportLayout.Description := LibraryUtility.GenerateGUID();
        CustomReportLayout.Insert(true);

        Clear(CustomReportLayout);
        CustomReportLayout."Report ID" := 404;
        CustomReportLayout.Type := CustomReportLayout.Type::Word;
        CustomReportLayout.Description := LibraryUtility.GenerateGUID();
        CustomReportLayout.Insert(true);
    end;

    local procedure StandardSalesInvoiceReportID(): Integer
    begin
        exit(Report::"Standard Sales - Invoice");
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
    procedure PurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementOKRequestPageHandler(var Statement: TestRequestPage Statement)
    begin
        Statement."Start Date".SetValue(WorkDate());
        Statement."End Date".SetValue(WorkDate());
        Statement.ReportOutput.SetValue(LibraryVariableStorage.DequeueInteger);
        Statement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Statement.OK.Invoke;
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
    procedure SelectSendingOptionHandlerPrint(var SelectSendingOption: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOption.Printer.SetValue(DocumentSendingProfile.Printer::"Yes (Prompt for Settings)");
        SelectSendingOption."E-Mail".SetValue(DocumentSendingProfile."E-Mail"::No);
        SelectSendingOption.Disk.SetValue(DocumentSendingProfile.Disk::PDF);
        SelectSendingOption.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    var
        EmailItem: Record "Email Item";
    begin
        LibraryVariableStorage.Enqueue(Format(EmailItem."Message Type"::"From Email Body Template"));
        LibraryVariableStorage.Enqueue(EmailEditor.BodyField.Value);
        LibraryVariableStorage.Enqueue(EmailEditor.Attachments.FileName.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandlerCustomMessage(var EmailEditor: TestPage "Email Editor")
    var
        EmailItem: Record "Email Item";
    begin
        LibraryVariableStorage.Enqueue(Format(EmailItem."Message Type"::"Custom Message"));
        LibraryVariableStorage.Enqueue(EmailEditor.BodyField.Value);
        LibraryVariableStorage.Enqueue(EmailEditor.Attachments.FileName.Value);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestAddressEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.ToField.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
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
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        if Message.StartsWith('Do you want to change') then
            Response := true;
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListHandler(var ContactList: TestPage "Contact List")
    var
        Contact: Record Contact;
        ContactNoFilter: Text;
    begin
        ContactNoFilter := ContactList.Filter.GetFilter("No.");
        Contact.SetFilter("No.", ContactNoFilter);
        Assert.RecordCount(Contact, 5);

        Contact.Reset();
        Contact.SetRange("Company No.", LibraryVariableStorage.DequeueText());
        Assert.RecordCount(Contact, 3);
        Contact.FindSet();
        repeat
            ContactList.GoToRecord(Contact);
        until Contact.Next() = 0;

        Contact.SetRange("Company No.", LibraryVariableStorage.DequeueText());
        Assert.RecordCount(Contact, 2);
        Contact.FindSet();
        repeat
            ContactList.GoToRecord(Contact);
        until Contact.Next() = 0;

        ContactList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerReportSelectionsHandler(var CustomerReportSelections: TestPage "Customer Report Selections")
    begin
        CustomerReportSelections.First();
        CustomerReportSelections."Custom Report Description".Drilldown();
        CustomerReportSelections."Custom Report Description".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    procedure CustReportSelectionsCopyFromModalPageHandler(var CustomerReportSelections: TestPage "Customer Report Selections");
    begin
        CustomerReportSelections.CopyFromReportSelectionsAction.Invoke();
    end;

    [ModalPageHandler]
    procedure VendorReportSelectionsCopyFromModalPageHandler(var VendorReportSelections: TestPage "Vendor Report Selections");
    begin
        VendorReportSelections.CopyFromReportSelectionsAction.Invoke();
    end;

    [ModalPageHandler]
    procedure CustomReportLayoutsHandler(var CustomReportLayouts: TestPage "Custom Report Layouts")
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustomReportLayout.Get(LibraryVariableStorage.DequeueText());
        CustomReportLayouts.GoToRecord(CustomReportLayout);
        CustomReportLayouts.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VendorReportSelectionsHandler(var VendorReportSelections: TestPage "Vendor Report Selections")
    begin
        VendorReportSelections.First();
        VendorReportSelections."Custom Report Description".Drilldown();
        VendorReportSelections."Custom Report Description".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    procedure ProFormInvoiceCustomerReportSelectionsHandler(var CustomerReportSelections: TestPage "Customer Report Selections")
    begin
        CustomerReportSelections.First();
        CustomerReportSelections.Usage2.SetValue('Pro Forma Invoice');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomReportLayoutsHandlerCancel(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.Cancel().Invoke();
    end;
}

