#if not CLEAN19
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
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailableQuantity: Decimal;
        PeriodType: Enum "Analysis Period Type";
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
                AvailableToPromise.CalcQtyAvailabletoPromise(
                  Item,
                  GrossRequirement,
                  ScheduledReceipt,
                  CalcAvailabilityDate(SalesLine),
                  PeriodType,
                  LookaheadDateformula),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcAvailabilityDate(var SalesLine: Record "Sales Line") AvailabilityDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailabilityDate(SalesLine, AvailabilityDate, IsHandled);
        if IsHandled then
            exit(AvailabilityDate);

        if SalesLine."Shipment Date" <> 0D then
            exit(SalesLine."Shipment Date");

        exit(WorkDate());
    end;

    procedure CalcAvailableInventory(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcAvailableInventoryOnAfterSetItemFilter(Item);

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
            OnCalcScheduledReceiptOnAfterSetItemFilter(Item);

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
            OnCalcGrossRequirementsOnAfterSetItemFilter(Item);

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
            OnCalcReservedRequirementsOnAfterSetItemFilter(Item);

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
            OnCalcReservedDemandOnAfterSetItemFilter(Item);

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
        exit(SalesLine.CountPrice(true));
    end;

    procedure CalcNoOfSalesLineDisc(var SalesLine: Record "Sales Line"): Integer
    begin
        exit(SalesLine.CountDiscount(true));
    end;

    local procedure ConvertQty(Qty: Decimal; PerUoMQty: Decimal) Result: Decimal
    begin
        if PerUoMQty = 0 then
            PerUoMQty := 1;
        Result := Round(Qty / PerUoMQty, UOMMgt.QtyRndPrecision());
        OnAfterConvertQty(Qty, PerUoMQty, Result);
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
        AvailableToPromise.ResetItemNo();
    end;

    procedure GetItem(var SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(SalesLine, Item, IsHandled, Result);
        if IsHandled then
            exit(Result);

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

    [Obsolete('Unused function discontinued.', '19.0')]
    [Scope('OnPrem')]
    procedure xCalcSaldo(CustNo: Code[20]): Decimal
    var
        Customer: Record Customer;
    begin
        with Customer do
            if Get(CustNo) then begin
                SetRange("Date Filter", 0D, WorkDate());
                CalcFields("Balance (LCY)");
                exit("Balance (LCY)");
            end;
        exit(0);
    end;

    [Obsolete('Unused function discontinued.', '19.0')]
    [Scope('OnPrem')]
    procedure xLookupSaldo(CustNo: Code[20])
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // NAVCZ
        DtldCustLedgEntry.SetRange("Customer No.", CustNo);
        DtldCustLedgEntry.SetRange("Posting Date", 0D, WorkDate());
        CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
    end;
    
    [IntegrationEvent(False, false)]
    local procedure OnAfterConvertQty(Qty: Decimal; PerUoMQty: Decimal; var Result: Decimal)
    begin
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
    local procedure OnBeforeCalcAvailabilityDate(var SalesLine: Record "Sales Line"; var AvailabilityDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(SalesLine: Record "Sales Line"; var Item: Record Item; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItem(var SalesLine: Record "Sales Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableInventoryOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcScheduledReceiptOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGrossRequirementsOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedDemandOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedRequirementsOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;
}

#endif