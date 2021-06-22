codeunit 137305 "SCM Warehouse Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ValidationErr: Label '%1 must be %2 in %3.';
        CombineShipmentMsg: Label 'The shipments are now combined';
        JournalLineRegistered: Label 'The journal lines were successfully registered.';
        WantToRegisterConfirm: Label 'Do you want to register the journal lines?';
        ErrRecordMissing: Label 'The record count must match.';
        SHIP: Label 'SHIP';
        BULK: Label 'BULK';
        InvtPutAwayCreated: Label 'Number of Invt. Put-away activities created';
        CombineShipmentErr: Label 'Incorrect Sales Invoice Line Type';

    [Test]
    [HandlerFunctions('PickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingList()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));
        RegisterPutAway(Location.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 5);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit;
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Picking List", true, false, WarehouseActivityHeader);

        // Verify: Source No shown in Picking List Report is equal to the Source No shown in Warehouse Activity Line Table.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('SourceNo_WhseActLine', SalesHeader."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_WhseActLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActLine', WarehouseActivityLine."Qty. (Base)");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetInboundSourceDocuments()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhsePutAwayRqst: Record "Whse. Put-away Request";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Post Warehouse Receipt.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, true);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Run Get Inbound Source Documents Batch Report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        WhsePutAwayRqst.SetRange("Completely Put Away", false);
        WhsePutAwayRqst.SetRange("Location Code", Location.Code);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRqst, WhseWorksheetName, Location.Code);

        // Verify: Check Warehouse Work Sheet Line have same Item No.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        Assert.AreEqual(
          Item."No.", WhseWorksheetLine."Item No.",
          StrSubstNo(ValidationErr, WhseWorksheetLine.FieldCaption("Item No."), Item."No.", WhseWorksheetLine.TableCaption));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayList()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Post Warehouse Receipt.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Run Put-away List report.
        Commit;
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Put-away List", true, false, WarehouseActivityHeader);

        // Verify.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('ItemNo1_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('SrcNo_WhseActivLine', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InventoryPutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayList()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Setup:  Create Warehouse Setup, Create and Release Purchase Order.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Run Inventory Put-away List report.
        Commit;
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Put-away List", true, false, Item);

        // Verify.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocumentNo_PurchLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Item', Item."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtytoReceive_PurchLine', PurchaseLine."Qty. to Receive");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_PurchLine', PurchaseLine."Location Code");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseReceiptListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceipt()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptNo: Code[20];
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Create Warehouse Receipt From Purchase Order.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        PurchaseQuantity := LibraryRandom.RandDec(10, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", PurchaseQuantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo;
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise: Run Whse. - Receipt report.
        Commit;
        WarehouseReceiptHeader.SetRange("No.", WarehouseReceiptNo);
        REPORT.Run(REPORT::"Whse. - Receipt", true, false, WarehouseReceiptHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('SourceNo_WhseRcptLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_WhseRcptLine', PurchaseQuantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_WhseRcptLine', WarehouseReceiptHeader."Bin Code");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishment()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Zone: Record Zone;
        Quantity: Decimal;
    begin
        // Setup : Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory.
        Initialize;
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        UpdateRankingOnAllBins(Location.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        Zone.Get(Location.Code, 'PICK');
        CreateBinContentForBin(Zone, Item, Quantity);
        FindFirstBinRankingForZone(Bin, 'BULK', Location.Code);  // BULK Zone.
        CreateWhseJnlLine(
          WarehouseJournalLine,
          Location.Code, Bin."Zone Code",
          Bin.Code,
          Item."No.",
          Quantity,
          WarehouseJournalBatch."Template Type"::Item);
        LibraryVariableStorage.Enqueue(WantToRegisterConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLineRegistered);  // Enqueue for MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, false);

        // Exercise : Run Calculate Bin Replenishment.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        BinContent.SetRange("Location Code", Location.Code);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, Location.Code, true, false, false);

        // Verify : Verify From Bin Code And To Bin code with Created Warehouse Worksheet Line.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        FindBinContent(BinContent, Location.Code, Item."No.");
        Bin.Get(Location.Code, BinContent."Bin Code");
        Assert.AreEqual(
          Bin.Code, WhseWorksheetLine."From Bin Code", StrSubstNo(ValidationErr, Bin.FieldCaption(Code), Bin.Code, Bin.TableCaption));
        FindLastRankingBin(Bin, Location.Code, Zone.Code);
        Assert.AreEqual(
          Bin.Code, WhseWorksheetLine."To Bin Code", StrSubstNo(ValidationErr, Bin.FieldCaption(Code), Bin.Code, Bin.TableCaption));
        Assert.AreEqual(
          Quantity, WhseWorksheetLine."Qty. to Handle", StrSubstNo(ValidationErr, 'Quantity', Quantity, 'Movement Worksheet'));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,WhseAdjustmentBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseAdjustmentBin()
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory, Random Values Important.
        Initialize;
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(50, 2);
        CreateAndRegisterWhseJnlLine(Location, Item."No.", Quantity);

        // Exercise: Run Whse. Adjustment Bin Report.
        WarehouseEntry.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Whse. Adjustment Bin", true, false, WarehouseEntry);

        // Verify: Check Item No. Exit On the report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('WarehouseEntryItemNo', Item."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('WarehouseEntryLocCode', Location.Code);
        Bin.Get(Location.Code, Location."Adjustment Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('WarehouseEntryBinCode', Bin.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('WhseEntryQtyBase', -Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('WhseEntryQuantity', -Quantity);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WarehouseBinListReportHandler')]
    [Scope('OnPrem')]
    procedure WarehouseBinList()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin.
        Initialize;
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        UpdateRankingOnAllBins(Location.Code);

        // Exercise: Run Warehouse Bin List Report.
        Commit;
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Adjustment Bin", false);
        REPORT.Run(REPORT::"Warehouse Bin List", true, false, Bin);

        // Verify: Check Bin Ranking with generated report.
        LibraryReportDataset.LoadDataSetFile;
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindSet;
        repeat
            LibraryReportDataset.Reset;
            LibraryReportDataset.SetRange('Code_Bin', Bin.Code);
            LibraryReportDataset.GetNextRow;
            LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_Bin', Location.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('BinRanking_Bin', Bin."Bin Ranking");
            LibraryReportDataset.AssertCurrentRowValueEquals('BinTypeCode_Code', Bin."Bin Type Code");
        until Bin.Next = 0;

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOutboundSourceDocuments()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // Setup: Create Warehouse Setup, Create and Release Sales Order, Release Warehouse Shipment.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(Location.Code);

        // Exercise: Run Get Outbound Source Documents Batch Report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", Location.Code);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, Location.Code);

        // Verify: Check Warehouse Worksheet Line have same Item No.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        Assert.AreEqual(
          Item."No.", WhseWorksheetLine."Item No.",
          StrSubstNo(ValidationErr, WhseWorksheetLine.FieldCaption("Item No."), Item."No.", WhseWorksheetLine.TableCaption));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MovementListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseMovement()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Zone: Record Zone;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory, Calculate Bin Replenishment and Create Movement.
        Initialize;
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Zone.Get(Location.Code, 'PICK');
        CreateBinContentForBin(Zone, Item, 100);
        UpdateRankingOnAllBins(Location.Code);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));
        RegisterPutAway(Location.Code, PurchaseHeader."No.");

        // Create Movement Worksheet with Movement.
        CreateMovementWorksheetLine(WhseWorksheetLine, Location.Code, Item."No.");
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, 0, false, false, false);

        // Exercise: Run Movement List Report.
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Movement);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Movement List", true, false, WarehouseActivityHeader);

        // Verify: Check Bin Code with Generated report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyWarehouseActivityLine(Item."No.", Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(Item."No.", Location.Code, WarehouseActivityLine."Action Type"::Place);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseCalculateInventory()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory.
        Initialize;
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        UpdateRankingOnAllBins(Location.Code);
        Quantity := LibraryRandom.RandDec(10, 2) + 100;  // Value used for quantity more than maximum Bin Content quntity.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        RegisterPutAway(Location.Code, PurchaseHeader."No.");

        // Exercise: Run Whse. Calculate Inventory Report.
        RunWhseCalculateInventoryReport(Location.Code, Item."No.");

        // Verify: Check Quantity with generated Warehouse Journal Line.
        FindAndVerifyWhseJnlLine(Location.Code, '', Quantity);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('TransferOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrder()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location.
        Initialize;
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);

        // Exercise: Run Transfer Order report.
        Commit;
        TransferHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Order", true, false, TransferHeader);

        // Verify: Check Transfer Order Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_TransLine', Item."No.", 'Qty_TransLine', TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('TransferShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferShipment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        FromLocation: Record Location;
        TransferLine: Record "Transfer Line";
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location And Post Transfer Shipment.
        Initialize;
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);

        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post Transfer Shipment.

        // Exercise: Run Transfer Shipment  report.
        TransferShipmentHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Shipment", true, false, TransferShipmentHeader);

        // Verify: Check Transfer Shipment Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_TransShptLine', Item."No.", 'Qty_TransShptLine', TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('TransferReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferReceipt()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location And Post Transfer Receipt.
        Initialize;
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);  // Post Transfer Shipment And Transfer Receipt.

        // Exercise: Run Transfer Receipt report.
        TransferReceiptHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Receipt", true, false, TransferReceiptHeader);

        // Verify: Check Transfer Receipt Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_TransRcpLine', Item."No.", 'Qty_TransRcpLine', TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('WhsePostedReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedWarehouseReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseEmployee: Record "Warehouse Employee";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WarehouseReceiptNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Warehouse receipt;
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo;
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindAndUpdateWarehouseReceipt(WarehouseReceiptNo, Item."No.", Quantity / 2);
        PostWarehouseReceipt(WarehouseReceiptNo);
        FindPostedWarehouseReceiptHeader(PostedWhseReceiptHeader, WarehouseReceiptNo, Location.Code);

        // Exercise: Run Posted Receipt report.
        Commit;
        REPORT.Run(REPORT::"Whse. - Posted Receipt", true, false, PostedWhseReceiptHeader);

        // Verify: Check Quantity To Receive, Item No. Quantity exist in Warehouse Posted Receipt Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_PostedWhseRcpLine', Item."No.", 'Qty_PostedWhseRcpLine', Quantity / 2);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InventoryPickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickingList()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        RegisterPutAway(Location.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity / 2);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit;
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Picking List", true, false, Item);

        // Verify: Source No ,ItemNo and Location shown in Inventory Picking List Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_Item', Item."No.", 'DocumentNo_SalesLine', SalesHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_SalesLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipment()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2) + 5;
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity);
        WarehouseShipmentHeaderNo := FindWarehouseShipmentNo;
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit;
        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentHeaderNo);
        REPORT.Run(REPORT::"Whse. - Shipment", true, false, WarehouseShipmentHeader);

        // Verify: Item No, Quantity and Location shown in Warehouse Shipment Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_WhseShptLine', Item."No.", 'Qty_WhseShptLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseShptLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentStatus()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize;
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2) + 5;
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity);
        WarehouseShipmentNo := FindWarehouseShipmentNo;
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit;
        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentNo);
        REPORT.Run(REPORT::"Whse. Shipment Status", true, false, WarehouseShipmentHeader);

        // Verify: Source No, Item No and Location shown in Warehouse Shipment Status Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_WhseShipmentLine', Item."No.", 'SourceNo_WhseShipmentLine', SalesHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseShipmentLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipment()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        "Count": Integer;
    begin
        // Setup : Create Customer, Item, Multiple Sales Order and Post Shipment.
        Initialize;
        CreateCustomer(Customer);
        CreateItem(Item);
        Count := LibraryRandom.RandInt(10);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", Count, LibraryRandom.RandDec(10, 2));

        // Exercise : Run Combine Sales Shipments With Option Post Invoice FALSE.
        RunCombineShipments(Customer."No.", false, false, false, false);

        // Verify : Check That Sales Invoice Created after Run Batch Report with Option Post Sales FALSE.
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        Assert.AreEqual(Count, SalesLine.Count, ErrRecordMissing);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentPostInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        "Count": Integer;
    begin
        // Setup : Create Customer, Item, Multiple Sales Order and Post Shipment.
        Initialize;
        CreateCustomer(Customer);
        CreateItem(Item);
        Count := LibraryRandom.RandInt(10);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", Count, LibraryRandom.RandDec(10, 2));
        // Exercise : Run Combine Sales Shipments With Option Post Invoice TRUE.
        RunCombineShipments(Customer."No.", false, true, false, false);

        // Verify : Check That Posted Sales Invoice Created after Run Batch Report with Option Post Invoice TRUE.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        Assert.AreEqual(Count, SalesInvoiceLine.Count, ErrRecordMissing);
    end;

    [Test]
    [HandlerFunctions('WhsePhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePhysicalInventoryList()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Order. Create and Post Warehouse Receipt. Run Warehouse Calculate Inventory Report.
        Initialize;
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity);
        RunWhseCalculateInventoryReport(LocationWhite.Code, Item."No.");

        // Exercise: Run Warehouse Physical Inventory List report.
        Commit;
        WarehouseJournalLine.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Whse. Phys. Inventory List", true, false, WarehouseJournalLine);

        // Verify: Verify Warehouse Physical Inventory List report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_WarehouseJournlLin', Item."No.", 'QtyCalculated_WhseJnlLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,WhseRegisterQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseRegisterQuantity()
    var
        WarehouseRegister: Record "Warehouse Register";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create and Register Warehouse Journal Line.
        Initialize;
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterWhseJnlLine(LocationWhite, Item."No.", Quantity);

        // Exercise: Run Warehouse Register Quantity report.
        Commit;
        WarehouseRegister.SetRange("From Entry No.", FindWarehouseEntryNo(Item."No."));
        REPORT.Run(REPORT::"Warehouse Register - Quantity", true, false, WarehouseRegister);

        // Verify: Verify Warehouse Register Quantity report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_WarehouseEntry', Item."No.", 'Quantity_WarehouseEntry', -Quantity);
    end;

    [Test]
    [HandlerFunctions('InventoryPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPostingTest()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create and Post Item Journal. Run Calculate Inventory. Update Quantity Physical Inventory on Item Journal line.
        Initialize;
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity);
        RunCalculateInventory(Item."No.", false);
        UpdateQuantityPhysicalInventoryOnPhysicalInventoryJournal(Item."No.");

        // Exercise: Run Inventory Posting Test report.
        Commit;
        ItemJournalLine.SetRange("Item No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Posting - Test", true, false, ItemJournalLine);

        // Verify: Quantity and Invoiced Quantity on Inventory Posting Test report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('Item_Journal_Line__Item_No__', Item."No.", 'Item_Journal_Line_Quantity', Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReport()
    var
        Item: Record Item;
        Item2: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create two Items. Create two Sales Orders.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", Customer."No.", Quantity);
        CreateSalesOrder(SalesHeader2, '', Item2."No.", Customer."No.", Quantity);

        // Exercise.
        Commit;
        Customer.SetRange("No.", Customer."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Customer - Order Detail", true, false, Customer);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_SalesLine', Item."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesHeaderNo', SalesHeader."No.");

        VerifyReportData('No_SalesLine', Item2."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesHeaderNo', SalesHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('SalesReturnReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnReceiptReport()
    var
        Item: Record Item;
        Customer: Record Customer;
        ReturnReceiptHeader: Record "Return Receipt Header";
        Quantity: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Order. Create and Post Sales Return Order.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", 1, Quantity);  // Value 1 required for one Sales Order.
        PostedDocumentNo := CreateAndPostSalesReturnOrder(Customer."No.", Item."No.", Quantity, FindItemLedgerEntryNo(Item."No."));

        // Exercise.
        ReturnReceiptHeader.SetRange("No.", PostedDocumentNo);
        REPORT.Run(REPORT::"Sales - Return Receipt", true, false, ReturnReceiptHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_ReturnReceiptLine', Item."No.", 'Qty_ReturnReceiptLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('WorkOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkOrderReport()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCommentLine: Record "Sales Comment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Sales Order. Create and update Sales Comment Line.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", Customer."No.", Quantity);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);  // Value 0 required for Document Line No.
        UpdateDateInSalesCommentLine(SalesCommentLine);

        // Exercise.
        Commit;
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Work Order", true, false, SalesHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_SalesLine', Item."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.Reset;
        LibraryReportDataset.AssertElementWithValueExists('Comment_SalesCommentLine', SalesCommentLine.Comment);
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PeriodLength: DateFormula;
    begin
        // Setup: Create and refresh Planned Production Order.
        Initialize;
        CreateAndRefreshPlannedProductionOrder(ProductionOrder);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');

        // Exercise.
        Commit;
        Item.SetRange("No.", ProductionOrder."Source No.");
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Inventory - Availability Plan", true, false, Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_Item', ProductionOrder."Source No.", 'ScheduledReceipt', 0);
        // Regardless of the period length, last period always includes the prod. order
        // in the projected available balance.
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvBalance8', ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('WarehouseBinListReportHandler')]
    [Scope('OnPrem')]
    procedure WarehouseBinListReport()
    var
        Item: Record Item;
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // Setup: Update Inventory using Warehouse Journal.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Quantity);

        // Exercise.
        Bin.SetRange("Location Code", Bin."Location Code");
        Bin.SetRange(Code, Bin.Code);
        REPORT.Run(REPORT::"Warehouse Bin List", true, false, Bin);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_BinContent', Item."No.", 'Quantity_BinContent', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Code_Bin', Bin.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('BinTypeCode_Code', Bin."Bin Type Code");
    end;

    [Test]
    [HandlerFunctions('PickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListWithSetBreakBulkAsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        Quantity: Decimal;
        WarehouseShipmentNo: Code[20];
    begin
        // Create and Register Pur away from Purchase Order. Create Pick from Warehouse Shipment.
        Initialize;
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithPurchaseUnitOfMesaure(ItemUnitOfMeasure);
        FindPickBin(Bin, LocationWhite.Code);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, ItemUnitOfMeasure."Item No.", Quantity + LibraryRandom.RandDec(10, 2));  // Calculated value required for test.
        RegisterPutAway(LocationWhite.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, LocationWhite.Code, ItemUnitOfMeasure."Item No.", Quantity);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        Commit;
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityLine."Activity Type");
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        REPORT.Run(REPORT::"Picking List", true, false, WarehouseActivityHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ItemNo_WhseActLine', WarehouseActivityLine."Item No.",
          'QtyBase_WhseActLine', WarehouseActivityLine."Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InventoryPutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayListWithBinCode()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Setup: Create Location with Bin. Create Bin Content. Create Inventory Put-away from Purchase Order.
        Initialize;
        CreateItem(Item);
        CreateLocation(Location, WarehouseEmployee, true);  // TRUE for Bin Mandatory.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        CreateInventoryPutAwayFromPurchaseOrder(Location.Code, Item."No.");

        // Exercise.
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Put-away List", true, false, Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_Item', Item."No.", 'LocationCode_PurchLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PriceListReport()
    var
        SalesPrice: Record "Sales Price";
        Item: Record Item;
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
    begin
        // Setup: Create Item with Sales Price.
        Initialize;
        CreateItemWithSalesPrice(SalesPrice);

        // Exercise.
        Commit;
        Item.SetRange("No.", SalesPrice."Item No.");
        LibraryVariableStorage.Enqueue(SalesPrice."Starting Date");
        LibraryVariableStorage.Enqueue(SalesType::"All Customers");
        REPORT.Run(REPORT::"Price List", true, false, Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('No_Item', SalesPrice."Item No.", 'MinimumQty_SalesPrices', SalesPrice."Minimum Quantity");
    end;

    [Test]
    [HandlerFunctions('WhereUsedListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedListReport()
    var
        AssemblyItem: Record Item;
        ComponentItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item with Component.
        Initialize;
        Quantity := CreateAssemblyItemWithComponent(AssemblyItem, ComponentItem);

        // Exercise.
        ComponentItem.SetRange("No.", ComponentItem."No.");
        REPORT.Run(REPORT::"Where-Used List", true, false, ComponentItem);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('ParentItemNo_BOMComponent', AssemblyItem."No.", 'Quantityper_BOMComponent', Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayListReportWithBinCode()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        BinCode: Code[20];
        PurchaseHeaderNo: Code[20];
    begin
        // Setup: Create Location with Bin Content and Inventory Put-away from Purchase.
        Initialize;
        CreateItem(Item);
        CreateLocation(Location, WarehouseEmployee, true);
        BinCode := CreateBinContent(Item, Location.Code);
        PurchaseHeaderNo := CreateInventoryPutAwayFromPurchaseOrder(Location.Code, Item."No.");

        // Exercise: Run the report Put-away List
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Purchase Order");
        WarehouseActivityHeader.SetRange("Source No.", PurchaseHeaderNo);
        REPORT.Run(REPORT::"Put-away List", true, false, WarehouseActivityHeader);

        // Verify: verify that Bin code is presented on report Put-away List
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportData('SrcNo_WhseActivLine', PurchaseHeaderNo, 'BinCode_WhseActivLine', BinCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcInvtOnPhysInvtJnlWithExistingWhseEntry()
    var
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Quantity: Decimal;
    begin
        // Setup: Create and register Warehouse Journal Line.
        Initialize;
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(50, 2);
        CreateAndRegisterWhseJnlLine2(
          LocationWhite, Item."No.", Quantity, WarehouseJournalBatch."Template Type"::"Physical Inventory");

        // Exercise: Run Calculate Inventory on Phys. Inventory Journal.
        RunCalculateInventory(Item."No.", true);

        // Verify: Verify Qty. (Calculated), Qty. (Phys. Inventory) and Quantity on Item Journal Line.
        VerifyPhysInvtJournalLine(Item."No.", 0, Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacingDescriptionOnlySalesLineBySalesLineWithItemTypeDoesNotPreventCombiningShipments()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDescription: Text[100];
        Quantity1: Decimal;
        Quantity2: Decimal;
    begin
        // [FEATURE] [Combine Shipments] [Description Sales Line]
        // [SCENARIO 363166] Replacing Description Only Sales Line (Type = 0) by Sales Line with Item type does not prevent Combining Shipment
        Quantity1 := LibraryRandom.RandDec(10, 2);
        Quantity2 := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Sales Order with two lines
        CreateItem(Item);
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Sales Line "L1", where "Type" = "Item", "No." = "X"
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity1);

        // [GIVEN] Sales Line "L2", where "Type" = " ", "No." = " ", Description = "D"
        CreateSalesLineDescriptionOnly(SalesHeader, SalesLine);
        SalesLineDescription := SalesLine.Description;

        // [GIVEN] Ship the Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Overwrite Sales Line "L2" with "Type" = "Item", "No." = "X"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        with SalesLine do begin
            Find;
            Validate(Type, Type::Item);
            Validate("No.", Item."No.");
            Validate(Quantity, Quantity2);
            Modify(true);
        end;

        // [GIVEN] Ship the Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = YES
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Posted Sales Invoice contains 3 lines: "L1", "L2" and Description line
        VerifyPostedSalesInvoice(Item."No.", Quantity1, Quantity2, SalesLineDescription);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithItemCharge()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Combine Shipments] [Item Charge]
        // [SCENARIO 378180] Shipment with Item Charge Line first should not prevent Combine Shipments
        Initialize;

        // [GIVEN] Sales Order with two lines: 1st - Item Charge, 2-nd - Item
        CreateCustomer(Customer);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSalesOrderWithItemCharge(SalesHeader, Customer."No.", ItemCharge."No.");

        // [GIVEN] Post Sales Order as Shipped
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run Combine Shipment Report
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler
        RunCombineShipments(Customer."No.", false, true, false, false);

        // [THEN] Sales Invoice is created with Item Charge Line
        DummySalesInvoiceLine.SetRange("No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(DummySalesInvoiceLine);
    end;

    [Test]
    [HandlerFunctions('WhseCalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseCalculateInventoryAssignsReasonCode()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Quantity: Decimal;
    begin
        // [SCENARIO 296916] Warehouse Journal Calculate Inventory report assigns Reason Code on the lines it generates
        Initialize;

        // [GIVEN] Warehouse setup
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Item with quantity in location
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);

        // [GIVEN] Whse Physical Inventory Journal Batch with Reason Code = "X"
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, Location.Code, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalBatch."Reason Code" := LibraryUtility.GenerateGUID;
        WarehouseJournalBatch.Modify;

        // [WHEN] Calculate Inventory report (7390) is ran
        RunWhseCalculateInventoryReportWithBatchAndRequestPage(WarehouseJournalBatch, Location.Code);
        // UI Handled by WhseCalculateInventoryRequestPageHandler

        // [THEN] The Whse Journal Line has Reason Code = "X"
        FindAndVerifyWhseJnlLine(Location.Code, WarehouseJournalBatch."Reason Code", Quantity);

        // Clean-up
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsDifferentSelltoBillto()
    var
        Customer: array[2] of Record Customer;
        Item: Record Item;
        "Count": array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Combine Shipments]
        // [SCENARIO 312531] Combine Shipments creates invoice with correct "Sell-To Customer No." and "Bill-to Customer No." when they are not equal on the initial shipment
        Initialize;

        // [GIVEN] Customer "CU01"
        CreateCustomer(Customer[1]);

        // [GIVEN] Customer "CU02" with "Bill-to Customer No." = "CU01"
        CreateCustomer(Customer[2]);
        Customer[2].Validate("Bill-to Customer No.", Customer[1]."No.");
        Customer[2].Modify(true);

        // [GIVEN] Sales Orders Created for "CU01" and "CU02"
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(Customer) do begin
            Count[i] := LibraryRandom.RandInt(5);
            CreateAndPostSalesOrder(Customer[i]."No.", Item."No.", Count[i], LibraryRandom.RandDec(10, 2));
        end;

        // [WHEN] Run Combine Shipments for "Bill-to Customer No." = "CU01" without posting
        RunCombineShipmentsByBillToCustomer(Customer[1]."No.", false, false, false, false);

        // [THEN] Invoices created for "CU01" and "CU02" with "Bill-to Customer No." = "CU01"
        VerifySalesInvoice(Customer[1]."No.", Customer[1]."No.", Count[1]);
        VerifySalesInvoice(Customer[2]."No.", Customer[1]."No.", Count[2]);
    end;

    [Test]
    [HandlerFunctions('PutAwayListRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintInvtPutAwayHeaderWhseDocPrint()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Put-away List]
        // [SCENARIO 312849] PrintInvtPutAwayHeader from codeunit Warehouse Document-Print prints report "Put-away List"
        Initialize;

        // [GIVEN] Inventory Put-away was created from Purchase Order
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Put-away", true);
        Location.Modify(true);
        CreateInventoryPutAwayFromPurchaseOrder(Location.Code, LibraryInventory.CreateItemNo);
        PurchaseHeader.SetRange("Location Code", Location.Code);
        PurchaseHeader.FindFirst;
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst;
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Commit;

        // [WHEN] Call PrintInvtPutAwayHeader from codeunit Warehouse Document-Print
        WarehouseDocumentPrint.PrintInvtPutAwayHeader(WarehouseActivityHeader, true);

        // [THEN] Report "Put-away List" is printed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('ItemNo1_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('SrcNo_WhseActivLine', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Reports");
        LibraryVariableStorage.Clear;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Reports");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        NoSeriesSetup;
        CreateLocationSetup;

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Reports");
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup;
        LibraryPurchase.SetOrderNoSeriesInSetup;
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite, WarehouseEmployee, true);
    end;

    local procedure CreateWarehouseSetup(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; UsePutawayWorksheet: Boolean)
    begin
        CreateLocation(Location, WarehouseEmployee, false);
        Location.Validate("Use Put-away Worksheet", UsePutawayWorksheet);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    [Normal]
    local procedure CreateFullWarehouseSetup(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; IsDefault: Boolean)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, IsDefault);
    end;

    local procedure CreateAssemblyItemWithComponent(var AssemblyItem: Record Item; var ComponentItem: Record Item) Quantity: Decimal
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard,
          AssemblyItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method"::FIFO,
          ComponentItem."Replenishment System"::Purchase, '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, ComponentItem."No.",
          AssemblyItem."No.", '', BOMComponent."Resource Usage Type", Quantity, false);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), Item."Reordering Policy",
          Item."Flushing Method", '', '');
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemWithPurchaseUnitOfMesaure(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10) + 1);
    end;

    local procedure CreateBinContent(var Item: Record Item; LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID, '', '');
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        exit(Bin.Code);
    end;

    [Normal]
    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineDescriptionOnly(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RecRef: RecordRef;
    begin
        with SalesLine do begin
            Init;
            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            RecRef.GetTable(SalesLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Type := Type::" ";
            Description := LibraryUtility.GenerateGUID;
            Insert(true);
        end;
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line.Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    [Normal]
    local procedure RegisterPutAway(LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Normal]
    local procedure CreateWhseShipmentAndPick(var WarehouseShipmentNo: Code[20]; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Create Warehouse Shipment. Run Create Pick.
        WarehouseShipmentNo := FindWarehouseShipmentNo;
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseReceiptNo: Code[20];
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo;
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptNo);
    end;

    local procedure CreateAndRefreshPlannedProductionOrder(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        CreateItemWithReplenishmentSystemAsProdOrder(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // True for CalcLines, CalcRoutings and CalcComponents.
    end;

    local procedure CreateInventoryPutAwayFromPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        WhseRequest: Record "Warehouse Request";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(InvtPutAwayCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);  // TRUE for PutAway.
        LibraryVariableStorage.AssertEmpty;
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateItemWithReplenishmentSystemAsProdOrder(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, LocationCode, ItemNo, '', Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Normal]
    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; "Count": Integer; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        I: Integer;
    begin
        for I := 1 to Count do begin
            Clear(SalesHeader);
            CreateSalesOrder(SalesHeader, '', ItemNo, CustomerNo, Quantity);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;
    end;

    local procedure CreateSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemChargeNo: Code[20])
    var
        SalesLineItemCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", ItemChargeNo, LibraryRandom.RandInt(10));
        SalesLineItemCharge.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLineItemCharge.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineItemCharge, SalesLineItem."Document Type",
          SalesLineItem."Document No.", SalesLineItem."Line No.", SalesLineItem."No.");
    end;

    local procedure CreateAndPostSalesReturnOrder(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ApplicationFromItemEntryNo: Integer) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Appl.-from Item Entry", ApplicationFromItemEntryNo);
        SalesLine.Modify(true);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateItemWithSalesPrice(var SalesPrice: Record "Sales Price")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreateSalesPrice(SalesPrice, SalesPrice."Sales Type"::"All Customers", '',
          Item."No.", WorkDate, '', '', '', LibraryRandom.RandDec(100, 2));
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, true, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateMovementWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Zone: Record Zone;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        WhseWorksheetLine.DeleteAll(true);

        // Select Bin Content with Quantity.
        FindBinContent(BinContent, LocationCode, ItemNo);
        Zone.Get(LocationCode, SHIP);
        FindFirstBinRankingForZone(Bin, Zone.Code, LocationCode);

        // Run Whse. Get Bin Content to populate the Whse. Worksheet Line.
        // Assigning Worksheet Template Name, Name and Location Code to Whse. Worksheet Line for the report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetName."Worksheet Template Name";
        WhseWorksheetLine.Name := WhseWorksheetName.Name;
        WhseWorksheetLine."Location Code" := LocationCode;
        WhseInternalPutAwayHeader.Init;
        LibraryWarehouse.WhseGetBinContent(BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, 0);  // Value for destination Type.

        // Find and Update the created Whse. Worksheet Line.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        WhseWorksheetLine.Validate("To Bin Code", Bin.Code);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]) EntryNo: Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst;
        EntryNo := ItemLedgerEntry."Entry No.";
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Option; SourceNo: Code[20]; ActivityType: Option)
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst;
    end;

    local procedure FindWarehouseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        WarehouseSetup.Get;
        exit(NoSeriesManagement.GetNextNo(WarehouseSetup."Whse. Ship Nos.", WorkDate, false));
    end;

    local procedure FindWarehouseEntryNo(ItemNo: Code[20]) FromEntryNo: Integer
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst;
        FromEntryNo := WarehouseEntry."Entry No.";
    end;

    local procedure FindWarehouseReceiptNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        WarehouseSetup.Get;
        exit(NoSeriesManagement.GetNextNo(WarehouseSetup."Whse. Receipt Nos.", WorkDate, false));
    end;

    local procedure FindWhseWorkSheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name")
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.FindFirst;
    end;

    local procedure FindLastRankingBin(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindLast;
    end;

    local procedure FindFirstBinRankingForZone(var Bin: Record Bin; ZoneCode: Code[10]; LocationCode: Code[10])
    begin
        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindFirst;
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; No: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst;
    end;

    local procedure FindPostedWarehouseReceiptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WhseReceiptNo: Code[20]; LocationCode: Code[10])
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptHeader.SetRange("Location Code", LocationCode);
        PostedWhseReceiptHeader.FindFirst;
    end;

    local procedure FindAndUpdateWarehouseReceipt(WarehouseReceiptNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptNo, ItemNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", Quantity);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindPickZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // TRUE for Put-away and Pick.
        Zone.FindFirst;
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RunWhseCalculateInventoryReport(LocationCode: Code[10]; ItemNo: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        BinContent: Record "Bin Content";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalLine.Init;
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst;
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, WorkDate, LibraryUtility.GenerateGUID, false);
    end;

    local procedure RunWhseCalculateInventoryReportWithBatchAndRequestPage(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseCalculateInventory: Report "Whse. Calculate Inventory";
    begin
        WarehouseJournalLine.Init;
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        WhseCalculateInventory.SetWhseJnlLine(WarehouseJournalLine);
        WhseCalculateInventory.UseRequestPage(true);
        EnqueueValuesForWhseCalculateInventoryRequestPage(WorkDate, LibraryUtility.GenerateGUID, false);

        Commit;

        WhseCalculateInventory.Run;
    end;

    local procedure RunCalculateInventory(ItemNo: Code[20]; ItemsNotOnInvt: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalLine.Init;
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate, ItemsNotOnInvt, false);
    end;

    local procedure RunCombineShipments(CustomerNo: Code[20]; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustomerNo);
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        LibrarySales.CombineShipments(
          SalesHeader, SalesShipmentHeader, WorkDate, WorkDate, CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
    end;

    local procedure RunCombineShipmentsByBillToCustomer(CustomerNo: Code[20]; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesShipmentHeader.SetRange("Bill-to Customer No.", CustomerNo);
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        LibrarySales.CombineShipments(
          SalesHeader, SalesShipmentHeader, WorkDate, WorkDate, CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
    end;

    local procedure CreateTransferOrderLocations(var FromLocation: Record Location; var ToLocation: Record Location; var IntransitLocation: Record Location)
    begin
        CreateAndUpdateLocation(FromLocation, false);
        CreateAndUpdateLocation(ToLocation, false);
        CreateAndUpdateLocation(IntransitLocation, true);
    end;

    local procedure CreateAndRealeaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; IntransitLocation: Code[10]; ItemNo: Code[20]; TransferQuantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, IntransitLocation);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, TransferQuantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    [Normal]
    local procedure CreateAndRegisterWhseJnlLine(Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        CreateAndRegisterWhseJnlLine2(Location, ItemNo, Quantity, WarehouseJournalBatch."Template Type"::Item);
    end;

    local procedure CreateAndRegisterWhseJnlLine2(Location: Record Location; ItemNo: Code[20]; Quantity: Decimal; TemplateType: Option)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        Zone.Get(Location.Code, BULK);
        FindFirstBinRankingForZone(Bin, Zone.Code, Location.Code);
        CreateWhseJnlLine(WarehouseJournalLine, Location.Code, Bin."Zone Code", Bin.Code, ItemNo, Quantity, TemplateType);
        Bin.Get(Location.Code, Location."Adjustment Bin Code");
        WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
        WarehouseJournalLine."From Bin Code" := Bin.Code;
        WarehouseJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(WantToRegisterConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLineRegistered);  // Enqueue for MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, false);
    end;

    [Normal]
    local procedure CreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; TemplateType: Option)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, TemplateType);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode,
          ZoneCode, BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; UseAsInTransit: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Modify(true);
    end;

    local procedure EnqueueValuesForWhseCalculateInventoryRequestPage(RegisteringDate: Date; WhseDocumentNo: Code[20]; ItemNotOnInventory: Boolean)
    begin
        LibraryVariableStorage.Enqueue(RegisteringDate);
        LibraryVariableStorage.Enqueue(WhseDocumentNo);
        LibraryVariableStorage.Enqueue(ItemNotOnInventory);
    end;

    [Normal]
    local procedure FindBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetFilter(Quantity, '>%1', 0);
        BinContent.FindFirst;
    end;

    [Normal]
    local procedure UpdateRankingOnAllBins(LocationCode: Code[10])
    var
        Bin: Record Bin;
        Zone: Record Zone;
        BinRanking: Integer;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindSet;
        repeat
            BinRanking := 0;
            Bin.SetRange("Location Code", LocationCode);
            Bin.SetRange("Zone Code", Zone.Code);
            Bin.FindSet;
            repeat
                BinRanking += 10;  // Value Used for incrementing rank in Bin.
                Bin.Validate("Bin Ranking", BinRanking);
                Bin.Modify(true);
            until Bin.Next = 0;
        until Zone.Next = 0;
    end;

    local procedure CreateBinContentForBin(Zone: Record Zone; Item: Record Item; MaxQty: Decimal)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindSet;
        repeat
            LibraryWarehouse.CreateBinContent(
              BinContent, Zone."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
            BinContent.Validate("Min. Qty.", 1);  // Value important For minimum quantity.
            BinContent.Validate("Max. Qty.", MaxQty);
            BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
            BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
            BinContent.Validate(Fixed, true);
            BinContent.Modify(true);
        until Bin.Next = 0;
    end;

    local procedure FindWhseJnlTemplateAndBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10]; WarehouseJournalTemplateType: Option)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplateType);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure UpdateDateInSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line")
    begin
        SalesCommentLine.Validate(Date, WorkDate);
        SalesCommentLine.Modify(true);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Option)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure ReleaseWarehouseShipment(LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst;
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure FindAndVerifyWhseJnlLine(LocationCode: Code[10]; ReasonCode: Code[10]; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Location Code", LocationCode);
        WarehouseJournalLine.FindFirst;
        Assert.AreEqual(
          Quantity, WarehouseJournalLine."Qty. (Calculated)",
          StrSubstNo(ValidationErr, WarehouseJournalLine.FieldCaption("Qty. (Calculated)"), Quantity, WarehouseJournalLine.TableCaption));
        WarehouseJournalLine.TestField("Reason Code", ReasonCode);
    end;

    local procedure UpdateQuantityPhysicalInventoryOnPhysicalInventoryJournal(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst;
        ItemJournalLine.Validate(
          "Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Calculated)" - (ItemJournalLine."Qty. (Calculated)" / 2));  // Value required for the test.
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        WarehouseJournalLine.DeleteAll(true);  // Delete existing Warehouse Journal Lines.
        CreateWhseJnlLine(
          WarehouseJournalLine,
          Bin."Location Code",
          Bin."Zone Code",
          Bin.Code,
          Item."No.",
          Quantity,
          WarehouseJournalBatch."Template Type"::Item);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyReportData(RowCaption: Text; RowValue: Variant; ColumnCaption: Text; ColumnValue: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        if LibraryReportDataset.GetNextRow then
            LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ColumnValue);
    end;

    [Normal]
    local procedure VerifyWarehouseActivityLine(ItemNo: Code[20]; LocationCode: Code[10]; ActionType: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst;

        LibraryReportDataset.SetRange('ActionType_WhseActivLine', Format(WarehouseActivityLine."Action Type"));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseActivHeader', WarehouseActivityLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_WhseActivLine', WarehouseActivityLine."Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");
    end;

    local procedure VerifyPhysInvtJournalLine(ItemNo: Code[20]; CalculatedQty: Decimal; PhysInvtQty: Decimal; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        with ItemJournalLine do begin
            SetRange("Item No.", ItemNo);
            FindFirst;
            TestField("Qty. (Calculated)", CalculatedQty);
            TestField("Qty. (Phys. Inventory)", PhysInvtQty);
            TestField(Quantity, Qty);
        end;
    end;

    local procedure VerifyPostedSalesInvoice(ItemNo: Code[20]; Quantity1: Decimal; Quantity2: Decimal; SalesLineDescription: Text[100])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        with SalesInvoiceLine do begin
            SetRange("No.", ItemNo);
            SetRange(Quantity, Quantity1);
            FindFirst;
            Assert.AreEqual(Type::Item, Type, CombineShipmentErr);
            SetRange(Quantity, Quantity2);
            FindFirst;
            Assert.AreEqual(Type::Item, Type, CombineShipmentErr);
            Reset;
            SetRange(Description, SalesLineDescription);
            FindFirst;
            Assert.AreEqual(Type::" ", Type, CombineShipmentErr);
        end;
    end;

    local procedure VerifySalesInvoice(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        Assert.RecordCount(SalesLine, ExpectedCount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PriceListRequestPageHandler(var PriceList: TestRequestPage "Price List")
    var
        DateReq: Variant;
        SalesType: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateReq);
        LibraryVariableStorage.Dequeue(SalesType);

        PriceList.Date.SetValue(DateReq);
        PriceList.SalesType.SetValue(SalesType);
        PriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseBinListReportHandler(var WarehouseBinList: TestRequestPage "Warehouse Bin List")
    begin
        WarehouseBinList.ShowBinContents.SetValue(true);
        WarehouseBinList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedListRequestPageHandler(var WhereUsedList: TestRequestPage "Where-Used List")
    begin
        WhereUsedList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickingListRequestPageHandler(var PickingList: TestRequestPage "Picking List")
    begin
        PickingList.Breakbulk.SetValue(true);
        PickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PutAwayListRequestPageHandler(var PutawayList: TestRequestPage "Put-away List")
    begin
        PutawayList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPutAwayListRequestPageHandler(var InventoryPutawayList: TestRequestPage "Inventory Put-away List")
    begin
        InventoryPutawayList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseReceiptListRequestPageHandler(var WhseReceipt: TestRequestPage "Whse. - Receipt")
    begin
        WhseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseAdjustmentBinRequestPageHandler(var WhseAdjustmentBin: TestRequestPage "Whse. Adjustment Bin")
    begin
        WhseAdjustmentBin.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MovementListRequestPageHandler(var MovementList: TestRequestPage "Movement List")
    begin
        MovementList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferOrderRequestPageHandler(var TransferOrder: TestRequestPage "Transfer Order")
    begin
        TransferOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferShipmentRequestPageHandler(var TransferShipment: TestRequestPage "Transfer Shipment")
    begin
        TransferShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferReceiptRequestPageHandler(var TransferReceipt: TestRequestPage "Transfer Receipt")
    begin
        TransferReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePostedReceiptRequestPageHandler(var WhsePostedReceipt: TestRequestPage "Whse. - Posted Receipt")
    begin
        WhsePostedReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPickingListRequestPageHandler(var InventoryPickingList: TestRequestPage "Inventory Picking List")
    begin
        InventoryPickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentRequestPageHandler(var WhseShipment: TestRequestPage "Whse. - Shipment")
    begin
        WhseShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentStatusRequestPageHandler(var WhseShipmentStatus: TestRequestPage "Whse. Shipment Status")
    begin
        WhseShipmentStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListRequestPageHandler(var WhsePhysInventoryList: TestRequestPage "Whse. Phys. Inventory List")
    var
        ShowCalculatedQty: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCalculatedQty);
        WhsePhysInventoryList.ShowCalculatedQty.SetValue(ShowCalculatedQty);
        WhsePhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseRegisterQuantityRequestPageHandler(var WarehouseRegisterQuantity: TestRequestPage "Warehouse Register - Quantity")
    begin
        WarehouseRegisterQuantity.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPostingTestRequestPageHandler(var InventoryPostingTest: TestRequestPage "Inventory Posting - Test")
    begin
        InventoryPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailRequestPageHandler(var CustomerOrderDetail: TestRequestPage "Customer - Order Detail")
    var
        ShowAmountInLCY: Variant;
        NewPagePerCustomer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);
        LibraryVariableStorage.Dequeue(NewPagePerCustomer);

        CustomerOrderDetail.ShowAmountsInLCY.SetValue(ShowAmountInLCY);
        CustomerOrderDetail.NewPagePerCustomer.SetValue(NewPagePerCustomer);
        CustomerOrderDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnReceiptRequestPageHandler(var SalesReturnReceipt: TestRequestPage "Sales - Return Receipt")
    begin
        SalesReturnReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkOrderRequestPageHandler(var WorkOrder: TestRequestPage "Work Order")
    begin
        WorkOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanRequestPageHandler(var InventoryAvailabilityPlan: TestRequestPage "Inventory - Availability Plan")
    var
        StartingDate: Variant;
        PeriodLength: Variant;
        UseStockkeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);

        InventoryAvailabilityPlan.StartingDate.SetValue(StartingDate);
        InventoryAvailabilityPlan.PeriodLength.SetValue(PeriodLength);
        InventoryAvailabilityPlan.UseStockkeepUnit.SetValue(UseStockkeepingUnit);
        InventoryAvailabilityPlan.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseCalculateInventoryRequestPageHandler(var WhseCalculateInventoryPage: TestRequestPage "Whse. Calculate Inventory")
    begin
        WhseCalculateInventoryPage.RegisteringDate.SetValue(LibraryVariableStorage.DequeueDate);
        WhseCalculateInventoryPage.WhseDocumentNo.SetValue(LibraryVariableStorage.DequeueText);
        WhseCalculateInventoryPage.ZeroQty.SetValue(LibraryVariableStorage.DequeueBoolean);
        WhseCalculateInventoryPage.OK.Invoke;
    end;
}

