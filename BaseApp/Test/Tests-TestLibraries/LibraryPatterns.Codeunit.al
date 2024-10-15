codeunit 132212 "Library - Patterns"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        TXTIncorrectEntry: Label 'Incorrect %1 in Entry No. %2.';
        TXTUnexpectedLine: Label 'Unexpected line after getting posted line to reverse.';
        TXTLineCountMismatch: Label 'Line count mismatch in revaluation for Item %1.';
        LibraryService: Codeunit "Library - Service";

    procedure ADDSerialNoTrackingInfo(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);

        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    procedure ASSIGNPurchChargeToPurchRcptLine(PurchaseHeader: Record "Purchase Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; Qty: Decimal; DirectUnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        MAKEItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, Qty, DirectUnitCost);

        PurchRcptLine.TestField(Type, PurchRcptLine.Type::Item);

        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          PurchRcptLine."No.", Qty, DirectUnitCost);
        ItemChargeAssignmentPurch.Insert();
    end;

    procedure ASSIGNPurchChargeToPurchInvoiceLine(PurchaseHeader: Record "Purchase Header"; PurchInvLine: Record "Purch. Inv. Line"; Qty: Decimal; DirectUnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        MAKEItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, Qty, DirectUnitCost);

        PurchInvLine.TestField(Type, PurchInvLine.Type::Item);

        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchInvLine."Document No.", PurchInvLine."Line No.",
          PurchInvLine."No.", Qty, DirectUnitCost);
        ItemChargeAssignmentPurch.Insert();
    end;

    procedure ASSIGNPurchChargeToPurchaseLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Qty: Decimal; DirectUnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine1: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        MAKEItemChargePurchaseLine(PurchaseLine1, ItemCharge, PurchaseHeader, Qty, DirectUnitCost);

        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);

        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine1, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
          PurchaseLine."Document No.", PurchaseLine."Line No.",
          PurchaseLine."No.", Qty, DirectUnitCost);
        ItemChargeAssignmentPurch.Insert();
    end;

    procedure ASSIGNPurchChargeToPurchReturnLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Qty: Decimal; DirectUnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine1: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        MAKEItemChargePurchaseLine(PurchaseLine1, ItemCharge, PurchaseHeader, Qty, DirectUnitCost);

        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);

        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine1, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Order",
          PurchaseLine."Document No.", PurchaseLine."Line No.",
          PurchaseLine."No.", Qty, DirectUnitCost);
        ItemChargeAssignmentPurch.Insert();
    end;

    procedure ASSIGNSalesChargeToSalesShptLine(SalesHeader: Record "Sales Header"; SalesShptLine: Record "Sales Shipment Line"; Qty: Decimal; UnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        MAKEItemChargeSalesLine(SalesLine, ItemCharge, SalesHeader, Qty, UnitCost);

        SalesShptLine.TestField(Type, SalesShptLine.Type::Item);

        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShptLine."Document No.", SalesShptLine."Line No.",
          SalesShptLine."No.", Qty, UnitCost);
        ItemChargeAssignmentSales.Insert();
    end;

    procedure ASSIGNSalesChargeToSalesLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Qty: Decimal; UnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        SalesLine1: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        MAKEItemChargeSalesLine(SalesLine1, ItemCharge, SalesHeader, Qty, UnitCost);

        SalesLine.TestField(Type, SalesLine.Type::Item);

        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine1, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
          SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."No.", Qty, UnitCost);
        ItemChargeAssignmentSales.Insert();
    end;

    procedure ASSIGNSalesChargeToSalesReturnLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Qty: Decimal; UnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        SalesLine1: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        MAKEItemChargeSalesLine(SalesLine1, ItemCharge, SalesHeader, Qty, UnitCost);

        SalesLine.TestField(Type, SalesLine.Type::Item);

        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine1, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Order",
          SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."No.", Qty, UnitCost);
        ItemChargeAssignmentSales.Insert();
    end;

    procedure MAKEConsumptionJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; ProdOrderLine: Record "Prod. Order Line"; ComponentItem: Record Item; PostingDate: Date; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        EntryType := ItemJournalLine."Entry Type"::"Negative Adjmt.";
        if ComponentItem.IsNonInventoriableType() then
            EntryType := ItemJournalLine."Entry Type"::Consumption;
        MAKEItemJournalLine(
          ItemJournalLine, ItemJournalBatch, ComponentItem, LocationCode, VariantCode, PostingDate,
          EntryType, Qty, 0);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        if ItemJournalLine."Location Code" <> LocationCode then // required for CH
            ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
    end;

    procedure MAKEItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; OverheadRate: Decimal; IndirectCostPercent: Decimal; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item."Costing Method" := CostingMethod;
        if Item."Costing Method" = Item."Costing Method"::Standard then
            Item."Standard Cost" := UnitCost;
        Item."Unit Cost" := UnitCost;
        Item."Overhead Rate" := OverheadRate;
        Item."Indirect Cost %" := IndirectCostPercent;
        Item."Item Tracking Code" := ItemTrackingCode;
        Item.Description := Item."No.";
        Item.Modify();
    end;

    procedure MAKEItemSimple(var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal)
    begin
        MAKEItem(Item, CostingMethod, UnitCost, 0, 0, '');
    end;

    procedure MAKEItemWithExtendedText(var Item: Record Item; ExtText: Text; CostingMethod: Enum "Costing Method"; UnitCost: Decimal)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        // Create Item.
        MAKEItem(Item, CostingMethod, UnitCost, 0, 0, '');
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify();

        // Create Extended Text Header and Line.
        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify();
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, CopyStr(ExtText, 1, MaxStrLen(ExtendedTextLine.Text)));
        ExtendedTextLine.Modify();
    end;

    procedure MAKEAdditionalItemUOM(var NewItemUOM: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPer: Decimal)
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUOM, ItemNo, QtyPer);
    end;

    procedure MAKEItemChargePurchaseLine(var PurchaseLine: Record "Purchase Line"; var ItemCharge: Record "Item Charge"; PurchaseHeader: Record "Purchase Header"; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    procedure MAKEItemChargeSalesLine(var SalesLine: Record "Sales Line"; var ItemCharge: Record "Item Charge"; SalesHeader: Record "Sales Header"; Qty: Decimal; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", Qty);
        SalesLine.Validate("Unit Price", UnitCost);
        SalesLine.Validate("Unit Cost", UnitCost);
        SalesLine.Modify(true);
    end;

    procedure MAKEItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; PostingDate: Date; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal; UnitAmount: Decimal)
    begin
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, PostingDate, EntryType, Qty);
        ItemJournalLine."Location Code" := LocationCode;
        ItemJournalLine."Variant Code" := VariantCode;
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Insert();
    end;

    procedure MAKEItemJournalLineWithApplication(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; PostingDate: Date; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal; UnitAmount: Decimal; AppltoEntryNo: Integer)
    begin
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, PostingDate, EntryType, Qty);
        ItemJournalLine."Location Code" := LocationCode;
        ItemJournalLine."Variant Code" := VariantCode;
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Applies-to Entry", AppltoEntryNo);
        ItemJournalLine.Insert();
    end;

    procedure MAKEItemReclassificationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; NewLocationCode: Code[10]; BinCode: Code[20]; NewBinCode: Code[20]; PostingDate: Date; Quantity: Decimal)
    begin
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, PostingDate, ItemJournalLine."Entry Type"::Transfer, Quantity);
        ItemJournalLine."Location Code" := LocationCode;
        ItemJournalLine."Variant Code" := VariantCode;
        ItemJournalLine."New Location Code" := NewLocationCode;
        ItemJournalLine."Bin Code" := BinCode;
        ItemJournalLine."New Bin Code" := NewBinCode;
        ItemJournalLine.Insert();
    end;

    procedure MAKEOutputJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; ProdOrderLine: Record "Prod. Order Line"; PostingDate: Date; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        RoutingLine: Record "Routing Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        Item.Get(ProdOrderLine."Item No.");
        MAKEItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, ProdOrderLine."Location Code", ProdOrderLine."Variant Code", PostingDate,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", 0, 0);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        if RoutingLine.FindFirst() then
            ItemJournalLine.Validate("Operation No.", RoutingLine."Operation No.");
        ItemJournalLine.Validate("Output Quantity", Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify();
    end;

    procedure MAKEProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ParentItem: Record Item; ChildItem: Record Item; ChildItemQtyPer: Decimal; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem."No.", ChildItemQtyPer);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify();

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify();
    end;

    procedure MAKEProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        NoSeries: Codeunit "No. Series";
        ProdNoSeries: Code[20];
    begin
        ProdNoSeries := LibraryUtility.GetGlobalNoSeriesCode();
        ManufacturingSetup.Get();
        case ProdOrderStatus of
            ProductionOrder.Status::Simulated:
                if ManufacturingSetup."Simulated Order Nos." <> ProdNoSeries then begin
                    ManufacturingSetup."Simulated Order Nos." := ProdNoSeries;
                    ManufacturingSetup.Modify();
                end;
            ProductionOrder.Status::Planned:
                if ManufacturingSetup."Planned Order Nos." <> ProdNoSeries then begin
                    ManufacturingSetup."Planned Order Nos." := ProdNoSeries;
                    ManufacturingSetup.Modify();
                end;
            ProductionOrder.Status::"Firm Planned":
                if ManufacturingSetup."Firm Planned Order Nos." <> ProdNoSeries then begin
                    ManufacturingSetup."Firm Planned Order Nos." := ProdNoSeries;
                    ManufacturingSetup.Modify();
                end;
            ProductionOrder.Status::Released:
                if ManufacturingSetup."Released Order Nos." <> ProdNoSeries then begin
                    ManufacturingSetup."Released Order Nos." := ProdNoSeries;
                    ManufacturingSetup.Modify();
                end;
        end;

        Clear(ProductionOrder);
        ProductionOrder."No." := NoSeries.GetNextNo(ProdNoSeries);
        ProductionOrder.Status := ProdOrderStatus;
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Validate(Quantity, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Insert(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.ModifyAll("Variant Code", VariantCode);
    end;

    procedure MAKEPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, '');
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine."Location Code" := LocationCode;
        PurchaseLine."Variant Code" := VariantCode;
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    procedure MAKEPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item, LocationCode, VariantCode, Qty, PostingDate,
          DirectUnitCost);
    end;

    procedure MAKEPurchaseQuote(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote,
          Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost);
    end;

    procedure MAKEPurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order",
          Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost);
    end;

    procedure MAKEPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", Item, LocationCode, VariantCode, Qty, PostingDate,
          DirectUnitCost);
    end;

    procedure MAKEPurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo",
          Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost);
    end;

    procedure MAKEPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal)
    begin
        MAKEPurchaseDoc(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Item, LocationCode, VariantCode, Qty, PostingDate,
          DirectUnitCost);
    end;

    procedure MAKERevaluationJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var Item: Record Item; NewPostingDate: Date; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewUpdStdCost: Boolean; NewCalcBase: Enum "Inventory Value Calc. Base")
    var
        ItemJournalLine: Record "Item Journal Line";
        NewDocNo: Code[20];
    begin
        NewDocNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line");
        RevaluationJournalCalcInventory(
          ItemJournalBatch, Item, NewPostingDate, NewDocNo, NewCalculatePer, NewByLocation, NewByVariant, NewUpdStdCost, NewCalcBase);
    end;

    procedure MAKERouting(var RoutingHeader: Record "Routing Header"; var Item: Record Item; RoutingLinkCode: Code[10]; DirectUnitCost: Decimal)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        WorkCenter.FindFirst();
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Modify();

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Modify();

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify();
    end;

    procedure MAKERoutingforWorkCenter(var RoutingHeader: Record "Routing Header"; var Item: Record Item; WorkCenterNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Modify();

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify();
    end;

    procedure MAKESalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine."Location Code" := LocationCode;
        SalesLine."Variant Code" := VariantCode;
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    procedure MAKESalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    begin
        MAKESalesDoc(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
    end;

    procedure MAKESalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    begin
        MAKESalesDoc(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
    end;

    procedure MAKESalesQuote(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    begin
        MAKESalesDoc(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
    end;

    procedure MAKESalesBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    begin
        MAKESalesDoc(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
    end;

    procedure MAKESalesReturnOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        MAKESalesDoc(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
        SalesLine.Validate("Unit Cost (LCY)", UnitCost);
        SalesLine.Modify();
    end;

    procedure MAKESalesCreditMemo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        MAKESalesDoc(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", Item,
          LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
        SalesLine.Validate("Unit Cost (LCY)", UnitCost);
        SalesLine.Modify();
    end;

    procedure MAKEStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        Clear(StockkeepingUnit);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", ItemVariant.Code);
        StockkeepingUnit."Unit Cost" := Item."Unit Cost";
        StockkeepingUnit."Standard Cost" := Item."Standard Cost";
        StockkeepingUnit.Modify();
    end;

    procedure MAKETransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Item: Record Item; FromLocation: Record Location; ToLocation: Record Location; InTransitLocation: Record Location; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; ShipmentDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferHeader.Validate("Posting Date", PostingDate);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify();
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Shipment Date", ShipmentDate);
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify();
    end;

    procedure POSTConsumption(ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        MAKEConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, Item, PostingDate, LocationCode, VariantCode, Qty, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTItemJournalLine(TemplateType: Enum "Item Journal Template Type"; EntryType: Enum "Item Ledger Entry Type"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, TemplateType);
        MAKEItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate, EntryType, Qty, UnitAmount);
        ItemJournalLine."Bin Code" := BinCode;
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTItemJournalLineWithApplication(TemplateType: Enum "Item Journal Template Type"; EntryType: Enum "Item Ledger Entry Type"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal; AppltoEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, TemplateType);
        MAKEItemJournalLineWithApplication(
          ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate, EntryType, Qty, UnitAmount, AppltoEntryNo);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTNegativeAdjustment(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        POSTItemJournalLine(ItemJournalTemplate.Type::Item,
          ItemJournalLine."Entry Type"::"Negative Adjmt.",
          Item,
          LocationCode,
          VariantCode,
          BinCode,
          Qty,
          PostingDate,
          UnitAmount);
    end;

    procedure POSTNegativeAdjustmentWithItemTracking(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; SerialNo: Code[50]; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        MAKEItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, 0);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTNegativeAdjustmentAmount(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; Amount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        MAKEItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, 0);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTOutput(ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; PostingDate: Date; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        Item.Get(ProdOrderLine."Item No.");
        MAKEOutputJournalLine(ItemJournalBatch, ProdOrderLine, PostingDate, Qty, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTOutputWithItemTracking(ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; RunTime: Decimal; PostingDate: Date; UnitCost: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        Item.Get(ProdOrderLine."Item No.");
        MAKEOutputJournalLine(ItemJournalBatch, ProdOrderLine, PostingDate, Qty, UnitCost);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Modify();
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTPositiveAdjustment(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        POSTItemJournalLine(ItemJournalTemplate.Type::Item,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item,
          LocationCode,
          VariantCode,
          BinCode,
          Qty,
          PostingDate,
          UnitAmount);
    end;

    procedure POSTPositiveAdjustmentAmount(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; Amount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        MAKEItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty, 0);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTPositiveAdjustmentWithItemTracking(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; SerialNo: Code[50]; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        MAKEItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty, 0);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTPurchaseJournal(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        POSTItemJournalLine(ItemJournalTemplate.Type::Item,
          ItemJournalLine."Entry Type"::Purchase,
          Item,
          LocationCode,
          VariantCode,
          BinCode,
          Qty,
          PostingDate,
          UnitAmount);
    end;

    procedure POSTPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal; Receive: Boolean; Invoice: Boolean)
    begin
        POSTPurchaseOrderPartially(PurchaseHeader, Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost, Receive, Qty, Invoice, Qty);
    end;

    procedure POSTPurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal; Receive: Boolean; Invoice: Boolean; SerialNo: Code[50]; LotNo: Code[50])
    var
        PurchaseLine: Record "Purchase Line";
        ReservEntry: Record "Reservation Entry";
    begin
        MAKEPurchaseOrder(PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost);
        PurchaseLine.Validate("Qty. to Receive", Qty);
        PurchaseLine.Validate("Qty. to Invoice", Qty);
        PurchaseLine.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservEntry, PurchaseLine, SerialNo, LotNo, Qty);
        if Invoice then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    procedure POSTPurchaseOrderPartially(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; DirectUnitCost: Decimal; Receive: Boolean; ReceiveQty: Decimal; Invoice: Boolean; InvoiceQty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        MAKEPurchaseOrder(PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, Qty, PostingDate, DirectUnitCost);
        PurchaseLine.Validate("Qty. to Receive", ReceiveQty);
        PurchaseLine.Validate("Qty. to Invoice", InvoiceQty);
        PurchaseLine.Modify();
        if Invoice then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    procedure POSTReclassificationJournalLine(Item: Record Item; StartDate: Date; FromLocationCode: Code[10]; ToLocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; NewBinCode: Code[20]; Quantity: Decimal)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Transfer);
        MAKEItemReclassificationJournalLine(ItemJnlLine, ItemJnlBatch, Item, VariantCode, FromLocationCode, ToLocationCode,
          BinCode, NewBinCode, StartDate, Quantity);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    procedure POSTSaleJournal(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        POSTItemJournalLine(ItemJournalTemplate.Type::Item,
          ItemJournalLine."Entry Type"::Sale,
          Item,
          LocationCode,
          VariantCode,
          BinCode,
          Qty,
          PostingDate,
          UnitAmount);
    end;

    procedure POSTSalesOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal; Ship: Boolean; Invoice: Boolean)
    begin
        POSTSalesOrderPartially(SalesHeader, Item, LocationCode, VariantCode, Qty, PostingDate, UnitCost, Ship, Qty, Invoice, Qty);
    end;

    procedure POSTSalesOrderPartially(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal; Ship: Boolean; ShipQty: Decimal; Invoice: Boolean; InvoiceQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        MAKESalesOrder(SalesHeader, SalesLine, Item, LocationCode, VariantCode, Qty, PostingDate, UnitCost);
        SalesLine.Validate("Qty. to Ship", ShipQty);
        SalesLine.Validate("Qty. to Invoice", InvoiceQty);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    procedure POSTTransferOrder(var TransferHeader: Record "Transfer Header"; Item: Record Item; FromLocation: Record Location; ToLocation: Record Location; InTransitLocation: Record Location; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; ShipmentDate: Date; Ship: Boolean; Receive: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        MAKETransferOrder(
          TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, VariantCode, Qty, PostingDate, ShipmentDate);
        LibraryWarehouse.PostTransferOrder(TransferHeader, Ship, Receive);
    end;

    procedure SETInventorySetup(AutomaticCostAdjustment: Option; AvgCostCalcType: Option; AvgCostPeriod: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Expected Cost Posting to G/L" := false;
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Validate("Average Cost Calc. Type", AvgCostCalcType);
        InventorySetup.Validate("Average Cost Period", AvgCostPeriod);
        InventorySetup.Modify();
    end;

    procedure SETNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Code[20];
    begin
        NoSeries := LibraryUtility.GetGlobalNoSeriesCode();

        InventorySetup.Get();
        if InventorySetup."Item Nos." <> NoSeries then begin
            InventorySetup.Validate("Item Nos.", NoSeries);
            InventorySetup.Modify();
        end;
        if InventorySetup."Transfer Order Nos." <> NoSeries then begin
            InventorySetup.Validate("Transfer Order Nos.", NoSeries);
            InventorySetup.Modify();
        end;

        ManufacturingSetup.Get();
        if ManufacturingSetup."Simulated Order Nos." <> NoSeries then begin
            ManufacturingSetup."Simulated Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Planned Order Nos." <> NoSeries then begin
            ManufacturingSetup."Planned Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Firm Planned Order Nos." <> NoSeries then begin
            ManufacturingSetup."Firm Planned Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Released Order Nos." <> NoSeries then begin
            ManufacturingSetup."Released Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Quote Nos." <> NoSeries then begin
            SalesReceivablesSetup."Quote Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Order Nos." <> NoSeries then begin
            SalesReceivablesSetup."Order Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Invoice Nos." <> NoSeries then begin
            SalesReceivablesSetup."Invoice Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Credit Memo Nos." <> NoSeries then begin
            SalesReceivablesSetup."Credit Memo Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Return Order Nos." <> NoSeries then begin
            SalesReceivablesSetup."Return Order Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Customer Nos." <> NoSeries then begin
            SalesReceivablesSetup."Customer Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;

        MarketingSetup.Get();
        if MarketingSetup."Contact Nos." <> NoSeries then begin
            MarketingSetup."Contact Nos." := NoSeries;
            MarketingSetup.Modify();
        end;
    end;

    local procedure GRPH1Outbound1Purchase(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean)
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Day1: Date;
        OutboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        OutboundQty := LibraryRandom.RandInt(10);
        POSTNegativeAdjustment(Item, LocationCode, VariantCode, '', OutboundQty, Day1, LibraryRandom.RandDec(100, 2));
        InsertTempILEFromLast(TempItemLedgerEntry);

        POSTPurchaseOrder(
          PurchaseHeader1, Item, LocationCode, VariantCode,
          LibraryRandom.RandIntInRange(OutboundQty, OutboundQty + LibraryRandom.RandInt(10)), Day1 + 1,
          LibraryRandom.RandDec(100, 2), true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        MAKEPurchaseOrder(
          PurchaseHeader2, PurchaseLine, Item, LocationCode, VariantCode, LibraryRandom.RandInt(10), Day1 + 2,
          LibraryRandom.RandDec(100, 2));
    end;

    procedure GRPH1Outbound1PurchRcvd(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        GRPH1Outbound1Purchase(TempItemLedgerEntry, PurchaseLine, Item, LocationCode, VariantCode, false);
    end;

    procedure GRPH1Outbound1PurchInvd(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        GRPH1Outbound1Purchase(TempItemLedgerEntry, PurchaseLine, Item, LocationCode, VariantCode, true);
    end;

    procedure GRPHPurchPartialRcvd1PurchReturn(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; var PurchaseLine1: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        Day1: Date;
        InboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        // Receive partially the Purchase Line, with or without invoicing.
        InboundQty := LibraryRandom.RandIntInRange(10, 20);
        MAKEPurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, InboundQty, Day1 + 2, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(PurchaseLine."Outstanding Quantity" - 5));
        PurchaseLine.Modify();
        if InvoicePurchase then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        // Repeat the receipt.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(PurchaseLine."Outstanding Quantity" - 1));
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        if InvoicePurchase then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        // Create Purchase Return Header and Line with 0 quantity. Actual qty to be added in calling test.
        MAKEPurchaseReturnOrder(
          PurchaseHeader1, PurchaseLine1, Item, LocationCode, VariantCode, 0, Day1 + 2, LibraryRandom.RandDec(100, 5));
    end;

    procedure GRPHPurchItemTracked(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; var ReservEntry: Record "Reservation Entry"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Day1: Date;
        InboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        InboundQty := LibraryRandom.RandInt(10);
        MAKEPurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, InboundQty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservEntry, PurchaseLine, '',
          CopyStr(LibraryUtility.GenerateRandomCode(ReservEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry"), 1, 10), InboundQty);
        if Invoice then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
        InsertTempILEFromLast(TempItemLedgerEntry);
    end;

    procedure GRPHSalesItemTracked(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var SalesLine: Record "Sales Line"; var ReservEntry: Record "Reservation Entry"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReservEntry2: Record "Reservation Entry";
        Day1: Date;
        OutboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        OutboundQty := LibraryRandom.RandInt(ReservEntry.Quantity);
        MAKESalesOrder(SalesHeader, SalesLine, Item, LocationCode, VariantCode, OutboundQty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry2, SalesLine, '', ReservEntry."Lot No.", OutboundQty);

        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
        ReservEntry := ReservEntry2;
        InsertTempILEFromLast(TempItemLedgerEntry);
    end;

    procedure GRPH3Purch1SalesItemTracked(var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean; InvoiceSales: Boolean)
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // Purchase 3 times.
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry2, Item, LocationCode, VariantCode, InvoicePurchase);
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry, Item, LocationCode, VariantCode, InvoicePurchase);
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry2, Item, LocationCode, VariantCode, InvoicePurchase);

        // Make the sales for the item tracking in 2nd purchase line
        GRPHSalesItemTracked(TempItemLedgerEntry, SalesLine, ReservEntry, Item, LocationCode, VariantCode, InvoiceSales);
    end;

    procedure GRPHSplitApplication(Item: Record Item; SalesLine: Record "Sales Line"; SalesLineSplit: Record "Sales Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QtyPurch1: Decimal;
        QtyPurch2: Decimal;
        QtySales1: Decimal;
        QtySales2: Decimal;
    begin
        QtyPurch1 := RandDec(10, 20, 2);
        QtyPurch2 := RandDec(10, 20, 2);
        QtySales1 := RandDec(0, QtyPurch1, 2);
        QtySales2 := RandDec(QtyPurch1 - QtySales1, QtyPurch1 - QtySales1 + QtyPurch2, 2);

        MAKEInbound(Item, QtyPurch1, WorkDate(), TempItemJournalLine);
        MAKEInbound(Item, QtyPurch2, WorkDate(), TempItemJournalLine);

        SHIPSales(SalesLine, Item, QtySales1, WorkDate());
        SHIPSales(SalesLineSplit, Item, QtySales2, WorkDate() + 1);
    end;

    procedure GRPHSeveralSplitApplicationWithCosts(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary; var Cost1: Decimal; var Cost2: Decimal; var Cost3: Decimal)
    var
        UnitCost1: Decimal;
        UnitCost2: Decimal;
        UnitCost3: Decimal;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        QtyOut1: Decimal;
        QtyOut2: Decimal;
        RemainingQty2: Decimal;
    begin
        Qty1 := RandDec(10, 20, 2);
        Qty2 := RandDec(10, 20, 2);
        Qty3 := RandDec(10, 20, 2);

        MAKEInbound(Item, Qty1, WorkDate(), TempItemJournalLine);
        UnitCost1 := TempItemJournalLine."Unit Amount";
        MAKEInbound(Item, Qty2, WorkDate() + 1, TempItemJournalLine);
        UnitCost2 := TempItemJournalLine."Unit Amount";
        MAKEInbound(Item, Qty3, WorkDate() + 2, TempItemJournalLine);
        UnitCost3 := TempItemJournalLine."Unit Amount";

        QtyOut1 := Qty1 + RandDec(0, Qty2 / 2, 2);
        RemainingQty2 := Qty2 + Qty1 - QtyOut1;
        QtyOut2 := RandDec(0, RemainingQty2, 2);

        MAKEOutbound(Item, QtyOut1, WorkDate() + 3, TempItemJournalLine);
        Cost1 := (Qty1 * UnitCost1 + (QtyOut1 - Qty1) * UnitCost2) / QtyOut1;
        MAKEOutbound(Item, QtyOut2, WorkDate() + 4, TempItemJournalLine);
        Cost2 := UnitCost2;

        RemainingQty2 -= QtyOut2;
        SHIPSales(SalesLine, Item, RemainingQty2 + RandDec(0, Qty3, 2), WorkDate() + 5);
        Cost3 := (RemainingQty2 * UnitCost2 + (SalesLine.Quantity - RemainingQty2) * UnitCost3) / SalesLine.Quantity;

        TempItemJournalLine.FindSet();
    end;

    procedure GRPHSplitJoinApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var SalesLineReturn: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        Qty: Decimal;
    begin
        Qty := RandDec(10, 20, 2);

        MAKEInbound(Item, Qty, WorkDate(), TempItemJournalLine);

        SHIPSales(SalesLine, Item, Qty / 2, WorkDate());
        POSTSalesLine(SalesLine, true, true);

        RECEIVESalesReturn(SalesLineReturn, SalesLine, WorkDate());
        SHIPSales(SalesLine, Item, Qty, WorkDate());
    end;

    procedure GRPHSeveralSplitApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        Unused: Decimal;
    begin
        GRPHSeveralSplitApplicationWithCosts(Item, SalesLine, TempItemJournalLine, Unused, Unused, Unused);
    end;

    procedure GRPHSalesOnly(Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        SHIPSales(SalesLine, Item, RandDec(10, 20, 2), WorkDate());
    end;

    procedure GRPHApplyInboundToUnappliedOutbound(var Item: Record Item; var SalesLine: Record "Sales Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QtyOut: Decimal;
        QtyIn1: Decimal;
        QtyIn2: Decimal;
    begin
        QtyOut := RandDec(10, 20, 2);
        QtyIn1 := RandDec(0, QtyOut / 2, 2);
        QtyIn2 := QtyOut - QtyIn1 + RandDec(0, 10, 2);

        SHIPSales(SalesLine, Item, QtyOut, WorkDate());

        MAKEInbound(Item, QtyIn1, WorkDate() - 1, TempItemJournalLine);
        MAKEInbound(Item, QtyIn2, WorkDate() - 2, TempItemJournalLine);
    end;

    procedure GRPHSimpleApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        QtyIn: Decimal;
    begin
        QtyIn := RandDec(10, 20, 2);
        MAKEInbound(Item, QtyIn, WorkDate(), TempItemJournalLine);
        SHIPSales(SalesLine, Item, RandDec(0, QtyIn, 2), WorkDate() + 1);
    end;

    procedure GRPHSalesReturnOnly(var Item: Record Item; var ReturnReceiptLine: Record "Return Receipt Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", RandDec(10, 20, 2));
        Commit();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptLine.SetFilter("No.", Item."No.");
        ReturnReceiptLine.FindLast();
    end;

    procedure GRPHSalesFromReturnReceipts(var Item: Record Item; var SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine1: Record "Return Receipt Line";
        ReturnReceiptLine2: Record "Return Receipt Line";
    begin
        GRPHSalesReturnOnly(Item, ReturnReceiptLine1);
        GRPHSalesReturnOnly(Item, ReturnReceiptLine2);
        SHIPSales(SalesLine, Item, ReturnReceiptLine1.Quantity + RandDec(0, ReturnReceiptLine2.Quantity, 2), WorkDate());
    end;

    procedure InsertTempILEFromLast(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.FindLast();
        TempItemLedgerEntry := ItemLedgerEntry;
        TempItemLedgerEntry.Insert();
    end;

    procedure CHECKValueEntry(var RefValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry")
    begin
        ValueEntry.TestField("Cost Amount (Expected)", RefValueEntry."Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", RefValueEntry."Cost Amount (Actual)");
        ValueEntry.TestField("Valued Quantity", RefValueEntry."Valued Quantity");
        ValueEntry.TestField("Cost per Unit", RefValueEntry."Cost per Unit");
        ValueEntry.TestField("Valuation Date", RefValueEntry."Valuation Date");
        ValueEntry.TestField("Entry Type", RefValueEntry."Entry Type");
        ValueEntry.TestField("Variance Type", RefValueEntry."Variance Type");
    end;

    procedure CHECKItemLedgerEntry(var RefItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        RefItemLedgerEntry.FindSet();
        ItemLedgerEntry.SetRange("Item No.", RefItemLedgerEntry."Item No.");
        ItemLedgerEntry.SetRange("Location Code", RefItemLedgerEntry."Location Code");
        ItemLedgerEntry.SetRange("Variant Code", RefItemLedgerEntry."Variant Code");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Cost Amount (Expected)", RefItemLedgerEntry."Cost Amount (Expected)");
            ItemLedgerEntry.TestField("Cost Amount (Actual)", RefItemLedgerEntry."Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Remaining Quantity", RefItemLedgerEntry."Remaining Quantity");
            ItemLedgerEntry.TestField("Invoiced Quantity", RefItemLedgerEntry."Invoiced Quantity");
            ItemLedgerEntry.TestField("Applies-to Entry", RefItemLedgerEntry."Applies-to Entry");
            RefItemLedgerEntry.Next();
        until ItemLedgerEntry.Next() = 0;
    end;

    procedure RandDec("Min": Decimal; "Max": Decimal; Precision: Integer): Decimal
    var
        Min2: Integer;
        Max2: Integer;
        Pow: Integer;
    begin
        Pow := Power(10, Precision);
        Min2 := Round(Min * Pow, 1);
        Max2 := Round(Max * Pow, 1);
        exit(Round(LibraryRandom.RandDecInRange(Min2, Max2, 1) / Pow, 1 / Pow));
    end;

    procedure RandCost(Item: Record Item): Decimal
    var
        Precision: Decimal;
    begin
        Precision := LibraryERM.GetAmountRoundingPrecision();
        if Item."Unit Cost" <> 0 then
            exit(Round(Item."Unit Cost" * RandDec(0, 2, 5), Precision));
        exit(Round(RandDec(0, 100, 5), Precision));
    end;

    local procedure SHIPSales(var SalesLine: Record "Sales Line"; Item: Record Item; Qty: Decimal; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Shipment Date", PostingDate);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure RECEIVESalesReturn(var SalesLineReturn: Record "Sales Line"; FromSalesLine: Record "Sales Line"; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        SalesShipmentLine.SetRange("Order No.", FromSalesLine."Document No.");
        SalesShipmentLine.FindFirst();
        CopyDocMgt.SetProperties(false, true, false, false, true, true, true);
        CopyDocMgt.CopySalesShptLinesToDoc(
          SalesHeader, SalesShipmentLine, LinesNotCopied, MissingExCostRevLink);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesLineReturn.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineReturn.SetRange("Document No.", SalesHeader."No.");
        SalesLineReturn.SetRange(Type, SalesLineReturn.Type::Item);
        Assert.AreEqual(1, SalesLineReturn.Count, TXTUnexpectedLine);
        SalesLineReturn.FindFirst();
    end;

    procedure CHECKCalcInvPost(Item: Record Item; ItemJnlBatch: Record "Item Journal Batch"; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        TempRefItemJnlLine: Record "Item Journal Line" temporary;
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Verify journal lines created by Calculate Inventory Value report
        CreateRefJnlforCalcInvPost(Item, TempRefItemJnlLine, PostingDate, CalculatePer, ByLocation, ByVariant, LocationFilter, VariantFilter);

        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJnlLine.SetRange("Item No.", Item."No.");

        Assert.AreEqual(TempRefItemJnlLine.Count, ItemJnlLine.Count, StrSubstNo(TXTLineCountMismatch, Item."No."));

        if CalculatePer = CalculatePer::Item then begin
            if ItemJnlLine.FindSet() then
                repeat
                    TempRefItemJnlLine.SetRange("Location Code", ItemJnlLine."Location Code");
                    TempRefItemJnlLine.SetRange("Variant Code", ItemJnlLine."Variant Code");
                    TempRefItemJnlLine.FindFirst();
                    Assert.AreEqual(
                      TempRefItemJnlLine.Quantity, ItemJnlLine.Quantity,
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName(Quantity), ItemJnlLine."Line No."));
                    Assert.AreEqual(TempRefItemJnlLine."Inventory Value (Calculated)", ItemJnlLine."Inventory Value (Calculated)",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Inventory Value (Calculated)"), ItemJnlLine."Line No."));
                until ItemJnlLine.Next() = 0;
        end else
            if ItemJnlLine.FindSet() then
                repeat
                    TempRefItemJnlLine.SetRange("Applies-to Entry", ItemJnlLine."Applies-to Entry");
                    TempRefItemJnlLine.FindFirst();
                    Assert.AreEqual(
                      TempRefItemJnlLine."Location Code", ItemJnlLine."Location Code",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Location Code"), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine."Variant Code", ItemJnlLine."Variant Code",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Variant Code"), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine.Quantity, ItemJnlLine.Quantity,
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName(Quantity), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine."Inventory Value (Calculated)", ItemJnlLine."Inventory Value (Calculated)",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Inventory Value (Calculated)"), ItemJnlLine."Applies-to Entry"));
                until ItemJnlLine.Next() = 0;
    end;

    local procedure CreateRefJnlforCalcInvPost(Item: Record Item; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempLocation: Record Location temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetFilter("Location Code", LocationFilter);
        ItemLedgerEntry.SetFilter("Variant Code", VariantFilter);
        ItemLedgerEntry.SetFilter("Posting Date", '<=%1', PostingDate);
        if Item."Costing Method" <> Item."Costing Method"::Standard then begin
            ItemLedgerEntry.SetRange("Completely Invoiced", true);
            ItemLedgerEntry.SetRange("Last Invoice Date", 0D, PostingDate);
        end;
        if CalculatePer = CalculatePer::Item then begin
            if LocationFilter <> '' then
                ByLocation := true;
            if VariantFilter <> '' then
                ByVariant := true;

            TempLocation.Code := '';
            TempLocation.Insert();
            TempItemVariant.Code := '';
            TempItemVariant.Insert();

            if ItemLedgerEntry.FindSet() then
                repeat
                    TempItemLedgerEntry := ItemLedgerEntry;
                    TempItemLedgerEntry.Insert();
                    TempLocation.Code := ItemLedgerEntry."Location Code";
                    if not TempLocation.Insert() then;
                    TempItemVariant.Code := ItemLedgerEntry."Variant Code";
                    if not TempItemVariant.Insert() then;
                until ItemLedgerEntry.Next() = 0;

            if ByLocation then begin
                TempLocation.FindSet();
                repeat
                    TempItemLedgerEntry.SetRange("Location Code", TempLocation.Code);
                    if ByVariant then begin
                        TempItemVariant.FindSet();
                        repeat
                            TempItemLedgerEntry.SetRange("Variant Code", TempItemVariant.Code);
                            CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                        until TempItemVariant.Next() = 0;
                    end else
                        CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                until TempLocation.Next() = 0;
            end else
                if ByVariant then begin
                    TempItemVariant.FindSet();
                    repeat
                        TempItemLedgerEntry.SetRange("Variant Code", TempItemVariant.Code);
                        CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                    until TempItemVariant.Next() = 0;
                end else
                    CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
        end else begin
            if ItemLedgerEntry.FindSet() then
                repeat
                    TempItemLedgerEntry := ItemLedgerEntry;
                    TempItemLedgerEntry.Insert();
                until ItemLedgerEntry.Next() = 0;
            CreateRefJournalLinePerILE(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate);
        end;
    end;

    local procedure CreateRefJournalLinePerItem(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date; ByLocation: Boolean; ByVariant: Boolean)
    var
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        RefQuantity: Decimal;
        RefCostAmount: Decimal;
    begin
        if TempItemLedgerEntry.FindSet() then
            repeat
                RefQuantity += TempItemLedgerEntry.Quantity;
                RefCostAmount += CalculateCostAtDate(TempItemLedgerEntry."Entry No.", PostingDate);
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", TempItemLedgerEntry."Entry No.");
                ItemApplicationEntry.SetFilter("Posting Date", '<=%1', PostingDate);
                if ItemApplicationEntry.FindSet() then
                    repeat
                        if (ItemApplicationEntry."Outbound Item Entry No." <> 0) and (ItemApplicationEntry.Quantity < 0) then begin
                            OutboundItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.");
                            RefQuantity += ItemApplicationEntry.Quantity;
                            RefCostAmount += CalculateCostAtDate(OutboundItemLedgerEntry."Entry No.", PostingDate) /
                              OutboundItemLedgerEntry.Quantity * ItemApplicationEntry.Quantity;
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until TempItemLedgerEntry.Next() = 0;

        if RefQuantity = 0 then
            exit;

        TempRefItemJnlLine."Line No." += 10000;
        TempRefItemJnlLine."Item No." := TempItemLedgerEntry."Item No.";
        if ByLocation then
            TempRefItemJnlLine."Location Code" := TempItemLedgerEntry."Location Code";
        if ByVariant then
            TempRefItemJnlLine."Variant Code" := TempItemLedgerEntry."Variant Code";
        TempRefItemJnlLine.Quantity := RefQuantity;
        TempRefItemJnlLine."Inventory Value (Calculated)" := Round(RefCostAmount, LibraryERM.GetAmountRoundingPrecision());
        TempRefItemJnlLine.Insert();
    end;

    local procedure CreateRefJournalLinePerILE(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if TempItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", TempItemLedgerEntry."Entry No.");
                ItemApplicationEntry.SetFilter("Posting Date", '<=%1', PostingDate);
                ItemApplicationEntry.CalcSums(Quantity);

                if ItemApplicationEntry.Quantity > 0 then begin
                    TempRefItemJnlLine."Line No." += 10000;
                    TempRefItemJnlLine."Item No." := TempItemLedgerEntry."Item No.";
                    TempRefItemJnlLine."Location Code" := TempItemLedgerEntry."Location Code";
                    TempRefItemJnlLine."Variant Code" := TempItemLedgerEntry."Variant Code";

                    TempRefItemJnlLine.Quantity := ItemApplicationEntry.Quantity;
                    TempRefItemJnlLine."Inventory Value (Calculated)" :=
                      Round(
                        CalculateCostAtDate(TempItemLedgerEntry."Entry No.", PostingDate) /
                        TempItemLedgerEntry.Quantity * ItemApplicationEntry.Quantity, LibraryERM.GetAmountRoundingPrecision());
                    TempRefItemJnlLine."Applies-to Entry" := TempItemLedgerEntry."Entry No.";
                    TempRefItemJnlLine.Insert();
                end;
            until TempItemLedgerEntry.Next() = 0;
    end;

    local procedure CalculateCostAtDate(ItemLedgerEntryNo: Integer; PostingDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetRange("Valuation Date", 0D, PostingDate);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
    end;

    procedure ExecutePostRevalueInboundILE(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Factor: Decimal)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        EntryNo: Integer;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryCosting.CheckAdjustment(Item);

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Revaluation);
        LibraryInventory.MakeItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, WorkDate(), ItemJnlLine."Entry Type"::Purchase, 0);
        TempItemLedgerEntry.FindFirst();
        EntryNo := TempItemLedgerEntry."Entry No.";
        ItemJnlLine.Validate("Applies-to Entry", EntryNo);
        ItemJnlLine.Validate("Inventory Value (Revalued)", ItemJnlLine."Inventory Value (Revalued)" * Factor);
        ItemJnlLine.Insert();

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    procedure CalculateInventoryValueRun(var ItemJnlBatch: Record "Item Journal Batch"; var Item: Record Item; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdStdCost: Boolean; CalcBase: Enum "Inventory Value Calc. Base"; ShowDialog: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        RevalueItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventoryValue: Report "Calculate Inventory Value";
        DocumentNo: Code[20];
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Revaluation);
        DocumentNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line");
        ItemJournalLine.Validate("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJnlBatch.Name);
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);
        RevalueItem.Copy(Item);
        if Item."No." <> '' then
            RevalueItem.SetRange("No.", Item."No.");
        CalculateInventoryValue.SetTableView(RevalueItem);
        CalculateInventoryValue.SetParameters(
          PostingDate, DocumentNo, true, CalculatePer, ByLocation, ByVariant, UpdStdCost, CalcBase, ShowDialog);
        CalculateInventoryValue.RunModal();
    end;

    procedure ModifyPostRevaluation(var ItemJnlBatch: Record "Item Journal Batch"; Factor: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate("Inventory Value (Revalued)",
                  Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    procedure ModifyAppliesToPostRevaluation(var ItemJnlBatch: Record "Item Journal Batch"; Factor: Decimal; AppliesToEntry: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate("Inventory Value (Revalued)",
                  Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Validate("Applies-to Entry", AppliesToEntry);
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    local procedure MAKEXBound(Item: Record Item; Qty: Decimal; Date: Date; EntryType: Enum "Item Ledger Entry Type"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, Date, EntryType, Qty);
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", Date);
        ItemJournalLine.Validate("Unit Amount", RandCost(Item));
        ItemJournalLine.Modify(true);

        TempItemJournalLine := ItemJournalLine;
        TempItemJournalLine.Insert();

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure MAKEInbound(Item: Record Item; Qty: Decimal; Date: Date; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        MAKEXBound(Item, Qty, Date, ItemJournalLine."Entry Type"::Purchase, TempItemJournalLine);
    end;

    local procedure MAKEOutbound(Item: Record Item; Qty: Decimal; Date: Date; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        MAKEXBound(Item, Qty, Date, ItemJournalLine."Entry Type"::Sale, TempItemJournalLine);
    end;

    procedure POSTSalesLine(SalesLine: Record "Sales Line"; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 < Value2 then
            exit(Value1);

        exit(Value2);
    end;

    procedure RevaluationJournalCalcInventory(var ItemJournalBatch: Record "Item Journal Batch"; var Item: Record Item; NewPostingDate: Date; NewDocNo: Code[20]; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewUpdStdCost: Boolean; NewCalcBase: Enum "Inventory Value Calc. Base")
    var
        TmpItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventoryValue: Report "Calculate Inventory Value";
        ItemJnlMgt: Codeunit ItemJnlManagement;
        JnlSelected: Boolean;
    begin
        Commit();
        CalculateInventoryValue.SetParameters(
            NewPostingDate, NewDocNo, true, NewCalculatePer, NewByLocation, NewByVariant,
            NewUpdStdCost, NewCalcBase, true);

        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);

        ItemJournalLine.Init();
        ItemJnlMgt.TemplateSelection(PAGE::"Revaluation Journal", 3, false, ItemJournalLine, JnlSelected); // 3 = FormTemplate::Revaluation
        ItemJnlMgt.OpenJnl(ItemJournalBatch.Name, ItemJournalLine);

        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);

        if Item.HasFilter then
            TmpItem.CopyFilters(Item)
        else begin
            Item.Get(Item."No.");
            TmpItem.SetRange("No.", Item."No.");
        end;
        CalculateInventoryValue.SetTableView(TmpItem);
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.RunModal();
    end;

    local procedure SetVendorDocNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
    end;
}

