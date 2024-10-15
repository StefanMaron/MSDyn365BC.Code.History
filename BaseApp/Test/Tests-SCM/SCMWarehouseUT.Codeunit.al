codeunit 137831 "SCM - Warehouse UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        NothingToHandleErr: Label 'Nothing to handle.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TransferRouteErr: Label 'You must specify a Transfer Route';
        LibraryRandom: Codeunit "Library - Random";
        CannotDeleteLocSKUExistErr: Label 'You cannot delete %1 because one or more stockkeeping units exist at this location.', Comment = '%1: Field(Code)';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestNoPickCreatedWithSalesLotNotAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 10 of Lot1, Sell 2 (2 of Lot2)
        CreateInventoryForLot(BinContent, Lot1Code, 10, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 2);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot2Code, 2);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : No pick is made
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        Assert.IsTrue(WhseActivityLine.IsEmpty, 'No inventory pick to be made.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestFullPickCreatedWithSalesLotParialAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 5 (2 of Lot)
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 5);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 2);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Full pick is made but 1 line with qty 2 and lot 1 and another without lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '3 PCS of unspecified lot was asked for.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotNotAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot1, Sell 7 (3 of Lot2)
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot2Code, 3);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '3 PCS of specified lot was asked for but not available.');
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of available inventory lot was not asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(4, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotPartialAvailableOtherLotPartialAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 1 of Lot1 & 3 of Lot2, Sell 7 (3 of Lot1)
        CreateInventoryForLot(BinContent, Lot1Code, 1, 0D);
        CreateInventoryForLot(BinContent, Lot2Code, 3, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 3);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(1, WhseActivityLine.Quantity, '3 PCS of specified lot was asked for but 1 available.');
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of available inventory lot was not asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for but 3 available');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotAvailablePartialReservedOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 4 of Lot, Sell 5 of Lot - 3 reserved against purchase)
        CreateInventoryForLot(BinContent, Lot1Code, 4, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 5);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 3, Lot1Code);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of unspecified lot was asked for, but 2 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotPartialAvailablePartialReservedOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 9 (5 of Lot - 3 reserved against purchase))
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 3, Lot1Code);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 3 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotPartialAvailablePartialReservedTwiceOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 9 (5 of Lot - 4 reserved against 2 purchases))
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 1, Lot1Code);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 2, Lot1Code);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 {5 - (1 + 2)} PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 3 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTestPartialPickCreatedWithSalesLotsPartialAvailablePartialReservedTwiceOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotBW(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory (2 of Lot1, 3 of Lot2), Sell 9 (2 of Lot1 with 1 reserved, 3 of Lot2 with 1 reserved)
        CreateInventoryForLot(BinContent, Lot1Code, 2, 0D);
        CreateInventoryForLot(BinContent, Lot2Code, 3, 0D);
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot1Code, 2);
        CreateSalesItemTracking(WarehouseRequest."Source No.", Lot2Code, 3);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 1, Lot2Code);
        CreateSalesReservationAgainstPurchase(WarehouseRequest."Source No.", 1, Lot1Code);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(1, WhseActivityLine.Quantity, '1 {2 - 1} PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 {3 - 1} PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 2 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestNoPickCreatedWithSalesLotNotAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 27137
        // SETUP : Create items, inventory, sales shipment
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 10 of Lot1, Sell 2 (2 of Lot2)
        CreateInventoryForLot(BinContent, Lot1Code, 10, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 2);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot2Code, 2);

        // EXERCISE : Create the pick
        asserterror CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Nothing to handle error
        Assert.ExpectedError(NothingToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestFullPickCreatedWithSalesLotParialAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 5 (2 of Lot)
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 5);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 2);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Full pick is made but 1 line with qty 2 and lot 1 and another without lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '3 PCS of unspecified lot was asked for.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotNotAvailableOtherLotAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot1, Sell 7 (3 of Lot2)
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot2Code, 3);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '3 PCS of specified lot was asked for but not available.');
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of available inventory lot was not asked for.');
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(4, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotPartialAvailableOtherLotPartialAvailable()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory 1 of Lot1 & 3 of Lot2, Sell 7 (3 of Lot1)
        CreateInventoryForLot(BinContent, Lot1Code, 1, 0D);
        CreateInventoryForLot(BinContent, Lot2Code, 3, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 3);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(1, WhseActivityLine.Quantity, '3 PCS of specified lot was asked for but 1 available.');
        WhseActivityLine.SetRange("Action Type");
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of available inventory lot was not asked for.');
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for but 3 available');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotAvailablePartialReservedOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 4 of Lot, Sell 5 of Lot - 3 reserved against purchase)
        CreateInventoryForLot(BinContent, Lot1Code, 4, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 5);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 3, Lot1Code);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, '0 PCS of unspecified lot was asked for, but 2 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotPartialAvailablePartialReservedOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 9 (5 of Lot - 4 reserved against 2 purchases))
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 3, Lot1Code);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 3 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotPartialAvailablePartialReservedTwiceOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();

        // Inventory 5 of Lot, Sell 9 (5 of Lot - 3 reserved against purchase))
        CreateInventoryForLot(BinContent, Lot1Code, 5, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 5);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 2, Lot1Code);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 1, Lot1Code);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS {5 - (2 + 1)} of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 3 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTestPartialPickCreatedWithSalesLotsPartialAvailablePartialReservedTwiceOnInventory()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Lot1Code: Code[10];
        Lot2Code: Code[10];
    begin
        // Refer to VSTF SICILY 6788
        // SETUP : Create items, inventory and sales order
        CreateSetupForLotWMS(BinContent);

        Lot1Code := LibraryUtility.GenerateGUID();
        Lot2Code := LibraryUtility.GenerateGUID();

        // Inventory (2 of Lot1, 3 of Lot2), Sell 9 (2 of Lot1 with 1 reserved, 3 of Lot2 with 1 reserved))
        CreateInventoryForLot(BinContent, Lot1Code, 2, 0D);
        CreateInventoryForLot(BinContent, Lot2Code, 3, 0D);
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 9);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot1Code, 2);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", Lot2Code, 3);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 1, Lot1Code);
        CreateSalesReservationAgainstPurchase(WarehouseShipmentLine."Source No.", 1, Lot2Code);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made only for unspecified lot
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", Lot1Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(1, WhseActivityLine.Quantity, '1 PCS {2 - 1} of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", Lot2Code);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '2 PCS {3 - 1} of specified lot was asked for.');
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2, WhseActivityLine.Quantity, '4 PCS of unspecified lot was asked for, but 2 available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWPickCreatedForLaterExpiryLotIfFirstExpiryLotIsReservedSecondSalesQtyLess()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        OlderLot: Code[10];
        NewerLot: Code[10];
    begin
        // Refer to VSTF SICILY 27491
        // SETUP : Create items, inventory and sales order
        CreateItemWithLotTracking(Item);
        CreateInventoryPickLocation(Location);
        Location."Pick According to FEFO" := true;
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");

        OlderLot := LibraryUtility.GenerateGUID();
        NewerLot := LibraryUtility.GenerateGUID();

        // Inventory (20 of older, 10 of newer)
        CreateInventoryForLot(BinContent, OlderLot, 7, CalcDate('<1M>', WorkDate()));
        CreateInventoryForLot(BinContent, NewerLot, 3, CalcDate('<2M>', WorkDate()));

        // Create sales of 20 for older lot. Reserve against it.
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseRequest."Source No.", OlderLot, 7);
        CreateSalesReservationAgainstILE(WarehouseRequest."Source No.", 7, OlderLot);

        // Create new sales for 10 PCS- no lot assigned.
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 3);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made for newer lot only
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Although no lot has been asked for, FEFO should assign lot.');
        WhseActivityLine.SetRange("Lot No.", OlderLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Older lot is already reserved. Should not make a pick.');
        WhseActivityLine.SetRange("Lot No.", NewerLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, 'FEFO should determine the newer lot for pick.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWPickCreatedForLaterExpiryLotIfFirstExpiryLotIsReservedSecondSalesQtyMore()
    var
        BinContent: Record "Bin Content";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        OlderLot: Code[10];
        NewerLot: Code[10];
    begin
        // Refer to VSTF SICILY 27491
        // SETUP : Create items, inventory and sales order
        CreateItemWithLotTracking(Item);
        CreateInventoryPickLocation(Location);
        Location."Pick According to FEFO" := true;
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");

        OlderLot := LibraryUtility.GenerateGUID();
        NewerLot := LibraryUtility.GenerateGUID();

        // Inventory (20 of older, 10 of newer)
        CreateInventoryForLot(BinContent, OlderLot, 7, CalcDate('<1M>', WorkDate()));
        CreateInventoryForLot(BinContent, NewerLot, 3, CalcDate('<2M>', WorkDate()));

        // Create sales of 20 for older lot. Reserve against it.
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 3);
        CreateSalesItemTracking(WarehouseRequest."Source No.", OlderLot, 3);
        CreateSalesReservationAgainstILE(WarehouseRequest."Source No.", 3, OlderLot);

        // Create new sales for 10 PCS- no lot assigned.
        CreateSales(WarehouseRequest, BinContent."Item No.", BinContent."Location Code", 7);

        // EXERCISE : Create the pick
        CreateInventoryPickFromWarehouseRequest(WarehouseRequest);

        // VERIFY : Pick is made for newer lot only
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Although no lot has been asked for, FEFO should assign lot.');
        WhseActivityLine.SetRange("Lot No.", OlderLot);
        WhseActivityLine.CalcSums(Quantity);
        asserterror Assert.AreEqual(4, WhseActivityLine.Quantity, 'Older lot of 7 has 3 reserved. Rest should appear as per FEFO.');
        Assert.ExpectedError('Assert.AreEqual'); // Due to Sicily 27491.
        WhseActivityLine.SetRange("Lot No.", NewerLot);
        WhseActivityLine.CalcSums(Quantity);
        asserterror Assert.AreEqual(3, WhseActivityLine.Quantity, 'FEFO should determine the newer lot for pick.');
        Assert.ExpectedError('Assert.AreEqual'); // Due to Sicily 27491.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSPickCreatedForLaterExpiryLotIfFirstExpiryLotIsReservedSecondSalesQtyLess()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        OlderLot: Code[10];
        NewerLot: Code[10];
    begin
        // Refer to VSTF SICILY 27491
        // SETUP : Create items, inventory and sales order
        CreateItemWithLotTracking(Item);
        CreateWarehousePickLocation(Location);
        Location."Pick According to FEFO" := true;
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");

        OlderLot := LibraryUtility.GenerateGUID();
        NewerLot := LibraryUtility.GenerateGUID();

        // Inventory (20 of older, 10 of newer)
        CreateInventoryForLot(BinContent, OlderLot, 7, CalcDate('<1M>', WorkDate()));
        CreateInventoryForLot(BinContent, NewerLot, 3, CalcDate('<2M>', WorkDate()));

        // Create sales of 20 for older lot. Reserve against it.
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 7);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", OlderLot, 7);
        CreateSalesReservationAgainstILE(WarehouseShipmentLine."Source No.", 7, OlderLot);

        // Create new sales for 10 PCS- no lot assigned.
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 3);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made for newer lot only
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Although no lot has been asked for, FEFO should assign lot.');
        WhseActivityLine.SetRange("Lot No.", OlderLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Older lot is already reserved. Should not make a pick.');
        WhseActivityLine.SetRange("Lot No.", NewerLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, 'FEFO should determine the newer lot for pick.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSPickCreatedForLaterExpiryLotIfFirstExpiryLotIsReservedSecondSalesQtyMore()
    var
        BinContent: Record "Bin Content";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        OlderLot: Code[10];
        NewerLot: Code[10];
    begin
        // Refer to VSTF SICILY 27491
        // SETUP : Create items, inventory and sales order
        CreateItemWithLotTracking(Item);
        CreateWarehousePickLocation(Location);
        Location."Pick According to FEFO" := true;
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");

        OlderLot := LibraryUtility.GenerateGUID();
        NewerLot := LibraryUtility.GenerateGUID();

        // Inventory (20 of older, 10 of newer)
        CreateInventoryForLot(BinContent, OlderLot, 7, CalcDate('<1M>', WorkDate()));
        CreateInventoryForLot(BinContent, NewerLot, 3, CalcDate('<2M>', WorkDate()));

        // Create sales of 20 for older lot. Reserve against it.
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 3);
        CreateSalesItemTracking(WarehouseShipmentLine."Source No.", OlderLot, 3);
        CreateSalesReservationAgainstILE(WarehouseShipmentLine."Source No.", 3, OlderLot);

        // Create new sales for 10 PCS- no lot assigned.
        CreateSalesShipment(WarehouseShipmentLine, BinContent."Item No.", BinContent."Location Code", 7);

        // EXERCISE : Create the pick
        CreateWarehousePickFromShipment(WarehouseShipmentLine);

        // VERIFY : Pick is made for newer lot only
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivityLine.SetRange("Lot No.", '');
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(0, WhseActivityLine.Quantity, 'Although no lot has been asked for, FEFO should assign lot.');
        WhseActivityLine.SetRange("Lot No.", OlderLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(4, WhseActivityLine.Quantity, 'Older lot of 7 has 3 reserved. Rest should appear as per FEFO.');
        WhseActivityLine.SetRange("Lot No.", NewerLot);
        WhseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3, WhseActivityLine.Quantity, 'FEFO should determine the newer lot for pick.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSKULocationWithTransferError()
    var
        Location1: Record Location;
        Location2: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferRoute: Record "Transfer Route";
        Item: Record Item;
    begin
        // [FEATURE] [Stockkeeping Unit] [Transfer Replenishment]
        // [SCENARIO 127315] Verify error message appears when validating "Location Code" to value from "Transfer-from Code".

        // [GIVEN] Stockkeeping Units with "Location Code" = "X" and "Transfer-from Code" = "Y".
        LibraryWarehouse.CreateLocation(Location1);
        LibraryWarehouse.CreateLocation(Location2);

        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        LibraryWarehouse.CreateTransferRoute(TransferRoute, Location2.Code, Location1.Code);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location1.Code, Item."No.", '');
        StockkeepingUnit.Validate("Transfer-from Code", Location2.Code);
        StockkeepingUnit.Modify(true);

        // [WHEN] Validate "Location Code" with "Y"
        asserterror StockkeepingUnit.Validate("Location Code", Location2.Code);

        // [THEN] Error message appears.
        Assert.ExpectedError(TransferRouteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerUOMIsCopiedToReversedWhseEntryFromOriginalEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseUndoQuantity: Codeunit "Whse. Undo Quantity";
        LocationCode: Code[10];
        BinCode: Code[20];
        NextLineNo: Integer;
    begin
        // [FEATURE] [Warehouse Entry] [UT]
        // [SCENARIO 381994] Function InsertTempWhseJnlLine in codeunit 7320 creates reversed Warehouse Journal Line to Warehouse Entry keeping absolute values of its quantity and base quantity.

        // [GIVEN] WMS Location set up for directed put-away and pick.
        // [GIVEN] Warehouse Entry "WE" with Quantity "Q", Quantity (base) "QB" and Qty. per Unit of Measure "QUOM".
        MockWMSLocation(LocationCode, BinCode);
        MockWhseEntry(WarehouseEntry, LocationCode, BinCode);
        MockItemJnlLine(ItemJournalLine, LocationCode, BinCode);

        // [WHEN] Call InsertTempWhseJnlLine function in codeunit 7320.
        WhseUndoQuantity.InsertTempWhseJnlLine(
          ItemJournalLine, WarehouseEntry."Source Type", WarehouseEntry."Source Subtype",
          WarehouseEntry."Source No.", WarehouseEntry."Source Line No.", 0, WarehouseJournalLine, NextLineNo);

        // [THEN] New warehouse journal line has "Qty. per Unit of Measure" = "QUOM".
        // [THEN] Quantity = -"Q".
        // [THEN] Quantity (Base) = -"QB".
        WarehouseJournalLine.TestField("Qty. per Unit of Measure", WarehouseEntry."Qty. per Unit of Measure");
        WarehouseJournalLine.TestField(Quantity, -WarehouseEntry.Quantity);
        WarehouseJournalLine.TestField("Qty. (Base)", -WarehouseEntry."Qty. (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCannotBeDeletedIfSKUExists()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Stockkeeping Unit] [Location] [UT]
        // [SCENARIO 215496] Location cannot be deleted if a stockkeeping unit exists on it.

        // [GIVEN] Location "L" and stockkeeping unit on it.
        MockLocation(Location);
        MockSKU(Location.Code);

        // [WHEN] Delete "L".
        asserterror Location.Delete(true);

        // [THEN] Error is thrown.
        Assert.ExpectedError(StrSubstNo(CannotDeleteLocSKUExistErr, Location.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentDeletedOnEraseBinCodeOnPutAwayLineWithActionTypePlace()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        // [FEATURE] [Put-away] [Bin Content] [UT]
        // [SCENARIO 229915] When you erase "Bin Code" on a put-away line, empty Bin Content for this bin is deleted.

        // [GIVEN] Location with directed put-away and pick.
        MockWMSLocation(LocationCode, BinCode);

        // [GIVEN] Empty bin content "BC" for bin "B" at the location.
        CreateBinContent(BinContent, LocationCode, BinCode, LibraryInventory.CreateItemNo());

        with WarehouseActivityLine do begin
            // [GIVEN] Put-away line with "Bin Code" = "B".
            MockWhseActivityLine(
              WarehouseActivityLine, "Activity Type"::"Put-away", "Action Type"::Place, LocationCode, BinCode, BinContent."Item No.");

            // [WHEN] Clear "Bin Code" on the put-away line.
            Validate("Bin Code", '');

            // [THEN] Bin Content "BC" is deleted.
            BinContent.SetRange("Item No.", "Item No.");
            Assert.RecordIsEmpty(BinContent);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentWithMinQtySettingIsNotDeleted()
    var
        BinContent: Record "Bin Content";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        // [FEATURE] [Bin Content] [UT]
        // [SCENARIO 235027] Empty Bin Content with defined "Min. Qty." setting is not deleted with "DeleteBinContent" function in Warehouse Activity Line.

        MockWMSLocation(LocationCode, BinCode);

        CreateBinContent(BinContent, LocationCode, BinCode, LibraryInventory.CreateItemNo());
        BinContent."Min. Qty." := LibraryRandom.RandInt(10);
        BinContent.Modify();

        with WarehouseActivityLine do begin
            MockWhseActivityLine(
              WarehouseActivityLine, "Activity Type"::"Put-away", "Action Type"::Place, LocationCode, BinCode, BinContent."Item No.");
            DeleteBinContent("Action Type"::Place.AsInteger());
        end;

        BinContent.SetRecFilter();
        Assert.RecordIsNotEmpty(BinContent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentWithMaxQtySettingIsNotDeleted()
    var
        BinContent: Record "Bin Content";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        // [FEATURE] [Bin Content] [UT]
        // [SCENARIO 235027] Empty Bin Content with defined "Max. Qty." setting is not deleted with "DeleteBinContent" function in Warehouse Activity Line.

        MockWMSLocation(LocationCode, BinCode);

        CreateBinContent(BinContent, LocationCode, BinCode, LibraryInventory.CreateItemNo());
        BinContent."Max. Qty." := LibraryRandom.RandInt(10);
        BinContent.Modify();

        with WarehouseActivityLine do begin
            MockWhseActivityLine(
              WarehouseActivityLine, "Activity Type"::"Put-away", "Action Type"::Place, LocationCode, BinCode, BinContent."Item No.");
            DeleteBinContent("Action Type"::Place.AsInteger());
        end;

        BinContent.SetRecFilter();
        Assert.RecordIsNotEmpty(BinContent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyBaseIsUpdatedBeforeOutstandingQtyOnWhseReceiptLine()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Warehouse Receipt] [UT]
        // [SCENARIO 252129] When you validate Quantity on warehouse receipt line, the program calculates "Qty. (Base)" before it does "Qty. Outstanding (Base)".

        with WarehouseReceiptLine do begin
            Init();
            "Qty. per Unit of Measure" := LibraryRandom.RandIntInRange(2, 5);
            Quantity := LibraryRandom.RandInt(10);
            "Qty. (Base)" := Quantity * "Qty. per Unit of Measure";
            "Qty. Outstanding" := Quantity;
            "Qty. Outstanding (Base)" := "Qty. (Base)";

            Validate(Quantity, Quantity * 2);

            TestField("Qty. (Base)", "Qty. Outstanding (Base)");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyBaseIsUpdatedBeforeOutstandingQtyOnWhseShipmentLine()
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Warehouse Shipment] [UT]
        // [SCENARIO 252129] When you validate Quantity on warehouse shipment line, the program calculates "Qty. (Base)" before it does "Qty. Outstanding (Base)".

        MockSalesLine(SalesLine);

        MockWhseShipmentHeader(WarehouseShipmentHeader);

        with WarehouseShipmentLine do begin
            Init();
            "No." := WarehouseShipmentHeader."No.";
            "Source Type" := DATABASE::"Sales Line";
            "Source Subtype" := SalesLine."Document Type".AsInteger();
            "Source No." := SalesLine."Document No.";
            "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
            Quantity := SalesLine."Outstanding Quantity";
            "Qty. (Base)" := Quantity * "Qty. per Unit of Measure";
            "Qty. Outstanding" := Quantity;
            "Qty. Outstanding (Base)" := "Qty. (Base)";

            Validate(Quantity, Quantity * 2);

            TestField("Qty. (Base)", "Qty. Outstanding (Base)");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlLineFromTransLineNotReservedWhenNoReservEntriesExistForTransLine()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEntry: Record "Warehouse Entry";
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Reservation] [UT]
        // [SCENARIO 253142] Item journal line generated to post whse. shipment from transfer is not reserved if no reservation entries exist for transfer line.

        MockItem(Item);
        MockTransferLine(TransferLine, Item."No.", LibraryRandom.RandIntInRange(51, 100));
        MockItemJournalLine(
          ItemJournalLine,
          ItemJournalLine."Entry Type"::Transfer, TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockWarehouseShipment(
          WarehouseShipmentHeader,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockWarehouseEntry(
          WarehouseEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", WarehouseEntry."Whse. Document Type"::Shipment,
          WarehouseShipmentHeader."No.", WarehouseShipmentHeader."Bin Code", LibraryRandom.RandInt(50));

        TransferLineReserve.TransferWhseShipmentToItemJnlLine(
          TransferLine, ItemJournalLine, WarehouseShipmentHeader, LibraryRandom.RandInt(10));

        with ReservationEntry do begin
            Init();
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Item No.", Item."No.");
            Assert.RecordIsEmpty(ReservationEntry);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlLineFromTransLineMustHaveSameLocationItemAndVariantCode()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Reservation] [UT]
        // [SCENARIO 253142] Item journal line generated to post whse. shipment from transfer must have the same item, location and variant code as the transfer line.

        Qty := LibraryRandom.RandInt(10);

        MockItem(Item);
        MockTransferLine(TransferLine, Item."No.", LibraryRandom.RandIntInRange(51, 100));
        MockItemJournalLine(
          ItemJournalLine,
          ItemJournalLine."Entry Type"::Transfer, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          LibraryUtility.GenerateGUID(), TransferLine.Quantity);
        MockReservationEntry(
          ReservationEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", -Qty);

        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Location Code');

        ItemJournalLine."Location Code" := TransferLine."Transfer-from Code";
        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Item No.');

        ItemJournalLine."Item No." := TransferLine."Item No.";
        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Variant Code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservEntryRelatedToTransLineMustHaveSameLocationItemAndVariantCode()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Reservation] [UT]
        // [SCENARIO 253142] Reservation entries on transfer line must have the same item, location and variant code as the transfer line.

        Qty := LibraryRandom.RandInt(10);

        MockItem(Item);
        MockTransferLine(TransferLine, Item."No.", LibraryRandom.RandIntInRange(51, 100));
        MockItemJournalLine(
          ItemJournalLine,
          ItemJournalLine."Entry Type"::Transfer, TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockReservationEntry(
          ReservationEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          LibraryUtility.GenerateGUID(), -Qty);
        MockWarehouseShipment(
          WarehouseShipmentHeader,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);

        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Item No.');

        ReservationEntry."Item No." := TransferLine."Item No.";
        ReservationEntry.Modify();
        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Variant Code');

        ReservationEntry."Variant Code" := TransferLine."Variant Code";
        ReservationEntry.Modify();
        Commit();
        asserterror TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);
        Assert.ExpectedError('Location Code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlLineFromTransLineNotReservedWhenItemNotPicked()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Reservation] [UT]
        // [SCENARIO 253142] Item journal line generated to post whse. shipment from transfer is not reserved if the quantity has not been picked.

        Qty := LibraryRandom.RandInt(10);

        MockItem(Item);
        MockTransferLine(TransferLine, Item."No.", LibraryRandom.RandIntInRange(51, 100));
        MockItemJournalLine(
          ItemJournalLine,
          ItemJournalLine."Entry Type"::Transfer, TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockReservationEntry(
          ReservationEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", -Qty);
        MockWarehouseShipment(
          WarehouseShipmentHeader,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);

        TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, Qty);

        Clear(ReservationEntry);
        with ReservationEntry do begin
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Item No.", Item."No.");
            Assert.RecordIsEmpty(ReservationEntry);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQtyOnItemJnlLineFromTransLineDoesNotExceedQtyToHandleOnItemTracking()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEntry: Record "Warehouse Entry";
        ReservationEntry: Record "Reservation Entry";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        Qty: Decimal;
        BinCode: Code[20];
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Reservation] [UT]
        // [SCENARIO 253142] Reserved quantity on item journal line generated to post whse. shipment from transfer does not exceed quantity to handle defined on item tracking.
        // [SCENARIO 349173] Bin code on item journal line generated to post whse. shipment from transfer is taken from Whse. Shipment Line

        Qty := LibraryRandom.RandInt(10);

        MockItem(Item);
        MockTransferLine(TransferLine, Item."No.", LibraryRandom.RandIntInRange(51, 100));
        MockItemJournalLine(
          ItemJournalLine,
          ItemJournalLine."Entry Type"::Transfer, TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockReservationEntry(
          ReservationEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", -Qty);
        BinCode := MockWarehouseShipment(
          WarehouseShipmentHeader,
          DATABASE::"Transfer Line", TransferLine."Document No.", TransferLine."Item No.", TransferLine."Variant Code",
          TransferLine."Transfer-from Code", TransferLine.Quantity);
        MockWarehouseEntry(
          WarehouseEntry,
          DATABASE::"Transfer Line", TransferLine."Document No.", WarehouseEntry."Whse. Document Type"::Shipment,
          WarehouseShipmentHeader."No.", BinCode, LibraryRandom.RandInt(50));

        TransferLineReserve.TransferWhseShipmentToItemJnlLine(TransferLine, ItemJournalLine, WarehouseShipmentHeader, 2 * Qty);

        Clear(ReservationEntry);
        with ReservationEntry do begin
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Item No.", Item."No.");
            FindFirst();
            TestField("Quantity (Base)", -Qty);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentsPageOpensFilteredByLocationSetUpForEmployee()
    var
        Location: array[2] of Record Location;
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        WarehouseEmployee: Record "Warehouse Employee";
        BinContents: TestPage "Bin Contents";
    begin
        // [FEATURE] [Bin Content] [Warehouse Employee] [UI]
        // [SCENARIO 295019] Bin Contents page shows bins only on locations a warehouse employee has an access to.

        // [GIVEN] Location "L1" with bin "B1".
        LibraryWarehouse.CreateLocationWMS(Location[1], true, false, false, false, false);
        CreateBin(Bin[1], Location[1].Code);
        CreateBinContent(BinContent, Location[1].Code, Bin[1].Code, LibraryInventory.CreateItemNo());

        // [GIVEN] Location "L2" with bin "B2".
        // [GIVEN] A user has been set as a warehouse employee only on location "L2".
        LibraryWarehouse.CreateLocationWMS(Location[2], true, false, false, false, false);
        CreateBin(Bin[2], Location[2].Code);
        CreateBinContent(BinContent, Location[2].Code, Bin[2].Code, LibraryInventory.CreateItemNo());
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, false);

        // [WHEN] Open Bin Contents page.
        BinContents.OpenView();

        // [THEN] Bin "B1" is not found on the page.
        BinContents.FILTER.SetFilter("Bin Code", Bin[1].Code);
        Assert.IsFalse(BinContents.First(), '');

        // [THEN] Bin "B2" is shown on the page.
        BinContents.FILTER.SetFilter("Bin Code", Bin[2].Code);
        Assert.IsTrue(BinContents.First(), '');

        BinContents.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSerialNoWhseActivityLineWhenTwoSimilarLinesHaveDifferentVariants()
    var
        WarehouseActivityLine1: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Variant]
        // [SCENARIO 307728] No error on validate "Serial No." in Warehouse Activity Line when other similar line with other Variant Code presents
        // [GIVEN] Warehouse Activity Line 1 had Variant Code = "V1" and Serial No = "S1"
        WarehouseActivityLine1.Init();
        WarehouseActivityLine1."Activity Type" := WarehouseActivityLine1."Activity Type"::Pick;
        WarehouseActivityLine1."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine1."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine1, WarehouseActivityLine1.FieldNo("Line No."));
        WarehouseActivityLine1."Item No." := CreateItemWithSNWhseTracking();
        WarehouseActivityLine1."Serial No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine1."Variant Code" := LibraryUtility.GenerateGUID();
        WarehouseActivityLine1."Qty. (Base)" := 1;
        WarehouseActivityLine1.Insert();

        // [GIVEN] Warehouse Activity Line 2 copied from Line 1 had Variant Code = "V2"
        WarehouseActivityLine2 := WarehouseActivityLine1;
        with WarehouseActivityLine2 do begin
            "Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine2, FieldNo("Line No."));
            "Variant Code" := LibraryUtility.GenerateGUID();
            Insert();
        end;

        // [WHEN] Validate "Serial No." = "S1" in Warehouse Activity Line 2
        WarehouseActivityLine2.Validate("Serial No.", WarehouseActivityLine1."Serial No.");

        // [THEN] Warehouse Activity Line 2 has "Serial No." = "S1"
        WarehouseActivityLine2.TestField("Serial No.", WarehouseActivityLine1."Serial No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentsLocationFilterFromSelectionFilter()
    var
        Location: array[10] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        BinContents: TestPage "Bin Contents";
        Index: Integer;
        FilterValue: Text[250];
        LocationRange: Text[40];
        LocationSelection: Text[30];
        ExpectedLocationFilter: Text[250];
    begin
        // [FEATURE] [Bin Content] [Warehouse Employee] [UI]
        // [SCENARIO 363777] Bin Contents page shows Locations filter created using SelectionFilterManagement codeunit.
        WarehouseEmployee.DeleteAll();

        // [GIVEN] 10 Locations "L001..L010" where "L001..L003" and "L007" and "L009" are assigned to a WarehouseEmployee
        for Index := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocationWMS(Location[Index], true, false, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[3].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[7].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[9].Code, false);

        // [WHEN] Open Bin Contents page.
        BinContents.OpenView();

        // [THEN] "Location Code" filter contains "L001..L003" range together with "L007|L009" selections
        FilterValue := CopyStr(BinContents.FILTER.GetFilter("Location Code"), 1, MaxStrLen(FilterValue));
        LocationRange := StrSubstNo('%1..%2', Location[1].Code, Location[3].Code);
        LocationSelection := StrSubstNo('%1|%2', Location[7].Code, Location[9].Code);
        ExpectedLocationFilter := StrSubstNo('%1|%2', LocationRange, LocationSelection);
        Assert.IsTrue(StrPos(FilterValue, LocationRange) > 0, 'Expected range of Locations in the filter');
        Assert.IsTrue(StrPos(FilterValue, LocationSelection) > 0, 'Expected selections of Locations in the filter');
        Assert.AreEqual(ExpectedLocationFilter, FilterValue, 'Expected filter string to contain range and selection');

        BinContents.Close();
    end;

    [Test]
    procedure CannotCreateBinWithBlankCode()
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 414436] Cannot create bin code with blank code.
        Initialize();

        MockLocation(Location);
        Bin.Init();
        Bin."Location Code" := Location.Code;
        Bin.Code := '';
        asserterror Bin.Insert(true);
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure CannotPostPurchaseOrderWithBlankBinWhenBinMandatory()
    var
        Location: Record Location;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Bin] [Purchase Order]
        // [SCENARIO 414436] Cannot post purchase order with blank bin code on location with mandatory bin.
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        Bin.Init();
        Bin."Location Code" := Location.Code;
        Bin.Code := '';
        Bin.Insert();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), Location.Code, WorkDate());

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure CannotPostSalesOrderWithBlankBinWhenBinMandatory()
    var
        Location: Record Location;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Bin] [Sales Order]
        // [SCENARIO 414436] Cannot post sales order with blank bin code on location with mandatory bin.
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        Bin.Init();
        Bin."Location Code" := Location.Code;
        Bin.Code := '';
        Bin.Insert();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), Location.Code, WorkDate());

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure CannotChangeItemTypeWhenWhseEntryExistsForItem()
    var
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 427208] Cannot change item type when warehouse entries exist for the item.
        Initialize();

        MockItem(Item);

        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry.Insert();

        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");

        Assert.ExpectedError(StrSubstNo(WhseEntriesExistErr, Item.FieldCaption(Type)));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM - Warehouse UT");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM - Warehouse UT");

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM - Warehouse UT");
    end;

    [Test]
    procedure BinCodeEditableOnPlaceLineForProdConsumption()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePick: TestPage "Warehouse Pick";
    begin
        // [FEATURE] [Consumption] [UI]
        // [SCENARIO 437738] Bin Code is editable on warehouse pick line for placing production component.

        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        MockWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);

        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Line No."));
        WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Prod. Consumption";
        WarehouseActivityLine."Location Code" := Location.Code;
        WarehouseActivityLine."Action Type" := WarehouseActivityLine."Action Type"::Place;
        WarehouseActivityLine."Whse. Document Type" := WarehouseActivityLine."Whse. Document Type"::Production;
        WarehouseActivityLine.Insert();

        WarehousePick.OpenEdit();
        WarehousePick.FILTER.SetFilter("No.", WarehouseActivityHeader."No.");
        Assert.IsTrue(WarehousePick.WhseActivityLines."Bin Code".Editable(), '');
    end;

    [Test]
    procedure BinCodeEditableOnPlaceLineForAssemblyConsumption()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePick: TestPage "Warehouse Pick";
    begin
        // [FEATURE] [Consumption] [UI]
        // [SCENARIO 437738] Bin Code is editable on warehouse pick line for placing assembly component.

        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        MockWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);

        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Line No."));
        WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Assembly Consumption";
        WarehouseActivityLine."Location Code" := Location.Code;
        WarehouseActivityLine."Action Type" := WarehouseActivityLine."Action Type"::Place;
        WarehouseActivityLine."Whse. Document Type" := WarehouseActivityLine."Whse. Document Type"::Assembly;
        WarehouseActivityLine.Insert();

        WarehousePick.OpenEdit();
        WarehousePick.FILTER.SetFilter("No.", WarehouseActivityHeader."No.");
        Assert.IsTrue(WarehousePick.WhseActivityLines."Bin Code".Editable(), '');
    end;

    [Test]
    procedure BinCodeEditableOnPlaceLineForJobUsage()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePick: TestPage "Warehouse Pick";
    begin
        // [FEATURE] [Consumption] [UI]
        // [SCENARIO 437738] Bin Code is editable on warehouse pick line for placing assembly component.

        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        MockWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);

        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Line No."));
        WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Job Usage";
        WarehouseActivityLine."Location Code" := Location.Code;
        WarehouseActivityLine."Action Type" := WarehouseActivityLine."Action Type"::Place;
        WarehouseActivityLine."Whse. Document Type" := WarehouseActivityLine."Whse. Document Type"::Job;
        WarehouseActivityLine.Insert();

        WarehousePick.OpenEdit();
        WarehousePick.FILTER.SetFilter("No.", WarehouseActivityHeader."No.");
        Assert.IsTrue(WarehousePick.WhseActivityLines."Bin Code".Editable(), '');
    end;

    local procedure CreateItemWithSNWhseTracking(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithLotTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := LibraryUtility.GenerateGUID();
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode.Insert();

        Clear(Item);
        Item."No." := LibraryUtility.GenerateGUID();
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Insert();
    end;

    local procedure CreateSetupForLotBW(var BinContent: Record "Bin Content")
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
    begin
        CreateItemWithLotTracking(Item);
        CreateInventoryPickLocation(Location);
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");
    end;

    local procedure CreateSetupForLotWMS(var BinContent: Record "Bin Content")
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
    begin
        CreateItemWithLotTracking(Item);
        CreateWarehousePickLocation(Location);
        Location.Insert();
        CreateBin(Bin, Location.Code);
        CreateBinContent(BinContent, Location.Code, Bin.Code, Item."No.");
    end;

    local procedure CreateBasicLocation(var Location: Record Location)
    begin
        Clear(Location);
        Location.Code := LibraryUtility.GenerateGUID();
        Location."Bin Mandatory" := true;
    end;

    local procedure CreateInventoryPickLocation(var Location: Record Location)
    begin
        CreateBasicLocation(Location);
        Location."Require Pick" := true;
    end;

    local procedure CreateWarehousePickLocation(var Location: Record Location)
    begin
        CreateBasicLocation(Location);
        Location."Require Shipment" := true;
        Location."Require Pick" := true;
    end;

    local procedure CreateBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Clear(Bin);
        Bin."Location Code" := LocationCode;
        Bin.Code := LibraryUtility.GenerateGUID();
        Bin.Insert();
    end;

    local procedure CreateZone(LocationCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        with Zone do begin
            Init();
            "Location Code" := LocationCode;
            Code := LibraryUtility.GenerateGUID();
            Insert();
            exit(Code);
        end;
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    begin
        Clear(BinContent);
        BinContent."Location Code" := LocationCode;
        BinContent."Bin Code" := BinCode;
        BinContent."Item No." := ItemNo;
        BinContent.Insert();
    end;

    local procedure CreateInventoryForLot(BinContent: Record "Bin Content"; LotNo: Code[10]; Quantity: Decimal; ExpirationDate: Date)
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntry2: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        WarehouseEntry2.FindLast();
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := WarehouseEntry2."Entry No." + 1;
        WarehouseEntry."Location Code" := BinContent."Location Code";
        WarehouseEntry."Bin Code" := BinContent."Bin Code";
        WarehouseEntry."Item No." := BinContent."Item No.";
        WarehouseEntry."Lot No." := LotNo;
        WarehouseEntry.Quantity := Quantity;
        WarehouseEntry."Qty. (Base)" := Quantity;
        WarehouseEntry."Expiration Date" := ExpirationDate;
        WarehouseEntry.Insert();

        ItemLedgerEntry2.FindLast();
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := ItemLedgerEntry2."Entry No." + 1;
        ItemLedgerEntry."Item No." := BinContent."Item No.";
        ItemLedgerEntry."Location Code" := BinContent."Location Code";
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry.Positive := ItemLedgerEntry.Quantity > 0;
        ItemLedgerEntry."Expiration Date" := ExpirationDate;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateItemTrackingEntry(var SalesLine: Record "Sales Line"; LotCode: Code[10]; LotQtyToShip: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
    begin
        if ReservationEntry2.FindLast() then;
        ReservationEntry.Init();
        ReservationEntry."Entry No." := ReservationEntry2."Entry No." + 1;
        ReservationEntry.Positive := false;
        ReservationEntry."Source Type" := DATABASE::"Sales Line";
        ReservationEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
        ReservationEntry."Source ID" := SalesLine."Document No.";
        ReservationEntry."Source Ref. No." := SalesLine."Line No.";
        ReservationEntry."Item No." := SalesLine."No.";
        ReservationEntry."Location Code" := SalesLine."Location Code";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        ReservationEntry."Lot No." := LotCode;
        ReservationEntry."Quantity (Base)" := -LotQtyToShip;
        ReservationEntry.Quantity := -LotQtyToShip;
        ReservationEntry."Qty. to Handle (Base)" := -LotQtyToShip;
        ReservationEntry."Shipment Date" := WorkDate();
        ReservationEntry.UpdateItemTracking();
        ReservationEntry.Insert();
    end;

    local procedure CreateReservationEntry(var SalesLine: Record "Sales Line"; LotCode: Code[10]; LotQtyToShip: Decimal; ResvAgainstSourceType: Integer; ResvAgainstSourceSubtype: Option; ResvAgainstSourceID: Code[20]; ResvAgainstSourceRefNo: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateItemTrackingEntry(SalesLine, LotCode, LotQtyToShip);
        ReservationEntry.FindLast();
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry."Expected Receipt Date" := ReservationEntry."Shipment Date";
        ReservationEntry.Modify();

        ReservationEntry.Positive := true;
        ReservationEntry."Source Type" := ResvAgainstSourceType;
        ReservationEntry."Source Subtype" := ResvAgainstSourceSubtype;
        ReservationEntry."Source ID" := ResvAgainstSourceID;
        ReservationEntry."Source Ref. No." := ResvAgainstSourceRefNo;
        ReservationEntry."Quantity (Base)" := LotQtyToShip;
        ReservationEntry.Quantity := LotQtyToShip;
        ReservationEntry."Qty. to Handle (Base)" := LotQtyToShip;
        ReservationEntry."Shipment Date" := ReservationEntry."Expected Receipt Date";
        ReservationEntry."Expected Receipt Date" := ReservationEntry."Shipment Date";
        ReservationEntry.Insert();
    end;

    local procedure CreateSales(var WarehouseRequest: Record "Warehouse Request"; ItemNo: Code[20]; LocationCode: Code[10]; QtyToShip: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Location Code" := LocationCode;
        SalesLine.Quantity := QtyToShip;
        SalesLine."Outstanding Quantity" := QtyToShip;
        SalesLine."Qty. to Ship" := QtyToShip;
        SalesLine."Quantity (Base)" := QtyToShip;
        SalesLine."Outstanding Qty. (Base)" := QtyToShip;
        SalesLine."Qty. to Ship (Base)" := QtyToShip;
        SalesLine.Insert();

        Clear(WarehouseRequest);
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := LocationCode;
        WarehouseRequest."Source Type" := DATABASE::"Sales Line";
        WarehouseRequest."Source Subtype" := SalesLine."Document Type".AsInteger();
        WarehouseRequest."Source No." := SalesLine."Document No.";
        WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Sales Order";
        WarehouseRequest.Insert();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateSalesItemTracking(SalesNo: Code[20]; LotCode: Code[10]; QtyToTrack: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesNo);
        CreateItemTrackingEntry(SalesLine, LotCode, QtyToTrack);
    end;

    local procedure ReduceOrDeleteQtyOnReservationEntry(var SalesLine: Record "Sales Line"; QtyToReserve: Decimal; LotCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Before creating reservation, reduce the quantity in the Reservation Entries so that a new reservation pair can be made.
        if LotCode <> '' then begin
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
            ReservationEntry.SetRange(Positive, false);
            ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
            ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type"::Order);
            ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
            ReservationEntry.SetRange("Lot No.", LotCode);
            ReservationEntry.FindFirst();
            Assert.IsTrue(Abs(ReservationEntry.Quantity) >= QtyToReserve, 'Enough quantity of the lot must be already tracked.');
            ReservationEntry."Quantity (Base)" += QtyToReserve;
            ReservationEntry.Quantity += QtyToReserve;
            ReservationEntry."Qty. to Handle (Base)" += QtyToReserve;
            if Abs(ReservationEntry."Quantity (Base)") <= 0 then
                ReservationEntry.Delete()
            else
                ReservationEntry.Modify();
        end;
    end;

    local procedure CreateSalesReservationAgainstPurchase(SalesNo: Code[20]; QtyToReserve: Decimal; LotCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindSalesLine(SalesLine, SalesNo);
        ReduceOrDeleteQtyOnReservationEntry(SalesLine, QtyToReserve, LotCode);

        CreateReservationEntry(SalesLine, LotCode, QtyToReserve,
          DATABASE::"Purchase Line", PurchaseLine."Document Type"::Order.AsInteger(), '', 0);
    end;

    local procedure CreateSalesReservationAgainstILE(SalesNo: Code[20]; QtyToReserve: Decimal; LotCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindSalesLine(SalesLine, SalesNo);
        ReduceOrDeleteQtyOnReservationEntry(SalesLine, QtyToReserve, LotCode);

        ItemLedgerEntry.SetRange("Lot No.", LotCode);
        ItemLedgerEntry.FindFirst();
        CreateReservationEntry(SalesLine, LotCode, QtyToReserve,
          DATABASE::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateSalesShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ItemNo: Code[20]; LocationCode: Code[10]; QtyToShip: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseRequest: Record "Warehouse Request";
        ShipmentBin: Record Bin;
    begin
        CreateSales(WarehouseRequest, ItemNo, LocationCode, QtyToShip);

        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentHeader."Location Code" := LocationCode;
        WarehouseShipmentHeader.Insert();

        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := WarehouseShipmentHeader."No.";
        WarehouseShipmentLine."Source Type" := WarehouseRequest."Source Type";
        WarehouseShipmentLine."Source Subtype" := WarehouseRequest."Source Subtype";
        WarehouseShipmentLine."Source No." := WarehouseRequest."Source No.";
        WarehouseShipmentLine."Source Document" := WarehouseRequest."Source Document";
        WarehouseShipmentLine."Location Code" := LocationCode;
        CreateBin(ShipmentBin, LocationCode);
        WarehouseShipmentLine."Bin Code" := ShipmentBin.Code;
        WarehouseShipmentLine."Item No." := ItemNo;
        WarehouseShipmentLine.Quantity := QtyToShip;
        WarehouseShipmentLine."Qty. (Base)" := QtyToShip;
        WarehouseShipmentLine."Qty. Outstanding" := QtyToShip;
        WarehouseShipmentLine."Qty. Outstanding (Base)" := QtyToShip;
        WarehouseShipmentLine.Insert();
    end;

    local procedure CreateInventoryPickFromWarehouseRequest(WarehouseRequest: Record "Warehouse Request")
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        WhseActivityHeader.Type := WhseActivityHeader.Type::"Invt. Pick";
        WhseActivityHeader."Location Code" := WarehouseRequest."Location Code";

        CreateInventoryPickMovement.SetWhseRequest(WarehouseRequest, true);
        CreateInventoryPickMovement.CheckSourceDoc(WarehouseRequest);
        CreateInventoryPickMovement.AutoCreatePickOrMove(WhseActivityHeader);
    end;

    local procedure CreateWarehousePickFromShipment(WarehouseShipmentLine: Record "Warehouse Shipment Line") WhsePickNo: Code[20]
    var
        CreatePickParameters: Record "Create Pick Parameters";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CreatePick: Codeunit "Create Pick";
        FirstWhseDocNo: Code[20];
    begin
        with WarehouseShipmentLine do begin
            ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
              WhseWkshLine."Whse. Document Type"::Shipment, "No.", "Line No.",
              "Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);

            CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::Shipment;
            CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
            CreatePick.SetParameters(CreatePickParameters);
            CreatePick.SetWhseShipment(WarehouseShipmentLine, 1, '', '', '');
            CreatePick.SetTempWhseItemTrkgLine("No.", DATABASE::"Warehouse Shipment Line", '', 0, "Line No.", "Location Code");
            CreatePick.CreateTempLine("Location Code", "Item No.", '', '', '', "Bin Code", 1, Quantity, "Qty. (Base)");
            CreatePick.CreateWhseDocument(FirstWhseDocNo, WhsePickNo, true);
        end;
    end;

    local procedure MockLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateGUID();
        Location.Insert();
    end;

    local procedure MockWMSLocation(var LocationCode: Code[10]; var BinCode: Code[20])
    var
        Location: Record Location;
        Bin: Record Bin;
        ZoneCode: Code[10];
    begin
        CreateBasicLocation(Location);
        ZoneCode := CreateZone(Location.Code);
        CreateBin(Bin, Location.Code);
        Bin."Zone Code" := ZoneCode;
        Bin.Modify();

        Location."Directed Put-away and Pick" := true;
        Location."Adjustment Bin Code" := Bin.Code;
        Location.Insert();

        LocationCode := Location.Code;
        BinCode := Bin.Code;
    end;

    local procedure MockSKU(LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Init();
        StockkeepingUnit."Location Code" := LocationCode;
        StockkeepingUnit.Insert();
    end;

    local procedure MockItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        with ItemJournalLine do begin
            Init();
            "Location Code" := LocationCode;
            "Bin Code" := BinCode;
            Insert();
        end;
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            Init();
            "Document Type" := "Document Type"::Order;
            "Document No." := LibraryUtility.GenerateGUID();
            "Outstanding Quantity" := LibraryRandom.RandInt(10);
            "Qty. per Unit of Measure" := LibraryRandom.RandIntInRange(2, 5);
            "Outstanding Qty. (Base)" := "Outstanding Quantity" * "Qty. per Unit of Measure";
            Insert();
        end;
    end;

    local procedure MockWhseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        with WarehouseShipmentHeader do begin
            Init();
            "No." := LibraryUtility.GenerateGUID();
            Status := Status::Open;
            Insert();
        end;
    end;

    local procedure MockWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        with WarehouseEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, FieldNo("Entry No."));
            "Entry Type" := "Entry Type"::"Negative Adjmt.";
            "Source Type" := DATABASE::"Sales Line";
            "Source Subtype" := 1;
            "Location Code" := LocationCode;
            "Bin Code" := BinCode;
            Quantity := -LibraryRandom.RandInt(10);
            "Qty. per Unit of Measure" := LibraryRandom.RandIntInRange(2, 5);
            "Qty. (Base)" := Quantity * "Qty. per Unit of Measure";
            Insert();
        end;
    end;

    local procedure MockWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    begin
        WarehouseActivityHeader.Init();
        WarehouseActivityHeader.Type := ActivityType;
        WarehouseActivityHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityHeader."Location Code" := LocationCode;
        WarehouseActivityHeader.Insert();
    end;

    local procedure MockWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    begin
        with WarehouseActivityLine do begin
            Init();
            "Activity Type" := ActivityType;
            "No." := LibraryUtility.GenerateGUID();
            "Action Type" := ActionType;
            "Location Code" := LocationCode;
            "Bin Code" := BinCode;
            "Item No." := ItemNo;
            Insert();
        end;
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        with Item do begin
            "No." := LibraryUtility.GenerateGUID();
            Insert();
        end;
    end;

    local procedure MockTransferLine(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; Qty: Decimal)
    begin
        with TransferLine do begin
            Init();
            "Document No." := LibraryUtility.GenerateGUID();
            "Transfer-from Code" := LibraryUtility.GenerateGUID();
            "Item No." := ItemNo;
            "Variant Code" := LibraryUtility.GenerateGUID();
            Quantity := Qty;
            Insert();
        end;
    end;

    local procedure MockItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Qty: Decimal)
    begin
        with ItemJournalLine do begin
            Init();
            "Entry Type" := EntryType;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            "Location Code" := LocationCode;
            Quantity := Qty;
        end;
    end;

    local procedure MockReservationEntry(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; SourceID: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Qty: Decimal)
    begin
        with ReservationEntry do begin
            Init();
            "Source Type" := SourceType;
            "Source ID" := SourceID;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            "Location Code" := LocationCode;
            "Quantity (Base)" := Qty;
            "Qty. to Handle (Base)" := Qty;
            "Qty. to Invoice (Base)" := Qty;
            Insert();
        end;
    end;

    local procedure MockWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceType: Integer; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Qty: Decimal): Code[20]
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        with WarehouseShipmentHeader do begin
            Init();
            "No." := LibraryUtility.GenerateGUID();
            "Location Code" := LocationCode;
            Insert();
        end;

        with WarehouseShipmentLine do begin
            Init();
            "No." := WarehouseShipmentHeader."No.";
            "Source Type" := SourceType;
            "Source No." := SourceNo;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            "Bin Code" := LibraryUtility.GenerateGUID();
            Quantity := Qty;
            Insert();
        end;

        exit(WarehouseShipmentLine."Bin Code")
    end;

    local procedure MockWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; SourceType: Integer; SourceNo: Code[20]; WhseDocType: Enum "Warehouse Journal Document Type"; WhseDocNo: Code[20]; BinCode: Code[20]; Qty: Decimal)
    begin
        with WarehouseEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, FieldNo("Entry No."));
            "Source Type" := SourceType;
            "Source No." := SourceNo;
            "Whse. Document Type" := WhseDocType;
            "Whse. Document No." := WhseDocNo;
            "Bin Code" := BinCode;
            "Qty. (Base)" := Qty;
            Insert();
        end;
    end;
}

