codeunit 925 "Assembly Header-Reserve"
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
        AssemblyTxt: Label 'Assembly';

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text001);

        AssemblyHeader.TestField("Item No.");
        AssemblyHeader.TestField("Due Date");

        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyHeader."Remaining Quantity (Base)") < Abs(AssemblyHeader."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(AssemblyHeader."Remaining Quantity (Base)") - Abs(AssemblyHeader."Reserved Qty. (Base)"));

        AssemblyHeader.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        AssemblyHeader.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase * SignFactor(AssemblyHeader) < 0 then
            ShipmentDate := AssemblyHeader."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := AssemblyHeader."Due Date";
        end;

        if AssemblyHeader."Planning Flexibility" <> AssemblyHeader."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(AssemblyHeader."Planning Flexibility");

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type",
          AssemblyHeader."No.", '', 0, 0, AssemblyHeader."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure SignFactor(AssemblyHeader: Record "Assembly Header"): Integer
    begin
        if AssemblyHeader."Document Type" in [2, 3, 5] then
            Error(Text001);

        exit(1);
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure SetDisallowCancellation(DisallowCancellation: Boolean)
    begin
        CreateReservEntry.SetDisallowCancellation(DisallowCancellation);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.SetReservationFilters(FilterReservEntry);
    end;

    procedure FindReservEntry(AssemblyHeader: Record "Assembly Header"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        AssemblyHeader.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    local procedure AssignForPlanning(var AssemblyHeader: Record "Assembly Header")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with AssemblyHeader do begin
            if "Document Type" <> "Document Type"::Order then
                exit;

            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure UpdatePlanningFlexibility(var AssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(AssemblyHeader, ReservEntry) then
            ReservEntry.ModifyAll("Planning Flexibility", AssemblyHeader."Planning Flexibility");
    end;

    procedure ReservEntryExist(AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        exit(AssemblyHeader.ReservEntryExist);
    end;

    procedure DeleteLine(var AssemblyHeader: Record "Assembly Header")
    begin
        with AssemblyHeader do begin
            ReservMgt.SetReservSource(AssemblyHeader);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            ReservMgt.ClearActionMessageReferences;
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(AssemblyHeader);
        end;
    end;

    procedure VerifyChange(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        NewAssemblyHeader.CalcFields("Reserved Qty. (Base)");
        ShowError := NewAssemblyHeader."Reserved Qty. (Base)" <> 0;

        if NewAssemblyHeader."Due Date" = 0D then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Item No.", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Location Code", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyHeader, OldAssemblyHeader, HasError, ShowError);

        if HasError then
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               FindReservEntry(NewAssemblyHeader, ReservEntry)
            then begin
                if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
                    ReservMgt.SetReservSource(OldAssemblyHeader);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewAssemblyHeader);
                end else begin
                    ReservMgt.SetReservSource(NewAssemblyHeader);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewAssemblyHeader."Remaining Quantity (Base)");
            end;

        if HasError or (NewAssemblyHeader."Due Date" <> OldAssemblyHeader."Due Date") then begin
            AssignForPlanning(NewAssemblyHeader);
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               (NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code") or
               (NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code")
            then
                AssignForPlanning(OldAssemblyHeader);
        end;
    end;

    procedure VerifyQuantity(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    begin
        with NewAssemblyHeader do begin
            if "Quantity (Base)" = OldAssemblyHeader."Quantity (Base)" then
                exit;

            ReservMgt.SetReservSource(NewAssemblyHeader);
            if "Qty. per Unit of Measure" <> OldAssemblyHeader."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Remaining Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Quantity (Base)");
            AssignForPlanning(NewAssemblyHeader);
        end;
    end;

    procedure Caption(AssemblyHeader: Record "Assembly Header") CaptionText: Text
    begin
        CaptionText := AssemblyHeader.GetSourceCaption;
    end;

    procedure CallItemTracking(var AssemblyHeader: Record "Assembly Header")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromAsmHeader(AssemblyHeader);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyHeader."Due Date");
        ItemTrackingLines.SetInbound(AssemblyHeader.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure DeleteLineConfirm(var AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        with AssemblyHeader do begin
            if not ReservEntryExist then
                exit(true);

            ReservMgt.SetReservSource(AssemblyHeader);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.InitSortingAndFilters(false);
        ReservEntry.SetSourceFilter(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type", AssemblyHeader."No.", -1, false);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure TransferAsmHeaderToItemJnlLine(var AssemblyHeader: Record "Assembly Header"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplToItemEntry: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        OldReservEntry2: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyHeader, OldReservEntry) then
            exit(TransferQty);
        AssemblyHeader.CalcFields("Assemble to Order");

        ItemJnlLine.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");

        OldReservEntry.Lock;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");
                if CheckApplToItemEntry and
                   (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation)
                then begin
                    OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                    OldReservEntry2.TestField("Source Type", DATABASE::"Item Ledger Entry");
                end;

                if AssemblyHeader."Assemble to Order" and
                   (OldReservEntry.Binding = OldReservEntry.Binding::"Order-to-Order")
                then begin
                    OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                    if Abs(OldReservEntry2."Qty. to Handle (Base)") < Abs(OldReservEntry."Qty. to Handle (Base)") then begin
                        OldReservEntry."Qty. to Handle (Base)" := Abs(OldReservEntry2."Qty. to Handle (Base)");
                        OldReservEntry."Qty. to Invoice (Base)" := Abs(OldReservEntry2."Qty. to Invoice (Base)");
                    end;
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := false;
        end;
        exit(TransferQty);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.Find;
            QtyPerUOM := AssemblyHeader.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        SourceRecRef.SetTable(AssemblyHeader);
        AssemblyHeader.TestField("Due Date");

        AssemblyHeader.SetReservationEntry(ReservEntry);

        CaptionText := AssemblyHeader.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(141);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [141, 142, 143, 144, 145]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 900); // DATABASE::"Assembly Header"
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
        AvailableAssemblyHeaders: page "Available - Assembly Headers";
    begin
        if EntrySummary."Entry No." in [141, 142] then begin
            Clear(AvailableAssemblyHeaders);
            AvailableAssemblyHeaders.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableAssemblyHeaders.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableAssemblyHeaders.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Assembly Header");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Assembly Header") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(AssemblyHeader);
            CreateReservation(AssemblyHeader, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
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
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceType) then begin
            AssemblyHeader.Reset();
            AssemblyHeader.SetRange("Document Type", SourceSubtype);
            AssemblyHeader.SetRange("No.", SourceID);
            PAGE.Run(PAGE::"Assembly Orders", AssemblyHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.SetReservationFilters(ReservEntry);
            CaptionText := AssemblyHeader.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(ReservEntry."Source Subtype", ReservEntry."Source ID");
        SourceRecRef.GetTable(AssemblyHeader);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(AssemblyHeader."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(AssemblyHeader."Quantity (Base)");
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
        AssemblyHeader: Record "Assembly Header";
        AvailabilityFilter: Text;
    begin
        if not AssemblyHeader.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        AssemblyHeader.FilterLinesForReservation(CalcReservEntry, DocumentType, AvailabilityFilter, Positive);
        if AssemblyHeader.FindSet then
            repeat
                AssemblyHeader.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" += AssemblyHeader."Reserved Qty. (Base)";
                TotalQuantity += AssemblyHeader."Remaining Quantity (Base)";
            until AssemblyHeader.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity > 0) = Positive then begin
                "Table ID" := DATABASE::"Assembly Header";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1 %2', AssemblyTxt, AssemblyHeader."Document Type"),
                    1, MaxStrLen("Summary Type"));
                "Total Quantity" := TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [141, 142] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 141, Positive, TotalQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyHeader: Record "Assembly Header"; OldAssemblyHeader: Record "Assembly Header"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}
