codeunit 7181 "Purchases Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchPriceCalcMgt: Codeunit "Purch. Price Calc. Mgt.";

    procedure CalcAvailability(var PurchLine: Record "Purchase Line"): Decimal
    var
        AvailableToPromise: Codeunit "Available to Promise";
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailableQuantity: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        AvailabilityDate: Date;
        LookaheadDateformula: DateFormula;
        IsHandled: Boolean;
    begin
        if GetItem(PurchLine) then begin
            if PurchLine."Expected Receipt Date" <> 0D then
                AvailabilityDate := PurchLine."Expected Receipt Date"
            else
                AvailabilityDate := WorkDate;

            Item.Reset;
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", PurchLine."Variant Code");
            Item.SetRange("Location Filter", PurchLine."Location Code");
            Item.SetRange("Drop Shipment Filter", false);

            IsHandled := false;
            OnBeforeCalcAvailability(Item, PurchLine, AvailableQuantity, IsHandled);
            if IsHandled then
                exit(AvailableQuantity);

            exit(
              AvailableToPromise.QtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    procedure CalcNoOfPurchasePrices(var PurchLine: Record "Purchase Line"): Integer
    begin
        if GetItem(PurchLine) then begin
            GetPurchHeader(PurchLine);
            exit(PurchPriceCalcMgt.NoOfPurchLinePrice(PurchHeader, PurchLine, true));
        end;
    end;

    procedure CalcNoOfPurchLineDisc(var PurchLine: Record "Purchase Line"): Integer
    begin
        if GetItem(PurchLine) then begin
            GetPurchHeader(PurchLine);
            exit(PurchPriceCalcMgt.NoOfPurchLineLineDisc(PurchHeader, PurchLine, true));
        end;
    end;

    local procedure GetItem(var PurchLine: Record "Purchase Line"): Boolean
    begin
        with Item do begin
            if (PurchLine.Type <> PurchLine.Type::Item) or (PurchLine."No." = '') then
                exit(false);

            if PurchLine."No." <> "No." then
                Get(PurchLine."No.");
            exit(true);
        end;
    end;

    local procedure GetPurchHeader(PurchLine: Record "Purchase Line")
    begin
        if (PurchLine."Document Type" <> PurchHeader."Document Type") or
           (PurchLine."Document No." <> PurchHeader."No.")
        then
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailability(var Item: Record Item; PurchaseLine: Record "Purchase Line"; var AvailableQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;
}

