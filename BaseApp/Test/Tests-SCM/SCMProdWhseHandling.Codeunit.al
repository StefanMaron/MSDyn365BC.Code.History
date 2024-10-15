codeunit 137298 "SCM Prod. Whse. Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Production] [Pick] [Put-away]
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
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsNoWhseHandling_ThrowsNothingToCreateMsg()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        MessageShown: Text;
        ThereIsNothingToCreateMsg: Label 'There is nothing to create.';
    begin
        // [SCENARIO] 'There is nothing to create' is shown when Production Consumption is set to 'No Warehouse Handling'.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'There is nothing to create' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsInvtPickMovement_CreatesInventoryPickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Inventory Pick/Movement' creates inventory pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick is run for the produciton order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 2 inventory pick lines are created with 2 quantities each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsWhsePickMandatory_CreateInventoryPickLinesThrowsNothingToCreate()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        MessageShown: Text;
        ThereIsNothingToCreateMsg: Label 'There is nothing to create.';
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'Nothing to create' message is shown.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdConsumpAsWhsePickOptional_CreatesWarehousePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (optional)' creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Warehouse Pick document lines is run for the Produciton Order.
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);

        // [THEN] 4 warehouse pick lines are created with 2 quantities each. 2 for Take and 2 for Place.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdConsumpAsWhsePickMandatory_CreatesWarehousePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Mandatory (Mandatory)' creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Warehouse Pick document lines is run for the Produciton Order.
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);

        // [THEN] 4 warehouse pick lines are created with 2 quantities each. 2 for Take and 2 for Place.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheck')]
    procedure ProdConsumpAsWhsePickMandatory_ProductionJournalQtyIs0()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' sets the qty to 0 on production journal.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Journal is open
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(0); // Consumption
        LibraryVariableStorage.Enqueue(0); // Consumption
        LibraryVariableStorage.Enqueue(1); // Output
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Consumption Qty. is set to 0
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsNoWhseHandling_CreateInventoryPutawayLinesThrowsNothingToCreate()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        MessageShown: Text;
        ThereIsNothingToCreateMsg: Label 'There is nothing to create.';
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", true, false, false);

        // [THEN] 'Nothing to create' message is shown.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsInventoryPutaway_CreateInventoryPutawayLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);
        Commit();

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        // [THEN] 1 put-away line is created
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] 1 put-away line is for the current location
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] Source Subtype is set to 'Released'
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Testfield("Source Subtype", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingProdConsumptionRespectsOnlyProdConsumpWhseHandling()
    var
        ParentItem: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        // [SCENARIO] Posting Production Consumption respects only 'Prod. Consump. Whse. Handling' property on Location.
        Initialize();

        // [GIVEN] Create Location with 5 bins and set Prod. Consump. Whse. Handling to 'No Warehouse Handling'.
        CreateLocationSetupWithBins(Location, false, false, true, true, true, 5, false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);

        // [GIVEN] Create an production item with 2 components.
        CreateProdItemWithTwoComponents(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ParentItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);
        Commit();

        // [WHEN] Post Production Consumption for the Production Order.
        Bin.FindFirst();
        PostProductionJournal(ProductionOrder, Location.Code, Bin.Code);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickEnforcedWhenWarehousePickIsSet()
    begin
        // Throw error is "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (mandatory)" and there is no pick.
        asserterror CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Assert.ExpectedError('remains to be picked.');

        // Allow posting usage if "Prod. Consump. Whse. Handling" is set to "Inventory Pick/Movement" and there is no pick.
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");

        // Creating and posting succeeds when "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (optional)" or "No Warehouse Handling".
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
    end;


    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostSucceedsWhenProdOutputIsNoWhseHandlingAndRequirePutawayON()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set on Production Journal when 'Prod. Output Whe. Handling' is set to 'No Whse. Handling' and 'Require Put-away' is set to 
        // true on Location. Posting succeeds as well.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to true and 'Prod. Output Whse. Handling' to 'No Whse. Handling' on Location.
        Location.Validate("Require Put-away", true);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 1
        LibraryVariableStorage.Enqueue(1); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('The journal lines were successfully posted.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostSucceedsWhenProdOutputIsNoWhseHandlingAndRequirePutawayOFF()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set on Production Journal when 'Prod. Output Whe. Handling' is set to 'No Whse. Handling' and 'Require Put-away' is set to 
        // false on Location. Posting succeeds as well.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to false and 'Prod. Output Whse. Handling' to 'No Whse. Handling' on Location.
        Location.Validate("Require Put-away", false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 1
        LibraryVariableStorage.Enqueue(1); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('The journal lines were successfully posted.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostFailsWhenProdOutputIsInventoryPutawayAndRequirePutawayOFF()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set to 0 on Production Journal when 'Prod. Output Whe. Handling' is set to 'Inventory Put-away' and 'Require Put-away' is set to 
        // false on Location. Posting fails and nothing to handle message is shown to the user.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to false and 'Prod. Output Whse. Handling' to 'Inventory Put-away' on Location.
        Location.Validate("Require Put-away", false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 0
        LibraryVariableStorage.Enqueue(0); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('There is nothing to post because the journal does not contain a quantity or amount.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsInventoryPutaway_CheckPutawaySource()
    var
        PutawayTemplateHeader: Record "Put-away Template Header";
        PutawayTemplateLine: Record "Put-away Template Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 481391] Check Source Document on inventory put-away created for production output.
        Initialize();

        // [GIVEN] Location with bin mandatory, put-away bin policy = put-away template, and set up for output posting via inventory put-away.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 2, false);
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order at the location.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
        Commit();

        // [WHEN] Create inventory put-away to post the output.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [THEN] Source document fields on the inventory put-away match the production order.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField("Source Type", Database::"Prod. Order Line");
        WarehouseActivityLine.Testfield("Source Subtype", 3);
        WarehouseActivityLine.TestField("Source No.", ProductionOrder."No.");

        // [THEN] The inventory put-away can be posted.
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        Item.Get(ProductionOrder."Source No.");
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ProductionOrder.Quantity);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Prod. Whse. Handling");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Prod. Whse. Handling");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Prod. Whse. Handling");
    end;

    local procedure CreateAndPostProductionConsumption(ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling")
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Prod. consumption Posting fails if pick is mandatory.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := ProdConsumpWhseHandling;
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        //[WHEN] Consumption is posted.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [THEN] No error is thrown if "Prod. Consump. Whse. Handling" is not set to "Warehouse Pick (Mandatory)".
        // [THEN] Error is thrown if "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (Mandatory)" and the caller validates the error thrown.
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption, ItemJournalTemplate.Name);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateProdItemWithTwoComponents(var ParentItem: Record Item; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem1."No.", CompItem2."No.", 2);

        ParentItem."Production BOM No." := ProductionBOMHeader."No.";
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::"Prod. Order";
        ParentItem.Modify(true);
    end;

    local procedure CreateProductionOrderWithLocationBinsAndTwoComponents(var ProductionOrder: Record "Production Order"; var Location: Record Location; var ParentItem: Record Item; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        Bin: Record Bin;
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);

        // [GIVEN] Create an production item with 2 components.
        CreateProdItemWithTwoComponents(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ParentItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateProductionOrderWithLocationBinsAndNoComponents(var ProductionOrder: Record "Production Order"; var Location: Record Location; var ProdItem: Record Item)
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);

        // [GIVEN] Create an production item with 2 components.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Modify(true);

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
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

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Document No.", ProductionOrder."No.");
        ItemJournalLine.ModifyAll("Location Code", LocationCode);
        ItemJournalLine.ModifyAll("Bin Code", BinCode);

        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();
        if ItemJournalLine."Quantity (Base)" = 0 then
            ItemJournalLine.ModifyAll("Quantity (Base)", 2);

        ItemJournalLine.SetRange("Entry Type");
        ItemJournalLine.FindFirst();

        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandlerWithQtyCheck(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        repeat
            ProductionJournal.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        until ProductionJournal.Next() = false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandlerWithQtyCheckAndPost(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        repeat
            ProductionJournal.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        until ProductionJournal.Next() = false;

        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

