codeunit 5816 "Undo Return Receipt Line"
{
    Permissions = TableData "Sales Line" = rimd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Whse. Item Entry Relation" = rimd,
                  TableData "Return Receipt Line" = rimd;
    TableNo = "Return Receipt Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
        SkipTypeCheck: Boolean;
    begin
        IsHandled := false;
        SkipTypeCheck := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck, HideDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        ReturnRcptLine.Copy(Rec);
        Code();
        Rec := ReturnRcptLine;
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        HideDialog: Boolean;
        NextLineNo: Integer;

        Text000: Label 'Do you really want to undo the selected Return Receipt lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        Text004: Label 'This receipt has already been invoiced. Undo Return Receipt can be applied only to posted, but not invoiced receipts.';
        AlreadyReversedErr: Label 'This return receipt has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseRcptLineFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(ReturnRcptLine, HideDialog, IsHandled);
        if not IsHandled then
            with ReturnRcptLine do begin
                Clear(ItemJnlPostLine);
                SetRange(Correction, false);
                SetFilter(Quantity, '<>0');
                if IsEmpty() then
                    Error(AlreadyReversedErr);

                FindFirst();
                repeat
                    if not HideDialog then
                        Window.Open(Text003);
                    CheckReturnRcptLine(ReturnRcptLine);
                until Next() = 0;

                Find('-');
                repeat
                    TempGlobalItemLedgEntry.Reset();
                    if not TempGlobalItemLedgEntry.IsEmpty() then
                        TempGlobalItemLedgEntry.DeleteAll();
                    TempGlobalItemEntryRelation.Reset();
                    if not TempGlobalItemEntryRelation.IsEmpty() then
                        TempGlobalItemEntryRelation.DeleteAll();

                    if not HideDialog then
                        Window.Open(Text001);

                    if Type = Type::Item then begin
                        PostedWhseRcptLineFound :=
                        WhseUndoQty.FindPostedWhseRcptLine(
                            PostedWhseRcptLine,
                            DATABASE::"Return Receipt Line", "Document No.",
                            DATABASE::"Sales Line", SalesLine."Document Type"::"Return Order".AsInteger(), "Return Order No.", "Return Order Line No.");

                        ItemShptEntryNo := PostItemJnlLine(ReturnRcptLine, DocLineNo);
                    end else
                        DocLineNo := GetCorrectionLineNo(ReturnRcptLine);

                    InsertNewReceiptLine(ReturnRcptLine, ItemShptEntryNo, DocLineNo);

                    IsHandled := false;
                    OnAfterInsertNewReceiptLine(ReturnRcptLine, PostedWhseRcptLine, PostedWhseRcptLineFound, DocLineNo, IsHandled);
                    if not IsHandled then begin
                        SalesLine.Get(SalesLine."Document Type"::"Return Order", "Return Order No.",
                        "Return Order Line No.");
                        if "Item Rcpt. Entry No." > 0 then
                            if SalesLine."Appl.-from Item Entry" <> 0 then begin
                                SalesLine."Appl.-from Item Entry" := ItemShptEntryNo;
                                SalesLine.Modify();
                            end;

                        if PostedWhseRcptLineFound then
                            WhseUndoQty.UndoPostedWhseRcptLine(PostedWhseRcptLine);

                        UpdateOrderLine(ReturnRcptLine);
                        UpdateItemTrkgApplFromEntry(SalesLine);
                    end;

                    if PostedWhseRcptLineFound then
                        WhseUndoQty.UpdateRcptSourceDocLines(PostedWhseRcptLine);

                    "Quantity Invoiced" := Quantity;
                    "Qty. Invoiced (Base)" := "Quantity (Base)";
                    "Return Qty. Rcd. Not Invd." := 0;
                    Correction := true;

                    OnBeforeReturnRcptLineModify(ReturnRcptLine, TempWhseJnlLine);
                    Modify();
                    OnAfterReturnRcptLineModify(ReturnRcptLine, TempWhseJnlLine, DocLineNo, HideDialog);
                until Next() = 0;

                MakeInventoryAdjustment();

                WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);
            end;

        OnAfterCode(ReturnRcptLine);
    end;

    local procedure CheckReturnRcptLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnRcptLine(ReturnRcptLine, IsHandled);
        if IsHandled then
            exit;

        if ReturnRcptLine.Correction then
            Error(AlreadyReversedErr);

        IsHandled := false;
        OnCheckReturnRcptLineOnBeforeCheckReturnQtyRcdNotInvd(ReturnRcptLine, IsHandled);
        if not IsHandled then
            if ReturnRcptLine."Return Qty. Rcd. Not Invd." <> ReturnRcptLine.Quantity then
                Error(Text004);

        if ReturnRcptLine.Type = "Sales Line Type"::Item then begin
            UndoPostingMgt.TestReturnRcptLine(ReturnRcptLine);
            IsHandled := false;
            OnCheckReturnRcptLineOnBeforeCollectItemLedgEntries(ReturnRcptLine, TempItemLedgEntry, IsHandled);
            if not IsHandled then begin
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Return Receipt Line",
                ReturnRcptLine."Document No.", ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, ReturnRcptLine."Line No.");
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(ReturnRcptLine: Record "Return Receipt Line") Result: Integer;
    var
        ReturnRcptLine2: Record "Return Receipt Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(ReturnRcptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with ReturnRcptLine do begin
            ReturnRcptLine2.SetRange("Document No.", "Document No.");
            ReturnRcptLine2."Document No." := "Document No.";
            ReturnRcptLine2."Line No." := "Line No.";
            ReturnRcptLine2.Find('=');

            if ReturnRcptLine2.Find('>') then begin
                LineSpacing := (ReturnRcptLine2."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(Text002);
            end else
                LineSpacing := 10000;

            exit("Line No." + LineSpacing);
        end;
    end;

    local procedure PostItemJnlLine(ReturnRcptLine: Record "Return Receipt Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        ReturnRcptHeader: Record "Return Receipt Header";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ReturnRcptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        with ReturnRcptLine do begin
            DocLineNo := GetCorrectionLineNo(ReturnRcptLine);

            SourceCodeSetup.Get();
            ReturnRcptHeader.Get("Document No.");
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Posting Date" := ReturnRcptHeader."Posting Date";
            ItemJnlLine."Document No." := "Document No.";
            ItemJnlLine."Document Line No." := DocLineNo;
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
            ItemJnlLine."Applies-to Entry" := "Item Rcpt. Entry No.";
            ItemJnlLine.Correction := true;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine.Quantity := Quantity;
            ItemJnlLine."Quantity (Base)" := "Quantity (Base)";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Document Date" := ReturnRcptHeader."Document Date";

            IsHandled := false;
            OnAfterCopyItemJnlLineFromReturnRcpt(
                ItemJnlLine, ReturnRcptHeader, ReturnRcptLine, WhseUndoQty, ItemLedgEntryNo, TempWhseJnlLine, NextLineNo, ReturnRcptHeader,
                TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, IsHandled);
            if IsHandled then
                exit(ItemLedgEntryNo);

            WhseUndoQty.InsertTempWhseJnlLine(
                ItemJnlLine,
                DATABASE::"Sales Line", SalesLine."Document Type"::"Return Order".AsInteger(), "Return Order No.", "Return Order Line No.",
                TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.".AsInteger(), TempWhseJnlLine, NextLineNo);

            if "Item Rcpt. Entry No." <> 0 then begin
                ItemJnlPostLine.Run(ItemJnlLine);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;

            UndoPostingMgt.CollectItemLedgEntries(
                TempApplyToEntryList, DATABASE::"Return Receipt Line", "Document No.", "Line No.", "Quantity (Base)", "Item Rcpt. Entry No.");

            UndoPostingMgt.PostItemJnlLineAppliedToList(
                ItemJnlLine, TempApplyToEntryList, Quantity, "Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewReceiptLine(OldReturnRcptLine: Record "Return Receipt Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewReturnRcptLine: Record "Return Receipt Line";
    begin
        with OldReturnRcptLine do begin
            NewReturnRcptLine.Init();
            NewReturnRcptLine.Copy(OldReturnRcptLine);
            NewReturnRcptLine."Line No." := DocLineNo;
            NewReturnRcptLine."Appl.-from Item Entry" := "Item Rcpt. Entry No.";
            NewReturnRcptLine."Item Rcpt. Entry No." := ItemShptEntryNo;
            NewReturnRcptLine.Quantity := -Quantity;
            NewReturnRcptLine."Return Qty. Rcd. Not Invd." := 0;
            NewReturnRcptLine."Quantity (Base)" := -"Quantity (Base)";
            NewReturnRcptLine."Quantity Invoiced" := NewReturnRcptLine.Quantity;
            NewReturnRcptLine."Qty. Invoiced (Base)" := NewReturnRcptLine."Quantity (Base)";
            NewReturnRcptLine.Correction := true;
            NewReturnRcptLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeNewReturnRcptLineInsert(NewReturnRcptLine, OldReturnRcptLine);
            NewReturnRcptLine.Insert();
            OnAfterNewReturnRcptLineInsert(NewReturnRcptLine, OldReturnRcptLine);

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewReturnRcptLine);
        end;
    end;

    procedure UpdateOrderLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(ReturnRcptLine, IsHandled);
        if IsHandled then
            exit;

        with ReturnRcptLine do begin
            SalesLine.Get(SalesLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
            OnUpdateOrderLineOnBeforeUpdateSalesLine(ReturnRcptLine, SalesLine);
            UndoPostingMgt.UpdateSalesLine(SalesLine, Quantity, "Quantity (Base)", TempGlobalItemLedgEntry);
            OnAfterUpdateSalesLine(ReturnRcptLine, SalesLine);
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewReturnRcptLine: Record "Return Receipt Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsReturnRcptLine(NewReturnRcptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure UpdateItemTrkgApplFromEntry(SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        SalesLine.SetReservationFilters(ReservationEntry);
        if ReservationEntry.FindSet() then
            repeat
                if ReservationEntry."Appl.-from Item Entry" <> 0 then
                    if ItemApplicationEntry.AppliedOutbndEntryExists(ReservationEntry."Item Ledger Entry No.", false, false) then begin
                        ReservationEntry."Appl.-from Item Entry" := ItemApplicationEntry."Outbound Item Entry No.";
                        ReservationEntry.Modify();
                    end;
            until ReservationEntry.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
            InvtAdjmtHandler.SetJobUpdateProperties(true);
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(ReturnReceiptLine: Record "Return Receipt Line"; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromReturnRcpt(var ItemJournalLine: Record "Item Journal Line"; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var WhseUndoQty: Codeunit "Whse. Undo Quantity"; var ItemLedgEntryNo: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer; ReturnRcptHeader: Record "Return Receipt Header"; var TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var PostedWhseRcptLineFound: Boolean; DocLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewReturnRcptLineInsert(var NewReturnReceiptLine: Record "Return Receipt Line"; OldReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnRcptLineModify(var ReturnRcptLine: Record "Return Receipt Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; DocLineNo: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var ReturnRcptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnRcptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(ReturnRcptLine: Record "Return Receipt Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewReturnRcptLineInsert(var NewReturnReceiptLine: Record "Return Receipt Line"; OldReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ReturnReceiptLine: Record "Return Receipt Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnRcptLineModify(var ReturnReceiptLine: Record "Return Receipt Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrderLineOnBeforeUpdateSalesLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReturnRcptLineOnBeforeCheckReturnQtyRcdNotInvd(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReturnRcptLineOnBeforeCollectItemLedgEntries(var ReturnRcptLine: Record "Return Receipt Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

