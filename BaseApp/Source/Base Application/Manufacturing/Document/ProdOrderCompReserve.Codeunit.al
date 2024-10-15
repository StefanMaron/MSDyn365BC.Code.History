namespace Microsoft.Manufacturing.Document;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;

codeunit 99000838 "Prod. Order Comp.-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

        Text000: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';

    procedure CreateReservation(ProdOrderComponent: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        ProdOrderComponent.TestField("Item No.");
        ProdOrderComponent.TestField("Due Date");
        ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderComponent."Remaining Qty. (Base)") < Abs(ProdOrderComponent."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderComponent."Remaining Qty. (Base)") - Abs(ProdOrderComponent."Reserved Qty. (Base)"));

        ProdOrderComponent.TestField("Location Code", FromTrackingSpecification."Location Code");
        ProdOrderComponent.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        if QuantityBase > 0 then
            ShipmentDate := ProdOrderComponent."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderComponent."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
            Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(),
            ProdOrderComponent."Prod. Order No.", '', ProdOrderComponent."Prod. Order Line No.",
            ProdOrderComponent."Line No.", ProdOrderComponent."Qty. per Unit of Measure",
            Quantity, QuantityBase, ForReservationEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
            ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(ProdOrderComponent: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(ProdOrderComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure Caption(ProdOrderComponent: Record "Prod. Order Component") CaptionText: Text
    begin
        CaptionText := ProdOrderComponent.GetSourceCaption();
    end;

    procedure FindReservEntry(ProdOrderComponent: Record "Prod. Order Component"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        if not ReservationEntry.IsEmpty() then
            exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ProdOrderComponent.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(ProductionOrder: Record "Production Order"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(
          Database::"Prod. Order Component", ProductionOrder.Status.AsInteger(), ProductionOrder."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure ReservEntryExist(ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEngineMgt.InitFilterAndSortingLookupFor(ReservationEntry, false);
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        exit(not ReservationEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderComponent.Status = NewProdOrderComponent.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderComponent."Line No." = 0 then
            if not ProdOrderComponent.Get(
                 NewProdOrderComponent.Status,
                 NewProdOrderComponent."Prod. Order No.",
                 NewProdOrderComponent."Prod. Order Line No.",
                 NewProdOrderComponent."Line No.")
            then
                exit;

        NewProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderComponent."Reserved Qty. (Base)" <> 0;

        if NewProdOrderComponent."Due Date" = 0D then
            if ShowError then
                NewProdOrderComponent.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No." then
            if ShowError then
                NewProdOrderComponent.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code" then
            if ShowError then
                NewProdOrderComponent.FieldError("Location Code", Text003)
            else
                HasError := true;
        if (NewProdOrderComponent."Bin Code" <> OldProdOrderComponent."Bin Code") and
           (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
              NewProdOrderComponent."Item No.", NewProdOrderComponent."Bin Code",
              NewProdOrderComponent."Location Code", NewProdOrderComponent."Variant Code",
              Database::"Prod. Order Component", NewProdOrderComponent.Status.AsInteger(),
              NewProdOrderComponent."Prod. Order No.", '', NewProdOrderComponent."Prod. Order Line No.",
              NewProdOrderComponent."Line No."))
        then begin
            if ShowError then
                NewProdOrderComponent.FieldError("Bin Code", Text003);
            HasError := true;
        end;
        if NewProdOrderComponent."Variant Code" <> OldProdOrderComponent."Variant Code" then
            if ShowError then
                NewProdOrderComponent.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderComponent."Line No." <> OldProdOrderComponent."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderComponent, OldProdOrderComponent, HasError, ShowError);

        if HasError then
            if (NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No.") or NewProdOrderComponent.ReservEntryExist() then begin
                if NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No." then begin
                    ReservationManagement.SetReservSource(OldProdOrderComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewProdOrderComponent);
                end else begin
                    ReservationManagement.SetReservSource(NewProdOrderComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewProdOrderComponent."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderComponent."Due Date" <> OldProdOrderComponent."Due Date") then begin
            AssignForPlanning(NewProdOrderComponent);
            if (NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No.") or
               (NewProdOrderComponent."Variant Code" <> OldProdOrderComponent."Variant Code") or
               (NewProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code")
            then
                AssignForPlanning(OldProdOrderComponent);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewProdOrderComponent, OldProdOrderComponent, ReservationManagement, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewProdOrderComponent.Status = NewProdOrderComponent.Status::Finished then
            exit;
        if NewProdOrderComponent."Line No." = OldProdOrderComponent."Line No." then
            if NewProdOrderComponent."Remaining Qty. (Base)" = OldProdOrderComponent."Remaining Qty. (Base)" then
                exit;
        if NewProdOrderComponent."Line No." = 0 then
            if not ProdOrderComponent.Get(NewProdOrderComponent.Status, NewProdOrderComponent."Prod. Order No.", NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewProdOrderComponent);
        if NewProdOrderComponent."Qty. per Unit of Measure" <> OldProdOrderComponent."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewProdOrderComponent."Remaining Qty. (Base)" * OldProdOrderComponent."Remaining Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewProdOrderComponent."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewProdOrderComponent."Remaining Qty. (Base)");
        AssignForPlanning(NewProdOrderComponent);
    end;

    procedure TransferPOCompToPOComp(var OldProdOrderComponent: Record "Prod. Order Component"; var NewProdOrderComponent: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOCompToPOComp(OldProdOrderComponent, NewProdOrderComponent);

        if not FindReservEntry(OldProdOrderComponent, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewProdOrderComponent.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code",
            TransferAll, TransferQty, NewProdOrderComponent."Qty. per Unit of Measure",
            Database::"Prod. Order Component", NewProdOrderComponent.Status.AsInteger(), NewProdOrderComponent."Prod. Order No.", '',
            NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.");
    end;

    procedure TransferPOCompToItemJnlLine(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal)
    begin
        TransferPOCompToItemJnlLineCheckILE(OldProdOrderComponent, NewItemJournalLine, TransferQty, false);
    end;

    procedure TransferPOCompToItemJnlLineCheckILE(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(OldProdOrderComponent, OldReservationEntry) then
            exit;

        OnBeforeTransferPOCompToItemJnlLineCheckILE(OldProdOrderComponent, NewItemJournalLine);

        if CheckApplFromItemEntry then
            if OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive) then
                if OppositeReservationEntry."Source Type" <> Database::"Item Ledger Entry" then
                    exit;

        // Store initial values
        OldReservationEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservationEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservationEntry.Lock();

        // Handle Item Tracking on consumption:
        Clear(CreateReservEntry);
        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Consumption then
            if NewItemJournalLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);
                // Try to match against Item Tracking on the prod. order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJournalLine.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

        OnTransferPOCompToItemJnlLineCheckILEOnBeforeCheckTransferQty(OldProdOrderComponent, NewItemJournalLine, OldReservationEntry, TransferQty, TrackedQty);

        if TransferQty = 0 then
            exit;

        ItemTrackingSetup.CopyTrackingFromItemJnlLine(NewItemJournalLine);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry, ItemTrackingSetup) then
            repeat
                OldReservationEntry.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

                OnTransferPOCompToItemJnlLineCheckILEOnBeforeTransferReservEntry(NewItemJournalLine, OldReservationEntry);

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    NewItemJournalLine."Entry Type".AsInteger(), NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", 0,
                    NewItemJournalLine."Line No.", NewItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                OnTransferPOCompToItemJnlLineCheckILEOnAfterTransferReservEntry(NewItemJournalLine, OldReservationEntry);

                EndLoop := TransferQty = 0;
                if not EndLoop then
                    if ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0 then
                        if ItemTrackingFilterIsSet then begin
                            OldReservationEntry.ClearTrackingFilter();
                            ItemTrackingFilterIsSet := false;
                            EndLoop := not ReservationEngineMgt.InitRecordSet(OldReservationEntry);
                        end else
                            EndLoop := true;
            until EndLoop;

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := OldProdOrderComponent."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservationManagement.SetReservSource(OldProdOrderComponent);
                ReservationManagement.DeleteReservEntries(false, OldProdOrderComponent."Remaining Qty. (Base)");
            end;
        end;
    end;

    procedure DeleteLineConfirm(var ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit(true);

        ReservationManagement.SetReservSource(ProdOrderComponent);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        if Blocked then
            exit;

        Clear(ReservationManagement);
        ReservationManagement.SetReservSource(ProdOrderComponent);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1);
        // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        OnDeleteLineOnAfterDeleteReservEntries(ProdOrderComponent);
        ProdOrderComponent.CalcFields(ProdOrderComponent."Reserved Qty. (Base)");
        AssignForPlanning(ProdOrderComponent);
    end;

    local procedure AssignForPlanning(var ProdOrderComponent: Record "Prod. Order Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ProdOrderComponent.Status = ProdOrderComponent.Status::Simulated then
            exit;
        if ProdOrderComponent."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Location Code", ProdOrderComponent."Due Date");
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderComponent: Record "Prod. Order Component")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if ProdOrderComponent.Status = ProdOrderComponent.Status::Finished then
            ItemTrackingDocManagement.ShowItemTrackingForProdOrderComp(Database::"Prod. Order Component",
              ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.")
        else begin
            ProdOrderComponent.TestField("Item No.");
            TrackingSpecification.InitFromProdOrderComp(ProdOrderComponent);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderComponent."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderComponent.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ProdOrderComponent, ItemTrackingLines);
            ItemTrackingLines.RunModal();
        end;

        OnAfterCallItemTracking(ProdOrderComponent);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservationEntry.SetSourceFilter(
            Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Line No.", true);
        ReservationEntry.SetSourceFilter('', ProdOrderComponent."Prod. Order Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure BindToPurchase(ProdOrderComponent: Record "Prod. Order Component"; PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ProdOrderComponent: Record "Prod. Order Component"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(ProdOrderComponent: Record "Prod. Order Component"; AssemblyHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(ProdOrderComponent: Record "Prod. Order Component"; TransferLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderComponent);
            ProdOrderComponent.Find();
            QtyPerUOM := ProdOrderComponent.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SourceRecordRef.SetTable(ProdOrderComponent);
        ProdOrderComponent.TestField("Due Date");

        ProdOrderComponent.SetReservationEntry(ReservationEntry);

        CaptionText := ProdOrderComponent.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Planned Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Prod. Order Component");
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
            AvailableProdOrderComp.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableProdOrderComp.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Prod. Order Component");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Prod. Order Component") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
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
            CaptionText := ProdOrderComp.GetSourceCaption();
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

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
        ReturnValue: Decimal;
    begin
        IsHandled := false;
        OnBeforeGetSourceValue(ReservationEntry, SourceRecordRef, ReturnOption, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);


        ProdOrderComponent.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ProdOrderComponent);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderComponent."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderComponent."Expected Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Enum "Production Order Status"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderComponent.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderComponent.FilterLinesForReservation(ReservationEntry, Status.AsInteger(), AvailabilityFilter, Positive);
        if ProdOrderComponent.FindSet() then
            repeat
                ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= ProdOrderComponent."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderComponent."Remaining Qty. (Base)";
            until ProdOrderComponent.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Prod. Order Component";
            if Status = ProdOrderComponent.Status::"Firm Planned" then
                TempEntrySummary."Summary Type" :=
                    CopyStr(StrSubstNo(Text010, ProdOrderComponent.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"))
            else
                TempEntrySummary."Summary Type" :=
                    CopyStr(StrSubstNo(Text011, ProdOrderComponent.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger()]
        then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Production Order Status".FromInteger(ReservSummEntry."Entry No." - 71), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, ReservationEntry."Source Subtype");
        ProdOrderComponent.SetRange("Prod. Order No.", ReservationEntry."Source ID");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ReservationEntry."Source Prod. Order Line");
        ProdOrderComponent.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(0, ProdOrderComponent);
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
    local procedure OnBeforeTransferPOCompToItemJnlLineCheckILE(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewProdOrderComponent: Record "Prod. Order Component"; OldProdOrderComponent: Record "Prod. Order Component"; var ReservationManagement: Codeunit "Reservation Management"; var IsHandled: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnAfterTransferReservEntry(NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnBeforeCheckTransferQty(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; var OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal; var TrackedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnBeforeTransferReservEntry(NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ProdOrderComponent: Record "Prod. Order Component"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;
}

