codeunit 99000838 "Prod. Order Comp.-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

    procedure CreateReservation(ProdOrderComp: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        ProdOrderComp.TestField("Item No.");
        ProdOrderComp.TestField("Due Date");
        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderComp."Remaining Qty. (Base)") < Abs(ProdOrderComp."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderComp."Remaining Qty. (Base)") - Abs(ProdOrderComp."Reserved Qty. (Base)"));

        ProdOrderComp.TestField("Location Code", FromTrackingSpecification."Location Code");
        ProdOrderComp.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        if QuantityBase > 0 then
            ShipmentDate := ProdOrderComp."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderComp."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Prod. Order Component", ProdOrderComp.Status,
          ProdOrderComp."Prod. Order No.", '', ProdOrderComp."Prod. Order Line No.",
          ProdOrderComp."Line No.", ProdOrderComp."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(ProdOrderComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(ProdOrderComp: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(ProdOrderComp, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    local procedure CreateBindingReservation(ProdOrderComp: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(ProdOrderComp, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    [Obsolete('Replaced by ProdOrderComp.SetReservationFilters(FilterReservEntry)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component")
    begin
        ProdOrderComp.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(ProdOrderComp: Record "Prod. Order Component") CaptionText: Text
    begin
        CaptionText := ProdOrderComp.GetSourceCaption;
    end;

    procedure FindReservEntry(ProdOrderComp: Record "Prod. Order Component"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ProdOrderComp.SetReservationFilters(ReservEntry);
        if not ReservEntry.IsEmpty then
            exit(ReservEntry.FindLast);
    end;

    procedure ReservEntryExist(ProdOrderComp: Record "Prod. Order Component"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ProdOrderComp);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderComp.Status = NewProdOrderComp.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderComp."Line No." = 0 then
            if not ProdOrderComp.Get(
                 NewProdOrderComp.Status,
                 NewProdOrderComp."Prod. Order No.",
                 NewProdOrderComp."Prod. Order Line No.",
                 NewProdOrderComp."Line No.")
            then
                exit;

        NewProdOrderComp.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderComp."Reserved Qty. (Base)" <> 0;

        if NewProdOrderComp."Due Date" = 0D then
            if ShowError then
                NewProdOrderComp.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderComp."Item No." <> OldProdOrderComp."Item No." then
            if ShowError then
                NewProdOrderComp.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderComp."Location Code" <> OldProdOrderComp."Location Code" then
            if ShowError then
                NewProdOrderComp.FieldError("Location Code", Text003)
            else
                HasError := true;
        if (NewProdOrderComp."Bin Code" <> OldProdOrderComp."Bin Code") and
           (not ReservMgt.CalcIsAvailTrackedQtyInBin(
              NewProdOrderComp."Item No.", NewProdOrderComp."Bin Code",
              NewProdOrderComp."Location Code", NewProdOrderComp."Variant Code",
              DATABASE::"Prod. Order Component", NewProdOrderComp.Status,
              NewProdOrderComp."Prod. Order No.", '', NewProdOrderComp."Prod. Order Line No.",
              NewProdOrderComp."Line No."))
        then begin
            if ShowError then
                NewProdOrderComp.FieldError("Bin Code", Text003);
            HasError := true;
        end;
        if NewProdOrderComp."Variant Code" <> OldProdOrderComp."Variant Code" then
            if ShowError then
                NewProdOrderComp.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderComp."Line No." <> OldProdOrderComp."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderComp, OldProdOrderComp, HasError, ShowError);

        if HasError then
            if (NewProdOrderComp."Item No." <> OldProdOrderComp."Item No.") or NewProdOrderComp.ReservEntryExist() then begin
                if NewProdOrderComp."Item No." <> OldProdOrderComp."Item No." then begin
                    ReservMgt.SetReservSource(OldProdOrderComp);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewProdOrderComp);
                end else begin
                    ReservMgt.SetReservSource(NewProdOrderComp);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewProdOrderComp."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderComp."Due Date" <> OldProdOrderComp."Due Date") then begin
            AssignForPlanning(NewProdOrderComp);
            if (NewProdOrderComp."Item No." <> OldProdOrderComp."Item No.") or
               (NewProdOrderComp."Variant Code" <> OldProdOrderComp."Variant Code") or
               (NewProdOrderComp."Location Code" <> OldProdOrderComp."Location Code")
            then
                AssignForPlanning(OldProdOrderComp);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if Blocked then
            exit;

        with NewProdOrderComp do begin
            if Status = Status::Finished then
                exit;
            if "Line No." = OldProdOrderComp."Line No." then
                if "Remaining Qty. (Base)" = OldProdOrderComp."Remaining Qty. (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ProdOrderComp.Get(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewProdOrderComp);
            if "Qty. per Unit of Measure" <> OldProdOrderComp."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Remaining Qty. (Base)" * OldProdOrderComp."Remaining Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Qty. (Base)");
            AssignForPlanning(NewProdOrderComp);
        end;
    end;

    procedure TransferPOCompToPOComp(var OldProdOrderComp: Record "Prod. Order Component"; var NewProdOrderComp: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOCompToPOComp(OldProdOrderComp, NewProdOrderComp);

        if not FindReservEntry(OldProdOrderComp, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewProdOrderComp.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

        OldReservEntry.TransferReservations(
          OldReservEntry, OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code",
          TransferAll, TransferQty, NewProdOrderComp."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Component", NewProdOrderComp.Status, NewProdOrderComp."Prod. Order No.", '',
          NewProdOrderComp."Prod. Order Line No.", NewProdOrderComp."Line No.");
    end;

    procedure TransferPOCompToItemJnlLine(var OldProdOrderComp: Record "Prod. Order Component"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal)
    begin
        TransferPOCompToItemJnlLineCheckILE(OldProdOrderComp, NewItemJnlLine, TransferQty, false);
    end;

    procedure TransferPOCompToItemJnlLineCheckILE(var OldProdOrderComp: Record "Prod. Order Component"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(OldProdOrderComp, OldReservEntry) then
            exit;

        if CheckApplFromItemEntry then
            if OppositeReservationEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then
                if OppositeReservationEntry."Source Type" <> DATABASE::"Item Ledger Entry" then
                    exit;

        // Store initial values
        OldReservEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservEntry.Lock;

        // Handle Item Tracking on consumption:
        Clear(CreateReservEntry);
        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::Consumption then
            if NewItemJnlLine.TrackingExists then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJnlLine);
                // Try to match against Item Tracking on the prod. order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty then
                    OldReservEntry.ClearTrackingFilter
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJnlLine.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry, NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.") then
            repeat
                OldReservEntry.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    NewItemJnlLine."Entry Type", NewItemJnlLine."Journal Template Name", NewItemJnlLine."Journal Batch Name", 0,
                    NewItemJnlLine."Line No.", NewItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                EndLoop := TransferQty = 0;
                if not EndLoop then
                    if ReservEngineMgt.NEXTRecord(OldReservEntry) = 0 then
                        if ItemTrackingFilterIsSet then begin
                            OldReservEntry.SetRange("Serial No.");
                            OldReservEntry.SetRange("Lot No.");
                            ItemTrackingFilterIsSet := false;
                            EndLoop := not ReservEngineMgt.InitRecordSet(OldReservEntry);
                        end else
                            EndLoop := true;
            until EndLoop;

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := OldProdOrderComp."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservMgt.SetReservSource(OldProdOrderComp);
                ReservMgt.DeleteReservEntries(false, OldProdOrderComp."Remaining Qty. (Base)");
            end;
        end;
    end;

    procedure DeleteLineConfirm(var ProdOrderComp: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ProdOrderComp do begin
            if not FindReservEntry(ProdOrderComp, ReservationEntry) then
                exit(true);

            ReservMgt.SetReservSource(ProdOrderComp);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ProdOrderComp: Record "Prod. Order Component")
    begin
        if Blocked then
            exit;

        with ProdOrderComp do begin
            Clear(ReservMgt);
            ReservMgt.SetReservSource(ProdOrderComp);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            OnDeleteLineOnAfterDeleteReservEntries(ProdOrderComp);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(ProdOrderComp);
        end;
    end;

    local procedure AssignForPlanning(var ProdOrderComp: Record "Prod. Order Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ProdOrderComp do begin
            if Status = Status::Simulated then
                exit;
            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", "Due Date");
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderComp: Record "Prod. Order Component")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if ProdOrderComp.Status = ProdOrderComp.Status::Finished then
            ItemTrackingDocMgt.ShowItemTrackingForProdOrderComp(DATABASE::"Prod. Order Component",
              ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.")
        else begin
            ProdOrderComp.TestField("Item No.");
            TrackingSpecification.InitFromProdOrderComp(ProdOrderComp);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderComp."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderComp.IsInbound);
            ItemTrackingLines.RunModal;
        end;

        OnAfterCallItemTracking(ProdOrderComp);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", true);
        ReservEntry.SetSourceFilter('', ProdOrderComponent."Prod. Order Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure BindToPurchase(ProdOrderComp: Record "Prod. Order Component"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ProdOrderComp: Record "Prod. Order Component"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
          ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(ProdOrderComp: Record "Prod. Order Component"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(ProdOrderComp: Record "Prod. Order Component"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderComp);
            ProdOrderComp.Find;
            QtyPerUOM := ProdOrderComp.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        SourceRecRef.SetTable(ProdOrderComp);
        ProdOrderComp.TestField("Due Date");

        ProdOrderComp.SetReservationEntry(ReservEntry);

        CaptionText := ProdOrderComp.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(71);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [71, 72, 73, 74]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 5407); // DATABASE::"Prod. Order Component"
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        AvailableProdOrderComp: page "Available - Prod. Order Comp.";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableProdOrderComp);
            AvailableProdOrderComp.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableProdOrderComp.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableProdOrderComp.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then begin
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Prod. Order Component") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ProdOrderComp);
            CreateReservation(ProdOrderComp, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrder.Reset();
            ProdOrder.SetRange(Status, SourceSubtype);
            ProdOrder.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Simulated Production Order", ProdOrder);
                1:
                    PAGE.RunModal(PAGE::"Planned Production Order", ProdOrder);
                2:
                    PAGE.RunModal(PAGE::"Firm Planned Prod. Order", ProdOrder);
                3:
                    PAGE.RunModal(PAGE::"Released Production Order", ProdOrder);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrderComp.Reset();
            ProdOrderComp.SetRange(Status, SourceSubtype);
            ProdOrderComp.SetRange("Prod. Order No.", SourceID);
            ProdOrderComp.SetRange("Prod. Order Line No.", SourceProdOrderLine);
            ProdOrderComp.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, ProdOrderComp);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderComp);
            ProdOrderComp.SetReservationFilters(ReservEntry);
            CaptionText := ProdOrderComp.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ProdOrderComp);
            ProdOrderComp.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ProdOrderComp);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderComp."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderComp."Expected Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderComp.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderComp.FilterLinesForReservation(CalcReservEntry, Status, AvailabilityFilter, Positive);
        if ProdOrderComp.FindSet then
            repeat
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= ProdOrderComp."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderComp."Remaining Qty. (Base)";
            until ProdOrderComp.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity < 0) = Positive then begin
                "Table ID" := DATABASE::"Prod. Order Component";
                if Status = ProdOrderComp.Status::"Firm Planned" then
                    "Summary Type" :=
                        CopyStr(StrSubstNo(Text010, ProdOrderComp.TableCaption), 1, MaxStrLen("Summary Type"))
                else
                    "Summary Type" :=
                        CopyStr(StrSubstNo(Text011, ProdOrderComp.TableCaption), 1, MaxStrLen("Summary Type"));
                "Total Quantity" := -TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [73, 74] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 71, Positive, TotalQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOCompToPOComp(var OldProdOrderComp: Record "Prod. Order Component"; var NewProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderComp: Record "Prod. Order Component"; OldProdOrderComp: Record "Prod. Order Component"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

