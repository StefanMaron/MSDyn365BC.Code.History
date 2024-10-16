namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;

codeunit 927 "Assembly Header Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromAssemblyHeader(var InventoryProfile: Record "Inventory Profile"; var AssemblyHeader: Record "Assembly Header"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        InventoryProfile.SetSource(
            Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, '', 0);
        InventoryProfile."Item No." := AssemblyHeader."Item No.";
        InventoryProfile."Variant Code" := AssemblyHeader."Variant Code";
        InventoryProfile."Location Code" := AssemblyHeader."Location Code";
        InventoryProfile."Bin Code" := AssemblyHeader."Bin Code";
        AssemblyHeader.SetReservationFilters(ReservationEntry);
        AutoReservedQty := InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        InventoryProfile."Untracked Quantity" := AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile."Min. Quantity" := AssemblyHeader."Reserved Qty. (Base)" - AutoReservedQty;
        InventoryProfile.Quantity := AssemblyHeader.Quantity;
        InventoryProfile."Remaining Quantity" := AssemblyHeader."Remaining Quantity";
        InventoryProfile."Finished Quantity" := AssemblyHeader."Assembled Quantity";
        InventoryProfile."Quantity (Base)" := AssemblyHeader."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := AssemblyHeader."Remaining Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := AssemblyHeader."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";
        InventoryProfile."Planning Flexibility" := AssemblyHeader."Planning Flexibility";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" >= 0;
        InventoryProfile."Due Date" := AssemblyHeader."Due Date";

        OnAfterTransferInventoryProfileFromAssemblyHeader(InventoryProfile, AssemblyHeader);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromAsmHeader(InventoryProfile, AssemblyHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromAssemblyHeader(var InventoryProfile: Record "Inventory Profile"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Assembly Header" then begin
            ReservationEntry.SetSource(
                Database::"Assembly Header", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Assembly Header" then
            InventoryProfile."Order Priority" := 320;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSupplyToInvProfile', '', false, false)]
    local procedure OnAfterSupplyToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer; var ToDate: Date)
    begin
        TransAssemblyHeaderToProfile(InventoryProfile, Item, ToDate, ReservEntry, NextLineNo);
    end;

    local procedure TransAssemblyHeaderToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var TempReservationEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order) then
            repeat
                if AssemblyHeader."Due Date" <> 0D then begin
                    InventoryProfile.Init();
                    NextLineNo += 1;
                    InventoryProfile."Line No." := NextLineNo;
                    TransferInventoryProfileFromAssemblyHeader(InventoryProfile, AssemblyHeader, TempReservationEntry);
                    if InventoryProfile."Finished Quantity" > 0 then
                        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
                    InventoryProfile.InsertSupplyInvtProfile(ToDate);
                end;
            until AssemblyHeader.Next() = 0;
    end;

}