codeunit 5880 "Phys. Invt. Order-Finish"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        PhysInvtOrderHeader.Copy(Rec);
        Code();
        Rec := PhysInvtOrderHeader;

        OnAfterOnRun(Rec);
    end;

    var
        FinishingLinesMsg: Label 'Finishing lines              #2######', Comment = '%2 = counter';
        LastPhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        Item: Record Item;
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        TempPhysInvtTrackingBuffer: Record "Phys. Invt. Tracking" temporary;
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        Window: Dialog;
        ErrorText: Text[250];
        LineCount: Integer;
        HideProgressWindow: Boolean;

    procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCode(PhysInvtOrderHeader, HideProgressWindow);

        with PhysInvtOrderHeader do begin
            TestField("No.");
            TestField(Status, Status::Open);
            TestField("Posting Date");

            PhysInvtRecordHeader.Reset();
            PhysInvtRecordHeader.SetRange("Order No.", "No.");
            if PhysInvtRecordHeader.Find('-') then
                repeat
                    PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Finished);
                until PhysInvtRecordHeader.Next() = 0;

            if not HideProgressWindow then begin
                Window.Open(
                '#1#################################\\' + FinishingLinesMsg);
                Window.Update(1, StrSubstNo('%1 %2', TableCaption(), "No."));
            end;

            LockTable();
            PhysInvtOrderLine.LockTable();

            LineCount := 0;
            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetRange("Document No.", "No.");
            OnCodeOnAfterSetFilters(PhysInvtOrderLine);
            if PhysInvtOrderLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    if not HideProgressWindow then
                        Window.Update(2, LineCount);

                    if not PhysInvtOrderLine.EmptyLine() then begin
                        CheckOrderLine(PhysInvtOrderHeader, PhysInvtOrderLine, Item);

                        if PhysInvtOrderLine."Qty. Recorded (Base)" - PhysInvtOrderLine."Qty. Expected (Base)" >= 0 then begin
                            PhysInvtOrderLine."Entry Type" := PhysInvtOrderLine."Entry Type"::"Positive Adjmt.";
                            PhysInvtOrderLine."Quantity (Base)" :=
                              PhysInvtOrderLine."Qty. Recorded (Base)" - PhysInvtOrderLine."Qty. Expected (Base)";
                            PhysInvtOrderLine."Without Difference" := PhysInvtOrderLine."Quantity (Base)" = 0;
                        end else begin
                            PhysInvtOrderLine."Entry Type" := PhysInvtOrderLine."Entry Type"::"Negative Adjmt.";
                            PhysInvtOrderLine."Quantity (Base)" :=
                              PhysInvtOrderLine."Qty. Expected (Base)" - PhysInvtOrderLine."Qty. Recorded (Base)";
                        end;

                        if PhysInvtOrderLine."Use Item Tracking" and
                           not IsBinMandatoryNoWhseTracking(Item, PhysInvtOrderLine."Location Code")
                        then begin
                            PhysInvtOrderLine."Pos. Qty. (Base)" := 0;
                            PhysInvtOrderLine."Neg. Qty. (Base)" := 0;
                            TempPhysInvtTrackingBuffer.Reset();
                            TempPhysInvtTrackingBuffer.DeleteAll();
                            CreateTrackingBufferLines(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");
                            CreateReservEntries(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", true, 0);
                        end else
                            if PhysInvtOrderLine."Entry Type" = PhysInvtOrderLine."Entry Type"::"Positive Adjmt." then
                                PhysInvtOrderLine."Pos. Qty. (Base)" := PhysInvtOrderLine."Quantity (Base)"
                            else
                                PhysInvtOrderLine."Neg. Qty. (Base)" := PhysInvtOrderLine."Quantity (Base)";

                        PhysInvtOrderLine.CalcCosts();

                        OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine);
                        PhysInvtOrderLine.Modify();
                    end;
                until PhysInvtOrderLine.Next() = 0;

            Clear(LastPhysInvtOrderLine);

            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetCurrentKey("Document No.", "Item No.", "Variant Code", "Location Code");
            PhysInvtOrderLine.SetRange("Document No.", "No.");
            PhysInvtOrderLine.SetRange("Use Item Tracking", true);
            OnCodeOnAfterSetFilters(PhysInvtOrderLine);
            if PhysInvtOrderLine.FindSet() then
                repeat
                    if IsNewPhysInvtOrderLineGroup() then begin
                        LastPhysInvtOrderLine := PhysInvtOrderLine;

                        Item.Get(PhysInvtOrderLine."Item No.");
                        if IsBinMandatoryNoWhseTracking(Item, PhysInvtOrderLine."Location Code") then begin
                            TempPhysInvtTrackingBuffer.Reset();
                            TempPhysInvtTrackingBuffer.DeleteAll();

                            UpdateBufferFromItemLedgerEntries(PhysInvtOrderLine);

                            SetPhysInvtRecordLineFilters();
                            if PhysInvtOrderLine2.Find('-') then
                                repeat
                                    PhysInvtRecordLine.Reset();
                                    PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
                                    PhysInvtRecordLine.SetRange("Order No.", PhysInvtOrderLine2."Document No.");
                                    PhysInvtRecordLine.SetRange("Order Line No.", PhysInvtOrderLine2."Line No.");
                                    if PhysInvtRecordLine.Find('-') then
                                        repeat
                                            if PhysInvtRecordLine."Quantity (Base)" <> 0 then
                                                UpdateBufferRecordedQty(
                                                  PhysInvtRecordLine."Serial No.", PhysInvtRecordLine."Lot No.", PhysInvtRecordLine."Quantity (Base)", PhysInvtOrderLine2."Line No.");
                                            OnCodeOnAfterUpdateFromPhysInvtRecordLine(TempPhysInvtTrackingBuffer, PhysInvtRecordLine);
                                        until PhysInvtRecordLine.Next() = 0;
                                until PhysInvtOrderLine2.Next() = 0;

                            TempPhysInvtTrackingBuffer.Reset();
                            if TempPhysInvtTrackingBuffer.Find('-') then
                                repeat
                                    TempPhysInvtTrackingBuffer."Qty. To Transfer" :=
                                      TempPhysInvtTrackingBuffer."Qty. Recorded (Base)" - TempPhysInvtTrackingBuffer."Qty. Expected (Base)";
                                    TempPhysInvtTrackingBuffer."Outstanding Quantity" := TempPhysInvtTrackingBuffer."Qty. To Transfer";
                                    TempPhysInvtTrackingBuffer.Open := TempPhysInvtTrackingBuffer."Outstanding Quantity" <> 0;
                                    TempPhysInvtTrackingBuffer.Modify();
                                until TempPhysInvtTrackingBuffer.Next() = 0;

                            if PhysInvtOrderLine2.Find('-') then
                                repeat
                                    if PhysInvtOrderLine2."Entry Type" = PhysInvtOrderLine2."Entry Type"::"Positive Adjmt." then
                                        PhysInvtOrderLine2."Pos. Qty. (Base)" := PhysInvtOrderLine2."Quantity (Base)"
                                    else
                                        PhysInvtOrderLine2."Neg. Qty. (Base)" := PhysInvtOrderLine2."Quantity (Base)";
                                    PhysInvtOrderLine2.Modify();
                                    if PhysInvtOrderLine2."Quantity (Base)" <> 0 then begin
                                        IsHandled := false;
                                        OnCodeOnBeforeCreateReservEntries(PhysInvtOrderLine2, IsHandled);
                                        if not IsHandled then
                                            CreateReservEntries(
                                                PhysInvtOrderLine2."Document No.", PhysInvtOrderLine2."Line No.", false,
                                                PhysInvtOrderLine2."Quantity (Base)");
                                    end;
                                    PhysInvtOrderLine2.CalcCosts();
                                    PhysInvtOrderLine2.Modify();
                                until PhysInvtOrderLine2.Next() = 0;
                        end;
                    end;
                until PhysInvtOrderLine.Next() = 0;

            Status := Status::Finished;
            Modify();
        end;
    end;

    local procedure CheckOrderLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOrderLine(PhysInvtOrderHeader, PhysInvtOrderLine, Item, IsHandled, PhysInvtOrderLine2);
        if IsHandled then
            exit;

        with PhysInvtOrderLine do begin
            CheckLine();
            Item.Get("Item No.");
            Item.TestField(Blocked, false);

            IsHandled := false;
            OnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader, IsHandled, PhysInvtOrderLine2);
            if not IsHandled then
                if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                     PhysInvtOrderLine, ErrorText, PhysInvtOrderLine2) > 1
                then
                    Error(ErrorText);
        end;
    end;

    procedure CreateTrackingBufferLines(DocNo: Code[20]; LineNo: Integer)
    var
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
    begin
        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", DocNo);
        PhysInvtRecordLine.SetRange("Order Line No.", LineNo);
        if PhysInvtRecordLine.Find('-') then
            repeat
                if PhysInvtRecordLine."Quantity (Base)" <> 0 then
                    UpdateBufferRecordedQty(
                      PhysInvtRecordLine."Serial No.", PhysInvtRecordLine."Lot No.", PhysInvtRecordLine."Quantity (Base)", LineNo);
                OnCreateTrackingBufferLinesFromPhysInvtRecordLine(TempPhysInvtTrackingBuffer, PhysInvtRecordLine);
            until PhysInvtRecordLine.Next() = 0;

        ExpPhysInvtTracking.Reset();
        ExpPhysInvtTracking.SetRange("Order No", DocNo);
        ExpPhysInvtTracking.SetRange("Order Line No.", LineNo);
        if ExpPhysInvtTracking.Find('-') then
            repeat
                UpdateBufferExpectedQty(
                  ExpPhysInvtTracking."Serial No.", ExpPhysInvtTracking."Lot No.", ExpPhysInvtTracking."Quantity (Base)", LineNo);
                OnCreateTrackingBufferLinesFromExpPhysInvtTracking(TempPhysInvtTrackingBuffer, ExpPhysInvtTracking);
            until ExpPhysInvtTracking.Next() = 0;

        TempPhysInvtTrackingBuffer.Reset();
        if TempPhysInvtTrackingBuffer.Find('-') then
            repeat
                TempPhysInvtTrackingBuffer."Qty. To Transfer" :=
                  TempPhysInvtTrackingBuffer."Qty. Recorded (Base)" - TempPhysInvtTrackingBuffer."Qty. Expected (Base)";
                TempPhysInvtTrackingBuffer."Outstanding Quantity" := TempPhysInvtTrackingBuffer."Qty. To Transfer";
                TempPhysInvtTrackingBuffer.Open := TempPhysInvtTrackingBuffer."Outstanding Quantity" <> 0;
                TempPhysInvtTrackingBuffer.Modify();
            until TempPhysInvtTrackingBuffer.Next() = 0;
    end;

    procedure CreateReservEntries(DocNo: Code[20]; LineNo: Integer; AllBufferLines: Boolean; MaxQtyToTransfer: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        QtyToTransfer: Decimal;
    begin
        TempPhysInvtTrackingBuffer.Reset();
        TempPhysInvtTrackingBuffer.SetCurrentKey(Open);
        TempPhysInvtTrackingBuffer.SetRange(Open, true);
        if TempPhysInvtTrackingBuffer.FindSet() then
            repeat
                QtyToTransfer := CalcQtyToTransfer(AllBufferLines, MaxQtyToTransfer);
                if QtyToTransfer <> 0 then begin
                    ReservEntry.Init();
                    ReservEntry."Entry No." := 0;
                    ReservEntry.Positive := QtyToTransfer > 0;
                    ReservEntry.Validate("Item No.", PhysInvtOrderLine."Item No.");
                    ReservEntry.Validate("Variant Code", PhysInvtOrderLine."Variant Code");
                    ReservEntry.Validate("Location Code", PhysInvtOrderLine."Location Code");
                    ReservEntry.Validate("Serial No.", TempPhysInvtTrackingBuffer."Serial No.");
                    ReservEntry.Validate("Lot No.", TempPhysInvtTrackingBuffer."Lot No");
                    ReservEntry.Validate("Source Type", DATABASE::"Phys. Invt. Order Line");
                    ReservEntry.Validate("Source ID", DocNo);
                    ReservEntry.Validate("Source Ref. No.", TempPhysInvtTrackingBuffer."Line No.");
                    ReservEntry.Validate(Quantity, QtyToTransfer);
                    ReservEntry."Qty. per Unit of Measure" := 1;
                    ReservEntry."Quantity (Base)" := ReservEntry.Quantity;
                    ReservEntry."Qty. to Handle (Base)" := ReservEntry.Quantity;
                    ReservEntry."Qty. to Invoice (Base)" := ReservEntry.Quantity;
                    ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
                    ReservEntry."Created By" := UserId;
                    ReservEntry.Validate("Creation Date", WorkDate());
                    if QtyToTransfer > 0 then begin
                        ReservEntry."Expected Receipt Date" := PhysInvtOrderHeader."Posting Date";
                        PhysInvtOrderLine."Pos. Qty. (Base)" += ReservEntry.Quantity;
                    end else begin
                        ReservEntry."Shipment Date" := PhysInvtOrderHeader."Posting Date";
                        PhysInvtOrderLine."Neg. Qty. (Base)" -= ReservEntry.Quantity;
                    end;
                    ReservEntry.Insert();
                    OnCreateReservEntriesOnBeforeInsert(ReservEntry, TempPhysInvtTrackingBuffer, PhysInvtOrderHeader, PhysInvtOrderLine);
                    RecRef.GetTable(ReservEntry);
                    if RecRef.IsDirty then
                        ReservEntry.Modify();
                end;
                TempPhysInvtTrackingBuffer."Outstanding Quantity" -= QtyToTransfer;
                TempPhysInvtTrackingBuffer.Open := TempPhysInvtTrackingBuffer."Outstanding Quantity" <> 0;
                TempPhysInvtTrackingBuffer.Modify();
                OnCreateReservEntriesOnAfterTempPhysInvtTrackingBufferModify(AllBufferLines, MaxQtyToTransfer, QtyToTransfer);
            until TempPhysInvtTrackingBuffer.Next() = 0;
    end;

    local procedure CalcQtyToTransfer(AllBufferLines: Boolean; MaxQtyToTransfer: Decimal) QtyToTransfer: Decimal;
    begin
        if AllBufferLines then
            QtyToTransfer := TempPhysInvtTrackingBuffer."Outstanding Quantity"
        else
            if MaxQtyToTransfer > 0 then
                if TempPhysInvtTrackingBuffer."Outstanding Quantity" <= MaxQtyToTransfer then
                    QtyToTransfer := TempPhysInvtTrackingBuffer."Outstanding Quantity"
                else
                    QtyToTransfer := MaxQtyToTransfer
            else
                if TempPhysInvtTrackingBuffer."Outstanding Quantity" >= MaxQtyToTransfer then
                    QtyToTransfer := TempPhysInvtTrackingBuffer."Outstanding Quantity"
                else
                    QtyToTransfer := MaxQtyToTransfer;
        OnAfterCalcQtyToTransfer(TempPhysInvtTrackingBuffer, AllBufferLines, MaxQtyToTransfer, QtyToTransfer);
    end;

    local procedure IsBinMandatoryNoWhseTracking(Item: Record Item; LocationCode: Code[10]): Boolean
    begin
        exit(PhysInvtTrackingMgt.LocationIsBinMandatory(LocationCode) and not PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item));
    end;

    local procedure UpdateBufferFromItemLedgerEntries(PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            Reset();
            SetCurrentKey(
              "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
            SetRange("Item No.", PhysInvtOrderLine."Item No.");
            SetRange("Variant Code", PhysInvtOrderLine."Variant Code");
            SetRange("Location Code", PhysInvtOrderLine."Location Code");
            SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
            if Find('-') then
                repeat
                    UpdateBufferExpectedQty("Serial No.", "Lot No.", Quantity, PhysInvtOrderLine."Line No.");
                    OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty(TempPhysInvtTrackingBuffer, ItemLedgEntry);
                until Next() = 0;
        end;
    end;

    local procedure UpdateBufferExpectedQty(SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal; LineNo: Integer)
    begin
        with TempPhysInvtTrackingBuffer do
            if not Get(SerialNo, LotNo) then begin
                Init();
                "Serial No." := SerialNo;
                "Lot No" := LotNo;
                "Qty. Expected (Base)" := QtyBase;
                "Line No." := LineNo;
                Insert();
            end else begin
                "Qty. Expected (Base)" += QtyBase;
                Modify();
            end;
    end;

    local procedure UpdateBufferRecordedQty(SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal; LineNo: Integer)
    begin
        with TempPhysInvtTrackingBuffer do
            if not Get(SerialNo, LotNo) then begin
                Init();
                "Serial No." := SerialNo;
                "Lot No" := LotNo;
                "Qty. Recorded (Base)" := QtyBase;
                "Line No." := LineNo;
                Insert();
            end else begin
                "Qty. Recorded (Base)" += QtyBase;
                Modify();
            end;
    end;

    local procedure IsNewPhysInvtOrderLineGroup() Result: Boolean
    begin
        Result :=
            (PhysInvtOrderLine."Item No." <> LastPhysInvtOrderLine."Item No.") or
            (PhysInvtOrderLine."Variant Code" <> LastPhysInvtOrderLine."Variant Code") or
            (PhysInvtOrderLine."Location Code" <> LastPhysInvtOrderLine."Location Code");
        OnAfterIsNewPhysInvtOrderLineGroup(PhysInvtOrderLine, LastPhysInvtOrderLine, Result);
    end;

    local procedure SetPhysInvtRecordLineFilters()
    begin
        PhysInvtOrderLine2.Reset();
        PhysInvtOrderLine2.SetCurrentKey(
          "Document No.", "Item No.", "Variant Code", "Location Code");
        PhysInvtOrderLine2.SetRange("Document No.", PhysInvtOrderLine."Document No.");
        PhysInvtOrderLine2.SetRange("Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtOrderLine2.SetRange("Variant Code", PhysInvtOrderLine."Variant Code");
        PhysInvtOrderLine2.SetRange("Location Code", PhysInvtOrderLine."Location Code");
        OnAfterSetPhysInvtRecordLineFilters(PhysInvtOrderLine2, PhysInvtOrderLine);
    end;

    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)
    begin
        HideProgressWindow := NewHideProgressWindow;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyToTransfer(var TempPhysInvtTrackingBuffer: Record "Phys. Invt. Tracking" temporary; AllBufferLines: Boolean; MaxQtyToTransfer: Decimal; var QtyToTransfer: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOrderLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Item: Record Item; var IsHandled: Boolean; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSamePhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSetFilters(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterUpdateFromPhysInvtRecordLine(var PhysInvtTracking: Record "Phys. Invt. Tracking"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeCreateReservEntries(var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntriesOnBeforeInsert(var ReservationEntry: Record "Reservation Entry"; PhysInvtTracking: Record "Phys. Invt. Tracking"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntriesOnAfterTempPhysInvtTrackingBufferModify(AllBufferLines: Boolean; var MaxQtyToTransfer: Decimal; QtyToTransfer: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingBufferLinesFromPhysInvtRecordLine(var TempPhysInvtTracking: Record "Phys. Invt. Tracking" temporary; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingBufferLinesFromExpPhysInvtTracking(var TempPhysInvtTracking: Record "Phys. Invt. Tracking" temporary; ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty(var PhysInvtTracking: Record "Phys. Invt. Tracking"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNewPhysInvtOrderLineGroup(PhysInvtOrderLine: Record "Phys. Invt. Order Line"; LastPhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPhysInvtRecordLineFilters(var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

