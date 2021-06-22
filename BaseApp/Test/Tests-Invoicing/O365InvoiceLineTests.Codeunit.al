codeunit 138935 "O365 Invoice Line Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [E2E] [UI]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        Language: Codeunit Language;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestInvoiceLineEditability()
    var
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        PriceName: Text;
        CustomerName: Text[50];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An invoicing user has a customer and a price
        CustomerName := LibraryInvoicingApp.CreateCustomer;
        PriceName := LibraryInvoicingApp.CreateItemWithPrice;

        // [WHEN] The user creates a new invoice
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value := CustomerName;
        BCO365SalesInvoice.Lines.New;

        // [THEN] The fields for invoice line are disabled, except the description
        CheckLinesSubpageFieldsEditability(false, BCO365SalesInvoice);

        // [WHEN] The user adds a line description
        BCO365SalesInvoice.Lines.Description.Value := PriceName;

        // [THEN] The fields for invoice line are enabled
        CheckLinesSubpageFieldsEditability(true, BCO365SalesInvoice);

        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestRenameUOMFailsGreaterThan10Char()
    var
        O365UnitOfMeasureCard: TestPage "O365 Unit Of Measure Card";
        NewUOMDescription: Text[50];
        OldUOMDescription: Text[10];
        UOMCode: Code[10];
        ItemDescription: Text[50];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has a Unit of Measure used in one posted invoice
        CreateItemWithUnitOfMeasure(ItemDescription, OldUOMDescription, UOMCode, false);
        LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.AddLineToInvoice(LibraryInvoicingApp.CreateInvoice, ItemDescription));

        O365UnitOfMeasureCard.OpenEdit;
        O365UnitOfMeasureCard.GotoKey(UOMCode);
        NewUOMDescription := GetRandText50;

        // [WHEN] The user renames the unit of measure
        asserterror O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value := NewUOMDescription;

        // [THEN] Expected error that length is too long
        Assert.ExpectedError('must be less than or equal to 10 characters');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestRenameUOMNotAffectingPostedLines()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedInvoiceNo: Code[20];
        OldUOMDescription: Text[10];
        UOMCode: Code[10];
        ItemDescription: Text[50];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has a Unit of Measure used in one posted invoice
        CreateItemWithUnitOfMeasure(ItemDescription, OldUOMDescription, UOMCode, false);
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(
            LibraryInvoicingApp.AddLineToInvoice(
              LibraryInvoicingApp.CreateInvoice, ItemDescription));

        // [WHEN] The user renames the unit of measure
        RenameUnitOfMeasureFromPage(UOMCode);

        // [THEN] The unit of measure in the posted document is not affected
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.SetRange("Unit of Measure", OldUOMDescription);
        SalesInvoiceLine.FindFirst;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEditUOMOpensRightUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        O365UnitOfMeasureCard: TestPage "O365 Unit Of Measure Card";
        O365UnitsofMeasureList: TestPage "O365 Units of Measure List";
        UOMCode: Code[10];
        UOMDescription: Text[10];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has multiple translated Units of Measure
        CreateUnitOfMeasure(GetRandText10);
        UOMDescription := GetRandText10;
        UOMCode := CreateUnitOfMeasure(UOMDescription);
        CreateUnitOfMeasure(GetRandText10);

        // [WHEN] The user tries to edit a unit of measure
        O365UnitsofMeasureList.OpenEdit;
        O365UnitsofMeasureList.GotoKey(UOMCode);
        O365UnitOfMeasureCard.Trap;
        O365UnitsofMeasureList.Edit.Invoke;

        // [THEN] The right unit of measure is opened in the page
        Assert.AreEqual(O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value, UOMDescription, '');

        // [WHEN] The user changes the description
        UOMDescription := GetRandText10;
        O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value := UOMDescription;
        O365UnitOfMeasureCard.Close;

        // [THEN] The right unit of measure translation is edited
        Assert.IsFalse(UnitOfMeasure.Get(UOMCode), 'Old UoM was not removed');
        Assert.IsTrue(UnitOfMeasure.Get(CopyStr(UOMDescription, 1, MaxStrLen(UnitOfMeasure.Code))), 'Could not find renamed UoM');
        Assert.AreEqual(UnitOfMeasure.GetDescriptionInCurrentLanguage, UOMDescription, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestRenameTranslatedUOMNotAffectingPostedLines()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        UnitOfMeasure: Record "Unit of Measure";
        PostedInvoiceNo: Code[20];
        OldTranslatedUOMDescription: Text[10];
        UOMCode: Code[10];
        ItemDescription: Text[50];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has a translated Unit of Measure used in one posted invoice
        CreateItemWithUnitOfMeasure(ItemDescription, OldTranslatedUOMDescription, UOMCode, false);
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(
            LibraryInvoicingApp.AddLineToInvoice(
              LibraryInvoicingApp.CreateInvoice, ItemDescription));

        // [WHEN] The user renames the unit of measure
        UnitOfMeasure.SetRange(Description, OldTranslatedUOMDescription);
        UnitOfMeasure.FindFirst;
        RenameUnitOfMeasureFromPage(UOMCode);

        // [THEN] The unit of measure in the posted document is not affected
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.SetRange("Unit of Measure", OldTranslatedUOMDescription);
        SalesInvoiceLine.FindFirst;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEditTranslatedUOMOpensRightUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        O365UnitOfMeasureCard: TestPage "O365 Unit Of Measure Card";
        O365UnitsofMeasureList: TestPage "O365 Units of Measure List";
        UOMCode: Code[10];
        UOMTranslation: Text[50];
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has multiple translated Units of Measure
        InsertUOMTranslationForCurrentLanguage(CreateUnitOfMeasure(GetRandText10), GetRandText10);
        UOMCode := CreateUnitOfMeasure(GetRandText10);
        UOMTranslation := InsertUOMTranslationForCurrentLanguage(UOMCode, GetRandText10);
        InsertUOMTranslationForCurrentLanguage(CreateUnitOfMeasure(GetRandText10), GetRandText10);

        // [WHEN] The user tries to edit a translated unit of measure
        O365UnitsofMeasureList.OpenEdit;
        O365UnitsofMeasureList.GotoKey(UOMCode);
        O365UnitOfMeasureCard.Trap;
        O365UnitsofMeasureList.Edit.Invoke;

        // [THEN] The right unit of measure is opened in the page
        Assert.AreEqual(O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value, UOMTranslation, '');

        // [WHEN] The user changes the description
        UOMTranslation := GetRandText10;
        O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value := UOMTranslation;
        O365UnitOfMeasureCard.Close;

        // [THEN] The right unit of measure translation is edited
        Assert.IsFalse(UnitOfMeasure.Get(UOMCode), 'Old UoM was not removed');
        Assert.IsTrue(UnitOfMeasure.Get(CopyStr(UOMTranslation, 1, MaxStrLen(UnitOfMeasure.Code))), 'Could not find renamed UoM');
        Assert.AreEqual(UnitOfMeasure.GetDescriptionInCurrentLanguage, UOMTranslation, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestNewUOMHasRightDescription()
    var
        UnitOfMeasure: Record "Unit of Measure";
        O365UnitOfMeasureCard: TestPage "O365 Unit Of Measure Card";
        UOMDescription: Text;
    begin
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An Invoicing user has already some (two) units of measure
        CreateUnitOfMeasure(GetRandText10);
        CreateUnitOfMeasure(GetRandText10);

        // [WHEN] The user creates a new unit of measure
        O365UnitOfMeasureCard.OpenNew;

        // [THEN] The card page is empty
        Assert.AreEqual(O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value, '', 'Description should be empty in new mode.');

        // [WHEN] The user changes the description and closes the page
        UOMDescription := GetRandText10;
        O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value := UOMDescription;
        O365UnitOfMeasureCard.Close;

        // [THEN] The unit of measure has the right description
        UnitOfMeasure.Get(CopyStr(UOMDescription, 1, MaxStrLen(UnitOfMeasure.Code)));
        Assert.AreEqual(UnitOfMeasure.GetDescriptionInCurrentLanguage, UOMDescription, 'Description should match the user input.');
    end;

    local procedure CheckLinesSubpageFieldsEditability(EnabledEditable: Boolean; BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        Assert.AreEqual(BCO365SalesInvoice.Lines.Description.Enabled and BCO365SalesInvoice.Lines.Description.Editable,
          true, 'Unexpected field editability.');

        Assert.AreEqual(BCO365SalesInvoice.Lines.LineQuantity.Enabled and BCO365SalesInvoice.Lines.LineQuantity.Editable,
          EnabledEditable, 'Unexpected field editability.');

        Assert.AreEqual(BCO365SalesInvoice.Lines."Line Amount".Enabled and BCO365SalesInvoice.Lines."Line Amount".Editable,
          EnabledEditable, 'Unexpected field editability.');

        Assert.AreEqual(BCO365SalesInvoice.Lines.UnitOfMeasure.Enabled and BCO365SalesInvoice.Lines.UnitOfMeasure.Editable,
          EnabledEditable, 'Unexpected field editability.');

        Assert.AreEqual(BCO365SalesInvoice.Lines."Line Discount %".Enabled and BCO365SalesInvoice.Lines."Line Discount %".Editable,
          EnabledEditable, 'Unexpected field editability.');

        Assert.AreEqual(BCO365SalesInvoice.Lines."Unit Price".Enabled and BCO365SalesInvoice.Lines."Unit Price".Editable,
          EnabledEditable, 'Unexpected field editability.');
    end;

    local procedure Init()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        TaxDetail: Record "Tax Detail";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        EventSubscriberInvoicingApp.Clear;
        O365SalesInitialSetup.Get();

        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        TaxDetail.ModifyAll("Tax Below Maximum", 5); // Avoid notification in US without mod file
        LibraryInvoicingApp.SetupEmail;

        WorkDate(Today);
        IsInitialized := true;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    local procedure CreateUnitOfMeasure(UOMDescription: Text[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, CopyStr(UOMDescription, 1, MaxStrLen(UnitOfMeasure.Code)));
        UnitOfMeasure.Validate(Description, UOMDescription);
        UnitOfMeasure.Insert(true);

        exit(UnitOfMeasure.Code);
    end;

    local procedure CreateItemWithUnitOfMeasure(var ItemDesc: Text; var UOMDesc: Text[10]; var UOMCode: Code[10]; InsertTranslation: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
    begin
        UOMDesc := GetRandText10;
        UOMCode := CreateUnitOfMeasure(UOMDesc);

        ItemDesc := LibraryInvoicingApp.CreateItem;
        Item.SetRange(Description, ItemDesc);
        Item.FindFirst;
        Item.Validate("Base Unit of Measure", UOMCode);
        Item.Modify(true);

        if InsertTranslation then
            InsertUOMTranslationForCurrentLanguage(UOMCode, GetRandText10);

        UnitOfMeasure.Get(UOMCode);
        UOMDesc := CopyStr(UnitOfMeasure.GetDescriptionInCurrentLanguage, 1, MaxStrLen(UOMDesc));
    end;

    local procedure RenameUnitOfMeasureFromPage(UnitOfMeasureCode: Code[10]) NewDescription: Text
    var
        O365UnitOfMeasureCard: TestPage "O365 Unit Of Measure Card";
    begin
        O365UnitOfMeasureCard.OpenEdit;
        O365UnitOfMeasureCard.GotoKey(UnitOfMeasureCode);
        NewDescription := GetRandText10;
        O365UnitOfMeasureCard.DescriptionInCurrentLanguage.Value := NewDescription;
        O365UnitOfMeasureCard.Close;
    end;

    local procedure InsertUOMTranslationForCurrentLanguage(UOMCode: Code[10]; TranslatedDescription: Text[50]): Text[50]
    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
    begin
        UnitOfMeasureTranslation.Code := UOMCode;
        UnitOfMeasureTranslation."Language Code" := Language.GetLanguageCode(GlobalLanguage);
        UnitOfMeasureTranslation.Description := TranslatedDescription;
        if UnitOfMeasureTranslation.Insert() then;

        exit(TranslatedDescription);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.SendToText.Value('test@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    local procedure GetRandText50(): Text[50]
    begin
        exit(CopyStr(LibraryRandom.RandText(50), 1, 50));
    end;

    local procedure GetRandText10(): Text[10]
    begin
        exit(CopyStr(LibraryRandom.RandText(10), 1, 10));
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

