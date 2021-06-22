codeunit 137407 "SCM Warehouse IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        QuantityError: Label 'Quantity must be equal to %1 in Reservation Entry Table.';
        EmptyWarehouseRegisterMustNotExist: Label 'Empty Warehouse Register must not exist.';
        ExpirationDate1: Label 'Expiration Date must not be %1';
        ExpirationDate2: Label 'in Warehouse Activity Line Activity Type=''Invt. Put-away'',No.=''%1'',';
        ExpirationDate3: Label 'Line No.=''%1''.';
        UnknownFailure: Label 'Unknown Failure.';
        PickMustBeDeletedError: Label 'The Registered Pick must have been deleted for Document No. : %1';
        BinTemplateCode: Code[20];
        FieldSeparator: Code[1];
        RackNo: Code[20];
        SectionNo: Code[20];
        LevelNo: Code[20];
        BinTemplateCodeError: Label 'Code must have a value in Bin Template: Code=. It cannot be zero or empty.';
        BinCodeLengthError: Label 'The length of From Rack+From Section+From Level is greater than the maximum length of %1 (%2).', Comment = '%1 = Caption Bin Code, %2 = Field Length of Bin Code';
        BinCodeNotExistError: Label 'Bin Code Must Not Exists.';
        MustSetupWhseEmployeeErr: Label 'You must first set up user %1 as a warehouse employee.';
        MustSetupDefaultLocationErr: Label 'You must set-up a default location code for user %1.';
        ShouldBeTxt: Label '%1 should be %2', Comment = '%1 = Field, %2 = Expected availability';
        EnabledTxt: Label 'enabled';
        DisabledTxt: Label 'disabled';
        BinMandatoryTxt: Label 'Bin Mandatory must be equal to ''No''  in Location';
        ItemTrackingMode: Option AssignLotNo,AssignSerialNo,SelectEntries,AssignLotAndQty;

    [Test]
    [Scope('OnPrem')]
    procedure GetAllowedLocationWhenNoWhseEmployee()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [SCENARIO] Error message when none Whse Employee is set

        // [GIVEN] No Whse Employee set for current user
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll;

        // [WHEN] GetAllowedLocation(X)
        Location.FindFirst;
        asserterror WMSManagement.GetAllowedLocation(Location.Code);

        // [THEN] Error message : 'Must setup Whse Employee'
        Assert.ExpectedError(StrSubstNo(MustSetupWhseEmployeeErr, UserId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAllowedLocationWhenWhseEmployeeIsSet()
    var
        WMSManagement: Codeunit "WMS Management";
        LocationCode: array[2] of Code[10];
        AllowedLocationCode: Code[10];
    begin
        // [SCENARIO] Get Location as allowed if it is set as Whse Employee

        // [GIVEN] Whse Employee set for current user and location A
        CreateWhseLocations(LocationCode);

        // [WHEN] GetAllowedLocation(A)
        AllowedLocationCode := WMSManagement.GetAllowedLocation(LocationCode[1]);

        // [THEN] Location A is returned
        Assert.AreEqual(LocationCode[1], AllowedLocationCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAllowedLocationWhenDefaultWhseEmployeeIsSet()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        LocationCode: array[2] of Code[10];
        AllowedLocationCode: Code[10];
    begin
        // [SCENARIO] Get Default Location as allowed if Whse Employee is not set

        // [GIVEN] Whse Employee is not set for current user and location A, location B - default
        CreateWhseLocations(LocationCode);
        WarehouseEmployee.Get(UserId, LocationCode[1]);
        WarehouseEmployee.Delete;

        // [WHEN] GetAllowedLocation(A)
        AllowedLocationCode := WMSManagement.GetAllowedLocation(LocationCode[1]);

        // [THEN] Location B is allowed
        Assert.AreEqual(LocationCode[2], AllowedLocationCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAllowedLocationWhenDefaultWhseEmployeeIsNotSet()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        LocationCode: array[2] of Code[10];
    begin
        // [SCENARIO] Get empty Location as allowed if default Whse Employee is not set

        // [GIVEN] Whse Employee is not set for current user and location A
        CreateWhseLocations(LocationCode);
        WarehouseEmployee.Get(UserId, LocationCode[1]);
        WarehouseEmployee.Delete;
        // [GIVEN] Whse Employee is set for current user and location B as not default
        WarehouseEmployee.Get(UserId, LocationCode[2]);
        WarehouseEmployee.Default := false;
        WarehouseEmployee.Modify;

        // [WHEN] GetAllowedLocation(A)
        asserterror WMSManagement.GetAllowedLocation(LocationCode[1]);

        // [THEN] Error message : 'Must setup default loation'
        Assert.ExpectedError(StrSubstNo(MustSetupDefaultLocationErr, UserId));
    end;

    [Test]
    [HandlerFunctions('WhseIntPickCardHandler')]
    [Scope('OnPrem')]
    procedure ShowInternalPickFromActivityLine()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Internal Pick card from Activity Line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);
        // [GIVEN] Exist three Internal Picks (P1..P3) for Location A
        InsertThreeInternalPicks(LocationCode[1], DocumentNo);

        // [WHEN] Open Whse. Document card from Activity line for Internal Pick P2
        ShowWhseDocFromActivityLine(
          WhseActivityLine."Whse. Document Type"::"Internal Pick", DocumentNo[2])

        // [THEN] Internal Pick P2 card is shown
        // Verified in WhseIntPickCardHandler
    end;

    [Test]
    [HandlerFunctions('WhseIntPickCardHandler')]
    [Scope('OnPrem')]
    procedure ShowInternalPickFromRegisteredActivityLine()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Internal Pick card from Registered Activity Line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);
        // [GIVEN] Exist three Internal Picks (P1..P3) for Location B
        InsertThreeInternalPicks(LocationCode[2], DocumentNo);

        // [WHEN] Open Whse. Document card from Registered Activity line for Internal Pick P2
        ShowWhseDocFromRegisteredActivityLine(
          RegisteredWhseActivityLine."Whse. Document Type"::"Internal Pick", DocumentNo[2])

        // [THEN] Internal Pick P2 card is shown
        // Verified in WhseIntPickCardHandler
    end;

    [Test]
    [HandlerFunctions('WhseIntPutAwayCardHandler')]
    [Scope('OnPrem')]
    procedure ShowInternalPutwayFromActivityLine()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Internal Put-Away card from Activity Line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);

        // [GIVEN] Exist three Internal Put-Aways (P1..P3) for Location B
        InsertThreeInternalPutAways(LocationCode[2], DocumentNo);

        // [WHEN] Open Whse. Document card from Activity line for Internal Put-Away P2
        ShowWhseDocFromActivityLine(
          WhseActivityLine."Whse. Document Type"::"Internal Put-away", DocumentNo[2])

        // [THEN] Internal Put-Away P2 card is shown
        // Verified in WhseIntPutAwayCardHandler
    end;

    [Test]
    [HandlerFunctions('WhseIntPutAwayCardHandler')]
    [Scope('OnPrem')]
    procedure ShowInternalPutwayFromRegisteredActivityLine()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Internal Put-Away card from Registered Activity Line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);

        // [GIVEN] Exist three Internal Put-Aways (P1..P3) for Location A
        InsertThreeInternalPutAways(LocationCode[1], DocumentNo);

        // [WHEN] Open Whse. Document card from Registered Activity line for Internal Put-Away P2
        ShowWhseDocFromRegisteredActivityLine(
          RegisteredWhseActivityLine."Whse. Document Type"::"Internal Put-away", DocumentNo[2])

        // [THEN] Internal Put-Away P2 card is shown
        // Verified in WhseIntPutAwayCardHandler
    end;

    [Test]
    [HandlerFunctions('RegisteredMovCardHandler')]
    [Scope('OnPrem')]
    procedure ShowRegisteredMovementFromRegisteredActivityLine()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Movement card from Registered Activity Line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);

        // [GIVEN] Exist three Registered Movements (M1..M3) for Location A
        InsertThreeRegisteredWhseActivities(
          RegisteredWhseActivityLine."Activity Type"::Movement, LocationCode[1], DocumentNo);

        // [WHEN] Show Registered Activity Doc from Registered Activity line for Movement M2
        ShowRegisteredActivityDoc(
          RegisteredWhseActivityLine."Activity Type"::Movement, DocumentNo[2]);

        // [THEN] Movement M2 card is shown
        // Verified in RegisteredMovCardHandler
    end;

    [Test]
    [HandlerFunctions('RegisteredPickCardHandler')]
    [Scope('OnPrem')]
    procedure ShowRegisteredPickFromRegisteredActivityLine()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Pick card from Registered Activity line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);

        // [GIVEN] Exist three Registered Picks (P1..P3) for Location B
        InsertThreeRegisteredWhseActivities(
          RegisteredWhseActivityLine."Activity Type"::Pick, LocationCode[2], DocumentNo);

        // [WHEN] Show Registered Activity Doc from Registered Activity line for Pick P2
        ShowRegisteredActivityDoc(
          RegisteredWhseActivityLine."Activity Type"::Pick, DocumentNo[2]);

        // [THEN] Pick P2 card is shown
        // Verified in RegisteredPickCardHandler
    end;

    [Test]
    [HandlerFunctions('RegisteredPutAwayCardHandler')]
    [Scope('OnPrem')]
    procedure ShowRegisteredPutwayFromRegisteredActivityLine()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LocationCode: array[2] of Code[10];
        DocumentNo: array[3] of Code[20];
    begin
        // [SCENARIO] Open Put-Away card from Registered Activity line

        // [GIVEN] Setup two Whse. locations (A, B-default) for UserID
        CreateWhseLocations(LocationCode);

        // [GIVEN] Exist three Registered Put-Aways (P1..P3) for Location A
        InsertThreeRegisteredWhseActivities(
          RegisteredWhseActivityLine."Activity Type"::"Put-away", LocationCode[1], DocumentNo);

        // [WHEN] Show Registered Activity Doc from Registered Activity line for Put-Away P2
        ShowRegisteredActivityDoc(
          RegisteredWhseActivityLine."Activity Type"::"Put-away", DocumentNo[2]);

        // [THEN] Put-Away P2 card is shown
        // Verified in RegisteredPutAwayCardHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingPurchaseLineSerialNo()
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] item tracking lines are created from Purchase Line for Serial No.

        // [GIVEN] Create Location and Bin. Create Item Tracking Code with Serial No.
        Initialize;
        ItemNo := CreateInitalSetupForWarehouse(Bin, true);

        // [WHEN] Create Purchase With Item Tracking Line.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, true, ItemNo, Bin."Location Code", Bin.Code);

        // [THEN] Reservation Entries created with Serial No.
        VerifyReservationEntry(ItemNo, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingPurchaseLineLotNo()
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] item tracking lines are created from Purchase Line for Lot No.

        // [GIVEN] Create Location and Bin. Create Item Tracking Code with Lot No.
        Initialize;
        ItemNo := CreateInitalSetupForWarehouse(Bin, false);

        // [WHEN] Create Purchase With Item Tracking Line.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, true, ItemNo, Bin."Location Code", Bin.Code);

        // [THEN] Reservation Entries created with Lot No.
        VerifyReservationEntry(ItemNo, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderFromActivityHeaderWithTrackingLineSerialNo()
    begin
        // Create Purchase Order, Create Item Tracking line for Serial No. Post Inventory Put and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        PostAndVerifyInventoryPut(true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderFromActivityHeaderWithTrackingLineLot()
    begin
        // Create Purchase Order, Create Item Tracking line for Lot No. Post Inventory Put and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        PostAndVerifyInventoryPut(false, true, false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderFromActivityHeaderSerialNo()
    begin
        // Create Purchase Order, Post Inventory Put for Serial No. and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        PostAndVerifyInventoryPut(true, false, true, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderFromActivityHeaderLotNo()
    begin
        // Create Purchase Order, Post Inventory Put for Lot No. and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        PostAndVerifyInventoryPut(false, false, false, true);
    end;

    local procedure PostAndVerifyInventoryPut(IsSerialNo: Boolean; IsTracking: Boolean; ManualAssignSerialNo: Boolean; ManualAssignLotNo: Boolean)
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [GIVEN] Create and Release Purchase Order with Expiration Date on Item Tracking Lines.
        ItemNo := CreateInitalSetupForWarehouse(Bin, IsSerialNo);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, IsTracking, ItemNo, Bin."Location Code", Bin.Code);
        CreateInventoryPut(PurchaseLine, ManualAssignSerialNo, ManualAssignLotNo, Bin."Location Code");  // Create Inventory Put with Expiration Date.

        // [WHEN] Post Inventory Put.
        PostInventoryPut(PurchaseLine."Document No.");

        // [THEN] Posted Inventory Put and Posted Document.
        VerifyPostedInventoryPutLine(PurchaseLine."Document No.", Bin."Location Code", ItemNo, WorkDate, Bin.Code);
        VerifyReceiptLine(PurchaseLine."Document No.", Bin."Location Code", Bin.Code, PurchaseLine.Quantity);
        VerifyPostedPurchaseInvoice(PurchaseLine."Document No.", Bin."Location Code", Bin.Code, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderFromActivityHeaderWithTrackingLineSerialNo()
    begin
        // Create Purchase Order with Item Tracking Line and Post Inventory Put. Create Sales Order with Item Tracking line for Serial No. Post Inventory Pick and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        PostAndVerifyInventoryPick(true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderFromActivityHeaderWithTrackingLineLot()
    begin
        // Create Purchase Order with Item Tracking Line and Post Inventory Put. Create Sales Order with Item Tracking line for Lot No. Post Inventory Pick and Verify Posted Document.
        Initialize;
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        PostAndVerifyInventoryPick(false, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderFromActivityHeaderSerialNo()
    begin
        // Create Purchase Order with Inventory Put, Create Sales Order with Item Tracking Line, Post Inventory Pick for Serial No. and Verify Posted Document.
        Initialize;
        PostAndVerifyInventoryPick(true, false, true, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderFromActivityHeaderLotNo()
    begin
        // Create Purchase Order with Inventory Put, Create Sales Order with Item Tracking Line,Post Inventory Pick for Lot No. and Verify Posted Document.
        Initialize;
        PostAndVerifyInventoryPick(false, false, false, true);
    end;

    local procedure PostAndVerifyInventoryPick(IsSerialNo: Boolean; IsTracking: Boolean; ManualAssignSerialNo: Boolean; ManualAssignLotNo: Boolean)
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [GIVEN] Create Inventory Put. Create and Release Sales Order with Expiration Date on Item Tracking Lines.
        ItemNo := CreateInitalSetupForWarehouse(Bin, IsSerialNo);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, IsTracking, ItemNo, Bin."Location Code", Bin.Code);
        CreateInventoryPut(PurchaseLine, ManualAssignSerialNo, ManualAssignLotNo, Bin."Location Code");  // Create Inventory Put with Expiration Date.
        PostInventoryPut(PurchaseLine."Document No.");

        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateAndReleaseSalesOrderWithItemTrackingLines(
          SalesLine, true, WorkDate, ItemNo, Bin."Location Code", Bin.Code, PurchaseLine.Quantity);
        CreateInventoryPick(SalesLine, Bin."Location Code");  // Create Inventory Pick with Expiration Date.

        // [WHEN] Post Inventory Pick.
        PostInventoryPick(SalesLine."Document No.", true);

        // [THEN] Posted Inventory Pick and Verify Posted Document.
        VerifyPostedInventoryPickLine(SalesLine."Document No.", Bin."Location Code", ItemNo, WorkDate, Bin.Code);
        VerifyShipmentLine(SalesLine."Document No.", Bin."Location Code", Bin.Code, SalesLine.Quantity);
        VerifyPostedSalesInvoice(SalesLine."Document No.", Bin."Location Code", Bin.Code, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SameExpirationDateForSameLot()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ExpirationDate: Date;
    begin
        // Create Purchase Order with Same Item two Lines, Create Inventory Put with same Lot No. with same Expiration date. Change Expiration date and Verify the Error Message.

        // [GIVEN] Create Purchase Order, Assign Item Tracking Line With same Lot No. and Create Inventory Put.
        Initialize;
        CreateInventoryPutWithSameLotNo(WarehouseActivityLine);

        // [WHEN] Update Inventory Put Line for Different Expiration Date.
        ExpirationDate := LibraryRandom.RandDate(10);
        asserterror WarehouseActivityLine.Validate("Expiration Date", ExpirationDate);

        // [THEN] Error Message for Different Expiration Date for Same Lot No.
        Assert.AreEqual(
          StrSubstNo(ExpirationDate1, ExpirationDate) + ' ' + StrSubstNo(ExpirationDate2, WarehouseActivityLine."No.") +
          StrSubstNo(ExpirationDate3, WarehouseActivityLine."Line No."), GetLastErrorText, UnknownFailure);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure WarehouseItemJournal()
    var
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create Warehouse Item Journal Line and select No on confirmation Dialog of Posting and Check line is not Posted.

        // [GIVEN] Create Full Warehouse Setup.
        Initialize;
        CreateFullWarehouseSetup(Location);
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);

        // Create Warehouse Item Journal.
        FindBin(Bin, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));

        // [WHEN] Confirm Dialog box for Posting select No in Confirm Message Handler.
        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", WarehouseJournalLine);

        // [THEN] Warehouse Journal Line Exists.
        VerifyWarehouseJournalLine(WarehouseJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseItemJournalPost()
    var
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create and Post Warehouse Item Journal Line and Verify Warehouse Entries.

        // [GIVEN] Create Full Warehouse Setup.
        Initialize;
        CreateFullWarehouseSetup(Location);
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);

        // Create Warehouse Item Journal.
        FindBin(Bin, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));

        // [WHEN] Post Warehouse Journal Line.
        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", WarehouseJournalLine);

        // [THEN] Warehouse Entries for Posted Warehouse Journal Line.
        VerifyWarehouseEntries(WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", WarehouseJournalLine.Quantity);
        VerifyWarehouseEntries(WarehouseJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", -WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure MultiplePurchaseOrders()
    var
        PurchaseOrderNo: array[5] of Code[20];
        PurchaseReceiptNo: array[5] of Code[20];
        ItemNo: Code[20];
        LoopCount: Integer;
    begin
        // Check posting of Purchase Invoices across multiple Purchase Orders.

        // Setup.
        Initialize;
        LoopCount := LibraryRandom.RandInt(5);  // Use Random for multiple Purchase orders.

        // [WHEN] Create multiple Purchase Orders and post them as Receive.
        ItemNo := CreateAndPostMultiplePurchaseOrders(PurchaseOrderNo, PurchaseReceiptNo, LoopCount);

        // [THEN] Verify Item Ledger Entry and Value Entry after posting multiple Purchase Invoices.
        VerifyPostedEntryAfterPostingPurchaseInvoice(PurchaseOrderNo, PurchaseReceiptNo, ItemNo, LoopCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialWarehouseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PartialQuantityToReceive: Decimal;
    begin
        // Test and verify Warehouse Receipt with partial Quantity To Receive.

        // [GIVEN] Create Warehouse Receipt From Purchase Order.
        Initialize;
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);

        // [WHEN] Post Warehouse Receipt with partial Quantity To Receive.
        PartialQuantityToReceive := PostWarehouseReceiptWithPartialQuantityToReceive(WarehouseReceiptLine, PurchaseLine);

        // [THEN] Verify Warehouse Receipt Line and Warehouse Activity Line.
        WarehouseReceiptLine.Get(WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.");
        WarehouseReceiptLine.TestField("Qty. to Receive", PartialQuantityToReceive);
        VerifyWarehouseActivityLine(PurchaseLine."Document No.", PurchaseLine."No.", PartialQuantityToReceive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPartialWarehouseActivity()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
    begin
        // Register Warehouse Activity created by Warehouse Receipt with partial Quantity To Receive.

        // [GIVEN] Create Warehouse Receipt From Purchase Order. Post Warehouse Receipt with partial Quantity To Receive.
        Initialize;
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);
        PostWarehouseReceiptWithPartialQuantityToReceive(WarehouseReceiptLine, PurchaseLine);

        // [WHEN] Register Warehouse Activity.
        FindWarehouseActivityNo(WarehouseActivityLine, PurchaseLine."Document No.", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Registered Warehouse Activity.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        RegisteredWhseActivityHdr.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockKeepingUnitBatchJobWithLocationAndReplaceFalse()
    var
        Item: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
    begin
        // Test functionality of Create Stock Keeping Unit batch job with Location and Replace Previous SKUs as False.

        // [GIVEN] Create an Item and a Location.
        Initialize;
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Create Stock Keeping Unit.
        CreateStockkeepingUnit(Item."No.", Location.Code, '', SKUCreationMethod::Location, false);

        // [THEN] Stock Keeping Unit gets created with new Item and Location.
        FindStockkeepingUnit(StockkeepingUnit, Item."No.", Location.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockKeepingUnitBatchJobWithVariantAndReplaceFalse()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
    begin
        // Test functionality of Create Stock Keeping Unit batch job with Variant and Replace Previous SKUs as False.

        // [GIVEN] Create an Item and a Variant.
        Initialize;
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Create Stock Keeping Unit.
        CreateStockkeepingUnit(Item."No.", '', ItemVariant.Code, SKUCreationMethod::Variant, false);

        // [THEN] Stock Keeping Unit gets created with new Item and Variant.
        FindStockkeepingUnit(StockkeepingUnit, Item."No.", '', ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockKeepingUnitBatchJobWithLocationVariantAndReplaceTrue()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        Location: Record Location;
        Location2: Record Location;
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
    begin
        // Test functionality of Create Stock Keeping Unit batch job with Location and Variant and Replace Previous SKUs as True.

        // [GIVEN] Create an Item, two Locations and two Variants. Create two Stock keeping units for Location and Variant. Update Item's Unit Cost.
        Initialize;
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");
        CreateStockkeepingUnit(Item."No.", Location.Code, ItemVariant.Code, SKUCreationMethod::"Location & Variant", false);
        CreateStockkeepingUnit(Item."No.", Location2.Code, ItemVariant2.Code, SKUCreationMethod::"Location & Variant", false);
        UpdateUnitCostInItem(Item);

        // [WHEN] Create Stock Keeping Unit with Replace Previous SKUs as True.
        CreateStockkeepingUnit(Item."No.", Location.Code, ItemVariant.Code, SKUCreationMethod::"Location & Variant", true);

        // [THEN] Previous Stock Keeping Unit gets replaced with the new one created with updated Unit Cost.
        VerifyStockkeepingUnit(Item."No.", Location.Code, ItemVariant.Code, Item."Unit Cost");
        VerifyStockkeepingUnit(Item."No.", Location2.Code, ItemVariant2.Code, 0);  // Unit Cost remains 0 as SKU does not gets replaced.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisteredPick()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test to verify Registered Pick exists after we create a Pick from Sales Order and Register it.

        // [GIVEN] Create Location, Create Item and update Inventory on the Location. Create a Sales Order and Warehouse Shipment and Create a Pick from it.
        Initialize;
        CreatePickFromSalesOrder(WarehouseActivityHeader);

        // [WHEN] Register the Pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify that the new Pick exists in the Registered Picks.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        RegisteredWhseActivityHdr.FindFirst;
    end;

    [Test]
    [HandlerFunctions('DeleteRegisteredWhseDocsReportHandler')]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWarehouseDocumentReport()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test to verify that Registered Pick gets deleted on running Delete Registered Warehouse Document report.

        // [GIVEN] Create Location, Create Item and update Inventory on the Location. Create a Sales Order and Warehouse Shipment. Create a Pick and Register it.
        Initialize;
        CreatePickFromSalesOrder(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Run Delete Registered Warehouse Document report.
        RunDeleteRegisteredWarehouseDocumentReport(WarehouseActivityHeader."No.");

        // [THEN] Verify that the Pick does not exist.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        Assert.IsFalse(RegisteredWhseActivityHdr.FindFirst, StrSubstNo(PickMustBeDeletedError, WarehouseActivityHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleItemJournalLinesForWarehouse()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // [SCENARIO] Warehouse Entries after posting multiple Item Journal Lines.

        // [GIVEN] Create Location and Find Bin.
        Initialize;
        CreateLocationAndFindBin(Bin, false);
        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random for Quantity.

        // [WHEN] Post multiple Item Journal Lines.
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item), Quantity, Bin."Location Code", Bin.Code);
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item2), Quantity, Bin."Location Code", Bin.Code);

        // [THEN] Verify Warehouse Entries.
        VerifyWarehouseEntries(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        VerifyWarehouseEntries(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialInventoryPickWithMultipleItems()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        PartialQuantity: Decimal;
    begin
        // Test and verify partial Inventory Pick with multiple Items.

        // [GIVEN] Create Location and Find Bin. Post multiple Item Journal Lines. Create and Release Sales Order with multiple lines.
        Initialize;
        CreateLocationAndFindBin(Bin, false);
        PartialQuantity := LibraryRandom.RandDec(100, 2);  // Use Random for Partial Quantity.
        Quantity := PartialQuantity + LibraryRandom.RandDec(100, 2);  // Use Random for Quantity required for test.
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item), Quantity, Bin."Location Code", Bin.Code);
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item2), Quantity, Bin."Location Code", Bin.Code);
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Item2."No.", Bin."Location Code", Bin.Code, Quantity);

        // [WHEN] Create and post Inventory Pick with partial Quantity To Handle.
        CreateAndPostInventoryPick(SalesHeader."No.", Bin."Location Code", PartialQuantity);

        // [THEN] Verify Quantity Handled on Warehouse Activity Line and Quantity Shipped on Sales Line.
        VerifyQuantityHandledOnWarehouseActivityLine(SalesHeader."No.", Bin."Location Code", PartialQuantity);
        VerifySalesLine(SalesHeader."No.", Item."No.", PartialQuantity);
        VerifySalesLine(SalesHeader."No.", Item2."No.", PartialQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FullInventoryPickWithMultipleItemAfterPartialInventoryPick()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        PartialQuantity: Decimal;
    begin
        // Test and verify full Inventory Pick with multiple Items after partial Inventory Pick.

        // [GIVEN] Create Location and Find Bin. Post multiple Item Journal Lines. Create and Release Sales Order with multiple lines. Create and post Inventory Pick with partial Quantity To Handle.
        Initialize;
        CreateLocationAndFindBin(Bin, false);
        PartialQuantity := LibraryRandom.RandDec(100, 2);  // Use Random for Partial Quantity.
        Quantity := PartialQuantity + LibraryRandom.RandDec(100, 2);  // Use Random for Quantity required for test.
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item), Quantity, Bin."Location Code", Bin.Code);
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item2), Quantity, Bin."Location Code", Bin.Code);
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Item2."No.", Bin."Location Code", Bin.Code, Quantity);
        CreateAndPostInventoryPick(SalesHeader."No.", Bin."Location Code", PartialQuantity);

        // [WHEN] Post Inventory Pick.
        PostInventoryPick(SalesHeader."No.", false);

        // [THEN] Verify Quantity Shipped on Sales Line.
        VerifySalesLine(SalesHeader."No.", Item."No.", Quantity);
        VerifySalesLine(SalesHeader."No.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeOnWarehouseRegisterAfterRegisterWarehouseJournalLine()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Test and verify Source Code on Warehouse Register after register Warehouse Journal Line.

        // [GIVEN] Create Warehouse Journal Line with Item Tracking Line.
        Initialize;
        CreateWarehouseJournalLineWithItemTrackingLines(WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");

        // [WHEN] Register Warehouse Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);

        // [THEN] Verify Source Code on Warehouse Register.
        SourceCodeSetup.Get;
        VerifyWarehouseRegister(WarehouseJournalLine."Journal Batch Name", SourceCodeSetup."Whse. Item Journal");
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeOnWarehouseRegisterAfterCalculateAndPostWarehouseAdjustment()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ItemJournalBatchName: Code[10];
    begin
        // Test and verify Source Code on Warehouse Register after calculate and post Warehouse Adjustment.

        // [GIVEN] Create Warehouse Journal Line with Item Tracking Line. Register Warehouse Journal Line.
        Initialize;
        CreateWarehouseJournalLineWithItemTrackingLines(WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);

        // [WHEN] Calculate and post Warehouse Adjustment.
        ItemJournalBatchName := CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");

        // [THEN] Verify Source Code on Warehouse Register.
        SourceCodeSetup.Get;
        VerifyWarehouseRegister(ItemJournalBatchName, SourceCodeSetup."Item Journal");
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesHandler,DateCompressWarehouseEntriesHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SourceCodeOnWarehouseRegisterAfterDateCompressWarehouseEntries()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseRegister: Record "Warehouse Register";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Test and verify Source Code on Warehouse Register after running Date Compress Warehouse Entries.

        // [GIVEN] Create Warehouse Journal Line with Item Tracking Line. Register Warehouse Journal Line. Calculate and post Warehouse Adjustment.
        Initialize;
        CreateWarehouseJournalLineWithItemTrackingLines(WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);
        CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");

        // [WHEN] Run Date Compress Warehouse Entries.
        RunDateCompressWhseEntries(WarehouseJournalLine."Item No.");

        // [THEN] Verify Source Code on Warehouse Register.
        SourceCodeSetup.Get;
        WarehouseRegister.FindLast;
        WarehouseRegister.TestField("Source Code", SourceCodeSetup."Compress Whse. Entries");
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesHandler,DateCompressWarehouseEntriesHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteEmptyWarehouseRegistersReport()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalBatchName: Code[10];
    begin
        // Test and verify functionality of Delete Empty Warehouse Registers report.

        // [GIVEN] Create Warehouse Journal Line with Item Tracking Line. Register Warehouse Journal Line. Calculate and post Warehouse Adjustment. Run Date Compress Warehouse Entries.
        Initialize;
        CreateWarehouseJournalLineWithItemTrackingLines(WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);
        ItemJournalBatchName := CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");
        RunDateCompressWhseEntries(WarehouseJournalLine."Item No.");

        // [WHEN] Run Delete Empty Warehouse Registers.
        LibraryWarehouse.DeleteEmptyWhseRegisters;

        // [THEN] Verify Empty Warehouse Registers must not exist.
        Assert.IsFalse(FindWarehouseRegister(WarehouseJournalLine."Journal Batch Name"), StrSubstNo(EmptyWarehouseRegisterMustNotExist));
        Assert.IsFalse(FindWarehouseRegister(ItemJournalBatchName), StrSubstNo(EmptyWarehouseRegisterMustNotExist));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseItemJournalBatchPost()
    var
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Post Warehouse Item Journal Batch and Verify Warehouse Entries.

        // [GIVEN] Create Full Warehouse Setup.
        Initialize;
        CreateFullWarehouseSetup(Location);
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);

        // Create Warehouse Item Journal.
        FindBin(Bin, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));  // Use randin value for Quantity.

        // [WHEN] Post Warehouse Journal Batch.
        Commit;  // Commit required for Batch Post.
        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-B.Register", WarehouseJournalBatch);

        // [THEN] Warehouse Entries for Posted Warehouse Journal Line.
        VerifyWarehouseEntries(WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", WarehouseJournalLine.Quantity);
        VerifyWarehouseEntries(WarehouseJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", -WarehouseJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationByPage()
    var
        TempLocation: Record Location temporary;
        LocationCode: Code[10];
    begin
        // Create Location by Page and verify it.

        // Setup.
        Initialize;

        // [WHEN] Create New Location by Page.
        TempLocation.Init;
        TempLocation.Validate(Code, LibraryUtility.GenerateRandomCode(TempLocation.FieldNo(Code), DATABASE::Location));
        TempLocation.Insert(true);

        LocationCode := CreateLocationByPage(TempLocation);

        // [THEN] Verify Location Code.
        VerifyLocation(TempLocation, LocationCode);
    end;

    [Test]
    [HandlerFunctions('CalculateBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinWithOutTemplateCode()
    var
        Location: Record Location;
        BinCreationWorksheet: TestPage "Bin Creation Worksheet";
    begin
        // Run Calculate Bins report without Bin template Code and handle error dialog.

        // [GIVEN] Create Location and Open Bin Creation Worksheet.
        Initialize;
        CreateAndUpdateLocationWithSetup(Location, true, false, false);
        BinTemplateCode := '';  // BinTemplateCode used in CalculateBinRequestPageHandler.
        BinCreationWorksheet.OpenEdit;

        // [WHEN] Run Calculate Bins report without Bin Template Code.
        asserterror BinCreationWorksheet.CalculateBins.Invoke;

        // [THEN] Error Message.
        Assert.AreEqual(StrSubstNo(BinTemplateCodeError), GetLastErrorText, UnknownFailure);
    end;

    [Test]
    [HandlerFunctions('CalculateBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinWithTemplateCode()
    var
        BinCreationWorksheet: TestPage "Bin Creation Worksheet";
    begin
        // Run Calculate Bins report with Bin template Code and Verify Bin Code is created in Bin Creation Worksheet.

        // [GIVEN] Create Location and Open Bin Creation Worksheet.
        Initialize;
        CreateLocationAndBinTemplate;
        FillBinCodeValue;  // Fill RackNo, SectionNo, LevelNo used in CalculateBinRequestPageHandler.
        BinCreationWorksheet.OpenEdit;

        // [WHEN] Run Calculate Bins report with Bin Template Code.
        BinCreationWorksheet.CalculateBins.Invoke;

        // [THEN] Bin Code is Created in Bin Creation Worksheet.
        VerifyBinCode(BinCreationWorksheet);
    end;

    [Test]
    [HandlerFunctions('CalculateBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinWithFieldSeparator()
    var
        BinCreationWorksheet: TestPage "Bin Creation Worksheet";
    begin
        // Run Calculate Bins report with Field Separator and Verify Bin Code is created in Bin Creation Worksheet.

        // [GIVEN] Create Location and Open Bin Creation Worksheet.
        Initialize;
        CreateLocationAndBinTemplate;
        FillBinCodeValue;  // Fill RackNo, SectionNo, LevelNo used in CalculateBinRequestPageHandler.
        FieldSeparator := Format(LibraryRandom.RandInt(5));  // Field Separator used in CalculateBinRequestPageHandler.
        BinCreationWorksheet.OpenEdit;

        // [WHEN] Run Calculate Bins report with Field Seprator.
        BinCreationWorksheet.CalculateBins.Invoke;

        // [THEN] Bin Code is Created on Bin Creation Worksheet.
        VerifyBinCode(BinCreationWorksheet);
    end;

    [Test]
    [HandlerFunctions('CalculateBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinWithBlankRackNo()
    var
        BinCreationWorksheet: TestPage "Bin Creation Worksheet";
    begin
        // Run Calculate Bins report with blank Rack From No. and Rack To No. as Blank and Verify Bin Code is not created on Bin Creation Worksheet.

        // [GIVEN] Create Location and Open Bin Creation Worksheet.
        Initialize;
        CreateLocationAndBinTemplate;
        FillBinCodeValue;  // Fill RackNo, SectionNo, LevelNo used in CalculateBinRequestPageHandler.
        RackNo := '';  // Set Rack No as Blank.
        BinCreationWorksheet.OpenEdit;

        // [WHEN] Run Calculate Bins report with blank Rack From No. and Rack To No.
        BinCreationWorksheet.CalculateBins.Invoke;

        // [THEN] Bin Code is not created on Bin Creation Worksheet.
        Assert.IsFalse(BinCreationWorksheet.First, BinCodeNotExistError);
    end;

    [Test]
    [HandlerFunctions('CalculateBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinWithMaximumLevel()
    var
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
        LibraryUtility: Codeunit "Library - Utility";
        BinCreationWorksheet: TestPage "Bin Creation Worksheet";
    begin
        // Calculate Bin when Level is greater than the maximum length of Bin Code and handle error dialog.

        // [GIVEN] Create Location and Open Bin Creation Worksheet.
        Initialize;
        CreateLocationAndBinTemplate;

        // Set Value for RackNo SectionNo and LevelNo used in CalculateBinRequestPageHandler.
        RackNo := BinTemplateCode;
        SectionNo := BinTemplateCode;
        LevelNo := BinTemplateCode;
        BinCreationWorksheet.OpenEdit;

        // [WHEN] Run Calculate Bins report.
        asserterror BinCreationWorksheet.CalculateBins.Invoke;

        // [THEN] Error Message.
        Assert.AreEqual(
          StrSubstNo(
            BinCodeLengthError, BinCreationWorksheetLine.FieldCaption("Bin Code"),
            LibraryUtility.GetFieldLength(DATABASE::"Bin Creation Worksheet Line", BinCreationWorksheetLine.FieldNo("Bin Code"))),
          GetLastErrorText, UnknownFailure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseGetBinContentReportFromItemJournalLine()
    var
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Test the functionality of Warehouse Get Bin Content Report run from Item Journal line.

        // [GIVEN] Create Location with Zones and Bins. Add Inventory on Location Bin to update the Bin Content.
        Initialize;
        CreateLocationAndFindBin(Bin, false);
        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random value for Quantity.
        CreateAndPostItemJournalLine(LibraryInventory.CreateItem(Item), Quantity, Bin."Location Code", Bin.Code);

        // [WHEN] Run Warehouse Get Bin Content report from Item Journal line.
        RunWarehouseGetBinContentReportFromItemJournalLine(Bin."Location Code", Item."No.", Bin.Code);

        // [THEN] Verify that Bin Content lines gets copied on Item Journal line.
        VerifyItemJournalLine(Item."No.", Bin."Location Code", Bin.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure WarehouseGetBinContentReportFromTransferOrder()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Test the functionality of Warehouse Get Bin Content Report run from Transfer Order.

        // [GIVEN] Create Location with Bins. Post Item Journal on Location Bin with Item Tracking. Create a Transfer Order.
        Initialize;
        CreateLocationAndFindBin(Bin, true);
        CreateItemWithItemTrackingCode(Item, true, false);
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Quantity, Bin."Location Code", Bin.Code);
        LibraryWarehouse.CreateTransferHeader(
          TransferHeader, Bin."Location Code", LibraryWarehouse.CreateLocation(Location), CreateInTransitLocation);

        // [WHEN] Run Warehouse Get Bin Content report from Transfer Order.
        LibraryWarehouse.GetBinContentTransferOrder(TransferHeader, Bin."Location Code", Item."No.", Bin.Code);

        // [THEN] Verify that Bin Content lines gets copied on Transfer Order line.
        VerifyTransferOrderLine(TransferHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BinContentFromBinContentCreationWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
    begin
        // Test that Bin Content is created by invoking Create Bin Content on Bin Content Creation Worksheet page.

        // [GIVEN] Create Location with Zones and Bins. Find Bin and create an Item.
        Initialize;
        CreateFullWarehouseSetup(Location);
        FindBin(Bin, Location.Code);
        LibraryInventory.CreateItem(Item);

        // [WHEN] Set values on Bin Content Creation Worksheet page and invoke Create Bin Content on the page.
        CreateBinContentFromWorksheetPage(Bin.Code, Item."No.");

        // [THEN] Bin Content has been created for the Bin.
        VerifyBinContent(Location.Code, Bin."Zone Code", Bin.Code, Item."No.");
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler')]
    [Scope('OnPrem')]
    procedure PickWorksheet()
    var
        SalesLine: Record "Sales Line";
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        // Test and verify Get Warehouse Documents functionality on Pick Worksheet.

        // [GIVEN] Create initial setup for Pick Worksheet.
        Initialize;
        CreateInitialSetupForPickWorksheet(SalesLine);

        // [WHEN] Invoke Get Warehouse Documents from Pick Worksheet.
        PickWorksheet.OpenEdit;
        PickWorksheet."Get Warehouse Documents".Invoke;

        // [THEN] Verify Pick Worksheet Line.
        VerifyPickWorksheet(SalesLine);
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler,CreatePickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheet()
    var
        SalesLine: Record "Sales Line";
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        // Test and verify Create Pick functionality on Pick Worksheet.

        // [GIVEN] Create initial setup for Pick Worksheet. Invoke Get Warehouse Documents from Pick Worksheet.
        Initialize;
        CreateInitialSetupForPickWorksheet(SalesLine);
        PickWorksheet.OpenEdit;
        PickWorksheet."Get Warehouse Documents".Invoke;

        // [WHEN] Invoke Create Pick from Pick Worksheet.
        Commit;  // Commit required.
        PickWorksheet.CreatePick.Invoke;

        // [THEN] Verify Warehouse Activity Line.
        VerifyWarehouseActivityLine(SalesLine."Document No.", SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesHandler,ItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure WarehousePick()
    var
        SalesLine: Record "Sales Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Test and verify functionality of Warehouse Pick with Warehouse Tracking Lines.

        // [GIVEN] Create and register Warehouse Journal Line with Item Tracking Lines. Calculate and post Warehouse Adjustment. Create and release Warehouse Shipment from Sales Order.
        Initialize;
        CreateWarehouseJournalLineWithItemTrackingLines(WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);
        CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");

        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateAndReleaseSalesOrderWithItemTrackingLines(
          SalesLine, true, WorkDate, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code", '', WarehouseJournalLine.Quantity);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesLine);

        // [WHEN] Create Warehouse Pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Verify Warehouse Activity Line.
        VerifyWarehouseActivityLine(SalesLine."Document No.", SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PutAwaySelectionHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayWorksheet()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
    begin
        // Create Warehouse Put Away Worksheet.

        // [GIVEN] Create Full Warehouse Setup. Create Warehouse Receipt from Purchase Order.
        Initialize;
        CreateAndUpdateFullWareHouseSetup(Location);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseLine, Location.Code);

        // [WHEN] Invoke Get Warehouse Documents from Put Away Worksheet.
        PutAwayWorksheet.OpenEdit;
        PutAwayWorksheet.GetWarehouseDocuments.Invoke;

        // [THEN] Verify Worksheet Line.
        VerifyPutAwayWorksheet(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PutAwaySelectionHandler,CreatePutAwayHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromPutAwayWorksheet()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
    begin
        // Create Put Away from Put Away Worksheet.

        // [GIVEN] Create Full Warehouse Setup. Create Warehouse Receipt from Purchase Order. Create Worksheet Line.
        Initialize;
        CreateAndUpdateFullWareHouseSetup(Location);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseLine, Location.Code);
        PutAwayWorksheet.OpenEdit;
        PutAwayWorksheet.GetWarehouseDocuments.Invoke;

        // [WHEN] Invoke Create Put Away from Pick Worksheet.
        Commit;  // Commit required.
        PutAwayWorksheet.CreatePutAway.Invoke;

        // [THEN] Verify Put Away Worksheet Line.
        VerifyWarehouseActivityLine(PurchaseLine."Document No.", PurchaseLine."No.", PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEFOPickEnabledIfBinMandatoryAndPickRequiredUT()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] [FEFO] [Bin Mandatory] [UI]
        // [SCENARIO 372104] "Pick According to FEFO" on Location Card should be enabled while "Require Pick" = Yes,"Bin Mandatory" = Yes

        // [GIVEN] Open Location Card
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] "Require Pick" and "Bin Mandatory" are set to TRUE
        LocationCard.Trap;
        LocationCard.OpenEdit;
        LocationCard.GotoRecord(Location);
        LocationCard."Require Pick".SetValue(true);
        LocationCard."Bin Mandatory".SetValue(true);

        // [THEN] "Pick According to FEFO" is enabled
        Assert.IsTrue(
          LocationCard."Pick According to FEFO".Enabled,
          StrSubstNo(ShouldBeTxt, LocationCard."Pick According to FEFO".Caption, EnabledTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEFOPickDisabledIfBinMandatoryAndNotPickRequiredUT()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] [FEFO] [Bin Mandatory] [UI]
        // [SCENARIO 372104] "Pick According to FEFO" on Location Card should be disabled while "Require Pick" = No,"Bin Mandatory" = Yes

        // [GIVEN] Open Location Card
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] "Require Pick" is set to FALSE, "Bin Mandatory" is set to TRUE
        LocationCard.Trap;
        LocationCard.OpenEdit;
        LocationCard.GotoRecord(Location);
        LocationCard."Bin Mandatory".SetValue(true);

        // [THEN] "Pick According to FEFO" is disabled
        Assert.IsFalse(
          LocationCard."Pick According to FEFO".Enabled,
          StrSubstNo(ShouldBeTxt, LocationCard."Pick According to FEFO".Caption, DisabledTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEFOPickDisabledIfNotBinMandatoryAndPickRequiredUT()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] [FEFO] [Bin Mandatory] [UI]
        // [SCENARIO 372104] "Pick According to FEFO" on Location Card should be disabled while "Require Pick" = Yes,"Bin Mandatory" = No

        // [GIVEN] Open Location Card
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] "Require Pick" is set to TRUE, "Bin Mandatory" is set to FALSE
        LocationCard.Trap;
        LocationCard.OpenEdit;
        LocationCard.GotoRecord(Location);
        LocationCard."Require Pick".SetValue(true);

        // [THEN] "Pick According to FEFO" is disabled
        Assert.IsFalse(
          LocationCard."Pick According to FEFO".Enabled,
          StrSubstNo(ShouldBeTxt, LocationCard."Pick According to FEFO".Caption, DisabledTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEFOPickDisabledIfNotBinMandatoryAndNotPickRequiredUT()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] [FEFO] [Bin Mandatory] [UI]
        // [SCENARIO 372104] "Pick According to FEFO" on Location Card should be disabled while "Require Pick" = No,"Bin Mandatory" = No

        // [GIVEN] Open Location Card
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] "Require Pick" is set to FALSE, "Bin Mandatory" is set to FALSE
        LocationCard.Trap;
        LocationCard.OpenEdit;
        LocationCard.GotoRecord(Location);

        // [THEN] "Pick According to FEFO" is disabled
        Assert.IsFalse(
          LocationCard."Pick According to FEFO".Enabled,
          StrSubstNo(ShouldBeTxt, LocationCard."Pick According to FEFO".Caption, DisabledTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvtPutAwayCanBeDeletedWhenBinNotMandatoryOnLocation()
    var
        Location: Record Location;
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
    begin
        // [FEATURE] [Inventory Put-Away] [Bin Mandatory] [UT]
        // [SCENARIO] Posted inventory put-away can be deleted if bin is not mandatory on location.
        Initialize;

        // [GIVEN] Posted inventory put-away on location with bin not mandatory.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        MockPostedInvtPutAway(PostedInvtPutAwayHeader, Location.Code);

        // [WHEN] Delete posted inventory put-away.
        PostedInvtPutAwayHeader.Delete(true);

        // [THEN] Delete succeeded.
        PostedInvtPutAwayHeader.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(PostedInvtPutAwayHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvtPutAwayCannotBeDeletedWhenBinMandatoryOnLocation()
    var
        Location: Record Location;
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
    begin
        // [FEATURE] [Inventory Put-Away] [Bin Mandatory] [UT]
        // [SCENARIO] Posted inventory put-away cannot be deleted if bin is mandatory on location.
        Initialize;

        // [GIVEN] Posted inventory put-away on location with mandatory bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        MockPostedInvtPutAway(PostedInvtPutAwayHeader, Location.Code);

        // [WHEN] Delete posted inventory put-away.
        asserterror PostedInvtPutAwayHeader.Delete(true);

        // [THEN] Delete failed.
        Assert.ExpectedError(BinMandatoryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCreatingStockkeepingUnitValidatePhysInvtCountingPeriodCode()
    var
        Location: Record Location;
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        CreatePerOption: Option Location,Variant,"Location & Variant";
    begin
        // [FEATURE] [Stockkeeping Unit] [Physical Inventory] [Counting Period]
        // [SCENARIO 208608] On creating "Stockkeeping Unit" the field "Phys Invt Counting Period Code" is validated by the same way as on validating the same in Item table.
        Initialize;

        // [GIVEN] Location "L";
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] "Phys. Invt. Counting Period" "P";
        CreatePhysInvtCountingPeriod(PhysInvtCountingPeriod);

        // [GIVEN] Item "I", "I"."Phys Invt Counting Period Code" = "P".Code;
        LibraryInventory.CreateItem(Item);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        Item.Modify(true);

        // [WHEN] Create Stockkeeping Unit for "I" per Location
        LibraryInventory.CreateStockKeepingUnit(Item, CreatePerOption::Location, false, false);

        // [THEN] Stockkeeping Unit for "I" and "L" has the same values of the fields "Phys Invt Counting Period Code", "Last Counting Period Update", "Next Counting Start Date" and "Next Counting End Date" as "I".
        StockkeepingUnit.Get(Location.Code, Item."No.", '');
        StockkeepingUnit.TestField("Phys Invt Counting Period Code", Item."Phys Invt Counting Period Code");
        StockkeepingUnit.TestField("Last Counting Period Update", Item."Last Counting Period Update");
        StockkeepingUnit.TestField("Next Counting Start Date", Item."Next Counting Start Date");
        StockkeepingUnit.TestField("Next Counting End Date", Item."Next Counting End Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCreatingStockkeepingUnitValidatePhysInvtCountingPeriodCodeWhenBlank()
    var
        Location: Record Location;
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        CreatePerOption: Option Location,Variant,"Location & Variant";
    begin
        // [FEATURE] [Stockkeeping Unit] [Physical Inventory] [Counting Period]
        // [SCENARIO 208608] On creating "Stockkeeping Unit" the field "Phys Invt Counting Period Code" remains blank if the field "Phys Invt Counting Period Code" of Item is blank, no dialogue occurs.
        Initialize;

        // [GIVEN] Location "L";
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Item "I";
        LibraryInventory.CreateItem(Item);

        // [WHEN] Create Stockkeeping Unit for "I" per Location
        LibraryInventory.CreateStockKeepingUnit(Item, CreatePerOption::Location, false, false);

        // [THEN] Stockkeeping Unit for "I" and "L" has the blank values of the fields "Phys Invt Counting Period Code", "Last Counting Period Update", "Next Counting Start Date" and "Next Counting End Date".
        StockkeepingUnit.Get(Location.Code, Item."No.", '');
        StockkeepingUnit.TestField("Phys Invt Counting Period Code", '');
        StockkeepingUnit.TestField("Last Counting Period Update", 0D);
        StockkeepingUnit.TestField("Next Counting Start Date", 0D);
        StockkeepingUnit.TestField("Next Counting End Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQuantityToCreateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentDoesNotInsertItemTrackingWhenAvailableSerialNoCannotBeDefined()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        TransferToLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TransferHeader: Record "Transfer Header";
        ReservationEntry: Record "Reservation Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Get Bin Content] [Transfer Order] [Item Tracking]
        // [SCENARIO 223887] Transfer Line populated by invoking "Get Bin Content" function does not receive any item tracking when there is uncertainty which serial no. is available.
        Initialize;

        // [GIVEN] WMS location "L" with mandatory shipment and pick.
        CreateAndUpdateLocationWithSetup(Location, true, true, true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item "I" with serial no. tracking.
        CreateItemWithItemTrackingCode(Item, true, false);

        // [GIVEN] X serial nos. "S1".."SX" of "I" are purchased and put-away.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, true, Item."No.", Location.Code, Bin.Code);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.");

        // [GIVEN] Sales order for "Y" ("Y" < "X") pcs of "I". No item tracking is selected on the sales line.
        // [GIVEN] Warehouse shipment and pick are created for the order.
        Qty := LibraryRandom.RandInt(5);
        CreateAndReleaseSalesOrderWithItemTrackingLines(SalesLine, false, WorkDate, Item."No.", Location.Code, Bin.Code, Qty);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesLine);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Transfer Order from "L" to another location.
        LibraryWarehouse.CreateTransferHeader(
          TransferHeader, Location.Code, LibraryWarehouse.CreateLocation(TransferToLocation), CreateInTransitLocation);

        // [WHEN] Run "Get Bin Content" filtered by location "L" and item "I" to create Transfer Order lines.
        LibraryWarehouse.GetBinContentTransferOrder(TransferHeader, Location.Code, Item."No.", '');

        // [THEN] Transfer Order Line for "X" - "Y" pcs of "I" is created.
        VerifyTransferOrderLine(TransferHeader."No.", Item."No.", PurchaseLine.Quantity - Qty);

        // [THEN] No item tracking is assigned to the line.
        ReservationEntry.Init;
        ReservationEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ReservationEntry);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyFirstBinIsFixedAndDefaultWhenCreateStockNonWMS()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        BinCode: array[2] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bin Content]
        // [SCENARIO 303213] Only first Bin is Fixed and Default when Item stock is created in non-WMS location with several Bins
        Initialize;

        // [GIVEN] Location with disabled Directed Put-away and Pick and two Bins "B1" and "B2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        for Index := 1 to ArrayLen(BinCode) do begin
            LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');
            BinCode[Index] := Bin.Code;
        end;

        // [GIVEN] Two Positive Adjustment Item Journal Lines for same Item, Location and Bins "B1" and "B2"
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo, Location.Code, BinCode[1], LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemJournalLine."Item No.", Location.Code, BinCode[2], LibraryRandom.RandInt(10));

        // [WHEN] Post Item Journal
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Bin Content for Bin Code "B1" has both Fixed and Default = TRUE
        VerifyBinContentDefaultAndFixed(Location.Code, BinCode[1], true, true);

        // [THEN] Bin Content for Bin Code "B2" has both Fixed and Default = FALSE
        VerifyBinContentDefaultAndFixed(Location.Code, BinCode[2], false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure WarrantyDateDefinedInReservationEntryCopiedToServiceItem()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ServiceItemGroup: Record "Service Item Group";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceItem: Record "Service Item";
        WarrantyDateFormula: DateFormula;
        DefaultWarrantyDuration: DateFormula;
        LotNo: Code[50];
        Qty: Integer;
        WarrantyStartDate: Date;
    begin
        // [FEATURE] [Warranty Date] [Item Tracking] [Service]
        // [SCENARIO 312703] Warranty Date specified via Lot Item Tracking is propagated to Service Item Warranty Starting Dates when Sales Order is posted
        // [SCENARIO 312703] Warranty Ending Date (Parts) is calculated via Warranty Date Formula specified in Item Tracking
        // [SCENARIO 312703] Warranty Ending Date (Labor) is calculated via Default Warranty Duration specified in Service Mgt. Setup
        Initialize;
        Evaluate(WarrantyDateFormula, '<2Y>');
        Evaluate(DefaultWarrantyDuration, '<3Y>');
        LotNo := LibraryUtility.GenerateGUID;
        Qty := LibraryRandom.RandInt(10);
        WarrantyStartDate := CalcDate('<1M>', WorkDate);

        // [GIVEN] Service Mgt. Setup had Default Warranty Duration = 2Y
        SetServiceSetupDefaultWarrantyDuration(DefaultWarrantyDuration);

        // [GIVEN] Item Tracking Code with Lot Sales Tracking and Man. Warranty Date Entry Reqd. enabled, Warranty Date Formula = 1Y
        CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        ItemTrackingCode.Validate("Man. Warranty Date Entry Reqd.", true);
        ItemTrackingCode.Validate("Warranty Date Formula", WarrantyDateFormula);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Service Item Group with Create Service Item enabled
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);

        // [GIVEN] Item with Item Tracking Code and Service Item Group had stock of 10 PCS
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Service Item Group", ServiceItemGroup.Code);
        Item.Modify(true);
        PostItemJournalLineWithLotTracking(Item."No.", LotNo, Qty);

        // [GIVEN] Sales Order with 10 PCS of Item and Posting Date 1/1/2019
        // [GIVEN] Item Tracking was defined with Warranty Date 1/2/2019
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        EnqueueTrackingLotAndQty(ItemTrackingMode::AssignLotAndQty, LotNo, Qty);
        SalesLine.OpenItemTrackingLines;
        ModifyReservationEntryWarrantyDate(Item."No.", WarrantyStartDate);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Service Item is created with Warranty Starting Date (Parts) = Warranty Starting Date (Labor)
        // [THEN] Warranty Ending Date (Parts) = 1/2/2020 <> Warranty Ending Date (Labor) = 1/2/2021
        with ServiceItem do begin
            SetRange("Item No.", Item."No.");
            FindFirst;
            TestField("Warranty Starting Date (Parts)", WarrantyStartDate);
            TestField("Warranty Starting Date (Labor)", "Warranty Starting Date (Parts)");
            TestField("Warranty Ending Date (Parts)", CalcDate(WarrantyDateFormula, WarrantyStartDate));
            TestField("Warranty Ending Date (Labor)", CalcDate(DefaultWarrantyDuration, WarrantyStartDate));
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure WarrantyDateDefinedInDropShipPurchCopiedToServiceItem()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceItemGroup: Record "Service Item Group";
        Item: Record Item;
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [Warranty Date] [Service] [Drop Shipment]
        // [SCENARIO 312841] Warranty Date in Service Item is propagated from Purchase Order Posting Date
        // [SCENARIO 312841] When Sales Order has Posting Date <blank> (Sales & Receivables Setup must have Default Posting Date = "No Date")
        // [SCENARIO 312841] and Drop Shipment is used for this Sales Order
        Initialize;

        // [GIVEN] Sales & Receivables Setup had Default Posting Date = "No Date"
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Default Posting Date", SalesReceivablesSetup."Default Posting Date"::"No Date");
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Service Item Group with Create Service Item enabled
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);

        // [GIVEN] Item with Service Item Group
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", ServiceItemGroup.Code);
        Item.Modify(true);

        // [GIVEN] Purchasing Code with Drop Shipment enabled
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);

        // [GIVEN] Sales Order with 10 PCS of Item and Purchasing Code and Posting Date = <blank> (as Default Posting Date was No Date)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);

        // [GIVEN] Purchase Order was created for Sales Order with Posting Date = 1/1/2021
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        // [WHEN] Post Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Service Item is created with Warranty Starting Date (Parts) = Warranty Starting Date (Labor) = 1/1/2021
        with ServiceItem do begin
            SetRange("Item No.", Item."No.");
            FindFirst;
            TestField("Warranty Starting Date (Parts)", PurchaseHeader."Posting Date");
            TestField("Warranty Starting Date (Labor)", "Warranty Starting Date (Parts)");
        end;
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse IV");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        // Clear global variables.
        Clear(BinTemplateCode);
        Clear(RackNo);
        Clear(SectionNo);
        Clear(LevelNo);
        Clear(FieldSeparator);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse IV");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        NoSeriesSetup;
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse IV");
    end;

    local procedure SetServiceSetupDefaultWarrantyDuration(DefaultWarrantyDuration: DateFormula)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get;
        ServiceMgtSetup.Validate("Default Warranty Duration", DefaultWarrantyDuration);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure PostItemJournalLineWithLotTracking(ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        EnqueueTrackingLotAndQty(ItemTrackingMode::AssignLotAndQty, LotNo, Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        ModifyReservationEntryWarrantyDate(ItemNo, WorkDate);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure EnqueueTrackingLotAndQty(ItemTrackingMode: Integer; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure ModifyReservationEntryWarrantyDate(ItemNo: Code[20]; WarrantyDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Warranty Date", WarrantyDate);
    end;

    local procedure CalculateAndPostWarehouseAdjustment(ItemNo: Code[20]): Code[10]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalBatch.Name);
    end;

    local procedure CreatePhysInvtCountingPeriod(var PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period")
    begin
        PhysInvtCountingPeriod.Init;
        PhysInvtCountingPeriod.Validate(
          Code, LibraryUtility.GenerateRandomCode(PhysInvtCountingPeriod.FieldNo(Code), DATABASE::"Phys. Invt. Counting Period"));
        PhysInvtCountingPeriod.Validate(
          Description, LibraryUtility.GenerateRandomText(MaxStrLen(PhysInvtCountingPeriod.Description)));
        PhysInvtCountingPeriod.Validate("Count Frequency per Year", LibraryRandom.RandIntInRange(7, 11));
        PhysInvtCountingPeriod.Insert(true);
    end;

    local procedure CreateAndPostInventoryPick(SourceNo: Code[20]; LocationCode: Code[10]; QtyToHandle: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseActivityHeader."Source Document"::"Sales Order", SourceNo, false, true, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindSet;
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next = 0;
        PostInventoryPick(SourceNo, false);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithItemTracking(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);  // Execute ItemTrackingLinesHandler for assigning Item Tracking lines.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostMultiplePurchaseOrders(var PurchaseOrderNo: array[5] of Code[20]; var PurchaseReceiptNo: array[5] of Code[20]; LoopCount: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        Counter: Integer;
    begin
        CreateAndUpdateLocationWithSetup(Location, true, false, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);  // Find Bin of Index 1.
        CreateItemWithItemTrackingCode(Item, true, false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        for Counter := 1 to LoopCount do begin
            Clear(PurchaseHeader);
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
            CreateAndUpdatePurchaseLine(
              PurchaseLine, PurchaseHeader, LibraryRandom.RandInt(5), Item."No.", Bin."Location Code", Bin.Code);  // Integer Value required.
            PurchaseLine.OpenItemTrackingLines;
            PurchaseOrderNo[Counter] := PurchaseHeader."No.";
            PurchaseReceiptNo[Counter] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;
        exit(Item."No.");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, false, LibraryInventory.CreateItem(Item), LocationCode, '');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
    end;

    local procedure CreateAndReleasePurchaseOrderWithItemTrackingLines(var PurchaseLine: Record "Purchase Line"; IsTracking: Boolean; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateAndUpdatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryRandom.RandIntInRange(10, 20), ItemNo, LocationCode, BinCode);  // Integer Value required.
        if IsTracking then
            CreatePurchaseTrackingLine(PurchaseLine, WorkDate);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithItemTrackingLines(var SalesLine: Record "Sales Line"; IsTracking: Boolean; ExpirationDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
        if IsTracking then begin
            SalesLine.OpenItemTrackingLines;
            UpdateReservationEntry(SalesLine."No.", ExpirationDate);
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, LocationCode, BinCode, Quantity);
        CreateSalesLine(SalesLine, SalesHeader, ItemNo2, LocationCode, BinCode, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", SalesLine."Location Code");
        WarehouseShipmentHeader.FindFirst;
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndUpdateFullWareHouseSetup(var Location: Record Location)
    begin
        CreateFullWarehouseSetup(Location);
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);
    end;

    local procedure CreateAndUpdateLocationWithSetup(var Location: Record Location; BinMandatory: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, true, true, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
    end;

    local procedure CreateAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Quantity: Decimal; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);  // Integer Value required.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateBinContentFromWorksheetPage(BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContentCreationWorksheet: TestPage "Bin Content Creation Worksheet";
    begin
        BinContentCreationWorksheet.OpenEdit;
        BinContentCreationWorksheet."Bin Code".SetValue(BinCode);
        BinContentCreationWorksheet."Item No.".SetValue(ItemNo);
        BinContentCreationWorksheet.Fixed.SetValue(true);
        BinContentCreationWorksheet.CreateBinContent.Invoke;
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateInTransitLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Use As In-Transit", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateInitialSetupForPickWorksheet(var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);
        PostWarehouseReceipt(PurchaseLine."Document No.");
        RegisterWarehouseActivity(PurchaseLine."Document No.");
        CreateAndReleaseSalesOrderWithItemTrackingLines(
          SalesLine, false, WorkDate, PurchaseLine."No.", PurchaseLine."Location Code", '', PurchaseLine.Quantity);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesLine);
    end;

    local procedure CreateInitalSetupForWarehouse(var Bin: Record Bin; IsSerialNo: Boolean): Code[20]
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        Item: Record Item;
    begin
        CreateAndUpdateLocationWithSetup(Location, true, false, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);  // Find Bin of Index 1.
        CreateItemWithItemTrackingCode(Item, IsSerialNo, true);
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        exit(Item."No.");  // Create Item With Item Tracking Code.
    end;

    local procedure CreateInventoryPut(var PurchaseLine: Record "Purchase Line"; ManualAssignSerialNo: Boolean; ManualAssignLot: Boolean; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseLine."Document No.", true, false, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", LocationCode, PurchaseLine."Document No.",
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

        if ManualAssignSerialNo then
            UpdateWarehouseActivityLineForSerialNo(WarehouseActivityLine);

        if ManualAssignLot then
            UpdateWarehouseActivityLineForLotNo(WarehouseActivityLine);
    end;

    local procedure CreateInventoryPick(var SalesLine: Record "Sales Line"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesLine."Document No.", false, true, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SalesLine."Document No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure CreateInventoryPutWithSameLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        LotNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        ItemNo := CreateInitalSetupForWarehouse(Bin, false);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, true, ItemNo, Bin."Location Code", Bin.Code);
        ReopenPurchaseHeader(PurchaseHeader, PurchaseLine."Document Type", PurchaseLine."Document No.");
        LotNo := GetLotNoFromReservationLine(PurchaseLine."No.");
        // Create Second Line for Purhase Order.
        CreateAndUpdatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine."Bin Code");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreatePurchaseTrackingLine(PurchaseLine, WorkDate);  // Create Item Tracking Line for Second Line.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        UpdateReservationEntryForLotNo(ItemNo, LotNo);  // Update Same Lot No. for Bot the Purchase Lines.
        CreateInventoryPut(PurchaseLine, false, false, Bin."Location Code");  // Create Inventory Put with Expiration Date.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", Bin."Location Code",
          PurchaseLine."Document No.", WarehouseActivityLine."Action Type"::Place);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; ManExpirDateEntryReqd: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", ManExpirDateEntryReqd);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; IsSerialNo: Boolean; ManExpirDateEntryReqd: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // Create Item Tracking Code With Serial or Lot No.
        if IsSerialNo then
            CreateItemTrackingCode(ItemTrackingCode, false, true, ManExpirDateEntryReqd)
        else
            CreateItemTrackingCode(ItemTrackingCode, true, false, ManExpirDateEntryReqd);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Modify(true);
    end;

    local procedure CreateLocationAndBinTemplate()
    var
        Location: Record Location;
        BinTemplate: Record "Bin Template";
    begin
        CreateAndUpdateLocationWithSetup(Location, true, false, false);
        LibraryWarehouse.CreateBinTemplate(BinTemplate, Location.Code);
        BinTemplateCode := BinTemplate.Code;  // BinTemplateCode used in CalculateBinRequestPageHandler.
    end;

    local procedure CreateLocationAndFindBin(var Bin: Record Bin; RequireShipment: Boolean)
    var
        Location: Record Location;
    begin
        CreateAndUpdateLocationWithSetup(Location, true, false, RequireShipment);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);  // Find Bin of Index 1.
    end;

    local procedure CreateLocationByPage(Location: Record Location) LocationCode: Code[10]
    var
        LibraryUtility: Codeunit "Library - Utility";
        LocationPage: TestPage "Location Card";
    begin
        LocationPage.OpenNew;
        LocationPage.Code.SetValue(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location));
        LocationPage."Bin Mandatory".SetValue(Location."Bin Mandatory");
        LocationPage."Directed Put-away and Pick".SetValue(Location."Directed Put-away and Pick");
        LocationCode := LocationPage.Code.Value;
        LocationPage.OK.Invoke;
    end;

    local procedure CreatePickFromSalesOrder(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndUpdateLocationWithSetup(Location, false, false, true);
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", Location.Code);
        CreateAndReleaseSalesOrderWithItemTrackingLines(
          SalesLine, false, WorkDate, Item."No.", Location.Code, '', LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst;
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityNo(WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure CreatePurchaseTrackingLine(var PurchaseLine: Record "Purchase Line"; ExpirationDate: Date)
    begin
        PurchaseLine.OpenItemTrackingLines;
        UpdateReservationEntry(PurchaseLine."No.", ExpirationDate);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateStockkeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; ItemVariantCode: Code[10]; CreatePerOption: Option; ReplacePreviousSKUs: Boolean)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Variant Filter", ItemVariantCode);
        LibraryInventory.CreateStockKeepingUnit(Item, CreatePerOption, false, ReplacePreviousSKUs);
    end;

    local procedure CreateWarehouseJournalBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateFullWarehouseSetup(Location);
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseLine, false, LibraryInventory.CreateItem(Item), Location.Code, '');
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseJournalLineWithItemTrackingLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option)
    var
        Location: Record Location;
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
    begin
        CreateFullWarehouseSetup(Location);
        Location.Validate("Allow Breakbulk", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
        CreateItemWithItemTrackingCode(Item, false, false);
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);
        FindBin(Bin, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code", Bin.Code, EntryType, Item."No.", LibraryRandom.RandDec(100, 2));  // Use random Quantity.
        WarehouseJournalLine.OpenItemTrackingLines;
    end;

    local procedure CreateWhseLocations(var LocationCode: array[2] of Code[10])
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        i: Integer;
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll;

        for i := 1 to 2 do begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, i = 2);
            LocationCode[i] := Location.Code;
        end;
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindFirst;
    end;

    local procedure FillBinCodeValue()
    begin
        // Fill RackNo, SectionNo, LevelNo With Random Values.
        RackNo := Format(LibraryRandom.RandInt(5));
        SectionNo := Format(LibraryRandom.RandInt(5));
        LevelNo := Format(LibraryRandom.RandInt(5));
    end;

    local procedure FindStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ItemVariantCode: Code[10])
    begin
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Variant Code", ItemVariantCode);
        StockkeepingUnit.FindFirst;
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst;
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Option)
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst;
    end;

    local procedure FindWarehouseRegister(JournalBatchName: Code[10]): Boolean
    var
        WarehouseRegister: Record "Warehouse Register";
    begin
        WarehouseRegister.SetRange("Journal Batch Name", JournalBatchName);
        exit(WarehouseRegister.FindFirst);
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Option; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Option)
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet;
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindFirst;
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Option; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst;
    end;

    local procedure GetLotNoFromReservationLine(ItemNo: Code[20]): Code[20]
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst;
        exit(ReservationEntry."Lot No.");
    end;

    local procedure InsertThreeInternalPicks(LocationCode: Code[10]; var DocumentNo: array[3] of Code[20])
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        i: Integer;
    begin
        for i := 1 to 3 do
            with WhseInternalPickHeader do begin
                Init;
                "No." := LibraryUtility.GenerateGUID;
                "Location Code" := LocationCode;
                Insert;
                DocumentNo[i] := "No.";
            end;
    end;

    local procedure InsertThreeInternalPutAways(LocationCode: Code[10]; var DocumentNo: array[3] of Code[20])
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        i: Integer;
    begin
        for i := 1 to 3 do
            with WhseInternalPutAwayHeader do begin
                Init;
                "No." := LibraryUtility.GenerateGUID;
                "Location Code" := LocationCode;
                Insert;
                DocumentNo[i] := "No.";
            end;
    end;

    local procedure InsertThreeRegisteredWhseActivities(ActivityType: Option; LocationCode: Code[10]; var DocumentNo: array[3] of Code[20])
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        i: Integer;
    begin
        for i := 1 to 3 do
            with RegisteredWhseActivityHdr do begin
                Init;
                Type := ActivityType;
                "No." := LibraryUtility.GenerateGUID;
                "Location Code" := LocationCode;
                Insert;
                DocumentNo[i] := "No.";
            end;
    end;

    local procedure MockPostedInvtPutAway(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; LocationCode: Code[10])
    begin
        with PostedInvtPutAwayHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Posted Invt. Put-away Header");
            "Location Code" := LocationCode;
            Insert;
        end;
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PostInventoryPick(SourceNo: Code[20]; AsInvoice: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, AsInvoice);
    end;

    local procedure PostInventoryPut(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Put-away");
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);  // Post as Invoice.
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseReceiptWithPartialQuantityToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record "Purchase Line"): Decimal
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseLine."Document No.");
        WarehouseReceiptLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);  // Use PurchaseLine.Quantity / 2 for taking partial Quantity To Receive.
        WarehouseReceiptLine.Modify(true);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        exit(WarehouseReceiptLine."Qty. to Receive");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReopenPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; DocumentNo: Code[20])
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
    end;

    local procedure RunDateCompressWhseEntries(ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
        DateCompressWhseEntries: Report "Date Compress Whse. Entries";
    begin
        Commit;  // Commit required for batch job report.
        Clear(DateCompressWhseEntries);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        DateCompressWhseEntries.SetTableView(WarehouseEntry);
        DateCompressWhseEntries.Run;
    end;

    local procedure RunDeleteRegisteredWarehouseDocumentReport(WarehouseActivityHeaderNo: Code[20])
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        DeleteRegisteredWhseDocs: Report "Delete Registered Whse. Docs.";
    begin
        Clear(DeleteRegisteredWhseDocs);
        Commit; // COMMIT is required to run the Report.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeaderNo);
        DeleteRegisteredWhseDocs.SetTableView(RegisteredWhseActivityHdr);
        DeleteRegisteredWhseDocs.Run;
    end;

    local procedure RunWarehouseGetBinContentReportFromItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Init;
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine."Posting Date" := WorkDate;
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);
    end;

    local procedure ShowRegisteredActivityDoc(ActivityType: Option; DocumentNo: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        LibraryVariableStorage.Enqueue(DocumentNo);
        RegisteredWhseActivityLine."Activity Type" := ActivityType;
        RegisteredWhseActivityLine."No." := DocumentNo;
        RegisteredWhseActivityLine.ShowRegisteredActivityDoc;
    end;

    local procedure ShowWhseDocFromActivityLine(WhseDocumentType: Option; WhseDocumentNo: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryVariableStorage.Enqueue(WhseDocumentNo);
        WhseActivityLine."Whse. Document Type" := WhseDocumentType;
        WhseActivityLine."Whse. Document No." := WhseDocumentNo;
        WhseActivityLine.ShowWhseDoc;
    end;

    local procedure ShowWhseDocFromRegisteredActivityLine(WhseDocumentType: Option; WhseDocumentNo: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        LibraryVariableStorage.Enqueue(WhseDocumentNo);
        RegisteredWhseActivityLine."Whse. Document Type" := WhseDocumentType;
        RegisteredWhseActivityLine."Whse. Document No." := WhseDocumentNo;
        RegisteredWhseActivityLine.ShowWhseDoc;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryUtility.GenerateGUID;  // Fix for Item Journal Posting creates a new Item Journal Batch.
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(10, 2));  // Taking random Quantity.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UpdateReservationEntryForLotNo(ItemNo: Code[20]; NewLotNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Lot No.", NewLotNo, true);
    end;

    local procedure UpdateUnitCostInItem(var Item: Record Item)
    begin
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Taking Random Unit Cost.
        Item.Modify(true);
    end;

    local procedure UpdateWarehouseActivityLineForLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.Validate("Lot No.", WarehouseActivityLine."Location Code");  // Value not important for test.
        WarehouseActivityLine.Validate("Expiration Date", WorkDate);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateWarehouseActivityLineForSerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        "Count": Integer;
    begin
        WarehouseActivityLine.FindSet;
        for Count := 1 to WarehouseActivityLine.Count do begin
            WarehouseActivityLine.Validate("Serial No.", Format(Count));
            WarehouseActivityLine.Validate("Expiration Date", WorkDate);
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.Next;
        end;
    end;

    local procedure VerifyBinCode(BinCreationWorksheet: TestPage "Bin Creation Worksheet")
    var
        BinCode: Code[62];
    begin
        BinCreationWorksheet.First;
        BinCode := RackNo + FieldSeparator + SectionNo + FieldSeparator + LevelNo;
        BinCreationWorksheet."Bin Code".AssertEquals(BinCode);
    end;

    local procedure VerifyBinContent(LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Zone Code", ZoneCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.FindFirst;
        BinContent.TestField("Item No.", ItemNo);
    end;

    local procedure VerifyBinContentDefaultAndFixed(LocationCode: Code[10]; BinCode: Code[20]; IsDefault: Boolean; IsFixed: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.FindFirst;
        BinContent.TestField(Default, IsDefault);
        BinContent.TestField(Fixed, IsFixed);
    end;

    local procedure VerifyPostedEntryAfterPostingPurchaseInvoice(PurchaseOrderNo: array[5] of Code[20]; PurchaseReceiptNo: array[5] of Code[20]; ItemNo: Code[20]; LoopCount: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        ValueEntry: Record "Value Entry";
        Counter: Integer;
    begin
        for Counter := 1 to LoopCount do begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo[Counter]);
            VerifyValueEntry(
              LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true), ValueEntry."Document Type"::"Purchase Invoice", ItemNo);
            VerifyValueEntry(PurchaseReceiptNo[Counter], ValueEntry."Document Type"::"Purchase Receipt", ItemNo);
            VerifyItemLedgerEntry(PurchaseReceiptNo[Counter], ItemNo);
        end;
    end;

    local procedure VerifyLocation(Location: Record Location; LocationCode: Code[20])
    var
        Location2: Record Location;
    begin
        Location2.Get(LocationCode);
        Location2.TestField("Bin Mandatory", Location."Bin Mandatory");
        Location2.TestField("Directed Put-away and Pick", Location."Directed Put-away and Pick");
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst;
        ItemJournalLine.TestField("Location Code", LocationCode);
        ItemJournalLine.TestField("Bin Code", BinCode);
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindSet;
        repeat
            ItemLedgerEntry.TestField("Item No.", ItemNo);
            ItemLedgerEntry.TestField(Quantity, 1);
            ItemLedgerEntry.TestField("Invoiced Quantity", 1);
        until ItemLedgerEntry.Next = 0;
    end;

    local procedure VerifyPickWorksheet(SalesLine: Record "Sales Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Item No.", SalesLine."No.");
        WhseWorksheetLine.FindFirst;
        WhseWorksheetLine.TestField(Quantity, SalesLine.Quantity);
        WhseWorksheetLine.TestField("Destination No.", SalesLine."Sell-to Customer No.");
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date; BinCode: Code[20])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", LocationCode);
        PostedInvtPickLine.FindFirst;
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Expiration Date", ExpirationDate);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPostedInventoryPutLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date; BinCode: Code[20])
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source No.", SourceNo);
        PostedInvtPutAwayLine.SetRange("Location Code", LocationCode);
        PostedInvtPutAwayLine.FindFirst;
        PostedInvtPutAwayLine.TestField("Item No.", ItemNo);
        PostedInvtPutAwayLine.TestField("Expiration Date", ExpirationDate);
        PostedInvtPutAwayLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPostedPurchaseInvoice(OrderNo: Code[20]; LocationCode: Code[10]; Bincode: Code[20]; Quantity: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst;

        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst;
        PurchInvLine.TestField("Location Code", LocationCode);
        PurchInvLine.TestField("Bin Code", Bincode);
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoice(OrderNo: Code[20]; LocationCode: Code[10]; Bincode: Code[20]; Quantity: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst;

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine.TestField("Location Code", LocationCode);
        SalesInvoiceLine.TestField("Bin Code", Bincode);
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPutAwayWorksheet(PurchaseLine: Record "Purchase Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Item No.", PurchaseLine."No.");
        WhseWorksheetLine.FindFirst;
        WhseWorksheetLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyQuantityHandledOnWarehouseActivityLine(SourceNo: Code[20]; LocationCode: Code[10]; QtyHandled: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        repeat
            WarehouseActivityLine.TestField("Qty. Handled", QtyHandled);
        until WarehouseActivityLine.Next = 0;
    end;

    local procedure VerifyReceiptLine(OrderNo: Code[20]; LocationCode: Code[10]; Bincode: Code[20]; Quantity: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst;
        PurchRcptLine.TestField("Location Code", LocationCode);
        PurchRcptLine.TestField("Bin Code", Bincode);
        PurchRcptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        TotalQuantity: Decimal;
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet;
        repeat
            TotalQuantity += ReservationEntry.Quantity;
        until ReservationEntry.Next = 0;
        Assert.AreEqual(Quantity, TotalQuantity, StrSubstNo(QuantityError, Quantity));
    end;

    local procedure VerifySalesLine(DocumentNo: Code[20]; No: Code[20]; QuantityShipped: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst;
        SalesLine.TestField("Quantity Shipped", QuantityShipped);
    end;

    local procedure VerifyShipmentLine(OrderNo: Code[20]; LocationCode: Code[10]; Bincode: Code[20]; Quantity: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst;
        SalesShipmentLine.TestField("Location Code", LocationCode);
        SalesShipmentLine.TestField("Bin Code", Bincode);
        SalesShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyStockkeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; ItemVariantCode: Code[10]; UnitCost: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockkeepingUnit(StockkeepingUnit, ItemNo, LocationCode, ItemVariantCode);
        StockkeepingUnit.TestField("Unit Cost", UnitCost);
    end;

    local procedure VerifyTransferOrderLine(TransferHeaderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferHeaderNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst;
        TransferLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; DocumentType: Option; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.FindSet;
        repeat
            ValueEntry.TestField("Item No.", ItemNo);
            ValueEntry.TestField("Valued Quantity", 1);
        until ValueEntry.Next = 0;
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet;
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, Quantity);
        until WarehouseActivityLine.Next = 0;
    end;

    local procedure VerifyWarehouseEntries(EntryType: Option; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst;
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        WarehouseJournalLine2: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine2.SetRange("Journal Template Name", WarehouseJournalLine."Journal Template Name");
        WarehouseJournalLine2.SetRange("Journal Batch Name", WarehouseJournalLine."Journal Batch Name");
        WarehouseJournalLine2.SetRange("Item No.", WarehouseJournalLine."Item No.");
        WarehouseJournalLine2.FindFirst;
    end;

    local procedure VerifyWarehouseRegister(JournalBatchName: Code[10]; SourceCode: Code[10])
    var
        WarehouseRegister: Record "Warehouse Register";
    begin
        WarehouseRegister.SetRange("Journal Batch Name", JournalBatchName);
        WarehouseRegister.FindFirst;
        WarehouseRegister.TestField("Source Code", SourceCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger of
            ItemTrackingMode::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke;
            ItemTrackingMode::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke;
            ItemTrackingMode::AssignLotAndQty:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
                end;
        end;
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateBinRequestPageHandler(var CalculateBins: TestRequestPage "Calculate Bins")
    begin
        CalculateBins.RackToNo.SetValue('');
        CalculateBins.SelectionToNo.SetValue('');
        CalculateBins.LevelToNo.SetValue('');
        CalculateBins.BinTemplateCode.SetValue(BinTemplateCode);
        CalculateBins.RackFromNo.SetValue(RackNo);
        CalculateBins.RackToNo.SetValue(RackNo);
        CalculateBins.SelectionFromNo.SetValue(SectionNo);
        CalculateBins.SelectionToNo.SetValue(SectionNo);
        CalculateBins.LevelFromNo.SetValue(LevelNo);
        CalculateBins.LevelToNo.SetValue(LevelNo);
        CalculateBins.FieldSeparator.SetValue(FieldSeparator);
        CalculateBins.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePutAwayHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWhseDocsReportHandler(var DeleteRegisteredWhseDocs: TestRequestPage "Delete Registered Whse. Docs.")
    begin
        DeleteRegisteredWhseDocs.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RegisteredMovCardHandler(var RegisteredMovCard: TestPage "Registered Movement")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        RegisteredMovCard."No.".AssertEquals(DocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RegisteredPickCardHandler(var RegisteredPickCard: TestPage "Registered Pick")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        RegisteredPickCard."No.".AssertEquals(DocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RegisteredPutAwayCardHandler(var RegisteredPutAwayCard: TestPage "Registered Put-away")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        RegisteredPutAwayCard."No.".AssertEquals(DocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseIntPickCardHandler(var WhseIntPickCard: TestPage "Whse. Internal Pick")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        WhseIntPickCard."No.".AssertEquals(DocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseIntPutAwayCardHandler(var WhseIntPutAwayCard: TestPage "Whse. Internal Put-away")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        WhseIntPutAwayCard."No.".AssertEquals(DocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(Format(LibraryRandom.RandInt(5)));  // Use random Lot No. because value is not important for test.
        WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsDEcimal);
        WhseItemTrackingLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DateCompressWarehouseEntriesHandler(var DateCompressWhseEntries: TestRequestPage "Date Compress Whse. Entries")
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        DateCompressWhseEntries.StartingDate.SetValue(Format(WorkDate));
        DateCompressWhseEntries.EndingDate.SetValue(Format(WorkDate));
        DateCompressWhseEntries.PeriodLength.SetValue(DateComprRegister."Period Length"::Week);
        DateCompressWhseEntries.SerialNo.SetValue(true);
        DateCompressWhseEntries.LotNo.SetValue(true);
        DateCompressWhseEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwaySelectionHandler(var PutAwaySelection: TestPage "Put-away Selection")
    begin
        PutAwaySelection.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickHandler(var CreatePick: TestRequestPage "Create Pick")
    begin
        CreatePick.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText);
        SalesList.First;
        SalesList.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

