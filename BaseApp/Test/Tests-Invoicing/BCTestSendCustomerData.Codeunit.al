codeunit 138963 "BC Test Send Customer Data"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Send Customer Data]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CustomerInformationTxt: Label 'Account Information';
        SentInvoicesTxt: Label 'Sent Invoices';
        DraftInvoicesTxt: Label 'Draft Invoices';
        QuotesTxt: Label 'Estimates';
        CustomerEmailTxt: Label 'customer@customer.dot';
        MyEmailTxt: Label 'me@my.doc';
        WorkDescrTxt: Label 'Dear customer, please accept our generous offer.';

    [Test]
    [HandlerFunctions('O365ExportCustomerDataPageHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestSendCreateCustomerExcelSheet()
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        BCTestSendCustomerData: Codeunit "BC Test Send Customer Data";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        // [SCENARIO] User can send an email with an excel book to the customer
        Initialize();
        BindSubscription(BCTestSendCustomerData);
        CreateCustomerData(Customer);
        CompanyInformation.Get;
        CompanyInformation."E-Mail" := MyEmailTxt;
        CompanyInformation.Modify;

        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens the customer card and clicks 'Export data'
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.ExportData.DrillDown;
        // Continue execution in O365ExportCustomerDataPageHandler

        // [THEN] There will be created an excel sheet with all relevant customer data and sent to the customer
        // Cleanup.
        UnbindSubscription(BCTestSendCustomerData);
    end;

    [Test]
    [HandlerFunctions('O365ExportCustomerDataPageHandlerOK,CustomerEmailConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWarnCustomerEmail()
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        BCTestSendCustomerData: Codeunit "BC Test Send Customer Data";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        // [SCENARIO] User can send an email with an excel book to the customer
        Initialize();
        BindSubscription(BCTestSendCustomerData);
        CreateCustomer(Customer);
        CompanyInformation.Get;
        CompanyInformation."E-Mail" := '';
        CompanyInformation.Modify;

        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens the customer card and clicks 'Export data'
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.ExportData.DrillDown;
        // Continue execution in O365ExportCustomerDataPageHandler

        // [THEN] There will be created an excel sheet with all relevant customer data and sent to the customer
        // Cleanup.
        UnbindSubscription(BCTestSendCustomerData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCustomerExcelSheet()
    var
        Customer: Record Customer;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        O365EmailCustomerData: Codeunit "O365 Email Customer Data";
        BCTestSendCustomerData: Codeunit "BC Test Send Customer Data";
        ServerFileName: Text;
    begin
        // [SCENARIO] User can send an email with an excel book to the customer
        Initialize();
        BindSubscription(BCTestSendCustomerData);
        CreateCustomerData(Customer);
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens the customer card and clicks 'Export data' (simulated by just creating the excel file here)
        ServerFileName := O365EmailCustomerData.CreateExcelBook(Customer);
        Assert.AreNotEqual('', ServerFileName, 'Missing file');
        Assert.IsTrue(File.Exists(ServerFileName), 'Server file does not exist (Customer Information)'); // We see random errors on OpenBook in this function, this is to verify that the file wasn't deleted for some reason

        // [THEN] There will be created an excel sheet with all relevant customer data and sent to the customer
        // Verify Customer sheet
        TempExcelBuffer.OpenBook(ServerFileName, CustomerInformationTxt);
        TempExcelBuffer.ReadSheet;
        TempExcelBuffer.Get(1, 1);
        Assert.AreEqual(CustomerInformationTxt, TempExcelBuffer."Cell Value as Text", 'Unexpected excel content');
        TempExcelBuffer.Get(3, 1);
        Assert.AreEqual(Customer.FieldCaption("No."), TempExcelBuffer."Cell Value as Text", 'Expected No. in Excel');
        TempExcelBuffer.Get(4, 2);
        Assert.AreEqual(Customer.Name, TempExcelBuffer."Cell Value as Text", 'Expected customer name in Excel');
        TempExcelBuffer.SetRange("Column No.", 1);
        TempExcelBuffer.SetRange("Cell Value as Text", Customer.FieldCaption("Responsibility Center"));
        Assert.IsFalse(TempExcelBuffer.IsEmpty, '"Responsibility Center" was expected');
        TempExcelBuffer.Reset;

        // Verify Sent invoices sheet
        Clear(TempExcelBuffer);
        Assert.IsTrue(File.Exists(ServerFileName), 'Server file does not exist (sent invoices)'); // We see random errors on OpenBook in this function, this is to verify that the file wasn't deleted for some reason
        TempExcelBuffer.OpenBook(ServerFileName, SentInvoicesTxt);
        TempExcelBuffer.ReadSheet;
        TempExcelBuffer.Get(1, 1);
        Assert.AreEqual(SentInvoicesTxt, TempExcelBuffer."Cell Value as Text", 'Unexpected excel content');
        TempExcelBuffer.Get(4, 2);
        Assert.AreEqual(Customer.Name, TempExcelBuffer."Cell Value as Text", 'Missing customer name for sent invoices');
        if not TempExcelBuffer.Get(4, 18) then
            TempExcelBuffer."Cell Value as Text" := '';
        Assert.AreEqual(WorkDescrTxt, TempExcelBuffer."Cell Value as Text", 'Missing Work Description for sent invoices');

        // Verify Draft invoices sheet
        Clear(TempExcelBuffer);
        Assert.IsTrue(File.Exists(ServerFileName), 'Server file does not exist (Draft Invoices)'); // We see random errors on OpenBook in this function, this is to verify that the file wasn't deleted for some reason
        TempExcelBuffer.OpenBook(ServerFileName, DraftInvoicesTxt);
        TempExcelBuffer.ReadSheet;
        TempExcelBuffer.Get(1, 1);
        Assert.AreEqual(DraftInvoicesTxt, TempExcelBuffer."Cell Value as Text", 'Unexpected excel content');
        TempExcelBuffer.Get(4, 2);
        Assert.AreEqual(Customer.Name, TempExcelBuffer."Cell Value as Text", 'Missing customer name for draft invoices');
        if not TempExcelBuffer.Get(4, 18) then
            TempExcelBuffer."Cell Value as Text" := '';
        Assert.AreEqual(WorkDescrTxt, TempExcelBuffer."Cell Value as Text", 'Missing Work Description for sent invoices');

        // Verify Estimates sheet
        Clear(TempExcelBuffer);
        Assert.IsTrue(File.Exists(ServerFileName), 'Server file does not exist (Estimates)'); // We see random errors on OpenBook in this function, this is to verify that the file wasn't deleted for some reason
        TempExcelBuffer.OpenBook(ServerFileName, QuotesTxt);
        TempExcelBuffer.ReadSheet;
        TempExcelBuffer.Get(1, 1);
        Assert.AreEqual(QuotesTxt, TempExcelBuffer."Cell Value as Text", 'Unexpected excel content');
        TempExcelBuffer.Get(4, 2);
        Assert.AreEqual(Customer.Name, TempExcelBuffer."Cell Value as Text", 'Missing customer name for draft invoices');
        if not TempExcelBuffer.Get(4, 18) then
            TempExcelBuffer."Cell Value as Text" := '';
        Assert.AreEqual('', TempExcelBuffer."Cell Value as Text", 'Unexpected Work Description for sent invoices');
        UnbindSubscription(BCTestSendCustomerData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCustomerExcelSheetWithSensitiveData()
    var
        Customer: Record Customer;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        DataSensitivity: Record "Data Sensitivity";
        O365EmailCustomerData: Codeunit "O365 Email Customer Data";
        BCTestSendCustomerData: Codeunit "BC Test Send Customer Data";
        ServerFileName: Text;
    begin
        // [SCENARIO] User can send an email with an excel book to the customer. Company sensitive data is excluded.
        Initialize();
        BindSubscription(BCTestSendCustomerData);
        CreateCustomerData(Customer);
        // Mark Customer."Responsibility Center" as company sensitive so it isn't exported
        DataSensitivity.Init;
        DataSensitivity."Company Name" := CompanyName;
        DataSensitivity."Table No" := DATABASE::Customer;
        DataSensitivity."Field No" := Customer.FieldNo("Responsibility Center"); // one of the 'other' fields
        DataSensitivity."Data Sensitivity" := DataSensitivity."Data Sensitivity"::"Company Confidential";
        DataSensitivity.Insert;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens the customer card and clicks 'Export data' (simulated by just creating the excel file here)
        ServerFileName := O365EmailCustomerData.CreateExcelBook(Customer);
        Assert.AreNotEqual('', ServerFileName, 'Missing file');

        // [THEN] There will be created an excel sheet with all relevant customer data
        // Verify Customer sheet
        TempExcelBuffer.OpenBook(ServerFileName, CustomerInformationTxt);
        TempExcelBuffer.ReadSheet;
        TempExcelBuffer.SetRange("Column No.", 1);
        TempExcelBuffer.SetRange("Cell Value as Text", Customer.FieldCaption("Responsibility Center"));
        Assert.IsTrue(TempExcelBuffer.IsEmpty, '"Responsibility Center" was not expected');

        UnbindSubscription(BCTestSendCustomerData);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"BC Test Send Customer Data");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."E-Mail" := CustomerEmailTxt;
        Customer.Modify;
    end;

    local procedure CreateCustomerData(var Customer: Record Customer)
    var
        DataSensitivity: Record "Data Sensitivity";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateCustomer(Customer);
        // We use Customer."Responsibility Center" to test the data sensitivity.
        Customer."Responsibility Center" := CopyStr(Format(CreateGuid), 1, MaxStrLen(Customer."Responsibility Center"));
        Customer.Modify;
        if DataSensitivity.Get(CompanyName, DATABASE::Customer, Customer.FieldNo("Responsibility Center")) then
            DataSensitivity.Delete;

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.SetWorkDescription(WorkDescrTxt);
        SalesHeader.Modify;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.SetWorkDescription(WorkDescrTxt);
        SalesHeader.Modify;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365ExportCustomerDataPageHandlerCancel(var O365ExportCustomerData: TestPage "O365 Export Customer Data")
    begin
        Assert.AreNotEqual('', O365ExportCustomerData.CustomerName.Value, 'missing customer name.');
        Assert.AreEqual(MyEmailTxt, O365ExportCustomerData.Email.Value, 'wrong email');
        O365ExportCustomerData.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365ExportCustomerDataPageHandlerOK(var O365ExportCustomerData: TestPage "O365 Export Customer Data")
    begin
        Assert.AreNotEqual('', O365ExportCustomerData.CustomerName.Value, 'missing customer name.');
        Assert.AreEqual('', O365ExportCustomerData.Email.Value, 'no email expected');
        O365ExportCustomerData.Email.SetValue(CustomerEmailTxt);
        O365ExportCustomerData.OK.Invoke; // -> should raise a warning/confirmation dialog that we choose to say 'no' to.
        O365ExportCustomerData.Cancel.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CustomerEmailConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, 'Warning:') > 0, 'unexpected message');
    end;

    [EventSubscriber(ObjectType::Codeunit, 9520, 'OnBeforeDoSending', '', false, false)]
    local procedure OnBeforeSendEmail(var CancelSending: Boolean)
    begin
        CancelSending := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure OnBeforeStartBackgroundTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}

