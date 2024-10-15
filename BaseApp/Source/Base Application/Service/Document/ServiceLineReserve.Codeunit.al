namespace Microsoft.Service.Document;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 99000842 "Service Line-Reserve"
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
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Codeunit is not initialized correctly.';
        Text001Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text002Err: Label 'must be filled in when a quantity is reserved';
        Text003Err: Label 'must not be changed when a quantity is reserved';
        Text004Err: Label 'must not be filled in when a quantity is reserved';
        SummaryTypeTxt: Label '%1', Locked = true;

    procedure CreateReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000Err);

        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.");
        ServiceLine.TestField("Needed by Date");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ServiceLine."Outstanding Qty. (Base)") < Abs(ServiceLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text001Err,
              Abs(ServiceLine."Outstanding Qty. (Base)") - Abs(ServiceLine."Reserved Qty. (Base)"));

        ServiceLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ServiceLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase > 0 then
            ShipmentDate := ServiceLine."Needed by Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ServiceLine."Needed by Date";
        end;

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ServiceLine, Quantity, QuantityBase, ForReservationEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(),
                ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
                ServiceLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(ServiceLine);
    end;

    procedure CreateBindingReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(ServiceLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure Caption(ServiceLine: Record "Service Line") CaptionText: Text
    begin
        CaptionText := ServiceLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ServiceLine: Record "Service Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ServiceLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure ReservQuantity(ServiceLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case ServiceLine."Document Type" of
            ServiceLine."Document Type"::Quote,
            ServiceLine."Document Type"::Order,
            ServiceLine."Document Type"::Invoice:
                begin
                    QtyToReserve := ServiceLine."Outstanding Quantity";
                    QtyToReserveBase := ServiceLine."Outstanding Qty. (Base)";
                end;
            ServiceLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -ServiceLine."Outstanding Quantity";
                    QtyToReserveBase := -ServiceLine."Outstanding Qty. (Base)"
                end;
        end;

        OnAfterReservQuantity(ServiceLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure GetReservedQtyFromInventory(ServiceLine: Record "Service Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ServiceLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(ServiceHeader: Record "Service Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure VerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
        if IsHandled then
            exit;

        if (NewServiceLine.Type <> NewServiceLine.Type::Item) and (OldServiceLine.Type <> OldServiceLine.Type::Item) then
            exit;

        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;

        NewServiceLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewServiceLine."Reserved Qty. (Base)" <> 0;

        if NewServiceLine.Type <> OldServiceLine.Type then
            if ShowError then
                NewServiceLine.FieldError(Type, Text003Err)
            else
                HasError := true;

        if NewServiceLine."No." <> OldServiceLine."No." then
            if ShowError then
                NewServiceLine.FieldError("No.", Text003Err)
            else
                HasError := true;

        if (NewServiceLine."Needed by Date" = 0D) and (OldServiceLine."Needed by Date" <> 0D) then
            if ShowError then
                NewServiceLine.FieldError("Needed by Date", Text002Err)
            else
                HasError := true;

        if NewServiceLine."Variant Code" <> OldServiceLine."Variant Code" then
            if ShowError then
                NewServiceLine.FieldError("Variant Code", Text003Err)
            else
                HasError := true;

        if NewServiceLine."Location Code" <> OldServiceLine."Location Code" then
            if ShowError then
                NewServiceLine.FieldError("Location Code", Text003Err)
            else
                HasError := true;

        if (NewServiceLine.Type = NewServiceLine.Type::Item) and (OldServiceLine.Type = OldServiceLine.Type::Item) then
            if (NewServiceLine."Bin Code" <> OldServiceLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewServiceLine."No.", NewServiceLine."Bin Code",
                  NewServiceLine."Location Code", NewServiceLine."Variant Code",
                  DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(),
                  NewServiceLine."Document No.", '', 0, NewServiceLine."Line No."))
            then begin
                if ShowError then
                    NewServiceLine.FieldError("Bin Code", Text004Err);
                HasError := true;
            end;

        if NewServiceLine."Line No." <> OldServiceLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewServiceLine, OldServiceLine, HasError, ShowError);

        if HasError then
            if (NewServiceLine."No." <> OldServiceLine."No.") or NewServiceLine.ReservEntryExist() then begin
                if NewServiceLine."No." <> OldServiceLine."No." then begin
                    ReservationManagement.SetReservSource(OldServiceLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewServiceLine);
                end else begin
                    ReservationManagement.SetReservSource(NewServiceLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewServiceLine."Needed by Date" <> OldServiceLine."Needed by Date")
        then begin
            AssignForPlanning(NewServiceLine);
            if (NewServiceLine."No." <> OldServiceLine."No.") or
               (NewServiceLine."Variant Code" <> OldServiceLine."Variant Code") or
               (NewServiceLine."Location Code" <> OldServiceLine."Location Code")
            then
                AssignForPlanning(OldServiceLine);
        end;
    end;

    procedure VerifyQuantity(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if not (NewServiceLine."Document Type" in
                [NewServiceLine."Document Type"::Quote, NewServiceLine."Document Type"::Order])
        then
            if NewServiceLine."Shipment No." = '' then
                exit;

        if NewServiceLine.Type <> NewServiceLine.Type::Item then
            exit;
        if NewServiceLine."Line No." = OldServiceLine."Line No." then
            if NewServiceLine."Quantity (Base)" = OldServiceLine."Quantity (Base)" then
                exit;
        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewServiceLine);
        if NewServiceLine."Qty. per Unit of Measure" <> OldServiceLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewServiceLine."Outstanding Qty. (Base)" * OldServiceLine."Outstanding Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(false, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewServiceLine."Outstanding Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
        AssignForPlanning(NewServiceLine);
    end;

    local procedure AssignForPlanning(var ServiceLine: Record "Service Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ServiceLine."Document Type" <> ServiceLine."Document Type"::Order then
            exit;
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if ServiceLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine."Needed by Date");
    end;

    procedure DeleteLineConfirm(var ServiceLine: Record "Service Line"): Boolean
    begin
        if not ServiceLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(ServiceLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ServiceLine: Record "Service Line")
    begin
        ReservationManagement.SetReservSource(ServiceLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        DeleteInvoiceSpecFromLine(ServiceLine);
        ServiceLine.CalcFields("Reserved Qty. (Base)");
    end;

    procedure CallItemTracking(var ServiceLine: Record "Service Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromServLine(ServiceLine, false);
        if ((ServiceLine."Document Type" = ServiceLine."Document Type"::Invoice) and
            (ServiceLine."Shipment No." <> ''))
        then
            ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Combined Ship/Rcpt");
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ServiceLine."Needed by Date");
        ItemTrackingLines.SetInbound(ServiceLine.IsInbound());
        OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ServiceLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure TransServLineToServLine(var OldServiceLine: Record "Service Line"; var NewServiceLine: Record "Service Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldServiceLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewServiceLine.TestItemFields(OldServiceLine."No.", OldServiceLine."Variant Code", OldServiceLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldServiceLine."No.", OldServiceLine."Variant Code", OldServiceLine."Location Code");

                    IsHandled := false;
                    OnTransServLineToServLineOnBeforeCreateReservEntry(OldReservationEntry, OldServiceLine, TransferQty, IsHandled);
                    if not IsHandled then
                        TransferQty :=
                            CreateReservEntry.TransferReservEntry(DATABASE::"Service Line",
                                NewServiceLine."Document Type".AsInteger(), NewServiceLine."Document No.", '', 0,
                                NewServiceLine."Line No.", NewServiceLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    procedure RetrieveInvoiceSpecification(var ServiceLine: Record "Service Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    var
        SourceTrackingSpecification: Record "Tracking Specification";
    begin
        Clear(TempTrackingSpecification);
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if ((ServiceLine."Document Type" = ServiceLine."Document Type"::Invoice) and
            (ServiceLine."Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(ServiceLine, TempTrackingSpecification)
        else begin
            SourceTrackingSpecification.InitFromServLine(ServiceLine, Consume);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecWithService(SourceTrackingSpecification, TempTrackingSpecification, Consume);
        end;
    end;

    local procedure RetrieveInvoiceSpecification2(var ServiceLine: Record "Service Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for combined shipment:
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if not FindReservEntry(ServiceLine, ReservationEntry) then
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
            TempInvoicingTrackingSpecification.Insert();
            ReservationEntry.Delete();
        until ReservationEntry.Next() = 0;

        OK := TempInvoicingTrackingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(ServiceHeader: Record "Service Header")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(ServiceLine: Record "Service Line")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.");
    end;

    procedure TransServLineToItemJnlLine(var ServiceLine: Record "Service Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean) Result: Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransServLineToItemJnlLine(ServiceLine, ItemJournalLine, TransferQty, CheckApplFromItemEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FindReservEntry(ServiceLine, OldReservationEntry) then
            exit(TransferQty);

        OldReservationEntry.Lock();

        ItemJournalLine.TestItemFields(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJournalLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservationEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservationEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure UpdateItemTrackingAfterPosting(ServiceHeader: Record "Service Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.SetSourceFilter(DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", -1, true);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure BindToPurchase(ServiceLine: Record "Service Line"; PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line",
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ServiceLine: Record "Service Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(ServiceLine: Record "Service Line"; TransferLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(ServiceLine: Record "Service Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(ServiceLine: Record "Service Line"; AssemblyHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.Find();
            if ServiceLine.UpdatePlanned() then begin
                ServiceLine.Modify(true);
                Commit();
            end;
            QtyPerUOM := ServiceLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: record "Reservation Entry"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        SourceRecordRef.SetTable(ServiceLine);
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("Needed by Date");

        ServiceLine.SetReservationEntry(ReservationEntry);

        CaptionText := ServiceLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Service Order".AsInteger() - 1);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = Enum::"Reservation Summary Type"::"Service Order".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = DATABASE::"Service Line");
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
        AvailableServiceLines: page "Available - Service Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableServiceLines);
            AvailableServiceLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableServiceLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableServiceLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Service Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Service Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ServiceLine);
            CreateReservation(ServiceLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        if MatchThisTable(SourceType) then begin
            ServiceHeader.Reset();
            ServiceHeader.SetRange("Document Type", SourceSubtype);
            ServiceHeader.SetRange("No.", SourceID);
            if SourceSubtype = 0 then
                PAGE.RunModal(PAGE::"Service Quote", ServiceHeader)
            else
                PAGE.RunModal(PAGE::"Service Order", ServiceHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceType) then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubtype);
            ServiceLine.SetRange("Document No.", SourceID);
            ServiceLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, ServiceLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.SetReservationFilters(ReservEntry);
            CaptionText := ServiceLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ServiceLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ServiceLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ServiceLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ServiceLine: Record "Service Line";
        AvailabilityFilter: Text;
    begin
        if not ServiceLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ServiceLine.FindLinesForReservation(CalcReservationEntry, AvailabilityFilter, Positive);
        if ServiceLine.FindSet() then
            repeat
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= ServiceLine."Reserved Qty. (Base)";
                TotalQuantity += ServiceLine."Outstanding Qty. (Base)";
            until ServiceLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := DATABASE::"Service Line";
            TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(SummaryTypeTxt, ServiceLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." = 110 then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        ServiceLine.SetRange("Document No.", ReservationEntry."Source ID");
        ServiceLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Service Line List", ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransServLineToItemJnlLine(var ServLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewServiceLine: Record "Service Line"; OldServiceLine: Record "Service Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ServiceLine: Record "Service Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(ServiceLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransServLineToServLineOnBeforeCreateReservEntry(OldReservationEntry: Record "Reservation Entry"; OldServiceLine: Record "Service Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ServiceLine: Record "Service Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var ServiceLine: Record "Service Line")
    begin
    end;
}
