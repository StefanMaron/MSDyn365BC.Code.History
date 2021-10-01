codeunit 137091 "SCM Kitting - D2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        isInitialized := false;
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage;
        StdCostLevel: Integer;
        isInitialized: Boolean;
        ErrorItemIsNotBOM: Label 'Item %1 is not a BOM.';
        ErrorDeleteItem: Label 'You cannot delete Item %1 because there is at least one Assembly Header that includes this item.';
        UpdateOrderLines: Boolean;
        ErrorLineType: Label 'Type must be equal to ''Item''';
        CnfmRefreshLines: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        WorkDate2: Date;

    [Normal]
    local procedure Initialize()
    var
        MfgSetup: Record "Manufacturing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - D2");
        // Initialize setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - D2");

        // Setup Demonstration data.
        isInitialized := true;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        MfgSetup.Get();
        WorkDate2 := CalcDate(MfgSetup."Default Safety Lead Time", WorkDate); // to avoid Due Date Before Work Date message.
        StdCostLevel := 2;
        LibraryAssembly.UpdateAssemblySetup(
          AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header", LibraryUtility.GetGlobalNoSeriesCode);
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - D2");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure RefillDeleteItem()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', false);
        Item.Get(AssemblyHeader."Item No.");

        // Exercise.
        AssemblyHeader.Validate("Item No.", Item."No.");
        AssemblyHeader.Modify(true);
        Commit(); // added as ASSERTERROR rolls back all changes made as yet- and therefore asm header cannot be verified.
        asserterror Item.Delete(true);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", false);
        Assert.AreEqual(StrSubstNo(ErrorDeleteItem, Item."No."), GetLastErrorText, 'Unexpected error message when deleting item.');
        ClearLastError;
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure NegQtyHeaderLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', false);

        // Exercise.
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if AssemblyLine.FindSet then
            repeat
                AssemblyLine.Validate(Quantity, -AssemblyLine.Quantity);
                AssemblyHeader.Modify(true);
            until AssemblyLine.Next = 0;
        Commit(); // added as ASSERTERROR rolls back all changes made as yet- and therefore asm header cannot be verified.
        asserterror AssemblyHeader.Validate(Quantity, -AssemblyHeader.Quantity);
        ClearLastError;

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ItemSubstitutionPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UseSubstitute()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemSubstitution: Record "Item Substitution";
        BOMComponent: Record "BOM Component";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', false);

        BOMComponent.SetRange("Parent Item No.", AssemblyHeader."Item No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindFirst;
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, BOMComponent."No.");

        // Exercise.
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, "BOM Component Type"::Item);
        AssemblyLine.SetRange("No.", BOMComponent."No.");

        if AssemblyLine.FindFirst then
            AssemblyLine.ShowItemSub;

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
        Assert.AreEqual(AssemblyLine."No.", ItemSubstitution."Substitute No.", 'Wrong substitution selected.');
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionPageHandler(var ItemSubstitutionEntries: Page "Item Substitution Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [Normal]
    local procedure UpdateLocation(UpdateLines: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        Location1: Record Location;
    begin
        // Setup.
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, Location.Code,
          AssemblySetup."Copy Component Dimensions from"::"Order Header", LibraryUtility.GetGlobalNoSeriesCode);
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', false);

        // Exercise.
        UpdateOrderLines := UpdateLines;
        VerifyLineLocation(AssemblyHeader."No.", Location.Code);
        LibraryWarehouse.CreateLocation(Location1);
        AssemblyHeader.Validate("Location Code", Location1.Code);
        AssemblyHeader.Modify(true);
        if UpdateOrderLines then
            Location := Location1;

        // Validate.
        VerifyLineLocation(AssemblyHeader."No.", Location.Code);

        // Teardown.
        LibraryAssembly.UpdateAssemblySetup(
          AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header", LibraryUtility.GetGlobalNoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure LineUpdate()
    begin
        UpdateLocation(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure NoLineUpdate()
    begin
        UpdateLocation(false);
    end;

    [Normal]
    local procedure AssemblyListRetrieval(ReplSystem: Enum "Replenishment System"; NoOfItems: Integer; NoOfResources: Integer; NoOfTexts: Integer; NewComps: Integer)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, ReplSystem, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, NoOfItems, NoOfResources, NoOfTexts, 1, '', '');

        // Exercise.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), '');
        LibraryAssembly.CreateAssemblyLines(Item."Costing Method"::Standard, AssemblyHeader."No.", NewComps, NewComps);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", (NewComps > 0));
        VerifyParentFlowFields(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure TwoItemOneRes()
    begin
        AssemblyListRetrieval(Item."Replenishment System"::Assembly, 2, 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextOnly()
    begin
        AssemblyListRetrieval(Item."Replenishment System"::Assembly, 0, 0, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAssemblyList()
    begin
        AssemblyListRetrieval(Item."Replenishment System"::Assembly, 0, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnTheFlyList()
    begin
        AssemblyListRetrieval(Item."Replenishment System"::Assembly, 0, 0, 0, 2);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure PurchItem()
    begin
        AssemblyListRetrieval(Item."Replenishment System"::Purchase, 2, 2, 1, 0);
    end;

    [Normal]
    local procedure CostInfoSync(ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; UpdateComp: Boolean; UpdateParent: Boolean; IndirectCost: Decimal; Overhead: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(
          AssemblyHeader, WorkDate2, ParentCostingMethod, CompCostingMethod, Item."Replenishment System"::Assembly,
          '', true);
        SaveInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");

        // Exercise.
        LibraryAssembly.ModifyItem(AssemblyHeader."Item No.", UpdateParent, IndirectCost, Overhead);
        LibraryAssembly.ModifyCostParams(AssemblyHeader."No.", UpdateComp, IndirectCost, Overhead);
        if UpdateParent then begin
            AssemblyHeader.Validate("Indirect Cost %", IndirectCost);
            AssemblyHeader.Validate("Overhead Rate", Overhead);
            AssemblyHeader.Modify(true);
        end;

        LibraryAssembly.EditAssemblyLines(
          ChangeType::Edit, "BOM Component Type"::Item, "BOM Component Type"::Item, '', AssemblyHeader."No.", true);
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdParentFIFOCompCostAdj()
    begin
        CostInfoSync(Item."Costing Method"::Standard, Item."Costing Method"::FIFO, true, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdParentAvgCompCostAdj()
    begin
        CostInfoSync(Item."Costing Method"::Standard, Item."Costing Method"::Average, true, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdParent()
    begin
        CostInfoSync(Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgParentFIFOCompCostAdj()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::FIFO, true, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCompOverhead()
    begin
        CostInfoSync(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, true, false, 0, LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCompIndCost()
    begin
        CostInfoSync(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, true, false, LibraryRandom.RandDec(10, 2), 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOParentAndCompIndCostOvhd()
    begin
        CostInfoSync(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, true, true, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgParentAndCompOverhead()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::Average, true, true, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgParentAndCompIndCost()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::Average, true, true, LibraryRandom.RandDec(10, 2), 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgUpdateParent()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::FIFO, false, true, 0, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgParentIndCost()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::FIFO, false, true, LibraryRandom.RandDec(10, 2), 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgParentOverhead()
    begin
        CostInfoSync(Item."Costing Method"::Average, Item."Costing Method"::FIFO, false, true, 0, LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOParentAvgComp()
    begin
        CostInfoSync(Item."Costing Method"::FIFO, Item."Costing Method"::Average, false, true, 0, 0);
    end;

    [Normal]
    local procedure ModifyAssemblyLines(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage; CostingMethod: Enum "Costing Method"; ComponentType: Enum "BOM Component Type"; NewComponentType: Enum "BOM Component Type"; UseBaseUnitOfMeasure: Boolean): Code[20]
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        NewComponentNo: Code[20];
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, CostingMethod, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', true);
        SaveInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");
        if NewComponentType = "BOM Component Type"::Item then
            NewComponentNo := LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '')
        else
            NewComponentNo := LibraryAssembly.CreateResource(Resource, true, '');

        // Exercise.
        LibraryAssembly.EditAssemblyLines(ChangeType, ComponentType, NewComponentType, NewComponentNo, AssemblyHeader."No.",
          UseBaseUnitOfMeasure);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
        VerifyInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");
        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure CostModifiedLines(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage; CostingMethod: Enum "Costing Method"; ComponentType: Enum "BOM Component Type"; NewComponentType: Enum "BOM Component Type"; UseBaseUnitOfMeasure: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        Resource: Record Resource;
        TempBOMComponent: Record "BOM Component" temporary;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        NewComponentNo: Code[20];
    begin
        // Setup.
        Initialize;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order,
          ModifyAssemblyLines(ChangeType, CostingMethod, ComponentType, NewComponentType, UseBaseUnitOfMeasure));
        if NewComponentType = "BOM Component Type"::Item then
            NewComponentNo := LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '')
        else
            NewComponentNo := LibraryAssembly.CreateResource(Resource, true, '');

        if ChangeType <> ChangeType::" " then begin
            StdCostLevel := 2;
            CalculateStandardCost.CalcItem(AssemblyHeader."Item No.", true);
        end;

        LibraryAssembly.EditAssemblyList(ChangeType, ComponentType, NewComponentType, NewComponentNo, AssemblyHeader."Item No.");
        SaveInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");

        // Exercise.
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ItemQtyPer()
    begin
        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::" ", true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ResQtyPer()
    begin
        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure UnitOfMeasure()
    begin
        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::" ", false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ReplaceItemWRes()
    begin
        ModifyAssemblyLines(
          ChangeType::Replace, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ReplaceItemWItem()
    begin
        ModifyAssemblyLines(
          ChangeType::Replace, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AddItem()
    begin
        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AddDirectRes()
    begin
        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AddFixedRes()
    begin
        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure DeleteItem()
    begin
        ModifyAssemblyLines(
          ChangeType::Delete, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure DeleteRes()
    begin
        ModifyAssemblyLines(
          ChangeType::Delete, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure DeleteAll()
    begin
        ModifyAssemblyLines(
          ChangeType::"Delete all", Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure Usage()
    begin
        ModifyAssemblyLines(
          ChangeType::Usage, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostItemQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostResQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostUnitOfMeasure()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostReplaceItemWItem()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostReplaceItemWRes()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostAddItem()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostAddDirectRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostAddFixedRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostDeleteItem()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostDeleteRes()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostDeleteAll()
    begin
        CostModifiedLines(
          ChangeType::"Delete all", Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure CostUsage()
    begin
        CostModifiedLines(
          ChangeType::Usage, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostItemQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostResQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostUnitOfMeasure()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostReplaceItemWItem()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostReplaceItemWRes()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostAddItem()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostAddDirectRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostAddFixedRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostDeleteItem()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostDeleteRes()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostDeleteAll()
    begin
        CostModifiedLines(
          ChangeType::"Delete all", Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostUsage()
    begin
        CostModifiedLines(
          ChangeType::Usage, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostItemQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostResQtyPer()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostUnitOfMeasure()
    begin
        CostModifiedLines(
          ChangeType::Edit, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostReplaceItemWItem()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostReplaceItemWRes()
    begin
        CostModifiedLines(
          ChangeType::Replace, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostAddItem()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostAddDirectRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostAddFixedRes()
    begin
        CostModifiedLines(
          ChangeType::Add, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostDeleteItem()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostDeleteRes()
    begin
        CostModifiedLines(
          ChangeType::Delete, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostDeleteAll()
    begin
        CostModifiedLines(
          ChangeType::"Delete all", Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FIFOCostUsage()
    begin
        CostModifiedLines(
          ChangeType::Usage, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false);
    end;

    [Normal]
    local procedure ModifyAssemblyHeader(CostingMethod: Enum "Costing Method"; SignFactor: Integer; BaseUoM: Boolean): Code[20]
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, CostingMethod, CostingMethod,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.CreateItem(Item, CostingMethod, Item."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateResource(Resource, true, '');
        LibraryAssembly.EditAssemblyLines(
          ChangeType::Add, "BOM Component Type"::Item, "BOM Component Type"::Item, Item."No.", AssemblyHeader."No.", true);
        LibraryAssembly.EditAssemblyLines(
          ChangeType::Add, "BOM Component Type"::Resource, "BOM Component Type"::Resource, Resource."No.",
          AssemblyHeader."No.", true);

        // Exercise.
        AssemblyHeader.Validate(Quantity, SignFactor * (AssemblyHeader.Quantity + LibraryRandom.RandDec(10, 2)));
        AssemblyHeader.Modify(true);
        AssemblyHeader.Validate(
          "Unit of Measure Code", LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, AssemblyHeader."Item No.", BaseUoM));
        AssemblyHeader.Modify(true);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure CostModifiedHeader(CostingMethod: Enum "Costing Method"; SignFactor: Integer; BaseUoM: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup.
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order,
          ModifyAssemblyHeader(CostingMethod, SignFactor, BaseUoM));

        // Exercise.
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderHeader(AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure IncreaseQty()
    begin
        ModifyAssemblyHeader(Item."Costing Method"::Standard, 1, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure ZeroQty()
    begin
        ModifyAssemblyHeader(Item."Costing Method"::Standard, 0, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdCostIncQty()
    begin
        CostModifiedHeader(Item."Costing Method"::Standard, 1, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdCostZeroQty()
    begin
        CostModifiedHeader(Item."Costing Method"::Standard, 0, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure NonBaseUoM()
    begin
        ModifyAssemblyHeader(Item."Costing Method"::Standard, 1, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdCostNonBaseUoM()
    begin
        CostModifiedHeader(Item."Costing Method"::Standard, 1, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostIncQty()
    begin
        CostModifiedHeader(Item."Costing Method"::Average, 1, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostZeroQty()
    begin
        CostModifiedHeader(Item."Costing Method"::Average, 0, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgCostNonBaseUoM()
    begin
        CostModifiedHeader(Item."Costing Method"::Average, 1, false);
    end;

    [Normal]
    local procedure RefreshOrder(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage; CostingMethod: Enum "Costing Method"; ComponentType: Enum "BOM Component Type"; NewComponentType: Enum "BOM Component Type"; UseBaseUnitOfMeasure: Boolean; UpdateAssemblyList: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order,
          ModifyAssemblyLines(ChangeType, CostingMethod, ComponentType, NewComponentType, UseBaseUnitOfMeasure));

        if ChangeType <> ChangeType::" " then begin
            StdCostLevel := 2;
            CalculateStandardCost.CalcItem(AssemblyHeader."Item No.", true);
        end;

        if UpdateAssemblyList then
            LibraryAssembly.EditAssemblyList(ChangeType, ComponentType, NewComponentType, '',
              AssemblyHeader."Item No.");
        SaveInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");

        // Exercise.
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);
        AssemblyHeader.RefreshBOM;
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", false);
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, AssemblyHeader."Item No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure SimpleRefresh()
    begin
        RefreshOrder(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false, false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure StdChangeAssemblyList()
    begin
        RefreshOrder(
          ChangeType::Edit, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, false, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure AvgChangeAssemblyList()
    begin
        RefreshOrder(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, false, true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure RefreshAfterDeleteAll()
    begin
        RefreshOrder(
          ChangeType::"Delete all", Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true);
    end;

    [Normal]
    local procedure MultipleLvlRollup(CostingMethod: Enum "Costing Method"; Rollup: Boolean; Level: Integer)
    var
        Item: Record Item;
        Item1: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateMultipleLvlTree(Item, Item1, Item."Replenishment System"::Assembly, CostingMethod, 1, 2);
        if Level > 1 then
            Item := Item1;

        if ChangeType <> ChangeType::" " then begin
            StdCostLevel := 2;
            CalculateStandardCost.CalcItem(Item."No.", true);
        end;

        LibraryAssembly.EditAssemblyList(ChangeType::Edit, "BOM Component Type"::Item, "BOM Component Type"::Item, '', Item."No.");
        SaveInitialAssemblyList(TempBOMComponent, Item."No.");
        if Rollup then begin
            StdCostLevel := Level;
            CalculateStandardCost.CalcItem(Item."No.", true);
            CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        end;
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", false);
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, Item."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdTwoLevelsNoRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Standard, false, 2);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdOneLevelNoRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Standard, false, 1);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdOneLevelRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Standard, true, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure StdTwoLevelsRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Standard, true, 2);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgTwoLevelsNoRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Average, false, 2);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgOneLevelNoRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Average, false, 1);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgOneLevelRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Average, true, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AvgTwoLevelsRollup()
    begin
        MultipleLvlRollup(Item."Costing Method"::Average, true, 2);
    end;

    [Normal]
    local procedure KitExplosion(TreeDepth: Integer)
    var
        Item: Record Item;
        Item1: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateMultipleLvlTree(
          Item, Item1, Item."Replenishment System"::Assembly, Item."Costing Method"::Standard, TreeDepth, 2
          );
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item1."No.", '', LibraryRandom.RandDec(10, 2), '');
        SaveInitialAssemblyList(TempBOMComponent, Item1."No.");

        // Exercise.
        TempAssemblyLine.DeleteAll();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, "BOM Component Type"::Item);
        if AssemblyLine.FindSet then
            repeat
                Item.Get(AssemblyLine."No.");
                if Item."Assembly BOM" then begin
                    AssemblyLine.ExplodeAssemblyList;
                    TempAssemblyLine := AssemblyLine;
                    TempAssemblyLine.Insert();
                end;
            until AssemblyLine.Next = 0;

        // Validate.
        VerifyExplodedLines(TempAssemblyLine, AssemblyHeader."No.");

        // Exercise
        AssemblyHeader.RefreshBOM;

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", false);
        VerifyInitialAssemblyList(TempBOMComponent, Item1."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure OneLevel()
    begin
        KitExplosion(1);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure TwoLevels()
    begin
        KitExplosion(2);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure FakeExplode()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', true);

        // Exercise.
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, "BOM Component Type"::Item);
        if AssemblyLine.FindSet then
            repeat
                asserterror AssemblyLine.ExplodeAssemblyList;
                // Validate.
                if AssemblyLine.Type = "BOM Component Type"::Item then
                    Assert.AreEqual(
                      StrSubstNo(ErrorItemIsNotBOM, AssemblyLine."No."), GetLastErrorText, 'Wrong BOM explosion message.')
                else
                    Assert.IsTrue(StrPos(GetLastErrorText, ErrorLineType) > 0, 'Actual:' + GetLastErrorText + '; Expected:' + ErrorLineType);
                ClearLastError;
            until AssemblyLine.Next = 0;
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesExplode()
    var
        Item: Record Item;
        Item1: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempBOMComponent: Record "BOM Component" temporary;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesExplodeBOM: Codeunit "Sales-Explode BOM";
    begin
        // Setup.
        Initialize;
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
        LibraryAssembly.CreateMultipleLvlTree(Item, Item1, Item."Replenishment System"::Assembly, Item."Costing Method"::Standard, 1, 2);
        SaveInitialAssemblyList(TempBOMComponent, Item1."No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item1."No.", LibraryRandom.RandDec(5, 2));
        TempSalesLine.DeleteAll();
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();

        // Exercise.
        SalesExplodeBOM.Run(SalesLine);

        // Validate.
        VerifyExplodedSalesLines(TempBOMComponent, SalesHeader, TempSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFakeExplode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine1: Record "Sales Line";
        SalesExplodeBOM: Codeunit "Sales-Explode BOM";
    begin
        // Setup.
        Initialize;
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo, 1);

        // Exercise.
        asserterror SalesExplodeBOM.Run(SalesLine);

        // Validate.
        Assert.AreEqual(StrSubstNo(ErrorItemIsNotBOM, SalesLine."No."), GetLastErrorText, 'Unexpected message for BOM explosion.');
        ClearLastError;

        // Exercise.
        asserterror SalesExplodeBOM.Run(SalesLine1);

        // Validate.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorLineType) > 0, 'Actual:' + GetLastErrorText + '; Expected:' + ErrorLineType);
        ClearLastError;
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchExplode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempBOMComponent: Record "BOM Component" temporary;
        PurchExplodeBOM: Codeunit "Purch.-Explode BOM";
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 2, 0, 0, 1, '', '');
        SaveInitialAssemblyList(TempBOMComponent, Item."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));
        TempPurchaseLine.DeleteAll();
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // Exercise.
        PurchExplodeBOM.Run(PurchaseLine);

        // Validate.
        VerifyExplodedPurchLines(TempBOMComponent, PurchaseHeader, TempPurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFakeExplode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine1: Record "Purchase Line";
        PurchExplodeBOM: Codeunit "Purch.-Explode BOM";
    begin
        // Setup.
        Initialize;
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine1, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo, 1);

        // Exercise.
        asserterror PurchExplodeBOM.Run(PurchaseLine);

        // Validate.
        Assert.AreEqual(StrSubstNo(ErrorItemIsNotBOM, PurchaseLine."No."), GetLastErrorText, 'Actual:' + GetLastErrorText);

        // Exercise.
        ClearLastError;
        asserterror PurchExplodeBOM.Run(PurchaseLine1);

        // Validate.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorLineType) > 0, 'Actual:' + GetLastErrorText + '; Expected:' + ErrorLineType);
        ClearLastError;
    end;

    [Normal]
    [HandlerFunctions('AvailabilityWindowHandler')]
    local procedure ResUsage(CostingMethod: Enum "Costing Method"; UseSameRes: Boolean; LotSize: Integer)
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateItem(Item, CostingMethod, Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
        LibraryAssembly.CreateResource(Resource, true, '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, LibraryRandom.RandDec(20, 2), true);
        if not UseSameRes then
            LibraryAssembly.CreateResource(Resource, true, '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Fixed, 20 + LibraryRandom.RandDec(20, 2), true);
        SaveInitialAssemblyList(TempBOMComponent, Item."No.");
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", false);
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotSize()
    begin
        ResUsage(Item."Costing Method"::Standard, false, LibraryRandom.RandInt(25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoLotSize()
    begin
        ResUsage(Item."Costing Method"::Standard, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonStdCostLotSize()
    begin
        ResUsage(Item."Costing Method"::Average, false, LibraryRandom.RandInt(25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonStdCostNoLotSize()
    begin
        ResUsage(Item."Costing Method"::Average, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResLotSize()
    begin
        ResUsage(Item."Costing Method"::Standard, true, LibraryRandom.RandInt(25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamesResNoLotSize()
    begin
        ResUsage(Item."Costing Method"::Standard, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResNonStdCostLotSize()
    begin
        ResUsage(Item."Costing Method"::Average, true, LibraryRandom.RandInt(25));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResNonStdCostNoLotSize()
    begin
        ResUsage(Item."Costing Method"::Average, true, 0);
    end;

    [Normal]
    local procedure SameComp(UseVariant: Boolean)
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        TempBOMComponent: Record "BOM Component" temporary;
        Item1: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize;
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(Item1, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateResource(Resource, true, '');

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, LibraryRandom.RandDec(20, 2), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, 20 + LibraryRandom.RandDec(20, 2), true);

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, LibraryRandom.RandDec(20, 2), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, 20 + LibraryRandom.RandDec(20, 2), true);
        SaveInitialAssemblyList(TempBOMComponent, Item."No.");
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item1."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, Item1."No.", true), 40 + LibraryRandom.RandDec(20, 2), 0, '');
        if UseVariant then
            AssemblyLine.Validate("Variant Code", LibraryInventory.GetVariant(Item1."No.", AssemblyLine."Variant Code"));
        AssemblyLine.Modify(true);
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Resource, Resource."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Resource, Resource."No.", true),
          40 + LibraryRandom.RandDec(20, 2), 0, '');
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
        VerifyOrderHeader(AssemblyHeader."No.");
        VerifyInitialAssemblyList(TempBOMComponent, Item."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SameItem()
    begin
        SameComp(false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SameItemDiffVar()
    begin
        SameComp(true);
    end;

    [Normal]
    local procedure CircularRef(IsDirectLoop: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize;
        StdCostLevel := 1;
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, AssemblyHeader."Item No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, 1, true);
        if IsDirectLoop then
            ItemNo := AssemblyHeader."Item No."
        else
            ItemNo := Item."No.";

        // Exercise.
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemNo,
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, AssemblyHeader."Item No.", true), 1, 0, '');
        LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Validate.
        VerifyOrderLines(AssemblyHeader."No.", true);
        VerifyOrderHeader(AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure DirectLoop()
    begin
        CircularRef(true);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure IndirectLoop()
    begin
        CircularRef(false);
    end;

    [Normal]
    local procedure VerifyOrderLines(AssemblyHeaderNo: Code[20]; CustomLines: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeaderNo);
        AssemblyLine.SetFilter(Type, '<>%1', "BOM Component Type"::" ");
        if AssemblyLine.FindSet then
            repeat
                BOMComponent.SetRange("Parent Item No.", AssemblyHeader."Item No.");
                BOMComponent.SetRange(Type, AssemblyLine.Type);
                BOMComponent.SetRange("No.", AssemblyLine."No.");
                BOMComponent.SetRange("Variant Code", AssemblyLine."Variant Code");
                BOMComponent.SetRange("Quantity per", AssemblyLine."Quantity per");
                BOMComponent.SetRange("Unit of Measure Code", AssemblyLine."Unit of Measure Code");
                // Bug 219898.
                // BOMComponent.SETRANGE("Resource Usage Type",AssemblyLine."Resource Usage Type");
                if not CustomLines then
                    Assert.AreEqual(1, BOMComponent.Count, 'Asm. line for ' + AssemblyLine."No." + ' not found.');
                VerifyOrderLine(AssemblyLine);
            until AssemblyLine.Next = 0;

        if not CustomLines then begin
            BOMComponent.Reset();
            BOMComponent.SetRange("Parent Item No.", AssemblyHeader."Item No.");
            BOMComponent.SetFilter(Type, '<>%1', BOMComponent.Type::" ");
            Assert.AreEqual(AssemblyLine.Count, BOMComponent.Count, 'Wrong no. of retrieved lines.');
        end;

        if AssemblyHeader.Quantity = 0 then
            Assert.AreEqual(0, AssemblyLine.Count, 'No. of lines should be 0 for Qty 0.');
    end;

    [Normal]
    local procedure VerifyOrderLine(AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
        OrderQty: Decimal;
        UnitCost: Decimal;
        Overhead: Decimal;
        IndirectCost: Decimal;
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyLine."Document No.");
        if AssemblyLine.Type = "BOM Component Type"::" " then
            exit;
        if (AssemblyLine.Type = "BOM Component Type"::Resource) and
           (AssemblyHeader.Quantity > 0) and (AssemblyLine."Resource Usage Type" = AssemblyLine."Resource Usage Type"::Fixed)
        then
            OrderQty := 1
        else
            OrderQty := AssemblyHeader.Quantity;

        Assert.AreEqual(
          Round(OrderQty * AssemblyLine."Quantity per", LibraryERM.GetAmountRoundingPrecision),
          Round(AssemblyLine.Quantity, LibraryERM.GetAmountRoundingPrecision), 'Wrong Quantity on Line.');
        Assert.AreEqual(
          Round(AssemblyLine.Quantity * AssemblyLine."Qty. per Unit of Measure", LibraryERM.GetUnitAmountRoundingPrecision),
          Round(AssemblyLine."Quantity (Base)", LibraryERM.GetUnitAmountRoundingPrecision), 'Wrong Base Qty calculation.');
        Assert.AreEqual(AssemblyLine.Quantity, AssemblyLine."Remaining Quantity", 'Wrong Remaining Qty.');
        Assert.AreEqual(AssemblyLine."Quantity (Base)", AssemblyLine."Remaining Quantity (Base)", 'Wrong Remaining Qty (Base).');

        LibraryAssembly.GetCostInformation(UnitCost, Overhead, IndirectCost, AssemblyLine.Type, AssemblyLine."No.", '', '');
        Assert.AreNearlyEqual(Round(UnitCost, LibraryERM.GetUnitAmountRoundingPrecision),
          Round(AssemblyLine."Unit Cost" / AssemblyLine."Qty. per Unit of Measure", LibraryERM.GetUnitAmountRoundingPrecision),
          LibraryERM.GetAmountRoundingPrecision, 'Wrong line Unit Cost.');
        Assert.AreEqual(
          Round(AssemblyLine."Unit Cost" * AssemblyLine.Quantity, LibraryERM.GetAmountRoundingPrecision),
          AssemblyLine."Cost Amount", 'Wrong line Cost Amount.');
    end;

    [Normal]
    local procedure VerifyParentFlowFields(AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
    begin
        Item.Get(AssemblyHeader."Item No.");
        Item.CalcFields("Qty. on Assembly Order", "Qty. on Asm. Component");
        Assert.AreNearlyEqual(
          AssemblyHeader.Quantity * AssemblyHeader."Qty. per Unit of Measure", Item."Qty. on Assembly Order",
          LibraryERM.GetUnitAmountRoundingPrecision, 'Wrong qty on assembly order - header.');
        Assert.AreEqual(0, Item."Qty. on Asm. Component", 'Wrong qty on component lines - header.');
    end;

    [Normal]
    local procedure VerifyExplodedLines(TempAssemblyLine: Record "Assembly Line" temporary; AssemblyHeaderNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempBOMComponent: Record "BOM Component" temporary;
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        LibraryAssembly.GetBOMComponentLines(TempBOMComponent, AssemblyHeader."Item No.");
        if AssemblyLine.FindSet then
            repeat
                TempBOMComponent.SetRange("Parent Item No.", AssemblyHeader."Item No.");
                TempBOMComponent.SetRange(Type, AssemblyLine.Type);
                TempBOMComponent.SetRange("No.", AssemblyLine."No.");
                TempBOMComponent.SetRange("Variant Code", AssemblyLine."Variant Code");
                TempBOMComponent.SetRange("Unit of Measure Code", AssemblyLine."Unit of Measure Code");
                // TempBOMComponent.SETRANGE("Resource Usage Type",AssemblyLine."Resource Usage Type");
                TempBOMComponent.FindFirst;
                Assert.AreEqual(1, TempBOMComponent.Count, 'Too many order lines exploded.');
                TempAssemblyLine.SetRange(Type, "BOM Component Type"::Item);
                TempAssemblyLine.SetRange("No.", TempBOMComponent."Parent Item No.");
                if TempAssemblyLine.FindFirst then
                    Assert.AreNearlyEqual(TempAssemblyLine."Quantity per" * TempBOMComponent."Quantity per", AssemblyLine."Quantity per",
                      LibraryERM.GetAmountRoundingPrecision, 'Wrong qty per in exploded line for ' + TempAssemblyLine."No.");
                VerifyOrderLine(AssemblyLine);
            until AssemblyLine.Next = 0
    end;

    [Normal]
    local procedure VerifyExplodedSalesLines(var TempBOMComponent: Record "BOM Component" temporary; SalesHeader: Record "Sales Header"; TempSalesLine: Record "Sales Line" temporary)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindSet();
        TempBOMComponent.FindSet();

        repeat
            TempBOMComponent.SetRange("Parent Item No.", TempSalesLine."No.");
            TempBOMComponent.SetRange("No.", SalesLine."No.");
            TempBOMComponent.SetRange("Variant Code", SalesLine."Variant Code");
            TempBOMComponent.SetRange("Unit of Measure Code", SalesLine."Unit of Measure Code");
            Assert.AreEqual(1, TempBOMComponent.Count, 'Too many order lines exploded.');
            TempBOMComponent.FindFirst;
            Assert.AreNearlyEqual(TempBOMComponent."Quantity per" * TempSalesLine.Quantity, SalesLine.Quantity,
              LibraryERM.GetAmountRoundingPrecision, 'Wrong qty in exploded line for ' + SalesLine."No.");
            TempBOMComponent.Delete(true);
        until SalesLine.Next = 0;

        TempBOMComponent.Reset();
        TempBOMComponent.SetRange(Type, TempBOMComponent.Type::Item);
        Assert.AreEqual(0, TempBOMComponent.Count, 'Not all lines were exploded.');
    end;

    [Normal]
    local procedure VerifyExplodedPurchLines(var TempBOMComponent: Record "BOM Component" temporary; PurchaseHeader: Record "Purchase Header"; TempPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.FindSet();
        TempBOMComponent.FindSet();

        repeat
            TempBOMComponent.SetRange("Parent Item No.", TempPurchaseLine."No.");
            TempBOMComponent.SetRange("No.", PurchaseLine."No.");
            TempBOMComponent.SetRange("Variant Code", PurchaseLine."Variant Code");
            TempBOMComponent.SetRange("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
            Assert.AreEqual(1, TempBOMComponent.Count, 'Too many order lines exploded.');
            TempBOMComponent.FindFirst;
            Assert.AreNearlyEqual(TempBOMComponent."Quantity per" * TempPurchaseLine.Quantity, PurchaseLine.Quantity,
              LibraryERM.GetAmountRoundingPrecision, 'Wrong qty in exploded line for ' + PurchaseLine."No.");
            TempBOMComponent.Delete(true);
        until PurchaseLine.Next = 0;

        TempBOMComponent.Reset();
        TempBOMComponent.SetRange(Type, TempBOMComponent.Type::Item);
        Assert.AreEqual(0, TempBOMComponent.Count, 'Not all lines were exploded.');
    end;

    [Normal]
    local procedure VerifyOrderHeader(AssemblyHeaderNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        MaterialCost: Decimal;
        ResourceCost: Decimal;
        ResourceOvhd: Decimal;
        CostAmount: Decimal;
        AssemblyOvhd: Decimal;
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);
        CostAmount := LibraryAssembly.CalcOrderCostAmount(MaterialCost, ResourceCost, ResourceOvhd, AssemblyOvhd, AssemblyHeaderNo);

        Assert.AreNearlyEqual(
          CostAmount, AssemblyHeader."Cost Amount", LibraryERM.GetAmountRoundingPrecision, 'Wrong header cost amount.');
        Assert.AreNearlyEqual(CostAmount,
          Round(AssemblyHeader.Quantity * AssemblyHeader."Unit Cost", LibraryERM.GetAmountRoundingPrecision),
          LibraryERM.GetAmountRoundingPrecision, 'Wrong header unit cost.');
    end;

    [Normal]
    local procedure SaveInitialAssemblyList(var TempBOMComponent: Record "BOM Component" temporary; ParentItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        Commit();
        TempBOMComponent.DeleteAll();
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        if BOMComponent.FindSet then
            repeat
                TempBOMComponent := BOMComponent;
                TempBOMComponent.Insert();
            until BOMComponent.Next = 0;
    end;

    [Normal]
    local procedure VerifyInitialAssemblyList(var TempBOMComponent: Record "BOM Component" temporary; ParentItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        if TempBOMComponent.FindSet then
            Assert.AreEqual(TempBOMComponent.Count, BOMComponent.Count, 'Assembly list was altered!');
        if BOMComponent.FindSet then
            repeat
                TempBOMComponent.SetRange("Parent Item No.", BOMComponent."Parent Item No.");
                TempBOMComponent.SetRange("Line No.", BOMComponent."Line No.");
                TempBOMComponent.SetRange(Type, BOMComponent.Type);
                TempBOMComponent.SetRange("No.", BOMComponent."No.");
                TempBOMComponent.SetRange("Quantity per", BOMComponent."Quantity per");
                TempBOMComponent.SetRange("Unit of Measure Code", BOMComponent."Unit of Measure Code");
                TempBOMComponent.SetRange("Variant Code", BOMComponent."Variant Code");
                Assert.AreEqual(1, TempBOMComponent.Count, 'Assembly list was altered at comp.' + BOMComponent."No." + '!');
            until BOMComponent.Next = 0;
    end;

    [Normal]
    local procedure VerifyLineLocation(AssemblyHeaderNo: Code[20]; LocationCode: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeaderNo);
        AssemblyLine.SetRange(Type, "BOM Component Type"::Item);
        if AssemblyLine.FindSet then
            repeat
                Assert.AreEqual(LocationCode, AssemblyLine."Location Code", 'Wrong location code on line.');
            until AssemblyLine.Next = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := StdCostLevel;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := UpdateOrderLines;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: Page "Assembly Availability"; var Response: Action)
    begin
        Response := ACTION::Yes; // always confirm
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmRefreshLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmRefreshLines) > 0, Question);
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

