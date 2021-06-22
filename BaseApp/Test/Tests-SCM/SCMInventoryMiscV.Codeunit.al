codeunit 137297 "SCM Inventory Misc. V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PickRequestLocationCode: Code[10];
        PickRequestDocumentNo: Code[20];
        PickWorkSheetQtyError: Label '%1 in Pick Worksheet line did not match quantity in Prod. Order for Component %2.';

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PickReqAvailableAfterPostConsumpJnl()
    var
        Item: Record Item;
        NewComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Bin: array[2] of Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Verify Picking Request is being available on Pick Worksheet for new Component line when  Production Order Component has been consumed, the Remaining Qty for all Lines will be 0.

        // Setup
        Initialize;
        CreateWarehouseLocation(Bin);
        CreateItemWithInventory(Item, Bin[1]."Location Code", Bin[1].Code);

        SetupProductionOrder(ProductionOrder, Bin[2], Item."No.");
        CreateAndRegisterPick(ProductionOrder."No.", Bin[2]."Location Code");
        CreateAndPostConsumptionJournal(ProductionOrder, Item."No.");

        CreateItemWithInventory(NewComponentItem, Bin[1]."Location Code", Bin[1].Code);
        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, Bin[2].Code, NewComponentItem."No.");

        // Exercise
        CreatePickWorksheetLine(WhseWorksheetLine, ProductionOrder."No.", Bin[2]."Location Code");

        // Verify
        WhseWorksheetLine.SetRange("Item No.", NewComponentItem."No.");
        WhseWorksheetLine.FindFirst;
        Assert.AreEqual(ProdOrderComponent.Quantity, WhseWorksheetLine.Quantity,
          StrSubstNo(PickWorkSheetQtyError, WhseWorksheetLine.FieldCaption(Quantity), NewComponentItem."No."));
        Assert.AreEqual(ProdOrderComponent.Quantity, WhseWorksheetLine."Qty. to Handle",
          StrSubstNo(PickWorkSheetQtyError, WhseWorksheetLine.FieldCaption("Qty. to Handle"), NewComponentItem."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValueEntryAfterInventoryRemainsZero()
    var
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        DocumentNo: Code[20];
        PstdPurchInvNo: Code[20];
    begin
        // Verify Value Entries for an Item which have zero Inventory after run the Adjust Cost Item Entries.

        // Setup: Update Inventory Setup and Sales Receivable Setup.
        Initialize;
        InventorySetup.Get;
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, InventorySetup."Expected Cost Posting to G/L", InventorySetup."Automatic Cost Adjustment",
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period"::Month);
        SalesReceivablesSetup.Get;
        UpdateSalesReceivableSetup(true);

        // Create and post Purchase Order, create and post Sales Order.
        PstdPurchInvNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase), true);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", '', PurchaseLine.Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Item.Get(PurchaseLine."No.");

        // Exercise: Run adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Value Entries for an Item which have zero Inventory.
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo);
        ValueEntry.TestField("Cost Amount (Actual)", Item."Last Direct Cost" * -SalesLine.Quantity);
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::Purchase, PstdPurchInvNo);
        ValueEntry.TestField("Cost Amount (Actual)", Item."Last Direct Cost" * PurchaseLine.Quantity);

        // Teardown:
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostLCYOnPurchOrderWithCurrency()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        WorkCenter: Record "Work Center";
    begin
        // Verify Unit Cost(LCY) on Purchase Line when Subcontracting Purchase Order is created with Foreign Currency.

        // Setup: Create Work Center, create and refresh Production Order.
        Initialize;
        WorkCenter.Get(CreateWorkCenter);
        UpdateRoutingOnItem(Item, WorkCenter."No.");
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));  // Take random Quantity.

        // Exercise: Carry Out Action Message on SubContract Worksheet.
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // Verify: Verify Unit Cost(LCY) on Purchase Line when Subcontracting Purchase Order is created with Foreign Currency.
        FindPurchaseLine(PurchaseLine, Item."No.");
        FindCurrencyExchangeRate(CurrencyExchangeRate, PurchaseLine."Currency Code");
        PurchaseLine.TestField(
          "Unit Cost (LCY)",
          PurchaseLine."Direct Unit Cost" *
          CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryAfterPostPurchOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        WorkCenter: Record "Work Center";
    begin
        // Verify Capacity Ledger Entries when Subcontracting Purchase Order is created and posted with Foreign Currency.

        // Setup: Create Work Center, create and refresh Production Order and Carry Out Action Message on SubContract Worksheet.
        Initialize;
        WorkCenter.Get(CreateWorkCenter);
        UpdateRoutingOnItem(Item, WorkCenter."No.");
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // Exercise: Post Purchase Order.
        FindPurchLineAndPostPurchOrder(PurchaseLine, Item."No.");

        // Verify: Verify Capacity Ledger Entries when Subcontracting Purchase Order is posted with Foreign Currency.
        FindCurrencyExchangeRate(CurrencyExchangeRate, PurchaseLine."Currency Code");
        FindCapacityLedgerEntry(CapacityLedgerEntry, ProductionOrder."No.");
        CapacityLedgerEntry.CalcFields("Direct Cost");
        CapacityLedgerEntry.TestField(
          "Direct Cost",
          Round(
            PurchaseLine."Direct Unit Cost" *
            PurchaseLine.Quantity * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateItemJnlDescAfterDeleteVariant()
    var
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item Journal Line Description is updated after deleting Variant Code.

        // Setup: Create Item, create Item Variant.
        Initialize;
        Item.Get(CreateItem);
        CreateAndModifyItemVariant(ItemVariant, Item."No.");
        CreateItemJournalLine(ItemJournalLine, ItemVariant."Item No.", ItemVariant.Code, '', '');

        // Exercise: Delete Variant code on Item Journal Line.
        UpdateVariantOnItemJnlLine(ItemJournalLine);

        // Verify: Verify Item Journal Line Description is updated.
        ItemJournalLine.TestField(Description, Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartDateAfterUpdateSendAheadQty()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CalculatedTime: Time;
        CalculatedTime2: Time;
        Difference: Integer;
    begin
        // Verify Starting Date on Production Order Routing when Send-Ahead Quantity is updated.

        // Setup: Create Item, create and certify Production BOM.
        Initialize;
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase)); // Component Item
        Item2.Get(CreateAndModifyItem('', Item2."Flushing Method"::Backward, Item2."Replenishment System"::"Prod. Order")); // Component Item
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."Base Unit of Measure", Item2."No.", '');

        // Create Routing with Work Center and Machine Center.
        WorkCenter.Get(CreateWorkCenter);
        RoutingHeader.Get(CreateRoutingSetup(WorkCenter."No.", ''));
        CreateMachineCenter(RoutingHeader, WorkCenter."No.");

        // Update Item with Prodouction BOM No. and Routing No.
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Create and refresh Released Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandInt(5));  // Take random Quantity.
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
        FindProdOrderRountingLine(ProdOrderRoutingLine, ProductionOrder."No.", ProdOrderRoutingLine.Type::"Work Center");
        Difference := ProdOrderRoutingLine."Setup Time" + (ProductionOrder.Quantity * ProdOrderRoutingLine."Run Time");
        CalculatedTime := DT2Time(ProdOrderRoutingLine."Starting Date-Time");
        CalculatedTime2 := CalculatedTime + Difference * 60000;

        // Exercise.
        FindAndUpdateProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // Verify: Verify Starting Date on Production Order Routing when Send-Ahead Quantity is updated.
        FindProdOrderRountingLine(ProdOrderRoutingLine, ProductionOrder."No.", ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.TestField("Starting Date-Time", CreateDateTime(ProdOrderLine."Starting Date", CalculatedTime2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqLineDescIsEqToItemDescWhenItCrossRefDescIsBlank()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Cross Reference]
        // [SCENARIO 233518] When Item Cross Reference Description is blank then Requisition Line Description is populated from Item Description.
        Initialize;

        // [GIVEN] Item "I" with Vendor = "V" and Description
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 0));
        Item.Modify(true);

        // [GIVEN] Item Cross Reference for "I" and "V", the field Description is blank
        LibraryInventory.CreateItemCrossReference(
          ItemCrossReference, Item."No.", ItemCrossReference."Cross-Reference Type"::Vendor, Vendor."No.");
        ItemCrossReference.Validate("Item No.", Item."No.");
        ItemCrossReference.Validate("Unit of Measure", Item."Base Unit of Measure");

        // [WHEN] Validate the fields "No." and "Vendor No." of "Requisition Line" "RL" table by "I" and "V"
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Description in the requisition line is copied from the item card
        RequisitionLine.TestField(Description, Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DifferentDimensionsForItemAndForItemChargeInOnePurchaseInvoice()
    var
        Item: array[2] of Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        DimensionValue: array[3] of Record "Dimension Value";
        ItemChargeAssignmentPurch: array[2] of Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        i: Integer;
        GlobalDimensionCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Item Charge] [Purchase]
        // [SCENARIO 233999] Dimensions of invoice line for item and for item charge inside one document are posting separetely.
        Initialize;
        GlobalDimensionCode := LibraryERM.GetGlobalDimensionCode(2);

        // [GIVEN] Purchase invoice "P" with 3 lines "L1" , "L2", "L3". "L1" and "L2" have Type Item and items "I1" and "I2" with Default Dimensions "D1" and "D2" of "Global Dimension 2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        for i := 1 to 2 do begin
            CreateItemWithDefaultDimensionValue(Item[i], DimensionValue[i], GlobalDimensionCode);
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[i], PurchaseHeader, PurchaseLine[i].Type::Item, Item[i]."No.", LibraryRandom.RandInt(10));
            PurchaseLine[i].Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
            PurchaseLine[i].Modify(true);
        end;

        // [GIVEN] "L3" has Type "Charge (Item)", "No." = "IC" with Default Dimensions "D3" of "Global Dimension 2"
        CreateItemChargeWithDefaultDimensionValue(ItemCharge, DimensionValue[3], GlobalDimensionCode);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[3], PurchaseHeader, PurchaseLine[3].Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine[3].Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine[3].Modify(true);

        // [GIVEN] Item Charge from "L3" is assigned to "L1" and "L2"
        for i := 1 to 2 do begin
            LibraryPurchase.CreateItemChargeAssignment(
              ItemChargeAssignmentPurch[i], PurchaseLine[3], ItemCharge,
              ItemChargeAssignmentPurch[i]."Applies-to Doc. Type"::Invoice,
              PurchaseLine[i]."Document No.", PurchaseLine[i]."Line No.", PurchaseLine[i]."No.",
              0.5, LibraryRandom.RandInt(1000));
            ItemChargeAssignmentPurch[i].Insert;
        end;

        // [WHEN] Post "P"
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Value Entry with "Entry Type" "Direct Cost", "I1" and blank item charge has "Global Dimension 2 Code" = "D1"
        FindDirectCostValueEntry(ValueEntry, Item[1]."No.", '');
        ValueEntry.TestField("Global Dimension 2 Code", DimensionValue[1].Code);

        // [THEN] Value Entry with "Entry Type" "Direct Cost", "I2" and blank item charge has "Global Dimension 2 Code" = "D2"
        FindDirectCostValueEntry(ValueEntry, Item[2]."No.", '');
        ValueEntry.TestField("Global Dimension 2 Code", DimensionValue[2].Code);

        // [THEN] Value Entry with "Entry Type" "Direct Cost", "I1" and item charge "IC" has "Global Dimension 2 Code" = "D3"
        FindDirectCostValueEntry(ValueEntry, Item[1]."No.", ItemCharge."No.");
        ValueEntry.TestField("Global Dimension 2 Code", DimensionValue[3].Code);

        // [THEN] Value Entry with "Entry Type" "Direct Cost", "I2" and item charge "IC" has "Global Dimension 2 Code" = "D3"
        FindDirectCostValueEntry(ValueEntry, Item[2]."No.", ItemCharge."No.");
        ValueEntry.TestField("Global Dimension 2 Code", DimensionValue[3].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcValueEntryCostAmountActualWithDifferentUOM()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Purchase] [Unit of Measure]
        // [SCENARIO 256926] "Qty. per Unit of Measure" in purchase line is updated during posting with the value corresponding to "Unit of Measure Code"
        Initialize;

        // [GIVEN] Workcenter "W" with subcontractor "S"
        CreateWorkCenterWithSubcontractor(WorkCenter);

        // [GIVEN] Production item "I" with routing with "W"
        UpdateRoutingOnItem(Item, WorkCenter."No.");

        // [GIVEN] Item unit of measure "UOM" with description different from its code and quantity per more then 1
        CreateItemUnitOfMeasureWithDescription(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Production order "P" of "I"
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandInt(10));

        // [GIVEN] Unit of measure of line of "P" set to "UOM"
        UpdateUOMInProdOrderLine(ProductionOrder, ItemUnitOfMeasure.Code);

        // [GIVEN] Calculate subcontract order and carry out action messages for "P" and "S", purchase order "R" is created
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // [WHEN] Post "R"
        FindPurchLineAndPostPurchOrder(PurchaseLine, Item."No.");

        // [THEN] The fields "Qty. per Unit of Measure" in created purchase receipt line and in "UOM" are equal
        FindPurchRcptLine(PurchRcptLine, Item."No.");
        PurchRcptLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateItemCrossReferenceDescriptionEmpty()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        ItemCrossReference: Record "Item Cross Reference";
    begin
        // [FEATURE] [Item Cross Reference]
        // [SCENARIO 263347] Description field in Item Cross Reference must stay empty when record is created

        Initialize;

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Create ItemVendor
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        // [THEN] Item Cross Reference with empty Description must be created
        ItemCrossReference.SetRange("Item No.", Item."No.");
        ItemCrossReference.FindFirst;
        ItemCrossReference.TestField(Description, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderForWhiteLocationAndItemTracking()
    var
        Item1: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        LocationWhite: Record Location;
    begin
        // [FEATURE] [Purchase] [Pick] [Item Tracking]
        // [SCENARIO 288433] Purchase Order for a Warehouse location should not be posted as Receive

        Initialize;

        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.

        // [GIVEN] Location with directed pick and put away - White
        // [GIVEN] Items "I1" and "I2" with lot tracking
        LibraryItemTracking.CreateLotItem(Item1);
        LibraryItemTracking.CreateLotItem(Item2);

        // [GIVEN] Create purchase order for items "I1" and "I2" and assign lot no. in first line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item1."No.", LibraryRandom.RandDec(100, 2));
        PurchaseLine1.Validate("Location Code", LocationWhite.Code);
        PurchaseLine1.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item2."No.", LibraryRandom.RandDec(100, 2));
        PurchaseLine2.Validate("Location Code", LocationWhite.Code);
        PurchaseLine2.Modify(true);

        // [GIVEN] Release order and create warehouse receipt from the purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWhseReceiptFromPurchOrder(WarehouseReceiptHeader, PurchaseHeader);

        // [GIVEN] Assign lot no. to first line in warehouse receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Item No.", Item1."No.");
        WarehouseReceiptLine.FindFirst;
        LibraryVariableStorage.Enqueue(WarehouseReceiptLine."Qty. (Base)");
        WarehouseReceiptLine.OpenItemTrackingLines; // Use handler to assign lot no.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Assign lot no. to second line in purchase order
        LibraryVariableStorage.Enqueue(PurchaseLine2."Quantity (Base)");
        PurchaseLine2.OpenItemTrackingLines;

        // [WHEN] Post purchase order and get error
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Check that purchase order is not posted
        Assert.ExpectedError('Warehouse handling is required');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderForWhiteLocationAndUndoReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationWhite: Record Location;
    begin
        // [FEATURE] [Purchase] [Undo] [Warehouse]
        // [SCENARIO 288903] Posting of Receipt from Purchase order skipping WMS requirements after posted receipt was undone

        Initialize;

        // [GIVEN] Location with directed pick and put away - White
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.

        // [GIVEN] Create purchase order for item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationWhite.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(100, 2));

        // [GIVEN] Release order and create warehouse receipt from the purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWhseReceiptFromPurchOrder(WarehouseReceiptHeader, PurchaseHeader);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Remove created put-away
        WarehouseActivityHeader.SetRange("Location Code", LocationWhite.Code);
        WarehouseActivityHeader.FindLast;
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Find posted purchase receipt and undo line
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);
        Commit;

        // [WHEN] Post purchase order as receipt
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Check that purchase line Qty. To Receipt is 0 (due to WMS location)
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
        Assert.AreEqual(0, PurchaseLine."Qty. to Receive", 'Qty. to Receive is not 0.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Misc. V");
        LibraryVariableStorage.Clear;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. V");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. V");
    end;

    local procedure CreateWorkCenter(): Code[20]
    var
        Currency: Record Currency;
        WorkCenter: Record "Work Center";
    begin
        Currency.Get(CreateCurrency);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", CreateAndModifyVendor(Currency.Code));
        WorkCenter.Modify(true);
        exit(WorkCenter."No.");
    end;

    local procedure CreateWorkCenterWithSubcontractor(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateRoutingOnItem(var Item: Record Item; WorkCenterNo: Code[20])
    begin
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::Manual, Item."Replenishment System"::Purchase));
        Item.Validate("Routing No.", CreateRoutingSetup(WorkCenterNo, ''));
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndModifyItemVariant(var ItemVariant: Record "Item Variant"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemVariant.Validate(Description, LibraryUtility.GenerateGUID);
        ItemVariant.Modify(true);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::Manual, Item."Replenishment System"::Purchase));
        UpdateInventoryPostingSetup(LocationCode, Item."Inventory Posting Group");
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', LocationCode, BinCode);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
    end;

    local procedure CreateAndRegisterPick(SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        CreatePickWorksheetLine(WhseWorksheetLine, SourceNo, LocationCode);

        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          LocationCode, '', 0, 0, 0, false, false, false, false, false, false, false);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreatePickWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst;
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        PickRequestDocumentNo := SourceNo;
        PickRequestLocationCode := LocationCode;
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);

        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindSet;
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption, ItemNo,
          ProductionOrder.Quantity);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Location Code", ProductionOrder."Location Code");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndUpdateProductionBOM(var ParentItem: Record Item; ChildItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItemNo, '');
        UpdateItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; BinCode: Code[20]; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.",
          FindProductionOrderLine(ProductionOrder."No.", ProductionOrder.Status));
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(5));
        ProdOrderComponent.Validate("Location Code", ProductionOrder."Location Code");
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Modify(true);
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(10));
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 10 + LibraryRandom.RandInt(10)); // Use random Quantity.
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2)); // Using Random value for Unit Cost.
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasureWithDescription(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; UOMQtyPer: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(UnitOfMeasure.Description)));
        UnitOfMeasure.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, UOMQtyPer);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Invoice: Boolean): Code[20]
    begin
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, ItemNo, '', CreateVendor, LibraryRandom.RandInt(10), WorkDate);
        exit(PostPurchaseDocument(PurchaseLine, Invoice));
    end;

    local procedure CreateMachineCenter(RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    var
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        UpdateRoutingHeaderStatus(RoutingHeader, RoutingHeader.Status::New);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID, RoutingLine.Type::"Machine Center", MachineCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Concurrent Capacities", 1);
        RoutingLine.Modify(true);

        UpdateRoutingHeaderStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateSameCodeDefaultDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; TableNo: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableNo, No, DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateItemWithDefaultDimensionValue(var Item: Record Item; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        CreateSameCodeDefaultDimensionValue(DimensionValue, DimensionCode, DATABASE::Item, Item."No.");
    end;

    local procedure CreateItemChargeWithDefaultDimensionValue(var ItemCharge: Record "Item Charge"; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSameCodeDefaultDimensionValue(DimensionValue, DimensionCode, DATABASE::"Item Charge", ItemCharge."No.");
    end;

    local procedure CarryOutAMSubcontractWksh(No: Code[20]; ItemNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        WorkCenter: Record "Work Center";
        RequisitionLine: Record "Requisition Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        WorkCenter.SetRange("No.", No);
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst;
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // take random Direct Cost.
        RequisitionLine.Validate("Gen. Business Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        RequisitionLine.Modify(true);
        Vendor.Get(RequisitionLine."Vendor No.");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        if not VATPostingSetup.FindFirst then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", '');
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateAndModifyItem(VendorNo: Code[20]; FlushingMethod: Option; ReplenishmentSystem: Option): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndModifyVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; ItemNo: Code[20]; VariantCode: Code[10]; VendorNo: Code[20]; Quantity: Decimal; OrderDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Order Date", OrderDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);

        // Update 'Invt. Accrual Acc. (Interim)' in General Posting Setup.
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
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

    local procedure CreateRoutingSetup(WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));  // Take random for Unit Price.
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateWarehouseLocation(var Bin: array[2] of Record Bin): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location);

        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin[1], Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin[1].FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin[1].FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin[2].FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin[2].FieldNo(Code))), '', '');
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateWhseReceiptFromPurchOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No."));
    end;

    local procedure UpdateInventoryPostingSetup(LocationCode: Code[10]; InventoryPostingGroupCode: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        RefInventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        RefInventoryPostingSetup.SetFilter("Inventory Account", '<>%1', '');
        RefInventoryPostingSetup.SetFilter("WIP Account", '<>%1', '');
        RefInventoryPostingSetup.FindFirst;
        InventoryPostingSetup.Init;
        InventoryPostingSetup.Validate("Location Code", LocationCode);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroupCode);
        if not InventoryPostingSetup.Insert(true) then;
        InventoryPostingSetup."Inventory Account" := RefInventoryPostingSetup."Inventory Account";
        InventoryPostingSetup."WIP Account" := RefInventoryPostingSetup."WIP Account";
        InventoryPostingSetup.Modify;
    end;

    local procedure UpdateUOMInProdOrderLine(ProductionOrder: Record "Production Order"; ItemUnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure FindAndUpdateProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20])
    begin
        FindProdOrderRountingLine(ProdOrderRoutingLine, ProdOrderNo, ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.Validate("Send-Ahead Quantity", LibraryRandom.RandInt(10));  // Take random to update Quantity.
    end;

    local procedure FindPurchLineAndPostPurchOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify(true);
        if not GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(
              GeneralPostingSetup, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure FindCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst;
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; OrderNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", OrderNo);
        CapacityLedgerEntry.FindFirst;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
    end;

    local procedure FindProductionOrderLine(ProdOrderNo: Code[20]; Status: Option): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst;
        exit(ProdOrderLine."Line No.");
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
    end;

    local procedure FindProdOrderRountingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Option)
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange(Type, Type);
        ProdOrderRoutingLine.FindFirst;
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

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntryType: Option; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst;
    end;

    local procedure FindDirectCostValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; ItemChargeNo: Code[20])
    begin
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst;
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst;
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Option; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst;
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Option)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupProductionOrder(var ProductionOrder: Record "Production Order"; Bin: Record Bin; ItemNo: Code[20])
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::Manual, Item."Replenishment System"::"Prod. Order"));
        UpdateInventoryPostingSetup(Bin."Location Code", Item."Inventory Posting Group");
        CreateAndUpdateProductionBOM(Item, ItemNo);
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", Bin."Location Code", 1);  // Taken 1 for Quantity as value is important.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.ModifyAll("Bin Code", Bin.Code);
    end;

    local procedure UpdateItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingHeaderStatus(var RoutingHeader: Record "Routing Header"; Status: Option)
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateVariantOnItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.Validate("Variant Code", '');
        ItemJournalLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: Page "Pick Selection"; var Response: Action)
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Location Code", PickRequestLocationCode);
        WhsePickRequest.SetRange("Document No.", PickRequestDocumentNo);
        WhsePickRequest.FindFirst;
        PickSelection.SetRecord(WhsePickRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyBase: Decimal;
    begin
        ItemTrackingLines."Assign Lot No.".Invoke;
        QtyBase := LibraryVariableStorage.DequeueDecimal;
        ItemTrackingLines."Quantity (Base)".SetValue(QtyBase);
    end;
}

