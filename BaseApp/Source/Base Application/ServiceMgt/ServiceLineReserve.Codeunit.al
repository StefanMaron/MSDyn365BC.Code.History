codeunit 99000842 "Service Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        DeleteItemTracking: Boolean;

        Text000: Label 'Codeunit is not initialized correctly.';
        Text001: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'must not be filled in when a quantity is reserved';

    procedure CreateReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000);

        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.");
        ServiceLine.TestField("Needed by Date");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ServiceLine."Outstanding Qty. (Base)") < Abs(ServiceLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text001,
              Abs(ServiceLine."Outstanding Qty. (Base)") - Abs(ServiceLine."Reserved Qty. (Base)"));

        ServiceLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ServiceLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase > 0 then
            ShipmentDate := ServiceLine."Needed by Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ServiceLine."Needed by Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(),
          ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
          ServiceLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(ServiceLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
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

    procedure FindReservEntry(ServiceLine: Record "Service Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ServiceLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast());
    end;

    procedure ReservQuantity(ServLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case ServLine."Document Type" of
            ServLine."Document Type"::Quote,
            ServLine."Document Type"::Order,
            ServLine."Document Type"::Invoice:
                begin
                    QtyToReserve := ServLine."Outstanding Quantity";
                    QtyToReserveBase := ServLine."Outstanding Qty. (Base)";
                end;
            ServLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -ServLine."Outstanding Quantity";
                    QtyToReserveBase := -ServLine."Outstanding Qty. (Base)"
                end;
        end;
    end;

    procedure VerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewServiceLine.Type <> NewServiceLine.Type::Item) and (OldServiceLine.Type <> OldServiceLine.Type::Item) then
            exit;

        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;

        NewServiceLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewServiceLine."Reserved Qty. (Base)" <> 0;

        if NewServiceLine.Type <> OldServiceLine.Type then
            if ShowError then
                NewServiceLine.FieldError(Type, Text003)
            else
                HasError := true;

        if NewServiceLine."No." <> OldServiceLine."No." then
            if ShowError then
                NewServiceLine.FieldError("No.", Text003)
            else
                HasError := true;

        if (NewServiceLine."Needed by Date" = 0D) and (OldServiceLine."Needed by Date" <> 0D) then
            if ShowError then
                NewServiceLine.FieldError("Needed by Date", Text002)
            else
                HasError := true;

        if NewServiceLine."Variant Code" <> OldServiceLine."Variant Code" then
            if ShowError then
                NewServiceLine.FieldError("Variant Code", Text003)
            else
                HasError := true;

        if NewServiceLine."Location Code" <> OldServiceLine."Location Code" then
            if ShowError then
                NewServiceLine.FieldError("Location Code", Text003)
            else
                HasError := true;

        if (NewServiceLine.Type = NewServiceLine.Type::Item) and (OldServiceLine.Type = OldServiceLine.Type::Item) then
            if (NewServiceLine."Bin Code" <> OldServiceLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewServiceLine."No.", NewServiceLine."Bin Code",
                  NewServiceLine."Location Code", NewServiceLine."Variant Code",
                  DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(),
                  NewServiceLine."Document No.", '', 0, NewServiceLine."Line No."))
            then begin
                if ShowError then
                    NewServiceLine.FieldError("Bin Code", Text004);
                HasError := true;
            end;

        if NewServiceLine."Line No." <> OldServiceLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewServiceLine, OldServiceLine, HasError, ShowError);

        if HasError then
            if (NewServiceLine."No." <> OldServiceLine."No.") or NewServiceLine.ReservEntryExist() then begin
                if NewServiceLine."No." <> OldServiceLine."No." then begin
                    ReservMgt.SetReservSource(OldServiceLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewServiceLine);
                end else begin
                    ReservMgt.SetReservSource(NewServiceLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
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
        with NewServiceLine do begin
            if not ("Document Type" in
                    ["Document Type"::Quote, "Document Type"::Order])
            then
                if "Shipment No." = '' then
                    exit;

            if Type <> Type::Item then
                exit;
            if "Line No." = OldServiceLine."Line No." then
                if "Quantity (Base)" = OldServiceLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ServiceLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewServiceLine);
            if "Qty. per Unit of Measure" <> OldServiceLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure();
            if "Outstanding Qty. (Base)" * OldServiceLine."Outstanding Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(false, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
            ReservMgt.ClearSurplus();
            ReservMgt.AutoTrack("Outstanding Qty. (Base)");
            AssignForPlanning(NewServiceLine);
        end;
    end;

    local procedure AssignForPlanning(var ServiceLine: Record "Service Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ServiceLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Needed by Date");
        end;
    end;

    procedure DeleteLineConfirm(var ServLine: Record "Service Line"): Boolean
    begin
        with ServLine do begin
            if not ReservEntryExist() then
                exit(true);

            ReservMgt.SetReservSource(ServLine);
            if ReservMgt.DeleteItemTrackingConfirm() then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ServLine: Record "Service Line")
    begin
        with ServLine do begin
            ReservMgt.SetReservSource(ServLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            DeleteInvoiceSpecFromLine(ServLine);
            CalcFields("Reserved Qty. (Base)");
        end;
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
            ItemTrackingLines.SetRunMode("Item Tracking Run Mode"::"Combined Ship/Rcpt");
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ServiceLine."Needed by Date");
        ItemTrackingLines.SetInbound(ServiceLine.IsInbound());
        OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ServiceLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure TransServLineToServLine(var OldServLine: Record "Service Line"; var NewServLine: Record "Service Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if not FindReservEntry(OldServLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock();

        NewServLine.TestItemFields(OldServLine."No.", OldServLine."Variant Code", OldServLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservEntry.FindSet() then
                repeat
                    OldReservEntry.TestItemFields(OldServLine."No.", OldServLine."Variant Code", OldServLine."Location Code");

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(DATABASE::"Service Line",
                            NewServLine."Document Type".AsInteger(), NewServLine."Document No.", '', 0,
                            NewServLine."Line No.", NewServLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    procedure RetrieveInvoiceSpecification(var ServLine: Record "Service Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    var
        SourceSpecification: Record "Tracking Specification";
    begin
        Clear(TempInvoicingSpecification);
        if ServLine.Type <> ServLine.Type::Item then
            exit;
        if ((ServLine."Document Type" = ServLine."Document Type"::Invoice) and
            (ServLine."Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(ServLine, TempInvoicingSpecification)
        else begin
            SourceSpecification.InitFromServLine(ServLine, Consume);
            OK := ItemTrackingMgt.RetrieveInvoiceSpecWithService(SourceSpecification, TempInvoicingSpecification, Consume);
        end;
    end;

    local procedure RetrieveInvoiceSpecification2(var ServLine: Record "Service Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        // Used for combined shipment:
        if ServLine.Type <> ServLine.Type::Item then
            exit;
        if not FindReservEntry(ServLine, ReservEntry) then
            exit;
        ReservEntry.FindSet();
        repeat
            ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            ReservEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservEntry."Item Ledger Entry No.");
            TempInvoicingSpecification := TrackingSpecification;
            TempInvoicingSpecification."Qty. to Invoice (Base)" :=
              ReservEntry."Qty. to Invoice (Base)";
            TempInvoicingSpecification."Qty. to Invoice" :=
              Round(ReservEntry."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            TempInvoicingSpecification."Buffer Status" := TempInvoicingSpecification."Buffer Status"::MODIFY;
            TempInvoicingSpecification.Insert();
            ReservEntry.Delete();
        until ReservEntry.Next() = 0;

        OK := TempInvoicingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(ServHeader: Record "Service Header")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromHeader(
          DATABASE::"Service Line", ServHeader."Document Type".AsInteger(), ServHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(ServLine: Record "Service Line")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromLine(
          DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.");
    end;

    procedure TransServLineToItemJnlLine(var ServLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean) Result: Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransServLineToItemJnlLine(ServLine, ItemJnlLine, TransferQty, CheckApplFromItemEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FindReservEntry(ServLine, OldReservEntry) then
            exit(TransferQty);

        OldReservEntry.Lock();

        ItemJnlLine.TestItemFields(ServLine."No.", ServLine."Variant Code", ServLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJnlLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(ServLine."No.", ServLine."Variant Code", ServLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure UpdateItemTrackingAfterPosting(ServHeader: Record "Service Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.SetSourceFilter(DATABASE::"Service Line", ServHeader."Document Type".AsInteger(), ServHeader."No.", -1, true);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure BindToPurchase(ServiceLine: Record "Service Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line",
          PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ServiceLine: Record "Service Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(ServiceLine, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(ServiceLine: Record "Service Line"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
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

    procedure BindToAssembly(ServiceLine: Record "Service Line"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
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

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: record "Reservation Entry"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        SourceRecRef.SetTable(ServiceLine);
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("Needed by Date");

        ServiceLine.SetReservationEntry(ReservEntry);

        CaptionText := ServiceLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit("Reservation Summary Type"::"Service Order".AsInteger() - 1);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = "Reservation Summary Type"::"Service Order".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 5902); // DATABASE::"Service Line"
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

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ServLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ServLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ServLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ServiceLine: Record "Service Line";
        AvailabilityFilter: Text;
    begin
        if not ServiceLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ServiceLine.FindLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
        if ServiceLine.FindSet() then
            repeat
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= ServiceLine."Reserved Qty. (Base)";
                TotalQuantity += ServiceLine."Outstanding Qty. (Base)";
            until ServiceLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity < 0) = Positive then begin
                "Table ID" := DATABASE::"Service Line";
                "Summary Type" :=
                    CopyStr(StrSubstNo('%1', ServiceLine.TableCaption()), 1, MaxStrLen("Summary Type"));
                "Total Quantity" := -TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." = 110 then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Positive, TotalQuantity);
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
}
