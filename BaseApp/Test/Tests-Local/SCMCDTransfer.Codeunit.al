codeunit 147103 "SCM CD Transfer"
{
    // Check the functionalities of Custom Declarations:
    // --==Transfer Orders Posting==--
    // CheckTOwithCD - Check Transfer Order with only CD Tracking Specification
    // CheckTOwithCDandSN - Check Transfer Order with CD and SN Tracking Specification
    // CheckTOwithCDandLot - Check Transfer Order with CD and Lot Tracking Specification
    // CheckPartTOwithCD - Check Transfer Order Partial Post (CD Tracking)
    // CheckPartTOwithCDandLot - Check Transfer Order Partial Post (SN+CD Tracking)
    // CheckTOwithCDUOM - Complex Unit of Measure Full Post (CD Tracking)
    // CheckTOwithCDandSNUOM - Complex Unit of Measure Full Post (SN+CD Tracking)
    // 
    // --==Errors in Item Tracking Lines==--
    // CheckITLinesSN - Compares the Error message when there is incorrect Serial Number in ITL
    // CheckTracking - Compares the Error message trying to post TO without Tracking info
    // CheckInventoryTO - Compares the error message
    // 
    // --==Check correct posting of Item Reclassification Jnl.==--
    // CheckItReclJnlLoc - Check Item Reclassification Journal (CD Tracking) for only CDNo. Changes (at one location)
    // CheckIrReclJnlLocationsCD - Check Item Reclassification Journal for Location, CD and SN reset
    // 
    // --==Check CD Tracking Setup with manually entered CD No.==--
    // CheckManualCDinTO - Check that in case of after-posting creation of CD Information fields (Inventory) is correct
    // CheckManualCDinTOInbError - Check that if "Allow Temporary CD No." = FALSE, it is not possible post the TO (Location To Setup)
    // CheckManualCDinIRJnl - Check that in case of after-posting Reclass Jnl Line creation of CD Information fields is correct
    // CheckManualCDError - Check that TO won't be posted with arbitrary CD No. (Transit Location Setup)
    // CheckItReclJnlErrorOutb - Check that Recl Jnl Line won't be posted with arbitrary CD No. / LocationFrom.OutboundCDInfo
    // CheckItReclJnlErrorInv - Check that it is impossible to outbound item with not-existing CD No
    // CheckItReclJnlErrorOneInb - Check CD Info doesn't exist Error in the case of inbound / LocationTo.InboundCDInfo
    // 
    // =======================================================================================
    // 
    // CheckTOwithSN - Check Transfer Order (SN Tracking)
    // CheckTOwithSNandLot - Check Transfer Order posting (SN and Lot tracking)
    // CheckSNLotError - Check correspondence between SN and Lot tracking in TO
    // 
    // =======================================================================================
    // 
    // CheckDTwithCD - Check Direct Transfer document with CD No. changes

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        IsNotOnvInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.';
        QtyToHandleMessage: Label 'Qty. to Handle (Base) in the item tracking assigned to the document line for item %1 is currently 3. It must be 4.\\Check the assignment for serial number %2, lot number .';
        CDInfoNotExist: Label 'The CD No. Information does not exist.';
        CDNoRequired: Label 'You must assign a CD number for item %1.', Comment = '%1 - Item No.';
        Text001: Label 'Error in TearDown';
        TextDT: Label 'Do you want to post the %1?';
        Text000: Label '&Ship,&Receive';
        TempCDIsNotEqualErr: Label 'Temporary CD No. must be equal to ''No''  in CD No. Information';
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryReservation: Codeunit "Create Reserv. Entry";
        ReservMgt: Codeunit "Reservation Management";
        InvSetup: Record "Inventory Setup";
        isInitialized: Boolean;
        WrongInventoryErr: Label 'Wrong inventory.';
        SerTxt: Label 'SER';
        DoYouWantPostDirectTransferMsg: Label 'Do you want to post the Direct Transfer?';
        IncorrectConfirmDialogOpenedMsg: Label 'Incorrect confirm dialog opened: ';
        HasBeenDeletedMsg: Label 'is now deleted';
        UnexpectedMsg: Label 'Unexpected message: ';

    [Normal]
    local procedure Initialize()
    var
        InvSetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        InvSetup.Get();
        InvSetup.Validate("Posted Direct Transfer Nos.", CreateNoSeries);
        InvSetup.Modify();

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 6);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[2], 4);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[1], 6);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 4);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[1], 6);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 4);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithCDandSN()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: array[2] of Code[30];
        Serial: Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        for i := 1 to 5 do begin
            Serial := 'SN0' + Format(i);
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, Serial, '', CDNo, 1);
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        for i := 1 to 3 do begin
            Serial := 'SN0' + Format(i);
            CreateDirectTracking(ReservationEntry, TransferLine, Serial, '', CDNo, NewCDNo[1], Serial, '', 1);
        end;

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        for i := 4 to 5 do begin
            Serial := 'SN0' + Format(i);
            CreateDirectTracking(ReservationEntry, TransferLine, Serial, '', CDNo, NewCDNo[2], Serial + '/01', '', 1);
        end;
        PostTransferDocument(TransferHeader);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'SN02', '', NewCDNo[1], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'SN05/01', '', NewCDNo[2], 1);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithBin()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        NewCDNo: array[2] of Code[10];
        BinCode: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LocationTo.Validate("Bin Mandatory", true);
        LocationTo.Modify();

        CDNo := LibraryUtility.GenerateGUID;
        for i := 1 to ArrayLen(BinCode) do begin
            BinCode[i] := LibraryUtility.GenerateGUID;
            CreateBin(LocationTo, BinCode[i]);
        end;

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 10);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[1], '', '', 3);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[1]);
        TransferLine.Modify();

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[2], '', '', 7);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[2]);
        TransferLine.Modify();
        PostTransferDocument(TransferHeader);

        CheckBinContent(LocationTo.Code, BinCode[1], Item."No.", 3);
        CheckBinContent(LocationTo.Code, BinCode[2], Item."No.", 7);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithCD()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: array[2] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 10);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[1], '', '', 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[2], '', '', 7);
        PostTransferDocument(TransferHeader);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', NewCDNo[1], 3);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', NewCDNo[2], 7);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithCDandLotNo()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: Code[30];
        LotNo: array[2] of Code[20];
        NewCDNo: array[2] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LotNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        for i := 1 to ArrayLen(LotNo) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[i], CDNo, 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        for i := 1 to ArrayLen(LotNo) do
            CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[i], CDNo, NewCDNo[1], '', LotNo[i], 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[1], CDNo, NewCDNo[2], '', LotNo[1], 2);
        CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[2], CDNo, NewCDNo[1], '', LotNo[2], 2);
        PostTransferDocument(TransferHeader);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], NewCDNo[1], 2);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], NewCDNo[2], 2);

        Item.SetFilter("Location Filter", LocationTo.Code);
        Item.SetFilter("CD No. Filter", NewCDNo[1]);
        Item.SetFilter("Lot No. Filter", LotNo[2]);
        Item.CalcFields(Inventory);

        Assert.AreEqual(5, Item.Inventory, WrongInventoryErr);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckManualCDinDT()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDLine: Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;
        NewCDNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 10);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo, '', '', 10);
        PostTransferDocument(TransferHeader);
        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", NewCDNo);
        CDLine.FindFirst;

        CheckCDInventoryLoc(CDLine, LocationTo.Code, 10);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithCD()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: Code[30];
        Qty: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateForeignVendor(Vendor);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 20;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo, 10);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, '', '', CDNo, -10);

        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', '', CDNo, -10);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo, 10);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithCDandSN()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        SerialNo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            SerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 2, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', CDNo[i], 1);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        for i := 1 to ArrayLen(SerialNo) do
            LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[i], '', CDNo[i], 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        for i := 1 to ArrayLen(SerialNo) do
            LibraryCDTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTransit.Code, SerialNo[i], '', CDNo[i], 1);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        for i := 1 to ArrayLen(SerialNo) do
            LibraryCDTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[i], '', CDNo[i], 1);
        CheckQuantityLocation(Item, LocationTransit.Code, 0);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithCDandLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        LotNo: array[3] of Code[20];
        SerialNo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            SerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[1], CDNo[1], 5);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[2], CDNo[2], 3);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[3], CDNo[2], 2);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[1], CDNo[1], 5);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[2], CDNo[2], 3);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[3], CDNo[2], 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[1], CDNo[1], 5);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[2], CDNo[2], 3);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[3], CDNo[2], 2);

        CheckQuantityLocation(Item, LocationFrom.Code, 0);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], CDNo[1], 5);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], CDNo[2], 3);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], CDNo[2], 2);

        CheckQuantityLocation(Item, LocationTransit.Code, 0);
        CheckQuantityLocation(Item, LocationTo.Code, 10);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithBin()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        BinCode: array[2] of Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        Qty: Integer;
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LocationTo.Validate("Bin Mandatory", true);
        LocationTo.Modify();

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            BinCode[i] := LibraryUtility.GenerateGUID;
            CreateBin(LocationTo, BinCode[i]);
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 3);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[2], 7);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[1], 3);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[1]);
        TransferLine.Modify();

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 7);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[2]);
        TransferLine.Modify();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        CheckBinContent(LocationTo.Code, BinCode[1], Item."No.", 3);
        CheckBinContent(LocationTo.Code, BinCode[2], Item."No.", 7);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartTOwithCD()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[2] of Code[30];
        Qty: Integer;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 20;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 10);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 20);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[1], 10);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 10);
        TransferLine.Validate("Qty. to Ship", 15);
        TransferLine.Modify();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        CheckQuantityLocation(Item, LocationFrom.Code, 5);
        CheckQuantityLocation(Item, LocationTo.Code, 15);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[1], 10);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 5);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartTOwithCDandLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        LotNo: array[3] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[1], CDNo, 4);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[2], CDNo, 3);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', LotNo[3], CDNo, 3);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[1], CDNo, 4);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[2], CDNo, 3);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', LotNo[3], CDNo, 3);
        TransferLine.Validate("Qty. to Ship", 9);
        TransferLine.Modify();

        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
        CheckQuantityLocation(Item, LocationFrom.Code, 1);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], CDNo, 4);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], CDNo, 3);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], CDNo, 2);

        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], CDNo, 1);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithCDUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[2] of Code[30];
        Qty: Integer;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 12);

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 100;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 70);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], 30);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 8);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[1], 70);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 26);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[1], 70);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 26);

        CheckQuantityLocation(Item, LocationTo.Code, 96);
        CheckQuantityLocation(Item, LocationFrom.Code, 4);
        CheckQuantityLocation(Item, LocationTransit.Code, 0);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithCDandSNUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        SerialNo: array[7] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        CreateTransferTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 3);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 7, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', CDNo, 1);
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        for i := 1 to 5 do
            LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[i], '', CDNo, 1);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[7], '', CDNo, 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        for i := 1 to 5 do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[i], '', CDNo, 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[7], '', CDNo, 1);

        CheckQuantityLocation(Item, LocationTransit.Code, 0);
        CheckQuantityLocation(Item, LocationFrom.Code, 1);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithManyLines()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: array[2] of Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode[1], false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item[1], ItemTrackingCode[1].Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item[1]."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode[2], false, false, false);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item[2], ItemTrackingCode[2].Code);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[1]."No.", 60, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 60);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[2]."No.", 60, LocationFrom.Code);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        i := 1;
        while i < 101 do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[2]."No.", 1);
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
            LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo, 1);
            i := i + 2;
        end;
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo, 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", LocationTo.Code, '', '', CDNo, 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", LocationTo.Code, '', '', '', 1);

        CheckQuantityLocation(Item[1], LocationTo.Code, 51);
        CheckQuantityLocation(Item[2], LocationTo.Code, 50);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckITLinesSN()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        SerialNo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();
        for i := 1 to ArrayLen(SerialNo) do
            SerialNo[i] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 1, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, SerialNo[1], '', CDNo, 1);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[2], '', CDNo, 1);
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTracking()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        SerialNo: array[4] of Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 4, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', CDNo[1], 1);
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[1], '', CDNo[1], 1);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[2], '', CDNo[2], 1);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, SerialNo[3], '', CDNo[1], 1);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(QtyToHandleMessage, Item."No.", SerialNo[1]));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckInventoryTO()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 4, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 4);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 4);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItReclJnlOneLoc()
    var
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 20, LocationTo.Code);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 20);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, EntryType::Transfer, WorkDate, Item."No.", 15, LocationTo.Code, LocationTo.Code);
        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 15);
        ReservationEntry.Validate("New CD No.", CDNo[2]);
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 15);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItReclJnlLocationsCD()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[3] of Code[30];
        SerialNo: array[4] of Code[20];
        NewSerialNo: array[4] of Code[20];
        Qty: Integer;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateForeignVendor(Vendor);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do
            CDNo[i] := LibraryUtility.GenerateGUID;
        for i := 1 to 2 do begin
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
            CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine.Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);

        for i := 1 to Qty do begin
            SerialNo[i] := LibraryUtility.GenerateGUID;
            NewSerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[i], '', CDNo[Round(i / 2, 1)], 1);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[3]);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();

        CreateItemReclassJnlLine(ItemJnlLine, EntryType::Transfer, WorkDate, Item."No.", 4, LocationFrom.Code, LocationTo.Code);

        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, SerialNo[1], '', CDNo[1], 1);
        ReservationEntry.Validate("New CD No.", CDNo[1]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[1]);
        ReservationEntry.Modify();
        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, SerialNo[2], '', CDNo[1], 1);
        ReservationEntry.Validate("New CD No.", CDNo[2]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[2]);
        ReservationEntry.Modify();
        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, SerialNo[3], '', CDNo[2], 1);
        ReservationEntry.Validate("New CD No.", CDNo[1]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[3]);
        ReservationEntry.Modify();
        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, SerialNo[4], '', CDNo[2], 1);
        ReservationEntry.Validate("New CD No.", CDNo[3]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[4]);
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CheckQuantityLocation(Item, LocationTo.Code, 4);
        CheckQuantityLocation(Item, LocationFrom.Code, 0);
        CheckQuantityLocationCD(Item, LocationFrom.Code, CDNo[1], 0);
        CheckQuantityLocationCD(Item, LocationFrom.Code, CDNo[2], 0);
        CheckQuantityLocationCD(Item, LocationTo.Code, CDNo[1], 2);
        CheckQuantityLocationCD(Item, LocationTo.Code, CDNo[2], 1);
        CheckQuantityLocationCD(Item, LocationTo.Code, CDNo[3], 1);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[1], '', CDNo[1], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[3], '', CDNo[1], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[4], '', CDNo[3], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[2], '', CDNo[2], 1);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckManualCDinTO()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDLine: Record "CD No. Information";
        InvSetup: Record "Inventory Setup";
        CDNo: array[2] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        for i := 1 to ArrayLen(CDNo) do
            CDNo[i] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 2);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[2], 3);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 5);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[1], 2);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[2], 3);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[1], 2);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 3);

        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", CDNo[1]);
        CDLine.FindFirst;

        CheckCDInventoryLoc(CDLine, LocationTo.Code, 2);
        CDLine.Reset();
        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", CDNo[2]);
        CDLine.FindFirst;

        CheckCDInventoryLoc(CDLine, LocationTo.Code, 3);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckManualCDinTOInbError()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        InvSetup: Record "Inventory Setup";
        CDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", true);
        InvSetup.Modify();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, false);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTransit.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 5);
        LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo, 5);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, true);
        Assert.ExpectedError(TempCDIsNotEqualErr);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckManualCDinIRJnl()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[3] of Code[30];
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        for i := 1 to ArrayLen(CDNo) do
            CDNo[i] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        for i := 1 to 5 do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, 'S' + Format(i), '', CDNo[1], 1);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, EntryType::Transfer, WorkDate, Item."No.", 5, LocationFrom.Code, LocationTo.Code);
        for i := 1 to 4 do begin
            LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, 'S' + Format(i), '', CDNo[1], 1);
            ReservationEntry.Validate("New Serial No.", 'S00' + Format(i));
            ReservationEntry.Validate("New CD No.", CDNo[2]);
            ReservationEntry.Modify();
        end;

        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, 'S5', '', CDNo[1], 1);
        ReservationEntry.Validate("New Serial No.", 'S005');
        ReservationEntry.Validate("New CD No.", CDNo[3]);
        ReservationEntry.Modify();

        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CDLine.Reset();
        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", CDNo[2]);
        CDLine.FindFirst;
        CheckCDInventoryLoc(CDLine, LocationTo.Code, 4);

        CDLine.Reset();
        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", CDNo[3]);
        CDLine.FindFirst;
        CheckCDInventoryLoc(CDLine, LocationTo.Code, 1);

        CDLine.Reset();
        CDLine.SetRange("No.", Item."No.");
        CDLine.SetRange("CD No.", CDNo[1]);
        CDLine.FindFirst;
        CheckCDInventoryLoc(CDLine, LocationFrom.Code, 0);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItReclJnlErrorInv()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        NewCDNo: Code[30];
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        NewCDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, EntryType::Transfer, WorkDate, Item."No.", 5, LocationFrom.Code, LocationTo.Code);
        LibraryCDTracking.CreateReclassJnLineTracking(ReservationEntry, ItemJnlLine, '', '', NewCDNo, 5);

        ReservationEntry.Validate("New CD No.", NewCDNo);
        ReservationEntry.Modify();

        asserterror LibraryCDTracking.PostItemJnlLine(ItemJnlLine);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithSN()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", true);
        InvSetup.Modify();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 9, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, SerTxt, '', 9);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        CreateTransferSNTracking(ReservationEntry, TransferLine, SerTxt, '', 4);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        for i := 1 to 4 do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, SerTxt + '0' + Format(i), '', '', 1);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
        for i := 1 to 4 do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, SerTxt + '0' + Format(i), '', '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, SerTxt + '0' + Format(7), '', '', 1);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithSNandLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S0', LotNo[1], 5);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S1', LotNo[2], 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S0', LotNo[1], 4);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S1', LotNo[2], 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S001', LotNo[1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S002', LotNo[1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S003', LotNo[1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S004', LotNo[1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S101', LotNo[2], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S102', LotNo[2], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, 'S005', LotNo[1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, 'S104', LotNo[2], '', 1);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSNLotError()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        CreateEmptyCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S0', LotNo[1], 5);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S1', LotNo[2], 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S1', LotNo[1], 4);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S0', LotNo[2], 2);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultiTrackingTO()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        ItemTrackingCode: array[2] of Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode[1], false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode[1].Code, LocationTransit.Code);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode[2], true, false, false);

        for i := 1 to ArrayLen(Item) do
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode[i].Code);
        CDNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[1]."No.", 5, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[2]."No.", 5, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, SerTxt, '', 5);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item[2]."No.", 4);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[2], Item[1]."No.", 2);
        CreateTransferSNTracking(ReservationEntry, TransferLine[1], SerTxt, '', 4);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(CDNoRequired, Item[1]."No."));

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithCDSNandCUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: array[2] of Code[30];
        SerialNo: array[20] of Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 9);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 20, LocationFrom.Code);
        CDNo := LibraryUtility.GenerateGUID;
        for i := 1 to 20 do begin
            SerialNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', CDNo, 1);
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        for i := 1 to 18 do
            CreateDirectTracking(ReservationEntry, TransferLine, SerialNo[i], '', CDNo, NewCDNo[1], SerialNo[i], '', 1);

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        CreateDirectTracking(ReservationEntry, TransferLine, SerialNo[19], '', CDNo, NewCDNo[2], SerialNo[19], '', 1);
        PostTransferDocument(TransferHeader);

        CheckQuantityLocationCD(Item, LocationTo.Code, NewCDNo[1], 18);
        CheckQuantityLocationCD(Item, LocationTo.Code, NewCDNo[2], 1);
        CheckQuantityLocationCD(Item, LocationFrom.Code, CDNo, 1);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithReserve()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: array[2] of Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[3] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CostingMethod: Option FIFO,LIFO,Specific,"Average",Standard;
        i: Integer;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        Item.Validate("Costing Method", CostingMethod::LIFO);
        Item.Modify();

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 3, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 3);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 4, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[3], 4);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 200, 10);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 5);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], 5);

        CreateDirectTrHeader(TransferHeader[1], LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader[1], TransferLine[1], Item."No.", 12);
        ReserveDTFromPO(TransferHeader[1], PurchaseHeader, Item, LocationFrom, '', '', CDNo[1], 5);
        SetNewCDNo(Item."No.", CDNo[1], CDNo[1]);
        ReserveDTFromPO(TransferHeader[1], PurchaseHeader, Item, LocationFrom, '', '', CDNo[2], 4);
        SetNewCDNo(Item."No.", CDNo[2], CDNo[2]);
        ReserveDTFromInv(TransferLine[1], 3);
        SetNewCDNo(Item."No.", CDNo[3], CDNo[3]);

        CreateDirectTrHeader(TransferHeader[2], LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader[2], TransferLine[2], Item."No.", 1);
        ReserveDTFromPO(TransferHeader[2], PurchaseHeader, Item, LocationFrom, '', '', CDNo[2], 1);
        SetNewCDNo(Item."No.", CDNo[2], CDNo[2]);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PostTransferDocument(TransferHeader[1]);

        CheckQuantityLocationCD(Item, LocationFrom.Code, CDNo[3], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[2], 4);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[1], 5);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckITLinDT()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: Code[30];
        Serial: Code[20];
        Qty: Integer;
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);

        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        CDTrackingSetup.Validate("Allow Temporary CD No.", true);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        CDTrackingSetup.Validate("Allow Temporary CD No.", true);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 5, LocationFrom.Code);
        CDNo := LibraryUtility.GenerateGUID;
        for i := 1 to 5 do begin
            Serial := 'SER0' + Format(i);
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, Serial, '', CDNo, 1);
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        NewCDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", NewCDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Modify();

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        for i := 1 to 3 do begin
            Serial := 'SER0' + Format(i);
            CreateDirectTracking(ReservationEntry, TransferLine, Serial, '', CDNo, NewCDNo, Serial, '', 1);
        end;

        asserterror PostTransferDocument(TransferHeader);
        Assert.ExpectedError(StrSubstNo(QtyToHandleMessage, Item."No.", 'SER01'));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCDInfoDT()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDNo: Code[30];
        NewCDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithCDInfoMustExist(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithCDInfoMustExist(ItemTrackingCode.Code, LocationFrom.Code, false);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;
        NewCDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 2, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 2);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo, '', '', 2);
        asserterror PostTransferDocument(TransferHeader);
        Assert.ExpectedError(CDInfoNotExist);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTemporaryCDNoDT()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        Qty: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", true);
        InvSetup.Modify();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, false);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Validate("Temporary CD No.", true);
        CDLine.Modify();

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 2, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 2);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, CDNo, '', '', 2);
        asserterror PostTransferDocument(TransferHeader);
        Assert.ExpectedError(TempCDIsNotEqualErr);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckCDFormatInDT()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNoFormat: Record "CD No. Format";
        CDNo: Code[30];
        NewCDNo: Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
    begin
        Initialize;
        UpdateCDNoFormat;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, false);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        NewCDNo := 'CD1/' + Item."No." + '/000';
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", NewCDNo);
        CDLine.Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
        CDLine.Validate("Temporary CD No.", false);
        CDLine.Modify();

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 2, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 2);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo, '', '', 2);
        PostTransferDocument(TransferHeader);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDTInventoryErrMsg()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationTo.Code, true);
        CreateCDTrackingWithAllowTempNo(ItemTrackingCode.Code, LocationFrom.Code, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 10, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 10);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item."No.", 2, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[2], 2);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 12);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo[1], CDNo[1], '', '', 8);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo[2], CDNo[2], '', '', 4);
        asserterror PostTransferDocument(TransferHeader);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithManyLines()
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode1: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: Code[30];
        NewCDNo: array[2] of Code[30];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        i: Integer;
    begin
        Initialize;
        InvSetup.Get();
        InvSetup.Validate("Check CD No. Format", false);
        InvSetup.Modify();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode1, true, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, LocationFrom.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode1.Code, LocationTo.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode1.Code, LocationFrom.Code);

        for i := 1 to ArrayLen(Item) do
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[1]."No.", 51, LocationFrom.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, 51);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(NewCDNo) do begin
            NewCDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item[i]."No.", NewCDNo[i]);
            CDLine[i].Validate("Country/Region Code", CDHeader."Country/Region of Origin Code");
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::"Positive Adjmt.", WorkDate, Item[2]."No.", 51, LocationFrom.Code);
        i := 1;
        while i < 52 do begin
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, 'SN' + Format(i), '', NewCDNo[2], 1);
            i += 1;
        end;
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        i := 1;
        while i < 101 do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
            CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[1], '', '', 1);

            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[2]."No.", 1);
            CreateDirectTracking(ReservationEntry, TransferLine, 'SN' + Format((i + 1) / 2), '', NewCDNo[2], NewCDNo[2], 'SN_' + Format((i + 1) / 2), '', 1);
            i := i + 2;
        end;
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', CDNo, NewCDNo[2], '', '', 1);
        PostTransferDocument(TransferHeader);

        CheckQuantityLocationCD(Item[1], LocationTo.Code, NewCDNo[1], 50);
        CheckQuantityLocationCD(Item[1], LocationTo.Code, NewCDNo[2], 1);
        CheckQuantityLocationCD(Item[2], LocationTo.Code, NewCDNo[2], 50);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure InTransitCodeUpdatedWhenChangingTransferFromTransOrderNoDirectTransfer()
    var
        LocationFrom: Record Location;
        LocationFromNew: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Transfer Order] [In-Transit Location]
        // [SCENARIO 371940] Transfer Order should allow changing "Transfer-From Code" resulting in empty transit code if "Direct Transfer" is not allowed

        // [GIVEN] Transfer order with "Direct Transfer" = FALSE and "In-Transit Code" filled
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationTransit);

        CreateTransferOrder(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code, false);

        // [WHEN] Change "Transfer-From Code" in the transfer order
        LibraryWarehouse.CreateLocation(LocationFromNew);
        TransferHeader.Validate("Transfer-from Code", LocationFromNew.Code);

        // [THEN] "In-Transit Code" is set to an empty string
        TransferHeader.TestField("In-Transit Code", '');
    end;

    [Scope('OnPrem')]
    procedure CheckQuantityLocation(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal): Boolean
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Qty, Item.Inventory, WrongInventoryErr);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CheckQuantityLocationCD(var Item: Record Item; LocationCode: Code[10]; CDNo: Code[30]; Qty: Decimal): Boolean
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("CD No. Filter", CDNo);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Qty, Item.Inventory, WrongInventoryErr);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateTransferSNTracking(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[10]; LotNo: Code[20]; Quantity: Integer)
    var
        i: Integer;
        Serial: Code[20];
    begin
        for i := 1 to Quantity do begin
            Serial := SerialNo + '0' + Format(i);
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, Serial, LotNo, 1);
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateJnlLineSNTracking(var ReservationEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line"; SerialNo: Code[10]; LotNo: Code[20]; Quantity: Decimal)
    var
        i: Integer;
        Serial: Code[20];
    begin
        for i := 1 to Quantity do begin
            Serial := SerialNo + '0' + Format(i);
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, Serial, LotNo, 1);
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateDirectTrHeader(var TransferHeader: Record "Transfer Header"; LocationTo: Text[10]; LocationFrom: Text[10])
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateDirectTracking(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; NewCDNo: Code[30]; NewSN: Code[20]; NewLot: Code[20]; QtyBase: Integer)
    begin
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo, LotNo, QtyBase);
        ReservationEntry.Validate("CD No.", CDNo);
        ReservationEntry.Validate("New CD No.", NewCDNo);
        ReservationEntry.Validate("New Serial No.", NewSN);
        ReservationEntry.Validate("New Lot No.", NewLot);
        ReservationEntry.Modify(true);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ReserveDTFromPO(var TransferHeader: Record "Transfer Header"; var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Location: Record Location; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Integer)
    begin
        LibraryReservation.CreateReservEntryFrom(5741, 0, TransferHeader."No.", '', 0, 10000, 1, SerialNo, LotNo, CDNo);
        LibraryReservation.CreateEntry(Item."No.", '', Location.Code, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, 0);
        LibraryReservation.CreateReservEntryFor(39, 1, PurchaseHeader."No.", '', 0, 10000, 1, Qty, Qty, SerialNo, LotNo, CDNo);
        LibraryReservation.CreateEntry(Item."No.", '', Location.Code, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, 0);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ReserveDTFromInv(var TransferLine: Record "Transfer Line"; Quantity: Integer)
    var
        AutoReserve: Boolean;
    begin
        ReservMgt.SetTransferLine(TransferLine, 0);
        TransferLine.TestField("Shipment Date");
        ReservMgt.AutoReserveToShip(AutoReserve, '', TransferLine."Shipment Date", Quantity, Quantity);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateBin(var Location: Record Location; BinCode: Code[20])
    var
        BinLine: Record Bin;
    begin
        BinLine.Init();
        BinLine.Validate("Location Code", Location.Code);
        BinLine.Validate(Code, BinCode);
        BinLine.Insert(true);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateItemReclassJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Option; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; NewLocationCode: Code[10])
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalTemplateType: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod.Order";
        LineNo: Integer;
    begin
        FindItemJnlTemplate(ItemJnlTemplate, ItemJournalTemplateType::Transfer);
        FindItemJnlBatch(ItemJnlBatch, ItemJournalTemplateType::Transfer, ItemJnlTemplate.Name);
        with ItemJnlLine do begin
            SetRange("Journal Template Name", ItemJnlTemplate.Name);
            SetRange("Journal Batch Name", ItemJnlBatch.Name);
            if FindLast then;
            LineNo := "Line No." + 10000;

            Init;
            "Journal Template Name" := ItemJnlTemplate.Name;
            "Journal Batch Name" := ItemJnlBatch.Name;
            "Line No." := LineNo;
            Insert(true);
            Validate("Posting Date", PostingDate);
            "Document No." := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", true);
            Validate("Entry Type", EntryType);
            Validate("Item No.", ItemNo);
            Validate(Quantity, Qty);
            Validate("Location Code", LocationCode);
            Validate("New Location Code", NewLocationCode);
            Modify;
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure FindItemJnlTemplate(var ItemJournalTemplate: Record "Item Journal Template"; ItemJournalTemplateType: Option)
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplateType);
        ItemJournalTemplate.FindFirst;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure FindItemJnlBatch(var ItemJnlBatch: Record "Item Journal Batch"; ItemJnlBatchTemplateType: Option; ItemJnlTemplateName: Code[10])
    begin
        ItemJnlBatch.SetRange("Template Type", ItemJnlBatchTemplateType);
        ItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplateName);

        if not ItemJnlBatch.FindFirst then
            CreateItemJnlBatch(ItemJnlBatch, ItemJnlTemplateName);

        if ItemJnlBatch."No. Series" = '' then begin
            ItemJnlBatch."No. Series" := CreateNoSeries;
        end;
    end;

    local procedure CreateDTLocations(var LocationFrom: Record Location; var LocationTo: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateItemJnlBatch(var ItemJnlBatch: Record "Item Journal Batch"; ItemJnlTemplateName: Code[10])
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch.Validate("Journal Template Name", ItemJnlTemplateName);
        ItemJnlBatch.Validate(
          Name, CopyStr(LibraryUtility.GenerateRandomCode(ItemJnlBatch.FieldNo(Name), DATABASE::"Item Journal Batch"), 1,
            MaxStrLen(ItemJnlBatch.Name)));
        ItemJnlBatch.Insert(true);
    end;

    local procedure CreateCDTrackingWithAllowTempNo(ItemTrackingCode: Code[10]; LocationCode: Code[10]; AllowTemporaryCDNo: Boolean)
    var
        CDTrackingSetup: Record "CD Tracking Setup";
    begin
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode, LocationCode);
        CDTrackingSetup.Validate("Allow Temporary CD No.", AllowTemporaryCDNo);
        CDTrackingSetup.Modify();
    end;

    local procedure CreateCDTrackingWithCDInfoMustExist(ItemTrackingCode: Code[10]; LocationCode: Code[10]; CDNoInfoMustExist: Boolean)
    var
        CDTrackingSetup: Record "CD Tracking Setup";
    begin
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode, LocationCode);
        CDTrackingSetup.Validate("CD Info. Must Exist", CDNoInfoMustExist);
        CDTrackingSetup.Modify();
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromCode: Code[10]; ToCode: Code[10]; InTransitCode: Code[10]; DirectTransfer: Boolean)
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromCode, ToCode, InTransitCode);
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
        TransferHeader.Modify(true);

        // Create a dummy item
        Item.Init();
        Item.Insert(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateTransferTracking(var CDTrackingSetup: Record "CD Tracking Setup"; ItemTrackingCode: Code[10]; CDLocationCode: Code[10])
    begin
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode, CDLocationCode);
        CDTrackingSetup.Validate("CD Sales Check on Release", false);
        CDTrackingSetup.Validate("CD Purchase Check on Release", false);
        CDTrackingSetup.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CheckCDInventoryLoc(var CDLine: Record "CD No. Information"; LocationCode: Code[10]; Qty: Decimal): Boolean
    begin
        CDLine.SetRange("Location Filter", LocationCode);
        CDLine.CalcFields(Inventory);
        Assert.AreEqual(Qty, CDLine.Inventory, WrongInventoryErr);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateEmptyCDTracking(var CDTrackingSetup: Record "CD Tracking Setup"; ItemTrackingCode: Code[10]; CDLocationCode: Code[10])
    begin
        CDTrackingSetup."Item Tracking Code" := ItemTrackingCode;
        CDTrackingSetup."Location Code" := CDLocationCode;
        CDTrackingSetup.Insert();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CheckBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Qty: Integer)
    var
        BinCon: Record "Bin Content";
    begin
        BinCon.SetFilter("Location Code", LocationCode);
        BinCon.SetFilter("Bin Code", BinCode);
        BinCon.SetFilter("Item No.", ItemNo);
        BinCon.FindFirst;
        BinCon.CalcFields(Quantity);
        Assert.AreEqual(Qty, BinCon.Quantity, WrongInventoryErr);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure SetNewCDNo(ItemNo: Code[20]; CDNo: Code[30]; NewCDNo: Code[30])
    var
        ItemTracking: Option "None","Lot No.","Lot and Serial No.","Serial No.","CD No.","Lot and CD No.","Serial and CD No.","Lot and Serial and CD No.";
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetFilter("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Transfer Line");
        ReservationEntry.FindLast;
        ReservationEntry.Validate("CD No.", CDNo);
        ReservationEntry.Validate("New CD No.", NewCDNo);
        ReservationEntry.Validate("Item Tracking", ItemTracking::"CD No.");
        ReservationEntry.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GetNoSeries(Descr: Text[50]; StartNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        ind: Code[20];
    begin
        NoSeries.SetRange(Description, Descr);
        if NoSeries.FindFirst then begin
            ind := NoSeries.Code;
            NoSeriesLine.SetRange("Series Code", ind);
            if (not NoSeriesLine.FindFirst) then begin
                NoSeriesLine.Init();
                NoSeriesLine.Validate("Series Code", ind);
                NoSeriesLine.Validate("Starting No.", StartNo);
                NoSeriesLine.Insert(true);
            end
        end
        else begin
            NoSeries.Init();
            NoSeries.Validate(Code, Format(StartNo, 5));
            NoSeries.Validate(Description, Descr);
            NoSeries.Validate("Default Nos.", true);
            NoSeries.Validate("Manual Nos.", true);
            NoSeries.Insert();
            NoSeriesLine.Init();
            NoSeriesLine.Validate("Series Code", ind);
            NoSeriesLine.Validate("Starting No.", StartNo);
            NoSeriesLine.Insert(true);
        end;
    end;

    local procedure PostTransferDocument(var TransferHeader: Record "Transfer Header")
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        TransferPostTransfer.Run(TransferHeader);
    end;

    local procedure UpdateCDNoFormat()
    var
        SetCDNoFormat: Record "CD No. Format";
    begin
        if SetCDNoFormat.FindLast then begin
            SetCDNoFormat.Validate(Format, '@@#/@@########/###');
            SetCDNoFormat.Modify();
        end else begin
            SetCDNoFormat.Init();
            SetCDNoFormat.Validate(Format, '@@#/@@########/###');
            SetCDNoFormat.Insert();
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure TearDown()
    begin
        asserterror Error(Text001);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantPostDirectTransferMsg) <> 0 then
            Reply := true
        else
            Error(IncorrectConfirmDialogOpenedMsg + Question);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(msg: Text[1024])
    var
        temp: Text[100];
    begin
        if StrPos(msg, HasBeenDeletedMsg) <> 0 then
            temp := msg;
        case msg of
            temp:
                ;
            else
                Error(UnexpectedMsg + msg);
        end;
    end;
}

