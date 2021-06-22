codeunit 137931 "SCM - Movement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Movement]
    end;

    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TotalPendingMovQtyExceedsBinAvailErr: Label 'Item tracking defined for line %1, lot number %2, serial number %3';
        DialogCodeErr: Label 'Dialog';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.';

    [Test]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentQtyHandledBase()
    var
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Decimal;
    begin
        // [FEATURE] [UT] [Movement Worksheet] [Qty. Handled]
        // [SCENARIO 312913] When Calculate Bin Replenishment in Movement Worksheet then Qty Handled (Base) is <zero>
        Initialize;
        ItemNo := LibraryInventory.CreateItemNo;
        MinQty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with with Pick Bin and Put-away Bin, Bin Ranking is higher for Pick Bin
        // [GIVEN] Bin Content for Put-away Bin had 10 PCS
        // [GIVEN] Fixed Bin Content for Pick Bin with Item, Min Qty = 5, Max Qty = 15
        LocationCode := CreateFullWMSLocation(1, false);

        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PutAwayBin."Zone Code", PutAwayBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentQty(BinContent, 2 * MinQty);

        LibraryWarehouse.FindBin(PickBin, LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PickBin."Zone Code", PickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishment(
          BinContent, MinQty, 3 * MinQty, PutAwayBin."Bin Ranking" + LibraryRandom.RandInt(10), PickBin."Bin Type Code");

        // [WHEN] Calculate Bin Replenishment
        CalculateBinReplenishment(BinContent, LocationCode);

        // [THEN] Whse. Worksheet Line is created for Pick Bin with Qty Handled = Qty Handled (Base) = 0
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst;
        WhseWorksheetLine.TestField("To Bin Code", PickBin.Code);
        WhseWorksheetLine.TestField("Qty. Outstanding", 2 * MinQty);
        WhseWorksheetLine.TestField("Qty. Handled", 0);
        WhseWorksheetLine.TestField("Qty. Handled (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandlerMultipleEntries')]
    [Scope('OnPrem')]
    procedure CreateMovementFromWkshWhenMultipleSimilarWkshLinesFEFO()
    var
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Integer;
        LotNo: array[4] of Code[50];
        ExpirationDate: array[4] of Date;
        Qty: array[4] of Integer;
        Delta: Integer;
        Index: Integer;
    begin
        // [FEATURE] [Movement Worksheet] [FEFO] [Item Tracking]
        // [SCENARIO 312913] Create Movement from Movement Worksheet generates correct Movements when multiple Similar Lines Present
        // [SCENARIO 312913] and pending Whse Shipment when Pick According to FEFO is enabled
        Initialize;
        InitQtys(MinQty, Qty, 2, 2, 10, 6);
        Delta := 1;
        for Index := 1 to ArrayLen(LotNo) do begin
            LotNo[Index] := LibraryUtility.GenerateGUID;
            ExpirationDate[Index] := CalcDate(StrSubstNo('<%1M>', Index), WorkDate);
        end;

        // [GIVEN] Item had Item Tracking Code with Lot Tracking and Man. Expir. Date Entry Reqd.
        ItemNo := CreateItemWithItemTrackingCode(true, true, true);

        // [GIVEN] Location with Pick According to FEFO enabled
        // [GIVEN] Pick Bin and 3 Put-away Bins "B1", "B2" and "B3", Bin Ranking was higher for Pick Bin
        // [GIVEN] Fixed Bin Content for Pick Bin with the Item, Min Qty = 10, Max Qty = 30
        LocationCode := CreateFullWMSLocation(1, true);
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.CreateNumberOfBins(LocationCode, PutAwayBin."Zone Code", PutAwayBin."Bin Type Code", 2, false);
        LibraryWarehouse.FindBin(PickBin, LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        SetBinRanking(PickBin, PutAwayBin."Bin Ranking" + LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PickBin."Zone Code", PickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishment(BinContent, MinQty, 3 * MinQty, PickBin."Bin Ranking", PickBin."Bin Type Code");

        // [GIVEN] Released Purchase Order with 20 PCS of the Item, Item Tracking was specified as follows:
        // [GIVEN] Lot "L1" with 2 PCS, Expiration Date = 1/1/2021
        // [GIVEN] Lot "L2" with 2 PCS, Expiration Date = 1/2/2021
        // [GIVEN] Lot "L3" with 10 PCS, Expiration Date = 1/3/2021
        // [GIVEN] Lot "L4" with 6 PCS, Expiration Date = 1/4/2021
        // [GIVEN] Posted Whse Receipt
        CreatePurchaseOrderWithLocationAndItem(PurchaseHeader, LocationCode, ItemNo, 2 * MinQty);
        PrepareItemTrackingLinesPurchase(PurchaseHeader, LotNo, ExpirationDate, Qty);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PostWhseReceipt(PurchaseHeader);

        // [GIVEN] Updated Put-away Place Lines as follows:
        // [GIVEN] Line with Lot "L2" had Bin Code = "B1"
        // [GIVEN] Line with Lot "L3" had Bin Code = "B2"
        // [GIVEN] Line with Lot "L4" had Bin Code = "B3"
        // [GIVEN] Registered Put-away
        FindPutAway(WarehouseActivityHeader, ItemNo);
        FilterWhseActivityLines(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place);
        for Index := 1 to ArrayLen(LotNo) - 1 do begin
            LibraryWarehouse.FindBin(PutAwayBin, LocationCode, PutAwayBin."Zone Code", Index);
            WarehouseActivityLine.SetRange("Lot No.", LotNo[Index + 1]);
            WarehouseActivityLine.FindFirst;
            WarehouseActivityLine.Validate("Zone Code", PutAwayBin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", PutAwayBin.Code);
            WarehouseActivityLine.Modify(true);
        end;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Released Sales Order with 2 PCS of Item with Lot "L1", created Warehouse Shipment and registered Pick
        CreateSalesOrderWithLocationAndItem(SalesHeader, LocationCode, ItemNo, Qty[1]);
        PrepareItemTrackingLineSales(SalesHeader, LotNo[1], Qty[1]);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        RegisterPick(SalesHeader);

        // [GIVEN] Calculated Bin Replenishment (Whse. Worksheet Lines were created with Total 18 PCS = 2 + 10 + 6 PCS)
        CalculateBinReplenishment(BinContent, LocationCode);

        // [GIVEN] Changed Qty. to Handle in the Lines, so that 16 PCS are handled
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindSet;
        WhseWorksheetLine.Next;
        repeat
            WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine."Qty. to Handle" - Delta);
            WhseWorksheetLine.Modify();
        until WhseWorksheetLine.Next = 0;

        // [GIVEN] Created Movement (3 Take Lines: Lot "L2", Bin "B1" with 2 PCS, Lot "L3", Bin "B2" with 10 PCS, Lot "L4", Bin "B3" with 4 PCS)
        // [GIVEN] Registered Movement
        CreateMovementFromMovementWorksheet;
        FindMovement(WarehouseActivityHeader, ItemNo);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Create Movement
        CreateMovementFromMovementWorksheet;

        // [THEN] Movement has Take Line with Lot "L4", Bin "B3" and 2 PCS
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, PutAwayBin."Zone Code", 3);
        FindMovement(WarehouseActivityHeader, ItemNo);
        FilterWhseActivityLines(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityLine.TestField("Lot No.", LotNo[4]);
        WarehouseActivityLine.TestField("Bin Code", PutAwayBin.Code);
        WarehouseActivityLine.TestField("Qty. to Handle", 2 * Delta);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithTrackingWhenPendingMovementExistsAndMoreQtyInTrkg()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        Bin: Record Bin;
        ToBin: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[2] of Code[50];
        QtyLot: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 325576] When pending Movements present then Movement is not created from Movement Worksheet if Lot Tracked Item has not enough PCS in the Bin
        Initialize;
        LotNo[1] := LibraryUtility.GenerateGUID;
        LotNo[2] := LibraryUtility.GenerateGUID;
        QtyLot[1] := 1 + LibraryRandom.RandInt(10);
        QtyLot[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Location with 2 Bins
        LocationCode := CreateFullWMSLocation(2, false);

        // [GIVEN] Item with Lot Warehouse Tracking enabled
        ItemNo := CreateItemWithItemTrackingCode(true, true, false);

        // [GIVEN] Bin "B" had 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, QtyLot[1] + QtyLot[2], true);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate, '');

        // [GIVEN] Warehouse Movement Worksheet Line with 1 PCS of the Item with From-Bin = "B" and Lot "L1"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', 1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines;

        // [GIVEN] Created Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", 0, false, false);

        // [GIVEN] Warehouse Movement Worksheet Line with 10 PCS of the Item with From-Bin = "B"
        // [GIVEN] Warehouse Item Tracking was specified as follows: 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', QtyLot[1] + QtyLot[2]);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        WhseWorksheetLine.OpenItemTrackingLines;

        // [WHEN] Create Movement from Worksheet
        asserterror LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", 0, false, false);

        // [THEN] Error 'Item tracking defined for line 10000, lot number L1, serial number cannot be applied.'
        Assert.ExpectedError(StrSubstNo(TotalPendingMovQtyExceedsBinAvailErr, WhseWorksheetLine."Line No.", LotNo[1], ''));
        Assert.ExpectedErrorCode(DialogCodeErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithTrackingWhenPendingMovementExists()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        Bin: Record Bin;
        ToBin: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[2] of Code[50];
        QtyLot: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 325576] When pending Movements present then Movement is created from Movement Worksheet if Lot Tracked Item has enough PCS in the Bin
        Initialize;
        LotNo[1] := LibraryUtility.GenerateGUID;
        LotNo[2] := LibraryUtility.GenerateGUID;
        QtyLot[1] := 1 + LibraryRandom.RandInt(10);
        QtyLot[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Location with 2 Bins
        LocationCode := CreateFullWMSLocation(2, false);

        // [GIVEN] Item with Lot Warehouse Tracking enabled
        ItemNo := CreateItemWithItemTrackingCode(true, true, false);

        // [GIVEN] Bin "B" had 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, QtyLot[1] + QtyLot[2], true);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate, '');

        // [GIVEN] Warehouse Movement Worksheet Line with 1 PCS of the Item with From-Bin = "B" and Lot "L1"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', 1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines;

        // [GIVEN] Created Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", 0, false, false);

        // [GIVEN] Warehouse Movement Worksheet Line with 9 PCS of the Item with From-Bin = "B"
        // [GIVEN] Warehouse Item Tracking was specified as follows: 3 PCS with Lot "L1" and 6 PCS with Lot "L2"
        QtyLot[1] -= WhseWorksheetLine."Qty. (Base)";
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', QtyLot[1] + QtyLot[2]);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        WhseWorksheetLine.OpenItemTrackingLines;

        // [WHEN] Create Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", 0, false, false);

        // [THEN] Movement is created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.");
        WarehouseActivityLine.SetRange("Bin Code", Bin.Code);
        WarehouseActivityLine.SetRange("Lot No.", LotNo[2]);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        for Index := 1 to ArrayLen(LotNo) do begin
            WarehouseActivityLine.SetRange("Lot No.", LotNo[Index]);
            WarehouseActivityLine.FindFirst;
            WarehouseActivityLine.TestField("Qty. (Base)", QtyLot[Index]);
        end;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrWhenValidateLocationCodeIntMovementWithLine()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        Location: Record Location;
    begin
        // [FEATURE] [UT] [Internal Movement]
        // [SCENARIO 311310] Location Code cannot be changed in Internal Movement if Lines present.
        Initialize;

        // [GIVEN] Internal Movement with Location 'BLUE' had Internal Movement Line
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, LibraryInventory.CreateItemNo, '', '', LibraryRandom.RandInt(10));
        CreateLocationWithBinMandatory(Location, true);

        // [WHEN] Validate Location Code = 'SILVER' in Internal Movement Header
        asserterror InternalMovementHeader.Validate("Location Code", Location.Code);

        // [THEN] Error 'You cannot change Location Code because one or more lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, InternalMovementHeader.FieldCaption("Location Code")));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateLocationCodeIntMovementWithoutLines()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        Location: Record Location;
    begin
        // [FEATURE] [UT] [Internal Movement]
        // [SCENARIO 311310] Location Code can be changed in Internal Movement Header when Lines do not present.
        Initialize;

        // [GIVEN] Internal Movement Header with Location 'BLUE'
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        CreateLocationWithBinMandatory(Location, true);

        // [WHEN] Validate Location Code = 'SILVER' in Internal Movement Header
        InternalMovementHeader.Validate("Location Code", Location.Code);

        // [THEN] Internal Movement Header has Location Code 'SILVER'
        InternalMovementHeader.TestField("Location Code", Location.Code);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Movement");

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        IsInitialized := true;
    end;

    local procedure InitQtys(var MinQty: Integer; var Qty: array[4] of Integer; Qty1: Integer; Qty2: Integer; Qty3: Integer; Qty4: Integer)
    var
        Index: Integer;
    begin
        Qty[1] := Qty1;
        Qty[2] := Qty2;
        Qty[3] := Qty3;
        Qty[4] := Qty4;
        MinQty := 0;
        for Index := 1 to ArrayLen(Qty) do
            MinQty += Qty[Index];
        MinQty := MinQty / 2;
    end;

    local procedure PrepareItemTrackingLinesPurchase(var PurchaseHeader: Record "Purchase Header"; LotNo: array[4] of Code[50]; ExpirationDate: array[4] of Date; Qty: array[4] of Integer)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Index: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;

        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(Qty[Index]);
        end;
        PurchaseLine.OpenItemTrackingLines;
        LibraryVariableStorage.AssertEmpty;

        for Index := 1 to ArrayLen(LotNo) do begin
            ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
            ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
            ReservationEntry.SetRange("Item No.", PurchaseLine."No.");
            ReservationEntry.SetRange("Lot No.", LotNo[Index]);
            ReservationEntry.FindFirst;
            ReservationEntry."Expiration Date" := ExpirationDate[Index];
            ReservationEntry.Modify();
        end;
    end;

    local procedure PrepareItemTrackingLineSales(var SalesHeader: Record "Sales Header"; LotNo: Code[50]; Qty: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines;
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure CreateItemWithItemTrackingCode(LotTracking: Boolean; LotWhseTracking: Boolean; ExpirationDateRequired: Boolean): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", LotTracking);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWhseTracking);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ExpirationDateRequired);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateFullWMSLocation(Bins: Integer; PickAccordingToFEFO: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, Bins);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        Location.Validate("Pick According to FEFO", PickAccordingToFEFO);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithBinMandatory(var Location: Record Location; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, false, false, false, false);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreatePurchaseOrderWithLocationAndItem(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesOrderWithLocationAndItem(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateMovementFromMovementWorksheet()
    var
        DummyWhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetWhseWkshLine(DummyWhseWorksheetLine);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run;
    end;

    local procedure PostWhseReceipt(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type", PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterPick(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesHeader."Document Type", SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CalculateBinReplenishment(BinContent: Record "Bin Content"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, LocationCode, true, true, false);
    end;

    local procedure SetBinRanking(var Bin: Record Bin; BinRanking: Integer)
    begin
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure UpdateBinContentQty(var BinContent: Record "Bin Content"; Qty: Decimal)
    begin
        BinContent.Validate(Quantity, Qty);
        BinContent.Validate("Quantity (Base)", Qty);
        BinContent.Modify(true);
    end;

    local procedure UpdateBinContentForReplenishment(var BinContent: Record "Bin Content"; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer; BinTypeCode: Code[10])
    begin
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Validate("Bin Type Code", BinTypeCode);
        BinContent.Modify(true);
    end;

    local procedure FilterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Integer)
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
    end;

    local procedure FindPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst;
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype",
          PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.");
    end;

    local procedure FindMovement(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindBinType(IsPick: Boolean; IsPutAway: Boolean; IsShip: Boolean; IsReceive: Boolean): Code[10]
    var
        BinType: Record "Bin Type";
    begin
        BinType.SetRange(Pick, IsPick);
        BinType.SetRange("Put Away", IsPutAway);
        BinType.SetRange(Ship, IsShip);
        BinType.SetRange(Receive, IsReceive);
        BinType.FindFirst;
        exit(BinType.Code);
    end;

    local procedure FindZone(LocationCode: Code[10]; BinTypeCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        LibraryWarehouse.FindZone(Zone, LocationCode, BinTypeCode, false);
        exit(Zone.Code);
    end;

    local procedure GetItemBaseUoM(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandlerMultipleEntries(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Index: Integer;
    begin
        ItemTrackingLines.First;
        for Index := 1 to LibraryVariableStorage.DequeueInteger do begin
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
            ItemTrackingLines.Next;
        end;
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandlerMultipleEntries(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
    begin
        WhseItemTrackingLines.First;
        for Index := 1 to LibraryVariableStorage.DequeueInteger do begin
            WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal);
            WhseItemTrackingLines.Next;
        end;
        WhseItemTrackingLines.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

