report 99001023 "Get Action Messages"
{
    Caption = 'Get Action Messages';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("Low-Level Code") WHERE("Order Tracking Policy" = CONST("Tracking & Action Msg."));
            RequestFilterFields = "No.", "Search Description";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Text001);
                Window.Update(2, "No.");

                if "Order Tracking Policy" <> "Order Tracking Policy"::"Tracking & Action Msg." then
                    CurrReport.Skip();
                ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
                ReqLineExtern.SetRange("No.", "No.");
                if ReqLineExtern.FindFirst() then begin
                    TempItemInOtherWksh := Item;
                    TempItemInOtherWksh.Insert();
                    CurrReport.Skip();
                end;

                ActionMessageEntry.SetRange("Item No.", "No.");
                if ActionMessageEntry.Find('-') then
                    repeat
                        ActionMessageEntry.SetSourceFilterFromActionEntry(ActionMessageEntry);
                        ActionMessageEntry.SetRange("Location Code", ActionMessageEntry."Location Code");
                        ActionMessageEntry.SetRange("Bin Code", ActionMessageEntry."Bin Code");
                        ActionMessageEntry.SetRange("Variant Code", ActionMessageEntry."Variant Code");
                        if ActionMessageEntry."Source ID" = '' then begin
                            TempNewActionMsgEntry.DeleteAll();
                            repeat
                                TrkgReservEntry.Get(ActionMessageEntry."Reservation Entry", false);
                                if TempNewActionMsgEntry.Get(
                                     TrkgReservEntry."Shipment Date" - 19000101D)
                                then begin // Generate Entry No. in date order.
                                    TempNewActionMsgEntry.Quantity += ActionMessageEntry.Quantity;
                                    TempNewActionMsgEntry.Modify();
                                end else begin
                                    TempNewActionMsgEntry := ActionMessageEntry;
                                    TempNewActionMsgEntry."Entry No." := TrkgReservEntry."Shipment Date" - 19000101D;
                                    TempNewActionMsgEntry."New Date" := TrkgReservEntry."Shipment Date";
                                    TempNewActionMsgEntry.Insert();
                                end;
                            until ActionMessageEntry.Next() = 0;

                            TempNewActionMsgEntry.Find('-');
                            repeat
                                TempActionMsgEntry := TempNewActionMsgEntry;
                                NextEntryNo := NextEntryNo + 1;
                                TempActionMsgEntry."Entry No." := NextEntryNo;
                                TempActionMsgEntry.Insert();
                            until TempNewActionMsgEntry.Next() = 0;
                        end else
                            if ActionMessageEntry.Find('+') then
                                UpdateActionMsgList(ActionMessageEntry."Source Type", ActionMessageEntry."Source Subtype",
                                  ActionMessageEntry."Source ID", ActionMessageEntry."Source Batch Name",
                                  ActionMessageEntry."Source Prod. Order Line", ActionMessageEntry."Source Ref. No.",
                                  ActionMessageEntry."Location Code", ActionMessageEntry."Bin Code",
                                  ActionMessageEntry."Variant Code", ActionMessageEntry."Item No.", 0D);
                        ActionMessageEntry.ClearSourceFilter();
                        ActionMessageEntry.SetRange("Location Code");
                        ActionMessageEntry.SetRange("Bin Code");
                        ActionMessageEntry.SetRange("Variant Code");
                    until ActionMessageEntry.Next() = 0;
            end;

            trigger OnPostDataItem()
            begin
                if TempItemInOtherWksh.FindFirst() then begin
                    Window.Close();
                    if Confirm(Text002) then
                        PAGE.RunModal(0, TempItemInOtherWksh);
                    if not Confirm(Text005) then
                        Error(Text006);
                    Window.Open(
                      '#1##########################\\' +
                      Text000);
                end;

                Window.Update(1, Text007);

                TempActionMsgEntry.Reset();
                PlanningLinesInserted := false;
                if not TempActionMsgEntry.Find('-') then
                    Error(Text008);

                repeat
                    GetActionMessages(TempActionMsgEntry);
                until TempActionMsgEntry.Next() = 0;

                if not PlanningLinesInserted then
                    Error(Text008);

                // Dynamic tracking is run for the handled Planning Lines:
                if TempReqLineList.Find('-') then
                    repeat
                        ReservMgt.SetReservSource(TempReqLineList);
                        ReservMgt.AutoTrack(TempReqLineList."Net Quantity (Base)");
                    until TempReqLineList.Next() = 0;

                // Dynamic tracking is run for the handled Planning Components:
                if TempPlanningCompList.Find('-') then
                    repeat
                        ReservMgt.SetReservSource(TempPlanningCompList);
                        ReservMgt.AutoTrack(TempPlanningCompList."Net Quantity (Base)");
                    until TempPlanningCompList.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                CopyFilter("Variant Filter", ActionMessageEntry."Variant Code");
                CopyFilter("Location Filter", ActionMessageEntry."Location Code");
                CopyFilter("Bin Filter", ActionMessageEntry."Bin Code");

                ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
                ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
                CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
                CopyFilter("Location Filter", ReqLineExtern."Location Code");

                ActionMessageEntry.SetCurrentKey("Source Type", "Source Subtype", "Source ID", "Source Batch Name",
                  "Source Prod. Order Line", "Source Ref. No.");
                ActionMessageEntry2.SetCurrentKey("Reservation Entry");

                TempItemInOtherWksh.DeleteAll();
                TempActionMsgEntry.DeleteAll();
                TempReqLineList.DeleteAll();
                TempPlanningCompList.DeleteAll();

                ManufacturingSetup.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Window.Open(
          '#1##########################\\' +
          Text000);
    end;

    var
        ReqLineExtern: Record "Requisition Line";
        TrkgReservEntry: Record "Reservation Entry";
        TempItemInOtherWksh: Record Item temporary;
        TempActionMsgEntry: Record "Action Message Entry" temporary;
        TempNewActionMsgEntry: Record "Action Message Entry" temporary;
        ActionMessageEntry: Record "Action Message Entry";
        ActionMessageEntry2: Record "Action Message Entry";
        ManufacturingSetup: Record "Manufacturing Setup";
        TempPlanningCompList: Record "Planning Component" temporary;
        TempReqLineList: Record "Requisition Line" temporary;
        SKU: Record "Stockkeeping Unit";
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        ReservMgt: Codeunit "Reservation Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        NextEntryNo: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        PlanningLinesInserted: Boolean;

        Text000: Label 'Item No.  #2##################';
        Text001: Label 'Building action message list...';
        Text002: Label 'Some items within the filter already exist on the planning lines.\Action messages that are related to these items will not be processed.\\Do you want to see a list of the unprocessed items?';
        Text005: Label 'Do you want to continue?';
        Text006: Label 'The process has been canceled.';
        Text007: Label 'Processing action messages...';
        Text008: Label 'No action messages exist.';
        Text009: Label 'GetActionMessages: Illegal Action Message relation.';

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
    end;

    procedure UpdateActionMsgList(ForType: Integer; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForLocation: Code[10]; ForBin: Code[10]; ForVariant: Code[10]; ForItem: Code[20]; OrderDate: Date)
    begin
        with TempActionMsgEntry do begin
            SetSourceFilter(ForType, ForSubtype, ForID, ForRefNo, false);
            SetSourceFilter(ForBatchName, ForProdOrderLine);
            SetRange("Location Code", ForLocation);
            SetRange("Bin Code", ForBin);
            SetRange("Variant Code", ForVariant);
            SetRange("Item No.", ForItem);
            SetRange("New Date", OrderDate);
            if Find('-') then
                exit;

            SetSource(ForType, ForSubtype, ForID, ForRefNo, ForBatchName, ForProdOrderLine);
            "Location Code" := ForLocation;
            "Bin Code" := ForBin;
            "Variant Code" := ForVariant;
            "Item No." := ForItem;
            "New Date" := OrderDate;
            NextEntryNo := NextEntryNo + 1;
            "Entry No." := NextEntryNo;
            Insert();
        end;
    end;

    procedure GetActionMessages(ActionMsgEntry: Record "Action Message Entry")
    var
        ReqLine: Record "Requisition Line";
        InsertNew: Boolean;
    begin
        if ActionMsgEntry."Source ID" = '' then // Not related to existing order.
            ActionMessageEntry := ActionMsgEntry
        else begin
            ActionMessageEntry.SetSourceFilterFromActionEntry(ActionMsgEntry);
            ActionMessageEntry.SetRange("Location Code", ActionMsgEntry."Location Code");
            ActionMessageEntry.SetRange("Bin Code", ActionMsgEntry."Bin Code");
            ActionMessageEntry.SetRange("Variant Code", ActionMsgEntry."Variant Code");
            ActionMessageEntry.SetRange("Item No.", ActionMsgEntry."Item No.");
            if not ActionMessageEntry.Find('-') then
                exit;
        end;

        with ActionMessageEntry do begin
            GetPlanningParameters.AtSKU(SKU, "Item No.", "Variant Code", "Location Code");
            InsertNew := false;
            ReqLine."Worksheet Template Name" := CurrTemplateName;
            ReqLine."Journal Batch Name" := CurrWorksheetName;
            ReqLine."Line No." += 10000;
            while not ReqLine.Insert() do
                ReqLine."Line No." += 10000;

            InsertNew := InitReqFromSource(ActionMsgEntry, ReqLine);

            Window.Update(2, ReqLine."No.");

            if ActionMsgEntry."Source ID" = '' then begin
                Quantity := ActionMsgEntry.Quantity;
                Type := Type::New;
                ReqLine."Due Date" := ActionMsgEntry."New Date";
                ReqLine."Ending Date" := ReqLine."Due Date" - 1;
            end else
                SumUp(ActionMessageEntry);

            if Quantity < 0 then
                if SKU."Lot Size" > 0 then
                    if ManufacturingSetup."Default Dampener %" > 0 then
                        if ManufacturingSetup."Default Dampener %" * SKU."Lot Size" / 100 >= Abs(Quantity) then
                            Quantity := 0;
            if (Quantity = 0) and ("New Date" = 0D) then
                exit;

            ReqLine."Original Quantity" := ReqLine.Quantity;
            ReqLine."Quantity (Base)" += Quantity;
            ReqLine.Quantity := Round(ReqLine."Quantity (Base)" / ReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            ReqLine."Remaining Quantity" := ReqLine.Quantity - ReqLine."Finished Quantity";
            ReqLine."Remaining Qty. (Base)" :=
              Round(ReqLine."Remaining Quantity" / ReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            if InsertNew then
                Type := Type::New;
            if "New Date" <> 0D then begin
                if Type <> Type::New then
                    ReqLine."Original Due Date" := ReqLine."Due Date";
                ReqLine."Due Date" := "New Date";
                ReqLine."Starting Date" := 0D;
                if BoundToComponent() then begin
                    ReqLine."Ending Date" := ComponentDueDate();
                    ReqLine."Ending Time" := ComponentDueTime();
                end else
                    ReqLine."Ending Date" := 0D;
            end;
            if ReqLine.Quantity = 0 then
                ReqLine."Action Message" := ReqLine."Action Message"::Cancel
            else
                ReqLine."Action Message" := Type;
            ReqLine."Planning Line Origin" := ReqLine."Planning Line Origin"::"Action Message";
            ReqLine."Accept Action Message" := true;
            ReqLine.Modify();
            if ReqLine."Starting Date" = 0D then
                ReqLine."Starting Date" := ReqLine."Due Date";
            if ReqLine."Ending Date" = 0D then
                ReqLine."Ending Date" := ReqLine."Due Date" - 1;
            ReqLine.BlockDynamicTracking(true);
            GetRoutingAndComponents(ReqLine);
            if ReqLine."Original Due Date" <> 0D then
                if not (ReqLine."Action Message" in [ReqLine."Action Message"::Reschedule,
                                                     ReqLine."Action Message"::"Resched. & Chg. Qty."])
                then
                    ReqLine."Original Due Date" := 0D;
            if ReqLine."Original Quantity" = ReqLine.Quantity then
                if ReqLine."Action Message" = ReqLine."Action Message"::"Resched. & Chg. Qty." then
                    ReqLine."Action Message" := ReqLine."Action Message"::Reschedule;
            ReqLine.Validate(Quantity);
            if ReqLine."Action Message" = ReqLine."Action Message"::Reschedule then
                ReqLine."Original Quantity" := 0;
            ReqLine.Modify();
            Clear(ReqLineExtern);

            // Retrieve temporary list of Planning Components handled:
            InvtProfileOffsetting.GetPlanningCompList(TempPlanningCompList);

            // Save inserted Planning Line in temporary list:
            TempReqLineList := ReqLine;
            TempReqLineList.Insert();

            PlanningLinesInserted := true;
        end;
    end;

    local procedure InitReqFromSource(ActionMsgEntry: Record "Action Message Entry"; var ReqLine: Record "Requisition Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchOrderLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        AsmHeader: Record "Assembly Header";
    begin
        with ActionMsgEntry do
            case "Source Type" of
                DATABASE::"Prod. Order Line":
                    if ProdOrderLine.Get("Source Subtype", "Source ID", "Source Prod. Order Line") then begin
                        ReqLine.GetProdOrderLine(ProdOrderLine);
                        exit(false);
                    end;
                DATABASE::"Purchase Line":
                    if PurchOrderLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then begin
                        ReqLine.GetPurchOrderLine(PurchOrderLine);
                        exit(false);
                    end;
                DATABASE::"Transfer Line":
                    if TransLine.Get("Source ID", "Source Ref. No.") then begin
                        ReqLine.GetTransLine(TransLine);
                        exit(false);
                    end;
                DATABASE::"Assembly Header":
                    if AsmHeader.Get("Source Subtype", "Source ID") then begin
                        ReqLine.GetAsmHeader(AsmHeader);
                        exit(false);
                    end;
                else
                    Error(Text009)
            end;
        ReqLine.TransferFromActionMessage(ActionMsgEntry);
        exit(true);
    end;

    local procedure GetRoutingAndComponents(var ReqLine: Record "Requisition Line")
    var
        Direction: Option Forward,Backward;
    begin
        InvtProfileOffsetting.GetRouting(ReqLine);
        InvtProfileOffsetting.GetComponents(ReqLine);
        InvtProfileOffsetting.Recalculate(ReqLine, Direction::Backward, true);
    end;
}

