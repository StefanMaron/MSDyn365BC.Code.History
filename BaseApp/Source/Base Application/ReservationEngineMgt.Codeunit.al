codeunit 99000831 "Reservation Engine Mgt."
{
    Permissions = TableData "Item Ledger Entry" = rm,
                  TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rid;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%1 must be greater than 0.';
        Text001: Label '%1 must be less than 0.';
        Text002: Label 'Use Cancel Reservation.';
        Text003: Label '%1 can only be reduced.';
        Text005: Label 'Outbound,Inbound';
        DummySalesLine: Record "Sales Line";
        DummyPurchLine: Record "Purchase Line";
        DummyItemJnlLine: Record "Item Journal Line";
        DummyProdOrderLine: Record "Prod. Order Line";
        DummyAsmHeader: Record "Assembly Header";
        DummyAsmLine: Record "Assembly Line";
        Item: Record Item;
        TempSurplusEntry: Record "Reservation Entry" temporary;
        TempSortRec1: Record "Reservation Entry" temporary;
        TempSortRec2: Record "Reservation Entry" temporary;
        TempSortRec3: Record "Reservation Entry" temporary;
        TempSortRec4: Record "Reservation Entry" temporary;
        Text006: Label 'Signing mismatch.';
        Text007: Label 'Renaming reservation entries...';
        DummyJobJnlLine: Record "Job Journal Line";
        ReservMgt: Codeunit "Reservation Management";
        LostReservationQty: Decimal;
        Text008: Label 'You cannot state %1 or %2 on a demand when it is linked to a supply by %3 = %4.';
        ReservationsModified: Boolean;

    procedure CancelReservation(ReservEntry: Record "Reservation Entry")
    var
        ReservEntry3: Record "Reservation Entry";
        DoCancel: Boolean;
    begin
        OnBeforeCancelReservation(ReservEntry);

        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.TestField("Disallow Cancellation", false);

        ReservEntry3.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
        DoCancel := ReservEntry3.TrackingExists or ReservEntry.TrackingExists;
        OnCancelReservationOnBeforeDoCancel(ReservEntry3, ReservEntry, DoCancel);
        if DoCancel then begin
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
            ReservEntry.Binding := ReservEntry.Binding::" ";
            ReservEntry3."Reservation Status" := ReservEntry3."Reservation Status"::Surplus;
            ReservEntry3.Binding := ReservEntry3.Binding::" ";
            RevertDateToSourceDate(ReservEntry);
            ReservEntry.Modify();
            ReservEntry3.Delete();
            ReservEntry3."Entry No." := 0;
            RevertDateToSourceDate(ReservEntry3);
            ReservEntry3.Insert();
            TempSurplusEntry.DeleteAll();
            UpdateTempSurplusEntry(ReservEntry);
            UpdateTempSurplusEntry(ReservEntry3);
            UpdateOrderTracking(TempSurplusEntry);
        end else
            CloseReservEntry(ReservEntry, true, false);
    end;

    local procedure RevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ReservEntry do
            case "Source Type" of
                DATABASE::"Sales Line":
                    begin
                        SalesLine.Get("Source Subtype", "Source ID", "Source Ref. No.");
                        if Positive then
                            ChangeDateFieldOnResEntry(ReservEntry, "Expected Receipt Date", 0D)
                        else
                            ChangeDateFieldOnResEntry(ReservEntry, 0D, SalesLine."Shipment Date");
                    end;
                DATABASE::"Purchase Line":
                    begin
                        PurchaseLine.Get("Source Subtype", "Source ID", "Source Ref. No.");
                        if Positive then
                            ChangeDateFieldOnResEntry(ReservEntry, PurchaseLine."Expected Receipt Date", 0D)
                        else
                            ChangeDateFieldOnResEntry(ReservEntry, 0D, "Shipment Date");
                    end;
                DATABASE::"Planning Component":
                    begin
                        PlanningComponent.Get("Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
                        ChangeDateFieldOnResEntry(ReservEntry, 0D, PlanningComponent."Due Date")
                    end;
                DATABASE::"Item Ledger Entry":
                    begin
                        ItemLedgerEntry.Get("Source Ref. No.");
                        ChangeDateFieldOnResEntry(ReservEntry, ItemLedgerEntry."Posting Date", 0D);
                    end;
                DATABASE::"Prod. Order Line":
                    begin
                        ProdOrderLine.Get("Source Subtype", "Source ID", "Source Prod. Order Line");
                        ChangeDateFieldOnResEntry(ReservEntry, ProdOrderLine."Due Date", 0D);
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        ProdOrderComponent.Get("Source Subtype", "Source ID", "Source Prod. Order Line", "Source Ref. No.");
                        ChangeDateFieldOnResEntry(ReservEntry, 0D, ProdOrderComponent."Due Date");
                        exit;
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransferLine.Get("Source ID", "Source Ref. No.");
                        if Positive then
                            ChangeDateFieldOnResEntry(ReservEntry, TransferLine."Receipt Date", 0D)
                        else
                            ChangeDateFieldOnResEntry(ReservEntry, 0D, TransferLine."Shipment Date");
                    end;
                DATABASE::"Service Line":
                    begin
                        ServiceLine.Get("Source Subtype", "Source ID", "Source Ref. No.");
                        ChangeDateFieldOnResEntry(ReservEntry, 0D, ServiceLine."Needed by Date");
                    end;
            end;
    end;

    local procedure ChangeDateFieldOnResEntry(var ReservEntry: Record "Reservation Entry"; ExpectedReceiptDate: Date; ShipmentDate: Date)
    begin
        ReservEntry."Expected Receipt Date" := ExpectedReceiptDate;
        ReservEntry."Shipment Date" := ShipmentDate;
    end;

    procedure CloseReservEntry(ReservEntry: Record "Reservation Entry"; ReTrack: Boolean; DeleteAll: Boolean)
    var
        ReservEntry2: Record "Reservation Entry";
        SurplusReservEntry: Record "Reservation Entry";
        DummyReservEntry: Record "Reservation Entry";
        TotalQty: Decimal;
        AvailabilityDate: Date;
    begin
        OnBeforeCloseReservEntry(ReservEntry, ReTrack, DeleteAll);

        ReservEntry.Delete();
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then
            exit;

        ModifyActionMessage(ReservEntry);

        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then begin
            GetItem(ReservEntry."Item No.");
            ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
            if (Item."Order Tracking Policy" = Item."Order Tracking Policy"::None) and
               (not TransferLineWithItemTracking(ReservEntry2)) and
               (((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and ReservEntry2.Positive) or
                (ReservEntry2."Source Type" = DATABASE::"Item Ledger Entry") or not ReservEntry2.TrackingExists)
            then
                ReservEntry2.Delete
            else begin
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;

                if ReservEntry2.Positive then begin
                    AvailabilityDate := ReservEntry2."Expected Receipt Date";
                    ReservEntry2."Shipment Date" := 0D
                end else begin
                    AvailabilityDate := ReservEntry2."Shipment Date";
                    ReservEntry2."Expected Receipt Date" := 0D;
                end;
                ReservEntry2.Modify();
                ReservMgt.SetSkipUntrackedSurplus(true);
                ReservEntry2."Quantity (Base)" :=
                  ReservMgt.MatchSurplus(ReservEntry2, SurplusReservEntry, ReservEntry2."Quantity (Base)", not ReservEntry2.Positive,
                    AvailabilityDate, Item."Order Tracking Policy");
                if ReservEntry2."Quantity (Base)" = 0 then begin
                    ReservEntry2.Delete(true);
                end else begin
                    ReservEntry2.Validate("Quantity (Base)");
                    ReservEntry2.Validate(Binding, ReservEntry2.Binding::" ");
                    if Item."Order Tracking Policy" > Item."Order Tracking Policy"::None then
                        ReservEntry2."Untracked Surplus" := ReservEntry2.IsResidualSurplus;
                    ReservEntry2.Modify();

                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
                        ModifyActionMessageDating(ReservEntry2);
                        if DeleteAll then
                            ReservMgt.IssueActionMessage(ReservEntry2, false, ReservEntry)
                        else
                            ReservMgt.IssueActionMessage(ReservEntry2, false, DummyReservEntry);
                    end;
                end;
            end;
        end;

        if ReTrack then begin
            TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
            ReservMgt.AutoTrack(TotalQty);
        end;
    end;

    procedure CloseSurplusTrackingEntry(ReservEntry: Record "Reservation Entry")
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry.Delete();
        GetItem(ReservEntry."Item No.");
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then
            exit;

        ModifyActionMessage(ReservEntry);
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then begin
            ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
            if not TransferLineWithItemTracking(ReservEntry2) and
               ((ReservEntry2."Source Type" = DATABASE::"Item Ledger Entry") or not ReservEntry2.TrackingExists)
            then
                ReservEntry2.Delete
            else begin
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
                ReservEntry2.Modify();
            end;
        end;
    end;

    procedure ModifyReservEntry(ReservEntry: Record "Reservation Entry"; NewQuantity: Decimal; NewDescription: Text[100]; ModifyReserved: Boolean)
    var
        TotalQty: Decimal;
    begin
        OnBeforeModifyReservEntry(ReservEntry, NewQuantity, NewDescription, ModifyReserved);

        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if NewQuantity * ReservEntry."Quantity (Base)" < 0 then
            if NewQuantity < 0 then
                Error(Text000, ReservEntry.FieldCaption("Quantity (Base)"))
            else
                Error(Text001, ReservEntry.FieldCaption("Quantity (Base)"));
        if NewQuantity = 0 then
            Error(Text002);
        if Abs(NewQuantity) > Abs(ReservEntry."Quantity (Base)") then
            Error(Text003, ReservEntry.FieldCaption("Quantity (Base)"));

        if ModifyReserved then begin
            if ReservEntry."Item No." <> Item."No." then
                GetItem(ReservEntry."Item No.");

            ReservEntry.Get(ReservEntry."Entry No.", ReservEntry.Positive); // Get existing entry
            ReservEntry.Validate("Quantity (Base)", NewQuantity);
            ReservEntry.Description := NewDescription;
            ReservEntry."Changed By" := UserId;
            OnModifyReservEntryOnBeforeExistingReservEntryModify(ReservEntry);
            ReservEntry.Modify();
            OnModifyReservEntryOnAfterExistingReservEntryModify(ReservEntry);
            if Item."Order Tracking Policy" > Item."Order Tracking Policy"::None then begin
                TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
                ReservMgt.AutoTrack(TotalQty);
            end;

            if ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then begin // Get related entry
                ReservEntry.Validate("Quantity (Base)", -NewQuantity);
                ReservEntry.Description := NewDescription;
                ReservEntry."Changed By" := UserId;
                ReservEntry.Modify();
                if Item."Order Tracking Policy" > Item."Order Tracking Policy"::None then begin
                    TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
                    ReservMgt.AutoTrack(TotalQty);
                end;
            end;
        end;

        OnAfterModifyReservEntry(ReservEntry);
    end;

    procedure CreateForText(ReservEntry: Record "Reservation Entry"): Text[80]
    begin
        if ReservEntry.Get(ReservEntry."Entry No.", false) then
            exit(CreateText(ReservEntry));

        exit('');
    end;

    procedure CreateFromText(ReservEntry: Record "Reservation Entry"): Text[80]
    begin
        if ReservEntry.Get(ReservEntry."Entry No.", true) then
            exit(CreateText(ReservEntry));

        exit('');
    end;

    procedure CreateText(ReservEntry: Record "Reservation Entry") SourceTypeDesc: Text[80]
    var
        SourceType: Option " ",Sales,"Requisition Line",Purchase,"Item Journal","BOM Journal","Item Ledger Entry","Prod. Order Line","Prod. Order Component","Planning Line","Planning Component",Transfer,Service,"Job Journal",Job,"Assembly Header","Assembly Line";
        SourceTypeText: Label 'Sales,Requisition Line,Purchase,Item Journal,BOM Journal,Item Ledger Entry,Prod. Order Line,Prod. Order Component,Planning Line,Planning Component,Transfer,Service,Job Journal,Job,Assembly Header,Assembly Line';
    begin
        with ReservEntry do begin
            case "Source Type" of
                DATABASE::"Sales Line":
                    begin
                        SourceType := SourceType::Sales;
                        DummySalesLine."Document Type" := "Source Subtype";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummySalesLine."Document Type", "Source ID"));
                    end;
                DATABASE::"Purchase Line":
                    begin
                        SourceType := SourceType::Purchase;
                        DummyPurchLine."Document Type" := "Source Subtype";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummyPurchLine."Document Type", "Source ID"));
                    end;
                DATABASE::"Requisition Line":
                    begin
                        SourceType := SourceType::"Requisition Line";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            "Source ID", "Source Batch Name"));
                    end;
                DATABASE::"Planning Component":
                    begin
                        SourceType := SourceType::"Planning Component";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            "Source ID", "Source Batch Name"));
                    end;
                DATABASE::"Item Journal Line":
                    begin
                        SourceType := SourceType::"Item Journal";
                        DummyItemJnlLine."Entry Type" := "Source Subtype";
                        exit(StrSubstNo('%1 %2 %3 %4', SelectStr(SourceType, SourceTypeText),
                            DummyItemJnlLine."Entry Type", "Source ID", "Source Batch Name"));
                    end;
                DATABASE::"Job Journal Line":
                    begin
                        SourceType := SourceType::"Job Journal";
                        exit(StrSubstNo('%1 %2 %3 %4', SelectStr(SourceType, SourceTypeText),
                            DummyJobJnlLine."Entry Type", "Source ID", "Source Batch Name"));
                    end;
                DATABASE::"Item Ledger Entry":
                    begin
                        SourceType := SourceType::"Item Ledger Entry";
                        exit(StrSubstNo('%1 %2', SelectStr(SourceType, SourceTypeText), "Source Ref. No."));
                    end;
                DATABASE::"Prod. Order Line":
                    begin
                        SourceType := SourceType::"Prod. Order Line";
                        DummyProdOrderLine.Status := "Source Subtype";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummyProdOrderLine.Status, "Source ID"));
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        SourceType := SourceType::"Prod. Order Component";
                        DummyProdOrderLine.Status := "Source Subtype";
                        exit(StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummyProdOrderLine.Status, "Source ID"));
                    end;
                DATABASE::"Transfer Line":
                    begin
                        SourceType := SourceType::Transfer;
                        exit(StrSubstNo('%1 %2, %3', SelectStr(SourceType, SourceTypeText),
                            "Source ID", SelectStr("Source Subtype" + 1, Text005)));
                    end;
                DATABASE::"Service Line":
                    begin
                        SourceType := SourceType::Service;
                        exit(StrSubstNo('%1 %2', SelectStr(SourceType, SourceTypeText), "Source ID"));
                    end;
                DATABASE::"Job Planning Line":
                    begin
                        SourceType := SourceType::Job;
                        exit(StrSubstNo('%1 %2', SelectStr(SourceType, SourceTypeText), "Source ID"));
                    end;
                DATABASE::"Assembly Header":
                    begin
                        DummyAsmHeader.Init();
                        SourceType := SourceType::"Assembly Header";
                        DummyAsmHeader."Document Type" := "Source Subtype";
                        exit(
                          StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummyAsmHeader."Document Type", "Source ID"));
                    end;
                DATABASE::"Assembly Line":
                    begin
                        DummyAsmLine.Init();
                        SourceType := SourceType::"Assembly Line";
                        DummyAsmLine."Document Type" := "Source Subtype";
                        exit(
                          StrSubstNo('%1 %2 %3', SelectStr(SourceType, SourceTypeText),
                            DummyAsmLine."Document Type", "Source ID"));
                    end;
            end;

            SourceTypeDesc := '';
            OnAfterCreateText(ReservEntry, SourceTypeDesc);
            exit(SourceTypeDesc);
        end;
    end;

    procedure ModifyShipmentDate(var ReservEntry: Record "Reservation Entry"; NewShipmentDate: Date)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2."Shipment Date" := NewShipmentDate;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2.Modify();

        if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry2."Shipment Date" := NewShipmentDate;
            ReservEntry2."Changed By" := UserId;
            ReservEntry2.Modify();

            ModifyActionMessageDating(ReservEntry2);
        end;

        OnAfterModifyShipmentDate(ReservEntry2, ReservEntry);
    end;

    local procedure ModifyActionMessage(ReservEntry: Record "Reservation Entry")
    begin
        GetItem(ReservEntry."Item No.");
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Surplus then begin
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                ReservMgt.ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete related action messages
        end else
            if ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order" then
                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                    ReservMgt.ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete related action messages
    end;

    procedure ModifyExpectedReceiptDate(var ReservEntry: Record "Reservation Entry"; NewExpectedReceiptDate: Date)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2."Expected Receipt Date" := NewExpectedReceiptDate;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2.Modify();

        ModifyActionMessageDating(ReservEntry2);

        if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry2."Expected Receipt Date" := NewExpectedReceiptDate;
            ReservEntry2."Changed By" := UserId;
            ReservEntry2.Modify();
        end;
    end;

    procedure InitFilterAndSortingFor(var FilterReservEntry: Record "Reservation Entry"; SetFilters: Boolean)
    begin
        FilterReservEntry.InitSortingAndFilters(SetFilters);
    end;

    procedure InitFilterAndSortingLookupFor(var FilterReservEntry: Record "Reservation Entry"; SetFilters: Boolean)
    begin
        FilterReservEntry.InitSortingAndFilters(SetFilters);
    end;

    procedure ModifyUnitOfMeasure(var ReservEntry: Record "Reservation Entry"; NewQtyPerUnitOfMeasure: Decimal)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry.TestField("Source Type");
        ReservEntry2.Reset();
        ReservEntry2.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");

        ReservEntry2.SetSourceFilterFromReservEntry(ReservEntry);

        if ReservEntry2.FindSet then
            if NewQtyPerUnitOfMeasure <> ReservEntry2."Qty. per Unit of Measure" then
                repeat
                    ReservEntry2.Validate("Qty. per Unit of Measure", NewQtyPerUnitOfMeasure);
                    ReservEntry2.Modify();
                until ReservEntry2.Next = 0;
    end;

    procedure ModifyActionMessageDating(var ReservEntry: Record "Reservation Entry")
    var
        ReservEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstDate: Date;
        NextEntryNo: Integer;
        DateFormula: DateFormula;
    begin
        if not (ReservEntry."Source Type" in [DATABASE::"Prod. Order Line",
                                              DATABASE::"Purchase Line"])
        then
            exit;

        if not ReservEntry.Positive then
            exit;

        GetItem(ReservEntry."Item No.");
        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        ActionMessageEntry.SetCurrentKey(
          "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
        ActionMessageEntry.SetSourceFilterFromReservEntry(ReservEntry);
        ActionMessageEntry.SetRange(Quantity, 0);

        ReservEntry2.Copy(ReservEntry);
        ReservEntry2.SetPointerFilter;
        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Reservation, ReservEntry2."Reservation Status"::Tracking);
        FirstDate := ReservMgt.FindDate(ReservEntry2, 0, true);

        ManufacturingSetup.Get();
        if (Format(ManufacturingSetup."Default Dampener Period") = '') or
           ((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and
            (ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation))
        then
            Evaluate(ManufacturingSetup."Default Dampener Period", '<0D>');

        ActionMessageEntry.DeleteAll();

        if FirstDate = 0D then
            exit;

        Evaluate(DateFormula, StrSubstNo('%1%2', '-', Format(ManufacturingSetup."Default Dampener Period")));
        if CalcDate(DateFormula, FirstDate) <= ReservEntry."Expected Receipt Date" then
            exit;

        if ReservEntry."Planning Flexibility" = ReservEntry."Planning Flexibility"::None then
            exit;

        ActionMessageEntry.Reset();
        NextEntryNo := ActionMessageEntry.GetLastEntryNo() + 1;
        ActionMessageEntry.Init();
        ActionMessageEntry.TransferFromReservEntry(ReservEntry);
        ActionMessageEntry."Entry No." := NextEntryNo;
        ActionMessageEntry.Type := ActionMessageEntry.Type::Reschedule;
        ActionMessageEntry."New Date" := FirstDate;
        ActionMessageEntry."Reservation Entry" := ReservEntry2."Entry No.";
        while not ActionMessageEntry.Insert do
            ActionMessageEntry."Entry No." += 1;
    end;

    procedure AddItemTrackingToTempRecSet(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code"): Decimal
    var
        ReservStatus: Integer;
    begin
        with TempReservEntry do begin
            LostReservationQty := 0; // Late Binding
            ReservationsModified := false;
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line", "Reservation Status");

            // Process entry in descending order against field Reservation Status
            for ReservStatus := "Reservation Status"::Prospect downto "Reservation Status"::Reservation do
                ModifyItemTrkgByReservStatus(
                    TempReservEntry, TrackingSpecification, ReservStatus, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);

            exit(QtyToAdd);
        end;
    end;

    [Obsolete('Replaced by AddItemTrackingToTempRecSet(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code")','16.0')]
    procedure AddItemTrackingToTempRecSet(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; SNSpecific: Boolean; LotSpecific: Boolean): Decimal
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ReservStatus: Integer;
    begin
        with TempReservEntry do begin
            LostReservationQty := 0; // Late Binding
            ReservationsModified := false;
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line", "Reservation Status");

            // Process entry in descending order against field Reservation Status
            ItemTrackingCode."SN Specific Tracking" := SNSpecific;
            ItemTrackingCode."Lot Specific Tracking" := LotSpecific;
            for ReservStatus := "Reservation Status"::Prospect downto "Reservation Status"::Reservation do
                ModifyItemTrkgByReservStatus(
                  TempReservEntry, TrackingSpecification, ReservStatus, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);

            exit(QtyToAdd);
        end;
    end;

    local procedure ModifyItemTrkgByReservStatus(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; ReservStatus: Enum "Reservation Status"; var QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code")
    begin
        if QtyToAdd = 0 then
            exit;

        TempReservEntry.SetRange("Reservation Status", ReservStatus);
        if TempReservEntry.FindSet() then
            repeat
                QtyToAdd :=
                  ModifyItemTrackingOnTempRec(
                      TempReservEntry, TrackingSpecification, QtyToAdd, QtyToAddAsBlank, 0,
                      ItemTrackingCode, false, false);
            until (TempReservEntry.Next = 0) or (QtyToAdd = 0);
    end;

    local procedure ModifyItemTrackingOnTempRec(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; LastEntryNo: Integer; ItemTrackingCode: Record "Item Tracking Code"; EntryMismatch: Boolean; CalledRecursively: Boolean): Decimal
    var
        TempReservEntryCopy: Record "Reservation Entry" temporary;
        ReservEntry1: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TempReservEntry2: Record "Reservation Entry" temporary;
        TrackingSpecification2: Record "Tracking Specification";
        QtyToAdd2: Decimal;
        ModifyPartnerRec: Boolean;
    begin
        if not CalledRecursively then begin
            TempReservEntryCopy := TempReservEntry;

            if TempReservEntry."Reservation Status" in
               [TempReservEntry."Reservation Status"::Reservation,
                TempReservEntry."Reservation Status"::Tracking]
            then begin
                ModifyPartnerRec := true;
                ReservEntry1 := TempReservEntry;
                ReservEntry1.Get(ReservEntry1."Entry No.", not ReservEntry1.Positive);
                TempReservEntry2 := ReservEntry1;
                TrackingSpecification2 := TrackingSpecification;

                SetItemTracking2(TempReservEntry2, TrackingSpecification2);

                EntryMismatch :=
                  CheckTrackingNoMismatch(
                      TempReservEntry, TrackingSpecification, TrackingSpecification2, ItemTrackingCode);
                QtyToAdd2 := -QtyToAdd;
            end;
        end;

        ReservEntry1 := TempReservEntry;
        ReservEntry1.Get(TempReservEntry."Entry No.", TempReservEntry.Positive);
        if Abs(TempReservEntry."Quantity (Base)") > Abs(QtyToAdd) then begin // Split entry
            ReservEntry2 := TempReservEntry;
            ReservEntry2.Validate("Quantity (Base)", QtyToAdd);
            ReservEntry2.CopyTrackingFromSpec(TrackingSpecification);
            ReservEntry2."Warranty Date" := TrackingSpecification."Warranty Date";
            ReservEntry2."Expiration Date" := TrackingSpecification."Expiration Date";
            ReservEntry2."Entry No." := LastEntryNo;
            OnBeforeUpdateItemTracking(ReservEntry2, TrackingSpecification);
            ReservEntry2.UpdateItemTracking;
            if EntryMismatch then begin
                if not CalledRecursively then
                    SaveLostReservQty(ReservEntry2); // Late Binding
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
                if ReservEntry2."Source Type" = DATABASE::"Item Ledger Entry" then begin
                    GetItem(ReservEntry2."Item No.");
                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                        ReservEntry2."Quantity (Base)" := 0;
                end;
            end else
                if not CalledRecursively then
                    ReservationsModified := ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation;
            if not CalledRecursively then
                VerifySurplusRecord(ReservEntry2, QtyToAddAsBlank);
            if ReservEntry2."Quantity (Base)" <> 0 then begin
                ReservEntry2.Insert();
                LastEntryNo := ReservEntry2."Entry No.";
            end;

            if EntryMismatch then
                LastEntryNo := 0;

            ReservEntry1.Validate("Quantity (Base)", ReservEntry1."Quantity (Base)" - QtyToAdd);
            ReservEntry1.Modify();
            TempReservEntry := ReservEntry1;
            if not CalledRecursively then begin
                TempReservEntry := ReservEntry2;
                if TempReservEntry."Quantity (Base)" <> 0 then
                    TempReservEntry.Insert();
                TempReservEntry := ReservEntry1;
                TempReservEntry.Modify();
            end else
                TempReservEntry := ReservEntry1;
            QtyToAdd := 0;
            UpdateTempSurplusEntry(ReservEntry1);
            UpdateTempSurplusEntry(ReservEntry2);
        end else begin // Modify entry directly
            ReservEntry1."Qty. to Handle (Base)" := ReservEntry1."Quantity (Base)";
            ReservEntry1."Qty. to Invoice (Base)" := ReservEntry1."Quantity (Base)";
            ReservEntry1.CopyTrackingFromSpec(TrackingSpecification);
            ReservEntry1."Warranty Date" := TrackingSpecification."Warranty Date";
            ReservEntry1."Expiration Date" := TrackingSpecification."Expiration Date";
            if ReservEntry1.Positive then
                ReservEntry1."Appl.-from Item Entry" := TrackingSpecification."Appl.-from Item Entry"
            else
                ReservEntry1."Appl.-to Item Entry" := TrackingSpecification."Appl.-to Item Entry";
            OnBeforeUpdateItemTracking(ReservEntry1, TrackingSpecification);
            ReservEntry1.UpdateItemTracking;
            if EntryMismatch then begin
                if not CalledRecursively then
                    SaveLostReservQty(ReservEntry1); // Late Binding
                GetItem(ReservEntry1."Item No.");
                if (ReservEntry1."Source Type" = DATABASE::"Item Ledger Entry") and
                   (Item."Order Tracking Policy" = Item."Order Tracking Policy"::None)
                then begin
                    ReservEntry1.Delete();
                end else begin
                    ReservEntry1."Reservation Status" := ReservEntry1."Reservation Status"::Surplus;
                    if CalledRecursively then begin
                        ReservEntry1.Delete();
                        ReservEntry1."Entry No." := LastEntryNo;
                        ReservEntry1.Insert();
                        LastEntryNo := ReservEntry1."Entry No.";
                    end else
                        ReservEntry1.Modify();
                end;
            end else begin
                if not CalledRecursively then
                    ReservationsModified := ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation;
                ReservEntry1.Modify();
            end;
            QtyToAdd -= ReservEntry1."Quantity (Base)";
            if not CalledRecursively then begin
                if VerifySurplusRecord(ReservEntry1, QtyToAddAsBlank) then
                    ReservEntry1.Modify();
                if ReservEntry1."Quantity (Base)" = 0 then begin
                    TempReservEntry := ReservEntry1;
                    TempReservEntry.Delete();
                    ReservEntry1.Delete();
                    ReservMgt.ModifyActionMessage(ReservEntry1."Entry No.", 0, true); // Delete related Action Msg.
                end else begin
                    TempReservEntry := ReservEntry1;
                    TempReservEntry.Modify();
                end;
            end;
            UpdateTempSurplusEntry(ReservEntry1);
        end;

        if ModifyPartnerRec then
            ModifyItemTrackingOnTempRec(
                TempReservEntry2, TrackingSpecification2, QtyToAdd2, QtyToAddAsBlank, LastEntryNo,
                ItemTrackingCode, EntryMismatch, true);

        TempSurplusEntry.Reset();
        if TempSurplusEntry.FindSet then begin
            GetItem(TempSurplusEntry."Item No.");
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                repeat
                    UpdateActionMessages(TempSurplusEntry);
                until TempSurplusEntry.Next = 0;
        end;

        if not CalledRecursively then
            TempReservEntry := TempReservEntryCopy;

        exit(QtyToAdd);
    end;

    local procedure VerifySurplusRecord(var ReservEntry: Record "Reservation Entry"; var QtyToAddAsBlank: Decimal) Modified: Boolean
    begin
        if ReservEntry.TrackingExists then
            exit;
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then begin
            ReservEntry.Validate("Quantity (Base)", 0);
            exit(true);
        end;
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then
            exit;
        if QtyToAddAsBlank * ReservEntry."Quantity (Base)" < 0 then
            Error(Text006);
        if Abs(QtyToAddAsBlank) < Abs(ReservEntry."Quantity (Base)") then begin
            ReservEntry.Validate("Quantity (Base)", QtyToAddAsBlank);
            Modified := true;
        end;
        QtyToAddAsBlank -= ReservEntry."Quantity (Base)";
        exit(Modified);
    end;

    local procedure UpdateTempSurplusEntry(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then
            exit;
        if ReservEntry."Quantity (Base)" = 0 then
            exit;
        TempSurplusEntry := ReservEntry;
        if not TempSurplusEntry.Insert() then
            TempSurplusEntry.Modify();
    end;

    procedure CollectAffectedSurplusEntries(var TempReservEntry: Record "Reservation Entry" temporary): Boolean
    begin
        TempSurplusEntry.Reset();
        TempReservEntry.Reset();

        if not TempSurplusEntry.FindSet then
            exit(false);

        repeat
            TempReservEntry := TempSurplusEntry;
            TempReservEntry.Insert();
        until TempSurplusEntry.Next = 0;

        TempSurplusEntry.DeleteAll();

        exit(true);
    end;

    procedure UpdateOrderTracking(var TempReservEntry: Record "Reservation Entry" temporary)
    var
        ReservEntry: Record "Reservation Entry";
        SurplusEntry: Record "Reservation Entry";
        ReservationMgt: Codeunit "Reservation Management";
        AvailabilityDate: Date;
        FirstLoop: Boolean;
    begin
        FirstLoop := true;

        while TempReservEntry.FindSet do begin
            if FirstLoop then begin
                GetItem(TempReservEntry."Item No.");
                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then begin
                    repeat
                        if (TempReservEntry."Source Type" = DATABASE::"Item Ledger Entry") or not TempReservEntry.TrackingExists then begin
                            ReservEntry := TempReservEntry;
                            ReservEntry.Delete();
                        end;
                    until TempReservEntry.Next = 0;
                    exit;
                end;
                ReservationMgt.SetSkipUntrackedSurplus(true);
                FirstLoop := false;
            end;
            Clear(SurplusEntry);
            SurplusEntry.TestField("Entry No.", 0);
            TempReservEntry.TestField("Item No.", Item."No.");
            if ReservEntry.Get(TempReservEntry."Entry No.", TempReservEntry.Positive) then
                if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Surplus then
                    ReservEntry."Quantity (Base)" := ReservationMgt.MatchSurplus(ReservEntry, SurplusEntry,
                        ReservEntry."Quantity (Base)", not ReservEntry.Positive, AvailabilityDate, Item."Order Tracking Policy");
            TempReservEntry.Delete();
            if SurplusEntry."Entry No." <> 0 then begin
                if ReservEntry."Quantity (Base)" = 0 then
                    ReservEntry.Delete(true)
                else begin
                    ReservEntry.Validate("Quantity (Base)");
                    ReservEntry.Modify();
                end;
                TempReservEntry := SurplusEntry;
                if not TempReservEntry.Insert() then
                    TempReservEntry.Modify();
            end;
        end;
    end;

    procedure UpdateActionMessages(SurplusEntry: Record "Reservation Entry")
    var
        DummyReservEntry: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", SurplusEntry."Entry No.");
        if not ActionMessageEntry.IsEmpty then
            ActionMessageEntry.DeleteAll();
        if not (SurplusEntry."Reservation Status" = SurplusEntry."Reservation Status"::Surplus) then
            exit;
        ReservMgt.IssueActionMessage(SurplusEntry, false, DummyReservEntry);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure ItemTrackingMismatch(ReservEntry: Record "Reservation Entry"; NewSerialNo: Code[50]; NewLotNo: Code[50]): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        if (NewLotNo = '') and (NewSerialNo = '') then
            exit(false);

        if ReservEntry."Reservation Status" > ReservEntry."Reservation Status"::Tracking then
            exit(false);

        ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);

        if ReservEntry2."Item Tracking" = ReservEntry2."Item Tracking"::None then
            exit(false);

        if (ReservEntry2."Lot No." <> '') and (NewLotNo <> '') then
            if ReservEntry2."Lot No." <> NewLotNo then
                exit(true);

        if (ReservEntry2."Serial No." <> '') and (NewSerialNo <> '') then
            if ReservEntry2."Serial No." <> NewSerialNo then
                exit(true);

        exit(false);
    end;

    procedure InitRecordSet(var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit(InitRecordSet(ReservEntry, '', ''));
    end;

    procedure InitRecordSet(var ReservEntry: Record "Reservation Entry"; CurrSerialNo: Code[50]; CurrLotNo: Code[50]): Boolean
    var
        IsDemand: Boolean;
        CarriesItemTracking: Boolean;
    begin
        // Used for combining sorting of reservation entries with priorities
        if not ReservEntry.FindSet then
            exit(false);

        IsDemand := ReservEntry."Quantity (Base)" < 0;

        TempSortRec1.Reset();
        TempSortRec2.Reset();
        TempSortRec3.Reset();
        TempSortRec4.Reset();

        TempSortRec1.DeleteAll();
        TempSortRec2.DeleteAll();
        TempSortRec3.DeleteAll();
        TempSortRec4.DeleteAll();

        repeat
            if not ItemTrackingMismatch(ReservEntry, CurrSerialNo, CurrLotNo) then begin
                TempSortRec1 := ReservEntry;
                TempSortRec1.Insert();
                CarriesItemTracking := TempSortRec1.TrackingExists;
                if CarriesItemTracking then begin
                    TempSortRec2 := TempSortRec1;
                    TempSortRec2.Insert();
                end;

                if TempSortRec1."Reservation Status" = TempSortRec1."Reservation Status"::Reservation then
                    if TempSortRec1."Expected Receipt Date" = 0D then // Inventory
                        if IsDemand then
                            if CarriesItemTracking then begin
                                TempSortRec4 := TempSortRec1;
                                TempSortRec4.Insert();
                                TempSortRec2.Delete();
                            end else begin
                                TempSortRec3 := TempSortRec1;
                                TempSortRec3.Insert();
                            end;
            end;
        until ReservEntry.Next = 0;

        SetKeyAndFilters(TempSortRec1);
        SetKeyAndFilters(TempSortRec2);
        SetKeyAndFilters(TempSortRec3);
        SetKeyAndFilters(TempSortRec4);

        exit(NEXTRecord(ReservEntry) <> 0);
    end;

    procedure NEXTRecord(var ReservEntry: Record "Reservation Entry"): Integer
    var
        Found: Boolean;
    begin
        // Used for combining sorting of reservation entries with priorities
        if not TempSortRec1.FindFirst then
            exit(0);

        if TempSortRec1."Reservation Status" = TempSortRec1."Reservation Status"::Reservation then
            if not TempSortRec4.IsEmpty then begin // Reservations with item tracking against inventory
                TempSortRec4.FindFirst;
                TempSortRec1 := TempSortRec4;
                TempSortRec4.Delete();
                Found := true;
            end else
                if not TempSortRec3.IsEmpty then begin // Reservations with no item tracking against inventory
                    TempSortRec3.FindFirst;
                    TempSortRec1 := TempSortRec3;
                    TempSortRec3.Delete();
                    Found := true;
                end;

        if not Found then begin
            TempSortRec2.SetRange("Reservation Status", TempSortRec1."Reservation Status");
            OnNextRecordOnAfterFilterTempSortRec2(TempSortRec2, TempSortRec1);
            if not TempSortRec2.IsEmpty then begin // Records carrying item tracking
                TempSortRec2.FindFirst;
                TempSortRec1 := TempSortRec2;
                TempSortRec2.Delete();
            end else begin
                TempSortRec2.SetRange("Reservation Status");
                if not TempSortRec2.IsEmpty then begin // Records carrying item tracking
                    TempSortRec2.FindFirst;
                    TempSortRec1 := TempSortRec2;
                    TempSortRec2.Delete();
                end;
            end;
        end;

        ReservEntry := TempSortRec1;
        TempSortRec1.Delete();
        exit(1);
    end;

    local procedure SetKeyAndFilters(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry.IsEmpty then
            exit;

        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");

        if ReservEntry.FindFirst then
            ReservEntry.SetPointerFilter;
    end;

    procedure RenamePointer(TableID: Integer; OldSubtype: Integer; OldID: Code[20]; OldBatchName: Code[10]; OldProdOrderLine: Integer; OldRefNo: Integer; NewSubtype: Integer; NewID: Code[20]; NewBatchName: Code[10]; NewProdOrderLine: Integer; NewRefNo: Integer)
    var
        ReservEntry: Record "Reservation Entry";
        NewReservEntry: Record "Reservation Entry";
        W: Dialog;
        PointerFieldIsActive: array[6] of Boolean;
    begin
        GetActivePointerFields(TableID, PointerFieldIsActive);
        if not PointerFieldIsActive[1] then
            exit;

        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");

        if PointerFieldIsActive[3] then
            ReservEntry.SetRange("Source ID", OldID)
        else
            ReservEntry.SetRange("Source ID", '');

        if PointerFieldIsActive[6] then
            ReservEntry.SetRange("Source Ref. No.", OldRefNo)
        else
            ReservEntry.SetRange("Source Ref. No.", 0);

        ReservEntry.SetRange("Source Type", TableID);

        if PointerFieldIsActive[2] then
            ReservEntry.SetRange("Source Subtype", OldSubtype)
        else
            ReservEntry.SetRange("Source Subtype", 0);

        if PointerFieldIsActive[4] then
            ReservEntry.SetRange("Source Batch Name", OldBatchName)
        else
            ReservEntry.SetRange("Source Batch Name", '');

        if PointerFieldIsActive[5] then
            ReservEntry.SetRange("Source Prod. Order Line", OldProdOrderLine)
        else
            ReservEntry.SetRange("Source Prod. Order Line", 0);

        ReservEntry.Lock;

        if ReservEntry.FindSet then begin
            W.Open(Text007);
            repeat
                NewReservEntry := ReservEntry;
                if OldSubtype <> NewSubtype then
                    NewReservEntry."Source Subtype" := NewSubtype;
                if OldID <> NewID then
                    NewReservEntry."Source ID" := NewID;
                if OldBatchName <> NewBatchName then
                    NewReservEntry."Source Batch Name" := NewBatchName;
                if OldProdOrderLine <> NewProdOrderLine then
                    NewReservEntry."Source Prod. Order Line" := NewProdOrderLine;
                if OldRefNo <> NewRefNo then
                    NewReservEntry."Source Ref. No." := NewRefNo;
                ReservEntry.Delete();
                NewReservEntry.Insert();
            until ReservEntry.Next = 0;
            W.Close;
        end;
    end;

    local procedure GetActivePointerFields(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean)
    begin
        Clear(PointerFieldIsActive);
        PointerFieldIsActive[1] := true;  // Type

        case TableID of
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line",
            DATABASE::"Service Line",
            DATABASE::"Job Planning Line",
            DATABASE::"Assembly Line":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Requisition Line":
                begin
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[4] := true;  // BatchName
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Item Journal Line":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[4] := true;  // BatchName
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Job Journal Line":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[4] := true;  // BatchName
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Item Ledger Entry":
                PointerFieldIsActive[6] := true;  // RefNo
            DATABASE::"Prod. Order Line":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[5] := true;  // ProdOrderLine
                end;
            DATABASE::"Prod. Order Component", DATABASE::"Transfer Line":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[5] := true;  // ProdOrderLine
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Planning Component":
                begin
                    PointerFieldIsActive[3] := true;  // ID
                    PointerFieldIsActive[4] := true;  // BatchName
                    PointerFieldIsActive[5] := true;  // ProdOrderLine
                    PointerFieldIsActive[6] := true;  // RefNo
                end;
            DATABASE::"Assembly Header":
                begin
                    PointerFieldIsActive[2] := true;  // SubType
                    PointerFieldIsActive[3] := true;  // ID
                end;
            else
                PointerFieldIsActive[1] := false;  // Type is not used
        end;
    end;

    procedure SplitTrackingConnection(ReservEntry2: Record "Reservation Entry"; NewDate: Date)
    var
        ActionMessageEntry: Record "Action Message Entry";
        ReservEntry3: Record "Reservation Entry";
        DummyReservEntry: Record "Reservation Entry";
    begin
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", ReservEntry2."Entry No.");
        if not ActionMessageEntry.IsEmpty then
            ActionMessageEntry.DeleteAll();

        if ReservEntry2.Positive then begin
            ReservEntry2."Expected Receipt Date" := NewDate;
            ReservEntry2."Shipment Date" := 0D;
        end else begin
            ReservEntry2."Shipment Date" := NewDate;
            ReservEntry2."Expected Receipt Date" := 0D;
        end;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
        ReservEntry2.Modify();

        if ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry3.Delete();
            ReservEntry3."Entry No." := 0;
            ReservEntry3."Reservation Status" := ReservEntry3."Reservation Status"::Surplus;
            if ReservEntry3.Positive then
                ReservEntry3."Shipment Date" := 0D
            else
                ReservEntry3."Expected Receipt Date" := 0D;
            ReservEntry3.Insert();
        end else
            Clear(ReservEntry3);

        if ReservEntry2."Quantity (Base)" <> 0 then
            ReservMgt.IssueActionMessage(ReservEntry2, false, DummyReservEntry);

        if ReservEntry3."Quantity (Base)" <> 0 then
            ReservMgt.IssueActionMessage(ReservEntry3, false, DummyReservEntry);
    end;

    local procedure SaveLostReservQty(ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then begin
            LostReservationQty += ReservEntry."Quantity (Base)";
            ReservationsModified := true;
        end;
    end;

    procedure RetrieveLostReservQty(var LostQuantity: Decimal) ReservEntriesHaveBeenModified: Boolean
    begin
        LostQuantity := LostReservationQty;
        LostReservationQty := 0;
        ReservEntriesHaveBeenModified := ReservationsModified;
        ReservationsModified := false;
    end;

    local procedure SetItemTracking2(TempReservEntry2: Record "Reservation Entry"; var TrackingSpecification2: Record "Tracking Specification")
    begin
        if TempReservEntry2.Binding = TempReservEntry2.Binding::"Order-to-Order" then begin
            // only supply can change IT and demand must respect it
            if TempReservEntry2.Positive and
               ((TempReservEntry2."Serial No." <> TrackingSpecification2."Serial No.") or
                (TempReservEntry2."Lot No." <> TrackingSpecification2."Lot No."))
            then
                Error(Text008,
                  TempReservEntry2.FieldCaption("Serial No."),
                  TempReservEntry2.FieldCaption("Lot No."),
                  TempReservEntry2.FieldCaption(Binding),
                  TempReservEntry2.Binding);
        end else
            // each record brings/holds own IT
            TrackingSpecification2.CopyTrackingFromReservEntry(TempReservEntry2);

        OnAfterSetItemTracking2(TrackingSpecification2, TempReservEntry2);
    end;

    procedure ResvExistsForSalesHeader(var SalesHeader: Record "Sales Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        with SalesHeader do begin
            ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
            ReservEntry.SetRange("Source Subtype", "Document Type");
            ReservEntry.SetRange("Source ID", "No.");
        end;

        exit(ResvExistsForHeader(ReservEntry));
    end;

    procedure ResvExistsForPurchHeader(var PurchHeader: Record "Purchase Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        with PurchHeader do begin
            ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
            ReservEntry.SetRange("Source Subtype", "Document Type");
            ReservEntry.SetRange("Source ID", "No.");
        end;

        exit(ResvExistsForHeader(ReservEntry));
    end;

    procedure ResvExistsForTransHeader(var TransHeader: Record "Transfer Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        with TransHeader do begin
            ReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
            ReservEntry.SetRange("Source ID", "No.");
        end;

        exit(ResvExistsForHeader(ReservEntry));
    end;

    local procedure ResvExistsForHeader(var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetFilter("Source Ref. No.", '>0');
        ReservEntry.SetFilter("Expected Receipt Date", '<>%1', 0D);

        exit(not ReservEntry.IsEmpty);
    end;

    local procedure TransferLineWithItemTracking(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservEntry."Source Type" = DATABASE::"Transfer Line") and ReservEntry.TrackingExists);
    end;

    local procedure CheckTrackingNoMismatch(ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; TrackingSpecification2: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        SNMismatch: Boolean;
        LotMismatch: Boolean;
    begin
        if ReservEntry.Positive then begin
            if TrackingSpecification2."Serial No." <> '' then
                SNMismatch := ItemTrackingCode."SN Specific Tracking" and
                  (TrackingSpecification."Serial No." <> TrackingSpecification2."Serial No.");
            if TrackingSpecification2."Lot No." <> '' then
                LotMismatch := ItemTrackingCode."Lot Specific Tracking" and
                  (TrackingSpecification."Lot No." <> TrackingSpecification2."Lot No.");
        end else begin
            if TrackingSpecification."Serial No." <> '' then
                SNMismatch := ItemTrackingCode."SN Specific Tracking" and
                  (TrackingSpecification."Serial No." <> TrackingSpecification2."Serial No.");
            if TrackingSpecification."Lot No." <> '' then
                LotMismatch := ItemTrackingCode."Lot Specific Tracking" and
                  (TrackingSpecification."Lot No." <> TrackingSpecification2."Lot No.");
        end;
        exit(LotMismatch or SNMismatch);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var SourceTypeText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyShipmentDate(var ReservationEntry2: Record "Reservation Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemTracking2(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCancelReservation(ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseReservEntry(var ReservEntry: Record "Reservation Entry"; ReTrack: Boolean; DeleteAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyReservEntry(ReservEntry: Record "Reservation Entry"; NewQuantity: Decimal; NewDescription: Text[100]; ModifyReserved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemTracking(var ReservEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelReservationOnBeforeDoCancel(ReservationEntry3: Record "Reservation Entry"; ReservationEntry: Record "Reservation Entry"; var DoCancel: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyReservEntryOnAfterExistingReservEntryModify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyReservEntryOnBeforeExistingReservEntryModify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecordOnAfterFilterTempSortRec2(var TempSortReservEntry2: Record "Reservation Entry"; TempSortReservEntry1: Record "Reservation Entry")
    begin
    end;
}

