namespace Microsoft.Inventory.Planning;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;

codeunit 99000860 "Plng. Component Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromPlanComponent(var InventoryProfile: Record "Inventory Profile"; var PlanningComponent: Record "Planning Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        ReservedQty: Decimal;
        AutoReservedQty: Decimal;
    begin
        InventoryProfile.SetSource(
          Database::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
          PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
        InventoryProfile."Ref. Order Type" := PlanningComponent."Ref. Order Type";
        InventoryProfile."Ref. Order No." := PlanningComponent."Ref. Order No.";
        InventoryProfile."Ref. Line No." := PlanningComponent."Ref. Order Line No.";
        InventoryProfile."Item No." := PlanningComponent."Item No.";
        InventoryProfile."Variant Code" := PlanningComponent."Variant Code";
        InventoryProfile."Location Code" := PlanningComponent."Location Code";
        InventoryProfile."Bin Code" := PlanningComponent."Bin Code";
        InventoryProfile."Due Date" := PlanningComponent."Due Date";
        InventoryProfile."Due Time" := PlanningComponent."Due Time";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        InventoryProfile."Planning Level Code" := PlanningComponent."Planning Level Code";
        PlanningComponent.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        PlanningComponent.CalcFields("Reserved Qty. (Base)");
        InventoryProfile."Untracked Quantity" :=
          PlanningComponent."Expected Quantity (Base)" - PlanningComponent."Reserved Qty. (Base)" + AutoReservedQty;
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                if ProdOrderComponent.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.",
                     PlanningComponent."Line No.")
                then begin
                    InventoryProfile."Original Quantity" := ProdOrderComponent."Expected Quantity";
                    ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderComponent."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := ProdOrderComponent."Reserved Qty. (Base)";
                        ProdOrderComponent.SetReservationFilters(ReservationEntry);
                        InventoryProfile.CalcReservedQty(ReservationEntry, ReservedQty);
                        if ReservedQty > InventoryProfile."Untracked Quantity" then
                            InventoryProfile."Untracked Quantity" := 0
                        else
                            InventoryProfile."Untracked Quantity" := InventoryProfile."Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    InventoryProfile."Primary Order Type" := Database::"Planning Component";
                    InventoryProfile."Primary Order Status" := PlanningComponent."Ref. Order Status".AsInteger();
                    InventoryProfile."Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
            PlanningComponent."Ref. Order Type"::Assembly:
                if AssemblyLine.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.")
                then begin
                    InventoryProfile."Original Quantity" := AssemblyLine.Quantity;
                    AssemblyLine.CalcFields("Reserved Qty. (Base)");
                    if AssemblyLine."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := AssemblyLine."Reserved Qty. (Base)";
                        AssemblyLine.SetReservationFilters(ReservationEntry);
                        InventoryProfile.CalcReservedQty(ReservationEntry, ReservedQty);
                        if ReservedQty > InventoryProfile."Untracked Quantity" then
                            InventoryProfile."Untracked Quantity" := 0
                        else
                            InventoryProfile."Untracked Quantity" := InventoryProfile."Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    InventoryProfile."Primary Order Type" := Database::"Planning Component";
                    InventoryProfile."Primary Order Status" := PlanningComponent."Ref. Order Status".AsInteger();
                    InventoryProfile."Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
        end;
        InventoryProfile.Quantity := PlanningComponent."Expected Quantity";
        InventoryProfile."Remaining Quantity" := PlanningComponent."Expected Quantity";
        InventoryProfile."Finished Quantity" := 0;
        InventoryProfile."Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;

        OnAfterTransferInventoryProfileFromPlanningComponent(InventoryProfile, PlanningComponent);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromPlanComponent(InventoryProfile, PlanningComponent);
#endif 
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromPlanningComponent(var InventoryProfile: Record "Inventory Profile"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean; UseSecondaryFields: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then begin
            if UseSecondaryFields then begin
                RequisitionLine.Get(InventoryProfile."Source ID", InventoryProfile."Source Batch Name", InventoryProfile."Source Prod. Order Line");
                case RequisitionLine."Ref. Order Type" of
                    RequisitionLine."Ref. Order Type"::"Prod. Order":
                        ReservationEntry.SetSource(
                            Database::"Prod. Order Component", RequisitionLine."Ref. Order Status".AsInteger(),
                            InventoryProfile."Ref. Order No.", InventoryProfile."Source Ref. No.", '', InventoryProfile."Ref. Line No.");
                    RequisitionLine."Ref. Order Type"::Assembly:
                        ReservationEntry.SetSource(
                            Database::"Assembly Line", InventoryProfile."Source Order Status", InventoryProfile."Ref. Order No.",
                            InventoryProfile."Source Ref. No.", '', InventoryProfile."Ref. Line No.");
                end;
            end else
                ReservationEntry.SetSource(
                    Database::"Planning Component", 0, InventoryProfile."Source ID", InventoryProfile."Source Ref. No.",
                    InventoryProfile."Source Batch Name", InventoryProfile."Source Prod. Order Line");
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then
            InventoryProfile."Order Priority" := 600;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then
            InventoryProfile."Order Priority" := 300;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer; PlanMRP: Boolean)
    begin
        TransPlanningCompToProfile(InventoryProfile, Item, ReservEntry, NextLineNo, PlanMRP);
    end;

    local procedure TransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer; PlanMRP: Boolean)
    var
        PlanningComponent: Record "Planning Component";
#if not CLEAN25
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransPlanningCompToProfile(InventoryProfile, Item, IsHandled);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeTransPlanningCompToProfile(InventoryProfile, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if not PlanMRP then
            exit;

        if PlanningComponent.FindLinesWithItemToPlan(Item) then
            repeat
                if PlanningComponent."Due Date" <> 0D then begin
                    InventoryProfile.Init();
                    NextLineNo += 1;
                    InventoryProfile."Line No." := NextLineNo;
                    InventoryProfile."Item No." := Item."No.";
                    TransferInventoryProfileFromPlanComponent(InventoryProfile, PlanningComponent, TempReservationEntry);
                    if InventoryProfile.IsSupply then
                        InventoryProfile.ChangeSign();
                    OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(InventoryProfile, Item, NextLineNo);
                    InventoryProfile.Insert();
                end;
            until PlanningComponent.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;

}