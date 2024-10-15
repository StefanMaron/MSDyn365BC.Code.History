namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;

codeunit 99000834 "Purch. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        Blocked: Boolean;
        ApplySpecificItemTracking: Boolean;
        OverruleItemTracking: Boolean;
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text001Err: Label 'must be filled in when a quantity is reserved';
        Text002Err: Label 'must not be filled in when a quantity is reserved';
        Text003Err: Label 'must not be changed when a quantity is reserved';
        Text004Err: Label 'Codeunit is not initialized correctly.';
        SummaryTypeTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(var PurchaseLine: Record "Purchase Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004Err);

        OnBeforeCreateReservation(PurchaseLine);
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.");
        PurchaseLine.TestField("Expected Receipt Date");
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        if Abs(PurchaseLine."Outstanding Qty. (Base)") < Abs(PurchaseLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000Err,
              Abs(PurchaseLine."Outstanding Qty. (Base)") - Abs(PurchaseLine."Reserved Qty. (Base)"));

        PurchaseLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        PurchaseLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then
            SignFactor := -1
        else
            SignFactor := 1;

        if QuantityBase * SignFactor < 0 then
            ShipmentDate := PurchaseLine."Expected Receipt Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := PurchaseLine."Expected Receipt Date";
        end;

        if PurchaseLine."Planning Flexibility" <> PurchaseLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(PurchaseLine."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(PurchaseLine, Quantity, QuantityBase, ForReservationEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
                PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", PurchaseLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(PurchaseLine);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure ReservQuantity(PurchaseLine: Record "Purchase Line") QtyToReserve: Decimal
    begin
        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Quote,
          PurchaseLine."Document Type"::Order,
          PurchaseLine."Document Type"::Invoice,
          PurchaseLine."Document Type"::"Blanket Order":
                QtyToReserve := -PurchaseLine."Outstanding Qty. (Base)";
            PurchaseLine."Document Type"::"Return Order",
          PurchaseLine."Document Type"::"Credit Memo":
                QtyToReserve := PurchaseLine."Outstanding Qty. (Base)";
        end;

        OnAfterReservQuantity(PurchaseLine, QtyToReserve);
    end;

    procedure Caption(PurchaseLine: Record "Purchase Line") CaptionText: Text
    begin
        CaptionText := PurchaseLine.GetSourceCaption();
    end;

    procedure FindReservEntry(PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        PurchaseLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(PurchaseLine: Record "Purchase Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        PurchaseLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;


    procedure ReservEntryExist(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(PurchaseLine.ReservEntryExist());
    end;

    procedure VerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewPurchaseLine, OldPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if (NewPurchaseLine.Type <> NewPurchaseLine.Type::Item) and (OldPurchaseLine.Type <> OldPurchaseLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewPurchaseLine."Line No." = 0 then
            if not PurchaseLine.Get(
                 NewPurchaseLine."Document Type",
                 NewPurchaseLine."Document No.",
                 NewPurchaseLine."Line No.")
            then
                exit;

        NewPurchaseLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewPurchaseLine."Reserved Qty. (Base)" <> 0;

        if (NewPurchaseLine."Expected Receipt Date" = 0D) and (OldPurchaseLine."Expected Receipt Date" <> 0D) then
            if ShowError then
                NewPurchaseLine.FieldError("Expected Receipt Date", Text001Err)
            else
                HasError := true;

        if NewPurchaseLine."Sales Order No." <> '' then
            if ShowError then
                NewPurchaseLine.FieldError("Sales Order No.", Text002Err)
            else
                HasError := NewPurchaseLine."Sales Order No." <> OldPurchaseLine."Sales Order No.";

        if NewPurchaseLine."Sales Order Line No." <> 0 then
            if ShowError then
                NewPurchaseLine.FieldError(
                  "Sales Order Line No.", Text002Err)
            else
                HasError := NewPurchaseLine."Sales Order Line No." <> OldPurchaseLine."Sales Order Line No.";

        if NewPurchaseLine."Drop Shipment" <> OldPurchaseLine."Drop Shipment" then
            if ShowError and NewPurchaseLine."Drop Shipment" then
                NewPurchaseLine.FieldError("Drop Shipment", Text002Err)
            else
                HasError := true;

        if NewPurchaseLine."No." <> OldPurchaseLine."No." then
            if ShowError then
                NewPurchaseLine.FieldError("No.", Text003Err)
            else
                HasError := true;

        IsHandled := false;
        OnVerifyChangeOnBeforeTestVariantCode(NewPurchaseLine, OldPurchaseLine, IsHandled);
        if not IsHandled then
            if NewPurchaseLine."Variant Code" <> OldPurchaseLine."Variant Code" then
                if ShowError then
                    NewPurchaseLine.FieldError("Variant Code", Text003Err)
                else
                    HasError := true;

        if NewPurchaseLine."Location Code" <> OldPurchaseLine."Location Code" then
            if ShowError then
                NewPurchaseLine.FieldError("Location Code", Text003Err)
            else
                HasError := true;

        VerifyPurchLine(NewPurchaseLine, OldPurchaseLine, HasError);

        OnVerifyChangeOnBeforeHasError(NewPurchaseLine, OldPurchaseLine, HasError, ShowError);

        if HasError then
            if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or NewPurchaseLine.ReservEntryExist() then begin
                if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or (NewPurchaseLine.Type <> OldPurchaseLine.Type) then begin
                    ReservationManagement.SetReservSource(OldPurchaseLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewPurchaseLine);
                end else begin
                    ReservationManagement.SetReservSource(NewPurchaseLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewPurchaseLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewPurchaseLine."Expected Receipt Date" <> OldPurchaseLine."Expected Receipt Date") then begin
            AssignForPlanning(NewPurchaseLine);
            if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or
               (NewPurchaseLine."Variant Code" <> OldPurchaseLine."Variant Code") or
               (NewPurchaseLine."Location Code" <> OldPurchaseLine."Location Code")
            then
                AssignForPlanning(OldPurchaseLine);
        end;
    end;

    procedure VerifyQuantity(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if Blocked then
            exit;

        IsHandled := false;
        OnBeforeVerifyQuantity(NewPurchaseLine, IsHandled, OldPurchaseLine);
        if IsHandled then
            exit;

        if NewPurchaseLine.Type <> NewPurchaseLine.Type::Item then
            exit;
        if NewPurchaseLine."Document Type" = OldPurchaseLine."Document Type" then
            if NewPurchaseLine."Line No." = OldPurchaseLine."Line No." then
                if NewPurchaseLine."Quantity (Base)" = OldPurchaseLine."Quantity (Base)" then
                    exit;
        if NewPurchaseLine."Line No." = 0 then
            if not PurchaseLine.Get(NewPurchaseLine."Document Type", NewPurchaseLine."Document No.", NewPurchaseLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewPurchaseLine);
        if NewPurchaseLine."Qty. per Unit of Measure" <> OldPurchaseLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewPurchaseLine."Outstanding Qty. (Base)" * OldPurchaseLine."Outstanding Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewPurchaseLine."Outstanding Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewPurchaseLine."Outstanding Qty. (Base)");
        AssignForPlanning(NewPurchaseLine);
    end;

    procedure UpdatePlanningFlexibility(var PurchaseLine: Record "Purchase Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(PurchaseLine, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", PurchaseLine."Planning Flexibility");
    end;

    procedure TransferPurchLineToItemJnlLine(var PurchaseLine: Record "Purchase Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplToItemEntry: Boolean) Result: Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        NotFullyReserved: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLine(PurchaseLine, ItemJournalLine, TransferQty, CheckApplToItemEntry, Result, IsHandled);
        if IsHandled then
            exit;

        if not FindReservEntry(PurchaseLine, OldReservationEntry) then
            exit(TransferQty);

        OldReservationEntry.Lock();
        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);
        if ApplySpecificItemTracking and (ItemJournalLine."Applies-to Entry" <> 0) then
            CreateReservEntry.SetItemLedgEntryNo(ItemJournalLine."Applies-to Entry");

        if OverruleItemTracking then
            if ItemJournalLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(ItemJournalLine);
                CreateReservEntry.SetOverruleItemTracking(true);
                // Try to match against Item Tracking on the purchase order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(ItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    exit(TransferQty);
            end;

        ItemJournalLine.TestItemFields(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJournalLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        OnTransferPurchLineToItemJnlLineOnBeforeInitRecordSet(OldReservationEntry);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code");

                if CheckApplToItemEntry then begin
                    if OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation then begin
                        OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                        if OppositeReservationEntry."Source Type" <> Database::"Item Ledger Entry" then
                            NotFullyReserved := true;
                    end else
                        NotFullyReserved := true;

                    if OldReservationEntry."Item Tracking" <> OldReservationEntry."Item Tracking"::None then begin
                        OldReservationEntry.TestField("Appl.-to Item Entry");
                        CreateReservEntry.SetApplyToEntryNo(OldReservationEntry."Appl.-to Item Entry");
                        CheckApplToItemEntry := false;
                    end;
                end;

                TransferPurchLineToItemJnlLineReservEntry(PurchaseLine, ItemJournalLine, OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := CheckApplToItemEntry and NotFullyReserved;
        end;
        exit(TransferQty);
    end;

    local procedure TransferPurchLineToItemJnlLineReservEntry(PurchaseLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal);
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLineReservEntry(OldReservationEntry, PurchaseLine, ItemJournalLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                Database::"Item Journal Line",
                ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
    end;

    procedure TransferPurchLineToPurchLine(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if not FindReservEntry(OldPurchaseLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewPurchaseLine.TestItemFields(OldPurchaseLine."No.", OldPurchaseLine."Variant Code", OldPurchaseLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            OnTransferPurchLineToPurchLineOnAfterOldReservEntrySetFilters(OldPurchaseLine, NewPurchaseLine);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldPurchaseLine."No.", OldPurchaseLine."Variant Code", OldPurchaseLine."Location Code");

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(
                            Database::"Purchase Line",
                            NewPurchaseLine."Document Type".AsInteger(), NewPurchaseLine."Document No.", '', 0, NewPurchaseLine."Line No.",
                            NewPurchaseLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end; // DO
    end;

    procedure DeleteLineConfirm(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if not PurchaseLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(PurchaseLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

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

        ReservationManagement.SetReservSource(PurchaseLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        DeleteInvoiceSpecFromLine(PurchaseLine);
        ReservationManagement.ClearActionMessageReferences();
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(PurchaseLine);
    end;

    local procedure AssignForPlanning(var PurchaseLine: Record "Purchase Line")
    var
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignForPlanning(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit;
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if PurchaseLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code", WorkDate());
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
                ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Combined Ship/Rcpt");
            ShouldProcessDropShipment := PurchaseLine."Drop Shipment";
            OnCallItemTrackingOnAfterCalcShouldProcessDropShipment(PurchaseLine, ShouldProcessDropShipment, ItemTrackingLines);
            if ShouldProcessDropShipment then begin
                ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Drop Shipment");
                if PurchaseLine."Sales Order No." <> '' then
                    ItemTrackingLines.SetSecondSourceRowID(
                        ItemTrackingManagement.ComposeRowID(
                            Database::"Sales Line", 1, PurchaseLine."Sales Order No.", '', 0, PurchaseLine."Sales Order Line No."));
            end;
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchaseLine."Expected Receipt Date");
            ItemTrackingLines.SetInbound(PurchaseLine.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchaseLine, ItemTrackingLines);
            RunItemTrackingLinesPage(ItemTrackingLines);
        end;
    end;

    procedure CallItemTracking(var PurchaseLine: Record "Purchase Line"; SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromPurchLine(PurchaseLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchaseLine."Expected Receipt Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchaseLine, ItemTrackingLines);
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

    procedure RetrieveInvoiceSpecification(var PurchaseLine: Record "Purchase Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification(PurchaseLine, IsHandled, OK, TempInvoicingTrackingSpecification);
        if IsHandled then
            exit;

        Clear(TempInvoicingTrackingSpecification);
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice) and
            (PurchaseLine."Receipt No." <> '')) or
           ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and
            (PurchaseLine."Return Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(PurchaseLine, TempInvoicingTrackingSpecification)
        else begin
            SourceTrackingSpecification.InitFromPurchLine(PurchaseLine);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecification(SourceTrackingSpecification, TempInvoicingTrackingSpecification);
        end;
    end;

    procedure RetrieveInvoiceSpecification2(var PurchaseLine: Record "Purchase Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification2(PurchaseLine, IsHandled);
        if IsHandled then
            exit;
        // Used for combined receipt/return:
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if not FindReservEntry(PurchaseLine, ReservationEntry) then
            exit;
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
            ReservationEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservationEntry."Item Ledger Entry No.");
            TempInvoicingTrackingSpecification := TrackingSpecification;
            TempInvoicingTrackingSpecification."Qty. to Invoice (Base)" := ReservationEntry."Qty. to Invoice (Base)";
            TempInvoicingTrackingSpecification."Qty. to Invoice" :=
              Round(ReservationEntry."Qty. to Invoice (Base)" / ReservationEntry."Qty. per Unit of Measure", UnitOfMeasureManagement.QtyRndPrecision());
            TempInvoicingTrackingSpecification."Buffer Status" := TempInvoicingTrackingSpecification."Buffer Status"::MODIFY;
            OnRetrieveInvoiceSpecification2OnBeforeInsert(TempInvoicingTrackingSpecification, ReservationEntry);
            TempInvoicingTrackingSpecification.Insert();
            ReservationEntry.Delete();
        until ReservationEntry.Next() = 0;

        OK := TempInvoicingTrackingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(PurchaseHeader: Record "Purchase Header")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
    end;

    procedure DeleteInvoiceSpecFromLine(PurchaseLine: Record "Purchase Line")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    procedure UpdateItemTrackingAfterPosting(PurchaseHeader: Record "Purchase Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.SetSourceFilter(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1, true);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);

        OnAfterUpdateItemTrackingAfterPosting(PurchaseHeader);
    end;

    procedure SetApplySpecificItemTracking(ApplySpecific: Boolean)
    begin
        ApplySpecificItemTracking := ApplySpecific;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    local procedure VerifyPurchLine(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var HasError: Boolean)
    begin
        if (NewPurchaseLine.Type = NewPurchaseLine.Type::Item) and (OldPurchaseLine.Type = OldPurchaseLine.Type::Item) then
            if (NewPurchaseLine."Bin Code" <> OldPurchaseLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewPurchaseLine."No.", NewPurchaseLine."Bin Code",
                  NewPurchaseLine."Location Code", NewPurchaseLine."Variant Code",
                  Database::"Purchase Line", NewPurchaseLine."Document Type".AsInteger(),
                  NewPurchaseLine."Document No.", '', 0, NewPurchaseLine."Line No."))
            then
                HasError := true;
        if NewPurchaseLine."Line No." <> OldPurchaseLine."Line No." then
            HasError := true;

        if NewPurchaseLine.Type <> OldPurchaseLine.Type then
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

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SourceRecordRef.SetTable(PurchaseLine);
        PurchaseLine.TestField("Job No.", '');
        PurchaseLine.TestField("Drop Shipment", false);
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("Expected Receipt Date");

        PurchaseLine.SetReservationEntry(ReservationEntry);

        CaptionText := PurchaseLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger() ..
                         Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Purchase Line");
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
            FilterReservEntry.SetRange("Source Type", Database::"Purchase Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Purchase Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(PurchaseLine);
            CreateReservation(PurchaseLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
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
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceType) then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", SourceSubtype);
            PurchaseLine.SetRange("Document No.", SourceID);
            PurchaseLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Purchase Lines", PurchaseLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.SetReservationFilters(ReservEntry);
            CaptionText := PurchaseLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(PurchaseLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PurchaseLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PurchaseLine."Quantity (Base)");
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

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Enum "Purchase Document Type"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        AvailabilityFilter: Text;
    begin
        if not PurchaseLine.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        PurchaseLine.FilterLinesForReservation(ReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.CalcFields("Reserved Qty. (Base)");
                OnUpdateStatisticsOnBeforeCheckSpecialOrder(PurchaseLine);
                if not PurchaseLine."Special Order" then begin
                    TempEntrySummary."Total Reserved Quantity" += PurchaseLine."Reserved Qty. (Base)";
                    TotalQuantity += PurchaseLine."Outstanding Qty. (Base)";
                end;
            until PurchaseLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (Positive = (TotalQuantity > 0)) and (DocumentType <> PurchaseLine."Document Type"::"Return Order") or
                (Positive = (TotalQuantity < 0)) and (DocumentType = PurchaseLine."Document Type"::"Return Order")
        then begin
            TempEntrySummary."Table ID" := Database::"Purchase Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, PurchaseLine.TableCaption(), PurchaseLine."Document Type"), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            if DocumentType = PurchaseLine."Document Type"::"Return Order" then
                TempEntrySummary."Total Quantity" := -TotalQuantity
            else
                TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Purchase Order".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()]
        then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Purchase Document Type".FromInteger(ReservSummEntry."Entry No." - 11), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        PurchaseLine.SetRange("Document No.", ReservationEntry."Source ID");
        PurchaseLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(PAGE::"Purchase Lines", PurchaseLine);
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
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var PurchLine: Record "Purchase Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; var Description: Text[100]; ShipmentDate: Date)
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
