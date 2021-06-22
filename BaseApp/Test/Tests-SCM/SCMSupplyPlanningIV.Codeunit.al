codeunit 137077 "SCM Supply Planning -IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        VendorNoError: Label 'Vendor No. must have a value in Requisition Line';
        NewWorksheetMessage: Label 'You are now in worksheet';
        RequisitionLinesQuantity: Label 'Quantity value must match.';
        AvailabilityWarningConfirmationMessage: Label 'There are availability warnings on one or more lines.';
        EditableError: Label 'The value must not be editable.';
        ReleasedProdOrderCreated: Label 'Released Prod. Order';
        SalesLineQtyChangedMsg: Label 'This Sales Line is currently planned. Your changes will not cause any replanning.';
        RequisitionLineQtyErr: Label 'The Quantity of component Item on Requisition Line is not correct.';
        RequisitionLineExistenceErr: Label 'Requisition Line expected to %1 for Item %2 and Location %3';
        ReqLineExpectedTo: Option "Not Exist",Exist;
        RequisitionLineProdOrderErr: Label '"Prod Order No." should be same as Released Production Order';
        CloseBOMVersionsQst: Label 'All versions attached to the BOM will be closed';
        NotAllItemsPlannedMsg: Label 'Not all items were planned. A total of %1 items were not planned.', Comment = '%1 = count of items not planned';
        BOMMustBeCertifiedErr: Label 'Status must be equal to ''Certified''  in Production BOM Header';
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity and WorkCenter Subcontractor.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Exercise: After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // Verify: Verify Inventory of Item is updated after Purchase Order posting for Item.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithBinAndCarryOutForPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", LocationSilver.Code, Bin.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify Location and Bin of Released Production order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Location Code", ProductionOrder."Location Code");
        PurchaseLine.TestField("Bin Code", ProductionOrder."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutWithNewDueDateAndQuantity()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet. Update new Quantity and Due Date on Requisition Line.
        CalculateSubcontractOrder(WorkCenter);
        UpdateRequisitionLineDueDateAndQuantity(
          RequisitionLine, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Production Order Quantity.

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Due Date and quantity of Requisition Line is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField(Quantity, RequisitionLine.Quantity);
        PurchaseLine.TestField("Expected Receipt Date", RequisitionLine."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithUpdatedUOM()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Setup: Create Item. Create Routing and update on Item. Create additional Base Unit of Measure for Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // Create and refresh Released Production Order. Update new Unit Of Measure on Production Order Line.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.
        UpdateProdOrderLineUnitOfMeasureCode(Item."No.", ItemUnitOfMeasure.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Unit of Measure of Released Production Order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithProdOrderRoutingLineForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet With Production Order Routing Line.
        CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrder."No.", WorkDate);

        // Verify: Verify that no Requisition line is created for Subcontracting Worksheet.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithMultiLineRoutingForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
    begin
        // Setup: Create Item. Create Multi Line Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateAndCertifyMultiLineRoutingSetup(WorkCenter, RoutingHeader, RoutingLine, RoutingLine2);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity, WorkCenter Subcontractor and Operation No.
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine."Operation No.");
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine2."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithCarryOutOrderItemVendorNoError()
    var
        Item: Record Item;
    begin
        // Setup: Create Order Item without updating Vendor No on it.
        Initialize;
        CreateOrderItem(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Exercise: Carry Out Action Message for Planning worksheet.
        asserterror CarryOutActionMessage(Item."No.");

        // Verify: Verify error - Vendor No. must have a value in Requisition Line for carry out.
        Assert.ExpectedError(VendorNoError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithCarryOutOrderItemVendorNoError()
    var
        Item: Record Item;
    begin
        // Setup: Create Order Item without updating Vendor No on it.
        Initialize;
        CreateOrderItem(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Exercise: Carry Out Action Message for Requisition Worksheet.
        asserterror CarryOutActionMessage(Item."No.");

        // Verify: Verify error - Vendor No. must have a value in Requisition Line for carry Out.
        Assert.ExpectedError(VendorNoError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithDropShipmentAndCarryOutOnReqWksh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize;
        CreateItem(Item);

        // Create Sales Order with Ship to Address and Purchasing Code Drop Shipment.
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation);
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item."No.", LocationSilver.Code);

        // Exercise: Get Sales Order From Drop Shipment on Requisition Worksheet and Carry out.
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // Verify: Verify Ship to Address and Ship to Code of Sales Order is also updated on Purchase Order created after Carry Out.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        VerifyPurchaseShippingDetails(Item."No.", SalesHeader."Ship-to Code", SalesHeader."Ship-to Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithSpecialOrderAndCarryOutOnReqWksh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize;
        CreateItem(Item);

        // Create Sales Order with Ship to Address and Purchasing Code Special Order.
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation);
        UpdateSalesLineWithSpecialOrderPurchasingCode(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise: Get Sales Order From Special Order on Requisition Worksheet and Carry out.
        GetSalesOrderForSpecialOrderAndCarryOutReqWksh(Item."No.");

        // Verify: Verify Ship to Address and Ship to Code of Sales Order is also updated on Purchase Order created after Carry Out.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        VerifyPurchaseShippingDetails(Item."No.", '', LocationBlue.Address);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForTranferShipWithoutReorderingPolicy()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item without Reordering Policy.
        Initialize;
        CreateItem(Item);

        // Update Inventory.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateInventory(Item."No.", Quantity, LocationBlue.Code);

        // Create and Post Transfer Order.
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Ship -TRUE.

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineWhenCalculateCapableToPromiseReplenishProdOrderLFLItem()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        OrderPromisingSetup: Record "Order Promising Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        OldReqTemplateType: Option;
    begin
        // Setup: Create Lot for Lot Item with Replenishment System Production Order.
        Initialize;
        OrderPromisingSetup.Get();
        ReqWkshTemplate.Get(OrderPromisingSetup."Order Promising Template");
        OldReqTemplateType := ReqWkshTemplate.Type;
        if ReqWkshTemplate.Type <> ReqWkshTemplate.Type::Planning then begin
            ReqWkshTemplate.Type := ReqWkshTemplate.Type::Planning;
            ReqWkshTemplate.Modify();
        end;

        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise to create Requisition Worksheet Line.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Requisition Line with Action Message,Quantity and Due Date after Calculating Capable To Promise.
        SalesLine.Find;  // Required to maintain the instance of Sales Line.
        VerifyRequisitionLineEntries(
          Item."No.", '', RequisitionLine."Action Message"::New, SalesLine."Shipment Date", 0, SalesLine.Quantity,
          RequisitionLine."Ref. Order Type"::"Prod. Order");

        // Restore Order Promising Setup
        if ReqWkshTemplate.Type <> OldReqTemplateType then begin
            ReqWkshTemplate.Type := OldReqTemplateType;
            ReqWkshTemplate.Modify();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForTransferLFLItem()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot For Lot Item.
        Initialize;
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);

        // Update Inventory.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateInventory(Item."No.", Quantity, LocationBlue.Code);

        // Create Transfer Order.
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, Quantity);

        // Exercise: Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Planning Worksheet for Location, Due Date, Action Message and Quantity.
        SelectTransferLine(TransferLine, TransferHeader."No.", Item."No.");
        VerifyRequisitionLineEntries(
          Item."No.", LocationRed.Code, RequisitionLine."Action Message"::Cancel, TransferLine."Receipt Date", TransferLine.Quantity, 0,
          RequisitionLine."Ref. Order Type"::Transfer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanTwiceCarryOutAndNewShipmentDateOnDemand()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
        StartDate: Date;
        NewShipmentDate: Date;
        NewStartDate: Date;
        NewEndDate: Date;
    begin
        // Setup: Create Order Item with Vendor No. Create Sales Order.
        Initialize;
        CreateOrderItem(Item);
        UpdateItemVendorNo(Item);
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Planning Worksheet and Carry Out.
        FindSalesLine(SalesLine, Item."No.");
        StartDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", -1);  // Start Date less than Shipment Date.
        EndDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date more than Shipment Date.
        CalcRegenPlanAndCarryOut(Item, StartDate, EndDate);

        // Update Shipment Date of Sales Order after Carry Out.
        NewShipmentDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date relative to Workdate.
        UpdateSalesLineShipmentDate(Item."No.", NewShipmentDate);

        // Exercise: Calculate Plan for Planning Worksheet again after Carry Out.
        NewStartDate := GetRequiredDate(10, 0, WorkDate, 1);  // Start date more than old Shipment Date of Sales Line.
        NewEndDate := GetRequiredDate(10, 10, NewShipmentDate, 1);  // End Date more than New Shipment Date of Sales Line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, NewStartDate, NewEndDate);

        // Verify: Verify Requisition Line is created with Reschedule Action Message.
        VerifyRequisitionLineEntries(
          Item."No.", '', RequisitionLine."Action Message"::Reschedule, NewShipmentDate, 0, SalesLine.Quantity,
          RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAndCarryOutOrderItemWithVendorHavingCurrency()
    var
        Item: Record Item;
        VendorCurrencyCode: Code[10];
        EndDate: Date;
    begin
        // Setup: Create Order Item. Create Vendor with Currency Code. Update Vendor on Item.
        Initialize;
        CreateOrderItem(Item);
        VendorCurrencyCode := UpdateItemWithVendor(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Calculate Regenerative Plan and Carry Out for Planning Worksheet.
        EndDate := GetRequiredDate(10, 30, WorkDate, 1);  // End Date more WORKDATE.
        CalcRegenPlanAndCarryOut(Item, WorkDate, EndDate);

        // Verify: Verify after Carry Out, Purchase Order is created successfully with Vendor having same Currency Code.
        VerifyPurchaseLineCurrencyCode(Item."No.", VendorCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanAndCarryOutReqWkshOrderItemWithVendorHavingCurrency()
    var
        Item: Record Item;
        VendorCurrencyCode: Code[10];
    begin
        // Setup: Create Order Item. Create Vendor with Currency Code. Update Vendor on Item.
        Initialize;
        CreateOrderItem(Item);
        VendorCurrencyCode := UpdateItemWithVendor(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Requisition Worksheet.
        LibraryVariableStorage.Enqueue(NewWorksheetMessage);  // Required inside MessageHandler.
        CalculatePlanForRequisitionWorksheet(Item);

        // Exercise: Carry Out Action Message for Requisition Worksheet.
        CarryOutActionMessage(Item."No.");

        // Verify: Verify after Carry Out, Purchase Order is created successfully with Vendor having same Currency Code.
        VerifyPurchaseLineCurrencyCode(Item."No.", VendorCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShipmentMethodForSpecialSalesOrderAndCarryOutReqWksh()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize;
        CreateItem(Item);

        // Create Sales Order and Purchasing Code Special Order.
        CreateSalesOrder(Item."No.", '');
        UpdateSalesLineWithSpecialOrderPurchasingCode(SalesLine, Item."No.", '');

        // Exercise: Get Sales Order From Special Order on Requisition Worksheet and Carry out.
        GetSalesOrderForSpecialOrderAndCarryOutReqWksh(Item."No.");

        // Verify: Verify Shipment Method Code of Sales Order is also updated on Purchase Order created after Carry Out.
        VerifyPurchaseShipmentMethod(SalesLine."Document No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanAndCarryOutWithGetSalesOrderAndDropShipmentFRQItem()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // Setup: Create multiple Fixed Reorder Quantity Items.
        Initialize;
        CreateFRQItem(Item);
        CreateFRQItem(Item2);
        UpdateItemVendorNo(Item2);

        // Create Sales Order with Purchasing Code Drop Shipment.
        CreateSalesOrder(Item2."No.", '');
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item2."No.", LocationBlue.Code);

        // Calculate Plan and Get Sales Order for Drop Shipment for same Requisition Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalculatePlanForReqWksh(Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        GetSalesOrderDropShipment(SalesLine, RequisitionLine, RequisitionWkshName);

        // Exercise: Carry Out for second Item created after Get Sales Order.
        CarryOutActionMessage(Item2."No.");

        // Verify: Verify after Carry Out for second Item, Lines for first Items are still on same Worksheet.
        VerifyRequisitionLineBatchAndTemplateForItem(Item."No.", RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnRequisitionWorksheetWithVendorNo()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Verify Requisition Worksheet is automatically updated with Vendor Item No. when Vendor No populated on Requisition Line.
        // Setup.
        Initialize;
        RequisitionLineWithVendorItemNoOfVendor(ReqWkshTemplate.Type::"Req.");  // Requisition Worksheet.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnPlanningWorksheetWithVendorNo()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Verify Planning Worksheet is automatically updated with Vendor Item No. when Vendor No populated on Requisition Line.
        // Setup.
        Initialize;
        RequisitionLineWithVendorItemNoOfVendor(ReqWkshTemplate.Type::Planning);  // Planning Worksheet.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnSKUHasHigherPriorityOnRequsitionLine()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // [FEATURE] [Requisition Worksheet] [Stockkeeping Unit]
        // [SCENARIO 223035] If stockkeeping unit exists for given item and location, vendor item no. on requisition line should be populated from SKU card.
        Initialize;

        // [GIVEN] Item "I" with stockkeeping unit "SKU" on location "L1". Vendor Item No. on the item = "VIN1", on the SKU = "VIN2".
        CreateItemWithSKU(Item, SKU, LocationBlue.Code);

        // [WHEN] Create requisition line with item "I", location "L1" and populated Vendor No. from the item card.
        CreateRequisitionLine(RequisitionLine, Item."No.", ReqWkshTemplate.Type::"Req.");
        RequisitionLine.Validate("Location Code", SKU."Location Code");
        RequisitionLine.Validate("Vendor No.", Item."Vendor No.");

        // [THEN] Stockkeeping unit exists for item "I" and location "L1".
        // [THEN] Vendor Item No. on the requisition line is equal to "VIN2".
        RequisitionLine.TestField("Vendor Item No.", SKU."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnItemHasLowerPriorityOnRequisitionLine()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // [FEATURE] [Requisition Worksheet] [Item]
        // [SCENARIO 223035] If stockkeeping unit does not exist for given item and location, vendor item no. on requisition line should be populated from item card.
        Initialize;

        // [GIVEN] Item "I" with stockkeeping unit "SKU" on location "L1". Vendor Item No. on the item = "VIN1", on the SKU = "VIN2".
        CreateItemWithSKU(Item, SKU, LocationRed.Code);

        // [WHEN] Create requisition line with item "I", location "L2" and populated Vendor No. from the item card.
        CreateRequisitionLine(RequisitionLine, Item."No.", ReqWkshTemplate.Type::"Req.");
        RequisitionLine.Validate("Location Code", LocationBlue.Code);
        RequisitionLine.Validate("Vendor No.", Item."Vendor No.");

        // [THEN] Stockkeeping unit does not exist for item "I" and location "L2".
        // [THEN] Vendor Item No. on the requisition line is equal to "VIN1".
        RequisitionLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    local procedure RequisitionLineWithVendorItemNoOfVendor(Type: Option)
    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Item. Update Item Vendor of Item with Vendor Item No.
        CreateItem(Item);
        CreateItemVendorWithVendorItemNo(ItemVendor, Item);

        // Create Requisition Line for Planning or Requisition Worksheet as required.
        CreateRequisitionLine(RequisitionLine, Item."No.", Type);

        // Exercise: Update Requisition Line with Vendor No.
        UpdateRequisitionLineVendorNo(RequisitionLine, ItemVendor."Vendor No.");

        // Verify: Verify Requisition Line is automatically updated with Vendor Item No. of Item Vendor.
        RequisitionLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForSalesWithLotTrackingLFLItem()
    var
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
    begin
        // Verify Lot specific tracking with Net Change Plan report.
        // Setup.
        Initialize;
        NetChangePlanWithTrackingLFLItem(ItemTrackingMode::"Assign Lot No.", false);  // SN Specific Tracking - FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForSalesWithSerialTrackingLFLItem()
    var
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
    begin
        // Verify Serial specific tracking with Net Change Plan report.
        // Setup.
        Initialize;
        NetChangePlanWithTrackingLFLItem(ItemTrackingMode::"Assign Serial No.", true);  // SN Specific Tracking - TRUE.
    end;

    local procedure NetChangePlanWithTrackingLFLItem(ItemTrackingMode: Option; SerialSpecific: Boolean)
    var
        Item: Record Item;
        ItemTrackingCodeSerialLotSpecific: Record "Item Tracking Code";
        SalesLine: Record "Sales Line";
    begin
        // Create Lot For Lot Item with Lot or Serial specific tracking.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        if SerialSpecific then begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSerialLotSpecific, true, false);
            LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        end else begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSerialLotSpecific, false, true);
            LibraryItemTracking.AddLotNoTrackingInfo(Item);
        end;

        // Create Sales Order. Assign SN or Lot specific Tracking to Sales Line. Page Handler - ItemTrackingPageHandler.
        CreateSalesOrder(Item."No.", '');
        AssignTrackingOnSalesLine(SalesLine, Item."No.", ItemTrackingMode);

        // Exercise: Calculate Net Change Plan from Planning Worksheet.
        CalcNetChangePlanForPlanWksh(Item);

        // Verify: Verify Quantity and Tracking is assigned on Requisition Line. Verified in ItemTrackingPageHandler.
        VerifyRequisitionWithTracking(ItemTrackingMode, Item."No.", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithDescriptionNotEditableForProdForecastMatrixPage()
    var
        Item: Record Item;
    begin
        // Setup: Create Lot For Lot Item.
        Initialize;
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);

        // Exercise & Verify: Open Production Forecast Matrix page and  Verify Item No and Description are uneditable.
        VerifyProductionForecastMatrixUneditable(Item."No.");
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesAfterCapableToPromiseLFLItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Lot For Lot Item. Create Sales Order.
        Initialize;
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise Action.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Reserved Quantity is updated on Sales Line.
        SalesLine.Find;  // Required to maintain the instance of Sales Line.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure DueDateOnReqWkshWithCapableToPromiseMakeToStockLFLItem()
    begin
        // Setup: Verify Due Date on Requisition Line created after Capable to promise for Manufacturing Policy Make-to-Stock on Item.
        Initialize;
        DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(false);  // FALSE- Manufacturing Policy Make-to-Stock.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure DueDateOnReqWkshWithCapableToPromiseMakeToOrderLFLItem()
    begin
        // Setup: Verify Due Date on Requisition Line created after Capable to promise for Manufacturing Policy Make-to-Order on Item.
        Initialize;
        DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(true);  // TRUE- Manufacturing Policy Make-to-Order.
    end;

    local procedure DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(MakeToOrder: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Lot For Lot Item and Update Lead Time Calculation. Create Sales Order.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        if MakeToOrder then
            UpdateItemManufacturingPolicy(Item, Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItemLeadTimeCalculation(Item, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>');  // Random Lead Time Calculation.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise Action.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Due Date on Requisition Line.
        SalesLine.Find;
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Due Date", SalesLine."Planned Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithSalesShipForStartingEndingTimeLFLItems()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Lot For Lot Parent and Child Item. Create Routing and update on Item.
        Initialize;
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(ParentItem, RoutingHeader."No.");

        // Create and Post Sales Order as Ship.
        CreateAndPostSalesOrderAsShip(ParentItem."No.");

        // Exercise: Calculate Plan for Planning Worksheet for Parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // Verify: Verify Starting Time and Ending Time on Planning Worksheet is according to Shop Calendar and Manufacturing Setup.
        FindShopCalendarWorkingDays(ShopCalendarWorkingDays, WorkCenter."Shop Calendar Code");
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
        VerifyRequisitionLineEndingTime(RequisitionLine, ParentItem."No.", ShopCalendarWorkingDays."Ending Time");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItems()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        RoutingHeader: Record "Routing Header";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Lot For Lot Parent and Child Item. Create Routing and update on Item.
        Initialize;
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(ParentItem, RoutingHeader."No.");

        // Create Released Production Order from Sales Order.
        CreateReleasedProdOrderFromSalesOrder(ParentItem."No.");

        // Exercise: Calculate Plan for Planning Worksheet for Parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // Verify: Verify Starting Time and Ending Time on Planning Worksheet is according to Manufacturing Setup.
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithLocation()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        PurchLine: Record "Purchase Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create Location, Create and refresh Released Production Order with Location.
        LibraryWarehouse.CreateLocation(Location);
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", Location.Code, '');

        // Exercise: Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Re-validate the Quantity on the purchase line created by Subcontracting worksheet.
        FindPurchLine(PurchLine, Item."No.");
        PurchLine.Validate(Quantity, ProductionOrder.Quantity);
        PurchLine.Modify(true);

        // Verify: Verify "Qty. on Purch. Order" on Item Card.
        Item.CalcFields("Qty. on Purch. Order");
        Item.TestField("Qty. on Purch. Order", 0);

        // Verify the value of Projected Available Balance on Item Availability By Location Page.
        VerifyItemAvailabilityByLocation(Item, Location.Code, ProductionOrder.Quantity);

        // Verify Scheduled Receipt and Projected Available Balance on Item Availability By Period Page.
        // the value of Scheduled Receipt equal to 0 on the line that Period Start is a day before WORKDATE
        // and the value of Scheduled Receipt equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        // the value of Projected Available Balance equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        VerifyItemAvailabilityByPeriod(Item, 0, ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CheckProdOrderStatusPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAfterUpdateQtyOnSalesOrderLineWithProdItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Test and verify Quantity for production component Item on Requisition Line is correct after replanning.

        // Setup: Create Item with planning parameters and Prod. BOM.
        Initialize;
        QuantityPer := CreateItemWithProdBOM(Item, ChildItem);

        // Create Released Production Order from Sales Order. Then Update Sales Line Quantity.
        CreateReleasedProdOrderFromSalesOrder(Item."No.");
        LibraryVariableStorage.Enqueue(SalesLineQtyChangedMsg);
        Quantity := LibraryRandom.RandInt(100);
        UpdateSalesLineQuantity(Item."No.", Quantity);

        // Exercise: Calculate Plan for Planning Worksheet for parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Quantity of child Item on Resuisition Line is correct.
        VerifyRequisitionLineQuantity(
          ChildItem."No.", RequisitionLine."Action Message"::"Change Qty.", Quantity * QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAfterUpdateQtyOnSalesOrderLineWithAssemblyItem()
    var
        Item: Record Item;
        CompItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Test and verify Quantity for assembly component Item on Requisition Line is correct after replanning.

        // Setup: Create Item with planning parameters and Asm. BOM.
        Initialize;
        QuantityPer := CreateAssemblyItemWithBOM(Item, CompItem);
        CreateSalesOrder(Item."No.", '');

        // Generate an Assembly Order for Sales Line by Planning Worksheet. Then Update Sales Line Quantity.
        CalcRegenPlanAndCarryOut(Item, WorkDate, WorkDate);
        CalcRegenPlanAndCarryOut(CompItem, WorkDate, WorkDate);
        Quantity := LibraryRandom.RandInt(100);
        UpdateSalesLineQuantity(Item."No.", Quantity);

        // Exercise: Calculate Plan for Planning Worksheet for parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(Item."No.", CompItem."No.");

        // Verify: Verify Quantity of child Item on Resuisition Line is correct.
        VerifyRequisitionLineQuantity(
          CompItem."No.", RequisitionLine."Action Message"::New, QuantityPer * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithMixedLocationsAndNoSKU()
    var
        Item: Record Item;
        PrevLocMandatory: Boolean;
        PrevComponentsAtLocation: Code[10];
    begin
        // [SCENARIO 354463] When Item does not have SKUs and Location Mandatory is FALSE and Components at Location is empty, Item is replenished as Lot-for-Lot and other planning parameters are ignored for non-empty Location.

        // [GIVEN] Location Mandatory = FALSE, Components at Location = ''.
        Initialize;
        PrevLocMandatory := UpdInvSetupLocMandatory(false);
        PrevComponentsAtLocation := UpdManufSetupComponentsAtLocation('');
        // [GIVEN] Item with no SKUs and some planning Quantities.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        SetReplenishmentQuantities(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 0));
        // [GIVEN] Inventory is both on empty and non-empty Location.
        UpdateInventory(Item."No.", LibraryRandom.RandDecInDecimalRange(10, 100, 0), '');
        UpdateInventory(Item."No.", LibraryRandom.RandDecInDecimalRange(10, 100, 0), LocationBlue.Code);

        // [WHEN] Calculating Regeneration Plan
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] For non-empty location used planning parameters: Lot-for-Lot, include inventory, other values are blank.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationBlue.Code, ReqLineExpectedTo::"Not Exist");
        // [THEN] For empty location used planning parameters from Item.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", '', ReqLineExpectedTo::Exist);

        // Teardown.
        UpdInvSetupLocMandatory(PrevLocMandatory);
        UpdManufSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineIsDeletedWhileCalculatingWorksheetForDifferentBatch()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionWkshName2: Record "Requisition Wksh. Name";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 363390] Requisition Line is deleted in Batch "A" while Calculating Worksheet for same Line for Batch "B"
        Initialize;

        // [GIVEN] Released Production Order for Item with Routing
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Requisition Worksheet Batch "A"
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // [GIVEN] Requisition Worksheet Batch "B"
        CreateRequisitionWorksheetName(RequisitionWkshName2);

        // [GIVEN] Calculate Worksheet for Batch "A". Requisition Worksheet Line "X" is created.
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName, WorkCenter);

        // [WHEN] Calculate Worksheet for Batch "B".
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName2, WorkCenter);

        // [THEN] Requisition Worksheet Line "Y" = "X" is created. Line "X" is deleted from Batch "A".
        VerifyRequisitionLineForTwoBatches(RequisitionWkshName.Name, RequisitionWkshName2.Name, Item."No.", ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationDeletedWhenDeletingProdOrderLine()
    var
        TopLevelItem: Record Item;
        MidLevelItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
    begin
        // [FEATURE] [Reservation] [Manufacturing] [Planning Worksheet]
        // [SCENARIO 363718] Reservation linking two prod. order lines in the same prod. order is deleted when top-level line is deleted

        Initialize;

        // [GIVEN] Item "I1" replenished through manufacturing with order tracking
        // [GIVEN] Item "I2" replenished through manufacturing with order tracking, used as a component for item "I1"
        CreateItemWithProdBOM(TopLevelItem, MidLevelItem);
        UpdateOrderTrackingPolicy(TopLevelItem);
        UpdateOrderTrackingPolicy(MidLevelItem);

        // [GIVEN] Sales order for item "I1"
        CreateSalesOrder(TopLevelItem."No.", LibrarySales.CreateCustomerNo);
        TopLevelItem.SetFilter("No.", '%1|%2', TopLevelItem."No.", MidLevelItem."No.");

        // [GIVEN] Calculate requisition plan for items "I1" and "I2"
        CalculateRegenPlanForPlanningWorksheet(TopLevelItem);
        AcceptActionMessage(RequisitionLine, TopLevelItem."No.");
        AcceptActionMessage(RequisitionLine, MidLevelItem."No.");

        // [GIVEN] Carry out requisition plan - one production order with 2 lines is created. Item "I2" is reserved as a component for the item "I1"
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, ProdOrderChoice::"Firm Planned", 0, 0, 0, '', '', '', '');

        // [WHEN] Delete production order line for item "I1"
        ProdOrderLine.SetRange("Item No.", TopLevelItem."No.");
        ProdOrderLine.FindFirst;
        ProdOrderLine.Delete(true);

        // [THEN] All reservation entries linked to this line are deleted
        VerifyReservationEntryIsEmpty(DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoSequentialProdOrdersPlannedOnCapacityContrainedMachineAndWorkCenters()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        Item: array[2] of Record Item;
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        StartingDateTime: DateTime;
    begin
        // [FEATURE] [Manufacturing] [Capacity Constrained Resource] [Planning Worksheet]
        // [SCENARIO] Two sequential prod. orders are planned when both machine center and its work center are capacity constrained

        // [GIVEN] Work center with 2 machine centers - "MC1" and "MC2"
        CreateWorkCenterWith2MachineCenters(WorkCenter, MachineCenter);

        // [GIVEN] All manufacturing capacities registered as capacity constrained resources
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[2]."No.");

        // [GIVEN] Item "I1" with routing involving machine centers "MC1", then "MC2"
        CreateLotForLotItemWithRouting(Item[1], MachineCenter[1], MachineCenter[2]);
        // [GIVEN] Item "I1" with routing involving machine centers "MC2", then "MC1"
        CreateLotForLotItemWithRouting(Item[2], MachineCenter[2], MachineCenter[1]);

        // [GIVEN] Sales order with 2 lines: 300 pcs of item "I1" and 300 pcs of item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", 300);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", 300);

        // [WHEN] Calculate regenerative plan for both items
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        CalculateRegenPlanForPlanningWorksheet(Item[1]);

        // [THEN] 2 sequential manufacturing orders are planned: P1."Ending Date-Time" = P2."Starting Date-Time"
        SelectRequisitionLine(RequisitionLine, Item[1]."No.");
        StartingDateTime := RequisitionLine."Starting Date-Time";

        SelectRequisitionLine(RequisitionLine, Item[2]."No.");
        RequisitionLine.TestField("Ending Date-Time", StartingDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoParallelProdOrdersPlannedOnConstrainedMachCentersWithUnlimitedWorkCenter()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        Item: array[2] of Record Item;
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: array[2] of Record "Requisition Line";
    begin
        // [FEATURE] [Manufacturing] [Capacity Constrained Resource] [Planning Worksheet]
        // [SCENARIO] Two parallel prod. orders are planned when machine centers are capacity contrained, but the work center is not constrained

        CreateWorkCenterWith2MachineCenters(WorkCenter, MachineCenter);

        // [GIVEN] Machine centers are registered as capacity constrained resources, work center is not constrained
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[2]."No.");

        // [GIVEN] Item "I1" with routing involving machine centers "MC1", then "MC2"
        CreateLotForLotItemWithRouting(Item[1], MachineCenter[1], MachineCenter[2]);
        // [GIVEN] Item "I1" with routing involving machine centers "MC2", then "MC1"
        CreateLotForLotItemWithRouting(Item[2], MachineCenter[2], MachineCenter[1]);

        // [GIVEN] Sales order with 2 lines: 300 pcs of item "I1" and 300 pcs of item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", 300);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", 300);

        // [WHEN] Calculate regenerative plan for both items
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        CalculateRegenPlanForPlanningWorksheet(Item[1]);

        // [THEN] 2 parallel production orders are planned: P1."Starting Date-Time" = P2."Starting Date-Time", P1."Ending Date-Time" = P2."Ending Date-Time"
        SelectRequisitionLine(RequisitionLine[1], Item[1]."No.");
        SelectRequisitionLine(RequisitionLine[2], Item[2]."No.");
        RequisitionLine[2].TestField("Starting Date-Time", RequisitionLine[1]."Starting Date-Time");
        RequisitionLine[2].TestField("Ending Date-Time", RequisitionLine[1]."Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcChangeSubcontractOrderWithExistingPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
        NewQty: Decimal;
    begin
        // [FEATURE] [Subcontracting Worksheet] [Requisition Line]
        // [SCENARIO] Can change Quantity in Subcontracting Worksheet if replenishment already exists.

        // [GIVEN] Item with subcontracting routing, create Released Production Order.
        Initialize;
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Calculate Subcontracts, accept and Carry Out Action.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [GIVEN] Update Quantity, Calculate Subcontracts.
        UpdateProdOrderLineQty(Item."No.", ProductionOrder.Quantity + LibraryRandom.RandIntInRange(1, 5));
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] In Subcontracting Worksheet, change Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        NewQty := RequisitionLine.Quantity + LibraryRandom.RandIntInRange(1, 5);
        RequisitionLine.Validate(Quantity, NewQty);

        // [THEN] Quantity changed.
        RequisitionLine.TestField(Quantity, NewQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegenerativePlanWithFixedReorderQtyConsidersLeadTimeCalculation()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedDueDate: Date;
    begin
        // [FEATURE] [Requisition Worksheet] [Lead Time Calculation]
        // [SCENARIO] Lead Time Calculation should be considered when calculating requisition plan for an item with fixed reorder quantity

        // [GIVEN] Item "I" with Lead Time Calculation = "1M" and reordering policy "Fixed Reorder Qty."
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Evaluate(Item."Lead Time Calculation", '<1M>');
        Item.Modify(true);

        // [WHEN] Calculate regenerative plan for item "I" on WORKDATE
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, WorkDate);

        // [THEN] "Due Date" in requisition line is WORKDATE + 1M
        ManufacturingSetup.Get();
        SelectRequisitionLine(ReqLine, Item."No.");
        ExpectedDueDate := CalcDate(StrSubstNo('<1M+%1>', ManufacturingSetup."Default Safety Lead Time"), WorkDate);
        ReqLine.TestField("Due Date", ExpectedDueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityForPeriodWithDropShipmentOrders()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        // [FEATURE] [Item Availability] [Drop Shipment]
        // [SCENARIO 377096] Item Availability for Period should not consider Drop Shipment Orders for Sheduled Receipt
        Initialize;

        // [GIVEN] Drop Shipment Sales Order of Quantity = "X"
        CreateItem(Item);
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation);
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item."No.", LocationSilver.Code);

        // [GIVEN] Purchase Order for Drop Shipment Sales Order
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // [WHEN] Run Item Availability for Period
        ItemCard.OpenView;
        ItemCard.GotoRecord(Item);
        ItemAvailabilityByPeriod.Trap;
        ItemCard.Period.Invoke;

        // [THEN] Sheduled Receipt = 0 on Item Availability Line
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMAndCertifiedVersion()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition plan should be calculated correctly for a manufactured item having closed BOM and certified BOM version
        Initialize;

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create and certify a version of BOM "B"
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);
        UpdateProdBOMVersionStatus(ProdBomVersion, ProdBomVersion.Status::Certified);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo);

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet
        PlanningWorksheet.OpenEdit;
        Commit();
        LibraryVariableStorage.Enqueue(false);  // Stop and Show First Error = FALSE
        LibraryVariableStorage.Enqueue(Item."No.");
        PlanningWorksheet.CalculateRegenerativePlan.Invoke;

        // [THEN] Requisition line for item "I" is created
        PlanningWorksheet."No.".AssertEquals(Item."No.");
        PlanningWorksheet."Ref. Order Type".AssertEquals(RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler,MessageHandler,PlanningErrorLogPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMPlanningResiliencyOn()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition worksheet should show a planning error list when planning a manufactured item wihout certified BOM, planning resiliency is on
        Initialize;

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create a version of production BOM "B", leave it in "New" status
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo);

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet with option "Stop and Show First Error" = FALSE
        PlanningWorksheet.OpenEdit;
        Commit();
        LibraryVariableStorage.Enqueue(false);  // Stop and Show First Error = FALSE
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue item no. for MessageHandler
        LibraryVariableStorage.Enqueue(StrSubstNo(NotAllItemsPlannedMsg, 1));
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue item no. again for PlanningErrorLogPageHandler
        PlanningWorksheet.CalculateRegenerativePlan.Invoke;

        // [THEN] "Planning Error Log" page is shown
        // Verified in PlanningErrorLogPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMPlanningResiliencyOff()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition worksheet should throw an error when planning a manufactured item wihout certified BOM, planning resiliency is off
        Initialize;

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create a version of production BOM "B", leave it in "New" status
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo);

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet with option "Stop and Show First Error" = TRUE
        PlanningWorksheet.OpenEdit;
        Commit();
        LibraryVariableStorage.Enqueue(true);  // Stop and Show First Error = TRUE
        LibraryVariableStorage.Enqueue(Item."No.");

        // [THEN] Planning is terminated with an error: "Status must be equal to 'Certified' in Production BOM Header"
        asserterror PlanningWorksheet.CalculateRegenerativePlan.Invoke;
        Assert.ExpectedError(BOMMustBeCertifiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractPurchHeaderNotSavedWhenLineCreationFails()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 382090] Purchase header created from the subcontracting worksheet should not be saved when lines cannot be generated due to erroneous setup

        Initialize;

        // [GIVEN] Work center "W" with linked subcontractor, routing "R" includes an operation on the work center "W"
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Work center "W" is not properly configured, because its Gen. Prod. Posting Group does not exist
        WorkCenter."Gen. Prod. Posting Group" := LibraryUtility.GenerateGUID;
        WorkCenter.Modify();

        // [GIVEN] Create a production order involving the usage of the work center "W"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Calculate subcontrat orders
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] Carry out subcontracting worksheet
        asserterror CarryOutActionMessageSubcontractWksh(Item."No.");

        // [THEN] Creation of a subcontracting purchase order fails, purchase header is not saved
        PurchaseHeader.Init();
        PurchaseHeader.SetRange("Buy-from Vendor No.", WorkCenter."Subcontractor No.");
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryExpectedCostForReceivedNotInvoicedSubcontrPurchaseOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Subcontracting] [Production] [Expected Cost]
        // [SCENARIO 381570] Expected cost of production output posted via purchase order for subcontracting should be calculated as "Unit Cost" on production order line multiplied by output quantity.
        Initialize;

        // [GIVEN] Item "I" with routing with subcontractor "S" for workcenter "W".
        CreateItemWithChildReplenishmentPurchaseAsProdBOM(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Refreshed released production order for "Q" pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Set "Unit Cost" = "X" on the prod. order line.
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst;
        ProdOrderLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ProdOrderLine.Modify(true);

        // [GIVEN] Calculate subcontracts for "W".
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Update unit cost on subcontracting worksheet line to "Y".
        // [GIVEN] Carry out action messages for Subcontracting Worksheet with creation of purchase order with vendor "S".
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] Post the purchase order as Receive but not as Invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, false);

        // [THEN] In related Value Entry expected cost amount is equal to "Q" * "X".
        FindValueEntry(ValueEntry, Item."No.");
        ValueEntry.TestField(
          "Cost Amount (Expected)",
          Round(ProdOrderLine."Unit Cost" * PurchaseLine.Quantity, LibraryERM.GetAmountRoundingPrecision));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanWorksheetCarryOutActionSeveralLinesWithSamePurchasingCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO 213568] Carry out action message in planning woeksheet should combine purchase lines with the same purchasing code under one purchase header

        Initialize;

        // [GIVEN] Item "I" with the default vendor "V"
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::Order, Item."Manufacturing Policy"::"Make-to-Stock",
          LibraryPurchase.CreateVendor(Vendor));

        // [GIVEN] Create two sales orders for item "I" with the same customer
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(Item."No.", Customer."No.");
        CreateSalesOrder(Item."No.", Customer."No.");

        // [GIVEN] Calculate regenerative plan for item "I"
        CalculateRegenPlanForPlanningWorksheet(Item);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [GIVEN] Create purchasing code "P" and set it in all planning worksheet lines generated for the item "I"
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        RequisitionLine.ModifyAll("Purchasing Code", Purchasing.Code);
        RequisitionLine.ModifyAll("Accept Action Message", true);

        // [WHEN] Carry out action message from the planning worksheet
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] One purchase order with two lines is created for the vendor "V"
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordCount(PurchaseHeader, 1);

        PurchaseHeader.FindFirst;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyReplenishedSKUAreNotPlannedWithRequisitionWorksheet()
    var
        Item: Record Item;
        CompItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Stockkeeping Unit] [Assembly] [Requisition Worksheet]
        // [SCENARIO 215219] Assembly replenished SKU cannot be planned with Requisition Worksheet.
        Initialize;

        // [GIVEN] Assembly Item "I".
        // [GIVEN] Stockkeeping unit "SKU-T" for "I" at location "T" and with Replenishment System = "Transfer".
        // [GIVEN] Stockkeeping unit "SKU-A" for "I" at location "A" and with Replenishment System = "Assembly".
        CreateAssemblyItemWithBOM(Item, CompItem);
        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, Item."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Transfer,
          StockkeepingUnit."Reordering Policy"::Order, LocationRed.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, Item."No.", LocationRed.Code, StockkeepingUnit."Replenishment System"::Assembly,
          StockkeepingUnit."Reordering Policy"::Order, '');

        // [GIVEN] Sales Order with item "I" at location "T".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, Item."No.",
          LibraryRandom.RandInt(10), LocationBlue.Code, WorkDate);

        // [WHEN] Calculate plan for "I" in Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // [THEN] Planning line for Assembly at location "A" is not created.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationRed.Code, ReqLineExpectedTo::"Not Exist");

        // [THEN] Planning line for Transfer at location "T" is created.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationBlue.Code, ReqLineExpectedTo::Exist);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanWorksheetCarryOutActionSeveralLinesWithSameShipToCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        // [FEATURE] [Requisition Worksheet] [Drop Shipment]
        // [SCENARIO 224262] Carry out action message in planning worksheet should combine purchase lines for drop shipment with the same ship-to code and location code under one purchase header.
        Initialize;

        // [GIVEN] Item "I" with the default vendor "V".
        // [GIVEN] The default location for vendor "V" is "Blue".
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::Order, Item."Manufacturing Policy"::"Make-to-Stock",
          LibraryPurchase.CreateVendor(Vendor));
        Vendor.Validate("Location Code", LocationBlue.Code);
        Vendor.Modify(true);

        // [GIVEN] Customer "C" with alternate ship-to address code "A".
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Sales order with Ship-to Address Code = "A".
        // [GIVEN] The order contains two lines with item "I" and purchasing code for drop shipment.
        // [GIVEN] Location code on both lines is "Red".
        CreatePurchasingCodeWithDropShipment(Purchasing);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
            SetPurchasingAndLocationOnSalesLine(SalesLine, LocationRed.Code, Purchasing.Code);
        end;

        // [WHEN] Run "Drop Shipment - Get Sales Orders" in requisition worksheet and carry out action message.
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // [THEN] One purchase order is created for vendor "V".
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordCount(PurchaseHeader, 1);

        // [THEN] The purchase contains two lines.
        PurchaseHeader.FindFirst;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);

        // [THEN] The location code on both lines is "Red".
        PurchaseLine.SetRange("Location Code", LocationRed.Code);
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationIsNotDeletedOnCalcRegenPlanForPurchasedItem()
    var
        Item: Record Item;
        SKU: array[2] of Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 276098] Existing reservation of a non-manufacturing item is not deleted when you calculate regenerative plan.
        Initialize;

        SelectTransferRoute(LocationBlue.Code, LocationRed.Code);

        // [GIVEN] Item "I" replenished with purchase.
        // [GIVEN] "I"."Manufacturing Policy" is set to "Make-to-Stock", this setting should be insignificant for a non-prod. item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);

        // [GIVEN] Two stockkeeping units - "SKU_Purch" with replenishment system = "Purchase" on location "L_Purch", "SKU_Trans" with replenishment system = "Transfer" on location "L_Trans".
        CreateStockkeepingUnit(
          SKU[1], Item."No.", LocationBlue.Code, SKU[1]."Replenishment System"::Purchase, SKU[1]."Reordering Policy"::Order, '');
        CreateStockkeepingUnit(
          SKU[2], Item."No.", LocationRed.Code, SKU[2]."Replenishment System"::Transfer, SKU[2]."Reordering Policy"::"Lot-for-Lot",
          LocationBlue.Code);

        // [GIVEN] Create a demand on location "L_Trans".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), LocationRed.Code, WorkDate);

        // [GIVEN] Calculate regenerative plan for item "I" and accept action message.
        // [GIVEN] The planning engine has created a purchase order on location "L_Purch" and a transfer order from "L_Purch" to "L_Trans".
        // [GIVEN] The transfer is reserved from the purchase with "Order-to-Order" binding.
        CalcRegenPlanAndCarryOutActionMessage(Item);

        // [GIVEN] Delete the demand.
        SalesHeader.Delete(true);

        // [WHEN] Calculate regenerative plan for item "I", do not accept action message so far.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] The reservation between the purchase and the transfer order has not been deleted.
        VerifyReservationBetweenSources(Item."No.", DATABASE::"Purchase Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialInventoryAdjustedForSafetyStockOnceOnReorderPointPlanning()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        InitialInventory: Decimal;
        OrderedQty: Decimal;
        ProjectedInventory: Decimal;
    begin
        // [FEATURE] [Safety Stock] [Maximum Inventory] [Reorder Point]
        // [SCENARIO 284376] If initial inventory is less than safety stock, but the full supply at planning date is greater than safety stock, the safety stock demand should not be taken into account.
        Initialize;

        InitialInventory := LibraryRandom.RandIntInRange(50, 100);
        OrderedQty := LibraryRandom.RandIntInRange(20, 40);
        ProjectedInventory := InitialInventory + OrderedQty;

        // [GIVEN] Item with "Maximum Qty." reordering policy.
        // [GIVEN] "Maximum Inventory" = 180 pcs, "Reorder Point" = 110 pcs, "Safety Stock" = 60 pcs.
        CreateAndUpdateItem(
            Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Maximum Qty.",
            "Manufacturing Policy"::"Make-to-Stock", '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(500, 1000));
        Item.Validate("Reorder Point", ProjectedInventory + LibraryRandom.RandIntInRange(20, 40));
        Item.Validate("Safety Stock Quantity", InitialInventory + LibraryRandom.RandInt(10));
        Item.Modify(true);

        // [GIVEN] The initial inventory at WORKDATE is 55 pcs, which is less than the safety stock 60 pcs.
        UpdateInventory(Item."No.", InitialInventory, '');

        // [GIVEN] Purchase order for 35 pcs at date "D" = WORKDATE + 1 day.
        // [GIVEN] The overall supply at date "D" is thus 90 pcs (55 initial inventory + 35 purchase), so the safety stock is covered.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", OrderedQty, '', LibraryRandom.RandDate(10));

        // [WHEN] Calculate regenerative plan starting from date "D". The current supply 90 pcs is less than the reorder point 110, so a new supply will be planned.
        Item.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, PurchaseLine."Expected Receipt Date", CalcDate('<CY>', PurchaseLine."Expected Receipt Date"));

        // [THEN] Planned quantity = 90 pcs (180 max. inventory - 90 current supply).
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Item."Maximum Inventory" - ProjectedInventory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanningTransferDoesNotInterfereWithOtherItemsReservation()
    var
        ReservedItem: Record Item;
        PlannedItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 287817] Replanning a transfer-replenished item does not affect reservation entries unrelated to the transfer being replanned.
        Initialize;

        // [GIVEN] Item "A" with an inventory reserved for a demand.
        LibraryInventory.CreateItem(ReservedItem);
        CreateReservedStock(ReservedItem."No.", LocationBlue.Code);

        // [GIVEN] Item "B" set up for replenishment by Transfer.
        LibraryInventory.CreateItem(PlannedItem);
        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, PlannedItem."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Transfer,
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", LocationRed.Code);

        // [GIVEN] Sales order "SO" for item "B".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, PlannedItem."No.",
          LibraryRandom.RandInt(50), LocationBlue.Code, WorkDate);

        // [GIVEN] Calculate regenerative plan and carry out action in order to create a transfer order to fulfill "SO".
        PlannedItem.SetRecFilter;
        PlannedItem.SetRange("Location Filter", LocationBlue.Code);
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [GIVEN] Double the quantity in "SO".
        UpdateSalesLineQuantity(PlannedItem."No.", SalesLine.Quantity * 2);

        // [WHEN] Replan item "B" and carry out action to adjust the quantity to transfer.
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [THEN] Expected receipt date on reservation entries for item "A" has not changed.
        ReservationEntry.SetRange("Item No.", ReservedItem."No.");
        ReservationEntry.FindFirst;
        ReservationEntry.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanningAssemblyDoesNotInterfereWithOtherItemsReservation()
    var
        ReservedItem: Record Item;
        PlannedItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 287817] Replanning an assembly-replenished item does not affect reservation entries unrelated to the assembly being replanned.
        Initialize;

        // [GIVEN] Item "A" with an inventory reserved for a demand.
        LibraryInventory.CreateItem(ReservedItem);
        CreateReservedStock(ReservedItem."No.", LocationBlue.Code);

        // [GIVEN] Item "B" set up for replenishment by Assembly.
        LibraryInventory.CreateItem(PlannedItem);
        CreateStockkeepingUnit(
          StockkeepingUnit, PlannedItem."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Assembly,
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", '');

        // [GIVEN] Sales order "SO" for item "B".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, PlannedItem."No.",
          LibraryRandom.RandInt(50), LocationBlue.Code, WorkDate);

        // [GIVEN] Calculate regenerative plan and carry out action in order to create an assembly order to fulfill "SO".
        PlannedItem.SetRecFilter;
        PlannedItem.SetRange("Location Filter", LocationBlue.Code);
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [GIVEN] Double the quantity in "SO".
        UpdateSalesLineQuantity(PlannedItem."No.", SalesLine.Quantity * 2);

        // [WHEN] Replan item "B" and carry out action to adjust the quantity to assemble.
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [THEN] Expected receipt date on reservation entries for item "A" has not changed.
        ReservationEntry.SetRange("Item No.", ReservedItem."No.");
        ReservationEntry.FindFirst;
        ReservationEntry.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForProductionItemWithBOMWithNonInventoryItem()
    var
        ProductionItem: Record Item;
        SalesLine: Record "Sales Line";
        NonInventoryItemNo: Code[20];
        InventoryItemNo: Code[20];
    begin
        // [FEATURE] [Item] [Item Type] [Planning Component]
        // [SCENARIO 303068] Calculate Regenerative plan for Production Item whose production BOM contains Item with Type::Non-Inventory
        Initialize;

        // [GIVEN] Production Item with Production BOM containing InventoryItem and NonInventoryItem
        CreateItemWithProdBOMWithNonInventoryItemType(ProductionItem, NonInventoryItemNo, InventoryItemNo);

        // [GIVEN] Sales Order with Production Item as a demand for LocationSilver
        CreateSalesOrder(ProductionItem."No.", '');
        FindSalesLine(SalesLine, ProductionItem."No.");
        SalesLine.Validate("Location Code", LocationSilver.Code);
        SalesLine.Modify(true);

        // [WHEN] Calc. Regenerative Plan for Production Item
        CalculateRegenPlanForPlanningWorksheet(ProductionItem);

        // [THEN] Requisition Line created for ProductionItem
        VerifyRequisitionLineItemExist(ProductionItem."No.");

        // [THEN] Planning Component table contains InventoryItem for LocationSilver
        VerifyPlanningComponentExistForItemLocation(InventoryItemNo, LocationSilver.Code);

        // [THEN] Planning Component table contains NonInventoryItem with blank Location Code
        VerifyPlanningComponentExistForItemLocation(NonInventoryItemNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForAssemblyItemWithBOMWithNonInventoryItem()
    var
        AssemblyItem: Record Item;
        SalesLine: Record "Sales Line";
        NonInventoryItemNo: Code[20];
        InventoryItemNo: Code[20];
    begin
        // [FEATURE] [Item] [Item Type] [Planning Component]
        // [SCENARIO 303068] Calculate Regenerative plan for Assembly Item whose assembly BOM contains Item with Type::Non-Inventory
        Initialize;

        // [GIVEN] AssemblyItme with Assembly BOM containing InventoryItem and NonInventoryItem
        CreateItemWithAssemblyBOMWithNonInventoryItemType(AssemblyItem, NonInventoryItemNo, InventoryItemNo);

        // [GIVEN] Sales Order with Production Item as a demand for LocationSilver
        CreateSalesOrder(AssemblyItem."No.", '');
        FindSalesLine(SalesLine, AssemblyItem."No.");
        SalesLine.Validate("Location Code", LocationSilver.Code);
        SalesLine.Modify(true);

        // [WHEN] Calc. Regenerative Plan for AssemblyItem
        CalculateRegenPlanForPlanningWorksheet(AssemblyItem);

        // [THEN] Requisition Line created for AssemblyItem
        VerifyRequisitionLineItemExist(AssemblyItem."No.");

        // [THEN] Planning Component table contains InventoryItem for LocationSilver
        VerifyPlanningComponentExistForItemLocation(InventoryItemNo, LocationSilver.Code);

        // [THEN] Planning Component table contains NonInventoryItem with blank Location Code
        VerifyPlanningComponentExistForItemLocation(NonInventoryItemNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItemsWhenBlankDefaultSafetyLeadTime()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItemNo: Code[20];
        BlankDefaultSafetyLeadTime: DateFormula;
        ParentStartingTime: Time;
        ParentStartingDate: Date;
    begin
        // [FEATURE] [Default Safety Lead Time] [Lot-for-Lot] [Production]
        // [SCENARIO 322927] When Safety Lead Times are 0D in Manufacturing Setup and the component Item, then Planning respects Starting/Ending Times
        // [SCENARIO 322927] in scenario when two items are planned, and one of those ones is production component of the other one
        Initialize;

        // [GIVEN] Manufacturing Setup had Default Safety Lead Time = '0D'
        Evaluate(BlankDefaultSafetyLeadTime, '<0D>');
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Default Safety Lead Time", BlankDefaultSafetyLeadTime);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Parent Item had Production BOM with Child Item as Component, Reordering Policy was Lot-for-Lot for both
        // [GIVEN] Child Item had Production BOM as well and Safety Lead Time = '0D'
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        UpdateItemSafetyLeadTime(ChildItemNo, '<0D>');

        // [GIVEN] Sales Order with Parent Item
        CreateSalesOrder(ParentItem."No.", '');

        // [WHEN] Calculate Regenerative Plan for both Items
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // [THEN] Ending Time in Child Requsition Line matches Starting Time in Parent Requisition Line
        SelectRequisitionLine(RequisitionLine, ParentItem."No.");
        ParentStartingTime := RequisitionLine."Starting Time";
        ParentStartingDate := RequisitionLine."Starting Date";
        SelectRequisitionLine(RequisitionLine, ChildItemNo);
        RequisitionLine.TestField("Ending Date", ParentStartingDate);
        RequisitionLine.TestField("Ending Time", ParentStartingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItemsWhenComponentSafetyLeadTime()
    var
        ParentItem: Record Item;
        ChildItemNo: Code[20];
    begin
        // [FEATURE] [Safety Lead Time] [Lot-for-Lot] [Production]
        // [SCENARIO 322927] When Component Item has Safety Lead Time <> 0D, then Starting/Ending Times are taken from Manufacturing Setup
        // [SCENARIO 322927] in scenario when two items are planned, and one of those ones is production component of the other one
        Initialize;

        // [GIVEN] Parent Item had Production BOM with Child Item as Component, Reordering Policy was Lot-for-Lot for both
        // [GIVEN] Child Item had Production BOM as well and Safety Lead Time = '1D'
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        UpdateItemSafetyLeadTime(ChildItemNo, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));

        // [GIVEN] Sales Order with Parent Item
        CreateSalesOrder(ParentItem."No.", '');

        // [WHEN] Calculate Regenerative Plan for both Items
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // [THEN] Starting Time and Ending Time in Child Requsition Line is matching Manufacturing Setup Normal Times
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAssemblyWithExistingOrderToOrderPlannedComponent()
    var
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Assembly] [Assemble-to-Order] [Order-to-Order Binding] [Reservation]
        // [SCENARIO 338018] Planning a supply for a new assembly does not interfere with already planned order-to-order sales order for the component.
        Initialize;
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Set up components at location = "BLUE" on Manufacturing Setup.
        UpdateComponentsAtLocationInMfgSetup(LocationBlue.Code);

        // [GIVEN] Create assembly structure: item "COMP" is a component of item "INTERMD", which is a component of item "FINAL".
        // [GIVEN] All items are set up for "Order" reordering policy.
        CreateAssemblyStructure(Item);

        // [GIVEN] Sales order for item "INTERMD" on location "BLUE". Creating a sales order generates an assembly in the background.
        // [GIVEN] Calculate regenerative plan for items "COMP" and "INTERMD" and carry out action message.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[2]."No.", Qty, LocationBlue.Code, WorkDate);
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");
        AcceptActionMessage(RequisitionLine, Item[1]."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Purchase order to supply "COMP" is created.
        // [GIVEN] Post the purchase order.
        FindPurchLine(PurchaseLine, Item[1]."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Sales order for item "COMP" on location "BLUE".
        // [GIVEN] Calculate regenerative plan and carry out action message.
        // [GIVEN] The sales order becomes order-to-order bound to a new purchase.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[1]."No.", Qty, LocationBlue.Code, WorkDate);
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");
        AcceptActionMessage(RequisitionLine, Item[1]."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Sales order for item "FINAL" on location "BLUE".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[3]."No.", Qty, LocationBlue.Code, WorkDate);

        // [WHEN] Calculate regenerative plan.
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");

        // [THEN] Only one planning line for item "COMP" is created.
        SelectRequisitionLine(RequisitionLine, Item[1]."No.");
        Assert.RecordCount(RequisitionLine, 1);

        // [THEN] The reserved quantity on the sales line for item "COMP" has not changed.
        FindSalesLine(SalesLine, Item[1]."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Supply Planning -IV");
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        LibraryApplicationArea.EnableEssentialSetup;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -IV");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        NoSeriesSetup;
        CreateLocationSetup;
        ItemJournalSetup;
        LibrarySetupStorage.SaveManufacturingSetup;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -IV");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateAndUpdateLocation(LocationSilver);  // Location Silver: Bin Mandatory TRUE.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Random Integer value required for Number of Bins.
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure UpdateItemSafetyLeadTime(ItemNo: Code[20]; SafetyLeadTimeText: Text)
    var
        Item: Record Item;
        SafetyLeadTime: DateFormula;
    begin
        Evaluate(SafetyLeadTime, SafetyLeadTimeText);
        Item.Get(ItemNo);
        Item.Validate("Safety Lead Time", SafetyLeadTime);
        Item.Modify(true);
    end;

    local procedure UpdInvSetupLocMandatory(NewValue: Boolean) Result: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        with InventorySetup do begin
            Get;
            Result := "Location Mandatory";
            Validate("Location Mandatory", NewValue);
            Modify(true);
        end;
    end;

    local procedure UpdManufSetupComponentsAtLocation(NewValue: Code[10]) Result: Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        with ManufacturingSetup do begin
            Get;
            Result := "Components at Location";
            Validate("Components at Location", NewValue);
            Modify(true);
        end;
    end;

    local procedure SetReplenishmentQuantities(var Item: Record Item; NewQuantity: Decimal)
    begin
        with Item do begin
            Validate("Safety Stock Quantity", NewQuantity);
            Validate("Minimum Order Quantity", NewQuantity);
            Validate("Maximum Order Quantity", NewQuantity);
            Validate("Order Multiple", NewQuantity);
            Validate("Include Inventory", true);
            Modify(true);
        end;
    end;

    local procedure CalculateSubcontractingWorksheetForBatch(RequisitionWkshName: Record "Requisition Wksh. Name"; WorkCenter: Record "Work Center")
    var
        RequisitionLine: Record "Requisition Line";
        CalculateSubcontracts: Report "Calculate Subcontracts";
    begin
        with RequisitionLine do begin
            Init;
            "Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
            "Journal Batch Name" := RequisitionWkshName.Name;
        end;

        Clear(CalculateSubcontracts);
        with CalculateSubcontracts do begin
            SetWkShLine(RequisitionLine);
            SetTableView(WorkCenter);
            UseRequestPage(false);
            RunModal;
        end;
    end;

    local procedure CertifyRouting(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithProdBOM(var Item: Record Item; var ChildItem: Record Item) QuantityPer: Decimal
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order,
          Item."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateChildItemAsProdBOM(ChildItem, ProductionBOMHeader, ChildItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithChildReplenishmentPurchaseAsProdBOM(var Item: Record Item) QuantityPer: Decimal
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order,
          Item."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateChildItemAsProdBOM(ChildItem, ProductionBOMHeader, ChildItem."Replenishment System"::Purchase);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithSKU(var Item: Record Item; var SKU: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
        CreateItem(Item);
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID);
        Item.Modify(true);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCode, Item."No.", '');
        SKU.Validate("Vendor Item No.", LibraryUtility.GenerateGUID);
        SKU.Modify(true);
    end;

    local procedure CreateStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; TransferFromCode: Code[10])
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateChildItemAsProdBOM(var ChildItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header"; ReplenishmentSystem: Enum "Replenishment System") QuantityPer: Decimal
    begin
        CreateAndUpdateItem(
          ChildItem, ReplenishmentSystem, ChildItem."Reordering Policy"::Order,
          ChildItem."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
    end;

    local procedure CreateCustomerWithLocation(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LocationBlue.Validate(Address, LocationBlue.Name);
        LocationBlue.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(LocationBlue);
        Customer.Validate("Location Code", LocationBlue.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateOrderItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemWithRouting(var Item: Record Item; MachineCenter1: Record "Machine Center"; MachineCenter2: Record "Machine Center")
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, MachineCenter1."No.", '10', 0, 1);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, MachineCenter2."No.", '20', 0, 1);
        CertifyRouting(RoutingHeader);

        UpdateItemRoutingNo(Item, RoutingHeader."No.");
    end;

    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAssemblyItemWithBOM(var Item: Record Item; var CompItem: Record Item) QuantityPer: Decimal
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Assembly, Item."Reordering Policy"::Order,
          Item."Manufacturing Policy", '');
        CreateAndUpdateItem(
          CompItem, CompItem."Replenishment System"::Purchase, CompItem."Reordering Policy"::Order,
          CompItem."Manufacturing Policy", LibraryPurchase.CreateVendorNo);
        QuantityPer := LibraryRandom.RandInt(5);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompItem."No.", Item."No.", '',
          BOMComponent."Resource Usage Type", QuantityPer, true); // Use Base Unit of Measure as True and Variant Code as blank.
    end;

    local procedure CreateAssemblyStructure(var Item: array[3] of Record Item)
    var
        BOMComponent: Record "BOM Component";
        i: Integer;
    begin
        CreateAndUpdateItem(
          Item[1], Item[1]."Replenishment System"::Purchase, Item[1]."Reordering Policy"::Order,
          Item[1]."Manufacturing Policy", LibraryPurchase.CreateVendorNo);

        for i := 2 to ArrayLen(Item) do begin
            CreateAndUpdateItem(
              Item[i], Item[i]."Replenishment System"::Assembly, Item[i]."Reordering Policy"::Order,
              Item[i]."Manufacturing Policy", '');
            Item[i].Validate("Assembly Policy", Item[i]."Assembly Policy"::"Assemble-to-Order");
            Item[i].Modify(true);

            LibraryAssembly.CreateAssemblyListComponent(
              BOMComponent.Type::Item, Item[i - 1]."No.", Item[i]."No.", '', 0, 1, true);
        end;
    end;

    local procedure CreateReservedStock(ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        UpdateInventory(ItemNo, LibraryRandom.RandIntInRange(50, 100), LocationCode);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, ItemNo,
          LibraryRandom.RandInt(50), LocationCode, WorkDate);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateItemWithProdBOMWithNonInventoryItemType(var ProductionItem: Record Item; var NonInventoryItemNo: Code[20]; var InventoryItemNo: Code[20])
    var
        InventoryItem: Record Item;
        NonInventoryItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(InventoryItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        InventoryItemNo := InventoryItem."No.";
        NonInventoryItemNo := NonInventoryItem."No.";

        LibraryInventory.CreateItemManufacturing(ProductionItem);
        ProductionItem.Validate("Replenishment System", ProductionItem."Replenishment System"::"Prod. Order");
        ProductionItem.Validate("Reordering Policy", ProductionItem."Reordering Policy"::"Maximum Qty.");
        ProductionItem.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        ProductionItem.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProductionItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          InventoryItem."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          NonInventoryItem."No.", LibraryRandom.RandInt(10));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProductionItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionItem.Modify(true);
    end;

    local procedure CreateItemWithAssemblyBOMWithNonInventoryItemType(var AssemblyItem: Record Item; var NonInventoryItemNo: Code[20]; var InventoryItemNo: Code[20])
    var
        NonInventoryItem: Record Item;
        InventoryItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(InventoryItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        InventoryItemNo := InventoryItem."No.";
        NonInventoryItemNo := NonInventoryItem."No.";

        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Reordering Policy", AssemblyItem."Reordering Policy"::"Maximum Qty.");
        AssemblyItem.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        AssemblyItem.Modify(true);

        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, AssemblyItem."No.", BOMComponent.Type::Item, InventoryItem."No.",
          LibraryRandom.RandDec(10, 2), InventoryItem."Base Unit of Measure");
        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, AssemblyItem."No.", BOMComponent.Type::Item, NonInventoryItem."No.",
          LibraryRandom.RandDec(10, 2), NonInventoryItem."Base Unit of Measure");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure UpdateItemRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateSalesLineQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithLocationAndBin(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LoactionCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LoactionCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst;
    end;

    local procedure PostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryPurchase.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);

        // Calculate calendar.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        RequisitionLine.Modify(true);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location.Validate("Pick According to FEFO", false);
        Location.Modify(true);
    end;

    local procedure CreateAndUpdateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; ManufacturingPolicy: Enum "Manufacturing Policy"; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Replenishment System", ReplenishmentSystem);
            Validate("Reordering Policy", ReorderingPolicy);
            Validate("Manufacturing Policy", ManufacturingPolicy);
            Validate("Vendor No.", VendorNo);
            Modify(true);
        end;
    end;

    local procedure CreateItemWithClosedBOMAndVersion(var Item: Record Item; var ProdBOMVersion: Record "Production BOM Version")
    var
        ChildItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithProdBOM(Item, ChildItem);
        ProdBOMHeader.Get(Item."Production BOM No.");
        UpdateProductionBOMStatus(ProdBOMHeader, ProdBOMHeader.Status::Closed);

        CreateProductionBOMVersion(ProdBOMVersion, ProdBOMHeader, ChildItem."No.", ProdBOMHeader."Unit of Measure Code", 1);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderLineQty(ItemNo: Code[20]; NewQty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with ProdOrderLine do begin
            SetRange("Item No.", ItemNo);
            FindFirst;
            Validate(Quantity, NewQty);
            Modify(true);
        end;
    end;

    local procedure UpdateRequisitionLineDueDateAndQuantity(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        NewDate: Date;
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        NewDate := GetRequiredDate(10, 0, RequisitionLine."Due Date", 1);  // Due Date more than current Due Date on Requisition Line.
        RequisitionLine.Validate("Due Date", NewDate);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateAndCertifyMultiLineRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CreateRoutingLine(RoutingLine2, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Option)
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst;
    end;

    local procedure CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrderNo: Code[20]; StartingDate: Date)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Starting Date", StartingDate);
        LibraryManufacturing.CalculateSubcontractOrderWithProdOrderRoutingLine(ProdOrderRoutingLine);
    end;

    local procedure CreateSalesOrder(ItemNo: Code[20]; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Value type important for Serial tracking.
    end;

    local procedure CarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure CalculatePlanForRequisitionWorksheet(Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name)
    end;

    local procedure CreateProductionBOMVersion(var ProductionBomVersion: Record "Production BOM Version"; ProdBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; UoMCode: Code[10]; QtyPer: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBomVersion, ProdBOMHeader."No.", LibraryUtility.GenerateGUID, UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, ProductionBomVersion."Version Code", ProdBOMLine.Type::Item, ItemNo, QtyPer);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst;
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst;
    end;

    local procedure UpdateSalesLineWithDropShipmentPurchasingCode(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithDropShipment(Purchasing);
        FindSalesLine(SalesLine, ItemNo);
        SetPurchasingAndLocationOnSalesLine(SalesLine, LocationCode, Purchasing.Code);
    end;

    local procedure UpdateSalesLineWithSpecialOrderPurchasingCode(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        FindSalesLine(SalesLine, ItemNo);
        SetPurchasingAndLocationOnSalesLine(SalesLine, LocationCode, Purchasing.Code);
    end;

    local procedure SetPurchasingAndLocationOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    local procedure GetSalesOrderForDropShipmentAndCarryOutReqWksh(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        GetSalesOrderDropShipment(SalesLine, RequisitionLine, RequisitionWkshName);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure GetSalesOrderForSpecialOrderAndCarryOutReqWksh(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure UpdateInventory(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateTransferOrderWithReceiptDate(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
        ReceiptDate: Date;
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        ReceiptDate := GetRequiredDate(10, 0, WorkDate, 1);  // Transfer Line Receipt Date more than WORKDATE.
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        // If Transfer Not Found then Create it.
        if not TransferRoute.Get(TransferFrom, TransferTo) then begin
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
            TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
            TransferRoute.Modify(true);
        end;
    end;

    local procedure CalculateRegenPlanForPlanningWorksheet(var Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate, 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMessage(var Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculateRegenPlanForPlanningWorksheet(Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst;
        RequisitionLine.ModifyAll("Accept Action Message", true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure SelectTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst;
    end;

    local procedure OpenOrderPromisingPage(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView;
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke;  // Open OrderPromisingPageHandler.
    end;

    local procedure UpdateSalesLineShipmentDate(ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure UpdateItemVendorNo(Item: Record Item)
    begin
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMStatus(var ProductionBOMHeader: Record "Production BOM Header"; NewStatus: Enum "BOM Status")
    begin
        LibraryVariableStorage.Enqueue(CloseBOMVersionsQst);
        ProductionBOMHeader.Validate(Status, NewStatus);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProdBOMVersionStatus(var ProductionBOMVersion: Record "Production BOM Version"; NewStatus: Enum "BOM Status")
    begin
        ProductionBOMVersion.Validate(Status, NewStatus);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CalcRegenPlanAndCarryOut(Item: Record Item; StartDate: Date; EndDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateVendorFCY(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates);
        Vendor.Modify(true);
    end;

    local procedure UpdateItemWithVendor(var Item: Record Item): Code[10]
    var
        Vendor: Record Vendor;
    begin
        CreateVendorFCY(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        exit(Vendor."Currency Code");
    end;

    local procedure CreateFRQItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDec(10, 2));
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CalculatePlanForReqWksh(Item: Record Item; ReqWkshTemplateName: Code[10]; RequisitionWkshNameName: Code[10])
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := GetRequiredDate(10, 0, WorkDate, -1);  // Start Date less than WORKDATE.
        EndDate := GetRequiredDate(10, 0, WorkDate, 1);  // End Date more than WORKDATE.
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplateName, RequisitionWkshNameName, StartDate, EndDate);
    end;

    local procedure GetSalesOrderDropShipment(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure CreateItemVendorWithVendorItemNo(var ItemVendor: Record "Item Vendor"; Item: Record Item)
    begin
        LibraryInventory.CreateItemVendor(ItemVendor, Item."Vendor No.", Item."No.");
        ItemVendor.Validate("Vendor Item No.", Item."No.");
        ItemVendor.Modify(true);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Type: Option)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, Type);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateRequisitionLineVendorNo(RequisitionLine: Record "Requisition Line"; VendorNo: Code[20])
    begin
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure AssignTrackingOnSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemTrackingMode: Option)
    begin
        LibraryVariableStorage.Enqueue(true);  // Boolean - TRUE used inside ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for Page Handler - ItemTrackingPageHandler.
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Sales Line using page - Item Tracking Lines.
    end;

    local procedure CalcNetChangePlanForPlanWksh(Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate, 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate, EndDate, false);
    end;

    local procedure UpdateItemManufacturingPolicy(var Item: Record Item; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemLeadTimeCalculation(var Item: Record Item; LeadTimeCalculation: Text[30])
    var
        LeadTimeCalculation2: DateFormula;
    begin
        Evaluate(LeadTimeCalculation2, LeadTimeCalculation);
        Item.Validate("Lead Time Calculation", LeadTimeCalculation2);
        Item.Modify(true);
    end;

    local procedure UpdateComponentsAtLocationInMfgSetup(LocationCode: Code[10])
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        MfgSetup.Get;
        MfgSetup.Validate("Components at Location", LocationCode);
        MfgSetup.Modify(true);
    end;

    local procedure CreateLotForLotItemSetup(var ParentItem: Record Item): Code[20]
    var
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.");
        CreateLotForLotItem(ChildItem, ChildItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(ChildItem, ProductionBOMHeader."No.");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");
        exit(ChildItem."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]) QuantityPer: Decimal
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        QuantityPer := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicy(var Item: Record Item)
    begin
        Item."Order Tracking Policy" := Item."Order Tracking Policy"::"Tracking Only";
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanWkshForMultipleItems(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        CalculateRegenPlanForPlanningWorksheet(Item);
    end;

    local procedure CreateAndPostSalesOrderAsShip(ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(ItemNo, '');
        FindSalesOrderHeader(SalesHeader, ItemNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure FindShopCalendarWorkingDays(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; ShopCalendarCode: Code[10])
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.FindFirst;
    end;

    local procedure FindSalesOrderHeader(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst;
    end;

    local procedure CreateReleasedProdOrderFromSalesOrder(ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        OrderType: Option ItemOrder,ProjectOrder;
    begin
        CreateSalesOrder(ItemNo, '');
        FindSalesOrderHeader(SalesHeader, ItemNo);
        LibraryVariableStorage.Enqueue(ReleasedProdOrderCreated);
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, ProductionOrder.Status::Released, OrderType::ItemOrder);
    end;

    local procedure CreateWorkCenterWith2MachineCenters(var WorkCenter: Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter[1], WorkCenter."No.", 1);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-1W>', WorkDate), WorkDate);
        LibraryManufacturing.CreateMachineCenter(MachineCenter[2], WorkCenter."No.", 1);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-1W>', WorkDate), WorkDate);
    end;

    local procedure VerifyItemAvailabilityByPeriod(Item: Record Item; ScheduledRcpt: Decimal; ScheduledRcpt2: Decimal; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        ItemCard.OpenView;
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByPeriod.Trap;
        ItemCard.Period.Invoke;

        ItemAvailabilityByPeriod.PeriodType.SetValue(PeriodType::Day);
        ItemAvailabilityByPeriod.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByPeriod.ItemAvailLines.Filter.SetFilter("Period Start", StrSubstNo('%1..%2', WorkDate - 1, WorkDate));
        ItemAvailabilityByPeriod.ItemAvailLines.First();
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt);
        ItemAvailabilityByPeriod.ItemAvailLines.Next;
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt2);
        ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByPeriod.Close;
    end;

    local procedure VerifyItemAvailabilityByLocation(Item: Record Item; LocationCode: Code[10]; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
    begin
        // Quantity assertions for the Item availability by location window
        ItemCard.OpenView;
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.Trap;
        ItemCard.Location.Invoke;

        ItemAvailabilityByLocation.ItemPeriodLength.SetValue(PeriodType::Day);
        ItemAvailabilityByLocation.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByLocation.FILTER.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.ItemAvailLocLines.FILTER.SetFilter(Code, LocationCode);
        ItemAvailabilityByLocation.ItemAvailLocLines.First;

        ItemAvailabilityByLocation.ItemAvailLocLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByLocation.Close;
    end;

    local procedure VerifyRequisitionLine(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center")
    begin
        RequisitionLine.TestField("Prod. Order No.", ProductionOrder."No.");
        RequisitionLine.TestField(Quantity, ProductionOrder.Quantity);
        RequisitionLine.TestField("Work Center No.", WorkCenter."No.");
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
    end;

    local procedure VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; No: Code[20]; OperationNo: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Operation No.", OperationNo);
        RequisitionLine.FindFirst;
        RequisitionLine.TestField("No.", No);
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    local procedure VerifyPurchaseShippingDetails(ItemNo: Code[20]; ShipToCode: Code[10]; ShipToAddress: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.TestField("Ship-to Address", ShipToAddress);
        PurchaseHeader.TestField("Ship-to Code", ShipToCode);
    end;

    local procedure VerifyRequisitionLineEntries(ItemNo: Code[20]; LocationCode: Code[10]; ActionMessage: Enum "Action Message Type"; DueDate: Date; OriginalQuantity: Decimal; Quantity: Decimal; RefOrderType: Option)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Due Date", DueDate);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
    end;

    local procedure VerifyPurchaseLineCurrencyCode(ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyPurchaseShipmentMethod(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");
    end;

    local procedure VerifyRequisitionLineBatchAndTemplateForItem(ItemNo: Code[20]; WorksheetTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst;
        RequisitionLine.TestField("Worksheet Template Name", WorksheetTemplateName);
        RequisitionLine.TestField("Journal Batch Name", JournalBatchName);
    end;

    local procedure VerifyTrackingOnRequisitionLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Boolean - FALSE used inside ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue Quantity(Base) for Item Tracking Lines Page.
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.TestField(Quantity, Quantity);
            RequisitionLine.OpenItemTrackingLines();
        until RequisitionLine.Next = 0;
    end;

    local procedure VerifyItemTrackingLineQty(ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
    end;

    local procedure VerifyRequisitionLineWithSerialTracking(ItemNo: Code[20]; TotalQuantity: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyTrackingOnRequisitionLine(ItemNo, 1);  // Quantity value required on Item Tracking Lines because Serial No tracking assigned on Requisition Lines.
        Assert.AreEqual(TotalQuantity, RequisitionLine.Count, RequisitionLinesQuantity);  // When Serial No. Tracking is assigned then total No of Requisition Lines equals Total Quantity.
    end;

    local procedure VerifyRequisitionWithTracking(ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No."; ItemNo: Code[20]; Quantity: Integer)
    begin
        if ItemTrackingMode = ItemTrackingMode::"Assign Lot No." then
            VerifyTrackingOnRequisitionLine(ItemNo, Quantity) // Lot Tracking.
        else
            VerifyRequisitionLineWithSerialTracking(ItemNo, 1);  // Quantity Value required for Serial Tracking.
    end;

    local procedure VerifyProductionForecastMatrixUneditable(ItemNo: Code[20])
    var
        ProductionForecastMatrix: TestPage "Demand Forecast Matrix";
    begin
        // Check the fields are uneditable on the Production Forecast Matrix Page.
        ProductionForecastMatrix.OpenEdit;
        ProductionForecastMatrix.FILTER.SetFilter("No.", ItemNo);
        Assert.IsFalse(ProductionForecastMatrix."No.".Editable, EditableError);
        Assert.IsFalse(ProductionForecastMatrix.Description.Editable, EditableError);
    end;

    local procedure VerifyRequisitionLineEndingTime(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; EndingTime: Time)
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Ending Time", EndingTime);
    end;

    local procedure VerifyRequisitionLineStartingAndEndingTime(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        VerifyRequisitionLineEndingTime(RequisitionLine, ItemNo, ManufacturingSetup."Normal Ending Time");
        RequisitionLine.TestField("Starting Time", ManufacturingSetup."Normal Starting Time");
    end;

    local procedure VerifyRequisitionLineQuantity(ItemNo: Code[20]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.FindFirst;
        Assert.AreEqual(Quantity, RequisitionLine.Quantity, RequisitionLineQtyErr);
    end;

    local procedure VerifyRequisitionLineExistenceWithLocation(ItemNo: Code[20]; LocationCode: Code[10]; ReqLineExpectedTo: Option "Not Exist",Exist)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        Assert.AreEqual(
          ReqLineExpectedTo = ReqLineExpectedTo::"Not Exist", RequisitionLine.IsEmpty,
          StrSubstNo(RequisitionLineExistenceErr, ReqLineExpectedTo, ItemNo, LocationCode));
    end;

    local procedure VerifyRequisitionLineForTwoBatches(RequisitionWkshName: Code[10]; RequisitionWkshName2: Code[10]; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        with RequisitionLine do begin
            SetRange("Journal Batch Name", RequisitionWkshName2);
            SetRange("No.", ItemNo);
            FindFirst;
            Assert.AreEqual(ProductionOrderNo, "Prod. Order No.", RequisitionLineProdOrderErr);

            SetRange("Journal Batch Name", RequisitionWkshName);
            Assert.RecordIsEmpty(RequisitionLine);
        end;
    end;

    local procedure VerifyRequisitionLineItemExist(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    local procedure VerifyReservationEntryIsEmpty(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        with ReservEntry do begin
            SetRange("Source Type", SourceType);
            SetRange("Source Subtype", SourceSubtype);
            SetRange("Source ID", SourceID);
            Assert.RecordIsEmpty(ReservEntry);
        end;
    end;

    local procedure VerifyReservationBetweenSources(ItemNo: Code[20]; SourceTypeFrom: Integer; SourceTypeFor: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Source Type", SourceTypeFrom);
            FindFirst;
            TestField("Reservation Status", "Reservation Status"::Reservation);

            Reset;
            Get("Entry No.", not Positive);
            TestField("Source Type", SourceTypeFor);
            TestField("Reservation Status", "Reservation Status"::Reservation);
        end;
    end;

    local procedure VerifyPlanningComponentExistForItemLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetFilter("Item No.", ItemNo);
        PlanningComponent.SetFilter("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(PlanningComponent);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcRegenPlanReqPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.MRP.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate);
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate);
        CalculatePlanPlanWksh.NoPlanningResiliency.SetValue(LibraryVariableStorage.DequeueBoolean);
        CalculatePlanPlanWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText);
        CalculatePlanPlanWksh.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke;  // Capable To Promise will generate a new Requisition Line for the demand.
        OrderPromisingLines.AcceptButton.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignTracking: Variant;
        TrackingMode: Variant;
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
        AssignTracking2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(AssignTracking);
        AssignTracking2 := AssignTracking;  // Required for variant to boolean.
        if AssignTracking2 then begin
            LibraryVariableStorage.Dequeue(TrackingMode);
            ItemTrackingMode := TrackingMode;
            case ItemTrackingMode of
                ItemTrackingMode::"Assign Lot No.":
                    ItemTrackingLines."Assign Lot No.".Invoke;
                ItemTrackingMode::"Assign Serial No.":
                    ItemTrackingLines."Assign Serial No.".Invoke;
            end;
            LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMessage);  // Required inside ConfirmHandlerTRUE.
        end else
            VerifyItemTrackingLineQty(ItemTrackingLines);  // Verify Quantity(Base) on Tracking Line.
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog."Item No.".AssertEquals(LibraryVariableStorage.DequeueText);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(false);
        EnterQuantityToCreate.OK.Invoke;  // Assign Serial Tracking on Enter Quantity to Create page.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMsg), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GenericMessageHandler(Message: Text[1024])
    begin
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProdOrderStatusPageHandler(var CheckProdOrderStatus: TestPage "Check Prod. Order Status")
    begin
        CheckProdOrderStatus.Yes.Invoke;
    end;
}

