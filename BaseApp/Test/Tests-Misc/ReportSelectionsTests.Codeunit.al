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
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
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

        // Exercise
        PostedSalesInvoice.Print.Invoke;

        // Verify
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTok, PostedSalesInvoice."No.".Value);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDF()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        // Setup
        SetupReportSelections(true, true);
        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Exercise
        PostedSalesInvoice.SendCustom.Invoke;

        // Verify
        VerifySendEmailPage(FromEmailBodyTemplateTxt, TemplateIdentificationTxt, PostedSalesInvoice."No.".Value);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EMailDialogHandler')]
    [Scope('OnPrem')]
    procedure TestSendToEMailAndPDFVendor()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize;

        // Setup
        SetupReportSelectionsVendor(true, true);
        OpenNewPurchaseOrder(PurchaseOrder);

        // Execute
        PurchaseOrder.SendCustom.Invoke;

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
        Initialize;

        OpenNewPostedSalesInvoice(PostedSalesInvoice);
        SetupReportSelections(false, false);

        // Exercise
        asserterror PostedSalesInvoice.Email.Invoke;

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
        Initialize;

        OpenNewPurchaseOrder(PurchaseOrder);
        SetupReportSelectionsVendor(false, false);

        // Exercise
        asserterror PurchaseOrder.SendCustom.Invoke;

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
        Initialize;

        // [GIVEN] Setup Report Selections to run REP1322 as default for Purchase Order.
        SetupReportSelectionsVendor(true, true);
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Purchase Order "PO" with filled "Vendor Invoice No." = "AAA" and "Vendor Order No." = "BBB".
        // [GIVEN] "PO" card page is opened.
        OpenNewPurchaseOrder(PurchaseOrder);
        VendorInvoiceNo := LibraryUtility.GenerateGUID;
        VendorOrderNo := LibraryUtility.GenerateGUID;
        PurchaseOrder."Vendor Invoice No.".SetValue(VendorInvoiceNo);
        PurchaseOrder."Vendor Order No.".SetValue(VendorOrderNo);

        // [WHEN] "Send" ActionButton invoked and printing is selected in SelectSendingOptionHandlerPrint.
        PurchaseOrder.SendCustom.Invoke;

        // [THEN] Printed report dataset contains "AAA" and "BBB" values for "Vendor Invoice No" and "Vendor Order No." fields respectively.
        LibraryReportDataset.LoadDataSetFile;
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
        Initialize;

        // Setup
        SetupReportSelections(true, true);

        OpenNewPostedSalesInvoice(PostedSalesInvoice);

        // Execute
        PostedSalesInvoice.Print.Invoke;

        // Verify
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo', PostedSalesInvoice."No.".Value);

        LibraryVariableStorage.AssertEmpty;
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
    [HandlerFunctions('SalesInvoiceRequestPageHandler,StandardSalesInvoiceRequestPageHandler')]
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
        Commit;

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

        // [THEN] "Standard Sales - Invoice" report prints "InvoiceB" and "InvoiceC"
        Clear(LibraryReportDataset);
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist(DocumentNoTok, SalesInvoiceHeader[1]."No.");
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTok, SalesInvoiceHeader[2]."No.");
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTok, SalesInvoiceHeader[3]."No.");

        // [THEN] "Sales Invoice Nos." is not printed at all
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

        ReportSelections.Init;
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

        ReportSelections.Init;
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
        Commit;

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
        Usage: Option "Purchase Order","Vendor Remittance","Vendor Remittance - Posted Entries","Posted Return Shipment";
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
        Commit;

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
    [HandlerFunctions('StatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmailCustomerStatementBlankEmailAddress()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        ErrorMessages: TestPage "Error Messages";
        CustomerCard: TestPage "Customer Card";
        ReportOutput: Option Print,Preview,PDF,Email,Excel,XML;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Statement]
        // [SCENARIO 312159] Send to email Customer Statement when targent is not specified.
        Initialize;

        // [GIVEN] Custom Report Selection with Customer "C", Usage "Customer Statement", Report ID = 116 (Statement), "Use for Email Body" = TRUE and "Send To Email" is blank.
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";

        InsertReportSelections(
          ReportSelections, GetCustomerStatementReportID, false, false, '', ReportSelections.Usage::"C.Statement");

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, CustomerNo, GetCustomerStatementReportID, true, true,
          CustomReportLayout.InitBuiltInLayout(GetCustomerStatementReportID, CustomReportLayout.Type::Word),
          '', CustomReportSelection.Usage::"C.Statement");
        Commit;

        // [WHEN] Run Statement report for the Customer "C" with "Report Output" = Email.
        LibraryVariableStorage.Enqueue(ReportOutput::Email);
        LibraryVariableStorage.Enqueue(CustomerNo);
        ErrorMessages.Trap;
        CustomerCard.OpenEdit;
        CustomerCard."Report Statement".Invoke;

        Assert.ExpectedMessage('The target email address has not been specified', ErrorMessages.Description.Value);
        ErrorMessages.Close;

        // [THEN] Confirmation message appears, that email couldn't be delivered. It suggests to download attachment.
        // [THEN] "Last Statement No." for Customer "C" increases by 1.
        // [THEN] Only one Interaction Log Entry is inserted.
        Customer.Get(CustomerNo);
        Customer.TestField("Last Statement No.", 0);
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
        Commit;

        // [WHEN] Run "Customer Statement" report for the Customer "C" with "Report Output" = Email.
        LibraryVariableStorage.Enqueue(StandardStatementReportOutput::Email);
        LibraryVariableStorage.Enqueue(CustomerNo);
        ErrorMessages.Trap;
        CustomerCard.OpenEdit;
        CustomerCard."Report Statement".Invoke;
        Commit;

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
        CustomReportSelection.Init;

        // [WHEN] Set "Send to Email" to a string with valid address "test@email.com" and invalid "newtest@"
        asserterror CustomReportSelection.Validate("Send To Email", 'test@email.com;newtest@');

        // [THEN] Error is shown than "newtest@" is not a valid email address
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('The email address "newtest@" is not valid.');
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

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        DummyEmailItem: Record "Email Item";
        InventorySetup: Record "Inventory Setup";
        CompanyInformation: Record "Company Information";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        BindActiveDirectoryMockEvents;
        LibraryVariableStorage.AssertEmpty;
        CustomReportSelection.DeleteAll;
        ReportSelections.DeleteAll;
        ReportLayoutSelection.DeleteAll;
        CreateDefaultReportSelection;
        LibrarySetupStorage.Restore;

        if Initialized then
            exit;

        Initialized := true;

        SetupInvoiceReportLayoutSelection;
        CustomMessageTypeTxt := Format(DummyEmailItem."Message Type"::"Custom Message");
        FromEmailBodyTemplateTxt := Format(DummyEmailItem."Message Type"::"From Email Body Template");

        CompanyInformation.Get;
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryWorkflow.SetUpSMTPEmailSetup;

        Commit;
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
        Customer.Validate(Name, 'A');
        Customer.Validate(Address, 'A');
        CountryRegion.FindFirst;
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
        CountryRegion.FindFirst;
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate(City, 'A');
        Vendor.Validate("Post Code", 'A');
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithCustomNo(var Vendor: Record Vendor; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Delete;
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

    local procedure FindInteractionLogEntriesByCustomerNo(var InteractionLogEntry: Record "Interaction Log Entry"; CustomerNo: Code[20]; DocumentType: Option)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
        InteractionLogEntry.SetRange("Contact No.", ContactBusinessRelation."Contact No.");
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.FindSet;
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; CustomerNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; SendToAddress: Text[200]; ReportUsage: Option)
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

    local procedure InsertCustomReportSelectionVendor(var CustomReportSelection: Record "Custom Report Selection"; VendorNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; SendToAddress: Text[200]; ReportUsage: Option)
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

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; ReportUsage: Option)
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

    [Scope('OnPrem')]
    procedure OpenNewPurchaseOrder(var PurchaseOrderPage: TestPage "Purchase Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrderPage.OpenEdit;
        PurchaseOrderPage.GotoRecord(PurchaseHeader);
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
        OldReportSelections.FindFirst;

        UpdateReportSelections(
          OldReportSelections.Usage::"P.Order", GetReportIDForPurchaseOrder, UseForEmailAttachment, UseForEmailBody,
          DummyCustomReportLayout.Code);
    end;

    local procedure SetupInvoiceReportLayoutSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.Init;
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Sales - Invoice";
        ReportLayoutSelection.Insert;

        // Setup for purchase order
        ReportLayoutSelection.Init;
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Word (built-in)";
        ReportLayoutSelection."Report ID" := REPORT::"Standard Purchase - Order";
        ReportLayoutSelection.Insert;
    end;

    local procedure CreateDefaultReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
        CreateReportSelection(ReportSelections.Usage::"P.Order", '2', REPORT::"Standard Purchase - Order");
        CreateReportSelection(ReportSelections.Usage::"S.Quote", '3', REPORT::"Standard Sales - Quote");
    end;

    local procedure CreateReportSelection(Usage: Integer; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init;
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert;
    end;

    local procedure UpdateReportSelections(NewUsage: Integer; NewReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; NewEmailBodyLayout: Code[20])
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.FilterPrintUsage(NewUsage);
        ReportSelections.FindFirst;
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
    procedure PurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
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
}

