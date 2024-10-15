codeunit 134119 "Price Asset UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Asset]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AssetNoMustHaveValueErr: Label 'Product No. must have a value';
        AssetTypeMustBeItemErr: Label 'Product Type must be equal to ''Item''';
        AssetTypeMustBeResourceErr: Label 'Product Type must be equal to ''Resource''';
        IsInitialized: Boolean;

    [Test]
    procedure T020_DescriptionForItem()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Item 'I', where Description is 'X'
        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryRandom.RandText(MaxStrLen(Item.Description));
        Item.Modify();
        // [WHEN] Validate Item "Asset No." as 'I'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, Item.Description);
    end;

    [Test]
    procedure T021_DescriptionForItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Item Variant 'IV', where Description is 'X'
        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryRandom.RandText(MaxStrLen(Item.Description));
        Item.Modify();
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Description := LibraryRandom.RandText(MaxStrLen(ItemVariant.Description));
        ItemVariant.Modify();

        // [WHEN] Validate Item "Asset No." as 'I', "Variant Code" as 'IV'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ItemVariant.Description);
    end;

    [Test]
    procedure T022_DescriptionForResource()
    var
        PriceAsset: Record "Price Asset";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Resource 'R', where Description is 'X'
        LibraryResource.CreateResource(Resource, '');
        Resource.Name := LibraryRandom.RandText(MaxStrLen(Resource.Name));
        Resource.Modify();
        // [WHEN] Validate Resource "Asset No." as 'R'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, Resource.Name);
    end;

    [Test]
    procedure T023_DescriptionForResourceGroup()
    var
        PriceAsset: Record "Price Asset";
        ResourceGroup: Record "Resource Group";
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] ResourceGroup 'RG', where Description is 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        ResourceGroup.Name := LibraryRandom.RandText(MaxStrLen(ResourceGroup.Name));
        ResourceGroup.Modify();
        // [WHEN] Validate ResourceGroup "Asset No." as 'RG'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ResourceGroup.Name);
    end;

    [Test]
    procedure T024_DescriptionForItemDiscountGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Item 'IDG', where Description is 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        ItemDiscountGroup.Description := LibraryRandom.RandText(MaxStrLen(ItemDiscountGroup.Description));
        ItemDiscountGroup.Modify();
        // [WHEN] Validate ItemDiscountGroup "Asset No." as 'IGD'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        PriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ItemDiscountGroup.Description);
    end;

    [Test]
    procedure T025_DescriptionForServiceCost()
    var
        PriceAsset: Record "Price Asset";
        ServiceCost: Record "Service Cost";
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] ServiceCost 'SC', where Description is 'X'
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Description := LibraryRandom.RandText(MaxStrLen(ServiceCost.Description));
        ServiceCost.Modify();
        // [WHEN] Validate ServiceCost "Asset No." as 'SC'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        PriceAsset.Validate("Asset No.", ServiceCost.Code);
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ServiceCost.Description);
    end;

    [Test]
    procedure T026_DescriptionForGLAccount()
    var
        GLAccount: Record "G/L Account";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] GLAccount 'A', where Description is 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := LibraryRandom.RandText(MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
        // [WHEN] Validate GLAccount "Asset No." as 'A'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        PriceAsset.Validate("Asset No.", GLAccount."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, GLAccount.Name);
    end;

    [Test]
    procedure T027_DescriptionBlankOnBlankProduct()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Description]
        Initialize();
        // [GIVEN] Asset, where Item 'I', Description is 'X'
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := LibraryUtility.GenerateGUID();
        PriceAsset.Description := LibraryUtility.GenerateGUID();
        // [WHEN] Validate Item "Asset No." as <blank>
        PriceAsset.Validate("Asset No.", '');
        // [THEN] Asset, where Description is <blank>
        PriceAsset.TestField(Description, '');
    end;

    [Test]
    procedure T030_WorkTypeCodeNotAllowedForItem()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeResourceErr);
    end;

    [Test]
    procedure T031_WorkTypeCodeNotAllowedForGLAccount()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'G/L Account'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'G/L Account' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeResourceErr);
    end;

    [Test]
    procedure T032_WorkTypeCodeNotAllowedForItemDiscountGroup()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item Discount Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item Discount Group' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeResourceErr);
    end;

    [Test]
    procedure T033_WorkTypeCodeNotAllowedForServiceCost()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Service Cost'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Service Cost' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeResourceErr);
    end;

    [Test]
    procedure T034_WorkTypeCodeNotAllowedForResourceGroup()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" canot be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource Group' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeResourceErr);
    end;

    [Test]
    procedure T035_WorkTypeCodeAllowedForResource()
    var
        PriceAsset: Record "Price Asset";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO] "Work Type Code" set for product type 'Resource' updates "Unit Of Measure"
        Initialize();
        // [GIVEN] Resource 'R', where "Base Unit Of Measure" is 'R-UOM' 
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        // [GIVEN] Asset, where "Unit Of Measure" is 'R-UOM' 
        PriceAsset.TestField("Unit of Measure Code", Resource."Base Unit of Measure");

        // [GIVEN] Work Type 'WT', where "Unit Of Measure" is 'WT-UOM' 
        WorkType.Get(GetWorkTypeCode(Resource."No."));

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceAsset.Validate("Work Type Code", WorkType.Code);

        // [THEN] Asset, where 'Work Type Code' is 'WT', "Unit Of Measure" is 'WT-UOM' 
        PriceAsset.TestField("Work Type Code", WorkType.Code);
        PriceAsset.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T040_VariantCodeAllowedForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" can be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item', "Asset No." is 'I' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        LibraryInventory.CreateItem(Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] "Variant Code" is 'V'
        PriceAsset.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure T041_VariantCodeNotAllowedForItemDiscGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Item Discount Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item Discount Group', "Asset No." is 'IDG' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        PriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T042_VariantCodeNotAllowedForGLAccount()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'G/L Account'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'G/L Account', "Asset No." is 'A' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        PriceAsset.Validate("Asset No.", LibraryERM.CreateGLAccountNo());
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T043_VariantCodeNotAllowedForResource()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource', "Asset No." is 'R' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", LibraryResource.CreateResourceNo());
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T044_VariantCodeNotAllowedForResourceGroup()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
        ResourceGroup: Record "Resource Group";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource Group', "Asset No." is 'RG' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T045_VariantCodeNotAllowedForServiceCost()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
        ServiceCost: Record "Service Cost";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Service Cost'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Service Cost', "Asset No." is 'SC' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        LibraryService.CreateServiceCost(ServiceCost);
        PriceAsset.Validate("Asset No.", ServiceCost.Code);
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T046_VariantCodeNoAllowedForBlankItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" cannot be filled for product type 'Item', but blank "Asset No."
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item', "Asset No." is <blank> 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", '');
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Asset No. must have a value.'
        Assert.ExpectedError(AssetNoMustHaveValueErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Asset UT");
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Asset UT");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Asset UT");
    end;


    local procedure GetWorkTypeCode(ResourceNo: Code[20]): Code[10]
    var
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateWorkType(WorkType);
        if ResourceNo <> '' then
            WorkType."Unit of Measure Code" := CreateResourceUOM(ResourceNo);
        exit(WorkType.Code);
    end;

    local procedure CreateResourceUOM(ResourceNo: Code[20]): Code[10]
    var
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(
            ResourceUnitofMeasure, ResourceNo, UnitofMeasure.Code, 2.0);
        exit(UnitofMeasure.Code);
    end;

}