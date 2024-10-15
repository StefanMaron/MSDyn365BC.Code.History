namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

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
        LastPhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        Item: Record Item;
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
#if not CLEAN24
        TempPhysInvtTrackingBuffer: Record "Phys. Invt. Tracking" temporary;
#endif
        TempInvtOrderTrackingBuffer: Record "Invt. Order Tracking" temporary;
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        Window: Dialog;
        ErrorText: Text[250];
        LineCount: Integer;
        HideProgressWindow: Boolean;

        FinishingLinesMsg: Label 'Finishing lines              #2######', Comment = '%2 = counter';
        UpdateTok: Label '%1 %2', Locked = true;

    procedure "Code"()
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        OnBeforeCode(PhysInvtOrderHeader, HideProgressWindow);

        PhysInvtOrderHeader.TestField("No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
        PhysInvtOrderHeader.TestField("Posting Date");

        PhysInvtRecordHeader.Reset();
        PhysInvtRecordHeader.SetRange("Order No.", PhysInvtOrderHeader."No.");
        if PhysInvtRecordHeader.Find('-') then
            repeat
                PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Finished);
            until PhysInvtRecordHeader.Next() = 0;

        if not HideProgressWindow then begin
            Window.Open(
            '#1#################################\\' + FinishingLinesMsg);
            Window.Update(1, StrSubstNo(UpdateTok, PhysInvtOrderHeader.TableCaption(), PhysInvtOrderHeader."No."));
        end;

        PhysInvtOrderHeader.LockTable();
        PhysInvtOrderLine.LockTable();

        LineCount := 0;
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
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
#if not CLEAN24
                        if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
                            TempPhysInvtTrackingBuffer.Reset();
                            TempPhysInvtTrackingBuffer.DeleteAll();
                            CreateTrackingBufferLines(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");
                            CreateReservEntries(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", true, 0);
                        end else begin
#endif
                            TempInvtOrderTrackingBuffer.Reset();
                            TempInvtOrderTrackingBuffer.DeleteAll();
                            CreateOrderTrackingBufferLines(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");
                            CreateReservationEntries(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", true, 0);
#if not CLEAN24
                        end;
#endif
                    end else
                        if PhysInvtOrderLine."Entry Type" = PhysInvtOrderLine."Entry Type"::"Positive Adjmt." then
                            PhysInvtOrderLine."Pos. Qty. (Base)" := PhysInvtOrderLine."Quantity (Base)"
                        else
                            PhysInvtOrderLine."Neg. Qty. (Base)" := PhysInvtOrderLine."Quantity (Base)";

                    IsHandled := false;
                    OnCodeOnBeforePhysInvtOrderLineCalcCosts(PhysInvtOrderLine, IsHandled);
                    if not IsHandled then
                        PhysInvtOrderLine.CalcCosts();

                    OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine);
                    PhysInvtOrderLine.Modify();
                end;
            until PhysInvtOrderLine.Next() = 0;

        Clear(LastPhysInvtOrderLine);

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetCurrentKey("Document No.", "Item No.", "Variant Code", "Location Code");
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.SetRange("Use Item Tracking", true);
        OnCodeOnAfterSetFilters(PhysInvtOrderLine);
        if PhysInvtOrderLine.FindSet() then
            repeat
                if IsNewPhysInvtOrderLineGroup() then begin
                    LastPhysInvtOrderLine := PhysInvtOrderLine;

                    Item.Get(PhysInvtOrderLine."Item No.");
                    if IsBinMandatoryNoWhseTracking(Item, PhysInvtOrderLine."Location Code") then begin
#if not CLEAN24
                        if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
                            TempPhysInvtTrackingBuffer.Reset();
                            TempPhysInvtTrackingBuffer.DeleteAll();
                        end else begin
#endif
                            TempInvtOrderTrackingBuffer.Reset();
                            TempInvtOrderTrackingBuffer.DeleteAll();
#if not CLEAN24
                        end;
#endif
                        UpdateBufferFromItemLedgerEntries(PhysInvtOrderLine);

                        SetPhysInvtRecordLineFilters();
                        if PhysInvtOrderLine2.Find('-') then
                            repeat
                                PhysInvtRecordLine.Reset();
                                PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
                                PhysInvtRecordLine.SetRange("Order No.", PhysInvtOrderLine2."Document No.");
                                PhysInvtRecordLine.SetRange("Order Line No.", PhysInvtOrderLine2."Line No.");
                                PhysInvtRecordLine.SetFilter("Quantity (Base)", '<>%1', 0);
                                if PhysInvtRecordLine.Find('-') then
                                    repeat
#if not CLEAN24
                                        if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
                                            UpdateBufferRecordedQty(
                                                PhysInvtRecordLine."Serial No.", PhysInvtRecordLine."Lot No.", PhysInvtRecordLine."Quantity (Base)", PhysInvtOrderLine2."Line No.");
                                            OnCodeOnAfterUpdateFromPhysInvtRecordLine(TempPhysInvtTrackingBuffer, PhysInvtRecordLine);
                                        end else begin
#endif
                                            ItemTrackingSetup."Serial No." := PhysInvtRecordLine."Serial No.";
                                            ItemTrackingSetup."Lot No." := PhysInvtRecordLine."Lot No.";
                                            ItemTrackingSetup."Package No." := PhysInvtRecordLine."Package No.";
                                            UpdateBufferRecordedQty(ItemTrackingSetup, PhysInvtRecordLine."Quantity (Base)", PhysInvtOrderLine2."Line No.");
                                            OnCodeOnAfterUpdateFromPhysInvtRecordLine2(TempInvtOrderTrackingBuffer, PhysInvtRecordLine);
#if not CLEAN24
                                        end;
#endif
                                    until PhysInvtRecordLine.Next() = 0;
                            until PhysInvtOrderLine2.Next() = 0;
#if not CLEAN24
                        if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
                            TempPhysInvtTrackingBuffer.Reset();
                            if TempPhysInvtTrackingBuffer.Find('-') then
                                repeat
                                    TempPhysInvtTrackingBuffer."Qty. To Transfer" :=
                                        TempPhysInvtTrackingBuffer."Qty. Recorded (Base)" - TempPhysInvtTrackingBuffer."Qty. Expected (Base)";
                                    TempPhysInvtTrackingBuffer."Outstanding Quantity" := TempPhysInvtTrackingBuffer."Qty. To Transfer";
                                    TempPhysInvtTrackingBuffer.Open := TempPhysInvtTrackingBuffer."Outstanding Quantity" <> 0;
                                    TempPhysInvtTrackingBuffer.Modify();
                                until TempPhysInvtTrackingBuffer.Next() = 0;
                        end else begin
#endif
                            TempInvtOrderTrackingBuffer.Reset();
                            if TempInvtOrderTrackingBuffer.Find('-') then
                                repeat
                                    TempInvtOrderTrackingBuffer."Qty. To Transfer" :=
                                        TempInvtOrderTrackingBuffer."Qty. Recorded (Base)" - TempInvtOrderTrackingBuffer."Qty. Expected (Base)";
                                    TempInvtOrderTrackingBuffer."Outstanding Quantity" := TempInvtOrderTrackingBuffer."Qty. To Transfer";
                                    TempInvtOrderTrackingBuffer.Open := TempInvtOrderTrackingBuffer."Outstanding Quantity" <> 0;
                                    TempInvtOrderTrackingBuffer.Modify();
                                until TempInvtOrderTrackingBuffer.Next() = 0;
#if not CLEAN24
                        end;
#endif
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
#if not CLEAN24
                                            if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then
                                            CreateReservEntries(
                                                PhysInvtOrderLine2."Document No.", PhysInvtOrderLine2."Line No.", false,
                                                PhysInvtOrderLine2."Quantity (Base)")
                                        else
#endif
                                                CreateReservationEntries(
                                                    PhysInvtOrderLine2."Document No.", PhysInvtOrderLine2."Line No.", false,
                                                    PhysInvtOrderLine2."Quantity (Base)");
                                end;
                                IsHandled := false;
                                OnCodeOnBeforePhysInvtOrderLine2CalcCosts(PhysInvtOrderLine2, IsHandled);
                                if not IsHandled then
                                    PhysInvtOrderLine2.CalcCosts();
                                PhysInvtOrderLine2.Modify();
                            until PhysInvtOrderLine2.Next() = 0;
                    end;
                end;
            until PhysInvtOrderLine.Next() = 0;

        OnCodeOnBeforeSetStatusToFinished(PhysInvtOrderHeader);
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Finished;
        PhysInvtOrderHeader.Modify();
    end;

    local procedure CheckOrderLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Item: Record Item)
    var
        ItemVariant: Record "Item Variant";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOrderLine(PhysInvtOrderHeader, PhysInvtOrderLine, Item, IsHandled, PhysInvtOrderLine2);
        if IsHandled then
            exit;

        PhysInvtOrderLine.CheckLine();
        Item.Get(PhysInvtOrderLine."Item No.");
        Item.TestField(Blocked, false);

        if PhysInvtOrderLine."Variant Code" <> '' then begin
            ItemVariant.SetLoadFields(Blocked);
            ItemVariant.Get(PhysInvtOrderLine."Item No.", PhysInvtOrderLine."Variant Code");
            ItemVariant.TestField(Blocked, false);
        end;

        IsHandled := false;
        OnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader, IsHandled, PhysInvtOrderLine2);
        if not IsHandled then
            if PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                 PhysInvtOrderLine, ErrorText, PhysInvtOrderLine2) > 1
            then
                Error(ErrorText);
    end;

#if not CLEAN24
    [Obsolete('Replaced by procedure CreateOrderTrackingBufferLines()', '24.0')]
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
#endif

    procedure CreateOrderTrackingBufferLines(DocNo: Code[20]; LineNo: Integer)
    var
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", DocNo);
        PhysInvtRecordLine.SetRange("Order Line No.", LineNo);
        PhysInvtRecordLine.SetFilter("Quantity (Base)", '<>%1', 0);
        if PhysInvtRecordLine.Find('-') then
            repeat
                ItemTrackingSetup."Serial No." := PhysInvtRecordLine."Serial No.";
                ItemTrackingSetup."Lot No." := PhysInvtRecordLine."Lot No.";
                ItemTrackingSetup."Package No." := PhysInvtRecordLine."Package No.";
                UpdateBufferRecordedQty(ItemTrackingSetup, PhysInvtRecordLine."Quantity (Base)", LineNo);
                OnCreateOrderTrackingBufferLinesFromPhysInvtRecordLine(TempInvtOrderTrackingBuffer, PhysInvtRecordLine);
            until PhysInvtRecordLine.Next() = 0;

        ExpInvtOrderTracking.Reset();
        ExpInvtOrderTracking.SetRange("Order No", DocNo);
        ExpInvtOrderTracking.SetRange("Order Line No.", LineNo);
        if ExpInvtOrderTracking.Find('-') then
            repeat
                ItemTrackingSetup."Serial No." := ExpInvtOrderTracking."Serial No.";
                ItemTrackingSetup."Lot No." := ExpInvtOrderTracking."Lot No.";
                ItemTrackingSetup."Package No." := ExpInvtOrderTracking."Package No.";
                UpdateBufferExpectedQty(ItemTrackingSetup, ExpInvtOrderTracking."Quantity (Base)", LineNo);
                OnCreateOrderTrackingBufferLinesFromExpInvtOrderTracking(TempInvtOrderTrackingBuffer, ExpInvtOrderTracking);
            until ExpInvtOrderTracking.Next() = 0;

        TempInvtOrderTrackingBuffer.Reset();
        if TempInvtOrderTrackingBuffer.Find('-') then
            repeat
                TempInvtOrderTrackingBuffer."Qty. To Transfer" :=
                  TempInvtOrderTrackingBuffer."Qty. Recorded (Base)" - TempInvtOrderTrackingBuffer."Qty. Expected (Base)";
                TempInvtOrderTrackingBuffer."Outstanding Quantity" := TempInvtOrderTrackingBuffer."Qty. To Transfer";
                TempInvtOrderTrackingBuffer.Open := TempInvtOrderTrackingBuffer."Outstanding Quantity" <> 0;
                TempInvtOrderTrackingBuffer.Modify();
            until TempInvtOrderTrackingBuffer.Next() = 0;
    end;

#if not CLEAN24
    [Obsolete('Replaced by procedure CreateReservationEntries()', '24.0')]
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
                QtyToTransfer := CalculateQtyToTransfer(AllBufferLines, MaxQtyToTransfer);
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
#endif

    procedure CreateReservationEntries(DocNo: Code[20]; LineNo: Integer; AllBufferLines: Boolean; MaxQtyToTransfer: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        QtyToTransfer: Decimal;
    begin
        TempInvtOrderTrackingBuffer.Reset();
        TempInvtOrderTrackingBuffer.SetCurrentKey(Open);
        TempInvtOrderTrackingBuffer.SetRange(Open, true);
        if TempInvtOrderTrackingBuffer.FindSet() then
            repeat
                QtyToTransfer := CalculateQtyToTransfer(AllBufferLines, MaxQtyToTransfer);
                if QtyToTransfer <> 0 then begin
                    ReservEntry.Init();
                    ReservEntry."Entry No." := 0;
                    ReservEntry.Positive := QtyToTransfer > 0;
                    ReservEntry.Validate("Item No.", PhysInvtOrderLine."Item No.");
                    ReservEntry.Validate("Variant Code", PhysInvtOrderLine."Variant Code");
                    ReservEntry.Validate("Location Code", PhysInvtOrderLine."Location Code");
                    ReservEntry.Validate("Serial No.", TempInvtOrderTrackingBuffer."Serial No.");
                    ReservEntry.Validate("Lot No.", TempInvtOrderTrackingBuffer."Lot No.");
                    ReservEntry.Validate("Package No.", TempInvtOrderTrackingBuffer."Package No.");
                    ReservEntry.Validate("Expiration Date", TempInvtOrderTrackingBuffer."Expiration Date");
                    ReservEntry.Validate("Source Type", DATABASE::"Phys. Invt. Order Line");
                    ReservEntry.Validate("Source ID", DocNo);
                    ReservEntry.Validate("Source Ref. No.", TempInvtOrderTrackingBuffer."Line No.");
                    ReservEntry.Validate(Quantity, QtyToTransfer);
                    ReservEntry."Qty. per Unit of Measure" := 1;
                    ReservEntry."Quantity (Base)" := ReservEntry.Quantity;
                    ReservEntry."Qty. to Handle (Base)" := ReservEntry.Quantity;
                    ReservEntry."Qty. to Invoice (Base)" := ReservEntry.Quantity;
                    ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
                    ReservEntry."Created By" := CopyStr(UserId(), 1, 50);
                    ReservEntry.Validate("Creation Date", WorkDate());
                    if QtyToTransfer > 0 then begin
                        ReservEntry."Expected Receipt Date" := PhysInvtOrderHeader."Posting Date";
                        PhysInvtOrderLine."Pos. Qty. (Base)" += ReservEntry.Quantity;
                    end else begin
                        ReservEntry."Shipment Date" := PhysInvtOrderHeader."Posting Date";
                        PhysInvtOrderLine."Neg. Qty. (Base)" -= ReservEntry.Quantity;
                    end;
                    ReservEntry.Insert();
                    OnCreateReservEntriesOnBeforeInsert2(ReservEntry, TempInvtOrderTrackingBuffer, PhysInvtOrderHeader, PhysInvtOrderLine);
                    RecRef.GetTable(ReservEntry);
                    if RecRef.IsDirty then
                        ReservEntry.Modify();
                end;
                TempInvtOrderTrackingBuffer."Outstanding Quantity" -= QtyToTransfer;
                TempInvtOrderTrackingBuffer.Open := TempInvtOrderTrackingBuffer."Outstanding Quantity" <> 0;
                TempInvtOrderTrackingBuffer.Modify();
                OnCreateReservEntriesOnAfterTempPhysInvtTrackingBufferModify(AllBufferLines, MaxQtyToTransfer, QtyToTransfer);
            until TempInvtOrderTrackingBuffer.Next() = 0;
    end;

    local procedure CalculateQtyToTransfer(AllBufferLines: Boolean; MaxQtyToTransfer: Decimal) QtyToTransfer: Decimal;
    begin
#if not CLEAN24
        if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
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
        end else begin
#endif
            if AllBufferLines then
                QtyToTransfer := TempInvtOrderTrackingBuffer."Outstanding Quantity"
            else
                if MaxQtyToTransfer > 0 then
                    if TempInvtOrderTrackingBuffer."Outstanding Quantity" <= MaxQtyToTransfer then
                        QtyToTransfer := TempInvtOrderTrackingBuffer."Outstanding Quantity"
                    else
                        QtyToTransfer := MaxQtyToTransfer
                else
                    if TempInvtOrderTrackingBuffer."Outstanding Quantity" >= MaxQtyToTransfer then
                        QtyToTransfer := TempInvtOrderTrackingBuffer."Outstanding Quantity"
                    else
                        QtyToTransfer := MaxQtyToTransfer;
            OnAfterCalculateQtyToTransfer(TempInvtOrderTrackingBuffer, AllBufferLines, MaxQtyToTransfer, QtyToTransfer);
#if not CLEAN24
        end;
#endif
    end;

    local procedure IsBinMandatoryNoWhseTracking(Item: Record Item; LocationCode: Code[10]): Boolean
    begin
        exit(PhysInvtTrackingMgt.LocationIsBinMandatory(LocationCode) and not PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item));
    end;

    local procedure UpdateBufferFromItemLedgerEntries(PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", PhysInvtOrderLine."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", PhysInvtOrderLine."Variant Code");
        ItemLedgerEntry.SetRange("Location Code", PhysInvtOrderLine."Location Code");
        ItemLedgerEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
        if ItemLedgerEntry.Find('-') then
            repeat
#if not CLEAN24
                if not PhysInvtTrackingMgt.IsPackageTrackingEnabled() then begin
                    UpdateBufferExpectedQty(ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry.Quantity, PhysInvtOrderLine."Line No.");
                    OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty(TempPhysInvtTrackingBuffer, ItemLedgerEntry);
                end else begin
#endif
                    ItemTrackingSetup.CopyTrackingFromitemLedgerEntry(ItemLedgerEntry);
                    UpdateBufferExpectedQty(ItemTrackingSetup, ItemLedgerEntry.Quantity, PhysInvtOrderLine."Line No.");
                    OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty2(TempInvtOrderTrackingBuffer, ItemLedgerEntry);
#if not CLEAN24
                end;
#endif
            until ItemLedgerEntry.Next() = 0;
    end;

#if not CLEAN24
    local procedure UpdateBufferExpectedQty(SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal; LineNo: Integer)
    begin
        if not TempPhysInvtTrackingBuffer.Get(SerialNo, LotNo) then begin
            TempPhysInvtTrackingBuffer.Init();
            TempPhysInvtTrackingBuffer."Serial No." := SerialNo;
            TempPhysInvtTrackingBuffer."Lot No" := LotNo;
            TempPhysInvtTrackingBuffer."Qty. Expected (Base)" := QtyBase;
            TempPhysInvtTrackingBuffer."Line No." := LineNo;
            TempPhysInvtTrackingBuffer.Insert();
        end else begin
            TempPhysInvtTrackingBuffer."Qty. Expected (Base)" += QtyBase;
            TempPhysInvtTrackingBuffer.Modify();
        end;
    end;

    local procedure UpdateBufferRecordedQty(SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal; LineNo: Integer)
    begin
        if not TempPhysInvtTrackingBuffer.Get(SerialNo, LotNo) then begin
            TempPhysInvtTrackingBuffer.Init();
            TempPhysInvtTrackingBuffer."Serial No." := SerialNo;
            TempPhysInvtTrackingBuffer."Lot No" := LotNo;
            TempPhysInvtTrackingBuffer."Qty. Recorded (Base)" := QtyBase;
            TempPhysInvtTrackingBuffer."Line No." := LineNo;
            TempPhysInvtTrackingBuffer.Insert();
        end else begin
            TempPhysInvtTrackingBuffer."Qty. Recorded (Base)" += QtyBase;
            TempPhysInvtTrackingBuffer.Modify();
        end;
    end;
#endif

    local procedure UpdateBufferRecordedQty(ItemTrackingSetup: Record "Item Tracking Setup"; QtyBase: Decimal; LineNo: Integer)
    begin
        if not TempInvtOrderTrackingBuffer.Get(ItemTrackingSetup."Serial No.", ItemTrackingSetup."Lot No.", ItemTrackingSetup."Package No.") then begin
            TempInvtOrderTrackingBuffer.Init();
            TempInvtOrderTrackingBuffer."Serial No." := ItemTrackingSetup."Serial No.";
            TempInvtOrderTrackingBuffer."Lot No." := ItemTrackingSetup."Lot No.";
            TempInvtOrderTrackingBuffer."Package No." := ItemTrackingSetup."Package No.";
            TempInvtOrderTrackingBuffer."Qty. Recorded (Base)" := QtyBase;
            TempInvtOrderTrackingBuffer."Line No." := LineNo;
            TempInvtOrderTrackingBuffer.Insert();
        end else begin
            TempInvtOrderTrackingBuffer."Qty. Recorded (Base)" += QtyBase;
            TempInvtOrderTrackingBuffer.Modify();
        end;
    end;

    local procedure UpdateBufferExpectedQty(ItemTrackingSetup: Record "Item Tracking Setup"; QtyBase: Decimal; LineNo: Integer)
    begin
        if not TempInvtOrderTrackingBuffer.Get(ItemTrackingSetup."Serial No.", ItemTrackingSetup."Lot No.", ItemTrackingSetup."Package No.") then begin
            TempInvtOrderTrackingBuffer.Init();
            TempInvtOrderTrackingBuffer."Serial No." := ItemTrackingSetup."Serial No.";
            TempInvtOrderTrackingBuffer."Lot No." := ItemTrackingSetup."Lot No.";
            TempInvtOrderTrackingBuffer."Package No." := ItemTrackingSetup."Package No.";
            TempInvtOrderTrackingBuffer."Qty. Expected (Base)" := QtyBase;
            TempInvtOrderTrackingBuffer."Line No." := LineNo;
            TempInvtOrderTrackingBuffer.Insert();
        end else begin
            TempInvtOrderTrackingBuffer."Qty. Expected (Base)" += QtyBase;
            TempInvtOrderTrackingBuffer.Modify();
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

#if not CLEAN24
    [Obsolete('Replaced by OnAfterCalculateQtyToTransfer', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyToTransfer(var TempPhysInvtTrackingBuffer: Record "Phys. Invt. Tracking" temporary; AllBufferLines: Boolean; MaxQtyToTransfer: Decimal; var QtyToTransfer: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQtyToTransfer(var TempInvtOrderTrackingBuffer: Record "Invt. Order Tracking" temporary; AllBufferLines: Boolean; MaxQtyToTransfer: Decimal; var QtyToTransfer: Decimal)
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

#if not CLEAN24
    [Obsolete('Replace by OnCodeOnAfterUpdateFromPhysInvtRecordLine2', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterUpdateFromPhysInvtRecordLine(var PhysInvtTracking: Record "Phys. Invt. Tracking"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterUpdateFromPhysInvtRecordLine2(var InvtOrderTracking: Record "Invt. Order Tracking"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeCreateReservEntries(var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN24
    [Obsolete('Replaced by event OnCreateReservEntriesOnBeforeInsert2', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntriesOnBeforeInsert(var ReservationEntry: Record "Reservation Entry"; PhysInvtTracking: Record "Phys. Invt. Tracking"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntriesOnBeforeInsert2(var ReservationEntry: Record "Reservation Entry"; InvtOrderTracking: Record "Invt. Order Tracking"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservEntriesOnAfterTempPhysInvtTrackingBufferModify(AllBufferLines: Boolean; var MaxQtyToTransfer: Decimal; QtyToTransfer: Decimal)
    begin
    end;

#if not CLEAN24
    [Obsolete('Replaced by event OnCreateOrderTrackingBufferLinesFromPhysInvtRecordLine', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingBufferLinesFromPhysInvtRecordLine(var TempPhysInvtTracking: Record "Phys. Invt. Tracking" temporary; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrderTrackingBufferLinesFromPhysInvtRecordLine(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

#if not CLEAN24
    [Obsolete('Replaced by event OnCreateOrderTrackingBufferLinesFromExpInvtOrderTracking', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingBufferLinesFromExpPhysInvtTracking(var TempPhysInvtTracking: Record "Phys. Invt. Tracking" temporary; ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrderTrackingBufferLinesFromExpInvtOrderTracking(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking")
    begin
    end;

#if not CLEAN24
    [Obsolete('Replaced by event OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty2', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty(var PhysInvtTracking: Record "Phys. Invt. Tracking"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBufferFromItemLedgerEntriesOnAfterUpdateExpectedQty2(var InvtOrderTracking: Record "Invt. Order Tracking"; ItemLedgerEntry: Record "Item Ledger Entry")
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

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePhysInvtOrderLineCalcCosts(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePhysInvtOrderLine2CalcCosts(var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetStatusToFinished(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

