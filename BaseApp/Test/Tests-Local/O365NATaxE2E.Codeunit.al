codeunit 138932 "O365 NA Tax E2E"
{
    Permissions = TableData "Sales Invoice Header" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Tax] [UI]
    end;

    var
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        TaxRateChangeResponse: Option ,KeepEditing,Discard;
        UpdateOtherAreasTxt: Label 'Updating a city or state tax rate will affect all customers using the rate.';
        InvoiceSentMsg: Label 'Your invoice is being sent.';
        TaxAreaInUseErr: Label 'You cannot delete this tax rate because it is used on one or more existing documents.';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CreateNewTaxRateStateCode()
    var
        StateCode: Code[10];
        StateRate: Integer;
    begin
        // [SCENARIO 210148] Sunshine scenario for creating tax rate with State code and State rate
        Initialize();

        // [WHEN] New tax rate State Code = XX and State Rate = 10 in the Tax Rate page
        StateCode := 'XX';
        StateRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithState(StateCode, StateRate);

        // [THEN] New Tax Area is created with State Code = xx and State Rate = 10
        VerifyTaxRate(StateCode, StateRate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EditTaxRateStateCode()
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        O365TaxSettingsList: TestPage "O365 Tax Settings List";
        StateCode: Code[10];
        NewStateCode: Code[10];
        StateRate: Integer;
    begin
        // [SCENARIO 210148] Sunshine scenario for editing tax rate State code
        Initialize();

        // [GIVEN] Tax rate State Code = XX and State Rate = 10 in the Tax Rate page
        StateCode := 'XX';
        StateRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithState(StateCode, StateRate);

        // [GIVEN] Open page Tax Rate for editing
        O365TaxSettingsCard.Trap;
        O365TaxSettingsList.OpenView;
        O365TaxSettingsList.Open.Invoke;

        // [GIVEN] Set State = 'YY'
        NewStateCode := 'YY';
        O365TaxSettingsCard.State.SetValue(NewStateCode);

        // [WHEN] Page Tax Rate is being closed
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] New Tax Area is created with
        VerifyTaxRate(NewStateCode, StateRate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CreateNewTaxRateWithEmptyStateCodeRespondDiscard()
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        // [SCENARIO 210148] Discard creating new tax rate with empty state rate doesn't lead to creating new tax area
        Initialize();

        // [GIVEN] New tax rate with empty State and non empty State Rate in the Tax Rate page
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.State.Value('');
        O365TaxSettingsCard.StateRate.SetValue(LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Page Tax Rate is being closed with response Discard
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::Discard);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] New Tax Area is not created
        Assert.RecordIsEmpty(TaxArea);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure CreateNewTaxRateWithEmptyStateCodeRespondKeepEditing()
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        // [SCENARIO 210148] Page Tax Rate is not closed after Keep Editing respond while creating new tax rate with empty state rate
        Initialize();

        // [GIVEN] New tax rate with empty State and non empty State Rate in the Tax Rate page
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.State.Value('');
        O365TaxSettingsCard.StateRate.SetValue(LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Page Tax Rate is being closed with response KeepEditing
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::KeepEditing);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] New Tax Area is not created
        Assert.RecordIsEmpty(TaxArea);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure SetEmptyStateCodeForTaxRateRespondDiscard()
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        O365TaxSettingsList: TestPage "O365 Tax Settings List";
        StateCode: Code[10];
        StateRate: Integer;
    begin
        // [SCENARIO 210148] Discard of changing tax rate state ratedoesn't create new tax area
        Initialize();

        // [GIVEN] Tax rate with State = 'XX' and State Rate = 5
        StateCode := 'XX';
        StateRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithState(StateCode, StateRate);

        // [GIVEN] Open page Tax Rate for editing
        O365TaxSettingsCard.Trap;
        O365TaxSettingsList.OpenView;
        O365TaxSettingsList.Open.Invoke;

        // [GIVEN] Set State = ''
        O365TaxSettingsCard.State.SetValue('');

        // [WHEN] Page Tax Rate is being closed with response Discard
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::Discard);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] Tax rate XX has not been changed
        VerifyTaxRate(StateCode, StateRate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure SetEmptyStateCodeForTaxRateRespondKeepEditing()
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        O365TaxSettingsList: TestPage "O365 Tax Settings List";
        StateCode: Code[10];
        StateRate: Integer;
    begin
        // [SCENARIO 210148] Page Tax Rate is not closed after Keep Editing respond while state rate became empty
        Initialize();

        // [GIVEN] Tax rate with State = 'XX' and State Rate = 5
        StateCode := 'XX';
        StateRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithState(StateCode, StateRate);

        // [GIVEN] Open page Tax Rate for editing
        O365TaxSettingsCard.Trap;
        O365TaxSettingsList.OpenView;
        O365TaxSettingsList.Open.Invoke;

        // [GIVEN] Set State = ''
        O365TaxSettingsCard.State.SetValue('');

        // [WHEN] Page Tax Rate is being closed with response Keep Editing
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::KeepEditing);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] Page Tax Rate is not closed, State left 'XX'
        O365TaxSettingsCard.First;
        O365TaxSettingsCard.State.AssertEquals(StateCode);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure CreateNewTaxRateWithEmptyCityRespondDiscard()
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        // [SCENARIO 210148] Discard creating new tax rate with empty city rate doesn't lead to creating new tax area
        Initialize();

        // [GIVEN] New tax rate with empty City and non empty City Rate in the Tax Rate page
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.City.Value('');
        O365TaxSettingsCard.CityRate.SetValue(LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Page Tax Rate is being closed with response Discard
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::Discard);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] New Tax Area is not created
        Assert.RecordIsEmpty(TaxArea);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure CreateNewTaxRateWithEmptyCityRespondKeepEditing()
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        // [SCENARIO 210148] Page Tax Rate is not closed after Keep Editing respond while creating new tax rate with empty city rate
        Initialize();

        // [GIVEN] New tax rate with empty City and non empty City Rate in the Tax Rate page
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.City.Value('');
        O365TaxSettingsCard.CityRate.SetValue(LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Page Tax Rate is being closed with response KeepEditing
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::KeepEditing);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] New Tax Area is not created
        Assert.RecordIsEmpty(TaxArea);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure SetEmptyCityForTaxRateRespondDiscard()
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        O365TaxSettingsList: TestPage "O365 Tax Settings List";
        CityCode: Code[10];
        CityRate: Integer;
    begin
        // [SCENARIO 210148] Discard of changing tax rate city ratedoesn't create new tax area
        Initialize();

        // [GIVEN] Tax rate with City = 'XX' and City Rate = 5
        CityCode := 'XX';
        CityRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithCity(CityCode, CityRate);

        // [GIVEN] Open page Tax Rate for editing
        O365TaxSettingsCard.Trap;
        O365TaxSettingsList.OpenView;
        O365TaxSettingsList.Open.Invoke;

        // [GIVEN] Set City = ''
        O365TaxSettingsCard.City.SetValue('');

        // [WHEN] Page Tax Rate is being closed with response Discard
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::Discard);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] Tax rate XX has not been changed
        VerifyTaxRate(CityCode, CityRate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,TaxRateChangeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure SetEmptyCityForTaxRateRespondKeepEditing()
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        O365TaxSettingsList: TestPage "O365 Tax Settings List";
        CityCode: Code[10];
        CityRate: Integer;
    begin
        // [SCENARIO 210148] Page Tax Rate is not closed after Keep Editing respond while city rate became empty
        Initialize();

        // [GIVEN] Tax rate with City = 'XX' and City Rate = 5
        CityCode := 'XX';
        CityRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithCity(CityCode, CityRate);

        // [GIVEN] Open page Tax Rate for editing
        O365TaxSettingsCard.Trap;
        O365TaxSettingsList.OpenView;
        O365TaxSettingsList.Open.Invoke;

        // [GIVEN] Set City = ''
        O365TaxSettingsCard.City.SetValue('');

        // [WHEN] Page Tax Rate is being closed with response Keep Editing
        LibraryVariableStorage.Enqueue(TaxRateChangeResponse::KeepEditing);
        O365TaxSettingsCard.OK.Invoke;

        // [THEN] Page Tax Rate is not closed, City left 'XX'
        O365TaxSettingsCard.First;
        O365TaxSettingsCard.City.AssertEquals(CityCode);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,UpdateOtherAreasStrMenuHandlerConfirm')]
    [Scope('OnPrem')]
    procedure TestUpdateOtherTaxAreasConfirm()
    var
        InitialStateRate: Decimal;
        InitialCityRate: Decimal;
    begin
        Initialize();

        // [GIVEN] The user has two different tax areas
        InitialStateRate := LibraryRandom.RandIntInRange(10, 20);
        InitialCityRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithStateAndCity('SS', InitialStateRate, 'CC', InitialCityRate);
        CreateAndSetupTaxRateWithStateAndCity('TT', InitialStateRate, 'DD', InitialCityRate);

        // [WHEN] The user creates a new tax area with same state of a previous one, and selects 'Continue' in the dialog
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('TT', InitialStateRate + 1.0, 'EE', InitialCityRate);

        // [THEN] Only the tax rate with the same state is modified
        VerifyTaxRate('TT', 1.0 + InitialStateRate);
        VerifyTaxRate('DD', InitialCityRate);
        VerifyTaxRate('SS', InitialStateRate);
        VerifyTaxRate('CC', InitialCityRate);
        VerifyTaxRate('EE', InitialCityRate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,UpdateOtherAreasStrMenuHandlerUndo')]
    [Scope('OnPrem')]
    procedure TestUpdateOtherTaxAreasUndo()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        InitialStateRate: Decimal;
        InitialCityRate: Decimal;
    begin
        Initialize();

        // [GIVEN] The user has two different tax areas
        InitialStateRate := LibraryRandom.RandIntInRange(10, 20);
        InitialCityRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupTaxRateWithStateAndCity('SS', InitialStateRate, 'CC', InitialCityRate);
        CreateAndSetupTaxRateWithStateAndCity('TT', InitialStateRate, 'DD', InitialCityRate);

        // [WHEN] The user creates a new tax area with same state of a previous one, and selects 'Undo' in the dialog
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('TT', InitialStateRate + 1.0, 'EE', InitialCityRate);

        // [THEN] No tax rate is modified
        VerifyTaxRate('TT', InitialStateRate);
        VerifyTaxRate('DD', InitialCityRate);
        VerifyTaxRate('SS', InitialStateRate);
        VerifyTaxRate('CC', InitialCityRate);

        TaxJurisdiction.SetRange(Code, 'EE');
        Assert.AreEqual(0, TaxJurisdiction.Count, 'Tax jurisdiction has been inserted.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCanPostInvoiceWithNewTaxArea()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryWorkflow: Codeunit "Library - Workflow";
        InitialStateRate: Decimal;
        InitialCityRate: Decimal;
        PostedInvNo: Code[20];
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] The user has set up a tax area as default
        InitialStateRate := LibraryRandom.RandIntInRange(10, 20);
        InitialCityRate := LibraryRandom.RandIntInRange(10, 20);
        CreateAndSetupDefaultTaxRateWithStateAndCity('SS', InitialStateRate, 'CC', InitialCityRate);

        // [WHEN] The user sends an invoice
        LibraryVariableStorage.Enqueue(InvoiceSentMsg);
        PostedInvNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The invoice has the correct tax area
        SalesInvoiceHeader.Get(PostedInvNo);
        VerifyTaxAreaStateAndCity(SalesInvoiceHeader."Tax Area Code", 'SS', 'CC');
    end;

    [Test]
    [HandlerFunctions('UpdateOtherAreasStrMenuHandlerConfirm')]
    [Scope('OnPrem')]
    procedure TestChangingCityTaxAlsoUpdatesRelatedTaxAreasAndInvoices()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set (called A) up with City name Lyngby, rate = 5% and State name = NY, rate 3%
        // [GIVEN] A customer using this tax setup
        // [GIVEN] An invoice for this customer which has in total 8% tax
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupDefaultTaxRateWithStateAndCity('NY', 3, 'Lyngby', 5);
        DocumentNo := LibraryInvoicingApp.CreateInvoice;

        // [WHEN] A new tax is set up with city name Lyngby, rate = 10% and state name = DY, rate 20%
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('DY', 20, 'Lyngby', 10);

        // [THEN] The lyngby tax rate has changed to 10%
        VerifyTaxRate('Lyngby', 10);

        // [THEN] The existing invoice line amounts have automatically been updated to the new tax percentage
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Assert.AreEqual(
          Round(SalesLine.Amount * 1.13, 0.01), SalesLine."Amount Including VAT",
          'The sales tax has not been correctly updated on the related invoices');
    end;

    [Test]
    [HandlerFunctions('UpdateOtherAreasStrMenuHandlerConfirm')]
    [Scope('OnPrem')]
    procedure TestChangingStateTaxAlsoUpdatesRelatedTaxAreasAndInvoices()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set (called A) up with City name Lyngby, rate = 5% and State name = NY, rate 3%
        // [GIVEN] A customer using this tax setup
        // [GIVEN] An invoice for this customer which has in total 8% tax
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupDefaultTaxRateWithStateAndCity('NY', 3, 'Lyngby', 5);
        DocumentNo := LibraryInvoicingApp.CreateInvoice;

        // [WHEN] A new tax is set up with city name Copenhagen, rate = 10% and state name = NY, rate 20%
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('NY', 20, 'Copenhagen', 10);

        // [THEN] The NY tax rate has changed to 20%
        VerifyTaxRate('NY', 20);

        // [THEN] The existing invoice line amounts have automatically been updated to the new tax percentage
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Assert.AreEqual(
          Round(SalesLine.Amount * 1.25, 0.01), SalesLine."Amount Including VAT",
          'The sales tax has not been correctly updated on the related invoices');
    end;

    [Test]
    [HandlerFunctions('UpdateOtherAreasStrMenuHandlerConfirm')]
    [Scope('OnPrem')]
    procedure TestChangingCityTaxAlsoUpdatesRelatedTaxAreasAndEstimates()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set (called A) up with City name Lyngby, rate = 5% and State name = NY, rate 3%
        // [GIVEN] A customer using this tax setup
        // [GIVEN] An invoice for this customer which has in total 8% tax
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupDefaultTaxRateWithStateAndCity('NY', 3, 'Lyngby', 5);
        DocumentNo := LibraryInvoicingApp.CreateEstimate;

        // [WHEN] A new tax is set up with city name Lyngby, rate = 10% and state name = DY, rate 20%
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('DY', 20, 'Lyngby', 10);

        // [THEN] The lyngby tax rate has changed to 10%
        VerifyTaxRate('Lyngby', 10);

        // [THEN] The existing invoice line amounts have automatically been updated to the new tax percentage
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Assert.AreEqual(
          Round(SalesLine.Amount * 1.13, 0.01), SalesLine."Amount Including VAT",
          'The sales tax has not been correctly updated on the related invoices');
    end;

    [Test]
    [HandlerFunctions('UpdateOtherAreasStrMenuHandlerConfirm')]
    [Scope('OnPrem')]
    procedure TestChangingStateTaxAlsoUpdatesRelatedTaxAreasAndEstimates()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set (called A) up with City name Lyngby, rate = 5% and State name = NY, rate 3%
        // [GIVEN] A customer using this tax setup
        // [GIVEN] An invoice for this customer which has in total 8% tax
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupDefaultTaxRateWithStateAndCity('NY', 3, 'Lyngby', 5);
        DocumentNo := LibraryInvoicingApp.CreateEstimate;

        // [WHEN] A new tax is set up with city name Copenhagen, rate = 10% and state name = NY, rate 20%
        LibraryVariableStorage.Enqueue(UpdateOtherAreasTxt);
        CreateAndSetupTaxRateWithStateAndCity('NY', 20, 'Copenhagen', 10);

        // [THEN] The NY tax rate has changed to 20%
        VerifyTaxRate('NY', 20);

        // [THEN] The existing invoice line amounts have automatically been updated to the new tax percentage
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Assert.AreEqual(
          Round(SalesLine.Amount * 1.25, 0.01), SalesLine."Amount Including VAT",
          'The sales tax has not been correctly updated on the related invoices');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveTaxAreaInUseCustomer()
    var
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set up
        // [GIVEN] A customer using this tax setup
        CreateAndSetupTaxRateWithStateAndCity('AB', 3, 'Lyngby', 5);
        TaxArea.Get('LYNGBY, AB');
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea.Code);
        Customer.Modify(true);

        // [WHEN] The tax area is removed
        asserterror TaxArea.Delete(true);

        // [THEN] An error is thrown as it is in use
        Assert.ExpectedError(TaxAreaInUseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveTaxAreaInUseSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set up
        // [GIVEN] An unposted sales document is using this tax setup
        CreateAndSetupTaxRateWithStateAndCity('AC', 3, 'Lyngby', 5);
        TaxArea.Get('LYNGBY, AC');
        SalesHeader.Init();
        SalesHeader."Tax Area Code" := TaxArea.Code;
        SalesHeader.Insert();

        // [WHEN] The tax area is removed
        asserterror TaxArea.Delete(true);

        // [THEN] An error is thrown as it is in use
        Assert.ExpectedError(TaxAreaInUseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveTaxAreaInUseSalesInvoiceHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxArea: Record "Tax Area";
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set up
        // [GIVEN] A posted sales document is using this tax setup
        CreateAndSetupTaxRateWithStateAndCity('AD', 3, 'Lyngby', 5);
        TaxArea.Get('LYNGBY, AD');
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."Tax Area Code" := TaxArea.Code;
        SalesInvoiceHeader.Insert();

        // [WHEN] The tax area is removed
        asserterror TaxArea.Delete(true);

        // [THEN] An error is thrown as it is in use
        Assert.ExpectedError(TaxAreaInUseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveTaxAreNotInUse()
    var
        TaxArea: Record "Tax Area";
    begin
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] Tax set up
        // [GIVEN] No one is using the tax area code
        CreateAndSetupTaxRateWithStateAndCity('AE', 3, 'Lyngby', 5);
        TaxArea.Get('LYNGBY, AE');

        // [WHEN] The tax area is removed
        // [THEN] The tax area is removed
        Assert.IsTrue(TaxArea.Delete(true), '');
    end;

    local procedure Initialize()
    begin
        EventSubscriberInvoicingApp.Clear;
        LibraryVariableStorage.Clear();
        ClearTaxRates;

        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        IsInitialized := true;
    end;

    local procedure CreateAndSetupTaxRateWithStateAndCity(StateCode: Code[10]; StateRate: Decimal; CityCode: Code[10]; CityRate: Decimal)
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.State.Value(StateCode);
        O365TaxSettingsCard.StateRate.SetValue(StateRate);
        O365TaxSettingsCard.City.Value(CityCode);
        O365TaxSettingsCard.CityRate.SetValue(CityRate);
        O365TaxSettingsCard.Close;
    end;

    local procedure CreateAndSetupDefaultTaxRateWithStateAndCity(StateCode: Code[10]; StateRate: Decimal; CityCode: Code[10]; CityRate: Decimal)
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.State.Value(StateCode);
        O365TaxSettingsCard.StateRate.SetValue(StateRate);
        O365TaxSettingsCard.City.Value(CityCode);
        O365TaxSettingsCard.CityRate.SetValue(CityRate);
        O365TaxSettingsCard.Default.DrillDown;
        O365TaxSettingsCard.Close;
    end;

    local procedure CreateAndSetupTaxRateWithState(StateCode: Code[10]; StateRate: Decimal)
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.State.Value(StateCode);
        O365TaxSettingsCard.StateRate.SetValue(StateRate);
        O365TaxSettingsCard.Close;
    end;

    local procedure CreateAndSetupTaxRateWithCity(CityCode: Code[10]; CityRate: Decimal)
    var
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
    begin
        O365TaxSettingsCard.OpenNew();
        O365TaxSettingsCard.City.Value(CityCode);
        O365TaxSettingsCard.CityRate.SetValue(CityRate);
        O365TaxSettingsCard.Close;
    end;

    local procedure ClearTaxRates()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxJurisdiction.DeleteAll(true);
        TaxArea.DeleteAll(false);
        TaxAreaLine.DeleteAll(true);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TaxRateChangeStrMenuHandler(Option: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;

    local procedure VerifyTaxRate(TaxJurisdictionCode: Code[10]; TaxBelowMaximum: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        TaxDetail.SetRange("Tax Below Maximum", TaxBelowMaximum);
        Assert.RecordIsNotEmpty(TaxDetail);

        TaxAreaLine.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        Assert.RecordIsNotEmpty(TaxAreaLine);
    end;

    local procedure VerifyTaxAreaStateAndCity(TaxAreaCode: Code[20]; StateCode: Code[10]; CityCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.Get(TaxAreaCode, StateCode);
        TaxAreaLine.Get(TaxAreaCode, CityCode);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure UpdateOtherAreasStrMenuHandlerConfirm(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    var
        ResponseOpt: Option Cancel,Continue,Undo;
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Instructions, 'Unexpected strmenu.');
        Choice := ResponseOpt::Continue;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure UpdateOtherAreasStrMenuHandlerUndo(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    var
        ResponseOpt: Option Cancel,Continue,Undo;
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Instructions, 'Unexpected strmenu.');
        Choice := ResponseOpt::Undo;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        if O365SalesEmailDialog.SendToText.Value = '' then
            O365SalesEmailDialog.SendToText.Value('invoicing@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

