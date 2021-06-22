codeunit 138008 "Cust/Vend/Item/Empl Templates"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [New Templates]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        IsInitialized: Boolean;
        TemplateFeatureEnabled: Boolean;
        GlobalDimCodeTemplateErr: Label 'Value of template Global Dimension Code is wrong';
        CopyTemplateDataErr: Label 'Data in copied template is wrong';
        CopyTemplateDimensionsErr: Label 'Dimensions in copied template are wrong';
        InsertedVendorErr: Label 'Vendor inserted with wrong data';
        InsertedCustomerErr: Label 'Customer inserted with wrong data';
        InsertedItemErr: Label 'Item inserted with wrong data';
        InsertedEmployeeErr: Label 'Employee inserted with wrong data';

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplValidateTemplateGlobalDimensionCodeUT()
    var
        VendorTempl: Record "Vendor Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        VendorTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        VendorTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        VendorTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Vendor Templ.", VendorTempl.Code, VendorTempl."Global Dimension 1 Code", VendorTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        VendorTempl: Record "Vendor Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Vendor Templ.", VendorTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Vendor Templ.", VendorTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        VendorTempl.Get(VendorTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Vendor Templ.", VendorTempl.Code, VendorTempl."Global Dimension 1 Code", VendorTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCopyTemplateUT()
    var
        SourceVendorTempl: Record "Vendor Templ.";
        DestVendorTempl: Record "Vendor Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(SourceVendorTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateVendorTemplate(DestVendorTempl);

        // [WHEN] Copy "DT" from "ST"
        DestVendorTempl.CopyFromTemplate(SourceVendorTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedVendorTemplateData(DestVendorTempl, SourceVendorTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Vendor Templ.", DestVendorTempl.Code, Database::"Vendor Templ.", SourceVendorTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorOneTemplateUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new vendor with one template
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor inserted with data from "T"
        VerifyVendor(Vendor, VendorTempl);
        // [THEN] Vendor dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VendorTemplListHandler')]
    procedure VendorTemplCreateVendorTwoTemplatesUT()
    var
        Vendor: Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new vendor with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [WHEN] Create new vendor from "T2" (VendorTemplListHandler)
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor filled with data from "T2"
        VerifyVendor(Vendor, VendorTempl2);
        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateBlockedVendorTemplateUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new vendor from template with filled "Blocked"
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = "Payment"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTempl.Blocked := VendorTempl.Blocked::Payment;
        VendorTempl.Modify(true);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor "Blocked" = "Payment"
        Assert.IsTrue(Vendor.Blocked = Vendor.Blocked::Payment, InsertedVendorErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplValidateTemplateGlobalDimensionCodeUT()
    var
        CustomerTempl: Record "Customer Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        CustomerTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        CustomerTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        CustomerTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Customer Templ.", CustomerTempl.Code, CustomerTempl."Global Dimension 1 Code", CustomerTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        CustomerTempl: Record "Customer Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Customer Templ.", CustomerTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Customer Templ.", CustomerTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        CustomerTempl.Get(CustomerTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Customer Templ.", CustomerTempl.Code, CustomerTempl."Global Dimension 1 Code", CustomerTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCopyTemplateUT()
    var
        SourceCustomerTempl: Record "Customer Templ.";
        DestCustomerTempl: Record "Customer Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(SourceCustomerTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateCustomerTemplate(DestCustomerTempl);

        // [WHEN] Copy "DT" from "ST"
        DestCustomerTempl.CopyFromTemplate(SourceCustomerTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedCustomerTemplateData(DestCustomerTempl, SourceCustomerTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Customer Templ.", DestCustomerTempl.Code, Database::"Customer Templ.", SourceCustomerTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerOneTemplateUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new customer with one template
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with data from "T"
        VerifyCustomer(Customer, CustomerTempl);
        // [THEN] Customer dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CustomerTemplListHandler')]
    procedure CustomerTemplCreateCustomerTwoTemplatesUT()
    var
        Customer: Record Customer;
        CustomerTempl1: Record "Customer Templ.";
        CustomerTempl2: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new customer with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl2);
        LibraryVariableStorage.Enqueue(CustomerTempl2.Code);

        // [WHEN] Create new customer from "T2" (CustomerTemplListHandler)
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Vendor filled with data from "T2"
        VerifyCustomer(Customer, CustomerTempl2);
        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateBlockedCustomerTemplateUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new customer from template with filled "Blocked"
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = "All"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustomerTempl.Blocked := CustomerTempl.Blocked::All;
        CustomerTempl.Modify(true);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer "Blocked" = "All"
        Assert.IsTrue(Customer.Blocked = Customer.Blocked::All, InsertedCustomerErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplValidateTemplateGlobalDimensionCodeUT()
    var
        ItemTempl: Record "Item Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        ItemTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        ItemTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        ItemTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Item Templ.", ItemTempl.Code, ItemTempl."Global Dimension 1 Code", ItemTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        ItemTempl: Record "Item Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Item Templ.", ItemTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Item Templ.", ItemTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        ItemTempl.Get(ItemTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Item Templ.", ItemTempl.Code, ItemTempl."Global Dimension 1 Code", ItemTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCopyTemplateUT()
    var
        SourceItemTempl: Record "Item Templ.";
        DestItemTempl: Record "Item Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(SourceItemTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateItemTemplate(DestItemTempl);

        // [WHEN] Copy "DT" from "ST"
        DestItemTempl.CopyFromTemplate(SourceItemTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedItemTemplateData(DestItemTempl, SourceItemTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Item Templ.", DestItemTempl.Code, Database::"Item Templ.", SourceItemTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemOneTemplateUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item with one template
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with data from template
        VerifyItem(Item, ItemTempl);
        // [THEN] Item dimensions inserted from template dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTemplListHandler')]
    procedure ItemTemplCreateItemTwoTemplatesUT()
    var
        Item: Record Item;
        ItemTempl1: Record "Item Templ.";
        ItemTempl2: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl2);
        LibraryVariableStorage.Enqueue(ItemTempl2.Code);

        // [WHEN] Create new Item from "T2" (ItemTemplListHandler)
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item filled with data from "T2"
        VerifyItem(Item, ItemTempl2);
        // [THEN] Item dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateBlockedItemTemplateUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new item from template with filled "Blocked"
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = true, "Sales Blocked" = true, "Purchasing Blocked" = true
        LibraryTemplates.CreateItemTemplate(ItemTempl);
        ItemTempl.Blocked := true;
        ItemTempl."Sales Blocked" := true;
        ItemTempl."Purchasing Blocked" := true;
        ItemTempl.Modify(true);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item "Blocked" = true
        // [THEN] Item "Sales Blocked" = true
        // [THEN] Item "Purchasing Blocked" = true
        Assert.IsTrue(Item.Blocked, InsertedItemErr);
        Assert.IsTrue(Item."Sales Blocked", InsertedItemErr);
        Assert.IsTrue(Item."Purchasing Blocked", InsertedItemErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplValidateTemplateGlobalDimensionCodeUT()
    var
        EmployeeTempl: Record "Employee Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        EmployeeTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        EmployeeTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        EmployeeTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Employee Templ.", EmployeeTempl.Code, EmployeeTempl."Global Dimension 1 Code", EmployeeTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        EmployeeTempl: Record "Employee Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Employee Templ.", EmployeeTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Employee Templ.", EmployeeTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        EmployeeTempl.Get(EmployeeTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Employee Templ.", EmployeeTempl.Code, EmployeeTempl."Global Dimension 1 Code", EmployeeTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCopyTemplateUT()
    var
        SourceEmployeeTempl: Record "Employee Templ.";
        DestEmployeeTempl: Record "Employee Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(SourceEmployeeTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateEmployeeTemplate(DestEmployeeTempl);

        // [WHEN] Copy "DT" from "ST"
        DestEmployeeTempl.CopyFromTemplate(SourceEmployeeTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedEmployeeTemplateData(DestEmployeeTempl, SourceEmployeeTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Employee Templ.", DestEmployeeTempl.Code, Database::"Employee Templ.", SourceEmployeeTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCreateEmployeeOneTemplateUT()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new employee with one template
        Initialize();
        EmployeeTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);

        // [WHEN] Create new employee
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee inserted with data from template
        VerifyEmployee(Employee, EmployeeTempl);
        // [THEN] Employee dimensions inserted from template dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EmployeeTemplListHandler')]
    procedure EmployeeTemplCreateEmployeeTwoTemplatesUT()
    var
        Employee: Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new employee with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [WHEN] Create new employee from "T2" (EmployeeTemplListHandler)
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee filled with data from "T2"
        VerifyEmployee(Employee, EmployeeTempl2);
        // [THEN] Employee dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplatesFeatureKeyUT()
    var
        FeatureKey: Record "Feature Key";
    begin
        // [SCENARIO] Get feature key for new templates
        FeatureKey.Get('NewTemplates');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EmployeeTemplListHandler')]
    procedure EmployeeTemplCreateEmployeeFromContactTwoTemplatesUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Employee: Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Create new employee from person contact with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [GIVEN] Person contact "C"
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create new employee from "C" using "T2" (EmployeeTemplListHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [THEN] Employee filled with data from "C" and "T2"
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No.");
        Employee.Get(ContBusRel."No.");
        Assert.IsTrue(Employee."First Name" = Contact.Name, InsertedEmployeeErr);
        VerifyEmployee(Employee, EmployeeTempl2);

        // [THEN] Employee dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VendorTemplListHandler')]
    procedure VendorTemplCreateVendorFromContactTwoTemplatesUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Vendor: Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Create new vendor from company contact with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        VendorTempl2.Get(VendorTempl2.Code);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [GIVEN] Company contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create new vendor from "C" using "T2" (VendorTemplListHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendor();

        // [THEN] Vendor filled with data from "C" and "T2"
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Vendor, Contact."No.");
        Vendor.Get(ContBusRel."No.");
        Assert.IsTrue(Vendor.Name = Contact.Name, InsertedVendorErr);
        VerifyVendor(Vendor, VendorTempl2);

        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    procedure SetCustTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetVendTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetItemTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetEmplTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    local procedure VerifyTemplateGlobalDimensionIsDefaultDimension(TemplateTableId: Integer; TemplateCode: Code[20]; GlobalDim1CodeValue: Code[20]; GlobalDim2CodeValue: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        DefaultDimension.SetRange("Table ID", TemplateTableId);
        DefaultDimension.SetRange("No.", TemplateCode);

        DefaultDimension.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DefaultDimension.SetRange("Dimension Value Code", GlobalDim1CodeValue);
        Assert.RecordIsNotEmpty(DefaultDimension);

        DefaultDimension.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DefaultDimension.SetRange("Dimension Value Code", GlobalDim2CodeValue);
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    local procedure VerifyTemplateGlobalDimensionCodeValue(TemplateTableId: Integer; TemplateCode: Code[20]; GlobalDim1CodeValue: Code[20]; GlobalDim2CodeValue: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();

        DefaultDimension.Get(TemplateTableId, TemplateCode, GeneralLedgerSetup."Global Dimension 1 Code");
        Assert.AreEqual(DefaultDimension."Dimension Value Code", GlobalDim1CodeValue, GlobalDimCodeTemplateErr);

        DefaultDimension.Get(TemplateTableId, TemplateCode, GeneralLedgerSetup."Global Dimension 2 Code");
        Assert.AreEqual(DefaultDimension."Dimension Value Code", GlobalDim2CodeValue, GlobalDimCodeTemplateErr);
    end;

    local procedure VerifyCopiedVendorTemplateData(DestVendorTempl: Record "Vendor Templ."; SourceVendorTempl: Record "Vendor Templ.")
    begin
        Assert.IsTrue(DestVendorTempl."Vendor Posting Group" = SourceVendorTempl."Vendor Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."Gen. Bus. Posting Group" = SourceVendorTempl."Gen. Bus. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."VAT Bus. Posting Group" = SourceVendorTempl."VAT Bus. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestVendorTempl."Global Dimension 1 Code" = SourceVendorTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."Global Dimension 2 Code" = SourceVendorTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedCustomerTemplateData(DestCustomerTempl: Record "Customer Templ."; SourceCustomerTempl: Record "Customer Templ.")
    begin
        Assert.IsTrue(DestCustomerTempl."Customer Posting Group" = SourceCustomerTempl."Customer Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."Gen. Bus. Posting Group" = SourceCustomerTempl."Gen. Bus. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."VAT Bus. Posting Group" = SourceCustomerTempl."VAT Bus. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestCustomerTempl."Global Dimension 1 Code" = SourceCustomerTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."Global Dimension 2 Code" = SourceCustomerTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedItemTemplateData(DestItemTempl: Record "Item Templ."; SourceItemTempl: Record "Item Templ.")
    begin
        Assert.IsTrue(DestItemTempl."Inventory Posting Group" = SourceItemTempl."Inventory Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."Gen. Prod. Posting Group" = SourceItemTempl."Gen. Prod. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."VAT Prod. Posting Group" = SourceItemTempl."VAT Prod. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestItemTempl."Global Dimension 1 Code" = SourceItemTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."Global Dimension 2 Code" = SourceItemTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedEmployeeTemplateData(DestEmployeeTempl: Record "Employee Templ."; SourceEmployeeTempl: Record "Employee Templ.")
    begin
        Assert.IsTrue(DestEmployeeTempl."Employee Posting Group" = SourceEmployeeTempl."Employee Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestEmployeeTempl."Statistics Group Code" = SourceEmployeeTempl."Statistics Group Code", CopyTemplateDataErr);

        Assert.IsTrue(DestEmployeeTempl."Global Dimension 1 Code" = SourceEmployeeTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestEmployeeTempl."Global Dimension 2 Code" = SourceEmployeeTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyVendor(Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        Assert.IsTrue(Vendor."Vendor Posting Group" = VendorTempl."Vendor Posting Group", InsertedVendorErr);
        Assert.IsTrue(Vendor."Gen. Bus. Posting Group" = VendorTempl."Gen. Bus. Posting Group", InsertedVendorErr);
        Assert.IsTrue(Vendor."VAT Bus. Posting Group" = VendorTempl."VAT Bus. Posting Group", InsertedVendorErr);

        Assert.IsTrue(Vendor."Global Dimension 1 Code" = VendorTempl."Global Dimension 1 Code", InsertedVendorErr);
        Assert.IsTrue(Vendor."Global Dimension 2 Code" = VendorTempl."Global Dimension 2 Code", InsertedVendorErr);
    end;

    local procedure VerifyCustomer(Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        Assert.IsTrue(Customer."Customer Posting Group" = CustomerTempl."Customer Posting Group", InsertedCustomerErr);
        Assert.IsTrue(Customer."Gen. Bus. Posting Group" = CustomerTempl."Gen. Bus. Posting Group", InsertedCustomerErr);
        Assert.IsTrue(Customer."VAT Bus. Posting Group" = CustomerTempl."VAT Bus. Posting Group", InsertedCustomerErr);

        Assert.IsTrue(Customer."Global Dimension 1 Code" = CustomerTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(Customer."Global Dimension 2 Code" = CustomerTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyItem(Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        Assert.IsTrue(Item."Inventory Posting Group" = ItemTempl."Inventory Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."Gen. Prod. Posting Group" = ItemTempl."Gen. Prod. Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."VAT Prod. Posting Group" = ItemTempl."VAT Prod. Posting Group", InsertedItemErr);

        Assert.IsTrue(Item."Global Dimension 1 Code" = ItemTempl."Global Dimension 1 Code", InsertedItemErr);
        Assert.IsTrue(Item."Global Dimension 2 Code" = ItemTempl."Global Dimension 2 Code", InsertedItemErr);

        ItemUnitofMeasure.SetRange(Code, Item."Base Unit of Measure");
        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ItemUnitofMeasure, 1);
    end;

    local procedure VerifyEmployee(Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        Assert.IsTrue(Employee."Employee Posting Group" = EmployeeTempl."Employee Posting Group", InsertedEmployeeErr);
        Assert.IsTrue(Employee."Statistics Group Code" = EmployeeTempl."Statistics Group Code", InsertedEmployeeErr);
    end;

    local procedure VerifyDimensions(DestTableId: Integer; DestNo: Code[20]; SourceTableid: Integer; SourceNo: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", DestTableId);
        DestDefaultDimension.SetRange("No.", DestNo);

        SourceDefaultDimension.SetRange("Table ID", SourceTableid);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        SourceDefaultDimension.FindSet();
        repeat
            DestDefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DestDefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DestDefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    [ModalPageHandler]
    procedure VendorTemplListHandler(var VendorTemplList: TestPage "Vendor Templ. List")
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.Get(LibraryVariableStorage.DequeueText());
        VendorTemplList.GoToRecord(VendorTempl);
        VendorTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerTemplListHandler(var CustomerTemplList: TestPage "Customer Templ. List")
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Get(LibraryVariableStorage.DequeueText());
        CustomerTemplList.GoToRecord(CustomerTempl);
        CustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTemplListHandler(var ItemTemplList: TestPage "Item Templ. List")
    var
        ItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Get(LibraryVariableStorage.DequeueText());
        ItemTemplList.GoToRecord(ItemTempl);
        ItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmployeeTemplListHandler(var EmployeeTemplList: TestPage "Employee Templ. List")
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        EmployeeTempl.Get(LibraryVariableStorage.DequeueText());
        EmployeeTemplList.GoToRecord(EmployeeTempl);
        EmployeeTemplList.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure CustOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure VendOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure ItemOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure EmplOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;
}