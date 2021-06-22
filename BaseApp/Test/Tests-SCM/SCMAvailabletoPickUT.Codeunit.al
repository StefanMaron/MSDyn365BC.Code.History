codeunit 137501 "SCM Available to Pick UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        TooManyPickLinesErr: Label 'There were too many pick lines generated.';
        DifferentQtyErr: Label 'Quantity on pick line different from quantity on shipment line.';
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NothingToHandleErr: Label 'Nothing to handle.';
        NothingToCreateErr: Label 'There is nothing to create.';
        InvtPutAwayMsg: Label 'Number of Invt. Put-away activities created: 1 out of a total of 1.';
        InvtPickMsg: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        MissingExpectedErr: Label 'Unexpected message: %1';
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        OverStockErr: Label 'item no. %1 is not available';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Available to Pick UT");
        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Available to Pick UT");

        LibraryApplicationArea.EnableFoundationSetup;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        // Setup Demonstration data.
        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Available to Pick UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Positive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Negative);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Partial);
    end;

    [Normal]
    local procedure DirectedPutawayAndPick(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize;
        SetupLocation(Location, true, true, true);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst;

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 9, '', '');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 4;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 5;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 9;
                    SecondSOQty := 4;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst;

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::Pick, 37, WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", 1, '', '');

        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SecondSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst;

        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", WhseShipmentLine.Quantity);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", WhseShipmentLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 2);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", 2);
                end;
            TestType::Negative:
                begin
                    asserterror LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    Assert.IsTrue(StrPos(GetLastErrorText, NothingToHandleErr) > 0, 'Unexpected error message');
                    ClearLastError;
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Positive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Negative);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Partial);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Positive);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler')]
    [Scope('OnPrem')]
    procedure PickNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Negative);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Partial);
    end;

    [Normal]
    local procedure PickAndShipment(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize;
        Clear(Location);
        SetupLocation(Location, false, true, true);
        SetupWarehouse(Location.Code);
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", 10);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst;
        WhseReceiptLine.Validate("Bin Code", 'RECEIPT');
        WhseReceiptLine.Modify;

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 10, 'RECEIPT', 'PICK');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 5;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 6;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 10;
                    SecondSOQty := 5;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst;
        WhseShipmentLine.Validate("Bin Code", 'SHIPMENT');
        WhseShipmentLine.Modify;

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        Clear(SalesHeader);
        Clear(WhseShipmentHeader);
        Clear(WhseShipmentLine);
        CreateAndPostSalesOrder(SalesHeader, SalesLine, Location.Code, Item."No.", SecondSOQty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst;
        WhseShipmentLine.Validate("Bin Code", 'SHIPMENT');
        WhseShipmentLine.Modify;

        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", WhseShipmentLine.Quantity);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", WhseShipmentLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 3);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", 3);
                end;
            TestType::Negative:
                begin
                    asserterror LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    Assert.IsTrue(StrPos(GetLastErrorText, NothingToHandleErr) > 0, 'Unexpected error message');
                    ClearLastError;
                end;
        end;
    end;

    [Normal]
    local procedure Pick(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Location: Record Location;
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize;
        Clear(Location);
        SetupLocation(Location, false, false, true);
        SetupWarehouse(Location.Code);
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", 10);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Invt. Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 10, '', 'PICK');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 5;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 6;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 10;
                    SecondSOQty := 5;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        Clear(SalesHeader);
        CreateAndPostSalesOrder(SalesHeader, SalesLine, Location.Code, Item."No.", SecondSOQty);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", SalesLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 3);
                end;
            TestType::Negative:
                LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByPeriodHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByPeriodFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByPeriod;
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByLocationHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByLocationFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByLocation;
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByVariantHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByVariantFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByVariant;
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByEventHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByEventFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByEvent;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAvailabilityByVariant()
    var
        SalesHeader: Record "Sales Header";
        TempItemVariant: Record "Item Variant" temporary;
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        i: Integer;
        ItemVariantQuantity: Decimal;
    begin
        // [SCENARIO 361061.1] Verify overstock by Variant in case of different Variant codes used in one Sales Order
        Initialize;

        // [GIVEN] 2 items "Item[i]", 2 Variant Codes "Var[i][j]" per each "Item[i]"
        CreateItemsWithVariants(TempItemVariant, 2, 2);

        // [GIVEN] Sales Order with "Shipping Advice" = COMPLETE, several Sales Lines per each "Var[i][j]"
        // [GIVEN] All item variants have exact inventory to comply the sales order
        MockSalesHeader(SalesHeader);
        TempItemVariant.FindSet;
        repeat
            ItemVariantQuantity := 0;
            for i := 1 to 2 do
                ItemVariantQuantity += MockSalesLine(SalesHeader, TempItemVariant);
            MockPositiveILE(TempItemVariant, ItemVariantQuantity);
        until TempItemVariant.Next = 0;

        // [GIVEN] Additional Sales Line with "Var[1][2]" for overstock condition
        TempItemVariant.FindFirst;
        TempItemVariant.SetRange("Item No.", TempItemVariant."Item No.");
        TempItemVariant.FindLast;
        MockSalesLine(SalesHeader, TempItemVariant);

        // [WHEN] Check Sales Order Availability
        asserterror GetSourceDocOutbound.CheckSalesHeader(SalesHeader, true);

        // [THEN] Error: 'item no. "Item[1]" is not available'
        Assert.ExpectedError(StrSubstNo(OverStockErr, TempItemVariant."Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderAvailabilityByVariant()
    var
        TransferHeader: Record "Transfer Header";
        TempItemVariant: Record "Item Variant" temporary;
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        i: Integer;
        ItemVariantQuantity: Decimal;
    begin
        // [SCENARIO 361061.2] Verify overstock by Variant in case of different Variant codes used in one Transfer Order
        Initialize;

        // [GIVEN] 2 items "Item[i]", 2 Variant Codes "Var[i][j]" per each "Item[i]"
        CreateItemsWithVariants(TempItemVariant, 2, 2);

        // [GIVEN] Transfer Order with "Shipping Advice" = COMPLETE, several Transfer Lines per each "Var[i][j]"
        // [GIVEN] All item variants have exact inventory to comply the Transfer Order
        MockTransferHeader(TransferHeader);
        TempItemVariant.FindSet;
        repeat
            ItemVariantQuantity := 0;
            for i := 1 to 2 do
                ItemVariantQuantity += MockTransferLine(TempItemVariant, TransferHeader."No.");
            MockPositiveILE(TempItemVariant, ItemVariantQuantity);
        until TempItemVariant.Next = 0;

        // [GIVEN] Additional Transfer Line with "Var[1][2]" for overstock condition
        TempItemVariant.FindFirst;
        TempItemVariant.SetRange("Item No.", TempItemVariant."Item No.");
        TempItemVariant.FindLast;
        MockTransferLine(TempItemVariant, TransferHeader."No.");

        // [WHEN] Check Transfer Order Availability
        asserterror GetSourceDocOutbound.CheckTransferHeader(TransferHeader, true);

        // [THEN] Error: 'item no. "Item[1]" is not available'
        Assert.ExpectedError(StrSubstNo(OverStockErr, TempItemVariant."Item No."));
    end;

    local procedure SetupWhseActivityLineForShowItemAvailability(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        Initialize;
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."Item No." := LibraryInventory.CreateItemNo;
    end;

    [Normal]
    local procedure SetupWarehouse(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
    end;

    [Normal]
    local procedure SetupLocation(var Location: Record Location; IsDirected: Boolean; ShipmentRequired: Boolean; BinMandatory: Boolean)
    var
        Bin: Record Bin;
    begin
        Location.Init;
        Location.SetRange("Bin Mandatory", BinMandatory);
        Location.SetRange("Require Shipment", ShipmentRequired);
        Location.SetRange("Require Receive", true);
        Location.SetRange("Require Pick", true);
        Location.SetRange("Require Put-away", true);
        Location.SetRange("Directed Put-away and Pick", IsDirected);

        if not Location.FindFirst then
            if not IsDirected then begin
                LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
                Location.Validate("Require Put-away", true);
                Location.Validate("Require Pick", true);
                Location.Validate("Require Receive", ShipmentRequired);
                Location.Validate("Require Shipment", ShipmentRequired);
                Location.Validate("Bin Mandatory", BinMandatory);
                Location.Modify(true);
                CreateBin(Bin, Location.Code, 'RECEIPT', '', '');
                CreateBin(Bin, Location.Code, 'PICK', '', '');
                CreateBin(Bin, Location.Code, 'SHIPMENT', '', '');
            end;

        Location.Validate("Always Create Pick Line", false);
        Location.Modify(true);
    end;

    local procedure CreateBin(var Bin: Record Bin; LocationCode: Text[10]; BinCode: Text[20]; ZoneCode: Text[10]; BinTypeCode: Text[10])
    begin
        Clear(Bin);
        Bin.Init;
        Bin.Validate("Location Code", LocationCode);
        Bin.Validate(Code, BinCode);
        Bin.Validate("Zone Code", ZoneCode);
        Bin.Validate("Bin Type Code", BinTypeCode);
        Bin.Insert(true);
    end;

    local procedure CreateItemsWithVariants(var ItemVariant: Record "Item Variant"; ItemCnt: Integer; VariantCntPerItem: Integer)
    var
        ItemNo: Code[20];
        i: Integer;
        j: Integer;
    begin
        for i := 1 to ItemCnt do begin
            ItemNo := MockItem;
            for j := 1 to VariantCntPerItem do begin
                ItemVariant.Init;
                ItemVariant."Item No." := ItemNo;
                ItemVariant.Code := MockItemVariantCode(ItemNo);
                ItemVariant.Insert;
            end;
        end;
    end;

    [Normal]
    local procedure CheckPick(LineType: Option; SalesOrderNo: Code[20]; ExpectedQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", 37);
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Sales Order");
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Action Type", LineType);
        Assert.AreEqual(WhseActivityLine.Count, 1, TooManyPickLinesErr);
        WhseActivityLine.FindFirst;
        Assert.AreEqual(WhseActivityLine.Quantity, ExpectedQty, DifferentQtyErr);
    end;

    [Normal]
    local procedure RegisterWhseActivity(ActivityType: Option; SourceType: Integer; SourceDocument: Option; SourceNo: Code[20]; QtyToHandle: Decimal; TakeBinCode: Code[10]; PlaceBinCode: Code[10])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset;
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet;
        repeat
            WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) and (TakeBinCode <> '') then
                WhseActivityLine."Bin Code" := TakeBinCode
            else
                if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place) and (PlaceBinCode <> '') then
                    WhseActivityLine."Bin Code" := PlaceBinCode;

            WhseActivityLine.Modify;
        until WhseActivityLine.Next = 0;

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst;
        if (ActivityType = WhseActivityLine."Activity Type"::"Put-away") or
           (ActivityType = WhseActivityLine."Activity Type"::Pick)
        then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemQuantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ItemQuantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemQuantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, ItemQuantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure MockItem(): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Item);
            Insert;
            exit("No.");
        end;
    end;

    local procedure MockItemVariantCode(ItemNo: Code[20]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        with ItemVariant do begin
            Init;
            "Item No." := ItemNo;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Item Variant");
            Insert;
            exit(Code);
        end;
    end;

    local procedure MockPositiveILE(ItemVariant: Record "Item Variant"; ILEQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastEntryNo: Integer;
    begin
        with ItemLedgerEntry do begin
            FindLast;
            LastEntryNo := "Entry No.";
            Init;
            "Entry No." := LastEntryNo + 1;
            "Item No." := ItemVariant."Item No.";
            "Variant Code" := ItemVariant.Code;
            Quantity := ILEQty;
            Insert;
        end;
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            Init;
            "Document Type" := "Document Type"::Order;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Sales Header");
            "Shipping Advice" := "Shipping Advice"::Complete;
            Insert;
        end;
    end;

    local procedure MockSalesLine(SalesHeader: Record "Sales Header"; ItemVariant: Record "Item Variant"): Decimal
    var
        SalesLine: Record "Sales Line";
        LastLineNo: Integer;
    begin
        with SalesLine do begin
            LastLineNo := 0;
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindLast then
                LastLineNo := "Line No.";
            Init;
            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            "Line No." := LastLineNo + 10000;
            Type := Type::Item;
            "No." := ItemVariant."Item No.";
            "Variant Code" := ItemVariant.Code;
            "Outstanding Qty. (Base)" := LibraryRandom.RandDec(100, 2);
            Insert;
            exit("Outstanding Qty. (Base)");
        end;
    end;

    local procedure MockTransferHeader(var TransferHeader: Record "Transfer Header")
    begin
        with TransferHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Transfer Header");
            "Shipping Advice" := "Shipping Advice"::Complete;
            Insert;
        end;
    end;

    local procedure MockTransferLine(ItemVariant: Record "Item Variant"; TransferHeaderNo: Code[20]): Decimal
    var
        TransferLine: Record "Transfer Line";
        LastLineNo: Integer;
    begin
        with TransferLine do begin
            LastLineNo := 0;
            SetRange("Document No.", TransferHeaderNo);
            if FindLast then
                LastLineNo := "Line No.";
            Init;
            "Document No." := TransferHeaderNo;
            "Line No." := LastLineNo + 10000;
            "Item No." := ItemVariant."Item No.";
            "Variant Code" := ItemVariant.Code;
            "Outstanding Qty. (Base)" := LibraryRandom.RandDec(100, 2);
            Insert;
            exit("Outstanding Qty. (Base)");
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ErrorHandler(Message: Text[1024])
    begin
        Message := DelChr(Message, '<>');
        if not (Message in [NothingToCreateErr, InvtPutAwayMsg, InvtPickMsg]) then
            Error(StrSubstNo(MissingExpectedErr, Message));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByPeriodHandler(var ItemAvailabilityByPeriods: Page "Item Availability by Periods"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByLocationHandler(var ItemAvailabilityByLocation: Page "Item Availability by Location"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByVariantHandler(var ItemAvailabilityByVariant: Page "Item Availability by Variant"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByEventHandler(var ItemAvailabilityByEvent: Page "Item Availability by Event"; var Response: Action)
    begin
    end;
}

