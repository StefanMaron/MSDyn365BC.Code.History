codeunit 137916 "SCM Assembly Reservation I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reservation] [SCM]
    end;

    var
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        WorkDate2: Date;
        Initialized: Boolean;
        ItemTrackingOption: Option AssignLotNo,AssignLotNoManual,AssignLotNos,SelectLotNo;
        WrongRemainingQtyErr: Label 'Wrong Remaining Quantity in the availability page';
        WrongReservedQtyErr: Label 'Wrong Reserved Quantity in the availability page';

    [Test]
    [HandlerFunctions('ReservationPage,AvailToReservePage')]
    [Scope('OnPrem')]
    procedure TestAsmHeaderItemLedEntries()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Available - Item Ledg. Entries]

        Initialize();
        CreateItem(ParentItem);
        CreateItem(ChildItem);
        AddItemToInventory(ChildItem, 1);
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2, 1, '');

        AssemblyLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailToReserveAsmHeaderPage')]
    [Scope('OnPrem')]
    procedure TestAsmHeaderFromSalesLine()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Assembly Headers]

        Initialize();
        CreateItem(ParentItem);
        CreateItem(ChildItem);

        CreateSalesOrder(SalesLine, WorkDate2, ParentItem."No.", 916);
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2, 916, '');

        LibraryVariableStorage.Enqueue(916);
        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailToReserveAsmLinePage')]
    [Scope('OnPrem')]
    procedure TestAsmLineFromPurchaseLine()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Assembly Lines]

        Initialize();
        CreateItem(ParentItem);
        CreateItem(ChildItem);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ChildItem."No.", 917);

        CreateAssemblyOrder(
          AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", CalcDate('<3D>', PurchaseLine."Expected Receipt Date"), 917, '');

        LibraryVariableStorage.Enqueue(917);
        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailAssemblyHeadersCancelReservationHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAssemblySupplyCancelReservation()
    var
        ParentItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Assembly Headers]

        Initialize();
        CreateItem(ParentItem);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ParentItem."No.", '', 1, '');

        CreateSalesOrder(SalesLine, WorkDate2, ParentItem."No.", 1);

        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailAssemblyHeadersDrillDownQtyHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAssemblySupplyDrillDownQuantity()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Assembly Headers]

        Initialize();
        CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', 1, '');

        CreateSalesOrder(SalesLine, WorkDate2, Item."No.", 1);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationPage,AvailToReserveAsmLinePage')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandFromTransferSupply()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Available - Assembly Lines]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Assembly Order, and supply - Transfer Order

        CreateItem(ParentItem);
        CreateItem(ChildItem);
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ChildItem."No.", LibraryRandom.RandInt(1000));

        CreateAssemblyOrder(
          AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2, TransferLine.Quantity, ToLocation.Code);

        LibraryVariableStorage.Enqueue(TransferLine.Quantity);
        TransferLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailToReserveAsmLinePage')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandFromAssemblySupply()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: array[2] of Record "Assembly Header";
        AssemblyLine: array[2] of Record "Assembly Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Available - Assembly Lines]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Assembly Order, and supply - Assembly Order

        CreateItem(ParentItem);
        CreateItem(ChildItem);
        Qty := LibraryRandom.RandDec(1000, 2);
        CreateAssemblyOrder(AssemblyHeader[1], AssemblyLine[1], ParentItem."No.", ChildItem."No.", WorkDate(), Qty, '');
        CreateAssemblyOrder(AssemblyHeader[2], AssemblyLine[2], ChildItem."No.", ParentItem."No.", WorkDate2, Qty, '');

        LibraryVariableStorage.Enqueue(Qty);
        AssemblyHeader[1].ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailableAssemblyLinesCancelReservationPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandCancelReservation()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Assembly Lines]
        // [SCENARIO] Reservation should be cancelled when "Cancel Reservation" action is executed in "Available - Assembly Lines" page

        CreateItem(ParentItem);
        CreateItem(ChildItem);
        ChildItem.Validate(Reserve, ChildItem.Reserve::Always);
        ChildItem.Modify(true);

        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2 + 1, LibraryRandom.RandDec(1000, 2), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ChildItem."No.", AssemblyLine.Quantity);
        AssemblyLine.AutoReserve();

        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailableAssemblyLinesDrillDownQtyPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandDrillDownQuantity()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Assembly Lines]
        // [SCENARIO] Drill down action in "Current Reserved Quantity", page "Available - Assembly Lines" should show full reserved quantity

        CreateItem(ParentItem);
        CreateItem(ChildItem);
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2 + 1, LibraryRandom.RandDec(1000, 2), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ChildItem."No.", AssemblyLine.Quantity);
        AssemblyLine.AutoReserve();

        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPage,AvailablePurchaseLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveAssemblyDemandFromPurchaseManually()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservedQty: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 269556] Assembly line can be reserved from purchase by running "Available to Reserve" -> "Reserve" actions on reservation page.
        Initialize();

        // [GIVEN] Assembly item "A", component item "C".
        CreateItem(ParentItem);
        CreateItem(ChildItem);

        // [GIVEN] Assembly order.
        CreateAssemblyOrder(
          AssemblyHeader, AssemblyLine, ParentItem."No.", ChildItem."No.", WorkDate2 + 1, LibraryRandom.RandDec(1000, 2), '');

        // [GIVEN] Purchase order for component "C".
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ChildItem."No.", AssemblyLine.Quantity);

        // [WHEN] Reserve the assembly line from the purchase. Run "Available to Reserve" and then "Reserve" on reservation page.
        AssemblyLine.ShowReservation();

        // [THEN] The assembly line is reserved.
        ReservedQty := LibraryVariableStorage.DequeueDecimal;
        Assert.AreEqual(AssemblyLine.Quantity, ReservedQty, 'The assembly line has not been reserved.');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerAssignSN,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedSalesInvoiceToOrderAssemblySNTrackingReserv()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        // [SCENARIO 269128] When copying a sales order with linked assembly with "Copy Document", reservation is established between sales and assembly, serial numbers are not copied from the original document

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Assembled item "A", tracked by serial number
        LibraryItemTracking.CreateSerialItem(AsmItem);

        // [GIVEN] Item "C", assembly component for the item "A"
        Qty := LibraryRandom.RandInt(10);
        CreateBOMComponentItem(AsmItem, CompItem, 1);
        AddItemToInventory(CompItem, Qty * 2);

        // [GIVEN] Sales order for item "A". "Assemble-to-Order" link is created for a new assembly order, serial numbers assigned.
        CreateSalesOrderWithTrackedAssembleToOrder(SalesHeader, SalesLine, AsmItem."No.", Qty);

        // [GIVEN] Post the assembly and sale
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Copy the posted sales invoice into a new order
        CopySalesDocumentFromPostedInvoice(SalesHeader, SalesLine."Document No.");

        // [THEN] New sales line is reserved against an assembly order. Serial numbers are not copied from the original sales order.
        VerifyReservationEntry(AsmItem."No.", '', '', -SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOption')]
    [Scope('OnPrem')]
    procedure CopyPostedSalesInvoiceToOrderAssemblyLotTrackingReserv()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNos: array[3] of Code[20];
        LotQty: array[3] of Decimal;
        TotalQty: Decimal;
        I: Integer;
    begin
        // [FEATURE] [Copy Document] [Item Tracking]
        // [SCENARIO 269128] When copying a sales order with linked assembly with "Copy Document", reservation is established between sales and assembly, lot numbers are copied from the original document

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Assembled item "A", tracked by lot number
        LibraryItemTracking.CreateLotItem(AsmItem);

        // [GIVEN] Item "C", assembly component for the item "A"
        CreateBOMComponentItem(AsmItem, CompItem, 1);

        for I := 1 to ArrayLen(LotNos) do begin
            LotNos[I] := LibraryUtility.GenerateGUID();
            LotQty[I] := LibraryRandom.RandInt(10);
            TotalQty += LotQty[I];
        end;

        AddItemToInventory(CompItem, TotalQty);

        // [GIVEN] Sales order for item "A". "Assemble-to-Order" link is created for a new assembly order. Item is sold is 3 lots: "L1" - "X" pcs, "L2" - "Y" pcs, "L3" - "Z" pcs
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNos);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        for I := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(LotNos[I]);
            LibraryVariableStorage.Enqueue(LotQty[I]);
        end;
        CreateSalesOrderWithTrackedAssembleToOrder(SalesHeader, SalesLine, AsmItem."No.", TotalQty);

        // [GIVEN] Post the assembly and sale
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Copy the posted sales invoice into a new order
        CopySalesDocumentFromPostedInvoice(SalesHeader, SalesLine."Document No.");

        // [THEN] New sales line is reserved against an assembly order. Lot numbers are copied into the new order.
        for I := 1 to ArrayLen(LotNos) do
            VerifyReservationEntry(AsmItem."No.", '', LotNos[I], LotQty[I]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesInvoiceToOrderAssemblyReservNoTracking()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 269128] When copying a sales order with linked assembly with "Copy Document", reservation is established between sales and assembly if item is not tracked

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Assembled item "A" without tracking
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] Item "C", assembly component for the item "A"
        Qty := LibraryRandom.RandInt(10);
        CreateBOMComponentItem(AsmItem, CompItem, 1);
        AddItemToInventory(CompItem, Qty * 2);

        // [GIVEN] Sales order for item "A". "Assemble-to-Order" link is created for a new assembly order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", Qty);
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        // [GIVEN] Post the assembly and sale
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Copy the posted sales invoice into a new order
        CopySalesDocumentFromPostedInvoice(SalesHeader, SalesLine."Document No.");

        // [THEN] New sales line is reserved against an assembly order
        VerifyReservationEntry(AsmItem."No.", '', '', -SalesLine.Quantity);
    end;

    local procedure Initialize()
    var
        MfgSetup: Record "Manufacturing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Reservation I");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Reservation I");

        MfgSetup.Get();
        WorkDate2 := CalcDate(MfgSetup."Default Safety Lead Time", WorkDate()); // to avoid Due Date Before Work Date message.

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Reservation I");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPage(var Reservation: TestPage Reservation)
    begin
        Commit();
        Reservation.AvailableToReserve.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailToReservePage(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries.First;

        Assert.IsTrue(AvailableItemLedgEntries."Entry Type".Value = 'Positive Adjmt.',
          'AvailableItemLedgEntries wrong entry type');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailToReserveAsmLinePage(var AvailableAsmLinesPage: TestPage "Available - Assembly Lines")
    var
        QtyToReserve: Decimal;
    begin
        QtyToReserve := LibraryVariableStorage.DequeueDecimal;

        AvailableAsmLinesPage.First;
        Assert.AreEqual(QtyToReserve, AvailableAsmLinesPage."Remaining Quantity".AsDEcimal, WrongRemainingQtyErr);

        AvailableAsmLinesPage.Reserve.Invoke;
        Assert.AreEqual(QtyToReserve, AvailableAsmLinesPage."Reserved Qty. (Base)".AsDEcimal, WrongReservedQtyErr);
    end;

    local procedure CreateSalesOrderWithTrackedAssembleToOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyHeader.OpenItemTrackingLines();
    end;

    local procedure AddItemToInventory(Item: Record Item; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        ItemJournalBatch.SetRange("Template Type", ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch.FindFirst();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CopySalesDocumentFromPostedInvoice(var SalesHeader: Record "Sales Header"; OrderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesInvoiceHeader."Sell-to Customer No.");
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", SalesInvoiceHeader."No.", false, true);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ParentItemNo: Code[20]; ChildItemNo: Code[20]; DueDate: Date; Qty: Decimal; LocationCode: Code[10])
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItemNo, '', Qty, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItemNo, '', Qty, 1, '');
        AssemblyLine.Validate("Location Code", LocationCode);
        AssemblyLine.Modify(true);
    end;

    local procedure CreateBOMComponentItem(AsmItem: Record Item; var CompItem: Record Item; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(CompItem);

        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", QtyPer, CompItem."Base Unit of Measure");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ShipmentDate: Date; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Source Type", DATABASE::"Sales Line");
            SetRange("Item No.", ItemNo);
            SetRange("Reservation Status", "Reservation Status"::Reservation);
            SetRange("Serial No.", SerialNo);
            SetRange("Lot No.", LotNo);
            FindFirst();
            TestField(Quantity, Qty);

            Get("Entry No.", true);
            TestField("Source Type", DATABASE::"Assembly Header");
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailToReserveAsmHeaderPage(var AvailableAsmHeadersPage: TestPage "Available - Assembly Headers")
    begin
        AvailableAsmHeadersPage.First;
        Assert.AreEqual(
          LibraryVariableStorage.DequeueDecimal, AvailableAsmHeadersPage."Remaining Quantity".AsDEcimal,
          WrongRemainingQtyErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailAssemblyHeadersCancelReservationHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.CancelReservation.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailAssemblyHeadersDrillDownQtyHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.ReservedQuantity.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyLinesCancelReservationPageHandler(var AvailableAssemblyLines: TestPage "Available - Assembly Lines")
    begin
        AvailableAssemblyLines.CancelReservation.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyLinesDrillDownQtyPageHandler(var AvailableAssemblyLines: TestPage "Available - Assembly Lines")
    begin
        AvailableAssemblyLines.ReservedQuantity.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailablePurchaseLinesModalPageHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.Reserve.Invoke;
        LibraryVariableStorage.Enqueue(AvailablePurchaseLines.ReservedQuantity.AsDEcimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        ReservationEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerAssignSN(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke;
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOption(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        NoOfLines: Integer;
        I: Integer;
    begin
        case LibraryVariableStorage.DequeueInteger of
            ItemTrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke;
            ItemTrackingOption::AssignLotNoManual:
                begin
                    ItemTrackingLines.New;
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
                end;
            ItemTrackingOption::AssignLotNos:
                begin
                    NoOfLines := LibraryVariableStorage.DequeueInteger;
                    for I := 1 to NoOfLines do begin
                        ItemTrackingLines.New;
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
                    end;
                end;
            ItemTrackingOption::SelectLotNo:
                ItemTrackingLines."Select Entries".Invoke;
        end;

        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;
}

