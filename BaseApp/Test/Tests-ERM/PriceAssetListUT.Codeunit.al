codeunit 134122 "Price Asset List UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Asset] [List]
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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure T001_AddAssetItemWithItemDiscount()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();
        // [WHEN] Add "Item" 'I', where "Item Disc. Group" is 'D', at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] Item Discount Group 'D', where Level is 7
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Item Discount Group");
        TempPriceAsset.TestField("Asset No.", ItemDiscountGroup.Code);
        TempPriceAsset.TestField(Level, Level);
        // [THEN] Item 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T002_AddAssetItemWithoutItemDiscount()
    var
        Item: Record Item;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        Item."Item Disc. Group" := '';
        Item.Modify();
        // [WHEN] Add "Item" 'I', where "Item Disc. Group" is <blank>, at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [THEN] GetList returns one record
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 1);
        // [THEN] Item 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T010_AddAssetResourceWithResourceGroup()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateResource(Resource, '');
        Resource."Resource Group No." := ResourceGroup."No.";
        Resource.Modify();
        // [WHEN] Add "Resource" 'R', where "Resource Group No." is 'G', at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Resource, Resource."No.");

        // [THEN] GetList returns three records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 3);
        // [THEN] Resource <blank> (for all resources), where Level is 7
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level + 2);
        // [THEN] Resource Group 'G', where Level is 6
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", ResourceGroup."No.");
        TempPriceAsset.TestField(Level, Level + 1);
        // [THEN] Resource Group 'G', where Level is 6
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", Resource."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T011_AddAssetResourceWithoutResourceGroup()
    var
        Resource: Record Resource;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResource(Resource, '');
        Resource."Resource Group No." := '';
        Resource.Modify();
        // [WHEN] Add "Resource Group" 'R', at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Resource, Resource."No.");

        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] Resource <blank> (for all resources), where Level is 6
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level + 1);
        // [THEN] Resource 'R', where Level is 5
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", Resource."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T020_AddAssetResourceGroup()
    var
        ResourceGroup: Record "Resource Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [WHEN] Add "Resource" 'R', where "Resource Group No." is <blank>, at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::"Resource Group", ResourceGroup."No.");

        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] Resource <blank> (for all resources), where Level is 6
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level + 1);
        // [THEN] Resource Group 'R', where Level is 5
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", ResourceGroup."No.");
        TempPriceAsset.TestField(Level, Level);
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Asset List UT");
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Asset List UT");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Asset List UT");
    end;


}