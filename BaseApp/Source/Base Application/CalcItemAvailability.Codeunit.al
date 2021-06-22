codeunit 5530 "Calc. Item Availability"
{

    trigger OnRun()
    begin
    end;

    var
        TempInvtEventBuf: Record "Inventory Event Buffer" temporary;
        EntryNo: Integer;
        TableNotSupportedErr: Label 'Table %1 is not supported by the ShowDocument function.', Comment = '%1 = table name';

    procedure CalcNewInvtEventBuf(var Item: Record Item; ForecastName: Code[10]; IncludeBlanketOrders: Boolean; ExcludeForecastBefore: Date; IncludePlan: Boolean)
    begin
        if Item.Type <> Item.Type::Inventory then
            exit;
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.DeleteAll();

        GetDocumentEntries(TempInvtEventBuf, Item);
        if (ForecastName <> '') or IncludeBlanketOrders or IncludePlan then
            GetAnticipatedDemand(TempInvtEventBuf, Item, ForecastName, ExcludeForecastBefore, IncludeBlanketOrders);
        if IncludePlan then
            GetPlanningEntries(TempInvtEventBuf, Item);
    end;

    procedure GetInvEventBuffer(var RequestInvtEventBuf: Record "Inventory Event Buffer")
    begin
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        if TempInvtEventBuf.Find('-') then
            repeat
                RequestInvtEventBuf := TempInvtEventBuf;
                RequestInvtEventBuf.Insert();
            until TempInvtEventBuf.Next = 0;
    end;

    procedure GetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    begin
        TryGetSalesOrdersDemandEntries(InvtEventBuf, Item);
        TryGetServOrdersDemandEntries(InvtEventBuf, Item);
        TryGetJobOrdersDemandEntries(InvtEventBuf, Item);
        TryGetPurchRetOrderDemandEntries(InvtEventBuf, Item);
        TryGetProdOrderCompDemandEntries(InvtEventBuf, Item);
        TryGetTransOrderDemandEntries(InvtEventBuf, Item);
        TryGetQtyOnInventory(InvtEventBuf, Item);
        TryGetPurchOrderSupplyEntries(InvtEventBuf, Item);
        TryGetSalesRetOrderSupplyEntries(InvtEventBuf, Item);
        TryGetProdOrderSupplyEntries(InvtEventBuf, Item);
        TryGetTransferOrderSupplyEntries(InvtEventBuf, Item);
        TryGetAsmOrderDemandEntries(InvtEventBuf, Item);
        TryGetAsmOrderSupllyEntries(InvtEventBuf, Item);

        OnAfterGetDocumentEntries(InvtEventBuf, Item, EntryNo);
    end;

    local procedure GetAnticipatedDemand(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; ForecastName: Code[10]; ExcludeForecastBefore: Date; IncludeBlanketOrders: Boolean)
    begin
        if ForecastName <> '' then
            GetRemainingForecast(InvtEventBuf, Item, ForecastName, ExcludeForecastBefore);
        if IncludeBlanketOrders then
            GetBlanketSalesOrders(InvtEventBuf, Item);
    end;

    local procedure GetPlanningEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    begin
        GetPlanningLines(InvtEventBuf, Item);
        GetPlanningComponents(InvtEventBuf, Item);
        GetPlanningTransDemand(InvtEventBuf, Item);
    end;

    local procedure TryGetQtyOnInventory(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        FilterItemLedgEntry: Record "Item Ledger Entry";
        IncludeLocation: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeTryGetQtyOnInventory(InvtEventBuf, Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ItemLedgEntry.ReadPermission then
            exit(false);

        if ItemLedgEntry.FindLinesWithItemToPlan(Item, false) then begin
            FilterItemLedgEntry.Copy(ItemLedgEntry);
            repeat
                if ItemLedgEntry."Location Code" = '' then
                    IncludeLocation := true
                else
                    IncludeLocation := not IsInTransitLocation(ItemLedgEntry."Location Code");

                ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");

                if IncludeLocation then begin
                    ItemLedgEntry.CalcSums("Remaining Quantity");
                    if ItemLedgEntry."Remaining Quantity" <> 0 then begin
                        InvtEventBuf.TransferInventoryQty(ItemLedgEntry);
                        InsertEntry(InvtEventBuf);
                    end;
                end;

                ItemLedgEntry.Find('+');
                ItemLedgEntry.CopyFilters(FilterItemLedgEntry);
            until ItemLedgEntry.Next = 0;
        end;

        exit(true);
    end;

    local procedure TryGetPurchOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        if not PurchLine.ReadPermission then
            exit(false);

        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order) then
            repeat
                InvtEventBuf.TransferFromPurchase(PurchLine);
                InsertEntry(InvtEventBuf);
            until PurchLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetSalesRetOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if not SalesLine.ReadPermission then
            exit(false);

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                InvtEventBuf.TransferFromSalesReturn(SalesLine);
                InsertEntry(InvtEventBuf);
            until SalesLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetProdOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrderLine.ReadPermission then
            exit(false);

        if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
            repeat
                InvtEventBuf.TransferFromProdOrder(ProdOrderLine);
                InsertEntry(InvtEventBuf);
            until ProdOrderLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetTransferOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        TransLine: Record "Transfer Line";
    begin
        if not TransLine.ReadPermission then
            exit(false);

        if TransLine.FindLinesWithItemToPlan(Item, true, false) then
            repeat
                InvtEventBuf.TransferFromInboundTransOrder(TransLine);
                InsertEntry(InvtEventBuf);
            until TransLine.Next = 0;

        exit(true)
    end;

    local procedure TryGetSalesOrdersDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if not SalesLine.ReadPermission then
            exit(false);

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                InvtEventBuf.TransferFromSales(SalesLine);
                InsertEntry(InvtEventBuf);
            until SalesLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetServOrdersDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        ServLine: Record "Service Line";
    begin
        if not ServLine.ReadPermission then
            exit(false);

        if ServLine.FindLinesWithItemToPlan(Item) then
            repeat
                InvtEventBuf.TransferFromServiceNeed(ServLine);
                InsertEntry(InvtEventBuf);
            until ServLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetJobOrdersDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if not JobPlanningLine.ReadPermission then
            exit(false);

        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                InvtEventBuf.TransferFromJobNeed(JobPlanningLine);
                InsertEntry(InvtEventBuf);
            until JobPlanningLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetPurchRetOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        if not PurchLine.ReadPermission then
            exit(false);

        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order") then
            repeat
                InvtEventBuf.TransferFromPurchReturn(PurchLine);
                InsertEntry(InvtEventBuf);
            until PurchLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetProdOrderCompDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if not ProdOrderComp.ReadPermission then
            exit(false);

        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                InvtEventBuf.TransferFromProdComp(ProdOrderComp);
                InsertEntry(InvtEventBuf);
            until ProdOrderComp.Next = 0;

        exit(true);
    end;

    local procedure TryGetTransOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        TransLine: Record "Transfer Line";
    begin
        if not TransLine.ReadPermission then
            exit(false);

        if TransLine.FindLinesWithItemToPlan(Item, false, false) then
            repeat
                InvtEventBuf.TransferFromOutboundTransOrder(TransLine);
                InsertEntry(InvtEventBuf);
            until TransLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetAsmOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        AsmLine: Record "Assembly Line";
    begin
        if not AsmLine.ReadPermission then
            exit(false);

        if AsmLine.FindLinesWithItemToPlan(Item, AsmLine."Document Type"::Order) then
            repeat
                InvtEventBuf.TransferFromAsmOrderLine(AsmLine);
                InsertEntry(InvtEventBuf);
            until AsmLine.Next = 0;

        exit(true);
    end;

    local procedure TryGetAsmOrderSupllyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        AsmHeader: Record "Assembly Header";
    begin
        if not AsmHeader.ReadPermission then
            exit(false);

        if AsmHeader.FindLinesWithItemToPlan(Item, AsmHeader."Document Type"::Order) then
            repeat
                InvtEventBuf.TransferFromAsmOrder(AsmHeader);
                InsertEntry(InvtEventBuf);
            until AsmHeader.Next = 0;

        exit(true);
    end;

    local procedure GetRemainingForecast(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; ForecastName: Code[10]; ExcludeForecastBefore: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        MfgSetup: Record "Manufacturing Setup";
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdForecastEntry2: Record "Production Forecast Entry";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        FromDate: Date;
        ToDate: Date;
        ForecastPeriodEndDate: Date;
        RemainingForecastQty: Decimal;
        ModuleLoop: Integer;
        ReplenishmentLocation: Code[10];
        LocationMandatory: Boolean;
        Module: Boolean;
    begin
        // Include Forecast consumption
        CopyOfInvtEventBuf.Copy(InvtEventBuf);
        if Format(Item."Date Filter") <> '' then begin
            FromDate := Item.GetRangeMin("Date Filter");
            ToDate := Item.GetRangeMax("Date Filter");
        end;
        if FromDate = 0D then
            FromDate := WorkDate;
        if ToDate = 0D then
            ToDate := DMY2Date(30, 12, 9999);

        MfgSetup.Get();
        if not MfgSetup."Use Forecast on Locations" then begin
            if not FindReplishmentLocation(ReplenishmentLocation, Item, LocationMandatory) then
                ReplenishmentLocation := MfgSetup."Components at Location";
            if LocationMandatory and
               (ReplenishmentLocation = '')
            then
                exit;

            ProdForecastEntry.SetCurrentKey(
              "Production Forecast Name", "Item No.", "Component Forecast", "Forecast Date", "Location Code");
        end else
            ProdForecastEntry.SetCurrentKey(
              "Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code");

        ProdForecastEntry.SetRange("Production Forecast Name", ForecastName);
        ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);
        ProdForecastEntry.SetRange("Item No.", Item."No.");

        ProdForecastEntry2.Copy(ProdForecastEntry);
        Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");

        for ModuleLoop := 1 to 2 do begin
            Module := ModuleLoop = 2;
            ProdForecastEntry.SetRange("Component Forecast", Module);
            ProdForecastEntry2.SetRange("Component Forecast", Module);
            if ProdForecastEntry2.FindSet then
                repeat
                    if MfgSetup."Use Forecast on Locations" then begin
                        ProdForecastEntry2.SetRange("Location Code", ProdForecastEntry2."Location Code");
                        ItemLedgEntry.SetRange("Location Code", ProdForecastEntry2."Location Code");
                        InvtEventBuf.SetRange("Location Code", ProdForecastEntry2."Location Code");
                    end else begin
                        Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");
                        Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");
                        Item.CopyFilter("Location Filter", InvtEventBuf."Location Code");
                    end;
                    ProdForecastEntry2.FindLast;
                    ProdForecastEntry2.CopyFilter("Location Code", ProdForecastEntry."Location Code");
                    Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");

                    if ForecastExist(ProdForecastEntry, ExcludeForecastBefore, FromDate, ToDate) then
                        repeat
                            ProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date");
                            ProdForecastEntry.Find('+');
                            ProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                            RemainingForecastQty := ProdForecastEntry."Forecast Quantity (Base)";
                            ForecastPeriodEndDate := FindForecastPeriodEndDate(ProdForecastEntry, ToDate);

                            ItemLedgEntry.SetRange("Item No.", Item."No.");
                            ItemLedgEntry.SetRange(Positive, false);
                            ItemLedgEntry.SetRange(Open);
                            ItemLedgEntry.SetRange(
                              "Posting Date", ProdForecastEntry."Forecast Date", ForecastPeriodEndDate);
                            Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                            if Module then begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                                if ItemLedgEntry.FindSet then
                                    repeat
                                        RemainingForecastQty += ItemLedgEntry.Quantity;
                                    until ItemLedgEntry.Next = 0;
                            end else begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
                                if ItemLedgEntry.FindSet then begin
                                    repeat
                                        if not ItemLedgEntry."Derived from Blanket Order" then
                                            RemainingForecastQty += ItemLedgEntry.Quantity;
                                    until ItemLedgEntry.Next = 0;
                                    // Undo shipment shall neutralize consumption from sales
                                    RemainingForecastQty += AjustForUndoneShipments(ItemLedgEntry);
                                end;
                            end;

                            InvtEventBuf.SetRange("Item No.", ProdForecastEntry."Item No.");
                            InvtEventBuf.SetRange(
                              "Availability Date", ProdForecastEntry."Forecast Date", ForecastPeriodEndDate);
                            if Module then
                                InvtEventBuf.SetFilter(Type, '%1|%2', InvtEventBuf.Type::Component, InvtEventBuf.Type::"Assembly Component")
                            else
                                InvtEventBuf.SetFilter(Type, '%1|%2', InvtEventBuf.Type::Sale, InvtEventBuf.Type::Service);
                            if InvtEventBuf.Find('-') then
                                repeat
                                    if not (InvtEventBuf.Positive or InvtEventBuf."Derived from Blanket Order")
                                    then
                                        RemainingForecastQty += InvtEventBuf."Remaining Quantity (Base)";
                                until (InvtEventBuf.Next = 0) or (RemainingForecastQty < 0);

                            if RemainingForecastQty < 0 then
                                RemainingForecastQty := 0;

                            InvtEventBuf.TransferFromForecast(ProdForecastEntry, RemainingForecastQty, MfgSetup."Use Forecast on Locations");
                            InsertEntry(InvtEventBuf);

                            ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);
                        until ProdForecastEntry.Next = 0;
                until ProdForecastEntry2.Next = 0;
        end;
        InvtEventBuf.Copy(CopyOfInvtEventBuf);
    end;

    local procedure GetBlanketSalesOrders(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        BlanketSalesLine: Record "Sales Line";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        QtyReleased: Decimal;
    begin
        CopyOfInvtEventBuf.Copy(InvtEventBuf);

        with BlanketSalesLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::"Blanket Order") then
                repeat
                    InvtEventBuf.SetRange(Type, InvtEventBuf.Type::Sale);
                    InvtEventBuf.SetRange("Derived from Blanket Order", true);
                    InvtEventBuf.SetRange("Ref. Order No.", "Document No.");
                    InvtEventBuf.SetRange("Ref. Order Line No.", "Line No.");
                    if InvtEventBuf.Find('-') then
                        repeat
                            QtyReleased -= InvtEventBuf."Remaining Quantity (Base)";
                        until InvtEventBuf.Next = 0;
                    SetRange("Document No.", "Document No.");
                    SetRange("Line No.", "Line No.");
                    repeat
                        if "Outstanding Qty. (Base)" > QtyReleased then begin
                            InvtEventBuf.TransferFromSalesBlanketOrder(
                              BlanketSalesLine, "Outstanding Qty. (Base)" - QtyReleased);
                            InsertEntry(InvtEventBuf);
                            QtyReleased := 0;
                        end else
                            QtyReleased -= "Outstanding Qty. (Base)";
                    until Next = 0;
                    SetRange("Document No.");
                    SetRange("Line No.");
                until Next = 0;
        end;

        InvtEventBuf.Copy(CopyOfInvtEventBuf);
    end;

    local procedure GetPlanningLines(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        ReqLine: Record "Requisition Line";
        RecRef: RecordRef;
    begin
        // Planning suggestions
        with ReqLine do begin
            SetRange(Type, Type::Item);
            SetRange("No.", Item."No.");
            SetFilter("Location Code", Item.GetFilter("Location Filter"));
            SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            if FindSet then
                repeat
                    RecRef.GetTable(ReqLine);
                    case "Action Message" of
                        "Action Message"::New:
                            begin
                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", "Quantity (Base)", RecRef.RecordId);
                                InsertEntry(InvtEventBuf);
                            end;
                        "Action Message"::"Change Qty.":
                            begin
                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", -GetOriginalQtyBase, RecRef.RecordId);
                                InsertEntry(InvtEventBuf);

                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", "Quantity (Base)", RecRef.RecordId);
                                InsertEntry(InvtEventBuf);
                            end;
                        "Action Message"::Reschedule:
                            begin
                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Original Due Date", -"Quantity (Base)", RecRef.RecordId);
                                InsertEntry(InvtEventBuf);

                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", "Quantity (Base)", RecRef.RecordId);
                                InsertEntry(InvtEventBuf);
                            end;
                        "Action Message"::"Resched. & Chg. Qty.":
                            begin
                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Original Due Date", -GetOriginalQtyBase, RecRef.RecordId);
                                InsertEntry(InvtEventBuf);

                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", "Quantity (Base)", RecRef.RecordId);
                                InsertEntry(InvtEventBuf);
                            end;
                        "Action Message"::Cancel:
                            begin
                                InvtEventBuf.TransferFromReqLine(ReqLine, "Location Code", "Due Date", -GetOriginalQtyBase, RecRef.RecordId);
                                InsertEntry(InvtEventBuf);
                            end;
                    end;
                until Next = 0;
        end;
    end;

    local procedure GetPlanningComponents(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        PlanningComp: Record "Planning Component";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        CameFromInvtEventBuf: Record "Inventory Event Buffer";
        ParentActionMessage: Option;
    begin
        // Neutralize Prod. Orders Components as they might be replaced by planning components
        CopyOfInvtEventBuf.Copy(InvtEventBuf);
        InvtEventBuf.SetRange(Type, InvtEventBuf.Type::Component);
        InvtEventBuf.SetRange("Action Message", InvtEventBuf."Action Message"::" ");
        if InvtEventBuf.Find('-') then
            repeat
                CameFromInvtEventBuf.Copy(InvtEventBuf);
                if ParentIsInPlanning(InvtEventBuf, ParentActionMessage) then begin
                    InvtEventBuf.PlanRevertEntry(InvtEventBuf, ParentActionMessage);
                    InsertEntry(InvtEventBuf);
                end;
                InvtEventBuf.Copy(CameFromInvtEventBuf);
            until InvtEventBuf.Next = 0;
        InvtEventBuf.Copy(CopyOfInvtEventBuf);

        // Insert possible replacements
        if PlanningComp.FindLinesWithItemToPlan(Item) then
            repeat
                InvtEventBuf.TransferFromPlanProdComp(PlanningComp);
                InsertEntry(InvtEventBuf);
            until PlanningComp.Next = 0;
    end;

    local procedure GetPlanningTransDemand(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        TransferReqLine: Record "Requisition Line";
        TransLine: Record "Transfer Line";
    begin
        TransferReqLine.SetCurrentKey("Replenishment System", Type, "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date");
        TransferReqLine.SetRange("Replenishment System", TransferReqLine."Replenishment System"::Transfer);
        TransferReqLine.SetRange(Type, TransferReqLine.Type::Item);
        TransferReqLine.SetRange("No.", Item."No.");
        Item.CopyFilter("Location Filter", TransferReqLine."Transfer-from Code");
        Item.CopyFilter("Variant Filter", TransferReqLine."Variant Code");
        Item.CopyFilter("Date Filter", TransferReqLine."Transfer Shipment Date");
        if TransferReqLine.FindSet then
            repeat
                if TransferReqLine."Action Message" <> TransferReqLine."Action Message"::New then begin
                    // Neutralize demand from the related document
                    FindTransDemandToReplace(TransferReqLine, TransLine);
                    InvtEventBuf.TransferFromOutboundTransOrder(TransLine);
                    InvtEventBuf.PlanRevertEntry(InvtEventBuf, TransferReqLine."Action Message");
                    InsertEntry(InvtEventBuf);
                end;
                InvtEventBuf.TransferFromReqLineTransDemand(TransferReqLine);
                InsertEntry(InvtEventBuf);
            until TransferReqLine.Next = 0;
    end;

    procedure InsertEntry(var NewInvtEventBuffer: Record "Inventory Event Buffer")
    begin
        NewInvtEventBuffer."Entry No." := NextEntryNo;
        NewInvtEventBuffer.Insert();
    end;

    procedure NextEntryNo(): Integer
    begin
        EntryNo += 1;
        exit(EntryNo);
    end;

    local procedure FindForecastPeriodEndDate(var ProdForecastEntry: Record "Production Forecast Entry"; ToDate: Date): Date
    var
        NextProdForecastEntry: Record "Production Forecast Entry";
        NextForecastExist: Boolean;
    begin
        NextProdForecastEntry.Copy(ProdForecastEntry);
        NextProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date" + 1, ToDate);
        if NextProdForecastEntry.FindFirst then
            repeat
                NextProdForecastEntry.SetRange("Forecast Date", NextProdForecastEntry."Forecast Date");
                NextProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                if NextProdForecastEntry."Forecast Quantity (Base)" = 0 then begin
                    NextProdForecastEntry.SetRange("Forecast Date", NextProdForecastEntry."Forecast Date" + 1, ToDate);
                    if not NextProdForecastEntry.FindLast then
                        NextProdForecastEntry."Forecast Date" := ToDate + 1;
                end else
                    NextForecastExist := true;
            until (NextProdForecastEntry."Forecast Date" = ToDate + 1) or NextForecastExist
        else
            NextProdForecastEntry."Forecast Date" := ToDate + 1;
        exit(NextProdForecastEntry."Forecast Date" - 1);
    end;

    local procedure AjustForUndoneShipments(var ItemLedgEntry: Record "Item Ledger Entry") AdjustQty: Decimal
    var
        CorItemLedgEntry: Record "Item Ledger Entry";
    begin
        CorItemLedgEntry.Copy(ItemLedgEntry);
        CorItemLedgEntry.SetRange(Positive, true);
        CorItemLedgEntry.SetRange(Correction, true);
        if CorItemLedgEntry.FindSet then
            repeat
                if not CorItemLedgEntry."Derived from Blanket Order" then
                    AdjustQty += CorItemLedgEntry.Quantity;
            until CorItemLedgEntry.Next = 0;
        ItemLedgEntry.SetRange(Correction);
    end;

    local procedure ParentIsInPlanning(InvtEventBuf: Record "Inventory Event Buffer"; var ParentActionMessage: Option): Boolean
    var
        ReqLine: Record "Requisition Line";
        ProdOrderComp: Record "Prod. Order Component";
        RecRef: RecordRef;
        RecordID: RecordID;
    begin
        // Check if the parent of a component line is represented with a planning suggestion
        RecordID := InvtEventBuf."Source Line ID";
        RecRef := RecordID.GetRecord;
        RecRef.SetTable(ProdOrderComp);
        ReqLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        ReqLine.SetRange("Ref. Order Type", ReqLine."Ref. Order Type"::"Prod. Order");
        ReqLine.SetRange("Ref. Order Status", ProdOrderComp.Status);
        ReqLine.SetRange("Ref. Order No.", ProdOrderComp."Prod. Order No.");
        ReqLine.SetRange("Ref. Line No.", ProdOrderComp."Prod. Order Line No.");
        ReqLine.SetRange("Operation No.", '');
        if ReqLine.FindFirst then begin
            ParentActionMessage := ReqLine."Action Message";
            exit(true);
        end;
    end;

    local procedure FindTransDemandToReplace(ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line")
    begin
        TransLine.Get(ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
    end;

    local procedure FindReplishmentLocation(var ReplenishmentLocation: Code[10]; var Item: Record Item; var LocationMandatory: Boolean): Boolean
    var
        SKU: Record "Stockkeeping Unit";
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        LocationMandatory := InvtSetup."Location Mandatory";

        ReplenishmentLocation := '';
        SKU.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        SKU.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        SKU.SetRange("Replenishment System", Item."Replenishment System"::Purchase, Item."Replenishment System"::"Prod. Order");
        SKU.SetFilter("Reordering Policy", '<>%1', SKU."Reordering Policy"::" ");
        if SKU.Find('-') then
            if SKU.Next = 0 then
                ReplenishmentLocation := SKU."Location Code";
        exit(ReplenishmentLocation <> '');
    end;

    local procedure IsInTransitLocation(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit(Location."Use As In-Transit");
        exit(false);
    end;

    local procedure ForecastExist(var ProdForecastEntry: Record "Production Forecast Entry"; ExcludeForecastBefore: Date; FromDate: Date; ToDate: Date): Boolean
    var
        ForecastExist: Boolean;
    begin
        with ProdForecastEntry do begin
            SetRange("Forecast Date", ExcludeForecastBefore, FromDate);
            if Find('+') then
                repeat
                    SetRange("Forecast Date", "Forecast Date");
                    CalcSums("Forecast Quantity (Base)");
                    if "Forecast Quantity (Base)" <> 0 then
                        ForecastExist := true
                    else
                        SetRange("Forecast Date", ExcludeForecastBefore, "Forecast Date" - 1);
                until (not Find('+')) or ForecastExist;

            if not ForecastExist then begin
                if ExcludeForecastBefore > FromDate then
                    SetRange("Forecast Date", ExcludeForecastBefore, ToDate)
                else
                    SetRange("Forecast Date", FromDate + 1, ToDate);
                if Find('-') then
                    repeat
                        SetRange("Forecast Date", "Forecast Date");
                        CalcSums("Forecast Quantity (Base)");
                        if "Forecast Quantity (Base)" <> 0 then
                            ForecastExist := true
                        else
                            SetRange("Forecast Date", "Forecast Date" + 1, ToDate);
                    until (not Find('-')) or ForecastExist
            end;
        end;
        exit(ForecastExist);
    end;

    procedure GetSourceReferences(FromRecordID: RecordID; TransferDirection: Enum "Transfer Direction"; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceBatchName: Code[10]; var SourceProdOrderLine: Integer; var SourceRefNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlngComp: Record "Planning Component";
        ProdForecastEntry: Record "Production Forecast Entry";
        ReqLine: Record "Requisition Line";
        ServiceLine: Record "Service Line";
        JobPlngLine: Record "Job Planning Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        SourceType := 0;
        SourceSubtype := 0;
        SourceID := '';
        SourceBatchName := '';
        SourceProdOrderLine := 0;
        SourceRefNo := 0;

        RecRef := FromRecordID.GetRecord;

        case FromRecordID.TableNo of
            DATABASE::"Item Ledger Entry":
                begin
                    RecRef.SetTable(ItemLedgEntry);
                    SourceType := DATABASE::"Item Ledger Entry";
                    SourceRefNo := ItemLedgEntry."Entry No.";
                end;
            DATABASE::"Sales Line":
                begin
                    RecRef.SetTable(SalesLine);
                    SourceType := DATABASE::"Sales Line";
                    SourceSubtype := SalesLine."Document Type";
                    SourceID := SalesLine."Document No.";
                    SourceRefNo := SalesLine."Line No.";
                end;
            DATABASE::"Purchase Line":
                begin
                    RecRef.SetTable(PurchLine);
                    SourceType := DATABASE::"Purchase Line";
                    SourceSubtype := PurchLine."Document Type";
                    SourceID := PurchLine."Document No.";
                    SourceRefNo := PurchLine."Line No.";
                end;
            DATABASE::"Transfer Line":
                begin
                    RecRef.SetTable(TransLine);
                    SourceType := DATABASE::"Transfer Line";
                    SourceSubtype := TransferDirection;
                    TransLine.Get(TransLine."Document No.", TransLine."Line No.");
                    SourceID := TransLine."Document No.";
                    SourceProdOrderLine := TransLine."Derived From Line No.";
                    SourceRefNo := TransLine."Line No.";
                end;
            DATABASE::"Prod. Order Line":
                begin
                    RecRef.SetTable(ProdOrderLine);
                    SourceType := DATABASE::"Prod. Order Line";
                    SourceSubtype := ProdOrderLine.Status;
                    SourceID := ProdOrderLine."Prod. Order No.";
                    SourceProdOrderLine := ProdOrderLine."Line No.";
                end;
            DATABASE::"Prod. Order Component":
                begin
                    RecRef.SetTable(ProdOrderComp);
                    SourceType := DATABASE::"Prod. Order Component";
                    SourceSubtype := ProdOrderComp.Status;
                    SourceID := ProdOrderComp."Prod. Order No.";
                    SourceProdOrderLine := ProdOrderComp."Prod. Order Line No.";
                    SourceRefNo := ProdOrderComp."Line No.";
                end;
            DATABASE::"Planning Component":
                begin
                    RecRef.SetTable(PlngComp);
                    SourceType := DATABASE::"Planning Component";
                    SourceID := PlngComp."Worksheet Template Name";
                    SourceBatchName := PlngComp."Worksheet Batch Name";
                    SourceProdOrderLine := PlngComp."Worksheet Line No.";
                    SourceRefNo := PlngComp."Line No.";
                end;
            DATABASE::"Requisition Line":
                begin
                    RecRef.SetTable(ReqLine);
                    SourceType := DATABASE::"Requisition Line";
                    SourceSubtype := TransferDirection;
                    SourceID := ReqLine."Worksheet Template Name";
                    SourceBatchName := ReqLine."Journal Batch Name";
                    SourceRefNo := ReqLine."Line No.";
                end;
            DATABASE::"Service Line":
                begin
                    RecRef.SetTable(ServiceLine);
                    SourceType := DATABASE::"Service Line";
                    SourceSubtype := ServiceLine."Document Type";
                    SourceID := ServiceLine."Document No.";
                    SourceRefNo := ServiceLine."Line No.";
                end;
            DATABASE::"Job Planning Line":
                begin
                    RecRef.SetTable(JobPlngLine);
                    SourceType := DATABASE::"Job Planning Line";
                    JobPlngLine.Get(JobPlngLine."Job No.", JobPlngLine."Job Task No.", JobPlngLine."Line No.");
                    SourceSubtype := JobPlngLine.Status;
                    SourceID := JobPlngLine."Job No.";
                    SourceRefNo := JobPlngLine."Job Contract Entry No.";
                end;
            DATABASE::"Production Forecast Entry":
                begin
                    RecRef.SetTable(ProdForecastEntry);
                    SourceType := DATABASE::"Production Forecast Entry";
                    SourceRefNo := ProdForecastEntry."Entry No.";
                end;
            DATABASE::"Assembly Header":
                begin
                    RecRef.SetTable(AssemblyHeader);
                    SourceType := DATABASE::"Assembly Header";
                    SourceSubtype := AssemblyHeader."Document Type";
                    SourceID := AssemblyHeader."No.";
                end;
            DATABASE::"Assembly Line":
                begin
                    RecRef.SetTable(AssemblyLine);
                    SourceType := DATABASE::"Assembly Line";
                    SourceSubtype := AssemblyLine."Document Type";
                    SourceID := AssemblyLine."Document No.";
                    SourceRefNo := AssemblyLine."Line No.";
                end
            else begin
                    IsHandled := false;
                    OnAfterGetSourceReferences(
                      FromRecordID, TransferDirection, SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo,
                      IsHandled);
                    if not IsHandled then
                        exit(false);
                end;
        end;
        exit(true);
    end;

    procedure ShowDocument(RecordID: RecordID)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        TransferHeader: Record "Transfer Header";
        TransShptHeader: Record "Transfer Shipment Header";
        TransRcptHeader: Record "Transfer Receipt Header";
        ProductionOrder: Record "Production Order";
        ProdForecastName: Record "Production Forecast Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        DemandForecast: Page "Demand Forecast";
        PlanningWorksheet: Page "Planning Worksheet";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        if Format(RecordID) = '' then
            exit;

        RecRef := RecordID.GetRecord;

        case RecordID.TableNo of
            DATABASE::"Item Ledger Entry":
                begin
                    RecRef.SetTable(ItemLedgEntry);
                    ItemLedgEntry.Get(ItemLedgEntry."Entry No.");
                    ItemLedgEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
                    if ItemLedgEntry."Location Code" <> '' then
                        ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
                    if ItemLedgEntry."Variant Code" <> '' then
                        ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                    PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry);
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Order:
                            PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
                        SalesHeader."Document Type"::Invoice:
                            PAGE.RunModal(PAGE::"Sales Invoice", SalesHeader);
                        SalesHeader."Document Type"::"Credit Memo":
                            PAGE.RunModal(PAGE::"Sales Credit Memo", SalesHeader);
                        SalesHeader."Document Type"::"Blanket Order":
                            PAGE.RunModal(PAGE::"Blanket Sales Orders", SalesHeader);
                        SalesHeader."Document Type"::"Return Order":
                            PAGE.RunModal(PAGE::"Sales Return Order", SalesHeader);
                    end;
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShptHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Shipment", SalesShptHeader);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Invoice", SalesInvHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
            DATABASE::"Service Shipment Header":
                begin
                    RecRef.SetTable(ServShptHeader);
                    PAGE.RunModal(PAGE::"Posted Service Shipment", ServShptHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServInvHeader);
                    PAGE.RunModal(PAGE::"Posted Service Invoice", ServInvHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServCrMemoHeader);
                    PAGE.RunModal(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchHeader);
                    case PurchHeader."Document Type" of
                        PurchHeader."Document Type"::Order:
                            PAGE.RunModal(PAGE::"Purchase Order", PurchHeader);
                        PurchHeader."Document Type"::Invoice:
                            PAGE.RunModal(PAGE::"Purchase Invoice", PurchHeader);
                        PurchHeader."Document Type"::"Credit Memo":
                            PAGE.RunModal(PAGE::"Purchase Credit Memo", PurchHeader);
                        PurchHeader."Document Type"::"Blanket Order":
                            PAGE.RunModal(PAGE::"Blanket Purchase Order", PurchHeader);
                        PurchHeader."Document Type"::"Return Order":
                            PAGE.RunModal(PAGE::"Purchase Return Order", PurchHeader);
                    end;
                end;
            DATABASE::"Purch. Rcpt. Header":
                begin
                    RecRef.SetTable(PurchRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            DATABASE::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    PAGE.RunModal(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHdr);
                    PAGE.RunModal(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
                end;
            DATABASE::"Return Shipment Header":
                begin
                    RecRef.SetTable(ReturnShptHeader);
                    PAGE.RunModal(PAGE::"Posted Return Shipment", ReturnShptHeader);
                end;
            DATABASE::"Return Receipt Header":
                begin
                    RecRef.SetTable(ReturnRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Return Receipt", ReturnRcptHeader);
                end;
            DATABASE::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    PAGE.RunModal(PAGE::"Transfer Order", TransferHeader);
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransShptHeader);
                    PAGE.RunModal(PAGE::"Posted Transfer Shipment", TransShptHeader);
                end;
            DATABASE::"Transfer Receipt Header":
                begin
                    RecRef.SetTable(TransRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Transfer Receipt", TransRcptHeader);
                end;
            DATABASE::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder);
                    case ProductionOrder.Status of
                        ProductionOrder.Status::Planned:
                            PAGE.RunModal(PAGE::"Planned Production Order", ProductionOrder);
                        ProductionOrder.Status::"Firm Planned":
                            PAGE.RunModal(PAGE::"Firm Planned Prod. Order", ProductionOrder);
                        ProductionOrder.Status::Released:
                            PAGE.RunModal(PAGE::"Released Production Order", ProductionOrder);
                        ProductionOrder.Status::Finished:
                            PAGE.RunModal(PAGE::"Finished Production Order", ProductionOrder);
                    end;
                end;
            DATABASE::"Production Forecast Name":
                begin
                    RecRef.SetTable(ProdForecastName);
                    DemandForecast.SetProductionForecastName(ProdForecastName.Name);
                    DemandForecast.RunModal;
                end;
            DATABASE::"Requisition Line":
                begin
                    RecRef.SetTable(RequisitionLine);
                    ReqWkshTemplate.Get(RequisitionLine."Worksheet Template Name");
                    ReqWkshTemplate.TestField("Page ID");
                    PAGE.RunModal(ReqWkshTemplate."Page ID", RequisitionLine);
                end;
            DATABASE::"Planning Component":
                begin
                    RecRef.SetTable(PlanningComponent);
                    RequisitionLine.Get(
                      PlanningComponent."Worksheet Template Name", PlanningComponent."Worksheet Batch Name",
                      PlanningComponent."Worksheet Line No.");
                    PlanningWorksheet.SetTableView(RequisitionLine);
                    PlanningWorksheet.SetRecord(RequisitionLine);
                    PlanningWorksheet.Run;
                    PlanningWorksheet.OpenPlanningComponent(PlanningComponent);
                end;
            DATABASE::"Assembly Header":
                begin
                    RecRef.SetTable(AssemblyHeader);
                    PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                end;
            DATABASE::"Assembly Line":
                begin
                    RecRef.SetTable(AssemblyLine);
                    AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
                    PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                end
            else begin
                    IsHandled := false;
                    OnAfterShowDocument(RecordID, IsHandled);
                    if not IsHandled then
                        Error(TableNotSupportedErr, RecordID.TableNo);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var CurrEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordID; TransferDirection: Enum "Transfer Direction"; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceBatchName: Code[10]; var SourceProdOrderLine: Integer; var SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocument(RecordID: RecordID; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryGetQtyOnInventory(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;
}

