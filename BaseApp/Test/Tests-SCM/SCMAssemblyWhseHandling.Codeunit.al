codeunit 137932 "SCM Assembly Whse. Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Assembly] [Pick] [Movement] [Consumption]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyConsumpAsNoWhseHandling_ThrowsNothingToCreateMsg()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        NothingToHandleErr: Label 'Nothing to handle.';
    begin
        // [SCENARIO] 'Nothing to handle' error is thrown when Assembly Consumption is set to 'No Warehouse Handling'.
        Initialize();

        // [GIVEN] Create needed setup with assembly order for an item with 2 components and release
        CreateAssemblyOrderWithLocationBinsAndTwoComponents(AssemblyHeader, Location, Item, CompItem1, CompItem2);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create Warehouse Pick is run for the assembly order.
        asserterror LibraryAssembly.CreateWhsePick(AssemblyHeader, '', 0, false, true, false);

        // [THEN] 'Nothing to handle' error is thrown.'.
        Assert.ExpectedError(NothingToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AssemblyConsumpAsInvtMovement_CreatesInventoryMovementLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Assembly Consumption set to 'Inventory Movement' creates inventory movement lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with assembly order for an item with 2 components and release
        CreateAssemblyOrderWithLocationBinsAndTwoComponents(AssemblyHeader, Location, Item, CompItem1, CompItem2);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"Inventory Movement";
        Location.Modify(true);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create Inventory Movement is run for the assembly order.
        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);

        // [THEN] 2 'Take' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AssemblyConsumpAsWhsePickMandatory_CreateWhsePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Assembly Consumption set to 'Warehouse Pick (Mandatory)', creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with assembly order for an item with 2 components and release
        CreateAssemblyOrderWithLocationBinsAndTwoComponents(AssemblyHeader, Location, Item, CompItem1, CompItem2);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create Warehouse Pick document lines is run for the assembly order.
        LibraryAssembly.CreateWhsePick(AssemblyHeader, '', 0, false, true, false);

        // [THEN] 2 'Take' inventory movement lines are created
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AssemblyConsumpAsWhsePickOptional_CreateWhsePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Assembly Consumption set to 'Warehouse Pick (Optional)', creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with assembly order for an item with 2 components and release
        CreateAssemblyOrderWithLocationBinsAndTwoComponents(AssemblyHeader, Location, Item, CompItem1, CompItem2);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"Warehouse Pick (Optional)";
        Location.Modify(true);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create Warehouse Pick document lines is run for the assembly order.
        LibraryAssembly.CreateWhsePick(AssemblyHeader, '', 0, false, true, false);

        // [THEN] 2 'Take' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAssemblyConsumptionRespectsOnlyAsmConsumpWhseHandling()
    var
        ParentItem: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SCENARIO] Posting Assembly Consumption respects only 'Asm. Consump. Whse. Handling' property on Location.
        Initialize();

        // [GIVEN] Create Location with 5 bins where 'Require Pick', 'Require Shipment' is turned ON and 'Asm. Consumption. Whse. Handling' is set to 'No Warehouse Handling'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, false);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        Bin.FindFirst();

        // [GIVEN] Create Assembly Order for 1 quantity of the parent item and set Location and Bin on the Assembly Header and Assembly Lines.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+14D>', WorkDate()), ParentItem."No.", Location.Code, 1, '');
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Validate("Bin Code", Bin.Code);
        AssemblyHeader.Modify(true);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.ModifyAll("Bin Code", Bin.Code);

        // [GIVEN] Assembly Order is posted
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] No error is thrown
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling()
    begin
        RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling(false, false);
        RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling(false, true);
        RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling(true, false);
        RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling(true, true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Whse. Handling");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Whse. Handling");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Whse. Handling");
    end;

    procedure RequirePickOrShipDoesNotInfluenceAssemblyConsumptionWhseHandling(RequirePick: Boolean; RequireShipment: Boolean)
    var
        ParentItem: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Require Pick and Require Shipment settings do not influence creation og inventory movement.
        Initialize();

        // [GIVEN] Create Location with 5 bins where 'Require Pick', 'Require Shipment' is turned set and 'Asm. Consumption. Whse. Handling' is set to 'Inventory Movement'.
        CreateLocationSetupWithBins(Location, false, RequirePick, false, RequireShipment, true, 5, false);
        Location."Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"Inventory Movement";
        Location.Modify(true);

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        Bin.FindFirst();

        // [GIVEN] Create Assembly Order for 1 quantity of the parent item and set Location and Bin on the Assembly Header and Assembly Lines.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+14D>', WorkDate()), ParentItem."No.", Location.Code, 1, '');
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Validate("Bin Code", Bin.Code);
        AssemblyHeader.Modify(true);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.ModifyAll("Bin Code", Bin.Code);

        // [GIVEN] Release Assembly Order to ensure warehouse request record is created.
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Inventory Movement is created.
        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);

        // [THEN] 2 'Take' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' inventory movement lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    local procedure CreateAssemblyBomComponent(var Item: Record Item; ParentItemNo: Code[20])
    var
        BomComponent: Record "BOM Component";
        BomRecordRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        BomComponent.Init();
        BomComponent.Validate(BomComponent."Parent Item No.", ParentItemNo);
        BomRecordRef.GetTable(BomComponent);
        BomComponent.Validate(BomComponent."Line No.", LibraryUtility.GetNewLineNo(BomRecordRef, BomComponent.FieldNo(BomComponent."Line No.")));
        BomComponent.Validate(BomComponent.Type, BomComponent.Type::Item);
        BomComponent.Validate(BomComponent."No.", Item."No.");
        BomComponent.Validate(BomComponent."Quantity per", LibraryRandom.RandInt(10));
        BomComponent.Insert(true);
    end;

    local procedure CreateAssemblyItemWithBOM(var AssemblyItem: Record Item; var BomComponentItem1: Record Item; var BomComponentItem2: Record Item)
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        // Create Component Item and set as Assembly BOM
        CreateAssemblyBomComponent(BomComponentItem1, AssemblyItem."No.");
        CreateAssemblyBomComponent(BomComponentItem2, AssemblyItem."No.");
        Commit(); // Save the BOM Component record created above
    end;

    local procedure CreateAssemblyOrderWithLocationBinsAndTwoComponents(var AssemblyHeader: Record "Assembly Header"; var Location: Record Location; var ParentItem: Record Item; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        Bin: Record Bin;
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);

        // [GIVEN] Create an production item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+14D>', WorkDate()), ParentItem."No.", Location.Code, 1, '');
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Modify(true);
    end;

    local procedure VerifyPickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer)
    begin
        // [THEN] Expected number of pick lines are created
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Expected number of pick lines are created
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Bin is set
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean; NoOfBins: Integer; UseBinRanking: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        if UseBinRanking then begin
            Bin.SetRange("Location Code", Location.Code);
            if Bin.FindSet() then
                repeat
                    Bin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 1000));
                    Bin.Modify(true);
                until Bin.Next() = 0;
        end;
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryInventory.NoSeriesSetup(InventorySetup);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate1: Record "Item Journal Template"; var ItemJournalBatch1: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate1, ItemJournalTemplateType);
        ItemJournalTemplate1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate1.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch1, ItemJournalTemplate1.Type, ItemJournalTemplate1.Name);
        ItemJournalBatch1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch1.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch1: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch1.Validate("No. Series", NoSeries);
        ItemJournalBatch1.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal;
                                                                                  LocationCode: Code[10];
                                                                                  BinCode: Code[20];
                                                                                  UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

