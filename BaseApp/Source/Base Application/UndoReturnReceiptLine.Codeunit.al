codeunit 5816 "Undo Return Receipt Line"
{
    Permissions = TableData "Sales Line" = imd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Whse. Item Entry Relation" = rimd,
                  TableData "Return Receipt Line" = imd;
    TableNo = "Return Receipt Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
        SkipTypeCheck: Boolean;
    begin
        IsHandled := false;
        SkipTypeCheck := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        ReturnRcptLine.Copy(Rec);
        Code;
        Rec := ReturnRcptLine;
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Text000: Label 'Do you really want to undo the selected Return Receipt lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        HideDialog: Boolean;
        Text003: Label 'Checking lines...';
        NextLineNo: Integer;
        Text004: Label 'This receipt has already been invoiced. Undo Return Receipt can be applied only to posted, but not invoiced receipts.';
        Text005: Label 'Undo Return Receipt can be performed only for lines of type Item. Please select a line of the Item type and repeat the procedure.';
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
    begin
        with ReturnRcptLine do begin
            Clear(ItemJnlPostLine);
            SetRange(Correction, false);
            SetFilter(Quantity, '<>0');
            if IsEmpty then
                Error(AlreadyReversedErr);

            FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                CheckReturnRcptLine(ReturnRcptLine);
            until Next = 0;

            Find('-');
            repeat
                TempGlobalItemLedgEntry.Reset();
                if not TempGlobalItemLedgEntry.IsEmpty then
                    TempGlobalItemLedgEntry.DeleteAll();
                TempGlobalItemEntryRelation.Reset();
                if not TempGlobalItemEntryRelation.IsEmpty then
                    TempGlobalItemEntryRelation.DeleteAll();

                if not HideDialog then
                    Window.Open(Text001);

                if Type = Type::Item then begin
                    PostedWhseRcptLineFound :=
                    WhseUndoQty.FindPostedWhseRcptLine(
                        PostedWhseRcptLine,
                        DATABASE::"Return Receipt Line",
                        "Document No.",
                        DATABASE::"Sales Line",
                        SalesLine."Document Type"::"Return Order",
                        "Return Order No.",
                        "Return Order Line No.");

                    ItemShptEntryNo := PostItemJnlLine(ReturnRcptLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(ReturnRcptLine);

                InsertNewReceiptLine(ReturnRcptLine, ItemShptEntryNo, DocLineNo);
                OnAfterInsertNewReceiptLine(ReturnRcptLine, PostedWhseRcptLine, PostedWhseRcptLineFound, DocLineNo);

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
                if PostedWhseRcptLineFound then
                    WhseUndoQty.UpdateRcptSourceDocLines(PostedWhseRcptLine);

                "Quantity Invoiced" := Quantity;
                "Qty. Invoiced (Base)" := "Quantity (Base)";
                "Return Qty. Rcd. Not Invd." := 0;
                Correction := true;

                OnBeforeReturnRcptLineModify(ReturnRcptLine);
                Modify;
                OnAfterReturnRcptLineModify(ReturnRcptLine);
            until Next = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.SetJobUpdateProperties(true);
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

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

        with ReturnRcptLine do begin
            if Correction then
                Error(AlreadyReversedErr);
            if "Return Qty. Rcd. Not Invd." <> Quantity then
                Error(Text004);
            if Type = Type::Item then begin
                UndoPostingMgt.TestReturnRcptLine(ReturnRcptLine);
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Return Receipt Line",
                "Document No.", "Line No.", "Quantity (Base)", "Item Rcpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.");
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(ReturnRcptLine: Record "Return Receipt Line"): Integer;
    var
        ReturnRcptLine2: Record "Return Receipt Line";
        LineSpacing: Integer;
    begin
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
        LineSpacing: Integer;
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

            OnAfterCopyItemJnlLineFromReturnRcpt(ItemJnlLine, ReturnRcptHeader, ReturnRcptLine);

            WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
              DATABASE::"Sales Line",
              SalesLine."Document Type"::"Return Order",
              "Return Order No.",
              "Return Order Line No.",
              TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.",
              TempWhseJnlLine,
              NextLineNo);

            if "Item Rcpt. Entry No." <> 0 then begin
                ItemJnlPostLine.Run(ItemJnlLine);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;
            UndoPostingMgt.CollectItemLedgEntries(TempApplyToEntryList, DATABASE::"Return Receipt Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Rcpt. Entry No.");

            UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
              Quantity, "Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

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
    begin
        with ReturnRcptLine do begin
            SalesLine.Get(SalesLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
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
            until TempItemEntryRelation.Next = 0;
    end;

    local procedure UpdateItemTrkgApplFromEntry(SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        SalesLine.SetReservationFilters(ReservationEntry);
        if ReservationEntry.FindSet then
            repeat
                if ReservationEntry."Appl.-from Item Entry" <> 0 then
                    if ItemApplicationEntry.AppliedOutbndEntryExists(ReservationEntry."Item Ledger Entry No.", false, false) then begin
                        ReservationEntry."Appl.-from Item Entry" := ItemApplicationEntry."Outbound Item Entry No.";
                        ReservationEntry.Modify();
                    end;
            until ReservationEntry.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromReturnRcpt(var ItemJournalLine: Record "Item Journal Line"; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PostedWhseRcptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewReturnRcptLineInsert(var NewReturnReceiptLine: Record "Return Receipt Line"; OldReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnRcptLineModify(var ReturnRcptLine: Record "Return Receipt Line")
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
    local procedure OnBeforeOnRun(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
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
    local procedure OnBeforeReturnRcptLineModify(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;
}

