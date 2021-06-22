codeunit 926 "Assembly Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text001: Label 'Codeunit is not initialized correctly.';
        DeleteItemTracking: Boolean;
        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';

    procedure CreateReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text001);

        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("No.");
        AssemblyLine.TestField("Due Date");

        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyLine."Remaining Quantity (Base)") < Abs(AssemblyLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
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
          DATABASE::"Assembly Line", AssemblyLine."Document Type",
          AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.", AssemblyLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    local procedure CreateBindingReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure SignFactor(AssemblyLine: Record "Assembly Line"): Integer
    begin
        if AssemblyLine."Document Type" in [2, 3, 5] then
            Error(Text001);

        exit(-1);
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetReservationFilters(FilterReservEntry);
    end;

    procedure FindReservEntry(AssemblyLine: Record "Assembly Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        AssemblyLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    local procedure AssignForPlanning(var AssemblyLine: Record "Assembly Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with AssemblyLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;

            if Type <> Type::Item then
                exit;

            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure ReservEntryExist(AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(AssemblyLine.ReservEntryExist);
    end;

    procedure DeleteLine(var AssemblyLine: Record "Assembly Line")
    begin
        with AssemblyLine do begin
            ReservMgt.SetReservSource(AssemblyLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            ReservMgt.ClearActionMessageReferences;
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(AssemblyLine);
        end;
    end;

    procedure SetDeleteItemTracking(AllowDirectDeletion: Boolean)
    begin
        DeleteItemTracking := AllowDirectDeletion;
    end;

    procedure VerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
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
                NewAssemblyLine.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewAssemblyLine.Type <> OldAssemblyLine.Type then begin
            if ShowError then
                NewAssemblyLine.FieldError(Type, Text003);
            HasError := true;
        end;

        if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
            if ShowError then
                NewAssemblyLine.FieldError("No.", Text003);
            HasError := true;
        end;

        if NewAssemblyLine."Location Code" <> OldAssemblyLine."Location Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Location Code", Text003);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyLine, OldAssemblyLine, HasError, ShowError);

        if (NewAssemblyLine.Type = NewAssemblyLine.Type::Item) and (OldAssemblyLine.Type = OldAssemblyLine.Type::Item) and
           (NewAssemblyLine."Bin Code" <> OldAssemblyLine."Bin Code")
        then
            if not ReservMgt.CalcIsAvailTrackedQtyInBin(
                 NewAssemblyLine."No.", NewAssemblyLine."Bin Code",
                 NewAssemblyLine."Location Code", NewAssemblyLine."Variant Code",
                 DATABASE::"Assembly Line", NewAssemblyLine."Document Type",
                 NewAssemblyLine."Document No.", '', 0, NewAssemblyLine."Line No.")
            then begin
                if ShowError then
                    NewAssemblyLine.FieldError("Bin Code", Text003);
                HasError := true;
            end;

        if NewAssemblyLine."Variant Code" <> OldAssemblyLine."Variant Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        if NewAssemblyLine."Line No." <> OldAssemblyLine."Line No." then
            HasError := true;

        if HasError then
            if (NewAssemblyLine."No." <> OldAssemblyLine."No.") or
               FindReservEntry(NewAssemblyLine, ReservEntry)
            then begin
                if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
                    ReservMgt.SetReservSource(OldAssemblyLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewAssemblyLine);
                end else begin
                    ReservMgt.SetReservSource(NewAssemblyLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewAssemblyLine."Remaining Quantity (Base)");
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
        with NewAssemblyLine do begin
            if Type <> Type::Item then
                exit;
            if "Line No." = OldAssemblyLine."Line No." then
                if "Remaining Quantity (Base)" = OldAssemblyLine."Remaining Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not AssemblyLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;

            ReservMgt.SetReservSource(NewAssemblyLine);
            if "Qty. per Unit of Measure" <> OldAssemblyLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Remaining Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Quantity (Base)");
            AssignForPlanning(NewAssemblyLine);
        end;
    end;

    procedure Caption(AssemblyLine: Record "Assembly Line") CaptionText: Text
    begin
        CaptionText := AssemblyLine.GetSourceCaption;
    end;

    procedure CallItemTracking(var AssemblyLine: Record "Assembly Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromAsmLine(AssemblyLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyLine."Due Date");
        ItemTrackingLines.SetInbound(AssemblyLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure DeleteLineConfirm(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        with AssemblyLine do begin
            if not ReservEntryExist then
                exit(true);

            ReservMgt.SetReservSource(AssemblyLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyLine: Record "Assembly Line")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.InitSortingAndFilters(false);
        ReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
        ReservEntry.SetRange("Source Subtype", AssemblyLine."Document Type");
        ReservEntry.SetRange("Source ID", AssemblyLine."Document No.");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure TransferAsmLineToItemJnlLine(var AssemblyLine: Record "Assembly Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyLine, OldReservEntry) then
            exit(TransferQty);

        ItemJnlLine.TestField("Item No.", AssemblyLine."No.");
        ItemJnlLine.TestField("Variant Code", AssemblyLine."Variant Code");
        ItemJnlLine.TestField("Location Code", AssemblyLine."Location Code");

        OldReservEntry.Lock;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestField("Item No.", AssemblyLine."No.");
                OldReservEntry.TestField("Variant Code", AssemblyLine."Variant Code");
                OldReservEntry.TestField("Location Code", AssemblyLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure TransferAsmLineToAsmLine(var OldAssemblyLine: Record "Assembly Line"; var NewAssemblyLine: Record "Assembly Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if TransferQty = 0 then
            exit;

        if not FindReservEntry(OldAssemblyLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewAssemblyLine.TestField("No.", OldAssemblyLine."No.");
        NewAssemblyLine.TestField("Variant Code", OldAssemblyLine."Variant Code");
        NewAssemblyLine.TestField("Location Code", OldAssemblyLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            OldReservEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestField("Item No.", OldAssemblyLine."No.");
                    OldReservEntry.TestField("Variant Code", OldAssemblyLine."Variant Code");
                    OldReservEntry.TestField("Location Code", OldAssemblyLine."Location Code");

                    TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Assembly Line",
                        NewAssemblyLine."Document Type", NewAssemblyLine."Document No.", '', 0,
                        NewAssemblyLine."Line No.", NewAssemblyLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

    procedure BindToPurchase(AsmLine: Record "Assembly Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(AsmLine: Record "Assembly Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(AsmLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(AsmLine: Record "Assembly Line"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyLine);
            AssemblyLine.Find;
            QtyPerUOM := AssemblyLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SourceRecRef.SetTable(AssemblyLine);
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("Due Date");

        AssemblyLine.SetReservationEntry(ReservEntry);

        CaptionText := AssemblyLine.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(151);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [151, 152, 153, 154, 155]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 901); // DATABASE::"Assembly Line"
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
            AvailableAssemblyLines.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableAssemblyLines.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then begin
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Assembly Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
        end;
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
            CaptionText := AssemblyLine.GetSourceCaption;
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

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(AssemblyLine);
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

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        AvailabilityFilter: Text;
    begin
        if not AssemblyLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        AssemblyLine.FilterLinesForReservation(CalcReservEntry, DocumentType, AvailabilityFilter, Positive);
        if AssemblyLine.FindSet then
            repeat
                AssemblyLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= AssemblyLine."Reserved Qty. (Base)";
                TotalQuantity += AssemblyLine."Remaining Quantity (Base)";
            until AssemblyLine.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if TotalQuantity < 0 = Positive then begin
                "Table ID" := DATABASE::"Assembly Line";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1, %2', AssemblyLine.TableCaption, AssemblyLine."Document Type"),
                    1, MaxStrLen("Summary Type"));
                "Total Quantity" := -TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [151, 152] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 151, Positive, TotalQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyLine: Record "Assembly Line"; OldAssemblyLine: Record "Assembly Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

