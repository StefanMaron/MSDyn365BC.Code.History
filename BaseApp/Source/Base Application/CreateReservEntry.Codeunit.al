codeunit 99000830 "Create Reserv. Entry"
{
    Permissions = TableData "Reservation Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'You cannot reserve this entry because it is not a true demand or supply.';
        InsertReservEntry: Record "Reservation Entry";
        InsertReservEntry2: Record "Reservation Entry";
        LastReservEntry: Record "Reservation Entry";
        TempTrkgSpec1: Record "Tracking Specification" temporary;
        TempTrkgSpec2: Record "Tracking Specification" temporary;
        Text001: Label 'Cannot match item tracking.';
        UOMMgt: Codeunit "Unit of Measure Management";
        OverruleItemTracking: Boolean;
        Inbound: Boolean;
        UseQtyToInvoice: Boolean;
        QtyToHandleAndInvoiceIsSet: Boolean;
        LastProcessedSourceID: Text;

    procedure CreateEntry(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Description: Text[100]; ExpectedReceiptDate: Date; ShipmentDate: Date; TransferredFromEntryNo: Integer; Status: Enum "Reservation Status")
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        TrackingSpecificationExists: Boolean;
        FirstSplit: Boolean;
    begin
        TempTrkgSpec1.Reset();
        TempTrkgSpec2.Reset();
        TempTrkgSpec1.DeleteAll();
        TempTrkgSpec2.DeleteAll();

        // Status Surplus gets special treatment.

        if Status < Status::Surplus then
            if InsertReservEntry."Quantity (Base)" = 0 then
                exit;

        InsertReservEntry.TestField("Source Type");

        ReservEntry := InsertReservEntry;
        ReservEntry."Reservation Status" := Status;
        ReservEntry."Item No." := ItemNo;
        ReservEntry."Variant Code" := VariantCode;
        ReservEntry."Location Code" := LocationCode;
        ReservEntry.Description := Description;
        ReservEntry."Creation Date" := WorkDate;
        ReservEntry."Created By" := UserId;
        ReservEntry."Expected Receipt Date" := ExpectedReceiptDate;
        ReservEntry."Shipment Date" := ShipmentDate;
        ReservEntry."Transferred from Entry No." := TransferredFromEntryNo;
        ReservEntry.Positive := (ReservEntry."Quantity (Base)" > 0);
        if (ReservEntry."Quantity (Base)" <> 0) and
           ((ReservEntry.Quantity = 0) or (ReservEntry."Qty. per Unit of Measure" <> InsertReservEntry2."Qty. per Unit of Measure"))
        then
            ReservEntry.Quantity := Round(ReservEntry."Quantity (Base)" / ReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        if not QtyToHandleAndInvoiceIsSet then begin
            ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
            ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
        end;
        ReservEntry."Untracked Surplus" := InsertReservEntry."Untracked Surplus" and not ReservEntry.Positive;

        OnCreateEntryOnBeforeSurplusCondition(ReservEntry);

        if Status < Status::Surplus then begin
            InsertReservEntry2.TestField("Source Type");

            ReservEntry2 := ReservEntry;
            ReservEntry2."Quantity (Base)" := -ReservEntry."Quantity (Base)";
            ReservEntry2.Quantity :=
              Round(ReservEntry2."Quantity (Base)" / InsertReservEntry2."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            ReservEntry2."Qty. to Handle (Base)" := -ReservEntry."Qty. to Handle (Base)";
            ReservEntry2."Qty. to Invoice (Base)" := -ReservEntry."Qty. to Invoice (Base)";
            ReservEntry2.Positive := (ReservEntry2."Quantity (Base)" > 0);
            ReservEntry2."Source Type" := InsertReservEntry2."Source Type";
            ReservEntry2."Source Subtype" := InsertReservEntry2."Source Subtype";
            ReservEntry2."Source ID" := InsertReservEntry2."Source ID";
            ReservEntry2."Source Batch Name" := InsertReservEntry2."Source Batch Name";
            ReservEntry2."Source Prod. Order Line" := InsertReservEntry2."Source Prod. Order Line";
            ReservEntry2."Source Ref. No." := InsertReservEntry2."Source Ref. No.";
            ReservEntry2.CopyTrackingFromreservEntry(InsertReservEntry2);
            ReservEntry2."Qty. per Unit of Measure" := InsertReservEntry2."Qty. per Unit of Measure";
            ReservEntry2."Untracked Surplus" := InsertReservEntry2."Untracked Surplus" and not ReservEntry2.Positive;

            OnAfterCopyFromInsertReservEntry(InsertReservEntry2, ReservEntry2, ReservEntry);

            if not QtyToHandleAndInvoiceIsSet then begin
                ReservEntry2."Qty. to Handle (Base)" := ReservEntry2."Quantity (Base)";
                ReservEntry2."Qty. to Invoice (Base)" := ReservEntry2."Quantity (Base)";
            end;

            ReservEntry2.ClearApplFromToItemEntry;

            if Status = Status::Reservation then
                if TransferredFromEntryNo = 0 then begin
                    ReservMgt.MakeRoomForReservation(ReservEntry2);
                    TrackingSpecificationExists :=
                      ReservMgt.CollectTrackingSpecification(TempTrkgSpec2);
                end;
            CheckValidity(ReservEntry2);
            AdjustDateIfItemLedgerEntry(ReservEntry2);
        end;

        ReservEntry.ClearApplFromToItemEntry;

        CheckValidity(ReservEntry);
        AdjustDateIfItemLedgerEntry(ReservEntry);
        if Status = Status::Reservation then
            if TransferredFromEntryNo = 0 then begin
                ReservMgt.MakeRoomForReservation(ReservEntry);
                TrackingSpecificationExists := TrackingSpecificationExists or
                  ReservMgt.CollectTrackingSpecification(TempTrkgSpec1);
            end;

        if TrackingSpecificationExists then
            SetupSplitReservEntry(ReservEntry, ReservEntry2);

        OnCreateEntryOnBeforeOnBeforeSplitReservEntry(ReservEntry, ReservEntry2);

        FirstSplit := true;
        while SplitReservEntry(ReservEntry, ReservEntry2, TrackingSpecificationExists, FirstSplit) do begin
            ReservEntry."Entry No." := 0;
            ReservEntry.UpdateItemTracking;
            OnBeforeReservEntryInsert(ReservEntry);
            ReservEntry.Insert();
            OnAfterReservEntryInsert(ReservEntry);
            if Status < Status::Surplus then begin
                ReservEntry2."Entry No." := ReservEntry."Entry No.";
                OnBeforeReservEntryUpdateItemTracking(ReservEntry, ReservEntry2);
                ReservEntry2.UpdateItemTracking();
                OnBeforeReservEntryInsertNonSurplus(ReservEntry2);
                ReservEntry2.Insert();
                OnAfterReservEntryInsertNonSurplus(ReservEntry2, ReservEntry);
            end;
        end;

        LastReservEntry := ReservEntry;

        Clear(InsertReservEntry);
        Clear(InsertReservEntry2);
        Clear(QtyToHandleAndInvoiceIsSet);
    end;

    procedure CreateReservEntry(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Description: Text[100]; ExpectedReceiptDate: Date; ShipmentDate: Date)
    begin
        CreateEntry(ItemNo, VariantCode, LocationCode, Description, ExpectedReceiptDate, ShipmentDate, 0, 0);
    end;

    procedure CreateReservEntry(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Description: Text[100]; ExpectedReceiptDate: Date; ShipmentDate: Date; TransferedFromEntryNo: Integer)
    begin
        CreateEntry(ItemNo, VariantCode, LocationCode, Description, ExpectedReceiptDate, ShipmentDate, TransferedFromEntryNo, 0);
    end;

    procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        Sign: Integer;
    begin
        InsertReservEntry.SetSource(ForType, ForSubtype, ForID, ForRefNo, ForBatchName, ForProdOrderLine);
        Sign := SignFactor(InsertReservEntry);
        InsertReservEntry.Quantity := Sign * Quantity;
        InsertReservEntry."Quantity (Base)" := Sign * QuantityBase;
        InsertReservEntry."Qty. per Unit of Measure" := ForQtyPerUOM;
        InsertReservEntry.CopyTrackingFromreservEntry(ForReservEntry);

        InsertReservEntry.TestField("Qty. per Unit of Measure");
    end;

    [Obsolete('Replaced by CreateReservEntryFor(ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry)', '16.0')]
    procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntryFor(ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;

    procedure CreateReservEntryFrom(FromTrackingSpecification: Record "Tracking Specification")
    begin
        InsertReservEntry2.Init();
        InsertReservEntry2.SetSource(
            FromTrackingSpecification."Source Type",
            FromTrackingSpecification."Source Subtype",
            FromTrackingSpecification."Source ID",
            FromTrackingSpecification."Source Ref. No.",
            FromTrackingSpecification."Source Batch Name",
            FromTrackingSpecification."Source Prod. Order Line");
        InsertReservEntry2."Qty. per Unit of Measure" := FromTrackingSpecification."Qty. per Unit of Measure";
        InsertReservEntry2.CopyTrackingFromSpec(FromTrackingSpecification);

        InsertReservEntry2.TestField("Qty. per Unit of Measure");
    end;

    [Obsolete('Replaced by CreateReservEntryFrom(FromTrackingSpecification: Record "Tracking Specification")', '16.0')]
    procedure CreateReservEntryFrom(FromType: Option; FromSubtype: Integer; FromID: Code[20]; FromBatchName: Code[10]; FromProdOrderLine: Integer; FromRefNo: Integer; FromQtyPerUOM: Decimal; FromSerialNo: Code[50]; FromLotNo: Code[50])
    begin
        InsertReservEntry2.Init();
        InsertReservEntry2.SetSource(FromType, FromSubtype, FromID, FromRefNo, FromBatchName, FromProdOrderLine);
        InsertReservEntry2."Qty. per Unit of Measure" := FromQtyPerUOM;
        InsertReservEntry2."Serial No." := FromSerialNo;
        InsertReservEntry2."Lot No." := FromLotNo;

        InsertReservEntry2.TestField("Qty. per Unit of Measure");
    end;

    procedure CreateReservEntryExtraFields(var OldTrackingSpecification: Record "Tracking Specification"; var NewTrackingSpecification: Record "Tracking Specification")
    begin
        OnCreateReservEntryExtraFields(InsertReservEntry, OldTrackingSpecification, NewTrackingSpecification);
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        InsertReservEntry.Binding := Binding;
        InsertReservEntry2.Binding := Binding;
    end;

    procedure SetPlanningFlexibility(Flexibility: Option Unlimited,"None")
    begin
        InsertReservEntry."Planning Flexibility" := Flexibility;
        InsertReservEntry2."Planning Flexibility" := Flexibility;
    end;

    procedure SetDates(WarrantyDate: Date; ExpirationDate: Date)
    begin
        InsertReservEntry."Warranty Date" := WarrantyDate;
        InsertReservEntry."Expiration Date" := ExpirationDate;
    end;

    procedure SetQtyToHandleAndInvoice(QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal)
    begin
        InsertReservEntry."Qty. to Handle (Base)" := QtyToHandleBase;
        InsertReservEntry."Qty. to Invoice (Base)" := QtyToInvoiceBase;
        QtyToHandleAndInvoiceIsSet := true;
    end;

    procedure SetNewSerialLotNo(NewSerialNo: Code[50]; NewLotNo: Code[50])
    begin
        InsertReservEntry."New Serial No." := NewSerialNo;
        InsertReservEntry."New Lot No." := NewLotNo;
    end;

    procedure SetNewTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        InsertReservEntry."New Serial No." := ItemJnlLine."Serial No.";
        InsertReservEntry."New Lot No." := ItemJnlLine."Lot No.";
    end;

    procedure SetNewTrackingFromNewWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        InsertReservEntry."New Serial No." := WhseItemTrackingLine."New Serial No.";
        InsertReservEntry."New Lot No." := WhseItemTrackingLine."New Lot No.";
    end;

    procedure SetNewExpirationDate(NewExpirationDate: Date)
    begin
        InsertReservEntry."New Expiration Date" := NewExpirationDate;
    end;

    procedure SetDisallowCancellation(NewDisallowCancellation: Boolean)
    begin
        InsertReservEntry."Disallow Cancellation" := NewDisallowCancellation;
    end;

    procedure CreateRemainingReservEntry(var OldReservEntry: Record "Reservation Entry"; RemainingQuantity: Decimal; RemainingQuantityBase: Decimal)
    var
        OldReservEntry2: Record "Reservation Entry";
        FromTracingSpecification: Record "Tracking Specification";
    begin
        CreateReservEntryFor(
          OldReservEntry."Source Type", OldReservEntry."Source Subtype",
          OldReservEntry."Source ID", OldReservEntry."Source Batch Name",
          OldReservEntry."Source Prod. Order Line", OldReservEntry."Source Ref. No.",
          OldReservEntry."Qty. per Unit of Measure", RemainingQuantity, RemainingQuantityBase,
          OldReservEntry);
        InsertReservEntry."Warranty Date" := OldReservEntry."Warranty Date";
        InsertReservEntry."Expiration Date" := OldReservEntry."Expiration Date";
        OnBeforeCreateRemainingReservEntry(InsertReservEntry, OldReservEntry);

        if OldReservEntry."Reservation Status" < OldReservEntry."Reservation Status"::Surplus then
            if OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then begin // Get the related entry
                FromTracingSpecification.SetSourceFromReservEntry((OldReservEntry2));
                FromTracingSpecification."Qty. per Unit of Measure" := OldReservEntry2."Qty. per Unit of Measure";
                FromTracingSpecification.CopyTrackingFromReservEntry(OldReservEntry2);
                CreateReservEntryFrom(FromTracingSpecification);
                InsertReservEntry2."Warranty Date" := OldReservEntry2."Warranty Date";
                InsertReservEntry2."Expiration Date" := OldReservEntry2."Expiration Date";
                OnBeforeCreateRemainingNonSurplusReservEntry(InsertReservEntry2, OldReservEntry2);
            end;

        CreateEntry(
          OldReservEntry."Item No.", OldReservEntry."Variant Code",
          OldReservEntry."Location Code", OldReservEntry.Description,
          OldReservEntry."Expected Receipt Date", OldReservEntry."Shipment Date",
          OldReservEntry."Entry No.", OldReservEntry."Reservation Status");
    end;

    procedure TransferReservEntry(NewType: Option; NewSubtype: Integer; NewID: Code[20]; NewBatchName: Code[10]; NewProdOrderLine: Integer; NewRefNo: Integer; QtyPerUOM: Decimal; OldReservEntry: Record "Reservation Entry"; TransferQty: Decimal): Decimal
    var
        NewReservEntry: Record "Reservation Entry";
        ReservEntry: Record "Reservation Entry";
        Location: Record Location;
        CarriedItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrkgMgt: Codeunit "Item Tracking Management";
        CurrSignFactor: Integer;
        xTransferQty: Decimal;
        QtyToHandleThisLine: Decimal;
        QtyToInvoiceThisLine: Decimal;
        QtyInvoiced: Decimal;
        UseQtyToHandle: Boolean;
    begin
        if TransferQty = 0 then
            exit;

        UseQtyToHandle := OldReservEntry.TrackingExists and not OverruleItemTracking;

        CurrSignFactor := SignFactor(OldReservEntry);
        TransferQty := TransferQty * CurrSignFactor;
        xTransferQty := TransferQty;

        if UseQtyToHandle then begin // Used when handling Item Tracking
            QtyToHandleThisLine := OldReservEntry."Qty. to Handle (Base)";
            QtyToInvoiceThisLine := OldReservEntry."Qty. to Invoice (Base)";
            if Abs(TransferQty) > Abs(QtyToHandleThisLine) then
                TransferQty := QtyToHandleThisLine;
            if UseQtyToInvoice then begin // Used when posting sales and purchase
                if Abs(TransferQty) > Abs(QtyToInvoiceThisLine) then
                    TransferQty := QtyToInvoiceThisLine;
            end;
        end else
            QtyToHandleThisLine := OldReservEntry."Quantity (Base)";

        if QtyToHandleThisLine = 0 then
            exit(xTransferQty * CurrSignFactor);

        NewReservEntry.TransferFields(OldReservEntry, false);

        NewReservEntry."Entry No." := OldReservEntry."Entry No.";
        NewReservEntry.Positive := OldReservEntry.Positive;
        NewReservEntry.SetSource(NewType, NewSubtype, NewID, NewRefNo, NewBatchName, NewProdOrderLine);
        NewReservEntry."Qty. per Unit of Measure" := QtyPerUOM;

        // Item Tracking on consumption, output and drop shipment:
        if (NewType = DATABASE::"Item Journal Line") and (NewSubtype in [3, 5, 6]) or OverruleItemTracking then
            if InsertReservEntry.NewTrackingExists then begin
                NewReservEntry.CopyTrackingFromReservEntryNewTracking(InsertReservEntry);
                if NewReservEntry."Qty. to Handle (Base)" = 0 then
                    NewReservEntry."Qty. to Handle (Base)" := NewReservEntry."Quantity (Base)";
                InsertReservEntry.ClearNewTracking();

                // If an order-to-order supply is being posted, item tracking must be carried to the related demand:
                if (TransferQty >= 0) and (NewReservEntry.Binding = NewReservEntry.Binding::"Order-to-Order") then begin
                    CarriedItemTrackingSetup.CopyTrackingFromReservEntry(NewReservEntry);
                    if not UseQtyToHandle then
                        // the IT is set only in Consumption/Output Journal and we need to update all fields properly
                        QtyToInvoiceThisLine := NewReservEntry."Quantity (Base)";
                end;
                OnTransferReservEntryOnNewItemTracking(NewReservEntry, InsertReservEntry, TransferQty);
            end;

        if InsertReservEntry."Item Ledger Entry No." <> 0 then begin
            NewReservEntry."Item Ledger Entry No." := InsertReservEntry."Item Ledger Entry No.";
            InsertReservEntry."Item Ledger Entry No." := 0;
        end;

        if NewReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then
            if NewReservEntry."Quantity (Base)" > 0 then
                NewReservEntry."Expected Receipt Date" := 0D
            else
                NewReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);

        NewReservEntry.UpdateItemTracking;

        if (TransferQty >= 0) <> OldReservEntry.Positive then begin // If sign has swapped due to negative posting
                                                                    // Create a new but unchanged version of the original reserventry:
            SetQtyToHandleAndInvoice(QtyToHandleThisLine, QtyToInvoiceThisLine);
            CreateRemainingReservEntry(OldReservEntry,
              OldReservEntry.Quantity * CurrSignFactor,
              OldReservEntry."Quantity (Base)" * CurrSignFactor);
            NewReservEntry.Validate("Quantity (Base)", TransferQty);
            // Correct primary key - swap "Positive":
            NewReservEntry.Positive := not NewReservEntry.Positive;

            if not ReservEntry.Get(NewReservEntry."Entry No.", NewReservEntry.Positive) then begin
                // Means that only one record exists = surplus or prospect
                NewReservEntry.Insert();
                OnTransferReservEntryOnAfterNewReservEntryInsert(NewReservEntry);
                // Delete the original record:
                NewReservEntry.Positive := not NewReservEntry.Positive;
                NewReservEntry.Delete();
            end else begin // A set of records exist = reservation or tracking
                NewReservEntry.Modify();
                // Get the original record and modify quantity:
                NewReservEntry.Get(NewReservEntry."Entry No.", not NewReservEntry.Positive); // Get partner-record
                NewReservEntry.Validate("Quantity (Base)", -TransferQty);
                NewReservEntry.Modify();
            end;
        end else
            if Abs(TransferQty) < Abs(OldReservEntry."Quantity (Base)") then begin
                OnBeforeUseOldReservEntry(OldReservEntry, InsertReservEntry);
                if OldReservEntry.Binding = OldReservEntry.Binding::"Order-to-Order" then
                    SetBinding(OldReservEntry.Binding::"Order-to-Order");
                if OldReservEntry."Disallow Cancellation" then
                    SetDisallowCancellation(OldReservEntry."Disallow Cancellation");
                if Abs(QtyToInvoiceThisLine) > Abs(TransferQty) then
                    QtyInvoiced := TransferQty
                else
                    QtyInvoiced := QtyToInvoiceThisLine;
                SetQtyToHandleAndInvoice(QtyToHandleThisLine - TransferQty, QtyToInvoiceThisLine - QtyInvoiced);
                CreateRemainingReservEntry(OldReservEntry,
                  0, (OldReservEntry."Quantity (Base)" - TransferQty) * CurrSignFactor);
                NewReservEntry.Validate("Quantity (Base)", TransferQty);
                NewReservEntry.Modify();
                if NewReservEntry.Get(NewReservEntry."Entry No.", not NewReservEntry.Positive) then begin // Get partner-record
                    NewReservEntry.Validate("Quantity (Base)", -TransferQty);
                    NewReservEntry.Modify();
                end;
            end else begin
                NewReservEntry.Modify();
                TransferQty := NewReservEntry."Quantity (Base)";
                if NewReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then begin
                    if NewReservEntry.Get(NewReservEntry."Entry No.", not NewReservEntry.Positive) then begin // Get partner-record
                        if NewReservEntry."Quantity (Base)" < 0 then
                            NewReservEntry."Expected Receipt Date" := 0D
                        else
                            NewReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
                        NewReservEntry.Modify();
                    end;

                    // If necessary create Whse. Item Tracking Lines
                    if (NewReservEntry."Source Type" = DATABASE::"Sales Line") and
                       (OldReservEntry."Source Type" = DATABASE::"Item Journal Line") and
                       (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation)
                    then begin
                        if ItemTrkgMgt.GetWhseItemTrkgSetup(OldReservEntry."Item No.") and
                            Location.RequireShipment(OldReservEntry."Location Code")
                        then
                            CreateWhseItemTrkgLines(NewReservEntry);
                    end;
                end else
                    if CarriedItemTrackingSetup.TrackingExists() then
                        if NewReservEntry.Get(NewReservEntry."Entry No.", not NewReservEntry.Positive) then; // Get partner-record
            end;

        if CarriedItemTrackingSetup.TrackingExists() then begin
            if NewReservEntry."Qty. to Handle (Base)" = 0 then
                NewReservEntry.Validate("Quantity (Base)");
            NewReservEntry.CopyTrackingFromItemTrackingSetup(CarriedItemTrackingSetup);
            OnTransferReservEntryOnBeforeUpdateItemTracking(NewReservEntry);
            NewReservEntry.UpdateItemTracking;
            if NewReservEntry.Modify then;
        end;

        SynchronizeTransferOutboundToInboundItemTracking(NewReservEntry."Entry No.");


        OnAfterTransferReservEntry(NewReservEntry, OldReservEntry);
        xTransferQty -= TransferQty;
        exit(xTransferQty * CurrSignFactor);
    end;

    procedure SignFactor(var ReservEntry: Record "Reservation Entry"): Integer
    var
        Sign: Integer;
    begin
        // Demand is regarded as negative, supply is regarded as positive.
        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                if ReservEntry."Source Subtype" in [3, 5] then // Credit memo, Return Order = supply
                    Sign := 1
                else
                    Sign := -1;
            DATABASE::"Requisition Line":
                if ReservEntry."Source Subtype" = 1 then
                    Sign := -1
                else
                    Sign := 1;
            DATABASE::"Purchase Line":
                if ReservEntry."Source Subtype" in [3, 5] then // Credit memo, Return Order = demand
                    Sign := -1
                else
                    Sign := 1;
            DATABASE::"Item Journal Line":
                if (ReservEntry."Source Subtype" = 4) and Inbound then
                    Sign := 1
                else
                    if ReservEntry."Source Subtype" in [1, 3, 4, 5] then // Sale, Negative Adjmt., Transfer, Consumption
                        Sign := -1
                    else
                        Sign := 1;
            DATABASE::"Job Journal Line":
                Sign := -1;
            DATABASE::"Item Ledger Entry":
                Sign := 1;
            DATABASE::"Prod. Order Line":
                Sign := 1;
            DATABASE::"Prod. Order Component":
                Sign := -1;
            DATABASE::"Assembly Header":
                Sign := 1;
            DATABASE::"Assembly Line":
                Sign := -1;
            DATABASE::"Planning Component":
                Sign := -1;
            DATABASE::"Transfer Line":
                if ReservEntry."Source Subtype" = 0 then // Outbound
                    Sign := -1
                else
                    Sign := 1;
            DATABASE::"Service Line":
                if ReservEntry."Source Subtype" in [3] then // Credit memo
                    Sign := 1
                else
                    Sign := -1;
            DATABASE::"Job Planning Line":
                Sign := -1;
            DATABASE::"Phys. Invt. Order Line":
                begin
                    if ReservEntry.Positive then
                        Sign := 1
                    else
                        Sign := -1;
                end;
        end;

        OnAfterSignFactor(ReservEntry, Sign);
        exit(Sign);
    end;

    local procedure CheckValidity(var ReservEntry: Record "Reservation Entry")
    var
        IsError: Boolean;
    begin
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Reservation then
            exit;

        case ReservEntry."Source Type" of
            DATABASE::"Sales Line":
                IsError := not (ReservEntry."Source Subtype" in [1, 5]);
            DATABASE::"Purchase Line":
                IsError := not (ReservEntry."Source Subtype" in [1, 5]);
            DATABASE::"Prod. Order Line",
          DATABASE::"Prod. Order Component":
                IsError := (ReservEntry."Source Subtype" = 4) or
                  ((ReservEntry."Source Subtype" = 1) and (ReservEntry.Binding = ReservEntry.Binding::" "));
            DATABASE::"Assembly Header",
          DATABASE::"Assembly Line":
                IsError := not (ReservEntry."Source Subtype" = 1); // Only Assembly Order supported
            DATABASE::"Requisition Line",
          DATABASE::"Planning Component":
                IsError := ReservEntry.Binding = ReservEntry.Binding::" ";
            DATABASE::"Item Journal Line":
                // Item Journal Lines with Entry Type Transfer can carry reservations during posting:
                IsError := (ReservEntry."Source Subtype" <> 4) and
                  (ReservEntry."Source Ref. No." <> 0);
            DATABASE::"Job Journal Line":
                IsError := ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order";
            DATABASE::"Job Planning Line":
                IsError := ReservEntry."Source Subtype" <> 2;
            else
                OnAfterCheckValidity(ReservEntry, IsError);
        end;

        if IsError then
            Error(Text000);
    end;

    procedure GetLastEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry := LastReservEntry;
    end;

    local procedure AdjustDateIfItemLedgerEntry(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then
            if ReservEntry."Quantity (Base)" > 0 then
                ReservEntry."Expected Receipt Date" := 0D
            else
                ReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
    end;

    local procedure SetupSplitReservEntry(var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry")
    var
        NonReleasedQty: Decimal;
    begin
        // Preparing the looping through Item Tracking.

        // Ensure that the full quantity is represented in the list of Tracking Specifications:
        NonReleasedQty := ReservEntry."Quantity (Base)";
        if TempTrkgSpec1.FindSet then
            repeat
                NonReleasedQty -= TempTrkgSpec1."Quantity (Base)";
            until TempTrkgSpec1.Next = 0;

        if NonReleasedQty <> 0 then begin
            TempTrkgSpec1.Init();
            TempTrkgSpec1.TransferFields(ReservEntry);
            TempTrkgSpec1.Validate("Quantity (Base)", NonReleasedQty);
            if (TempTrkgSpec1."Source Type" <> DATABASE::"Item Ledger Entry") and
               (ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Reservation)
            then
                TempTrkgSpec1.ClearTracking;
            TempTrkgSpec1.Insert();
        end;

        if not (ReservEntry."Reservation Status" < ReservEntry."Reservation Status"::Surplus) then
            exit;

        NonReleasedQty := ReservEntry2."Quantity (Base)";
        if TempTrkgSpec2.FindSet then
            repeat
                NonReleasedQty -= TempTrkgSpec2."Quantity (Base)";
            until TempTrkgSpec2.Next = 0;

        if NonReleasedQty <> 0 then begin
            TempTrkgSpec2.Init();
            TempTrkgSpec2.TransferFields(ReservEntry2);
            TempTrkgSpec2.Validate("Quantity (Base)", NonReleasedQty);
            if (TempTrkgSpec2."Source Type" <> DATABASE::"Item Ledger Entry") and
               (ReservEntry2."Reservation Status" <> ReservEntry2."Reservation Status"::Reservation)
            then
                TempTrkgSpec2.ClearTracking;
            TempTrkgSpec2.Insert();
        end;

        BalanceLists;
    end;

    local procedure BalanceLists()
    var
        TempTrkgSpec3: Record "Tracking Specification" temporary;
        TempTrkgSpec4: Record "Tracking Specification" temporary;
        LastEntryNo: Integer;
        NextState: Option SetFilter1,SetFilter2,LoosenFilter1,LoosenFilter2,Split,Error,Finish;
    begin
        TempTrkgSpec1.Reset();
        TempTrkgSpec2.Reset();
        TempTrkgSpec1.SetCurrentKey("Lot No.", "Serial No.");
        TempTrkgSpec2.SetCurrentKey("Lot No.", "Serial No.");

        if not TempTrkgSpec1.FindLast then
            exit;

        repeat
            case NextState of
                NextState::SetFilter1:
                    begin
                        TempTrkgSpec1.SetTrackingFilterFromSpec(TempTrkgSpec2);
                        if TempTrkgSpec1.FindLast then
                            NextState := NextState::Split
                        else
                            NextState := NextState::LoosenFilter1;
                    end;
                NextState::LoosenFilter1:
                    begin
                        if TempTrkgSpec2."Quantity (Base)" > 0 then
                            TempTrkgSpec1.SetTrackingFilterBlank
                        else begin
                            if TempTrkgSpec2."Serial No." = '' then
                                TempTrkgSpec1.SetRange("Serial No.");
                            if TempTrkgSpec2."Lot No." = '' then
                                TempTrkgSpec1.SetRange("Lot No.");
                        end;
                        if TempTrkgSpec1.FindLast then
                            NextState := NextState::Split
                        else
                            NextState := NextState::Error;
                    end;
                NextState::SetFilter2:
                    begin
                        TempTrkgSpec2.SetTrackingFilterFromSpec(TempTrkgSpec1);
                        if TempTrkgSpec2.FindLast then
                            NextState := NextState::Split
                        else
                            NextState := NextState::LoosenFilter2;
                    end;
                NextState::LoosenFilter2:
                    begin
                        if TempTrkgSpec1."Quantity (Base)" > 0 then
                            TempTrkgSpec2.SetTrackingFilterBlank
                        else begin
                            if TempTrkgSpec1."Serial No." = '' then
                                TempTrkgSpec2.SetRange("Serial No.");
                            if TempTrkgSpec1."Lot No." = '' then
                                TempTrkgSpec2.SetRange("Lot No.");
                        end;
                        if TempTrkgSpec2.FindLast then
                            NextState := NextState::Split
                        else
                            NextState := NextState::Error;
                    end;
                NextState::Split:
                    begin
                        TempTrkgSpec3 := TempTrkgSpec1;
                        TempTrkgSpec4 := TempTrkgSpec2;
                        if Abs(TempTrkgSpec1."Quantity (Base)") = Abs(TempTrkgSpec2."Quantity (Base)") then begin
                            TempTrkgSpec1.Delete();
                            TempTrkgSpec2.Delete();
                            TempTrkgSpec1.ClearTrackingFilter;
                            if TempTrkgSpec1.FindLast then
                                NextState := NextState::SetFilter2
                            else begin
                                TempTrkgSpec2.Reset();
                                if TempTrkgSpec2.FindLast then
                                    NextState := NextState::Error
                                else
                                    NextState := NextState::Finish;
                            end;
                        end else
                            if Abs(TempTrkgSpec1."Quantity (Base)") < Abs(TempTrkgSpec2."Quantity (Base)") then begin
                                TempTrkgSpec2.Validate("Quantity (Base)", TempTrkgSpec2."Quantity (Base)" +
                                  TempTrkgSpec1."Quantity (Base)");
                                TempTrkgSpec4.Validate("Quantity (Base)", -TempTrkgSpec1."Quantity (Base)");
                                TempTrkgSpec1.Delete();
                                TempTrkgSpec2.Modify();
                                NextState := NextState::SetFilter1;
                            end else begin
                                TempTrkgSpec1.Validate("Quantity (Base)", TempTrkgSpec1."Quantity (Base)" +
                                  TempTrkgSpec2."Quantity (Base)");
                                TempTrkgSpec3.Validate("Quantity (Base)", -TempTrkgSpec2."Quantity (Base)");
                                TempTrkgSpec2.Delete();
                                TempTrkgSpec1.Modify();
                                NextState := NextState::SetFilter2;
                            end;
                        TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                        TempTrkgSpec4."Entry No." := LastEntryNo + 1;
                        TempTrkgSpec3.Insert();
                        TempTrkgSpec4.Insert();
                        LastEntryNo := TempTrkgSpec3."Entry No.";
                    end;
                NextState::Error:
                    Error(Text001);
            end;
        until NextState = NextState::Finish;

        TempTrkgSpec1.Reset();
        TempTrkgSpec2.Reset();
        TempTrkgSpec3.Reset();
        TempTrkgSpec4.Reset();

        if TempTrkgSpec3.FindSet then
            repeat
                TempTrkgSpec1 := TempTrkgSpec3;
                TempTrkgSpec1.Insert();
            until TempTrkgSpec3.Next = 0;

        if TempTrkgSpec4.FindSet then
            repeat
                TempTrkgSpec2 := TempTrkgSpec4;
                TempTrkgSpec2.Insert();
            until TempTrkgSpec4.Next = 0;
    end;

    local procedure SplitReservEntry(var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry"; TrackingSpecificationExists: Boolean; var FirstSplit: Boolean): Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
        OldReservEntryQty: Decimal;
    begin
        if not TrackingSpecificationExists then
            if not FirstSplit then
                exit(false)
            else begin
                FirstSplit := false;
                exit(true);
            end;

        SalesSetup.Get();
        TempTrkgSpec1.Reset();
        if not TempTrkgSpec1.FindFirst then
            exit(false);

        OnBeforeSplitReservEntry(TempTrkgSpec1, ReservEntry);

        ReservEntry.CopyTrackingFromSpec(TempTrkgSpec1);
        OldReservEntryQty := ReservEntry.Quantity;
        ReservEntry.Validate("Quantity (Base)", TempTrkgSpec1."Quantity (Base)");
        if Abs(ReservEntry.Quantity - OldReservEntryQty) <= UOMMgt.QtyRndPrecision then
            ReservEntry.Quantity := OldReservEntryQty;
        TempTrkgSpec1.Delete();

        if ReservEntry."Reservation Status" < ReservEntry."Reservation Status"::Surplus then begin
            TempTrkgSpec2.Get(TempTrkgSpec1."Entry No.");
            OnBeforeSplitNonSurplusReservEntry(TempTrkgSpec2, ReservEntry);

            ReservEntry2.CopyTrackingFromSpec(TempTrkgSpec2);
            OldReservEntryQty := ReservEntry2.Quantity;
            ReservEntry2.Validate("Quantity (Base)", TempTrkgSpec2."Quantity (Base)");
            if Abs(ReservEntry2.Quantity - OldReservEntryQty) <= UOMMgt.QtyRndPrecision then
                ReservEntry2.Quantity := OldReservEntryQty;
            if ReservEntry2.Positive and SalesSetup."Exact Cost Reversing Mandatory" then
                ReservEntry2."Appl.-from Item Entry" := TempTrkgSpec2."Appl.-from Item Entry";
            TempTrkgSpec2.Delete();
        end;

        exit(true);
    end;

    local procedure CreateWhseItemTrkgLines(ReservEntry: Record "Reservation Entry")
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ItemTrkgMgt: Codeunit "Item Tracking Management";
    begin
        with WhseShipmentLine do begin
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            SetRange("Source Type", ReservEntry."Source Type");
            SetRange("Source Subtype", ReservEntry."Source Subtype");
            SetRange("Source No.", ReservEntry."Source ID");
            SetRange("Source Line No.", ReservEntry."Source Ref. No.");
            if FindFirst then
                if not ItemTrkgMgt.WhseItemTrkgLineExists("No.", DATABASE::"Warehouse Shipment Line", 0, '', 0,
                     "Source Line No.", "Location Code", ReservEntry."Serial No.", ReservEntry."Lot No.")
                then begin
                    ItemTrkgMgt.InitWhseWkshLine(WhseWkshLine,
                      2, "No.", "Line No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);
                    ItemTrkgMgt.CreateWhseItemTrkgForResEntry(ReservEntry, WhseWkshLine);
                end;
        end;
    end;

    procedure SetItemLedgEntryNo(EntryNo: Integer)
    begin
        InsertReservEntry."Item Ledger Entry No." := EntryNo;
    end;

    procedure SetApplyToEntryNo(EntryNo: Integer)
    begin
        InsertReservEntry."Appl.-to Item Entry" := EntryNo;
    end;

    procedure SetApplyFromEntryNo(EntryNo: Integer)
    begin
        InsertReservEntry."Appl.-from Item Entry" := EntryNo;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    procedure SetInbound(NewInbound: Boolean)
    begin
        Inbound := NewInbound;
    end;

    procedure SetUseQtyToInvoice(UseQtyToInvoice2: Boolean)
    begin
        UseQtyToInvoice := UseQtyToInvoice2;
    end;

    [Scope('OnPrem')]
    procedure SetUntrackedSurplus(OrderTracking: Boolean)
    begin
        InsertReservEntry."Untracked Surplus" := OrderTracking;
        InsertReservEntry2."Untracked Surplus" := OrderTracking;
    end;

    procedure UpdateItemTrackingAfterPosting(var ReservEntry: Record "Reservation Entry")
    var
        CurrSourceRefNo: Integer;
        ReachedEndOfResvEntries: Boolean;
    begin
        if not ReservEntry.FindSet(true) then
            exit;

        repeat
            CurrSourceRefNo := ReservEntry."Source Ref. No.";

            repeat
                ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
                ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
                ReservEntry.Modify();
                if ReservEntry.Next = 0 then
                    ReachedEndOfResvEntries := true;
            until ReachedEndOfResvEntries or (ReservEntry."Source Ref. No." <> CurrSourceRefNo);

        // iterate over each set of Source Ref No.
        until ReservEntry."Source Ref. No." = CurrSourceRefNo;
    end;

    local procedure SynchronizeTransferOutboundToInboundItemTracking(ReservationEntryNo: Integer)
    var
        FromReservationEntry: Record "Reservation Entry";
        ToReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if FromReservationEntry.Get(ReservationEntryNo, false) then
            if (FromReservationEntry."Source Type" = DATABASE::"Transfer Line") and
               (FromReservationEntry."Source Subtype" = 0) and
               FromReservationEntry.TrackingExists and
               NeedSynchronizeItemTrackingToOutboundTransfer(FromReservationEntry)
            then begin
                ToReservationEntry := FromReservationEntry;
                ToReservationEntry."Source Subtype" := 1;
                ItemTrackingManagement.SynchronizeItemTrackingByPtrs(FromReservationEntry, ToReservationEntry);
            end;
    end;

    local procedure NeedSynchronizeItemTrackingToOutboundTransfer(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CurrSourceID: Text;
    begin
        with ReservationEntry do
            CurrSourceID :=
              ItemTrackingMgt.ComposeRowID(
                "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");

        if LastProcessedSourceID = CurrSourceID then
            exit(false);

        LastProcessedSourceID := CurrSourceID;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckValidity(ReservEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromInsertReservEntry(var InsertReservEntry: Record "Reservation Entry"; var ReservEntry: Record "Reservation Entry"; FromReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservEntryInsert(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservEntryInsertNonSurplus(var ReservationEntry2: Record "Reservation Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSignFactor(ReservationEntry: Record "Reservation Entry"; var Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferReservEntry(NewReservEntry: Record "Reservation Entry"; OldReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRemainingReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRemainingNonSurplusReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservEntryInsert(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservEntryInsertNonSurplus(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservEntryUpdateItemTracking(var ReservationEntry: Record "Reservation Entry"; var ReservationEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitNonSurplusReservEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitReservEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUseOldReservEntry(var ReservEntry: Record "Reservation Entry"; var InsertReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntryOnBeforeOnBeforeSplitReservEntry(var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntryOnBeforeSurplusCondition(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntryExtraFields(var InsertReservEntry: Record "Reservation Entry"; OldTrackingSpecification: Record "Tracking Specification"; NewTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReservEntryOnBeforeUpdateItemTracking(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReservEntryOnAfterNewReservEntryInsert(var NewReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReservEntryOnNewItemTracking(var NewReservEntry: Record "Reservation Entry"; var InsertReservEntry: Record "Reservation Entry"; TransferQty: Decimal)
    begin
    end;
}

