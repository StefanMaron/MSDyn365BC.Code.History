codeunit 915 "Assembly Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";

    procedure CalcAvailability(var AsmLine: Record "Assembly Line"): Decimal
    var
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        LookaheadDateformula: DateFormula;
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(
              AvailableToPromise.QtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                CalcAvailabilityDate(AsmLine),
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    local procedure CalcAvailabilityDate(AsmLine: Record "Assembly Line"): Date
    begin
        if AsmLine."Due Date" <> 0D then
            exit(AsmLine."Due Date");

        exit(WorkDate);
    end;

    procedure CalcAvailableInventory(var AsmLine: Record "Assembly Line"): Decimal
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(AvailableToPromise.CalcAvailableInventory(Item));
        end;
    end;

    procedure CalcScheduledReceipt(var AsmLine: Record "Assembly Line"): Decimal
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(AvailableToPromise.CalcScheduledReceipt(Item));
        end;
    end;

    procedure CalcGrossRequirement(var AsmLine: Record "Assembly Line"): Decimal
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(AvailableToPromise.CalcGrossRequirement(Item));
        end;
    end;

    procedure CalcReservedReceipt(var AsmLine: Record "Assembly Line"): Decimal
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(AvailableToPromise.CalcReservedReceipt(Item));
        end;
    end;

    procedure CalcReservedRequirement(var AsmLine: Record "Assembly Line"): Decimal
    begin
        if GetItem(AsmLine) then begin
            SetItemFilter(Item, AsmLine);

            exit(AvailableToPromise.CalcReservedRequirement(Item));
        end;
    end;

    procedure LookupItem(AsmLine: Record "Assembly Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupItem(AsmLine, IsHandled);
        if IsHandled then
            exit;

        AsmLine.TestField(Type, AsmLine.Type::Item);
        AsmLine.TestField("No.");
        GetItem(AsmLine);
        PAGE.RunModal(PAGE::"Item Card", Item);
    end;

    local procedure GetItem(AsmLine: Record "Assembly Line"): Boolean
    begin
        with Item do begin
            if (AsmLine.Type <> AsmLine.Type::Item) or (AsmLine."No." = '') then
                exit(false);

            if AsmLine."No." <> "No." then
                Get(AsmLine."No.");
            exit(true);
        end;
    end;

    local procedure SetItemFilter(var Item: Record Item; AsmLine: Record "Assembly Line")
    begin
        Item.Reset();
        Item.SetRange("Date Filter", 0D, CalcAvailabilityDate(AsmLine));
        Item.SetRange("Variant Filter", AsmLine."Variant Code");
        Item.SetRange("Location Filter", AsmLine."Location Code");
        Item.SetRange("Drop Shipment Filter", false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItem(AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}

