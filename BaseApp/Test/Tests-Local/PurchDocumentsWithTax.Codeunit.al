codeunit 144024 "Purch. Documents With Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Sales] [Drop Shipment]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValueMustEqualErr: Label 'Value must be equal.';
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [HandlerFunctions('PurchReceiptLinesPageHandler,ItemChargeAssignmentHandler')]
    [Scope('OnPrem')]
    procedure ValueEntriesAfterPostPurchOrdWithItemAndItemCharge()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        PostedPurchaseInvoiceNo: Code[20];
        PostedPurchaseInvoiceNo2: Code[20];
        PostedPurchaseReceiptNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // Verify Value Entry after Post purchase Order with Item And Item Charge with different Unit Costs.

        // Setup: Create Sales Order with Drop Shipment, post Purchase Order after carry out action message.
        Initialize();
        Item.Get(CreateItem);
        CreateAndPostItemJournal(ItemJournalLine, Item."No.");
        CreateSalesOrderWithDropShipment(SalesLine, Item."No.", ItemJournalLine.Quantity);
        GetSalesOrderAndCarryOutActionMessage(SalesLine);
        PostedPurchaseReceiptNo := UpdateAndPostPurchaseOrder(PurchaseLine, Item."Vendor No.", Item."Unit Cost" * 2);  // Updating Unit Cost with multiple of 2.
        LibraryVariableStorage.Enqueue(PostedPurchaseReceiptNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesLine."Document No.");
        PostedPurchaseInvoiceNo := PostPurchaseOrder(PurchaseLine."Document No.");

        // Exercise: Create and Post Purchase Invoice with Item Charge.
        PostedPurchaseInvoiceNo2 := CreateAndPostPurchaseInvoiceWithItemCharge(PurchaseLine.Quantity);

        // Verify: Verify Cost Amount (Expected) and Value Quantity on Value Entry.
        VerifyValueEntries(
          ValueEntry."Item Ledger Entry Type"::Purchase, PostedPurchaseReceiptNo, PurchaseLine.Quantity,
          PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
        VerifyValueEntries(
          ValueEntry."Item Ledger Entry Type"::Purchase, PostedPurchaseInvoiceNo, PurchaseLine.Quantity,
          -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
        VerifyValueEntries(
          ValueEntry."Item Ledger Entry Type"::Sale, PostedSalesInvoiceNo, -SalesLine.Quantity,
          SalesLine.Quantity * SalesLine."Unit Cost");
        VerifyValueEntries(
          ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ItemJournalLine."Document No.", ItemJournalLine.Quantity, 0);  // 0 value required.
        VerifyValueEntries(ValueEntry."Item Ledger Entry Type"::Purchase, PostedPurchaseInvoiceNo2, PurchaseLine.Quantity, 0);  // 0 value required.
    end;

    [Test]
    [HandlerFunctions('PurchReceiptLinesPageHandler,ItemChargeAssignmentHandler,AverageCostCalcOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitCostAfterPostPurchOrdWithItemAndItemCharge()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ItemCard: TestPage "Item Card";
    begin
        // Verify Unit Cost on Item Page after Post purchase Order with Item And Item Charge with different Unit Costs.

        // Setup: Create Sales Order with Drop Shipment, post Purchase Order after carry out action message. Create and Post Purchase Invoice with Item Charge.
        Initialize();
        Item.Get(CreateItem);
        CreateAndPostItemJournal(ItemJournalLine, Item."No.");
        CreateSalesOrderWithDropShipment(SalesLine, Item."No.", ItemJournalLine.Quantity);
        GetSalesOrderAndCarryOutActionMessage(SalesLine);
        LibraryVariableStorage.Enqueue(UpdateAndPostPurchaseOrder(PurchaseLine, Item."Vendor No.", Item."Unit Cost" * 2));  // Updating Unit Cost with multiple of 2.
        PostSalesOrder(SalesLine."Document No.");
        PostPurchaseOrder(PurchaseLine."Document No.");
        CreateAndPostPurchaseInvoiceWithItemCharge(PurchaseLine.Quantity);
        EnqueueForAverageCostCalcOverviewPageHandler(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine.Quantity,
          ItemJournalLine.Quantity * ItemJournalLine."Unit Cost");
        EnqueueForAverageCostCalcOverviewPageHandler(
          ItemJournalLine."Entry Type"::Sale, -SalesLine.Quantity, -SalesLine.Quantity * SalesLine."Unit Cost");

        // Exercise: Drill down Unit Cost from Item Card Page.
        ItemCard.OpenEdit;
        ItemCard.FILTER.SetFilter("No.", Item."No.");
        ItemCard."Unit Cost".DrillDown;

        // Verify: Verification is covered in AverageCostCalcOverviewPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostItemJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithItemCharge(Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", CreateItemChargeNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));  // Take Random Unit cost.
        PurchaseLine.Modify(true);
        PurchaseLine.ShowItemChargeAssgnt();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');  // Blank value is required for VAT Business Posting Group.
        Customer.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("VAT Prod. Posting Group", '');  // Blank value required for creating Sales Line.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Take Random Unit Cost.
        Item.Validate("Vendor No.", CreateVendor);
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemChargeNo(): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", '');
        ItemCharge.Modify(true);
        exit(ItemCharge."No.")
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');  // Blank value required for creating Purchase Line.
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, Type, No, Quantity);
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure EnqueueForAverageCostCalcOverviewPageHandler(EntryType: Option; Quantity: Decimal; CostAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(EntryType);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(CostAmount);
    end;

    local procedure GetSalesOrderAndCarryOutActionMessage(SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::Item);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate, WorkDate(), WorkDate, '');
    end;

    local procedure UpdateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure PostPurchaseOrder(DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesOrder(DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure VerifyAverageCostCalcOverview(var AverageCostCalcOverview: TestPage "Average Cost Calc. Overview")
    var
        CostAmountActual: Variant;
        EntryType: Variant;
        Quantity: Variant;
    begin
        AverageCostCalcOverview.Next();
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(CostAmountActual);
        AverageCostCalcOverview."Entry Type".AssertEquals(EntryType);
        AverageCostCalcOverview.Quantity.AssertEquals(Quantity);
        AverageCostCalcOverview."Cost Amount (Actual)".AssertEquals(CostAmountActual);
        AverageCostCalcOverview.Next();
    end;

    local procedure VerifyValueEntries(ItemLedgerEntryType: Option; DocumentNo: Code[20]; ValueQuantity: Decimal; CostAmountExpected: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(ValueQuantity, ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision, ValueMustEqualErr);
        Assert.AreNearlyEqual(
          CostAmountExpected, ValueEntry."Cost Amount (Expected)", LibraryERM.GetAmountRoundingPrecision, ValueMustEqualErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AverageCostCalcOverviewPageHandler(var AverageCostCalcOverview: TestPage "Average Cost Calc. Overview")
    begin
        AverageCostCalcOverview.Expand(true);
        VerifyAverageCostCalcOverview(AverageCostCalcOverview);
        AverageCostCalcOverview.Expand(true);
        AverageCostCalcOverview.Next();
        VerifyAverageCostCalcOverview(AverageCostCalcOverview);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReceiptLines.Invoke;
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke;
        ItemChargeAssignmentPurch.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptLinesPageHandler(var PurchReceiptLines: TestPage "Purch. Receipt Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PurchReceiptLines.FILTER.SetFilter("Document No.", DocumentNo);
        PurchReceiptLines.OK.Invoke;
    end;
}

