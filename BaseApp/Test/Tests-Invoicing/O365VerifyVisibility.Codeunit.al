codeunit 138913 "O365 Verify Visibility"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        FieldShouldBeVisibleMsg: Label 'Field %1 should be visible';
        IsNotFoundOnThePageTxt: Label 'is not found on the page';
        PostButtonMustBeVisibleTxt: Label 'Post button must be visible';
        BusinessInformationTitleTxt: Label 'Business Information';
        TaxPaymentsSettingsTitleTxt: Label 'Tax Payments Settings';
        ImportExportTitleTxt: Label 'Import & Export ';
        InvoiceSendOptionsTitleTxt: Label 'Invoice send options';
        HelpAndFeedbackTitleTxt: Label 'Help and Feedback';
        MenuItemNotFoundTxt: Label 'Menu item %1 not found';
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySalesInvoiceVisibilityForSalesTax()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use Sales Tax
        InitializeSalesTax;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".Value(CreateCustomer);

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsTrue(O365SalesInvoice.TaxAreaDescription.Visible, '"Tax Area Code" should be visible when sales tax is used');
        Assert.IsFalse(
          O365SalesInvoice."VAT Registration No.".Visible, '"VAT Registration No." should NOT be visible when sales tax is used');
        O365SalesInvoice.SaveForLater.Invoke;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySalesInvoiceVisibilityForVAT()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use VAT
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".Value(CreateCustomer);

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(O365SalesInvoice.TaxAreaDescription.Visible, '"Tax Area Code" should NOT be visible when sales tax is used');
        Assert.IsTrue(O365SalesInvoice."VAT Registration No.".Visible, '"VAT Registration No." should be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySalesInvoiceLineVisibilityForSalesTax()
    var
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use Sales Tax
        InitializeSalesTax;
        LibraryLowerPermissions.SetInvoiceApp;

        O365SalesInvoiceLineCard.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(
          O365SalesInvoiceLineCard.VATProductPostingGroupDescription.Visible,
          '"VAT Prod. Posting Group" should NOT be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySalesInvoiceLineVisibilityForVAT()
    var
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use VAT
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365SalesInvoiceLineCard.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(O365SalesInvoiceLineCard."Tax Group Code".Visible, '"Tax Group Code" should NOT be visible when VAT is used');
        Assert.IsFalse(O365SalesInvoiceLineCard.TaxRate.Visible, '"Tax Rate" should NOT be visible when VAT is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySendSalesInvoiceVisibilityForSalesTax()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use Sales Tax
        InitializeSalesTax;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365PostedSalesInvoice.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsTrue(O365PostedSalesInvoice.TaxAreaDescription.Visible, '"Tax Area Code" should be visible when sales tax is used');
        Assert.IsFalse(
          O365PostedSalesInvoice."VAT Registration No.".Visible, '"VAT Registration No." should NOT be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySendSalesInvoiceVisibilityForVAT()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use VAT
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365PostedSalesInvoice.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(O365PostedSalesInvoice.TaxAreaDescription.Visible, '"Tax Area Code" should NOT be visible when sales tax is used');
        Assert.IsTrue(
          O365PostedSalesInvoice."VAT Registration No.".Visible, '"VAT Registration No." should be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySendSalesInvoiceLineVisibilityForSalesTax()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use Sales Tax
        InitializeSalesTax;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365PostedSalesInvoice.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsTrue(O365PostedSalesInvoice.Lines."Tax Group Code".Visible, '"Tax Group Code" should be visible when sales tax is used');
        Assert.IsTrue(O365PostedSalesInvoice.Lines."VAT %".Visible, '"Tax Rate" should be visible when sales tax is used');
        Assert.IsFalse(
          O365PostedSalesInvoice.Lines.VATProductPostingGroupDescription.Visible,
          '"VAT Prod. Posting Group" should NOT be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifySendSalesInvoiceLineVisibilityForVAT()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [GIVEN] Invoicing App has been set up to use VAT
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The sales invoice card is opened
        O365PostedSalesInvoice.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(O365PostedSalesInvoice.Lines."Tax Group Code".Visible, '"Tax Group Code" should NOT be visible when VAT is used');
        Assert.IsFalse(O365PostedSalesInvoice.Lines."VAT %".Visible, '"Tax Rate" should NOT be visible when VAT is used');
        Assert.IsTrue(
          O365PostedSalesInvoice.Lines.VATProductPostingGroupDescription.Visible,
          '"VAT Prod. Posting Group" should NOT be visible when VAT is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifyItemVisibilityForSalesTax()
    var
        O365ItemCard: TestPage "O365 Item Card";
    begin
        // [FEATURE] [Item]
        // [GIVEN] Invoicing App has been set up to use Sales Tax
        InitializeSalesTax;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The Item card is opened
        O365ItemCard.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsTrue(O365ItemCard."Tax Group Code".Visible, 'Tax group code should be visible when sales tax is used');
        Assert.IsFalse(
          O365ItemCard.VATProductPostingGroupDescription.Visible, 'VAT prod. posting group should NOT be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure VerifyItemVisibilityForVAT()
    var
        O365ItemCard: TestPage "O365 Item Card";
    begin
        // [FEATURE] [Item]
        // [GIVEN] Invoicing App has been set up to use VAT
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The Item card is opened
        O365ItemCard.OpenNew;

        // [THEN] Visibility of Tax and VAT fields are set accordingly
        Assert.IsFalse(O365ItemCard."Tax Group Code".Visible, 'Tax group code should NOT be visible when sales tax is used');
        Assert.IsTrue(
          O365ItemCard.VATProductPostingGroupDescription.Visible, 'VAT prod. posting group should be visible when sales tax is used');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure TestInvoicingRelatedFieldsOnCountriesPage()
    var
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [Country/Region]
        // [SCENARIO 197381] Only Code and Name fields of Countries\Regions page are visible
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] #Invoicing app area enabled
        LibraryApplicationArea.EnableInvoicingSetup;

        // [WHEN] Countries\Regions page is being opened
        CountriesRegions.OpenEdit;

        // [THEN] Code and Name are visible
        Assert.IsTrue(CountriesRegions.Code.Visible, StrSubstNo(FieldShouldBeVisibleMsg, CountriesRegions.Code.Caption));
        Assert.IsTrue(CountriesRegions.Name.Visible, StrSubstNo(FieldShouldBeVisibleMsg, CountriesRegions.Name.Caption));

        // [THEN] Intrastat Code field is not found on page
        asserterror CountriesRegions."Intrastat Code".Activate;
        Assert.ExpectedError(IsNotFoundOnThePageTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure TestInvoicingRelatedFieldsItemCardPage()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 197381] Invoicing related fields of Item Card page are visible
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] #Invoicing app area enabled
        LibraryApplicationArea.EnableInvoicingSetup;

        // [WHEN] Item Card page is being opened
        ItemCard.OpenEdit;

        // [THEN] Code and Name are visible
        Assert.IsTrue(ItemCard."Unit Price".Visible, StrSubstNo(FieldShouldBeVisibleMsg, ItemCard."Unit Price".Caption));
        Assert.IsTrue(
          ItemCard."Base Unit of Measure".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, ItemCard."Base Unit of Measure".Caption));
        // [THEN] Picture is visible
        Assert.IsTrue(ItemCard.ItemPicture.Picture.Visible, StrSubstNo(FieldShouldBeVisibleMsg, ItemCard.ItemPicture.Caption));

        // [THEN] Assembly BOM field is not found on page
        asserterror ItemCard.AssemblyBOM.Activate;
        Assert.ExpectedError(IsNotFoundOnThePageTxt);

        // [THEN] Stockout Warning field is not found on page
        asserterror ItemCard.StockoutWarningDefaultYes.Activate;
        Assert.ExpectedError(IsNotFoundOnThePageTxt);

        // [THEN] Prevent Negative Inventory field is not found on page
        asserterror ItemCard.PreventNegInventoryDefaultYes.Activate;
        Assert.ExpectedError(IsNotFoundOnThePageTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure TestInvoicingRelatedFieldsItemListPage()
    var
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 197381] Invoicing related fields of Item List page are visible
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] #Invoicing app area enabled
        LibraryApplicationArea.EnableInvoicingSetup;
        CreateItemWithPage;

        // [WHEN] Item List page is being opened
        ItemList.OpenView;

        // [THEN] Code and Name are visible
        Assert.IsTrue(ItemList."Unit Price".Visible, StrSubstNo(FieldShouldBeVisibleMsg, ItemList."Unit Price".Caption));
        Assert.IsTrue(
          ItemList."Base Unit of Measure".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, ItemList."Base Unit of Measure".Caption));

        // [THEN] Assembly BOM field is not found on page
        asserterror ItemList."Unit Cost".Activate;
        Assert.ExpectedError(IsNotFoundOnThePageTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure TestInvoicingSMTPUserSpecifiedAddressPage()
    var
        SMTPUserSpecifiedAddress: TestPage "SMTP User-Specified Address";
    begin
        // [FEATURE] [SMTP]
        // [SCENARIO 197381] Email Address field visible on SMTP User-Specified Address page
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] #Invoicing app area enabled
        LibraryApplicationArea.EnableInvoicingSetup;

        // [WHEN] SMTP User-Specified Address page is being opened
        SMTPUserSpecifiedAddress.OpenEdit;

        // [THEN] Email Address is visible
        Assert.IsTrue(
          SMTPUserSpecifiedAddress.EmailAddressField.Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, SMTPUserSpecifiedAddress.EmailAddressField.Caption));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure InvoicingAppAreaSunshineSalesScenario()
    var
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 197381] It is possible to go through major sales activity scenario
        InitializeVAT;
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] #Invoicing app area enabled
        LibraryApplicationArea.EnableInvoicingSetup;

        // [GIVEN] Customer created with page
        // [WHEN] Sales invoice created with page
        CreateInvoiceWithPage(O365SalesInvoice);

        // [THEN] Post button is visible
        // The post and send process is difficult to emulate, so it is not executed here
        Assert.IsTrue(O365SalesInvoice.Post.Visible, PostButtonMustBeVisibleTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure TestInvoicingSettingsContent()
    var
        O365InvoicingSettings: TestPage "O365 Invoicing Settings";
    begin
        // [FEATURE] [Invoicing Settings]
        // [SCENARIO 197381] Top level Invoicing Settings page contains proper sub-menu items
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [WHEN] Top level Invoicing Settings page is being opened
        O365InvoicingSettings.OpenView;

        // [THEN] Settings page contains Business Information menu item
        VerifyMenuItemExists(O365InvoicingSettings, BusinessInformationTitleTxt);
        // [THEN] Settings page contains Tax Payments Settings Title menu item
        VerifyMenuItemExists(O365InvoicingSettings, TaxPaymentsSettingsTitleTxt);
        // [THEN] Settings page contains Import Export Title menu item
        VerifyMenuItemExists(O365InvoicingSettings, ImportExportTitleTxt);
        // [THEN] Settings page contains Invoice Send Options Title menu item
        VerifyMenuItemExists(O365InvoicingSettings, InvoiceSendOptionsTitleTxt);
        // [THEN] Settings page contains Help And Feedback Title menu item
        VerifyMenuItemExists(O365InvoicingSettings, HelpAndFeedbackTitleTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure PhysInvtItemSelectionLocationCodeVisible()
    var
        PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection";
    begin
        // [FEATURE] [Location] [Physical Inventory]
        // [SCENARIO] Field "Location Code" in the page 7380 "Phys. Invt. Item Selection" should be visible when the #Location application area is enabled

        Initialize;
        LibraryLowerPermissions.SetItemView;
        LibraryApplicationArea.DisableApplicationAreaSetup;
        LibraryApplicationArea.EnableLocationsSetup;
        PhysInvtItemSelection.OpenView;
        Assert.IsTrue(
          PhysInvtItemSelection."Location Code".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Location Code".Caption));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure PhysInvtItemSelectionBasicItemFieldsVisible()
    var
        PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection";
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] Fields relating to basic item setup in the page 7380 "Phys. Invt. Item Selection" should be visible when the #Basic application area is enabled

        Initialize;
        LibraryLowerPermissions.SetItemView;
        LibraryApplicationArea.DisableApplicationAreaSetup;
        LibraryApplicationArea.EnableFoundationSetup;
        PhysInvtItemSelection.OpenView;

        Assert.IsTrue(
          PhysInvtItemSelection."Item No.".Visible, StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Item No.".Caption));
        Assert.IsTrue(
          PhysInvtItemSelection.Description.Visible, StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection.Description.Caption));
        Assert.IsTrue(
          PhysInvtItemSelection."Phys Invt Counting Period Code".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Phys Invt Counting Period Code".Caption));
        Assert.IsTrue(
          PhysInvtItemSelection."Last Counting Date".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Last Counting Date".Caption));
        Assert.IsTrue(
          PhysInvtItemSelection."Next Counting Start Date".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Next Counting Start Date".Caption));
        Assert.IsTrue(
          PhysInvtItemSelection."Next Counting End Date".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtItemSelection."Next Counting End Date".Caption));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSent')]
    [Scope('OnPrem')]
    procedure PhysInvtCountingPeriodsBasicItemFieldsVisible()
    var
        PhysInvtCountingPeriods: TestPage "Phys. Invt. Counting Periods";
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] Fields relating to basic item setup in the page 7381 "Phys. Invt. Counting Periods" should be visible when the #Basic application area is enabled

        Initialize;
        LibraryLowerPermissions.SetO365BusFull;
        LibraryApplicationArea.DisableApplicationAreaSetup;
        LibraryApplicationArea.EnableFoundationSetup;

        PhysInvtCountingPeriods.OpenView;
        Assert.IsTrue(PhysInvtCountingPeriods.Code.Visible, StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtCountingPeriods.Code.Caption));
        Assert.IsTrue(
          PhysInvtCountingPeriods.Description.Visible, StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtCountingPeriods.Description.Caption));
        Assert.IsTrue(
          PhysInvtCountingPeriods."Count Frequency per Year".Visible,
          StrSubstNo(FieldShouldBeVisibleMsg, PhysInvtCountingPeriods."Count Frequency per Year".Caption));
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;
    end;

    local procedure InitializeSalesTax()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        Initialize;

        O365SalesInitialSetup.Get;
        O365SalesInitialSetup."Tax Type" := O365SalesInitialSetup."Tax Type"::"Sales Tax";
        O365SalesInitialSetup.Modify;
    end;

    local procedure InitializeVAT()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        Initialize;

        O365SalesInitialSetup.Get;
        O365SalesInitialSetup."Tax Type" := O365SalesInitialSetup."Tax Type"::VAT;
        O365SalesInitialSetup.Modify;
    end;

    local procedure CreateCustomer() CustomerName: Text[50]
    var
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
    begin
        O365SalesCustomerCard.OpenNew;
        CustomerName := LibraryUtility.GenerateGUID;
        O365SalesCustomerCard.Name.Value(CustomerName);
        O365SalesCustomerCard.Close;
    end;

    local procedure CreateItemWithPage() ItemNo: Code[20]
    var
        Item: Record Item;
        BCO365ItemCard: TestPage "BC O365 Item Card";
    begin
        BCO365ItemCard.OpenNew;
        BCO365ItemCard.Description.Value :=
          LibraryUtility.GenerateRandomCode(
            Item.FieldNo(Description),
            DATABASE::Item);
        BCO365ItemCard."Unit Price".Value := Format(LibraryRandom.RandDec(100, 2));
        Item.SetRange(Description, BCO365ItemCard.Description.Value);
        BCO365ItemCard.OK.Invoke;

        Item.FindLast;

        ItemNo := Item."No.";
    end;

    local procedure CreateCustomerWithPage(): Text
    var
        Customer: Record Customer;
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
    begin
        O365SalesCustomerCard.OpenNew;
        O365SalesCustomerCard.Name.Value :=
          LibraryUtility.GenerateRandomCode(
            Customer.FieldNo("No."),
            DATABASE::Customer);
        Customer.SetRange(Name, O365SalesCustomerCard.Name.Value);
        O365SalesCustomerCard.OK.Invoke;
        Customer.FindFirst;
        exit(Customer.Name);
    end;

    local procedure CreateInvoiceWithPage(var O365SalesInvoice: TestPage "O365 Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".Value(CreateCustomerWithPage);
        SalesHeader.FindLast;
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        SalesLine.Modify;
    end;

    local procedure VerifyMenuItemExists(var O365InvoicingSettings: TestPage "O365 Invoicing Settings"; ExpectedMenuItem: Text)
    begin
        O365InvoicingSettings.FILTER.SetFilter(Title, StrSubstNo('''%1''', ExpectedMenuItem));
        Assert.IsTrue(
          O365InvoicingSettings.First,
          StrSubstNo(MenuItemNotFoundTxt, ExpectedMenuItem));
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSent(var TheNotification: Notification): Boolean
    begin
        Assert.Fail(StrSubstNo('No notification should be thrown. The notification was %1.', TheNotification.Message));
    end;
}

