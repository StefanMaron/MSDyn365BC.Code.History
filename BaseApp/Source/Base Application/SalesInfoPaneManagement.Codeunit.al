codeunit 7171 "Sales Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure CalcAvailability(var SalesLine: Record "Sales Line"): Decimal
    var
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailableQuantity: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        LookaheadDateformula: DateFormula;
        IsHandled: Boolean;
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            IsHandled := false;
            OnBeforeCalcAvailability(Item, SalesLine, AvailableQuantity, IsHandled);
            if IsHandled then
                exit(AvailableQuantity);

            Evaluate(LookaheadDateformula, '<0D>');
            exit(
              ConvertQty(
                AvailableToPromise.QtyAvailabletoPromise(
                  Item,
                  GrossRequirement,
                  ScheduledReceipt,
                  CalcAvailabilityDate(SalesLine),
                  PeriodType,
                  LookaheadDateformula),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcAvailabilityDate(var SalesLine: Record "Sales Line"): Date
    begin
        if SalesLine."Shipment Date" <> 0D then
            exit(SalesLine."Shipment Date");

        exit(WorkDate);
    end;

    procedure CalcAvailableInventory(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);

            exit(
              ConvertQty(
                AvailableToPromise.CalcAvailableInventory(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcScheduledReceipt(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);

            exit(
              ConvertQty(
                AvailableToPromise.CalcScheduledReceipt(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcGrossRequirements(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);

            exit(
              ConvertQty(
                AvailableToPromise.CalcGrossRequirement(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcReservedRequirements(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);

            exit(
              ConvertQty(
                AvailableToPromise.CalcReservedReceipt(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcReservedDemand(SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);

            exit(
              ConvertQty(
                AvailableToPromise.CalcReservedRequirement(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcNoOfSubstitutions(var SalesLine: Record "Sales Line"): Integer
    begin
        if GetItem(SalesLine) then begin
            Item.CalcFields("No. of Substitutes");
            exit(Item."No. of Substitutes");
        end;
    end;

    procedure CalcNoOfSalesPrices(var SalesLine: Record "Sales Line"): Integer
    begin
        if GetItem(SalesLine) then
            exit(SalesLine.CountPrice(true));
    end;

    procedure CalcNoOfSalesLineDisc(var SalesLine: Record "Sales Line"): Integer
    begin
        if GetItem(SalesLine) then
            exit(SalesLine.CountDiscount(true));
    end;

    local procedure ConvertQty(Qty: Decimal; PerUoMQty: Decimal): Decimal
    begin
        if PerUoMQty = 0 then
            PerUoMQty := 1;
        exit(Round(Qty / PerUoMQty, UOMMgt.QtyRndPrecision));
    end;

    procedure LookupItem(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupItem(SalesLine, Item, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.");
        GetItem(SalesLine);
        PAGE.RunModal(PAGE::"Item Card", Item);
    end;

    procedure ResetItemNo()
    begin
        AvailableToPromise.ResetItemNo;
    end;

    local procedure GetItem(var SalesLine: Record "Sales Line"): Boolean
    begin
        with Item do begin
            if (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') then
                exit(false);

            if SalesLine."No." <> "No." then
                Get(SalesLine."No.");
            exit(true);
        end;
    end;

    local procedure SetItemFilter(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        Item.Reset();
        Item.SetRange("Date Filter", 0D, CalcAvailabilityDate(SalesLine));
        Item.SetRange("Variant Filter", SalesLine."Variant Code");
        Item.SetRange("Location Filter", SalesLine."Location Code");
        Item.SetRange("Drop Shipment Filter", SalesLine."Drop Shipment");
        OnAfterSetItemFilter(Item, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilter(var Item: Record Item; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailability(var Item: Record Item; var SalesLine: Record "Sales Line"; var AvailableQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItem(var SalesLine: Record "Sales Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;
}

