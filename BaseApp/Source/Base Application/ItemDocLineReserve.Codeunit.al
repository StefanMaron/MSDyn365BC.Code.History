codeunit 12452 "Item Doc. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Codeunit is not initialized correctly.';
        Text001: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text006: Label 'Outbound,Inbound';
        FromTrackingSpecification: Record "Tracking Specification";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;

    procedure CreateReservation(var ItemDocLine: Record "Item Document Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000);

        ItemDocLine.TestField("Item No.");
        ItemDocLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        case ItemDocLine."Document Type" of
            1: // Shipment
                begin
                    ItemDocLine.TestField("Document Date");
                    ItemDocLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    ItemDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(ItemDocLine."Quantity (Base)") <
                       Abs(ItemDocLine."Reserved Qty. Outbnd. (Base)") + Quantity
                    then
                        Error(
                          Text001,
                          Abs(ItemDocLine."Quantity (Base)") - Abs(ItemDocLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := ItemDocLine."Document Date";
                end;
            0: // Receipt
                begin
                    ItemDocLine.TestField("Document Date");
                    ItemDocLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    ItemDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(ItemDocLine."Quantity (Base)") <
                       Abs(ItemDocLine."Reserved Qty. Inbnd. (Base)") + Quantity
                    then
                        Error(
                          Text001,
                          Abs(ItemDocLine."Quantity (Base)") - Abs(ItemDocLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := ItemDocLine."Document Date";
                end;
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Item Document Line",
          ItemDocLine."Document Type", ItemDocLine."Document No.", '',
          0, ItemDocLine."Line No.", ItemDocLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ItemDocLine."Item No.", ItemDocLine."Variant Code", FromTrackingSpecification."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('This method is replaced with another overload.', '16.0')]
    procedure CreateReservation(var ItemDocLine: Record "Item Document Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50]; ForCDNo: Code[30])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        ForReservEntry."CD No." := ForCDNo;
        CreateReservation(ItemDocLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);

    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ItemDocLine: Record "Item Document Line")
    begin
        ItemDocLine.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(ItemDocLine: Record "Item Document Line"): Text
    begin
        exit(ItemDocLine.GetSourceCaption);
    end;

    procedure FindReservEntry(ItemDocLine: Record "Item Document Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ItemDocLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.Find('+'));
    end;

    procedure VerifyChange(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    var
        ItemDocLine: Record "Item Document Line";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
    begin
        if Blocked then
            exit;
        if NewItemDocLine."Line No." = 0 then
            if not ItemDocLine.Get(NewItemDocLine."Document Type", NewItemDocLine."Document No.", NewItemDocLine."Line No.") then
                exit;

        NewItemDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewItemDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewItemDocLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewItemDocLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewItemDocLine."Document Type" in
           [NewItemDocLine."Document Type"::Receipt, 2]
        then begin
            if NewItemDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewItemDocLine.FieldError("Document Date", Text002);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Document Type" in
           [NewItemDocLine."Document Type"::Shipment, 2]
        then begin
            if NewItemDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewItemDocLine.FieldError("Document Date", Text002);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewItemDocLine.FieldError("Item No.", Text003);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Location Code" <> OldItemDocLine."Location Code" then begin
            if ShowErrorOutbnd then
                NewItemDocLine.FieldError("Location Code", Text003);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Bin Code" <> OldItemDocLine."Bin Code" then begin
            if ShowErrorOutbnd then
                NewItemDocLine.FieldError("Bin Code", Text003);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code" then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewItemDocLine.FieldError("Variant Code", Text003);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Line No." <> OldItemDocLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if HasErrorOutbnd then begin
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or NewItemDocLine.ReservEntryExist then begin
                if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
                    ReservMgt.SetReservSource(OldItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewItemDocLine);
                end else begin
                    ReservMgt.SetReservSource(NewItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewItemDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewItemDocLine);
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               (NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code")
            then
                AssignForPlanning(OldItemDocLine);
        end;

        if HasErrorInbnd then begin
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or NewItemDocLine.ReservEntryExist() then begin
                if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
                    ReservMgt.SetReservSource(OldItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewItemDocLine);
                end else begin
                    ReservMgt.SetReservSource(NewItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewItemDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewItemDocLine);
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               (NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code") or
               (NewItemDocLine."Location Code" <> OldItemDocLine."Location Code")
            then
                AssignForPlanning(OldItemDocLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyQuantity(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if Blocked then
            exit;

        with NewItemDocLine do begin
            if "Line No." = OldItemDocLine."Line No." then
                if "Quantity (Base)" = OldItemDocLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ItemDocLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewItemDocLine);
            if "Qty. per Unit of Measure" <> OldItemDocLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Quantity (Base)");
            AssignForPlanning(NewItemDocLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure TransferItemDocToItemJnlLine(var ItemDocLine: Record "Item Document Line"; var ItemJnlLine: Record "Item Journal Line"; ReceiptQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(ItemDocLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        ItemJnlLine.TestField("Location Code", ItemDocLine."Location Code");
        ItemJnlLine.TestField("Item No.", ItemDocLine."Item No.");
        ItemJnlLine.TestField("Variant Code", ItemDocLine."Variant Code");

        if ReceiptQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestField("Item No.", ItemDocLine."Item No.");
                OldReservEntry.TestField("Variant Code", ItemDocLine."Variant Code");
                OldReservEntry.TestField("Location Code", ItemDocLine."Location Code");
                if ItemJnlLine."Red Storno" then
                    OldReservEntry.Validate("Quantity (Base)", -OldReservEntry."Quantity (Base)");
                ReceiptQty :=
                  CreateReservEntry.TransferReservEntry(
                    DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry,
                    ReceiptQty * ItemJnlLine."Qty. per Unit of Measure"); // qty base

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (ReceiptQty = 0);
    end;

    [Scope('OnPrem')]
    procedure RenameLine(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Item Document Line",
          0,
          OldItemDocLine."Document No.",
          '',
          0,
          OldItemDocLine."Line No.",
          0,
          NewItemDocLine."Document No.",
          '',
          0,
          NewItemDocLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure DeleteLine(var ItemDocLine: Record "Item Document Line")
    var
        ItemDocHeader: Record "Item Document Header";
        RedStorno: Boolean;
    begin
        if Blocked then
            exit;

        with ItemDocLine do begin
            ItemDocHeader.Get("Document Type", "Document No.");
            RedStorno := ItemDocHeader.Correction;
            case "Document Type" of
                "Document Type"::Receipt:
                    begin
                        ReservMgt.SetReservSource(ItemDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Outbnd. (Base)");
                    end;
                "Document Type"::Shipment:
                    begin
                        ReservMgt.SetReservSource(ItemDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Inbnd. (Base)");
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AssignForPlanning(var ItemDocLine: Record "Item Document Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ItemDocLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(
              ItemDocLine."Item No.",
              ItemDocLine."Variant Code",
              ItemDocLine."Location Code",
              ItemDocLine."Document Date");
    end;

    [Scope('OnPrem')]
    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    [Scope('OnPrem')]
    procedure CallItemTracking(var ItemDocLine: Record "Item Document Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemDocLine."Document Date");
        ItemTrackingLines.SetInbound(ItemDocLine."Document Type" = ItemDocLine."Document Type"::Receipt);
        ItemTrackingLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure CallItemTracking2(var ItemDocLine: Record "Item Document Line"; var SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemDocLine."Document Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure InitBinContentItemTracking(var ItemDocLine: Record "Item Document Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; QtyOnBin: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification" temporary;
        ReservEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        TrackingSpecification."Serial No." := SerialNo;
        TrackingSpecification."New Serial No." := SerialNo;
        TrackingSpecification."Lot No." := LotNo;
        TrackingSpecification."New Lot No." := LotNo;
        TrackingSpecification."CD No." := CDNo;
        TrackingSpecification."Quantity Handled (Base)" := 0;
        TrackingSpecification.Validate("Quantity (Base)", QtyOnBin);
        ReservEntry.TransferFields(TrackingSpecification);
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
        ReservEntry.Positive := ReservEntry."Quantity (Base)" > 0;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ItemDocLine);
            ItemDocLine.Find;
            QtyPerUOM := ItemDocLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        SourceRecRef.SetTable(ItemDocLine);
        ReservEntry.SetSource(
          DATABASE::"Item Document Line", ItemDocLine."Document Type", ItemDocLine."Document No.", ItemDocLine."Line No.", '', 0);

        ReservEntry."Item No." := ItemDocLine."Item No.";
        ReservEntry."Variant Code" := ItemDocLine."Variant Code";
        ReservEntry."Location Code" := ItemDocLine."Location Code";
        if ReservEntry."Source Subtype" = 0 then
            ReservEntry."Expected Receipt Date" := ItemDocLine."Document Date"
        else
            ReservEntry."Shipment Date" := ItemDocLine."Document Date";

        CaptionText := ItemDocLine.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(12450);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [12450, 12451]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 12453); // DATABASE::"Item Document Line"
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
        AvailableItemDocLines: page "Available - Item Doc. Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableItemDocLines);
            AvailableItemDocLines.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableItemDocLines.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Item Document Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then begin
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Item Document Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantityElseCase', '', false, false)]
    local procedure OnDrillDownTotalQuantityElseCase(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        CreatePick: Codeunit "Create Pick";
        AvailableItemLedgEntries: page "Available - Item Ledg. Entries";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, "Transfer Direction".FromInteger(ReservEntry."Source Subtype"));
            if Location."Bin Mandatory" or Location."Require Pick" then
                AvailableItemLedgEntries.SetTotalAvailQty(
                    EntrySummary."Total Available Quantity" +
                    CreatePick.CheckOutBound(
                    ReservEntry."Source Type", ReservEntry."Source Subtype",
                    ReservEntry."Source ID", ReservEntry."Source Ref. No.",
                    ReservEntry."Source Prod. Order Line"))
            else
                AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
            AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
            AvailableItemLedgEntries.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ItemDocLine);
            CreateReservation(ItemDocLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ItemDocHeader: Record "Item Document Header";
    begin
        if MatchThisTable(SourceType) then begin
            ItemDocHeader.Reset();
            ItemDocHeader.SetRange("Document Type", SourceSubtype);
            ItemDocHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Item Receipt", ItemDocHeader);
                1:
                    PAGE.RunModal(PAGE::"Item Shipment", ItemDocHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if MatchThisTable(SourceType) then begin
            ItemDocLine.Reset();
            ItemDocLine.SetRange("Document Type", SourceSubtype);
            ItemDocLine.SetRange("Document No.", SourceID);
            ItemDocLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, ItemDocLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ItemDocLine);
            ItemDocLine.SetReservationFilters(ReservEntry);
            CaptionText := ItemDocLine.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ItemDocLine);
            ItemDocLine.GetRemainingQty(RemainingQty, RemainingQtyBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemDocLine: Record "Item Document Line";
    begin
        ItemDocLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ItemDocLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemDocLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemDocLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Integer; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ItemDocLine: Record "Item Document Line";
        AvailabilityFilter: Text;
    begin
        if not ItemDocLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        case DocumentType of
            0:
                ItemDocLine.FilterShipmentLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
            1:
                ItemDocLine.FilterReceiptLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
        end;

        if ItemDocLine.FindSet then
            repeat
                case DocumentType of
                    0:
                        begin
                            ItemDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" -= ItemDocLine."Reserved Qty. Outbnd. (Base)";
                            TotalQuantity -= ItemDocLine."Quantity (Base)";
                        end;
                    1:
                        begin
                            ItemDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" += ItemDocLine."Reserved Qty. Inbnd. (Base)";
                            TotalQuantity += ItemDocLine."Quantity (Base)";
                        end;
                end;
            until ItemDocLine.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity > 0) = Positive then begin
                "Table ID" := DATABASE::"Item Document Line";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1, %2', ItemDocLine.TableCaption, SelectStr(DocumentType, Text006)),
                    1, MaxStrLen("Summary Type"));
                "Total Quantity" := TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [12450, 12451] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 12450, Positive, TotalQuantity);
    end;
}

