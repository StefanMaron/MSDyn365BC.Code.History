codeunit 138916 "O365 Translation Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Language] [UI]
    end;

    var
        FRCTxt: Label 'FRC', Locked = true;
        CountryRegion: Record "Country/Region";
        TaxArea: Record "Tax Area";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        UnitOfMeasure: Record "Unit of Measure";
        OtherUnitOfMeasure: Record "Unit of Measure";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        OrigLang: Integer;
        TranslatedCountryName: Text[50];
        TranslatedTaxAreaName: Text[50];
        TranslatedPaymentTermsName: Text[50];
        TranslatedPaymentMethodName: Text[50];
        TranslatedOtherUOMDescription: Text[10];
        TranslatedUOMDescription: Text[10];
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365CountryRegionList,O365AddressHandler')]
    [Scope('OnPrem')]
    procedure CustomerCardCountryRegionTest()
    var
        Customer: Record Customer;
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
    begin
        Init;
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(CountryRegion.Code);
        LibraryVariableStorage.Enqueue(TranslatedCountryName);
        O365SalesCustomerCard.FullAddress.AssistEdit;
        O365SalesCustomerCard.Close;
        GlobalLanguage := OrigLang;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365TaxAreaList')]
    [Scope('OnPrem')]
    procedure CustomerCardTaxAreaTest()
    var
        Customer: Record Customer;
        O365SalesCustomerCard: TestPage "O365 Sales Customer Card";
    begin
        Init;
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(TaxArea.Description);
        LibraryVariableStorage.Enqueue(TranslatedTaxAreaName);
        O365SalesCustomerCard.TaxAreaDescription.Lookup;
        Assert.AreEqual(TranslatedTaxAreaName, O365SalesCustomerCard.TaxAreaDescription.Value, '');
        O365SalesCustomerCard.Close;
        GlobalLanguage := OrigLang;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365TaxAreaList')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTest()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        Init;
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);
        LibraryVariableStorage.Enqueue(TaxArea.Description);
        LibraryVariableStorage.Enqueue(TranslatedTaxAreaName);
        O365SalesInvoice.TaxAreaDescription.Lookup;
        Assert.AreEqual(TranslatedTaxAreaName, O365SalesInvoice.TaxAreaDescription.Value, '');
        O365SalesInvoice.SaveForLater.Invoke;
        GlobalLanguage := OrigLang;
    end;

    // [Test] The test fails with an invalid error message.
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365UOMList')]
    [Scope('OnPrem')]
    procedure UOMInvoiceTest()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        TaxDetail: Record "Tax Detail";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        O365UnitsofMeasureList: TestPage "O365 Units of Measure List";
    begin
        // [GIVEN] A French-Canadian Invoicing user (taxes are set up to avoid notification when test is run in US)
        Init;
        TaxDetail.ModifyAll("Tax Below Maximum", 5.0);
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateItemWithUOM(Item, UnitOfMeasure);

        // [WHEN] The user creates a new line for a sales invoice and inserts an item description that matches an existing item
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value := Item.Description;

        // [THEN] The unit of measure is populated in the correct language
        Assert.AreEqual(BCO365SalesInvoice.Lines.UnitOfMeasure.Value, TranslatedUOMDescription, '');

        // [WHEN] The user changes unit of measure again by looking up
        LibraryVariableStorage.Enqueue(OtherUnitOfMeasure.Code);
        BCO365SalesInvoice.Lines.UnitOfMeasure.Lookup;

        // [THEN] The unit of measure is populated in the correct language and the lookup page is also in the current language
        Assert.AreEqual(TranslatedOtherUOMDescription, BCO365SalesInvoice.Lines.UnitOfMeasure.Value, '');
        BCO365SalesInvoice.Close;

        O365UnitsofMeasureList.OpenView;
        O365UnitsofMeasureList.GotoKey(OtherUnitOfMeasure.Code);
        Assert.AreEqual(TranslatedOtherUOMDescription, O365UnitsofMeasureList.Description.Value, '');

        GlobalLanguage := OrigLang;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365PaymentTermsList,HandleO365PaymentMethodList')]
    [Scope('OnPrem')]
    procedure PaymentSettingsTest()
    var
        O365PaymentsSettings: TestPage "O365 Payments Settings";
    begin
        Init;
        GlobalLanguage := GetFRCLanguageID;
        O365PaymentsSettings.OpenEdit;
        LibraryVariableStorage.Enqueue(PaymentTerms.Code);
        LibraryVariableStorage.Enqueue(TranslatedPaymentTermsName);
        O365PaymentsSettings.PaymentTermsCode.Lookup;
        LibraryVariableStorage.Enqueue(PaymentMethod.Code);
        LibraryVariableStorage.Enqueue(TranslatedPaymentMethodName);
        O365PaymentsSettings.PaymentMethodCode.Lookup;
        Assert.AreEqual(PaymentTerms.Code, O365PaymentsSettings.PaymentTermsCode.Value, '');
        Assert.AreEqual(PaymentMethod.Code, O365PaymentsSettings.PaymentMethodCode.Value, '');
        O365PaymentsSettings.Close;
        GlobalLanguage := OrigLang;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365CountryRegionList,O365AddressHandler')]
    [Scope('OnPrem')]
    procedure BusinessInfoSettingsTest()
    var
        O365BusinessInfoSettings: TestPage "O365 Business Info Settings";
    begin
        Init;
        GlobalLanguage := GetFRCLanguageID;
        O365BusinessInfoSettings.OpenEdit;
        LibraryVariableStorage.Enqueue(CountryRegion.Code);
        LibraryVariableStorage.Enqueue(TranslatedCountryName);
        O365BusinessInfoSettings.FullAddress.AssistEdit;
        O365BusinessInfoSettings.Close;
        GlobalLanguage := OrigLang;
    end;

    local procedure GetFRCLanguageID(): Integer
    var
        Language: Record Language;
    begin
        Language.SetRange(Code, FRCTxt);
        Language.FindFirst;
        exit(Language."Windows Language ID");
    end;

    local procedure CreateUOM(var LocalUnitOfMeasure: Record "Unit of Measure")
    begin
        LocalUnitOfMeasure.Init();
        LocalUnitOfMeasure.Validate(Code, LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
        LocalUnitOfMeasure.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(UnitOfMeasure.Description)));
        LocalUnitOfMeasure.Insert(true);
    end;

    local procedure CreateCountry(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Name := LibraryUtility.GenerateGUID;
        CountryRegion.Modify();
    end;

    local procedure CreateItemWithUOM(var Item: Record Item; LocalUnitOfMeasure: Record "Unit of Measure")
    var
        ItemTemplate: Record "Item Template";
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        ItemTemplate.NewItemFromTemplate(Item);
        O365SalesManagement.SetItemDefaultValues(Item);

        Item.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 1));
        Item.Validate("Unit Price", LibraryUtility.GenerateRandomFraction);
        Item.Validate("Base Unit of Measure", LocalUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure InsertCountryRegionTranslation(CRCode: Code[10]; LCode: Code[10]; TranslatedName: Text[50])
    var
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        CountryRegionTranslation."Country/Region Code" := CRCode;
        CountryRegionTranslation."Language Code" := LCode;
        CountryRegionTranslation.Name := TranslatedName;
        if CountryRegionTranslation.Insert() then;
    end;

    local procedure InsertTaxAreaTranslation(TaxAreaCode: Code[20]; LCode: Code[10]; TranslatedName: Text[50])
    var
        TaxAreaTranslation: Record "Tax Area Translation";
    begin
        TaxAreaTranslation."Tax Area Code" := TaxAreaCode;
        TaxAreaTranslation."Language Code" := LCode;
        TaxAreaTranslation.Description := TranslatedName;
        if TaxAreaTranslation.Insert() then;
    end;

    local procedure InsertPaymentTermsTranslation(PaymentTermsCode: Code[10]; LCode: Code[10]; TranslatedName: Text[50])
    var
        PaymentTermTranslation: Record "Payment Term Translation";
    begin
        PaymentTermTranslation."Payment Term" := PaymentTermsCode;
        PaymentTermTranslation."Language Code" := LCode;
        PaymentTermTranslation.Description := TranslatedName;
        if PaymentTermTranslation.Insert() then;
    end;

    local procedure InsertPaymentMethodTranslation(PaymentMethodCode: Code[10]; LCode: Code[10]; TranslatedName: Text[50])
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
    begin
        PaymentMethodTranslation."Payment Method Code" := PaymentMethodCode;
        PaymentMethodTranslation."Language Code" := LCode;
        PaymentMethodTranslation.Description := TranslatedName;
        if PaymentMethodTranslation.Insert() then;
    end;

    local procedure InsertUOMTranslation(UOMCode: Code[10]; LCode: Code[10]; TranslatedDescription: Text[10])
    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
    begin
        UnitOfMeasureTranslation.Code := UOMCode;
        UnitOfMeasureTranslation."Language Code" := LCode;
        UnitOfMeasureTranslation.Description := TranslatedDescription;
        if UnitOfMeasureTranslation.Insert() then;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleO365CountryRegionList(var O365CountryRegionList: TestPage "O365 Country/Region List")
    var
        CountryRegionCode: Code[10];
        TranslatedName: Text[50];
    begin
        CountryRegionCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(CountryRegionCode));
        TranslatedName := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TranslatedName));
        O365CountryRegionList.FindFirstField(Code, CountryRegionCode);
        Assert.AreEqual(TranslatedName, O365CountryRegionList.Name.Value, '');
        O365CountryRegionList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleO365TaxAreaList(var O365TaxAreaList: TestPage "O365 Tax Area List")
    var
        TaxAreaCode: Code[10];
        TranslatedName: Text[50];
    begin
        TaxAreaCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TaxAreaCode));
        TranslatedName := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TranslatedName));
        O365TaxAreaList.GotoKey(TaxAreaCode);
        Assert.AreEqual(TranslatedName, O365TaxAreaList.Name.Value, '');
        O365TaxAreaList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleO365UOMList(var O365UnitsofMeasure: TestPage "O365 Units of Measure List")
    var
        UOMCode: Code[10];
    begin
        UOMCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(UOMCode));
        O365UnitsofMeasure.GotoKey(UOMCode);
        O365UnitsofMeasure.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleO365PaymentTermsList(var O365PaymentTermsList: TestPage "O365 Payment Terms List")
    var
        PaymentTermsCode: Code[10];
        TranslatedName: Text[50];
    begin
        PaymentTermsCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(PaymentTermsCode));
        TranslatedName := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TranslatedName));
        O365PaymentTermsList.FindFirstField(Code, PaymentTermsCode);
        O365PaymentTermsList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleO365PaymentMethodList(var O365PaymentMethodList: TestPage "O365 Payment Method List")
    var
        PaymentMethodCode: Code[10];
        TranslatedName: Text[50];
    begin
        PaymentMethodCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(PaymentMethodCode));
        TranslatedName := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TranslatedName));
        O365PaymentMethodList.FindFirstField(Code, PaymentMethodCode);
        Assert.AreEqual(TranslatedName, O365PaymentMethodList.Description.Value, '');
        O365PaymentMethodList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365AddressHandler(var O365Address: TestPage "O365 Address")
    begin
        O365Address.CountryRegionCode.Lookup;
        Assert.AreEqual(CountryRegion.Code, O365Address.CountryRegionCode.Value, '');
    end;

    local procedure Init()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Translation Tests");

        if not Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Translation Tests");
        if O365SalesInitialSetup.Insert() then;
        OrigLang := GlobalLanguage;

        CreateCountry(CountryRegion);
        TranslatedCountryName :=
            CopyStr(CountryRegion.Name + CountryRegion.Name, 1, MaxStrLen(TranslatedCountryName));
        InsertCountryRegionTranslation(CountryRegion.Code, FRCTxt, TranslatedCountryName);

        LibraryERM.CreateTaxArea(TaxArea);
        TranslatedTaxAreaName :=
            CopyStr(TaxArea.Description + TaxArea.Description, 1, MaxStrLen(TranslatedTaxAreaName));
        InsertTaxAreaTranslation(TaxArea.Code, FRCTxt, TranslatedTaxAreaName);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Description := LibraryUtility.GenerateGUID;
        PaymentTerms.Modify();
        TranslatedPaymentTermsName :=
            CopyStr(PaymentTerms.Description + PaymentTerms.Description, 1, MaxStrLen(TranslatedPaymentTermsName));
        InsertPaymentTermsTranslation(PaymentTerms.Code, FRCTxt, TranslatedPaymentTermsName);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Description := LibraryUtility.GenerateGUID;
        PaymentMethod."Use for Invoicing" := true;
        PaymentMethod.Modify();
        TranslatedPaymentMethodName :=
            CopyStr(PaymentMethod.Description + PaymentMethod.Description, 1, MaxStrLen(TranslatedPaymentMethodName));
        InsertPaymentMethodTranslation(PaymentMethod.Code, FRCTxt, TranslatedPaymentMethodName);

        CreateUOM(UnitOfMeasure);
        TranslatedUOMDescription :=
            CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(TranslatedUOMDescription)), 1, MaxStrLen(TranslatedUOMDescription));
        InsertUOMTranslation(UnitOfMeasure.Code, FRCTxt, TranslatedUOMDescription);

        CreateUOM(OtherUnitOfMeasure);
        TranslatedOtherUOMDescription := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(TranslatedOtherUOMDescription)),
            1, MaxStrLen(TranslatedOtherUOMDescription));
        InsertUOMTranslation(OtherUnitOfMeasure.Code, FRCTxt, TranslatedOtherUOMDescription);

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Translation Tests");
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

