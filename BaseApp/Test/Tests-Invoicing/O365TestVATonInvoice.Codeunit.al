codeunit 138919 "O365 Test VAT on Invoice"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [VAT on Sales Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        DatasetFileName: Text;
        IsInitialized: Boolean;
        EmailProvider: Option "Office 365",Other;

    // [Test] Fails with AssertEquals for Field: Unit Price Expected = ',621.44', Actual = '5,621.44' 
    [HandlerFunctions('VerifyNoNotificationsAreSend,VATProductPostingGroupHandler,DraftSalesInvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPersonShowsPriceIncVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        // [GIVEN] A Item and Customer of type Person
        Initialize;
        CreateItemWithPrice(Item);
        CreateCustomer(Customer, Customer."Contact Type"::Person);

        // [WHEN] Creating a Sales invoice with the new Customer and Item
        LibraryLowerPermissions.SetSalesDocsCreate;
        CreateInvoice(Customer, O365SalesInvoice, O365SalesInvoiceLineCard);

        O365SalesInvoiceLineCard.Description.SetValue(Item.Description);

        // [THEN] The price that is shown and typed on the sales line is including VAT
        O365SalesInvoiceLineCard."Unit Price".AssertEquals(CopyStr(O365SalesInvoiceLineCard.LineAmountInclVAT.Value, 2));

        // [THEN] The excluding VAT is the same as the Unit Price of the Item on the sales line
        O365SalesInvoiceLineCard.LineAmountExclVAT.AssertEquals(Item."Unit Price");

        // [THEN] The including VAT is larger than excluding VAT on the sales line
        Assert.IsTrue(O365SalesInvoiceLineCard.LineAmountInclVAT.Value > O365SalesInvoiceLineCard.LineAmountExclVAT.Value,
          'Price Inc VAT should be the largest value');

        SalesHeader.FindLast;
        O365SalesInvoice.GotoRecord(SalesHeader);
        // [THEN] The brick value for the sales line should be including VAT
        O365SalesInvoice.Lines."Line Amount".AssertEquals(O365SalesInvoiceLineCard.LineAmountInclVAT.Value);

        // [THEN] The total excluding VAT should match the sales line value excluding VAT
        O365SalesInvoice.Amount.AssertEquals(O365SalesInvoiceLineCard.LineAmountExclVAT.Value);

        // [THEN] The total including VAT should match the sales line value including VAT
        O365SalesInvoice."Amount Including VAT".AssertEquals(O365SalesInvoiceLineCard.LineAmountInclVAT.Value);

        // [WHEN] Changing the VAT group to be no VAT
        O365SalesInvoiceLineCard.VATProductPostingGroupDescription.Lookup;
        O365SalesInvoiceLineCard.VATProductPostingGroupDescription.SetValue(
          O365SalesInvoiceLineCard.VATProductPostingGroupDescription.Value);

        // [THEN] The price that is shown and typed on the sales line is including VAT (0%)
        O365SalesInvoiceLineCard."Unit Price".AssertEquals(CopyStr(O365SalesInvoiceLineCard.LineAmountInclVAT.Value, 2));

        // [THEN] The including VAT and the excluding VAT on the sales line is the same
        O365SalesInvoiceLineCard.LineAmountInclVAT.AssertEquals(O365SalesInvoiceLineCard.LineAmountExclVAT.Value);

        O365SalesInvoice.GotoRecord(SalesHeader);
        // [THEN] The brick value for the sales line should be including VAT (0%)
        O365SalesInvoice.Lines."Line Amount".AssertEquals(O365SalesInvoiceLineCard.LineAmountInclVAT.Value);

        // [THEN] The total including VAT should match the sales line value including VAT
        O365SalesInvoice."Amount Including VAT".AssertEquals(O365SalesInvoiceLineCard.LineAmountInclVAT.Value);

        O365SalesInvoiceLineCard.Close;

        // [THEN] The draft report shows VAT Clause header for no VAT
        SaveDraftInvoiceToXML(SalesHeader."No.");
        VerifyVATClauseInDraftReportDataset('VAT Clause');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCompanyShowsPriceIncVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        // [GIVEN] A Item and Customer of type Company
        Initialize;
        CreateCustomerAndItem(Item, Customer, Customer."Contact Type"::Company);

        // [WHEN] Creating a Sales invoice with the new Customer and Item
        LibraryLowerPermissions.SetSalesDocsCreate;
        CreateInvoice(Customer, O365SalesInvoice, O365SalesInvoiceLineCard);

        O365SalesInvoiceLineCard.Description.SetValue(Item.Description);
        // [THEN] The price that is shown and typed on the sales line is excluding VAT
        O365SalesInvoiceLineCard."Unit Price".AssertEquals(Item."Unit Price");

        // [THEN] The excluding VAT is the same as the Unit Price of the Item on the sales line
        O365SalesInvoiceLineCard.LineAmountExclVAT.AssertEquals(Item."Unit Price");

        // [THEN] The including VAT is larger than excluding VAT on the sales line
        Assert.IsTrue(O365SalesInvoiceLineCard.LineAmountInclVAT.Value > O365SalesInvoiceLineCard.LineAmountExclVAT.Value,
          'Price Inc VAT should be the largest value');

        SalesHeader.FindLast;
        O365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The brick value for the sales line should be excluding VAT
        O365SalesInvoice.Lines."Line Amount".AssertEquals(O365SalesInvoice.Amount.Value);

        // [THEN] The total excluding VAT should match the sales line value excluding VAT
        O365SalesInvoice.Amount.AssertEquals(O365SalesInvoiceLineCard.LineAmountExclVAT.Value);

        // [THEN] The total including VAT should match the sales line value including VAT
        O365SalesInvoice."Amount Including VAT".AssertEquals(O365SalesInvoiceLineCard.LineAmountInclVAT.Value);

        O365SalesInvoiceLineCard.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,DraftSalesInvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATClauseInDraftInvoiceReport()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365TemplateManagement: Codeunit "O365 Template Management";
        O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card";
        DraftInvoiceNo: Code[20];
    begin
        // [GIVEN] A clean Invoicing app
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a sales draft invoice
        DraftInvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [THEN] Draft invoice report should have no VAT Clause header
        SaveDraftInvoiceToXML(DraftInvoiceNo);
        VerifyVATClauseInDraftReportDataset('');

        // [WHEN] User goes to default VAT settings and the code on after get current record for VAT card is executed
        VATProductPostingGroup.Get(O365TemplateManagement.GetDefaultVATProdPostingGroup);
        O365VATPostingSetupCard.OpenEdit;
        O365VATPostingSetupCard.GotoRecord(VATProductPostingGroup);
        Assert.AreEqual('', O365VATPostingSetupCard."VAT Regulation Reference".Value,
          'Description is not empty for Invoicing Default VAT Posting Group');
        O365VATPostingSetupCard.Close;

        // [THEN] Draft invoice report should have no VAT Clause header
        DraftInvoiceNo := LibraryInvoicingApp.CreateInvoice;
        SaveDraftInvoiceToXML(DraftInvoiceNo);
        VerifyVATClauseInDraftReportDataset('');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,BCEmailSetupPageHandler,SalesInvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATClauseInInvoiceReport()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365TemplateManagement: Codeunit "O365 Template Management";
        O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card";
        PostedInvoiceNo: Code[20];
    begin
        // [GIVEN] A clean Invoicing app
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates and sends a simple invoice
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [WHEN] User goes to default VAT settings and the code on after get current record for VAT card is executed
        VATProductPostingGroup.Get(O365TemplateManagement.GetDefaultVATProdPostingGroup);
        O365VATPostingSetupCard.OpenEdit;
        O365VATPostingSetupCard.GotoRecord(VATProductPostingGroup);
        Assert.AreEqual('', O365VATPostingSetupCard."VAT Regulation Reference".Value,
          'Description is not empty for Invoicing Default VAT Posting Group');
        O365VATPostingSetupCard.Close;

        // [THEN] Invoice report should have no VAT Clause header
        SaveInvoiceToXML(PostedInvoiceNo);
        VerifyVATClauseInDraftReportDataset('');
    end;

    local procedure CreateItemWithPrice(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1, 99999, 2));
        Item.Modify();
    end;

    local procedure CreateCustomer(var Customer: Record Customer; Type: Option)
    var
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
    begin
        LibrarySales.CreateCustomer(Customer);
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        O365SalesCustomerCard."Contact Type".SetValue(Type);
        O365SalesCustomerCard.Close;
    end;

    local procedure CreateCustomerAndItem(var Item: Record Item; var Customer: Record Customer; Type: Option)
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithPrice(Item);
        CreateCustomer(Customer, Type);
    end;

    local procedure CreateInvoice(Customer: Record Customer; var O365SalesInvoice: TestPage "O365 Sales Invoice"; var O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        SalesHeader.FindLast;
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    local procedure SaveDraftInvoiceToXML(DraftInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DraftInvoiceNo);
        SalesHeader.SetRecFilter;
        Commit();
        REPORT.RunModal(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);
    end;

    local procedure SaveInvoiceToXML(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.SetRecFilter;
        Commit();
        REPORT.RunModal(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceReportRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
    begin
        DatasetFileName := LibraryReportDataset.GetFileName;
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, DatasetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
    begin
        DatasetFileName := LibraryReportDataset.GetFileName;
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, DatasetFileName);
    end;

    local procedure VerifyVATClauseInDraftReportDataset(VATClauseTxt: Text)
    var
        XMLBuffer: Record "XML Buffer";
    begin
        XMLBuffer.Load(DatasetFileName);
        XMLBuffer.SetRange(Name, 'VATClausesHeader');
        if XMLBuffer.FindFirst then
            Assert.AreEqual(VATClauseTxt, XMLBuffer.Value, 'Incorrect VAT Clause Header');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BCEmailSetupPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    begin
        with BCO365EmailSetupWizard.EmailSettingsWizardPage do begin
            "Email Provider".SetValue(EmailProvider::"Office 365");
            FromAccount.SetValue('test@test.com');
            Password.SetValue('pass');
        end;
        BCO365EmailSetupWizard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATProductPostingGroupHandler(var O365VATProductPostingGr: TestPage "O365 VAT Product Posting Gr.")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst;

        O365VATProductPostingGr.GotoKey(VATPostingSetup."VAT Prod. Posting Group");
        O365VATProductPostingGr.OK.Invoke;
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);
        IsInitialized := true;
    end;
}

