codeunit 99000757 "Update Prod. Order Cost"
{

    trigger OnRun()
    begin
    end;

    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ServiceInvLine: Record "Service Line";

    procedure ModifySourceLineCost(ReservEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReqLine: Record "Requisition Line";
        QtyToReserveNonBase: Decimal;
        QtyToReserve: Decimal;
        QtyReservedNonBase: Decimal;
        QtyReserved: Decimal;
    begin
        if UnitCost = 0 then
            exit;

        if not ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
            exit;

        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
                    SalesLine.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
                    if SalesLine."Qty. per Unit of Measure" <> 0 then
                        SalesLine."Unit Cost (LCY)" :=
                          Round(SalesLine."Unit Cost (LCY)" / SalesLine."Qty. per Unit of Measure");
                    if SalesLine."Quantity (Base)" <> 0 then
                        SalesLine."Unit Cost (LCY)" :=
                          Round(
                            (SalesLine."Unit Cost (LCY)" *
                             (SalesLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / SalesLine."Quantity (Base)", 0.00001);
                    if SalesLine."Qty. per Unit of Measure" <> 0 then
                        SalesLine."Unit Cost (LCY)" :=
                          Round(SalesLine."Unit Cost (LCY)" * SalesLine."Qty. per Unit of Measure");
                    SalesLine.Validate("Unit Cost (LCY)");
                    SalesLine.Modify();
                end;
            DATABASE::"Requisition Line":
                begin
                    ReqLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
                    ReqLine.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
                    if ReqLine."Qty. per Unit of Measure" <> 0 then
                        ReqLine."Direct Unit Cost" :=
                          Round(ReqLine."Direct Unit Cost" / ReqLine."Qty. per Unit of Measure");
                    if ReqLine."Quantity (Base)" <> 0 then
                        ReqLine."Direct Unit Cost" :=
                          Round(
                            (ReqLine."Direct Unit Cost" *
                             (ReqLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / ReqLine."Quantity (Base)", 0.00001);
                    if ReqLine."Qty. per Unit of Measure" <> 0 then
                        ReqLine."Direct Unit Cost" :=
                          Round(ReqLine."Direct Unit Cost" * ReqLine."Qty. per Unit of Measure");
                    ReqLine.Validate("Direct Unit Cost");
                    ReqLine.Modify();
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
                    if PurchLine."Qty. per Unit of Measure" <> 0 then
                        PurchLine."Unit Cost (LCY)" :=
                          Round(PurchLine."Unit Cost (LCY)" / PurchLine."Qty. per Unit of Measure");
                    if PurchLine."Quantity (Base)" <> 0 then
                        PurchLine."Unit Cost (LCY)" :=
                          Round(
                            (PurchLine."Unit Cost (LCY)" *
                             (PurchLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / PurchLine."Quantity (Base)", 0.00001);
                    if PurchLine."Qty. per Unit of Measure" <> 0 then
                        PurchLine."Unit Cost (LCY)" :=
                          Round(PurchLine."Unit Cost (LCY)" * PurchLine."Qty. per Unit of Measure");
                    PurchLine.Validate("Unit Cost (LCY)");
                    PurchLine.Modify();
                end;
            DATABASE::"Item Journal Line":
                begin
                    ItemJnlLine.Get(
                      ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
                    if ItemJnlLine."Qty. per Unit of Measure" <> 0 then
                        ItemJnlLine."Unit Cost" :=
                          Round(ItemJnlLine."Unit Cost" / ItemJnlLine."Qty. per Unit of Measure");
                    if ItemJnlLine."Quantity (Base)" <> 0 then
                        ItemJnlLine."Unit Cost" :=
                          Round(
                            (ItemJnlLine."Unit Cost" *
                             (ItemJnlLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / ItemJnlLine."Quantity (Base)", 0.00001);
                    if ItemJnlLine."Qty. per Unit of Measure" <> 0 then
                        ItemJnlLine."Unit Cost" :=
                          Round(ItemJnlLine."Unit Cost" * ItemJnlLine."Qty. per Unit of Measure");
                    ItemJnlLine.Validate("Unit Cost");
                    ItemJnlLine.Modify();
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ProdOrderLine.Get(
                      ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line");
                    if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                        ProdOrderLine."Unit Cost" :=
                          Round(ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure");
                    if ProdOrderLine."Quantity (Base)" <> 0 then
                        ProdOrderLine."Unit Cost" :=
                          Round(
                            (ProdOrderLine."Unit Cost" *
                             (ProdOrderLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / ProdOrderLine."Quantity (Base)", 0.00001);
                    if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                        ProdOrderLine."Unit Cost" :=
                          Round(ProdOrderLine."Unit Cost" * ProdOrderLine."Qty. per Unit of Measure");
                    ProdOrderLine.Validate("Unit Cost");
                    ProdOrderLine.Modify();
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(
                      ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line",
                      ReservEntry."Source Ref. No.");
                    ProdOrderComp.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
                    if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                        ProdOrderComp."Unit Cost" :=
                          Round(ProdOrderComp."Unit Cost" / ProdOrderComp."Qty. per Unit of Measure");
                    if ProdOrderComp."Expected Qty. (Base)" <> 0 then
                        ProdOrderComp."Unit Cost" :=
                          Round(
                            (ProdOrderComp."Unit Cost" *
                             (ProdOrderComp."Expected Qty. (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / ProdOrderComp."Expected Qty. (Base)", 0.00001);
                    if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                        ProdOrderComp."Unit Cost" :=
                          Round(ProdOrderComp."Unit Cost" * ProdOrderComp."Qty. per Unit of Measure");
                    ProdOrderComp.Validate("Unit Cost");
                    ProdOrderComp.Modify();
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.Get(
                      ReservEntry."Source ID",
                      ReservEntry."Source Batch Name",
                      ReservEntry."Source Prod. Order Line",
                      ReservEntry."Source Ref. No.");
                    if PlanningComponent."Qty. per Unit of Measure" <> 0 then
                        PlanningComponent."Unit Cost" :=
                          Round(PlanningComponent."Unit Cost" / PlanningComponent."Qty. per Unit of Measure");
                    if PlanningComponent."Expected Quantity (Base)" <> 0 then
                        PlanningComponent."Unit Cost" :=
                          Round(
                            (PlanningComponent."Unit Cost" *
                             (PlanningComponent."Expected Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / PlanningComponent."Expected Quantity (Base)", 0.00001);
                    if PlanningComponent."Qty. per Unit of Measure" <> 0 then
                        PlanningComponent."Unit Cost" :=
                          Round(PlanningComponent."Unit Cost" * PlanningComponent."Qty. per Unit of Measure");
                    PlanningComponent.Validate("Unit Cost");
                    PlanningComponent.Modify();
                end;
            DATABASE::"Service Line":
                begin
                    ServiceInvLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
                    ServiceInvLine.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
                    if ServiceInvLine."Qty. per Unit of Measure" <> 0 then
                        ServiceInvLine."Unit Cost (LCY)" :=
                          Round(ServiceInvLine."Unit Cost (LCY)" / ServiceInvLine."Qty. per Unit of Measure");
                    if ServiceInvLine."Quantity (Base)" <> 0 then
                        ServiceInvLine."Unit Cost (LCY)" :=
                          Round(
                            (ServiceInvLine."Unit Cost (LCY)" *
                             (ServiceInvLine."Quantity (Base)" - QtyReserved) +
                             UnitCost * QtyReserved) / ServiceInvLine."Quantity (Base)", 0.00001);
                    if ServiceInvLine."Qty. per Unit of Measure" <> 0 then
                        ServiceInvLine."Unit Cost (LCY)" :=
                          Round(ServiceInvLine."Unit Cost (LCY)" * ServiceInvLine."Qty. per Unit of Measure");
                    ServiceInvLine.Validate("Unit Cost (LCY)");
                    ServiceInvLine.Modify();
                end;
        end;
    end;

    local procedure SumTrackingCosts(var ReservEntry: Record "Reservation Entry"; var TotalUnitCost: Decimal; var TotalCostQty: Decimal; Item: Record Item)
    begin
        TotalUnitCost := 0;
        TotalCostQty := 0;

        repeat
            ProdOrderComp.Get(
              ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
            if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                TotalUnitCost += Item."Unit Cost" * ReservEntry.Quantity;
            TotalCostQty += ReservEntry.Quantity;
        until ReservEntry.Next() = 0;
    end;

    procedure UpdateUnitCostOnProdOrder(var ProdOrderLine: Record "Prod. Order Line"; MultipleLevels: Boolean; UpdateReservation: Boolean)
    var
        Item: Record Item;
        ProdOrderComp: Record "Prod. Order Component";
        ReservEntry: Record "Reservation Entry";
        TotalCostQty: Decimal;
        TotalUnitCost: Decimal;
        UnitCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCostOnProdOrder(ProdOrderLine, MultipleLevels, UpdateReservation, IsHandled);
        if IsHandled then
            exit;

        if not Item.Get(ProdOrderLine."Item No.") then
            exit;

        if Item."Costing Method".AsInteger() > Item."Costing Method"::Average.AsInteger() then
            exit;

        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        if ProdOrderComp.Find('-') then
            repeat
                TotalCostQty := 0;
                TotalUnitCost := 0;
                Item.Get(ProdOrderComp."Item No.");
                OnUpdateUnitCostOnProdOrderOnAfterGetProdOrderCompItem(ProdOrderLine, ProdOrderComp, Item);
                if Item."Costing Method".AsInteger() <= Item."Costing Method"::Average.AsInteger() then begin
                    ReservEntry."Source Type" := DATABASE::"Prod. Order Component";
                    ReservEntry.InitSortingAndFilters(true);
                    ProdOrderComp.SetReservationFilters(ReservEntry);
                    if ReservEntry.Find('-') then
                        SumTrackingCosts(ReservEntry, TotalUnitCost, TotalCostQty, Item);
                    ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                    UpdateTotalUnitCostOnProdOrder(ProdOrderComp, Item, TotalUnitCost);
                    TotalCostQty :=
                      TotalCostQty +
                      (ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
                    if TotalCostQty <> 0 then begin
                        UnitCost := TotalUnitCost / TotalCostQty * ProdOrderComp."Qty. per Unit of Measure";
                        if ProdOrderComp."Unit Cost" <> UnitCost then begin
                            ProdOrderComp.Validate("Unit Cost", UnitCost);
                            ProdOrderComp.Modify();
                        end;
                    end;
                end;
            until ProdOrderComp.Next() = 0;

        ProdOrderLine.CalcFields(
          "Expected Operation Cost Amt.",
          "Total Exp. Oper. Output (Qty.)",
          "Expected Component Cost Amt.");

        if ProdOrderLine."Total Exp. Oper. Output (Qty.)" <> 0 then
            ProdOrderLine."Expected Operation Cost Amt." :=
              Round(
                ProdOrderLine."Expected Operation Cost Amt." /
                ProdOrderLine."Total Exp. Oper. Output (Qty.)" *
                ProdOrderLine.Quantity);

        OnUpdateUnitCostOnProdOrderOnBeforeValidateUnitCost(ProdOrderLine);
        ProdOrderLine.Validate(
          "Unit Cost",
          (ProdOrderLine."Expected Operation Cost Amt." + ProdOrderLine."Expected Component Cost Amt.") / ProdOrderLine.Quantity);

        OnUpdateUnitCostOnProdOrderOnAfterValidateUnitCost(ProdOrderLine);

        ProdOrderLine.Modify();
        if UpdateReservation then begin
            ReservEntry.Reset();
            ReservEntry."Source Type" := DATABASE::"Prod. Order Line";
            ReservEntry.InitSortingAndFilters(false);
            ProdOrderLine.SetReservationFilters(ReservEntry);
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                UnitCost := Round(ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure", 0.00001)
            else
                UnitCost := ProdOrderLine."Unit Cost";
            if ReservEntry.Find('-') then
                repeat
                    ModifySourceLineCost(ReservEntry, UnitCost);
                until ReservEntry.Next() = 0;
        end;
    end;

    local procedure UpdateTotalUnitCostOnProdOrder(var ProdOrderComp: Record "Prod. Order Component"; Item: Record Item; var TotalUnitCost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTotalUnitCostOnProdOrder(ProdOrderComp, TotalUnitCost, IsHandled);
        if IsHandled then
            exit;

        TotalUnitCost :=
            TotalUnitCost +
            (Item."Unit Cost" *
            (ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCostOnProdOrder(var ProdOrderLine: Record "Prod. Order Line"; MultipleLevels: Boolean; UpdateReservation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalUnitCostOnProdOrder(var ProdOrderComp: Record "Prod. Order Component"; var TotalUnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnAfterValidateUnitCost(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnAfterGetProdOrderCompItem(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnBeforeValidateUnitCost(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
}

