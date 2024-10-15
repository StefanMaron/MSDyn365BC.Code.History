namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

codeunit 5996 "Prod. Order Warehouse Mgt."
{
    var
        Bin: Record Bin;
        Location: Record Location;
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WMSManagement: Codeunit "WMS Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Prod. Order Component" then begin
            ProdOrderComponent.Reset();
            ProdOrderComponent.SetRange(Status, SourceSubType);
            ProdOrderComponent.SetRange("Prod. Order No.", SourceNo);
            ProdOrderComponent.SetRange("Prod. Order Line No.", SourceLineNo);
            ProdOrderComponent.SetRange("Line No.", SourceSubLineNo);
            IsHandled := false;
#if not CLEAN23
            WMSManagement.RunOnShowSourceDocLineOnBeforeShowProdOrderComp(ProdOrderComponent, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, IsHandled);
#endif
            OnBeforeShowProdOrderComponents(ProdOrderComponent, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, IsHandled);
            if not IsHandled then
                case SourceSubType of
                    3: // Released
                        PAGE.RunModal(PAGE::"Prod. Order Comp. Line List", ProdOrderComponent);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        if SourceType in [Database::"Prod. Order Line", Database::"Prod. Order Component"] then
            if ProductionOrder.Get(SourceSubType, SourceNo) then begin
                ProductionOrder.SetRange(Status, SourceSubType);
                PAGE.RunModal(PAGE::"Released Production Order", ProductionOrder);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowWhseActivityDocLine', '', false, false)]
    local procedure OnAfterShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        if WhseActivityDocType = WhseActivityDocType::Production then
            ShowProdOrderLine(WhseDocNo, WhseDocLineNo);
    end;

    procedure ShowProdOrderLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", WhseDocNo);
        ProdOrderLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Prod. Order Line List", ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnCheckIfBinIsEligible', '', false, false)]
    local procedure OnCheckIfBinIsEligible(ItemJournalLine: Record "Item Journal Line"; var BinIsEligible: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ItemJournalLine."Order Type" = ItemJournalLine."Order Type"::Production then begin
            if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Output) then
                if ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.") then
                    BinIsEligible := (ItemJournalLine."Location Code" = ProdOrderLine."Location Code") and (ItemJournalLine."Bin Code" = ProdOrderLine."Bin Code");
            if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Consumption) then
                if ProdOrderComponent.Get(ProdOrderComponent.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.", ItemJournalLine."Prod. Order Comp. Line No.") then
                    BinIsEligible := (ItemJournalLine."Location Code" = ProdOrderComponent."Location Code") and (ItemJournalLine."Bin Code" = ProdOrderComponent."Bin Code");
        end;
    end;

    procedure CreateWhseJnlLineFromConsumptionJournal(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"): Boolean
    begin
        with ItemJournalLine do begin
            if Adjustment or
               ("Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation])
            then
                exit(false);

            TestField("Order Type", "Order Type"::Production);
            GetLocation("Location Code");
            TestField("Unit of Measure Code");
            WMSManagement.InitWhseJnlLine(ItemJournalLine, WarehouseJournalLine, "Quantity (Base)");
            SetZoneAndBinsForConsumption(ItemJournalLine, WarehouseJournalLine);
            WarehouseJournalLine.SetSource(DATABASE::"Item Journal Line", 4, "Order No.", "Order Line No.", "Prod. Order Comp. Line No."); // Consumption Journal
            WarehouseJournalLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WarehouseJournalLine."Source Type", WarehouseJournalLine."Source Subtype");
            WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Production, "Order No.", "Order Line No.");
            WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Prod.";
            WarehouseJournalLine."Reference No." := "Order No.";
            WMSManagement.TransferWhseItemTracking(WarehouseJournalLine, ItemJournalLine);
#if not CLEAN23
            WMSManagement.RunOnAfterCreateWhseJnlLineFromConsumJnl(WarehouseJournalLine, ItemJournalLine);
#endif
            OnAfterCreateWhseJnlLineFromConsumptionJournal(WarehouseJournalLine, ItemJournalLine);
        end;
    end;

    procedure CreateWhseJnlLineFromOutputJournal(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"): Boolean
    begin
        OnBeforeCreateWhseJnlLineFromOutputJournal(ItemJournalLine);
        with ItemJournalLine do begin
            if Adjustment or
               ("Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation])
            then
                exit(false);

            TestField("Order Type", "Order Type"::Production);
            GetLocation("Location Code");
            TestField("Unit of Measure Code");
            WMSManagement.InitWhseJnlLine(ItemJournalLine, WarehouseJournalLine, "Output Quantity (Base)");
            OnCreateWhseJnlLineFromOutputJournalOnAfterInitWhseJnlLine(WarehouseJournalLine, ItemJournalLine);
#if not CLEAN23
            WMSManagement.RunOnCreateWhseJnlLineFromOutputJnlOnAfterInitWhseJnlLine(WarehouseJournalLine, ItemJournalLine);
#endif
            SetZoneAndBinsForOutput(ItemJournalLine, WarehouseJournalLine);
            WarehouseJournalLine.SetSource(DATABASE::"Item Journal Line", 5, "Order No.", "Order Line No.", 0); // Output Journal
            WarehouseJournalLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WarehouseJournalLine."Source Type", WarehouseJournalLine."Source Subtype");
            WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Production, "Order No.", "Order Line No.");
            WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Prod.";
            WarehouseJournalLine."Reference No." := "Order No.";
            WMSManagement.TransferWhseItemTracking(WarehouseJournalLine, ItemJournalLine);
#if not CLEAN23
            WMSManagement.RunOnAfterCreateWhseJnlLineFromOutputJnl(WarehouseJournalLine, ItemJournalLine);
#endif
            OnAfterCreateWhseJnlLineFromOutputJournal(WarehouseJournalLine, ItemJournalLine);
        end;
    end;

    local procedure SetZoneAndBinsForConsumption(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WMSManagement.RunOnBeforeSetZoneAndBinsForConsumption(ItemJournalLine, ProdOrderComponent, WarehouseJournalLine, Location, IsHandled);
#endif
        OnBeforeSetZoneAndBinsForConsumption(ItemJournalLine, ProdOrderComponent, WarehouseJournalLine, Location, IsHandled);
        if IsHandled then
            exit;

        with ItemJournalLine do
            if GetProdOrderCompLine(
                 ProdOrderComponent, ProdOrderComponent.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.")
            then
                if Quantity > 0 then begin
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                    WarehouseJournalLine."From Bin Code" := "Bin Code";
                    if Location."Bin Mandatory" and (Location."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then begin
                        OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine, ProdOrderComponent);
#if not CLEAN23
                        WMSManagement.RunOnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine, ProdOrderComponent);
#endif
                        if (ProdOrderComponent."Planning Level Code" = 0) and
                           ((ProdOrderComponent."Flushing Method" = ProdOrderComponent."Flushing Method"::Manual) or
                            (ProdOrderComponent."Flushing Method" = ProdOrderComponent."Flushing Method"::"Pick + Backward") or
                            ((ProdOrderComponent."Flushing Method" = ProdOrderComponent."Flushing Method"::"Pick + Forward") and
                             (ProdOrderComponent."Routing Link Code" <> '')))
                        then
                            CheckProdOrderCompLineQtyPickedBase(ProdOrderComponent, ItemJournalLine);
                        GetBin("Location Code", WarehouseJournalLine."From Bin Code");
                        WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                        WarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";
                    end;
                end else begin
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                    WarehouseJournalLine."To Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WarehouseJournalLine."To Bin Code");
                        WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                    end;
                end
            else
                if Quantity > 0 then begin
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                    WarehouseJournalLine."From Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WarehouseJournalLine."From Bin Code");
                        WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                        WarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";
                    end;
                end else begin
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                    WarehouseJournalLine."To Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WarehouseJournalLine."To Bin Code");
                        WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                    end;
                end;
    end;

    local procedure SetZoneAndBinsForOutput(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        with ItemJournalLine do
            if "Output Quantity" >= 0 then begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                WarehouseJournalLine."To Bin Code" := "Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin("Location Code", WarehouseJournalLine."To Bin Code");
                    WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                end;
            end else begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                WarehouseJournalLine."From Bin Code" := "Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin("Location Code", WarehouseJournalLine."From Bin Code");
                    WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                end;
            end;
    end;

    procedure GetPlanningRtngLastOperationFromBinCode(WkshTemplateName: Code[10]; WkshBatchName: Code[10]; WkshLineNo: Integer; LocationCode: Code[10]): Code[20]
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        with PlanningRoutingLine do begin
            SetRange("Worksheet Template Name", WkshTemplateName);
            SetRange("Worksheet Batch Name", WkshBatchName);
            SetRange("Worksheet Line No.", WkshLineNo);
            if FindLast() then
                exit(GetProdCenterBinCode(Type, "No.", LocationCode, false, Enum::"Flushing Method Routing"::Manual));
        end;
    end;

    procedure GetProdCenterLocationCode(Type: Enum "Capacity Type"; No: Code[20]): Code[10]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case Type of
            Type::"Work Center":
                begin
                    WorkCenter.Get(No);
                    exit(WorkCenter."Location Code");
                end;
            Type::"Machine Center":
                begin
                    MachineCenter.Get(No);
                    exit(MachineCenter."Location Code");
                end;
        end;
    end;

    procedure GetProdCenterBinCode(Type: Enum "Capacity Type"; No: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    begin
        case Type of
            Type::"Work Center":
                exit(GetWorkCenterBinCode(No, LocationCode, UseFlushingMethod, FlushingMethod));
            Type::"Machine Center":
                exit(GetMachineCenterBinCode(No, LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    local procedure GetMachineCenterBinCode(MachineCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        MachineCenter: Record "Machine Center";
    begin
        if MachineCenter.Get(MachineCenterNo) then begin
            if MachineCenter."Location Code" = LocationCode then
                exit(MachineCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));

            exit(GetWorkCenterBinCode(MachineCenter."Work Center No.", LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    local procedure GetWorkCenterBinCode(WorkCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get(WorkCenterNo) then
            if WorkCenter."Location Code" = LocationCode then
                exit(WorkCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));
    end;

    procedure GetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]) Result: Boolean
    begin
        exit(WMSManagement.GetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode));
    end;

    local procedure GetProdOrderCompLine(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ProdOrdCompLineNo: Integer): Boolean
    begin
        if (ProdOrderNo = '') or
           (ProdOrderLineNo = 0) or
           (ProdOrdCompLineNo = 0)
        then
            exit(false);
        if (ProdOrderComponent.Status <> Status) or
            (ProdOrderComponent."Prod. Order No." <> ProdOrderNo) or
            (ProdOrderComponent."Prod. Order Line No." <> ProdOrderLineNo) or
            (ProdOrderComponent."Line No." <> ProdOrdCompLineNo)
        then begin
            if ProdOrderComponent.Get(Status, ProdOrderNo, ProdOrderLineNo, ProdOrdCompLineNo) then
                exit(true);

            exit(false);
        end;
        exit(true);
    end;

    local procedure CheckProdOrderCompLineQtyPickedBase(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WMSManagement.RunOnBeforeCheckProdOrderCompLineQtyPickedBase(ProdOrderComponent, ItemJournalLine, IsHandled);
#endif
        OnBeforeCheckProdOrderComponentQtyPickedBase(ProdOrderComponent, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderComponent."Qty. Picked (Base)" < ItemJournalLine."Quantity (Base)" then
            ProdOrderComponent.FieldError("Qty. Picked (Base)");
    end;

    procedure GetLastOperationFromBinCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", RoutingVersionCode);
        if RoutingLine.FindLast() then
            exit(GetProdCenterBinCode(RoutingLine.Type, RoutingLine."No.", LocationCode, UseFlushingMethod, FlushingMethod));
    end;

    procedure GetLastOperationLocationCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", RoutingVersionCode);
        if RoutingLine.FindLast() then
            exit(GetProdCenterLocationCode(RoutingLine.Type, RoutingLine."No."));
    end;

    procedure GetProdRoutingLastOperationFromBinCode(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingRefNo: Integer; RoutingNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        if ProdOrderRoutingLine.FindLast() then
            exit(
                GetProdCenterBinCode(
                    ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", LocationCode, false, Enum::"Flushing Method"::Manual));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
        Bin.TestField(Code);

        GetLocation(LocationCode);
        if Location."Directed Put-away and Pick" then
            Bin.TestField("Zone Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowProdOrderComponents(var ProdOrderComponent: Record "Prod. Order Component"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromConsumptionJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetZoneAndBinsForConsumption(ItemJournalLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component"; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLineFromOutputJournal(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineFromOutputJournalOnAfterInitWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderComponentQtyPickedBase(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromOutputJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    procedure ProdComponentVerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseValidateSourceLine.RunOnBeforeProdComponentVerifyChange(NewProdOrderComponent, OldProdOrderComponent, IsHandled);
#endif
        OnBeforeProdComponentVerifyChange(NewProdOrderComponent, OldProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Component", OldProdOrderComponent.Status, OldProdOrderComponent."Prod. Order No.",
             OldProdOrderComponent."Prod. Order Line No.", OldProdOrderComponent."Line No.", OldProdOrderComponent.Quantity)
        then begin
            NewRecordRef.GetTable(NewProdOrderComponent);
            OldRecordRef.GetTable(OldProdOrderComponent);
            if WhseValidateSourceLine.FieldValueIsChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(Status)) then begin
                if not WhseValidateSourceLine.WhseWorkSheetLinesExist(
                    Database::"Prod. Order Component", OldProdOrderComponent.Status, OldProdOrderComponent."Prod. Order No.",
                    OldProdOrderComponent."Prod. Order Line No.", OldProdOrderComponent."Line No.", OldProdOrderComponent.Quantity)
                then
                    exit;
            end else
                exit;
        end;

        NewRecordRef.GetTable(NewProdOrderComponent);
        OldRecordRef.GetTable(OldProdOrderComponent);
        with NewProdOrderComponent do begin
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo(Status));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Prod. Order No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Prod. Order Line No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Line No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Item No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Variant Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Location Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Unit of Measure Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Due Date"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo(Quantity));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Quantity per"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Expected Quantity"));
        end;

        OnAfterProdComponentVerifyChange(NewRecordRef, OldRecordRef);
#if not CLEAN23
        WhseValidateSourceLine.RunOnAfterProdComponentVerifyChange(NewRecordRef, OldRecordRef);
#endif
    end;

    procedure ProdComponentDelete(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Component",
             ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.",
             ProdOrderComponent."Line No.", ProdOrderComponent.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderComponent.TableCaption());

        if WhseValidateSourceLine.WhseWorkSheetLinesExist(
            Database::"Prod. Order Component",
            ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.",
            ProdOrderComponent."Line No.", ProdOrderComponent.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderComponent.TableCaption());

        OnAfterProdComponentDelete(ProdOrderComponent);
#if not CLEAN23
        WhseValidateSourceLine.RunOnAfterProdComponentDelete(ProdOrderComponent);
#endif
    end;

    procedure ProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if not WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Line", OldProdOrderLine.Status, OldProdOrderLine."Prod. Order No.",
             OldProdOrderLine."Line No.", 0, OldProdOrderLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewProdOrderLine);
        OldRecordRef.GetTable(OldProdOrderLine);
        with NewProdOrderLine do begin
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo(Status));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Prod. Order No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Line No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Item No."));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Variant Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Location Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Unit of Measure Code"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Due Date"));
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo(Quantity));
        end;

        OnAfterProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine, NewRecordRef, OldRecordRef);
    end;

    procedure ProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        with ProdOrderLine do
            if WhseValidateSourceLine.WhseLinesExist(
                 Database::"Prod. Order Line", Status, "Prod. Order No.", "Line No.", 0, Quantity)
            then
                WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderLine.TableCaption());

        OnAfterProdOrderLineDelete(ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentDelete(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdComponentVerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        ProductionOrder: Record "Production Order";
    begin
        case WarehouseRequest."Source Document" of
            Enum::"Warehouse Request Source Document"::"Prod. Consumption", Enum::"Warehouse Request Source Document"::"Prod. Output":
                begin
                    ProductionOrder.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Released Production Order", ProductionOrder);
                end;
        end;
    end;
}