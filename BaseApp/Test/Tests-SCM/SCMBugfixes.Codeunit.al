codeunit 137045 "SCM Bugfixes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        isInitialized: Boolean;
        LocationCodesArr: array[3] of Code[10];
        ConfirmMessageQst: Label 'Do you want to change ';
        NoReservEntryErr: Label 'No reservation entries created for requisition line.';
        ReservEntryNotDeletedErr: Label 'Requisition line is deleted. All reservation entries must be deleted as well.';
        WrongPurchLineQtyErr: Label 'Quantity in purchase line is incorrect after carrying performing action message.';
        WrongSKUUnitCostErr: Label 'Stockkeeping unit''s unit cost must be equal to item unit cost';
        EmailNotAutomaticallySetErr: Label 'Expected BuyFromContactEmail to automatically be set to the email of the contact, but it wasnt.';
        UseInTransitLocationErr: Label 'You can use In-Transit location %1 for transfer orders only.', Comment = '%1: Location code';

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesShipmentAndInvoice()
    var
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
    begin
        // Setup : Update Sales Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        // Exercise And Verify.
        CreateSalesDocument("Sales Document Type From"::"Posted Shipment", SalesHeader."Document Type"::Invoice, false);  // Set False for Ship Only Posting.

        // Tear Down : Restore Sales Setup.
        RestoreSalesReceivablesSetup(SalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAndCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
    begin
        // Setup : Update Sales Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        // Exercise And Verify.
        CreateSalesDocument("Sales Document Type From"::"Posted Invoice", SalesHeader."Document Type"::"Credit Memo", true);  // Set True for Posting with Invoice Option.

        // Tear Down : Restore Sales Setup.
        RestoreSalesReceivablesSetup(SalesReceivablesSetup);
    end;

    local procedure CreateSalesDocument(FromDocumentType: Enum "Sales Document Type From"; DocumentType: Enum "Sales Document Type"; Invoice: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase, true);

        // Create Sales Order, Post Ship And Invoice and Create Sales Credit Memo with Copy Document.
        // Random values used for item quantity.
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(15, 2), SalesHeader."Document Type"::Order);
        SalesHeader.Validate("External Document No.", SalesHeader."No.");
        SalesHeader.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
        CopySalesDocument(SalesHeader, DocumentType, FromDocumentType, DocumentNo);

        // Verify : Verify the Sales Lines With FromDocumentType.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        VerifySalesLine(SalesLine, FromDocumentType, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationSystemPlanning()
    var
        Item: Record Item;
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        RequisitionLine: Record "Requisition Line";
        SalesOrderQuantity: Decimal;
    begin
        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        // Exercise.
        CreateReservationSystem(Item, RequisitionLine, SalesOrderQuantity);

        // Verify : Verify Item, Quantity and Transfer Location on Planning Work Sheet.
        VerifyPlanningWorkSheet(Item."No.", SalesOrderQuantity, LocationCodesArr[2]);

        // Tear Down.
        RestoreSalesReceivablesSetup(SalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationSystemRequisition()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesOrderQuantity: Decimal;
    begin
        // Setup : Update Sales Setup. Create Item.
        Initialize();

        // Exercise.
        CreateReservationSystem(Item, RequisitionLine, SalesOrderQuantity);
        CarryOutActionMsgPlanSetup(RequisitionLine, Item."No.");

        // Verify : Verify Item , Quantity and Transfer Location on Requisition Work Sheet.
        VerifyPlanningWorkSheet(Item."No.", SalesOrderQuantity, LocationCodesArr[2]);

        // Tear Down.
        RestoreSalesReceivablesSetup(SalesReceivablesSetup);
    end;

    local procedure CreateReservationSystem(var Item: Record Item; var RequisitionLine: Record "Requisition Line"; var SalesOrderQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase, true);
        // Create Location Array, Update Location, Create Transfer Route, Create Stock Keeping unit for each Item
        // at each Location, Post two Item Journal lines to update Item Inventory for each location, Create Sales Order
        // and Accept Capable To Promise. Random values used for item quantity.
        CreateUpdateLocations();
        CreateTransferRoutes();
        CreateUpdateStockKeepUnit(StockkeepingUnit, Item."No.");
        CreateAndPostItemJrnl(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationCodesArr, LibraryRandom.RandDec(15, 2), 2);
        SalesOrderQuantity := LibraryRandom.RandDec(10, 2);
        Item.SetFilter("Location Filter", LocationCodesArr[1]);
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", LocationCodesArr[1], Item.Inventory + SalesOrderQuantity, SalesHeader."Document Type"::Order);
        AcceptCapableToPromise(RequisitionLine, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ContactEmailSyncs_PurchaseDocuments()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseCrMemo: TestPage "Purchase Credit Memo";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [GIVEN] A vendor with a contact who has an E-mail
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);
        Contact.Validate("E-Mail", 'test123@test.com');
        Contact.Modify();

        // [GIVEN] Purchase Order page with a new record
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Contact is selectd via Lookup() of field "Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        PurchaseOrder."Buy-from Contact".Lookup();

        // [THEN] Contact E-mail is auto-filled
        Assert.AreEqual(PurchaseOrder.BuyFromContactEmail.Value, Contact."E-Mail", EmailNotAutomaticallySetErr);

        // [GIVEN] Blanket Purchase Order page with a new record
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Contact is selectd via Lookup() of field "Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        BlanketPurchaseOrder."Buy-from Contact".Lookup();

        // [THEN] Contact E-mail is auto-filled
        Assert.AreEqual(BlanketPurchaseOrder.BuyFromContactEmail.Value, Contact."E-Mail", EmailNotAutomaticallySetErr);

        // [GIVEN] Blanket Purchase Order page with a new record
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Contact is selectd via Lookup() of field "Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        PurchaseInvoice."Buy-from Contact".Lookup();

        // [THEN] Contact E-mail is auto-filled
        Assert.AreEqual(PurchaseInvoice.BuyFromContactEmail.Value, Contact."E-Mail", EmailNotAutomaticallySetErr);

        // [GIVEN] Blanket Purchase Order page with a new record
        PurchaseCrMemo.OpenNew();
        PurchaseCrMemo."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Contact is selectd via Lookup() of field "Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        PurchaseCrMemo."Buy-from Contact".Lookup();

        // [THEN] Contact E-mail is auto-filled
        Assert.AreEqual(PurchaseCrMemo.BuyFromContactEmail.Value, Contact."E-Mail", EmailNotAutomaticallySetErr);

        // [GIVEN] Blanket Purchase Order page with a new record
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Contact is selectd via Lookup() of field "Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        PurchaseReturnOrder."Buy-from Contact".Lookup();

        // [THEN] Contact E-mail is auto-filled
        Assert.AreEqual(PurchaseReturnOrder.BuyFromContactEmail.Value, Contact."E-Mail", EmailNotAutomaticallySetErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WorkFlowPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // Setup.
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Buy-from Vendor No.", '');
        PurchaseHeader.Modify(true);

        // Exercise : Create Purchase Order And Verify Buy From Vendor No. Confirmation.
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Modify(true);

        // Verify : Verify that Vendor No is available on the Purchase Header.
        PurchaseHeader.TestField("Buy-from Vendor No.", VendorNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WorkFlowSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // Setup :
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Sell-to Customer No.", '');
        SalesHeader.Modify(true);

        // Exercise : Create Sales Order And Verify Sell to Customer No. Confirmation.
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);

        // Verify : Verify that Customer No is available on the Sales Header.
        SalesHeader.TestField("Sell-to Customer No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyCanBeChangedToGreaterValueOnReqLineWithItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
        TrackedQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Requisition Line]
        // [SCENARIO 287648] Quantity on planning line with both order tracking and item tracking can be increased, this action does not affect item tracking.
        Initialize();

        // [GIVEN] Lot-tracked item with enabled order tracking.
        CreateTrackedItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order for 10 pcs, sales order for 5 pcs. The supply is thus excessive.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", 10);
        CreateSalesOrder(SalesHeader, Item."No.", '', 5, SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate regenerative plan in planning worksheet, the program suggests to change quantity in the purchase to 5.
        // [GIVEN] Assign lot no. on the planning line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequsitionLine(ReqLine, Item."No.");
        ReqLine.OpenItemTrackingLines();

        // [WHEN] Increase quantity on the planning line up to 50.
        TrackedQty := ReqLine.Quantity;
        ReqLine.Validate(Quantity, ReqLine."Original Quantity" + LibraryRandom.RandIntInRange(20, 40));
        ReqLine.Modify(true);

        // [THEN] Order tracking quantity on the planning line is now 50.
        // [THEN] Item tracking quantity on the planning line is still 5.
        with ReqLine do
            VerifyReservationEntryQuantity("No.", "Worksheet Template Name", Quantity, TrackedQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutPlanWkshSuggestedQuantityReductionAfterAssigningLotTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        IncorrectTrackingQtyErr: Label 'Item tracking quantity is incorrect.';
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Requisition Line]
        // [SCENARIO 287648] Item tracking can be assigned on planning line with the suggested action to reduce quantity and both order tracking and item tracking
        Initialize();

        // [GIVEN] Item "I" with lot tracking and order tracking enabled.
        CreateTrackedItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order for 13 pcs, sales order for 2 pcs. The supply is thus excessive.
        // [GIVEN] To reproduce this scenario, the sales quantity must be less than half of the purchase
        CreatePurchaseOrder(PurchaseHeader, Item."No.", 13);
        CreateSalesOrder(SalesHeader, Item."No.", '', 2, SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate regenerative plan in planning worksheet, the program suggests to change quantity in the purchase to 5.
        // [GIVEN] Assign lot no. on the planning line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequsitionLine(ReqLine, Item."No.");
        ReqLine.OpenItemTrackingLines();

        // [GIVEN] Set "Accept Action Message" on all requisition lines
        UpdatePlanningWorkSheet(ReqLine, Item."No.");

        // [WHEN] Carry out action messages
        LibraryPlanning.CarryOutPlanWksh(ReqLine, 0, NewPurchOrderChoice::"Make Purch. Orders", 0, 0, '', '', '', '');

        // [THEN] 2 pcs of item "I" have lot no. assigned
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::"Lot No.");
        ReservationEntry.CalcSums(Quantity);
        Assert.AreEqual(2, ReservationEntry.Quantity, IncorrectTrackingQtyErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyCanBeChangedToGreaterValueOnReqLineWithoutItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Requisition Line]
        // [SCENARIO 287648] Quantity on planning line with order tracking and no item tracking can be increased, this action does not check item tracking limitations.
        Initialize();

        // [GIVEN] Lot-tracked item with enabled order tracking.
        CreateTrackedItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order for 10 pcs, sales order for 5 pcs. The supply is thus excessive.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(11, 20));
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandInt(10), SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate regenerative plan in planning worksheet, the program suggests to change quantity in the purchase to 5.
        // [GIVEN] Do not assign item tracking.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequsitionLine(ReqLine, Item."No.");

        // [WHEN] Increase quantity on the planning line up to 50.
        ReqLine.Validate(Quantity, ReqLine."Original Quantity" + LibraryRandom.RandIntInRange(20, 40));
        ReqLine.Modify(true);

        // [THEN] Order tracking quantity on the planning line is now 50.
        // [THEN] No item tracking exists on the planning line.
        with ReqLine do
            VerifyReservationEntryQuantity("No.", "Worksheet Template Name", Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyCannotBeChangedToLessValueOnReqLineWithItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Requisition Line]
        // [SCENARIO 287648] Quantity on planning line with both order tracking and item tracking cannot be decreased, because assigned item tracking quantity would become greater than the quantity on the line.
        Initialize();

        // [GIVEN] Lot-tracked item with enabled order tracking.
        CreateTrackedItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order for 10 pcs, sales order for 5 pcs. The supply is thus excessive.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(11, 20));
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandInt(10), SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate regenerative plan in planning worksheet, the program suggests to change quantity in the purchase to 5.
        // [GIVEN] Assign lot no. on the planning line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequsitionLine(ReqLine, Item."No.");
        ReqLine.OpenItemTrackingLines();

        // [WHEN] Decrease quantity on the planning line to 1.
        asserterror ReqLine.Validate(Quantity, LibraryRandom.RandIntInRange(0, ReqLine.Quantity - 1));

        // [THEN] An error "Item tracking defined in the requisition line accounts for more quantity than you have entered" is thrown.
        Assert.ExpectedError('Item tracking is defined');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyCanBeChangedToLessValueOnReqLineWithoutItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Requisition Line]
        // [SCENARIO 287648] Quantity on planning line with order tracking and no item tracking can be decreased, this action does not check item tracking limitations.
        Initialize();

        // [GIVEN] Lot-tracked item with enabled order tracking.
        CreateTrackedItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order for 10 pcs, sales order for 5 pcs. The supply is thus excessive.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(11, 20));
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandInt(10), SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate regenerative plan in planning worksheet, the program suggests to change quantity in the purchase to 5.
        // [GIVEN] Do not assign item tracking.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequsitionLine(ReqLine, Item."No.");

        // [WHEN] Decrease quantity on the planning line to 1.
        ReqLine.Validate(Quantity, LibraryRandom.RandIntInRange(0, ReqLine.Quantity - 1));

        // [THEN] Order tracking quantity on the planning line is now 1.
        // [THEN] No item tracking exists on the planning line.
        with ReqLine do
            VerifyReservationEntryQuantity("No.", "Worksheet Template Name", Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservEntriesDeletedAfterQtyChange()
    var
        RequisitionLine: Record "Requisition Line";
        ReservEntry: Record "Reservation Entry";
    begin
        CreateRequisitionLineChangeQuantity(RequisitionLine);

        ReservEntry.SetRange("Item No.", RequisitionLine."No.");
        Assert.IsFalse(ReservEntry.IsEmpty, NoReservEntryErr);

        // Exercise: Delete requisition line
        RequisitionLine.Delete(true);

        // Verify: All reservation entries deleted
        Assert.IsTrue(ReservEntry.IsEmpty, ReservEntryNotDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageAfterQtyChange()
    var
        RequisitionLine: Record "Requisition Line";
        TempRequisitionLine: Record "Requisition Line" temporary;
    begin
        CreateRequisitionLineChangeQuantity(RequisitionLine);
        // Carry Out Action Message batch job deletes requisition line. Need to save it for verification.
        TempRequisitionLine := RequisitionLine;

        // Exercise: Carry out action message
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate(), WorkDate(), WorkDate(), '');

        // Verify: Quantity in purchase line is updated correctly
        with TempRequisitionLine do
            VerifyPurchaseLineQuantity("Ref. Order No.", "Ref. Line No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActionMsgAfterReshedAndQtyChange()
    var
        RequisitionLine: Record "Requisition Line";
        TempRequisitionLine: Record "Requisition Line" temporary;
    begin
        CreateRequisitionLineChangeQuantity(RequisitionLine);

        with RequisitionLine do begin
            Validate("Due Date", CalcDate('<+1D>', "Due Date"));
            // New qty. must not exceed original quanity.
            Validate(Quantity, Quantity + 1);
            Modify(true);
        end;

        TempRequisitionLine := RequisitionLine;

        // Exercise: Carry out action message
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate(), WorkDate(), WorkDate(), '');

        // Verify: Quantity in purchase line is updated correctly
        with TempRequisitionLine do
            VerifyPurchaseLineQuantity("Ref. Order No.", "Ref. Line No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderTrackingHandler,SalesReturnOrderHandler')]
    [Scope('OnPrem')]
    procedure OpenSalesReturnOrderFromOrderTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Check Sales Return Order page will open from Order Tracking.

        // Setup : create item,Sales order and calculated Regenrative plan
        Initialize();
        CreateItemWithReorderValues(Item);
        CreateSalesOrder(SalesHeader, Item."No.", '', -LibraryRandom.RandDec(15, 2), SalesHeader."Document Type"::"Return Order");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, WorkDate(), CalcDate(StrSubstNo('<%1m>', LibraryRandom.RandInt(3)), WorkDate()), false);

        // Exercise : Open Planning work sheet and invoke Order Tracking page.
        OpenOrderTrackingFromPlanWorkSheet(Item."No.");

        // Verify : Verification of opening SalesReturnOrder Page done in SalesReturnOrderHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReclassificationJournalToTransitLocation()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Item Reclassification Journal] [Transit Location]
        // [SCENARIO 377757] It should be prohibited to Post Reclassification Journal to In-Transit Location
        Initialize();

        // [GIVEN] In-Transit Location "X"
        LibraryWarehouse.CreateInTransitLocation(Location);

        // [GIVEN] Reclassification Journal with "Location Code" = "X"
        CreatItemJournalLine(ItemJournalBatch, ItemJournalLine."Entry Type"::Transfer, Location.Code, '');

        // [WHEN] Post Reclassification Journal
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] Error is thrown: "You can use In-Transit location X for Transfer Orders only."
        Assert.ExpectedError(StrSubstNo(UseInTransitLocationErr, Location.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReclassificationJournalFromTransitLocation()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Reclassification Journal] [Transit Location]
        // [SCENARIO 377757] It should be prohibited to Post Reclassification Journal from In-Transit Location
        Initialize();

        // [GIVEN] In-Transit Location "X"
        LibraryWarehouse.CreateInTransitLocation(Location);

        // [GIVEN] Reclassification Journal with "New Location Code" = "X"
        CreatItemJournalLine(ItemJournalBatch, ItemJournalLine."Entry Type"::Transfer, '', Location.Code);

        // [WHEN] Post Reclassification Journal
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] Error is thrown: "You can use In-Transit location X for Transfer Orders only."
        Assert.ExpectedError(StrSubstNo(UseInTransitLocationErr, Location.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemUnitCostIsTransferredToNewSKU()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 361539] Check that item unit cost is transferred to the stockkeeping unit card when a new SKU is created
        // [GIVEN] Item "A" with "Unit Cost" = "X"
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();

        // [WHEN] "Item No." is set to "A" in a new stockkeeping unit card
        SKU.Init();
        SKU.Validate("Item No.", Item."No.");

        // [THEN] "Unit Cost" is "X" in the stockkeping unit card
        Assert.AreEqual(Item."Unit Cost", SKU."Unit Cost", WrongSKUUnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorNoValidationDoesNotChangeLocationInSystemCreatedReqLine()
    var
        Item: Record Item;
        Location: Record Location;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 362374] Location code is not updated in the requisition line when Vendor No. is changed after modifying Due Date

        // [GIVEN] Item with "Lot-for-Lot" reordering policy
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase, true);

        // [GIVEN] Vendor "V" with default location "L1"
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, LibraryWarehouse.CreateLocation(Location));

        // [GIVEN] Sales Order with location "L2"
        LibraryWarehouse.CreateLocation(Location);
        CreateSalesOrder(SalesHeader, Item."No.", Location.Code, LibraryRandom.RandDec(100, 2), SalesHeader."Document Type"::Order);

        // [GIVEN] Calculate requisition plan
        CalculateRequisitionPlan(ReqWkshName, Item);

        ReqWorksheet.Trap();
        PAGE.Run(PAGE::"Req. Worksheet");
        FindRequisitionLine(ReqLine, ReqWkshName, ReqLine."Action Message"::New);
        ReqWorksheet.CurrentJnlBatchName.SetValue(ReqLine."Journal Batch Name");
        ReqWorksheet.GotoRecord(ReqLine);

        // [GIVEN] Change "Due Date" in the requisition line
        ReqWorksheet."Due Date".SetValue(CalcDate('<1W>', ReqLine."Due Date"));

        // [WHEN] "Vendor No." in the requisition line is set to "V"
        ReqWorksheet."Vendor No.".SetValue(Vendor."No.");

        // [THEN] "Location Code" in the requisition line is "L2"
        ReqWorksheet."Location Code".AssertEquals(Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWithComponentStartingDateIsPlannedWhenDateIsValid()
    var
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        I: Integer;
    begin
        // [FEATURE] [Capable to Promise] [Production BOM]
        // [SCENARIO 382250] Items included in a production BOM with a starting date, should be planned if Starting Date is equal to WORKDATE

        Initialize();

        // [GIVEN] Create 3 "Critical" items: "I1", "I2", "I3"
        // [GIVEN] Items "I2" and "I3" are replenished via production, "I1" is purchased
        // [GIVEN] Create production BOM structure, so that "I1" is a component of "I2", and "I2" is a component of "I3"
        // [GIVEN] Low-level component "I1" is included in a production BOM with the Starting Date = WORKDATE
        CreateProdBOMStructureOfCriticalItems(Item, WorkDate(), Item[1]."Replenishment System"::Purchase);

        // [GIVEN] Create a sales order with item "I3"
        CreateSalesOrder(SalesHeader, Item[3]."No.", '', LibraryRandom.RandInt(100), SalesHeader."Document Type"::Order);

        // [WHEN] Run "Capable-to-Promise" for item "I3"
        AcceptCapableToPromise(RequisitionLine, SalesHeader);

        // [THEN] Replenishment is planned for all 3 items in the planning worksheet
        for I := 1 to 3 do
            VerifyRequisitionLineCount(Item[I]."No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWithComponentStartingDateIsNotPlannedWhenDateIsInvalid()
    var
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        I: Integer;
    begin
        // [FEATURE] [Capable to Promise] [Production BOM]
        // [SCENARIO 382250] Items included in a production BOM with a starting date, should not be planned if Starting Date is greater than WORKDATE

        Initialize();

        // [GIVEN] Create 3 "Critical" items: "I1", "I2", "I3"
        // [GIVEN] Items "I2" and "I3" are replenished via production, "I1" is purchased
        // [GIVEN] Create production BOM structure, so that "I1" is a component of "I2", and "I2" is a component of "I3"
        // [GIVEN] Low-level component "I1" is included in a production BOM with the Starting Date = WorkDate() + 1 week
        CreateProdBOMStructureOfCriticalItems(Item, CalcDate('<1W>', WorkDate()), Item[1]."Replenishment System"::Purchase);

        // [GIVEN] Create a sales order with item "I3"
        CreateSalesOrder(SalesHeader, Item[3]."No.", '', LibraryRandom.RandInt(100), SalesHeader."Document Type"::Order);

        // [WHEN] Run "Capable-to-Promise" for item "I3"
        AcceptCapableToPromise(RequisitionLine, SalesHeader);

        // [THEN] Items "I2" and "I3" are planned in the planning worksheet, there is no plan for item "I1"
        VerifyRequisitionLineCount(Item[1]."No.", 0);
        for I := 2 to 3 do
            VerifyRequisitionLineCount(Item[I]."No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesForMTOProdOrdersHaveSingleOrderNoInPlanningWhsht()
    var
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Capable to Promise] [Production BOM]
        // [SCENARIO 205943] Multi-lined production order should have a single Ref. Order No. in Planning Worksheet created by Capable-to-Promise.
        Initialize();

        // [GIVEN] BOM structure of three production items "I1", "I2" and "I3" is created, so that "I1" is a component of "I2", and "I2" is a component of "I3".
        CreateProdBOMStructureOfCriticalItems(Item, WorkDate(), Item[1]."Replenishment System"::"Prod. Order");

        // [GIVEN] Create a sales order with item "I3"
        CreateSalesOrder(SalesHeader, Item[3]."No.", '', LibraryRandom.RandInt(100), SalesHeader."Document Type"::Order);

        // [WHEN] Run "Capable-to-Promise" for the sales order.
        AcceptCapableToPromise(RequisitionLine, SalesHeader);

        // [THEN] Whole planned BOM structure of items "I1".."I3" has a single Ref. Order No.
        VerifySingleRefOrderNoInReqLine(Item);
    end;

    [Test]
    [HandlerFunctions('TransferOrderSaveAsXML')]
    [Scope('OnPrem')]
    procedure PrintMultipleTransferOrdersWhenUsingCarryOutActionMessage()
    var
        RequisitionPlanningLine: array[2] of Record "Requisition Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReservationEntry: Record "Reservation Entry";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        TransOrderChoice: Enum "Planning Create Transfer Order";
        ItemNo: array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO 492125] Verify printing of multiple transfer orders in the "planning worksheet" sheet when using Carry Out Action Message.
        Initialize();

        // [GIVEN] Create Location Array, Update Location, Create Transfer Route
        CreateUpdateLocations();
        CreateTransferRoutes();

        // [GIVEN] Select Planning worksheet.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.DeleteAll();

        // [GIVEN] remove old Reservation Entry
        ReservationEntry.SetRange("Source Type", Database::"Requisition Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetRange("Source ID", RequisitionWkshName."Worksheet Template Name");
        ReservationEntry.SetRange("Source Batch Name", RequisitionWkshName.Name);
        ReservationEntry.DeleteAll();

        // [GIVEN] Create multiple  items, Create Stock Keeping unit for each Item
        for i := 1 to ArrayLen(ItemNo) do begin
            ItemNo[i] := LibraryInventory.CreateItemNo();
            CreateUpdateStockKeepUnit(StockkeepingUnit, ItemNo[i]);

            // [GIVEN] Create and modify the requisition line.
            Clear(RequisitionPlanningLine[i]);
            LibraryPlanning.CreateRequisitionLine(RequisitionPlanningLine[i], RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
            RequisitionPlanningLine[i].Validate("Order Date", WorkDate());
            RequisitionPlanningLine[i].Validate("Due Date", WorkDate());
            RequisitionPlanningLine[i].Validate(Type, RequisitionPlanningLine[i].Type::Item);
            if RequisitionPlanningLine[i]."Due Date" = 0D then
                RequisitionPlanningLine[i].Validate("Due Date", WorkDate());
            RequisitionPlanningLine[i]."No." := ItemNo[i];
            RequisitionPlanningLine[i]."Location Code" := LocationCodesArr[1];
            RequisitionPlanningLine[i].Validate("No.", ItemNo[i]);
            RequisitionPlanningLine[i].Validate("Location Code", LocationCodesArr[1]);
            RequisitionPlanningLine[i].Validate("Transfer Shipment Date", WorkDate());
            RequisitionPlanningLine[i].Validate("Accept Action Message", true);
            RequisitionPlanningLine[i].Validate(Quantity, LibraryRandom.RandInt(10));
            RequisitionPlanningLine[i].Modify(true);
            RequisitionPlanningLine[i].Testfield("Ref. Order Type", RequisitionPlanningLine[i]."Ref. Order Type"::"Transfer");
            RequisitionPlanningLine[i].Testfield("Supply From", LocationCodesArr[2]);
        end;

        // [GIVEN] Filter newly created requisition lines.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Transfer");
        RequisitionLine.FindSet();

        // [GIVEN] Setup report selection.
        SetupReportSelections("Report Selection Usage"::Inv1, Report::"Transfer Order");

        // [WHEN] Carry out action in planning worksheet with option "Make Trans. Orders & Print".
        LibraryPlanning.CarryOutPlanWksh(
            RequisitionLine, 0, 0, TransOrderChoice::"Make Trans. Order & Print".AsInteger(),
            0, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, '', '');

        // [THEN] Verify Print of Multiple Transfer Orders When Using Carry Out Action Message.
        TransferHeader.SetRange("Transfer-to Code", LocationCodesArr[1]);
        VerifyPrintedTransferOrders(TransferHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseInboundHandlingTimeOnPurchaseOrderUpdatedOnInsert()
    var
        Location: Record Location;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        InbHandlingTime: DateFormula;
    begin
        // [FEATURE] [Purchase] [Location] [Inbound Whse. Handling Time] [UT]
        // [SCENARIO 310491] "Inbound Whse. Handling Time" on purchase order is updated from location settings when the record is inserted.
        Initialize();

        // [GIVEN] Location "L" with "Inbound Whse. Handling Time" = "5D".
        Evaluate(InbHandlingTime, StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)));
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Inbound Whse. Handling Time", InbHandlingTime);
        Location.Modify(true);

        // [GIVEN] Vendor "V" with location code "L".
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location.Code);

        // [GIVEN] Initialize a purchase order for vendor "V".
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [WHEN] Insert the purchase header record.
        PurchaseHeader.Insert(true);

        // [THEN] "Inbound Whse. Handling Time" on the purchase header is "5D".
        PurchaseHeader.TestField("Inbound Whse. Handling Time", Location."Inbound Whse. Handling Time");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Bugfixes");
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Bugfixes");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        GeneralLedgerSetup.Get();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Bugfixes");
    end;

    local procedure SetupReportSelections(ReportSelectionUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelectionUsage);
        ReportSelections.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportSelectionUsage);
        ReportSelections.Validate(Sequence, LibraryRandom.RandText(2));
        ReportSelections.Validate("Report ID", ReportId);
        ReportSelections.Insert(true);
    end;

    local procedure VerifyPrintedTransferOrders(var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('No_TransferHdr', TransferHeader."No.");
            LibraryReportDataset.GetNextRow();
        until TransferHeader.Next() = 0;
    end;

    local procedure UpdateSalesReceivablesSetup(var TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary; CreditWarnings: Option; StockoutWarning: Boolean)
    begin
        SalesReceivablesSetup.Get();
        TempSalesReceivablesSetup := SalesReceivablesSetup;
        TempSalesReceivablesSetup.Insert();

        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure AssignProductionBOMToItem(var ParentItem: Record Item; ComponentItemNo: Code[20]; ComponentStartingDate: Date; QtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateCertifiedProductionBOMWithComponentStartingDate(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ComponentItemNo, QtyPer, ComponentStartingDate);
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; IncludeInventory: Boolean)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJrnl(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: array[3] of Code[10]; Quantity: Decimal; NoOfLines: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        "Count": Integer;
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // Creating only two Item Journal lines.
        for Count := 1 to NoOfLines do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
            ItemJournalLine."Location Code" := LocationCode[Count];
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateCertifiedProductionBOMWithComponentStartingDate(var ProductionBOMHeader: Record "Production BOM Header"; UOMCode: Code[10]; ItemNo: Code[20]; QtyPer: Decimal; StartingDate: Date)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UOMCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QtyPer);
        ProductionBOMLine.Validate("Starting Date", StartingDate);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CalculateRequisitionPlan(var ReqWkshName: Record "Requisition Wksh. Name"; Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        DateRec: Record Date;
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, ReqWkshTemplate.Name);

        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetFilter("Period Start", '<=%1', WorkDate());
        DateRec.FindLast();
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, ReqWkshTemplate.Name, ReqWkshName.Name, DateRec."Period Start", NormalDate(DateRec."Period End"));
    end;

    local procedure CreateCriticalItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);

        with Item do begin
            Validate(Critical, true);
            Validate("Replenishment System", ReplenishmentSystem);
            Validate("Manufacturing Policy", "Manufacturing Policy"::"Make-to-Order");
            Modify(true);
        end;
    end;

    local procedure CreateItemTrackingCodeWithLotSpecTracking(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        with ItemTrackingCode do begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
            Validate("Lot Purchase Inbound Tracking", true);
            Validate("Lot Sales Outbound Tracking", true);
            Validate("Lot Specific Tracking", true);
            Modify(true);
        end;
    end;

    local procedure CreateProdBOMStructureOfCriticalItems(var Item: array[3] of Record Item; LowerCompStartingDate: Date; LowerCompReplenishmentSystem: Enum "Replenishment System")
    var
        I: Integer;
    begin
        CreateCriticalItem(Item[1], LowerCompReplenishmentSystem);
        for I := 2 to 3 do
            CreateCriticalItem(Item[I], Item[I]."Replenishment System"::"Prod. Order");

        AssignProductionBOMToItem(Item[2], Item[1]."No.", LowerCompStartingDate, 1);
        AssignProductionBOMToItem(Item[3], Item[2]."No.", 0D, 1);
    end;

    local procedure CreateOrdersAndRequisitionPlan(var RequisitionLine: Record "Requisition Line")
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        CreateTrackedItem(Item);

        CreatePurchaseOrder(PurchHeader, Item."No.", LibraryRandom.RandIntInRange(10, 15));
        FindPurchaseLine(PurchLine, PurchHeader."No.");
        CreateSalesOrder(
          SalesHeader, Item."No.", '',
          PurchLine.Quantity - LibraryRandom.RandIntInRange(5, 8), SalesHeader."Document Type"::Order);
        CalculateRequisitionPlan(ReqWkshName, Item);

        FindRequisitionLine(RequisitionLine, ReqWkshName, RequisitionLine."Action Message"::"Change Qty.");
    end;

    local procedure CreateRequisitionLineChangeQuantity(var RequisitionLine: Record "Requisition Line")
    begin
        CreateOrdersAndRequisitionPlan(RequisitionLine);

        with RequisitionLine do begin
            // Change requisition line quantity. New quantity must be greater than sales line qty., but less than purch. line
            Validate(Quantity, Quantity + LibraryRandom.RandIntInRange(1, "Original Quantity" - Quantity - 1));
            Modify(true);
        end;
    end;

    local procedure CreateTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeWithLotSpecTracking(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        with Item do begin
            Validate("Replenishment System", "Replenishment System"::Purchase);
            Validate("Reordering Policy", "Reordering Policy"::"Lot-for-Lot");
            Modify(true);
        end;
    end;

    local procedure CreateUpdateLocations()
    var
        Location: Record Location;
        HandlingTime: DateFormula;
        HandlingTime2: DateFormula;
        k: Integer;
    begin
        // Values Used are important for Test.
        Evaluate(HandlingTime, '<1D>');
        Evaluate(HandlingTime2, '<0D>');
        for k := 1 to 3 do begin  // Creating three Locations.
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            LocationCodesArr[k] := Location.Code;
        end;

        // Update Two Locations only because third location is In-Transit.
        for k := 1 to 2 do
            UpdateLocation(LocationCodesArr[k], false, HandlingTime2, HandlingTime2);
        UpdateLocation(LocationCodesArr[3], true, HandlingTime2, HandlingTime2);
    end;

    local procedure CreateUpdateStockKeepUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Location Filter", LocationCodesArr[1], LocationCodesArr[2]);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);

        // Update Replenishment System in Stock Keeping Unit.
        UpdateStockKeepingUnit(StockkeepingUnit."Replenishment System"::Purchase, LocationCodesArr[1], ItemNo, '', '');
        UpdateStockKeepingUnit(StockkeepingUnit."Replenishment System"::Transfer, LocationCodesArr[1], ItemNo, '', LocationCodesArr[2]);
    end;

    local procedure CreateTransferRoutes()
    var
        TransferRoute: Record "Transfer Route";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServicesCode: array[3] of Code[10];
        i: Integer;
        j: Integer;
        k: Integer;
    begin
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);

        // Transfer Route for Location Code.
        k := 1;
        for i := 1 to 2 do
            for j := i + 1 to 2 do begin
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCodesArr[i], LocationCodesArr[j]);
                UpdateTransferRoute(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCodesArr[j], LocationCodesArr[i]);
                UpdateTransferRoute(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                k := k + 1;
            end;
    end;

    local procedure CreatItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; NewLocationCode: Code[10])
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          EntryType, Item."No.", LibraryRandom.RandDec(15, 2));
        ItemJournalLine."Location Code" := LocationCode;
        ItemJournalLine."New Location Code" := NewLocationCode;
        ItemJournalLine.Modify(true);
    end;

    local procedure FindPurchaseLine(var PurchLine: Record "Purchase Line"; PurchDocNo: Code[20])
    begin
        with PurchLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange("Document No.", PurchDocNo);
            FindFirst();
        end;
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; ActionMessage: Enum "Action Message Type")
    begin
        with RequisitionLine do begin
            SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
            SetRange("Journal Batch Name", RequisitionWkshName.Name);
            SetRange("Action Message", ActionMessage);
            FindFirst();
        end;
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProdBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateTransferRoute(var TransferRoute: Record "Transfer Route"; ShippingAgentServiceCode: Code[10]; ShippingAgentCode: Code[10])
    begin
        TransferRoute.Validate("In-Transit Code", LocationCodesArr[3]);
        TransferRoute.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferRoute.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferRoute.Modify(true);
    end;

    local procedure UpdateStockKeepingUnit(ReplenishmentSystem: Enum "Replenishment System"; LocationCode: Code[10]; ItemNo: Code[20]; VendorNo: Code[20]; TransferfromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst();
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferfromCode);
        StockkeepingUnit.Validate("Vendor No.", VendorNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateLocation("Code": Code[10]; UseAsInTransit: Boolean; OutboundWhseHandlingTime: DateFormula; InboundWhseHandlingTime: DateFormula)
    var
        Location: Record Location;
    begin
        Location.Get(Code);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        Location.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '', ItemNo, Quantity, '', WorkDate());
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', ItemNo, Quantity, LocationCode, WorkDate());
    end;

    local procedure AcceptCapableToPromise(var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header")
    var
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        AvailabilityMgt.SetSalesHeader(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");
        OrderPromisingLine.FindFirst();
        AvailabilityMgt.UpdateSource(OrderPromisingLine);
        RequisitionLine.SetRange("Order Promising ID", SalesHeader."No.");
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreateShippingAgentServices(var ShippingAgent: Record "Shipping Agent"; var ShippingAgentServicesCode: array[3] of Code[10])
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
        j: Integer;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        for j := 1 to 3 do begin  // Count equal to no of Locations.
            Evaluate(ShippingTime, '<' + Format(j) + 'D>');
            LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
            ShippingAgentServicesCode[j] := ShippingAgentServices.Code;
        end;
    end;

    local procedure CarryOutActionMsgPlanSetup(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChoice: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        // Update Vendor No in Requisition Worksheet and Carry Out Action Message.
        // Update Accept Action Message in Planning Worksheet.
        UpdatePlanningWorkSheet(RequisitionLine, ItemNo);

        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, RequisitionLine."Worksheet Template Name");

        LibraryPlanning.CarryOutPlanWksh(
          RequisitionLine,
          NewProdOrderChoice::Planned, NewPurchOrderChoice::"Copy to Req. Wksh",
          NewTransOrderChoice::"Copy to Req. Wksh", NewAsmOrderChoice::" ",
          RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name,
          RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure UpdatePlanningWorkSheet(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CopySalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; FromDocType: Enum "Sales Document Type From"; DocumentNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        LibrarySales.CopySalesDocument(SalesHeader, FromDocType, DocumentNo, true, true);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Line Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure VerifySalesLine(SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type From"; DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        case DocumentType of
            DocumentType::"Posted Invoice":
                begin
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
                    SalesInvoiceLine.FindFirst();
                    SalesLine.TestField(Type, SalesInvoiceLine.Type);
                    SalesLine.TestField("No.", SalesInvoiceLine."No.");
                    SalesLine.TestField(Quantity, SalesInvoiceLine.Quantity);
                end;
            DocumentType::"Posted Shipment":
                begin
                    SalesShipmentLine.SetRange("Document No.", DocumentNo);
                    SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
                    SalesShipmentLine.FindFirst();
                    SalesLine.TestField(Type, SalesShipmentLine.Type);
                    SalesLine.TestField("No.", SalesShipmentLine."No.");
                    SalesLine.TestField(Quantity, SalesShipmentLine.Quantity);
                end;
        end;
    end;

    local procedure VerifyPlanningWorkSheet(ItemNo: Code[20]; Quantity: Decimal; LocationCode2: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequsitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Transfer-from Code", LocationCode2);
    end;

    local procedure RestoreSalesReceivablesSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItemWithReorderValues(var Item: Record Item)
    begin
        with Item do begin
            CreateItem(Item, "Reordering Policy"::"Fixed Reorder Qty.", "Replenishment System"::Purchase, true);
            Validate("Reorder Point", LibraryRandom.RandDec(10, 2));
            Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
            Modify(true);
        end;
    end;

    local procedure OpenOrderTrackingFromPlanWorkSheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        RequisitionLine.SetRange("Accept Action Message", false);
        FindRequsitionLine(RequisitionLine, ItemNo);

        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.GotoRecord(RequisitionLine);
        PlanningWorksheet.OrderTracking.Invoke();
    end;

    local procedure FindRequsitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure VerifyPurchaseLineQuantity(RefOrderNo: Code[20]; RefLineNo: Integer; ExpectedQuantity: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange("Document No.", RefOrderNo);
            SetRange("Line No.", RefLineNo);
            FindFirst();
            Assert.AreEqual(ExpectedQuantity, Quantity, WrongPurchLineQtyErr);
        end;
    end;

    local procedure VerifyRequisitionLineCount(ItemNo: Code[20]; ExpectedCount: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.RecordCount(RequisitionLine, ExpectedCount);
    end;

    local procedure VerifySingleRefOrderNoInReqLine(var Item: array[3] of Record Item)
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderNo: Code[20];
        i: Integer;
    begin
        with RequisitionLine do begin
            FindRequsitionLine(RequisitionLine, Item[3]."No.");
            RefOrderNo := "Ref. Order No.";

            for i := 1 to 2 do begin
                FindRequsitionLine(RequisitionLine, Item[i]."No.");
                TestField("Ref. Order No.", RefOrderNo);
            end;
        end;
    end;

    local procedure VerifyReservationEntryQuantity(ItemNo: Code[20]; SourceID: Code[20]; ExpectedQuantity: Decimal; TrackedQuantity: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        with ReservEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Source ID", SourceID);
            CalcSums(Quantity);
            TestField(Quantity, ExpectedQuantity);

            SetFilter("Item Tracking", '<>%1', "Item Tracking"::None);
            CalcSums(Quantity);
            TestField(Quantity, TrackedQuantity);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListModalPageHandler(var ContactLookup: Page "Contact List"; var Response: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Get(LibraryVariableStorage.DequeueText());
        ContactLookup.SetRecord(Contact);
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Check confirmation message.
        Assert.AreNotEqual(StrPos(Question, ConfirmMessageQst), 0, Question);
        Reply := true;
    end;

    [ReportHandler]
    procedure TransferOrderSaveAsXML(var TransferOrder: Report "Transfer Order")
    var
        TransferHeader: Record "Transfer Header";
    begin
        LibraryReportDataset.RunReportAndLoad(Report::"Transfer Order", TransferHeader, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnOrderHandler(var SalesReturnOrder: TestPage "Sales Return Order")
    var
        SalesReturnOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesReturnOrderNo);
        SalesReturnOrder."No.".AssertEquals(SalesReturnOrderNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking.Show.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

