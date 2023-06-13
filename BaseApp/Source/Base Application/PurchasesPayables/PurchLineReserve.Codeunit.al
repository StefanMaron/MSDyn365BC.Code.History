codeunit 99000834 "Purch. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1';
        Text001: Label 'must be filled in when a quantity is reserved';
        Text002: Label 'must not be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Blocked: Boolean;
        ApplySpecificItemTracking: Boolean;
        OverruleItemTracking: Boolean;
        DeleteItemTracking: Boolean;

    procedure CreateReservation(var PurchLine: Record "Purchase Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        OnBeforeCreateReservation(PurchLine);
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("No.");
        PurchLine.TestField("Expected Receipt Date");
        PurchLine.CalcFields("Reserved Qty. (Base)");
        if Abs(PurchLine."Outstanding Qty. (Base)") < Abs(PurchLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(PurchLine."Outstanding Qty. (Base)") - Abs(PurchLine."Reserved Qty. (Base)"));

        PurchLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        PurchLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then
            SignFactor := -1
        else
            SignFactor := 1;

        if QuantityBase * SignFactor < 0 then
            ShipmentDate := PurchLine."Expected Receipt Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := PurchLine."Expected Receipt Date";
        end;

        if PurchLine."Planning Flexibility" <> PurchLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(PurchLine."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(PurchLine, Quantity, QuantityBase, ForReservEntry, IsHandled);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(),
                PurchLine."Document No.", '', 0, PurchLine."Line No.", PurchLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          PurchLine."No.", PurchLine."Variant Code", PurchLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(PurchLine);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure ReservQuantity(PurchLine: Record "Purchase Line") QtyToReserve: Decimal
    begin
        case PurchLine."Document Type" of
            PurchLine."Document Type"::Quote,
          PurchLine."Document Type"::Order,
          PurchLine."Document Type"::Invoice,
          PurchLine."Document Type"::"Blanket Order":
                QtyToReserve := -PurchLine."Outstanding Qty. (Base)";
            PurchLine."Document Type"::"Return Order",
          PurchLine."Document Type"::"Credit Memo":
                QtyToReserve := PurchLine."Outstanding Qty. (Base)";
        end;

        OnAfterReservQuantity(PurchLine, QtyToReserve);
    end;

    procedure Caption(PurchLine: Record "Purchase Line") CaptionText: Text
    begin
        CaptionText := PurchLine.GetSourceCaption();
    end;

    procedure FindReservEntry(PurchLine: Record "Purchase Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        PurchLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast());
    end;

    procedure ReservEntryExist(PurchLine: Record "Purchase Line"): Boolean
    begin
        exit(PurchLine.ReservEntryExist());
    end;

    procedure VerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewPurchLine, OldPurchLine, IsHandled);
        if IsHandled then
            exit;

        if (NewPurchLine.Type <> NewPurchLine.Type::Item) and (OldPurchLine.Type <> OldPurchLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewPurchLine."Line No." = 0 then
            if not PurchLine.Get(
                 NewPurchLine."Document Type",
                 NewPurchLine."Document No.",
                 NewPurchLine."Line No.")
            then
                exit;

        NewPurchLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewPurchLine."Reserved Qty. (Base)" <> 0;

        if (NewPurchLine."Expected Receipt Date" = 0D) and (OldPurchLine."Expected Receipt Date" <> 0D) then
            if ShowError then
                NewPurchLine.FieldError("Expected Receipt Date", Text001)
            else
                HasError := true;

        if NewPurchLine."Sales Order No." <> '' then
            if ShowError then
                NewPurchLine.FieldError("Sales Order No.", Text002)
            else
                HasError := NewPurchLine."Sales Order No." <> OldPurchLine."Sales Order No.";

        if NewPurchLine."Sales Order Line No." <> 0 then
            if ShowError then
                NewPurchLine.FieldError(
                  "Sales Order Line No.", Text002)
            else
                HasError := NewPurchLine."Sales Order Line No." <> OldPurchLine."Sales Order Line No.";

        if NewPurchLine."Drop Shipment" <> OldPurchLine."Drop Shipment" then
            if ShowError and NewPurchLine."Drop Shipment" then
                NewPurchLine.FieldError("Drop Shipment", Text002)
            else
                HasError := true;

        if NewPurchLine."No." <> OldPurchLine."No." then
            if ShowError then
                NewPurchLine.FieldError("No.", Text003)
            else
                HasError := true;

        IsHandled := false;
        OnVerifyChangeOnBeforeTestVariantCode(NewPurchLine, OldPurchLine, IsHandled);
        if not IsHandled then
            if NewPurchLine."Variant Code" <> OldPurchLine."Variant Code" then
                if ShowError then
                    NewPurchLine.FieldError("Variant Code", Text003)
                else
                    HasError := true;

        if NewPurchLine."Location Code" <> OldPurchLine."Location Code" then
            if ShowError then
                NewPurchLine.FieldError("Location Code", Text003)
            else
                HasError := true;

        VerifyPurchLine(NewPurchLine, OldPurchLine, HasError);

        OnVerifyChangeOnBeforeHasError(NewPurchLine, OldPurchLine, HasError, ShowError);

        if HasError then
            if (NewPurchLine."No." <> OldPurchLine."No.") or NewPurchLine.ReservEntryExist() then begin
                if (NewPurchLine."No." <> OldPurchLine."No.") or (NewPurchLine.Type <> OldPurchLine.Type) then begin
                    ReservMgt.SetReservSource(OldPurchLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewPurchLine);
                end else begin
                    ReservMgt.SetReservSource(NewPurchLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewPurchLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewPurchLine."Expected Receipt Date" <> OldPurchLine."Expected Receipt Date") then begin
            AssignForPlanning(NewPurchLine);
            if (NewPurchLine."No." <> OldPurchLine."No.") or
               (NewPurchLine."Variant Code" <> OldPurchLine."Variant Code") or
               (NewPurchLine."Location Code" <> OldPurchLine."Location Code")
            then
                AssignForPlanning(OldPurchLine);
        end;
    end;

    procedure VerifyQuantity(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if Blocked then
            exit;

        IsHandled := false;
        OnBeforeVerifyQuantity(NewPurchLine, IsHandled, OldPurchLine);
        if IsHandled then
            exit;

        with NewPurchLine do begin
            if Type <> Type::Item then
                exit;
            if "Document Type" = OldPurchLine."Document Type" then
                if "Line No." = OldPurchLine."Line No." then
                    if "Quantity (Base)" = OldPurchLine."Quantity (Base)" then
                        exit;
            if "Line No." = 0 then
                if not PurchLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewPurchLine);
            if "Qty. per Unit of Measure" <> OldPurchLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure();
            if "Outstanding Qty. (Base)" * OldPurchLine."Outstanding Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
            ReservMgt.ClearSurplus();
            ReservMgt.AutoTrack("Outstanding Qty. (Base)");
            AssignForPlanning(NewPurchLine);
        end;
    end;

    procedure UpdatePlanningFlexibility(var PurchLine: Record "Purchase Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(PurchLine, ReservEntry) then
            ReservEntry.ModifyAll("Planning Flexibility", PurchLine."Planning Flexibility");
    end;

    procedure TransferPurchLineToItemJnlLine(var PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplToItemEntry: Boolean) Result: Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        OppositeReservEntry: Record "Reservation Entry";
        NotFullyReserved: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLine(PurchLine, ItemJnlLine, TransferQty, CheckApplToItemEntry, Result, IsHandled);
        if IsHandled then
            exit;

        if not FindReservEntry(PurchLine, OldReservEntry) then
            exit(TransferQty);

        OldReservEntry.Lock();
        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);
        if ApplySpecificItemTracking and (ItemJnlLine."Applies-to Entry" <> 0) then
            CreateReservEntry.SetItemLedgEntryNo(ItemJnlLine."Applies-to Entry");

        if OverruleItemTracking then
            if ItemJnlLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(ItemJnlLine);
                CreateReservEntry.SetOverruleItemTracking(true);
                // Try to match against Item Tracking on the purchase order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
                if OldReservEntry.IsEmpty() then
                    exit(TransferQty);
            end;

        ItemJnlLine.TestItemFields(PurchLine."No.", PurchLine."Variant Code", PurchLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJnlLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        OnTransferPurchLineToItemJnlLineOnBeforeInitRecordSet(OldReservEntry);
        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(PurchLine."No.", PurchLine."Variant Code", PurchLine."Location Code");

                if CheckApplToItemEntry then begin
                    if OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation then begin
                        OppositeReservEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                        if OppositeReservEntry."Source Type" <> DATABASE::"Item Ledger Entry" then
                            NotFullyReserved := true;
                    end else
                        NotFullyReserved := true;

                    if OldReservEntry."Item Tracking" <> OldReservEntry."Item Tracking"::None then begin
                        OldReservEntry.TestField("Appl.-to Item Entry");
                        CreateReservEntry.SetApplyToEntryNo(OldReservEntry."Appl.-to Item Entry");
                        CheckApplToItemEntry := false;
                    end;
                end;

                TransferPurchLineToItemJnlLineReservEntry(PurchLine, ItemJnlLine, OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := CheckApplToItemEntry and NotFullyReserved;
        end;
        exit(TransferQty);
    end;

    local procedure TransferPurchLineToItemJnlLineReservEntry(PurchLine: Record "Purchase Line"; ItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry"; var TransferQty: Decimal);
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLineReservEntry(OldReservEntry, PurchLine, ItemJnlLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                DATABASE::"Item Journal Line",
                ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name",
                ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
    end;

    procedure TransferPurchLineToPurchLine(var OldPurchLine: Record "Purchase Line"; var NewPurchLine: Record "Purchase Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if not FindReservEntry(OldPurchLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock();

        NewPurchLine.TestItemFields(OldPurchLine."No.", OldPurchLine."Variant Code", OldPurchLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", ReservStatus);
            OnTransferPurchLineToPurchLineOnAfterOldReservEntrySetFilters(OldPurchLine, NewPurchLine);
            if OldReservEntry.FindSet() then
                repeat
                    OldReservEntry.TestItemFields(OldPurchLine."No.", OldPurchLine."Variant Code", OldPurchLine."Location Code");

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(DATABASE::"Purchase Line",
                            NewPurchLine."Document Type".AsInteger(), NewPurchLine."Document No.", '', 0, NewPurchLine."Line No.",
                            NewPurchLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next() = 0) or (TransferQty = 0);
        end; // DO
    end;

    procedure DeleteLineConfirm(var PurchLine: Record "Purchase Line"): Boolean
    begin
        with PurchLine do begin
            if not ReservEntryExist() then
                exit(true);

            ReservMgt.SetReservSource(PurchLine);
            if ReservMgt.DeleteItemTrackingConfirm() then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteLine(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        with PurchaseLine do begin
            ReservMgt.SetReservSource(PurchaseLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            DeleteInvoiceSpecFromLine(PurchaseLine);
            ReservMgt.ClearActionMessageReferences();
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(PurchaseLine);
        end;
    end;

    local procedure AssignForPlanning(var PurchLine: Record "Purchase Line")
    var
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignForPlanning(PurchLine, IsHandled);
        if IsHandled then
            exit;
        with PurchLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", WorkDate());
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var PurchaseLine: Record "Purchase Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        ShouldProcessDropShipment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(PurchaseLine, IsHandled);
        if not IsHandled then begin
            TrackingSpecification.InitFromPurchLine(PurchaseLine);
            if ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice) and
                (PurchaseLine."Receipt No." <> '')) or
            ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and
                (PurchaseLine."Return Shipment No." <> ''))
            then
                ItemTrackingLines.SetRunMode("Item Tracking Run Mode"::"Combined Ship/Rcpt");
            ShouldProcessDropShipment := PurchaseLine."Drop Shipment";
            OnCallItemTrackingOnAfterCalcShouldProcessDropShipment(PurchaseLine, ShouldProcessDropShipment, ItemTrackingLines);
            if ShouldProcessDropShipment then begin
                ItemTrackingLines.SetRunMode("Item Tracking Run Mode"::"Drop Shipment");
                if PurchaseLine."Sales Order No." <> '' then
                    ItemTrackingLines.SetSecondSourceRowID(ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Line",
                        1, PurchaseLine."Sales Order No.", '', 0, PurchaseLine."Sales Order Line No."));
            end;
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchaseLine."Expected Receipt Date");
            ItemTrackingLines.SetInbound(PurchaseLine.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchaseLine, ItemTrackingLines);
            RunItemTrackingLinesPage(ItemTrackingLines);
        end;
    end;

    procedure CallItemTracking(var PurchLine: Record "Purchase Line"; SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromPurchLine(PurchLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchLine."Expected Receipt Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchLine, ItemTrackingLines);
        RunItemTrackingLinesPage(ItemTrackingLines);
    end;

    local procedure RunItemTrackingLinesPage(var ItemTrackingLines: Page "Item Tracking Lines")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunItemTrackingLinesPage(ItemTrackingLines, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingLines.RunModal();
    end;

    procedure RetrieveInvoiceSpecification(var PurchLine: Record "Purchase Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        SourceSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification(PurchLine, IsHandled, OK, TempInvoicingSpecification);
        if IsHandled then
            exit;

        Clear(TempInvoicingSpecification);
        if PurchLine.Type <> PurchLine.Type::Item then
            exit;
        if ((PurchLine."Document Type" = PurchLine."Document Type"::Invoice) and
            (PurchLine."Receipt No." <> '')) or
           ((PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo") and
            (PurchLine."Return Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(PurchLine, TempInvoicingSpecification)
        else begin
            SourceSpecification.InitFromPurchLine(PurchLine);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecification(SourceSpecification, TempInvoicingSpecification);
        end;
    end;

    procedure RetrieveInvoiceSpecification2(var PurchLine: Record "Purchase Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification2(PurchLine, IsHandled);
        if IsHandled then
            exit;
        // Used for combined receipt/return:
        if PurchLine.Type <> PurchLine.Type::Item then
            exit;
        if not FindReservEntry(PurchLine, ReservEntry) then
            exit;
        ReservEntry.FindSet();
        repeat
            ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            ReservEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservEntry."Item Ledger Entry No.");
            TempInvoicingSpecification := TrackingSpecification;
            TempInvoicingSpecification."Qty. to Invoice (Base)" := ReservEntry."Qty. to Invoice (Base)";
            TempInvoicingSpecification."Qty. to Invoice" :=
              Round(ReservEntry."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            TempInvoicingSpecification."Buffer Status" := TempInvoicingSpecification."Buffer Status"::MODIFY;
            OnRetrieveInvoiceSpecification2OnBeforeInsert(TempInvoicingSpecification, ReservEntry);
            TempInvoicingSpecification.Insert();
            ReservEntry.Delete();
        until ReservEntry.Next() = 0;

        OK := TempInvoicingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(PurchHeader: Record "Purchase Header")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
    end;

    procedure DeleteInvoiceSpecFromLine(PurchLine: Record "Purchase Line")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
    end;

    procedure UpdateItemTrackingAfterPosting(PurchHeader: Record "Purchase Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.SetSourceFilter(DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.", -1, true);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);

        OnAfterUpdateItemTrackingAfterPosting(PurchHeader);
    end;

    procedure SetApplySpecificItemTracking(ApplySpecific: Boolean)
    begin
        ApplySpecificItemTracking := ApplySpecific;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    local procedure VerifyPurchLine(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var HasError: Boolean)
    begin
        if (NewPurchLine.Type = NewPurchLine.Type::Item) and (OldPurchLine.Type = OldPurchLine.Type::Item) then
            if (NewPurchLine."Bin Code" <> OldPurchLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewPurchLine."No.", NewPurchLine."Bin Code",
                  NewPurchLine."Location Code", NewPurchLine."Variant Code",
                  DATABASE::"Purchase Line", NewPurchLine."Document Type".AsInteger(),
                  NewPurchLine."Document No.", '', 0, NewPurchLine."Line No."))
            then
                HasError := true;
        if NewPurchLine."Line No." <> OldPurchLine."Line No." then
            HasError := true;

        if NewPurchLine.Type <> OldPurchLine.Type then
            HasError := true;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.Find();
            QtyPerUOM := PurchaseLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchLine: Record "Purchase Line";
    begin
        SourceRecRef.SetTable(PurchLine);
        PurchLine.TestField("Job No.", '');
        PurchLine.TestField("Drop Shipment", false);
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("Expected Receipt Date");

        PurchLine.SetReservationEntry(ReservEntry);

        CaptionText := PurchLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit("Reservation Summary Type"::"Purchase Quote".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in ["Reservation Summary Type"::"Purchase Quote".AsInteger() ..
                         "Reservation Summary Type"::"Purchase Return Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 39); // DATABASE::"Purchase Line"
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
        AvailablePurchaseLines: page "Available - Purchase Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailablePurchaseLines);
            AvailablePurchaseLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailablePurchaseLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailablePurchaseLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Purchase Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(PurchLine);
            CreateReservation(PurchLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PurchHeader: Record "Purchase Header";
    begin
        if MatchThisTable(SourceType) then begin
            PurchHeader.Reset();
            PurchHeader.SetRange("Document Type", SourceSubtype);
            PurchHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Purchase Quote", PurchHeader);
                1:
                    PAGE.RunModal(PAGE::"Purchase Order", PurchHeader);
                2:
                    PAGE.RunModal(PAGE::"Purchase Invoice", PurchHeader);
                3:
                    PAGE.RunModal(PAGE::"Purchase Credit Memo", PurchHeader);
                5:
                    PAGE.RunModal(PAGE::"Purchase Return Order", PurchHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceType) then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", SourceSubtype);
            PurchLine.SetRange("Document No.", SourceID);
            PurchLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Purchase Lines", PurchLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PurchLine);
            PurchLine.SetReservationFilters(ReservEntry);
            CaptionText := PurchLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(PurchLine);
            PurchLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(PurchLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PurchLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PurchLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewPurchLine: Record "Purchase Line"; OldPurchLine: Record "Purchase Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Enum "Purchase Document Type"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        PurchLine: Record "Purchase Line";
        AvailabilityFilter: Text;
    begin
        if not PurchLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        PurchLine.FilterLinesForReservation(CalcReservEntry, DocumentType, AvailabilityFilter, Positive);
        if PurchLine.FindSet() then
            repeat
                PurchLine.CalcFields("Reserved Qty. (Base)");
                OnUpdateStatisticsOnBeforeCheckSpecialOrder(PurchLine);
                if not PurchLine."Special Order" then begin
                    TempEntrySummary."Total Reserved Quantity" += PurchLine."Reserved Qty. (Base)";
                    TotalQuantity += PurchLine."Outstanding Qty. (Base)";
                end;
            until PurchLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (Positive = (TotalQuantity > 0)) and (DocumentType <> PurchLine."Document Type"::"Return Order") or
                (Positive = (TotalQuantity < 0)) and (DocumentType = PurchLine."Document Type"::"Return Order")
            then begin
                "Table ID" := DATABASE::"Purchase Line";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1, %2', PurchLine.TableCaption(), PurchLine."Document Type"),
                    1, MaxStrLen("Summary Type"));
                if DocumentType = PurchLine."Document Type"::"Return Order" then
                    "Total Quantity" := -TotalQuantity
                else
                    "Total Quantity" := TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in ["Reservation Summary Type"::"Purchase Order".AsInteger(),
                                           "Reservation Summary Type"::"Purchase Return Order".AsInteger()]
        then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, "Purchase Document Type".FromInteger(ReservSummEntry."Entry No." - 11), Positive, TotalQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemTrackingAfterPosting(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPurchLineToItemJnlLine(var PurchaseLine: Record "Purchase Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplToItemEntry: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPurchLineToItemJnlLineReservEntry(var OldReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line"; ItemJnlLine: Record "Item Journal Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunItemTrackingLinesPage(var ItemTrackingLines: Page "Item Tracking Lines"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; OldPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPurchLineToPurchLineOnAfterOldReservEntrySetFilters(var OldPurchLine: record "Purchase Line"; var NewPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPurchLineToItemJnlLineOnBeforeInitRecordSet(var OldReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeTestVariantCode(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingFormRunModal(var PurchLine: Record "Purchase Line"; var ItemTrackingForm: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveInvoiceSpecification2OnBeforeInsert(var TempInvoicingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatisticsOnBeforeCheckSpecialOrder(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignForPlanning(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var OK: Boolean; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification2(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var PurchLine: Record "Purchase Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnAfterCalcShouldProcessDropShipment(var PurchLine: Record "Purchase Line"; var ShouldProcessDropShipment: Boolean; var ItemTrackingLinesPage: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(PurchaseLine: Record "Purchase Line"; var QtyToReserve: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}
