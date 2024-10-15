namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;

codeunit 928 "Assembly Line Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromAsmLine(var InventoryProfile: Record "Inventory Profile"; var AssemblyLine: Record "Assembly Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        InventoryProfile.SetSource(
            Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", '', 0);
        InventoryProfile."Ref. Order Type" := InventoryProfile."Ref. Order Type"::Assembly;
        InventoryProfile."Ref. Order No." := AssemblyLine."Document No.";
        InventoryProfile."Ref. Line No." := AssemblyLine."Line No.";
        InventoryProfile."Item No." := AssemblyLine."No.";
        InventoryProfile."Variant Code" := AssemblyLine."Variant Code";
        InventoryProfile."Location Code" := AssemblyLine."Location Code";
        InventoryProfile."Bin Code" := AssemblyLine."Bin Code";
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        AssemblyLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile.Quantity := AssemblyLine.Quantity;
        InventoryProfile."Remaining Quantity" := AssemblyLine."Remaining Quantity";
        InventoryProfile."Finished Quantity" := AssemblyLine."Consumed Quantity";
        InventoryProfile."Quantity (Base)" := AssemblyLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := AssemblyLine."Remaining Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;
        InventoryProfile."Due Date" := AssemblyLine."Due Date";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;

        OnAfterTransferInventoryProrileFromAssemblyLine(InventoryProfile, AssemblyLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromAsmLine(InventoryProfile, AssemblyLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProrileFromAssemblyLine(var InventoryProfile: Record "Inventory Profile"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Assembly Line" then begin
            if InventoryProfile."Source Order Status" = 4 then begin
                // Blanket Order will be marked as Surplus
                ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                ReservationEntry."Suppressed Action Msg." := true;
            end;
            ReservationEntry.SetSource(
                Database::"Assembly Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        TransAssemblyLineToProfile(InventoryProfile, Item, ReservEntry, NextLineNo);
    end;

    local procedure TransAssemblyLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReqLine: Record "Requisition Line";
        RemRatio: Decimal;
    begin
        if AssemblyLine.FindItemToPlanLines(Item, AssemblyLine."Document Type"::Order) then
            repeat
                if AssemblyLine."Due Date" <> 0D then begin
                    ReqLine.SetRefOrderFilters(
                      ReqLine."Ref. Order Type"::Assembly, AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", 0);
                    ReqLine.SetRange("Operation No.", '');
                    if not ReqLine.FindFirst() then
                        InsertAssemblyLineToProfile(InventoryProfile, AssemblyLine, 1, TempReservationEntry, NextLineNo);
                end;
            until AssemblyLine.Next() = 0;

        if AssemblyLine.FindItemToPlanLines(Item, AssemblyLine."Document Type"::"Blanket Order") then
            repeat
                if AssemblyLine."Due Date" <> 0D then begin
                    ReqLine.SetRefOrderFilters(
                        ReqLine."Ref. Order Type"::Assembly, AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", 0);
                    ReqLine.SetRange("Operation No.", '');
                    if not ReqLine.FindFirst() then begin
                        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
                        RemRatio := (AssemblyHeader."Quantity (Base)" - CalcSalesOrderQty(AssemblyLine)) / AssemblyHeader."Quantity (Base)";
                        InsertAssemblyLineToProfile(InventoryProfile, AssemblyLine, RemRatio, TempReservationEntry, NextLineNo);
                    end;
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure InsertAssemblyLineToProfile(var InventoryProfile: Record "Inventory Profile"; AssemblyLine: Record "Assembly Line"; RemRatio: Decimal; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        UOMMgt: Codeunit Microsoft.Foundation.UOM."Unit of Measure Management";
    begin
        InventoryProfile.Init();
        NextLineNo += 1;
        InventoryProfile."Line No." := NextLineNo;
        TransferInventoryProfileFromAsmLine(InventoryProfile, AssemblyLine, TempReservationEntry);
        if RemRatio <> 1 then begin
            InventoryProfile."Untracked Quantity" := Round(InventoryProfile."Untracked Quantity" * RemRatio, UOMMgt.QtyRndPrecision());
            InventoryProfile."Remaining Quantity (Base)" := InventoryProfile."Untracked Quantity";
        end;
        if InventoryProfile.IsSupply then
            InventoryProfile.ChangeSign();
        InventoryProfile.Insert();
    end;

    local procedure CalcSalesOrderQty(AssemblyLine: Record "Assembly Line") QtyOnSalesOrder: Decimal
    var
        SalesOrderLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        QtyOnSalesOrder := 0;
        ATOLink.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        SalesOrderLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange("Blanket Order No.", ATOLink."Document No.");
        SalesOrderLine.SetRange("Blanket Order Line No.", ATOLink."Document Line No.");
        if SalesOrderLine.Find('-') then
            repeat
                QtyOnSalesOrder += SalesOrderLine."Quantity (Base)";
            until SalesOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Assembly Line" then
            InventoryProfile."Order Priority" := 470;
    end;
}