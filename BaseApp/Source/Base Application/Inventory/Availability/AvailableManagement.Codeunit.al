namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Planning;

codeunit 5400 "Available Management"
{

    trigger OnRun()
    begin
    end;

    procedure ExpectedQtyOnHand(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date) ExpectedQty: Decimal
    var
        CopyOfItem: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcExpectedQtyOnHand(Item, CalcAvailable, ExtraNetNeed, Available, PlannedOrderReceiptDate, ExpectedQty, IsHandled);
        if IsHandled then
            exit(ExpectedQty);

        CopyOfItem.Copy(Item);

        Available := 0;
        if CalcAvailable then
            Available := CalcAvailableQty(Item, true, PlannedOrderReceiptDate) - ExtraNetNeed;
        Item.Copy(CopyOfItem);

        ExpectedQty := CalcAvailableQty(Item, false, 0D) - ExtraNetNeed;

        OnAfterCalcExpectedQty(Item, CalcAvailable, ExtraNetNeed, Available, PlannedOrderReceiptDate, ExpectedQty);

        exit(ExpectedQty);
    end;

    local procedure CalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date) AvailableQty: Decimal
    var
        CopyOfItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailableQty(Item, CalcAvailable, PlannedOrderReceiptDate, AvailableQty, IsHandled);
        if IsHandled then
            exit(AvailableQty);

        CopyOfItem.Copy(Item);
        with CopyOfItem do begin
            SetRange("Date Filter", 0D, GetRangeMax("Date Filter"));
            CalcFields(
              "Qty. on Purch. Order",
              "Scheduled Receipt (Qty.)",
              "Trans. Ord. Receipt (Qty.)",
              "Planned Order Receipt (Qty.)",
              "Qty. on Sales Return");

            if GetFilter("Location Filter") <> '' then
                CalcFields("Qty. in Transit");

            if CalcAvailable then
                SetRange("Date Filter", 0D, PlannedOrderReceiptDate);
            CalcFields(
              "Qty. on Sales Order",
              "Qty. on Component Lines",
              "Trans. Ord. Shipment (Qty.)",
              "Qty. on Service Order",
              "Qty. on Assembly Order",
              "Qty. on Purch. Return");

            if JobPlanningLine.ReadPermission then
                CalcFields("Qty. on Job Order");

            AvailableQty :=
              Inventory +
              "Qty. on Purch. Order" -
              "Qty. on Sales Order" -
              "Qty. on Component Lines" +
              "Planned Order Receipt (Qty.)" +
              "Scheduled Receipt (Qty.)" -
              "Trans. Ord. Shipment (Qty.)" +
              "Qty. in Transit" +
              "Trans. Ord. Receipt (Qty.)" -
              "Qty. on Service Order" -
              "Qty. on Job Order" -
              "Qty. on Purch. Return" +
              "Qty. on Assembly Order" +
              "Qty. on Sales Return";

            OnAfterCalcAvailableQty(Item, CalcAvailable, PlannedOrderReceiptDate, AvailableQty);

            exit(AvailableQty);
        end;
    end;

    procedure GetItemReorderQty(Item: Record Item; QtyAvailable: Decimal) ReorderQty: Decimal
    begin
        if Item."Reordering Policy" = Item."Reordering Policy"::" " then
            if Item."Maximum Inventory" <= 0 then begin
                if QtyAvailable > 0 then
                    QtyAvailable := 0;
                if Item."Reorder Quantity" > 0 then
                    ReorderQty :=
                      Round((Item."Reorder Point" - QtyAvailable) / Item."Reorder Quantity", 1, '>') *
                      Item."Reorder Quantity"
                else
                    ReorderQty := Item."Reorder Point" - QtyAvailable;
            end
            else
                if (Item."Reorder Point" > Item."Maximum Inventory") or
                   ((QtyAvailable + Item."Reorder Quantity") > Item."Maximum Inventory")
                then
                    ReorderQty := 0
                else
                    if Item."Reorder Quantity" > 0 then
                        ReorderQty :=
                          Round((Item."Maximum Inventory" - QtyAvailable) / Item."Reorder Quantity", 1, '<') *
                          Item."Reorder Quantity"
                    else
                        ReorderQty := Item."Maximum Inventory" - QtyAvailable
        else begin
            if Item."Reorder Point" > Item."Safety Stock Quantity" then begin
                if QtyAvailable > 0 then
                    QtyAvailable := 0;
                ReorderQty := Item."Reorder Point" - QtyAvailable
            end else
                ReorderQty := -QtyAvailable;

            if ReorderQty <= 0 then
                exit(0);

            ReorderQty := CalcReorderQty(Item, ReorderQty, QtyAvailable);
            ReorderQty += AdjustReorderQty(ReorderQty, Item);
        end;
    end;

    local procedure AdjustReorderQty(OrderQty: Decimal; Item: Record Item): Decimal
    var
        DeltaQty: Decimal;
        Rounding: Decimal;
    begin
        // Copy of AdjustReorderQty in COD 99000854 - Inventory Profile Offsetting
        // excluding logging surplus & MinQty check
        if OrderQty <= 0 then
            exit(0);

        if (Item."Maximum Order Quantity" < OrderQty) and
           (Item."Maximum Order Quantity" <> 0)
        // AND  (SKU."Maximum Order Quantity" > MinQty)
        then
            DeltaQty := Item."Maximum Order Quantity" - OrderQty
        else
            DeltaQty := 0;
        if Item."Minimum Order Quantity" > (OrderQty + DeltaQty) then
            DeltaQty := Item."Minimum Order Quantity" - OrderQty;

        if Item."Order Multiple" <> 0 then begin
            Rounding := Round(OrderQty + DeltaQty, Item."Order Multiple", '>') - (OrderQty + DeltaQty);
            DeltaQty += Rounding;
        end;
        exit(DeltaQty);
    end;

    local procedure CalcReorderQty(Item: Record Item; NeededQty: Decimal; ProjectedInventory: Decimal) QtyToOrder: Decimal
    begin
        // Copy of CalcReorderQty in COD 99000854 - Inventory Profile Offsetting
        // excluding logging surplus, resiliency errors and comments
        case Item."Reordering Policy" of
            Item."Reordering Policy"::"Maximum Qty.":
                if Item."Maximum Inventory" < Item."Reorder Point" then
                    QtyToOrder := Item."Reorder Point" - ProjectedInventory
                else
                    QtyToOrder := Item."Maximum Inventory" - ProjectedInventory;
            Item."Reordering Policy"::"Fixed Reorder Qty.":
                begin
                    Item.TestField("Reorder Quantity"); // Assertion
                    QtyToOrder := Item."Reorder Quantity";
                end;
            else
                QtyToOrder := NeededQty;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date; var AvailableQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedQty(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date; var ExpectedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcExpectedQtyOnHand(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date; var ExpectedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date; var AvailableQty: Decimal; var IsHandled: Boolean)
    begin
    end;
}

