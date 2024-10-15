namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;

codeunit 99000792 "Create Prod. Order from Sale"
{

    trigger OnRun()
    begin
    end;

    var
        UOMMgt: Codeunit "Unit of Measure Management";
        HideValidationDialog: Boolean;

        Text000: Label '%1 Prod. Order %2 has been created.';

    procedure CreateProductionOrder(SalesLine: Record "Sales Line"; ProdOrderStatus: Enum "Production Order Status"; OrderType: Enum "Create Production Order Type")
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
        ProdOrderRowID: Text[250];
        IsHandled: Boolean;
    begin
        ProdOrder.Init();
        ProdOrder.Status := ProdOrderStatus;
        ProdOrder."No." := '';
        OnCreateProdOrderOnBeforeProdOrderInsert(ProdOrder, SalesLine);
        ProdOrder.Insert(true);
        OnCreateProdOrderOnAfterProdOrderInsert(ProdOrder, SalesLine);

        ProdOrder."Starting Date" := WorkDate();
        ProdOrder."Creation Date" := WorkDate();
        ProdOrder."Low-Level Code" := 0;
        if OrderType = OrderType::ProjectOrder then begin
            ProdOrder."Source Type" := ProdOrder."Source Type"::"Sales Header";
            ProdOrder.Validate("Source No.", SalesLine."Document No.");
            ProdOrder."Due Date" := SalesLine."Shipment Date";
            ProdOrder."Ending Date" :=
              LeadTimeMgt.PlannedEndingDate(SalesLine."No.", SalesLine."Location Code", '', ProdOrder."Due Date", '', 2);
        end else begin
            OnCreateProductionOrderOnBeforeItemOrder(ProdOrder, SalesLine);
            ProdOrder."Due Date" := SalesLine."Shipment Date";
            ProdOrder."Source Type" := ProdOrder."Source Type"::Item;
            ProdOrder."Location Code" := SalesLine."Location Code";
            ProdOrder."Bin Code" := SalesLine."Bin Code";
            ProdOrder.Validate("Source No.", SalesLine."No.");
            ProdOrder.Validate("Variant Code", SalesLine."Variant Code");
            ProdOrder.Validate(Description, SalesLine.Description);
            SalesLine.CalcFields("Reserved Qty. (Base)");
            ProdOrder.Quantity := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)";
        end;
        OnAfterCreateProdOrderFromSalesLine(ProdOrder, SalesLine);
        ProdOrder.Modify();
        ProdOrder.SetRange("No.", ProdOrder."No.");

        IsHandled := false;
        OnBeforeCreateProdOrderLines(ProdOrder, SalesLine, IsHandled);
        if not IsHandled then begin
            CreateProdOrderLines.SetSalesLine(SalesLine);
            CreateProdOrderLines.Copy(ProdOrder, 1, SalesLine."Variant Code", false);
        end;

        IsHandled := false;
        OnCreateProdOrderOnBeforeProcessItemSourceType(ProdOrder, SalesLine, IsHandled);
        if not IsHandled then
            if ProdOrder."Source Type" = ProdOrder."Source Type"::Item then begin
                ProdOrderLine.SetRange(Status, ProdOrder.Status);
                ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");

                if ProdOrderLine.FindFirst() then begin
                    ProdOrderRowID :=
                      ItemTrackingMgt.ComposeRowID(
                        Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
                        ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0);
                    ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1(), ProdOrderRowID, true, true);

                    SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    if ProdOrderLine."Remaining Qty. (Base)" > (SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)")
                    then begin
                        ReservQty := (SalesLine."Outstanding Quantity" - SalesLine."Reserved Quantity");
                        ReservQtyBase := (SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)");
                    end else begin
                        ReservQty := Round(ProdOrderLine."Remaining Qty. (Base)" / SalesLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                        ReservQtyBase := ProdOrderLine."Remaining Qty. (Base)";
                    end;
                    SalesLineReserve.BindToProdOrder(SalesLine, ProdOrderLine, ReservQty, ReservQtyBase);
                    UpdateSalesLineReserve(SalesLine, ProdOrderLine);
                    OnCreateProductionOrderOnBeforeProdOrderLineModify(ProdOrderLine, SalesLine, ProdOrder, SalesLineReserve);
                    ProdOrderLine.Modify();
                    OnCreateProductionOrderOnAfterProdOrderLineModify(ProdOrderLine, SalesLine);
                end;
            end;

        if ProdOrder.Status = ProdOrder.Status::Released then
            ProdOrderStatusMgt.FlushProdOrder(ProdOrder, ProdOrder.Status, WorkDate());

        OnAfterCreateProdOrder(ProdOrder, SalesLine);

        if not HideValidationDialog then
            Message(
              Text000,
              ProdOrder.Status, ProdOrder."No.");
    end;

    local procedure UpdateSalesLineReserve(var SalesLine: Record "Sales Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLineReserve(SalesLine, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.Reserve = SalesLine.Reserve::Never then begin
            SalesLine.Reserve := SalesLine.Reserve::Optional;
            SalesLine.Modify();
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateProdOrder(var ProdOrder: Record "Production Order"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateProdOrderFromSalesLine(var ProdOrder: Record "Production Order"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateProdOrderLines(var ProdOrder: Record "Production Order"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineReserve(var SalesLine: Record "Sales Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderOnAfterProdOrderInsert(var ProductionOrder: Record "Production Order"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderOnBeforeProdOrderInsert(var ProductionOrder: Record "Production Order"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProductionOrderOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var SalesLine: Record "Sales Line"; var ProdOrder: Record "Production Order"; var SalesLineReserve: Codeunit "Sales Line-Reserve")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProductionOrderOnAfterProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderOnBeforeProcessItemSourceType(var ProdOrder: Record "Production Order"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProductionOrderOnBeforeItemOrder(var ProdOrder: Record "Production Order"; var SalesLine: Record "Sales Line")
    begin
    end;
}

