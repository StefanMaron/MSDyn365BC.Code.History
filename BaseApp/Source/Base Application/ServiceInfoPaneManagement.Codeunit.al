codeunit 5972 "Service Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ServHeader: Record "Service Header";
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";

    procedure CalcAvailability(var ServLine: Record "Service Line"): Decimal
    var
        AvailableToPromise: Codeunit "Available to Promise";
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        AvailabilityDate: Date;
        LookaheadDateformula: DateFormula;
    begin
        if GetItem(ServLine) then begin
            if ServLine."Needed by Date" <> 0D then
                AvailabilityDate := ServLine."Needed by Date"
            else
                AvailabilityDate := WorkDate;

            Item.Reset;
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", ServLine."Variant Code");
            Item.SetRange("Location Filter", ServLine."Location Code");
            Item.SetRange("Drop Shipment Filter", false);

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

    procedure CalcNoOfSubstitutions(var ServLine: Record "Service Line"): Integer
    begin
        if GetItem(ServLine) then begin
            Item.CalcFields("No. of Substitutes");
            exit(Item."No. of Substitutes");
        end;
    end;

    procedure CalcNoOfSalesPrices(var ServLine: Record "Service Line"): Integer
    begin
        if GetItem(ServLine) then begin
            GetServHeader(ServLine);
            exit(SalesPriceCalcMgt.NoOfServLinePrice(ServHeader, ServLine, true));
        end;
    end;

    procedure CalcNoOfSalesLineDisc(var ServLine: Record "Service Line"): Integer
    begin
        if GetItem(ServLine) then begin
            GetServHeader(ServLine);
            exit(SalesPriceCalcMgt.NoOfServLineLineDisc(ServHeader, ServLine, true));
        end;
    end;

    local procedure GetItem(var ServLine: Record "Service Line"): Boolean
    begin
        with Item do begin
            if (ServLine.Type <> ServLine.Type::Item) or (ServLine."No." = '') then
                exit(false);

            if ServLine."No." <> "No." then
                Get(ServLine."No.");
            exit(true);
        end;
    end;

    local procedure GetServHeader(ServLine: Record "Service Line")
    begin
        if (ServLine."Document Type" <> ServHeader."Document Type") or
           (ServLine."Document No." <> ServHeader."No.")
        then
            ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
    end;

    procedure CalcNoOfServItemComponents(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            ServItemComponent.Reset;
            ServItemComponent.SetRange(Active, true);
            ServItemComponent.SetRange("Parent Service Item No.", ServItemLine."Service Item No.");
            exit(ServItemComponent.Count);
        end;
    end;

    procedure CalcNoOfTroubleshootings(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ResultValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNoOfTroubleshootings(ServItemLine, ResultValue, IsHandled);
        if IsHandled then
            exit(ResultValue);

        TroubleshootingSetup.Reset();
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item");
        TroubleshootingSetup.SetRange("No.", ServItemLine."Service Item No.");
        if not TroubleshootingSetup.IsEmpty then
            exit(TroubleshootingSetup.Count);
        if not ServItem.Get(ServItemLine."Service Item No.") then
            exit(0);
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);
        TroubleshootingSetup.SetRange("No.", ServItem."Item No.");
        if not TroubleshootingSetup.IsEmpty then
            exit(TroubleshootingSetup.Count);
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item Group");
        TroubleshootingSetup.SetRange("No.", ServItem."Service Item Group Code");
        exit(TroubleshootingSetup.Count);
    end;

    procedure CalcNoOfSkilledResources(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        Res: Record Resource;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        NoOfSkilledResources: Integer;
        ResourceSkillType: Option Resource,"Service Item Group",Item,"Service Item";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            Res.Reset;
            if Res.Find('-') then
                repeat
                    if ServOrderAllocMgt.ResourceQualified(Res."No.", ResourceSkillType::"Service Item", ServItem."No.") then
                        NoOfSkilledResources += 1;
                until Res.Next = 0;
            exit(NoOfSkilledResources);
        end;
    end;

    procedure ShowServItemComponents(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            ServItemComponent.Reset;
            ServItemComponent.SetRange(Active, true);
            ServItemComponent.SetRange("Parent Service Item No.", ServItemLine."Service Item No.");
            PAGE.RunModal(PAGE::"Service Item Component List", ServItemComponent);
        end;
    end;

    procedure ShowTroubleshootings(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        TroubleshootingSetup: Record "Troubleshooting Setup";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            TroubleshootingSetup.Reset;
            TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item");
            TroubleshootingSetup.SetRange("No.", ServItemLine."Service Item No.");
            PAGE.RunModal(PAGE::"Troubleshooting Setup", TroubleshootingSetup);
        end;
    end;

    procedure ShowSkilledResources(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        ResourceSkill: Record "Resource Skill";
        SkilledResourceList: Page "Skilled Resource List";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            Clear(SkilledResourceList);
            SkilledResourceList.Initialize(ResourceSkill.Type::"Service Item", ServItem."No.", ServItem.Description);
            SkilledResourceList.RunModal;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfTroubleshootings(ServItemLine: Record "Service Item Line"; var ResultValue: Integer; var IsHandled: Boolean)
    begin
    end;
}

