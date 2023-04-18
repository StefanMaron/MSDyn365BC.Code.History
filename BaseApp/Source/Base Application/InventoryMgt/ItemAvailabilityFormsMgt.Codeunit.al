codeunit 353 "Item Availability Forms Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        ItemAvailByBOMLevel: Page "Item Availability by BOM Level";
        ForecastName: Code[10];
        AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM;
        QtyByUnitOfMeasure: Decimal;

        Text012: Label 'Do you want to change %1 from %2 to %3?', Comment = '%1=FieldCaption, %2=OldDate, %3=NewDate';

    procedure CalcItemPlanningFields(var Item: Record Item; CalculateTransferQuantities: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        with Item do begin
            Init();
            CalcFields(
              "Qty. on Purch. Order",
              "Qty. on Sales Order",
              "Qty. on Service Order",
              Inventory,
              "Net Change",
              "Scheduled Receipt (Qty.)",
              "Qty. on Component Lines",
              "Planned Order Receipt (Qty.)",
              "FP Order Receipt (Qty.)",
              "Rel. Order Receipt (Qty.)",
              "Planned Order Release (Qty.)",
              "Purch. Req. Receipt (Qty.)",
              "Planning Issues (Qty.)",
              "Purch. Req. Release (Qty.)");

            if JobPlanningLine.ReadPermission then
                CalcFields("Qty. on Job Order");
            CalcFields(
              "Qty. on Assembly Order",
              "Qty. on Asm. Component",
              "Qty. on Purch. Return",
              "Qty. on Sales Return");
            if CalculateTransferQuantities then
                CalcFields(
                  "Trans. Ord. Shipment (Qty.)",
                  "Qty. in Transit",
                  "Trans. Ord. Receipt (Qty.)");

            OnAfterCalcItemPlanningFields(Item);
        end;
    end;

    procedure CalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal)
    var
        TransOrdShipmentQty: Decimal;
        QtyinTransit: Decimal;
        TransOrdReceiptQty: Decimal;
    begin
        CalcItemPlanningFields(Item, true);

        with Item do begin
            if GetFilter("Location Filter") = '' then begin
                TransOrdShipmentQty := 0;
                QtyinTransit := 0;
                TransOrdReceiptQty := 0;
            end else begin
                TransOrdShipmentQty := "Trans. Ord. Shipment (Qty.)";
                QtyinTransit := "Qty. in Transit";
                TransOrdReceiptQty := "Trans. Ord. Receipt (Qty.)";
            end;
            GrossRequirement :=
                "Qty. on Sales Order" + "Qty. on Service Order" + "Qty. on Job Order" + "Qty. on Component Lines" +
                TransOrdShipmentQty + "Planning Issues (Qty.)" + "Qty. on Asm. Component" + "Qty. on Purch. Return";
            PlannedOrderReceipt :=
                "Planned Order Receipt (Qty.)" + "Purch. Req. Receipt (Qty.)";
            ScheduledReceipt :=
                "FP Order Receipt (Qty.)" + "Rel. Order Receipt (Qty.)" + "Qty. on Purch. Order" +
                QtyinTransit + TransOrdReceiptQty + "Qty. on Assembly Order" + "Qty. on Sales Return";
            OnCalculateNeedOnAfterCalcScheduledReceipt(Item, ScheduledReceipt, QtyinTransit, TransOrdReceiptQty);
            PlannedOrderReleases :=
                "Planned Order Release (Qty.)" + "Purch. Req. Release (Qty.)";
        end;
        OnAfterCalculateNeed(Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    local procedure CalcProjAvailableBalance(var Item: Record Item): Decimal
    var
        Item2: Record Item;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        Item2.Copy(Item);
        Item2.SetRange("Date Filter", 0D, Item.GetRangeMax("Date Filter"));
        CalculateNeed(Item2, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
        exit(Item2.Inventory + PlannedOrderReceipt + ScheduledReceipt - GrossRequirement);
    end;

    local procedure CalcProjAvailableBalance(Inventory: Decimal; GrossRequirement: Decimal; PlannedOrderReceipt: Decimal; ScheduledReceipt: Decimal): Decimal
    begin
        exit(Inventory + PlannedOrderReceipt + ScheduledReceipt - GrossRequirement);
    end;

    procedure CalcAvailQuantities(var Item: Record Item; IsBalanceAtDate: Boolean; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal)
    var
        AvailableMgt: Codeunit "Available Management";
    begin
        CalculateNeed(Item, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt, PlannedOrderReleases);
        if IsBalanceAtDate then
            ProjAvailableBalance :=
              CalcProjAvailableBalance(Item.Inventory, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt)
        else
            ProjAvailableBalance := CalcProjAvailableBalance(Item);

        OnAfterCalculateProjAvailableBalance(Item, ProjAvailableBalance);

        ExpectedInventory := AvailableMgt.ExpectedQtyOnHand(Item, true, 0, QtyAvailable, DMY2Date(31, 12, 9999));
    end;

    procedure CalcAvailQuantities(var Item: Record Item; IsBalanceAtDate: Boolean; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal; var AvailableInventory: Decimal)
    var
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        CalcAvailQuantities(
            Item, isBalanceAtDate, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
            PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, QtyAvailable);
        AvailableInventory := AvailableToPromise.CalcAvailableInventory(Item);
    end;

    procedure ShowItemLedgerEntries(var Item: Record Item; NetChange: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FindLinesWithItemToPlan(Item, NetChange);
        PAGE.Run(0, ItemLedgEntry);
    end;

    procedure ShowSalesLines(var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order);
        PAGE.Run(0, SalesLine);
    end;

    procedure ShowServLines(var Item: Record Item)
    var
        ServLine: Record "Service Line";
    begin
        ServLine.FindLinesWithItemToPlan(Item);
        PAGE.Run(0, ServLine);
    end;

    procedure ShowJobPlanningLines(var Item: Record Item)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.FindLinesWithItemToPlan(Item);
        PAGE.Run(0, JobPlanningLine);
    end;

    procedure ShowPurchLines(var Item: Record Item)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order);
        PAGE.Run(0, PurchLine);
    end;

    procedure ShowSchedReceipt(var Item: Record Item)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.FindLinesWithItemToPlan(Item, true);
        PAGE.Run(0, ProdOrderLine);
    end;

    procedure ShowSchedNeed(var Item: Record Item)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.FindLinesWithItemToPlan(Item, true);
        PAGE.Run(0, ProdOrderComp);
    end;

    procedure ShowTransLines(var Item: Record Item; What: Integer)
    var
        TransLine: Record "Transfer Line";
    begin
        case What of
            Item.FieldNo("Trans. Ord. Shipment (Qty.)"):
                TransLine.FindLinesWithItemToPlan(Item, false, false);
            Item.FieldNo("Qty. in Transit"),
          Item.FieldNo("Trans. Ord. Receipt (Qty.)"):
                TransLine.FindLinesWithItemToPlan(Item, true, false);
        end;
        PAGE.Run(0, TransLine);
    end;

    procedure ShowAsmOrders(var Item: Record Item)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
        PAGE.Run(0, AssemblyHeader);
    end;

    procedure ShowAsmCompLines(var Item: Record Item)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.FindItemToPlanLines(Item, AssemblyLine."Document Type"::Order);
        PAGE.Run(0, AssemblyLine);
    end;

    procedure ShowItemAvailLineList(var Item: Record Item; What: Integer)
    var
        ItemCopy: Record Item;
        ItemAvailLineList: Page "Item Availability Line List";
    begin
        ItemCopy.Copy(Item);
        CalcItemPlanningFields(ItemCopy, ItemCopy.GetFilter("Location Filter") <> '');
        IF QtyByUnitOfMeasure <> 0 THEN
            ItemAvailLineList.SetQtyByUnitOfMeasure(QtyByUnitOfMeasure);
        ItemAvailLineList.Init(What, ItemCopy);
        ItemAvailLineList.RunModal();
    end;

    procedure ShowItemAvailFromItem(var Item: Record Item; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with Item do begin
            TestField("No.");

            OnBeforeShowItemAvailFromItem(Item);
            case AvailabilityType of
                AvailabilityType::Date:
                    ShowItemAvailByDate(Item, '', NewDate, NewDate);
                AvailabilityType::Variant:
                    ShowItemAvailVariant(Item, '', NewVariantCode, NewVariantCode);
                AvailabilityType::Location:
                    ShowItemAvailByLoc(Item, '', NewLocationCode, NewLocationCode);
                AvailabilityType::"Event":
                    ShowItemAvailByEvent(Item, '', NewDate, NewDate, false);
                AvailabilityType::BOM:
                    ShowItemAvailByBOMLevel(Item, '', NewDate, NewDate);
                AvailabilityType::UOM:
                    ShowItemAvailByUOM(Item, '', NewUnitOfMeasureCode, NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromSalesLine(var SalesLine: Record "Sales Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
        IsHandled: Boolean;
    begin
        with SalesLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            Item.Reset();
            Item.Get("No.");
            FilterItem(Item, "Location Code", "Variant Code", "Shipment Date");

            IsHandled := false;
            OnBeforeShowItemAvailFromSalesLine(Item, SalesLine, IsHandled, AvailabilityType);
            if IsHandled then
                exit;

            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate) then
                        Validate("Shipment Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then begin
                        Validate("Variant Code", NewVariantCode);
                        ItemCheckAvail.SalesLineCheck(SalesLine);
                    end;
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then begin
                        Validate("Location Code", NewLocationCode);
                        ItemCheckAvail.SalesLineCheck(SalesLine);
                    end;
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate, false) then
                        Validate("Shipment Date", NewDate);
                AvailabilityType::BOM:
                    if AsmToOrderExists(AsmHeader) then
                        ShowItemAvailFromAsmHeader(AsmHeader, AvailabilityType)
                    else
                        if ShowItemAvailByBOMLevel(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate) then
                            Validate("Shipment Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromPurchLine(var PurchLine: Record "Purchase Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
        IsHandled: Boolean;
    begin
        with PurchLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            Item.Reset();
            Item.Get("No.");
            FilterItem(Item, "Location Code", "Variant Code", "Expected Receipt Date");

            IsHandled := false;
            OnBeforeShowItemAvailFromPurchLine(Item, PurchLine, IsHandled, AvailabilityType);
            if IsHandled then
                exit;

            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Expected Receipt Date"), "Expected Receipt Date", NewDate) then
                        Validate("Expected Receipt Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Expected Receipt Date"), "Expected Receipt Date", NewDate, false) then
                        Validate("Expected Receipt Date", NewDate);
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Expected Receipt Date"), "Expected Receipt Date", NewDate) then
                        Validate("Expected Receipt Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromReqLine(var ReqLine: Record "Requisition Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with ReqLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            Item.Reset();
            Item.Get("No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromReqLine(Item, ReqLine, AvailabilityType);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    begin
                        Item.SetRange("Date Filter");

                        ForecastName := '';
                        FindCurrForecastName(ForecastName);

                        if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, true) then
                            Validate("Due Date", NewDate);
                    end;
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with ProdOrderLine do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromProdOrderLine(Item, ProdOrderLine);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false) then
                        Validate("Due Date", NewDate);
                AvailabilityType::BOM:
                    if ShowCustomProdItemAvailByBOMLevel(ProdOrderLine, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with ProdOrderComp do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromProdOrderComp(Item, ProdOrderComp);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false) then
                        Validate("Due Date", NewDate);
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromTransLine(var TransLine: Record "Transfer Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with TransLine do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Transfer-from Code", "Variant Code", "Shipment Date");

            OnBeforeShowItemAvailFromTransLine(Item, TransLine, AvailabilityType);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate) then
                        Validate("Shipment Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Transfer-from Code"), "Transfer-from Code", NewLocationCode) then
                        Validate("Transfer-from Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate, false) then
                        Validate("Shipment Date", NewDate);
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Shipment Date"), "Shipment Date", NewDate) then
                        Validate("Shipment Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromWhseActivLine(var WhseActivLine: Record "Warehouse Activity Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with WhseActivLine do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromWhseActivLine(Item, WhseActivLine, AvailabilityType);
            case AvailabilityType of
                AvailabilityType::Date:
                    ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate);
                AvailabilityType::Variant:
                    ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false);
                AvailabilityType::BOM:
                    ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate);
                AvailabilityType::UOM:
                    ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromServLine(var ServLine: Record "Service Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        ServHeader: Record "Service Header";
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with ServLine do begin
            ServHeader.Get("Document Type", "Document No.");
            TestField(Type, Type::Item);
            TestField("No.");
            Item.Reset();
            Item.Get("No.");
            FilterItem(Item, "Location Code", "Variant Code", ServHeader."Response Date");

            OnBeforeShowItemAvailFromServLine(Item, ServLine);
            case AvailabilityType of
                AvailabilityType::Date:
                    ShowItemAvailByDate(Item, ServHeader.FieldCaption("Response Date"), ServHeader."Response Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    ShowItemAvailByEvent(Item, ServHeader.FieldCaption("Response Date"), ServHeader."Response Date", NewDate, false);
                AvailabilityType::BOM:
                    ShowItemAvailByBOMLevel(Item, ServHeader.FieldCaption("Response Date"), ServHeader."Response Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with WhseRcptLine do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromWhseRcptLine(Item, WhseRcptLine, AvailabilityType);
            case AvailabilityType of
                AvailabilityType::Date:
                    ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate);
                AvailabilityType::Variant:
                    ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false);
                AvailabilityType::BOM:
                    ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate);
                AvailabilityType::UOM:
                    ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with ItemJnlLine do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Posting Date");

            OnBeforeShowItemAvailFromItemJnlLine(Item, ItemJnlLine, AvailabilityType);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Posting Date"), "Posting Date", NewDate) then
                        Validate("Posting Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Posting Date"), "Posting Date", NewDate, false) then
                        Validate("Posting Date", NewDate);
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Posting Date"), "Posting Date", NewDate) then
                        Validate("Posting Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromAsmHeader(var AsmHeader: Record "Assembly Header"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with AsmHeader do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromAsmHeader(Item, AsmHeader);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false) then
                        Validate("Due Date", NewDate);
                AvailabilityType::BOM:
                    if ShowCustomAsmItemAvailByBOMLevel(AsmHeader, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromAsmLine(var AsmLine: Record "Assembly Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with AsmLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            Item.Reset();
            Item.Get("No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromAsmLine(Item, AsmLine);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, false) then
                        Validate("Due Date", NewDate);
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromPlanningComp(var PlanningComp: Record "Planning Component"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        with PlanningComp do begin
            TestField("Item No.");
            Item.Reset();
            Item.Get("Item No.");
            FilterItem(Item, "Location Code", "Variant Code", "Due Date");

            OnBeforeShowItemAvailFromPlanningComp(Item, PlanningComp);
            case AvailabilityType of
                AvailabilityType::Date:
                    if ShowItemAvailByDate(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::Variant:
                    if ShowItemAvailVariant(Item, FieldCaption("Variant Code"), "Variant Code", NewVariantCode) then
                        Validate("Variant Code", NewVariantCode);
                AvailabilityType::Location:
                    if ShowItemAvailByLoc(Item, FieldCaption("Location Code"), "Location Code", NewLocationCode) then
                        Validate("Location Code", NewLocationCode);
                AvailabilityType::"Event":
                    begin
                        ForecastName := '';
                        FindCurrForecastName(ForecastName);

                        if ShowItemAvailByEvent(Item, FieldCaption("Due Date"), "Due Date", NewDate, true) then
                            Validate("Due Date", NewDate);
                    end;
                AvailabilityType::BOM:
                    if ShowItemAvailByBOMLevel(Item, FieldCaption("Due Date"), "Due Date", NewDate) then
                        Validate("Due Date", NewDate);
                AvailabilityType::UOM:
                    if ShowItemAvailByUOM(Item, FieldCaption("Unit of Measure Code"), "Unit of Measure Code", NewUnitOfMeasureCode) then
                        Validate("Unit of Measure Code", NewUnitOfMeasureCode);
            end;
        end;
    end;

    procedure ShowItemAvailFromInvtDocLine(var InvtDocLine: Record "Invt. Document Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM)
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        CaptionText: Text[80];
    begin
        InvtDocLine.TestField("Item No.");
        Item.Reset();
        Item.Get(InvtDocLine."Item No.");
        FilterItem(Item, InvtDocLine."Location Code", InvtDocLine."Variant Code", InvtDocLine."Posting Date");

        case AvailabilityType of
            AvailabilityType::Date:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailByDate(Item, CaptionText, InvtDocLine."Posting Date", NewDate) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
            AvailabilityType::Variant:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Variant Code"), 1, 80);
#pragma warning disable AA0139 // required fix
                    if ShowItemAvailVariant(Item, CaptionText, InvtDocLine."Variant Code", NewVariantCode) then
                        InvtDocLine.Validate("Variant Code", NewVariantCode);
#pragma warning restore AA0139
                end;
            AvailabilityType::Location:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Location Code"), 1, 80);
#pragma warning disable AA0139 // required fix
                    if ShowItemAvailByLoc(Item, CaptionText, InvtDocLine."Location Code", NewLocationCode) then
                        InvtDocLine.Validate("Location Code", NewLocationCode);
#pragma warning restore AA0139
                end;
            AvailabilityType::"Event":
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailByEvent(Item, CaptionText, InvtDocLine."Posting Date", NewDate, false) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
            AvailabilityType::BOM:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailByBOMLevel(Item, CaptionText, InvtDocLine."Posting Date", NewDate) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
        end;
    end;

    procedure ShowItemAvailByEvent(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; IncludeForecast: Boolean): Boolean
    var
        ItemAvailByEvent: Page "Item Availability by Event";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailByEvent(Item, FieldCaption, OldDate, NewDate, IncludeForecast, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if FieldCaption <> '' then
            ItemAvailByEvent.LookupMode(true);
        ItemAvailByEvent.SetItem(Item);
        if IncludeForecast then begin
            ItemAvailByEvent.SetIncludePlan(true);
            if ForecastName <> '' then
                ItemAvailByEvent.SetForecastName(ForecastName);
        end;
        if ItemAvailByEvent.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByEvent.GetSelectedDate();
            if (NewDate <> 0D) and (NewDate <> OldDate) then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailByLoc(var Item: Record Item; FieldCaption: Text[80]; OldLocationCode: Code[20]; var NewLocationCode: Code[20]): Boolean
    var
        ItemAvailByLoc: Page "Item Availability by Location";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailByLoc(Item, FieldCaption, OldLocationCode, NewLocationCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.SetRange("Location Filter");
        if FieldCaption <> '' then
            ItemAvailByLoc.LookupMode(true);
        ItemAvailByLoc.SetRecord(Item);
        ItemAvailByLoc.SetTableView(Item);
        if ItemAvailByLoc.RunModal() = ACTION::LookupOK then begin
            NewLocationCode := ItemAvailByLoc.GetLastLocation();
            if OldLocationCode <> NewLocationCode then
                if Confirm(Text012, true, FieldCaption, OldLocationCode, NewLocationCode) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailByDate(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    var
        ItemAvailByPeriods: Page "Item Availability by Periods";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailByDate(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.SetRange("Date Filter");
        if FieldCaption <> '' then
            ItemAvailByPeriods.LookupMode(true);
        ItemAvailByPeriods.SetRecord(Item);
        ItemAvailByPeriods.SetTableView(Item);
        if ItemAvailByPeriods.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByPeriods.GetLastDate();
            if OldDate <> NewDate then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailVariant(var Item: Record Item; FieldCaption: Text[80]; OldVariant: Code[20]; var NewVariant: Code[20]): Boolean
    var
        ItemAvailByVariant: Page "Item Availability by Variant";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailVariant(Item, FieldCaption, OldVariant, NewVariant, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.SetRange("Variant Filter");
        if FieldCaption <> '' then
            ItemAvailByVariant.LookupMode(true);
        ItemAvailByVariant.SetRecord(Item);
        ItemAvailByVariant.SetTableView(Item);
        if ItemAvailByVariant.RunModal() = ACTION::LookupOK then begin
            NewVariant := ItemAvailByVariant.GetLastVariant();
            if OldVariant <> NewVariant then
                if Confirm(Text012, true, FieldCaption, OldVariant, NewVariant) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailByBOMLevel(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailByBOMLevel(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Clear(ItemAvailByBOMLevel);
        Item.SetRange("Date Filter");
        ItemAvailByBOMLevel.InitItem(Item);
        ItemAvailByBOMLevel.InitDate(OldDate);
        exit(ShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate));
    end;

    procedure ShowItemAvailByUOM(var Item: Record Item; FieldCaption: Text[80]; OldUoMCode: Code[10]; var NewUoMCode: Code[10]): Boolean
    var
        ItemAvailByUOM: Page "Item Availability by UOM";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailByUOM(Item, FieldCaption, OldUoMCode, NewUoMCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.SetRange("Base Unit of Measure");
        if FieldCaption <> '' then
            ItemAvailByUOM.LookupMode(true);
        ItemAvailByUOM.SetRecord(Item);
        ItemAvailByUOM.SetTableView(Item);
        if ItemAvailByUOM.RunModal() = ACTION::LookupOK then begin
            NewUoMCode := ItemAvailByUOM.GetLastUOM();
            if OldUoMCode <> NewUoMCode then
                if Confirm(Text012, true, FieldCaption, OldUoMCode, NewUoMCode) then
                    exit(true);
        end;
    end;

    local procedure ShowCustomAsmItemAvailByBOMLevel(var AsmHeader: Record "Assembly Header"; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    begin
        Clear(ItemAvailByBOMLevel);
        ItemAvailByBOMLevel.InitAsmOrder(AsmHeader);
        ItemAvailByBOMLevel.InitDate(OldDate);
        exit(ShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate));
    end;

    local procedure ShowCustomProdItemAvailByBOMLevel(var ProdOrderLine: Record "Prod. Order Line"; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    begin
        Clear(ItemAvailByBOMLevel);
        ItemAvailByBOMLevel.InitProdOrder(ProdOrderLine);
        ItemAvailByBOMLevel.InitDate(OldDate);
        exit(ShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate));
    end;

    local procedure ShowBOMLevelAbleToMake(FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    begin
        if FieldCaption <> '' then
            ItemAvailByBOMLevel.LookupMode(true);
        if ItemAvailByBOMLevel.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByBOMLevel.GetSelectedDate();
            if OldDate <> NewDate then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure SetQtyByUnitOfMeasure(NewQtyByUnitOfMeasure: Decimal);
    begin
        QtyByUnitOfMeasure := NewQtyByUnitOfMeasure;
    end;

    procedure FilterItem(var Item: Record Item; LocationCode: Code[20]; VariantCode: Code[20]; Date: Date)
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Date Filter", 0D, Date);
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);

        OnAfterFilterItem(Item, LocationCode, VariantCode, Date);
    end;

    procedure ByEvent(): Integer
    begin
        exit(AvailabilityType::"Event");
    end;

    procedure ByLocation(): Integer
    begin
        exit(AvailabilityType::Location);
    end;

    procedure ByVariant(): Integer
    begin
        exit(AvailabilityType::Variant);
    end;

    procedure ByPeriod(): Integer
    begin
        exit(AvailabilityType::Date);
    end;

    procedure ByBOM(): Integer
    begin
        exit(AvailabilityType::BOM);
    end;

    procedure ByUOM(): Integer
    begin
        exit(AvailabilityType::UOM);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateProjAvailableBalance(var Item: Record Item; var ProjAvailableBalance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByBOMLevel(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByDate(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByEvent(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var IncludeForecast: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByLoc(var Item: Record Item; FieldCaption: Text[80]; OldLocationCode: Code[20]; var NewLocationCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByUOM(var Item: Record Item; FieldCaption: Text[80]; OldUoMCode: Code[20]; var NewUoMCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromItemJnlLine(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromSalesLine(var Item: Record Item; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPurchLine(var Item: Record Item; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromServLine(var Item: Record Item; var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromReqLine(var Item: Record Item; var ReqLine: Record "Requisition Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderLine(var Item: Record Item; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderComp(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromTransLine(var Item: Record Item; var TransLine: Record "Transfer Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromWhseActivLine(var Item: Record Item; var WhseActivLine: Record "Warehouse Activity Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromWhseRcptLine(var Item: Record Item; var WhseRcptLine: Record "Warehouse Receipt Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmHeader(var Item: Record Item; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmLine(var Item: Record Item; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPlanningComp(var Item: Record Item; var PlanningComp: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailVariant(var Item: Record Item; FieldCaption: Text[80]; OldVariant: Code[20]; var NewVariant: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateNeedOnAfterCalcScheduledReceipt(var Item: Record Item; var ScheduledReceipt: Decimal; QtyinTransit: Decimal; TransOrdReceiptQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterItem(var Item: Record Item; LocationCode: Code[20]; VariantCode: Code[20]; Date: Date)
    begin
    end;
}

