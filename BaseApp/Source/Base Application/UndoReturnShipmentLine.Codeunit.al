codeunit 5814 "Undo Return Shipment Line"
{
    Permissions = TableData "Purchase Line" = imd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Return Shipment Line" = imd;
    TableNo = "Return Shipment Line";

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

        ReturnShptLine.Copy(Rec);
        Code;
        Rec := ReturnShptLine;
    end;

    var
        Text000: Label 'Do you really want to undo the selected Return Shipment lines?';
        ReturnShptLine: Record "Return Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        HideDialog: Boolean;
        Text003: Label 'Checking lines...';
        JobItem: Boolean;
        NextLineNo: Integer;
        Text004: Label 'This shipment has already been invoiced. Undo Return Shipment can be applied only to posted, but not invoiced shipments.';
        Text005: Label 'Undo Return Shipment can be performed only for lines of type Item. Please select a line of the Item type and repeat the procedure.';
        AlreadyReversedErr: Label 'This return shipment has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseShptLineFound: Boolean;
    begin
        with ReturnShptLine do begin
            Clear(ItemJnlPostLine);
            SetFilter(Quantity, '<>0');
            SetRange(Correction, false);
            if IsEmpty then
                Error(AlreadyReversedErr);
            FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                CheckReturnShptLine(ReturnShptLine);
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
                    PostedWhseShptLineFound :=
                      WhseUndoQty.FindPostedWhseShptLine(
                        PostedWhseShptLine,
                        DATABASE::"Return Shipment Line",
                        "Document No.",
                        DATABASE::"Purchase Line",
                        SalesLine."Document Type"::"Return Order",
                        "Return Order No.",
                        "Return Order Line No.");

                    ItemShptEntryNo := PostItemJnlLine(ReturnShptLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(ReturnShptLine);

                InsertNewReturnShptLine(ReturnShptLine, ItemShptEntryNo, DocLineNo);
                OnAfterInsertNewReturnShptLine(ReturnShptLine, PostedWhseShptLine, PostedWhseShptLineFound, DocLineNo);

                if PostedWhseShptLineFound then
                    WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

                UpdateOrderLine(ReturnShptLine);
                if PostedWhseShptLineFound then
                    WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

                "Quantity Invoiced" := Quantity;
                "Qty. Invoiced (Base)" := "Quantity (Base)";
                "Return Qty. Shipped Not Invd." := 0;
                Correction := true;

                OnBeforeReturnShptLineModify(ReturnShptLine);
                Modify;
                OnAfterReturnShptLineModify(ReturnShptLine);

                if not JobItem then
                    JobItem := (Type = Type::Item) and ("Job No." <> '');
            until Next = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.SetJobUpdateProperties(not JobItem);
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);
        end;

        OnAfterCode(ReturnShptLine);
    end;

    local procedure CheckReturnShptLine(ReturnShptLine: Record "Return Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnShptLine(ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        with ReturnShptLine do begin
            if Correction then
                Error(AlreadyReversedErr);
            if "Return Qty. Shipped Not Invd." <> Quantity then
                Error(Text004);

            if Type = Type::Item then begin
                TestField("Prod. Order No.", '');

                UndoPostingMgt.TestReturnShptLine(ReturnShptLine);
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Return Shipment Line",
                  "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.");
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(ReturnShptLine: Record "Return Shipment Line"): Integer
    var
        ReturnShptLine2: Record "Return Shipment Line";
        LineSpacing: Integer;
    begin
        with ReturnShptLine do begin
            ReturnShptLine2.SetRange("Document No.", "Document No.");
            ReturnShptLine2."Document No." := "Document No.";
            ReturnShptLine2."Line No." := "Line No.";
            ReturnShptLine2.Find('=');

            if ReturnShptLine2.Find('>') then begin
                LineSpacing := (ReturnShptLine2."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(Text002);
            end else
                LineSpacing := 10000;

            exit("Line No." + LineSpacing);
        end;
    end;

    local procedure PostItemJnlLine(ReturnShptLine: Record "Return Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ReturnShptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        with ReturnShptLine do begin
            DocLineNo := GetCorrectionLineNo(ReturnShptLine);

            SourceCodeSetup.Get();
            ReturnShptHeader.Get("Document No.");
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Posting Date" := ReturnShptHeader."Posting Date";
            ItemJnlLine."Document No." := "Document No.";
            ItemJnlLine."Document Line No." := DocLineNo;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Return Shipment";
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Source Code" := SourceCodeSetup.Purchases;
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";
            if "Job No." = '' then begin
                ItemJnlLine.Correction := true;
                ItemJnlLine."Applies-to Entry" := "Item Shpt. Entry No.";
            end else begin
                ItemJnlLine."Job No." := "Job No.";
                ItemJnlLine."Job Task No." := "Job Task No.";
                ItemJnlLine."Job Purchase" := true;
                ItemJnlLine."Unit Cost" := "Unit Cost (LCY)";
            end;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine.Quantity := "Quantity (Base)";
            ItemJnlLine."Quantity (Base)" := "Quantity (Base)";
            ItemJnlLine."Document Date" := ReturnShptHeader."Document Date";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";

            OnAfterCopyItemJnlLineFromReturnShpt(ItemJnlLine, ReturnShptHeader, ReturnShptLine);

            WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
              DATABASE::"Purchase Line",
              PurchLine."Document Type"::"Return Order",
              "Return Order No.",
              "Return Order Line No.",
              TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment",
              TempWhseJnlLine,
              NextLineNo);

            if "Item Shpt. Entry No." <> 0 then begin
                if "Job No." <> '' then
                    UndoPostingMgt.TransferSourceValues(ItemJnlLine, "Item Shpt. Entry No.");
                UndoPostingMgt.PostItemJnlLine(ItemJnlLine);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;
            UndoPostingMgt.CollectItemLedgEntries(TempApplyToEntryList, DATABASE::"Return Shipment Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");

            UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
              Quantity, "Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewReturnShptLine(OldReturnShptLine: Record "Return Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewReturnShptLine: Record "Return Shipment Line";
    begin
        with OldReturnShptLine do begin
            NewReturnShptLine.Init();
            NewReturnShptLine.Copy(OldReturnShptLine);
            NewReturnShptLine."Line No." := DocLineNo;
            NewReturnShptLine."Appl.-to Item Entry" := "Item Shpt. Entry No.";
            NewReturnShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
            NewReturnShptLine.Quantity := -Quantity;
            NewReturnShptLine."Quantity (Base)" := -"Quantity (Base)";
            NewReturnShptLine."Quantity Invoiced" := NewReturnShptLine.Quantity;
            NewReturnShptLine."Qty. Invoiced (Base)" := NewReturnShptLine."Quantity (Base)";
            NewReturnShptLine."Return Qty. Shipped Not Invd." := 0;
            NewReturnShptLine.Correction := true;
            NewReturnShptLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeNewReturnShptLineInsert(NewReturnShptLine, OldReturnShptLine);
            NewReturnShptLine.Insert();
            OnAfterNewReturnShptLineInsert(NewReturnShptLine, OldReturnShptLine);

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewReturnShptLine);
        end;
    end;

    procedure UpdateOrderLine(ReturnShptLine: Record "Return Shipment Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        with ReturnShptLine do begin
            PurchLine.Get(PurchLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
            UndoPostingMgt.UpdatePurchLine(PurchLine, Quantity, "Quantity (Base)", TempGlobalItemLedgEntry);
            OnAfterUpdatePurchLine(PurchLine, ReturnShptLine);
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewReturnShptLine: Record "Return Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsReturnShptLine(NewReturnShptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromReturnShpt(var ItemJournalLine: Record "Item Journal Line"; ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReturnShptLine(var ReturnShipmentLine: Record "Return Shipment Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewReturnShptLineInsert(var NewReturnShipmentLine: Record "Return Shipment Line"; OldReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLine(var PurchaseLine: Record "Purchase Line"; var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptLineModify(var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewReturnShptLineInsert(var NewReturnShipmentLine: Record "Return Shipment Line"; OldReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ReturnShipmentLine: Record "Return Shipment Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptLineModify(var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;
}

