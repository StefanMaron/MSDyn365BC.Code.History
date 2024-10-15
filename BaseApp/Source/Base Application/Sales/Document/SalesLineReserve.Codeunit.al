namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Document;

codeunit 99000832 "Sales Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

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
        ItemTrkgAlreadyOverruled: Boolean;

        ReservedQtyTooLargeErr: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1: not reserved quantity on Sales Line';
        ValueIsEmptyErr: Label 'must be filled in when a quantity is reserved';
        ValueNotEmptyErr: Label 'must not be filled in when a quantity is reserved';
        ValueChangedErr: Label 'must not be changed when a quantity is reserved';
        CodeunitInitErr: Label 'Codeunit is not initialized correctly.';
        SummaryTypeTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(SalesLine: Record "Sales Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReservation(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if FromTrackingSpecification."Source Type" = 0 then
            Error(CodeunitInitErr);

        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.");
        SalesLine.TestField("Shipment Date");
        SalesLine.CalcFields("Reserved Qty. (Base)");

        IsHandled := false;
        OnCreateReservationOnBeforeCheckReservedQty(SalesLine, IsHandled, QuantityBase);
        if IsHandled then
            exit;

        if Abs(SalesLine."Outstanding Qty. (Base)") < Abs(SalesLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              ReservedQtyTooLargeErr,
              Abs(SalesLine."Outstanding Qty. (Base)") - Abs(SalesLine."Reserved Qty. (Base)"));

        IsHandled := false;
        OnCreateReservationOnBeforeTestVariantCode(SalesLine, FromTrackingSpecification, IsHandled);
        if not IsHandled then
            SalesLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        IsHandled := false;
        OnCreateReservationOnBeforeTestLocationCode(SalesLine, FromTrackingSpecification, IsHandled);
        if not IsHandled then
            SalesLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            SignFactor := 1
        else
            SignFactor := -1;

        if QuantityBase * SignFactor < 0 then
            ShipmentDate := SalesLine."Shipment Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := SalesLine."Shipment Date";
        end;

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(SalesLine, Quantity, QuantityBase, ForReservationEntry, IsHandled);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Sales Line", SalesLine."Document Type".AsInteger(),
                SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(SalesLine);
    end;

    procedure CreateBindingReservation(SalesLine: Record "Sales Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(SalesLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure SetDisallowCancellation(DisallowCancellation: Boolean)
    begin
        CreateReservEntry.SetDisallowCancellation(DisallowCancellation);
    end;

    procedure ReservQuantity(SalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Quote,
            SalesLine."Document Type"::Order,
            SalesLine."Document Type"::Invoice,
            SalesLine."Document Type"::"Blanket Order":
                begin
                    QtyToReserve := SalesLine."Outstanding Quantity";
                    QtyToReserveBase := SalesLine."Outstanding Qty. (Base)";
                end;
            SalesLine."Document Type"::"Return Order",
            SalesLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -SalesLine."Outstanding Quantity";
                    QtyToReserveBase := -SalesLine."Outstanding Qty. (Base)"
                end;
        end;

        OnAfterReservQuantity(SalesLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure Caption(SalesLine: Record "Sales Line") CaptionText: Text
    begin
        CaptionText := SalesLine.GetSourceCaption();
    end;

    procedure FindReservEntry(SalesLine: Record "Sales Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        SalesLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(SalesLine: Record "Sales Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        SalesLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(SalesHeader: Record "Sales Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure ReservEntryExist(SalesLine: Record "Sales Line"): Boolean
    begin
        exit(SalesLine.ReservEntryExist());
    end;

    procedure VerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewSalesLine, OldSalesLine, IsHandled);
        if IsHandled then
            exit;

        if (NewSalesLine.Type <> NewSalesLine.Type::Item) and (OldSalesLine.Type <> OldSalesLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewSalesLine."Line No." = 0 then
            if not SalesLine.Get(
                 NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.")
            then
                exit;

        NewSalesLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewSalesLine."Reserved Qty. (Base)" <> 0;

        HasError := TestSalesLineModification(OldSalesLine, NewSalesLine, ShowError);

        OnVerifyChangeOnBeforeHasError(NewSalesLine, OldSalesLine, HasError, ShowError);

        if HasError then
            ClearReservation(OldSalesLine, NewSalesLine);

        if HasError or (NewSalesLine."Shipment Date" <> OldSalesLine."Shipment Date") then begin
            AssignForPlanning(NewSalesLine);
            if (NewSalesLine."No." <> OldSalesLine."No.") or
               (NewSalesLine."Variant Code" <> OldSalesLine."Variant Code") or
               (NewSalesLine."Location Code" <> OldSalesLine."Location Code")
            then
                AssignForPlanning(OldSalesLine);
        end;
    end;

    procedure VerifyQuantity(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewSalesLine, IsHandled, OldSalesLine);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewSalesLine.Type <> NewSalesLine.Type::Item then
            exit;
        if NewSalesLine."Document Type" = OldSalesLine."Document Type" then
            if NewSalesLine."Line No." = OldSalesLine."Line No." then
                if NewSalesLine."Quantity (Base)" = OldSalesLine."Quantity (Base)" then
                    exit;
        if NewSalesLine."Line No." = 0 then
            if not SalesLine.Get(NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewSalesLine);
        DeleteSalesReservEntries(NewSalesLine, OldSalesLine);
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewSalesLine."Outstanding Qty. (Base)");
        AssignForPlanning(NewSalesLine);
    end;

    procedure SetSaleShipQty(ErrorInfo: ErrorInfo)
    var
        CurrSalesLine: Record "Sales Line";
    begin
        CurrSalesLine.Get(ErrorInfo.RecordId);
        CurrSalesLine.Validate("Qty. to Ship", CurrSalesLine."Outstanding Quantity");
        CurrSalesLine.Modify(true);
    end;

    procedure SetSalesQtyInvoice(ErrorInfo: ErrorInfo)
    var
        CurrSalesLine: Record "Sales Line";
    begin
        CurrSalesLine.Get(ErrorInfo.RecordId);
        CurrSalesLine.Validate("Qty. to Invoice", CurrSalesLine.MaxQtyToInvoice());
        CurrSalesLine.Modify(true);
    end;

    local procedure DeleteSalesReservEntries(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesReservEntries(NewSalesLine, OldSalesLine, ReservationManagement, IsHandled);
        if IsHandled then
            exit;

        if NewSalesLine."Qty. per Unit of Measure" <> OldSalesLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if (NewSalesLine."Outstanding Qty. (Base)" * OldSalesLine."Outstanding Qty. (Base)" < 0) or
            CheckQuantityReducedOnSalesLine(NewSalesLine, OldSalesLine) then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewSalesLine."Outstanding Qty. (Base)");
    end;

    procedure TransferSalesLineToItemJnlLine(var SalesLine: Record "Sales Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean; OnlyILEReservations: Boolean): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        NotFullyReserved: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferSalesLineToItemJnlLine(SalesLine, IsHandled, ItemJournalLine);
        if IsHandled then
            exit;

        if not FindReservEntry(SalesLine, OldReservationEntry) then
            exit(TransferQty);

        OldReservationEntry.LockTable(); //Lock the entry related to the sales line.
        OldReservationEntry.FindLast();

        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);

        if OverruleItemTracking then
            if ItemJournalLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(ItemJournalLine);
                CreateReservEntry.SetOverruleItemTracking(not ItemTrkgAlreadyOverruled);
                // Try to match against Item Tracking on the sales order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(ItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    exit(TransferQty);
            end;


        IsHandled := false;
        OnTransferSalesLineToItemJnlLineOnBeforeItemJournalLineTest(SalesLine, IsHandled, ItemJournalLine, TransferQty);
        if not IsHandled then
            ItemJournalLine.TestItemFields(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJournalLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        OnTransferSalesLineToItemJnlLineOnBeforeInitRecordSet(OldReservationEntry);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                IsHandled := false;
                OnTransferSalesLineToItemJnlLineOnBeforeOldReservEntryTest(SalesLine, IsHandled, ItemJournalLine);
                if not IsHandled then
                    OldReservationEntry.TestItemFields(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");

                if ApplySpecificItemTracking and (ItemJournalLine."Applies-to Entry" <> 0) then begin
                    CreateReservEntry.SetItemLedgEntryNo(ItemJournalLine."Applies-to Entry");
                    CheckApplFromItemEntry := false;
                end;

                if ItemJournalLine."Assemble to Order" then begin
                    ItemTrackingSetup.CopyTrackingFromReservEntry(OldReservationEntry);
                    OldReservationEntry."Appl.-to Item Entry" := SalesLine.FindOpenATOEntry(ItemTrackingSetup);
                end;

                if CheckApplFromItemEntry then begin
                    if OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation then begin
                        OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                        if OppositeReservationEntry."Source Type" <> Database::"Item Ledger Entry" then
                            NotFullyReserved := true;
                    end else
                        NotFullyReserved := true;

                    if OldReservationEntry."Item Tracking" <> OldReservationEntry."Item Tracking"::None then begin
                        IsHandled := false;
                        OnTransferSalesLineToItemJnlLineOnBeforeApplFromItemEntryTestField(SalesLine, OldReservationEntry, IsHandled, ItemJournalLine);
                        if not IsHandled then
                            OldReservationEntry.TestField("Appl.-from Item Entry");
                        CreateReservEntry.SetApplyFromEntryNo(OldReservationEntry."Appl.-from Item Entry");
                        CheckApplFromItemEntry := false;
                    end;
                end;

                IsHandled := false;
                OnTransferSalesLineToItemJnlLineOnBeforeTransferReservationEntry(OldReservationEntry, SalesLine, ItemJournalLine, IsHandled);
                if not IsHandled then
                    if not (ItemJournalLine."Assemble to Order" xor OldReservationEntry."Disallow Cancellation") then
                        if not VerifyPickedQtyReservToInventory(OldReservationEntry, SalesLine, TransferQty) then
                            if OnlyILEReservations and OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive) then begin
                                if OppositeReservationEntry."Source Type" = Database::"Item Ledger Entry" then
                                    TransferReservationEntry(TransferQty, ItemJournalLine, OldReservationEntry);
                            end else
                                TransferReservationEntry(TransferQty, ItemJournalLine, OldReservationEntry);
            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := CheckApplFromItemEntry and NotFullyReserved;
        end;
        exit(TransferQty);
    end;

    local procedure TransferReservationEntry(var TransferQty: Decimal; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        if ItemJournalLine.IsSourceSales() then
            TransferQty :=
                CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Document No.",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Document Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", ReservationEntry, TransferQty)
        else
            TransferQty :=
                CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", ReservationEntry, TransferQty);
    end;

    procedure TransferSaleLineToSalesLine(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservationStatus: Enum "Reservation Status";
        IsHandled: Boolean;
    begin
        // Used for sales quote and blanket order when transferred to order
        IsHandled := false;
        OnBeforeTransferSaleLineToSalesLine(OldSalesLine, NewSalesLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        if not FindReservEntry(OldSalesLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewSalesLine.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");

        for ReservationStatus := ReservationStatus::Reservation to ReservationStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservationStatus);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");
                    if (OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Prospect) and
                       (OldSalesLine."Document Type" in [OldSalesLine."Document Type"::Quote,
                                                         OldSalesLine."Document Type"::"Blanket Order"])
                    then
                        OldReservationEntry."Reservation Status" := OldReservationEntry."Reservation Status"::Surplus;

                    IsHandled := false;
                    OnTransferSaleLineToSalesLineOnBeforeCalcTransferQty(NewSalesLine, OldReservationEntry, IsHandled);
                    if not IsHandled then
                        TransferQty :=
                            CreateReservEntry.TransferReservEntry(
                                Database::"Sales Line",
                                NewSalesLine."Document Type".AsInteger(), NewSalesLine."Document No.", '', 0,
                                NewSalesLine."Line No.", NewSalesLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    procedure DeleteLineConfirm(var SalesLine: Record "Sales Line"): Boolean
    begin
        if not SalesLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(SalesLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteLine(SalesLine, IsHandled);
        if not IsHandled then begin
            ReservationManagement.SetReservSource(SalesLine);
            if DeleteItemTracking then
                ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
            ReservationManagement.DeleteReservEntries(true, 0);
            DeleteInvoiceSpecFromLine(SalesLine);
            SalesLine.CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(SalesLine);
        end;
    end;

    procedure AssignForPlanning(var SalesLine: Record "Sales Line")
    var
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignForPlanning(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if SalesLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Shipment Date");
    end;

    procedure CallItemTracking(var SalesLine: Record "Sales Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(SalesLine, IsHandled);
        if IsHandled then
            exit;

        TrackingSpecification.InitFromSalesLine(SalesLine);
        if ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
            (SalesLine."Shipment No." <> '')) or
           ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
            (SalesLine."Return Receipt No." <> ''))
        then
            ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Combined Ship/Rcpt");
        if SalesLine."Drop Shipment" then begin
            ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Drop Shipment");
            if SalesLine."Purchase Order No." <> '' then
                ItemTrackingLines.SetSecondSourceRowID(ItemTrackingManagement.ComposeRowID(
                    Database::"Purchase Line",
                    1, SalesLine."Purchase Order No.", '', 0, SalesLine."Purch. Order Line No."));
        end;
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, SalesLine."Shipment Date");
        ItemTrackingLines.SetInbound(SalesLine.IsInbound());
        OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(SalesLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure CallItemTracking(var SalesLine: Record "Sales Line"; SecondSourceQuantityArray: array[3] of Decimal)
    begin
        CallItemTrackingSecondSource(SalesLine, SecondSourceQuantityArray, false);
    end;

    procedure CallItemTrackingSecondSource(var SalesLine: Record "Sales Line"; SecondSourceQuantityArray: array[3] of Decimal; AsmToOrder: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        if SecondSourceQuantityArray[1] = Database::"Warehouse Shipment Line" then
            ItemTrackingLines.SetSecondSourceID(Database::"Warehouse Shipment Line", AsmToOrder);

        TrackingSpecification.InitFromSalesLine(SalesLine);

        IsHandled := false;
        OnCallItemTrackingSecondSourceOnBeforeOpenItemTrackingLines(SalesLine, TrackingSpecification, SecondSourceQuantityArray, IsHandled);
        if not IsHandled then begin
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, SalesLine."Shipment Date");
            ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
            OnCallItemTrackingSecondSourceOnBeforeItemTrackingLinesRun(SalesLine, ItemTrackingLines);
            ItemTrackingLines.RunModal();
        end;
    end;

    procedure RetrieveInvoiceSpecification(var SalesLine: Record "Sales Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification(SalesLine, OK, IsHandled, TempInvoicingTrackingSpecification);
        if IsHandled then
            exit;

        Clear(TempInvoicingTrackingSpecification);
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
            (SalesLine."Shipment No." <> '')) or
           ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
            (SalesLine."Return Receipt No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(SalesLine, TempInvoicingTrackingSpecification)
        else begin
            SourceTrackingSpecification.InitFromSalesLine(SalesLine);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecification(SourceTrackingSpecification, TempInvoicingTrackingSpecification);
        end;
    end;

    procedure RetrieveInvoiceSpecification2(var SalesLine: Record "Sales Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification2(SalesLine, OK, IsHandled);
        if IsHandled then
            exit;

        // Used for combined shipment/return:
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if not FindReservEntry(SalesLine, ReservationEntry) then
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
            OnRetrieveInvoiceSpecificationOnBeforeInsert(TempInvoicingTrackingSpecification, ReservationEntry);
            TempInvoicingTrackingSpecification.Insert();
            ReservationEntry.Delete();
        until ReservationEntry.Next() = 0;

        OK := TempInvoicingTrackingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteInvoiceSpecFromHeader(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteInvoiceSpecFromLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
    end;

    procedure UpdateItemTrackingAfterPosting(SalesHeader: Record "Sales Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -1, true);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure SetApplySpecificItemTracking(ApplySpecific: Boolean)
    begin
        ApplySpecificItemTracking := ApplySpecific;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure SetItemTrkgAlreadyOverruled(HasBeenOverruled: Boolean)
    begin
        ItemTrkgAlreadyOverruled := HasBeenOverruled;
    end;

    local procedure VerifyPickedQtyReservToInventory(OldReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; TransferQty: Decimal): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        NewReservationEntry: Record "Reservation Entry";
    begin
        if not WarehouseShipmentLine.ReadPermission then
            exit(false);

        WarehouseShipmentLine.SetSourceFilter(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        WarehouseShipmentLine.SetRange(Status, WarehouseShipmentLine.Status::"Partially Picked");
        exit
            (WarehouseShipmentLine.FindFirst() and NewReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive) and
            (OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation) and
            (NewReservationEntry."Source Type" <> Database::"Item Ledger Entry") and (WarehouseShipmentLine."Qty. Picked (Base)" >= TransferQty));
    end;

    procedure BindToPurchase(SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(SalesLine: Record "Sales Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBindToProdOrder(SalesLine, ProdOrderLine, ReservQty, ReservQtyBase, IsHandled);
        if IsHandled then
            exit;

        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(SalesLine: Record "Sales Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        if SalesLine.Reserve = SalesLine.Reserve::Never then
            exit;
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(SalesLine: Record "Sales Line"; TransferLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(SalesLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    local procedure CheckItemNo(var SalesLine: Record "Sales Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetFilter("Item No.", '<>%1', SalesLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        exit(ReservationEntry.IsEmpty);
    end;

    local procedure ClearReservation(OldSalesLine: Record "Sales Line"; NewSalesLine: Record "Sales Line")
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        if (NewSalesLine."No." <> OldSalesLine."No.") or FindReservEntry(NewSalesLine, DummyReservationEntry) then begin
            if (NewSalesLine."No." <> OldSalesLine."No.") or (NewSalesLine.Type <> OldSalesLine.Type) then begin
                ReservationManagement.SetReservSource(OldSalesLine);
                ReservationManagement.DeleteReservEntries(true, 0);
                ReservationManagement.SetReservSource(NewSalesLine);
            end else begin
                ReservationManagement.SetReservSource(NewSalesLine);
                ReservationManagement.DeleteReservEntries(true, 0);
            end;
            ReservationManagement.AutoTrack(NewSalesLine."Outstanding Qty. (Base)");
        end;
    end;

    local procedure TestSalesLineModification(OldSalesLine: Record "Sales Line"; NewSalesLine: Record "Sales Line"; ThrowError: Boolean) HasError: Boolean
    var
        IsHandled: Boolean;
    begin
        if (NewSalesLine."Shipment Date" = 0D) and (OldSalesLine."Shipment Date" <> 0D) then begin
            if ThrowError then
                NewSalesLine.FieldError("Shipment Date", ValueIsEmptyErr);
            HasError := true;
        end;

        OnTestSalesLineModificationOnBeforeTestJobNo(NewSalesLine, IsHandled);
        if not IsHandled then
            if NewSalesLine."Job No." <> '' then begin
                if ThrowError then
                    NewSalesLine.FieldError("Job No.", ValueNotEmptyErr);
                HasError := true;
            end;

        if NewSalesLine."Purchase Order No." <> '' then begin
            if ThrowError then
                NewSalesLine.FieldError("Purchase Order No.", ValueNotEmptyErr);
            HasError := NewSalesLine."Purchase Order No." <> OldSalesLine."Purchase Order No.";
        end;

        if NewSalesLine."Purch. Order Line No." <> 0 then begin
            if ThrowError then
                NewSalesLine.FieldError("Purch. Order Line No.", ValueNotEmptyErr);
            HasError := NewSalesLine."Purch. Order Line No." <> OldSalesLine."Purch. Order Line No.";
        end;

        if NewSalesLine."Drop Shipment" and not OldSalesLine."Drop Shipment" then begin
            if ThrowError then
                NewSalesLine.FieldError("Drop Shipment", ValueNotEmptyErr);
            HasError := true;
        end;

        if NewSalesLine."Special Order" and not OldSalesLine."Special Order" then begin
            if ThrowError then
                NewSalesLine.FieldError("Special Order", ValueNotEmptyErr);
            HasError := true;
        end;

        if (NewSalesLine."No." <> OldSalesLine."No.") and not CheckItemNo(NewSalesLine) then begin
            if ThrowError then
                NewSalesLine.FieldError("No.", ValueChangedErr);
            HasError := true;
        end;

        IsHandled := false;
        OnTestSalesLineModificationOnBeforeTestVariantCode(NewSalesLine, OldSalesLine, IsHandled, HasError, ThrowError);
        if not IsHandled then
            if NewSalesLine."Variant Code" <> OldSalesLine."Variant Code" then begin
                if ThrowError then
                    NewSalesLine.FieldError("Variant Code", ValueChangedErr);
                HasError := true;
            end;

        IsHandled := false;
        OnTestSalesLineModificationOnBeforeTestLocationCode(NewSalesLine, OldSalesLine, IsHandled, HasError);
        if not IsHandled then
            if NewSalesLine."Location Code" <> OldSalesLine."Location Code" then begin
                if ThrowError then
                    NewSalesLine.FieldError("Location Code", ValueChangedErr);
                HasError := true;
            end;

        IsHandled := false;
        OnTestSalesLineModificationOnBeforeTestBinCode(NewSalesLine, OldSalesLine, IsHandled);
        if not IsHandled then
            if (OldSalesLine.Type = OldSalesLine.Type::Item) and (NewSalesLine.Type = NewSalesLine.Type::Item) then
                if (NewSalesLine."Bin Code" <> OldSalesLine."Bin Code") and
                (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                    NewSalesLine."No.", NewSalesLine."Bin Code",
                    NewSalesLine."Location Code", NewSalesLine."Variant Code",
                    Database::"Sales Line", NewSalesLine."Document Type".AsInteger(),
                    NewSalesLine."Document No.", '', 0, NewSalesLine."Line No."))
                then begin
                    if ThrowError then
                        NewSalesLine.FieldError("Bin Code", ValueChangedErr);
                    HasError := true;
                end;

        if NewSalesLine."Line No." <> OldSalesLine."Line No." then
            HasError := true;

        if NewSalesLine.Type <> OldSalesLine.Type then
            HasError := true;
    end;

    procedure SetDeleteItemTracking(NewDeleteItemTracking: Boolean)
    begin
        DeleteItemTracking := NewDeleteItemTracking
    end;

    procedure CopyReservEntryToTemp(var TempReservationEntry: Record "Reservation Entry" temporary; OldSalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(
          Database::"Sales Line", OldSalesLine."Document Type".AsInteger(), OldSalesLine."Document No.", OldSalesLine."Line No.", true);
        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert();
            until ReservationEntry.Next() = 0;
        ReservationEntry.DeleteAll();
    end;

    procedure CopyReservEntryFromTemp(var TempReservationEntry: Record "Reservation Entry" temporary; OldSalesLine: Record "Sales Line"; NewSourceRefNo: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        TempReservationEntry.Reset();
        TempReservationEntry.SetSourceFilter(
          Database::"Sales Line", OldSalesLine."Document Type".AsInteger(), OldSalesLine."Document No.", OldSalesLine."Line No.", true);
        if TempReservationEntry.FindSet() then
            repeat
                ReservationEntry := TempReservationEntry;
                ReservationEntry."Source Ref. No." := NewSourceRefNo;
                ReservationEntry.Insert();
            until TempReservationEntry.Next() = 0;
        TempReservationEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(SalesLine);
            SalesLine.Find();
            QtyPerUOM := SalesLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SourceRecordRef.SetTable(SalesLine);
        TestSourceTableFields(SalesLine);
        SalesLine.SetReservationEntry(ReservationEntry);
        CaptionText := SalesLine.GetSourceCaption();
    end;

    local procedure TestSourceTableFields(SalesLine: Record "Sales Line")
    begin
        SalesLine.TestField("Job No.", '');
        SalesLine.TestField("Drop Shipment", false);
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("Shipment Date");

        OnAfterTestSourceTableFields(SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSourceTableFields(SalesLine: Record "Sales Line")
    begin
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Sales Quote".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Sales Quote".AsInteger() ..
                         Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Sales Line");
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
        AvailableSalesLines: page "Available - Sales Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableSalesLines);
            AvailableSalesLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableSalesLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableSalesLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Sales Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(SalesLine);
            CreateReservation(SalesLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        if MatchThisTable(SourceType) then begin
            SalesHeader.Reset();
            SalesHeader.SetRange("Document Type", SourceSubtype);
            SalesHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Sales Quote", SalesHeader);
                1:
                    PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
                2:
                    PAGE.RunModal(PAGE::"Sales Invoice", SalesHeader);
                3:
                    PAGE.RunModal(PAGE::"Sales Credit Memo", SalesHeader);
                5:
                    PAGE.RunModal(PAGE::"Sales Return Order", SalesHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        if MatchThisTable(SourceType) then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SourceSubtype);
            SalesLine.SetRange("Document No.", SourceID);
            SalesLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Sales Lines", SalesLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(SalesLine);
            SalesLine.SetReservationFilters(ReservEntry);
            CaptionText := SalesLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(SalesLine);
            SalesLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(SalesLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(SalesLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(SalesLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Enum "Sales Document Type"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        AvailabilityFilter: Text;
    begin
        if not SalesLine.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        SalesLine.FilterLinesForReservation(ReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if SalesLine.FindSet() then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= SalesLine."Reserved Qty. (Base)";
                TotalQuantity += SalesLine."Outstanding Qty. (Base)";
            until SalesLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (Positive = (TotalQuantity < 0)) and (DocumentType <> SalesLine."Document Type"::"Return Order") or
            (Positive = (TotalQuantity > 0)) and (DocumentType = SalesLine."Document Type"::"Return Order")
        then begin
            TempEntrySummary."Table ID" := DATABASE::"Sales Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, SalesLine.TableCaption(), SalesLine."Document Type"),
                1, MaxStrLen(TempEntrySummary."Summary Type"));
            if DocumentType = SalesLine."Document Type"::"Return Order" then
                TempEntrySummary."Total Quantity" := TotalQuantity
            else
                TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        SalesLine.SetRange("Document No.", ReservationEntry."Source ID");
        SalesLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(PAGE::"Sales Lines", SalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Sales Order".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger()] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Sales Document Type".FromInteger(ReservSummEntry."Entry No." - 31), Positive, TotalQuantity);
    end;

    local procedure CheckQuantityReducedOnSalesLine(NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"): Boolean
    var
        Item: Record Item;
    begin
        if (NewSalesLine.Type <> NewSalesLine.Type::Item) or (NewSalesLine.Quantity = 0) then
            exit(false);

        Item.SetLoadFields(Reserve, "Costing Method");
        Item.Get(NewSalesLine."No.");
        if (Item.Reserve <> Item.Reserve::Always) or (Item."Costing Method" <> Item."Costing Method"::FIFO) then
            exit(false);

        exit(NewSalesLine.Quantity < OldSalesLine.Quantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(SalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignForPlanning(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBindToProdOrder(SalesLine: Record "Sales Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesReservEntries(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var ReservMgt: Codeunit "Reservation Management"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification(var SalesLine: Record "Sales Line"; var OK: Boolean; var IsHandled: Boolean; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification2(var SalesLine: Record "Sales Line"; var OK: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSaleLineToSalesLine(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line"; var TransferQty: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeTestVariantCode(SalesLine: Record "Sales Line"; FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeTestLocationCode(SalesLine: Record "Sales Line"; FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLineModificationOnBeforeTestBinCode(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLineModificationOnBeforeTestJobNo(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLineModificationOnBeforeTestVariantCode(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean; var HasError: Boolean; ThrowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLineModificationOnBeforeTestLocationCode(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean; var HasError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesLineToItemJnlLineOnBeforeItemJournalLineTest(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TransferQty: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesLineToItemJnlLineOnBeforeInitRecordSet(var OldReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesLineToItemJnlLineOnBeforeOldReservEntryTest(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesLineToItemJnlLineOnBeforeTransferReservationEntry(var ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSaleLineToSalesLineOnBeforeCalcTransferQty(var NewSalesLine: Record "Sales Line"; var OldReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesLineToItemJnlLineOnBeforeApplFromItemEntryTestField(SalesLine: Record "Sales Line"; OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteInvoiceSpecFromHeader(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteInvoiceSpecFromLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewSalesLine: Record "Sales Line"; var IsHandled: Boolean; var OldSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSalesLineToItemJnlLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var SalesLine: Record "Sales Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingSecondSourceOnBeforeItemTrackingLinesRun(var SalesLine: Record "Sales Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingSecondSourceOnBeforeOpenItemTrackingLines(var SalesLine: Record "Sales Line"; TrackingSpecification: Record "Tracking Specification"; SecondSourceQuantityArray: array[3] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveInvoiceSpecificationOnBeforeInsert(var TempInvoicingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCheckReservedQty(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; QuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var SalesLine: Record "Sales Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

