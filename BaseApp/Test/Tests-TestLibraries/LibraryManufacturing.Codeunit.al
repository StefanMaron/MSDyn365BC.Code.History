codeunit 132202 "Library - Manufacturing"
{
    // Unsupported version tags:
    // 
    // Contains all utility functions related to Manufacturing.


    trigger OnRun()
    begin
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        TemplateName: Label 'FOR. LABOR';
        BatchName: Label 'DEFAULT', Comment = 'Default Batch';

    procedure CalculateConsumption(ProductionOrderNo: Code[20]; ItemJournalTemplateName: Code[10]; ItemJournalBatchName: Code[10])
    var
        ProductionOrder: Record "Production Order";
        CalcConsumption: Report "Calc. Consumption";
        CalcBasedOn: Option "Actual Output","Expected Output";
    begin
        CalcConsumption.InitializeRequest(WorkDate(), CalcBasedOn::"Expected Output");
        CalcConsumption.SetTemplateAndBatchName(ItemJournalTemplateName, ItemJournalBatchName);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        CalcConsumption.SetTableView(ProductionOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
    end;

    procedure CalculateConsumptionForJournal(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; PostingDate: Date; ActualOutput: Boolean)
    var
        TmpProductionOrder: Record "Production Order";
        TmpProdOrderComponent: Record "Prod. Order Component";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        CalcConsumption: Report "Calc. Consumption";
        CalcBasedOn: Option "Actual Output","Expected Output";
    begin
        Commit();
        if ActualOutput then
            CalcBasedOn := CalcBasedOn::"Actual Output"
        else
            CalcBasedOn := CalcBasedOn::"Expected Output";
        CalcConsumption.InitializeRequest(PostingDate, CalcBasedOn);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Consumption);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        CalcConsumption.SetTemplateAndBatchName(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        if ProductionOrder.HasFilter then
            TmpProductionOrder.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            TmpProductionOrder.SetRange(Status, ProductionOrder.Status);
            TmpProductionOrder.SetRange("No.", ProductionOrder."No.");
        end;
        CalcConsumption.SetTableView(TmpProductionOrder);
        if ProdOrderComponent.HasFilter then
            TmpProdOrderComponent.CopyFilters(ProdOrderComponent)
        else begin
            ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
              ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
            TmpProdOrderComponent.SetRange(Status, ProdOrderComponent.Status);
            TmpProdOrderComponent.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
            TmpProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
            TmpProdOrderComponent.SetRange("Line No.", ProdOrderComponent."Line No.");
        end;
        CalcConsumption.SetTableView(TmpProdOrderComponent);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
    end;

    procedure CalculateMachCenterCalendar(var MachineCenter: Record "Machine Center"; StartingDate: Date; EndingDate: Date)
    var
        TmpMachineCenter: Record "Machine Center";
        CalcMachineCenterCalendar: Report "Calc. Machine Center Calendar";
    begin
        Commit();
        CalcMachineCenterCalendar.InitializeRequest(StartingDate, EndingDate);
        if MachineCenter.HasFilter then
            TmpMachineCenter.CopyFilters(MachineCenter)
        else begin
            MachineCenter.Get(MachineCenter."No.");
            TmpMachineCenter.SetRange("No.", MachineCenter."No.");
        end;
        CalcMachineCenterCalendar.SetTableView(TmpMachineCenter);
        CalcMachineCenterCalendar.UseRequestPage(false);
        CalcMachineCenterCalendar.RunModal();
    end;

    procedure CalculateWorksheetPlan(var Item: Record Item; OrderDate: Date; ToDate: Date)
    var
        TempItem: Record Item temporary;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        Commit();
        CalculatePlanPlanWksh.InitializeRequest(OrderDate, ToDate, false);
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.FindFirst();
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.FindFirst();
        CalculatePlanPlanWksh.SetTemplAndWorksheet(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, true);
        if Item.HasFilter then
            TempItem.CopyFilters(Item)
        else begin
            Item.Get(Item."No.");
            TempItem.SetRange("No.", Item."No.");
        end;
        CalculatePlanPlanWksh.SetTableView(TempItem);
        CalculatePlanPlanWksh.UseRequestPage(false);
        CalculatePlanPlanWksh.RunModal();
    end;

    procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    var
        RequisitionLine: Record "Requisition Line";
        CalculateSubcontracts: Report "Calculate Subcontracts";
    begin
        RequisitionLineForSubcontractOrder(RequisitionLine);
        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        CalculateSubcontracts.SetTableView(WorkCenter);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.RunModal();
    end;

    procedure CalculateWorkCenterCalendar(var WorkCenter: Record "Work Center"; StartingDate: Date; EndingDate: Date)
    var
        TmpWorkCenter: Record "Work Center";
        CalculateWorkCenterCalendarReport: Report "Calculate Work Center Calendar";
    begin
        Commit();
        CalculateWorkCenterCalendarReport.InitializeRequest(StartingDate, EndingDate);
        if WorkCenter.HasFilter then
            TmpWorkCenter.CopyFilters(WorkCenter)
        else begin
            WorkCenter.Get(WorkCenter."No.");
            TmpWorkCenter.SetRange("No.", WorkCenter."No.");
        end;
        CalculateWorkCenterCalendarReport.SetTableView(TmpWorkCenter);
        CalculateWorkCenterCalendarReport.UseRequestPage(false);
        CalculateWorkCenterCalendarReport.RunModal();
    end;

    procedure CalculateSubcontractOrderWithProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        RequisitionLine: Record "Requisition Line";
        TmpProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CalculateSubcontracts: Report "Calculate Subcontracts";
    begin
        if ProdOrderRoutingLine.HasFilter then
            TmpProdOrderRoutingLine.CopyFilters(ProdOrderRoutingLine)
        else begin
            ProdOrderRoutingLine.Get(ProdOrderRoutingLine."No.");
            TmpProdOrderRoutingLine.SetRange("No.", ProdOrderRoutingLine."No.");
        end;

        RequisitionLineForSubcontractOrder(RequisitionLine);
        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        CalculateSubcontracts.SetTableView(TmpProdOrderRoutingLine);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.RunModal();
    end;

    procedure ChangeProdOrderStatus(var ProductionOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean)
    var
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, NewStatus, PostingDate, UpdateUnitCost);
    end;

    procedure ChangeStatusPlannedToFinished(ProductionOrderNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrderNo);
        ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst();
        ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
        exit(ProductionOrder."No.");
    end;

    procedure ChangeStatusReleasedToFinished(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
    end;

    procedure ChangeProuctionOrderStatus(ProductionOrderNo: Code[20]; FromStatus: Enum "Production Order Status"; ToStatus: Enum "Production Order Status"): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(FromStatus, ProductionOrderNo);
        ChangeProdOrderStatus(ProductionOrder, ToStatus, WorkDate(), true);
        ProductionOrder.SetRange(Status, ToStatus);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst();
        exit(ProductionOrder."No.");
    end;

#if not CLEAN24
    [Obsolete('Moved implementation to ChangeProuctionOrderStatus method.', '24.0')]
    procedure ChangeStatusFirmPlanToReleased(ProductionOrderNo: Code[20]; FromStatus: Enum "Production Order Status"; ToStatus: Enum "Production Order Status"): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        exit(ChangeProuctionOrderStatus(ProductionOrderNo, FromStatus, ToStatus));
    end;
#endif
    procedure ChangeStatusFirmPlanToReleased(ProductionOrderNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        exit(ChangeProuctionOrderStatus(ProductionOrderNo, ProductionOrder.Status::"Firm Planned", ProductionOrder.Status::Released));
    end;

    procedure ChangeStatusSimulatedToReleased(ProductionOrderNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        exit(ChangeProuctionOrderStatus(ProductionOrderNo, ProductionOrder.Status::Simulated, ProductionOrder.Status::Released));
    end;

    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        CreateProductionOrder(ProductionOrder, ProdOrderStatus, SourceType, SourceNo, Quantity);
        RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    procedure CreateBOMComponent(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; Type: Enum "BOM Component Type"; No: Code[20]; QuantityPer: Decimal; UnitOfMeasureCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        BOMComponent.Init();
        BOMComponent.Validate("Parent Item No.", ParentItemNo);
        RecRef.GetTable(BOMComponent);
        BOMComponent.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BOMComponent.FieldNo("Line No.")));
        BOMComponent.Insert(true);
        BOMComponent.Validate(Type, Type);
        if BOMComponent.Type <> BOMComponent.Type::" " then begin
            BOMComponent.Validate("No.", No);
            BOMComponent.Validate("Quantity per", QuantityPer);
            if UnitOfMeasureCode <> '' then
                BOMComponent.Validate("Unit of Measure Code", UnitOfMeasureCode);
        end;
        BOMComponent.Modify(true);
    end;

    procedure CreateCalendarAbsenceEntry(var CalendarAbsenceEntry: Record "Calendar Absence Entry"; CapacityType: Enum "Capacity Type"; No: Code[20]; Date: Date; StartingTime: Time; EndingTime: Time; Capacity: Decimal)
    begin
        CalendarAbsenceEntry.Init();
        CalendarAbsenceEntry.Validate("Capacity Type", CapacityType);
        CalendarAbsenceEntry.Validate("No.", No);
        CalendarAbsenceEntry.Validate(Date, Date);
        CalendarAbsenceEntry.Validate("Starting Time", StartingTime);
        CalendarAbsenceEntry.Validate("Ending Time", EndingTime);
        CalendarAbsenceEntry.Insert(true);
        CalendarAbsenceEntry.Validate(Capacity, Capacity);
        CalendarAbsenceEntry.Modify(true);
    end;

    procedure CreateCapacityConstrainedResource(var CapacityConstrainedResource: Record "Capacity Constrained Resource"; CapacityType: Enum "Capacity Type"; CapacityNo: Code[20])
    begin
        Clear(CapacityConstrainedResource);
        CapacityConstrainedResource.Init();
        CapacityConstrainedResource.Validate("Capacity Type", CapacityType);
        CapacityConstrainedResource.Validate("Capacity No.", CapacityNo);
        CapacityConstrainedResource.Insert(true);
    end;

    procedure CreateCapacityUnitOfMeasure(var CapacityUnitOfMeasure: Record "Capacity Unit of Measure"; Type: Enum "Capacity Unit of Measure")
    begin
        CapacityUnitOfMeasure.Init();
        CapacityUnitOfMeasure.Validate(
          Code, LibraryUtility.GenerateRandomCode(CapacityUnitOfMeasure.FieldNo(Code), DATABASE::"Capacity Unit of Measure"));
        CapacityUnitOfMeasure.Insert(true);
        CapacityUnitOfMeasure.Validate(Type, Type);
        CapacityUnitOfMeasure.Modify(true);
    end;

    procedure CreateFamily(var Family: Record Family)
    begin
        Family.Init();
        Family.Validate("No.", LibraryUtility.GenerateRandomCode(Family.FieldNo("No."), DATABASE::Family));
        Family.Insert(true);
        Family.Validate(Description, Family."No.");
        Family.Modify(true);
    end;

    procedure CreateFamilyLine(var FamilyLine: Record "Family Line"; FamilyNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        RecRef: RecordRef;
    begin
        FamilyLine.Init();
        FamilyLine.Validate("Family No.", FamilyNo);
        RecRef.GetTable(FamilyLine);
        FamilyLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FamilyLine.FieldNo("Line No.")));
        FamilyLine.Insert(true);
        FamilyLine.Validate("Item No.", ItemNo);
        FamilyLine.Validate(Quantity, Qty);
        FamilyLine.Modify(true);
    end;

    procedure CreateItemManufacturing(var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; ReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        // Create Item extended for Manufacturing.
        LibraryInventory.CreateItemManufacturing(Item);
        Item.Validate("Costing Method", CostingMethod);
        if Item."Costing Method" = Item."Costing Method"::Standard then
            Item.Validate("Standard Cost", UnitCost)
        else begin
            Item.Validate("Unit Cost", UnitCost);
            Item.Validate("Last Direct Cost", Item."Unit Cost");
        end;

        Item.Validate("Reordering Policy", ReorderPolicy);
        Item.Validate("Flushing Method", FlushingMethod);

        if ProductionBOMNo <> '' then begin
            InventoryPostingSetup.FindLast();
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Routing No.", RoutingNo);
            Item.Validate("Production BOM No.", ProductionBOMNo);
            Item.Validate("Inventory Posting Group", InventoryPostingSetup."Invt. Posting Group Code");
        end;
        Item.Modify(true);
    end;

    procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20]; Capacity: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetupInvtToGL(GeneralPostingSetup);
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Machine Center Nos."));

        Clear(MachineCenter);
        MachineCenter.Insert(true);
        MachineCenter.Validate("Work Center No.", WorkCenterNo);
        MachineCenter.Validate(Capacity, Capacity);
        MachineCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        MachineCenter.Modify(true);
    end;

    procedure CreateMachineCenterWithCalendar(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20]; Capacity: Decimal)
    begin
        CreateMachineCenter(MachineCenter, WorkCenterNo, Capacity);
        CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    begin
        // Create Output Journal.
        if ItemJournalTemplate.Type <> ItemJournalTemplate.Type::Output then
            exit;
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Output;

        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type");
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Modify(true);
        Commit();
    end;

    procedure CreateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Qty: Decimal)
    begin
        ProdOrderLine.Init();
        ProdOrderLine.Validate(Status, ProdOrderStatus);
        ProdOrderLine.Validate("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.Validate("Line No.", LibraryUtility.GetNewRecNo(ProdOrderLine, ProdOrderLine.FieldNo("Line No.")));
        ProdOrderLine.Validate("Item No.", ItemNo);
        ProdOrderLine.Validate("Variant Code", VariantCode);
        ProdOrderLine.Validate("Location Code", LocationCode);
        ProdOrderLine.Validate(Quantity, Qty);

        ProdOrderLine.Insert(true);
    end;

    procedure CreateProductionBOMCommentLine(ProductionBOMLine: Record "Production BOM Line")
    var
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        LineNo: Integer;
    begin
        ProductionBOMCommentLine.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ProductionBOMCommentLine.SetRange("Version Code", ProductionBOMLine."Version Code");
        ProductionBOMCommentLine.SetRange("BOM Line No.", ProductionBOMLine."Line No.");
        if ProductionBOMCommentLine.FindLast() then;
        LineNo := ProductionBOMCommentLine."Line No." + 10000;

        ProductionBOMCommentLine.Init();
        ProductionBOMCommentLine.Validate("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ProductionBOMCommentLine.Validate("BOM Line No.", ProductionBOMLine."Line No.");
        ProductionBOMCommentLine.Validate("Version Code", ProductionBOMLine."Version Code");
        ProductionBOMCommentLine.Validate("Line No.", LineNo);
        ProductionBOMCommentLine.Validate(Comment, LibraryUtility.GenerateGUID());
        ProductionBOMCommentLine.Insert(true);
    end;

    procedure CreateProductionBOMHeader(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]): Code[20]
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Production BOM Nos."));

        Clear(ProductionBOMHeader);
        ProductionBOMHeader.Insert(true);
        ProductionBOMHeader.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateProductionBOMLine(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; VersionCode: Code[20]; Type: Enum "Production BOM Line Type"; No: Code[20]; QuantityPer: Decimal)
    var
        RecRef: RecordRef;
    begin
        ProductionBOMLine.Init();
        ProductionBOMLine.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.Validate("Version Code", VersionCode);
        RecRef.GetTable(ProductionBOMLine);
        ProductionBOMLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ProductionBOMLine.FieldNo("Line No.")));
        ProductionBOMLine.Insert(true);
        ProductionBOMLine.Validate(Type, Type);
        ProductionBOMLine.Validate("No.", No);
        ProductionBOMLine.Validate("Quantity per", QuantityPer);
        ProductionBOMLine.Modify(true);
    end;

    procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; QuantityPer: Decimal): Code[20]
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Item.Get(ItemNo);
        CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateCertifProdBOMWithTwoComp(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityPer: Decimal): Code[20]
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create Production BOM.
        Item.Get(ItemNo);
        CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, QuantityPer);
        UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateProductionBOMVersion(var ProductionBomVersion: Record "Production BOM Version"; BomNo: Code[20]; Version: Code[20]; UOMCode: Code[10])
    begin
        ProductionBomVersion.Init();
        ProductionBomVersion.Validate("Production BOM No.", BomNo);
        ProductionBomVersion.Validate("Version Code", Version);
        ProductionBomVersion.Insert(true);
        ProductionBomVersion.Validate("Unit of Measure Code", UOMCode);
        ProductionBomVersion.Modify(true);
    end;

    procedure CreateProductionBOMVersion(var ProductionBomVersion: Record "Production BOM Version"; BomNo: Code[20]; Version: Code[20]; UOMCode: Code[10]; StartingDate: Date)
    begin
        CreateProductionBOMVersion(ProductionBomVersion, BomNo, Version, UOMCode);
        ProductionBomVersion.Validate("Starting Date", StartingDate);
        ProductionBomVersion.Modify(true);
    end;

    procedure CreateProductionForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; ProductionForecastName: Code[10]; ItemNo: Code[20]; LocationCode: Code[10]; ForecastDate: Date; ComponentForecast: Boolean)
    begin
        Clear(ProductionForecastEntry);
        ProductionForecastEntry.Init();
        ProductionForecastEntry.Validate("Production Forecast Name", ProductionForecastName);
        ProductionForecastEntry.Validate("Item No.", ItemNo);
        ProductionForecastEntry.Validate("Location Code", LocationCode);
        ProductionForecastEntry.Validate("Forecast Date", ForecastDate);
        ProductionForecastEntry.Validate("Component Forecast", ComponentForecast);
        ProductionForecastEntry.Insert(true);
    end;

    procedure CreateProductionForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; ProductionForecastName: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ForecastDate: Date; ComponentForecast: Boolean)
    begin
        ProductionForecastEntry.Init();
        ProductionForecastEntry.Validate("Production Forecast Name", ProductionForecastName);
        ProductionForecastEntry.Validate("Item No.", ItemNo);
        ProductionForecastEntry.Validate("Variant Code", VariantCode);
        ProductionForecastEntry.Validate("Location Code", LocationCode);
        ProductionForecastEntry.Validate("Forecast Date", ForecastDate);
        ProductionForecastEntry.Validate("Component Forecast", ComponentForecast);
        ProductionForecastEntry.Insert(true);
    end;

    procedure CreateProductionForecastName(var ProductionForecastName: Record "Production Forecast Name")
    begin
        Clear(ProductionForecastName);
        ProductionForecastName.Init();
        ProductionForecastName.Validate(
          Name, LibraryUtility.GenerateRandomCode(ProductionForecastName.FieldNo(Name), DATABASE::"Production Forecast Name"));
        ProductionForecastName.Validate(Description, ProductionForecastName.Name);
        ProductionForecastName.Insert(true);
    end;

    procedure CreateProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        case Status of
            ProductionOrder.Status::Simulated:
                LibraryUtility.UpdateSetupNoSeriesCode(
                  DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Simulated Order Nos."));
            ProductionOrder.Status::Planned:
                LibraryUtility.UpdateSetupNoSeriesCode(
                  DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Planned Order Nos."));
            ProductionOrder.Status::"Firm Planned":
                LibraryUtility.UpdateSetupNoSeriesCode(
                  DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Firm Planned Order Nos."));
            ProductionOrder.Status::Released:
                LibraryUtility.UpdateSetupNoSeriesCode(
                  DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        end;

        Clear(ProductionOrder);
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, Status);
        ProductionOrder.Insert(true);
        ProductionOrder.Validate("Source Type", SourceType);
        ProductionOrder.Validate("Source No.", SourceNo);
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Modify(true);
    end;

    procedure CreateProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    var
        RecRef: RecordRef;
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent.Validate(Status, Status);
        ProdOrderComponent.Validate("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.Validate("Prod. Order Line No.", ProdOrderLineNo);
        RecRef.GetTable(ProdOrderComponent);
        ProdOrderComponent.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ProdOrderComponent.FieldNo("Line No.")));
        ProdOrderComponent.Insert(true);
    end;

    procedure CreateProductionOrderFromSalesOrder(SalesHeader: Record "Sales Header"; ProdOrderStatus: Enum "Production Order Status"; OrderType: Enum "Create Production Order Type")
    var
        SalesLine: Record "Sales Line";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
        EndLoop: Boolean;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            CreateProdOrderFromSale.CreateProductionOrder(SalesLine, ProdOrderStatus, OrderType);
            if OrderType = OrderType::ProjectOrder then
                EndLoop := true;
        until (SalesLine.Next() = 0) or EndLoop;
    end;

    procedure CreateRegisteredAbsence(var RegisteredAbsence: Record "Registered Absence"; CapacityType: Enum "Capacity Type"; No: Code[20]; Date: Date; StartingTime: Time; EndingTime: Time)
    begin
        RegisteredAbsence.Init();
        RegisteredAbsence.Validate("Capacity Type", CapacityType);
        RegisteredAbsence.Validate("No.", No);
        RegisteredAbsence.Validate(Date, Date);
        RegisteredAbsence.Validate("Starting Time", StartingTime);
        RegisteredAbsence.Validate("Ending Time", EndingTime);
        RegisteredAbsence.Insert(true);
    end;

    procedure CreateRoutingHeader(var RoutingHeader: Record "Routing Header"; Type: Option)
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Routing Nos."));

        Clear(RoutingHeader);
        RoutingHeader.Insert(true);
        RoutingHeader.Validate(Type, Type);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
    end;

    procedure CreateRoutingLine(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; VersionCode: Code[20]; OperationNo: Code[10]; Type: Enum "Capacity Type Routing"; No: Code[20])
    begin
        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingHeader."No.");
        RoutingLine.Validate("Version Code", VersionCode);
        if OperationNo = '' then
            OperationNo := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line");
        RoutingLine.Validate("Operation No.", OperationNo);
        RoutingLine.Insert(true);
        RoutingLine.Validate(Type, Type);
        RoutingLine.Validate("No.", No);
        RoutingLine.Modify(true);
    end;

    procedure CreateRoutingLineSetup(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; OperationNo: Code[10]; SetupTime: Decimal; RunTime: Decimal)
    begin
        // Create Routing Lines with required fields.
        CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type, CenterNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Concurrent Capacities", 1);
        RoutingLine.Modify(true);
    end;

    procedure CreateRoutingLink(var RoutingLink: Record "Routing Link")
    begin
        RoutingLink.Init();
        RoutingLink.Validate(Code, LibraryUtility.GenerateRandomCode(RoutingLink.FieldNo(Code), DATABASE::"Routing Link"));
        RoutingLink.Insert(true);
    end;

    procedure CreateQualityMeasure(var QualityMeasure: Record "Quality Measure")
    begin
        QualityMeasure.Init();
        QualityMeasure.Validate(Code, LibraryUtility.GenerateRandomCode(QualityMeasure.FieldNo(Code), DATABASE::"Quality Measure"));
        QualityMeasure.Insert(true);
    end;

    procedure CreateRoutingQualityMeasureLine(var RoutingQualityMeasure: Record "Routing Quality Measure"; RoutingLine: Record "Routing Line"; QualityMeasure: Record "Quality Measure")
    begin
        RoutingQualityMeasure.Init();
        RoutingQualityMeasure.Validate("Routing No.", RoutingLine."Routing No.");
        RoutingQualityMeasure.Validate("Operation No.", RoutingLine."Operation No.");
        RoutingQualityMeasure.Validate("Qlty Measure Code", QualityMeasure.Code);
        RoutingQualityMeasure.Insert(true);
    end;

    procedure CreateRoutingVersion(var RoutingVersion: Record "Routing Version"; RoutingNo: Code[20]; VersionCode: Code[20])
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion.Validate("Version Code", VersionCode);
        RoutingVersion.Insert(true);
    end;

    procedure CreateShopCalendarCode(var ShopCalendar: Record "Shop Calendar"): Code[10]
    begin
        ShopCalendar.Init();
        ShopCalendar.Validate(Code, LibraryUtility.GenerateRandomCode(ShopCalendar.FieldNo(Code), DATABASE::"Shop Calendar"));
        ShopCalendar.Insert(true);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateShopCalendarCustomTime(FromDay: Option; ToDay: Option; FromTime: Time; ToTime: Time): Code[10]
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
        ShopCalendarCode: Code[10];
        WorkShiftCode: Code[10];
        Day: Integer;
    begin
        // Create Shop Calendar Working Days.
        ShopCalendarCode := CreateShopCalendarCode(ShopCalendar);
        WorkShiftCode := CreateWorkShiftCode(WorkShift);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);

        for Day := FromDay to ToDay do
            CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, Day, WorkShiftCode, FromTime, ToTime);

        exit(ShopCalendarCode);
    end;

    procedure CreateShopCalendarWorkingDays(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; ShopCalendarCode: Code[10]; Day: Option; WorkShiftCode: Code[10]; StartingTime: Time; EndingTime: Time)
    begin
        ShopCalendarWorkingDays.Init();
        ShopCalendarWorkingDays.Validate("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.Validate(Day, Day);
        ShopCalendarWorkingDays.Validate("Starting Time", StartingTime);
        ShopCalendarWorkingDays.Validate("Ending Time", EndingTime);
        ShopCalendarWorkingDays.Validate("Work Shift Code", WorkShiftCode);
        ShopCalendarWorkingDays.Insert(true);
    end;

    procedure CreateStandardTask(var StandardTask: Record "Standard Task")
    begin
        StandardTask.Init();
        StandardTask.Validate(Code, LibraryUtility.GenerateRandomCode(StandardTask.FieldNo(Code), DATABASE::"Standard Task"));
        StandardTask.Insert(true);
    end;

    procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        CreateWorkCenterCustomTime(WorkCenter, 080000T, 160000T);
    end;

    procedure CreateWorkCenterCustomTime(var WorkCenter: Record "Work Center"; FromTime: Time; ToTime: Time)
    begin
        CreateWorkCenterWithoutShopCalendar(WorkCenter);
        WorkCenter.Validate(
          "Shop Calendar Code", UpdateShopCalendarWorkingDaysCustomTime(FromTime, ToTime));
        WorkCenter.Modify(true);
    end;

    procedure CreateWorkCenterFullWorkingWeek(var WorkCenter: Record "Work Center"; FromTime: Time; ToTime: Time)
    begin
        CreateWorkCenterWithoutShopCalendar(WorkCenter);
        WorkCenter.Validate(
          "Shop Calendar Code", UpdateShopCalendarFullWorkingWeekCustomTime(FromTime, ToTime));
        WorkCenter.Modify(true);
    end;

    procedure CreateWorkCenterGroup(var WorkCenterGroup: Record "Work Center Group")
    begin
        WorkCenterGroup.Init();
        WorkCenterGroup.Validate(Code, LibraryUtility.GenerateRandomCode(WorkCenterGroup.FieldNo(Code), DATABASE::"Work Center Group"));
        WorkCenterGroup.Insert(true);
    end;

    procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center")
    begin
        CreateWorkCenter(WorkCenter);
        CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreateWorkCenterWithoutShopCalendar(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenterGroup: Record "Work Center Group";
    begin
        CreateWorkCenterGroup(WorkCenterGroup);
        CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);
        LibraryERM.FindGeneralPostingSetupInvtToGL(GeneralPostingSetup);
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Manufacturing Setup", ManufacturingSetup.FieldNo("Work Center Nos."));

        Clear(WorkCenter);
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", WorkCenterGroup.Code);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    procedure CreateWorkShiftCode(var WorkShift: Record "Work Shift"): Code[10]
    begin
        WorkShift.Init();
        WorkShift.Validate(Code, LibraryUtility.GenerateRandomCode(WorkShift.FieldNo(Code), DATABASE::"Work Shift"));
        WorkShift.Insert(true);
        exit(WorkShift.Code);
    end;

    procedure OpenProductionJournal(ProductionOrder: Record "Production Order"; ProductionOrderLineNo: Integer)
    var
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProductionJournalMgt.Handling(ProductionOrder, ProductionOrderLineNo);
    end;

    procedure OutputJournalExplodeRouting(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
    end;

    procedure OutputJournalExplodeOrderLineRouting(var ItemJournalBatch: Record "Item Journal Batch"; ProdOrderLine: Record "Prod. Order Line"; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
    end;

    procedure PostConsumptionJournal()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Consumption);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    procedure PostOutputJournal()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    procedure RefreshProdOrder(var ProductionOrder: Record "Production Order"; Forward: Boolean; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; CreateInbRqst: Boolean)
    var
        TmpProductionOrder: Record "Production Order";
        RefreshProductionOrder: Report "Refresh Production Order";
        TempTransactionType: TransactionType;
        Direction: Option Forward,Backward;
    begin
        Commit();
        TempTransactionType := CurrentTransactionType;
        CurrentTransactionType(TRANSACTIONTYPE::Update);

        if Forward then
            Direction := Direction::Forward
        else
            Direction := Direction::Backward;
        if ProductionOrder.HasFilter then
            TmpProductionOrder.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            TmpProductionOrder.SetRange(Status, ProductionOrder.Status);
            TmpProductionOrder.SetRange("No.", ProductionOrder."No.");
        end;
        RefreshProductionOrder.InitializeRequest(Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst);
        RefreshProductionOrder.SetTableView(TmpProductionOrder);
        RefreshProductionOrder.UseRequestPage := false;
        RefreshProductionOrder.RunModal();

        Commit();
        CurrentTransactionType(TempTransactionType);
    end;

    procedure RunReplanProductionOrder(var ProductionOrder: Record "Production Order"; NewDirection: Option; NewCalcMethod: Option)
    var
        TmpProductionOrder: Record "Production Order";
        ReplanProductionOrder: Report "Replan Production Order";
    begin
        Commit();
        ReplanProductionOrder.InitializeRequest(NewDirection, NewCalcMethod);
        if ProductionOrder.HasFilter then
            TmpProductionOrder.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            TmpProductionOrder.SetRange(Status, ProductionOrder.Status);
            TmpProductionOrder.SetRange("No.", ProductionOrder."No.");
        end;
        ReplanProductionOrder.SetTableView(TmpProductionOrder);
        ReplanProductionOrder.UseRequestPage(false);
        ReplanProductionOrder.RunModal();
    end;

    procedure RunRollUpStandardCost(var Item: Record Item; StandardCostWorksheetName: Code[10])
    var
        Item2: Record Item;
        RollUpStandardCost: Report "Roll Up Standard Cost";
    begin
        Commit();
        if Item.HasFilter then
            Item2.CopyFilters(Item)
        else begin
            Item2.Get(Item."No.");
            Item2.SetRange("No.", Item."No.");
        end;
        RollUpStandardCost.SetTableView(Item2);
        RollUpStandardCost.SetStdCostWksh(StandardCostWorksheetName);
        RollUpStandardCost.UseRequestPage(false);
        RollUpStandardCost.RunModal();
    end;

    local procedure RequisitionLineForSubcontractOrder(var RequisitionLine: Record "Requisition Line")
    var
        ReqJnlManagement: Codeunit ReqJnlManagement;
        JnlSelected: Boolean;
        Handled: Boolean;
    begin
        ReqJnlManagement.WkshTemplateSelection(PAGE::"Subcontracting Worksheet", false, "Req. Worksheet Template Type"::"For. Labor", RequisitionLine, JnlSelected);
        if not JnlSelected then
            Error('');
        RequisitionLine."Worksheet Template Name" := TemplateName;
        RequisitionLine."Journal Batch Name" := BatchName;
        OnBeforeOpenJournal(RequisitionLine, Handled);
        if Handled then
            exit;
        ReqJnlManagement.OpenJnl(RequisitionLine."Journal Batch Name", RequisitionLine);
    end;

    procedure UpdateManufacturingSetup(var ManufacturingSetup: Record "Manufacturing Setup"; ShowCapacityIn: Code[10]; ComponentsAtLocation: Code[10]; DocNoIsProdOrderNo: Boolean; CostInclSetup: Boolean; DynamicLowLevelCode: Boolean)
    begin
        // Update Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Doc. No. Is Prod. Order No.", DocNoIsProdOrderNo);
        ManufacturingSetup.Validate("Cost Incl. Setup", CostInclSetup);
        ManufacturingSetup.Validate("Show Capacity In", ShowCapacityIn);
        ManufacturingSetup.Validate("Components at Location", ComponentsAtLocation);
        ManufacturingSetup.Validate("Dynamic Low-Level Code", DynamicLowLevelCode);
        ManufacturingSetup.Modify(true);
    end;

    procedure UpdateOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ProdOrderRoutingLine.SetRange("Routing No.", ItemJournalLine."Routing No.");
            case ItemJournalLine.Type of
                ItemJournalLine.Type::"Work Center":
                    ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
                ItemJournalLine.Type::"Machine Center":
                    ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
            end;
            ProdOrderRoutingLine.SetRange("No.", ItemJournalLine."No.");
            ProdOrderRoutingLine.FindFirst();
            ItemJournalLine.Validate("Setup Time", ProdOrderRoutingLine."Setup Time");
            ItemJournalLine.Validate("Run Time", ProdOrderRoutingLine."Run Time");
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    procedure UpdateProductionBOMStatus(var ProductionBOMHeader: Record "Production BOM Header"; NewStatus: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, NewStatus);
        ProductionBOMHeader.Modify(true);
    end;

    procedure UpdateProductionBOMVersionStatus(var ProductionBOMVersion: Record "Production BOM Version"; NewStatus: Enum "BOM Status")
    begin
        ProductionBOMVersion.Validate(Status, NewStatus);
        ProductionBOMVersion.Modify(true);
    end;

    procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; NewStatus: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, NewStatus);
        RoutingHeader.Modify(true);
    end;

    procedure UpdateShopCalendarFullWorkingWeekCustomTime(FromTime: Time; ToTime: Time): Code[10]
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        exit(CreateShopCalendarCustomTime(ShopCalendarWorkingDays.Day::Monday, ShopCalendarWorkingDays.Day::Sunday, FromTime, ToTime));
    end;

    procedure UpdateShopCalendarWorkingDays(): Code[10]
    begin
        // Create Shop Calendar Working Days using 8 hrs daily work shift.
        exit(UpdateShopCalendarWorkingDaysCustomTime(080000T, 160000T));
    end;

    procedure UpdateShopCalendarWorkingDaysCustomTime(FromTime: Time; ToTime: Time): Code[10]
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        exit(CreateShopCalendarCustomTime(ShopCalendarWorkingDays.Day::Monday, ShopCalendarWorkingDays.Day::Friday, FromTime, ToTime));
    end;

    [Normal]
    procedure UpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(ProdOrderLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProdOrderLine);
        ProdOrderLine.Modify(true);
    end;

    [Normal]
    procedure UpdateProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(ProdOrderComponent);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProdOrderComponent);
        ProdOrderComponent.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJournal(var RequisitionLine: Record "Requisition Line"; var Handled: Boolean)
    begin
    end;
}

