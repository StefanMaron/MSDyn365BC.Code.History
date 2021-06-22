codeunit 137080 "SCM Planning And Manufacturing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        NoActionMessagesExistError: Label 'No action messages exist.';
        ChangeWillNotAffect: Label 'The change will not affect existing entries';
        IllegalActionMessageRelation: Label 'Illegal Action Message relation.';
        YouWantToContinueConfirm: Label 'Are you sure that you want to continue?';
        PostJournalLinesConfirm: Label 'Do you want to post the journal lines?';
        JournalLinesSuccessfullyPosted: Label 'The journal lines were successfully posted.';
        ReservationEntryMustBeEmpty: Label 'Reservation Entry must be empty.';
        ConfirmDeleteItemTracking: Label 'Item tracking is defined for item';
        DueDateErr: Label 'Requisition Line Due Date for proposed Production Order can''t be later than demand Sales Order.';
        StatusMustBeCertifiedErr: Label 'Routing Header No. %1 is not certified.', Comment = '%1 - Routing No.';
        ErrorsWhenPlanningMsg: Label 'Not all items were planned.';
        OnlyOneRecordErr: Label 'Only one record is expected.';

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize;
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", LocationBlue.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalcDate(Vendor."Lead Time Calculation", WorkDate);  // Value required for test.
        ExpectedReceiptDate :=
          CalcDate('<' + GetDefaultSafetyLeadTime + '>', CalcDate(LocationBlue."Inbound Whse. Handling Time", PlannedReceiptDate));  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnPurchaseOrderUsingBaseCalendar()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Location: Record Location;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate + 1, CalcDate(Vendor."Lead Time Calculation", WorkDate), 1);  // Use 1 for Forward Planning.
        ExpectedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            PlannedReceiptDate,
            CalcDate('<' + GetDefaultSafetyLeadTime + '>', CalcDate(Location."Inbound Whse. Handling Time", PlannedReceiptDate)), 1);  // Use 1 for Forward Planning.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnRequisitionLine()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ExpectedReceiptDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize;
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", LocationBlue.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalcDate(Vendor."Lead Time Calculation", WorkDate);  // Value required for test.
        ExpectedReceiptDate :=
          CalcDate('<' + GetDefaultSafetyLeadTime + '>', CalcDate(LocationBlue."Inbound Whse. Handling Time", PlannedReceiptDate));  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnRequisitionLineUsingBaseCalendar()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location;
        ExpectedReceiptDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", Location.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate + 1, CalcDate(Vendor."Lead Time Calculation", WorkDate), 1);  // Use 1 for Forward Planning.
        ExpectedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            PlannedReceiptDate,
            CalcDate('<' + GetDefaultSafetyLeadTime + '>', CalcDate(Location."Inbound Whse. Handling Time", PlannedReceiptDate)), 1);  // Use 1 for Forward Planning.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PlannedReceiptDate: Date;
        OrderDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize;
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", LocationBlue.Code, WorkDate);

        // Verify.
        PlannedReceiptDate :=
          CalcDate(
            '<-' + GetDefaultSafetyLeadTime + '>', CalcDate('<-' + Format(LocationBlue."Inbound Whse. Handling Time") + '>', WorkDate));  // Value required for test.
        OrderDate := CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate);  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnPurchaseOrderUsingBaseCalendar()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Location: Record Location;
        PlannedReceiptDate: Date;
        OrderDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, WorkDate);

        // Verify.
        PlannedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate(
              '<-' + GetDefaultSafetyLeadTime + '>', CalcDate('<-' + Format(Location."Inbound Whse. Handling Time") + '>', WorkDate)),
            WorkDate - 1, -1);  // Use -1 for Backward Planning.
        OrderDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate), PlannedReceiptDate, -1);  // Use -1 for Backward Planning.
        ExpectedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate, WorkDate, 1);
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnRequisitionLine()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        OrderDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize;
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", LocationBlue.Code, WorkDate);

        // Verify.
        PlannedReceiptDate :=
          CalcDate(
            '<-' + GetDefaultSafetyLeadTime + '>', CalcDate('<-' + Format(LocationBlue."Inbound Whse. Handling Time") + '>', WorkDate));  // Value required for test.
        OrderDate := CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate);  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnRequisitionLineUsingBaseCalendar()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location;
        OrderDate: Date;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", Location.Code, WorkDate);

        // Verify.
        PlannedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate(
              '<-' + GetDefaultSafetyLeadTime + '>', CalcDate('<-' + Format(Location."Inbound Whse. Handling Time") + '>', WorkDate)),
            WorkDate - 1, -1);  // Use -1 for Backward Planning.
        OrderDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate), PlannedReceiptDate, -1);  // Use -1 for Backward Planning.
        ExpectedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate, WorkDate, 1);
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorNoActionMessagesExistOnGetActionMessages()
    var
        Item: Record Item;
    begin
        // Setup: Create Item.
        Initialize;
        LibraryInventory.CreateItem(Item);

        // Exercise.
        asserterror LibraryPlanning.GetActionMessages(Item);

        // Verify.
        Assert.ExpectedError(NoActionMessagesExistError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithPurchaseReplenishmentSystem()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithPurchaseReplenishmentSystem(false, false);  // Use BeforeIllegalActionMessage and AfterIllegalActionMessage as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorIllegalMessageRelationOnGetActionMessages()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithPurchaseReplenishmentSystem(true, false);  // Use BeforeIllegalActionMessage as True and AfterIllegalActionMessage as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GetActionMessagesAfterIllegalActionMessage()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithPurchaseReplenishmentSystem(true, true);  // Use BeforeIllegalActionMessage and AfterIllegalActionMessage as True.
    end;

    local procedure GetActionMessagesWithPurchaseReplenishmentSystem(BeforeIllegalActionMessage: Boolean; AfterIllegalActionMessage: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order with New Item having Purchase Replenishment System and Make-to-Order Manufacturing Policy.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Manufacturing Policy"::"Make-to-Order");
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify.
        VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, false, RequisitionLine."Ref. Order Type"::Purchase);  // Use AcceptActionMessage as False.

        if BeforeIllegalActionMessage then begin
            // Exercise.
            UpdateQuantityOnSalesLine(SalesLine);
            DeleteRequisitionLine(Item."No.");
            asserterror LibraryPlanning.GetActionMessages(Item);

            // Verify.
            Assert.ExpectedError(IllegalActionMessageRelation);
        end;

        if AfterIllegalActionMessage then begin
            // Exercise.
            DeleteRequisitionLine(Item."No.");
            UpdateQuantityOnSalesLine(SalesLine);
            LibraryPlanning.GetActionMessages(Item);

            // Verify.
            VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, true, RequisitionLine."Ref. Order Type"::Purchase);  // Use AcceptActionMessage as True.
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderReplenishmentSystem()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithProdOrderReplenishmentSystem(false, false);  // Use CarryOutActionMessage and UpdateQuantity as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgWithProdOrderReplenishmentSystem()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithProdOrderReplenishmentSystem(true, false);  // Use CarryOutActionMessage as True and UpdateQuantity as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GetActionMessagesWithUpdatedQuantity()
    begin
        // Setup.
        Initialize;
        GetActionMessagesWithProdOrderReplenishmentSystem(true, true);  // Use CarryOutActionMessage and UpdateQuantity as True.
    end;

    local procedure GetActionMessagesWithProdOrderReplenishmentSystem(CarryOutActionMessage: Boolean; UpdateQuantity: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
        OldPlanningWarning: Boolean;
    begin
        // Update Planning Warning on Manufacturing Setup. Create Sales Order with New Item having Production Order Replenishment System and Make-to-Stock Manufacturing Policy.
        UpdatePlanningWarningOnManufacturingSetup(OldPlanningWarning, false);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Manufacturing Policy"::"Make-to-Stock");
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify.
        VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, false, RequisitionLine."Ref. Order Type"::"Prod. Order");  // Use AcceptActionMessage as False.

        if CarryOutActionMessage then begin
            // Exercise.
            CarryOutActionMessageOnPlanningWorksheet(Item."No.");

            // Verify.
            VerifyProductionOrder(SalesLine);
        end;

        if UpdateQuantity then begin
            // Exercise.
            UpdateQuantityOnSalesLine(SalesLine);
            LibraryPlanning.GetActionMessages(Item);

            // Verify.
            VerifyRequisitionLine(
              SalesLine, RequisitionLine."Action Message"::"Change Qty.", true, RequisitionLine."Ref. Order Type"::"Prod. Order");  // Use AcceptActionMessage as True.
        end;

        // Tear down.
        UpdatePlanningWarningOnManufacturingSetup(OldPlanningWarning, OldPlanningWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalAfterExplodeRouting()
    begin
        // Setup.
        Initialize;
        FinishedRoutingStatusAfterPostOutputJournal(false, false, false);  // Use PostOutputJournal, Finished and UpdateRoutingStatus as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostUnfinishedOutputAfterDeleteOutputJournalLine()
    begin
        // Setup.
        Initialize;
        FinishedRoutingStatusAfterPostOutputJournal(true, false, false);  // Use PostOutputJournal as True. Use Finished and UpdateRoutingStatus as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFinishedOutputAfterDeleteOutputJournalLine()
    begin
        // Setup.
        Initialize;
        FinishedRoutingStatusAfterPostOutputJournal(true, true, false);  // Use PostOutputJournal and Finished as True. Use UpdateRoutingStatus as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinishedRoutingStatusAfterPostUnfinishedOutput()
    begin
        // Setup.
        Initialize;
        FinishedRoutingStatusAfterPostOutputJournal(true, false, true);  // Use PostOutputJournal and UpdateRoutingStatus as True. Use Finished as False.
    end;

    local procedure FinishedRoutingStatusAfterPostOutputJournal(PostOutputJournal: Boolean; Finished: Boolean; UpdateRoutingStatus: Boolean)
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // Create Item with Routing. Create and refresh Released Production Order.
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, '', true);  // Use Blank for Item Tracking Code and True for with Machine Center.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");

        // Exercise.
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", false);

        // Verify.
        VerifyOutputJournalLine(ProductionOrder, RoutingLine);
        VerifyOutputJournalLine(ProductionOrder, RoutingLine2);

        if PostOutputJournal then begin
            // Exercise.
            PostOutputJournalAfterDeleteOutputJournalLine(ProductionOrder, RoutingLine, RoutingLine2, Finished);

            // Verify.
            if Finished then begin
                VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run, 0);  // Use 0 for Allocated Time.
                VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, 0);  // Use 0 for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run,
                  RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, RoutingLine2."Setup Time");
            end else begin
                VerifyProductionOrderCapacityNeed(
                  RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run,
                  RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, RoutingLine."Setup Time");
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run,
                  RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, RoutingLine2."Setup Time");
            end;
        end;

        if UpdateRoutingStatus then begin
            // Exercise.
            UpdateFinishedRoutingStatusOnProdOrderRoutingLine(ProductionOrder."No.", RoutingLine."Operation No.");

            // Verify.
            VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run, 0);  // Use 0 for Allocated Time.
            VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, 0);  // Use 0 for Allocated Time.
            VerifyProductionOrderCapacityNeed(
              RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Run,
              RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
            VerifyProductionOrderCapacityNeed(
              RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::Setup, RoutingLine2."Setup Time");
        end;
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,ItemTrackingLinesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalUsingLotItemTracking()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        LotNo: Code[20];
    begin
        // Setup: Create Item with Routing.
        Initialize;
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, CreateLotItemTrackingCode, true);  // Use True for with Machine Center.

        // Exercise.
        LotNo := PostProductionJournalFromRPOWithLot(ProductionOrder, Item."No.");

        // Verify.
        VerifyItemLedgerEntry(ProductionOrder, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OutputJournalForMultipleExplodeRoutingUsingLot()
    begin
        // Setup.
        Initialize;
        PostOutputJournalUsingLotForMultipleExplodeRouting(false);  // Use False for Post Output.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputJournalForMultipleExplodeRoutingUsingLot()
    begin
        // Setup.
        Initialize;
        PostOutputJournalUsingLotForMultipleExplodeRouting(true);  // Use True for Post Output.
    end;

    local procedure PostOutputJournalUsingLotForMultipleExplodeRouting(PostOutput: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        LotNo: Code[20];
        LotNo2: Code[20];
    begin
        // Create Lot Item with Production BOM. Create and refresh Released Production Order. Add Lot Item Tracking to Output Journal Line after Explode Routing.
        CreateLotItemWithProductionBOM(Item);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", true);
        LotNo := AddLotItemTrackingToOutputJournalLine(ItemJournalLine, ProductionOrder);

        // Exercise.
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", true);
        LotNo2 := AddLotItemTrackingToOutputJournalLine(ItemJournalLine, ProductionOrder);

        // Verify.
        VerifyReservationEntry(ProductionOrder, LotNo2);
        VerifyEmptyReservationEntry(Item."No.", LotNo);

        if PostOutput then begin
            // Exercise.
            LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

            // Verify.
            VerifyEmptyReservationEntry(Item."No.", LotNo2);
            VerifyEmptyReservationEntry(Item."No.", LotNo);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderCapacityNeedWithoutWaitTime()
    begin
        // Setup.
        Initialize;
        ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(false);  // Use False for without Wait Time.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderCapacityNeedWithWaitTime()
    begin
        // Setup.
        Initialize;
        ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(true);  // Use True for with Wait Time.
    end;

    local procedure ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(WithWaitTime: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // Create Item with Routing.
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, '', false);  // Use Blank for Item Tracking Code and False for without Machine Center.

        // Exercise.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");

        // Verify.
        ProductionOrder.Find;
        VerifyProdOrderCapacityNeedWithStartingTime(
          RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Input, ProdOrderCapacityNeed."Time Type"::Run,
          ProductionOrder."Starting Time", RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
        VerifyProdOrderCapacityNeedWithStartingTime(
          RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Input, ProdOrderCapacityNeed."Time Type"::Run,
          ProductionOrder."Starting Time" + RoutingLine."Run Time" * ProductionOrder.Quantity * 60000,
          RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Starting Time and Allocated Time.

        if WithWaitTime then begin
            // Exercise.
            UpdateWaitTimeOnProdOrderRoutingLine(ProductionOrder."No.", RoutingLine."Operation No.");

            // Verify.
            VerifyProdOrderCapacityNeedWithStartingTime(
              RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::" ", ProdOrderCapacityNeed."Time Type"::Setup,
              ProductionOrder."Starting Time", 0);  // Use 0 for Allocated Time.
            VerifyProdOrderCapacityNeedWithStartingTime(
              RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Both, ProdOrderCapacityNeed."Time Type"::Run,
              ProductionOrder."Starting Time", RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingZeroRunTime()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        Item: Record Item;
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] Run Time of routing "R" is zero
        CreateShipmentPlanningFromToDatesSetup(ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        CreateWorkCenterDemand(Item, WorkCenter."No.", 0, ShipmentDate);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenter."No.", ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingPositiveRunTime()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        Item: Record Item;
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with positive "Run Time" calculates the same values of "Starting Date Time" and "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] Run Time of routing "R" is positive
        CreateShipmentPlanningFromToDatesSetup(ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        CreateWorkCenterDemand(Item, WorkCenter."No.", LibraryRandom.RandIntInRange(5, 15), ShipmentDate);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenter."No.", ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the beginning of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date"
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceBeginningDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center in the beginning of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of workday and ends in the middle of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceBeginningDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceMiddleDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the middle of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the middle of the day one day before "SO"."Shipment Date". Absence of "W" starts and ends in the middle of workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceMiddleDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the ending of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceEndDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center in the ending of the day with overlapping with non-working hours ca
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceEndDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center the whole day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [SCM] [Planning] [Manufacturing] [Capacity]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts with the beginning of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceWholeDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center the whole day with overlapping with non-working hours calculates th
        // [FEATURE] [SCM] [Planning] [Manufacturing] [Capacity]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceWholeDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the beginning of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date"
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceBeginningDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the beginning of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of workday and ends in the middle of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceBeginningDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceMiddleDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the middle of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the middle of the day one day before "SO"."Shipment Date". Absence of "W" starts and ends in the middle of workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceMiddleDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120));

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the ending of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceEndDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the ending of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceEndDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center the whole day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts with the beginning of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceWholeDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center the whole day with overlapping with non-working hours calculate
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize;

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceWholeDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateTimePlanningRoutingLineToProdOrderRoutingLineCorresponding()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        PlanningRoutingLine: Record "Planning Routing Line";
        Qty: Decimal;
    begin
        // [SCENARIO 203921] For "Send-Ahead Quantity" the results of calculating of fields "Starting Date-Time" and "Ending Date-Time" by regenerative plan
        // [SCENARIO] for production order must correspond to the ones of the refreshing of production order.
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Send-Ahead Quantity]
        Initialize;

        // [GIVEN] Manufacturing Item "I" with serial routing with 4 lines L1, L2, L3, L4: L2 and L3 have "Send-Ahead Quantity" > 1.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        CreateRoutingWithSendahead(RoutingHeader, WorkCenter."No.", 60, LibraryRandom.RandIntInRange(2, 5));
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Sales Order as Demand for "I".
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateSalesOrderWithQuantity(Item."No.", Qty);

        CalculateProductionOrder(TempProdOrderRoutingLine, Item, Qty);

        // [WHEN] Calculate Regenerative Plan for "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");

        // [THEN] Corresponding data in "Planning Routing Line" table contains 4 Lines;
        Assert.RecordCount(PlanningRoutingLine, 4);

        // [THEN] Each of these 4 lines has the same values of "Starting Date-Time" and "Ending Date-Time" fields as if these fields were calculated for "Production Order" with the same Quantity.
        TempProdOrderRoutingLine.FindSet;
        repeat
            PlanningRoutingLine.SetRange("Operation No.", TempProdOrderRoutingLine."Operation No.");
            PlanningRoutingLine.FindFirst;
            PlanningRoutingLine.TestField("Starting Date-Time", TempProdOrderRoutingLine."Starting Date-Time");
            PlanningRoutingLine.TestField("Ending Date-Time", TempProdOrderRoutingLine."Ending Date-Time");
        until TempProdOrderRoutingLine.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesForecastWithBlankLocationCodeForAssemblyItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Assembly] [Components At Location]
        // [SCENARIO 201871] For Assembly Item blank location in Sales Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in Manufacturing Setup can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = Assembly, Current Production Forecast "F", Forecast Entry with type Sales for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has some inventory at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is blank, "R"."Quantity" = "Q"
        SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesForecastWithBlankLocationCodeForProdOrderItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Manufacturing] [Components At Location]
        // [SCENARIO 201871]  For Prod. Order Item blank location in Sales Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in Manufacturing Setup can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = "Prod. Order", Current Production Forecast "F", Forecast Entry with type Sales for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has some inventory at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is blank, "R"."Quantity" = "Q"
        SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentForecastWithBlankLocationCodeForAssemblyItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Assembly] [Components At Location]
        // [SCENARIO 201871] For Assembly Item blank location in Component Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in Manufacturing Setup can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = Assembly, Current Production Forecast "F", Forecast Entry with type Component for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has inventory "IL" at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is "L".Code, "R"."Quantity" = "Q" - "IL"
        ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentForecastWithBlankLocationCodeForProdOrderItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Manufacturing] [Components At Location]
        // [SCENARIO 201871] For Prod. Order Item blank location in Component Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in Manufacturing Setup can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = "Prod. Order", Current Production Forecast "F", Forecast Entry with type Component for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has inventory "IL" at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is "L".Code, "R"."Quantity" = "Q" - "IL"
        ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(
          Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScrapPctInProdBOMLineCopiedFromComponent()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        // [FEATURE] [Production BOM] [Scrap] [UT]
        // [SCENARIO 218724] Scrap % in production BOM line should be copied from the component item when the item No. is validated

        Initialize;

        // [GIVEN] Item "I" with scrap % = "X"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Scrap %", LibraryRandom.RandInt(20));
        Item.Modify(true);

        // [GIVEN] Production BOM with one line
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        ProductionBOMLine.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.Validate(Type, ProductionBOMLine.Type::Item);

        // [WHEN] Set item "I" as the component in the BOM line
        ProductionBOMLine.Validate("No.", Item."No.");

        // [THEN] Scrap % in the BOM line is "X"
        ProductionBOMLine.TestField("Scrap %", Item."Scrap %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesSalesOrderSameLocation()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for "Sales Order" at the same location as "Work Center"
        Initialize;

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Lot-for-Lot"
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [GIVEN] Sales Order "S" for "I" at "L"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo,
          Item."No.", 1, WorkCenter[1]."Location Code", WorkDate);

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLine(WorkCenter[2], Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesSalesOrderBlankLocation()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for Sales Order with blank location
        Initialize;

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Lot-for-Lot"
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [GIVEN] Sales Order "S" for "I" with blank location
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, Item."No.", 1, '', WorkDate);

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLineBlankLocationAndBins(Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesReorderPoint()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for Item reorder point
        Initialize;

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Fixed Reorder Qty.", "Reorder Point" and "Reorder Quantity" specified
        CreateFixedReorderQtyItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLine(WorkCenter[2], Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,CheckProdOrderStatusModalPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure ReducedQtyInSalesPlannedAsOrderToOrderLeadsToReducingQtyInBoundProductionOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Production] [Sales] [Order-to-Order Binding]
        // [SCENARIO 300468] When a user reduces quantity on sales line bound to a prod. order as order-to-order, and runs planning, the program suggests reducing the production order accordingly.
        Initialize;

        // [GIVEN] Production item set up for "Maximum Qty." reordering policy, "Maximum Inventory" = 16, "Order Multiple" = 4.
        // [GIVEN] "Order Multiple" setting being greater than 1 is crucial for the test.
        CreateProdOrderItem(Item, Item."Reordering Policy"::"Maximum Qty.", LibraryRandom.RandIntInRange(2, 5), '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        // [GIVEN] 16 pcs of the item are in stock (maximum inventory).
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Item."Maximum Inventory");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 100 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 200), '', WorkDate);

        // [GIVEN] Create firm planned production order out of the sales order using "Planning" functionality to cover the demand.
        // [GIVEN] The new production order has quantity = 100 pcs.
        // [GIVEN] The production is reserved to the sales with order-to-order link.
        LibraryPlanning.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // [GIVEN] Reduce the quantity on the sales line to 60.
        SalesLine.Find;
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(30, 60));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan for the item in order to replan the production order.
        Item.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] The planning engine suggests reducing quantity on the production order to 60 so it matches the sales.
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,CheckProdOrderStatusModalPageHandler,SimpleMessageHandler')]
    procedure ReducedQtyInSalesPlannedAsOrderToOrderLeadsToReducingQtyInBoundProdOrderRespectPlanParamsOn()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Production] [Sales] [Order-to-Order Binding]
        // [SCENARIO 300468] When a user reduces quantity on sales line bound to a prod. order as order-to-order, and runs planning with "Respect Planning Parameters" setting turned on, the program suggests reducing the production order accordingly.
        Initialize;

        // [GIVEN] Production item set up for "Maximum Qty." reordering policy, "Maximum Inventory" = 16, "Order Multiple" = 4.
        // [GIVEN] "Order Multiple" setting being greater than 1 is crucial for the test.
        CreateProdOrderItem(Item, Item."Reordering Policy"::"Maximum Qty.", LibraryRandom.RandIntInRange(2, 5), '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        // [GIVEN] 16 pcs of the item are in stock (maximum inventory).
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Item."Maximum Inventory");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 100 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 200), '', WorkDate);

        // [GIVEN] Create firm planned production order out of the sales order using "Planning" functionality to cover the demand.
        // [GIVEN] The new production order has quantity = 100 pcs.
        // [GIVEN] The production is reserved to the sales with order-to-order link.
        LibraryPlanning.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // [GIVEN] Reduce the quantity on the sales line to 60.
        SalesLine.Find;
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(30, 60));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan with respect planning parameters setting turned on in order to replan the production order.
        Item.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, WorkDate, WorkDate, true);

        // [THEN] The planning engine suggests reducing quantity on the production order to 60 so it matches the sales.
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PlanningErrorLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanErrorDoesNotInfluenceRest()
    var
        Item: array[2] of Record Item;
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningErrorLog: Record "Planning Error Log";
        Quantity: array[2] of Decimal;
        OrderMultipleQuantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Planning]
        // [SCENARIO 230817] When an error occurs on regenerative plan calculation for some item this doesn't cause influence the calculation of other items.
        Initialize;

        OrderMultipleQuantity := LibraryRandom.RandIntInRange(3, 5) * 100;
        Quantity[1] := LibraryRandom.RandIntInRange(3, 5) * 1000 + LibraryRandom.RandInt(OrderMultipleQuantity);
        Quantity[2] := LibraryRandom.RandInt(OrderMultipleQuantity);

        // [GIVEN] Two Items "I1" and "I2", "Replenishment System" = "Prod. Order" both.
        // [GIVEN] "I1" has "Order Multiple" specified, "I1"."Reordering Policy" = "Lot-for-Lot", "I2"."Reordering Policy" = Order.
        // [GIVEN] "I1" is leading when sorting by primary key "No." and has "Routing No." set by uncertified routing "R".
        CreateUncertifiedRouting(RoutingHeader);
        CreateProdOrderItem(Item[1], Item[1]."Reordering Policy"::"Lot-for-Lot", OrderMultipleQuantity, RoutingHeader."No.");
        CreateProdOrderItem(Item[2], Item[2]."Reordering Policy"::Order, 0, '');

        // [GIVEN] Two sales blanket orders "S1" for "I1" and "S2" for "I2" with quantities "Q1" and "Q2".
        for i := 1 to 2 do
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '', Item[i]."No.", Quantity[i], '', WorkDate);

        // [WHEN] Calculate regenerative plan for "I1" and "I2".
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        LibraryVariableStorage.Enqueue(ErrorsWhenPlanningMsg); // Enqueue for MessageHandler
        LibraryVariableStorage.Enqueue(Item[1]."No."); // Enqueue for PlanningErrorLogModalPageHandler
        LibraryVariableStorage.Enqueue(RoutingHeader."No."); // Enqueue for PlanningErrorLogModalPageHandler
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate, WorkDate);

        // [THEN] The message "Not all items were planned." occurs.
        // [THEN] The page "Planning Error Log" opens, it has one line for "I1" with "Error Description" "Status must be equal to 'Certified'  in Routing Header: No.="R". Current value is 'New'."
        // [THEN] The requisition line for "I2" with quantity "Q2" exists.
        FindRequisitionLine(RequisitionLine, Item[2]."No.");
        RequisitionLine.TestField(Quantity, Quantity[2]);

        // Tear down.
        PlanningErrorLog.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinesOnOneProdOrderPlannedSeparatelyForItemWithReorderingPolicyOrder()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
        NoOfLines: Integer;
        i: Integer;
    begin
        // [FEATURE] [Planning] [Reordering Policy] [Production Order] [Prod. Order Component]
        // [SCENARIO 328536] Prod. order components that belong to different prod. order lines in one production order are planned separately for item with Reordering Policy = Order.
        Initialize;
        Qty := LibraryRandom.RandInt(10);
        NoOfLines := LibraryRandom.RandIntInRange(2, 5);

        // [GIVEN] Production item "P".
        // [GIVEN] Component item "C" with Reordering Policy = "Order".
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Reordering Policy", CompItem."Reordering Policy"::Order);
        CompItem.Modify(true);

        // [GIVEN] Released production order for item "P".
        // [GIVEN] Create 4 prod. order lines, each for 10 pcs.
        // [GIVEN] Add component "C" to each of prod. order lines, "Quantity per" = 10 pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Qty);
        for i := 1 to NoOfLines do begin
            LibraryManufacturing.CreateProdOrderLine(
              ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProdItem."No.", '', '', Qty);
            LibraryManufacturing.CreateProductionOrderComponent(
              ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            ProdOrderComponent.Validate("Item No.", CompItem."No.");
            ProdOrderComponent.Validate("Quantity per", Qty);
            ProdOrderComponent.Modify(true);
        end;

        // [WHEN] Calculate regenerative plan for item "C".
        CompItem.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWksh(CompItem, WorkDate, WorkDate);

        // [THEN] 4 planning lines are created.
        FindRequisitionLine(RequisitionLine, CompItem."No.");
        Assert.RecordCount(RequisitionLine, NoOfLines);

        // [THEN] Each planning line has quantity = 100 (10 pcs on prod. order line * 10 pcs on prod. order component).
        RequisitionLine.SetRange(Quantity, Qty * Qty);
        Assert.RecordCount(RequisitionLine, NoOfLines);

        // [THEN] Each prod. order component line is reserved.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet;
        repeat
            ProdOrderComponent.CalcFields("Reserved Quantity");
            ProdOrderComponent.TestField("Reserved Quantity", ProdOrderComponent.Quantity);
        until ProdOrderComponent.Next = 0;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning And Manufacturing");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        LibraryApplicationArea.EnablePremiumSetup;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning And Manufacturing");
        NoSeriesSetup;
        OutputJournalSetup;
        LibraryWarehouse.CreateLocation(LocationBlue);
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning And Manufacturing");
    end;

    local procedure SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(ReplenishmentSystem: Option)
    var
        Location: Record Location;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithReplenishmentSystem(Item, ReplenishmentSystem);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateCurrentProductionForecastAndComponentsAtLocationOnManufacturingSetup(ProductionForecastName.Name, Location.Code);

        CreateProductionForecastEntryWithBlankLocation(ProductionForecastEntry, Item, ProductionForecastName.Name, false);

        IncreaseItemInventoryAtLocation(Location.Code, Item."No.");

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, WorkDate, CalcDate('<CY>', ProductionForecastEntry."Forecast Date"), true);

        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField(Quantity, ProductionForecastEntry."Forecast Quantity");
        RequisitionLine.TestField("Location Code", '');
    end;

    local procedure ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(ReplenishmentSystem: Option)
    var
        Location: Record Location;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        ItemInventory: Decimal;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithReplenishmentSystem(Item, ReplenishmentSystem);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateCurrentProductionForecastAndComponentsAtLocationOnManufacturingSetup(ProductionForecastName.Name, Location.Code);

        CreateProductionForecastEntryWithBlankLocation(ProductionForecastEntry, Item, ProductionForecastName.Name, true);

        ItemInventory := IncreaseItemInventoryAtLocation(Location.Code, Item."No.");

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, WorkDate, CalcDate('<CY>', ProductionForecastEntry."Forecast Date"), true);

        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField(Quantity, ProductionForecastEntry."Forecast Quantity" - ItemInventory);
        RequisitionLine.TestField("Location Code", Location.Code);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        OutputItemJournalTemplate.Modify(true);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure AddLotItemTrackingToOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order") LotNo: Code[20]
    begin
        LotNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, '', ItemJournalLine.Type, '');
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateAbscenceShipmentPlanningFromToDatesSetup(var AbsenceDate: Date; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date)
    var
        CMDateFormula: DateFormula;
    begin
        PlanningFromDate := WorkDate;
        AbsenceDate := LibraryRandom.RandDateFrom(PlanningFromDate, LibraryRandom.RandInt(10));
        ShipmentDate := AbsenceDate + 1;
        Evaluate(CMDateFormula, '<CM>');
        PlanningToDate := CalcDate(CMDateFormula, ShipmentDate);
    end;

    local procedure CreateShipmentPlanningFromToDatesSetup(var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date)
    var
        CMDateFormula: DateFormula;
    begin
        PlanningFromDate := WorkDate;
        ShipmentDate := PlanningFromDate + LibraryRandom.RandInt(10);
        Evaluate(CMDateFormula, '<CM>');
        PlanningToDate := CalcDate(CMDateFormula, ShipmentDate);
    end;

    local procedure WorkCenterAndDemandAbsenceBeginningDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheBeginningOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceMiddleDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheMiddleOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceEndDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheEndOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceWholeDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithTheWholeDayAbsence(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(var Item: Record Item; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        StartingEndingDateTime: DateTime;
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);
        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField("Starting Date-Time", RequisitionLine."Ending Date-Time");
        StartingEndingDateTime := RequisitionLine."Starting Date-Time";

        ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(
          Item, RequisitionLine, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, StartingEndingDateTime, StartingEndingDateTime);
    end;

    local procedure PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(var Item: Record Item; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);
        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        StartingDateTime := RequisitionLine."Starting Date-Time";
        EndingDateTime := RequisitionLine."Ending Date-Time";

        ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(
          Item, RequisitionLine, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, StartingDateTime, EndingDateTime);
    end;

    local procedure ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(var Item: Record Item; var RequisitionLine: Record "Requisition Line"; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date; StartingDateTime: DateTime; EndingDateTime: DateTime)
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        ScheduleDirection: Option Forward,Backward;
    begin
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, ScheduleDirection::Forward, true, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);

        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Delete(true);

        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenterNo);

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);

        FindRequisitionLine(RequisitionLine, Item."No.");
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, ScheduleDirection::Forward, true, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);
    end;

    local procedure CalculateDateWithNonWorkingDays(FromDate: Date; ToDate: Date; SignFactor: Integer) DateWithNonWorkingDays: Date
    var
        BaseCalendarChange: Record "Base Calendar Change";
        Date: Record Date;
    begin
        if SignFactor > 0 then
            DateWithNonWorkingDays := ToDate
        else
            DateWithNonWorkingDays := FromDate;
        Date.SetRange("Period Start", FromDate, ToDate);
        Date.SetRange("Period Name", Format(BaseCalendarChange.Day::Sunday));
        DateWithNonWorkingDays := CalcDate('<' + Format(SignFactor * Date.Count) + 'D>', DateWithNonWorkingDays);  // Add or Substract Non-working days to date.

        // Use 7 for Sunday required for test.
        if Date2DWY(DateWithNonWorkingDays, 1) = 7 then
            DateWithNonWorkingDays := CalcDate('<' + Format(SignFactor) + 'D>', DateWithNonWorkingDays);
    end;

    local procedure CarryOutActionMessageOnPlanningWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CarryOutRequisitionLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst;
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Order Date", WorkDate);
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, ExpectedReceiptDate, '');  // Use Blank for YourRef.
        FindPurchaseLine(PurchaseLine, ItemNo);
    end;

    local procedure CalculateProductionOrder(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; Item: Record Item; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        CreateAndRefreshReleasedProductionOrderWithQty(ProductionOrder, Item."No.", Quantity);

        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.FindSet;
        repeat
            TempProdOrderRoutingLine := ProdOrderRoutingLine;
            TempProdOrderRoutingLine.Insert();
        until ProdOrderRoutingLine.Next = 0;

        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst;
        ProdOrderLine.Delete(true);
    end;

    local procedure CreateSalesOrderWithQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateRoutingWithSendahead(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RunTime: Integer; SendaheadQuantity: Decimal)
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendahead(RoutingHeader, '10', WorkCenterNo, RunTime, 0);
        CreateRoutingLineWithSendahead(RoutingHeader, '20', WorkCenterNo, RunTime, SendaheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '30', WorkCenterNo, RunTime, SendaheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '40', WorkCenterNo, RunTime, 0);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLineWithSendahead(var RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; WorkCenterNo: Code[20]; RunTime: Integer; SendaheadQuantity: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Send-Ahead Quantity", SendaheadQuantity);
        RoutingLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Use True for Calculate Lines, Routing and Components.
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithQty(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Use True for Calculate Lines, Routing and Components.
    end;

    local procedure CreateBaseCalendarWithBaseCalendarChange(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Sunday);  // Use 0D for Date.
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        Item2: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(Item2);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandInt(5));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateInitialSetupForPlanning(var Location: Record Location; var Vendor: Record Vendor; var Item: Record Item; BaseCalendarCode: Code[10])
    begin
        UpdateInboundWhseHandlingTimeOnLocation(Location, BaseCalendarCode);
        CreateVendorWithLeadTimeCalculation(Vendor, BaseCalendarCode);
        CreateItemWithVendorNo(Item, Vendor."No.");
    end;

    local procedure CreateInitialSetupForPlanningWithBaseCalendar(var Location: Record Location; var Vendor: Record Vendor; var Item: Record Item)
    var
        BaseCalendar: Record "Base Calendar";
    begin
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar);
        CreateInitialSetupForPlanning(Location, Vendor, Item, BaseCalendar.Code);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Option; ManufacturingPolicy: Option)
    begin
        LibraryVariableStorage.Enqueue(ChangeWillNotAffect);  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
    end;

    local procedure CreateLotProdMakeToOrderItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateProdOrderItem(var Item: Record Item; ReorderingPolicy: Option; OrderMultipleQuantity: Decimal; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Order Multiple", OrderMultipleQuantity);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateFixedReorderQtyItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", LibraryRandom.RandIntInRange(200, 300));
        Item.Validate("Reorder Quantity", LibraryRandom.RandIntInRange(100, 200));
        Item.Modify(true);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line"; ItemTrackingCode: Code[10]; WithMachineCenter: Boolean)
    var
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
    begin
        LibraryInventory.CreateItem(Item);
        WorkCenter.FindFirst;
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine.FieldNo("Operation No."))),
          RoutingLine.Type::"Work Center", WorkCenter."No.");  // Use Blank for Version Code.
        if WithMachineCenter then begin
            MachineCenter.SetRange("Work Center No.", WorkCenter."No.");
            MachineCenter.FindFirst;
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine2, '',
              CopyStr(
                LibraryUtility.GenerateRandomCode(RoutingLine2.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
                LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine2.FieldNo("Operation No."))),
              RoutingLine2.Type::"Machine Center", MachineCenter."No.");  // Use Blank for Version Code.
            UpdateRoutingLine(RoutingLine2, RoutingLine."Operation No.", '', LibraryRandom.RandInt(5));  // Use Blank for Previous Operation No.
            UpdateRoutingLine(RoutingLine, '', RoutingLine2."Operation No.", LibraryRandom.RandInt(5));  // Use Blank for Next Operation No.
        end else begin
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine2, '',
              CopyStr(
                LibraryUtility.GenerateRandomCode(RoutingLine2.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
                LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine2.FieldNo("Operation No."))),
              RoutingLine2.Type::"Work Center", WorkCenter."No.");  // Use Blank for Version Code.
            UpdateRoutingLine(RoutingLine2, '', '', 0);  // Use Blank for Previous and Next Operation. Use 0 for Setup Time required for test.
            UpdateRoutingLine(RoutingLine, '', '', 0);  // Use Blank for Previous and Next Operation. Use 0 for Setup Time required for test.
        end;
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        UpdateRoutingNoAndItemTrackingCodeOnItem(Item, RoutingHeader."No.", ItemTrackingCode);
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreateLotItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLotItemWithProductionBOM(var Item: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Item Tracking Code", CreateLotItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithShipmentDate(ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, LibraryRandom.RandIntInRange(20, 30));
    end;

    local procedure CreateWorkCenterWithShopCalendarWorkingDays(var WorkCenter: Record "Work Center"; var ShopCalendarWorkingDays: Record "Shop Calendar Working Days")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        ShopCalendarWorkingDays.FindFirst;
    end;

    local procedure CreateWorkCenterAbsence(WorkCenter: Record "Work Center"; AbsenceDate: Date; AbsenceFromTime: Time; AbsenceToTime: Time; CalendarFromDate: Date; CalendarToDate: Date)
    var
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
    begin
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.",
          AbsenceDate, AbsenceFromTime, AbsenceToTime, 1);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheBeginningOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time";
        AbsenceToTime := AbsenceFromTime + AbsenceDuration;
        if TimeShift then
            AbsenceFromTime -= HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheMiddleOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time" + HoursInMs(LibraryRandom.RandIntInRange(1, 2));
        AbsenceToTime := AbsenceFromTime + AbsenceDuration;
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheEndOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceToTime := ShopCalendarWorkingDays."Ending Time";
        AbsenceFromTime := AbsenceToTime - AbsenceDuration;
        if TimeShift then
            AbsenceToTime += HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithTheWholeDayAbsence(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time";
        AbsenceToTime := ShopCalendarWorkingDays."Ending Time";
        if TimeShift then begin
            AbsenceFromTime -= HoursInMs(LibraryRandom.RandIntInRange(2, 4));
            AbsenceToTime += HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        end;
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateTwoWorkCentersWithProductionBins(var WorkCenter: array[2] of Record "Work Center")
    var
        Location: Record Location;
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[i]);
            WorkCenter[i].Validate("Location Code", Location.Code);
            LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
            WorkCenter[i].Validate("To-Production Bin Code", Bin.Code);
            LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
            WorkCenter[i].Validate("From-Production Bin Code", Bin.Code);
            WorkCenter[i].Modify(true);
        end;
    end;

    local procedure CreateVersionRoutingLine(var RoutingLine: Record "Routing Line"; var WorkCenter: array[2] of Record "Work Center")
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        CreateTwoWorkCentersWithProductionBins(WorkCenter);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.",
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), DATABASE::"Routing Line"));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, RoutingVersion."Version Code", RoutingLine."Operation No.",
          RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;

    local procedure HoursInMs(Hours: Integer) Ms: Integer
    begin
        Ms := 60 * 60 * 1000 * Hours;
    end;

    local procedure CreateRoutingWithRunTime(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RunTime: Integer)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateUncertifiedRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Work Center", WorkCenter."No.");
    end;

    local procedure CreateWorkCenterDemand(var Item: Record Item; WorkCenterNo: Code[20]; RunTime: Integer; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateRoutingWithRunTime(RoutingHeader, WorkCenterNo, RunTime);
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");
        CreateSalesOrderWithShipmentDate(Item."No.", DueDate);
    end;

    local procedure CreateVendorWithLeadTimeCalculation(var Vendor: Record Vendor; BaseCalendarCode: Code[10])
    var
        LeadTimeCalculation: DateFormula;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Vendor.Validate("Lead Time Calculation", LeadTimeCalculation);
        Vendor.Validate("Base Calendar Code", BaseCalendarCode);
        Vendor.Modify(true);
    end;

    local procedure CreateProductionForecastEntryWithBlankLocation(var ProductionForecastEntry: Record "Production Forecast Entry"; Item: Record Item; ProductionForecastName: Code[10]; ComponentForecast: Boolean)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName, Item."No.", '',
          WorkDate + LibraryRandom.RandIntInRange(30, 60), ComponentForecast);
        ProductionForecastEntry.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ProductionForecastEntry.Validate("Forecast Quantity", LibraryRandom.RandIntInRange(1000, 2000));
        ProductionForecastEntry.Modify(true);
    end;

    local procedure DeleteRequisitionLine(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.DeleteAll(true);
    end;

    local procedure ExplodeRoutingOnOutputJournal(OrderNo: Code[20]; HasItemTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Variant: Variant;
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", OrderNo);
        ItemJournalLine.Modify(true);

        if HasItemTracking then
            LibraryVariableStorage.Enqueue(ConfirmDeleteItemTracking); // Explode BOM - confirm delete if Item Tracking
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        if HasItemTracking then
            LibraryVariableStorage.Dequeue(Variant);
    end;

    local procedure FilterReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LotNo: Code[20])
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
    end;

    local procedure FindOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; OperationNo: Code[10]; Type: Option; No: Code[20])
    begin
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Item No.", ProductionOrder."Source No.");
        ItemJournalLine.SetRange("Operation No.", OperationNo);
        ItemJournalLine.SetRange(Type, Type);
        ItemJournalLine.SetRange("No.", No);
        ItemJournalLine.FindFirst;
    end;

    local procedure FindProdOrderCapacityNeed(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; TimeType: Option)
    begin
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderCapacityNeed.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderCapacityNeed.SetRange(Type, RoutingLine.Type);
        ProdOrderCapacityNeed.SetRange("No.", RoutingLine."No.");
        ProdOrderCapacityNeed.SetRange("Time Type", TimeType);
        ProdOrderCapacityNeed.FindFirst;
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst;
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst;
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Type: Option; No: Code[20])
    begin
        ProductionOrder.SetRange("Source Type", Type);
        ProductionOrder.SetRange("Source No.", No);
        ProductionOrder.FindFirst;
    end;

    local procedure GetDefaultSafetyLeadTime(): Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        exit(Format(ManufacturingSetup."Default Safety Lead Time"));
    end;

    local procedure PostOutputJournalAfterDeleteOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line"; RoutingLine2: Record "Routing Line"; Finished: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine2."Operation No.", RoutingLine2.Type, RoutingLine2."No.");
        ItemJournalLine.Delete(true);
        UpdateFinishedOnOutputJournalLine(ProductionOrder, RoutingLine, Finished);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure PostProductionJournalFromRPOWithLot(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]) LotNo: Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemNo);
        LotNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesSuccessfullyPosted);  // Enqueue for MessageHandler.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Posting is performing on ProductionJournalPageHandler with Lot Item Tracking.
    end;

    local procedure IncreaseItemInventoryAtLocation(LocationCode: Code[10]; ItemNo: Code[20]) Quantity: Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateFinishedOnOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line"; Finished: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine."Operation No.", RoutingLine.Type, RoutingLine."No.");
        ItemJournalLine.Validate(Finished, Finished);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateFinishedRoutingStatusOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryVariableStorage.Enqueue(YouWantToContinueConfirm);  // Enqueue for ConfirmHandler.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, OperationNo);
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateInboundWhseHandlingTimeOnLocation(var Location: Record Location; BaseCalendarCode: Code[10])
    var
        InboundWhseHandlingTime: DateFormula;
    begin
        Evaluate(InboundWhseHandlingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        Location.Validate("Base Calendar Code", BaseCalendarCode);
        Location.Modify(true);
    end;

    local procedure UpdatePlanningWarningOnManufacturingSetup(var OldPlanningWarning: Boolean; NewPlanningWarning: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        OldPlanningWarning := ManufacturingSetup."Planning Warning";
        ManufacturingSetup.Validate("Planning Warning", NewPlanningWarning);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateCurrentProductionForecastAndComponentsAtLocationOnManufacturingSetup(CurrentProductionForecast: Code[10]; ComponentsAtLocation: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Current Production Forecast", CurrentProductionForecast);
        ManufacturingSetup.Validate("Components at Location", ComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandDec(100, 2));  // Increase Quantity on Sales Line after calculate regenerative plan required for test.
        SalesLine.Modify(true);
    end;

    local procedure UpdateRoutingNoAndItemTrackingCodeOnItem(Item: Record Item; RoutingNo: Code[20]; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; NextOperationNo: Code[30]; PreviousOperationNo: Code[30]; SetupTime: Decimal)
    begin
        RoutingLine.Validate("Previous Operation No.", PreviousOperationNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Modify(true);
    end;

    local procedure UpdateWaitTimeOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, OperationNo);
        ProdOrderRoutingLine.Validate("Wait Time", LibraryRandom.RandInt(5) + 50);  // Large value required for test.
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure VerifyEmptyReservationEntry(ItemNo: Code[20]; LotNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LotNo);
        Assert.IsTrue(ReservationEntry.IsEmpty, ReservationEntryMustBeEmpty);
    end;

    local procedure VerifyItemLedgerEntry(ProductionOrder: Record "Production Order"; LotNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ProductionOrder."Source No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst;
        ItemLedgerEntry.TestField(Quantity, ProductionOrder.Quantity);
    end;

    local procedure VerifyOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine."Operation No.", RoutingLine.Type, RoutingLine."No.");
        ItemJournalLine.TestField("Output Quantity", ProductionOrder.Quantity);
    end;

    local procedure VerifyPlanningDatesOnPurchaseLine(PurchaseLine: Record "Purchase Line"; OrderDate: Date; PlannedReceiptDate: Date; ExpectedReceiptDate: Date)
    begin
        PurchaseLine.TestField("Order Date", OrderDate);
        PurchaseLine.TestField("Planned Receipt Date", PlannedReceiptDate);
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyProductionOrder(SalesLine: Record "Sales Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("Source No.", SalesLine."No.");
        ProductionOrder.FindFirst;
        ProductionOrder.TestField("Location Code", SalesLine."Location Code");
        ProductionOrder.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyProdOrderCapacityNeedWithStartingTime(RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; SendAheadType: Option; TimeType: Option; StartingTime: Time; AllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("Send-Ahead Type", SendAheadType);
        FindProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine, ProductionOrderNo, TimeType);
        ProdOrderCapacityNeed.TestField("Starting Time", StartingTime);
        ProdOrderCapacityNeed.TestField("Allocated Time", AllocatedTime);
    end;

    local procedure VerifyProductionOrderCapacityNeed(RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; TimeType: Option; AllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        FindProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine, ProductionOrderNo, TimeType);
        ProdOrderCapacityNeed.TestField("Allocated Time", AllocatedTime);
    end;

    local procedure VerifyRequisitionLine(SalesLine: Record "Sales Line"; ActionMessage: Option; AcceptActionMessage: Boolean; RefOrderType: Option)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Accept Action Message", AcceptActionMessage);
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
        RequisitionLine.TestField("Location Code", SalesLine."Location Code");
    end;

    local procedure VerifyRequisitionLineStartingEndingDateTime(ItemNo: Code[20]; ShipmentDate: Date; StartingDateTime: DateTime; EndingDateTime: DateTime)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        Assert.RecordCount(RequisitionLine, 1);
        Assert.IsTrue(ShipmentDate >= RequisitionLine."Due Date", DueDateErr);
        RequisitionLine.TestField("Starting Date-Time", StartingDateTime);
        RequisitionLine.TestField("Ending Date-Time", EndingDateTime);
    end;

    local procedure VerifyReservationEntry(ProductionOrder: Record "Production Order"; LotNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ProductionOrder."Source No.", LotNo);
        ReservationEntry.FindFirst;
        ReservationEntry.TestField("Quantity (Base)", ProductionOrder.Quantity);
    end;

    local procedure VerifyProductionOrderWithRoutingLine(WorkCenter: Record "Work Center"; ItemNo: Code[20]; OperationNo: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
        ProductionOrder.TestField("Bin Code", WorkCenter."From-Production Bin Code");

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", OperationNo);
        ProdOrderRoutingLine.TestField("To-Production Bin Code", WorkCenter."To-Production Bin Code");
        ProdOrderRoutingLine.TestField("From-Production Bin Code", WorkCenter."From-Production Bin Code");
    end;

    local procedure VerifyProductionOrderWithRoutingLineBlankLocationAndBins(ItemNo: Code[20]; OperationNo: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
        ProductionOrder.TestField("Location Code", '');
        ProductionOrder.TestField("Bin Code", '');

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", OperationNo);
        ProdOrderRoutingLine.TestField("Location Code", '');
        ProdOrderRoutingLine.TestField("To-Production Bin Code", '');
        ProdOrderRoutingLine.TestField("From-Production Bin Code", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Lot No.".SetValue(DequeueVariable);
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDEcimal);
        ItemTrackingLines.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Last;
        ProductionJournal.ItemTrackingLines.Invoke;
        ProductionJournal.Post.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogModalPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog.First;
        PlanningErrorLog."Item No.".AssertEquals(LibraryVariableStorage.DequeueText);
        PlanningErrorLog."Error Description".AssertEquals(StrSubstNo(StatusMustBeCertifiedErr, LibraryVariableStorage.DequeueText));
        Assert.IsFalse(PlanningErrorLog.Next, OnlyOneRecordErr);
        PlanningErrorLog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesModalPageHandler(var CreateOrderFromSales: TestPage "Create Order From Sales")
    begin
        CreateOrderFromSales.Yes.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProdOrderStatusModalPageHandler(var CheckProdOrderStatus: TestPage "Check Prod. Order Status")
    begin
        CheckProdOrderStatus.Yes.Invoke;
    end;
}

