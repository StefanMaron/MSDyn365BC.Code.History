codeunit 137079 "SCM Production Order III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationWhite: Record Location;
        LocationSilver: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ItemJournalLineExistErr: Label 'There is no Item Journal Line within the filter.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        IsInitialized: Boolean;
        TrackingMsg: Label 'The change will not affect existing entries';
        NewWorksheetMsg: Label 'You are now in worksheet';
        ItemTrackingErr: Label 'You cannot define item tracking on this line because it is linked to production order';
        StartingDateMsg: Label 'Starting Date must be less or equal.';
        EndingDateMsg: Label 'Ending Date must be greater or equal.';
        PickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';
        PutawayActivitiesCreatedMsg: Label 'Number of Invt. Put-away activities created';
        InboundWhseRequestCreatedMsg: Label 'Inbound Whse. Requests are created.';
        UnadjustedValueEntriesNotCoveredMsg: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        ChangeExpectedCostPostingToGLMsg: Label 'If you change the Expected Cost Posting to G/L, the program must update table Post Value Entry to G/L.';
        ExpectedCostPostingChangedMsg: Label 'Expected Cost Posting to G/L has been changed to Yes. You should now run Post Inventory Cost to G/L.';
        PostJournalLinesConfirmationMsg: Label 'Do you want to post the journal lines';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        RecreatePurchaseLineConfirmHandlerQst: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?';
        WHHandlingIsRequiredErr: Label 'Warehouse handling is required for Entry Type = Output';
        AppliesToEntryErr: Label 'Applies-to Entry must have a value in Item Journal Line: Journal Template Name';
        QtyPickedBaseErr: Label 'Qty. Picked (Base) must not be 0 in Prod. Order Component';
        ItemTrackingMode: Option AssignLotNo,AssignSerialNo,SelectEntries,SetValue,UpdateQuantityBase;
        LeaveProductionJournalQst: Label 'Do you want to leave the Production Journal?';
        QtyToHandleBaseInTrackingErr: Label 'It must be %1.';
        WhseRequestErr: Label 'There is no "Warehouse Request" related to Production Order %1.';
        WhsePickRequestErr: Label 'There is no "Whse. Pick Request" related to Production Order %1.';
        OutputJournalItemNoErr: Label '%1 must be equal to ''%2''  in %3';
        ProdOrderLineBinCodeErr: Label 'Wrong "Prod. Order Line" BinCode value';
        ItemSubstCountErr: Label 'Wrong Item Substitution''s count.';
        ItemSubstDublicationErr: Label 'Duplicated Substitution Item is found.';
        ItemSubstItemNoErr: Label 'Wron Item Substitution No.';
        ValueEntrySourceTypeErr: Label 'Value Entry Source Type must be equal to %1';
        ValueEntrySourceNoErr: Label 'Value Entry Source No must be equal to %1';
        ProdJournalOutQtyErr: Label 'Output Quantity should be 0 in Production Journal Line linked to Subcontracted Workcenter';
        ComponentsAlreadyPickedQst: Label 'Components for production order %1 have already been picked. Do you want to continue?', Comment = 'Production order no.: Components for production order 101001 have already been picked. Do you want to continue?';
        SubcItemJnlErr: Label '%1 must be zero', Comment = '%1 - "Subcontractor No."';
        RtngLineBinCodeErr: Label 'Wrong %1 in %2.', Comment = '%1: Field(To-Production Bin Code), %2: TableCaption(Prod. Order Routing Line)';
        ActConsumptionNotZeroErr: Label 'Act. Consumption (Qty) must be equal to ''0''';

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionForReleasedProductionOrderWithLocationAndBin()
    begin
        // Verify Consumption Entry after post Consumption for the Child Item for Released Production Order.
        // Setup.
        Initialize;
        PostJournalsForReleasedProductionOrderWithLocationAndBin(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialOutputForReleasedProductionOrderWithLocationAndBin()
    begin
        // Verify Output Entry after post Output of the Parent Item for Released Production Order.
        // Setup.
        Initialize;
        PostJournalsForReleasedProductionOrderWithLocationAndBin(true);  // Post Output TRUE.
    end;

    local procedure PostJournalsForReleasedProductionOrderWithLocationAndBin(PostOutput: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
        QuantityPer: Integer;
    begin
        // Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        QuantityPer := LibraryRandom.RandInt(5);
        Quantity := LibraryRandom.RandInt(10);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, LocationRed.Code, Bin.Code);  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // Exercise: Calculate and post Consumption Journal. Create and post Output Journal.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        if PostOutput then
            CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", Quantity / 2);  // Post partial Quantity.

        // Verify: Verify the partial Output Quantity and Location for the Parent Item in Item Ledger Entry and Warehouse Entry. Verify Consumption Quantity and Location for the Child Item in Item Ledger Entry and Warehouse Entry.
        if PostOutput then begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity / 2, LocationRed.Code);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", Item."No.", Bin.Code, LocationRed.Code, Quantity);
        end else begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -Quantity * QuantityPer, LocationRed.Code);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Negative Adjmt.", ProductionOrder."No.", ChildItem."No.", Bin.Code, LocationRed.Code,
              -Quantity * QuantityPer);
        end;

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorPostConsumptionForAlreadyConsumedComponentItemWithLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
        QuantityPer: Integer;
    begin
        // Setup: Update Components at a Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        Initialize;
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, LocationRed.Code, Bin.Code);  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, LocationRed.Code, Bin.Code);
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");  // Calculate and post Consumption.

        // Exercise: Create and post Consumption Journal.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption for the already Consumed Item with Location.
        Assert.ExpectedError(ItemJournalLineExistErr);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorPostConsumptionForAlreadyConsumedComponentItemWithoutLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        QuantityPer: Integer;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Update Components at blank Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        Initialize;
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation('');  // Using blank Location.
        Quantity := LibraryRandom.RandInt(10);
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, '', '');  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");  // Calculate and post Consumption.

        // Exercise: Calculate and post Consumption Journal.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption for the already Consumed Item without Location.
        Assert.ExpectedError(ItemJournalLineExistErr);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForMultiLineSalesWithFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Craete Item. Update Order Tracking Policy on Item. Create and release Sales Order with multiple Sales Lines.
        Initialize;
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Quantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", Quantity, '', '');

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForMultiLineSalesWithFirmPlannedProdOrderCalcRegenPlanAndCarryOut()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Order Tracking Policy on Item. Update Planning parameters on Item.
        Initialize;
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");

        // Create and release Sales Order with multiple Lines, Calculate Regenerative Plan on WORKDATE.
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Quantity);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanReqWkshWithMaximumQuantityItemForEqualDemand()
    begin
        // Verify the Due Date, Action Message and Quantity on Requisition Line created for Maximum Quantity Item.
        // Setup.
        Initialize;
        CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(false);  // Accept and Carry Out Action FALSE.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcPlanReqWkshWithMaximumQuantityItemForEqualDemand()
    begin
        // Verify the Quantity on Purchase Line created for Maximum Quantity Item after Calc. Plan and Carry Out Action.
        // Setup.
        Initialize;
        CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(true);  // Accept and Carry Out Action TRUE.
    end;

    local procedure CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(AcceptAndCarryOutAction: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        // Create item with Reordering Policy. Create and post Purchase Order. Create and post Sales Order with Item Maximum Quantity.
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required for Item Maximum Inventory.
        CreateAndPostPurchaseOrderAsReceive(PurchaseHeader, Item."No.", Item."Maximum Inventory");
        CreateAndPostSalesOrderAsShip(Item, Item."Maximum Inventory");

        // Exercise: Calculate Plan for Requisition Worksheet on WORKDATE. Accept and Carry Out Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);
        if AcceptAndCarryOutAction then
            AcceptAndCarryOutActionMessageForRequisitionWorksheet(Item."No.");

        // Verify: Verify Quantity on Purchase Line created. Verify the Due Date, Action Message and Quantity on Requisition Line created.
        if AcceptAndCarryOutAction then
            VerifyPurchaseLine(Item."No.", Item."Maximum Inventory")
        else begin
            ManufacturingSetup.Get();
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, Item."Maximum Inventory",
              CalcDate(ManufacturingSetup."Default Safety Lead Time", WorkDate));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation()
    begin
        // Verify the Requisition Line after Calculate Plan on Planning Worksheet with demand generated from Blanket Order with Location.
        // Setup.
        Initialize;
        CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(false);  // Accept and Carry Out FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineAfterAcceptAndCarryOutPlanWkshForDemandFromBlanketOrderWithLocation()
    begin
        // Verify the Prod. Order Line after Calculate Plan and Carry Out on Planning Worksheet with demand generated from Blanket Order with Location.
        // Setup.
        Initialize;
        CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(true);  // Accept and Carry Out TRUE.
    end;

    local procedure CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(AcceptAndCarryOut: Boolean)
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        Quantity: Integer;
    begin
        // Update Sales and Receivables setup. Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create Sales Order from Blanket Order.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity, LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan on WORKDATE for Planning Worksheet. Accept and Carry Out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        if AcceptAndCarryOut then
            AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify the Quantity, Due Date and Location Code on Prod. Order Line created. Verify the Quantity and Location Code and Action Message on Requisition Line.
        if AcceptAndCarryOut then
            VerifyProdOrderLine(Item."No.", LocationBlue.Code, Quantity, WorkDate)
        else
            VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanTwiceOnPlanWkshForDemandFromBlanketOrderWithLocation()
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        Quantity: Integer;
    begin
        // Setup: Update Sales and Receivables setup. Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create Sales Order from Blanket Order.
        Initialize;
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity, LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);  // Calculate Regenerative Plan on WORKDATE.
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false); // Post Sales Order as Ship only.

        // Exercise: Calculate Regenerative Plan on WORKDATE for Planning Worksheet after posting Sales Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify: Verify the Quantity and Location Code and Action Message on Requisition Line.
        VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanOnPlanWkshForSalesOrderWithUpdatedBlanketOrderNoWithLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineBlanket: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Integer;
    begin
        // Setup: Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create a Blanket Order.
        Initialize;
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateBlanketOrder(SalesHeader, Item."No.", Quantity, '');

        // Create Sales Order. Update Blanket Order No and Location Code on Sales Order.
        CreateSalesOrder(SalesOrderHeader, Item."No.", Quantity, false);  // Multiple Sales Lines FALSE.
        SelectSalesOrderLine(SalesLine, SalesOrderHeader."No.");

        LibrarySales.FindFirstSalesLine(SalesLineBlanket, SalesHeader);
        UpdateBlanketOrderNoAndLocationOnSalesLine(SalesLine, SalesLineBlanket, LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify: Verify the Quantity and Location Code and Action Message on Requisition Line.
        VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        Initialize;
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.

        // Exercise: Calculate Subcontracts from Subcontracting Worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Reservation Entry for Status and Tracking after Calculate Subcontracts. Verify Production Quantity and WorkCenter Subcontractor on Subcontracting Worksheet.
        VerifyReservationEntry(Item."No.", ProductionOrder.Quantity, ReservationEntry."Reservation Status"::Surplus, '');
        VerifyRequisitionLineForSubcontract(ProductionOrder, WorkCenter, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    begin
        // Verify the Purchase Line created after Calculate Subcontracts and Carry Out on Subcontracting Worksheet.
        // Setup.
        Initialize;
        CalcSubcontractOrderForReleasedProductionOrderWithTracking(false);  // Assign Tracking on Purchase Line FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorAssignTrackingOnPurchLineAfterCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    begin
        // Verify the Tracking error on Purchase Line after Calculate Subcontracts and Carry Out.
        // Setup.
        Initialize;
        CalcSubcontractOrderForReleasedProductionOrderWithTracking(true);  // Assign Tracking on Purchase Line TRUE.
    end;

    local procedure CalcSubcontractOrderForReleasedProductionOrderWithTracking(AssignTracking: Boolean)
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.
        CalculateSubcontractOrder(WorkCenter);  // Calculate Subcontracts from Subcontracting worksheet.

        // Exercise: Accept and Carry Out Subcontracting Worksheet. Assign Tracking on Purchase Line.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        if AssignTracking then begin
            asserterror PurchaseLine.OpenItemTrackingLines;

            // Verify: Verify the Tracking error on Purchase Line. Verify the Quantity on Purchase Line created.
            Assert.ExpectedError(ItemTrackingErr);
        end else
            VerifyPurchaseLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        Initialize;
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.
        CalculateSubcontractOrder(WorkCenter);  // Calculate Subcontracts from Subcontracting worksheet.

        // Accept and Carry Out Action Message on Subcontracting Worksheet.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Exercise: Post Purchase Order as Ship.
        PostPurchaseOrderAsShip(Item."No.");

        // Verify: Verify that Finished Quantity on Prod. Order Line exist after Purchase Order posting.
        VerifyReleasedProdOrderLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProductionOrderWithLocationAndTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order with Location.
        Initialize;
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), LocationBlue.Code, '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.

        // Exercise: Calculate Subcontracts from Subcontracting Worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Reservation Entry for Status, Location Code and Tracking after Calculate Subcontracts. Verify Production Quantity and WorkCenter Subcontractor on Subcontracting Worksheet.
        VerifyReservationEntry(Item."No.", ProductionOrder.Quantity, ReservationEntry."Reservation Status"::Surplus, LocationBlue.Code);
        VerifyRequisitionLineForSubcontract(ProductionOrder, WorkCenter, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateOnProdOrderRoutingLineForReleasedProdOrderSchedulingBack()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create Item. Create Routing Setup and update Routing on Item. Create a Released Production Order.
        Initialize;
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2));

        // Exercise: Refresh Released Production Order with Scheduling Direction Back.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify that the Starting Date is less than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Starting Date" <= ProductionOrder."Due Date", StartingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateOnProdOrderRoutingLineForReleasedProdOrderSchedulingForward()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize;
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 1000);  // Large Quantity required.

        // Exercise: Refresh Released Production Order with Scheduling Direction Forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // Verify: Verify that the Ending Date is greater than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date" >= ProductionOrder."Due Date", EndingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostConsumptionForReleasedProductionOrder()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Cost Amount Actual on Production Order Statistics page after post Consumption for Released Production Order.

        // Setup.
        Initialize;
        PostJournalsForReleasedProductionOrder(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostConsumptionAndOutputForReleasedProductionOrder()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Cost Amount Actual on Production Order Statistics page after post Consumption and Output for Released Production Order.

        // Setup.
        Initialize;
        PostJournalsForReleasedProductionOrder(true);  // Post Output TRUE.
    end;

    local procedure PostJournalsForReleasedProductionOrder(PostOutput: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ComponentsAtLocation: Code[10];
        QuantityPer: Integer;
        ActualCost: Decimal;
    begin
        // Update Components at blank Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation('');
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(10) + 100, '', '');  // Large Quantity required for Component Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // Exercise: Calculate and post Consumption Journal. Create and post Output Journal.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        ActualCost := QuantityPer * (ProductionOrder.Quantity * ChildItem."Unit Cost");
        if PostOutput then begin
            CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Production Order Status from Released to Finished.
        end;

        // Verify: Verify the Cost Amount Actual on Production Order Statistics Page.
        if PostOutput then
            VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost)
        else
            VerifyCostAmountActualOnReleasedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        FamilyItemQuantity: Decimal;
    begin
        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family.
        Initialize;
        FamilyItemQuantity := LibraryRandom.RandDec(10, 2);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2, LibraryRandom.RandInt(5));
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", FamilyItemQuantity);

        // Verify: Verify the Production Order Lines created. Production Order Quantity as calculated from Family Item Quantity.
        VerifyProdOrderLine(ParentItem."No.", '', FamilyItemQuantity * FamilyItemQuantity, WorkDate);
        VerifyProdOrderLine(ParentItem2."No.", '', FamilyItemQuantity * FamilyItemQuantity, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalCostOnFinishedProductionOrderStatisticsPageForFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        FamilyItemQuantity: Decimal;
        ActualCost: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify the correct Total Actual Cost on Finished Production Order with source type Family.

        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Initialize;
        QuantityPer := LibraryRandom.RandInt(5);
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2, QuantityPer);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::Released, Family."No.", FamilyItemQuantity);

        // Calculate and post Consumption and Output journals.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", LibraryRandom.RandDec(100, 2) + 100);  // Quantity greater than FamilyItemQuantity.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the correct Total Actual Cost on Finished Production Order Statistics page.
        ActualCost :=
          QuantityPer * FamilyItemQuantity * (FamilyItemQuantity * ChildItem."Unit Cost" + FamilyItemQuantity * ChildItem2."Unit Cost");
        VerifyTotalActualCostOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureOnWhseReceiptWithLocation()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Setup: Create Item with multiple Item Unit of Measure, create and release Purchase Order.
        Initialize;
        CreateItem(Item);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2);

        // Exercise: Create Whse Receipt from Purchase Order.
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandDec(10, 2));

        // Verify: Verify the Unit of Measure on whse Receipt Line.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseReceiptLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureOnWhsePutAwayWithLocation()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with multiple Item Unit of Measure. Create and release Purchase Order, create Whse Receipt.
        Initialize;
        CreateItem(Item);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandDec(10, 2));

        // Exercise: Post Warehouse Receipt.
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Verify: Verify the Put Away created with new Unit of Measure.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyUOMOnWhseActivityLine(WarehouseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewUnitOfMeasureOnWhsePickForReleasedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Update Components at Location. Create parent and child Items with multiple Item Unit of Measure in a Prod. BOM, create and release Purchase Order. Create and post Warehouse Receipt.
        Initialize;
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateMultipleItemUnitOfMeasureSetup(ChildItem, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Register the Put Away, create and refresh a Released Production Order.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Exercise: Create Pick from Released Production Order.
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify that new Unit of Measure is updated on Warehouse Pick Line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyUOMOnWhseActivityLine(WarehouseActivityLine, ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure");

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewUnitOfMeasureOnRegisteredWhsePutAwayWithProductionBOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        ChildItem: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items with multiple Item Unit of Measure in a Prod. BOM, create and release Purchase Order. Create and post Warehouse Receipt.
        Initialize;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateMultipleItemUnitOfMeasureSetup(ChildItem, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Exercise: Register the Put Away created.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify: Verify the Unit of Measure Code updated on Registered Whse Activity Lines.
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, PurchaseHeader."No.", RegisteredWhseActivityLine."Action Type"::Take,
          RegisteredWhseActivityLine."Activity Type"::"Put-away");
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", Quantity);
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, PurchaseHeader."No.", RegisteredWhseActivityLine."Action Type"::Place,
          RegisteredWhseActivityLine."Activity Type"::"Put-away");
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure", Quantity / 2);  // Used for Break bulk.
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure OutputEntryOnProductionJournalForReleasedProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item. Create and refresh a Released Production Order.
        Initialize;
        CreateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), LocationWhite.Code,
          LocationWhite."To-Production Bin Code");

        // Exercise & Verify: Open Production Journal for the Released Production Order. Verify the Output Entry on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", ProductionOrder.Quantity, ItemJournalLine."Entry Type"::Output);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionEntryOnProductionJournalForProductionOrderAfterCreateAndRegisterPick()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        ComponentsAtLocation: Code[10];
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup, update Components at Location.
        Initialize;
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);  // Register the Pick created.

        // Exercise & Verify: Open Production Journal for the Released Production Order. Verify the Consumption Entry on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, ChildItem."No.", Item."No.", Quantity, ItemJournalLine."Entry Type"::Consumption);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and multiple components in a Production BOM and certify it. Update Inventory for component Items. Create and refresh a Released Production Order.
        Initialize;
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationSilver.Code);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3);
        UpdateComponentsInventory(Item2."No.", Item3."No.", LocationSilver.Code, Bin.Code, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Exercise: Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Verify: Verify that Inventory Pick created successfully.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(WarehouseActivityLine, Item2."No.", Quantity);
        VerifyWarehouseActivityLine(WarehouseActivityLine, Item3."No.", Quantity);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPartialInventoryPickForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and multiple components in a Production BOM and certify it. Update Inventory for component Items. Create and refresh a Released Production Order.
        Initialize;
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationSilver.Code);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3);
        UpdateComponentsInventory(Item2."No.", Item3."No.", LocationSilver.Code, Bin.Code, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Create Inventory Pick from the Released Production Order. Update partial quantity on Inventory Pick line created.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        UpdateQuantityOnWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity / 2, LocationSilver.Code);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, LocationSilver.Code);

        // Exercise: Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Invoice False.

        // Verify: Verify that Inventory Pick posted successfully with partial Quantity.
        VerifyPostedInventoryPickLine(ProductionOrder."No.", Item2."No.", Bin.Code, Quantity / 2, LocationSilver.Code);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionCompItemWithBackwardFlushingForReleasedProdOrderError()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Flushing method on child Item. Update Inventory for the Child Item. Create Routing. Create and Refresh a Released Production Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');  // Large Component Quantity is required.
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), '', '');

        // Exercise: Calculate and post Consumption for the child Item.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption.
        Assert.ExpectedError(ItemJournalLineExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputAndFinishReleasedProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Finished Quantity is correct on Prod. Order Line with component Flushing Method = Backward, after Prod. Order change Status from Released to Finished.

        // Setup: Create Parent and Child Items in Certified Production BOM. Update Flushing method on child Item. Update Inventory for the Child Item. Create Routing. Create and Refresh a Released Production Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');  // Large Component Quantity is required.
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), '', '');
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);  // Create and post Output Journal for the Production Order.

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.

        // Verify: Verify the Finished Quantity on Prod. Order Line.
        VerifyFinishedProdOrderLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostNegativeOutputForProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize;
        CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(Item, ChildItem, ProductionOrder);

        // Exercise: Post the negative Output for the Production Order.
        CreateAndPostOutputJournalWithApplyEntry(Item."No.", -ProductionOrder.Quantity);

        // Verify: Verify the Cost Amount Actual as zero for Output Entry.
        VerifyValueEntry(Item."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Output, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostOutputAndFinishReleasedProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Cost Amount is correct in Value Entry after Production Order post Output and change status from Released to Finished, child item has Flushing Method = Backward.

        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize;
        CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(Item, ChildItem, ProductionOrder);

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Cost Amount Actual in Value Entry created. Verify the Cost Amount Actual as zero for Output Entry.
        VerifyValueEntry(
          ChildItem."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Consumption,
          -ProductionOrder.Quantity * ChildItem."Unit Cost");
        VerifyValueEntry(Item."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Output, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureCodeOnProdOrderLineWithBOMVersionCode()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create parent and child Items in a Certified Production BOM. Create Certified Production BOM version with Copy Version and certify it. Create and refresh a Released Production Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateCertifiedProductionBOMVersionWithCopyBOM(Item."Production BOM No.", Item."Base Unit of Measure");
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Update Production BOM Version Code on Production Order Line.
        UpdateProdBOMVersionCodeOnProdOrderLine(Item);

        // Verify: Verify the Unit Of Measure Code remains same on Production Order Line when Production BOM Version Code is changed.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPickedAfterRegisterWhsePickForProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize;
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Exercise: Register the Whse Pick.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify the Qty Picked and Qty Picked (Base) on Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem."No.", ProductionOrder.Quantity);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure WhsePickAfterRefreshProductionOrderForAlreadyPickedItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize;
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Register the Whse Pick. Refresh the Production Order again.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryVariableStorage.Enqueue(StrSubstNo(ComponentsAlreadyPickedQst, ProductionOrder."No."));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Exercise: Create Whse Pick again.
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify the Take and Place Pick lines created after refresh Production Order twice.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Place);
        VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickForReleasedProductionOrderWithItemFlushingPickAndBackward()
    begin
        // Verify the Movement Warehouse Entries created after create Whse Pick with Child Item Flushing method Pick + Backward.
        // Setup.
        Initialize;
        CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(false);  // Register Pick FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntryAfterRegisterPickForReleasedProductionOrderWithItemFlushingPickAndBackward()
    begin
        // Verify the Movement Warehouse Entries created after Register Whse Pick with Child Item Flushing method Pick + Backward.
        // Setup.
        Initialize;
        CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(true);  // Register Pick TRUE.
    end;

    local procedure CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(RegisterPick: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Update Components at Location. Create parent and child Items in a Production BOM. Update Flushing Method on Child Item. Update Child Item Inventory. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateItemFlushingMethodPickAndBackward(ChildItem);
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Exercise: Create Whse Pick from Released Production Order. Register the Whse Pick created.
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        if RegisterPick then
            RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityHeader.Type::Pick);

        // Verify: Verify the Movement Warehouse Entry created after Register Whse Pick. Verify the Pick created for Child Item with Pick + Backward Flushing method.
        if RegisterPick then
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, ProductionOrder."No.", ChildItem."No.", LocationWhite."Cross-Dock Bin Code",
              LocationWhite.Code, -Quantity)
        else begin
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Take);
            VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Place);
            VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
        end;

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntryAfterPutAwayForReleasedProductionOrderWithItemFlushingBackward()
    begin
        // Verify the Movement Warehouse Entries created after post Whse Receipt for Item with Backward Flushing method.
        // Setup.
        Initialize;
        CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(false);  // Register Put Away FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntriesAfterRegisterPutAwayForReleasedProductionOrderWithItemFlushingBackward()
    begin
        // Verify the Movement Warehouse Entries created after Register Whse Put Away for Item with Backward Flushing method.
        // Setup.
        Initialize;
        CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(true);  // Register Put Away TRUE.
    end;

    local procedure CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(RegisterPutAway: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Create parent and child Items in a Production BOM and update Backward Flushing on child Item. Create and release Purchase Order. Create Warehouse Receipt.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);

        // Exercise: Post Warehouse Receipt. Register the Put Away created.
        PostWarehouseReceipt(PurchaseHeader."No.");
        if RegisterPutAway then
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify: Verify the Movement Warehouse Entries created after post Whse Receipt and Register Whse Put Away for Child Item with Backward Flushing method.
        if RegisterPutAway then
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, PurchaseHeader."No.", ChildItem."No.", LocationWhite."Receipt Bin Code",
              LocationWhite.Code, -Quantity)
        else
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", PurchaseHeader."No.", ChildItem."No.", LocationWhite."Receipt Bin Code",
              LocationWhite.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MessageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ValueEntriesForFinishedProdOrderWithNewUOM()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        CostAmount: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Value Entries are correct for Finished Production Order if Prod. Order Line is updated with new UOM, then Production Journal posted, then status changed from Released to Finished.

        // Setup: Create parent and child Items in a Production BOM and certify it. Update Overhead rate, Unit of measure and Quantity per unit of measure on Parent Item. Create and Post Purchase Order as Receive.
        Initialize;
        UpdateInventorySetup(InventorySetup);
        CreateItemsSetup(ParentItem, ChildItem, LibraryRandom.RandInt(5));
        UpdateItemOverheadRate(ParentItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ParentItem."No.", LibraryRandom.RandInt(10));
        CreateAndPostPurchaseOrderWithDirectUnitCostAsReceive(PurchaseHeader, ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100);  // Large Quantity required.

        // Create and refresh Released Production Order and change Unit of Measure on Production Order Line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandDec(10, 2), '', '');
        UpdateProdOrderLineUnitOfMeasureCode(ProdOrderLine, ParentItem."No.", ItemUnitOfMeasure.Code);

        // Open Production Journal and Post.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Handler used -PostProductionJournalHandler.

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Value Entries for Finished Production Order With Entry Type Direct Cost and Indirect Cost. Verify the Cost Amount, Cost Per Unit and Invoiced Quantity as Zero.
        CostAmount := ProdOrderLine."Overhead Rate" * ItemUnitOfMeasure."Qty. per Unit of Measure" * ProductionOrder.Quantity;
        VerifyValueEntryForEntryType(
          ValueEntry."Entry Type"::"Direct Cost", ProductionOrder."No.",
          ProductionOrder.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", 0, 0, 0, 0);
        VerifyValueEntryForEntryType(
          ValueEntry."Entry Type"::"Indirect Cost", ProductionOrder."No.", 0, CostAmount, 0, ProdOrderLine."Overhead Rate", CostAmount);

        // Tear Down.
        ResetInventorySetup(InventorySetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterUpdatingVATBusPostingGroupFromHeader()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Test that after changing VAT bus posting group from Purchase Header created from subcontacting worksheet, Purchase line should not be updated with Item card.
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), '', '');

        // Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Exercise: Update the purchase header with VAT bus posting group different from the earlier one.
        LibraryVariableStorage.Enqueue(
          StrSubstNo(RecreatePurchaseLineConfirmHandlerQst, PurchaseHeader.FieldCaption("VAT Bus. Posting Group")));  // Required inside ConfirmHandlerTRUE.
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdatePurchaseHeaderVATBusPostingGroup(PurchaseHeader);

        // Verify: Verify that the Purchase line should not be updated with Item card. And the field values remains the same.
        VerifyRecreatedPurchaseLine(PurchaseLine, PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithRequirePickLocationForItemWithRouting()
    begin
        // Verify production journal with negative quantity on output line can be posted with Require Pick Location for Item with routing
        PostOutputCorrectionWithRequirePickLocation(true); // TRUE indicates routing exists
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithRequirePickLocationForItemWithoutRouting()
    begin
        // Verify production journal with negative quantity on output line can be posted with Require Pick Location for Item without routing
        PostOutputCorrectionWithRequirePickLocation(false); // FALSE indicates routing doesn't exist
    end;

    local procedure PostOutputCorrectionWithRequirePickLocation(HasRouting: Boolean)
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Location: Record Location;
    begin
        // Setup: Create Production Item
        Initialize;
        LibraryInventory.CreateItem(Item);

        if HasRouting then begin
            CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
            FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity
        end;

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false); // Create a Require-Pick Location
        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, ''); // Set Bin Code to empty
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity); // Create and post Output Journal for the Production Order.

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        CreateAndPostOutputJournalWithApplyEntryAndOperationNo(Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.");

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationBinMandatory()
    var
        Bin: Record Bin;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Test to verify the production journal with negative quantity can be posted with Bin Mandatory Location for Item with routing.

        // Use a Bin-Mandatory Location
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, LocationRed.Code, Bin.Code, true);

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickWithoutApplyToEntry()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Entry using Location with Require Pick.

        // Create a Require-Pick Location and create output correct journal without "Applies-to Entry"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, Location.Code, '', false);

        // Exercise and Verify: Post output journal and expect the error pops up
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedError(WHHandlingIsRequiredErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndShipmentWithoutApplyToEntry()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Entry using Location with Require Pick and Require Shipment.

        // Create a Require-Pick and Require-Shipment Location and create output correct journal without "Applies-to Entry"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, Location.Code, '', false);

        // Exercise and Verify: Post output journal and expect the error pops up
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedError(AppliesToEntryErr);
    end;

    local procedure CreateOutputCorrectionWithLocation(var Item: Record Item; var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; BinCode: Code[20]; SetAppliesToEntry: Boolean)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Production Item
        Initialize;
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity

        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), LocationCode, BinCode);
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // Create output journal with negative quantity
        CreateOutputJournalWithApplyEntryAndOperationNo(
          Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.", SetAppliesToEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndItemTracking()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // Setup: Create a Require-Pick Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // Create Output Correction Journal with Location and Item Tracking.
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, Location.Code, true);

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndItemTrackingWithoutApplyToItemEntry()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Item Entry using Location with Require Pick.

        // Setup: Create a Require-Pick Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // Create Output Correction Journal with Location and Item Tracking without " Apply-to Item Entry".
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, Location.Code, false);

        // Exercise and Verify: Post output journal and verify error pops up.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedError(WHHandlingIsRequiredErr);

        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingLooksForSoleOpenOriginalOutputEntryWithSameLotToApply()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with lot no. and does not set an entry to apply, the program finds the sole original output with the same lot and populates "Applies-to Entry" field.

        // [GIVEN] Lot-tracked item "I".
        // [GIVEN] Released production order for "I".
        // [GIVEN] Set lot no. "L" on the output journal line and post the output of "I". Output quantity = "Q".
        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, '', false);

        // [WHEN] Post the output correction.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The reversed output is successfully posted and applied to the original one.
        VerifyReversedOutputItemLedgerEntry(Item."No.");

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandlerWithoutApplyToItemEntry,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingLooksForSoleOpenOriginalOutputEntryWithSameSNToApply()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with serial no. and does not set an entry to apply, the program finds the sole original output with the same serial no. and populates "Applies-to Entry" field.
        Initialize;

        // [GIVEN] Serial no.-tracked item "I".
        LibraryItemTracking.CreateSerialItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for 1 pc of "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 1, '', '');

        // [GIVEN] Set serial no. "S" on the output journal line and post the output of "I".
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a reversed line in the output journal with item = "I", serial no. = "S", quantity = -1 and blank "Applies-to Entry".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateReversedOutputJournalLine(
          ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post the output correction.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The reversed output is successfully posted and applied to the original one.
        VerifyReversedOutputItemLedgerEntry(Item."No.");

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenSeveralEntriesMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        LotNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the original output entry cannot be selected unambiguously.
        Initialize;

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 2 * LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Post two output entries with item "I" and lot "L", each output for "Q" pcs.
        LotNo := LibraryUtility.GenerateGUID;
        for i := 1 to 2 do begin
            CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
            ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity / 2);
            ItemJournalLine.Modify(true);

            LibraryVariableStorage.Enqueue(ItemTrackingMode::SetValue);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue('');
            LibraryVariableStorage.Enqueue(ProductionOrder.Quantity / 2);
            ItemJournalLine.OpenItemTrackingLines(false);

            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        CreateOutputJournalWithApplyEntryAndItemTracking(
          Item."No.", -ProductionOrder.Quantity / 2, FindLastOperationNo(Item."Routing No."), false);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not unambiguously define the original entry to apply.
        Assert.ExpectedError(AppliesToEntryErr);

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenLotNotMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case item tracking in the original output does not match.
        Initialize;

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Set lot no. "L1" on the output journal line and post the output of "I". Output quantity = "Q".
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // [GIVEN] Create a reversed line in the output journal with item = "I", quantity = "-Q", blank "Applies-to Entry" and new lot no. = "L2".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetValue);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(-ProductionOrder.Quantity);
        CreateReversedOutputJournalLine(
          ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not find an output entry with lot no. "L2".
        Assert.ExpectedError(AppliesToEntryErr);

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandlerWithoutApplyToItemEntry,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenLotNotSuffice()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the remaining quantity in the original output does not suffice for full application.
        Initialize;

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 2 * LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Set lot no. "L" on the output journal line and post the output of "I". Output quantity = "2Q".
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-2Q" and blank "Applies-to Entry".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateReversedOutputJournalLine(
          ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Post the negative adjustment for "Q" pcs of lot "L".
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.");
        CreateAndPostInvtAdjustmentOfItemWithLot(Item."No.", ItemLedgerEntry."Lot No.", -ProductionOrder.Quantity / 2);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] "Applies-to Entry must have a value" error message is raised. The remaining quantity of the original output is now "Q" pcs, that is not enough to fully apply the reversed output for "2Q" pcs.
        Assert.ExpectedError(AppliesToEntryErr);

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandlerWithoutApplyToItemEntry,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenProdOrderLineNotMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the original output was posted for a different prod. order line.
        Initialize;

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        // [GIVEN] The production order has two prod. order lines "POL1", "POL2", each for "Q" pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 2 * LibraryRandom.RandInt(10));
        for i := 1 to ArrayLen(ProdOrderLine) do
            LibraryManufacturing.CreateProdOrderLine(
              ProdOrderLine[i], ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', ProductionOrder.Quantity / 2);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);

        // [GIVEN] Open the output journal and explode the routing.
        // [GIVEN] Define the item tracking on the journal line representing prod. order line "POL1". Lot No. = "L".
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity / 2);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Delete the output journal lines representing prod. order line "POL2".
        ItemJournalLine.SetRange("Order Line No.", ProdOrderLine[2]."Line No.");
        ItemJournalLine.DeleteAll(true);

        // [GIVEN] Post the output.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        // [GIVEN] Set "Order Line No." = "POL2" on the reversed output line.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        ItemJournalLine.Validate("Output Quantity", -ProductionOrder.Quantity / 2);
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine[2]."Line No.");
        ItemJournalLine.Validate("Operation No.", FindLastOperationNo(Item."Routing No."));
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not find an original output for prod. order line "POL2".
        Assert.ExpectedError(AppliesToEntryErr);

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure OutputQtyWithScrapInProductionJournalAfterCreateReleasedProductionOrder()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        RoutingLine: Record "Routing Line";
        Quantity: Decimal;
        ScrapFactor: Decimal;
        ScrapFactor2: Decimal;
        FixedScrapQty: Decimal;
        FixedScrapQty2: Decimal;
        RndgPrecision: Decimal;
        OutputQty: Decimal;
    begin
        // Test to verify Output Quantity in Production Journal is correct with setting Fixed Scrap Quantity and Scrap Factor % in Routing.

        // Setup: Create Routing with Item. Set "Scrap Factor %" and "Fixed Scrap Quantity" for Routing Lines.
        Initialize;
        LibraryInventory.CreateItem(Item);
        CreateRoutingWithScrapAndFlushingMethod(
          Item, WorkCenter."Flushing Method"::Manual, true, LibraryRandom.RandDec(10, 2), LibraryRandom.RandInt(5));

        // Exercise: Create Released Production Order.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');

        // Calculate the ScrapFactor & FixedScrapQty manually to avoid the rounding issue.
        FindFirstRoutingLine(RoutingLine, Item."Routing No.");
        RndgPrecision := LibraryRandom.RandDec(0, 5);
        ScrapFactor := 1 + RoutingLine."Scrap Factor %" / 100;
        FixedScrapQty := RoutingLine."Fixed Scrap Quantity";
        RoutingLine.Next;
        ScrapFactor2 := Round(ScrapFactor * (1 + RoutingLine."Scrap Factor %" / 100), RndgPrecision);
        FixedScrapQty2 := Round(RoutingLine."Fixed Scrap Quantity" * ScrapFactor + FixedScrapQty, RndgPrecision);
        OutputQty := Round(Quantity * ScrapFactor2 + FixedScrapQty2, RndgPrecision);

        // Verify: Open Production Journal for the Released Production Order.
        // Verify the Output Quantity on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", OutputQty, ItemJournalLine."Entry Type"::Output);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActualCapacityCostOnReleasedProductionOrderStatisticsPage()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        RunTime: Decimal;
        UnitCost: Decimal;
    begin
        // Test to verify Capacity Cost should be recognized in Production order Statistics as Actual Cost when posting output journal with Output Quantity = 0.
        Initialize;

        // Setup: Create and refresh release Production Order with setting blank Location code
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // Create and Post Output Journal with Output Quantity = 0
        RunTime := LibraryRandom.RandDec(10, 2);
        UnitCost := LibraryRandom.RandDec(10, 2);
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, UnitCost);

        // Exercise: Open Release Production Order Statistics Page
        OpenReleasedProductionOrderStatisticsPage(ProductionOrderStatistics, ProductionOrder."No.");

        // Verify: Capacity Cost and Total Cost for Actual Cost column is correct on Release Production Order Statistics Page
        ProductionOrderStatistics.CapacityCost_ActualCost.AssertEquals(RunTime * UnitCost);
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals(RunTime * UnitCost);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PostProductionJournalWithItemFlushingPickAndBackward()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // Test to verify an error pops up when posting the Production Journal with Qty. Picked (Base) is zero
        // in Prod. Order Component with Item Flushing Method is Pick + Backward.

        // Setup: Create Item with BOM and Routing. Update Inventory with Item Journal.
        Initialize;
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateLocationAndBins(LocationSilver);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1); // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandIntInRange(50, 100), LocationSilver.Code, Bin.Code); // Large Component Quantity is required.

        // Create and refresh 1st Released Production Order. Create and register the Whse. Pick created from Released Production Order.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationSilver.Code, '');
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Create 2nd Released Production Order.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationSilver.Code, LocationSilver."To-Production Bin Code");
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // Exercise: Open Production Journal, then post it by PostProductionJournalHandler.
        asserterror LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verify an error pops up when posting Production Journal with Qty. Picked (Base) is zero in Prod. Order Component.
        Assert.ExpectedError(QtyPickedBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutProductionOrderByPlanningWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify Bin Code is correct in production order line after carry out the planning line with Warehouse LocationWhite.
        // Bin Code should be From-Production Bin Code of LocationWhite.

        // Setup: Create Item. Create Sales Order and update Location on Sales Line.
        Initialize;
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(50), false); // Multiple Sales Lines is FALSE.
        UpdateLocationOnSalesLine(SalesHeader."No.", LocationWhite.Code);

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify Bin Code in Production Order Line.
        VerifyBinCodeInProductionOrderLine(Item."No.", LocationWhite."From-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalAfterChangingUOMOnProdOrdLine()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemNo: Code[20];
    begin
        // Test to verify the Quantity in Warehouse Entry is based on the UOM with Posting after changing UOM on Production Order Line.

        // Setup: Create Item with Routing. Create Item UOM. Create and refresh Release Production Order.
        Initialize;
        ItemNo := CreateItemWithRouting;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, ItemNo, LibraryRandom.RandInt(20),
          LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Change UOM on Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        UpdateProdOrderLineUnitOfMeasureCode(ProdOrderLine, ItemNo, ItemUnitOfMeasure.Code);

        // Exercise: Open Production Journal and post by handler PostProductionJournalHandler.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verify Quantity on Warehouse Entry is correct.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", ItemNo,
          LocationWhite."To-Production Bin Code", LocationWhite.Code, ProdOrderLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalWithDifferentUOMForConsumption()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QuantityPer: Decimal;
    begin
        // Test to verify the Quantity of ChildItem with consumed in Warehouse Entry is based on the UOM of Prod. BOM Line.

        // Setup: Create Item with BOM and Routing. Create ChildItem UOM. Update UOM of Prod. BOM line.
        // Create and refresh Released Production Order.
        Initialize;
        QuantityPer := LibraryRandom.RandIntInRange(2, 5); // It must be greater than 1.
        CreateItemWithBOMAndRouting(Item, ChildItem, QuantityPer);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ChildItem."No.", QuantityPer);
        UpdateBOMHeaderWithLineUOM(Item."Production BOM No.", ChildItem."No.", ItemUnitOfMeasure.Code);
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, LibraryRandom.RandInt(10) + 1000);

        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", LibraryRandom.RandInt(10),
          LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Create and register Pick from Released Production Order.
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Open Production Journal and post by PostProductionJournalHandler.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verify Quantity of ChildItem consumed on Warehouse Entry is correct.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", ProductionOrder."No.", ChildItem."No.",
          LocationWhite."To-Production Bin Code", LocationWhite.Code, -(ProdOrderLine.Quantity * QuantityPer));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandlerWithoutApplyToItemEntry,ItemTrackingSummaryPageHandler,PostProductionJournalHandlerWithUpdateQuantity,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWhenBackFlushingConsumptionAndManualOutputWithError()
    var
        Verification: Option VerifyErr,VerifyItemLedgerEntry;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Error message is correct when Finish Production Order for Back Flushing Consumption and Manual Flushing Output with Scrap.

        FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification::VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandlerWithoutApplyToItemEntry,ItemTrackingSummaryPageHandler,PostProductionJournalHandlerWithUpdateQuantity,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWhenBackFlushingConsumptionAndManualOutputWithUpdateTracking()
    var
        Verification: Option VerifyErr,VerifyItemLedgerEntry;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Production Order can be Finished when updating Tracking for Back Flushing Consumption and Manual Flushing Output with Scrap.

        FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification::VerifyItemLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByBOMPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailByBOMLevelWithMultipleUOM()
    var
        Item: Record Item;
        ChildItem: Record Item;
        TopItem: Record Item;
        QuantityPer: Decimal;
        QuantityPer2: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        QtyPerUnitOfMeasure2: Decimal;
        AvailableQty: Decimal;
        AvailableQty2: Decimal;
        ChildItemAbleToMakeParentQty: Decimal;
        ChildItemAbleToMakeTopItemQty: Decimal;
    begin
        // Setup: Create Production BOM, Parent Item and attach Production BOM. Create Child Item UOM. Update UOM of Prod. BOM line.
        // Create and post Item Journal Line for Child Item.
        Initialize;
        CreateItem(ChildItem);
        InitSetupForProdBOMWithMultipleUOM(Item, ChildItem, QuantityPer, QtyPerUnitOfMeasure, AvailableQty);
        InitSetupForProdBOMWithMultipleUOM(TopItem, Item, QuantityPer2, QtyPerUnitOfMeasure2, AvailableQty2);

        // Item is a BOM Item, so "Able to Make Parent" = (AvailQty + "Able to Make Parent") / "Qty. per Parent".
        // "Able to Make Top Item" = AvailQty / "Qty. per Top Item" + "Able to Make Top Item".
        // ChildItem is a Leaf Item, so "Able to Make Parent" := AvailQty / "Qty. per Parent", "Able to Make Top Item" := AvailQty / "Qty. per Top Item".
        ChildItemAbleToMakeParentQty := AvailableQty / (QuantityPer * QtyPerUnitOfMeasure);
        ChildItemAbleToMakeTopItemQty := AvailableQty / (QuantityPer * QtyPerUnitOfMeasure) / (QuantityPer2 * QtyPerUnitOfMeasure2);
        EnqueueVariablesForItemAvailByBOMPage(
          Item."No.", (AvailableQty2 + ChildItemAbleToMakeParentQty) / (QuantityPer2 * QtyPerUnitOfMeasure2),
          AvailableQty2 / (QuantityPer2 * QtyPerUnitOfMeasure2) + ChildItemAbleToMakeTopItemQty);
        EnqueueVariablesForItemAvailByBOMPage(ChildItem."No.", ChildItemAbleToMakeParentQty, ChildItemAbleToMakeTopItemQty);

        // Exercise & Verify: Run Item Availablity By BOM Level Page.
        // Verify Able to Make Parent and Able to Make Top Item of Item and ChildItem through ItemAvailabilityByBOMPageHandler.
        RunItemAvailByBOMLevelPage(TopItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestExistsWhenAddingNewCompWithZeroQty()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ChildItem: Record Item;
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        // [FEATURE] [Warehouse] [Manufacturing] [Warehouse Request]
        // [SCENARIO 109052.1] Verify 'Warehouse Request' exists when adding new component with zero Qty

        Initialize;
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);  // Require Pick

        // [GIVEN] Create Released Production Order "PO"
        CreateItemsSetup(Item, ChildItem, 10 + LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 10 + LibraryRandom.RandInt(10), Location.Code, '');

        // [GIVEN] Create new Prod. Order Component "C"
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);

        // [WHEN] Insert new "C" to "PO" line with zero Quantity
        WhseProdRelease.ReleaseLine(NewProdOrderComponent, ProdOrderComponent); // simulate (Rec,xRec) 'Prod. Order Component'.INSERT trigger

        // [THEN] Warehouse Request exists for "PO"
        VerifyWhseRequestExist(ProductionOrder."No.", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickRequestExistsWhenAddingNewCompAfterFullyConsumpedComp()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ChildItem: Record Item;
        WhseProdRelease: Codeunit "Whse.-Production Release";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Warehouse] [Manufacturing] [Warehouse Request]
        // [SCENARIO 109052.2] Verify 'Whse. Pick Request' exists when adding new component after fully consumed previous component

        Initialize;
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);  // Require Pick, Shipment
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create production item, fill inventory with consumption item "CI"
        Quantity := 10 + LibraryRandom.RandInt(10);
        QuantityPer := 10 + LibraryRandom.RandInt(10);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity * QuantityPer * 2, Location.Code, '');

        // [GIVEN] Create Released Production Order "PO", make Whse. Pick, register Pick and Post Consumption Journal
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, Location.Code, '');
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        FindAndRegisterWhseActivity(Location.Code, ProductionOrder."No.");
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // [GIVEN] Create new Prod. Order Component "C"
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);

        // [WHEN] Insert "C" after "CI"
        WhseProdRelease.ReleaseLine(NewProdOrderComponent, ProdOrderComponent); // simulate (Rec,xRec) 'Prod. Order Component'.INSERT trigger

        // [THEN] Whse. Pick Request exists for "PO"
        VerifyWhsePickRequestExist(ProductionOrder."No.", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostOutputJournalWithChangedOrderLineNo()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        NewProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production] [Manufacturing] [Output Journal]
        // [SCENARIO 109053] Posting of Output Journal is not allowed with ItemNo different from Order Line's Item

        Initialize;
        CreateItem(Item);
        CreateItem(Item2);

        // [GIVEN] Create and Refresh Released Production Order "RPO" for Item "X1"
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(100), '', '');

        // [GIVEN] Manually add new Prod. Order Line with new Item "X2"
        CreateAddProdOrderLine(NewProdOrderLine, ProductionOrder, Item2."No.");

        // [GIVEN] Open Output Journal and add a line for "RPO" SourceNo Item "X1"
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [GIVEN] Modify Output Journal's "Order Line No." to the line with item "X2"
        ItemJournalLine.Validate("Order Line No.", NewProdOrderLine."Line No.");
        ItemJournalLine.Modify(true);

        // [WHEN] Post the Output Journal
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] Error occurs: 'Item No. must be equal to "X2" in Item Journal Line... '
        Assert.ExpectedError(
          StrSubstNo(OutputJournalItemNoErr, ItemJournalLine.FieldCaption("Item No."), Item2."No.", ItemJournalLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderLineGetsBinCodeFromWorkCenterThroughPlanningRoutingLine()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning] [Bin] [Planning Worksheet] [Work Center]
        // [SCENARIO 360750.1] ProdOrderLine gets BinCode from Work Center through Planning Routing Line

        Initialize;

        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center No on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);

        // [WHEN] Carry out Action Message
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] ProdOrderLine's BinCode is same as Work Center's Bin Code
        VerifyProdOrderLineBinCode(ItemNo, WorkCenter."From-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('ItemSubstEntries_MPH')]
    [Scope('OnPrem')]
    procedure ItemSubstitutionALLtoALLHasNoDuplications()
    var
        TempItem: Record Item temporary;
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[10] of Code[20];
        ItemCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [Production] [Item Substitutions]
        // [SCENARIO] No duplicate items in Substitution list for ALL-to-ALL subtitution setup

        Initialize;
        ItemCount := ArrayLen(ItemNo);

        // [GIVEN] N Items with ALL-to-ALL substitution setup
        for i := 1 to ItemCount do
            ItemNo[i] := CreateSimpleItem;

        for i := 1 to ItemCount do
            CreateItemSubstitution(ItemNo, i);

        // [WHEN] Show Item substitution list for the first item
        ProdOrderComponent.Init();
        ProdOrderComponent."Item No." := ItemNo[1];
        ProdOrderComponent.ShowItemSub;

        // [THEN] Number of substitutions are equal to (N - 1)
        Assert.AreEqual(ItemCount - 1, LibraryVariableStorage.Length, ItemSubstCountErr);

        // [THEN] There is no duplications within substitution list
        TempItem.Init();
        for i := 1 to ItemCount - 1 do begin
            TempItem."No." := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TempItem."No."));
            Assert.IsTrue(TempItem.Insert, ItemSubstDublicationErr);
        end;

        // [THEN] There are correct substitution Items
        for i := 2 to ItemCount do
            Assert.IsTrue(TempItem.Get(ItemNo[i]), ItemSubstItemNoErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesCreatesValueEntryWithSourceTypeTakenFromoItemLedgerEntryDuringSubcontracting()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost] [Subcontracting]
        // [SCENARIO 361968] Adjust Cost Item Entries creates Value Entry with "Source Type" and "Source No." taken from original VE during Subcontracting
        Initialize;

        // [GIVEN] Subcontracting Work Center
        // [GIVEN] Item with Routing
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        // [GIVEN] Released Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        // [GIVEN] Subcontracting Purchase Order
        // [GIVEN] Post output/consuption. Finish Production Order
        CreateAndPostSubcontractingPurchaseOrder(WorkCenter, Item."No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Value Entry is created with "Source Type" and "Source No." taken from from Original VE
        VerifyValueEntrySource(ProductionOrder."No.", WorkCenter."Subcontractor No.", ValueEntry."Source Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,PostProductionJournalHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesCreatesValueEntryWithSourceTypeTakenFromoItemJournalLine()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WorkCenter: Record "Work Center";
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Adjust Cost] [Subcontracting]
        // [SCENARIO 361968] Adjust Cost Item Entries creates Value Entry with "Source Type" and "Source No." taken from original VE
        Initialize;

        // [GIVEN] Item with Routing
        Quantity := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, Quantity);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', '');
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        // [GIVEN] Released Production Order
        // [GIVEN] Post output/consuption. Finish Production Order
        ProdOrderNo := CreateFinishedProdOrder(Item."No.", Quantity);

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Value Entry is created with "Source Type" and "Source No." taken from from Original VE
        VerifyValueEntrySource(ProdOrderNo, Item."No.", ValueEntry."Source Type"::Item);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalSubcontractedPageHandler')]
    [Scope('OnPrem')]
    procedure CheckProductionJournalOutQtyWithSubcontractedWorkCenter()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Production Journal should fill "Output Quantity" with zero while linked to Subcontracted Work Center
        Initialize;

        // [GIVEN] Released Production Order with Subcontracting
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // [WHEN] Open Production Journal
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst;
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [THEN] Production Journal has "Output Quantity" = 0
        // Verify throuhg ProductionJournalSubcontractedPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalOutputQuantity()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Output Quantity" zero while linked to Subcontracted Work Center
        Initialize;

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Output Quantity" to X <> 0
        asserterror ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Output Quantity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalRunTime()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Run Time" zero while linked to Subcontracted Work Center
        Initialize;

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Run Time" to X <> 0
        asserterror ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Run Time")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalSetupTime()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Setup Time" zero while linked to Subcontracted Work Center
        Initialize;

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Run Time" to X <> 0
        asserterror ItemJournalLine.Validate("Setup Time", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Setup Time")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionJournalForZeroExpectedQuantity()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 378650] Post Consumption Journal Job for Component with Zero Expected Quantity should set Remaining Quantity for this Component to zero.
        Initialize;

        // [GIVEN] Released Production Order.
        // [GIVEN] Prod. Order Component with "Quantity Per" = 0.
        CreateProdOrderAddNewComponentAndCreateConsumptionLine(ProdOrderComponent, 0);

        // [WHEN] Post Consumption Journal Line for this Component.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [THEN] The Component has "Remaining Qty. (Base)" = 0.
        ProdOrderComponent.Find;
        ProdOrderComponent.TestField("Remaining Qty. (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateProdOrderLineExpectedQuantity()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Prod. Order Component] [UT]
        // [SCENARIO 379075] Remaining Quantity should be 0 if Expected Qty. is validated to 0, regardless of posted consumption quantity.
        Initialize;

        // [GIVEN] Item Ledger Entry with Entry Type = Consumption and Quantity <> 0.
        // [GIVEN] Prod. Order Component.
        MockProdOrderComponent(ProdOrderComponent);
        MockItemLedgerEntryForConsumption(ProdOrderComponent);

        // [WHEN] Revalidate "Expected Quantity" of this Component to 0.
        ProdOrderComponent.Validate("Expected Quantity", 0);

        // [THEN] The Component has "Remaining Quantity" = 0.
        ProdOrderComponent.TestField("Remaining Quantity", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdOrderRoutingGetsToProdBinFromWorkCenter()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning Worksheet] [Work Center] [Bin]
        // [SCENARIO 379347] Prod. Order Routing Line gets "To-Production Bin Code" from Work Center with Manual Flushing Method through Planning.
        Initialize;

        // [GIVEN] Create Work Center with "Flushing Method" = Manual and "To-Production Bin Code" = "B".
        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);

        // [WHEN] Carry out Action Message.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] "To-Production Bin Code" in Prod. Order Routing Line is equal to "B".
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemNo);
        Assert.AreEqual(
          WorkCenter."To-Production Bin Code", ProdOrderRoutingLine."To-Production Bin Code",
          StrSubstNo(RtngLineBinCodeErr, ProdOrderRoutingLine.FieldCaption("To-Production Bin Code"), ProdOrderRoutingLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdOrderRoutingGetsOpenShopFloorBinFromWorkCenter()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning Worksheet] [Work Center] [Bin]
        // [SCENARIO 379347] Prod. Order Routing Line gets "Open Shop Floor Bin Code" from Work Center with non-Manual Flushing Method through Planning.
        Initialize;

        // [GIVEN] Create Work Center with "Flushing Method" <> Manual and "Open Shop Floor Bin Code" = "B".
        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);
        WorkCenter.Validate("Flushing Method", LibraryRandom.RandInt(2)); // forward or backward
        WorkCenter.Modify(true);

        // [WHEN] Carry out Action Message.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] "Open Shop Floor Bin Code" in Prod. Order Routing Line is equal to "B".
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemNo);
        Assert.AreEqual(
          WorkCenter."Open Shop Floor Bin Code", ProdOrderRoutingLine."Open Shop Floor Bin Code",
          StrSubstNo(RtngLineBinCodeErr, ProdOrderRoutingLine.FieldCaption("Open Shop Floor Bin Code"), ProdOrderRoutingLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeShouldBeFilledAfterValidatingVariantCodeinProductionOrderLine()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Production] [Bin]
        // [SCENARIO 379950] Released Production Order should successfully post output on changing status to finished if variant code was changed before it in Production Order Line.
        Initialize;

        // [GIVEN] Create parent Item with routing, child Item and Production BOM.
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, false);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Update Flushing Method On child Item to Backward.
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // [GIVEN] Inventory of ChildItem in white Location in Open Shop Floor Bin.
        UpdateItemInventoryForLocation(ChildItem, LocationWhite, LibraryRandom.RandDecInRange(11, 100, 2));

        // [GIVEN] Released Production Order with 1 line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), LocationWhite.Code, '');
        UpdateFlushingMethodOnProdOrderRoutingLine(ProductionOrder);

        // [WHEN] Change Variant Code in Production Order Line.
        UpdateVariantCodeInProductionOrderLine(ProdOrderLine, ProductionOrder, ItemVariant.Code);

        // [THEN] Bin Code should be filled and production order should change status successfully.
        ProdOrderLine.TestField("Bin Code", LocationWhite."From-Production Bin Code");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        VerifyProductionOrderIsEmpty(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentBinCopiedFromWorkCenterProductionBinWithRoutingLink()
    var
        ParentItem: Record Item;
        ComponentItem: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Bin] [Routing] [Production BOM] [Routing Link]
        // [SCENARIO 253201] Bin code in the planning component line shoud be taken from the "To-Production Bin Code" field of the work center linked to the corresponding production BOM line

        Initialize;

        // [GIVEN] Manufactured item "I" with two components "C1" and "C2"
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);

        // [GIVEN] Work center "W1" with "To-Production Bin" "B1"
        CreateWorkCenterWithLocationAndBin(WorkCenter[1], LocationSilver.Code);
        // [GIVEN] Work center "W2" with "To-Production Bin" "B2"
        CreateWorkCenterWithNewToProductionBin(WorkCenter[2], LocationSilver.Code);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Routing operation on the work center "W1" linked to a production BOM line with component "C1"
        CreateLinkedProdBOMLineAndRoutingLine(ProductionBOMHeader, RoutingHeader, WorkCenter[1]."No.", ComponentItem[1]."No.");
        // [GIVEN] Routing operation on the work center "W2" linked to a production BOM line with component "C2"
        CreateLinkedProdBOMLineAndRoutingLine(ProductionBOMHeader, RoutingHeader, WorkCenter[2]."No.", ComponentItem[2]."No.");

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItemManufacturingProperties(ParentItem, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Sales order for the top-level item "I"
        CreateSalesOrderOnLocation(SalesHeader, ParentItem."No.", LibraryRandom.RandInt(100), WorkCenter[1]."Location Code");

        // [WHEN] Run regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate, WorkDate);

        // [THEN] Planning component line for the item "C1" has "Bin Code" = "B1"
        VerifyPlanningComponentBin(ComponentItem[1]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
        // [THEN] Planning component line for the item "C2" has "Bin Code" = "B2"
        VerifyPlanningComponentBin(ComponentItem[2]."No.", WorkCenter[2]."Location Code", WorkCenter[2]."To-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentBinCopiedFromFirstWorkCenterProdBinWhenNoRoutingLink()
    var
        ParentItem: Record Item;
        ComponentItem: array[2] of Record Item;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Bin] [Routing] [Production BOM]
        // [SCENARIO 253201] Bin code in the planning component line shoud be taken from the "To-Production Bin Code" field of the work center in the first routing operation if there is no routing link

        Initialize;

        // [GIVEN] Manufactured item "I" with two components "C1" and "C2"
        CreateAndCertifyProdBOMWithMultipleComponent(ParentItem, ComponentItem[1], ComponentItem[2]);

        // [GIVEN] Work center "W1" with "To-Production Bin" "B1"
        CreateWorkCenterWithLocationAndBin(WorkCenter[1], LocationSilver.Code);
        // [GIVEN] Work center "W2" with "To-Production Bin" "B2"
        CreateWorkCenterWithNewToProductionBin(WorkCenter[2], LocationSilver.Code);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter[1]."No.");
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter[2]."No.");

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        UpdateItemManufacturingProperties(ParentItem, ParentItem."Production BOM No.", RoutingHeader."No.");

        // [GIVEN] Sales order for the top-level item "I"
        CreateSalesOrderOnLocation(SalesHeader, ParentItem."No.", LibraryRandom.RandInt(100), WorkCenter[1]."Location Code");

        // [WHEN] Run regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate, WorkDate);

        // [THEN] "To-Production Bin Code" is "B1" on both planning component lines
        VerifyPlanningComponentBin(ComponentItem[1]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
        VerifyPlanningComponentBin(ComponentItem[2]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure CustomSelectedBinIsNotRedefinedWithToProdBinCode()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 262029] Non-blank bin code on a production order line is not redefined, despite the different "From-Production Bin Code" setting on the location.
        Initialize;

        // [GIVEN] Location "L" with two bins - "B1", "B2".
        // [GIVEN] Set "From-Production Bin Code" on the location = "B1".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Released production order on location "L".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10), Location.Code, '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Set "Bin Code" = "B2" on the production order line.
        ProdOrderLine.Validate("Bin Code", Bin[2].Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting;

        // [THEN] Manually defined "Bin Code" = "B2" on the production order line is not changed.
        ProdOrderLine.Find;
        ProdOrderLine.TestField("Bin Code", Bin[2].Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure BlankBinCodeOnProdOrderLineIsUpdatedWithDefaultBin()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 262029] Blank bin code on a production order line is populated with a bin code, that has a default bin content for the item, location and variant on the prod. order line.
        Initialize;

        // [GIVEN] Location "L" with mandatory bin.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order for item "I" on location "L". "Bin Code" is blank on the prod. order line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Create bin content for item "I", location "L", bin "B", default = TRUE.
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting;

        // [THEN] "Bin Code" on the prod. order line is updated to "B".
        ProdOrderLine.Find;
        ProdOrderLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure UnitCostOnProdOrderLineIsNotChangedOnShowRouting()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        UnitCost: Decimal;
    begin
        // [SCENARIO 262029] If you open and close Routing page in a production order, it won't affect unit cost on production order lines.
        Initialize;

        // [GIVEN] Released production order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10), '', '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Set unit cost on the prod. order line = "X".
        UnitCost := LibraryRandom.RandDec(10, 2);
        ProdOrderLine.Validate("Unit Cost", UnitCost);
        ProdOrderLine.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting;

        // [THEN] Unit cost on the prod. order line remains to be equal to "X".
        ProdOrderLine.Find;
        ProdOrderLine.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostOnPostingOutputIsInheritedFromItemIfSKUDoesNotExist()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Expected Cost]
        // [SCENARIO 266183] Unit cost on item card is posted as expected unit cost of output if no stockkeeping unit exists for the item and location.
        Initialize;

        // [GIVEN] Item with "Unit Cost" = 0.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Released production order for "Q" pcs of the item.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code, '');

        // [GIVEN] Update "Unit Cost" on the item to "X".
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        // [WHEN] Post the output.
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // [THEN] Expected cost of the output is equal to "Q" * "X".
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindFirst;
        ValueEntry.TestField("Cost Amount (Expected)", ProductionOrder.Quantity * Item."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostOnPostingOutputIsInheritedFromSKUIfItExists()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Expected Cost] [Stockkeeping Unit]
        // [SCENARIO 266183] Unit cost on stockkeeping unit card is posted as expected unit cost of output if SKU exists for the item and location.
        Initialize;

        // [GIVEN] Item "I" with "Unit Cost" = 0.
        // [GIVEN] Stockkeeping unit for item "I" on location "L".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationBlue.Code, Item."No.", '');

        // [GIVEN] Released production order for "Q" pcs of the item.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code, '');

        // [GIVEN] Update "Unit Cost" on the item to "X".
        // [GIVEN] Update "Unit Cost" on the stockkeeping unit to "Y".
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        SKU.Validate("Unit Cost", LibraryRandom.RandDecInRange(11, 20, 2));
        SKU.Modify(true);

        // [WHEN] Post the output.
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // [THEN] xpected cost of the output is equal to "Q" * "Y".
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindFirst;
        ValueEntry.TestField("Cost Amount (Expected)", ProductionOrder.Quantity * SKU."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingNewComponentDoesNotCheckActualConsumedQty()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Prod. Order Component] [Consumption] [UT]
        // [SCENARIO 287655] Adding new prod. order component does not check for lack of previously posted consumption.
        Initialize;

        // [GIVEN] Component item "C" is in inventory.
        LibraryInventory.CreateItem(CompItem);
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(50, 100), '', '');

        // [GIVEN] Production item "P" does not have a production BOM yet.
        // [GIVEN] Released production order for item "P".
        LibraryInventory.CreateItem(ProdItem);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandInt(10), '', '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post the consumption of "C" in consumption journal.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, CompItem."No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Initialize a new prod. order component.
        ProdOrderComponent.Init();
        ProdOrderComponent.Validate(Status, ProdOrderLine.Status);
        ProdOrderComponent.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.Validate("Prod. Order Line No.", ProdOrderLine."Line No.");

        // [WHEN] Select item "C" on the new prod. order component line.
        ProdOrderComponent.Validate("Item No.", CompItem."No.");

        // [THEN] The new component is successfully added.
        ProdOrderComponent.TestField("Unit of Measure Code", CompItem."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyingExistingComponentChecksActualConsumedQtyIsZero()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Prod. Order Component] [Consumption] [UT]
        // [SCENARIO 287655] Updating item no. on prod. order component checks that there were no previously posted consumption for this prod. order component line.
        Initialize;

        // [GIVEN] Component item "C" is in inventory.
        // [GIVEN] Production item "P" has a production BOM with item "C" as a component.
        // [GIVEN] Released production order for item "P".
        // [GIVEN] Post the consumption of item "C" in consumption journal.
        CreateProdOrderAddNewComponentAndCreateConsumptionLine(ProdOrderComponent, 1);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [WHEN] Change Item No. on prod. order component from "C" to a new item "X".
        ProdOrderComponent.Find;
        asserterror ProdOrderComponent.Validate("Item No.", LibraryInventory.CreateItemNo);

        // [THEN] Error is thrown, reading that there was a posted consumption on this component line.
        Assert.ExpectedError(ActConsumptionNotZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatingProdOrderDateTimeAsMininumAndMaximumAmongProdOrderLines()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 291614] AdjustStartEndingDate function on Production Order table finds the earliest and the latest dates among prod. order lines to populate Starting Date and Ending Date respectively.
        Initialize;

        // [GIVEN] Released production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));

        // [GIVEN] The production order has eight lines with various starting, ending and due dates.
        // [GIVEN] The earliest starting date-time is 05/01/20 11:00, the latest ending date-time is 30/01/20 22:00.
        // [GIVEN] The latest due date is 01/02/20.
        CreateProdOrderLineWithDates(ProductionOrder, 20200116D, 080000T, 20200122D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200130D, 220000T, 20200131D); // the latest ending date
        CreateProdOrderLineWithDates(ProductionOrder, 20200105D, 150000T, 20200117D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200117D, 140000T, 20200118D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200105D, 110000T, 20200101D); // the earliest starting date
        CreateProdOrderLineWithDates(ProductionOrder, 20200107D, 020000T, 20200130D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200130D, 080000T, 20200201D); // the latest due date
        CreateProdOrderLineWithDates(ProductionOrder, 20200124D, 170000T, 20200128D);

        // [WHEN] Invoke 'AdjustStartEndingDate' function on the production order.
        ProductionOrder.AdjustStartEndingDate;

        // [THEN] The production order dates are updated.
        // [THEN] Starting date-time = 05/01/20 11:00.
        // [THEN] Ending date-time = 30/01/20 22:00.
        // [THEN] Due date = 01/02/20.
        ProductionOrder.TestField("Starting Date-Time", CreateDateTime(20200105D, 110000T));
        ProductionOrder.TestField("Ending Date-Time", CreateDateTime(20200130D, 220000T));
        ProductionOrder.TestField("Due Date", 20200201D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateFunctionOnProdOrderLineUpdatesProdOrderDates()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        Direction: Option Forward,Backward;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 291614] Invoking Recalculate function on a production order line updates dates on the production order without running 'AdjustStartEndingDate' on the production order explicitly.
        Initialize;

        // [GIVEN] Released production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Change dates on the production order, so they do not match the dates on the production order line.
        ProductionOrder."Starting Date" := ProductionOrder."Starting Date" - LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder."Ending Date" := ProductionOrder."Ending Date" + LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder."Due Date" := ProductionOrder."Due Date" + LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder.Modify();

        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Recalculate the production order line.
        CalculateProdOrder.Recalculate(ProdOrderLine, Direction::Backward, false);

        // [THEN] The dates on the production order are equal to the dates on the production order line.
        ProductionOrder.Find;
        ProductionOrder.TestField("Starting Date", ProdOrderLine."Starting Date");
        ProductionOrder.TestField("Ending Date", ProdOrderLine."Ending Date");
        ProductionOrder.TestField("Due Date", ProdOrderLine."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePreviousNextOperationNoProdOrderRouting()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
        FirstOperationNo: Code[10];
        LastOperationNo: Code[10];
    begin
        // [FEATURE] [Routing]
        // [SCENARIO 291617] "Next/Previous Operation No." are automatically relinked on deletion of Prod. Order Routing Lines
        Initialize;

        // [GIVEN] Created Item "IT" with Routing of type "Serial" and 3 Routing Lines
        ItemNo := CreateItemSerialRoutingSeveralLines(3);

        // [GIVEN] Released Prod. Order for item "IT" Created and Refreshed
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder,
          ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item,
          ItemNo,
          LibraryRandom.RandDec(10, 0));

        // [GIVEN] First Prod. Order Routing Line with "Operation No." = 10
        // [GIVEN] Last Prod. Order Routing Line with "Operation No." = 30
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        FirstOperationNo := ProdOrderRoutingLine."Operation No.";
        ProdOrderRoutingLine.FindLast;
        LastOperationNo := ProdOrderRoutingLine."Operation No.";

        // [WHEN] CheckPreviousAndNext called on the middle Prod. Order Routing Line
        ProdOrderRoutingLine.Next(-1);
        ProdOrderRoutingLine.CheckPreviousAndNext;

        // [THEN] "Next Operation No." = 30 on the first Prod. Order Routing Line
        ProdOrderRoutingLine.FindFirst;
        Assert.AreEqual(LastOperationNo, ProdOrderRoutingLine."Next Operation No.", '');

        // [THEN] "Previous Operation No." = 10 on the last Prod. Order Routing Line
        ProdOrderRoutingLine.FindLast;
        Assert.AreEqual(FirstOperationNo, ProdOrderRoutingLine."Previous Operation No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPositiveOutputDoesNotRequireMandatoryWhseHandling()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Inventory Put-away] [Output]
        // [SCENARIO 297641] Warehouse handling is not mandatory when posting production output on location set up for required put-away.
        Initialize;

        // [GIVEN] Location "L" with "Require Put-away" = TRUE, "Require Receive" = FALSE.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item "I" with routing.
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for item "I" on location "L".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, Bin.Code);

        // [GIVEN] Open output journal and explode routing for the production order.
        // [GIVEN] Set the output quantity.
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the output journal.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The output is successfully posted.
        // [THEN] The warehouse and item entries representing the output are created.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", Item."No.",
          Bin.Code, Location.Code, ProductionOrder.Quantity);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item."No.", ProductionOrder.Quantity, Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingOutputFailsIfInventoryPutAwayAlreadyExists()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Inventory Put-away] [Output]
        // [SCENARIO 297641] A user cannot proceed posting output directly from output journal after they created an inventory put-away.
        Initialize;

        // [GIVEN] Location "L" with "Require Put-away" = TRUE, "Require Receive" = FALSE.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item "I" with routing.
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for item "I" on location "L".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, Bin.Code);

        // [GIVEN] Create inbound warehouse request and inventory put-away from the production order.
        LibraryVariableStorage.Enqueue(InboundWhseRequestCreatedMsg);
        LibraryVariableStorage.Enqueue(PutawayActivitiesCreatedMsg);
        LibraryWarehouse.CreateInboundWhseReqFromProdO(ProductionOrder);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [GIVEN] Open output journal and explode routing for the production order.
        // [GIVEN] Set the output quantity.
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the output journal.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The posting fails. A user is notified that they have to proceed with the inventory put-away to post the output.
        Assert.ExpectedError(WHHandlingIsRequiredErr);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsFromProdBinCodeForLocationWithDirectedPAAndPick()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is by default blank on production order despite the "From-Production Bin Code" setting on location with directed put-away and pick.
        Initialize;

        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", LocationWhite.Code);

        ProductionOrder.TestField("Bin Code", '');
        LocationWhite.TestField("From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsNotOverriddenToDefaultForLocationWithDirectedPAAndPick()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
        FromProdBinCode: Code[20];
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is not set to "Default Bin" when you select location code with enabled directed put-away and pick on production order and "From-Production Bin Code" is not defined.
        Initialize;

        LocationWhite.Find;
        FromProdBinCode := LocationWhite."From-Production Bin Code";
        LocationWhite."From-Production Bin Code" := '';
        LocationWhite.Modify();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        LibraryWarehouse.CreateBinContent(BinContent, LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", LocationWhite.Code);

        ProductionOrder.TestField("Bin Code", '');

        // tear down
        LocationWhite."From-Production Bin Code" := FromProdBinCode;
        LocationWhite.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsOverriddenToDefaultForBasicWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is set to "Default Bin" when you select a location with disabled directed put-away and pick on production order and "From-Production Bin Code" is not defined.
        Initialize;

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", Location.Code);

        ProductionOrder.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateOnCalendarEntry()
    var
        CalendarEntry: Record "Calendar Entry";
        StartingTime: Time;
        EndingTime: Time;
        CurrDate: Date;
    begin
        // [FEATURE] [Calendar Entry] [UT]
        // [SCENARIO 331428] GetStartingEndingDateAndTime function in Calendar Entry table initializes StartingTime,EndingTime and Date variables used as expressions on date and time controls on Calendar Entry page.
        Initialize;

        CalendarEntry.Init();
        CalendarEntry."No." := LibraryUtility.GenerateGUID;
        CalendarEntry."Starting Date-Time" := CreateDateTime(WorkDate, 120000T);
        CalendarEntry."Ending Date-Time" := CreateDateTime(WorkDate + 30, 120000T);

        CalendarEntry.GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);

        Assert.AreEqual(DT2Time(CalendarEntry."Starting Date-Time"), StartingTime, '');
        Assert.AreEqual(DT2Time(CalendarEntry."Ending Date-Time"), EndingTime, '');
        Assert.AreEqual(DT2Date(CalendarEntry."Ending Date-Time"), CurrDate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnProductionOrderLists()
    var
        PlannedProdOrder: Record "Production Order";
        FirmPlannedProdOrder: Record "Production Order";
        ReleasedProdOrder: Record "Production Order";
        FinishedProdOrder: Record "Production Order";
        SimulatedProdOrder: Record "Production Order";
        PlannedProductionOrders: TestPage "Planned Production Orders";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
        ReleasedProductionOrders: TestPage "Released Production Orders";
        FinishedProductionOrders: TestPage "Finished Production Orders";
        SimulatedProductionOrders: TestPage "Simulated Production Orders";
        ProductionOrderList: TestPage "Production Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Date" and "Ending Date" controls on production order lists are expressions calculated from "Starting Date-Time" and "Ending Date-Time" fields in accordance with the current time zone.
        Initialize;

        MockProductionOrder(PlannedProdOrder, PlannedProdOrder.Status::Planned);
        MockProductionOrder(FirmPlannedProdOrder, FirmPlannedProdOrder.Status::"Firm Planned");
        MockProductionOrder(ReleasedProdOrder, ReleasedProdOrder.Status::Released);
        MockProductionOrder(FinishedProdOrder, FinishedProdOrder.Status::Finished);
        MockProductionOrder(SimulatedProdOrder, SimulatedProdOrder.Status::Simulated);

        PlannedProductionOrders.OpenView;
        PlannedProductionOrders.FILTER.SetFilter("No.", PlannedProdOrder."No.");
        PlannedProductionOrders."Starting Date".AssertEquals(DT2Date(PlannedProdOrder."Starting Date-Time"));
        PlannedProductionOrders."Ending Date".AssertEquals(DT2Date(PlannedProdOrder."Ending Date-Time"));
        PlannedProductionOrders.Close;

        FirmPlannedProdOrders.OpenView;
        FirmPlannedProdOrders.FILTER.SetFilter("No.", FirmPlannedProdOrder."No.");
        FirmPlannedProdOrders."Starting Date".AssertEquals(DT2Date(FirmPlannedProdOrder."Starting Date-Time"));
        FirmPlannedProdOrders."Ending Date".AssertEquals(DT2Date(FirmPlannedProdOrder."Ending Date-Time"));
        FirmPlannedProdOrders.Close;

        ReleasedProductionOrders.OpenView;
        ReleasedProductionOrders.FILTER.SetFilter("No.", ReleasedProdOrder."No.");
        ReleasedProductionOrders."Starting Date".AssertEquals(DT2Date(ReleasedProdOrder."Starting Date-Time"));
        ReleasedProductionOrders."Ending Date".AssertEquals(DT2Date(ReleasedProdOrder."Ending Date-Time"));
        ReleasedProductionOrders.Close;

        FinishedProductionOrders.OpenView;
        FinishedProductionOrders.FILTER.SetFilter("No.", FinishedProdOrder."No.");
        FinishedProductionOrders."Starting Date".AssertEquals(DT2Date(FinishedProdOrder."Starting Date-Time"));
        FinishedProductionOrders."Ending Date".AssertEquals(DT2Date(FinishedProdOrder."Ending Date-Time"));
        FinishedProductionOrders.Close;

        SimulatedProductionOrders.OpenView;
        SimulatedProductionOrders.FILTER.SetFilter("No.", SimulatedProdOrder."No.");
        SimulatedProductionOrders."Starting Date".AssertEquals(DT2Date(SimulatedProdOrder."Starting Date-Time"));
        SimulatedProductionOrders."Ending Date".AssertEquals(DT2Date(SimulatedProdOrder."Ending Date-Time"));
        SimulatedProductionOrders.Close;

        ProductionOrderList.OpenView;
        ProductionOrderList.FILTER.SetFilter("No.", PlannedProdOrder."No.");
        ProductionOrderList."Starting Date".AssertEquals(DT2Date(PlannedProdOrder."Starting Date-Time"));
        ProductionOrderList."Ending Date".AssertEquals(DT2Date(PlannedProdOrder."Ending Date-Time"));
        ProductionOrderList.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnPlannedProductionOrderCard()
    var
        PlannedProdOrder: Record "Production Order";
        PlannedProductionOrderCard: TestPage "Planned Production Order";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Time", "Starting Date", "Ending Time" and "Ending Date" controls on Planned Production Order page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding field i
        Initialize;

        MockProductionOrder(PlannedProdOrder, PlannedProdOrder.Status::Planned);

        PlannedProductionOrderCard.OpenEdit;
        PlannedProductionOrderCard.FILTER.SetFilter("No.", PlannedProdOrder."No.");
        PlannedProductionOrderCard."Starting Time".AssertEquals(DT2Time(PlannedProdOrder."Starting Date-Time"));
        PlannedProductionOrderCard."Starting Date".AssertEquals(DT2Date(PlannedProdOrder."Starting Date-Time"));
        PlannedProductionOrderCard."Ending Time".AssertEquals(DT2Time(PlannedProdOrder."Ending Date-Time"));
        PlannedProductionOrderCard."Ending Date".AssertEquals(DT2Date(PlannedProdOrder."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        PlannedProductionOrderCard."Starting Date".SetValue(NewDate);
        PlannedProdOrder.Find;
        PlannedProdOrder.TestField("Starting Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        PlannedProductionOrderCard."Starting Time".SetValue(NewTime);
        PlannedProdOrder.Find;
        PlannedProdOrder.TestField("Starting Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        PlannedProductionOrderCard."Ending Date".SetValue(NewDate);
        PlannedProdOrder.Find;
        PlannedProdOrder.TestField("Ending Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        PlannedProductionOrderCard."Ending Time".SetValue(NewTime);
        PlannedProdOrder.Find;
        PlannedProdOrder.TestField("Ending Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        PlannedProductionOrderCard."Due Date".SetValue(NewDate);
        PlannedProductionOrderCard."Ending Date".AssertEquals(NewDate - 1);

        PlannedProductionOrderCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnFirmPlannedProductionOrderCard()
    var
        FirmPlannedProdOrder: Record "Production Order";
        FirmPlannedProdOrderCard: TestPage "Firm Planned Prod. Order";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Time", "Starting Date", "Ending Time" and "Ending Date" controls on Firm Planned Production Order page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding fi
        Initialize;

        MockProductionOrder(FirmPlannedProdOrder, FirmPlannedProdOrder.Status::"Firm Planned");

        FirmPlannedProdOrderCard.OpenEdit;
        FirmPlannedProdOrderCard.FILTER.SetFilter("No.", FirmPlannedProdOrder."No.");
        FirmPlannedProdOrderCard."Starting Time".AssertEquals(DT2Time(FirmPlannedProdOrder."Starting Date-Time"));
        FirmPlannedProdOrderCard."Starting Date".AssertEquals(DT2Date(FirmPlannedProdOrder."Starting Date-Time"));
        FirmPlannedProdOrderCard."Ending Time".AssertEquals(DT2Time(FirmPlannedProdOrder."Ending Date-Time"));
        FirmPlannedProdOrderCard."Ending Date".AssertEquals(DT2Date(FirmPlannedProdOrder."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        FirmPlannedProdOrderCard."Starting Date".SetValue(NewDate);
        FirmPlannedProdOrder.Find;
        FirmPlannedProdOrder.TestField("Starting Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        FirmPlannedProdOrderCard."Starting Time".SetValue(NewTime);
        FirmPlannedProdOrder.Find;
        FirmPlannedProdOrder.TestField("Starting Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        FirmPlannedProdOrderCard."Ending Date".SetValue(NewDate);
        FirmPlannedProdOrder.Find;
        FirmPlannedProdOrder.TestField("Ending Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        FirmPlannedProdOrderCard."Ending Time".SetValue(NewTime);
        FirmPlannedProdOrder.Find;
        FirmPlannedProdOrder.TestField("Ending Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        FirmPlannedProdOrderCard."Due Date".SetValue(NewDate);
        FirmPlannedProdOrderCard."Ending Date".AssertEquals(NewDate - 1);

        FirmPlannedProdOrderCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnReleasedProductionOrderCard()
    var
        ReleasedProdOrder: Record "Production Order";
        ReleasedProductionOrderCard: TestPage "Released Production Order";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Time", "Starting Date", "Ending Time" and "Ending Date" controls on Released Production Order page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding field
        Initialize;

        MockProductionOrder(ReleasedProdOrder, ReleasedProdOrder.Status::Released);

        ReleasedProductionOrderCard.OpenEdit;
        ReleasedProductionOrderCard.FILTER.SetFilter("No.", ReleasedProdOrder."No.");
        ReleasedProductionOrderCard."Starting Time".AssertEquals(DT2Time(ReleasedProdOrder."Starting Date-Time"));
        ReleasedProductionOrderCard."Starting Date".AssertEquals(DT2Date(ReleasedProdOrder."Starting Date-Time"));
        ReleasedProductionOrderCard."Ending Time".AssertEquals(DT2Time(ReleasedProdOrder."Ending Date-Time"));
        ReleasedProductionOrderCard."Ending Date".AssertEquals(DT2Date(ReleasedProdOrder."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        ReleasedProductionOrderCard."Starting Date".SetValue(NewDate);
        ReleasedProdOrder.Find;
        ReleasedProdOrder.TestField("Starting Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ReleasedProductionOrderCard."Starting Time".SetValue(NewTime);
        ReleasedProdOrder.Find;
        ReleasedProdOrder.TestField("Starting Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        ReleasedProductionOrderCard."Ending Date".SetValue(NewDate);
        ReleasedProdOrder.Find;
        ReleasedProdOrder.TestField("Ending Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ReleasedProductionOrderCard."Ending Time".SetValue(NewTime);
        ReleasedProdOrder.Find;
        ReleasedProdOrder.TestField("Ending Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        ReleasedProductionOrderCard."Due Date".SetValue(NewDate);
        ReleasedProductionOrderCard."Ending Date".AssertEquals(NewDate - 1);

        ReleasedProductionOrderCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnFinishedProductionOrderCard()
    var
        FinishedProdOrder: Record "Production Order";
        FinishedProductionOrderCard: TestPage "Finished Production Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Time", "Starting Date", "Ending Time" and "Ending Date" controls on Finished Production Order page are expressions calculated from datetime fields. Finished production orders are not editable.
        Initialize;

        MockProductionOrder(FinishedProdOrder, FinishedProdOrder.Status::Finished);

        FinishedProductionOrderCard.OpenView;
        FinishedProductionOrderCard.FILTER.SetFilter("No.", FinishedProdOrder."No.");
        FinishedProductionOrderCard."Starting Time".AssertEquals(DT2Time(FinishedProdOrder."Starting Date-Time"));
        FinishedProductionOrderCard."Starting Date".AssertEquals(DT2Date(FinishedProdOrder."Starting Date-Time"));
        FinishedProductionOrderCard."Ending Time".AssertEquals(DT2Time(FinishedProdOrder."Ending Date-Time"));
        FinishedProductionOrderCard."Ending Date".AssertEquals(DT2Date(FinishedProdOrder."Ending Date-Time"));
        FinishedProductionOrderCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnSimulatedProductionOrderCard()
    var
        SimulatedProdOrder: Record "Production Order";
        SimulatedProductionOrderCard: TestPage "Simulated Production Order";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 331428] "Starting Time", "Starting Date", "Ending Time" and "Ending Date" controls on Simulated Production Order page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding field
        Initialize;

        MockProductionOrder(SimulatedProdOrder, SimulatedProdOrder.Status::Simulated);

        SimulatedProductionOrderCard.OpenEdit;
        SimulatedProductionOrderCard.FILTER.SetFilter("No.", SimulatedProdOrder."No.");
        SimulatedProductionOrderCard."Starting Time".AssertEquals(DT2Time(SimulatedProdOrder."Starting Date-Time"));
        SimulatedProductionOrderCard."Starting Date".AssertEquals(DT2Date(SimulatedProdOrder."Starting Date-Time"));
        SimulatedProductionOrderCard."Ending Time".AssertEquals(DT2Time(SimulatedProdOrder."Ending Date-Time"));
        SimulatedProductionOrderCard."Ending Date".AssertEquals(DT2Date(SimulatedProdOrder."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        SimulatedProductionOrderCard."Starting Date".SetValue(NewDate);
        SimulatedProdOrder.Find;
        SimulatedProdOrder.TestField("Starting Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        SimulatedProductionOrderCard."Starting Time".SetValue(NewTime);
        SimulatedProdOrder.Find;
        SimulatedProdOrder.TestField("Starting Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        SimulatedProductionOrderCard."Ending Date".SetValue(NewDate);
        SimulatedProdOrder.Find;
        SimulatedProdOrder.TestField("Ending Date", NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        SimulatedProductionOrderCard."Ending Time".SetValue(NewTime);
        SimulatedProdOrder.Find;
        SimulatedProdOrder.TestField("Ending Time", NewTime);

        NewDate := LibraryRandom.RandDate(30);
        SimulatedProductionOrderCard."Due Date".SetValue(NewDate);
        SimulatedProductionOrderCard."Ending Date".AssertEquals(NewDate - 1);

        SimulatedProductionOrderCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnProdOrderCapacityNeed()
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [Capacity Need] [UI]
        // [SCENARIO 331428] "Starting Time", "Ending Time" and "Date" controls on Capacity Need page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding field in the table.
        Initialize;

        ProdOrderCapacityNeed.Init();
        ProdOrderCapacityNeed."Prod. Order No." := LibraryUtility.GenerateGUID;
        ProdOrderCapacityNeed."Starting Date-Time" := CreateDateTime(WorkDate, 120000T);
        ProdOrderCapacityNeed."Ending Date-Time" := CreateDateTime(WorkDate + 30, 120000T);
        ProdOrderCapacityNeed.Insert();

        ProdOrderCapacityNeedPage.OpenEdit;
        ProdOrderCapacityNeedPage.FILTER.SetFilter("Prod. Order No.", ProdOrderCapacityNeed."Prod. Order No.");
        ProdOrderCapacityNeedPage."Starting Time".AssertEquals(DT2Time(ProdOrderCapacityNeed."Starting Date-Time"));
        ProdOrderCapacityNeedPage."Ending Time".AssertEquals(DT2Time(ProdOrderCapacityNeed."Ending Date-Time"));
        ProdOrderCapacityNeedPage.Date.AssertEquals(DT2Date(ProdOrderCapacityNeed."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        ProdOrderCapacityNeedPage.Date.SetValue(NewDate);
        ProdOrderCapacityNeed.Find;
        ProdOrderCapacityNeed.TestField(Date, NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ProdOrderCapacityNeedPage."Starting Time".SetValue(NewTime);
        ProdOrderCapacityNeed.Find;
        ProdOrderCapacityNeed.TestField("Starting Time", NewTime);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ProdOrderCapacityNeedPage."Ending Time".SetValue(NewTime);
        ProdOrderCapacityNeed.Find;
        ProdOrderCapacityNeed.TestField("Ending Time", NewTime);

        ProdOrderCapacityNeedPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnProdOrderRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Production Order Routing Line] [UT]
        // [SCENARIO 331428] GetStartingEndingDateAndTime function in Prod. Order Routing Line table initializes StartingTime, EndingTime, StartingDate, EndingDate variables used as expressions on time and date controls on Prod. Order Routing page.
        Initialize;

        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine."Prod. Order No." := LibraryUtility.GenerateGUID;
        ProdOrderRoutingLine."Starting Date-Time" := CreateDateTime(WorkDate, 120000T);
        ProdOrderRoutingLine."Ending Date-Time" := CreateDateTime(WorkDate + 30, 120000T);

        ProdOrderRoutingLine.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);

        Assert.AreEqual(DT2Time(ProdOrderRoutingLine."Starting Date-Time"), StartingTime, '');
        Assert.AreEqual(DT2Time(ProdOrderRoutingLine."Ending Date-Time"), EndingTime, '');
        Assert.AreEqual(DT2Date(ProdOrderRoutingLine."Starting Date-Time"), StartingDate, '');
        Assert.AreEqual(DT2Date(ProdOrderRoutingLine."Ending Date-Time"), EndingDate, '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Order III");
        LibraryVariableStorage.Clear;

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Order III");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        CreateLocationSetup;
        LibraryERMCountryData.UpdateInventoryPostingSetup;
        ItemJournalSetup;
        ConsumptionJournalSetup;
        OutputJournalSetup;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Order III");
    end;

    local procedure InitSetupForProdBOMWithMultipleUOM(var Item: Record Item; var ChildItem: Record Item; var QuantityPer: Decimal; var QtyPerUnitOfMeasure: Decimal; var AvailableQty: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        QuantityPer := LibraryRandom.RandIntInRange(2, 5);
        QtyPerUnitOfMeasure := LibraryRandom.RandIntInRange(2, 5);
        AvailableQty := LibraryRandom.RandIntInRange(50, 100);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ChildItem."No.", QtyPerUnitOfMeasure);
        UpdateBOMHeaderWithLineUOM(Item."Production BOM No.", ChildItem."No.", ItemUnitOfMeasure.Code);
        CreateAndPostItemJournalLine(ChildItem."No.", AvailableQty, '', '');
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWMS(LocationRed, true, false, false, false, false);  // Location Red.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, false, false, false);  // Location Blue.
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for number of Bins.

        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);  // Location Silver.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required for Number of Bins.
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessageForPlanningWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item: Record Item; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure MockSubcontractedJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        WorkCenter: Record "Work Center";
    begin
        with WorkCenter do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Subcontractor No." := LibraryUtility.GenerateGUID;
            Insert;
        end;

        with ItemJournalLine do begin
            Init;
            LibraryUtility.GetNewRecNo(ItemJournalLine, FieldNo("Line No."));
            "Entry Type" := "Entry Type"::Output;
            Type := Type::"Work Center";
            "Work Center No." := WorkCenter."No.";
            Insert;
        end;
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        CreateItem(Item2);

        // Create Production BOM, Parent Item and attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithBOMAndRouting(var Item: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Backward");
        UpdateBOMHeader(Item."Production BOM No.", ChildItem."No.", CreateRoutingAndUpdateItem(Item, WorkCenter));
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
    end;

    local procedure CreateItemWithRouting(): Code[20]
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
    begin
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        exit(Item."No.");
    end;

    local procedure CreateSimpleItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateItemSubstitution(ItemNo: array[10] of Code[20]; ItemIndex: Integer)
    var
        ItemSubstitution: Record "Item Substitution";
        i: Integer;
    begin
        with ItemSubstitution do begin
            Init;
            Type := Type::Item;
            "No." := ItemNo[ItemIndex];
            "Substitute Type" := "Substitute Type"::Item;
            for i := 0 to ArrayLen(ItemNo) - 2 do begin
                "Substitute No." := ItemNo[1 + ((ItemIndex + i) mod ArrayLen(ItemNo))]; // all ItemNo except ItemIndex
                Insert;
            end;
        end;
    end;

    local procedure CreateProdItemWithScrapAndFlushingMethod(var Item: Record Item; var ChildItemNo: Code[20]; FlushingMethod: Option; QtyPer: Decimal; MultipleRoutingLine: Boolean; ScrapFactor: Decimal; FixedScrapQuantity: Decimal; Tracking: Boolean)
    var
        ChildItem: Record Item;
    begin
        CreateItemsSetup(Item, ChildItem, QtyPer);
        ChildItemNo := ChildItem."No.";
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // Create Routing with 2 routing lines, set Scrap % and Fixed Scrap Quantity in Routing Line, set flushing method for work center bound to the routing line
        if Tracking then
            UpdateItemForLotTrackingAndFlushingMethod(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateRoutingWithScrapAndFlushingMethod(Item, FlushingMethod, MultipleRoutingLine, ScrapFactor, FixedScrapQuantity);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, '', '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostInvtAdjustmentOfItemWithLot(ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetValue);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; RunTime: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        with ItemJournalLine do begin
            Validate("Output Quantity", OutputQuantity);
            Validate("Run Time", RunTime);
            Validate("Unit Cost", UnitCost);
            Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryVariableStorage.Enqueue(NewWorksheetMsg);  // Required inside MessageHandler.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure AssignTrackingOnProdOrderLine(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst;
        ProdOrderLine.OpenItemTrackingLines;  // Invokes ItemTrackingPageHandler.
    end;

    local procedure CalculateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalWithExplodeRouting(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateLinkedProdBOMLineAndRoutingLine(var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingLineWithRoutingLink(RoutingLine, RoutingHeader, WorkCenterNo);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        ProductionBOMLine.Validate("Routing Link Code", RoutingLine."Routing Link Code");
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateOutputJournalWithExplodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        CreateOutputJournal(ItemJournalLine, ProductionOrderNo, '');
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputCorrectionWithLocationAndItemTracking(var Item: Record Item; var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; ApplyToItemEntry: Boolean)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Production Item, create a Require-Pick Location
        Initialize;
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity

        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), LocationCode, '');
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // Create Output Correction Journal with Location and Item Tracking.
        CreateOutputJournalWithApplyEntryAndItemTracking(
          Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.", ApplyToItemEntry);
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingHandler.
        ItemJournalLine.OpenItemTrackingLines(false); // Invokes ItemTrackingHandler.

        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithApplyEntryAndOperationNo(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10]; SetAppliesToEntry: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Operation No.", OperationNo);

        if SetAppliesToEntry then
            ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateOutputJournalWithApplyEntryAndItemTracking(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10]; ApplyToItemEntry: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingHandler.
        LibraryVariableStorage.Enqueue(ApplyToItemEntry); // Enqueue for ItemTrackingHandler.
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");  // Enqueue for ItemTrackingHandler.
        ItemJournalLine.OpenItemTrackingLines(false); // Invokes ItemTrackingHandler.

        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; MultipleLines: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if MultipleLines then
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderOnLocation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        UpdateLocationOnSalesLine(SalesLine."Document No.", LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity, true);  // Multiple Sales Lines TRUE.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Option; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name"; Type: Option)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst;
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateAndPostSalesOrderAsShip(var Item: Record Item; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, false);  // Multiple Sales Lines FALSE.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, WorkDate);
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 10);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(10, 2));  // Minimum Order Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Maximum Order Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderAsReceive(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesOrderFromBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        CreateBlanketOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CreateBlanketOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Item Tracking Code", CreateItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        if IsSubcontracted then
            WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingLineWithRoutingLink(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    var
        RoutingLink: Record "Routing Link";
    begin
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item; var WorkCenter: Record "Work Center"): Code[10]
    begin
        exit(CreateRoutingAndUpdateItemSubc(Item, WorkCenter, false));
    end;

    local procedure CreateRoutingAndUpdateItemSubc(var Item: Record Item; var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        CreateWorkCenter(WorkCenter, IsSubcontracted);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLink.FindFirst;
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(RoutingLink.Code);
    end;

    local procedure CreateItemSerialRoutingSeveralLines(LinesCount: Integer): Code[20]
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        I: Integer;
    begin
        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to LinesCount do begin
            CreateWorkCenter(WorkCenter, false);
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateFamily(var Family: Record Family; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, Quantity);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, Quantity);
    end;

    local procedure CreateItemHierarchyForFamily(var ParentItem: Record Item; var ParentItem2: Record Item; var ChildItem: Record Item; var ChildItem2: Record Item; QuantityPer: Decimal)
    begin
        CreateItemsSetup(ParentItem, ChildItem, QuantityPer);
        CreateItemsSetup(ParentItem2, ChildItem2, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100), '', '');
        CreateAndPostItemJournalLine(ChildItem2."No.", LibraryRandom.RandInt(100), '', '');
    end;

    local procedure CreateAndRefreshProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; Status: Option; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRequisitionLineWithPlanningRouting(var RequisitionLine: Record "Requisition Line"; var WorkCenter: Record "Work Center"; var ItemNo: Code[20])
    var
        Item: Record Item;
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        CreateWorkCenterWithLocationAndBin(WorkCenter, LocationRed.Code);
        CreateSalesOrderWithItem(Item);
        CreateRequisitionLineWithWorkCenter(RequisitionLine, WorkCenter, Item);
        CreatePlanningRoutingLineWithWorkCenter(PlanningRoutingLine, RequisitionLine, WorkCenter);
        ItemNo := Item."No.";
    end;

    local procedure CreateRequisitionLineWithWorkCenter(var RequisitionLine: Record "Requisition Line"; WorkCenter: Record "Work Center"; Item: Record Item)
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);  // Calculate Regenerative Plan on WORKDATE.
        FindRequisitionLine(RequisitionLine, Item."No.");
        with RequisitionLine do begin
            Validate("Location Code", WorkCenter."Location Code");
            Validate("Accept Action Message", true);
            Modify;
        end;
    end;

    local procedure CreateWorkCenterWithLocationAndBin(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        BinFrom: Record Bin;
        BinTo: Record Bin;
        BinOpenShopFloor: Record Bin;
    begin
        LibraryWarehouse.FindBin(BinFrom, LocationCode, '', 1);  // Find Bin of Index 1.
        LibraryWarehouse.FindBin(BinTo, LocationCode, '', 2);
        LibraryWarehouse.FindBin(BinOpenShopFloor, LocationCode, '', 3);

        CreateWorkCenter(WorkCenter, false);
        with WorkCenter do begin
            Validate("Location Code", LocationCode);
            Validate("From-Production Bin Code", BinFrom.Code);
            Validate("To-Production Bin Code", BinTo.Code);
            Validate("Open Shop Floor Bin Code", BinOpenShopFloor.Code);
            Modify;
        end;
    end;

    local procedure CreateWorkCenterWithNewToProductionBin(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        CreateWorkCenterWithLocationAndBin(WorkCenter, LocationCode);
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', '', '');
        WorkCenter.Validate("To-Production Bin Code", Bin.Code);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSalesOrderWithItem(var Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Replenishment System", "Replenishment System"::"Prod. Order");
            Validate("Reordering Policy", "Reordering Policy"::"Lot-for-Lot");
            Modify;
        end;

        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10), false);  // Multiple Sales Lines FALSE.
    end;

    local procedure CreatePlanningRoutingLineWithWorkCenter(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; WorkCenter: Record "Work Center")
    begin
        CreatePlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningRoutingLine.Validate("No.", WorkCenter."No.");
        PlanningRoutingLine.Modify();
    end;

    local procedure CreateMultipleItemUnitOfMeasureSetup(var Item: Record Item; var PurchItemUnitOfMeasure: Record "Item Unit of Measure"; var PutawayItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        QtyPerUnitOfMeasure: Integer;
    begin
        QtyPerUnitOfMeasure := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemUnitOfMeasureCode(PurchItemUnitOfMeasure, Item."No.", QtyPerUnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasureCode(PutawayItemUnitOfMeasure, Item."No.", 2 * QtyPerUnitOfMeasure);
        Item.Validate("Purch. Unit of Measure", PurchItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", PutawayItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateWhseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseJournalLine(var Item: Record Item; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
    end;

    local procedure CreateAndCertifyProdBOMWithMultipleComponent(var Item: Record Item; var Item2: Record Item; var Item3: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item);  // Parent Item.
        // Create Component Items.
        CreateItem(Item2);
        CreateItem(Item3);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
          ProductionBOMHeader, Item2."No.", Item3."No.", LibraryRandom.RandInt(5));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateAndPostOutputJournalWithApplyEntry(ItemNo: Code[20]; OutputQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalWithApplyEntryAndOperationNo(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        with ItemJournalLine do begin
            Validate("Output Quantity", OutputQuantity);
            Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
            Validate("Operation No.", OperationNo);
            Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
    end;

    local procedure CreateReversedOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; RoutingOperationNo: Code[10]; Qty: Decimal)
    begin
        CreateOutputJournal(ItemJournalLine, ProdOrderNo, ItemNo);
        ItemJournalLine.Validate("Output Quantity", Qty);
        ItemJournalLine.Validate("Operation No.", RoutingOperationNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(var Item: Record Item; var ChildItem: Record Item; var ProductionOrder: Record "Production Order")
    var
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        Quantity := LibraryRandom.RandInt(10);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostPurchaseOrderAsReceive(PurchaseHeader, ChildItem."No.", Quantity);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);  // Create and post Output Journal for the Production Order.
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; var NewProdOrderComponent: Record "Prod. Order Component"; QuantityPer: Decimal)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);
        NewProdOrderComponent.Validate("Item No.", Item."No.");
        NewProdOrderComponent.Validate("Quantity per", QuantityPer);
        NewProdOrderComponent.Insert(true);
    end;

    local procedure CreatePlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; var RequisitionLine: Record "Requisition Line")
    begin
        with PlanningRoutingLine do begin
            Init;
            Validate("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            Validate("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            Validate("Worksheet Line No.", RequisitionLine."Line No.");
            Validate("Operation No.", LibraryUtility.GenerateGUID);
            Insert(true);
        end;
    end;

    local procedure CreateCertifiedProductionBOMVersionWithCopyBOM(ProductionBOMNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo,
          LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"),
          UnitOfMeasureCode);
        ProductionBOMCopy.CopyBOM(ProductionBOMNo, '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderWithDirectUnitCostAsReceive(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateRoutingWithScrapAndFlushingMethod(var Item: Record Item; FlushingMethod: Option; MultipleRoutingLine: Boolean; ScrapFactor: Decimal; FixedScrapQuantity: Decimal)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        UpdateFlushingMethodOnWorkCenter(WorkCenter, FlushingMethod); // The flushing method on work center will be copied to Prod. Order Routing Line
        RoutingHeader.Get(Item."Routing No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");

        // Set Scrap on Routing Line
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.FindFirst;
        UpdateScrapOnRoutingLine(RoutingLine, ScrapFactor, FixedScrapQuantity);

        if MultipleRoutingLine then begin
            CreateWorkCenter(WorkCenter, false);
            UpdateFlushingMethodOnWorkCenter(WorkCenter, FlushingMethod); // The flushing method on work center will be copied to Prod. Order Routing Line
            CreateRoutingLineWithRoutingLink(RoutingLine, RoutingHeader, WorkCenter."No.");
            UpdateScrapOnRoutingLine(RoutingLine, LibraryRandom.RandDec(10, 2), LibraryRandom.RandInt(5));
        end;
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateAndInitNewProdOrderComponent(var NewProdOrderComponent: Record "Prod. Order Component"; var LastProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        FindLastProductionOrderCompLine(LastProdOrderComponent, ProdOrderLine);
        InitProdOrderComponent(NewProdOrderComponent, LastProdOrderComponent);
    end;

    local procedure CreateAddProdOrderLine(var NewProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        with NewProdOrderLine do begin
            Status := ProdOrderLine.Status;
            "Prod. Order No." := ProdOrderLine."Prod. Order No.";
            "Line No." := ProdOrderLine."Line No." + 10000;
            Validate("Item No.", ItemNo);
            Insert(true);
        end;
    end;

    local procedure CreateProdOrderLineWithDates(ProductionOrder: Record "Production Order"; StartingDate: Date; StartingTime: Time; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.",
          LibraryInventory.CreateItemNo, '', '', LibraryRandom.RandInt(10));
        ProdOrderLine."Starting Date" := StartingDate;
        ProdOrderLine."Starting Time" := StartingTime;
        ProdOrderLine."Ending Date" := ProdOrderLine."Starting Date";
        ProdOrderLine."Ending Time" := ProdOrderLine."Starting Time";
        ProdOrderLine."Due Date" := DueDate;
        ProdOrderLine.UpdateDatetime;
        ProdOrderLine.Modify();
    end;

    local procedure CreateAndPostSubcontractingPurchaseOrder(WorkCenter: Record "Work Center"; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID;
        PurchaseHeader.Modify();
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandInt(5);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateProdOrderAddNewComponentAndCreateConsumptionLine(var ProdOrderComponent: Record "Prod. Order Component"; CompLineQtyPer: Decimal)
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateLocation(Location);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, CompLineQtyPer);
        CreateAndPostItemJournalLine(ProdOrderComponent."Item No.", LibraryRandom.RandIntInRange(10, 100), '', '');

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption,
          ProdOrderComponent."Item No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateFinishedProdOrder(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with LibraryManufacturing do begin
            CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released,
              ProductionOrder."Source Type"::Item, ItemNo, Quantity);
            RefreshProdOrder(ProductionOrder, false, true, true, true, false);
            FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
            OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
            ChangeStatusReleasedToFinished(ProductionOrder."No.");
            exit(ProductionOrder."No.");
        end;
    end;

    local procedure DeleteReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.DeleteAll(true);
    end;

    local procedure EnqueueVariablesForItemAvailByBOMPage(ChildItemNo: Code[20]; AbleToMakeParentQty: Decimal; AbleToMakeTopItemQty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ChildItemNo);
        LibraryVariableStorage.Enqueue(AbleToMakeParentQty);
        LibraryVariableStorage.Enqueue(AbleToMakeTopItemQty);
    end;

    local procedure UpdateComponentsInventory(ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateAndPostItemJournalLine(ItemNo, Quantity, LocationCode, BinCode);
        CreateAndPostItemJournalLine(ItemNo2, Quantity, LocationCode, BinCode);
    end;

    local procedure OpenProductionJournalPage(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; EntryType: Option)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Enqueue values for use in ProductionJournalPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(EntryType);
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo2);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Option; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst;
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst;
    end;

    local procedure FindFirmPlannedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Option; ProdOrderNo: Code[20])
    begin
        with ProdOrderLine do begin
            SetRange(Status, ProdOrderStatus);
            SetRange("Prod. Order No.", ProdOrderNo);
            FindFirst;
        end;
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
    end;

    local procedure FindWarehouseReceiptNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Option; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst;
    end;

    local procedure PostPurchaseOrderAsShip(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Ship only.
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindLastProductionOrderCompLine(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
        with ProdOrderComponent do begin
            SetRange(Status, ProdOrderLine.Status);
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Line No.", ProdOrderLine."Line No.");
            FindLast;
        end;
    end;

    local procedure FindReleasedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Option; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Option)
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst;
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Option)
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst;
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceNo: Code[20]; ActionType: Option; ActivityType: Option)
    begin
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindFirst;
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; ActionType: Option; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."No.");
    end;

    local procedure FindAndRegisterWhseActivity(LocationCode: Code[10]; ProdOrderNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, ProdOrderNo, 0);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindLastRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindLast;
    end;

    local procedure FindFirstRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst;
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        with ProductionBOMLine do begin
            SetRange("Production BOM No.", ProductionBOMHeaderNo);
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            FindFirst;
        end;
    end;

    local procedure FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification: Option VerifyErr,VerifyItemLedgerEntry)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ItemJournalLine: Record "Item Journal Line";
        ChildItemNo: Code[20];
        Quantity: Decimal;
        QtyPer: Decimal;
        FixedScrapQuantity: Decimal;
    begin
        // Setup: Create a Product Item for Manual Flushing and scrap Routing
        // Create Child Item for Backward Flushing and Lot Tracking
        Initialize;
        Quantity := LibraryRandom.RandInt(100);
        QtyPer := 0.01 * LibraryRandom.RandInt(99); // Qty per need less than 1
        FixedScrapQuantity := LibraryRandom.RandInt(10);
        CreateProdItemWithScrapAndFlushingMethod(
          Item, ChildItemNo, WorkCenter."Flushing Method"::Manual, QtyPer, false, 0, FixedScrapQuantity, true);

        // Update Inventory for Component Item
        CreateAndPostItemJournalLineWithTracking(ChildItemNo, Quantity); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry

        // Create and Refresh Production Order and Assign Lot Item Tracking for Component Item
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');
        SelectItemTrackingForProdOrderComponents(ChildItemNo); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry

        // Open Production Journal Page, update Output Quantity and Post Production Journal on PostProductionJournalHandlerWithUpdateQuantity
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", Quantity, ItemJournalLine."Entry Type"::Output);

        case Verification of
            Verification::VerifyErr:
                begin
                    // Exercise: Change Status to Finished
                    // Verify: Error message pops up and error info is correct.
                    asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
                    Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QtyToHandleBaseInTrackingErr, Quantity * QtyPer)) > 0, GetLastErrorText);
                end;
            Verification::VerifyItemLedgerEntry:
                begin
                    // Update Quantity (Base) in Item Tracking for Prod. Order Components.
                    // Exercise: Change Status to Finished
                    UpdateQuantityBaseInTrackingForProdOrderComponents(ChildItemNo, Quantity * QtyPer); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry
                    LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

                    // Verify:  There is no error pops up when change status
                    // Verify Item Ledger Entries are correct for Consumption and Output Quantity
                    VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItemNo, -Quantity * QtyPer, '');
                    VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity, '');
                end;
        end;
    end;

    local procedure FilterValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemLedgerEntryType: Option)
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure MockItemLedgerEntryForConsumption(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
    begin
        with ItemLedgerEntry do begin
            Init;
            RecRef.GetTable(ItemLedgerEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Entry Type" := "Entry Type"::Consumption;
            "Order Type" := "Order Type"::Production;
            "Order No." := ProdOrderComponent."Prod. Order No.";
            "Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";
            Quantity := LibraryRandom.RandInt(10);
            Insert;
        end;
    end;

    local procedure MockProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Option)
    begin
        with ProductionOrder do begin
            Init;
            Status := ProdOrderStatus;
            "No." := LibraryUtility.GenerateGUID;
            "Starting Date-Time" := CreateDateTime(WorkDate, 120000T);
            "Ending Date-Time" := CreateDateTime(WorkDate + 30, 120000T);
            Insert;
        end;
    end;

    local procedure MockProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        with ProdOrderComponent do begin
            Init;
            Status := Status::Released;
            "Prod. Order No." := LibraryUtility.GenerateGUID;
            "Line No." := LibraryRandom.RandInt(10);
            "Item No." := LibraryUtility.GenerateGUID;
            "Qty. per Unit of Measure" := LibraryRandom.RandInt(10);
            Insert;

            BlockDynamicTracking(true); // prevents calling of VerifyQuantity function
        end;
    end;

    local procedure OpenReleasedProductionOrderStatisticsPage(var ProductionOrderStatistics: TestPage "Production Order Statistics"; ProductionOrderNo: Code[20])
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit;
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap;
        ReleasedProductionOrder.Statistics.Invoke;
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Option)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunItemAvailByBOMLevelPage(var Item: Record Item)
    var
        ItemAvailabilityByBOMLevel: Page "Item Availability by BOM Level";
    begin
        ItemAvailabilityByBOMLevel.InitItem(Item);
        ItemAvailabilityByBOMLevel.Run;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst;
    end;

    local procedure SelectSalesOrderLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst;
    end;

    local procedure SelectItemTrackingForProdOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit;
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);

        ProdOrderComponents.ItemTrackingLines.Invoke;
    end;

    local procedure UpdateBlanketOrderNoAndLocationOnSalesLine(var SalesLine: Record "Sales Line"; SalesLineBlanket: Record "Sales Line"; LocationCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Blanket Order No.", SalesLineBlanket."Document No.");
        SalesLine."Blanket Order Line No." := SalesLineBlanket."Line No.";
        SalesLine.Modify(true);
    end;

    local procedure UpdateManufacturingSetupComponentsAtLocation(NewComponentsAtLocation: Code[10]) ComponentsAtLocation: Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ComponentsAtLocation := ManufacturingSetup."Components at Location";
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicyOnItem(var Item: Record Item; OrderTrackingPolicy: Option)
    begin
        LibraryVariableStorage.Enqueue(TrackingMsg);  // Enqueue variable for use in MessageHandler.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanning(var Item: Record Item; ReplenishmentSystem: Option; ReorderingPolicy: Option)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldStockoutWarning: Boolean; var OldCreditWarnings: Option; NewStockoutWarning: Boolean; NewCreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateLocationSetup(var Location: Record Location; NewAlwaysCreatePickLine: Boolean) AlwaysCreatePickLine: Boolean
    begin
        AlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryWithWhseItemJournal(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create and register the Warehouse Item Journal Line.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLine(Item, WarehouseJournalLine, Location, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item, ItemJournalBatch);
    end;

    local procedure UpdateQuantityOnWarehouseActivityLine(SourceNo: Code[20]; ActionType: Option; Quantity: Decimal; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo, ActionType);
        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Option)
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnProdOrderRoutingLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        ProdOrderRoutingLine.Validate("Flushing Method", ProdOrderRoutingLine."Flushing Method"::Backward);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateProdBOMVersionCodeOnProdOrderLine(Item: Record Item)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMVersion.FindFirst;
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.Validate("Production BOM Version Code", ProductionBOMVersion."Version Code");
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateItemFlushingMethodPickAndBackward(var Item: Record Item)
    begin
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Backward");
        Item.Modify(true);
    end;

    local procedure UpdateItemForLotTrackingAndFlushingMethod(var Item: Record Item; FlushingMethod: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        with Item do begin
            Validate("Item Tracking Code", CreateItemTrackingCode);
            Validate("Lot Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Flushing Method", FlushingMethod);
            Validate("Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
            Modify(true);
        end;
    end;

    local procedure UpdateItemManufacturingProperties(var Item: Record Item; ProdBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        with Item do begin
            Validate("Replenishment System", "Replenishment System"::"Prod. Order");
            Validate("Reordering Policy", "Reordering Policy"::"Lot-for-Lot");
            Validate("Production BOM No.", ProdBOMNo);
            Validate("Routing No.", RoutingNo);
            Modify(true);
        end;
    end;

    local procedure UpdateInventorySetup(var InventorySetup: Record "Inventory Setup")
    var
        InventorySetup2: Record "Inventory Setup";
    begin
        // Enqueue values for use in MessageHandler.
        LibraryVariableStorage.Enqueue(ChangeExpectedCostPostingToGLMsg);
        LibraryVariableStorage.Enqueue(ExpectedCostPostingChangedMsg);
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMsg);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        InventorySetup.Get();  // To maintain the original state of setup.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup2."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");  // Update few parameters to effect restore.
    end;

    local procedure UpdateItemOverheadRate(var Item: Record Item)
    begin
        Item.Validate("Overhead Rate", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure UpdateItemInventoryForLocation(Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        Zone: Record Zone;
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        Bin.Get(Location.Code, Location."Open Shop Floor Bin Code");
        Zone.Get(Location.Code, Bin."Zone Code");
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Zone.Code,
          Location."Open Shop Floor Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item, ItemJournalBatch);
    end;

    local procedure UpdateLocationAndBins(var Location: Record Location)
    var
        Bin2: Record Bin;
        Bin3: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin2, Location.Code, '', 2); // Find Bin of Index 2.
        LibraryWarehouse.FindBin(Bin3, Location.Code, '', 3); // Find Bin of Index 3.
        with Location do begin
            Validate("Require Shipment", true);
            Validate("Require Put-away", false);
            Validate("To-Production Bin Code", Bin2.Code);
            Validate("From-Production Bin Code", Bin3.Code);
            Modify(true);
        end;
    end;

    local procedure UpdateBOMHeader(ProductionBOMNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Update Routing link Code on specified BOM component Lines.
        with ProductionBOMHeader do begin
            SetRange("No.", ProductionBOMNo);
            FindFirst;
            Validate(Status, Status::"Under Development");
            Modify(true);
        end;
        UpdateBOMLineRoutingLinkCode(ProductionBOMNo, ItemNo, RoutingLinkCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateBOMLineRoutingLinkCode(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateBOMHeaderWithLineUOM(ProductionBOMNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Update Unit of Measure Code on specified BOM component Line.
        with ProductionBOMHeader do begin
            SetRange("No.", ProductionBOMNo);
            FindFirst;
            Validate(Status, Status::"Under Development");
            Modify(true);
        end;
        UpdateBOMLineUOM(ProductionBOMNo, ItemNo, UnitOfMeasureCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateBOMLineUOM(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateLocationOnSalesLine(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantCodeInProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemVariantCode: Code[10])
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.FindFirst;
        ProdOrderLine.Validate("Variant Code", ItemVariantCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateQuantityBaseInTrackingForProdOrderComponents(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit;
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQuantityBase);
        LibraryVariableStorage.Enqueue(Qty);

        ProdOrderComponents.ItemTrackingLines.Invoke;
    end;

    local procedure UpdateScrapOnRoutingLine(var RoutingLine: Record "Routing Line"; ScrapFactor: Decimal; FixedScrapQuantity: Decimal)
    begin
        RoutingLine.Validate("Scrap Factor %", ScrapFactor);
        RoutingLine.Validate("Fixed Scrap Quantity", FixedScrapQuantity);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Option)
    begin
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure ResetInventorySetup(var InventorySetup: Record "Inventory Setup")
    begin
        LibraryVariableStorage.Enqueue(ChangeExpectedCostPostingToGLMsg);
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMsg);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderVATBusPostingGroup(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("VAT Bus. Posting Group", GetDifferentVATBusPostingGroup(PurchaseHeader."VAT Bus. Posting Group"));
        PurchaseHeader.Modify(true);
    end;

    local procedure GetDifferentVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusPostingGroup.SetFilter(Code, '<>%1', VATBusPostingGroupCode);
        VATBusPostingGroup.FindFirst;
        exit(VATBusPostingGroup.Code);
    end;

    local procedure InitProdOrderComponent(var NewProdOrderComponent: Record "Prod. Order Component"; OldProdOrderComponent: Record "Prod. Order Component")
    begin
        with NewProdOrderComponent do begin
            Init;
            Status := OldProdOrderComponent.Status;
            "Prod. Order No." := OldProdOrderComponent."Prod. Order No.";
            "Prod. Order Line No." := OldProdOrderComponent."Prod. Order Line No.";
            "Line No." := OldProdOrderComponent."Line No." + 10000;
            Validate("Item No.", OldProdOrderComponent."Item No.");
            Validate("Location Code", OldProdOrderComponent."Location Code");
        end;
    end;

    local procedure VerifyValueEntryForEntryType(EntryType: Option; DocumentNo: Code[20]; ItemLedgerEntryQuantity: Decimal; CostPostedToGL: Decimal; InvoicedQuantity: Decimal; CostPerUnit: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntry(ValueEntry, DocumentNo, ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.FindFirst;
        ValueEntry.TestField("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.TestField("Cost Posted to G/L", CostPostedToGL);
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ValueEntry.TestField("Cost per Unit", CostPerUnit);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyUOMOnWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer)
    begin
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
    end;

    local procedure VerifyProdOrderLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Location Code", LocationCode);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Location Code", LocationCode)
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            SetRange("Entry Type", EntryType);
            SetRange("Item No.", ItemNo);
            SetRange("Source No.", SourceNo);
            FindFirst;
            TestField("Location Code", LocationCode);
            TestField("Bin Code", BinCode);
            TestField(Quantity, Qty);
        end;
    end;

    local procedure VerifyOrderTrackingForProductionOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        OrderTracking: Page "Order Tracking";
        OrderTracking2: TestPage "Order Tracking";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        OrderTracking.SetProdOrderLine(ProdOrderLine);
        OrderTracking2.Trap;
        OrderTracking.Run;
        repeat
            OrderTracking2."Item No.".AssertEquals(ItemNo);
            OrderTracking2.Quantity.AssertEquals(Quantity);
        until not OrderTracking2.Next;
    end;

    local procedure VerifyPlanningComponentBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", ItemNo);
        PlanningComponent.FindFirst;
        PlanningComponent.TestField("Location Code", LocationCode);
        PlanningComponent.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyProdOrderLineBinCode(ItemNo: Code[20]; WorkCenterBinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with ProdOrderLine do begin
            SetRange("Item No.", ItemNo);
            FindFirst;
            Assert.AreEqual(WorkCenterBinCode, "Bin Code", ProdOrderLineBinCodeErr);
        end;
    end;

    local procedure VerifyPurchaseLine(No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRecreatedPurchaseLine(PurchaseLine: Record "Purchase Line"; VATBusPostingGroupCode: Code[20])
    var
        RecreatedPurchaseLine: Record "Purchase Line";
    begin
        with RecreatedPurchaseLine do begin
            SetRange("Document Type", PurchaseLine."Document Type");
            SetRange("Document No.", PurchaseLine."Document No.");
            FindFirst;  // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
            TestField(Description, PurchaseLine.Description);
            TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
            TestField("Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            TestField("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
            TestField("VAT Identifier", PurchaseLine."VAT Identifier");
            TestField("Qty. per Unit of Measure", PurchaseLine."Qty. per Unit of Measure");
            TestField("Expected Receipt Date", PurchaseLine."Expected Receipt Date");
            TestField("Requested Receipt Date", PurchaseLine."Requested Receipt Date");
            TestField("VAT Bus. Posting Group", VATBusPostingGroupCode);
        end;
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; ActionMessage: Option; Quantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyRequisitionLineWithLocation(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ActionMessage: Option)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit;
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap;
        FinishedProductionOrder.Statistics.Invoke;
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyTotalActualCostOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit;
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap;
        FinishedProductionOrder.Statistics.Invoke;
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyCostAmountActualOnReleasedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        ReleasedProductionOrder.OpenEdit;
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap;
        ReleasedProductionOrder.Statistics.Invoke;
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal; ReservationStatus: Option; LocationCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst;
        ReservationEntry.TestField(Quantity, Quantity);
        ReservationEntry.TestField("Reservation Status", ReservationStatus);
        ReservationEntry.TestField("Lot No.");
        ReservationEntry.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyRequisitionLineForSubcontract(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Prod. Order No.", ProductionOrder."No.");
        RequisitionLine.TestField(Quantity, ProductionOrder.Quantity);
        RequisitionLine.TestField("Work Center No.", WorkCenter."No.");
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
    end;

    local procedure VerifyReleasedProdOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    local procedure VerifyRegisteredWhseActivityLine(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer; Quantity: Decimal)
    begin
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyFinishedProdOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Finished);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Item No.", ItemNo);
        PostedInvtPickLine.FindSet;
        repeat
            PostedInvtPickLine.TestField("Bin Code", BinCode);
            PostedInvtPickLine.TestField(Quantity, Quantity);
            PostedInvtPickLine.TestField("Location Code", LocationCode);
        until PostedInvtPickLine.Next = 0;
    end;

    local procedure VerifyWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Qty. (Base)", Quantity);
    end;

    local procedure VerifyValueEntry(ItemNo: Code[20]; DocumentNo: Code[20]; ItemLedgerEntryType: Option; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntry(ValueEntry, DocumentNo, ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst;
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyValueEntrySource(ProdOrderNo: Code[20]; SourceNo: Code[20]; SourceType: Option " ",Customer,Vendor,Item)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Order No.", ProdOrderNo);
            FindSet;
            repeat
                Assert.AreEqual(SourceType, "Source Type", StrSubstNo(ValueEntrySourceTypeErr, SourceType));
                Assert.AreEqual(SourceNo, "Source No.", StrSubstNo(ValueEntrySourceNoErr, SourceNo));
            until Next = 0;
        end;
    end;

    local procedure VerifyProdOrderComponent(ProdOrderNo: Code[20]; Status: Option; ItemNo: Code[20]; QtyPicked: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Qty. Picked", QtyPicked);
        ProdOrderComponent.TestField("Qty. Picked (Base)", QtyPicked);
    end;

    local procedure VerifyProductionOrderIsEmpty(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        Assert.RecordIsEmpty(ProductionOrder);
    end;

    local procedure VerifyOutputItemLedgerEntry(ItemNo: Code[20]; Location: Code[10]; Qty: Decimal; Qty2: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            SetRange("Entry Type", "Entry Type"::Output);
            SetRange("Item No.", ItemNo);
            FindSet;
            TestField(Quantity, Qty);
            TestField("Location Code", Location);
            Next;
            TestField(Quantity, Qty2);
            TestField("Location Code", Location);
        end;
    end;

    local procedure VerifyReversedOutputItemLedgerEntry(ItemNo: Code[20])
    var
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PositiveItemLedgerEntry.SetRange(Positive, true);
        FindItemLedgerEntry(PositiveItemLedgerEntry, PositiveItemLedgerEntry."Entry Type"::Output, ItemNo);

        NegativeItemLedgerEntry.SetRange(Positive, false);
        FindItemLedgerEntry(NegativeItemLedgerEntry, NegativeItemLedgerEntry."Entry Type"::Output, ItemNo);
        NegativeItemLedgerEntry.TestField("Applies-to Entry", PositiveItemLedgerEntry."Entry No.");
        NegativeItemLedgerEntry.TestField("Lot No.", PositiveItemLedgerEntry."Lot No.");
        NegativeItemLedgerEntry.TestField("Serial No.", PositiveItemLedgerEntry."Serial No.");
    end;

    local procedure VerifyBinCodeInProductionOrderLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyItemAvailabilityByBOMPage(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    var
        ChildItemNo: Variant;
        AbleToMakeParentQty: Variant;
        AbleToMakeTopItemQty: Variant;
    begin
        LibraryVariableStorage.Dequeue(ChildItemNo);
        LibraryVariableStorage.Dequeue(AbleToMakeParentQty);
        LibraryVariableStorage.Dequeue(AbleToMakeTopItemQty);

        ItemAvailByBOMLevel."No.".AssertEquals(ChildItemNo);
        ItemAvailByBOMLevel."Able to Make Parent".AssertEquals(AbleToMakeParentQty);
        ItemAvailByBOMLevel."Able to Make Top Item".AssertEquals(AbleToMakeTopItemQty);
    end;

    local procedure VerifyWhseRequestExist(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        with WarehouseRequest do begin
            SetRange("Source Type", DATABASE::"Prod. Order Component");
            SetRange("Source Subtype", 3); // Released
            SetRange("Source No.", DocumentNo);
            SetRange("Location Code", LocationCode);
            Assert.IsTrue(FindFirst, StrSubstNo(WhseRequestErr, DocumentNo));
        end;
    end;

    local procedure VerifyWhsePickRequestExist(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        with WhsePickRequest do begin
            SetRange("Document Type", "Document Type"::Production);
            SetRange("Document Subtype", 3); // Released
            SetRange("Document No.", DocumentNo);
            SetRange("Location Code", LocationCode);
            Assert.IsTrue(FindFirst, StrSubstNo(WhsePickRequestErr, DocumentNo));
        end;
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke;
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        ApplToItemEntryNo: Integer;
        LotNo: Code[10];
        SerialNo: Code[10];
        Quantity: Decimal;
        ApplyToItemEntry: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;

        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke;  // Assign Lot No.
                    LotNo := ItemTrackingLines."Lot No.".Value;
                end;
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke;  // Assign Serial No.
                    SerialNo := ItemTrackingLines."Serial No.".Value;
                end;
            ItemTrackingMode::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke;  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ApplyToItemEntry := DequeueVariable;
                    if ApplyToItemEntry then begin
                        LibraryVariableStorage.Dequeue(DequeueVariable);
                        ApplToItemEntryNo := DequeueVariable;
                        ItemTrackingLines."Appl.-to Item Entry".SetValue(ApplToItemEntryNo);
                    end;
                end;
            ItemTrackingMode::SetValue:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    LotNo := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    SerialNo := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity := DequeueVariable;

                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
        end;

        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingHandlerWithoutApplyToItemEntry(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        LotNo: Code[10];
        SerialNo: Code[10];
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;

        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke;  // Assign Lot No.
                    LotNo := ItemTrackingLines."Lot No.".Value;
                end;
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke;  // Assign Serial No.
                    SerialNo := ItemTrackingLines."Serial No.".Value;
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke;  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
            ItemTrackingMode::SetValue:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    LotNo := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    SerialNo := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity := DequeueVariable;

                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            ItemTrackingMode::UpdateQuantityBase:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
        end;

        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
        Quantity: Variant;
        EntryType: Variant;
        EntryType2: Option;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(EntryType);
        EntryType2 := EntryType;
        ProductionJournal.FILTER.SetFilter("Item No.", ItemNo);
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(EntryType2));
        ProductionJournal.Quantity.AssertEquals(Quantity);
        ProductionJournal."Output Quantity".AssertEquals(Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMsg);  // Required inside ConfirmHandlerTRUE.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);  // Required inside MessageHandler.
        ProductionJournal.Post.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandlerWithUpdateQuantity(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
        Quantity: Variant;
        EntryType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(EntryType);
        ProductionJournal.FILTER.SetFilter("Item No.", ItemNo);
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(EntryType));
        ProductionJournal.Last;
        ProductionJournal."Output Quantity".SetValue(Quantity);

        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMsg); // Required inside ConfirmHandlerTRUE.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg); // Required inside MessageHandler.
        LibraryVariableStorage.Enqueue(LeaveProductionJournalQst); // Required inside MessageHandler.
        ProductionJournal.Post.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByBOMPageHandler(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    begin
        ItemAvailByBOMLevel.Expand(true);
        ItemAvailByBOMLevel.Next;
        VerifyItemAvailabilityByBOMPage(ItemAvailByBOMLevel);

        ItemAvailByBOMLevel.Expand(true);
        ItemAvailByBOMLevel.Next;
        VerifyItemAvailabilityByBOMPage(ItemAvailByBOMLevel);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstEntries_MPH(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.First;
        repeat
            LibraryVariableStorage.Enqueue(ItemSubstitutionEntries."Substitute No.".Value);
        until not ItemSubstitutionEntries.Next;
        ItemSubstitutionEntries.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalSubcontractedPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First;
        Assert.AreEqual(0, ProductionJournal."Output Quantity".AsDEcimal, ProdJournalOutQtyErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    begin
        ProdOrderRouting.OK.Invoke;
    end;
}

