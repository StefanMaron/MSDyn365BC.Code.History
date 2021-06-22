codeunit 138012 "O365 Templates Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Template]
    end;

    var
        ConfigTemplateHeader: Record "Config. Template Header";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        isInitialized: Boolean;
        NewActionTok: Label 'New';
        CancelActionTok: Label 'Cancel';
        EditActionTok: Label 'Edit';
        NoActionTok: Label 'NoAction';
        OKActionTok: Label 'OK';
        CouldNotFindDimensionWithCodeErr: Label 'Could not find Dimension Template Header with code %1.';
        GlobalTemplateName: Text[50];
        TemplateSelectionAction: Option SelectTemplate,VerifyDefaultSelection;
        WrongTemplatesCountErr: Label 'Wrong no. of configuration templates in the list';
        UnexpectedTemplateInListErr: Label 'Configuration template %1 should not be displayed in the list.';
        TemplateMustBeEnabledErr: Label 'New configuration template must be enabled';
        RelationErr: Label 'A template cannot relate to itself. Specify a different template.';
        DuplicateRelationErr: Label 'The template %1 is already in this hierarchy.';

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerTemplateFromBlankCustomer()
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemTemplateFromBlankItem()
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorTemplateFromBlankVendor()
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerTemplateFromCustomerWithAllTemplateFieldsSet()
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithTemplateFieldsSet(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemTemplateFromItemWithAllTemplateFieldsSet()
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorTemplateFromVendorWithAllTemplateFieldsSet()
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveCustomerWithDimensionsAsTemplate()
    var
        Customer: Record Customer;
        CustomerConfigTemplateHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithDimensions(Customer);
        CreateTemplateFromCustomer(Customer, CustomerConfigTemplateHeaderCode);

        ValidateCustomerVsConfigTemplate(Customer, CustomerConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Customer."No.", DATABASE::Customer, CustomerConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveItemWithDimensionsAsTemplate()
    var
        Item: Record Item;
        ItemConfigTemplateHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithDimensions(Item);
        CreateTemplateFromItem(Item, ItemConfigTemplateHeaderCode);

        ValidateItemVsConfigTemplate(Item, ItemConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Item."No.", DATABASE::Item, ItemConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveVendorWithDimensionsAsTemplate()
    var
        Vendor: Record Vendor;
        VendorConfigTemplateHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithDimensions(Vendor);
        CreateTemplateFromVendor(Vendor, VendorConfigTemplateHeaderCode);

        ValidateVendorVsConfigTemplate(Vendor, VendorConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Vendor."No.", DATABASE::Vendor, VendorConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ReadCustomerTemplateFromConfigTemplateHeader()
    var
        Customer: Record Customer;
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithTemplateFieldsSet(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        ReadCustTemplFromConfigTempl(ConfigTemplHeaderCode, TempMiniCustomerTemplate);

        ValidateCustTemplVsConfigTemplate(TempMiniCustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ReadItemTemplateFromConfigTemplateHeader()
    var
        Item: Record Item;
        TempItemTemplate: Record "Item Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        ReadItemTemplFromConfigTempl(ConfigTemplHeaderCode, TempItemTemplate);

        ValidateItemTemplVsConfigTemplate(TempItemTemplate);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ReadVendorTemplateFromConfigTemplateHeader()
    var
        Vendor: Record Vendor;
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        ReadVendTemplFromConfigTempl(ConfigTemplHeaderCode, TempMiniVendorTemplate);

        ValidateVendTemplVsConfigTemplate(TempMiniVendorTemplate);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerTemplateTest()
    var
        Customer: Record Customer;
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        UpdateCustomerTemplate(ConfigTemplHeaderCode, TempMiniCustomerTemplate);
        ValidateCustTemplVsConfigTemplate(TempMiniCustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure UpdateItemTemplateTest()
    var
        Item: Record Item;
        TempItemTemplate: Record "Item Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        UpdateItemTemplate(ConfigTemplHeaderCode, TempItemTemplate);

        ValidateItemTemplVsConfigTemplate(TempItemTemplate);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure UpdateVendorTemplateTest()
    var
        Vendor: Record Vendor;
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        UpdateVendorTemplate(ConfigTemplHeaderCode, TempMiniVendorTemplate);
        ValidateVendTemplVsConfigTemplate(TempMiniVendorTemplate);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure DeleteCustomerTemplateTest()
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithTemplateFieldsSet(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        DeleteCustTemplateFromConfigTempl(ConfigTemplHeaderCode);

        ValidateThereIsNoTemplate(ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure DeleteItemTemplateTest()
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        DeleteItemTemplateFromConfigTempl(ConfigTemplHeaderCode);

        ValidateThereIsNoTemplate(ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure DeleteVendorTemplateTest()
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        DeleteVendTemplateFromConfigTempl(ConfigTemplHeaderCode);

        ValidateThereIsNoTemplate(ConfigTemplHeaderCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateFieldDefinitionsMatchCustomerFields()
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        RecRefCust: RecordRef;
        RecRefMiniCustTempl: RecordRef;
        FieldRefArray: array[23] of FieldRef;
    begin
        // [FEATURE] [Customer]
        Initialize;

        RecRefCust.Open(DATABASE::Customer);
        TempMiniCustomerTemplate.Init();
        RecRefMiniCustTempl.GetTable(TempMiniCustomerTemplate);

        TempMiniCustomerTemplate.CreateFieldRefArray(FieldRefArray, RecRefMiniCustTempl);
        TemplateFieldDefinitionsMatchTableFields(RecRefCust, FieldRefArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateFieldDefinitionsMatchVendorFields()
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        RecRefVend: RecordRef;
        RecRefVendTempl: RecordRef;
        FieldRefArray: array[17] of FieldRef;
    begin
        // [FEATURE] [Vendor]
        Initialize;

        RecRefVend.Open(DATABASE::Vendor);
        TempMiniVendorTemplate.Init();
        RecRefVendTempl.GetTable(TempMiniVendorTemplate);

        TempMiniVendorTemplate.CreateFieldRefArray(FieldRefArray, RecRefVendTempl);
        TemplateFieldDefinitionsMatchTableFields(RecRefVend, FieldRefArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateFieldDefinitionsMatchItemFields()
    var
        TempItemTemplate: Record "Item Template" temporary;
        RecRefItem: RecordRef;
        RecRefItemTempl: RecordRef;
        FieldRefArray: array[17] of FieldRef;
    begin
        // [FEATURE] [Item]
        Initialize;

        RecRefItem.Open(DATABASE::Item);
        TempItemTemplate.Init();
        RecRefItemTempl.GetTable(TempItemTemplate);

        TempItemTemplate.CreateFieldRefArray(FieldRefArray, RecRefItemTempl);
        TemplateFieldDefinitionsMatchTableFields(RecRefItem, FieldRefArray);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerTemplateFromConfigTemplateList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        CustomerList.OpenNew;
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewVendorTemplateFromConfigTemplateList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        VendorList.OpenNew;
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewItemTemplateFromConfigTemplateList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        LibrarySmallBusiness.CreateItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        ItemList.OpenNew;
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditCustomerTemplateInConfigTemplateList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        CustomerList.OpenNew;
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditVendorTemplateInConfigTemplateList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        VendorList.OpenNew;
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditItemTemplateInConfigTemplateList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        LibrarySmallBusiness.CreateItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        ItemList.OpenNew;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateCity()
    var
        PostCodeRec: Record "Post Code";
        NoreturnCity: Code[10];
        ExpectedPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        NoreturnCity := 'Noreturn';

        PostCodeRec.SetFilter(City, NoreturnCity);
        PostCodeRec.DeleteAll();
        ExpectedPostCode := '';
        ExpectedRegionCode := '';
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := '';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplatePostCode()
    var
        PostCodeRec: Record "Post Code";
        ExpectedCity: Code[10];
        NoreturnPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        NoreturnPostCode := 'Noreturn';

        PostCodeRec.SetFilter(Code, NoreturnPostCode);
        PostCodeRec.DeleteAll();
        ExpectedCity := '';
        ExpectedRegionCode := '';
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := '';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateCity()
    var
        PostCodeRec: Record "Post Code";
        NoreturnCity: Code[10];
        ExpectedPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        NoreturnCity := 'Noreturn';

        PostCodeRec.SetFilter(City, NoreturnCity);
        PostCodeRec.DeleteAll();
        ExpectedPostCode := '';
        ExpectedRegionCode := '';
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := '';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplatePostCode()
    var
        PostCodeRec: Record "Post Code";
        ExpectedCity: Code[10];
        NoreturnPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        NoreturnPostCode := 'Noreturn';

        PostCodeRec.SetFilter(Code, NoreturnPostCode);
        PostCodeRec.DeleteAll();
        ExpectedCity := '';
        ExpectedRegionCode := '';
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := '';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomeWhenNoTemplatesDefined()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer]
        Initialize;

        CustomerCard.OpenNew;

        Assert.AreEqual(CustomerCard.Name.Value, '', 'Blank customer should be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorWhenNoTemplatesDefined()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor]
        Initialize;

        VendorCard.OpenNew;

        Assert.AreEqual(VendorCard.Name.Value, '', 'Blank vendor should be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateItemWhenNoTemplatesDefined()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item]
        Initialize;

        ItemCard.OpenNew;

        Assert.AreEqual(ItemCard.Description.Value, '', 'Blank Item should be opened');
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerWhenOneTemplateDefined()
    var
        CustomerFromTemplate: Record Customer;
        CustomerWithTemplateFieldsSet: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Variant;
        CustomerTemplateCode: Code[10];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Customer]
        Initialize;

        // [GIVEN] One Customer template with field set, blank No. Series, no dimensions
        CreateCustomerWithTemplateFieldsSet(CustomerWithTemplateFieldsSet);
        CreateTemplateFromCustomer(CustomerWithTemplateFieldsSet, CustomerTemplateCode);
        GetDefaultCustomerNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Customer from the template
        CustomerCard.OpenNew;

        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.Close;

        // [THEN] Fields in new customer matches template's fields, no dimensions assigned
        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);

        // [THEN] Customer is created with No. and "No. Series" from Sales&Receivables Setup (TFS 229503)
        VerifyCustomerNoWithSeries(CustomerNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorWhenOneTemplateDefined()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Variant;
        VendorTemplateCode: Code[10];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        // [GIVEN] One Vendor template with field set, blank No. Series, no dimensions
        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);
        GetDefaultVendorNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Vendor from the template
        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test');

        VendorNo := VendorCard."No.".Value;
        VendorCard.Close;

        // [THEN] Fields in new vendor matches template's fields, no dimensions assigned
        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);

        // [THEN] Vendor is created with No. and "No. Series" from Purchase&Payables Setup (TFS 229503)
        VerifyVendorNoWithSeries(VendorNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemWhenOneTemplateDefined()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        ItemCard: TestPage "Item Card";
        ItemNo: Variant;
        ItemTemplateCode: Code[10];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Item]
        Initialize;

        // [GIVEN] One Item template with field set, blank No. Series, no dimensions
        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);
        GetDefaultItemNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Item from the template
        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value;
        ItemCard.Close;

        // [THEN] Fields in new item matches template's fields, no dimensions assigned
        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);

        // [THEN] Item is created with No. and "No. Series" from Inventory Setup (TFS 229503)
        VerifyItemNoWithSeries(ItemNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromTemplateWhenMultipleTemplatesDefined()
    var
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: Code[10];
        BlankCustomerTemplateCode: Code[10];
        CustomerNo: Text;
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomerTemplateFromCustomer(CustomerTemplateCode, BlankCustomerTemplateCode);

        LibraryVariableStorage.Enqueue(CustomerTemplateCode);

        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.Close;

        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('CustomerConfigTemplatesHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorFromTemplateWhenMultipleTemplatesDefined()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        BlankVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: Code[10];
        BlankVendorTemplateCode: Code[10];
        VendorNo: Text;
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);

        CreateBlankVendor(BlankVendor);
        CreateTemplateFromVendor(BlankVendor, BlankVendorTemplateCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        VendorCard.OpenNew;

        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value;
        VendorCard.Close;

        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('ItemConfigTemplatesHandler,ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromTemplateWhenMultipleTemplatesDefined()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        BlankItem: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: Code[10];
        BlankItemTemplateCode: Code[10];
        ItemNo: Text;
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);

        CreateBlankItem(BlankItem);
        CreateTemplateFromItem(BlankItem, BlankItemTemplateCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test');

        ItemNo := ItemCard."No.".Value;
        ItemCard.Close;

        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomerFromTemplateVerifyContacts()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Contact: Record Contact;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Code[20];
        ContactsCount: Integer;
    begin
        // [FEATURE] [Customer] [Contact]
        // [SCENARIO] One related Contact is created when create Customer from template
        Initialize;

        // [GIVEN] Customer Template
        UpdateMarketingSetup;
        LibrarySmallBusiness.CreateCustomerTemplate(ConfigTemplateHeader);
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        ContactsCount := Contact.Count();

        // [WHEN] Create Customer from Template
        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.Close;

        // [THEN] One Contact created for Customer
        VerifyOneCustomerContactDoesExist(CustomerNo, ContactsCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorFromTemplateVerifyContacts()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Contact: Record Contact;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Code[20];
        ContactsCount: Integer;
    begin
        // [FEATURE] [Vendor] [Contact]
        // [SCENARIO] One related Contact is created when create Vendor from template
        Initialize;

        // [GIVEN] Vendor Template
        UpdateMarketingSetup;
        LibrarySmallBusiness.CreateVendorTemplate(ConfigTemplateHeader);
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        ContactsCount := Contact.Count();

        // [WHEN] Create Vendor from Template
        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value;
        VendorCard.Close;

        // [THEN] One Contact created for Vendor
        VerifyOneVendorContactDoesExist(VendorNo, ContactsCount);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,ConfigTemplatesSelectionHandler')]
    [Scope('OnPrem')]
    procedure ValidateThatTheLastSelectionIsSavedForCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: array[10] of Code[10];
        TotalNoOfTemplates: Integer;
        SelectedTemplateIndex: Integer;
        LoopIndex: Integer;
    begin
        // [FEATURE] [Customer]
        Initialize;

        TotalNoOfTemplates := LibraryRandom.RandIntInRange(3, 10);
        SelectedTemplateIndex := LibraryRandom.RandIntInRange(3, TotalNoOfTemplates);
        CreateBlankCustomer(Customer);

        for LoopIndex := 1 to TotalNoOfTemplates do
            CreateTemplateFromCustomer(Customer, CustomerTemplateCode[LoopIndex]);

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::SelectTemplate));
        LibraryVariableStorage.Enqueue(CustomerTemplateCode[SelectedTemplateIndex]);

        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test1');
        CustomerCard.Close;

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::VerifyDefaultSelection));
        LibraryVariableStorage.Enqueue(CustomerTemplateCode[SelectedTemplateIndex]);

        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test2');
        CustomerCard.Close;
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler,ConfigTemplatesSelectionHandler')]
    [Scope('OnPrem')]
    procedure ValidateThatTheLastSelectionIsSavedForVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: array[10] of Code[10];
        TotalNoOfTemplates: Integer;
        SelectedTemplateIndex: Integer;
        LoopIndex: Integer;
    begin
        // [FEATURE] [Vendor]
        Initialize;

        TotalNoOfTemplates := LibraryRandom.RandIntInRange(3, 10);
        SelectedTemplateIndex := LibraryRandom.RandIntInRange(3, TotalNoOfTemplates);
        CreateBlankVendor(Vendor);

        for LoopIndex := 1 to TotalNoOfTemplates do
            CreateTemplateFromVendor(Vendor, VendorTemplateCode[LoopIndex]);

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::SelectTemplate));
        LibraryVariableStorage.Enqueue(VendorTemplateCode[SelectedTemplateIndex]);

        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test1');
        VendorCard.Close;

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::VerifyDefaultSelection));
        LibraryVariableStorage.Enqueue(VendorTemplateCode[SelectedTemplateIndex]);
        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test2');
        VendorCard.Close;
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler,ConfigTemplatesSelectionHandler')]
    [Scope('OnPrem')]
    procedure ValidateThatTheLastSelectionIsSavedForItem()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: array[10] of Code[10];
        TotalNoOfTemplates: Integer;
        SelectedTemplateIndex: Integer;
        LoopIndex: Integer;
    begin
        // [FEATURE] [Item]
        Initialize;

        TotalNoOfTemplates := LibraryRandom.RandIntInRange(3, 10);
        SelectedTemplateIndex := LibraryRandom.RandIntInRange(3, TotalNoOfTemplates);
        CreateBlankItem(Item);

        for LoopIndex := 1 to TotalNoOfTemplates do
            CreateTemplateFromItem(Item, ItemTemplateCode[LoopIndex]);

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::SelectTemplate));
        LibraryVariableStorage.Enqueue(ItemTemplateCode[SelectedTemplateIndex]);

        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test1');
        ItemCard.Close;

        LibraryVariableStorage.Enqueue(Format(TemplateSelectionAction::VerifyDefaultSelection));
        LibraryVariableStorage.Enqueue(ItemTemplateCode[SelectedTemplateIndex]);
        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test2');
        ItemCard.Close;
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerTemplateToCustomer()
    var
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: Code[10];
        BlankCustomerTemplateCode: Code[10];
        CustomerNo: Text;
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomerTemplateFromCustomer(CustomerTemplateCode, BlankCustomerTemplateCode);

        LibraryVariableStorage.Enqueue(BlankCustomerTemplateCode);

        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        CustomerCard.ApplyTemplate.Invoke;
        CustomerCard.Close;

        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorTemplateToVendor()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        BlankVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: Code[10];
        BlankVendorTemplateCode: Code[10];
        VendorNo: Text;
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);

        CreateBlankVendor(BlankVendor);
        CreateTemplateFromVendor(BlankVendor, BlankVendorTemplateCode);

        LibraryVariableStorage.Enqueue(BlankVendorTemplateCode);

        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value;
        LibraryVariableStorage.Enqueue(VendorTemplateCode);
        VendorCard.ApplyTemplate.Invoke;
        VendorCard.Close;

        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyItemTemplateToItem()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        BlankItem: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: Code[10];
        BlankItemTemplateCode: Code[10];
        ItemNo: Text;
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);

        CreateBlankItem(BlankItem);
        CreateTemplateFromItem(BlankItem, BlankItemTemplateCode);

        LibraryVariableStorage.Enqueue(BlankItemTemplateCode);

        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value;
        LibraryVariableStorage.Enqueue(ItemTemplateCode);
        ItemCard.ApplyTemplate.Invoke;
        ItemCard.Close;

        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerTemplateWithDimToCustomer()
    var
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Customer][Default Dimension]
        // [SCENARIO 209195] Customer should have default dimensions from Customer Template after applying the template when "Customer Nos." is not default
        Initialize;

        // [GIVEN] Customer Template with default dimensions
        CustomerTemplateCode := CreateCustTemplateWithDimFromCustomer;
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);

        // [GIVEN] Sales & Receivables Setup Customer "No. Series" is not default
        UpdateSalesReceivablesSetupCustNoSeries;

        // [WHEN] Applying the template
        CustomerCard.OpenNew;
        CustomerCard."No.".SetValue(LibraryUtility.GenerateRandomCode(CustomerFromTemplate.FieldNo("No."), DATABASE::Customer));
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        CustomerCard.ApplyTemplate.Invoke;
        CustomerCard.Close;

        // [THEN] Customer has default dimensions from template
        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplate(CustomerFromTemplate, CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorTemplateWithDimToVendor()
    var
        VendorFromTemplate: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Vendor][Default Dimension]
        // [SCENARIO 209195] Vendor should have default dimensions from Vendor Template after applying the template when "Vendor Nos." is not default
        Initialize;

        // [GIVEN] Vendor Template with default dimensions
        VendorTemplateCode := CreateVendTemplateWithDimFromVendor;
        LibraryVariableStorage.Enqueue(VendorTemplateCode);

        // [GIVEN] Purchases & Payables Setup Vendor "No. Series" is not default
        UpdatePurchasesPayablesSetupVendNoSeries;

        // [WHEN] Applying the template
        VendorCard.OpenNew;
        VendorCard."No.".SetValue(LibraryUtility.GenerateRandomCode(VendorFromTemplate.FieldNo("No."), DATABASE::Vendor));
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value;
        LibraryVariableStorage.Enqueue(VendorTemplateCode);
        VendorCard.ApplyTemplate.Invoke;
        VendorCard.Close;

        // [THEN] Vendor has default dimensions from template
        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplate(VendorFromTemplate, VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyItemTemplateWithDimToItem()
    var
        ItemFromTemplate: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item][Default Dimension]
        // [SCENARIO 209195] Item should have default dimensions from Item Template after applying the template when "Item Nos." is not default
        Initialize;

        // [GIVEN] Vendor Template with default dimensions
        ItemTemplateCode := CreateItemTemplateWithDimFromItem;
        LibraryVariableStorage.Enqueue(ItemTemplateCode);

        // [GIVEN] Inventory Setup with Item "No. Series" is not default
        UpdateInventorySetupItemNoSeries;

        // [WHEN] Applying the template
        ItemCard.OpenNew;
        ItemCard."No.".SetValue(LibraryUtility.GenerateRandomCode(ItemFromTemplate.FieldNo("No."), DATABASE::Item));
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value;
        LibraryVariableStorage.Enqueue(ItemTemplateCode);
        ItemCard.ApplyTemplate.Invoke;
        ItemCard.Close;

        // [THEN] Item has default dimensions from template
        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplate(ItemFromTemplate, ItemTemplateCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerTemplateCreatesConfigTemplate()
    var
        CustomerFromTemplate: Record Customer;
        CustomerWithTemplateFieldsSet: Record Customer;
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerTemplateCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithTemplateFieldsSet(CustomerWithTemplateFieldsSet);
        CreateTemplateFromCustomer(CustomerWithTemplateFieldsSet, CustomerTemplateCode);
        ConfigTemplateHeader.Get(CustomerTemplateCode);
        TempMiniCustomerTemplate.InitializeTempRecordFromConfigTemplate(TempMiniCustomerTemplate, ConfigTemplateHeader);
        TempMiniCustomerTemplate.Delete(true);

        TempMiniCustomerTemplate.Insert(true);
        TempMiniCustomerTemplate.NewCustomerFromTemplate(CustomerFromTemplate);

        CustomerFromTemplate.Get(CustomerFromTemplate."No.");
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure NewVendorTemplateCreatesConfigTemplate()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        ConfigTemplateHeader: Record "Config. Template Header";
        VendorTemplateCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);
        ConfigTemplateHeader.Get(VendorTemplateCode);
        TempMiniVendorTemplate.InitializeTempRecordFromConfigTemplate(TempMiniVendorTemplate, ConfigTemplateHeader);
        TempMiniVendorTemplate.Delete(true);

        TempMiniVendorTemplate.Insert(true);
        TempMiniVendorTemplate.NewVendorFromTemplate(VendorFromTemplate);

        VendorFromTemplate.Get(VendorFromTemplate."No.");
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure NewItemTemplateCreatesConfigTemplate()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        TempItemTemplate: Record "Item Template" temporary;
        ConfigTemplateHeader: Record "Config. Template Header";
        ItemTemplateCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);
        ConfigTemplateHeader.Get(ItemTemplateCode);
        TempItemTemplate.InitializeTempRecordFromConfigTemplate(TempItemTemplate, ConfigTemplateHeader);
        TempItemTemplate.Delete(true);

        TempItemTemplate.Insert(true);
        TempItemTemplate.NewItemFromTemplate(ItemFromTemplate);

        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerWithDimensionsFromTemplate()
    var
        Customer: Record Customer;
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerConfigTemplateHeaderCode: Code[10];
        CustomerNo: Text;
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateCustomerWithDimensions(Customer);
        CreateTemplateFromCustomer(Customer, CustomerConfigTemplateHeaderCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.Close;

        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplate(CustomerFromTemplate, CustomerConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorWithDimensionsFromTemplate()
    var
        Vendor: Record Vendor;
        VendorFromTemplate: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorConfigTemplateHeaderCode: Code[10];
        VendorNo: Text;
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateVendorWithDimensions(Vendor);
        CreateTemplateFromVendor(Vendor, VendorConfigTemplateHeaderCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        VendorCard.OpenNew;
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value;
        VendorCard.Close;

        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplate(VendorFromTemplate, VendorConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemWithDimensionsFromTemplate()
    var
        Item: Record Item;
        ItemFromTemplate: Record Item;
        ItemCard: TestPage "Item Card";
        ItemConfigTemplateHeaderCode: Code[10];
        ItemNo: Text;
    begin
        // [FEATURE] [Item] [Dimension]
        Initialize;

        CreateItemWithDimensions(Item);
        CreateTemplateFromItem(Item, ItemConfigTemplateHeaderCode);

        ItemCard.Trap;

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        ItemCard.OpenNew;
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value;
        ItemCard.Close;

        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplate(ItemFromTemplate, ItemConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure DimensionsCRUDTest()
    var
        Dimension1: Record Dimension;
        Dimension2: Record Dimension;
        Dimension3: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        TempDimensionsTemplate: Record "Dimensions Template" temporary;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
        DimensionsTemplateList: TestPage "Dimensions Template List";
        DimensionsTemplateListUpdate: TestPage "Dimensions Template List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Dimension]
        Initialize;

        CreateDimension(Dimension1);
        CreateDimension(Dimension2);
        CreateDimension(Dimension3);

        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        ConfigTemplates.OpenView;
        ItemTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // Test create
        DimensionsTemplateList.Trap;
        ItemTemplateCard."Default Dimensions".Invoke;

        DimensionsTemplateList.New;
        DimensionsTemplateList."Dimension Code".SetValue(Dimension1.Code);

        DimensionValue.SetRange("Dimension Code", Dimension1.Code);
        DimensionValue.FindFirst;
        DimensionsTemplateList."Dimension Value Code".SetValue(DimensionValue.Code);
        DimensionsTemplateList."<Dimension Value Code>".SetValue(DefaultDimension."Value Posting"::"Code Mandatory");

        DimensionsTemplateList.New;
        DimensionsTemplateList."Dimension Code".SetValue(Dimension2.Code);
        DimensionsTemplateList.OK.Invoke;

        VerifyDefaultDimensionsTemplateSavedCorrectly(
          ConfigTemplHeaderCode, Dimension1.Code, DimensionValue.Code, DefaultDimension."Value Posting"::"Code Mandatory");
        VerifyDefaultDimensionsTemplateSavedCorrectly(ConfigTemplHeaderCode, Dimension2.Code, '', DefaultDimension."Value Posting"::" ");

        // Test update
        DimensionsTemplateListUpdate.Trap;
        ItemTemplateCard."Default Dimensions".Invoke;
        DimensionsTemplateListUpdate.First;
        DimensionsTemplateListUpdate."Dimension Code".SetValue(Dimension3.Code);
        DimensionsTemplateListUpdate.Next;
        DimensionValue.SetRange("Dimension Code", Dimension2.Code);
        DimensionValue.FindFirst;
        DimensionsTemplateListUpdate."Dimension Value Code".SetValue(DimensionValue.Code);
        DimensionsTemplateListUpdate."<Dimension Value Code>".SetValue(DefaultDimension."Value Posting"::"Code Mandatory");
        DimensionsTemplateListUpdate.OK.Invoke;

        VerifyDefaultDimensionsTemplateSavedCorrectly(ConfigTemplHeaderCode, Dimension3.Code, '', DefaultDimension."Value Posting"::" ");
        VerifyDefaultDimensionsTemplateSavedCorrectly(
          ConfigTemplHeaderCode, Dimension2.Code, DimensionValue.Code, DefaultDimension."Value Posting"::"Code Mandatory");
        ItemTemplateCard.OK.Invoke;

        // Test delete
        // Page Testability can't invoke Delete test on table level
        ConfigTemplateHeader.Get(GetDimensionsTemplateCode(ConfigTemplHeaderCode, Dimension2.Code));
        TempDimensionsTemplate.InitializeTempRecordFromConfigTemplate(
          TempDimensionsTemplate, ConfigTemplateHeader, ConfigTemplHeaderCode, DATABASE::Item);
        TempDimensionsTemplate.Delete(true);

        VerifyNumberOfDimensionsTemplateRelatedToMasterTemplate(ConfigTemplHeaderCode, 1);

        ConfigTemplateHeader.Get(GetDimensionsTemplateCode(ConfigTemplHeaderCode, Dimension3.Code));
        TempDimensionsTemplate.InitializeTempRecordFromConfigTemplate(
          TempDimensionsTemplate, ConfigTemplateHeader, ConfigTemplHeaderCode, DATABASE::Item);
        TempDimensionsTemplate.Delete(true);

        Clear(ConfigTemplateHeader);
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::"Default Dimension");
        Assert.IsFalse(ConfigTemplateHeader.FindFirst, 'There should be no Dimensions template in the database');

        VerifyNumberOfDimensionsTemplateRelatedToMasterTemplate(ConfigTemplHeaderCode, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewGeneralTemplateInConfigTemplateList()
    var
        ConfigTemplates: TestPage "Config Templates";
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
    begin
        Initialize;

        ConfigTemplates.OpenView;
        ConfigTemplateHeaderPage.Trap;
        ConfigTemplates.NewConfigTemplate.Invoke;
        Assert.IsTrue(ConfigTemplateHeaderPage.Code.Editable, 'Template page opened in read-only mode.');
        Assert.AreEqual('', ConfigTemplateHeaderPage.Code.Value, 'Template not opened in new mode.');
        ConfigTemplateHeaderPage.Close;
        ConfigTemplates.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditGeneralTemplateInConfigTemplateList()
    var
        DefaultDimension: Record "Default Dimension";
        ConfigTemplates: TestPage "Config Templates";
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
    begin
        // [FEATURE] [Dimension]
        Initialize;

        CreateDefaultDimension(DefaultDimension);
        CreateTemplateFromDimension(DefaultDimension);

        ConfigTemplates.OpenView;
        ConfigTemplateHeaderPage.Trap;
        ConfigTemplates."Edit Template".Invoke;

        Assert.IsTrue(ConfigTemplateHeaderPage.Code.Editable, 'Template page opened in read-only mode.');
        Assert.AreEqual(DefaultDimension."No.", ConfigTemplateHeaderPage.Code.Value, 'Wrong template opened.');

        ConfigTemplateHeaderPage.Close;
        ConfigTemplates.Close;
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure RenameTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        NewTemplateCode: Code[10];
        TemplateCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, TemplateCode);

        NewTemplateCode := LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        UpdateCodeOnConfigTempate(TemplateCode, NewTemplateCode);

        ValidateThereIsNoTemplate(TemplateCode);
        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, NewTemplateCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateTemplateInDifferentLanguageCode()
    var
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        TemplateName: Code[10];
        OtherLanguageID: Integer;
        OriginalLanguageID: Integer;
    begin
        // [FEATURE] [Language]
        Initialize;

        OriginalLanguageID := GlobalLanguage;
        OtherLanguageID := GetDifferentLanguageID;
        CreateTemplateInLanguage(TemplateName, Item, OtherLanguageID);
        Assert.AreNotEqual(OriginalLanguageID, OtherLanguageID, 'Language ID should be reverted to original languageID');

        ConfigTemplateLine.SetRange("Data Template Code", TemplateName);
        ConfigTemplateLine.FindSet;

        repeat
            Assert.AreEqual(OtherLanguageID, ConfigTemplateLine."Language ID", 'Wrong Language ID was set on configuration template line');
        until ConfigTemplateLine.Next = 0;

        CreateItemFromTemplateAndCompareWithOriginal(Item);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyTemplateWithoutLanguageCode()
    var
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        TemplateName: Code[10];
    begin
        // [FEATURE] [Language]
        Initialize;
        CreateTemplateInLanguage(TemplateName, Item, GlobalLanguage);

        ConfigTemplateLine.SetRange("Data Template Code", TemplateName);
        ConfigTemplateLine.ModifyAll("Language ID", 0);

        CreateItemFromTemplateAndCompareWithOriginal(Item);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ModifyTemplateLineToAnotherLanguageCode()
    var
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        TemplateName: Code[10];
        OtherLanguageID: Integer;
        OriginalLanguageID: Integer;
    begin
        // [FEATURE] [Language]
        Initialize;

        OriginalLanguageID := GlobalLanguage;
        OtherLanguageID := GetDifferentLanguageID;
        CreateTemplateInLanguage(TemplateName, Item, OtherLanguageID);
        Assert.AreNotEqual(OriginalLanguageID, OtherLanguageID, 'Language ID should be reverted to original languageID');

        GlobalLanguage(OtherLanguageID);

        ConfigTemplateLine.SetRange("Data Template Code", TemplateName);
        ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Allow Invoice Disc."));
        ConfigTemplateLine.FindFirst;
        ConfigTemplateLine.Validate("Default Value", Format(false));
        ConfigTemplateLine.Modify(true);

        Assert.AreEqual(GlobalLanguage, ConfigTemplateLine."Language ID", 'Language ID was not updated');

        GlobalLanguage(OriginalLanguageID);

        CreateItemFromTemplateAndCompareWithOriginal(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewOpensItemTemplateCardInItemContext()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
    begin
        // [FEATURE] [Item]
        Initialize;

        CreateBlankItem(Item);
        ItemCard.OpenEdit;
        ItemCard.GotoRecord(Item);

        ConfigTemplates.Trap;
        ItemCard.Templates.Invoke;

        ItemTemplateCard.Trap;
        ConfigTemplates.NewItemTemplate.Invoke;

        ItemTemplateCard."Template Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewOpensCustomerTemplateCardInCustomerContext()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ConfigTemplates: TestPage "Config Templates";
        CustTemplateCard: TestPage "Cust. Template Card";
    begin
        // [FEATURE] [Customer]
        Initialize;

        CreateBlankCustomer(Customer);
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        ConfigTemplates.Trap;
        CustomerCard.Templates.Invoke;

        CustTemplateCard.Trap;
        ConfigTemplates.NewCustomerTemplate.Invoke;

        CustTemplateCard."Template Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewOpensVendorTemplateCardInVendorContext()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ConfigTemplates: TestPage "Config Templates";
        VendorTemplateCard: TestPage "Vendor Template Card";
    begin
        // [FEATURE] [Vendor]
        Initialize;

        CreateBlankVendor(Vendor);
        VendorCard.OpenEdit;
        VendorCard.GotoRecord(Vendor);

        ConfigTemplates.Trap;
        VendorCard.Templates.Invoke;

        VendorTemplateCard.Trap;
        ConfigTemplates.NewVendorTemplate.Invoke;
        VendorTemplateCard."Template Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewConfigTemplateIsEnabledByDefault()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [SCENARIO 159448] When a new config. template is created in UI it is enabled by default

        Initialize;

        // [GIVEN] Create new configuration template
        ConfigTemplateHeader.Init();

        // [THEN] New template is created with "Enabled" = TRUE
        Assert.IsTrue(ConfigTemplateHeader.Enabled, TemplateMustBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateEnabledFieldSynchronizedWithConfigTemplateHeader()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 159448] Field "Enabled" in item template card should be synchronized with configuration template

        // [GIVEN] Create new item template
        Initialize;

        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        // [WHEN] Open item template card from configuration templates list
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        ItemTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // [THEN] "Enabled" = TRUE in template card
        ItemTemplateCard.TemplateEnabled.AssertEquals(true);

        // [WHEN] Set "Enabled" = FALSE in template card
        ItemTemplateCard.TemplateEnabled.SetValue(false);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = FALSE
        ConfigTemplateHeader.TestField(Enabled, false);

        // [WHEN] Set "Enabled" = TRUE in template card
        ItemTemplateCard.TemplateEnabled.SetValue(true);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = TRUE
        ConfigTemplateHeader.TestField(Enabled, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateFieldsSynchronizedWithConfigTemplateLine()
    var
        ItemCategory: Record "Item Category";
        ServiceItemGroup: Record "Service Item Group";
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
        ServiceItemGroupCode: Code[10];
    begin
        // [FEATURE] [Item]
        // [SCENARIO 382249] Item Category Code and Service Item Group code should be saved in Configuration Templates for Item table after they have been updated on Item Template page.
        Initialize;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] Item template "T".
        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        // [GIVEN] Open item template card from configuration templates list.
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        ItemTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // [GIVEN] Item Category field is updated on the item template card. New value = "IC".
        LibraryInventory.CreateItemCategory(ItemCategory);
        ItemTemplateCard."Item Category Code".SetValue(ItemCategory.Code);

        // [GIVEN] Service Item Group field is updated on the item template card. New value = "SIG".
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode := ServiceItemGroup.Code;
        ItemTemplateCard."Service Item Group".SetValue(ServiceItemGroupCode);
        LibraryLowerPermissions.SetO365Full;

        // [WHEN] Close the item template card.
        ItemTemplateCard.OK.Invoke;

        // [THEN] New configuration template line for "T" is created, "Field No." = Item Category Code, "Default Value" = "IC".
        VerifyConfigTemplateLine(
          ConfigTemplateHeader.Code, DATABASE::Item, Item.FieldNo("Item Category Code"), ItemCategory.Code);

        // [THEN] New configuration template line for "T" is created, "Field No." = Service Item Group, "Default Value" = "SIG".
        VerifyConfigTemplateLine(
          ConfigTemplateHeader.Code, DATABASE::Item, Item.FieldNo("Service Item Group"), ServiceItemGroupCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewItemFromTemplateWithTwoEnabledTemplates()
    var
        ItemTemplate: Record "Item Template";
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [SCENARIO 159448] Item template should be selected from a list when creating a new item with two item templates enabled
        Initialize;

        // [GIVEN] Create two enabled item templates "T1" and "T2"
        CreateConfigTemplateFromItemWithEnabledOption(true);
        CreateConfigTemplateFromItemWithEnabledOption(true);
        // [GIVEN] Create one disabled template "T3"
        CreateConfigTemplateFromItemWithEnabledOption(false);

        // [WHEN] Create new item from template
        EnqueueEnabledTemplates;
        ItemTemplate.NewItemFromTemplate(Item);

        // [THEN] List of item templates with two elements "T1" and "T2" is presented
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewItemFromTemplateWithOneEnabledTemplate()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Template";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        // [SCENARIO 159448] New item should be created according to template without user confirmation if there is only one enabled item template
        Initialize;

        // [GIVEN] Create disabled item template "T1"
        CreateConfigTemplateFromItemWithEnabledOption(false);
        // [GIVEN] Create enabled item template "T2"
        ConfigTemplHeaderCode := CreateConfigTemplateFromItemWithEnabledOption(true);

        // [WHEN] Create new item from template
        ItemTemplate.NewItemFromTemplate(Item);

        // [THEN] New item is created from template "T2"
        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewItemFromTemplateNoEnabledTemplates()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Template";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 159448] Blank item is created when all item templates are disabled
        Initialize;

        // [GIVEN] Create two disabled item templates
        CreateConfigTemplateFromItemWithEnabledOption(false);
        CreateConfigTemplateFromItemWithEnabledOption(false);

        // [WHEN] Create new item from template
        ItemTemplate.NewItemFromTemplate(Item);

        // [THEN] Blank item is created
        ValidateItemVsBlankTemplate(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateValidateTableRelations()
    var
        ItemTemplate: Record "Item Template";
    begin
        // [SCENARIO] Item Template does not allow non-existing values in table relation fields.

        // [GIVEN] An item template
        ItemTemplate.Init();

        // [WHEN] Assigning a non-existing "Base Unit of Measure"
        asserterror ItemTemplate.Validate("Base Unit of Measure", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Inventory Posting Group"
        asserterror ItemTemplate.Validate("Inventory Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Item Disc. Group"
        asserterror ItemTemplate.Validate("Item Disc. Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Gen. Prod. Posting Group"
        asserterror ItemTemplate.Validate("Gen. Prod. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Tax Group Code"
        asserterror ItemTemplate.Validate("Tax Group Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "VAT Prod. Posting Group"
        asserterror ItemTemplate.Validate("VAT Prod. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Item Category Code"
        asserterror ItemTemplate.Validate("Item Category Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Service Item Group"
        asserterror ItemTemplate.Validate("Service Item Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Warehouse Class Code"
        asserterror ItemTemplate.Validate("Warehouse Class Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateValidateTableRelations()
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
    begin
        // [SCENARIO] Customer Template does not allow non-existing values in table relation fields.

        // [GIVEN] A customer template
        MiniCustomerTemplate.Init();

        // [WHEN] Assigning a non-existing "Document Sending Profile"
        asserterror MiniCustomerTemplate.Validate("Document Sending Profile", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Customer Posting Group"
        asserterror MiniCustomerTemplate.Validate("Customer Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Currency Code"
        asserterror MiniCustomerTemplate.Validate("Currency Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Customer Price Group"
        asserterror MiniCustomerTemplate.Validate("Customer Price Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Language Code"
        asserterror MiniCustomerTemplate.Validate("Language Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Payment Terms Code"
        asserterror MiniCustomerTemplate.Validate("Payment Terms Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Fin. Charge Terms Code"
        asserterror MiniCustomerTemplate.Validate("Fin. Charge Terms Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Customer Disc. Group"
        asserterror MiniCustomerTemplate.Validate("Customer Disc. Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Country/Region Code"
        asserterror MiniCustomerTemplate.Validate("Country/Region Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Payment Method Code"
        asserterror MiniCustomerTemplate.Validate("Payment Method Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Gen. Bus. Posting Group"
        asserterror MiniCustomerTemplate.Validate("Gen. Bus. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Reminder Terms Code"
        asserterror MiniCustomerTemplate.Validate("Reminder Terms Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "VAT Bus. Posting Group"
        asserterror MiniCustomerTemplate.Validate("VAT Bus. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateValidateTableRelations()
    var
        MiniVendorTemplate: Record "Mini Vendor Template";
    begin
        // [SCENARIO] Vendor Template does not allow non-existing values in table relation fields.

        // [GIVEN] A vendor template
        MiniVendorTemplate.Init();

        // [WHEN] Assigning a non-existing "Vendor Posting Group"
        asserterror MiniVendorTemplate.Validate("Vendor Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Currency Code"
        asserterror MiniVendorTemplate.Validate("Currency Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Language Code"
        asserterror MiniVendorTemplate.Validate("Language Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Payment Terms Code"
        asserterror MiniVendorTemplate.Validate("Payment Terms Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Fin. Charge Terms Code"
        asserterror MiniVendorTemplate.Validate("Fin. Charge Terms Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Invoice Disc. Code"
        asserterror MiniVendorTemplate.Validate("Invoice Disc. Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Country/Region Code"
        asserterror MiniVendorTemplate.Validate("Country/Region Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Payment Method Code"
        asserterror MiniVendorTemplate.Validate("Payment Method Code", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "Gen. Bus. Posting Group"
        asserterror MiniVendorTemplate.Validate("Gen. Bus. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;

        // [WHEN] Assigning a non-existing "VAT Bus. Posting Group"
        asserterror MiniVendorTemplate.Validate("VAT Bus. Posting Group", LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateEnabledFieldSynchronizedWithConfigTemplateHeader()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        CustTemplateCard: TestPage "Cust. Template Card";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 159448] Field "Enabled" in customer template card should be synchronized with configuration template

        // [GIVEN] Create new customer template
        Initialize;

        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);

        // [WHEN] Open customer template card from configuration templates list
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        CustTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // [THEN] "Enabled" = TRUE in template card
        CustTemplateCard.TemplateEnabled.AssertEquals(true);

        // [WHEN] Set "Enabled" = FALSE in template card
        CustTemplateCard.TemplateEnabled.SetValue(false);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = FALSE
        ConfigTemplateHeader.TestField(Enabled, false);

        // [WHEN] Set "Enabled" = TRUE in template card
        CustTemplateCard.TemplateEnabled.SetValue(true);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = TRUE
        ConfigTemplateHeader.TestField(Enabled, true);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerFromTemplateWithTwoEnabledTemplates()
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 159448] Customer template should be selected from a list when creating a new customer with two customer templates enabled

        Initialize;

        // [GIVEN] Create two enabled customer templates "T1" and "T2"
        CreateConfigTemplateFromCustomerWithEnabledOption(true);
        CreateConfigTemplateFromCustomerWithEnabledOption(true);
        // [GIVEN] Create one disabled template "T3"
        CreateConfigTemplateFromCustomerWithEnabledOption(false);

        // [WHEN] Create new customer from template
        EnqueueEnabledTemplates;
        MiniCustomerTemplate.NewCustomerFromTemplate(Customer);

        // [THEN] List of customer templates with two elements "T1" and "T2" is presented
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerFromTemplateWithOneEnabledTemplate()
    var
        Customer: Record Customer;
        MiniCustomerTemplate: Record "Mini Customer Template";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 159448] New customer should be created according to template without user confirmation if there is only one enabled customer template

        Initialize;

        // [GIVEN] Create disabled customer template "T1"
        CreateConfigTemplateFromCustomerWithEnabledOption(false);
        // [GIVEN] Create enabled customer template "T2"
        ConfigTemplHeaderCode := CreateConfigTemplateFromCustomerWithEnabledOption(true);

        // [WHEN] Create new customer from template
        MiniCustomerTemplate.NewCustomerFromTemplate(Customer);

        // [THEN] New customer is created from template "T2"
        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerFromTemplateNoEnabledTemplates()
    var
        Customer: Record Customer;
        MiniCustomerTemplate: Record "Mini Customer Template";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 159448] Blank customer is created when all customer templates are disabled

        Initialize;

        // [GIVEN] Create two disabled customer templates
        CreateConfigTemplateFromCustomerWithEnabledOption(false);
        CreateConfigTemplateFromCustomerWithEnabledOption(false);

        // [WHEN] Create new customer from template
        MiniCustomerTemplate.NewCustomerFromTemplate(Customer);

        // [THEN] Blank customer is created
        ValidateCustomerVsBlankTemplate(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateEnabledFieldSynchronizedWithConfigTemplateHeader()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        VendorTemplateCard: TestPage "Vendor Template Card";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 159448] Field "Enabled" in vendor template card should be synchronized with configuration template

        // [GIVEN] Create new vendor template
        Initialize;

        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Vendor);

        // [WHEN] Open vendor template card from configuration templates list
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        VendorTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // [THEN] "Enabled" = TRUE in template card
        VendorTemplateCard.TemplateEnabled.AssertEquals(true);

        // [WHEN] Set "Enabled" = FALSE in template card
        VendorTemplateCard.TemplateEnabled.SetValue(false);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = FALSE
        ConfigTemplateHeader.TestField(Enabled, false);

        // [WHEN] Set "Enabled" = TRUE in template card
        VendorTemplateCard.TemplateEnabled.SetValue(true);
        ConfigTemplateHeader.Find;

        // [THEN] Record in table "Config. Template Header" is updated: "Enabled" = TRUE
        ConfigTemplateHeader.TestField(Enabled, true);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewVendorFromTemplateWithTwoEnabledTemplates()
    var
        MiniVendorTemplate: Record "Mini Vendor Template";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 159448] Vendor template should be selected from a list when creating a new vendor with two vendor templates enabled

        Initialize;

        // [GIVEN] Create two enabled vendor templates "T1" and "T2"
        CreateConfigTemplateFromVendorWithEnabledOption(true);
        CreateConfigTemplateFromVendorWithEnabledOption(true);
        // [GIVEN] Create one disabled template "T3"
        CreateConfigTemplateFromVendorWithEnabledOption(false);

        // [WHEN] Create new vendor from template
        EnqueueEnabledTemplates;
        MiniVendorTemplate.NewVendorFromTemplate(Vendor);

        // [THEN] List of vendor templates with two elements "T1" and "T2" is presented
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewVendorFromTemplateWithOneEnabledTemplate()
    var
        Vendor: Record Vendor;
        MiniVendorTemplate: Record "Mini Vendor Template";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 159448] New vendor should be created according to template without user confirmation if there is only one enabled vendor template

        Initialize;

        // [GIVEN] Create disabled vendor template "T1"
        CreateConfigTemplateFromVendorWithEnabledOption(false);
        // [GIVEN] Create enabled vendor template "T2"
        ConfigTemplHeaderCode := CreateConfigTemplateFromVendorWithEnabledOption(true);

        // [WHEN] Create new vendor from template
        MiniVendorTemplate.NewVendorFromTemplate(Vendor);

        // [THEN] New vendor is created from template "T2"
        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewVendorFromTemplateNoEnabledTemplates()
    var
        Vendor: Record Vendor;
        MiniVendorTemplate: Record "Mini Vendor Template";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 159448] Blank vendor is created when all vendor templates are disabled

        Initialize;

        // [GIVEN] Create two disabled vendor templates
        CreateConfigTemplateFromVendorWithEnabledOption(false);
        CreateConfigTemplateFromVendorWithEnabledOption(false);

        // [WHEN] Create new vendor from template
        MiniVendorTemplate.NewVendorFromTemplate(Vendor);

        // [THEN] Blank vendor is created
        ValidateVendorVsBlankTemplate(Vendor);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerWithTemplateWhenOneEnabled()
    var
        Customer: Record Customer;
        MiniCustomerTemplate: Record "Mini Customer Template";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 382241] Only Enabled=TRUE customer templates are shown when perform "Apply Template" action
        Initialize;
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create disabled customer template "T1"
        CreateConfigTemplateFromCustomerWithEnabledOption(false);
        // [GIVEN] Create enabled customer template "T2"
        CreateConfigTemplateFromCustomerWithEnabledOption(true);

        // [WHEN] Perform Customer->"Apply Template" action
        EnqueueEnabledTemplates;
        Assert.AreEqual(1, LibraryVariableStorage.PeekInteger(1), '');
        MiniCustomerTemplate.UpdateCustomerFromTemplate(Customer);

        // [THEN] Customer template list is shown with only "T2" template
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorWithTemplateWhenOneEnabled()
    var
        Vendor: Record Vendor;
        MiniVendorTemplate: Record "Mini Vendor Template";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 382241] Only Enabled=TRUE vendor templates are shown when perform "Apply Template" action
        Initialize;
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create disabled vendor template "T1"
        CreateConfigTemplateFromVendorWithEnabledOption(false);
        // [GIVEN] Create enabled vendor template "T2"
        CreateConfigTemplateFromVendorWithEnabledOption(true);

        // [WHEN] Perform Vendor->"Apply Template" action
        EnqueueEnabledTemplates;
        Assert.AreEqual(1, LibraryVariableStorage.PeekInteger(1), '');
        MiniVendorTemplate.UpdateVendorFromTemplate(Vendor);

        // [THEN] Vendor template list is shown with only "T2" template
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler,ConfigTemplatesCountVerificationHandler')]
    [Scope('OnPrem')]
    procedure ApplyItemWithTemplateWhenOneEnabled()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Template";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO 382241] Only Enabled=TRUE item templates are shown when perform "Apply Template" action
        Initialize;
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create disabled item template "T1"
        CreateConfigTemplateFromItemWithEnabledOption(false);
        // [GIVEN] Create enabled item template "T2"
        CreateConfigTemplateFromItemWithEnabledOption(true);

        // [WHEN] Perform Item->"Apply Template" action
        EnqueueEnabledTemplates;
        Assert.AreEqual(1, LibraryVariableStorage.PeekInteger(1), '');
        ItemTemplate.UpdateItemFromTemplate(Item);

        // [THEN] Item template list is shown with only "T2" template
        // Verified in ConfigTemplatesCountVerificationHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodNewTemplate()
    var
        InventorySetup: Record "Inventory Setup";
        ItemTemplateCard: TestPage "Item Template Card";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] New Item Templates take the costing method from Inventory Setup

        // [GIVEN] Default Costing Method = Average
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [WHEN] Opening the Item Template Card
        ItemTemplateCard.OpenNew;

        // [THEN] The Costing Method equals Average
        ItemTemplateCard."Costing Method".AssertEquals(InventorySetup."Default Costing Method"::Average);
        ItemTemplateCard.Close;
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodPartialTemplate()
    var
        InventorySetup: Record "Inventory Setup";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        ItemTemplateCard: TestPage "Item Template Card";
        ConfigTemplates: TestPage "Config Templates";
        TemplateCode: Code[20];
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] Templates without Costing Method take the costing method from Inventory Setup

        // [GIVEN] A template with Costing Method FIFO
        TemplateCode := CreateConfigTemplateFromItemWithEnabledOption(true);

        // [GIVEN] Default Costing Method Average in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [WHEN] Opening the Item Template Card for the Template
        ItemTemplateCard.Trap;
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoKey(TemplateCode);
        ConfigTemplates."Edit Template".Invoke;

        // [THEN] The Costing Method on the Template Card is FIFO
        ItemTemplateCard."Costing Method".AssertEquals(InventorySetup."Default Costing Method"::FIFO);
        ItemTemplateCard.Close;

        // [WHEN] Deleting the Costing method from the template and reopening the template
        ConfigTemplateLine.SetRange("Data Template Code", TemplateCode);
        ConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Costing Method"));
        ConfigTemplateLine.DeleteAll();

        ItemTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;

        // [THEN] The Costing method is Average
        ItemTemplateCard."Costing Method".AssertEquals(InventorySetup."Default Costing Method"::Average);
        ItemTemplateCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodNoTemplate()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] Item created manually take the costing method from Inventory Setup

        // [GIVEN] Default Costing Method Average in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [WHEN] Create new item manually without template
        Item.Init();
        Item.Validate("No.", LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item));

        // [THEN] The Costing method is Average
        Assert.AreEqual(Item."Costing Method"::Average, Item."Costing Method", 'Costing Method should be Average');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodRenaming()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] Rename item created manually keep costing method unchanged

        // [GIVEN] Default Costing Method Average in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [GIVEN] New item with Costing Method Average
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Default Costing Method Standard in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Standard);
        InventorySetup.Modify();

        // [THEN] Rename item
        Item.Rename(LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item));

        // [WHEN] The Costing method is still Average
        Assert.AreEqual(Item."Costing Method"::Average, Item."Costing Method", 'Costing Method should be Average');
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ItemTemplateCardUpdateNoSeries()
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Item]
        // [SCENARIO 229503] User sets No. Series on Item Template Card
        Initialize;

        // [GIVEN] Configuration Template for blank Item
        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;

        // [GIVEN] Item Template Card is opened for the Config. Template
        ItemTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;

        // [WHEN] Set No. Series ="S" on the Item Template Card
        ItemTemplateCard.NoSeries.SetValue(NoSeriesCode);
        ItemTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in the Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ItemTemplateCardResetNoSeries()
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        ItemTemplateCard: TestPage "Item Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Item]
        // [SCENARIO 229503] User clears No. Series value on Item Template Card
        Initialize;

        // [GIVEN] Configuration Template "" for blank Item with No. Series = "S"
        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);

        // [GIVEN] Item Template Card is opened for the Config. Template
        ItemTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;
        ItemTemplateCard.NoSeries.AssertEquals(NoSeriesCode);

        // [WHEN] Set No. Series ="S" on the Item Template Card
        ItemTemplateCard.NoSeries.SetValue('');
        ItemTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", '');
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromItemTemplateWithNoSeries()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemNo: Variant;
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Item]
        // [SCENARIO 229503] When new item is created from template, No. and No. Series are assigned from Item Template No. Series
        Initialize;

        // [GIVEN] Configuration Template for blank Item with No. Series = "S" and next No. = "N"
        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate);

        // [WHEN] Create new Item
        ItemCard.OpenNew;
        ItemNo := ItemCard."No.".Value;
        ItemCard.Close;

        // [THEN] Item is created with No. = "N" and "No. Series" = "S"
        VerifyItemNoWithSeries(ItemNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateCardUpdateNoSeries()
    var
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        CustTemplateCard: TestPage "Cust. Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Customer]
        // [SCENARIO 229503] User sets No. Series on Customer Template Card
        Initialize;

        // [GIVEN] Configuration Template for blank Customer
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;

        // [GIVEN] Customer Template Card is opened for the Config. Template
        CustTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;

        // [WHEN] Set No. Series ="S" on the Customer Template Card
        CustTemplateCard.NoSeries.SetValue(NoSeriesCode);
        CustTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in the Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateCardResetNoSeries()
    var
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        CustTemplateCard: TestPage "Cust. Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Customer]
        // [SCENARIO 229503] User clears No. Series value on Customer Template Card
        Initialize;

        // [GIVEN] Configuration Template "" for blank Customer with No. Series = "S"
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);

        // [GIVEN] Customer Template Card is opened for the Config. Template
        CustTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;
        CustTemplateCard.NoSeries.AssertEquals(NoSeriesCode);

        // [WHEN] Set No. Series ="S" on the Customer Template Card
        CustTemplateCard.NoSeries.SetValue('');
        CustTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", '');
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromCustomerTemplateWithNoSeries()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Variant;
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Customer]
        // [SCENARIO 229503] When new customer is created from template, No. and No. Series are assigned from Customer Template No. Series
        Initialize;

        // [GIVEN] Configuration Template for blank Customer with No. Series = "S" and next No. = "N"
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate);

        // [WHEN] Create new Customer
        CustomerCard.OpenNew;
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.Close;

        // [THEN] Customer is created with No. = "N" and "No. Series" = "S"
        VerifyCustomerNoWithSeries(CustomerNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateCardUpdateNoSeries()
    var
        Vendor: Record Vendor;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        VendorTemplateCard: TestPage "Vendor Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Vendor]
        // [SCENARIO 229503] User sets No. Series on Vendor Template Card
        Initialize;

        // [GIVEN] Configuration Template for blank Vendor
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;

        // [GIVEN] Vendor Template Card is opened for the Config. Template
        VendorTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;

        // [WHEN] Set No. Series ="S" on the Vendor Template Card
        VendorTemplateCard.NoSeries.SetValue(NoSeriesCode);
        VendorTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in the Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateCardResetNoSeries()
    var
        Vendor: Record Vendor;
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
        VendorTemplateCard: TestPage "Vendor Template Card";
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series] [Vendor]
        // [SCENARIO 229503] User clears No. Series value on Vendor Template Card
        Initialize;

        // [GIVEN] Configuration Template "" for blank Vendor with No. Series = "S"
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);

        // [GIVEN] Vendor Template Card is opened for the Config. Template
        VendorTemplateCard.Trap;
        ConfigTemplates.OpenView;
        ConfigTemplates.GotoKey(ConfigTemplHeaderCode);
        ConfigTemplates."Edit Template".Invoke;
        VendorTemplateCard.NoSeries.AssertEquals(NoSeriesCode);

        // [WHEN] Set No. Series ="S" on the Vendor Template Card
        VendorTemplateCard.NoSeries.SetValue('');
        VendorTemplateCard.Close;

        // [THEN] Instance No. Series = "S" in Config. Template Header
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.TestField("Instance No. Series", '');
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorFromVendorTemplateWithNoSeries()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Variant;
        ConfigTemplHeaderCode: Code[10];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Vendor]
        // [SCENARIO 229503] When new vendor is created from template, No. and No. Series are assigned from Vendor Template No. Series
        Initialize;

        // [GIVEN] Configuration Template for blank Vendor with No. Series = "S" and next No. = "N"
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode, NoSeriesCode);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate);

        // [WHEN] Create new Vendor
        VendorCard.OpenNew;
        VendorNo := VendorCard."No.".Value;
        VendorCard.Close;

        // [THEN] Vendor is created with No. = "N" and "No. Series" = "S"
        VerifyVendorNoWithSeries(VendorNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure InsertItemWithGlobalDimensionsFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ItemTemplate: Record "Item Template";
        Item: Record Item;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Item]
        // [SCENARIO 252076] Global dimensions codes are populated when insert item from template with these dimensions.
        Initialize;

        // [GIVEN] Item template with both global dimensions codes
        TemplateCode := CreateItemTemplateWithGlobDimFromItem(GlobalDim1ValCode, GlobalDim2ValCode);
        ConfigTemplateHeader.Get(TemplateCode);

        // [WHEN] Insert new item from this template
        ItemTemplate.InsertItemFromTemplate(ConfigTemplateHeader, Item);

        // [THEN] The codes of the global dimensions of the new created item are equal to the codes of the global dimensions of the template
        Item.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Item.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler,TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateItemWithGlobalDimensionsFromTemplate()
    var
        TempItemTemplate: Record "Item Template" temporary;
        Item: Record Item;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Item]
        // [SCENARIO 252076] Global dimensions codes are populated when update item from template with these dimensions.
        Initialize;

        // [GIVEN] Blank item
        CreateBlankItem(Item);

        // [GIVEN] Item template with both global dimensions codes
        TemplateCode := CreateItemTemplateWithGlobDimFromItem(GlobalDim1ValCode, GlobalDim2ValCode);
        ReadItemTemplFromConfigTempl(TemplateCode, TempItemTemplate);
        LibraryVariableStorage.Enqueue(TemplateCode);

        // [WHEN] Update the item from this template
        TempItemTemplate.UpdateItemFromTemplate(Item);

        // [THEN] The codes of the global dimensions of the updated item are equal to the codes of the global dimensions of the template
        Item.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Item.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure InsertCustomerWithGlobalDimensionsFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        MiniCustomerTemplate: Record "Mini Customer Template";
        Customer: Record Customer;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Customer]
        // [SCENARIO 252076] Global dimensions codes are populated when insert customer from template with these dimensions.
        Initialize;

        // [GIVEN] Customer template with both global dimensions codes
        TemplateCode := CreateCustTemplateWithGlobDimFromCustomer(GlobalDim1ValCode, GlobalDim2ValCode);
        ConfigTemplateHeader.Get(TemplateCode);

        // [WHEN] Insert new customer from this template
        MiniCustomerTemplate.InsertCustomerFromTemplate(ConfigTemplateHeader, Customer);

        // [THEN] The codes of the global dimensions of the new created customer are equal to the codes of the global dimensions of the template
        Customer.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Customer.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerWithGlobalDimensionsFromTemplate()
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        Customer: Record Customer;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Customer]
        // [SCENARIO 252076] Global dimensions codes are populated when update customer from template with these dimensions.
        Initialize;

        // [GIVEN] Blank customer
        CreateBlankCustomer(Customer);

        // [GIVEN] Customer template with both global dimensions codes
        TemplateCode := CreateCustTemplateWithGlobDimFromCustomer(GlobalDim1ValCode, GlobalDim2ValCode);
        ReadCustTemplFromConfigTempl(TemplateCode, TempMiniCustomerTemplate);
        LibraryVariableStorage.Enqueue(TemplateCode);

        // [WHEN] Update the customer from this template
        TempMiniCustomerTemplate.UpdateCustomerFromTemplate(Customer);

        // [THEN] The codes of the global dimensions of the updated customer are equal to the codes of the global dimensions of the template
        Customer.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Customer.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure InsertVendorWithGlobalDimensionsFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        MiniVendorTemplate: Record "Mini Vendor Template";
        Vendor: Record Vendor;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Vendor]
        // [SCENARIO 252076] Global dimensions codes are populated when insert vendor from template with these dimensions.
        Initialize;

        // [GIVEN] Vendor template with both global dimensions codes
        TemplateCode := CreateVendTemplateWithGlobDimFromVendor(GlobalDim1ValCode, GlobalDim2ValCode);
        ConfigTemplateHeader.Get(TemplateCode);

        // [WHEN] Insert new vendor from this template
        MiniVendorTemplate.InsertVendorFromTemplate(ConfigTemplateHeader, Vendor);

        // [THEN] The codes of the global dimensions of the new created vendor are equal to the codes of the global dimensions of the template
        Vendor.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Vendor.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler,TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateVendorWithGlobalDimensionsFromTemplate()
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        Vendor: Record Vendor;
        TemplateCode: Code[10];
        GlobalDim1ValCode: Code[20];
        GlobalDim2ValCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Vendor]
        // [SCENARIO 252076] Global dimensions codes are populated when update vendor from template with these dimensions.
        Initialize;

        // [GIVEN] Blank vendor
        CreateBlankVendor(Vendor);

        // [GIVEN] Vendor template with both global dimensions codes
        TemplateCode := CreateVendTemplateWithGlobDimFromVendor(GlobalDim1ValCode, GlobalDim2ValCode);
        ReadVendTemplFromConfigTempl(TemplateCode, TempMiniVendorTemplate);
        LibraryVariableStorage.Enqueue(TemplateCode);

        // [WHEN] Update the vendor from this template
        TempMiniVendorTemplate.UpdateVendorFromTemplate(Vendor);

        // [THEN] The codes of the global dimensions of the updated vendor are equal to the codes of the global dimensions of the template
        Vendor.TestField("Global Dimension 1 Code", GlobalDim1ValCode);
        Vendor.TestField("Global Dimension 2 Code", GlobalDim2ValCode);
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateLookupCity()
    var
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Cust. Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of City field for Customer Template page
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        OpenCustomerTemplateCard(CustTemplateCard);

        // [WHEN] Lookup for City field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard.City.Lookup;

        // [THEN] Customer template Post Code = "PC", Country/Region Code = "CRC"
        CustTemplateCard."Post Code".AssertEquals(PostCode.Code);
        CustTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        CustTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateLookupPostCode()
    var
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Cust. Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of Post Code field for Customer Template page
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        OpenCustomerTemplateCard(CustTemplateCard);

        // [WHEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard."Post Code".Lookup;

        // [THEN] Customer template City = "CITY", Country/Region Code = "CRC"
        CustTemplateCard.City.AssertEquals(PostCode.City);
        CustTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        CustTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateValidateCountryCode()
    var
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Cust. Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Changing Country/Region Code on Customer Template page leads to clear Country and Post Code fields
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        OpenCustomerTemplateCard(CustTemplateCard);

        // [GIVEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard."Post Code".Lookup;

        // [WHEN] Country/Region Code is being cleared
        CustTemplateCard."Country/Region Code".SetValue('');

        // [THEN] Customer template City = '', Post Code = ''
        CustTemplateCard.City.AssertEquals('');
        CustTemplateCard."Post Code".AssertEquals('');
        CustTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateLookupCity()
    var
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of City field for Vendor Template page
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        OpenVendorTemplateCard(VendorTemplateCard);

        // [WHEN] Lookup for City field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard.City.Lookup;

        // [THEN] Vendor Template Post Code = "PC", Country/Region Code = "CRC"
        VendorTemplateCard."Post Code".AssertEquals(PostCode.Code);
        VendorTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        VendorTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateLookupPostCode()
    var
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of Post Code field for Vendor Template page
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        OpenVendorTemplateCard(VendorTemplateCard);

        // [WHEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard."Post Code".Lookup;

        // [THEN] Vendor Template City = "CITY", Country/Region Code = "CRC"
        VendorTemplateCard.City.AssertEquals(PostCode.City);
        VendorTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        VendorTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateValidateCountryCode()
    var
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Template Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Changing Country/Region Code on Vendor Template page leads to clear Country and Post Code fields
        Initialize;

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        OpenVendorTemplateCard(VendorTemplateCard);

        // [GIVEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard."Post Code".Lookup;

        // [WHEN] Country/Region Code is being cleared
        VendorTemplateCard."Country/Region Code".SetValue('');

        // [THEN] Vendor Template City = '', Post Code = ''
        VendorTemplateCard.City.AssertEquals('');
        VendorTemplateCard."Post Code".AssertEquals('');
        VendorTemplateCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure RelatedTemplateFromAnotherTableOnValidate()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplHeaderCodeCustomer: Code[10];
        ConfigTemplHeaderCodeVendor: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309201] Set Related Template Code to Code from another table's template in Config. Template Line OnValidate
        Initialize;

        // [GIVEN] Customer Template C001
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer,ConfigTemplHeaderCodeCustomer);
        // [GIVEN] Vendor Template V001
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor,ConfigTemplHeaderCodeVendor);

        // [WHEN] Validate "Template Code" to V001
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine,ConfigTemplHeaderCodeCustomer);
        ConfigTemplateLine.Validate(Type,ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.Validate("Template Code",ConfigTemplHeaderCodeVendor);

        // [THEN] "Template Code" = V001
        ConfigTemplateLine.TestField("Template Code",ConfigTemplHeaderCodeVendor);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure RelatedTemplateAddedTwiceOnValidate()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplHeaderCodeCustomer: Code[10];
        ConfigTemplHeaderCodeVendor: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309201] Set Related Template Code to Code from another table's template twice in Config. Template Line OnValidate
        Initialize;

        // [GIVEN] Customer Template C001
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer,ConfigTemplHeaderCodeCustomer);
        // [GIVEN] Vendor Template V001
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor,ConfigTemplHeaderCodeVendor);

        // [GIVEN] ConfigTemplateLine CTL1 with "Template Code" = V001
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine,ConfigTemplHeaderCodeCustomer);
        ConfigTemplateLine.Validate(Type,ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.Validate("Template Code",ConfigTemplHeaderCodeVendor);
        ConfigTemplateLine.Modify(true);

        // [WHEN]  Validate "Template Code" to V001 the second time
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine,ConfigTemplHeaderCodeCustomer);
        ConfigTemplateLine.Validate(Type,ConfigTemplateLine.Type::"Related Template");
        asserterror ConfigTemplateLine.Validate("Template Code",ConfigTemplHeaderCodeVendor);
        Assert.ExpectedError(StrSubstNo(DuplicateRelationErr,ConfigTemplHeaderCodeVendor));
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,VendorTemplateCardHandler,ConfigTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure RelatedTemplateFromAnotherTableOnLookup()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateSubform: TestPage "Config. Template Subform";
        ConfigTemplHeaderCodeCustomer: Code[10];
        ConfigTemplHeaderCodeVendor: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309201] Set Related Template Code to Code from another table's template in Config. Template Line OnLookup
        Initialize;

        // [GIVEN] Customer Template C001
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer,ConfigTemplHeaderCodeCustomer);
        // [GIVEN] Vendor Template V001
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor,ConfigTemplHeaderCodeVendor);

        // [WHEN] Validate "Template Code" to V001
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine,ConfigTemplHeaderCodeCustomer);
        ConfigTemplateLine.Validate(Type,ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.Modify(true);
        ConfigTemplateSubform.OpenEdit;
        ConfigTemplateSubform.GotoRecord(ConfigTemplateLine);
        LibraryVariableStorage.Enqueue(ConfigTemplHeaderCodeVendor);
        ConfigTemplateSubform."Template Code".Lookup;
        ConfigTemplateSubform.Close;

        // [THEN] "Template Code" = V001
        ConfigTemplateLine.SetRange("Data Template Code",ConfigTemplateLine."Data Template Code");
        ConfigTemplateLine.SetRange("Line No.",ConfigTemplateLine."Line No.");
        ConfigTemplateLine.FindFirst;
        ConfigTemplateLine.TestField("Template Code",ConfigTemplHeaderCodeVendor);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler,ConfigTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetRelatedTemplateToItselfOnLookup()
    var
        Customer: Record Customer;
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateSubform: TestPage "Config. Template Subform";
        ConfigTemplHeaderCodeCustomer: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309201] Set Related Template Code to Template's Code in Config. Template Line OnLookup
        Initialize;

        // [GIVEN] Customer Template C001
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer,ConfigTemplHeaderCodeCustomer);

        // [WHEN] Validate "Template Code" to C001
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine,ConfigTemplHeaderCodeCustomer);
        ConfigTemplateLine.Validate(Type,ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.Modify(true);
        ConfigTemplateSubform.OpenEdit;
        ConfigTemplateSubform.GotoRecord(ConfigTemplateLine);
        LibraryVariableStorage.Enqueue(ConfigTemplHeaderCodeCustomer);
        asserterror ConfigTemplateSubform."Template Code".Lookup;
        Assert.ExpectedError(RelationErr);
        ConfigTemplateSubform.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerTemplateWithDimToCustomers()
    var
        Customer: array[2] of Record Customer;
        MiniCustomerTemplate: Record "Mini Customer Template";
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Customer] [Default Dimension]
        // [SCENARIO 341169] Customers should have default dimensions from Customer Template after applying the template.
        Initialize;

        // [GIVEN] Customer Template with default dimensions.
        CustomerTemplateCode := CreateCustTemplateWithDimFromCustomer();
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);

        // [GIVEN] Two blank Customers.
        CreateBlankCustomer(Customer[1]);
        CreateBlankCustomer(Customer[2]);

        // [WHEN] Applying the template.
        Customer[1].SetFilter("No.", '%1|%2', Customer[1]."No.", Customer[2]."No.");
        MiniCustomerTemplate.UpdateCustomersFromTemplate(Customer[1]);

        // [THEN] Customers has default dimensions from template.
        Customer[1].Find();
        ValidateCustomerVsConfigTemplate(Customer[1], CustomerTemplateCode);
        Customer[2].Find();
        ValidateCustomerVsConfigTemplate(Customer[2], CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorTemplateWithDimToVendors()
    var
        MiniVendorTemplate: Record "Mini Vendor Template";
        Vendor: array[2] of Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Default Dimension]
        // [SCENARIO 341169] Vendors should have default dimensions from Vendor Template after applying the template.
        Initialize;

        // [GIVEN] Vendor Template with default dimensions.
        VendorTemplateCode := CreateVendTemplateWithDimFromVendor();
        LibraryVariableStorage.Enqueue(VendorTemplateCode);

        // [GIVEN] Two blank Vendors.
        CreateBlankVendor(Vendor[1]);
        CreateBlankVendor(Vendor[2]);

        // [WHEN] Applying the template.
        Vendor[1].SetFilter("No.", '%1|%2', Vendor[1]."No.", Vendor[2]."No.");
        MiniVendorTemplate.UpdateVendorsFromTemplate(Vendor[1]);

        // [THEN] Vendors has default dimensions from template.
        Vendor[1].Find();
        ValidateVendorVsConfigTemplate(Vendor[1], VendorTemplateCode);
        Vendor[2].Find();
        ValidateVendorVsConfigTemplate(Vendor[2], VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler,ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure ApplyItemTemplateWithDimToItems()
    var
        Item: array[2] of Record Item;
        ItemTemplate: Record "Item Template";
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item] [Default Dimension]
        // [SCENARIO 341169] Item should have default dimensions from Item Template after applying the template.
        Initialize;

        // [GIVEN] Item Template with default dimensions
        ItemTemplateCode := CreateItemTemplateWithDimFromItem();
        LibraryVariableStorage.Enqueue(ItemTemplateCode);

        // [GIVEN] Two blank Items.
        CreateBlankItem(Item[1]);
        CreateBlankItem(Item[2]);

        // [WHEN] Applying the template.
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        ItemTemplate.UpdateItemsFromTemplate(Item[1]);

        // [THEN] Items has default dimensions from template.
        Item[1].Find();
        ValidateItemVsConfigTemplate(Item[1], ItemTemplateCode);
        Item[2].Find();
        ValidateItemVsConfigTemplate(Item[2], ItemTemplateCode);
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Templates Test");
        DeleteConfigurationTemplates;
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Templates Test");

        ClearTable(DATABASE::"Item Identifier");
        ClearTable(DATABASE::Job);
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        ClearTable(DATABASE::"Resource Skill");
        ClearTable(DATABASE::"Service Item Component");
        ClearTable(DATABASE::"Troubleshooting Setup");

        if not LibraryFiscalYear.AccountingPeriodsExists then
            LibraryFiscalYear.CreateFiscalYear;

        LibraryApplicationArea.EnableFoundationSetup;
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Templates Test");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        ProductionBOMLine: Record "Production BOM Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ResourceSkill: Record "Resource Skill";
        ItemIdentifier: Record "Item Identifier";
        ServiceItemComponent: Record "Service Item Component";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::"Job Planning Line":
                JobPlanningLine.DeleteAll();
            DATABASE::Job:
                Job.DeleteAll();
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::"Troubleshooting Setup":
                TroubleshootingSetup.DeleteAll();
            DATABASE::"Resource Skill":
                ResourceSkill.DeleteAll();
            DATABASE::"Item Identifier":
                ItemIdentifier.DeleteAll();
            DATABASE::"Service Item Component":
                ServiceItemComponent.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full;
    end;

    local procedure TemplateFieldDefinitionsMatchTableFields(RecRef: RecordRef; FieldRefArray: array[100] of FieldRef)
    var
        FieldRefTemplate: FieldRef;
        FieldRefTable: FieldRef;
        I: Integer;
    begin
        for I := 1 to ArrayLen(FieldRefArray) do begin
            FieldRefTemplate := FieldRefArray[I];
            FieldRefTable := RecRef.Field(FieldRefTemplate.Number);
            ValidateFieldDefinitionsMatch(FieldRefTable, FieldRefTemplate);
        end;
    end;

    local procedure CreateBlankCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer.Insert(true);
    end;

    local procedure CreateBlankItem(var Item: Record Item)
    begin
        Item.Init();
        Item.Insert(true);
    end;

    local procedure CreateBlankVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor.Insert(true);
    end;

    local procedure CreateConfigTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; TableID: Integer)
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", TableID);
        ConfigTemplateHeader.Modify(true);
    end;

    local procedure CreateConfigTemplateFromItemWithEnabledOption(IsTemplateEnabled: Boolean): Code[10]
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        SetTemplateEnabled(ConfigTemplHeaderCode, IsTemplateEnabled);
        exit(ConfigTemplHeaderCode);
    end;

    local procedure CreateConfigTemplateFromCustomerWithEnabledOption(IsTemplateEnabled: Boolean): Code[10]
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        CreateCustomerWithTemplateFieldsSet(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        SetTemplateEnabled(ConfigTemplHeaderCode, IsTemplateEnabled);
        exit(ConfigTemplHeaderCode);
    end;

    local procedure CreateConfigTemplateFromVendorWithEnabledOption(IsTemplateEnabled: Boolean): Code[10]
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        CreateVendorWithTemplateFieldsSet(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        SetTemplateEnabled(ConfigTemplHeaderCode, IsTemplateEnabled);
        exit(ConfigTemplHeaderCode);
    end;

    local procedure CreateCustomerWithTemplateFieldsSet(var Customer: Record Customer)
    var
        Customer2: Record Customer;
        Currency: Record Currency;
        CustomerPriceGroup: Record "Customer Price Group";
        Language: Record Language;
        PaymentTerms: Record "Payment Terms";
        FinChargeTerms: Record "Finance Charge Terms";
        CustDiscGroup: Record "Customer Discount Group";
        PaymentMethod: Record "Payment Method";
        ReminderTerms: Record "Reminder Terms";
    begin
        LibrarySales.CreateCustomer(Customer2);
        Customer.Init();
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate("Address 2", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Post Code"), DATABASE::Customer));
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDecInRange(1, 10000, 1));
        Customer.Validate("Customer Posting Group", Customer2."Customer Posting Group");

        Customer.Validate("Currency Code", EnsureRecordExistAndGetValue(Currency.FieldNo(Code), DATABASE::Currency));
        Customer.Validate(
          "Customer Price Group", EnsureRecordExistAndGetValue(CustomerPriceGroup.FieldNo(Code), DATABASE::"Customer Price Group"));
        Customer.Validate("Language Code", EnsureRecordExistAndGetValue(Language.FieldNo(Code), DATABASE::Language));
        Customer.Validate("Payment Terms Code", EnsureRecordExistAndGetValue(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms"));
        Customer.Validate(
          "Fin. Charge Terms Code", EnsureRecordExistAndGetValue(FinChargeTerms.FieldNo(Code), DATABASE::"Finance Charge Terms"));
        Customer.Validate(
          "Customer Disc. Group", EnsureRecordExistAndGetValue(CustDiscGroup.FieldNo(Code), DATABASE::"Customer Discount Group"));

        Customer.Validate("Print Statements", not Customer."Print Statements");
        Customer.Validate("Payment Method Code", EnsureRecordExistAndGetValue(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method"));
        Customer.Validate("Application Method", LibraryRandom.RandIntInRange(0, 1));
        Customer.Validate("Prices Including VAT", not Customer."Prices Including VAT");
        Customer.Validate("Gen. Bus. Posting Group", Customer2."Gen. Bus. Posting Group");
        Customer.Validate("Reminder Terms Code", EnsureRecordExistAndGetValue(ReminderTerms.FieldNo(Code), DATABASE::"Reminder Terms"));
        Customer.Validate("VAT Bus. Posting Group", Customer2."VAT Bus. Posting Group");
        Customer.Validate("Block Payment Tolerance", not Customer."Block Payment Tolerance");
        Customer.Validate("Allow Line Disc.", not Customer."Allow Line Disc.");
        Customer.Validate("Validate EU Vat Reg. No.", Customer."Validate EU Vat Reg. No.");
        Customer.Insert(true);
    end;

    local procedure CreateItemWithTemplateFieldsSet(var Item: Record Item)
    var
        Item2: Record Item;
        ItemDiscGroup: Record "Item Discount Group";
    begin
        LibraryInventory.CreateItem(Item2);
        CreateBlankItem(Item);
        Item.Validate("Base Unit of Measure", Item2."Base Unit of Measure");
        Item.Validate("Inventory Posting Group", Item2."Inventory Posting Group");
        Item.Validate("Item Disc. Group", EnsureRecordExistAndGetValue(ItemDiscGroup.FieldNo(Code), DATABASE::"Item Discount Group"));
        Item.Validate("Allow Invoice Disc.", not Item."Allow Invoice Disc.");
        Item.Validate("Price/Profit Calculation", LibraryRandom.RandIntInRange(0, 1));
        Item.Validate("Costing Method", LibraryRandom.RandIntInRange(0, 1));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDecInRange(1, 100, 1));
        Item.Validate("Gen. Prod. Posting Group", Item2."Gen. Prod. Posting Group");
        Item.Validate("Automatic Ext. Texts", not Item."Automatic Ext. Texts");
        Item.Validate("VAT Prod. Posting Group", Item2."VAT Prod. Posting Group");
        LibrarySmallBusiness.SetVATBusPostingGrPriceSetup(Item."VAT Prod. Posting Group", not Item."Price Includes VAT");
        Item.Validate("Price Includes VAT", not Item."Price Includes VAT");
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);
    end;

    local procedure CreateVendorWithTemplateFieldsSet(var Vendor: Record Vendor)
    var
        Vendor2: Record Vendor;
        Currency: Record Currency;
        Language: Record Language;
        PaymentTerms: Record "Payment Terms";
        FinChargeTerms: Record "Finance Charge Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor.Init();
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate("Address 2", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Post Code"), DATABASE::Vendor));
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor.Validate("Vendor Posting Group", Vendor2."Vendor Posting Group");

        Vendor.Validate("Currency Code", EnsureRecordExistAndGetValue(Currency.FieldNo(Code), DATABASE::Currency));
        Vendor.Validate("Language Code", EnsureRecordExistAndGetValue(Language.FieldNo(Code), DATABASE::Language));
        Vendor.Validate("Payment Terms Code", EnsureRecordExistAndGetValue(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms"));
        Vendor.Validate(
          "Fin. Charge Terms Code", EnsureRecordExistAndGetValue(FinChargeTerms.FieldNo(Code), DATABASE::"Finance Charge Terms"));

        Vendor.Validate("Payment Method Code", EnsureRecordExistAndGetValue(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method"));
        Vendor.Validate("Shipment Method Code", Vendor2."Shipment Method Code");
        Vendor.Validate("Application Method", LibraryRandom.RandIntInRange(0, 1));
        Vendor.Validate("Prices Including VAT", not Vendor."Prices Including VAT");
        Vendor.Validate("Gen. Bus. Posting Group", Vendor2."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", Vendor2."VAT Bus. Posting Group");
        Vendor.Validate("Block Payment Tolerance", not Vendor."Block Payment Tolerance");
        Vendor.Validate("Validate EU Vat Reg. No.", Vendor."Validate EU Vat Reg. No.");
        Vendor.Insert(true);
    end;

    local procedure CreateDefaultDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
    begin
        DefaultDimension.Init();
        DefaultDimension."Table ID" := DATABASE::Vendor;
        DefaultDimension."No." := 'Dimension';
        Dimension.FindFirst;
        DefaultDimension."Dimension Code" := Dimension.Code;
        DefaultDimension.Insert();
    end;

    local procedure CreateTemplateFromCustomer(Customer: Record Customer; var ConfigTemplHeaderCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        MiniCustomerTemplate: Record "Mini Customer Template";
    begin
        GlobalTemplateName := Customer."No.";
        MiniCustomerTemplate.SaveAsTemplate(Customer);

        ConfigTemplateHeader.SetRange(Description, Customer."No.");
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.FindLast;
        ConfigTemplHeaderCode := ConfigTemplateHeader.Code;
    end;

    local procedure CreateTemplateFromItem(Item: Record Item; var ConfigTemplHeaderCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ItemTemplate: Record "Item Template";
    begin
        GlobalTemplateName := Item."No.";
        ItemTemplate.SaveAsTemplate(Item);

        ConfigTemplateHeader.SetRange(Description, Item."No.");
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateHeader.FindLast;
        ConfigTemplHeaderCode := ConfigTemplateHeader.Code;
    end;

    local procedure CreateTemplateFromVendor(Vendor: Record Vendor; var ConfigTemplHeaderCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        MiniVendorTemplate: Record "Mini Vendor Template";
    begin
        GlobalTemplateName := Vendor."No.";
        MiniVendorTemplate.SaveAsTemplate(Vendor);

        ConfigTemplateHeader.SetRange(Description, Vendor."No.");
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
        ConfigTemplateHeader.FindLast;
        ConfigTemplHeaderCode := ConfigTemplateHeader.Code;
    end;

    local procedure CreateTemplateFromDimension(DefaultDimension: Record "Default Dimension")
    var
        ConfigTemplateHeader: TestPage "Config. Template Header";
    begin
        ConfigTemplateHeader.OpenNew;
        ConfigTemplateHeader.Code.SetValue(DefaultDimension."No.");
        ConfigTemplateHeader."Table ID".SetValue(DATABASE::"Default Dimension");
        ConfigTemplateHeader.Description.SetValue(DefaultDimension."No.");
        ConfigTemplateHeader.OK.Invoke;
    end;

    local procedure CreateBlankCustomerTemplateFromCustomer(var CustomerTemplateCode: Code[10]; var BlankCustomerTemplateCode: Code[10])
    var
        CustomerWithTemplateFieldsSet: Record Customer;
        BlankCustomer: Record Customer;
    begin
        CreateCustomerWithTemplateFieldsSet(CustomerWithTemplateFieldsSet);
        CreateTemplateFromCustomer(CustomerWithTemplateFieldsSet, CustomerTemplateCode);

        CreateBlankCustomer(BlankCustomer);
        CreateTemplateFromCustomer(BlankCustomer, BlankCustomerTemplateCode);
    end;

    local procedure CreateCustTemplateWithDimFromCustomer(): Code[10]
    var
        Customer: Record Customer;
        CustomerTemplateCode: Code[10];
    begin
        CreateCustomerWithDimensions(Customer);
        CreateTemplateFromCustomer(Customer, CustomerTemplateCode);
        exit(CustomerTemplateCode);
    end;

    local procedure CreateVendTemplateWithDimFromVendor(): Code[10]
    var
        Vendor: Record Vendor;
        VendorTemplateCode: Code[10];
    begin
        CreateVendorWithDimensions(Vendor);
        CreateTemplateFromVendor(Vendor, VendorTemplateCode);
        exit(VendorTemplateCode);
    end;

    local procedure CreateItemTemplateWithDimFromItem(): Code[10]
    var
        Item: Record Item;
        ItemTemplateCode: Code[10];
    begin
        CreateItemWithDimensions(Item);
        CreateTemplateFromItem(Item, ItemTemplateCode);
        exit(ItemTemplateCode);
    end;

    local procedure CreateCustTemplateWithGlobDimFromCustomer(var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20]): Code[10]
    var
        Customer: Record Customer;
        CustomerTemplateCode: Code[10];
    begin
        CreateCustomerWithGlobalDimensions(Customer, GlobalDim1ValCode, GlobalDim2ValCode);
        CreateTemplateFromCustomer(Customer, CustomerTemplateCode);
        exit(CustomerTemplateCode);
    end;

    local procedure CreateVendTemplateWithGlobDimFromVendor(var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
        VendorTemplateCode: Code[10];
    begin
        CreateVendorWithGlobalDimensions(Vendor, GlobalDim1ValCode, GlobalDim2ValCode);
        CreateTemplateFromVendor(Vendor, VendorTemplateCode);
        exit(VendorTemplateCode);
    end;

    local procedure CreateItemTemplateWithGlobDimFromItem(var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20]): Code[10]
    var
        Item: Record Item;
        ItemTemplateCode: Code[10];
    begin
        CreateItemWithGlobalDimensions(Item, GlobalDim1ValCode, GlobalDim2ValCode);
        CreateTemplateFromItem(Item, ItemTemplateCode);
        exit(ItemTemplateCode);
    end;

    local procedure EnqueueEnabledTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.SetRange(Enabled, true);
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Count);
        ConfigTemplateHeader.FindSet;
        repeat
            LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Description);
        until ConfigTemplateHeader.Next = 0;
    end;

    local procedure GetDefaultItemNoWithSeries(var ItemNo: Code[20]; var NoSeries: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        NoSeries := InventorySetup."Item Nos.";
        ItemNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate);
    end;

    local procedure GetDefaultCustomerNoWithSeries(var CustomerNo: Code[20]; var NoSeries: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        NoSeries := SalesReceivablesSetup."Customer Nos.";
        CustomerNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate);
    end;

    local procedure GetDefaultVendorNoWithSeries(var VendorNo: Code[20]; var NoSeries: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries := PurchasesPayablesSetup."Vendor Nos.";
        VendorNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate);
    end;

    local procedure OpenCustomerTemplateCard(var CustTemplateCard: TestPage "Cust. Template Card")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
    begin
        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        CustTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;
    end;

    local procedure OpenVendorTemplateCard(var VendorTemplateCard: TestPage "Vendor Template Card")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: TestPage "Config Templates";
    begin
        CreateConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Vendor);
        ConfigTemplates.OpenEdit;
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        VendorTemplateCard.Trap;
        ConfigTemplates."Edit Template".Invoke;
    end;

    local procedure SetTemplateEnabled(ConfigTemplHeaderCode: Code[10]; IsEnabled: Boolean)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.Validate(Enabled, IsEnabled);
        ConfigTemplateHeader.Modify(true);
    end;

    local procedure ValidateCustomerVsBlankTemplate(Customer: Record Customer)
    var
        BlankCustomer: Record Customer;
        ConfigTemplateCode: Code[10];
    begin
        CreateBlankCustomer(BlankCustomer);
        CreateTemplateFromCustomer(BlankCustomer, ConfigTemplateCode);
        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplateCode);
    end;

    local procedure ValidateCustomerVsConfigTemplate(Customer: Record Customer; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Customer);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyCustomerDimensionsVsTemplate(Customer, ConfigTemplHeaderCode);
    end;

    local procedure ValidateCustomerVsConfigTemplateWithEmptyDim(Customer: Record Customer; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Customer);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyEmptyDefaultDimension(DATABASE::Customer, Customer."No.");
    end;

    local procedure ValidateItemVsBlankTemplate(Item: Record Item)
    var
        BlankItem: Record Item;
        ConfigTemplateCode: Code[10];
    begin
        CreateBlankItem(BlankItem);
        CreateTemplateFromItem(BlankItem, ConfigTemplateCode);
        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplateCode);
    end;

    local procedure ValidateItemVsConfigTemplate(Item: Record Item; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Item);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyItemDimensionsVsTemplate(Item, ConfigTemplHeaderCode);
    end;

    local procedure ValidateItemVsConfigTemplateWithEmptyDim(Item: Record Item; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Item);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyEmptyDefaultDimension(DATABASE::Item, Item."No.");
    end;

    local procedure ValidateVendorVsBlankTemplate(Vendor: Record Vendor)
    var
        BlankVendor: Record Vendor;
        ConfigTemplateCode: Code[10];
    begin
        CreateBlankVendor(BlankVendor);
        // Invoice discount code is updated if it is blank in the template. So two "blank" vendors will actually have different discount codes.
        BlankVendor."Invoice Disc. Code" := Vendor."Invoice Disc. Code";
        CreateTemplateFromVendor(BlankVendor, ConfigTemplateCode);
        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplateCode);
    end;

    local procedure ValidateVendorVsConfigTemplate(Vendor: Record Vendor; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Vendor);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyVendorDimensionsVsTemplate(Vendor, ConfigTemplHeaderCode);
    end;

    local procedure ValidateVendorVsConfigTemplateWithEmptyDim(Vendor: Record Vendor; ConfigTemplHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Vendor);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplHeaderCode);
        VerifyEmptyDefaultDimension(DATABASE::Vendor, Vendor."No.");
    end;

    local procedure ValidateCustTemplVsConfigTemplate(var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempMiniCustomerTemplate);
        ValidateRecRefVsConfigTemplate(RecRef, TempMiniCustomerTemplate.Code);
    end;

    local procedure ValidateVendTemplVsConfigTemplate(var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempMiniVendorTemplate);
        ValidateRecRefVsConfigTemplate(RecRef, TempMiniVendorTemplate.Code);
    end;

    local procedure ValidateItemTemplVsConfigTemplate(var TempItemTemplate: Record "Item Template" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempItemTemplate);
        ValidateRecRefVsConfigTemplate(RecRef, TempItemTemplate.Code);
    end;

    local procedure ValidateRecRefVsConfigTemplate(RecRef: RecordRef; TemplateCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
    begin
        with ConfigTemplateLine do begin
            SetRange("Data Template Code", TemplateCode);
            SetRange(Type, Type::Field);
            FindSet;
            repeat
                FieldRef := RecRef.Field("Field ID");
                Assert.AreEqual(
                  Format(FieldRef.Value),
                  "Default Value",
                  StrSubstNo('<%1> field was different than in the template.', FieldRef.Caption));
            until Next = 0;
        end;
    end;

    local procedure ValidateFieldDefinitionsMatch(FieldRef1: FieldRef; FieldRef2: FieldRef)
    begin
        Assert.AreEqual(FieldRef1.Name, FieldRef2.Name, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'names'));
        Assert.AreEqual(FieldRef1.Caption, FieldRef2.Caption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'captions'));
        Assert.IsTrue(FieldRef1.Type = FieldRef2.Type, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'types'));
        Assert.AreEqual(FieldRef1.Length, FieldRef2.Length, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'lengths'));
        Assert.AreEqual(
          FieldRef1.OptionMembers, FieldRef2.OptionMembers, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option string'));
        Assert.AreEqual(
          FieldRef1.OptionCaption, FieldRef2.OptionCaption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option caption'));
        Assert.AreEqual(FieldRef1.Relation, FieldRef2.Relation, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'table relation'));
    end;

    local procedure ValidateThereIsNoTemplate(TemplateCode: Code[20])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        Assert.IsFalse(ConfigTemplateHeader.Get(TemplateCode), 'Config Template Header should not exist');

        ConfigTemplateLine.SetRange("Data Template Code", TemplateCode);
        Assert.IsFalse(ConfigTemplateLine.FindLast, 'There should be no Config Template Lines present');
    end;

    local procedure ReadCustTemplFromConfigTempl(TemplateCode: Code[20]; var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(TemplateCode);
        TempMiniCustomerTemplate.InitializeTempRecordFromConfigTemplate(TempMiniCustomerTemplate, ConfigTemplateHeader);
    end;

    local procedure ReadVendTemplFromConfigTempl(TemplateCode: Code[20]; var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(TemplateCode);
        TempMiniVendorTemplate.InitializeTempRecordFromConfigTemplate(TempMiniVendorTemplate, ConfigTemplateHeader);
    end;

    local procedure ReadItemTemplFromConfigTempl(TemplateCode: Code[20]; var TempItemTemplate: Record "Item Template" temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(TemplateCode);
        TempItemTemplate.InitializeTempRecordFromConfigTemplate(TempItemTemplate, ConfigTemplateHeader);
    end;

    local procedure UpdateCustomerTemplate(ConfigTemplateHeaderCode: Code[10]; var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(ConfigTemplateHeaderCode);
        TempMiniCustomerTemplate.InitializeTempRecordFromConfigTemplate(TempMiniCustomerTemplate, ConfigTemplateHeader);
        TempMiniCustomerTemplate."Credit Limit (LCY)" := LibraryRandom.RandDecInRange(1, 1000, 1);
        TempMiniCustomerTemplate.Modify(true);
    end;

    local procedure UpdateVendorTemplate(ConfigTemplateHeaderCode: Code[10]; var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(ConfigTemplateHeaderCode);
        TempMiniVendorTemplate.InitializeTempRecordFromConfigTemplate(TempMiniVendorTemplate, ConfigTemplateHeader);
        TempMiniVendorTemplate."Prices Including VAT" := not TempMiniVendorTemplate."Prices Including VAT";
        TempMiniVendorTemplate.Modify(true);
    end;

    local procedure UpdateItemTemplate(ConfigTemplateHeaderCode: Code[10]; var TempItemTemplate: Record "Item Template" temporary)
    begin
        ConfigTemplateHeader.Get(ConfigTemplateHeaderCode);
        TempItemTemplate.InitializeTempRecordFromConfigTemplate(TempItemTemplate, ConfigTemplateHeader);
        TempItemTemplate."Allow Invoice Disc." := not TempItemTemplate."Allow Invoice Disc.";
        TempItemTemplate.Modify(true);
    end;

    local procedure DeleteCustTemplateFromConfigTempl(ConfigTemplateCode: Code[10])
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
    begin
        ReadCustTemplFromConfigTempl(ConfigTemplateCode, TempMiniCustomerTemplate);
        TempMiniCustomerTemplate.Delete(true);
    end;

    local procedure DeleteVendTemplateFromConfigTempl(ConfigTemplateCode: Code[10])
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
    begin
        ReadVendTemplFromConfigTempl(ConfigTemplateCode, TempMiniVendorTemplate);
        TempMiniVendorTemplate.Delete(true);
    end;

    local procedure DeleteItemTemplateFromConfigTempl(ConfigTemlateHeaderCode: Code[10])
    var
        TempItemTemplate: Record "Item Template" temporary;
    begin
        ReadItemTemplFromConfigTempl(ConfigTemlateHeaderCode, TempItemTemplate);
        TempItemTemplate.Delete(true);
    end;

    local procedure ErrorMessageForFieldComparison(FieldRef1: FieldRef; FieldRef2: FieldRef; MismatchType: Text): Text
    begin
        exit(
          Format(
            'Field ' +
            MismatchType +
            ' on fields ' +
            FieldRef1.Record.Name + '.' + FieldRef1.Name + ' and ' + FieldRef2.Record.Name + '.' + FieldRef2.Name + ' do not match.'));
    end;

    local procedure ValidateCustCity(CityName: Code[10]; ExpectedPostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
    begin
        TempMiniCustomerTemplate.Insert();
        TempMiniCustomerTemplate.Validate(City, CityName);
        Assert.AreEqual(ExpectedPostCode, TempMiniCustomerTemplate."Post Code", 'Wrong "Post Code"');
        Assert.AreEqual(ExpectedCountryRegionCode, TempMiniCustomerTemplate."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateCustPostCode(ExpectedCityName: Code[10]; PostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
    begin
        TempMiniCustomerTemplate.Insert();
        TempMiniCustomerTemplate.Validate("Post Code", PostCode);
        Assert.AreEqual(ExpectedCityName, TempMiniCustomerTemplate.City, 'Wrong City');
        Assert.AreEqual(ExpectedCountryRegionCode, TempMiniCustomerTemplate."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateVendCity(CityName: Code[10]; ExpectedPostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
    begin
        TempMiniVendorTemplate.Insert();
        TempMiniVendorTemplate.Validate(City, CityName);
        Assert.AreEqual(ExpectedPostCode, TempMiniVendorTemplate."Post Code", 'Wrong "Post Code"');
        Assert.AreEqual(ExpectedCountryRegionCode, TempMiniVendorTemplate."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateVendPostCode(ExpectedCityName: Code[10]; PostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
    begin
        TempMiniVendorTemplate.Insert();
        TempMiniVendorTemplate.Validate("Post Code", PostCode);
        Assert.AreEqual(ExpectedCityName, TempMiniVendorTemplate.City, 'Wrong City');
        Assert.AreEqual(ExpectedCountryRegionCode, TempMiniVendorTemplate."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure DeleteConfigurationTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.DeleteAll(true);
    end;

    local procedure EnsureRecordExistAndGetValue(FieldNo: Integer; TableNo: Integer): Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);

        if not RecordRef.FindFirst then begin
            RecordRef.Init();
            FieldRef := RecordRef.Field(FieldNo);
            FieldRef.Value := LibraryUtility.GenerateRandomCode(FieldNo, TableNo);
            RecordRef.Insert(true);
        end else
            FieldRef := RecordRef.Field(FieldNo);

        exit(FieldRef.Value);
    end;

    local procedure CreateDimension(var Dimension: Record Dimension)
    var
        DimensionValue: Record "Dimension Value";
        NumberOfDimensionValues: Integer;
        I: Integer;
    begin
        Dimension.Init();
        Dimension.Code := LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension);
        Dimension.Insert(true);

        NumberOfDimensionValues := LibraryRandom.RandIntInRange(2, 10);

        for I := 1 to NumberOfDimensionValues do begin
            DimensionValue.Init();
            DimensionValue.Code := LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value");
            DimensionValue."Dimension Code" := Dimension.Code;
            DimensionValue.Insert();
        end;
    end;

    local procedure VerifyDefaultDimensionsTemplateSavedCorrectly(ParentTemplateCode: Code[10]; DimensionCode: Code[20]; DimensionValueCode: Code[20]; ValuePosting: Option)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        TempDimensionsTemplate: Record "Dimensions Template" temporary;
        "Field": Record "Field";
        DimensionConfigTemplateCode: Code[10];
        ValuePostingText: Text;
    begin
        // Dimension Value Code is used to identify Dimension Template since it is part of the primary key
        DimensionConfigTemplateCode := GetDimensionsTemplateCode(ParentTemplateCode, DimensionCode);

        ConfigTemplateLine.SetRange("Data Template Code", DimensionConfigTemplateCode);
        Assert.AreEqual(3, ConfigTemplateLine.Count, 'Not all values were saved as Config Template Line');

        TempDimensionsTemplate.Insert();
        Clear(ConfigTemplateLine);
        ConfigTemplateLine.SetRange("Data Template Code", DimensionConfigTemplateCode);
        ConfigTemplateLine.SetRange("Field ID", TempDimensionsTemplate.FieldNo("Dimension Value Code"));
        ConfigTemplateLine.FindFirst;
        Assert.AreEqual(ConfigTemplateLine."Default Value", DimensionValueCode, 'Value in template does not match saved value');

        Clear(ConfigTemplateLine);
        ConfigTemplateLine.SetRange("Data Template Code", DimensionConfigTemplateCode);
        ConfigTemplateLine.SetRange("Field ID", TempDimensionsTemplate.FieldNo("Value Posting"));
        ConfigTemplateLine.FindFirst;

        Field.Get(DATABASE::"Default Dimension", ConfigTemplateLine."Field ID");
        ValuePostingText := SelectStr(ValuePosting + 1, Field.OptionString);
        Assert.AreEqual(ConfigTemplateLine."Default Value", ValuePostingText, 'Value in template does not match saved value');

        VerifyDefaultDimensionsTemplateRelatedToParentTemplate(ParentTemplateCode, DimensionConfigTemplateCode);
    end;

    local procedure VerifyDefaultDimensionsTemplateRelatedToParentTemplate(ConfigTemplateHeaderCode: Code[10]; DimensionsTemplateHeaderCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeaderCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.SetRange("Template Code", DimensionsTemplateHeaderCode);
        Assert.AreEqual(1, ConfigTemplateLine.Count, 'There should be only one Child Dimensions line found with specified code');
    end;

    local procedure VerifyNumberOfDimensionsTemplateRelatedToMasterTemplate(ConfigTemplateHeaderCode: Code[10]; ExpectedNumberOfTemplates: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeaderCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");

        if ExpectedNumberOfTemplates > 0 then
            Assert.AreEqual(ExpectedNumberOfTemplates, ConfigTemplateLine.Count, 'Wrong number of related templates found')
        else
            Assert.IsFalse(ConfigTemplateLine.FindFirst, 'There shoudl be no templates in the system');
    end;

    local procedure VerifyConfigTemplateHeaderExists(TemplateName: Text[50])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.SetFilter(Description, TemplateName);

        Assert.AreEqual(1, ConfigTemplateHeader.Count, 'There was more than one config template header in the system with given name');
    end;

    local procedure GetDimensionsTemplateCode(ParentTemplateCode: Code[10]; DimensionsCode: Code[20]): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateHeader.SetRange(Description, ParentTemplateCode);
        ConfigTemplateHeader.FindSet;

        repeat
            ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
            ConfigTemplateLine.SetRange("Default Value", DimensionsCode);
            if ConfigTemplateLine.FindFirst then
                exit(ConfigTemplateHeader.Code);
        until ConfigTemplateHeader.Next = 0;

        Error(CouldNotFindDimensionWithCodeErr, DimensionsCode);
    end;

    local procedure AddDefaultDimensionsToRecord(RecordNo: Code[20]; TableID: Integer; NumberOfDimensions: Integer)
    var
        I: Integer;
    begin
        for I := 1 to NumberOfDimensions do
            AddDefaultDimension(RecordNo, TableID);
    end;

    local procedure AddDefaultDimension(RecordNo: Code[20]; TableID: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        CreateDimension(Dimension);
        DefaultDimension.Init();
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."No." := RecordNo;
        DefaultDimension."Dimension Code" := Dimension.Code;

        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindLast;
        DefaultDimension."Dimension Value Code" := DimensionValue.Code;
        DefaultDimension.Insert();
    end;

    local procedure AddGlobalDimension(RecordNo: Code[20]; TableID: Integer; DimNo: Integer) GlobalDimensionValueCode: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionCode: Code[20];
    begin
        DimensionCode := LibraryERM.GetGlobalDimensionCode(DimNo);
        DefaultDimension.Init();
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."No." := RecordNo;
        DefaultDimension."Dimension Code" := DimensionCode;

        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        GlobalDimensionValueCode := DimensionValue.Code;
        DefaultDimension."Dimension Value Code" := DimensionValue.Code;
        DefaultDimension.Insert();
    end;

    local procedure VerifyDimensionsSavedCorrectly(MasterRecordNo: Code[20]; TableID: Integer; ConfigTemplateHeaderCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("No.", MasterRecordNo);
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.FindSet;

        repeat
            VerifyDefaultDimensionsTemplateSavedCorrectly(
              ConfigTemplateHeaderCode, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code",
              DefaultDimension."Value Posting");
        until DefaultDimension.Next = 0;
    end;

    local procedure InsertPostCodeRec(CityName: Code[10]; PostCode: Code[10]; ExpectedRegionCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
    begin
        with PostCodeRec do begin
            SetFilter(City, CityName);
            DeleteAll();
            Reset;
            SetFilter(Code, PostCode);
            DeleteAll();

            Init;
            Code := PostCode;
            City := CityName;
            "Search City" := CityName;
            "Country/Region Code" := ExpectedRegionCode;
            Insert(true);
        end;
    end;

    local procedure IsValueInArray(Haystack: array[2] of Text; Needle: Text): Boolean
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(Haystack) do
            if Needle = Haystack[I] then
                exit(true);

        exit(false);
    end;

    local procedure UpdateCodeOnConfigTempate(OldTemplateCode: Code[10]; NewTemplateCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        ExpectedCount: Integer;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", OldTemplateCode);
        ExpectedCount := ConfigTemplateLine.Count();

        ConfigTemplateHeader.Get(OldTemplateCode);
        ConfigTemplateHeader.Rename(NewTemplateCode);

        ConfigTemplateHeader.Get(NewTemplateCode);

        ConfigTemplateLine.SetRange("Data Template Code", NewTemplateCode);
        Assert.AreEqual(
          ExpectedCount, ConfigTemplateLine.Count, 'Not all lines where transfered to ConfigTemplateLine wile rename Header');
    end;

    local procedure UpdateMarketingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        BusinessRelation: Record "Business Relation";
    begin
        MarketingSetup.Get();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusinessRelation.Code);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusinessRelation.Code);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupCustNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        SalesReceivablesSetup."Customer Nos." := NoSeries.Code;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdatePurchasesPayablesSetupVendNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        PurchasesPayablesSetup."Vendor Nos." := NoSeries.Code;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateInventorySetupItemNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
    begin
        InventorySetup.Get();
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        InventorySetup."Item Nos." := NoSeries.Code;
        InventorySetup.Modify();
    end;

    local procedure UpdateConfigTemplateHeaderNoSeries(ConfigTemplHeaderCode: Code[20]; NoSeriesCode: Code[20])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(ConfigTemplHeaderCode);
        ConfigTemplateHeader.SetNoSeries(NoSeriesCode);
    end;

    local procedure VerifyItemDimensionsVsTemplate(Item: Record Item; ConfigTemplateHeaderCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Item);
        DefaultDimension.SetRange("No.", Item."No.");
        DefaultDimension.FindSet;
        repeat
            VerifyDefaultDimensionsVsTemplate(
              DefaultDimension, GetDimensionsTemplateCode(ConfigTemplateHeaderCode, DefaultDimension."Dimension Code"));
        until DefaultDimension.Next = 0;
    end;

    local procedure VerifyCustomerDimensionsVsTemplate(Customer: Record Customer; ConfigTemplateHeaderCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", Customer."No.");
        DefaultDimension.FindSet;
        repeat
            VerifyDefaultDimensionsVsTemplate(
              DefaultDimension, GetDimensionsTemplateCode(ConfigTemplateHeaderCode, DefaultDimension."Dimension Code"));
        until DefaultDimension.Next = 0;
    end;

    local procedure VerifyVendorDimensionsVsTemplate(Vendor: Record Vendor; ConfigTemplateHeaderCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Vendor);
        DefaultDimension.SetRange("No.", Vendor."No.");
        DefaultDimension.FindSet;
        repeat
            VerifyDefaultDimensionsVsTemplate(
              DefaultDimension, GetDimensionsTemplateCode(ConfigTemplateHeaderCode, DefaultDimension."Dimension Code"));
        until DefaultDimension.Next = 0;
    end;

    local procedure VerifyDefaultDimensionsVsTemplate(DefaultDimension: Record "Default Dimension"; ConfigTemplateHeaderCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DefaultDimension);
        ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplateHeaderCode);
    end;

    local procedure VerifyEmptyDefaultDimension(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        Assert.RecordIsEmpty(DefaultDimension);
    end;

    local procedure VerifyOneCustomerContactDoesExist(CustomerNo: Code[20]; ContactsCount: Integer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        Assert.RecordCount(Contact, ContactsCount + 1);

        MarketingSetup.Get();
        ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        Assert.RecordCount(ContactBusinessRelation, 1);
    end;

    local procedure VerifyOneVendorContactDoesExist(VendorNo: Code[20]; ContactsCount: Integer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        Assert.RecordCount(Contact, ContactsCount + 1);

        MarketingSetup.Get();
        ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", VendorNo);
        Assert.RecordCount(ContactBusinessRelation, 1);
    end;

    local procedure VerifyConfigTemplateLine(DataTemplateCode: Code[10]; TableID: Integer; FieldNumber: Integer; DefaultValue: Text)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        with ConfigTemplateLine do begin
            SetRange("Data Template Code", DataTemplateCode);
            SetRange(Type, Type::Field);
            SetRange("Table ID", TableID);
            SetRange("Field ID", FieldNumber);
            FindFirst;
            TestField("Default Value", DefaultValue);
        end;
    end;

    local procedure VerifyItemNoWithSeries(ItemNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField("No.", ExpectedNo);
        Item.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure VerifyCustomerNoWithSeries(CustomerNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.TestField("No.", ExpectedNo);
        Customer.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure VerifyVendorNoWithSeries(VendorNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.TestField("No.", ExpectedNo);
        Vendor.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure CreateCustomerWithDimensions(var Customer: Record Customer)
    var
        NumberOfDimensions: Integer;
    begin
        CreateCustomerWithTemplateFieldsSet(Customer);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Customer."No.", DATABASE::Customer, NumberOfDimensions);
    end;

    local procedure CreateVendorWithDimensions(var Vendor: Record Vendor)
    var
        NumberOfDimensions: Integer;
    begin
        CreateVendorWithTemplateFieldsSet(Vendor);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Vendor."No.", DATABASE::Vendor, NumberOfDimensions);
    end;

    local procedure CreateItemWithDimensions(var Item: Record Item)
    var
        NumberOfDimensions: Integer;
    begin
        CreateItemWithTemplateFieldsSet(Item);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Item."No.", DATABASE::Item, NumberOfDimensions);
    end;

    local procedure CreateCustomerWithGlobalDimensions(var Customer: Record Customer; var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20])
    begin
        CreateCustomerWithTemplateFieldsSet(Customer);
        GlobalDim1ValCode := AddGlobalDimension(Customer."No.", DATABASE::Customer, 1);
        GlobalDim2ValCode := AddGlobalDimension(Customer."No.", DATABASE::Customer, 2);
    end;

    local procedure CreateVendorWithGlobalDimensions(var Vendor: Record Vendor; var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20])
    begin
        CreateVendorWithTemplateFieldsSet(Vendor);
        GlobalDim1ValCode := AddGlobalDimension(Vendor."No.", DATABASE::Vendor, 1);
        GlobalDim2ValCode := AddGlobalDimension(Vendor."No.", DATABASE::Vendor, 2);
    end;

    local procedure CreateItemWithGlobalDimensions(var Item: Record Item; var GlobalDim1ValCode: Code[20]; var GlobalDim2ValCode: Code[20])
    begin
        CreateItemWithTemplateFieldsSet(Item);
        GlobalDim1ValCode := AddGlobalDimension(Item."No.", DATABASE::Item, 1);
        GlobalDim2ValCode := AddGlobalDimension(Item."No.", DATABASE::Item, 2);
    end;

    local procedure CreateTemplateInLanguage(var TemplateName: Code[10]; var Item: Record Item; LanguageID: Integer)
    var
        CurrentLanguageID: Integer;
    begin
        CurrentLanguageID := GlobalLanguage;
        GlobalLanguage(LanguageID);
        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, TemplateName);
        GlobalLanguage(CurrentLanguageID);
    end;

    local procedure VerifyRecordRefsMatch(RecordRef1: RecordRef; RecordRef2: RecordRef)
    var
        Item: Record Item;
        FieldRef1: FieldRef;
        FieldRef2: FieldRef;
        I: Integer;
    begin
        for I := 2 to RecordRef1.FieldCount do begin
            FieldRef1 := RecordRef1.FieldIndex(I);
            FieldRef2 := RecordRef2.FieldIndex(I);
            if not ((RecordRef1.Number = DATABASE::Item) and (FieldRef1.Number = Item.FieldNo(Id))) then
                if Assert.IsDataTypeSupported(FieldRef1.Value) then
                    Assert.AreEqual(FieldRef1.Value, FieldRef2.Value, StrSubstNo('Field values for field %1 do not match', FieldRef1.Caption));
        end;
    end;

    local procedure GetDifferentLanguageID(): Integer
    var
        DanishLanguageID: Integer;
        EnglishLanguageID: Integer;
    begin
        DanishLanguageID := 1030;
        EnglishLanguageID := 1033;

        if GlobalLanguage <> DanishLanguageID then
            exit(DanishLanguageID);

        exit(EnglishLanguageID);
    end;

    local procedure CreateItemFromTemplateAndCompareWithOriginal(Item: Record Item)
    var
        NewItem: Record Item;
        ItemCard: TestPage "Item Card";
        RecordRef1: RecordRef;
        RecordRef2: RecordRef;
        ItemNo: Code[20];
    begin
        ItemCard.OpenNew;

        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value;
        ItemCard.Close;

        NewItem.Get(ItemNo);
        Item.Description := 'Test';
        Item."Search Description" := 'TEST';
        Item."Last Time Modified" := NewItem."Last Time Modified";
        Item."Last Date Modified" := NewItem."Last Date Modified";
        Item."Last DateTime Modified" := NewItem."Last DateTime Modified";
        Item.Id := NewItem.Id;
        Item.Modify();
        RecordRef1.GetTable(Item);
        RecordRef2.GetTable(NewItem);

        VerifyRecordRefsMatch(RecordRef1, RecordRef2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerConfigTemplatesHandler(var ConfigTemplates: TestPage "Config Templates")
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
        CustTemplateCard: TestPage "Cust. Template Card";
        ActionToInvoke: Variant;
        ExpectedTemplateName: Variant;
        CloseAction: Variant;
        TemplateName: Text[50];
    begin
        LibraryVariableStorage.Dequeue(ActionToInvoke);

        if (Format(ActionToInvoke) = NewActionTok) or (Format(ActionToInvoke) = EditActionTok) then begin
            CustTemplateCard.Trap;

            if Format(ActionToInvoke) = NewActionTok then begin
                ConfigTemplates.NewCustomerTemplate.Invoke;
                Assert.AreEqual('', CustTemplateCard."Template Name".Value, 'Wrong template opened.');
                TemplateName :=
                  LibraryUtility.GenerateRandomCode(MiniCustomerTemplate.FieldNo("Template Name"), DATABASE::"Mini Customer Template");
                CustTemplateCard."Template Name".SetValue(TemplateName);
                CustTemplateCard.City.Activate;
                VerifyConfigTemplateHeaderExists(TemplateName);
            end;

            if Format(ActionToInvoke) = EditActionTok then begin
                ConfigTemplates."Edit Template".Invoke;
                LibraryVariableStorage.Dequeue(ExpectedTemplateName);
                Assert.AreEqual(ExpectedTemplateName, CustTemplateCard."Template Name".Value, 'Wrong template opened.');
            end;

            Assert.IsTrue(CustTemplateCard."Template Name".Editable, 'Template page opened in read-only mode.');
            CustTemplateCard.Close;
        end;

        LibraryVariableStorage.Dequeue(CloseAction);

        if Format(CloseAction) = CancelActionTok then
            ConfigTemplates.Cancel.Invoke;

        if Format(CloseAction) = OKActionTok then
            ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemConfigTemplatesHandler(var ConfigTemplates: TestPage "Config Templates")
    var
        ItemTemplate: Record "Item Template";
        ItemTemplatePage: TestPage "Item Template Card";
        ActionToInvoke: Variant;
        ExpectedTemplateName: Variant;
        CloseAction: Variant;
        TemplateName: Text[50];
    begin
        LibraryVariableStorage.Dequeue(ActionToInvoke);

        if (Format(ActionToInvoke) = NewActionTok) or (Format(ActionToInvoke) = EditActionTok) then begin
            ItemTemplatePage.Trap;

            if Format(ActionToInvoke) = NewActionTok then begin
                ConfigTemplates.NewItemTemplate.Invoke;
                Assert.AreEqual('', ItemTemplatePage."Template Name".Value, 'Wrong template opened.');
                TemplateName :=
                  LibraryUtility.GenerateRandomCode(ItemTemplate.FieldNo("Template Name"), DATABASE::"Item Template");
                ItemTemplatePage."Template Name".SetValue(TemplateName);
                ItemTemplatePage."Base Unit of Measure".Activate;
                VerifyConfigTemplateHeaderExists(TemplateName);
            end;

            if Format(ActionToInvoke) = EditActionTok then begin
                ConfigTemplates."Edit Template".Invoke;
                LibraryVariableStorage.Dequeue(ExpectedTemplateName);
                Assert.AreEqual(ExpectedTemplateName, ItemTemplatePage."Template Name".Value, 'Wrong template opened.');
            end;

            Assert.IsTrue(ItemTemplatePage."Template Name".Editable, 'Template page opened in read-only mode.');
            ItemTemplatePage.Close;
        end;

        LibraryVariableStorage.Dequeue(CloseAction);

        if Format(CloseAction) = CancelActionTok then
            ConfigTemplates.Cancel.Invoke;

        if Format(CloseAction) = OKActionTok then
            ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesSelectionHandler(var ConfigTemplates: TestPage "Config Templates")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ActionNameVariant: Variant;
        TemplateNameVariant: Variant;
        ActionName: Text;
        TemplateName: Text;
    begin
        LibraryVariableStorage.Dequeue(ActionNameVariant);
        LibraryVariableStorage.Dequeue(TemplateNameVariant);

        ActionName := Format(ActionNameVariant);
        TemplateName := Format(TemplateNameVariant);
        if ActionName = Format(TemplateSelectionAction::SelectTemplate) then begin
            ConfigTemplateHeader.Get(TemplateName);
            ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        end else
            if ActionName = Format(TemplateSelectionAction::VerifyDefaultSelection) then begin
                ConfigTemplateHeader.Get(TemplateName);
                ConfigTemplates."Template Name".AssertEquals(ConfigTemplateHeader.Description);
            end;
        ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorTemplateCardHandler(var VendorTemplateCard: TestPage "Vendor Template Card")
    begin
        VendorTemplateCard."Template Name".SetValue(GlobalTemplateName);
        VendorTemplateCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateCardHandler(var CustTemplateCard: TestPage "Cust. Template Card")
    begin
        CustTemplateCard."Template Name".SetValue(GlobalTemplateName);
        CustTemplateCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTemplateCardHandler(var ItemTemplateCard: TestPage "Item Template Card")
    begin
        ItemTemplateCard."Template Name".SetValue(GlobalTemplateName);
        ItemTemplateCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionPageHandler(var ConfigTemplates: TestPage "Config Templates")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateHeader.Get(LibraryVariableStorage.DequeueText);
        ConfigTemplates.GotoRecord(ConfigTemplateHeader);
        ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeModalPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText);
        PostCodes.FILTER.SetFilter(City, LibraryVariableStorage.DequeueText);
        PostCodes.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateListModalPageHandler(var ConfigTemplateList: TestPage "Config. Template List")
    begin
        ConfigTemplateList.FILTER.SetFilter(Code,LibraryVariableStorage.DequeueText);
        ConfigTemplateList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesCountVerificationHandler(var ConfigTemplates: TestPage "Config Templates")
    var
        TemplatesCount: Integer;
        ExpectedTemplatesCount: Integer;
        ConfigTemplateName: array[2] of Text;
        I: Integer;
    begin
        ExpectedTemplatesCount := LibraryVariableStorage.DequeueInteger;
        for I := 1 to ExpectedTemplatesCount do
            ConfigTemplateName[I] := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(ConfigTemplateName[I]));

        ConfigTemplates.First;
        repeat
            TemplatesCount += 1;
            Assert.IsTrue(
              IsValueInArray(
                ConfigTemplateName, ConfigTemplates."Template Name".Value),
              StrSubstNo(UnexpectedTemplateInListErr, ConfigTemplates."Template Name"));
        until not ConfigTemplates.Next;

        Assert.AreEqual(ExpectedTemplatesCount, TemplatesCount, WrongTemplatesCountErr);
    end;
}

