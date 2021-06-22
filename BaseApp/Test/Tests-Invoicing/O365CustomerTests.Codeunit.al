codeunit 138909 "O365 Customer Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Customer] [UI]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryUtility: Codeunit "Library - Utility";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter(Code, '*WAY');
        CountryRegion.DeleteAll;

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCustomerContactType()
    var
        Customer: Record Customer;
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
        CustomerName: Text[30];
    begin
        Initialize;

        // Exercise create new customer
        LibraryLowerPermissions.SetInvoiceApp;
        O365SalesCustomerCard.OpenNew;
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        O365SalesCustomerCard.Name.SetValue(CustomerName);

        // Verify default customer type is person and is prices inclusing VAT
        O365SalesCustomerCard."Contact Type".AssertEquals(Customer."Contact Type"::Person);
        O365SalesCustomerCard.Close;
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst;
        Customer.TestField("Prices Including VAT", true);

        // Exercise change customer to company
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        O365SalesCustomerCard."Contact Type".SetValue(Customer."Contact Type"::Company);
        O365SalesCustomerCard.Close;

        // Verify that the customer changed to prices excluding VAT
        Customer.Get(Customer."No.");
        Customer.TestField("Prices Including VAT", false);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressModalPageHandler,CountryRegionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestAddressCountryCodeLookupSelect()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        O365CountryRegion: Record "O365 Country/Region";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
        CustomerName: Text[30];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User has some countries
        LibraryInvoicingApp.CreateCountryRegion('MSWAY');
        LibraryInvoicingApp.CreateCountryRegion('NAVWAY');

        // [WHEN] User creates a new customer with a certain existing country
        O365SalesCustomerCard.OpenNew;
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        O365SalesCustomerCard.Name.SetValue(CustomerName);
        O365SalesCustomerCard.FullAddress.AssistEdit; // Calls trigger and sets Country/Region to NAVWAY
        O365SalesCustomerCard.Close;

        // [THEN] The customer has been created with the correct Country/Region
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst;
        Customer.TestField("Country/Region Code", 'NAVWAY');

        // [THEN] The Country/Region exists and the shadow table O365CountryRegion is still empty
        CountryRegion.Get('NAVWAY');
        Assert.RecordIsEmpty(O365CountryRegion);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,CountryRegionModalPageHandler,AddressModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestAddressCountryCodeLookupNew()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        O365CountryRegion: Record "O365 Country/Region";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
        O365CountryRegionCard: TestPage "O365 Country/Region Card";
        CustomerName: Text[30];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User has some countries
        LibraryInvoicingApp.CreateCountryRegion('MSWAY');

        // [WHEN] User creates a new customer and a new country during lookup
        O365CountryRegionCard.OpenNew;
        O365CountryRegionCard.Code.SetValue('NAVWAY');
        O365CountryRegionCard.Name.SetValue(CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(CountryRegion.Name)));
        O365CountryRegionCard.Close;

        // [THEN] A customer can be created with the Country/Region
        O365SalesCustomerCard.OpenNew;
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        O365SalesCustomerCard.Name.SetValue(CustomerName);
        O365SalesCustomerCard.FullAddress.AssistEdit; // Calls trigger and sets Country/Region to NAVWAY
        O365SalesCustomerCard.Close;

        // [THEN] The Country/Region exists and the shadow table O365CountryRegion is still empty
        CountryRegion.Get('NAVWAY');
        Assert.RecordIsEmpty(O365CountryRegion);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestAddressCountryCodeLookupBCSelect()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        O365CountryRegion: Record "O365 Country/Region";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        CustomerName: Text[30];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User has some countries
        LibraryInvoicingApp.CreateCountryRegion('MSWAY');
        LibraryInvoicingApp.CreateCountryRegion('NAVWAY');

        // [WHEN] User creates a new customer with a certain existing country
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        BCO365SalesCustomerCard.Name.SetValue(CustomerName);
        BCO365SalesCustomerCard.CountryRegionCode.SetValue('NAVWAY');
        BCO365SalesCustomerCard.Close;

        // [THEN] The customer has been created with the correct Country/Region
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst;
        Customer.TestField("Country/Region Code", 'NAVWAY');

        // [THEN] The Country/Region exists and the shadow table O365CountryRegion is still empty
        CountryRegion.Get('NAVWAY');
        Assert.RecordIsEmpty(O365CountryRegion);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestManuallyEnterCountryNameBC()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        O365CountryRegion: Record "O365 Country/Region";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        CustomerName: Text[30];
        PartialCountryName: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User has some countries
        LibraryInvoicingApp.CreateCountryRegion('MSWAY');
        LibraryInvoicingApp.CreateCountryRegion('NAVWAY');
        CountryRegion.Get('NAVWAY');
        PartialCountryName := CopyStr(CountryRegion.Name, 1, MaxStrLen(CountryRegion.Code));

        // [WHEN] User creates a new customer and manually fills the country with the name
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        BCO365SalesCustomerCard.Name.SetValue(CustomerName);
        BCO365SalesCustomerCard.CountryRegionCode.SetValue(PartialCountryName); // Calls trigger and sets Country/Region to NAVWAY
        BCO365SalesCustomerCard.Close;

        // [THEN] The customer has been created with the correct Country/Region
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst;
        Customer.TestField("Country/Region Code", 'NAVWAY');

        // [THEN] The shadow table O365CountryRegion is still empty
        Assert.RecordIsEmpty(O365CountryRegion);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,BCEmailSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangeCustomerNameAfterPostingInvoice()
    var
        Customer: Record Customer;
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CustomerName: Text[100];
        EditedCustomerName: Text[100];
        ItemDescription: Text[100];
    begin
        Initialize;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user creates a new customer and sends an invoice to the customer
        CustomerName := LibraryInvoicingApp.CreateCustomerWithEmail;
        ItemDescription := LibraryInvoicingApp.CreateItemWithPrice;
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);
        BCO365SalesInvoice.Lines.Description.SetValue(ItemDescription);
        BCO365SalesInvoice.Post.Invoke;

        // [WHEN] User tries to edit the customer name
        Customer.SetRange(Name, CustomerName);
        Assert.RecordCount(Customer, 1);
        Customer.FindFirst;
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        EditedCustomerName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(Customer.Name));
        BCO365SalesCustomerCard.Name.SetValue(EditedCustomerName);
        BCO365SalesCustomerCard.Close;

        // [THEN] No error is thrown and the modification succeeded
        Customer.SetRange(Name, CustomerName);
        Assert.RecordCount(Customer, 0);
        Customer.SetRange(Name, EditedCustomerName);
        Assert.RecordCount(Customer, 1);
        Customer.FindFirst;

        EventSubscriberInvoicingApp.Clear();
        UnbindSubscription(EventSubscriberInvoicingApp);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddressModalPageHandler(var O365Address: TestPage "O365 Address")
    begin
        O365Address.CountryRegionCode.Lookup;

        O365Address.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CountryRegionModalPageHandler(var O365CountryRegionList: TestPage "O365 Country/Region List")
    begin
        O365CountryRegionList.GotoKey('NAVWAY');
        O365CountryRegionList.OK.Invoke;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
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
            FromAccount.SetValue('test@microsoft.com');
            Password.SetValue('pass');
        end;

        BCO365EmailSetupWizard.OK.Invoke;
    end;
}

