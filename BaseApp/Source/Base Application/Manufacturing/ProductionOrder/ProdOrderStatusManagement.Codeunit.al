codeunit 5407 "Prod. Order Status Management"
{
    Permissions = TableData "Source Code Setup" = r,
                  TableData "Production Order" = rimd,
                  TableData "Prod. Order Capacity Need" = rid,
                  TableData "Inventory Adjmt. Entry (Order)" = rim;
    TableNo = "Production Order";

    trigger OnRun()
    var
        ChangeStatusForm: Page "Change Status on Prod. Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(ChangeStatusForm, Rec, IsHandled, NewStatus, NewPostingDate, NewUpdateUnitCost);
        if IsHandled then
            exit;

        ChangeStatusForm.Set(Rec);
        if ChangeStatusForm.RunModal() = ACTION::Yes then begin
            OnRunOnAfterChangeStatusFormRun(Rec);
            ChangeStatusForm.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);
            ChangeProdOrderStatus(Rec, NewStatus, NewPostingDate, NewUpdateUnitCost);
            Commit();
            ShowStatusMessage(Rec);
        end;
    end;

    var
        Text000: Label '%2 %3  with status %1 has been changed to %5 %6 with status %4.';
        Text002: Label 'Posting Automatic consumption...\\';
        Text003: Label 'Posting lines         #1###### @2@@@@@@@@@@@@@';
        Text004: Label '%1 %2 has not been finished. Some output is still missing. Do you still want to finish the order?';
        Text005: Label 'The update has been interrupted to respect the warning.';
        Text006: Label '%1 %2 has not been finished. Some consumption is still missing. Do you still want to finish the order?';
        ToProdOrder: Record "Production Order";
        SourceCodeSetup: Record "Source Code Setup";
        Item: Record Item;
        InvtSetup: Record "Inventory Setup";
        DimMgt: Codeunit DimensionManagement;
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        UpdateProdOrderCost: Codeunit "Update Prod. Order Cost";
        ACYMgt: Codeunit "Additional-Currency Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        UOMMgt: Codeunit "Unit of Measure Management";
        NewStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        SourceCodeSetupRead: Boolean;
        Text008: Label '%1 %2 cannot be finished as the associated subcontract order %3 has not been fully delivered.';
        Text009: Label 'You cannot finish line %1 on %2 %3. It has consumption or capacity posted with no output.';
        Text010: Label 'You must specify a %1 in %2 %3 %4.';
        ProdOrderCompRemainToPickErr: Label 'You cannot finish production order no. %1 because there is an outstanding pick for one or more components.', Comment = '%1: Production Order No.';

    procedure ChangeProdOrderStatus(ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        SetPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);
        IsHandled := false;
        OnBeforeChangeStatusOnProdOrder(ProdOrder, NewStatus.AsInteger(), IsHandled, NewPostingDate, NewUpdateUnitCost);
        if IsHandled then
            exit;
        if NewStatus = NewStatus::Finished then begin
            CheckBeforeFinishProdOrder(ProdOrder);
            FlushProdOrder(ProdOrder, NewStatus, NewPostingDate);
            IsHandled := false;
            OnChangeProdOrderStatusOnBeforeDeleteDocReservation(ProdOrder, IsHandled);
            if not IsHandled then
                ReservMgt.DeleteDocumentReservation(DATABASE::"Prod. Order Line", ProdOrder.Status.AsInteger(), ProdOrder."No.", false);
            ErrorIfUnableToClearWIP(ProdOrder);
            TransProdOrder(ProdOrder);

            MakeMultiLevelAdjmt(ProdOrder);

            WhseProdRelease.FinishedDelete(ProdOrder);
            WhseOutputProdRelease.FinishedDelete(ProdOrder);
        end else begin
            OnChangeProdOrderStatusOnBeforeTransProdOrder(ProdOrder, NewStatus);
            TransProdOrder(ProdOrder);
            FlushProdOrder(ProdOrder, NewStatus, NewPostingDate);
            WhseProdRelease.Release(ProdOrder);
        end;
        SuppressCommit := false;
        OnAfterChangeStatusOnProdOrder(ProdOrder, ToProdOrder, NewStatus, NewPostingDate, NewUpdateUnitCost, SuppressCommit);

        if not SuppressCommit then
            Commit();
    end;

    local procedure MakeMultiLevelAdjmt(ProdOrder: Record "Production Order")
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeMultiLevelAdjmt(ProdOrder, IsHandled);
        if IsHandled then
            exit;

        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
    end;

    procedure TransProdOrder(var FromProdOrder: Record "Production Order")
    var
        ToProdOrderLine: Record "Prod. Order Line";
    begin
        OnBeforeTransProdOrder(FromProdOrder, NewStatus);

        with FromProdOrder do begin
            ToProdOrderLine.LockTable();

            ToProdOrder := FromProdOrder;
            ToProdOrder.Status := NewStatus;

            case Status of
                Status::Simulated:
                    ToProdOrder."Simulated Order No." := "No.";
                Status::Planned:
                    ToProdOrder."Planned Order No." := "No.";
                Status::"Firm Planned":
                    ToProdOrder."Firm Planned Order No." := "No.";
                Status::Released:
                    begin
                        ToProdOrder."Finished Date" := NewPostingDate;
                        OnTransProdOrderOnAfterStatusIsReleased(ToProdOrder, FromProdOrder);
                    end;
            end;

            ToProdOrder.TestNoSeries();
            if (ToProdOrder.GetNoSeriesCode() <> GetNoSeriesCode()) and
               (ToProdOrder.Status <> ToProdOrder.Status::Finished)
            then begin
                ToProdOrder."No." := '';
                ToProdOrder."Due Date" := 0D;
            end;

            OnTransProdOrderOnBeforeToProdOrderInsert(ToProdOrder, FromProdOrder, NewPostingDate);
            ToProdOrder.Insert(true);
            ToProdOrder."Starting Time" := "Starting Time";
            ToProdOrder."Starting Date" := "Starting Date";
            ToProdOrder."Ending Time" := "Ending Time";
            ToProdOrder."Ending Date" := "Ending Date";
            ToProdOrder.UpdateDatetime();
            ToProdOrder."Due Date" := "Due Date";
            ToProdOrder."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ToProdOrder."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ToProdOrder."Dimension Set ID" := "Dimension Set ID";
            OnCopyFromProdOrder(ToProdOrder, FromProdOrder);
            ToProdOrder.Modify();

            TransProdOrderLine(FromProdOrder);
            TransProdOrderRtngLine(FromProdOrder);
            TransProdOrderComp(FromProdOrder);
            TransProdOrderRtngTool(FromProdOrder);
            TransProdOrderRtngPersnl(FromProdOrder);
            TransProdOrdRtngQltyMeas(FromProdOrder);
            TransProdOrderCmtLine(FromProdOrder);
            TransProdOrderRtngCmtLn(FromProdOrder);
            TransProdOrderBOMCmtLine(FromProdOrder);
            TransProdOrderCapNeed(FromProdOrder);
            OnAfterTransProdOrder(FromProdOrder, ToProdOrder);
            Delete();
            FromProdOrder := ToProdOrder;
        end;
    end;

    local procedure TransProdOrderLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderLine: Record "Prod. Order Line";
        ToProdOrderLine: Record "Prod. Order Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewStatusOption: Option;
        IsHandled: Boolean;
    begin
        with FromProdOrderLine do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                OnTransProdOrderLineOnAfterFromProdOrderLineFindSet(FromProdOrderLine, ToProdOrderLine, NewStatus);
                repeat
                    IsHandled := false;
                    OnTransProdOrderLineOnBeforeFromProdOrderLineLoop(FromProdOrderLine, ToProdOrderLine, NewStatus, IsHandled, ToProdOrder);
                    if not IsHandled then begin
                        ToProdOrderLine := FromProdOrderLine;
                        ToProdOrderLine.Status := ToProdOrder.Status;
                        ToProdOrderLine."Prod. Order No." := ToProdOrder."No.";
                        InsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
                        if NewStatus = NewStatus::Finished then begin
                            if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, "Prod. Order No.", "Line No.") then begin
                                InvtAdjmtEntryOrder."Routing No." := ToProdOrderLine."Routing No.";
                                InvtAdjmtEntryOrder.Modify();
                            end else
                                InvtAdjmtEntryOrder.SetProdOrderLine(FromProdOrderLine);
                            InvtAdjmtEntryOrder."Cost is Adjusted" := false;
                            InvtAdjmtEntryOrder."Is Finished" := true;
                            OnTransProdOrderLineOnBeforeFinishedInvtAdjmtEntryOrderModify(InvtAdjmtEntryOrder, FromProdOrderLine, ToProdOrderLine, ToProdOrder);
                            InvtAdjmtEntryOrder.Modify();

                            if NewUpdateUnitCost then
                                UpdateProdOrderCost.UpdateUnitCostOnProdOrder(FromProdOrderLine, true, true);
                            ToProdOrderLine."Unit Cost (ACY)" :=
                              ACYMgt.CalcACYAmt(ToProdOrderLine."Unit Cost", NewPostingDate, true);
                            ToProdOrderLine."Cost Amount (ACY)" :=
                              ACYMgt.CalcACYAmt(ToProdOrderLine."Cost Amount", NewPostingDate, false);
                            ReservMgt.SetReservSource(FromProdOrderLine);
                            ReservMgt.DeleteReservEntries(true, 0);
                            OnTransProdOrderLineOnAfterDeleteReservEntries(FromProdOrderLine, ToProdOrderLine, NewStatus);
                        end else begin
                            if Item.Get("Item No.") then begin
                                if (Item."Costing Method" <> Item."Costing Method"::Standard) and NewUpdateUnitCost then
                                    UpdateProdOrderCost.UpdateUnitCostOnProdOrder(FromProdOrderLine, false, true);
                            end;
                            ToProdOrderLine.BlockDynamicTracking(true);
                            ToProdOrderLine.Validate(Quantity);
                            OnTransProdOrderLineOnBeforeTransferPOLineToPOLine(FromProdOrderLine, ToProdOrderLine, NewStatus);
                            ProdOrderLineReserve.TransferPOLineToPOLine(FromProdOrderLine, ToProdOrderLine, 0, true);
                        end;
                        ToProdOrderLine.Validate("Unit Cost", "Unit Cost");
                        OnCopyFromProdOrderLine(ToProdOrderLine, FromProdOrderLine);
                        ToProdOrderLine.Modify();
                        NewStatusOption := NewStatus.AsInteger();
                        OnAfterToProdOrderLineModify(ToProdOrderLine, FromProdOrderLine, NewStatusOption);
                        NewStatus := "Production Order Status".FromInteger(NewStatusOption);
                    end;
                until Next() = 0;
                OnAfterTransProdOrderLines(FromProdOrder, ToProdOrder);
                DeleteAll();
            end;
        end;
    end;

    local procedure InsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
        OnBeforeInsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
        ToProdOrderLine.Insert();
        OnAfterInsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
    end;

    local procedure TransProdOrderRtngLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngLine: Record "Prod. Order Routing Line";
        ToProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        with FromProdOrderRtngLine do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderRtngLine := FromProdOrderRtngLine;
                    ToProdOrderRtngLine.Status := ToProdOrder.Status;
                    ToProdOrderRtngLine."Prod. Order No." := ToProdOrder."No.";
                    if ToProdOrder.Status = ToProdOrder.Status::Released then
                        ToProdOrderRtngLine."Routing Status" := "Routing Status"::Planned;
                    if ToProdOrder.Status = ToProdOrder.Status::Finished then
                        ToProdOrderRtngLine."Routing Status" := "Routing Status"::Finished;

                    if ToProdOrder.Status in [ToProdOrder.Status::"Firm Planned", ToProdOrder.Status::Released] then begin
                        ProdOrderCapNeed.SetRange("Prod. Order No.", FromProdOrder."No.");
                        ProdOrderCapNeed.SetRange(Status, FromProdOrder.Status);
                        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
                        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
                        ProdOrderCapNeed.SetRange("Requested Only", false);
                        ProdOrderCapNeed.CalcSums("Needed Time (ms)");
                        ToProdOrderRtngLine."Expected Capacity Need" := ProdOrderCapNeed."Needed Time (ms)";
                    end;
                    OnCopyFromProdOrderRoutingLine(ToProdOrderRtngLine, FromProdOrderRtngLine, NewPostingDate);
                    ToProdOrderRtngLine.Insert();
                    OnAfterToProdOrderRtngLineInsert(ToProdOrderRtngLine, FromProdOrderRtngLine);
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderComp(FromProdOrder: Record "Production Order")
    var
        FromProdOrderComp: Record "Prod. Order Component";
        ToProdOrderComp: Record "Prod. Order Component";
        Location: Record Location;
    begin
        with FromProdOrderComp do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    if Location.Get("Location Code") and
                       Location."Bin Mandatory" and
                       not Location."Directed Put-away and Pick" and
                       (Status = Status::"Firm Planned") and
                       (ToProdOrder.Status = ToProdOrder.Status::Released) and
                       ("Flushing Method" in ["Flushing Method"::Forward, "Flushing Method"::"Pick + Forward"]) and
                       ("Routing Link Code" = '') and
                       ("Bin Code" = '')
                    then
                        Error(
                          Text010,
                          FieldCaption("Bin Code"),
                          TableCaption,
                          FieldCaption("Line No."),
                          "Line No.");
                    ToProdOrderComp := FromProdOrderComp;
                    ToProdOrderComp.Validate(Status, ToProdOrder.Status);
                    ToProdOrderComp."Prod. Order No." := ToProdOrder."No.";
                    OnTransProdOrderCompOnBeforeToProdOrderCompInsert(FromProdOrderComp, ToProdOrderComp);
                    ToProdOrderComp.Insert();
                    OnTransProdOrderCompOnAfterToProdOrderCompInsert(FromProdOrderComp, ToProdOrderComp);
                    if NewStatus = NewStatus::Finished then begin
                        ReservMgt.SetReservSource(FromProdOrderComp);
                        ReservMgt.DeleteReservEntries(true, 0);
                    end else begin
                        ToProdOrderComp.BlockDynamicTracking(true);
                        ToProdOrderComp.Validate("Expected Quantity");
                        ProdOrderCompReserve.TransferPOCompToPOComp(FromProdOrderComp, ToProdOrderComp, 0, true);
                        if ToProdOrderComp.Status in [ToProdOrderComp.Status::"Firm Planned", ToProdOrderComp.Status::Released] then
                            ToProdOrderComp.AutoReserve();
                    end;
                    OnCopyFromProdOrderComp(ToProdOrderComp, FromProdOrderComp);
                    ToProdOrderComp.Modify();
                until Next() = 0;
                OnAfterTransProdOrderComp(FromProdOrder, ToProdOrder);
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderRtngTool(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngTool: Record "Prod. Order Routing Tool";
        ToProdOrderRoutTool: Record "Prod. Order Routing Tool";
    begin
        with FromProdOrderRtngTool do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderRoutTool := FromProdOrderRtngTool;
                    ToProdOrderRoutTool.Status := ToProdOrder.Status;
                    ToProdOrderRoutTool."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderRoutTool.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderRtngPersnl(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
        ToProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
    begin
        with FromProdOrderRtngPersonnel do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderRtngPersonnel := FromProdOrderRtngPersonnel;
                    ToProdOrderRtngPersonnel.Status := ToProdOrder.Status;
                    ToProdOrderRtngPersonnel."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderRtngPersonnel.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrdRtngQltyMeas(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ToProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        with FromProdOrderRtngQltyMeas do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderRtngQltyMeas := FromProdOrderRtngQltyMeas;
                    ToProdOrderRtngQltyMeas.Status := ToProdOrder.Status;
                    ToProdOrderRtngQltyMeas."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderRtngQltyMeas.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderCommentLine: Record "Prod. Order Comment Line";
        ToProdOrderCommentLine: Record "Prod. Order Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderCmtLine(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        with FromProdOrderCommentLine do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderCommentLine := FromProdOrderCommentLine;
                    ToProdOrderCommentLine.Status := ToProdOrder.Status;
                    ToProdOrderCommentLine."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderCommentLine.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
        TransferLinks(FromProdOrder, ToProdOrder);
    end;

    local procedure TransProdOrderRtngCmtLn(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        ToProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderRtngCmtLn(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        with FromProdOrderRtngComment do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderRtngComment := FromProdOrderRtngComment;
                    ToProdOrderRtngComment.Status := ToProdOrder.Status;
                    ToProdOrderRtngComment."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderRtngComment.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderBOMCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        ToProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderBOMCmtLine(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        with FromProdOrderBOMComment do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            LockTable();
            if FindSet() then begin
                repeat
                    ToProdOrderBOMComment := FromProdOrderBOMComment;
                    ToProdOrderBOMComment.Status := ToProdOrder.Status;
                    ToProdOrderBOMComment."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderBOMComment.Insert();
                until Next() = 0;
                DeleteAll();
            end;
        end;
    end;

    local procedure TransProdOrderCapNeed(FromProdOrder: Record "Production Order")
    var
        FromProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ToProdOrderCapNeed: Record "Prod. Order Capacity Need";
        IsHandled: Boolean;
    begin
        with FromProdOrderCapNeed do begin
            SetRange(Status, FromProdOrder.Status);
            SetRange("Prod. Order No.", FromProdOrder."No.");
            SetRange("Requested Only", false);
            if NewStatus = NewStatus::Finished then begin
                IsHandled := false;
                OnTransProdOrderCapNeedOnBeforeDeleteAll(ToProdOrder, FromProdOrderCapNeed, IsHandled);
                if not IsHandled then
                    DeleteAll();
            end else begin
                LockTable();
                if FindSet() then begin
                    repeat
                        ToProdOrderCapNeed := FromProdOrderCapNeed;
                        ToProdOrderCapNeed.Status := ToProdOrder.Status;
                        ToProdOrderCapNeed."Prod. Order No." := ToProdOrder."No.";
                        ToProdOrderCapNeed."Allocated Time" := ToProdOrderCapNeed."Needed Time";
                        OnCopyFromProdOrderCapacityNeed(ToProdOrderCapNeed, FromProdOrderCapNeed);
                        ToProdOrderCapNeed.Insert();
                    until Next() = 0;
                    DeleteAll();
                end;
            end;
        end;
    end;

    procedure FlushProdOrder(ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; PostingDate: Date)
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        SuppliedByProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Window: Dialog;
        QtyToPost: Decimal;
        NoOfRecords: Integer;
        LineCount: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFlushProdOrder(ProdOrder, NewStatus, PostingDate, IsHandled);
        if IsHandled then
            exit;

        if IsStatusSimulatedOrPlanned(NewStatus) then
            exit;

        GetSourceCodeSetup();

        ProdOrderLine.LockTable();
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderRtngLine.SetCurrentKey("Prod. Order No.", Status, "Flushing Method");
                if NewStatus = NewStatus::Released then
                    ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Forward)
                else begin
                    ProdOrderRtngLine.Ascending(false); // In case of backward flushing on the last operation
                    ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Backward);
                end;
                ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
                ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                ProdOrderRtngLine.LockTable();
                FlushProdOrderProcessProdOrderRtngLine(ProdOrder, ProdOrderLine, ProdOrderRtngLine, PostingDate);
                OnFlushProdOrderOnAfterProdOrderLineLoopIteration(ProdOrderLine, NewStatus, PostingDate);
            until ProdOrderLine.Next() = 0;

        with ProdOrderComp do begin
            SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
            if NewStatus = NewStatus::Released then
                SetFilter(
                  "Flushing Method",
                  '%1|%2',
                  "Flushing Method"::Forward,
                  "Flushing Method"::"Pick + Forward")
            else
                SetFilter(
                  "Flushing Method",
                  '%1|%2',
                  "Flushing Method"::Backward,
                  "Flushing Method"::"Pick + Backward");
            SetRange("Routing Link Code", '');
            SetRange(Status, Status::Released);
            SetRange("Prod. Order No.", ProdOrder."No.");
            SetFilter("Item No.", '<>%1', '');
            LockTable();
            OnFlushProdOrderOnAfterProdOrderCompSetFilters(ProdOrder, ProdOrderComp);
            if FindSet() then begin
                NoOfRecords := Count;
                Window.Open(
                  Text002 +
                  Text003);
                LineCount := 0;

                repeat
                    LineCount := LineCount + 1;
                    Item.Get("Item No.");
                    Item.TestField("Rounding Precision");
                    Window.Update(1, LineCount);
                    Window.Update(2, Round(LineCount / NoOfRecords * 10000, 1));
                    ProdOrderLine.Get(Status, ProdOrder."No.", "Prod. Order Line No.");
                    if NewStatus = NewStatus::Released then
                        QtyToPost := GetNeededQty(1, false)
                    else begin
                        QtyToPost := GetNeededQty(0, false);
                        if SuppliedByProdOrderLine.Get(Status, "Prod. Order No.", "Supplied-by Line No.") and
                           (SuppliedByProdOrderLine."Remaining Quantity" = 0) and
                           (SuppliedByProdOrderLine.Quantity = SuppliedByProdOrderLine."Finished Quantity")
                        then
                            QtyToPost := GetNeededQty(1, false);
                    end;

                    OnAfterCalculateQtyToPost(ProdOrderComp, QtyToPost, ProdOrder, NewStatus);
                    RoundQtyToPost(ProdOrderComp, Item, QtyToPost);

                    if QtyToPost <> 0 then begin
                        InitItemJnlLineFromProdOrderComp(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp, PostingDate, QtyToPost);
                        ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                        OnFlushProdOrderOnBeforeCopyItemTracking(ItemJnlLine, ProdOrderComp, Item);
                        if Item."Item Tracking Code" <> '' then
                            ItemTrackingMgt.CopyItemTracking(RowID1(), ItemJnlLine.RowID1(), false);
                        PostFlushItemJnlLine(ItemJnlLine);
                        OnFlushProdOrderOnAfterPostFlushItemJnlLine(ItemJnlLine);
                    end;
                until Next() = 0;
                Window.Close();
            end;
        end;
    end;

    local procedure RoundQtyToPost(ProdOrderComp: Record "Prod. Order Component"; Item: Record Item; var QtyToPost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundQtyToPost(ProdOrderComp, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        QtyToPost := UOMMgt.RoundToItemRndPrecision(QtyToPost, Item."Rounding Precision");

        OnAfterRoundQtyToPost(ProdOrderComp, QtyToPost);
    end;

    local procedure FlushProdOrderProcessProdOrderRtngLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; PostingDate: Date)
    var
        ItemJnlLine: Record "Item Journal Line";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        IsLastOperation: Boolean;
        ActualOutputAndScrapQty: Decimal;
        ActualOutputAndScrapQtyBase: Decimal;
        PutawayQtyBaseToCalc: Decimal;
        OutputQty: Decimal;
        OutputQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFlushProdOrderProcessProdOrderRtngLine(ProdOrderLine, ProdOrderRtngLine, PostingDate, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderRtngLine.Find('-') then begin
            // First found operation
            IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';
            OnFlushProdOrderOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsLastOperation);
            if ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Backward then begin
                ActualOutputAndScrapQtyBase :=
                  CostCalcMgt.CalcActOperOutputAndScrap(ProdOrderLine, ProdOrderRtngLine);
                ActualOutputAndScrapQty := ActualOutputAndScrapQtyBase / ProdOrderLine."Qty. per Unit of Measure";
                PutawayQtyBaseToCalc := CostCalcMgt.CalcActualOutputQtyWithNoCapacity(ProdOrderLine, ProdOrderRtngLine);
            end;

            if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Forward) or IsLastOperation then begin
                OutputQty := ProdOrderLine."Remaining Quantity";
                OutputQtyBase := ProdOrderLine."Remaining Qty. (Base)";
            end else
                if not IsLastOperation then begin // Not Last Operation
                    OutputQty := ActualOutputAndScrapQty;
                    OutputQtyBase := ActualOutputAndScrapQtyBase;
                    PutawayQtyBaseToCalc := 0;
                end;
            OnFlushProdOrderProcessProdOrderRtngLineOnAfterCalcOutputQty(ProdOrderLine, ProdOrderRtngLine, OutputQty, OutputQtyBase);

            repeat
                IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';
                OnFlushProdOrderOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsLastOperation);
                InitItemJnlLineFromProdOrderLine(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderRtngLine, PostingDate);
                if ProdOrderRtngLine."Concurrent Capacities" = 0 then
                    ProdOrderRtngLine."Concurrent Capacities" := 1;
                SetTimeAndQuantityOmItemJnlLine(
                  ItemJnlLine, ProdOrderRtngLine, OutputQtyBase,
                  GetOutputQtyForProdOrderRoutingLine(ProdOrderLine, ProdOrderRtngLine, IsLastOperation, OutputQty),
                  PutawayQtyBaseToCalc);
                ItemJnlLine."Concurrent Capacity" := ProdOrderRtngLine."Concurrent Capacities";
                ItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
                if not (ItemJnlLine.TimeIsEmpty() and (ItemJnlLine."Output Quantity" = 0)) then begin
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ItemJnlLine."Dimension Set ID", ItemJnlLine."Shortcut Dimension 1 Code", ItemJnlLine."Shortcut Dimension 2 Code");
                    OnAfterUpdateGlobalDim(ItemJnlLine, ProdOrderRtngLine, ProdOrderLine);
                    if IsLastOperation then
                        ProdOrderLineReserve.TransferPOLineToItemJnlLine(ProdOrderLine, ItemJnlLine, ItemJnlLine."Output Quantity (Base)");
                    PostFlushItemJnlLine(ItemJnlLine);
                end;

                if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Backward) and IsLastOperation then begin
                    OutputQty += ActualOutputAndScrapQty;
                    OutputQtyBase += ActualOutputAndScrapQtyBase;
                    PutawayQtyBaseToCalc := 0;
                end;
            until ProdOrderRtngLine.Next() = 0;
        end;

        OnAfterFlushProdOrderProcessProdOrderRtngLine(ProdOrder, ProdOrderLine, ProdOrderRtngLine, NewStatus.AsInteger(), PostingDate);
    end;

    local procedure PostFlushItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFlushItemJnlLine(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure InitItemJnlLineFromProdOrderLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PostingDate: Date)
    begin
        ItemJnlLine.Init();
        OnInitItemJnlLineFromProdOrderLineOnAfterInit(ItemJnlLine);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ItemJnlLine.Validate("Routing No.", ProdOrderRoutingLine."Routing No.");
        ItemJnlLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ItemJnlLine."Location Code" := ProdOrderLine."Location Code";
        ItemJnlLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");

        OnAfterInitItemJnlLineFromProdOrderLine(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderRoutingLine);
    end;

    local procedure InitItemJnlLineFromProdOrderComp(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; PostingDate: Date; QtyToPost: Decimal)
    begin
        ItemJnlLine.Init();
        OnInitItemJnlLineFromProdOrderCompOnAfterInit(ItemJnlLine);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Production;
        ItemJnlLine."Order No." := ProdOrder."No.";
        ItemJnlLine."Source No." := ProdOrderLine."Item No.";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Order Line No." := ProdOrderLine."Line No.";
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Item No.", ProdOrderComp."Item No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderComp."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        ItemJnlLine."Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        ItemJnlLine.Description := ProdOrderComp.Description;
        ItemJnlLine.Validate(Quantity, QtyToPost);
        ItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
        ItemJnlLine."Location Code" := ProdOrderComp."Location Code";
        ItemJnlLine."Bin Code" := ProdOrderComp."Bin Code";
        ItemJnlLine."Variant Code" := ProdOrderComp."Variant Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
        ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        OnAfterInitItemJnlLineFromProdOrderComp(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp);
    end;

    local procedure CheckBeforeFinishProdOrder(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchLine: Record "Purchase Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ShowWarning: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBeforeFinishProdOrder(ProdOrder, IsHandled);
        if IsHandled then
            exit;

        with PurchLine do begin
            SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Type, Type::Item);
            SetRange("Prod. Order No.", ProdOrder."No.");
            SetFilter("Outstanding Quantity", '<>%1', 0);
            OnCheckBeforeFinishProdOrderOnAfterSetProdOrderCompFilters(ProdOrderComp, ProdOrder, PurchLine);
            if FindFirst() then
                Error(Text008, ProdOrder.TableCaption(), ProdOrder."No.", "Document No.");
        end;

        OnCheckBeforeFinishProdOrderOnAfterCheckProdOrder(ProdOrder);

        with ProdOrderLine do begin
            ShowWarning := false;
            SetRange(Status, ProdOrder.Status);
            SetRange("Prod. Order No.", ProdOrder."No.");
            SetFilter("Remaining Quantity", '<>0');
            IsHandled := false;
            OnCheckBeforeFinishProdOrderOnBeforeFindSet(ProdOrderLine, ProdOrderRtngLine, ShowWarning, IsHandled);
            if not IsHandled then
                if FindSet() then
                    repeat
                        ProdOrderRtngLine.SetRange(Status, Status);
                        ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
                        ProdOrderRtngLine.SetRange("Routing Reference No.", "Line No.");
                        ProdOrderRtngLine.SetRange("Next Operation No.", '');
                        ProdOrderRtngLine.SetRange("Flushing Method");
                        if not ProdOrderRtngLine.IsEmpty() then begin
                            ProdOrderRtngLine.SetFilter("Flushing Method", '<>%1', ProdOrderRtngLine."Flushing Method"::Backward);
                            ShowWarning := not ProdOrderRtngLine.IsEmpty();
                        end else
                            ShowWarning := true;
                    until (Next() = 0) or ShowWarning;

            OnCheckMissingOutput(ProdOrder, ProdOrderLine, ProdOrderRtngLine, ShowWarning);
            if ShowWarning then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, ProdOrder.TableCaption(), ProdOrder."No."), true) then
                    Error(Text005);
        end;

        with ProdOrderComp do begin
            ShowWarning := false;
            SetProdOrderCompFilters(ProdOrderComp, ProdOrder);
            if FindSet() then
                repeat
                    CheckNothingRemainingToPickForProdOrderComp(ProdOrderComp);
                    if (("Flushing Method" <> "Flushing Method"::Backward) and
                        ("Flushing Method" <> "Flushing Method"::"Pick + Backward") and
                        ("Routing Link Code" = '')) or
                       (("Routing Link Code" <> '') and not RtngWillFlushComp(ProdOrderComp))
                    then
                        ShowWarning := true;
                until Next() = 0;

            OnCheckMissingConsumption(ProdOrder, ProdOrderLine, ProdOrderRtngLine, ShowWarning);
            if ShowWarning then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text006, ProdOrder.TableCaption(), ProdOrder."No."), true) then
                    Error(Text005);
        end;
    end;

    local procedure RtngWillFlushComp(ProdOrderComp: Record "Prod. Order Component"): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderComp."Routing Link Code" = '' then
            exit;

        with ProdOrderComp do
            ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

        with ProdOrderRtngLine do begin
            SetCurrentKey("Prod. Order No.", Status, "Flushing Method");
            SetRange("Flushing Method", "Flushing Method"::Backward);
            SetRange(Status, Status::Released);
            SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
            SetRange("Routing Link Code", ProdOrderComp."Routing Link Code");
            SetRange("Routing No.", ProdOrderLine."Routing No.");
            SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            exit(FindFirst());
        end;
    end;

    local procedure GetSourceCodeSetup()
    begin
        if not SourceCodeSetupRead then
            SourceCodeSetup.Get();
        SourceCodeSetupRead := true;
    end;

    procedure SetPostingInfo(Status: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean)
    begin
        NewStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
    end;

    local procedure ErrorIfUnableToClearWIP(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.FindSet() then
            repeat
                IsHandled := false;
                OnErrorIfUnableToClearWIPOnBeforeError(ProdOrderLine, IsHandled);
                if not IsHandled then
                    if not OutputExists(ProdOrderLine) then
                        if MatrOrCapConsumpExists(ProdOrderLine) then
                            Error(Text009, ProdOrderLine."Line No.", ToProdOrder.TableCaption(), ProdOrderLine."Prod. Order No.");
            until ProdOrderLine.Next() = 0;
    end;

    procedure OutputExists(ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        if ItemLedgEntry.FindFirst() then begin
            ItemLedgEntry.CalcSums(Quantity);
            if ItemLedgEntry.Quantity <> 0 then
                exit(true)
        end;
        exit(false);
    end;

    procedure MatrOrCapConsumpExists(ProdOrderLine: Record "Prod. Order Line") EntriesExist: Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatrOrCapConsumpExists(ProdOrderLine, EntriesExist, IsHandled);
        if IsHandled then
            exit(EntriesExist);

        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
        if not ItemLedgEntry.IsEmpty() then
            exit(true);

        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        CapLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        CapLedgEntry.SetRange("Routing No.", ProdOrderLine."Routing No.");
        CapLedgEntry.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        exit(not CapLedgEntry.IsEmpty);
    end;

    procedure SetTimeAndQuantityOmItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; OutputQtyBase: Decimal; OutputQty: Decimal; PutawayQtyBaseToCalc: Decimal)
    var
        CostCalculationManagement: Codeunit "Cost Calculation Management";
    begin
        if ItemJnlLine.SubcontractingWorkCenterUsed() then begin
            ItemJnlLine.Validate("Output Quantity", 0);
            ItemJnlLine.Validate("Run Time", 0);
            ItemJnlLine.Validate("Setup Time", 0)
        end else begin
            ItemJnlLine.Validate(
              "Setup Time",
              Round(
                ProdOrderRtngLine."Setup Time" *
                ProdOrderRtngLine."Concurrent Capacities" *
                CalendarMgt.QtyperTimeUnitofMeasure(
                  ProdOrderRtngLine."Work Center No.",
                  ProdOrderRtngLine."Setup Time Unit of Meas. Code"),
                UOMMgt.TimeRndPrecision()));
            ItemJnlLine.Validate(
              "Run Time",
              CostCalculationManagement.CalcCostTime(
                OutputQtyBase + PutawayQtyBaseToCalc,
                ProdOrderRtngLine."Setup Time", ProdOrderRtngLine."Setup Time Unit of Meas. Code",
                ProdOrderRtngLine."Run Time", ProdOrderRtngLine."Run Time Unit of Meas. Code",
                ProdOrderRtngLine."Lot Size",
                ProdOrderRtngLine."Scrap Factor % (Accumulated)", ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)",
                ProdOrderRtngLine."Work Center No.", 0, false, 0));
            ItemJnlLine.Validate("Output Quantity", OutputQty);
            OnAfterSetTimeAndQuantityOmItemJnlLine(ItemJnlLine, ProdOrderRtngLine, OutputQtyBase, OutputQty);
        end;
    end;

    local procedure GetOutputQtyForProdOrderRoutingLine(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; IsLastOperation: Boolean; LastOutputQty: Decimal): Decimal
    var
        CostCalculationManagement: Codeunit "Cost Calculation Management";
        OutputQty: Decimal;
    begin
        if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Forward) or IsLastOperation then
            exit(LastOutputQty);
        OutputQty := LastOutputQty -
          CostCalculationManagement.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine) / ProdOrderLine."Qty. per Unit of Measure";
        if OutputQty > 0 then
            exit(OutputQty);
        exit(0);
    end;

    local procedure TransferLinks(FromProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order")
    var
        RecordLink: Record "Record Link";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLinks(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnTransferLinksOnBeforeCopyLinks(FromProdOrder, ToProdOrder, IsHandled);
        if not IsHandled then
            ToProdOrder.CopyLinks(FromProdOrder);
        RecordLink.SetRange("Record ID", FromProdOrder.RecordId);
        RecordLink.DeleteAll();

        RecordLink.SetRange("Record ID", ToProdOrder.RecordId);
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        if RecordLink.FindSet(true) then
            repeat
                RecordLink.Validate(
                  URL1, GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PageManagement.GetPageID(ToProdOrder), ToProdOrder));
                RecordLink.Validate(
                  Description,
                  StrSubstNo(
                    '%1 - %2 - %3',
                    PageManagement.GetPageCaption(PageManagement.GetPageID(ToProdOrder)),
                    ToProdOrder."No.", ToProdOrder.Description));
                RecordLink.Modify(true);
            until RecordLink.Next() = 0;
    end;

    local procedure IsStatusSimulatedOrPlanned(Status: Enum "Production Order Status"): Boolean
    begin
        exit((Status = Status::Simulated) or (Status = Status::Planned) or (Status = Status::"Firm Planned"));
    end;

    local procedure SetProdOrderCompFilters(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>0');

        OnAfterSetProdOrderCompFilters(ProdOrderComponent, ProductionOrder);
    end;

    local procedure ShowStatusMessage(ProdOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowStatusMessage(ProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        Message(Text000, ProdOrder.Status, ProdOrder.TableCaption(), ProdOrder."No.", ToProdOrder.Status, ToProdOrder.TableCaption(), ToProdOrder."No.");
    end;

    procedure ChangeProdOrderStatus(ProdOrder: Record "Production Order"; var NewProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
        ChangeProdOrderStatus(ProdOrder, NewStatus, NewPostingDate, NewUpdateUnitCost);
        NewProdOrder := ToProdOrder;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemJnlLineFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemJnlLineFromProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTimeAndQuantityOmItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OutputQtyBase: Decimal; OutputQty: Decimal)
    begin
    end;

    local procedure CheckNothingRemainingToPickForProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetFilter(
          "Activity Type", '%1|%2|%3',
          WarehouseActivityLine."Activity Type"::"Invt. Movement", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.", true);
        WarehouseActivityLine.SetRange("Original Breakbulk", false);
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        WarehouseActivityLine.SetFilter("Qty. Outstanding (Base)", '<>%1', 0);
        if not WarehouseActivityLine.IsEmpty() then
            Error(ProdOrderCompRemainToPickErr, ProdOrderComponent."Prod. Order No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrder(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrderLines(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrderComp(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToProdOrderLineModify(var ToProdOrderLine: Record "Prod. Order Line"; var FromProdOrderLine: Record "Prod. Order Line"; var NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToProdOrderRtngLineInsert(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; var FromProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQtyToPost(ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangeStatusOnProdOrder(var ProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGlobalDim(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeStatusOnProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished; var IsHandled: Boolean; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBeforeFinishProdOrder(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ChangeStatusOnProdOrderPage: Page "Change Status on Prod. Order"; var ProductionOrder: Record "Production Order"; var IsHandled: Boolean; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeMultiLevelAdjmt(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderRtngCmtLn(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderCmtLine(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderBOMCmtLine(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLinks(FromProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundQtyToPost(ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatrOrCapConsumpExists(ProdOrderLine: Record "Prod. Order Line"; Var EntriesExist: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeProdOrderStatusOnBeforeTransProdOrder(var ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMissingConsumption(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMissingOutput(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnAfterSetProdOrderCompFilters(var ProdOrderComp: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; var PurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnAfterCheckProdOrder(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrder(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderRoutingLine(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; FromProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderComp(var ToProdOrderComp: Record "Prod. Order Component"; var FromProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderCapacityNeed(var ToProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; FromProdOrderCapacityNeed: Record "Prod. Order Capacity Need")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterFindProdOrderRtngLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterPostFlushItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterProdOrderCompSetFilters(ProdOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterProdOrderLineLoopIteration(var ProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnBeforeCopyItemTracking(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderProcessProdOrderRtngLineOnAfterCalcOutputQty(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var OutputQty: Decimal; var OutputQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushProdOrderProcessProdOrderRtngLine(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemJnlLineFromProdOrderCompOnAfterInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemJnlLineFromProdOrderLineOnAfterInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompOnAfterToProdOrderCompInsert(var FromProdOrderComp: Record "Prod. Order Component"; var ToProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompOnBeforeToProdOrderCompInsert(var FromProdOrderComp: Record "Prod. Order Component"; var ToProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeFinishedInvtAdjmtEntryOrderModify(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; ToProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeTransferPOLineToPOLine(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCapNeedOnBeforeDeleteAll(var ProdOrder: Record "Production Order"; var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderCompFilters(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfUnableToClearWIPOnBeforeError(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterChangeStatusFormRun(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderOnBeforeToProdOrderInsert(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order"; NewPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowStatusMessage(ProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnAfterDeleteReservEntries(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; var NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderOnAfterStatusIsReleased(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrder(var FromProdOrder: Record "Production Order"; Status: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeFromProdOrderLineLoop(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status"; var IsHandled: Boolean; ToProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnAfterFromProdOrderLineFindSet(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeProdOrderStatusOnBeforeDeleteDocReservation(ProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushProdOrderProcessProdOrderRtngLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; NewStatus: Option Simulated,Planned,"Firm Planned",Released,Finished; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundQtyToPost(ProdOrderComp: Record "Prod. Order Component"; QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnBeforeFindSet(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLinksOnBeforeCopyLinks(var FromProductionOrder: Record "Production Order"; var ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;
}

