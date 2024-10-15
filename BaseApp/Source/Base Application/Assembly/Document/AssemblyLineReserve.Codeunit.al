namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 926 "Assembly Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationManagement: Codeunit "Reservation Management";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - quantity';
        Text001Err: Label 'Codeunit is not initialized correctly.';
        Text002Err: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003Err: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        SummaryTypeTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservationEntry, FromTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text001Err);

        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("No.");
        AssemblyLine.TestField("Due Date");

        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyLine."Remaining Quantity (Base)") < Abs(AssemblyLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000Err,
              Abs(AssemblyLine."Remaining Quantity (Base)") - Abs(AssemblyLine."Reserved Qty. (Base)"));

        AssemblyLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        AssemblyLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase * SignFactor(AssemblyLine) < 0 then
            ShipmentDate := AssemblyLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := AssemblyLine."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(),
          AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.", AssemblyLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservationEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure SignFactor(AssemblyLine: Record "Assembly Line"): Integer
    begin
        if AssemblyLine."Document Type".AsInteger() in [2, 3, 5] then
            Error(Text001Err);

        exit(-1);
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetReservationFilters(FilterReservationEntry);
    end;

    procedure FindReservEntry(AssemblyLine: Record "Assembly Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        AssemblyLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    local procedure AssignForPlanning(var AssemblyLine: Record "Assembly Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if AssemblyLine."Document Type" <> AssemblyLine."Document Type"::Order then
            exit;

        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        if AssemblyLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code", WorkDate());
    end;

    procedure ReservEntryExist(AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(AssemblyLine.ReservEntryExist());
    end;

    procedure DeleteLine(var AssemblyLine: Record "Assembly Line")
    begin
        ReservationManagement.SetReservSource(AssemblyLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ReservationManagement.ClearActionMessageReferences();
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(AssemblyLine);
    end;

    procedure SetDeleteItemTracking(AllowDirectDeletion: Boolean)
    begin
        DeleteItemTracking := AllowDirectDeletion;
    end;

    procedure GetReservedQtyFromInventory(AssemblyLine: Record "Assembly Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        AssemblyLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(AssemblyHeader: Record "Assembly Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(DATABASE::"Assembly Line", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure VerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewAssemblyLine.Type <> NewAssemblyLine.Type::Item) and (OldAssemblyLine.Type <> OldAssemblyLine.Type::Item) then
            exit;

        if NewAssemblyLine."Line No." = 0 then
            if not AssemblyLine.Get(NewAssemblyLine."Document Type", NewAssemblyLine."Document No.", NewAssemblyLine."Line No.") then
                exit;

        NewAssemblyLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewAssemblyLine."Reserved Qty. (Base)" <> 0;

        if NewAssemblyLine."Due Date" = 0D then begin
            if ShowError then
                NewAssemblyLine.FieldError("Due Date", Text002Err);
            HasError := true;
        end;

        if NewAssemblyLine.Type <> OldAssemblyLine.Type then begin
            if ShowError then
                NewAssemblyLine.FieldError(Type, Text003Err);
            HasError := true;
        end;

        if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
            if ShowError then
                NewAssemblyLine.FieldError("No.", Text003Err);
            HasError := true;
        end;

        if NewAssemblyLine."Location Code" <> OldAssemblyLine."Location Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Location Code", Text003Err);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyLine, OldAssemblyLine, HasError, ShowError);

        if (NewAssemblyLine.Type = NewAssemblyLine.Type::Item) and (OldAssemblyLine.Type = OldAssemblyLine.Type::Item) and
           (NewAssemblyLine."Bin Code" <> OldAssemblyLine."Bin Code")
        then
            if not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                 NewAssemblyLine."No.", NewAssemblyLine."Bin Code",
                 NewAssemblyLine."Location Code", NewAssemblyLine."Variant Code",
                 Database::"Assembly Line", NewAssemblyLine."Document Type".AsInteger(),
                 NewAssemblyLine."Document No.", '', 0, NewAssemblyLine."Line No.")
            then begin
                if ShowError then
                    NewAssemblyLine.FieldError("Bin Code", Text003Err);
                HasError := true;
            end;

        if NewAssemblyLine."Variant Code" <> OldAssemblyLine."Variant Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Variant Code", Text003Err);
            HasError := true;
        end;

        if NewAssemblyLine."Line No." <> OldAssemblyLine."Line No." then
            HasError := true;

        if HasError then
            if (NewAssemblyLine."No." <> OldAssemblyLine."No.") or
               FindReservEntry(NewAssemblyLine, ReservationEntry)
            then begin
                if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
                    ReservationManagement.SetReservSource(OldAssemblyLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewAssemblyLine);
                end else begin
                    ReservationManagement.SetReservSource(NewAssemblyLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewAssemblyLine."Remaining Quantity (Base)");
            end;

        if HasError or (NewAssemblyLine."Due Date" <> OldAssemblyLine."Due Date") then begin
            AssignForPlanning(NewAssemblyLine);
            if (NewAssemblyLine."No." <> OldAssemblyLine."No.") or
               (NewAssemblyLine."Variant Code" <> OldAssemblyLine."Variant Code") or
               (NewAssemblyLine."Location Code" <> OldAssemblyLine."Location Code")
            then
                AssignForPlanning(OldAssemblyLine);
        end;
    end;

    procedure VerifyQuantity(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if NewAssemblyLine.Type <> NewAssemblyLine.Type::Item then
            exit;
        if NewAssemblyLine."Line No." = OldAssemblyLine."Line No." then
            if NewAssemblyLine."Remaining Quantity (Base)" = OldAssemblyLine."Remaining Quantity (Base)" then
                exit;
        if NewAssemblyLine."Line No." = 0 then
            if not AssemblyLine.Get(NewAssemblyLine."Document Type", NewAssemblyLine."Document No.", NewAssemblyLine."Line No.") then
                exit;

        ReservationManagement.SetReservSource(NewAssemblyLine);
        if NewAssemblyLine."Qty. per Unit of Measure" <> OldAssemblyLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewAssemblyLine."Remaining Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewAssemblyLine."Remaining Quantity (Base)");
        AssignForPlanning(NewAssemblyLine);
    end;

    procedure Caption(AssemblyLine: Record "Assembly Line") CaptionText: Text
    begin
        CaptionText := AssemblyLine.GetSourceCaption();
    end;

    procedure CallItemTracking(var AssemblyLine: Record "Assembly Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromAsmLine(AssemblyLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyLine."Due Date");
        ItemTrackingLines.SetInbound(AssemblyLine.IsInbound());
        OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(AssemblyLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure DeleteLineConfirm(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        if not AssemblyLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(AssemblyLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyLine: Record "Assembly Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.InitSortingAndFilters(false);
        ReservationEntry.SetRange("Item No.", AssemblyLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Assembly Line");
        ReservationEntry.SetRange("Source Subtype", AssemblyLine."Document Type");
        ReservationEntry.SetRange("Source ID", AssemblyLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Prod. Order Line", 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure TransferAsmLineToItemJnlLine(var AssemblyLine: Record "Assembly Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyLine, OldReservationEntry) then
            exit(TransferQty);

        ItemJournalLine.TestField("Item No.", AssemblyLine."No.");
        ItemJournalLine.TestField("Variant Code", AssemblyLine."Variant Code");
        ItemJournalLine.TestField("Location Code", AssemblyLine."Location Code");

        OldReservationEntry.Lock();

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestField("Item No.", AssemblyLine."No.");
                OldReservationEntry.TestField("Variant Code", AssemblyLine."Variant Code");
                OldReservationEntry.TestField("Location Code", AssemblyLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservationEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservationEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure TransferAsmLineToAsmLine(var OldAssemblyLine: Record "Assembly Line"; var NewAssemblyLine: Record "Assembly Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if TransferQty = 0 then
            exit;

        if not FindReservEntry(OldAssemblyLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewAssemblyLine.TestField("No.", OldAssemblyLine."No.");
        NewAssemblyLine.TestField("Variant Code", OldAssemblyLine."Variant Code");
        NewAssemblyLine.TestField("Location Code", OldAssemblyLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestField("Item No.", OldAssemblyLine."No.");
                    OldReservationEntry.TestField("Variant Code", OldAssemblyLine."Variant Code");
                    OldReservationEntry.TestField("Location Code", OldAssemblyLine."Location Code");

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(
                            Database::"Assembly Line", NewAssemblyLine."Document Type".AsInteger(), NewAssemblyLine."Document No.", '', 0,
                            NewAssemblyLine."Line No.", NewAssemblyLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    procedure BindToRequisition(AssemblyLine: Record "Assembly Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(AssemblyLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToPurchase(AssemblyLine: Record "Assembly Line"; PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AssemblyLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(AssemblyLine: Record "Assembly Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AssemblyLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AssemblyLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(AssemblyLine: Record "Assembly Line"; TransferLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AssemblyLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyLine);
            AssemblyLine.Find();
            QtyPerUOM := AssemblyLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SourceRecordRef.SetTable(AssemblyLine);
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("Due Date");

        AssemblyLine.SetReservationEntry(ReservationEntry);

        CaptionText := AssemblyLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Assembly Quote Line".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Assembly Quote Line".AsInteger(),
                         Enum::"Reservation Summary Type"::"Assembly Order Line".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Assembly Line");
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
        AvailableAssemblyLines: page "Available - Assembly Lines";
    begin
        if EntrySummary."Entry No." in [151, 152] then begin
            Clear(AvailableAssemblyLines);
            AvailableAssemblyLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableAssemblyLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableAssemblyLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Assembly Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Assembly Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(AssemblyLine);
            CreateReservation(AssemblyLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceType) then begin
            AssemblyHeader.Reset();
            AssemblyHeader.SetRange("Document Type", SourceSubtype);
            AssemblyHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    ;
                1:
                    PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                5:
                    ;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(SourceType) then begin
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document Type", SourceSubtype);
            AssemblyLine.SetRange("Document No.", SourceID);
            AssemblyLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Assembly Lines", AssemblyLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyLine);
            AssemblyLine.SetReservationFilters(ReservEntry);
            CaptionText := AssemblyLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(AssemblyLine);
            AssemblyLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(AssemblyLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(AssemblyLine."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(AssemblyLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        AvailabilityFilter: Text;
    begin
        if not AssemblyLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        AssemblyLine.FilterLinesForReservation(CalcReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if AssemblyLine.FindSet() then
            repeat
                AssemblyLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= AssemblyLine."Reserved Qty. (Base)";
                TotalQuantity += AssemblyLine."Remaining Quantity (Base)";
            until AssemblyLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if TotalQuantity < 0 = Positive then begin
            TempEntrySummary."Table ID" := Database::"Assembly Line";
            TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(SummaryTypeTxt, AssemblyLine.TableCaption(), AssemblyLine."Document Type"),
                1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [151, 152] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 151, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        AssemblyLine.SetRange("Document No.", ReservationEntry."Source ID");
        AssemblyLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Assembly Lines", AssemblyLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyLine: Record "Assembly Line"; OldAssemblyLine: Record "Assembly Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var AssemblyLine: Record "Assembly Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry"; FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;
}

