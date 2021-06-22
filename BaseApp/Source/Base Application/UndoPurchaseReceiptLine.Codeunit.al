codeunit 5813 "Undo Purchase Receipt Line"
{
    Permissions = TableData "Purchase Line" = imd,
                  TableData "Purch. Rcpt. Line" = imd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Whse. Item Entry Relation" = rimd;
    TableNo = "Purch. Rcpt. Line";

    trigger OnRun()
    var
        SkipTypeCheck: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        PurchRcptLine.Copy(Rec);
        Code;
        Rec := PurchRcptLine;
    end;

    var
        Text000: Label 'Do you really want to undo the selected Receipt lines?';
        Text001: Label 'Undo quantity posting...';
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        Text002: Label 'There is not enough space to insert correction lines.';
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        UOMMgt: Codeunit "Unit of Measure Management";
        HideDialog: Boolean;
        JobItem: Boolean;
        Text003: Label 'Checking lines...';
        NextLineNo: Integer;
        Text004: Label 'This receipt has already been invoiced. Undo Receipt can be applied only to posted, but not invoiced receipts.';
        Text005: Label 'Undo Receipt can be performed only for lines of type Item. Please select a line of the Item type and repeat the procedure.';
        AllLinesCorrectedErr: Label 'All lines have been already corrected.';
        AlreadyReversedErr: Label 'This receipt has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        PurchLine: Record "Purchase Line";
        Window: Dialog;
        ItemRcptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseRcptLineFound: Boolean;
    begin
        with PurchRcptLine do begin
            SetFilter(Quantity, '<>0');
            SetRange(Correction, false);
            if IsEmpty then
                Error(AllLinesCorrectedErr);

            FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                CheckPurchRcptLine(PurchRcptLine);
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
                        DATABASE::"Purch. Rcpt. Line",
                        "Document No.",
                        DATABASE::"Purchase Line",
                        PurchLine."Document Type"::Order,
                        "Order No.",
                        "Order Line No.");

                    ItemRcptEntryNo := PostItemJnlLine(PurchRcptLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(PurchRcptLine);

                InsertNewReceiptLine(PurchRcptLine, ItemRcptEntryNo, DocLineNo);
                OnAfterInsertNewReceiptLine(PurchRcptLine, PostedWhseRcptLine, PostedWhseRcptLineFound, DocLineNo);

                if PostedWhseRcptLineFound then
                    WhseUndoQty.UndoPostedWhseRcptLine(PostedWhseRcptLine);

                UpdateOrderLine(PurchRcptLine);
                if PostedWhseRcptLineFound then
                    WhseUndoQty.UpdateRcptSourceDocLines(PostedWhseRcptLine);

                if ("Blanket Order No." <> '') and ("Blanket Order Line No." <> 0) then
                    UpdateBlanketOrder(PurchRcptLine);

                "Quantity Invoiced" := Quantity;
                "Qty. Invoiced (Base)" := "Quantity (Base)";
                "Qty. Rcd. Not Invoiced" := 0;
                Correction := true;

                OnBeforePurchRcptLineModify(PurchRcptLine, TempWhseJnlLine);
                Modify;
                OnAfterPurchRcptLineModify(PurchRcptLine, TempWhseJnlLine);

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

        OnAfterCode(PurchRcptLine);
    end;

    local procedure CheckPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchRcptLine(PurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        with PurchRcptLine do begin
            if Correction then
                Error(AlreadyReversedErr);
            if "Qty. Rcd. Not Invoiced" <> Quantity then
                if HasInvoicedNotReturnedQuantity(PurchRcptLine) then
                    Error(Text004);
            if Type = Type::Item then begin
                TestField("Prod. Order No.", '');
                TestField("Sales Order No.", '');
                TestField("Sales Order Line No.", 0);

                UndoPostingMgt.TestPurchRcptLine(PurchRcptLine);
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Purch. Rcpt. Line",
                  "Document No.", "Line No.", "Quantity (Base)", "Item Rcpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.", "Qty. Rcd. Not Invoiced" <> Quantity);
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(PurchRcptLine: Record "Purch. Rcpt. Line"): Integer
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        LineSpacing: Integer;
    begin
        with PurchRcptLine do begin
            PurchRcptLine2.SetRange("Document No.", "Document No.");
            PurchRcptLine2."Document No." := "Document No.";
            PurchRcptLine2."Line No." := "Line No.";
            PurchRcptLine2.Find('=');

            if PurchRcptLine2.Find('>') then begin
                LineSpacing := (PurchRcptLine2."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(Text002);
            end else
                LineSpacing := 10000;
            exit("Line No." + LineSpacing);
        end;
    end;

    local procedure PostItemJnlLine(PurchRcptLine: Record "Purch. Rcpt. Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
        Item: Record Item;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemLedgEntryNo: Integer;
        IsHandled: Boolean;
        NewDocLineNo: Integer;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(PurchRcptLine, DocLineNo, ItemLedgEntryNo, IsHandled, NewDocLineNo);
        if NewDocLineNo > DocLineNo then
            DocLineNo := NewDocLineNo;
        if IsHandled then
            exit(ItemLedgEntryNo);

        with PurchRcptLine do begin
            DocLineNo := GetCorrectionLineNo(PurchRcptLine);

            SourceCodeSetup.Get();
            PurchRcptHeader.Get("Document No.");
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Posting Date" := PurchRcptHeader."Posting Date";
            ItemJnlLine."Document No." := "Document No.";
            ItemJnlLine."Document Line No." := DocLineNo;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Source Code" := SourceCodeSetup.Purchases;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Document Date" := PurchRcptHeader."Document Date";
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";

            if "Job No." = '' then begin
                ItemJnlLine.Correction := true;
                ItemJnlLine."Applies-to Entry" := "Item Rcpt. Entry No.";
            end else begin
                ItemJnlLine."Job No." := "Job No.";
                ItemJnlLine."Job Task No." := "Job Task No.";
                ItemJnlLine."Job Purchase" := true;
                ItemJnlLine."Unit Cost" := "Unit Cost (LCY)";
            end;
            ItemJnlLine.Quantity := -(Quantity - "Quantity Invoiced");
            ItemJnlLine."Quantity (Base)" := -("Quantity (Base)" - "Qty. Invoiced (Base)");

            OnAfterCopyItemJnlLineFromPurchRcpt(ItemJnlLine, PurchRcptHeader, PurchRcptLine);

            WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
              DATABASE::"Purchase Line",
              PurchLine."Document Type"::Order,
              "Order No.",
              "Line No.",
              TempWhseJnlLine."Reference Document"::"Posted Rcpt.",
              TempWhseJnlLine,
              NextLineNo);

            if "Item Rcpt. Entry No." <> 0 then begin
                if "Job No." <> '' then
                    UndoPostingMgt.TransferSourceValues(ItemJnlLine, "Item Rcpt. Entry No.");

                IsHandled := false;
                OnPostItemJnlLineOnBeforeUndoPosting(ItemJnlLine, PurchRcptHeader, PurchRcptLine, SourceCodeSetup, IsHandled);
                if IsHandled then
                    exit(ItemJnlLine."Item Shpt. Entry No.");

                UndoPostingMgt.PostItemJnlLine(ItemJnlLine);

                if "Job No." <> '' then begin
                    Item.Get("No.");
                    if Item.Type = Item.Type::Inventory then begin
                        UndoPostingMgt.FindItemReceiptApplication(ItemApplicationEntry, "Item Rcpt. Entry No.");
                        ItemJnlPostLine.UndoValuePostingWithJob(
                          "Item Rcpt. Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
                        IsHandled := false;
                        OnPostItemJournalInboundItemEntryPostingWithJob(ItemJnlLine, ItemApplicationEntry, IsHandled);
                        if not IsHandled then begin
                            UndoPostingMgt.FindItemShipmentApplication(ItemApplicationEntry, ItemJnlLine."Item Shpt. Entry No.");
                            ItemJnlPostLine.UndoValuePostingWithJob(
                              ItemApplicationEntry."Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
                        end;
                        Clear(UndoPostingMgt);
                        UndoPostingMgt.ReapplyJobConsumption("Item Rcpt. Entry No.");
                    end;
                end;

                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;

            UndoPostingMgt.CollectItemLedgEntries(
              TempApplyToEntryList, DATABASE::"Purch. Rcpt. Line", "Document No.", "Line No.", "Quantity (Base)", "Item Rcpt. Entry No.");

            if "Job No." <> '' then
                if TempApplyToEntryList.FindSet then
                    repeat
                        UndoPostingMgt.ReapplyJobConsumption(TempApplyToEntryList."Entry No.");
                    until TempApplyToEntryList.Next = 0;

            UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
              Quantity - "Quantity Invoiced", "Quantity (Base)" - "Qty. Invoiced (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, "Qty. Rcd. Not Invoiced" <> Quantity);

            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewReceiptLine(OldPurchRcptLine: Record "Purch. Rcpt. Line"; ItemRcptEntryNo: Integer; DocLineNo: Integer)
    var
        NewPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        with OldPurchRcptLine do begin
            NewPurchRcptLine.Init();
            NewPurchRcptLine.Copy(OldPurchRcptLine);
            NewPurchRcptLine."Line No." := DocLineNo;
            NewPurchRcptLine."Appl.-to Item Entry" := "Item Rcpt. Entry No.";
            NewPurchRcptLine."Item Rcpt. Entry No." := ItemRcptEntryNo;
            NewPurchRcptLine.Quantity := -Quantity;
            NewPurchRcptLine."Quantity (Base)" := -"Quantity (Base)";
            NewPurchRcptLine."Quantity Invoiced" := NewPurchRcptLine.Quantity;
            NewPurchRcptLine."Qty. Invoiced (Base)" := NewPurchRcptLine."Quantity (Base)";
            NewPurchRcptLine."Qty. Rcd. Not Invoiced" := 0;
            NewPurchRcptLine.Correction := true;
            NewPurchRcptLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeNewPurchRcptLineInsert(NewPurchRcptLine, OldPurchRcptLine);
            NewPurchRcptLine.Insert();
            OnAfterNewPurchRcptLineInsert(NewPurchRcptLine, OldPurchRcptLine);

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewPurchRcptLine);
        end;
    end;

    procedure UpdateOrderLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchRcptLine do begin
            PurchLine.Get(PurchLine."Document Type"::Order, "Order No.", "Order Line No.");
            UndoPostingMgt.UpdatePurchLine(PurchLine, Quantity - "Quantity Invoiced", "Quantity (Base)" - "Qty. Invoiced (Base)", TempGlobalItemLedgEntry);
            UndoPostingMgt.UpdatePurchaseLineOverRcptQty(PurchLine, "Over-Receipt Quantity");
            OnAfterUpdateOrderLine(PurchRcptLine, PurchLine);
        end;
    end;

    procedure UpdateBlanketOrder(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        BlanketOrderPurchaseLine: Record "Purchase Line";
    begin
        with PurchRcptLine do
            if BlanketOrderPurchaseLine.Get(
                 BlanketOrderPurchaseLine."Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.")
            then begin
                BlanketOrderPurchaseLine.TestField(Type, Type);
                BlanketOrderPurchaseLine.TestField("No.", "No.");
                BlanketOrderPurchaseLine.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");

                if BlanketOrderPurchaseLine."Qty. per Unit of Measure" = "Qty. per Unit of Measure" then
                    BlanketOrderPurchaseLine."Quantity Received" := BlanketOrderPurchaseLine."Quantity Received" - Quantity
                else
                    BlanketOrderPurchaseLine."Quantity Received" :=
                      BlanketOrderPurchaseLine."Quantity Received" -
                      Round(
                        "Qty. per Unit of Measure" / BlanketOrderPurchaseLine."Qty. per Unit of Measure" * Quantity, UOMMgt.QtyRndPrecision);

                BlanketOrderPurchaseLine."Qty. Received (Base)" := BlanketOrderPurchaseLine."Qty. Received (Base)" - "Quantity (Base)";
                OnBeforeBlanketOrderInitOutstanding(BlanketOrderPurchaseLine, PurchRcptLine);
                BlanketOrderPurchaseLine.InitOutstanding;
                BlanketOrderPurchaseLine.Modify();
            end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewPurchRcptLine: Record "Purch. Rcpt. Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsPurchRcptLine(NewPurchRcptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next = 0;
    end;

    local procedure HasInvoicedNotReturnedQuantity(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnedInvoicedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        InvoicedQuantity: Decimal;
        ReturnedInvoicedQuantity: Decimal;
    begin
        if PurchRcptLine.Type = PurchRcptLine.Type::Item then begin
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
            ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
            ItemLedgerEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
            ItemLedgerEntry.FindSet();
            repeat
                InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                if ItemApplicationEntry.AppliedOutbndEntryExists(ItemLedgerEntry."Entry No.", false, false) then
                    repeat
                        if ItemApplicationEntry."Item Ledger Entry No." = ItemApplicationEntry."Outbound Item Entry No." then begin
                            ReturnedInvoicedItemLedgerEntry.Get(ItemApplicationEntry."Item Ledger Entry No.");
                            if IsCancelled(ReturnedInvoicedItemLedgerEntry) then
                                ReturnedInvoicedQuantity += ReturnedInvoicedItemLedgerEntry."Invoiced Quantity";
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgerEntry.Next() = 0;
            exit(InvoicedQuantity + ReturnedInvoicedQuantity <> 0);
        end else begin
            PurchInvLine.SetRange("Order No.", PurchRcptLine."Order No.");
            PurchInvLine.SetRange("Order Line No.", PurchRcptLine."Order Line No.");
            if PurchInvLine.FindSet() then
                repeat
                    PurchInvHeader.Get(PurchInvLine."Document No.");
                    PurchInvHeader.CalcFields(Cancelled);
                    if not PurchInvHeader.Cancelled then
                        exit(true);
                until PurchInvLine.Next() = 0;

            exit(false);
        end;
    end;

    local procedure IsCancelled(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                begin
                    ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    if ReturnShipmentHeader."Applies-to Doc. Type" = ReturnShipmentHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Purch. Inv. Header", ReturnShipmentHeader."Applies-to Doc. No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                begin
                    PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
                    if PurchCrMemoHdr."Applies-to Doc. Type" = PurchCrMemoHdr."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Purch. Inv. Header", PurchCrMemoHdr."Applies-to Doc. No."));
                end;
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchRcpt(var ItemJournalLine: Record "Item Journal Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var PostedWhseRcptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewPurchRcptLineInsert(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineModify(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderInitOutstanding(var BlanketOrderPurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewPurchRcptLineInsert(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean; var NewDocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptLineModify(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJournalInboundItemEntryPostingWithJob(var ItemJournalLine: Record "Item Journal Line"; ItemApplicationEntry: Record "Item Application Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeUndoPosting(var ItemJournalLine: Record "Item Journal Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; SourceCodeSetup: Record "Source Code Setup"; var IsHandled: Boolean)
    begin
    end;
}

