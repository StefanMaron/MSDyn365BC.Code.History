codeunit 138948 "O365 Address Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Customer] [UI]
    end;

    var
        TempStandardAddress: Record "Standard Address" temporary;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryUtility: Codeunit "Library - Utility";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        UnrecognizedFieldErr: Label 'Unrecognized field number.';

    local procedure Initialize()
    var
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryVariableStorage.AssertEmpty;
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');

        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        BindSubscription(TestProxyNotifMgtExt);

        WorkDate(Today);
        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('CompanyAddressPageHandler')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoCollapsedAddressCountry()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion1: Record "Country/Region";
        CountryRegion2: Record "Country/Region";
        BCO365MySettings: TestPage "BC O365 My Settings";
        NewCountryRegionName: Text;
    begin
        // [GIVEN] A user in invoicing has some custom countries
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        CountryRegion1.Init();
        CountryRegion1.Validate(Code,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion1.Code)), 1, MaxStrLen(CountryRegion1.Code)));
        CountryRegion1.Validate(Name,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion1.Name)), 1, MaxStrLen(CountryRegion1.Name)));
        CountryRegion1.Insert(true);

        CountryRegion2.Init();
        CountryRegion2.Validate(Code,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion2.Code)), 1, MaxStrLen(CountryRegion2.Code)));
        CountryRegion2.Validate(Name,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion2.Name)), 1, MaxStrLen(CountryRegion2.Name)));
        CountryRegion2.Insert(true);

        // [WHEN] The user opens settings and changes company information address
        LibraryVariableStorage.Enqueue(CountryRegion1.Code);
        BCO365MySettings.OpenEdit;
        BCO365MySettings.Control20.FullAddress.AssistEdit;

        // [THEN] The address page is opened with the right data
        // [WHEN] The user edits the country in the address page and types the country CODE
        // Both done in the handler
        BCO365MySettings.Close;

        // [THEN] The changes are reflected in company information
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation."Country/Region Code", CountryRegion1.Code,
          'Country/region not correctly updated in company information by code');

        // [WHEN] The user edits the country in the address page and types the country name
        NewCountryRegionName := CopyStr(CountryRegion2.Name, 2,
            MaxStrLen(CountryRegion2.Code)); // Input field is the same length as Code
        Assert.AreNotEqual(NewCountryRegionName, '', 'Empty country name generated');
        LibraryVariableStorage.Enqueue(NewCountryRegionName);
        BCO365MySettings.OpenEdit;
        BCO365MySettings.Control20.FullAddress.AssistEdit;
        // Logic in handler

        // [THEN] The changes are reflected in company information
        BCO365MySettings.Close;
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation."Country/Region Code", CountryRegion2.Code,
          'Country/region not correctly updated in company information by name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddressPageNoCreateMode()
    var
        O365Address: TestPage "O365 Address";
    begin
        // [GIVEN] An user in invoicing
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The user opens a collapsed address
        // [THEN] The page does not allow create mode
        asserterror O365Address.OpenNew;
        Assert.ExpectedError('You do not have the following permissions on Page 2148: Insert');
    end;

    [Test]
    [HandlerFunctions('CustomerCardModalPageHandler,KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCAddressFromCustToInvoice()
    var
        DummyCustomer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer inline in the invoice and edits one field of the address from the customer card
        // [THEN] The customer and sales header have the same address
        CheckFieldIsPropagatedFromCustToInvoice(DummyCustomer.FieldNo(Address));
        CheckFieldIsPropagatedFromCustToInvoice(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsPropagatedFromCustToInvoice(DummyCustomer.FieldNo(City));
        CheckFieldIsPropagatedFromCustToInvoice(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsPropagatedFromCustToInvoice(DummyCustomer.FieldNo(County));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CheckFieldIsPropagatedFromCustToInvoice(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CreateCustomerName(CustomerName);
        // New name triggers inline creation
        EditAddressCustomerCardFromInvoice(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckSameAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('CustomerCardModalPageHandler,KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCAddressFromCustToEstimate()
    var
        DummyCustomer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer inline in the estimate and edits one field of the address from the customer card
        // [THEN] The customer and sales header have the same address
        CheckFieldIsPropagatedFromCustToEstimate(DummyCustomer.FieldNo(Address));
        CheckFieldIsPropagatedFromCustToEstimate(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsPropagatedFromCustToEstimate(DummyCustomer.FieldNo(City));
        CheckFieldIsPropagatedFromCustToEstimate(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsPropagatedFromCustToEstimate(DummyCustomer.FieldNo(County));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CheckFieldIsPropagatedFromCustToEstimate(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CreateCustomerName(CustomerName);
        // New name triggers inline creation
        EditAddressCustomerCardFromEstimate(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckSameAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCAddressFromInvoiceToCust()
    var
        DummyCustomer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer inline in the invoice and edits one field of the address from the invoice card
        // [THEN] The customer and sales header have the same address
        CheckFieldIsPropagatedFromInvoiceToCust(DummyCustomer.FieldNo(Address));
        CheckFieldIsPropagatedFromInvoiceToCust(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsPropagatedFromInvoiceToCust(DummyCustomer.FieldNo(City));
        CheckFieldIsPropagatedFromInvoiceToCust(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsPropagatedFromInvoiceToCust(DummyCustomer.FieldNo(County));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CheckFieldIsPropagatedFromInvoiceToCust(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CreateCustomerName(CustomerName);
        // New name triggers inline creation
        EditAddressInvoiceCard(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckSameAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCAddressFromEstimateToCust()
    var
        DummyCustomer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer inline in the estimate and edits one field of the address from the estimate card
        // [THEN] The customer and sales header have the same address
        CheckFieldIsPropagatedFromEstimateToCust(DummyCustomer.FieldNo(Address));
        CheckFieldIsPropagatedFromEstimateToCust(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsPropagatedFromEstimateToCust(DummyCustomer.FieldNo(City));
        CheckFieldIsPropagatedFromEstimateToCust(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsPropagatedFromEstimateToCust(DummyCustomer.FieldNo(County));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CheckFieldIsPropagatedFromEstimateToCust(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CreateCustomerName(CustomerName);
        // New name triggers inline creation
        EditAddressEstimateCard(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckSameAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCDoNotPropagateFromEstimateIfNotEmpty()
    var
        DummyCustomer: Record Customer;
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer with some address and edits the address in the estimate
        // [THEN] The address is not propagated
        CheckFieldIsNotOverwrittenFromEstimateToCust(DummyCustomer.FieldNo(Address));
        CheckFieldIsNotOverwrittenFromEstimateToCust(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsNotOverwrittenFromEstimateToCust(DummyCustomer.FieldNo(City));
        CheckFieldIsNotOverwrittenFromEstimateToCust(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsNotOverwrittenFromEstimateToCust(DummyCustomer.FieldNo(County));
    end;

    local procedure CheckFieldIsNotOverwrittenFromEstimateToCust(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CustomerName := LibraryInvoicingApp.CreateCustomerWithAddress;

        EditAddressEstimateCard(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckDifferentAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBCDoNotPropagateFromInvoiceIfNotEmpty()
    var
        DummyCustomer: Record Customer;
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new customer with some address and edits the address in the invoice
        // [THEN] The address is not propagated
        CheckFieldIsNotOverwrittenFromInvoiceToCust(DummyCustomer.FieldNo(Address));
        CheckFieldIsNotOverwrittenFromInvoiceToCust(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsNotOverwrittenFromInvoiceToCust(DummyCustomer.FieldNo(City));
        CheckFieldIsNotOverwrittenFromInvoiceToCust(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsNotOverwrittenFromInvoiceToCust(DummyCustomer.FieldNo(County));
    end;

    local procedure CheckFieldIsNotOverwrittenFromInvoiceToCust(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CustomerName := LibraryInvoicingApp.CreateCustomerWithAddress;

        EditAddressInvoiceCard(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckDifferentAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler,CustomerCardModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestBCDoNotPropagateToEstimateIfNotEmpty()
    var
        DummyCustomer: Record Customer;
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new estimate with some address and edits the address in the customer
        // [THEN] The address is not propagated
        CheckFieldIsNotOverwrittenFromCustToEstimate(DummyCustomer.FieldNo(Address));
        CheckFieldIsNotOverwrittenFromCustToEstimate(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsNotOverwrittenFromCustToEstimate(DummyCustomer.FieldNo(City));
        CheckFieldIsNotOverwrittenFromCustToEstimate(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsNotOverwrittenFromCustToEstimate(DummyCustomer.FieldNo(County));
    end;

    local procedure CheckFieldIsNotOverwrittenFromCustToEstimate(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CustomerName := LibraryInvoicingApp.CreateCustomerWithAddress;

        EditAddressCustomerCardFromEstimate(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckDifferentAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('KeepDocumentConfirmHandler,CustomerCardModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestBCDoNotPropagateToInvoiceIfNotEmpty()
    var
        DummyCustomer: Record Customer;
    begin
        // [GIVEN] An user in invoicing Business Center
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user creates a new invoice with some address and edits the address in the customer
        // [THEN] The address is not propagated
        CheckFieldIsNotOverwrittenFromCustToInvoice(DummyCustomer.FieldNo(Address));
        CheckFieldIsNotOverwrittenFromCustToInvoice(DummyCustomer.FieldNo("Address 2"));
        CheckFieldIsNotOverwrittenFromCustToInvoice(DummyCustomer.FieldNo(City));
        CheckFieldIsNotOverwrittenFromCustToInvoice(DummyCustomer.FieldNo("Post Code"));
        CheckFieldIsNotOverwrittenFromCustToInvoice(DummyCustomer.FieldNo(County));
    end;

    local procedure CheckFieldIsNotOverwrittenFromCustToInvoice(CustomerFieldNo: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerName: Text[50];
    begin
        CustomerName := LibraryInvoicingApp.CreateCustomerWithAddress;

        EditAddressCustomerCardFromInvoice(CustomerFieldNo, CustomerName);
        FindCustomerAndSalesHeaderFromName(CustomerName, Customer, SalesHeader);
        CheckDifferentAddress(Customer, SalesHeader);
        DeleteCustomersAndContacts;
    end;

    [Test]
    [HandlerFunctions('AddressPageHandler')]
    [Scope('OnPrem')]
    procedure TestCanChangeCityAndPostCodeIndependently()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        CompanyInformation: Record "Company Information";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BCO365MySettings: TestPage "BC O365 My Settings";
        PreviousCity: Text[50];
        PreviousPostCode: Text[50];
    begin
        // [GIVEN] An user in invoicing
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;
        O365SalesInitialSetup.Get();
        Assert.IsTrue(O365SalesInitialSetup."Is initialized", 'Not an Invoicing company');

        // [GIVEN] The user has set a company address
        BCO365MySettings.OpenEdit;
        with TempStandardAddress do begin
            Address := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(Address));
            "Address 2" := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen("Address 2"));
            City := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(City));
            "Country/Region Code" := 'US';
            County := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(County));
            "Post Code" := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen("Post Code") - 5);
        end;
        PreviousPostCode := TempStandardAddress."Post Code";
        BCO365MySettings.Control20.FullAddress.AssistEdit;
        BCO365MySettings.Close;

        // [WHEN] The user edits the city
        BCO365MySettings.OpenEdit;
        TempStandardAddress.City := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(TempStandardAddress.City));
        BCO365MySettings.Control20.FullAddress.AssistEdit;
        BCO365MySettings.Close;

        // [THEN] The post code is not affected
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation."Post Code", PreviousPostCode, 'Post Code was changed.');
        Assert.AreEqual(CompanyInformation.City, TempStandardAddress.City, 'City was not changed.');

        // [WHEN] The user edits the post code
        BCO365MySettings.OpenEdit;
        PreviousCity := TempStandardAddress.City;
        TempStandardAddress."Post Code" := CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(TempStandardAddress."Post Code"));
        BCO365MySettings.Control20.FullAddress.AssistEdit;
        BCO365MySettings.Close;

        // [THEN] The city is not affected
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation.City, PreviousCity, 'City was changed.');
        Assert.AreEqual(CompanyInformation."Post Code", TempStandardAddress."Post Code", 'Post code was not changed.');

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CheckSameAddress(Customer: Record Customer; SalesHeader: Record "Sales Header")
    var
        Contact: Record Contact;
    begin
        Assert.IsFalse(SalesHeader.HasDifferentBillToAddress(Customer), 'Bill-to address not propagated correctly.');
        Assert.IsFalse(SalesHeader.HasDifferentSellToAddress(Customer), 'Sell-to address not propagated correctly.');

        // Also verify the related contact has the same address
        Contact.Get(FindContactNoByCustomer(Customer."No."));
        Assert.AreEqual(Customer.Address, Contact.Address, 'Address was not propagated to contact');
        Assert.AreEqual(Customer."Address 2", Contact."Address 2", '"Address 2" was not propagated to contact');
        Assert.AreEqual(Customer.City, Contact.City, 'City was not propagated to contact');
        Assert.AreEqual(
          Customer."Country/Region Code",
          Contact."Country/Region Code",
          '"Country/Region Code" was not propagated to contact');
        Assert.AreEqual(Customer.County, Contact.County, 'County was not propagated to contact');
        Assert.AreEqual(Customer."Post Code", Contact."Post Code", '"Post Code" was not propagated to contact');
    end;

    local procedure CheckDifferentAddress(Customer: Record Customer; SalesHeader: Record "Sales Header")
    begin
        Assert.IsTrue(SalesHeader.HasDifferentBillToAddress(Customer), 'Bill-to address propagated.');
        Assert.IsTrue(SalesHeader.HasDifferentSellToAddress(Customer), 'Sell-to address propagated.');
    end;

    local procedure EditAddressCustomerCardFromInvoice(CustomerFieldNo: Integer; CustomerName: Text[50])
    var
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        LibraryVariableStorage.Enqueue(CustomerFieldNo);
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value := CustomerName;
        BCO365SalesInvoice.ViewContactCard.DrillDown;
        // Handler executes and edits field
        BCO365SalesInvoice.Close;
    end;

    local procedure EditAddressCustomerCardFromEstimate(CustomerFieldNo: Integer; CustomerName: Text[50])
    var
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        LibraryVariableStorage.Enqueue(CustomerFieldNo);

        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value := CustomerName;
        BCO365SalesQuote.ViewContactCard.DrillDown;
        // Handler executes and edits field
        BCO365SalesQuote.Close;
    end;

    local procedure EditAddressInvoiceCard(CustomerFieldNo: Integer; CustomerName: Text[50])
    var
        DummyCustomer: Record Customer;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value := CustomerName;

        case CustomerFieldNo of
            DummyCustomer.FieldNo(Address):
                BCO365SalesInvoice."Sell-to Address".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.Address));
            DummyCustomer.FieldNo("Address 2"):
                BCO365SalesInvoice."Sell-to Address 2".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Address 2"));
            DummyCustomer.FieldNo(City):
                BCO365SalesInvoice."Sell-to City".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.City));
            DummyCustomer.FieldNo("Post Code"):
                BCO365SalesInvoice."Sell-to Post Code".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Post Code"));
            DummyCustomer.FieldNo(County):
                BCO365SalesInvoice."Sell-to County".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.County));
            DummyCustomer.FieldNo("Country/Region Code"):
                BCO365SalesInvoice.CountryRegionCode.Value := 'FI';
            else
                Error(UnrecognizedFieldErr);
        end;

        BCO365SalesInvoice.Close;
    end;

    local procedure EditAddressEstimateCard(CustomerFieldNo: Integer; CustomerName: Text[50])
    var
        DummyCustomer: Record Customer;
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value := CustomerName;

        case CustomerFieldNo of
            DummyCustomer.FieldNo(Address):
                BCO365SalesQuote."Sell-to Address".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.Address));
            DummyCustomer.FieldNo("Address 2"):
                BCO365SalesQuote."Sell-to Address 2".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Address 2"));
            DummyCustomer.FieldNo(City):
                BCO365SalesQuote."Sell-to City".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.City));
            DummyCustomer.FieldNo("Post Code"):
                BCO365SalesQuote."Sell-to Post Code".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Post Code"));
            DummyCustomer.FieldNo(County):
                BCO365SalesQuote."Sell-to County".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.County));
            DummyCustomer.FieldNo("Country/Region Code"):
                BCO365SalesQuote.CountryRegionCode.Value := 'NO';
            else
                Error(UnrecognizedFieldErr);
        end;

        BCO365SalesQuote.Close;
    end;

    local procedure FindCustomerAndSalesHeaderFromName(Name: Text; var Customer: Record Customer; var SalesHeader: Record "Sales Header")
    begin
        Customer.SetRange(Name, Name);
        Customer.FindFirst;

        SalesHeader.SetRange("Sell-to Customer Name", Name);
        SalesHeader.FindFirst;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure KeepDocumentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsFalse(
          0 = StrPos(Question, 'Do you want to keep the new'),
          'Unexpected confirm dialog');
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardModalPageHandler(var BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card")
    var
        DummyCustomer: Record Customer;
        FieldNumber: Integer;
    begin
        FieldNumber := LibraryVariableStorage.DequeueInteger;

        case FieldNumber of
            DummyCustomer.FieldNo(Address):
                BCO365SalesCustomerCard.Address.Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.Address));
            DummyCustomer.FieldNo("Address 2"):
                BCO365SalesCustomerCard."Address 2".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Address 2"));
            DummyCustomer.FieldNo(City):
                BCO365SalesCustomerCard.City.Value :=
                  CopyStr(LibraryUtility.GenerateGUID, 1, MaxStrLen(DummyCustomer.City));
            DummyCustomer.FieldNo("Post Code"):
                BCO365SalesCustomerCard."Post Code".Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer."Post Code"));
            DummyCustomer.FieldNo(County):
                BCO365SalesCustomerCard.County.Value :=
                  CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(DummyCustomer.County));
            DummyCustomer.FieldNo("Country/Region Code"):
                BCO365SalesCustomerCard.CountryRegionCode.Value := 'SE';
            else
                Error(UnrecognizedFieldErr);
        end;
    end;

    local procedure CreateCustomerName(var CustomerName: Text[50])
    begin
        CustomerName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 1), 1, 30);
    end;

    local procedure FindContactNoByCustomer(CustomerNo: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo);
        exit(ContBusRel."Contact No.");
    end;

    local procedure DeleteCustomersAndContacts()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.DeleteAll(true);
        Customer.DeleteAll();
        Contact.DeleteAll();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyAddressPageHandler(var O365Address: TestPage "O365 Address")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        Assert.AreEqual(O365Address.Address.Value, CompanyInformation.Address, 'Unexpected address');
        Assert.AreEqual(O365Address."Address 2".Value, CompanyInformation."Address 2", 'Unexpected address 2');
        Assert.AreEqual(O365Address.City.Value, CompanyInformation.City, 'Unexpected city');
        Assert.AreEqual(O365Address."Post Code".Value, CompanyInformation."Post Code", 'Unexpected post code');
        Assert.AreEqual(O365Address.County.Value, CompanyInformation.County, 'Unexpected county');
        Assert.AreEqual(O365Address.CountryRegionCode.Value, CompanyInformation."Country/Region Code", 'Unexpected country/region');

        O365Address.CountryRegionCode.Value := LibraryVariableStorage.DequeueText;

        O365Address.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddressPageHandler(var O365Address: TestPage "O365 Address")
    begin
        if O365Address.Address.Value <> TempStandardAddress.Address then
            O365Address.Address.Value := TempStandardAddress.Address;

        if O365Address."Address 2".Value <> TempStandardAddress."Address 2" then
            O365Address."Address 2".Value := TempStandardAddress."Address 2";

        if O365Address.CountryRegionCode.Value <> TempStandardAddress."Country/Region Code" then
            O365Address.CountryRegionCode.Value := TempStandardAddress."Country/Region Code";

        if O365Address.County.Value <> TempStandardAddress.County then
            O365Address.County.Value := TempStandardAddress.County;

        if O365Address.City.Value <> TempStandardAddress.City then
            O365Address.City.Value := TempStandardAddress.City;

        if O365Address."Post Code".Value <> TempStandardAddress."Post Code" then
            O365Address."Post Code".Value := TempStandardAddress."Post Code";

        O365Address.OK.Invoke;
    end;
}

