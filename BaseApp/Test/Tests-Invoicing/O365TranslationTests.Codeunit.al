#if not CLEAN21
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
        Init();
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(CountryRegion.Code);
        LibraryVariableStorage.Enqueue(TranslatedCountryName);
        O365SalesCustomerCard.FullAddress.AssistEdit;
        O365SalesCustomerCard.Close();
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
        Init();
        GlobalLanguage := GetFRCLanguageID;
        LibrarySales.CreateCustomer(Customer);
        O365SalesCustomerCard.OpenEdit;
        O365SalesCustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(TaxArea.Description);
        LibraryVariableStorage.Enqueue(TranslatedTaxAreaName);
        O365SalesCustomerCard.TaxAreaDescription.Lookup;
        Assert.AreEqual(TranslatedTaxAreaName, O365SalesCustomerCard.TaxAreaDescription.Value, '');
        O365SalesCustomerCard.Close();
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
        Init();
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

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365PaymentTermsList,HandleO365PaymentMethodList')]
    [Scope('OnPrem')]
    procedure PaymentSettingsTest()
    var
        O365PaymentsSettings: TestPage "O365 Payments Settings";
    begin
        Init();
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
        O365PaymentsSettings.Close();
        GlobalLanguage := OrigLang;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleO365CountryRegionList,O365AddressHandler')]
    [Scope('OnPrem')]
    procedure BusinessInfoSettingsTest()
    var
        O365BusinessInfoSettings: TestPage "O365 Business Info Settings";
    begin
        Init();
        GlobalLanguage := GetFRCLanguageID;
        O365BusinessInfoSettings.OpenEdit;
        LibraryVariableStorage.Enqueue(CountryRegion.Code);
        LibraryVariableStorage.Enqueue(TranslatedCountryName);
        O365BusinessInfoSettings.FullAddress.AssistEdit;
        O365BusinessInfoSettings.Close();
        GlobalLanguage := OrigLang;
    end;

    local procedure GetFRCLanguageID(): Integer
    var
        Language: Record Language;
    begin
        Language.SetRange(Code, FRCTxt);
        Language.FindFirst();
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
        CountryRegion.Name := LibraryUtility.GenerateGUID();
        CountryRegion.Modify();
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
        PaymentTerms.Description := LibraryUtility.GenerateGUID();
        PaymentTerms.Modify();
        TranslatedPaymentTermsName :=
            CopyStr(PaymentTerms.Description + PaymentTerms.Description, 1, MaxStrLen(TranslatedPaymentTermsName));
        InsertPaymentTermsTranslation(PaymentTerms.Code, FRCTxt, TranslatedPaymentTermsName);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Description := LibraryUtility.GenerateGUID();
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

        if not O365C2GraphEventSettings.Get() then
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
#endif
