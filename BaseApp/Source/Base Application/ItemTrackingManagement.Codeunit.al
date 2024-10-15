codeunit 6500 "Item Tracking Management"
{
    Permissions = TableData "Item Entry Relation" = rd,
                  TableData "Value Entry Relation" = rd,
                  TableData "Whse. Item Tracking Line" = rimd,
                  TableData "Tracking Specification" = rd;

    trigger OnRun()
    var
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        SourceSpecification.TestField("Source Type");
        ItemTrackingLines.RegisterItemTrackingLines(
          SourceSpecification, DueDate, TempTrackingSpecification)
    end;

    var
        Text003: Label 'No information exists for %1 %2.';
        Text005: Label 'Warehouse item tracking is not enabled for %1 %2.';
        SourceSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempGlobalWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        CachedItem: Record Item;
        CachedItemTrackingCode: Record "Item Tracking Code";
        UOMMgt: Codeunit "Unit of Measure Management";
        DueDate: Date;
        Text006: Label 'Synchronization cancelled.';
        Registering: Boolean;
        Text007: Label 'There are multiple expiration dates registered for lot %1.';
        text008: Label '%1 already exists for %2 %3. Do you want to overwrite the existing information?';
        IsConsume: Boolean;
        Text011: Label '%1 must not be %2.';
        Text012: Label 'Only one expiration date is allowed per lot number.\%1 currently has two different expiration dates: %2 and %3.';
        IsPick: Boolean;
        DeleteReservationEntries: Boolean;
        CannotMatchItemTrackingErr: Label 'Cannot match item tracking.';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';

    procedure SetPointerFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
        with TrackingSpecification do begin
            SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
            SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
        end;
    end;

    procedure LookupLotSerialNoInfo(ItemNo: Code[20]; Variant: Code[20]; LookupType: Option "Serial No.","Lot No.","CD No."; LookupNo: Code[50])
    var
        LotNoInfo: Record "Lot No. Information";
        SerialNoInfo: Record "Serial No. Information";
        CDNoInfo: Record "CD No. Information";
    begin
        case LookupType of
            LookupType::"Serial No.":
                begin
                    if not SerialNoInfo.Get(ItemNo, Variant, LookupNo) then
                        Error(Text003, SerialNoInfo.FieldCaption("Serial No."), LookupNo);
                    PAGE.RunModal(0, SerialNoInfo);
                end;
            LookupType::"Lot No.":
                begin
                    if not LotNoInfo.Get(ItemNo, Variant, LookupNo) then
                        Error(Text003, LotNoInfo.FieldCaption("Lot No."), LookupNo);
                    PAGE.RunModal(0, LotNoInfo);
                end;
            LookupType::"CD No.":
                begin
                    if not CDNoInfo.Get(CDNoInfo.Type::Item, ItemNo, Variant, LookupNo) then
                        Error(Text003, CDNoInfo.FieldCaption("CD No."), LookupNo);
                    PAGE.RunModal(0, CDNoInfo);
                end;
        end;
    end;

    procedure CreateTrackingSpecification(var FromReservEntry: Record "Reservation Entry"; var ToTrackingSpecification: Record "Tracking Specification")
    begin
        ToTrackingSpecification.Init;
        ToTrackingSpecification.TransferFields(FromReservEntry);
        ToTrackingSpecification."Qty. to Handle (Base)" := 0;
        ToTrackingSpecification."Qty. to Invoice (Base)" := 0;
        ToTrackingSpecification."Quantity Handled (Base)" := FromReservEntry."Qty. to Handle (Base)";
        ToTrackingSpecification."Quantity Invoiced (Base)" := FromReservEntry."Qty. to Invoice (Base)";

        OnAfterCreateTrackingSpecification(ToTrackingSpecification, FromReservEntry);
    end;

    procedure GetItemTrackingSettings(var ItemTrackingCode: Record "Item Tracking Code"; var CDTrackingSetup: Record "CD Tracking Setup"; EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output"; Inbound: Boolean; var SNRequired: Boolean; var LotRequired: Boolean; var CDRequired: Boolean; var SNInfoRequired: Boolean; var LotInfoRequired: Boolean; var CDInfoRequired: Boolean)
    begin
        SNRequired := false;
        LotRequired := false;
        CDRequired := false;
        SNInfoRequired := false;
        LotInfoRequired := false;
        CDInfoRequired := false;

        if ItemTrackingCode.Code = '' then begin
            Clear(ItemTrackingCode);
            exit;
        end;
        ItemTrackingCode.Get(ItemTrackingCode.Code);

        if (CDTrackingSetup."Item Tracking Code" = '') or (CDTrackingSetup."Location Code" = '') then
            Clear(CDTrackingSetup)
        else
            if not CDTrackingSetup.Get(CDTrackingSetup."Item Tracking Code", CDTrackingSetup."Location Code") then
                Clear(CDTrackingSetup);

        if EntryType = EntryType::Transfer then begin
            LotInfoRequired := ItemTrackingCode."Lot Info. Outbound Must Exist" or ItemTrackingCode."Lot Info. Inbound Must Exist";
            SNInfoRequired := ItemTrackingCode."SN Info. Outbound Must Exist" or ItemTrackingCode."SN Info. Inbound Must Exist";
        end else begin
            SNInfoRequired := (Inbound and ItemTrackingCode."SN Info. Inbound Must Exist") or
              (not Inbound and ItemTrackingCode."SN Info. Outbound Must Exist");

            LotInfoRequired := (Inbound and ItemTrackingCode."Lot Info. Inbound Must Exist") or
              (not Inbound and ItemTrackingCode."Lot Info. Outbound Must Exist");
        end;

        CDInfoRequired := CDTrackingSetup."CD Info. Must Exist";

        if ItemTrackingCode."SN Specific Tracking" then begin
            SNRequired := true;
        end else
            case EntryType of
                EntryType::Purchase:
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Purchase Inbound Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Purchase Outbound Tracking";
                EntryType::Sale:
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Sales Inbound Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Sales Outbound Tracking";
                EntryType::"Positive Adjmt.":
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking";
                EntryType::"Negative Adjmt.":
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking";
                EntryType::Transfer:
                    SNRequired := ItemTrackingCode."SN Transfer Tracking";
                EntryType::Consumption, EntryType::Output:
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Manuf. Inbound Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Manuf. Outbound Tracking";
                EntryType::"Assembly Consumption", EntryType::"Assembly Output":
                    if Inbound then
                        SNRequired := ItemTrackingCode."SN Assembly Inbound Tracking"
                    else
                        SNRequired := ItemTrackingCode."SN Assembly Outbound Tracking";
            end;

        if ItemTrackingCode."Lot Specific Tracking" then begin
            LotRequired := true;
        end else
            case EntryType of
                EntryType::Purchase:
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Purchase Inbound Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Purchase Outbound Tracking";
                EntryType::Sale:
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Sales Inbound Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Sales Outbound Tracking";
                EntryType::"Positive Adjmt.":
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking";
                EntryType::"Negative Adjmt.":
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking";
                EntryType::Transfer:
                    LotRequired := ItemTrackingCode."Lot Transfer Tracking";
                EntryType::Consumption, EntryType::Output:
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Manuf. Inbound Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Manuf. Outbound Tracking";
                EntryType::"Assembly Consumption", EntryType::"Assembly Output":
                    if Inbound then
                        LotRequired := ItemTrackingCode."Lot Assembly Inbound Tracking"
                    else
                        LotRequired := ItemTrackingCode."Lot Assembly Outbound Tracking";
            end;

        CDRequired := ItemTrackingCode."CD Specific Tracking";
    end;

    procedure RetrieveInvoiceSpecification(SourceSpecification: Record "Tracking Specification"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecSummedUp: Record "Tracking Specification" temporary;
    begin
        OK := false;
        TempInvoicingSpecification.Reset;
        TempInvoicingSpecification.DeleteAll;

        ReservEntry.SetSourceFilter(
          SourceSpecification."Source Type", SourceSpecification."Source Subtype", SourceSpecification."Source ID",
          SourceSpecification."Source Ref. No.", true);
        ReservEntry.SetSourceFilter(SourceSpecification."Source Batch Name", SourceSpecification."Source Prod. Order Line");
        ReservEntry.SetFilter("Reservation Status", '<>%1', ReservEntry."Reservation Status"::Prospect);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        SumUpItemTracking(ReservEntry, TempTrackingSpecSummedUp, false, true);

        // TrackingSpecification contains information about lines that should be invoiced:
        TrackingSpecification.SetSourceFilter(
          SourceSpecification."Source Type", SourceSpecification."Source Subtype", SourceSpecification."Source ID",
          SourceSpecification."Source Ref. No.", true);
        TrackingSpecification.SetSourceFilter(
          SourceSpecification."Source Batch Name", SourceSpecification."Source Prod. Order Line");
        if TrackingSpecification.FindSet then
            repeat
                TrackingSpecification.TestField("Qty. to Handle (Base)", 0);
                TrackingSpecification.TestField("Qty. to Handle", 0);
                if not TrackingSpecification.Correction then begin
                    TempInvoicingSpecification := TrackingSpecification;
                    TempInvoicingSpecification."Qty. to Invoice" :=
                      Round(TempInvoicingSpecification."Qty. to Invoice (Base)" /
                        SourceSpecification."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    TempInvoicingSpecification.Insert;
                    OK := true;

                    TempTrackingSpecSummedUp.SetTrackingFilter(
                      TempInvoicingSpecification."Serial No.", TempInvoicingSpecification."Lot No.", TempInvoicingSpecification."CD No.");
                    if TempTrackingSpecSummedUp.FindFirst then begin
                        TempTrackingSpecSummedUp."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                        OnBeforeTempTrackingSpecSummedUpModify(TempTrackingSpecSummedUp, TempInvoicingSpecification);
                        TempTrackingSpecSummedUp.Modify;
                    end else begin
                        TempTrackingSpecSummedUp := TempInvoicingSpecification;
                        TempTrackingSpecSummedUp.Insert;
                    end;
                end;
            until TrackingSpecification.Next = 0;

        if not IsConsume and (SourceSpecification."Qty. to Invoice (Base)" <> 0) then
            CheckQtyToInvoiceMatchItemTracking(
              TempTrackingSpecSummedUp, TempInvoicingSpecification,
              SourceSpecification."Qty. to Invoice (Base)", SourceSpecification."Qty. per Unit of Measure");

        TempInvoicingSpecification.SetFilter("Qty. to Invoice (Base)", '<>0');
        if not TempInvoicingSpecification.FindFirst then
            TempInvoicingSpecification.Init;
    end;

    procedure RetrieveInvoiceSpecWithService(SourceSpecification: Record "Tracking Specification"; var TempInvoicingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    begin
        IsConsume := Consume;
        OK := RetrieveInvoiceSpecification(SourceSpecification, TempInvoicingSpecification);
    end;

    procedure RetrieveItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        exit(RetrieveItemTrackingFromReservEntry(ItemJnlLine, ReservEntry, TempHandlingSpecification));
    end;

    procedure RetrieveItemTrackingFromReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"; var TempTrackingSpec: Record "Tracking Specification" temporary): Boolean
    begin
        if ItemJnlLine.Subcontracting then
            exit(RetrieveSubcontrItemTracking(ItemJnlLine, TempTrackingSpec));

        ReservEntry.SetSourceFilter(
          DATABASE::"Item Journal Line", ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name", ItemJnlLine."Line No.", true);
        ReservEntry.SetSourceFilter(ItemJnlLine."Journal Batch Name", 0);
        OnAfterReserveEntryFilter(ItemJnlLine, ReservEntry);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        OnRetrieveItemTrackingFromReservEntryFilter(ReservEntry, ItemJnlLine);
        if SumUpItemTracking(ReservEntry, TempTrackingSpec, false, true) then begin
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            if not ReservEntry.IsEmpty then
                ReservEntry.DeleteAll;
            exit(true);
        end;
        exit(false);
    end;

    local procedure RetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsLastOperation: Boolean;
    begin
        if not ItemJnlLine.Subcontracting then
            exit(false);

        if ItemJnlLine."Operation No." = '' then
            exit(false);

        ItemJnlLine.TestField("Routing No.");
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        if not ProdOrderRoutingLine.Get(
             ProdOrderRoutingLine.Status::Released, ItemJnlLine."Order No.",
             ItemJnlLine."Routing Reference No.", ItemJnlLine."Routing No.", ItemJnlLine."Operation No.")
        then
            exit(false);

        IsLastOperation := ProdOrderRoutingLine."Next Operation No." = '';
        OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
        if not IsLastOperation then
            exit(false);

        ReservEntry.SetSourceFilter(DATABASE::"Prod. Order Line", 3, ItemJnlLine."Order No.", 0, true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if SumUpItemTracking(ReservEntry, TempHandlingSpecification, false, true) then begin
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            if not ReservEntry.IsEmpty then
                ReservEntry.DeleteAll;
            exit(true);
        end;
        exit(false);
    end;

    procedure RetrieveConsumpItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        ReservEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", 3, ItemJnlLine."Order No.", ItemJnlLine."Prod. Order Comp. Line No.", true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        ReservEntry.SetTrackingFilterFromItemJnlLine(ItemJnlLine);

        // Sum up in a temporary table per component line:
        exit(SumUpItemTracking(ReservEntry, TempHandlingSpecification, true, true));
    end;

    procedure SumUpItemTracking(var ReservEntry: Record "Reservation Entry"; var TempHandlingSpecification: Record "Tracking Specification" temporary; SumPerLine: Boolean; SumPerLotSN: Boolean): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        NextEntryNo: Integer;
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        // Sum up Item Tracking in a temporary table (to defragment the ReservEntry records)
        TempHandlingSpecification.Reset;
        TempHandlingSpecification.DeleteAll;
        if SumPerLotSN then
            TempHandlingSpecification.SetCurrentKey("Lot No.", "Serial No.");

        if ReservEntry.FindSet then begin
            GetItemTrackingCode(ReservEntry."Item No.", ItemTrackingCode);
            repeat
                if ReservEntry.TrackingExists then begin
                    if SumPerLine then
                        TempHandlingSpecification.SetRange("Source Ref. No.", ReservEntry."Source Ref. No."); // Sum up line per line
                    if SumPerLotSN then begin
                        TempHandlingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
                        if ReservEntry."New Serial No." <> '' then
                            TempHandlingSpecification.SetRange("New Serial No.", ReservEntry."New Serial No.");
                        if ReservEntry."New Lot No." <> '' then
                            TempHandlingSpecification.SetRange("New Lot No.", ReservEntry."New Lot No.");
                        if ReservEntry."New CD No." <> '' then
                            TempHandlingSpecification.SetRange("New CD No.", ReservEntry."New CD No.");
                    end;
                    OnBeforeFindTempHandlingSpecification(TempHandlingSpecification, ReservEntry);
                    if TempHandlingSpecification.FindFirst then begin
                        TempHandlingSpecification."Quantity (Base)" += ReservEntry."Quantity (Base)";
                        TempHandlingSpecification."Qty. to Handle (Base)" += ReservEntry."Qty. to Handle (Base)";
                        TempHandlingSpecification."Qty. to Invoice (Base)" += ReservEntry."Qty. to Invoice (Base)";
                        TempHandlingSpecification."Quantity Invoiced (Base)" += ReservEntry."Quantity Invoiced (Base)";
                        TempHandlingSpecification."Qty. to Handle" :=
                          TempHandlingSpecification."Qty. to Handle (Base)" /
                          ReservEntry."Qty. per Unit of Measure";
                        TempHandlingSpecification."Qty. to Invoice" :=
                          TempHandlingSpecification."Qty. to Invoice (Base)" /
                          ReservEntry."Qty. per Unit of Measure";
                        if ReservEntry."Reservation Status" > ReservEntry."Reservation Status"::Tracking then
                            TempHandlingSpecification."Buffer Value1" += // Late Binding
                              TempHandlingSpecification."Qty. to Handle (Base)";
                        TempHandlingSpecification.Modify;
                    end else begin
                        TempHandlingSpecification.Init;
                        TempHandlingSpecification.TransferFields(ReservEntry);
                        NextEntryNo += 1;
                        TempHandlingSpecification."Entry No." := NextEntryNo;
                        TempHandlingSpecification."Qty. to Handle" :=
                          TempHandlingSpecification."Qty. to Handle (Base)" /
                          ReservEntry."Qty. per Unit of Measure";
                        TempHandlingSpecification."Qty. to Invoice" :=
                          TempHandlingSpecification."Qty. to Invoice (Base)" /
                          ReservEntry."Qty. per Unit of Measure";
                        if ReservEntry."Reservation Status" > ReservEntry."Reservation Status"::Tracking then
                            TempHandlingSpecification."Buffer Value1" += // Late Binding
                              TempHandlingSpecification."Qty. to Handle (Base)";

                        if ItemTrackingCode."Use Expiration Dates" then begin
                            ExpDate :=
                              ExistingExpirationDate(
                                ReservEntry."Item No.", ReservEntry."Variant Code", ReservEntry."Lot No.",
                                ReservEntry."Serial No.", false, EntriesExist);
                            if EntriesExist then
                                TempHandlingSpecification."Expiration Date" := ExpDate;
                        end;
                        OnBeforeTempHandlingSpecificationInsert(TempHandlingSpecification, ReservEntry);
                        TempHandlingSpecification.Insert;
                    end;
                end;
            until ReservEntry.Next = 0;
        end;

        TempHandlingSpecification.Reset;
        exit(TempHandlingSpecification.FindFirst);
    end;

    procedure SumUpItemTrackingOnlyInventoryOrATO(var ReservationEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification"; SumPerLine: Boolean; SumPerLotSN: Boolean): Boolean
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        if ReservationEntry.FindSet then
            repeat
                if (ReservationEntry."Reservation Status" <> ReservationEntry."Reservation Status"::Reservation) or
                   IsResEntryReservedAgainstInventory(ReservationEntry)
                then begin
                    TempReservationEntry := ReservationEntry;
                    TempReservationEntry.Insert;
                end;
            until ReservationEntry.Next = 0;

        exit(SumUpItemTracking(TempReservationEntry, TrackingSpecification, SumPerLine, SumPerLotSN));
    end;

    local procedure IsResEntryReservedAgainstInventory(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        ReservationEntry2: Record "Reservation Entry";
    begin
        if (ReservationEntry."Reservation Status" <> ReservationEntry."Reservation Status"::Reservation) or
           ReservationEntry.Positive
        then
            exit(false);

        ReservationEntry2.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        if ReservationEntry2."Source Type" = DATABASE::"Item Ledger Entry" then
            exit(true);

        exit(IsResEntryReservedAgainstATO(ReservationEntry));
    end;

    local procedure IsResEntryReservedAgainstATO(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        ReservationEntry2: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        if (ReservationEntry."Source Type" <> DATABASE::"Sales Line") or
           (ReservationEntry."Source Subtype" <> SalesLine."Document Type"::Order) or
           (not SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.")) or
           (not AssembleToOrderLink.AsmExistsForSalesLine(SalesLine))
        then
            exit(false);

        ReservationEntry2.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        if (ReservationEntry2."Source Type" <> DATABASE::"Assembly Header") or
           (ReservationEntry2."Source Subtype" <> AssembleToOrderLink."Assembly Document Type") or
           (ReservationEntry2."Source ID" <> AssembleToOrderLink."Assembly Document No.")
        then
            exit(false);

        exit(true);
    end;

    procedure DecomposeRowID(IDtext: Text[250]; var StrArray: array[6] of Text[100])
    var
        Len: Integer;
        Pos: Integer;
        ArrayIndex: Integer;
        "Count": Integer;
        Char: Text[1];
        NoWriteSinceLastNext: Boolean;
        Write: Boolean;
        Next: Boolean;
    begin
        for ArrayIndex := 1 to 6 do
            StrArray[ArrayIndex] := '';
        Len := StrLen(IDtext);
        Pos := 1;
        ArrayIndex := 1;

        while not (Pos > Len) do begin
            Char := CopyStr(IDtext, Pos, 1);
            if Char = '"' then begin
                Write := false;
                Count += 1;
            end else begin
                if Count = 0 then
                    Write := true
                else begin
                    if Count mod 2 = 1 then begin
                        Next := (Char = ';');
                        Count -= 1;
                    end else
                        if NoWriteSinceLastNext and (Char = ';') then begin
                            Count -= 2;
                            Next := true;
                        end;
                    Count /= 2;
                    while Count > 0 do begin
                        StrArray[ArrayIndex] += '"';
                        Count -= 1;
                    end;
                    Write := not Next;
                end;
                NoWriteSinceLastNext := Next;
            end;

            if Next then begin
                ArrayIndex += 1;
                Next := false
            end;

            if Write then
                StrArray[ArrayIndex] += Char;
            Pos += 1;
        end;
    end;

    procedure ComposeRowID(Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer): Text[250]
    var
        StrArray: array[2] of Text[100];
        Pos: Integer;
        Len: Integer;
        T: Integer;
    begin
        StrArray[1] := ID;
        StrArray[2] := BatchName;
        for T := 1 to 2 do
            if StrPos(StrArray[T], '"') > 0 then begin
                Len := StrLen(StrArray[T]);
                Pos := 1;
                repeat
                    if CopyStr(StrArray[T], Pos, 1) = '"' then begin
                        StrArray[T] := InsStr(StrArray[T], '"', Pos + 1);
                        Len += 1;
                        Pos += 1;
                    end;
                    Pos += 1;
                until Pos > Len;
            end;
        exit(StrSubstNo('"%1";"%2";"%3";"%4";"%5";"%6"', Type, Subtype, StrArray[1], StrArray[2], ProdOrderLine, RefNo));
    end;

    procedure CopyItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; SwapSign: Boolean)
    begin
        CopyItemTracking(FromRowID, ToRowID, SwapSign, false);
    end;

    procedure CopyItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; SwapSign: Boolean; SkipReservation: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetPointer(FromRowID);
        ReservEntry.SetPointerFilter;
        CopyItemTracking3(ReservEntry, ToRowID, SwapSign, SkipReservation);
    end;

    local procedure CopyItemTracking3(var ReservEntry: Record "Reservation Entry"; ToRowID: Text[250]; SwapSign: Boolean; SkipReservation: Boolean)
    var
        ReservEntry1: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
    begin
        if SkipReservation then
            ReservEntry.SetFilter("Reservation Status", '<>%1', ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.FindSet then begin
            repeat
                if ReservEntry.TrackingExists then begin
                    TempReservEntry := ReservEntry;
                    TempReservEntry."Reservation Status" := TempReservEntry."Reservation Status"::Prospect;
                    TempReservEntry.SetPointer(ToRowID);
                    if SwapSign then begin
                        TempReservEntry."Quantity (Base)" := -TempReservEntry."Quantity (Base)";
                        TempReservEntry.Quantity := -TempReservEntry.Quantity;
                        TempReservEntry."Qty. to Handle (Base)" := -TempReservEntry."Qty. to Handle (Base)";
                        TempReservEntry."Qty. to Invoice (Base)" := -TempReservEntry."Qty. to Invoice (Base)";
                        TempReservEntry."Quantity Invoiced (Base)" := -TempReservEntry."Quantity Invoiced (Base)";
                        TempReservEntry.Positive := TempReservEntry."Quantity (Base)" > 0;
                        TempReservEntry.ClearApplFromToItemEntry;
                        OnCopyItemTracking3OnBeforeSwapSign(TempReservEntry);
                    end;
                    TempReservEntry.Insert;
                end;
            until ReservEntry.Next = 0;

            ModifyTemp337SetIfTransfer(TempReservEntry);

            if TempReservEntry.FindSet then begin
                ReservEntry1.Reset;
                repeat
                    ReservEntry1 := TempReservEntry;
                    ReservEntry1."Entry No." := 0;
                    ReservEntry1.Insert;
                until TempReservEntry.Next = 0;
            end;
        end;
    end;

    procedure CopyHandledItemTrkgToInvLine(FromSalesLine: Record "Sales Line"; ToSalesInvLine: Record "Sales Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        // Used for combined shipment/returns:
        if FromSalesLine.Type <> FromSalesLine.Type::Item then
            exit;

        case ToSalesInvLine."Document Type" of
            ToSalesInvLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      DATABASE::"Sales Shipment Line", 0, ToSalesInvLine."Shipment No.", ToSalesInvLine."Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            ToSalesInvLine."Document Type"::"Credit Memo":
                begin
                    ItemEntryRelation.SetSourceFilter(
                      DATABASE::"Return Receipt Line", 0, ToSalesInvLine."Return Receipt No.", ToSalesInvLine."Return Receipt Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToSalesInvLine.FieldError("Document Type", Format(ToSalesInvLine."Document Type"));
        end;

        InsertProspectReservEntryFromItemEntryRelationAndSourceData(
          ItemEntryRelation, ToSalesInvLine."Document Type", ToSalesInvLine."Document No.", ToSalesInvLine."Line No.");

        OnAfterCopyHandledItemTrkgToInvLine(FromSalesLine, ToSalesInvLine);
    end;

    procedure CopyHandledItemTrkgToInvLine(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line")
    begin
        CopyHandledItemTrkgToPurchLine(FromPurchLine, ToPurchLine, false);
    end;

    procedure CopyHandledItemTrkgToPurchLineWithLineQty(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line")
    begin
        CopyHandledItemTrkgToPurchLine(FromPurchLine, ToPurchLine, true);
    end;

    local procedure CopyHandledItemTrkgToPurchLine(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line"; CheckLineQty: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TrackingSpecification: Record "Tracking Specification";
        QtyBase: Decimal;
    begin
        // Used for combined receipts/returns:
        if FromPurchLine.Type <> FromPurchLine.Type::Item then
            exit;

        case ToPurchLine."Document Type" of
            ToPurchLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      DATABASE::"Purch. Rcpt. Line", 0, ToPurchLine."Receipt No.", ToPurchLine."Receipt Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            ToPurchLine."Document Type"::"Credit Memo":
                begin
                    ItemEntryRelation.SetSourceFilter(
                      DATABASE::"Return Shipment Line", 0, ToPurchLine."Return Shipment No.", ToPurchLine."Return Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToPurchLine.FieldError("Document Type", Format(ToPurchLine."Document Type"));
        end;

        if not ItemEntryRelation.FindSet then
            exit;

        repeat
            TrackingSpecification.Get(ItemEntryRelation."Item Entry No.");
            QtyBase := TrackingSpecification."Quantity (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
            if CheckLineQty and (QtyBase > ToPurchLine.Quantity) then
                QtyBase := ToPurchLine.Quantity;
            InsertReservEntryFromTrackingSpec(
              TrackingSpecification, ToPurchLine."Document Type", ToPurchLine."Document No.", ToPurchLine."Line No.", QtyBase);
        until ItemEntryRelation.Next = 0;
    end;

    procedure CopyHandledItemTrkgToServLine(FromServLine: Record "Service Line"; ToServLine: Record "Service Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        // Used for combined shipment/returns:
        if FromServLine.Type <> FromServLine.Type::Item then
            exit;

        case ToServLine."Document Type" of
            ToServLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      DATABASE::"Service Shipment Line", 0, ToServLine."Shipment No.", ToServLine."Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToServLine.FieldError("Document Type", Format(ToServLine."Document Type"));
        end;

        InsertProspectReservEntryFromItemEntryRelationAndSourceData(
          ItemEntryRelation, ToServLine."Document Type", ToServLine."Document No.", ToServLine."Line No.");
    end;

    procedure CollectItemEntryRelation(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; TotalQty: Decimal): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        Quantity: Decimal;
    begin
        Quantity := 0;
        TempItemLedgEntry.Reset;
        TempItemLedgEntry.DeleteAll;
        ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ItemEntryRelation.SetSourceFilter2(SourceBatchName, SourceProdOrderLine);
        if ItemEntryRelation.FindSet then
            repeat
                ItemLedgEntry.Get(ItemEntryRelation."Item Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert;
                Quantity := Quantity + ItemLedgEntry.Quantity;
            until ItemEntryRelation.Next = 0;
        exit(Quantity = TotalQty);
    end;

    procedure IsOrderNetworkEntity(Type: Integer; Subtype: Integer): Boolean
    var
        IsNetworkEntity: Boolean;
    begin
        case Type of
            DATABASE::"Sales Line":
                exit(Subtype in [1, 5]);
            DATABASE::"Purchase Line":
                exit(Subtype in [1, 5]);
            DATABASE::"Prod. Order Line":
                exit(Subtype in [2, 3]);
            DATABASE::"Prod. Order Component":
                exit(Subtype in [2, 3]);
            DATABASE::"Assembly Header":
                exit(Subtype in [1]);
            DATABASE::"Assembly Line":
                exit(Subtype in [1]);
            DATABASE::"Transfer Line":
                exit(true);
            DATABASE::"Service Line":
                exit(Subtype in [1]);
            else begin
                    OnIsOrderNetworkEntity(Type, Subtype, IsNetworkEntity);
                    exit(IsNetworkEntity);
                end;
        end;
    end;

    procedure DeleteItemEntryRelation(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; DeleteAllDocLines: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true);
        if DeleteAllDocLines then
            ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true)
        else
            ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ItemEntryRelation.SetSourceFilter2(SourceBatchName, SourceProdOrderLine);
        if not ItemEntryRelation.IsEmpty then
            ItemEntryRelation.DeleteAll;
    end;

    procedure DeleteValueEntryRelation(RowID: Text[100])
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        ValueEntryRelation.SetCurrentKey("Source RowId");
        ValueEntryRelation.SetRange("Source RowId", RowID);
        if not ValueEntryRelation.IsEmpty then
            ValueEntryRelation.DeleteAll;
    end;

    procedure FindInInventory(ItemNo: Code[20]; VariantCode: Code[20]; SerialNo: Code[50]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset;
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange(Positive, true);
        if SerialNo <> '' then
            ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        exit(ItemLedgerEntry.FindFirst);
    end;

    procedure SplitWhseJnlLine(TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary; var TempWhseSplitTrackingSpec: Record "Tracking Specification" temporary; ToTransfer: Boolean)
    var
        NonDistrQtyBase: Decimal;
        NonDistrCubage: Decimal;
        NonDistrWeight: Decimal;
        SplitFactor: Decimal;
        LineNo: Integer;
        WhseSNRequired: Boolean;
        WhseLNRequired: Boolean;
        WhseCDRequired: Boolean;
    begin
        TempWhseJnlLine2.DeleteAll;

        CheckWhseItemTrkgSetup(
          TempWhseJnlLine."Item No.", TempWhseJnlLine."Location Code", WhseSNRequired, WhseLNRequired, WhseCDRequired, false);

        OnSplitWhseJnlLineOnAfterCheckWhseItemTrkgSetup(TempWhseJnlLine, TempWhseSplitTrackingSpec, WhseSNRequired, WhseLNRequired);

        if not (WhseSNRequired or WhseLNRequired or WhseCDRequired) then begin
            TempWhseJnlLine2 := TempWhseJnlLine;
            TempWhseJnlLine2.Insert;
            OnAfterSplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2);
            exit;
        end;

        LineNo := TempWhseJnlLine."Line No.";
        with TempWhseSplitTrackingSpec do begin
            Reset;
            case TempWhseJnlLine."Source Type" of
                DATABASE::"Item Journal Line",
              DATABASE::"Job Journal Line":
                    SetSourceFilter(
                      TempWhseJnlLine."Source Type", -1, TempWhseJnlLine."Journal Template Name", TempWhseJnlLine."Source Line No.", true);
                0: // Whse. journal line
                    SetSourceFilter(
                      DATABASE::"Warehouse Journal Line", -1, TempWhseJnlLine."Journal Batch Name", TempWhseJnlLine."Line No.", true);
                else
                    SetSourceFilter(
                      TempWhseJnlLine."Source Type", -1, TempWhseJnlLine."Source No.", TempWhseJnlLine."Source Line No.", true);
            end;
            SetFilter("Quantity actual Handled (Base)", '<>%1', 0);
            NonDistrQtyBase := TempWhseJnlLine."Qty. (Absolute, Base)";
            NonDistrCubage := TempWhseJnlLine.Cubage;
            NonDistrWeight := TempWhseJnlLine.Weight;
            if FindSet then
                repeat
                    LineNo += 10000;
                    TempWhseJnlLine2 := TempWhseJnlLine;
                    TempWhseJnlLine2."Line No." := LineNo;

                    if "Serial No." <> '' then
                        if Abs("Quantity (Base)") <> 1 then
                            FieldError("Quantity (Base)");

                    if ToTransfer then begin
                        SetWhseSerialLotNo(TempWhseJnlLine2."Serial No.", "New Serial No.", WhseSNRequired);
                        SetWhseSerialLotNo(TempWhseJnlLine2."Lot No.", "New Lot No.", WhseLNRequired);
                        SetWhseSerialLotNo(TempWhseJnlLine2."CD No.", "New CD No.", WhseCDRequired);
                        if "New Expiration Date" <> 0D then
                            TempWhseJnlLine2."Expiration Date" := "New Expiration Date"
                    end else begin
                        SetWhseSerialLotNo(TempWhseJnlLine2."Serial No.", "Serial No.", WhseSNRequired);
                        SetWhseSerialLotNo(TempWhseJnlLine2."Lot No.", "Lot No.", WhseLNRequired);
                        SetWhseSerialLotNo(TempWhseJnlLine2."CD No.", "CD No.", WhseCDRequired);
                        TempWhseJnlLine2."Expiration Date" := "Expiration Date";
                    end;
                    SetWhseSerialLotNo(TempWhseJnlLine2."New Serial No.", "New Serial No.", WhseSNRequired);
                    SetWhseSerialLotNo(TempWhseJnlLine2."New Lot No.", "New Lot No.", WhseLNRequired);
                    SetWhseSerialLotNo(TempWhseJnlLine2."New CD No.", "New CD No.", WhseCDRequired);
                    TempWhseJnlLine2."New Expiration Date" := "New Expiration Date";
                    TempWhseJnlLine2."Warranty Date" := "Warranty Date";
                    TempWhseJnlLine2."Qty. (Absolute, Base)" := Abs("Quantity (Base)");
                    TempWhseJnlLine2."Qty. (Absolute)" :=
                      Round(
                        TempWhseJnlLine2."Qty. (Absolute, Base)" / TempWhseJnlLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    if TempWhseJnlLine.Quantity > 0 then begin
                        TempWhseJnlLine2."Qty. (Base)" := TempWhseJnlLine2."Qty. (Absolute, Base)";
                        TempWhseJnlLine2.Quantity := TempWhseJnlLine2."Qty. (Absolute)";
                    end else begin
                        TempWhseJnlLine2."Qty. (Base)" := -TempWhseJnlLine2."Qty. (Absolute, Base)";
                        TempWhseJnlLine2.Quantity := -TempWhseJnlLine2."Qty. (Absolute)";
                    end;
                    SplitFactor := "Quantity (Base)" / NonDistrQtyBase;
                    if SplitFactor < 1 then begin
                        TempWhseJnlLine2.Cubage := Round(NonDistrCubage * SplitFactor, UOMMgt.QtyRndPrecision);
                        TempWhseJnlLine2.Weight := Round(NonDistrWeight * SplitFactor, UOMMgt.QtyRndPrecision);
                        NonDistrQtyBase -= "Quantity (Base)";
                        NonDistrCubage -= TempWhseJnlLine2.Cubage;
                        NonDistrWeight -= TempWhseJnlLine2.Weight;
                    end else begin // the last record
                        TempWhseJnlLine2.Cubage := NonDistrCubage;
                        TempWhseJnlLine2.Weight := NonDistrWeight;
                    end;
                    OnBeforeTempWhseJnlLine2Insert(
                      TempWhseJnlLine2, TempWhseJnlLine, TempWhseSplitTrackingSpec, ToTransfer, WhseSNRequired, WhseLNRequired);
                    TempWhseJnlLine2.Insert;
                until Next = 0
            else begin
                TempWhseJnlLine2 := TempWhseJnlLine;
                OnBeforeTempWhseJnlLine2Insert(
                  TempWhseJnlLine2, TempWhseJnlLine, TempWhseSplitTrackingSpec, ToTransfer, false, false);
                TempWhseJnlLine2.Insert;
            end;
        end;

        OnAfterSplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2);
    end;

    procedure SplitPostedWhseRcptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    var
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        LineNo: Integer;
        WhseSNRequired: Boolean;
        WhseLNRequired: Boolean;
        WhseCDRequired: Boolean;
        CrossDockQty: Decimal;
        CrossDockQtyBase: Decimal;
    begin
        TempPostedWhseRcptLine.Reset;
        TempPostedWhseRcptLine.DeleteAll;

        CheckWhseItemTrkgSetup(
          PostedWhseRcptLine."Item No.", PostedWhseRcptLine."Location Code", WhseSNRequired, WhseLNRequired, WhseCDRequired, false);
        if not (WhseSNRequired or WhseLNRequired or WhseCDRequired) then begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert;
            OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
            exit;
        end;

        WhseItemEntryRelation.Reset;
        WhseItemEntryRelation.SetSourceFilter(
          DATABASE::"Posted Whse. Receipt Line", 0, PostedWhseRcptLine."No.", PostedWhseRcptLine."Line No.", true);
        if WhseItemEntryRelation.FindSet then begin
            repeat
                ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                TempPostedWhseRcptLine.SetRange("Serial No.", ItemLedgEntry."Serial No.");
                TempPostedWhseRcptLine.SetRange("Lot No.", ItemLedgEntry."Lot No.");
                TempPostedWhseRcptLine.SetRange("CD No.", ItemLedgEntry."CD No.");
                TempPostedWhseRcptLine.SetRange("Warranty Date", ItemLedgEntry."Warranty Date");
                TempPostedWhseRcptLine.SetRange("Expiration Date", ItemLedgEntry."Expiration Date");
                OnTempPostedWhseRcptLineSetFilters(TempPostedWhseRcptLine, ItemLedgEntry, WhseItemEntryRelation);
                if TempPostedWhseRcptLine.FindFirst then begin
                    TempPostedWhseRcptLine."Qty. (Base)" += ItemLedgEntry.Quantity;
                    TempPostedWhseRcptLine.Quantity :=
                      Round(
                        TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision);
                    OnBeforeModifySplitPostedWhseRcptLine(
                      TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemEntryRelation, ItemLedgEntry);
                    TempPostedWhseRcptLine.Modify;

                    CrossDockQty := CrossDockQty - TempPostedWhseRcptLine."Qty. Cross-Docked";
                    CrossDockQtyBase := CrossDockQtyBase - TempPostedWhseRcptLine."Qty. Cross-Docked (Base)";
                end else begin
                    LineNo += 10000;
                    TempPostedWhseRcptLine.Reset;
                    TempPostedWhseRcptLine := PostedWhseRcptLine;
                    TempPostedWhseRcptLine."Line No." := LineNo;
                    TempPostedWhseRcptLine.SetTracking(
                      WhseItemEntryRelation."Serial No.", WhseItemEntryRelation."Lot No.", WhseItemEntryRelation."CD No.",
                      ItemLedgEntry."Warranty Date", ItemLedgEntry."Expiration Date");
                    TempPostedWhseRcptLine."Qty. (Base)" := ItemLedgEntry.Quantity;
                    TempPostedWhseRcptLine.Quantity :=
                      Round(
                        TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision);
                    OnBeforeInsertSplitPostedWhseRcptLine(
                      TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemEntryRelation, ItemLedgEntry);
                    TempPostedWhseRcptLine.Insert;
                end;

                if WhseSNRequired then begin
                    if CrossDockQty < PostedWhseRcptLine."Qty. Cross-Docked" then begin
                        TempPostedWhseRcptLine."Qty. Cross-Docked" := TempPostedWhseRcptLine.Quantity;
                        TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := TempPostedWhseRcptLine."Qty. (Base)";
                    end else begin
                        TempPostedWhseRcptLine."Qty. Cross-Docked" := 0;
                        TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := 0;
                    end;
                    CrossDockQty := CrossDockQty + TempPostedWhseRcptLine.Quantity;
                end else
                    if PostedWhseRcptLine."Qty. Cross-Docked" > 0 then begin
                        if TempPostedWhseRcptLine.Quantity <=
                           PostedWhseRcptLine."Qty. Cross-Docked" - CrossDockQty
                        then begin
                            TempPostedWhseRcptLine."Qty. Cross-Docked" := TempPostedWhseRcptLine.Quantity;
                            TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := TempPostedWhseRcptLine."Qty. (Base)";
                        end else begin
                            TempPostedWhseRcptLine."Qty. Cross-Docked" := PostedWhseRcptLine."Qty. Cross-Docked" - CrossDockQty;
                            TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" :=
                              PostedWhseRcptLine."Qty. Cross-Docked (Base)" - CrossDockQtyBase;
                        end;
                        CrossDockQty := CrossDockQty + TempPostedWhseRcptLine."Qty. Cross-Docked";
                        CrossDockQtyBase := CrossDockQtyBase + TempPostedWhseRcptLine."Qty. Cross-Docked (Base)";
                        if CrossDockQty >= PostedWhseRcptLine."Qty. Cross-Docked" then begin
                            PostedWhseRcptLine."Qty. Cross-Docked" := 0;
                            PostedWhseRcptLine."Qty. Cross-Docked (Base)" := 0;
                        end;
                    end;
                TempPostedWhseRcptLine.Modify;
            until WhseItemEntryRelation.Next = 0;
        end else begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert;
        end;

        OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
    end;

    procedure SplitInternalPutAwayLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LineNo: Integer;
        WhseSNRequired: Boolean;
        WhseLNRequired: Boolean;
        WhseCDRequired: Boolean;
    begin
        TempPostedWhseRcptLine.DeleteAll;

        CheckWhseItemTrkgSetup(
          PostedWhseRcptLine."Item No.", PostedWhseRcptLine."Location Code", WhseSNRequired, WhseLNRequired, WhseCDRequired, false);
        if not (WhseSNRequired or WhseLNRequired or WhseCDRequired) then begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert;
            exit;
        end;

        WhseItemTrackingLine.Reset;
        WhseItemTrackingLine.SetSourceFilter(
          DATABASE::"Whse. Internal Put-away Line", 0, PostedWhseRcptLine."No.", PostedWhseRcptLine."Line No.", true);
        WhseItemTrackingLine.SetSourceFilter('', 0);
        WhseItemTrackingLine.SetFilter("Qty. to Handle (Base)", '<>0');
        if WhseItemTrackingLine.FindSet then
            repeat
                LineNo += 10000;
                TempPostedWhseRcptLine := PostedWhseRcptLine;
                TempPostedWhseRcptLine."Line No." := LineNo;
                TempPostedWhseRcptLine.SetTracking(
                  WhseItemTrackingLine."Serial No.", WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."CD No.",
                  WhseItemTrackingLine."Warranty Date", WhseItemTrackingLine."Expiration Date");
                TempPostedWhseRcptLine."Qty. (Base)" := WhseItemTrackingLine."Qty. to Handle (Base)";
                TempPostedWhseRcptLine.Quantity :=
                  Round(
                    TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                    UOMMgt.QtyRndPrecision);
                OnBeforeInsertSplitInternalPutAwayLine(TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemTrackingLine);
                TempPostedWhseRcptLine.Insert;
            until WhseItemTrackingLine.Next = 0
        else begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert;
        end
    end;

    procedure DeleteWhseItemTrkgLines(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; RelatedToLine: Boolean)
    begin
        DeleteWhseItemTrkgLinesWithRunDeleteTrigger(
          SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo, LocationCode, RelatedToLine, false);
    end;

    procedure DeleteWhseItemTrkgLinesWithRunDeleteTrigger(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; RelatedToLine: Boolean; RunDeleteTrigger: Boolean)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        with WhseItemTrkgLine do begin
            Reset;
            SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true);
            if RelatedToLine then begin
                SetSourceFilter(SourceBatchName, SourceProdOrderLine);
                SetRange("Source Ref. No.", SourceRefNo);
                SetRange("Location Code", LocationCode);
            end;

            if FindSet then
                repeat
                    // If the item tracking information was added through a pick registration, the reservation entry needs to
                    // be modified/deleted as well in order to remove this item tracking information again.
                    if DeleteReservationEntries and
                       "Created by Whse. Activity Line" and
                       ("Source Type" = DATABASE::"Warehouse Shipment Line")
                    then
                        RemoveItemTrkgFromReservEntry(WhseItemTrkgLine);
                    Delete(RunDeleteTrigger);
                until Next = 0;
        end;
    end;

    local procedure RemoveItemTrkgFromReservEntry(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        ReservEntry: Record "Reservation Entry";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WhseItemTrackingLine."Source ID");
        WarehouseShipmentLine.SetRange("Line No.", WhseItemTrackingLine."Source Ref. No.");
        if not WarehouseShipmentLine.FindFirst then
            exit;

        ReservEntry.SetSourceFilter(
          WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype",
          WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.", true);
        ReservEntry.SetTrackingFilterFromWhseSpec(WhseItemTrackingLine);
        if ReservEntry.FindSet then
            repeat
                case ReservEntry."Reservation Status" of
                    ReservEntry."Reservation Status"::Surplus:
                        ReservEntry.Delete(true);
                    else begin
                            ReservEntry.ClearItemTrackingFields;
                            ReservEntry.Modify(true);
                        end;
                end;
            until ReservEntry.Next = 0;
    end;

    procedure SetDeleteReservationEntries(DeleteEntries: Boolean)
    begin
        DeleteReservationEntries := DeleteEntries;
    end;

    procedure InitTrackingSpecification(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        WhseManagement: Codeunit "Whse. Management";
        SourceType: Integer;
    begin
        SourceType := WhseManagement.GetSourceType(WhseWkshLine);
        with WhseWkshLine do begin
            if "Whse. Document Type" = "Whse. Document Type"::Receipt then begin
                PostedWhseReceiptLine.SetRange("No.", "Whse. Document No.");
                PostedWhseReceiptLine.SetRange("Line No.", "Whse. Document Line No.");
                if PostedWhseReceiptLine.FindFirst then
                    InsertWhseItemTrkgLines(PostedWhseReceiptLine, SourceType);
            end;

            if SourceType = DATABASE::"Prod. Order Component" then begin
                WhseItemTrkgLine.SetSourceFilter(SourceType, "Source Subtype", "Source No.", "Source Subline No.", true);
                WhseItemTrkgLine.SetRange("Source Prod. Order Line", "Source Line No.");
            end else
                WhseItemTrkgLine.SetSourceFilter(SourceType, -1, "Whse. Document No.", "Whse. Document Line No.", true);

            WhseItemTrkgLine.LockTable;
            if WhseItemTrkgLine.FindSet then begin
                repeat
                    CalcWhseItemTrkgLine(WhseItemTrkgLine);
                    WhseItemTrkgLine.Modify;
                    if SourceType in [DATABASE::"Prod. Order Component", DATABASE::"Assembly Line"] then begin
                        TempWhseItemTrkgLine := WhseItemTrkgLine;
                        TempWhseItemTrkgLine.Insert;
                    end;
                until WhseItemTrkgLine.Next = 0;
                if not TempWhseItemTrkgLine.IsEmpty then
                    CheckWhseItemTrkg(TempWhseItemTrkgLine, WhseWkshLine);
            end else
                case SourceType of
                    DATABASE::"Posted Whse. Receipt Line":
                        CreateWhseItemTrkgForReceipt(WhseWkshLine);
                    DATABASE::"Warehouse Shipment Line":
                        CreateWhseItemTrkgBatch(WhseWkshLine);
                    DATABASE::"Prod. Order Component":
                        CreateWhseItemTrkgBatch(WhseWkshLine);
                    DATABASE::"Assembly Line":
                        CreateWhseItemTrkgBatch(WhseWkshLine);
                end;
        end;
    end;

    local procedure CreateWhseItemTrkgForReceipt(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        with WhseWkshLine do begin
            WhseItemTrackingLine.Reset;
            if WhseItemTrackingLine.FindLast then
                EntryNo := WhseItemTrackingLine."Entry No.";

            WhseItemEntryRelation.SetSourceFilter(
              DATABASE::"Posted Whse. Receipt Line", 0, "Whse. Document No.", "Whse. Document Line No.", true);
            if WhseItemEntryRelation.FindSet then
                repeat
                    WhseItemTrackingLine.Init;
                    EntryNo += 1;
                    WhseItemTrackingLine."Entry No." := EntryNo;
                    WhseItemTrackingLine."Item No." := "Item No.";
                    WhseItemTrackingLine."Variant Code" := "Variant Code";
                    WhseItemTrackingLine."Location Code" := "Location Code";
                    WhseItemTrackingLine.Description := Description;
                    WhseItemTrackingLine."Qty. per Unit of Measure" := "Qty. per From Unit of Measure";
                    WhseItemTrackingLine.SetSource(
                      DATABASE::"Posted Whse. Receipt Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                    ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                    WhseItemTrackingLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                    WhseItemTrackingLine."Quantity (Base)" := ItemLedgEntry.Quantity;
                    if "Qty. (Base)" = "Qty. to Handle (Base)" then
                        WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                    WhseItemTrackingLine."Qty. to Handle" :=
                      Round(
                        WhseItemTrackingLine."Qty. to Handle (Base)" / WhseItemTrackingLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision);
                    OnBeforeCreateWhseItemTrkgForReceipt(WhseItemTrackingLine, WhseWkshLine, ItemLedgEntry);
                    WhseItemTrackingLine.Insert;
                until WhseItemEntryRelation.Next = 0;
        end;
    end;

    local procedure CreateWhseItemTrkgBatch(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        SourceItemTrackingLine: Record "Reservation Entry";
        WhseManagement: Codeunit "Whse. Management";
        SourceType: Integer;
    begin
        SourceType := WhseManagement.GetSourceType(WhseWkshLine);

        with WhseWkshLine do begin
            case SourceType of
                DATABASE::"Prod. Order Component":
                    begin
                        SourceItemTrackingLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Subline No.", true);
                        SourceItemTrackingLine.SetSourceFilter('', "Source Line No.");
                    end;
                else begin
                        SourceItemTrackingLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", true);
                        SourceItemTrackingLine.SetSourceFilter('', 0);
                    end;
            end;
            if SourceItemTrackingLine.FindSet then
                repeat
                    CreateWhseItemTrkgForResEntry(SourceItemTrackingLine, WhseWkshLine);
                until SourceItemTrackingLine.Next = 0;
        end;
    end;

    procedure CreateWhseItemTrkgForResEntry(SourceReservEntry: Record "Reservation Entry"; WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseManagement: Codeunit "Whse. Management";
        EntryNo: Integer;
        SourceType: Integer;
    begin
        if not ((SourceReservEntry."Reservation Status" <> SourceReservEntry."Reservation Status"::Reservation) or
                IsResEntryReservedAgainstInventory(SourceReservEntry))
        then
            exit;

        if not SourceReservEntry.TrackingExists then
            exit;

        SourceType := WhseManagement.GetSourceType(WhseWkshLine);

        if WhseItemTrackingLine.FindLast then
            EntryNo := WhseItemTrackingLine."Entry No.";

        WhseItemTrackingLine.Init;

        with WhseWkshLine do
            case SourceType of
                DATABASE::"Posted Whse. Receipt Line":
                    WhseItemTrackingLine.SetSource(
                      DATABASE::"Posted Whse. Receipt Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                DATABASE::"Warehouse Shipment Line":
                    WhseItemTrackingLine.SetSource(
                      DATABASE::"Warehouse Shipment Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                DATABASE::"Assembly Line":
                    WhseItemTrackingLine.SetSource(
                      DATABASE::"Assembly Line", "Source Subtype", "Whse. Document No.", "Whse. Document Line No.", '', 0);
                DATABASE::"Prod. Order Component":
                    WhseItemTrackingLine.SetSource(
                      "Source Type", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.");
            end;

        WhseItemTrackingLine."Entry No." := EntryNo + 1;
        WhseItemTrackingLine."Item No." := SourceReservEntry."Item No.";
        WhseItemTrackingLine."Variant Code" := SourceReservEntry."Variant Code";
        WhseItemTrackingLine."Location Code" := SourceReservEntry."Location Code";
        WhseItemTrackingLine.Description := SourceReservEntry.Description;
        WhseItemTrackingLine."Qty. per Unit of Measure" := SourceReservEntry."Qty. per Unit of Measure";
        WhseItemTrackingLine.CopyTrackingFromReservEntry(SourceReservEntry);
        WhseItemTrackingLine."Quantity (Base)" := -SourceReservEntry."Quantity (Base)";

        if WhseWkshLine."Qty. Handled (Base)" <> 0 then begin
            WhseItemTrackingLine."Quantity Handled (Base)" := WhseWkshLine."Qty. Handled (Base)";
            WhseItemTrackingLine."Qty. Registered (Base)" := WhseWkshLine."Qty. Handled (Base)";
        end else
            if WhseWkshLine."Qty. (Base)" = WhseWkshLine."Qty. to Handle (Base)" then begin
                WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                WhseItemTrackingLine."Qty. to Handle" := -SourceReservEntry.Quantity;
            end;
        OnBeforeCreateWhseItemTrkgForResEntry(WhseItemTrackingLine, SourceReservEntry, WhseWkshLine);
        WhseItemTrackingLine.Insert;
    end;

    procedure CalcWhseItemTrkgLine(var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseActivQtyBase: Decimal;
    begin
        case WhseItemTrkgLine."Source Type" of
            DATABASE::"Posted Whse. Receipt Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Receipt;
            DATABASE::"Whse. Internal Put-away Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Internal Put-away";
            DATABASE::"Warehouse Shipment Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Shipment;
            DATABASE::"Whse. Internal Pick Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Internal Pick";
            DATABASE::"Prod. Order Component":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Production;
            DATABASE::"Assembly Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Assembly;
            DATABASE::"Whse. Worksheet Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Movement Worksheet";
        end;
        WhseItemTrkgLine.CalcFields("Put-away Qty. (Base)", "Pick Qty. (Base)");

        if WhseItemTrkgLine."Put-away Qty. (Base)" > 0 then
            WhseActivQtyBase := WhseItemTrkgLine."Put-away Qty. (Base)";
        if WhseItemTrkgLine."Pick Qty. (Base)" > 0 then
            WhseActivQtyBase := WhseItemTrkgLine."Pick Qty. (Base)";

        if not Registering then
            WhseItemTrkgLine.Validate("Quantity Handled (Base)",
              WhseActivQtyBase + WhseItemTrkgLine."Qty. Registered (Base)")
        else
            WhseItemTrkgLine.Validate("Quantity Handled (Base)",
              WhseItemTrkgLine."Qty. Registered (Base)");

        if WhseItemTrkgLine."Quantity (Base)" >= WhseItemTrkgLine."Quantity Handled (Base)" then
            WhseItemTrkgLine.Validate("Qty. to Handle (Base)",
              WhseItemTrkgLine."Quantity (Base)" - WhseItemTrkgLine."Quantity Handled (Base)");
    end;

    procedure InitItemTrkgForTempWkshLine(WhseDocType: Option; WhseDocNo: Code[20]; WhseDocLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    var
        TempWhseWkshLine: Record "Whse. Worksheet Line";
    begin
        InitWhseWkshLine(TempWhseWkshLine, WhseDocType, WhseDocNo, WhseDocLineNo, SourceType, SourceSubtype, SourceNo,
          SourceLineNo, SourceSublineNo);
        InitTrackingSpecification(TempWhseWkshLine);
    end;

    procedure InitWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line"; WhseDocType: Option; WhseDocNo: Code[20]; WhseDocLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        WhseWkshLine.Init;
        WhseWkshLine."Whse. Document Type" := WhseDocType;
        WhseWkshLine."Whse. Document No." := WhseDocNo;
        WhseWkshLine."Whse. Document Line No." := WhseDocLineNo;
        WhseWkshLine."Source Type" := SourceType;
        WhseWkshLine."Source Subtype" := SourceSubtype;
        WhseWkshLine."Source No." := SourceNo;
        WhseWkshLine."Source Line No." := SourceLineNo;
        WhseWkshLine."Source Subline No." := SourceSublineNo;

        if WhseDocType = WhseWkshLine."Whse. Document Type"::Production then begin
            ProdOrderComponent.Get(SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo);
            WhseWkshLine."Qty. Handled (Base)" := ProdOrderComponent."Qty. Picked (Base)";
        end;
    end;

    procedure UpdateWhseItemTrkgLines(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        if TempWhseItemTrkgLine.FindSet then
            repeat
                WhseItemTrkgLine.SetCurrentKey("Serial No.", "Lot No.");
                WhseItemTrkgLine.SetTrackingFilter(
                  TempWhseItemTrkgLine."Serial No.", TempWhseItemTrkgLine."Lot No.", TempWhseItemTrkgLine."CD No.");
                WhseItemTrkgLine.SetSourceFilter(
                  TempWhseItemTrkgLine."Source Type", TempWhseItemTrkgLine."Source Subtype", TempWhseItemTrkgLine."Source ID",
                  TempWhseItemTrkgLine."Source Ref. No.", false);
                WhseItemTrkgLine.SetSourceFilter(
                  TempWhseItemTrkgLine."Source Batch Name", TempWhseItemTrkgLine."Source Prod. Order Line");
                WhseItemTrkgLine.LockTable;
                if WhseItemTrkgLine.FindFirst then begin
                    CalcWhseItemTrkgLine(WhseItemTrkgLine);
                    WhseItemTrkgLine.Modify;
                end;
            until TempWhseItemTrkgLine.Next = 0
    end;

    local procedure InsertWhseItemTrkgLines(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        QtyHandledBase: Decimal;
        RemQtyHandledBase: Decimal;
    begin
        if WhseItemTrkgLine.FindLast then
            EntryNo := WhseItemTrkgLine."Entry No." + 1
        else
            EntryNo := 1;

        with PostedWhseReceiptLine do begin
            WhseItemEntryRelation.Reset;
            WhseItemEntryRelation.SetSourceFilter(SourceType, 0, "No.", "Line No.", true);
            if WhseItemEntryRelation.FindSet then begin
                WhseItemTrkgLine.SetSourceFilter(SourceType, 0, "No.", "Line No.", false);
                WhseItemTrkgLine.DeleteAll;
                WhseItemTrkgLine.Init;
                WhseItemTrkgLine.SetCurrentKey("Serial No.", "Lot No.");
                repeat
                    OnBeforeInsertWhseItemTrkgLinesLoop(PostedWhseReceiptLine, WhseItemEntryRelation, WhseItemTrkgLine);
                    WhseItemTrkgLine.SetTrackingFilterFromRelation(WhseItemEntryRelation);
                    ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                    if (WhseItemEntryRelation."Lot No." <> WhseItemTrkgLine."Lot No.") or
                       (WhseItemEntryRelation."Serial No." <> WhseItemTrkgLine."Serial No.") or
                       (WhseItemEntryRelation."CD No." <> WhseItemTrkgLine."CD No.")
                    then
                        RemQtyHandledBase := RegisteredPutAwayQtyBase(PostedWhseReceiptLine, WhseItemEntryRelation)
                    else
                        RemQtyHandledBase -= QtyHandledBase;
                    QtyHandledBase := RemQtyHandledBase;
                    if QtyHandledBase > ItemLedgEntry.Quantity then
                        QtyHandledBase := ItemLedgEntry.Quantity;

                    if not WhseItemTrkgLine.FindFirst then begin
                        WhseItemTrkgLine.Init;
                        WhseItemTrkgLine."Entry No." := EntryNo;
                        EntryNo := EntryNo + 1;

                        WhseItemTrkgLine."Item No." := ItemLedgEntry."Item No.";
                        WhseItemTrkgLine."Location Code" := ItemLedgEntry."Location Code";
                        WhseItemTrkgLine.Description := ItemLedgEntry.Description;
                        WhseItemTrkgLine.SetSource(
                          WhseItemEntryRelation."Source Type", WhseItemEntryRelation."Source Subtype", WhseItemEntryRelation."Source ID",
                          WhseItemEntryRelation."Source Ref. No.", WhseItemEntryRelation."Source Batch Name",
                          WhseItemEntryRelation."Source Prod. Order Line");
                        WhseItemTrkgLine.SetTracking(
                          WhseItemEntryRelation."Serial No.", WhseItemEntryRelation."Lot No.", WhseItemEntryRelation."CD No.",
                          ItemLedgEntry."Warranty Date", ItemLedgEntry."Expiration Date");
                        WhseItemTrkgLine."Qty. per Unit of Measure" := ItemLedgEntry."Qty. per Unit of Measure";
                        WhseItemTrkgLine."Quantity Handled (Base)" := QtyHandledBase;
                        WhseItemTrkgLine."Qty. Registered (Base)" := QtyHandledBase;
                        WhseItemTrkgLine.Validate("Quantity (Base)", ItemLedgEntry.Quantity);
                        OnBeforeInsertWhseItemTrkgLines(WhseItemTrkgLine, PostedWhseReceiptLine, WhseItemEntryRelation, ItemLedgEntry);
                        WhseItemTrkgLine.Insert;
                    end else begin
                        WhseItemTrkgLine."Quantity Handled (Base)" += QtyHandledBase;
                        WhseItemTrkgLine."Qty. Registered (Base)" += QtyHandledBase;
                        WhseItemTrkgLine.Validate("Quantity (Base)", WhseItemTrkgLine."Quantity (Base)" + ItemLedgEntry.Quantity);
                        OnBeforeModifyWhseItemTrkgLines(WhseItemTrkgLine, PostedWhseReceiptLine, WhseItemEntryRelation, ItemLedgEntry);
                        WhseItemTrkgLine.Modify;
                    end;
                    OnAfterInsertWhseItemTrkgLinesLoop(PostedWhseReceiptLine, WhseItemEntryRelation, WhseItemTrkgLine);
                until WhseItemEntryRelation.Next = 0;
            end;
        end;
    end;

    local procedure RegisteredPutAwayQtyBase(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        with PostedWhseReceiptLine do begin
            RegisteredWhseActivityLine.Reset;
            RegisteredWhseActivityLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", -1, true);
            RegisteredWhseActivityLine.SetTrackingFilterFromRelation(WhseItemEntryRelation);
            RegisteredWhseActivityLine.SetRange("Whse. Document No.", "No.");
            RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Take);
            RegisteredWhseActivityLine.CalcSums("Qty. (Base)");
        end;

        exit(RegisteredWhseActivityLine."Qty. (Base)");
    end;

    procedure ItemTrkgIsManagedByWhse(Type: Integer; Subtype: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]): Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        Location: Record Location;
        SNRequired: Boolean;
        LNRequired: Boolean;
        CDRequired: Boolean;
    begin
        if not (Type in [DATABASE::"Sales Line",
                         DATABASE::"Purchase Line",
                         DATABASE::"Transfer Line",
                         DATABASE::"Assembly Header",
                         DATABASE::"Assembly Line",
                         DATABASE::"Prod. Order Line",
                         DATABASE::"Service Line",
                         DATABASE::"Prod. Order Component"])
        then
            exit(false);

        if not (Location.RequirePicking(LocationCode) or Location.RequirePutaway(LocationCode)) then
            exit(false);

        CheckWhseItemTrkgSetup(ItemNo, LocationCode, SNRequired, LNRequired, CDRequired, false);
        if not (SNRequired or LNRequired or CDRequired) then
            exit(false);

        WhseShipmentLine.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        if not WhseShipmentLine.IsEmpty then
            exit(true);

        if Type in [DATABASE::"Prod. Order Component", DATABASE::"Prod. Order Line"] then begin
            WhseWkshLine.SetSourceFilter(Type, Subtype, ID, ProdOrderLine, true);
            WhseWkshLine.SetRange("Source Subline No.", RefNo);
        end else
            WhseWkshLine.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        if WhseWkshLine.FindFirst then
            if WhseWkshTemplate.Get(WhseWkshLine."Worksheet Template Name") then
                if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Pick then
                    exit(true);

        if Type in [DATABASE::"Prod. Order Component", DATABASE::"Prod. Order Line"] then
            WhseActivLine.SetSourceFilter(Type, Subtype, ID, ProdOrderLine, RefNo, true)
        else
            WhseActivLine.SetSourceFilter(Type, Subtype, ID, RefNo, 0, true);
        if WhseActivLine.FindFirst then
            if WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::Pick,
                                                 WhseActivLine."Activity Type"::"Invt. Put-away",
                                                 WhseActivLine."Activity Type"::"Invt. Pick"]
            then
                exit(true);

        exit(false);
    end;

    procedure CheckWhseItemTrkgSetup(ItemNo: Code[20]; LocationCode: Code[20]; var SNRequired: Boolean; var LNRequired: Boolean; var CDRequired: Boolean; ShowError: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        CDTrackingSetup: Record "CD Tracking Setup";
    begin
        SNRequired := false;
        LNRequired := false;
        CDRequired := false;
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
        if Item."Item Tracking Code" <> '' then begin
            if ItemTrackingCode.Code <> Item."Item Tracking Code" then
                ItemTrackingCode.Get(Item."Item Tracking Code");
            SNRequired := ItemTrackingCode."SN Warehouse Tracking";
            LNRequired := ItemTrackingCode."Lot Warehouse Tracking";
            CDRequired := ItemTrackingCode."CD Warehouse Tracking";
        end;
        if not (SNRequired or LNRequired or CDRequired) and ShowError then
            Error(Text005, Item.FieldCaption("No."), ItemNo);
    end;

    procedure SetGlobalParameters(SourceSpecification2: Record "Tracking Specification" temporary; var TempTrackingSpecification2: Record "Tracking Specification" temporary; DueDate2: Date)
    begin
        SourceSpecification := SourceSpecification2;
        DueDate := DueDate2;
        if TempTrackingSpecification2.FindSet then
            repeat
                TempTrackingSpecification := TempTrackingSpecification2;
                TempTrackingSpecification.Insert;
            until TempTrackingSpecification2.Next = 0;
    end;

    procedure AdjustQuantityRounding(NonDistrQuantity: Decimal; var QtyToBeHandled: Decimal; NonDistrQuantityBase: Decimal; QtyToBeHandledBase: Decimal)
    var
        FloatingFactor: Decimal;
    begin
        // Used by CU80/90 for handling rounding differences during invoicing

        FloatingFactor := QtyToBeHandledBase / NonDistrQuantityBase;

        if FloatingFactor < 1 then
            QtyToBeHandled := Round(FloatingFactor * NonDistrQuantity, UOMMgt.QtyRndPrecision)
        else
            QtyToBeHandled := NonDistrQuantity;
    end;

    procedure SynchronizeItemTrackingByPtrs(FromReservEntry: Record "Reservation Entry"; ToReservEntry: Record "Reservation Entry")
    var
        FromRowID: Text[250];
        ToRowID: Text[250];
    begin
        FromRowID := ComposeRowID(
            FromReservEntry."Source Type", FromReservEntry."Source Subtype", FromReservEntry."Source ID",
            FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.");
        ToRowID := ComposeRowID(
            ToReservEntry."Source Type", ToReservEntry."Source Subtype", ToReservEntry."Source ID",
            ToReservEntry."Source Batch Name", ToReservEntry."Source Prod. Order Line", ToReservEntry."Source Ref. No.");
        SynchronizeItemTracking(FromRowID, ToRowID, '');
    end;

    procedure SynchronizeItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; DialogText: Text[250])
    var
        ReservEntry1: Record "Reservation Entry";
    begin
        // Used for syncronizing between orders linked via Drop Shipment
        ReservEntry1.SetPointer(FromRowID);
        ReservEntry1.SetPointerFilter;
        SynchronizeItemTracking2(ReservEntry1, ToRowID, DialogText);

        OnAfterSynchronizeItemTracking(ReservEntry1, ToRowID);
    end;

    local procedure SynchronizeItemTracking2(var FromReservEntry: Record "Reservation Entry"; ToRowID: Text[250]; DialogText: Text[250])
    var
        ReservEntry2: Record "Reservation Entry";
        TempTrkgSpec1: Record "Tracking Specification" temporary;
        TempTrkgSpec2: Record "Tracking Specification" temporary;
        TempTrkgSpec3: Record "Tracking Specification" temporary;
        TempSourceSpec: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        ItemTrackingLines: Page "Item Tracking Lines";
        AvailabilityDate: Date;
        LastEntryNo: Integer;
        SignFactor1: Integer;
        SignFactor2: Integer;
        SecondSourceRowID: Text[250];
    begin
        // Used for synchronizing between orders linked via Drop Shipment and for
        // synchronizing between invt. pick/put-away and parent line.
        ReservEntry2.SetPointer(ToRowID);
        SignFactor1 := CreateReservEntry.SignFactor(FromReservEntry);
        SignFactor2 := CreateReservEntry.SignFactor(ReservEntry2);
        ReservEntry2.SetPointerFilter;

        if ReservEntry2.IsEmpty then begin
            if FromReservEntry.IsEmpty then
                exit;
            if DialogText <> '' then
                if not ConfirmManagement.GetResponseOrDefault(DialogText, true) then begin
                    Message(Text006);
                    exit;
                end;
            CopyItemTracking3(FromReservEntry, ToRowID, SignFactor1 <> SignFactor2, false);

            // Copy to inbound part of transfer.
            if IsReservedFromTransferShipment(FromReservEntry) then begin
                SecondSourceRowID :=
                  ItemTrackingMgt.ComposeRowID(FromReservEntry."Source Type",
                    1, FromReservEntry."Source ID",
                    FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line",
                    FromReservEntry."Source Ref. No.");
                if ToRowID <> SecondSourceRowID then // Avoid copying to the line itself
                    CopyItemTracking(ToRowID, SecondSourceRowID, true);
            end;
        end else begin
            if IsReservedFromTransferShipment(FromReservEntry) then
                SynchronizeItemTrkgTransfer(ReservEntry2);    // synchronize transfer

            if SumUpItemTracking(ReservEntry2, TempTrkgSpec2, false, true) then
                TempSourceSpec := TempTrkgSpec2 // TempSourceSpec is used for conveying source information to Form6510.
            else
                TempSourceSpec.TransferFields(ReservEntry2);

            if ReservEntry2."Quantity (Base)" > 0 then
                AvailabilityDate := ReservEntry2."Expected Receipt Date"
            else
                AvailabilityDate := ReservEntry2."Shipment Date";

            SumUpItemTracking(FromReservEntry, TempTrkgSpec1, false, true);

            TempTrkgSpec1.Reset;
            TempTrkgSpec2.Reset;
            TempTrkgSpec1.SetCurrentKey("Lot No.", "Serial No.");
            TempTrkgSpec2.SetCurrentKey("Lot No.", "Serial No.");
            if TempTrkgSpec1.FindSet then
                repeat
                    TempTrkgSpec2.SetTrackingFilterFromSpec(TempTrkgSpec1);
                    if TempTrkgSpec2.FindFirst then begin
                        if TempTrkgSpec2."Quantity (Base)" * SignFactor2 <> TempTrkgSpec1."Quantity (Base)" * SignFactor1 then begin
                            TempTrkgSpec3 := TempTrkgSpec2;
                            TempTrkgSpec3.Validate("Quantity (Base)",
                              (TempTrkgSpec1."Quantity (Base)" * SignFactor1 - TempTrkgSpec2."Quantity (Base)" * SignFactor2));
                            TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                            TempTrkgSpec3.Insert;
                        end;
                        TempTrkgSpec2.Delete;
                    end else begin
                        TempTrkgSpec3 := TempTrkgSpec1;
                        TempTrkgSpec3.Validate("Quantity (Base)", TempTrkgSpec1."Quantity (Base)" * SignFactor1);
                        TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                        TempTrkgSpec3.Insert;
                    end;
                    LastEntryNo := TempTrkgSpec3."Entry No.";
                    TempTrkgSpec1.Delete;
                until TempTrkgSpec1.Next = 0;

            TempTrkgSpec2.Reset;

            if TempTrkgSpec2.FindFirst then
                repeat
                    TempTrkgSpec3 := TempTrkgSpec2;
                    TempTrkgSpec3.Validate("Quantity (Base)", -TempTrkgSpec2."Quantity (Base)" * SignFactor2);
                    TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                    TempTrkgSpec3.Insert;
                    LastEntryNo := TempTrkgSpec3."Entry No.";
                until TempTrkgSpec2.Next = 0;

            TempTrkgSpec3.Reset;

            if not TempTrkgSpec3.IsEmpty then begin
                if DialogText <> '' then
                    if not ConfirmManagement.GetResponseOrDefault(DialogText, true) then begin
                        Message(Text006);
                        exit;
                    end;
                TempSourceSpec."Quantity (Base)" := ReservMgt.GetSourceRecordValue(ReservEntry2, false, 1);
                if TempTrkgSpec3."Source Type" = DATABASE::"Transfer Line" then begin
                    TempTrkgSpec3.ModifyAll("Location Code", ReservEntry2."Location Code");
                    ItemTrackingLines.SetFormRunMode(4);
                end else
                    if FromReservEntry."Source Type" <> ReservEntry2."Source Type" then // If different it is drop shipment
                        ItemTrackingLines.SetFormRunMode(3);
                ItemTrackingLines.RegisterItemTrackingLines(TempSourceSpec, AvailabilityDate, TempTrkgSpec3);
            end;
        end;

        OnAfterSynchronizeItemTracking2(FromReservEntry, ReservEntry2);
    end;

    procedure SetRegistering(Registering2: Boolean)
    begin
        Registering := Registering2;
    end;

    local procedure ModifyTemp337SetIfTransfer(var TempReservEntry: Record "Reservation Entry" temporary)
    var
        TransLine: Record "Transfer Line";
    begin
        if TempReservEntry."Source Type" = DATABASE::"Transfer Line" then begin
            TransLine.Get(TempReservEntry."Source ID", TempReservEntry."Source Ref. No.");
            TempReservEntry.ModifyAll("Reservation Status", TempReservEntry."Reservation Status"::Surplus);
            if TempReservEntry."Source Subtype" = 0 then begin
                TempReservEntry.ModifyAll("Location Code", TransLine."Transfer-from Code");
                TempReservEntry.ModifyAll("Expected Receipt Date", 0D);
                TempReservEntry.ModifyAll("Shipment Date", TransLine."Shipment Date");
            end else begin
                TempReservEntry.ModifyAll("Location Code", TransLine."Transfer-to Code");
                TempReservEntry.ModifyAll("Expected Receipt Date", TransLine."Receipt Date");
                TempReservEntry.ModifyAll("Shipment Date", 0D);
            end;
        end;
    end;

    procedure SynchronizeWhseItemTracking(var TempTrackingSpecification: Record "Tracking Specification" temporary; RegPickNo: Code[20]; Deletion: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        RegisteredWhseActLine: Record "Registered Whse. Activity Line";
        Qty: Decimal;
        ZeroQtyToHandle: Boolean;
    begin
        if TempTrackingSpecification.FindSet then
            repeat
                if TempTrackingSpecification.Correction then begin
                    if IsPick then begin
                        ZeroQtyToHandle := false;
                        Qty := -TempTrackingSpecification."Qty. to Handle (Base)";
                        if RegPickNo <> '' then begin
                            RegisteredWhseActLine.SetRange("Activity Type", RegisteredWhseActLine."Activity Type"::Pick);
                            RegisteredWhseActLine.SetSourceFilter(
                              TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype",
                              TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Ref. No.", -1, true);
                            RegisteredWhseActLine.SetTrackingFilterFromSpec(TempTrackingSpecification);
                            RegisteredWhseActLine.SetFilter("No.", '<> %1', RegPickNo);
                            if not RegisteredWhseActLine.FindFirst then
                                ZeroQtyToHandle := true
                            else
                                if RegisteredWhseActLine."Whse. Document Type" = RegisteredWhseActLine."Whse. Document Type"::Shipment then begin
                                    ZeroQtyToHandle := true;
                                    Qty := -(TempTrackingSpecification."Qty. to Handle (Base)" + CalcQtyBaseRegistered(RegisteredWhseActLine));
                                end;
                        end;

                        ReservEntry.SetSourceFilter(
                          TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype",
                          TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Ref. No.", true);
                        ReservEntry.SetSourceFilter('', TempTrackingSpecification."Source Prod. Order Line");
                        ReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        if ReservEntry.FindSet(true) then
                            repeat
                                if ZeroQtyToHandle then begin
                                    ReservEntry."Qty. to Handle (Base)" := 0;
                                    ReservEntry."Qty. to Invoice (Base)" := 0;
                                    ReservEntry.Modify;
                                end;
                            until ReservEntry.Next = 0;

                        if ReservEntry.FindSet(true) then
                            repeat
                                if RegPickNo <> '' then begin
                                    ReservEntry."Qty. to Handle (Base)" += Qty;
                                    ReservEntry."Qty. to Invoice (Base)" += Qty;
                                end else
                                    if not Deletion then begin
                                        ReservEntry."Qty. to Handle (Base)" := Qty;
                                        ReservEntry."Qty. to Invoice (Base)" := Qty;
                                    end;
                                if Abs(ReservEntry."Qty. to Handle (Base)") > Abs(ReservEntry."Quantity (Base)") then begin
                                    Qty := ReservEntry."Qty. to Handle (Base)" - ReservEntry."Quantity (Base)";
                                    ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
                                    ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
                                end else
                                    Qty := 0;
                                ReservEntry.Modify;

                                if IsReservedFromTransferShipment(ReservEntry) then
                                    UpdateItemTrackingInTransferReceipt(ReservEntry);
                            until (ReservEntry.Next = 0) or (Qty = 0);
                    end;
                    TempTrackingSpecification.Delete;
                end;
            until TempTrackingSpecification.Next = 0;

        RegisterNewItemTrackingLines(TempTrackingSpecification);
    end;

    local procedure CheckWhseItemTrkg(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line")
    var
        SourceReservEntry: Record "Reservation Entry";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
        Checked: Boolean;
    begin
        OnBeforeCheckWhseItemTrkg(TempWhseItemTrkgLine, WhseWkshLine, Checked);
        if Checked then
            exit;

        with WhseWkshLine do begin
            if WhseItemTrackingLine.FindLast then
                EntryNo := WhseItemTrackingLine."Entry No.";

            if "Source Type" = DATABASE::"Prod. Order Component" then begin
                SourceReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Subline No.", true);
                SourceReservEntry.SetSourceFilter('', "Source Line No.");
            end else begin
                SourceReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", true);
                SourceReservEntry.SetSourceFilter('', 0);
            end;
            if SourceReservEntry.FindSet then
                repeat
                    if SourceReservEntry.TrackingExists then begin
                        if "Source Type" = DATABASE::"Prod. Order Component" then begin
                            TempWhseItemTrkgLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Subline No.", true);
                            TempWhseItemTrkgLine.SetRange("Source Prod. Order Line", "Source Line No.");
                        end else begin
                            TempWhseItemTrkgLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", true);
                            TempWhseItemTrkgLine.SetRange("Source Prod. Order Line", 0);
                        end;
                        TempWhseItemTrkgLine.SetTrackingFilterFromReservEntry(SourceReservEntry);

                        if TempWhseItemTrkgLine.FindFirst then
                            TempWhseItemTrkgLine.Delete
                        else begin
                            WhseItemTrackingLine.Init;
                            EntryNo += 1;
                            WhseItemTrackingLine."Entry No." := EntryNo;
                            WhseItemTrackingLine."Item No." := SourceReservEntry."Item No.";
                            WhseItemTrackingLine."Variant Code" := SourceReservEntry."Variant Code";
                            WhseItemTrackingLine."Location Code" := SourceReservEntry."Location Code";
                            WhseItemTrackingLine.Description := SourceReservEntry.Description;
                            WhseItemTrackingLine."Qty. per Unit of Measure" := SourceReservEntry."Qty. per Unit of Measure";
                            if "Source Type" = DATABASE::"Prod. Order Component" then
                                WhseItemTrackingLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.")
                            else
                                WhseItemTrackingLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", '', 0);
                            WhseItemTrackingLine.CopyTrackingFromReservEntry(SourceReservEntry);
                            WhseItemTrackingLine."Quantity (Base)" := -SourceReservEntry."Quantity (Base)";
                            if "Qty. (Base)" = "Qty. to Handle (Base)" then
                                WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                            WhseItemTrackingLine."Qty. to Handle" :=
                              Round(
                                WhseItemTrackingLine."Qty. to Handle (Base)" / WhseItemTrackingLine."Qty. per Unit of Measure",
                                UOMMgt.QtyRndPrecision);
                            OnBeforeWhseItemTrackingLineInsert(WhseItemTrackingLine, SourceReservEntry);
                            WhseItemTrackingLine.Insert;
                        end;
                    end;
                until SourceReservEntry.Next = 0;

            TempWhseItemTrkgLine.Reset;
            if TempWhseItemTrkgLine.FindSet then
                repeat
                    if TempWhseItemTrkgLine.TrackingExists and (TempWhseItemTrkgLine."Quantity Handled (Base)" = 0) then begin
                        WhseItemTrackingLine.Get(TempWhseItemTrkgLine."Entry No.");
                        WhseItemTrackingLine.Delete;
                    end;
                until TempWhseItemTrkgLine.Next = 0;
        end;
    end;

    procedure CopyLotNoInformation(LotNoInfo: Record "Lot No. Information"; NewLotNo: Code[50])
    var
        NewLotNoInfo: Record "Lot No. Information";
        ConfirmManagement: Codeunit "Confirm Management";
        CommentType: Option " ","Serial No.","Lot No.";
    begin
        if NewLotNoInfo.Get(LotNoInfo."Item No.", LotNoInfo."Variant Code", NewLotNo) then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   text008, LotNoInfo.TableCaption, LotNoInfo.FieldCaption("Lot No."), NewLotNo), true)
            then
                Error('');
            NewLotNoInfo.TransferFields(LotNoInfo, false);
            NewLotNoInfo.Modify;
        end else begin
            NewLotNoInfo := LotNoInfo;
            NewLotNoInfo."Lot No." := NewLotNo;
            NewLotNoInfo.Insert;
        end;

        CopyInfoComment(
          CommentType::"Lot No.",
          LotNoInfo."Item No.",
          LotNoInfo."Variant Code",
          LotNoInfo."Lot No.",
          NewLotNo);
    end;

    procedure CopySerialNoInformation(SerialNoInfo: Record "Serial No. Information"; NewSerialNo: Code[50])
    var
        NewSerialNoInfo: Record "Serial No. Information";
        ConfirmManagement: Codeunit "Confirm Management";
        CommentType: Option " ","Serial No.","Lot No.";
    begin
        if NewSerialNoInfo.Get(SerialNoInfo."Item No.", SerialNoInfo."Variant Code", NewSerialNo) then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   text008, SerialNoInfo.TableCaption, SerialNoInfo.FieldCaption("Serial No."), NewSerialNo), true)
            then
                Error('');
            NewSerialNoInfo.TransferFields(SerialNoInfo, false);
            NewSerialNoInfo.Modify;
        end else begin
            NewSerialNoInfo := SerialNoInfo;
            NewSerialNoInfo."Serial No." := NewSerialNo;
            NewSerialNoInfo.Insert;
        end;

        CopyInfoComment(
          CommentType::"Serial No.",
          SerialNoInfo."Item No.",
          SerialNoInfo."Variant Code",
          SerialNoInfo."Serial No.",
          NewSerialNo);
    end;

    [Scope('OnPrem')]
    procedure CopyCDNoInformation(CDNoInfo: Record "CD No. Information"; NewCDNo: Code[20])
    var
        NewCDNoInfo: Record "CD No. Information";
        CommentType: Option " ","Serial No.","Lot No.";
    begin
        if NewCDNoInfo.Get(CDNoInfo.Type::Item, CDNoInfo."No.", CDNoInfo."Variant Code", NewCDNo) then begin
            if not Confirm(text008, false, CDNoInfo.TableCaption, CDNoInfo.FieldCaption("CD No."), NewCDNo) then
                Error('');
            NewCDNoInfo.TransferFields(CDNoInfo, false);
            NewCDNoInfo.Modify;
        end else begin
            NewCDNoInfo := CDNoInfo;
            NewCDNoInfo."CD No." := NewCDNo;
            NewCDNoInfo.Insert;
        end;

        CopyInfoComment(
          CommentType::"Serial No.",
          CDNoInfo."No.",
          CDNoInfo."Variant Code",
          CDNoInfo."CD No.",
          NewCDNo);
    end;

    local procedure CopyInfoComment(InfoType: Option " ","Serial No.","Lot No.","CD No."; ItemNo: Code[20]; VariantCode: Code[10]; SerialLotNo: Code[50]; NewSerialLotNo: Code[50])
    var
        ItemTrackingComment: Record "Item Tracking Comment";
        ItemTrackingComment1: Record "Item Tracking Comment";
    begin
        if SerialLotNo = NewSerialLotNo then
            exit;

        ItemTrackingComment1.SetRange(Type, InfoType);
        ItemTrackingComment1.SetRange("Item No.", ItemNo);
        ItemTrackingComment1.SetRange("Variant Code", VariantCode);
        ItemTrackingComment1.SetRange("Serial/Lot/CD No.", NewSerialLotNo);

        if not ItemTrackingComment1.IsEmpty then
            ItemTrackingComment1.DeleteAll;

        ItemTrackingComment.SetRange(Type, InfoType);
        ItemTrackingComment.SetRange("Item No.", ItemNo);
        ItemTrackingComment.SetRange("Variant Code", VariantCode);
        ItemTrackingComment.SetRange("Serial/Lot/CD No.", SerialLotNo);

        if ItemTrackingComment.IsEmpty then
            exit;

        if ItemTrackingComment.FindSet then begin
            repeat
                ItemTrackingComment1 := ItemTrackingComment;
                ItemTrackingComment1."Serial/Lot/CD No." := NewSerialLotNo;
                ItemTrackingComment1.Insert;
            until ItemTrackingComment.Next = 0
        end;
    end;

    procedure GetLotSNDataSet(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        ItemLedgEntry.Reset;
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.", "CD No.");

        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Variant Code", Variant);
        if LotNo <> '' then
            ItemLedgEntry.SetRange("Lot No.", LotNo)
        else
            if SerialNo <> '' then
                ItemLedgEntry.SetRange("Serial No.", SerialNo);
        if CDNo <> '' then
            ItemLedgEntry.SetRange("CD No.", CDNo);
        ItemLedgEntry.SetRange(Positive, true);

        exit(ItemLedgEntry.FindLast);
    end;

    procedure WhseItemTrackingLineExists(TemplateName: Code[10]; BatchName: Code[10]; LocationCode: Code[10]; LineNo: Integer; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Boolean
    begin
        with WhseItemTrackingLine do begin
            Reset;
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.", "Location Code");
            SetRange("Source Type", DATABASE::"Warehouse Journal Line");
            SetRange("Source Subtype", 0);
            SetRange("Source Batch Name", TemplateName);
            SetRange("Source ID", BatchName);
            SetRange("Location Code", LocationCode);
            if LineNo <> 0 then
                SetRange("Source Ref. No.", LineNo);
            SetRange("Source Prod. Order Line", 0);

            exit(not IsEmpty);
        end;
    end;

    procedure ExistingExpirationDate(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; TestMultiple: Boolean; var EntriesExist: Boolean) ExpDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTracingMgt: Codeunit "Item Tracing Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExistingExpirationDate(ItemNo, Variant, LotNo, SerialNo, TestMultiple, EntriesExist, ExpDate, IsHandled);
        if IsHandled then
            exit;

        if not GetLotSNDataSet(ItemNo, Variant, LotNo, SerialNo, '', ItemLedgEntry) then begin
            EntriesExist := false;
            exit;
        end;

        EntriesExist := true;
        ExpDate := ItemLedgEntry."Expiration Date";

        if TestMultiple and ItemTracingMgt.SpecificTracking(ItemNo, SerialNo, LotNo, '', '') then begin
            ItemLedgEntry.SetFilter("Expiration Date", '<>%1', ItemLedgEntry."Expiration Date");
            ItemLedgEntry.SetRange(Open, true);
            if not ItemLedgEntry.IsEmpty then
                Error(Text007, LotNo);
        end;
    end;

    procedure ExistingExpirationDateAndQty(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; var SumOfEntries: Decimal) ExpDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExistingExpirationDateAndQty(ItemNo, Variant, LotNo, SerialNo, SumOfEntries, ExpDate, IsHandled);
        if IsHandled then
            exit;

        SumOfEntries := 0;
        if not GetLotSNDataSet(ItemNo, Variant, LotNo, SerialNo, '', ItemLedgEntry) then
            exit;

        ExpDate := ItemLedgEntry."Expiration Date";
        if ItemLedgEntry.FindSet then
            repeat
                SumOfEntries += ItemLedgEntry."Remaining Quantity";
            until ItemLedgEntry.Next = 0;
    end;

    procedure ExistingWarrantyDate(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; var EntriesExist: Boolean) WarDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if not GetLotSNDataSet(ItemNo, Variant, LotNo, SerialNo, '', ItemLedgEntry) then
            exit;

        EntriesExist := true;
        WarDate := ItemLedgEntry."Warranty Date";
    end;

    procedure WhseExistingExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var EntriesExist: Boolean) ExpDate: Date
    var
        WhseEntry: Record "Warehouse Entry";
        SumOfEntries: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseExistingExpirationDate(ItemNo, VariantCode, Location, LotNo, SerialNo, EntriesExist, ExpDate, IsHandled);
        if IsHandled then
            exit;

        ExpDate := 0D;
        SumOfEntries := 0;

        if Location."Adjustment Bin Code" = '' then
            exit;

        with WhseEntry do begin
            Reset;
            SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", Location."Adjustment Bin Code");
            SetRange("Location Code", Location.Code);
            SetRange("Variant Code", VariantCode);
            if LotNo <> '' then
                SetRange("Lot No.", LotNo)
            else
                if SerialNo <> '' then
                    SetRange("Serial No.", SerialNo);
            if IsEmpty then
                exit;

            if FindSet then
                repeat
                    SumOfEntries += "Qty. (Base)";
                    if ("Expiration Date" <> 0D) and (("Expiration Date" < ExpDate) or (ExpDate = 0D)) then
                        ExpDate := "Expiration Date";
                until Next = 0;
        end;

        EntriesExist := SumOfEntries < 0;
    end;

    local procedure WhseExistingWarrantyDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var EntriesExist: Boolean) WarDate: Date
    var
        WhseEntry: Record "Warehouse Entry";
        SumOfEntries: Decimal;
    begin
        WarDate := 0D;
        SumOfEntries := 0;

        if Location."Adjustment Bin Code" = '' then
            exit;

        with WhseEntry do begin
            Reset;
            SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", Location."Adjustment Bin Code");
            SetRange("Location Code", Location.Code);
            SetRange("Variant Code", VariantCode);
            if LotNo <> '' then
                SetRange("Lot No.", LotNo)
            else
                if SerialNo <> '' then
                    SetRange("Serial No.", SerialNo);
            if IsEmpty then
                exit;

            if FindSet then
                repeat
                    SumOfEntries += "Qty. (Base)";
                    if ("Warranty Date" <> 0D) and (("Warranty Date" < WarDate) or (WarDate = 0D)) then
                        WarDate := "Warranty Date";
                until Next = 0;
        end;

        EntriesExist := SumOfEntries < 0;
    end;

    procedure GetWhseExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var ExpDate: Date): Boolean
    var
        EntriesExist: Boolean;
    begin
        ExpDate := ExistingExpirationDate(ItemNo, VariantCode, LotNo, SerialNo, false, EntriesExist);
        if EntriesExist then
            exit(true);

        ExpDate := WhseExistingExpirationDate(ItemNo, VariantCode, Location, LotNo, SerialNo, EntriesExist);
        if EntriesExist then
            exit(true);

        ExpDate := 0D;
        exit(false);
    end;

    procedure GetWhseWarrantyDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var Wardate: Date): Boolean
    var
        EntriesExist: Boolean;
    begin
        Wardate := ExistingWarrantyDate(ItemNo, VariantCode, LotNo, SerialNo, EntriesExist);
        if EntriesExist then
            exit(true);

        Wardate := WhseExistingWarrantyDate(ItemNo, VariantCode, Location, LotNo, SerialNo, EntriesExist);
        if EntriesExist then
            exit(true);

        Wardate := 0D;
        exit(false);
    end;

    procedure SumNewLotOnTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary): Decimal
    var
        TempTrackingSpecification2: Record "Tracking Specification";
        SumLot: Decimal;
    begin
        SumLot := 0;
        TempTrackingSpecification2 := TempTrackingSpecification;
        TempTrackingSpecification.SetRange("New Lot No.", TempTrackingSpecification."New Lot No.");
        if TempTrackingSpecification.FindSet then
            repeat
                SumLot += TempTrackingSpecification."Quantity (Base)";
            until TempTrackingSpecification.Next = 0;
        TempTrackingSpecification := TempTrackingSpecification2;
        exit(SumLot);
    end;

    procedure TestExpDateOnTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        if (TempTrackingSpecification."Lot No." = '') or (TempTrackingSpecification."Serial No." = '') then
            exit;
        TempTrackingSpecification.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
        TempTrackingSpecification.SetFilter("Expiration Date", '<>%1', TempTrackingSpecification."Expiration Date");
        if not TempTrackingSpecification.IsEmpty then
            Error(Text007, TempTrackingSpecification."Lot No.");
        TempTrackingSpecification.SetRange("Lot No.");
        TempTrackingSpecification.SetRange("Expiration Date");
    end;

    procedure TestExpDateOnTrackingSpecNew(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        if TempTrackingSpecification."New Lot No." = '' then
            exit;
        TempTrackingSpecification.SetRange("New Lot No.", TempTrackingSpecification."New Lot No.");
        TempTrackingSpecification.SetFilter("New Expiration Date", '<>%1', TempTrackingSpecification."New Expiration Date");
        if not TempTrackingSpecification.IsEmpty then
            Error(Text007, TempTrackingSpecification."New Lot No.");
        TempTrackingSpecification.SetRange("New Lot No.");
        TempTrackingSpecification.SetRange("New Expiration Date");
    end;

    procedure ItemTrackingOption(LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]) OptionValue: Integer
    var
        ReserveEntry: Record "Reservation Entry";
    begin
        if LotNo <> '' then
            OptionValue := ReserveEntry."Item Tracking"::"Lot No.";

        if SerialNo <> '' then begin
            if LotNo <> '' then
                OptionValue := ReserveEntry."Item Tracking"::"Lot and Serial No."
            else
                OptionValue := ReserveEntry."Item Tracking"::"Serial No.";
        end;

        if CDNo <> '' then
            case true of
                (LotNo = '') and (SerialNo = ''):
                    OptionValue := ReserveEntry."Item Tracking"::"CD No.";
                (LotNo <> '') and (SerialNo = ''):
                    OptionValue := ReserveEntry."Item Tracking"::"Lot and CD No.";
                (LotNo = '') and (SerialNo <> ''):
                    OptionValue := ReserveEntry."Item Tracking"::"Serial and CD No.";
                (LotNo <> '') and (SerialNo <> ''):
                    OptionValue := ReserveEntry."Item Tracking"::"Lot and Serial and CD No.";
            end;
    end;

    procedure CalcQtyBaseRegistered(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"): Decimal
    var
        RegisteredWhseActivityLineForCalcBaseQty: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLineForCalcBaseQty.CopyFilters(RegisteredWhseActivityLine);
        with RegisteredWhseActivityLineForCalcBaseQty do begin
            SetRange("Action Type", "Action Type"::Place);
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)");
        end;
    end;

    procedure CopyItemLedgEntryTrkgToSalesLn(var TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary; ToSalesLine: Record "Sales Line"; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; FromShptOrRcpt: Boolean)
    var
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        TotalCostLCY: Decimal;
        ItemLedgEntryQty: Decimal;
        QtyBase: Decimal;
        SignFactor: Integer;
        LinkThisEntry: Boolean;
        EntriesExist: Boolean;
    begin
        if (ToSalesLine.Type <> ToSalesLine.Type::Item) or (ToSalesLine.Quantity = 0) then
            exit;

        if FillExactCostRevLink then
            FillExactCostRevLink := not ToSalesLine.IsShipment;

        with TempItemLedgEntryBuf do
            if FindSet then begin
                if Quantity / ToSalesLine.Quantity < 0 then
                    SignFactor := 1
                else
                    SignFactor := -1;
                if ToSalesLine.IsCreditDocType then
                    SignFactor := -SignFactor;

                ReservMgt.SetSalesLine(ToSalesLine);
                ReservMgt.DeleteReservEntries(true, 0);

                repeat
                    LinkThisEntry := "Entry No." > 0;

                    if FillExactCostRevLink then
                        QtyBase := "Shipped Qty. Not Returned" * SignFactor
                    else
                        QtyBase := Quantity * SignFactor;

                    if FillExactCostRevLink then
                        if not LinkThisEntry then
                            MissingExCostRevLink := true
                        else
                            if not MissingExCostRevLink then begin
                                CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                                TotalCostLCY := TotalCostLCY + "Cost Amount (Expected)" + "Cost Amount (Actual)";
                                ItemLedgEntryQty := ItemLedgEntryQty - Quantity;
                            end;

                    InsertReservEntryForSalesLine(
                      ReservEntry, TempItemLedgEntryBuf, ToSalesLine, QtyBase, FillExactCostRevLink and LinkThisEntry, EntriesExist);

                    TempReservEntry := ReservEntry;
                    TempReservEntry.Insert;
                until Next = 0;
                ReservEngineMgt.UpdateOrderTracking(TempReservEntry);

                if FillExactCostRevLink and not MissingExCostRevLink then begin
                    ToSalesLine.Validate(
                      "Unit Cost (LCY)", Abs(TotalCostLCY / ItemLedgEntryQty) * ToSalesLine."Qty. per Unit of Measure");
                    if not FromShptOrRcpt then
                        CopyDocMgt.CalculateRevSalesLineAmount(ToSalesLine, ItemLedgEntryQty, FromPricesInclVAT, ToPricesInclVAT);
                    ToSalesLine.Modify;
                end;
            end;
    end;

    procedure CopyItemLedgEntryTrkgToPurchLn(var ItemLedgEntryBuf: Record "Item Ledger Entry"; ToPurchLine: Record "Purchase Line"; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; FromShptOrRcpt: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        TotalCostLCY: Decimal;
        ItemLedgEntryQty: Decimal;
        QtyBase: Decimal;
        SignFactor: Integer;
        LinkThisEntry: Boolean;
        EntriesExist: Boolean;
    begin
        if (ToPurchLine.Type <> ToPurchLine.Type::Item) or (ToPurchLine.Quantity = 0) then
            exit;

        if FillExactCostRevLink then
            FillExactCostRevLink := ToPurchLine.Signed(ToPurchLine."Quantity (Base)") < 0;

        if FillExactCostRevLink then
            if (ToPurchLine."Document Type" in [ToPurchLine."Document Type"::Invoice, ToPurchLine."Document Type"::"Credit Memo"]) and
               (ToPurchLine."Job No." <> '')
            then
                FillExactCostRevLink := false;

        with ItemLedgEntryBuf do
            if FindSet then begin
                if Quantity / ToPurchLine.Quantity > 0 then
                    SignFactor := 1
                else
                    SignFactor := -1;
                if ToPurchLine."Document Type" in
                   [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
                then
                    SignFactor := -SignFactor;

                if ToPurchLine."Expected Receipt Date" = 0D then
                    ToPurchLine."Expected Receipt Date" := WorkDate;
                ToPurchLine."Outstanding Qty. (Base)" := ToPurchLine."Quantity (Base)";
                ReservMgt.SetPurchLine(ToPurchLine);
                ReservMgt.DeleteReservEntries(true, 0);

                repeat
                    LinkThisEntry := "Entry No." > 0;

                    if FillExactCostRevLink then
                        if not LinkThisEntry then
                            MissingExCostRevLink := true
                        else
                            if not MissingExCostRevLink then begin
                                CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                                TotalCostLCY := TotalCostLCY + "Cost Amount (Expected)" + "Cost Amount (Actual)";
                                ItemLedgEntryQty := ItemLedgEntryQty - Quantity;
                            end;

                    if LinkThisEntry and ("Lot No." = '') then
                        // The check for Lot No = '' is to avoid changing the remaining quantity for partly sold Lots
                        // because this will cause undefined quantities in the item tracking
                        "Remaining Quantity" := Quantity;
                    if ToPurchLine."Job No." = '' then
                        QtyBase := "Remaining Quantity" * SignFactor
                    else begin
                        ItemLedgEntry.Get("Entry No.");
                        QtyBase := Abs(ItemLedgEntry.Quantity) * SignFactor;
                    end;

                    InsertReservEntryForPurchLine(
                      ItemLedgEntryBuf, ToPurchLine, QtyBase, FillExactCostRevLink and LinkThisEntry, EntriesExist);
                until Next = 0;

                if FillExactCostRevLink and not MissingExCostRevLink then begin
                    ToPurchLine.Validate(
                      "Unit Cost (LCY)",
                      Abs(TotalCostLCY / ItemLedgEntryQty) * ToPurchLine."Qty. per Unit of Measure");
                    if not FromShptOrRcpt then
                        CopyDocMgt.CalculateRevPurchLineAmount(
                          ToPurchLine, ItemLedgEntryQty, FromPricesInclVAT, ToPricesInclVAT);

                    ToPurchLine.Modify;
                end;
            end;
    end;

    procedure CopyItemLedgEntryTrkgToTransferLine(var ItemLedgEntryBuf: Record "Item Ledger Entry"; ToTransferLine: Record "Transfer Line")
    var
        QtyBase: Decimal;
        SignFactor: Integer;
        EntriesExist: Boolean;
    begin
        if ToTransferLine.Quantity = 0 then
            exit;

        SignFactor := -1;

        with ItemLedgEntryBuf do
            if FindSet then
                repeat
                    QtyBase := "Remaining Quantity" * SignFactor;
                    InsertReservEntryForTransferLine(ItemLedgEntryBuf, ToTransferLine, QtyBase, EntriesExist);
                until Next = 0;
    end;

    procedure SynchronizeWhseActivItemTrkg(WhseActivLine: Record "Warehouse Activity Line")
    var
        TempTrackingSpec: Record "Tracking Specification" temporary;
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        ReservEntryBindingCheck: Record "Reservation Entry";
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text[250];
        IsTransferReceipt: Boolean;
        IsATOPosting: Boolean;
        IsBindingOrderToOrder: Boolean;
    begin
        // Used for carrying the item tracking from the invt. pick/put-away to the parent line.
        with WhseActivLine do begin
            Reset;
            SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true);
            SetRange("Assemble to Order", "Assemble to Order");
            if FindSet then begin
                // Transfer receipt needs special treatment:
                IsTransferReceipt := ("Source Type" = DATABASE::"Transfer Line") and ("Source Subtype" = 1);
                IsATOPosting := ("Source Type" = DATABASE::"Sales Line") and "Assemble to Order";
                if ("Source Type" in [DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component"]) or IsTransferReceipt then
                    ToRowID :=
                      ItemTrackingMgt.ComposeRowID(
                        "Source Type", "Source Subtype", "Source No.", '', "Source Line No.", "Source Subline No.")
                else begin
                    if IsATOPosting then begin
                        ATOSalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
                        ATOSalesLine.AsmToOrderExists(AsmHeader);
                        ToRowID :=
                          ItemTrackingMgt.ComposeRowID(
                            DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0);
                    end else
                        ToRowID :=
                          ItemTrackingMgt.ComposeRowID(
                            "Source Type", "Source Subtype", "Source No.", '', "Source Subline No.", "Source Line No.");
                end;
                OnSynchronizeWhseActivItemTrkgOnAfterSetToRowID(WhseActivLine, ToRowID);
                TempReservEntry.SetPointer(ToRowID);
                SignFactor := WhseActivitySignFactor(WhseActivLine);
                ReservEntryBindingCheck.SetPointer(ToRowID);
                ReservEntryBindingCheck.SetPointerFilter;
                repeat
                    if TrackingExists then begin
                        TempReservEntry."Entry No." += 1;
                        TempReservEntry.Positive := SignFactor > 0;
                        TempReservEntry."Item No." := "Item No.";
                        TempReservEntry."Location Code" := "Location Code";
                        TempReservEntry.Description := Description;
                        TempReservEntry."Variant Code" := "Variant Code";
                        TempReservEntry."Quantity (Base)" := "Qty. Outstanding (Base)" * SignFactor;
                        TempReservEntry.Quantity := "Qty. Outstanding" * SignFactor;
                        TempReservEntry."Qty. to Handle (Base)" := "Qty. to Handle (Base)" * SignFactor;
                        TempReservEntry."Qty. to Invoice (Base)" := "Qty. to Handle (Base)" * SignFactor;
                        TempReservEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                        TempReservEntry."Lot No." := "Lot No.";
                        TempReservEntry."Serial No." := "Serial No.";
                        TempReservEntry."CD No." := "CD No.";
                        TempReservEntry."Expiration Date" := "Expiration Date";
                        OnSyncActivItemTrkgOnBeforeInsertTempReservEntry(TempReservEntry, WhseActivLine);
                        TempReservEntry.Insert;

                        if not IsBindingOrderToOrder then begin
                            ReservEntryBindingCheck.SetTrackingFilter("Serial No.", "Lot No.", "CD No.");
                            ReservEntryBindingCheck.SetRange(Binding, ReservEntryBindingCheck.Binding::"Order-to-Order");
                            IsBindingOrderToOrder := not ReservEntryBindingCheck.IsEmpty;
                        end;
                    end;
                until Next = 0;

                if TempReservEntry.IsEmpty then
                    exit;
            end;
        end;

        SumUpItemTracking(TempReservEntry, TempTrackingSpec, false, true);

        if TempTrackingSpec.FindSet then
            repeat
                ReservEntry.SetSourceFilter(
                  TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype",
                  TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", true);
                ReservEntry.SetSourceFilter('', TempTrackingSpec."Source Prod. Order Line");
                ReservEntry.SetTrackingFilterFromSpec(TempTrackingSpec);
                if IsTransferReceipt then
                    ReservEntry.SetRange("Source Ref. No.");
                if ReservEntry.FindSet then begin
                    repeat
                        if Abs(TempTrackingSpec."Qty. to Handle (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Handle (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Handle (Base)", TempTrackingSpec."Qty. to Handle (Base)");

                        if Abs(TempTrackingSpec."Qty. to Invoice (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Invoice (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Invoice (Base)", TempTrackingSpec."Qty. to Invoice (Base)");

                        TempTrackingSpec."Qty. to Handle (Base)" -= ReservEntry."Qty. to Handle (Base)";
                        TempTrackingSpec."Qty. to Invoice (Base)" -= ReservEntry."Qty. to Invoice (Base)";
                        OnSyncActivItemTrkgOnBeforeTempTrackingSpecModify(TempTrackingSpec, ReservEntry);
                        TempTrackingSpec.Modify;

                        with WhseActivLine do begin
                            Reset;
                            SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true);
                            SetTrackingFilter(ReservEntry."Serial No.", ReservEntry."Lot No.", ReservEntry."CD No.");
                            if FindFirst then
                                ReservEntry."Expiration Date" := "Expiration Date";
                            OnSynchronizeWhseActivItemTrkgOnAfterSetExpirationDate(WhseActivLine, ReservEntry);
                        end;

                        ReservEntry.Modify;

                        if IsReservedFromTransferShipment(ReservEntry) then
                            UpdateItemTrackingInTransferReceipt(ReservEntry);
                    until ReservEntry.Next = 0;

                    if (TempTrackingSpec."Qty. to Handle (Base)" = 0) and (TempTrackingSpec."Qty. to Invoice (Base)" = 0) then
                        TempTrackingSpec.Delete
                    else
                        Error(CannotMatchItemTrackingErr);
                end;
            until TempTrackingSpec.Next = 0;

        if TempTrackingSpec.FindSet then
            repeat
                TempTrackingSpec."Quantity (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                TempTrackingSpec."Qty. to Handle (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                TempTrackingSpec."Qty. to Invoice (Base)" := Abs(TempTrackingSpec."Qty. to Invoice (Base)");
                TempTrackingSpec.Modify;
            until TempTrackingSpec.Next = 0;

        RegisterNewItemTrackingLines(TempTrackingSpec);
    end;

    local procedure RegisterNewItemTrackingLines(var TempTrackingSpec: Record "Tracking Specification" temporary)
    var
        TrackingSpec: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        OnBeforeRegisterNewItemTrackingLines(TempTrackingSpec);

        if TempTrackingSpec.FindSet then
            repeat
                TempTrackingSpec.SetSourceFilter(
                  TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype",
                  TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", false);
                TempTrackingSpec.SetRange("Source Prod. Order Line", TempTrackingSpec."Source Prod. Order Line");

                TrackingSpec := TempTrackingSpec;
                TempTrackingSpec.CalcSums("Qty. to Handle (Base)");

                TrackingSpec."Quantity (Base)" :=
                  TempTrackingSpec."Qty. to Handle (Base)" + Abs(ItemTrkgQtyPostedOnSource(TrackingSpec));

                OnBeforeRegisterItemTrackingLinesLoop(TrackingSpec, TempTrackingSpec);

                Clear(ItemTrackingLines);
                ItemTrackingLines.SetCalledFromSynchWhseItemTrkg(true);
                ItemTrackingLines.RegisterItemTrackingLines(TrackingSpec, TrackingSpec."Creation Date", TempTrackingSpec);
                TempTrackingSpec.ClearSourceFilter;
            until TempTrackingSpec.Next = 0;
    end;

    local procedure WhseActivitySignFactor(WhseActivityLine: Record "Warehouse Activity Line"): Integer
    begin
        if WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Invt. Pick" then begin
            if WhseActivityLine."Assemble to Order" then
                exit(1);
            exit(-1);
        end;
        if WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Invt. Put-away" then
            exit(1);

        Error(Text011, WhseActivityLine.FieldCaption("Activity Type"), WhseActivityLine."Activity Type");
    end;

    procedure RetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        OnBeforeRetrieveAppliedExpirationDate(TempItemLedgEntry);

        with TempItemLedgEntry do begin
            if Positive then
                exit;

            ItemApplnEntry.Reset;
            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", "Entry No.");
            ItemApplnEntry.SetRange("Item Ledger Entry No.", "Entry No.");
            if ItemApplnEntry.FindFirst then begin
                ItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
                "Expiration Date" := ItemLedgEntry."Expiration Date";
            end;
        end;

        OnAfterRetrieveAppliedExpirationDate(TempItemLedgEntry, ItemApplnEntry);
    end;

    local procedure ItemTrkgQtyPostedOnSource(SourceTrackingSpec: Record "Tracking Specification") Qty: Decimal
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TransferLine: Record "Transfer Line";
    begin
        with SourceTrackingSpec do begin
            TrackingSpecification.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
            TrackingSpecification.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
            if not TrackingSpecification.IsEmpty then begin
                TrackingSpecification.FindSet;
                repeat
                    Qty += TrackingSpecification."Quantity (Base)";
                until TrackingSpecification.Next = 0;
            end;

            ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", false);
            ReservEntry.SetSourceFilter('', "Source Prod. Order Line");
            if not ReservEntry.IsEmpty then begin
                ReservEntry.FindSet;
                repeat
                    Qty += ReservEntry."Qty. to Handle (Base)";
                until ReservEntry.Next = 0;
            end;
            if "Source Type" = DATABASE::"Transfer Line" then begin
                TransferLine.Get("Source ID", "Source Ref. No.");
                Qty -= TransferLine."Qty. Shipped (Base)";
            end;
        end;
    end;

    local procedure UpdateItemTrackingInTransferReceipt(FromReservEntry: Record "Reservation Entry")
    var
        ToReservEntry: Record "Reservation Entry";
        ToRowID: Text[250];
    begin
        ToRowID := ComposeRowID(
            DATABASE::"Transfer Line", 1, FromReservEntry."Source ID",
            FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.");
        ToReservEntry.SetPointer(ToRowID);
        ToReservEntry.SetPointerFilter;
        SynchronizeItemTrkgTransfer(ToReservEntry);
    end;

    local procedure SynchronizeItemTrkgTransfer(var ReservEntry: Record "Reservation Entry")
    var
        FromReservEntry: Record "Reservation Entry";
        ToReservEntry: Record "Reservation Entry";
        TempToReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        FromReservEntry.Copy(ReservEntry);
        FromReservEntry.SetRange("Source Subtype", 0);

        ToReservEntry.Copy(ReservEntry);
        ToReservEntry.SetRange("Source Subtype", 1);
        if ToReservEntry.FindSet then
            repeat
                TempToReservEntry := ToReservEntry;
                TempToReservEntry."Qty. to Handle (Base)" := 0;
                TempToReservEntry."Qty. to Invoice (Base)" := 0;
                TempToReservEntry.Insert;
            until ToReservEntry.Next = 0;
        if TempToReservEntry.IsEmpty then
            exit;

        SumUpItemTracking(FromReservEntry, TempTrackingSpecification, false, true);
        TempTrackingSpecification.Reset;
        TempTrackingSpecification.SetFilter("Qty. to Handle (Base)", '<%1', 0);
        if TempTrackingSpecification.FindSet then
            repeat
                ToReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                ToReservEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                ToReservEntry.ModifyAll("Qty. to Handle (Base)", 0);
                ToReservEntry.ModifyAll("Qty. to Invoice (Base)", 0);

                TempTrackingSpecification."Qty. to Handle (Base)" *= -1;

                TempToReservEntry.SetCurrentKey(
                  "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.");
                TempToReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                TempToReservEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                if TempToReservEntry.FindSet then
                    repeat
                        if TempToReservEntry."Quantity (Base)" < TempTrackingSpecification."Qty. to Handle (Base)" then begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Quantity (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" -= TempToReservEntry."Quantity (Base)";
                            TempToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Quantity (Base)";
                        end else begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                            TempToReservEntry."Qty. to Invoice (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                        end;

                        ToReservEntry.Get(TempToReservEntry."Entry No.", TempToReservEntry.Positive);
                        ToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry.Modify;
                    until (TempToReservEntry.Next = 0) or (TempTrackingSpecification."Qty. to Handle (Base)" = 0);
                ReservEntry.Get(ToReservEntry."Entry No.", ToReservEntry.Positive);

            until TempTrackingSpecification.Next = 0;
    end;

    procedure InitCollectItemTrkgInformation()
    begin
        TempGlobalWhseItemTrkgLine.DeleteAll;
    end;

    procedure CollectItemTrkgInfWhseJnlLine(WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        with WhseItemTrackingLine do begin
            SetSourceFilter(
              DATABASE::"Warehouse Journal Line", -1, WhseJnlLine."Journal Batch Name", WhseJnlLine."Line No.", true);
            SetSourceFilter(WhseJnlLine."Journal Template Name", -1);
            SetRange("Location Code", WhseJnlLine."Location Code");
            SetRange("Item No.", WhseJnlLine."Item No.");
            SetRange("Variant Code", WhseJnlLine."Variant Code");
            SetRange("Qty. per Unit of Measure", WhseJnlLine."Qty. per Unit of Measure");
            if FindSet then
                repeat
                    Clear(TempGlobalWhseItemTrkgLine);
                    TempGlobalWhseItemTrkgLine := WhseItemTrackingLine;
                    if TempGlobalWhseItemTrkgLine.Insert then;
                until Next = 0;
        end;
    end;

    procedure CheckItemTrkgInfBeforePost()
    var
        TempLotNoInfo: Record "Lot No. Information" temporary;
        CheckExpDate: Date;
        ErrorFound: Boolean;
        EndLoop: Boolean;
        ErrMsgTxt: Text[160];
    begin
        // Check for different expiration dates within one Lot no.
        if TempGlobalWhseItemTrkgLine.Find('-') then begin
            TempLotNoInfo.DeleteAll;
            repeat
                if TempGlobalWhseItemTrkgLine."New Lot No." <> '' then begin
                    Clear(TempLotNoInfo);
                    TempLotNoInfo."Item No." := TempGlobalWhseItemTrkgLine."Item No.";
                    TempLotNoInfo."Variant Code" := TempGlobalWhseItemTrkgLine."Variant Code";
                    TempLotNoInfo."Lot No." := TempGlobalWhseItemTrkgLine."New Lot No.";
                    OnCheckItemTrkgInfBeforePostOnBeforeTempItemLotInfoInsert(TempLotNoInfo, TempGlobalWhseItemTrkgLine);
                    if TempLotNoInfo.Insert then;
                end;
            until TempGlobalWhseItemTrkgLine.Next = 0;

            if TempLotNoInfo.Find('-') then
                repeat
                    ErrorFound := false;
                    EndLoop := false;
                    if TempGlobalWhseItemTrkgLine.Find('-') then begin
                        CheckExpDate := 0D;
                        repeat
                            if (TempGlobalWhseItemTrkgLine."Item No." = TempLotNoInfo."Item No.") and
                               (TempGlobalWhseItemTrkgLine."Variant Code" = TempLotNoInfo."Variant Code") and
                               (TempGlobalWhseItemTrkgLine."New Lot No." = TempLotNoInfo."Lot No.")
                            then
                                if CheckExpDate = 0D then
                                    CheckExpDate := TempGlobalWhseItemTrkgLine."New Expiration Date"
                                else
                                    if TempGlobalWhseItemTrkgLine."New Expiration Date" <> CheckExpDate then begin
                                        ErrorFound := true;
                                        ErrMsgTxt :=
                                          StrSubstNo(Text012,
                                            TempGlobalWhseItemTrkgLine."Lot No.",
                                            TempGlobalWhseItemTrkgLine."New Expiration Date",
                                            CheckExpDate);
                                    end;
                            if not ErrorFound then
                                if TempGlobalWhseItemTrkgLine.Next = 0 then
                                    EndLoop := true;
                        until EndLoop or ErrorFound;
                    end;
                until (TempLotNoInfo.Next = 0) or ErrorFound;
            if ErrorFound then
                Error(ErrMsgTxt);
        end;
    end;

    procedure SetPick(IsPick2: Boolean)
    begin
        IsPick := IsPick2;
    end;

    procedure StrictExpirationPosting(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);
        if Item."Item Tracking Code" = '' then
            exit(false);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        exit(ItemTrackingCode."Strict Expiration Posting");
    end;

    procedure WhseItemTrkgLineExists(SourceId: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; SerialNo: Code[50]; LotNo: Code[50]): Boolean
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        with WhseItemTrkgLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceId, SourceRefNo, true);
            SetSourceFilter(SourceBatchName, SourceProdOrderLine);
            SetRange("Location Code", LocationCode);
            if SerialNo <> '' then
                SetRange("Serial No.", SerialNo);
            if LotNo <> '' then
                SetRange("Lot No.", LotNo);
            exit(not IsEmpty);
        end;
    end;

    local procedure SetWhseSerialLotNo(var DestNo: Code[50]; SourceNo: Code[50]; NoRequired: Boolean)
    begin
        if NoRequired then
            DestNo := SourceNo;
    end;

    local procedure InsertProspectReservEntryFromItemEntryRelationAndSourceData(var ItemEntryRelation: Record "Item Entry Relation"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyBase: Decimal;
    begin
        if not ItemEntryRelation.FindSet then
            exit;

        repeat
            TrackingSpecification.Get(ItemEntryRelation."Item Entry No.");
            QtyBase := TrackingSpecification."Quantity (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
            InsertReservEntryFromTrackingSpec(
              TrackingSpecification, SourceSubtype, SourceID, SourceRefNo, QtyBase);
        until ItemEntryRelation.Next = 0;
    end;

    procedure UpdateQuantities(WhseWorksheetLine: Record "Whse. Worksheet Line"; var TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; var SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal; SourceType: Integer): Boolean
    begin
        SourceQuantityArray[1] := Abs(WhseWorksheetLine."Qty. (Base)");
        SourceQuantityArray[2] := Abs(WhseWorksheetLine."Qty. to Handle (Base)");
        exit(CalculateSums(WhseWorksheetLine, TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray, SourceType));
    end;

    procedure CalculateSums(WhseWorksheetLine: Record "Whse. Worksheet Line"; var TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal; SourceType: Integer): Boolean
    begin
        with TotalWhseItemTrackingLine do begin
            SetRange("Location Code", WhseWorksheetLine."Location Code");
            case SourceType of
                DATABASE::"Posted Whse. Receipt Line",
              DATABASE::"Warehouse Shipment Line",
              DATABASE::"Whse. Internal Put-away Line",
              DATABASE::"Whse. Internal Pick Line",
              DATABASE::"Assembly Line",
              DATABASE::"Internal Movement Line":
                    SetSourceFilter(
                      SourceType, -1, WhseWorksheetLine."Whse. Document No.", WhseWorksheetLine."Whse. Document Line No.", true);
                DATABASE::"Prod. Order Component":
                    begin
                        SetSourceFilter(
                          SourceType, WhseWorksheetLine."Source Subtype", WhseWorksheetLine."Source No.", WhseWorksheetLine."Source Subline No.",
                          true);
                        SetRange("Source Prod. Order Line", WhseWorksheetLine."Source Line No.");
                    end;
                DATABASE::"Whse. Worksheet Line",
                DATABASE::"Warehouse Journal Line":
                    begin
                        SetSourceFilter(SourceType, -1, WhseWorksheetLine.Name, WhseWorksheetLine."Line No.", true);
                        SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
                    end;
            end;
            CalcSums("Quantity (Base)", "Qty. to Handle (Base)");
        end;
        exit(UpdateUndefinedQty(TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray));
    end;

    procedure UpdateUndefinedQty(TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal): Boolean
    begin
        UndefinedQtyArray[1] := SourceQuantityArray[1] - TotalWhseItemTrackingLine."Quantity (Base)";
        UndefinedQtyArray[2] := SourceQuantityArray[2] - TotalWhseItemTrackingLine."Qty. to Handle (Base)";
        exit(not (Abs(SourceQuantityArray[1]) < Abs(TotalWhseItemTrackingLine."Quantity (Base)")));
    end;

    local procedure InsertReservEntryForSalesLine(var ReservEntry: Record "Reservation Entry"; ItemLedgEntryBuf: Record "Item Ledger Entry"; SalesLine: Record "Sales Line"; QtyBase: Decimal; AppliedFromItemEntry: Boolean; var EntriesExist: Boolean)
    begin
        if QtyBase = 0 then
            exit;

        with ReservEntry do begin
            InitReservEntry(ReservEntry, ItemLedgEntryBuf, QtyBase, SalesLine."Shipment Date", EntriesExist);
            SetSource(
              DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", '', 0);
            if SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::"Return Order"] then
                "Reservation Status" := "Reservation Status"::Surplus
            else
                "Reservation Status" := "Reservation Status"::Prospect;
            if AppliedFromItemEntry then
                "Appl.-from Item Entry" := ItemLedgEntryBuf."Entry No.";
            Description := SalesLine.Description;
            OnCopyItemLedgEntryTrkgToDocLine(ItemLedgEntryBuf, ReservEntry);
            UpdateItemTracking;
            OnBeforeInsertReservEntryForSalesLine(ReservEntry, SalesLine);
            Insert;
        end;
    end;

    local procedure InsertReservEntryForPurchLine(ItemLedgEntryBuf: Record "Item Ledger Entry"; PurchaseLine: Record "Purchase Line"; QtyBase: Decimal; AppliedToItemEntry: Boolean; var EntriesExist: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if QtyBase = 0 then
            exit;

        with ReservEntry do begin
            InitReservEntry(ReservEntry, ItemLedgEntryBuf, QtyBase, PurchaseLine."Expected Receipt Date", EntriesExist);
            SetSource(DATABASE::"Purchase Line", PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.", '', 0);
            if PurchaseLine."Document Type" in [PurchaseLine."Document Type"::Order, PurchaseLine."Document Type"::"Return Order"] then
                "Reservation Status" := "Reservation Status"::Surplus
            else
                "Reservation Status" := "Reservation Status"::Prospect;
            if AppliedToItemEntry then
                "Appl.-to Item Entry" := ItemLedgEntryBuf."Entry No.";
            Description := PurchaseLine.Description;
            OnCopyItemLedgEntryTrkgToDocLine(ItemLedgEntryBuf, ReservEntry);
            UpdateItemTracking;
            OnBeforeInsertReservEntryForPurchLine(ReservEntry, PurchaseLine);
            Insert;
        end;
    end;

    local procedure InsertReservEntryForTransferLine(ItemLedgEntryBuf: Record "Item Ledger Entry"; TransferLine: Record "Transfer Line"; QtyBase: Decimal; var EntriesExist: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        ToReservEntry: Record "Reservation Entry";
    begin
        if not ItemLedgEntryBuf.TrackingExists or (QtyBase = 0) then
            exit;

        with ReservEntry do begin
            InitReservEntry(ReservEntry, ItemLedgEntryBuf, QtyBase, TransferLine."Shipment Date", EntriesExist);
            SetSource(DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", '', 0);
            "Reservation Status" := "Reservation Status"::Surplus;
            Description := TransferLine.Description;
            UpdateItemTracking;
            Insert;
        end;

        // push item tracking to the inbound transfer
        ToReservEntry := ReservEntry;
        ToReservEntry."Source Subtype" := 1;
        SynchronizeItemTrackingByPtrs(ReservEntry, ToReservEntry);
    end;

    local procedure InsertReservEntryFromTrackingSpec(TrackingSpecification: Record "Tracking Specification"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; QtyBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if QtyBase = 0 then
            exit;

        with ReservEntry do begin
            Init;
            TransferFields(TrackingSpecification);
            "Source Subtype" := SourceSubtype;
            "Source ID" := SourceID;
            "Source Ref. No." := SourceRefNo;
            "Reservation Status" := "Reservation Status"::Prospect;
            "Quantity Invoiced (Base)" := 0;
            Validate("Quantity (Base)", QtyBase);
            Positive := ("Quantity (Base)" > 0);
            "Entry No." := 0;
            "Item Tracking" := ItemTrackingOption("Lot No.", "Serial No.", "CD No.");
            Insert;
        end;
    end;

    local procedure InitReservEntry(var ReservEntry: Record "Reservation Entry"; ItemLedgEntryBuf: Record "Item Ledger Entry"; QtyBase: Decimal; Date: Date; var EntriesExist: Boolean)
    begin
        with ReservEntry do begin
            Init;
            "Item No." := ItemLedgEntryBuf."Item No.";
            "Location Code" := ItemLedgEntryBuf."Location Code";
            "Variant Code" := ItemLedgEntryBuf."Variant Code";
            "Qty. per Unit of Measure" := ItemLedgEntryBuf."Qty. per Unit of Measure";
            CopyTrackingFromItemLedgEntry(ItemLedgEntryBuf);
            "Quantity Invoiced (Base)" := 0;
            Validate("Quantity (Base)", QtyBase);
            Positive := ("Quantity (Base)" > 0);
            "Entry No." := 0;
            if Positive then begin
                "Warranty Date" := ItemLedgEntryBuf."Warranty Date";
                "Expiration Date" :=
                  ExistingExpirationDate("Item No.", "Variant Code", "Lot No.", "Serial No.", false, EntriesExist);
                "Expected Receipt Date" := Date;
            end else
                "Shipment Date" := Date;
            "Creation Date" := WorkDate;
            "Created By" := UserId;
        end;

        OnAfterInitReservEntry(ReservEntry, ItemLedgEntryBuf);
    end;

    procedure DeleteInvoiceSpecFromHeader(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, false);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.DeleteAll;
    end;

    procedure DeleteInvoiceSpecFromLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, false);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.DeleteAll;
    end;

    local procedure IsReservedFromTransferShipment(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservEntry."Source Type" = DATABASE::"Transfer Line") and (ReservEntry."Source Subtype" = 0));
    end;

    procedure ItemTrackingExistsOnDocumentLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.SetRange(Correction, false);
        ReservEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);

        exit(not TrackingSpecification.IsEmpty or not ReservEntry.IsEmpty);
    end;

    procedure CalcQtyToHandleForTrackedQtyOnDocumentLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        ReservEntry.CalcSums("Qty. to Handle (Base)");
        exit(ReservEntry."Qty. to Handle (Base)");
    end;

    local procedure CheckQtyToInvoiceMatchItemTracking(var TempTrackingSpecSummedUp: Record "Tracking Specification" temporary; var TempTrackingSpecNotInvoiced: Record "Tracking Specification" temporary; QtyToInvoiceOnDocLine: Decimal; QtyPerUoM: Decimal)
    var
        NoOfLotsOrSerials: Integer;
        Sign: Integer;
        QtyToInvOnLineAndTrkgDiff: Decimal;
    begin
        TempTrackingSpecSummedUp.Reset;
        TempTrackingSpecSummedUp.SetFilter("Qty. to Invoice (Base)", '<>%1', 0);
        NoOfLotsOrSerials := TempTrackingSpecSummedUp.Count;
        if NoOfLotsOrSerials = 0 then
            exit;

        TempTrackingSpecSummedUp.CalcSums("Qty. to Invoice (Base)");
        QtyToInvOnLineAndTrkgDiff := Abs(QtyToInvoiceOnDocLine) - Abs(TempTrackingSpecSummedUp."Qty. to Invoice (Base)");
        if QtyToInvOnLineAndTrkgDiff = 0 then
            exit;

        if ((NoOfLotsOrSerials > 1) and (QtyToInvOnLineAndTrkgDiff <> 0)) or
           ((NoOfLotsOrSerials = 1) and (QtyToInvOnLineAndTrkgDiff > 0))
        then
            Error(QtyToInvoiceDoesNotMatchItemTrackingErr);

        if TempTrackingSpecNotInvoiced.IsEmpty then
            exit;

        if NoOfLotsOrSerials = 1 then begin
            QtyToInvoiceOnDocLine := Abs(QtyToInvoiceOnDocLine);
            TempTrackingSpecNotInvoiced.CalcSums("Qty. to Invoice (Base)");
            if QtyToInvoiceOnDocLine < Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)") then begin
                TempTrackingSpecNotInvoiced.FindSet;
                repeat
                    if QtyToInvoiceOnDocLine >= Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)") then
                        QtyToInvoiceOnDocLine -= Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)")
                    else begin
                        Sign := 1;
                        if TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" < 0 then
                            Sign := -1;

                        TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" := QtyToInvoiceOnDocLine * Sign;
                        TempTrackingSpecNotInvoiced."Qty. to Invoice" :=
                          Round(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" / QtyPerUoM, UOMMgt.QtyRndPrecision);
                        TempTrackingSpecNotInvoiced.Modify;

                        QtyToInvoiceOnDocLine := 0;
                    end;
                until TempTrackingSpecNotInvoiced.Next = 0;
            end;
        end;
    end;

    local procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        if CachedItem."No." <> ItemNo then begin
            // searching for a new item, clear the cached item
            Clear(CachedItem);

            // get the item from the database
            if CachedItem.Get(ItemNo) then begin
                if CachedItem."Item Tracking Code" <> CachedItemTrackingCode.Code then
                    Clear(CachedItemTrackingCode); // item tracking code changed, clear the cached tracking code

                if CachedItem."Item Tracking Code" <> '' then
                    // item tracking code changed to something not empty, so get the new item tracking code from the database
                    CachedItemTrackingCode.Get(CachedItem."Item Tracking Code");
            end else
                Clear(CachedItemTrackingCode); // can't find the item, so clear the cached tracking code as well
        end;

        ItemTrackingCode := CachedItemTrackingCode;
    end;

    [Scope('OnPrem')]
    procedure CopyExpirationDateForLot(var TrackingSpecification: Record "Tracking Specification")
    var
        CurrTrackingSpec: Record "Tracking Specification";
    begin
        with TrackingSpecification do begin
            if "Lot No." = '' then
                exit;

            CurrTrackingSpec.Copy(TrackingSpecification);

            SetFilter("Entry No.", '<>%1', "Entry No.");
            SetRange("Item No.", "Item No.");
            SetRange("Variant Code", "Variant Code");
            SetRange("Lot No.", "Lot No.");
            SetRange("Buffer Status", 0);
            if FindFirst then
                CurrTrackingSpec."Expiration Date" := "Expiration Date";

            Copy(CurrTrackingSpec);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateExpirationDateForLot(var TrackingSpecification: Record "Tracking Specification")
    var
        CurrTrackingSpec: Record "Tracking Specification";
    begin
        with TrackingSpecification do begin
            if "Lot No." = '' then
                exit;

            CurrTrackingSpec.Copy(TrackingSpecification);

            SetFilter("Entry No.", '<>%1', "Entry No.");
            SetRange("Item No.", "Item No.");
            SetRange("Variant Code", "Variant Code");
            SetRange("Lot No.", "Lot No.");
            SetFilter("Expiration Date", '<>%1', "Expiration Date");
            SetRange("Buffer Status", 0);
            ModifyAll("Expiration Date", CurrTrackingSpec."Expiration Date");

            Copy(CurrTrackingSpec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyHandledItemTrkgToInvLine(FromSalesLine: Record "Sales Line"; var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseItemTrkgLinesLoop(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSynchronizeItemTracking(var ReservationEntry: Record "Reservation Entry"; ToRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseItemTrkg(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary; WhseWkshLine: Record "Whse. Worksheet Line"; var Checked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrkgForReceipt(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrkgForResEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceReservEntry: Record "Reservation Entry"; WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExistingExpirationDate(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; TestMultiple: Boolean; var EntriesExist: Boolean; var ExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExistingExpirationDateAndQty(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; SumOfEntries: Decimal; var ExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTempHandlingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReservEntryForPurchLine(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReservEntryForSalesLine(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSplitPostedWhseRcptLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSplitInternalPutAwayLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySplitPostedWhseRcptLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterNewItemTrackingLines(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecSummedUpModify(var TempTrackingSpecSummedUp: Record "Tracking Specification" temporary; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseJnlLine2Insert(var TempWhseJnlLineTo: Record "Warehouse Journal Line" temporary; TempWhseJnlLineFrom: Record "Warehouse Journal Line" temporary; var TempSplitTrackingSpec: Record "Tracking Specification" temporary; TransferTo: Boolean; WhseSNRequired: Boolean; WhseLNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempHandlingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseExistingExpirationDate(ItemNo: Code[20]; Variant: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var EntriesExist: Boolean; var ExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncActivItemTrkgOnBeforeInsertTempReservEntry(var TempReservEntry: Record "Reservation Entry" temporary; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncActivItemTrkgOnBeforeTempTrackingSpecModify(var TrackingSpecification: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseItemTrkgLines(var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyWhseItemTrkgLines(var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterItemTrackingLinesLoop(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseItemTrkgLinesLoop(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemTracking3OnBeforeSwapSign(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrkgInfBeforePostOnBeforeTempItemLotInfoInsert(var TempLotNoInfo: Record "Lot No. Information" temporary; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemLedgEntryTrkgToDocLine(var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOrderNetworkEntity(Type: Integer; Subtype: Integer; var IsNetworkEntity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReservEntry(var ReservEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveEntryFilter(ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveItemTrackingFromReservEntryFilter(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSynchronizeItemTracking2(FromReservEntry: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgOnAfterSetExpirationDate(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgOnAfterSetToRowID(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ToRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTempPostedWhseRcptLineSetFilters(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; ItemLedgerEntry: Record "Item Ledger Entry"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitWhseJnlLineOnAfterCheckWhseItemTrkgSetup(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseSplitTrackingSpec: Record "Tracking Specification" temporary; var WhseSNRequired: Boolean; var WhseLNRequired: Boolean)
    begin
    end;
}

