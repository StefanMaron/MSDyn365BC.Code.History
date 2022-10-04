codeunit 5854 "Invt. Doc. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        InvtSetup: Record "Inventory Setup";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;
        InvtSetupRead: Boolean;
        CodeunitIsNotInitializedErr: Label 'Codeunit is not initialized correctly.';
        CannotBeGreaterErr: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - quantity';
        MustBeFilledErr: Label 'must be filled in when a quantity is reserved';
        MustNotBeChangedErr: Label 'must not be changed when a quantity is reserved';
        DirectionTxt: Label 'Outbound,Inbound';
        SummaryTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(var InvtDocLine: Record "Invt. Document Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(CodeunitIsNotInitializedErr);

        InvtDocLine.TestField("Item No.");
        InvtDocLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        case InvtDocLine."Document Type" of
            "Invt. Doc. Document Type"::Shipment:
                begin
                    InvtDocLine.TestField("Document Date");
                    InvtDocLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    InvtDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(InvtDocLine."Quantity (Base)") <
                       Abs(InvtDocLine."Reserved Qty. Outbnd. (Base)") + Quantity
                    then
                        Error(
                          CannotBeGreaterErr,
                          Abs(InvtDocLine."Quantity (Base)") - Abs(InvtDocLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := InvtDocLine."Document Date";
                end;
            "Invt. Doc. Document Type"::Receipt:
                begin
                    InvtDocLine.TestField("Document Date");
                    InvtDocLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    InvtDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(InvtDocLine."Quantity (Base)") <
                       Abs(InvtDocLine."Reserved Qty. Inbnd. (Base)") + Quantity
                    then
                        Error(
                          CannotBeGreaterErr,
                          Abs(InvtDocLine."Quantity (Base)") - Abs(InvtDocLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := InvtDocLine."Document Date";
                end;
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Invt. Document Line",
          InvtDocLine."Document Type".AsInteger(), InvtDocLine."Document No.", '',
          0, InvtDocLine."Line No.", InvtDocLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          InvtDocLine."Item No.", InvtDocLine."Variant Code", FromTrackingSpecification."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; InvtDocLine: Record "Invt. Document Line")
    begin
        InvtDocLine.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(InvtDocLine: Record "Invt. Document Line"): Text
    begin
        exit(InvtDocLine.GetSourceCaption());
    end;

    procedure FindReservEntry(InvtDocLine: Record "Invt. Document Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        InvtDocLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.Find('+'));
    end;

    procedure VerifyChange(var NewInvtDocLine: Record "Invt. Document Line"; var OldInvtDocLine: Record "Invt. Document Line")
    var
        InvtDocLine: Record "Invt. Document Line";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
    begin
        if Blocked then
            exit;
        if NewInvtDocLine."Line No." = 0 then
            if not InvtDocLine.Get(NewInvtDocLine."Document Type", NewInvtDocLine."Document No.", NewInvtDocLine."Line No.") then
                exit;

        NewInvtDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewInvtDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewInvtDocLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewInvtDocLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewInvtDocLine."Document Type" = NewInvtDocLine."Document Type"::Receipt then begin
            if NewInvtDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewInvtDocLine.FieldError("Document Date", MustBeFilledErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Document Type" = NewInvtDocLine."Document Type"::Shipment then begin
            if NewInvtDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewInvtDocLine.FieldError("Document Date", MustBeFilledErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Item No." <> OldInvtDocLine."Item No." then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewInvtDocLine.FieldError("Item No.", MustNotBeChangedErr);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Location Code" <> OldInvtDocLine."Location Code" then begin
            if ShowErrorOutbnd then
                NewInvtDocLine.FieldError("Location Code", MustNotBeChangedErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Bin Code" <> OldInvtDocLine."Bin Code" then begin
            if ShowErrorOutbnd then
                NewInvtDocLine.FieldError("Bin Code", MustNotBeChangedErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Variant Code" <> OldInvtDocLine."Variant Code" then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewInvtDocLine.FieldError("Variant Code", MustNotBeChangedErr);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewInvtDocLine."Line No." <> OldInvtDocLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if HasErrorOutbnd then begin
            if (NewInvtDocLine."Item No." <> OldInvtDocLine."Item No.") or NewInvtDocLine.ReservEntryExist() then begin
                if NewInvtDocLine."Item No." <> OldInvtDocLine."Item No." then begin
                    ReservMgt.SetReservSource(OldInvtDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewInvtDocLine);
                end else begin
                    ReservMgt.SetReservSource(NewInvtDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewInvtDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewInvtDocLine);
            if (NewInvtDocLine."Item No." <> OldInvtDocLine."Item No.") or
               (NewInvtDocLine."Variant Code" <> OldInvtDocLine."Variant Code")
            then
                AssignForPlanning(OldInvtDocLine);
        end;

        if HasErrorInbnd then begin
            if (NewInvtDocLine."Item No." <> OldInvtDocLine."Item No.") or NewInvtDocLine.ReservEntryExist() then begin
                if NewInvtDocLine."Item No." <> OldInvtDocLine."Item No." then begin
                    ReservMgt.SetReservSource(OldInvtDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewInvtDocLine);
                end else begin
                    ReservMgt.SetReservSource(NewInvtDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewInvtDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewInvtDocLine);
            if (NewInvtDocLine."Item No." <> OldInvtDocLine."Item No.") or
               (NewInvtDocLine."Variant Code" <> OldInvtDocLine."Variant Code") or
               (NewInvtDocLine."Location Code" <> OldInvtDocLine."Location Code")
            then
                AssignForPlanning(OldInvtDocLine);
        end;
    end;

    procedure VerifyQuantity(var NewInvtDocLine: Record "Invt. Document Line"; var OldInvtDocLine: Record "Invt. Document Line")
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if Blocked then
            exit;

        with NewInvtDocLine do begin
            if "Line No." = OldInvtDocLine."Line No." then
                if "Quantity (Base)" = OldInvtDocLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not InvtDocLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewInvtDocLine);
            if "Qty. per Unit of Measure" <> OldInvtDocLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure();
            ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
            ReservMgt.ClearSurplus();
            ReservMgt.AutoTrack("Quantity (Base)");
            AssignForPlanning(NewInvtDocLine);
        end;
    end;

    procedure TransferInvtDocToItemJnlLine(var InvtDocLine: Record "Invt. Document Line"; var ItemJnlLine: Record "Item Journal Line"; ReceiptQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(InvtDocLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock();

        ItemJnlLine.TestField("Location Code", InvtDocLine."Location Code");
        ItemJnlLine.TestField("Item No.", InvtDocLine."Item No.");
        ItemJnlLine.TestField("Variant Code", InvtDocLine."Variant Code");

        if ReceiptQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestField("Item No.", InvtDocLine."Item No.");
                OldReservEntry.TestField("Variant Code", InvtDocLine."Variant Code");
                OldReservEntry.TestField("Location Code", InvtDocLine."Location Code");
                ReceiptQty :=
                  CreateReservEntry.TransferReservEntry(
                    DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry,
                    ReceiptQty * ItemJnlLine."Qty. per Unit of Measure"); // qty base

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (ReceiptQty = 0);
    end;

    procedure RenameLine(var NewInvtDocLine: Record "Invt. Document Line"; var OldInvtDocLine: Record "Invt. Document Line")
    begin
        ReservEngineMgt.RenamePointer(
            DATABASE::"Invt. Document Line",
            0, OldInvtDocLine."Document No.", '', 0, OldInvtDocLine."Line No.",
            0, NewInvtDocLine."Document No.", '', 0, NewInvtDocLine."Line No.");
    end;

    procedure DeleteLine(var InvtDocLine: Record "Invt. Document Line")
    var
        InvtDocHeader: Record "Invt. Document Header";
        RedStorno: Boolean;
    begin
        if Blocked then
            exit;

        with InvtDocLine do begin
            InvtDocHeader.Get("Document Type", "Document No.");
            RedStorno := InvtDocHeader.Correction;
            case "Document Type" of
                "Document Type"::Receipt:
                    begin
                        ReservMgt.SetReservSource(InvtDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Outbnd. (Base)");
                    end;
                "Document Type"::Shipment:
                    begin
                        ReservMgt.SetReservSource(InvtDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Inbnd. (Base)");
                    end;
            end;
        end;
    end;

    procedure AssignForPlanning(var InvtDocLine: Record "Invt. Document Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if InvtDocLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(
              InvtDocLine."Item No.",
              InvtDocLine."Variant Code",
              InvtDocLine."Location Code",
              InvtDocLine."Document Date");
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var InvtDocLine: Record "Invt. Document Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromInvtDocLine(InvtDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, InvtDocLine."Document Date");
        ItemTrackingLines.SetInbound(InvtDocLine."Document Type" = InvtDocLine."Document Type"::Receipt);
        ItemTrackingLines.RunModal();
    end;

    procedure CallItemTracking2(var InvtDocLine: Record "Invt. Document Line"; var SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromInvtDocLine(InvtDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, InvtDocLine."Document Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal();
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(InvtDocLine);
            InvtDocLine.Find();
            QtyPerUOM := InvtDocLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        SourceRecRef.SetTable(InvtDocLine);
        ReservEntry.SetSource(
          DATABASE::"Invt. Document Line", InvtDocLine."Document Type".AsInteger(), InvtDocLine."Document No.", InvtDocLine."Line No.", '', 0);

        ReservEntry."Item No." := InvtDocLine."Item No.";
        ReservEntry."Variant Code" := InvtDocLine."Variant Code";
        ReservEntry."Location Code" := InvtDocLine."Location Code";
        if ReservEntry."Source Subtype" = 0 then
            ReservEntry."Expected Receipt Date" := InvtDocLine."Document Date"
        else
            ReservEntry."Shipment Date" := InvtDocLine."Document Date";

        CaptionText := InvtDocLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit("Reservation Summary Type"::"Inventory Receipt".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        if not (EntryNo in ["Reservation Summary Type"::"Inventory Receipt".AsInteger(),
                            "Reservation Summary Type"::"Inventory Shipment".AsInteger()])
        then
            exit(false);

        GetInvtSetup();
        exit(InvtSetup."Allow Invt. Doc. Reservation");
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        if TableID <> 5851 then
            exit(false);

        GetInvtSetup();
        exit(InvtSetup."Allow Invt. Doc. Reservation");
    end;

    local procedure GetInvtSetup()
    begin
        if InvtSetupRead then
            exit;

        InvtSetup.Get();
        InvtSetupRead := true;
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
        AvailableInvtDocLines: page "Available - Invt. Doc. Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableInvtDocLines);
            AvailableInvtDocLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableInvtDocLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Invt. Document Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Invt. Document Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
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
            AvailableItemLedgEntries.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(InvtDocLine);
            CreateReservation(InvtDocLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        if MatchThisTable(SourceType) then begin
            InvtDocHeader.Reset();
            InvtDocHeader.SetRange("Document Type", SourceSubtype);
            InvtDocHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Invt. Receipt", InvtDocHeader);
                1:
                    PAGE.RunModal(PAGE::"Invt. Shipment", InvtDocHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceType) then begin
            InvtDocLine.Reset();
            InvtDocLine.SetRange("Document Type", SourceSubtype);
            InvtDocLine.SetRange("Document No.", SourceID);
            InvtDocLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, InvtDocLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(InvtDocLine);
            InvtDocLine.SetReservationFilters(ReservEntry);
            CaptionText := InvtDocLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(InvtDocLine);
            InvtDocLine.GetRemainingQty(RemainingQty, RemainingQtyBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        InvtDocLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(InvtDocLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(InvtDocLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(InvtDocLine."Quantity (Base)");
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
        InvtDocLine: Record "Invt. Document Line";
        AvailabilityFilter: Text;
    begin
        if not InvtDocLine.ReadPermission() then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        case DocumentType of
            0:
                InvtDocLine.FilterShipmentLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
            1:
                InvtDocLine.FilterReceiptLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
        end;

        if InvtDocLine.FindSet() then
            repeat
                case DocumentType of
                    0:
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" -= InvtDocLine."Reserved Qty. Outbnd. (Base)";
                            TotalQuantity -= InvtDocLine."Quantity (Base)";
                        end;
                    1:
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" += InvtDocLine."Reserved Qty. Inbnd. (Base)";
                            TotalQuantity += InvtDocLine."Quantity (Base)";
                        end;
                end;
            until InvtDocLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := DATABASE::"Invt. Document Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(
                    StrSubstNo(SummaryTxt, InvtDocLine.TableCaption(), SelectStr(DocumentType + 1, DirectionTxt)),
                    1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" :=
                TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if MatchThisEntry(ReservSummEntry."Entry No.") then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - EntryStartNo(), Positive, TotalQuantity);
    end;
}

