codeunit 5431 "Calc. Item Plan - Plan Wksh."
{
    TableNo = Item;

    trigger OnRun()
    begin
        Item.Copy(Rec);
        Code;
        Rec := Item;
    end;

    var
        Item: Record Item;
        MfgSetup: Record "Manufacturing Setup";
        TempPlanningCompList: Record "Planning Component" temporary;
        TempItemList: Record Item temporary;
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        MPS: Boolean;
        MRP: Boolean;
        NetChange: Boolean;
        PeriodLength: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        UseForecast: Code[10];
        FromDate: Date;
        ToDate: Date;
        Text000: Label 'You must decide what to calculate.';
        Text001: Label 'Enter a starting date.';
        Text002: Label 'Enter an ending date.';
        Text003: Label 'The ending date must not be before the order date.';
        Text004: Label 'You must not use a variant filter when calculating MPS from a forecast.';
        ExcludeForecastBefore: Date;
        RespectPlanningParm: Boolean;

    local procedure "Code"()
    var
        ReqLineExtern: Record "Requisition Line";
        PlannedProdOrderLine: Record "Prod. Order Line";
        PlanningAssignment: Record "Planning Assignment";
        ProdOrder: Record "Production Order";
        CurrWorksheetType: Option Requisition,Planning;
    begin
        with Item do begin
            if not PlanThisItem then
                exit;

            ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
            CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
            CopyFilter("Location Filter", ReqLineExtern."Location Code");
            ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
            ReqLineExtern.SetRange("No.", "No.");
            if ReqLineExtern.Find('-') then
                repeat
                    ReqLineExtern.Delete(true);
                until ReqLineExtern.Next = 0;

            PlannedProdOrderLine.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code");
            PlannedProdOrderLine.SetRange(Status, PlannedProdOrderLine.Status::Planned);
            CopyFilter("Variant Filter", PlannedProdOrderLine."Variant Code");
            CopyFilter("Location Filter", PlannedProdOrderLine."Location Code");
            PlannedProdOrderLine.SetRange("Item No.", "No.");
            if PlannedProdOrderLine.Find('-') then
                repeat
                    if ProdOrder.Get(PlannedProdOrderLine.Status, PlannedProdOrderLine."Prod. Order No.") then begin
                        if (ProdOrder."Source Type" = ProdOrder."Source Type"::Item) and
                           (ProdOrder."Source No." = PlannedProdOrderLine."Item No.")
                        then
                            ProdOrder.Delete(true);
                    end else
                        PlannedProdOrderLine.Delete(true);
                until PlannedProdOrderLine.Next = 0;

            Commit();

            InvtProfileOffsetting.SetParm(UseForecast, ExcludeForecastBefore, CurrWorksheetType::Planning);
            InvtProfileOffsetting.CalculatePlanFromWorksheet(
              Item, MfgSetup, CurrTemplateName, CurrWorksheetName, FromDate, ToDate, MRP, RespectPlanningParm);

            // Retrieve list of Planning Components handled:
            InvtProfileOffsetting.GetPlanningCompList(TempPlanningCompList);

            CopyFilter("Variant Filter", PlanningAssignment."Variant Code");
            CopyFilter("Location Filter", PlanningAssignment."Location Code");
            PlanningAssignment.SetRange(Inactive, false);
            PlanningAssignment.SetRange("Net Change Planning", true);
            PlanningAssignment.SetRange("Item No.", "No.");
            if PlanningAssignment.Find('-') then
                repeat
                    if PlanningAssignment."Latest Date" <= ToDate then begin
                        PlanningAssignment.Inactive := true;
                        PlanningAssignment.Modify();
                    end;
                until PlanningAssignment.Next = 0;

            Commit();

            TempItemList := Item;
            TempItemList.Insert();
        end;
    end;

    procedure Initialize(NewFromDate: Date; NewToDate: Date; NewMPS: Boolean; NewMRP: Boolean; NewRespectPlanningParm: Boolean)
    begin
        FromDate := NewFromDate;
        ToDate := NewToDate;
        MPS := NewMPS;
        MRP := NewMRP;
        RespectPlanningParm := NewRespectPlanningParm;

        MfgSetup.Get();
        CheckPreconditions;
    end;

    procedure Finalize()
    var
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        // Items already planned for removed from temporary list:
        if TempPlanningCompList.Find('-') then
            repeat
                if TempPlanningCompList."Planning Level Code" > 0 then begin
                    RequisitionLine.SetRange("Worksheet Template Name", CurrTemplateName);
                    RequisitionLine.SetRange("Journal Batch Name", CurrWorksheetName);
                    RequisitionLine.SetRange("Ref. Order Type", TempPlanningCompList."Ref. Order Type");
                    RequisitionLine.SetRange("Ref. Order No.", TempPlanningCompList."Ref. Order No.");
                    RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
                    RequisitionLine.SetRange("No.", TempPlanningCompList."Item No.");
                    if RequisitionLine.IsEmpty then begin
                        PlanningComponent := TempPlanningCompList;
                        PlanningComponent.Find;
                        PlanningComponent.Validate("Planning Level Code", 0);
                        PlanningComponent.Modify(true);
                    end;
                end;
                if TempItemList.Get(TempPlanningCompList."Item No.") then
                    TempPlanningCompList.Delete();
            until TempPlanningCompList.Next = 0;

        // Dynamic tracking is run for the remaining Planning Components:
        if TempPlanningCompList.Find('-') then
            repeat
                ReservMgt.SetReservSource(TempPlanningCompList);
                ReservMgt.AutoTrack(TempPlanningCompList."Net Quantity (Base)");
            until TempPlanningCompList.Next = 0;

        Commit();
    end;

    local procedure CheckPreconditions()
    var
        ForecastEntry: Record "Production Forecast Entry";
        IsHandled: Boolean;
    begin
        OnBeforeCheckPreconditions(Item, MPS, MRP, FromDate, ToDate, IsHandled);
        if IsHandled then
            exit;

        if not MPS and not MRP then
            Error(Text000);

        if FromDate = 0D then
            Error(Text001);
        if ToDate = 0D then
            Error(Text002);
        PeriodLength := ToDate - FromDate + 1;
        if PeriodLength <= 0 then
            Error(Text003);

        if MPS and
           (Item.GetFilter("Variant Filter") <> '') and
           (UseForecast <> '')
        then begin
            ForecastEntry.SetCurrentKey("Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
            ForecastEntry.SetRange("Production Forecast Name", UseForecast);
            Item.CopyFilter("No.", ForecastEntry."Item No.");
            if MfgSetup."Use Forecast on Locations" then
                Item.CopyFilter("Location Filter", ForecastEntry."Location Code");
            if not ForecastEntry.IsEmpty then
                Error(Text004);
        end;
    end;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10]; NetChange2: Boolean)
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
        NetChange := NetChange2;
    end;

    local procedure PlanThisItem(): Boolean
    var
        SKU: Record "Stockkeeping Unit";
        ForecastEntry: Record "Production Forecast Entry";
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
        PlanningAssignment: Record "Planning Assignment";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePlanThisItem(Item, IsHandled);
        if IsHandled then
            exit;

        SKU.SetCurrentKey("Item No.");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        SKU.SetRange("Item No.", Item."No.");
        if SKU.IsEmpty and (Item."Reordering Policy" = Item."Reordering Policy"::" ") then
            exit(false);

        Item.CopyFilter("Variant Filter", PlanningAssignment."Variant Code");
        Item.CopyFilter("Location Filter", PlanningAssignment."Location Code");
        PlanningAssignment.SetRange(Inactive, false);
        PlanningAssignment.SetRange("Net Change Planning", true);
        PlanningAssignment.SetRange("Item No.", Item."No.");
        if NetChange and PlanningAssignment.IsEmpty then
            exit(false);

        if MRP = MPS then
            exit(true);

        SalesLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SalesLine.SetFilter("Document Type", '%1|%2', SalesLine."Document Type"::Order, SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        Item.CopyFilter("Variant Filter", SalesLine."Variant Code");
        Item.CopyFilter("Location Filter", SalesLine."Location Code");
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.SetFilter("Outstanding Qty. (Base)", '<>0');
        if not SalesLine.IsEmpty then
            exit(MPS);

        ForecastEntry.SetCurrentKey("Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
        ForecastEntry.SetRange("Production Forecast Name", UseForecast);
        if MfgSetup."Use Forecast on Locations" then
            Item.CopyFilter("Location Filter", ForecastEntry."Location Code");
        ForecastEntry.SetRange("Item No.", Item."No.");
        if ForecastEntry.FindFirst then begin
            ForecastEntry.CalcSums("Forecast Quantity (Base)");
            if ForecastEntry."Forecast Quantity (Base)" > 0 then
                exit(MPS);
        end;

        if ServLine.LinesWithItemToPlanExist(Item) then
            exit(MPS);

        if JobPlanningLine.LinesWithItemToPlanExist(Item) then
            exit(MPS);

        ProdOrderLine.SetCurrentKey("Item No.");
        ProdOrderLine.SetRange("MPS Order", true);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        if not ProdOrderLine.IsEmpty then
            exit(MPS);

        PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("MPS Order", true);
        PurchaseLine.SetRange("No.", Item."No.");
        if not PurchaseLine.IsEmpty then
            exit(MPS);

        exit(MRP);
    end;

    procedure SetParm(Forecast: Code[10]; ExclBefore: Date; var Item2: Record Item)
    begin
        UseForecast := Forecast;
        ExcludeForecastBefore := ExclBefore;
        Item.Copy(Item2);
    end;

    procedure SetResiliencyOn()
    begin
        InvtProfileOffsetting.SetResiliencyOn;
    end;

    procedure GetResiliencyError(var PlanningErrorLogEntry: Record "Planning Error Log"): Boolean
    begin
        exit(InvtProfileOffsetting.GetResiliencyError(PlanningErrorLogEntry));
    end;

    procedure ClearInvtProfileOffsetting()
    begin
        Clear(InvtProfileOffsetting);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPreconditions(var Item: Record Item; MPS: Boolean; MRP: Boolean; FromDate: Date; ToDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanThisItem(Item: Record Item; var IsHandled: Boolean)
    begin
    end;
}

