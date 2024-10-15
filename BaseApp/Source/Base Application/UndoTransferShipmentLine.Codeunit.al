codeunit 31070 "Undo Transfer Shipment Line"
{
    Permissions = TableData "Item Application Entry" = rmd,
                  TableData "Transfer Line" = imd,
                  TableData "Transfer Shipment Line" = imd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Transfer Shipment Line";

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        ItemList: Text;
        ConfirmQst: Text;
    begin
        ItemList := GetItemList(Rec);
        if ItemList = '' then
            Error(EmptyItemNoErr);

        ConfirmQst := UndoShptLinesQst + '\\' + ItemList;
        if not HideDialog then
            if not Confirm(ConfirmQst) then
                exit;

        TransShptLineGlob.Copy(Rec);
        Code;
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := TransShptLineGlob;
    end;

    var
        TransShptHdr: Record "Transfer Shipment Header";
        TransShptLineGlob: Record "Transfer Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        HideDialog: Boolean;
        NextLineNo: Integer;
        UndoShptLinesQst: Label 'Do you really want to undo the selected Shipment lines?';
        UndoQtyPostingMsg: Label 'Undo quantity posting...';
        NotEnoughSpaceErr: Label 'There is not enough space to insert correction lines.';
        CheckingLinesMsg: Label 'Checking lines...';
        ShptAlreadyReceiptErr: Label 'This shipment has already been received. Undo Shipment can be applied only to posted, but not received shipments.';
        EmptyItemNoErr: Label 'Undo Shipment can be performed only for lines with nonempty Item No. Please select a line with nonempty Item No. and repeat the procedure.';

    [Scope('OnPrem')]
    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        TransHeader: Record "Transfer Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        ReleaseTransDoc: Codeunit "Release Transfer Document";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        Release: Boolean;
        PostedWhseShptLineFound: Boolean;
    begin
        with TransShptLineGlob do begin
            Clear(ItemJnlPostLine);
            SetRange(Correction, false);

            repeat
                if not HideDialog then
                    Window.Open(CheckingLinesMsg);
                CheckTransShptLine;
            until Next = 0;

            TransHeader.Get("Transfer Order No.");
            Release := TransHeader.Status = TransHeader.Status::Released;
            if Release then
                ReleaseTransDoc.Reopen(TransHeader);

            FindSet(false, false);
            repeat
                TempGlobalItemLedgEntry.Reset;
                if not TempGlobalItemLedgEntry.IsEmpty then
                    TempGlobalItemLedgEntry.DeleteAll;
                TempGlobalItemEntryRelation.Reset;
                if not TempGlobalItemEntryRelation.IsEmpty then
                    TempGlobalItemEntryRelation.DeleteAll;

                if not HideDialog then
                    Window.Open(UndoQtyPostingMsg);

                PostedWhseShptLineFound :=
                  WhseUndoQty.FindPostedWhseShptLine(
                    PostedWhseShptLine,
                    DATABASE::"Transfer Shipment Line",
                    "Document No.",
                    DATABASE::"Transfer Line",
                    0,
                    "Transfer Order No.",
                    "Line No.");

                ItemShptEntryNo := PostItemJnlLine;

                InsertNewShipmentLine(TransShptLineGlob, ItemShptEntryNo);

                if PostedWhseShptLineFound then
                    WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

                TempWhseJnlLine.SetRange("Source Line No.", "Line No.");
                WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);

                UpdateTransLine(TransShptLineGlob);

                if PostedWhseShptLineFound then
                    WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

                Correction := true;
                Modify;

            until Next = 0;

            InvtSetup.Get;
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                TransShptHdr.Get("Document No.");
                InvtAdjmt.SetProperties(true, true);
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            if Release then begin
                TransHeader.Find;
                ReleaseTransDoc.Run(TransHeader);
            end;
        end;
    end;

    local procedure CheckTransShptLine()
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TransLine: Record "Transfer Line";
    begin
        with TransShptLineGlob do begin
            TransLine.Get("Transfer Order No.", "Line No.");
            if TransLine."Quantity Received" <> 0 then
                Error(ShptAlreadyReceiptErr);

            UndoPostingMgt.TestTransferShptLine(TransShptLineGlob);
            UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Transfer Shipment Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
            UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.");
        end;
    end;

    local procedure PostItemJnlLine(): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TransShptHeader: Record "Transfer Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        with TransShptLineGlob do begin
            SourceCodeSetup.Get;
            TransShptHeader.Get("Document No.");

            ItemJnlLine.Init;

            ItemJnlLine."Posting Date" := TransShptHeader."Posting Date";
            ItemJnlLine."Document Date" := TransShptHeader."Posting Date";
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Transfer Shipment";
            ItemJnlLine."Document No." := TransShptHeader."No.";
            ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
            ItemJnlLine."Order No." := TransShptHeader."Transfer Order No.";
            ItemJnlLine."External Document No." := TransShptHeader."External Document No.";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
            ItemJnlLine."Item No." := "Item No.";
            ItemJnlLine.Description := Description;
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."New Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."New Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Dimension Set ID" := "Dimension Set ID";
            ItemJnlLine."New Dimension Set ID" := "Dimension Set ID";
            ItemJnlLine."Location Code" := TransShptHeader."In-Transit Code";
            ItemJnlLine."New Location Code" := TransShptHeader."Transfer-from Code";
            ItemJnlLine.Quantity := Quantity;
            ItemJnlLine."Invoiced Quantity" := Quantity;
            ItemJnlLine."Quantity (Base)" := "Quantity (Base)";
            ItemJnlLine."Invoiced Qty. (Base)" := "Quantity (Base)";
            ItemJnlLine."Source Code" := SourceCodeSetup.Transfer;
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Inventory Posting Group" := "Inventory Posting Group";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."New Bin Code" := "Transfer-from Bin Code";
            ItemJnlLine."Country/Region Code" := TransShptHeader."Trsf.-from Country/Region Code";
            ItemJnlLine."Transaction Type" := TransShptHeader."Transaction Type";
            ItemJnlLine."Transport Method" := TransShptHeader."Transport Method";
            ItemJnlLine."Entry/Exit Point" := TransShptHeader."Entry/Exit Point";
            ItemJnlLine.Area := TransShptHeader.Area;
            ItemJnlLine."Transaction Specification" := TransShptHeader."Transaction Specification";
            ItemJnlLine."Item Category Code" := "Item Category Code";
            ItemJnlLine.Validate("Gen. Bus. Posting Group", "Gen. Bus. Post. Group Ship");
            ItemJnlLine."Shpt. Method Code" := TransShptHeader."Shipment Method Code";

            InsertTempWhseJnlLine(ItemJnlLine,
              DATABASE::"Transfer Line",
              0,
              "Transfer Order No.",
              "Line No.",
              TempWhseJnlLine."Reference Document"::"Posted T. Shipment",
              TempWhseJnlLine,
              NextLineNo);

            if "Item Shpt. Entry No." <> 0 then begin
                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;
            UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Transfer Shipment Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");

            UndoPostingMgt.PostItemJnlLineAppliedToListTr(ItemJnlLine, TempItemLedgEntry,
              Quantity, "Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewShipmentLine(OldTransShptLine: Record "Transfer Shipment Line"; ItemShptEntryNo: Integer)
    var
        NewTransShptLine: Record "Transfer Shipment Line";
        LineSpacing: Integer;
    begin
        with OldTransShptLine do begin
            NewTransShptLine.SetRange("Document No.", "Document No.");
            NewTransShptLine."Document No." := "Document No.";
            NewTransShptLine."Line No." := "Line No.";
            NewTransShptLine.Find('=');

            if NewTransShptLine.Find('>') then begin
                LineSpacing := (NewTransShptLine."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(NotEnoughSpaceErr);
            end else
                LineSpacing := 10000;

            NewTransShptLine.Reset;
            NewTransShptLine.Init;
            NewTransShptLine.Copy(OldTransShptLine);
            NewTransShptLine."Line No." := "Line No." + LineSpacing;
            NewTransShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
            NewTransShptLine.Quantity := -Quantity;
            NewTransShptLine."Quantity (Base)" := -"Quantity (Base)";
            NewTransShptLine.Correction := true;
            NewTransShptLine.Insert;

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewTransShptLine);
        end;
    end;

    local procedure UpdateTransLine(TransShptLine: Record "Transfer Shipment Line")
    var
        TransLine: Record "Transfer Line";
    begin
        with TransShptLine do begin
            TransLine.Get("Transfer Order No.", "Line No.");
            UndoPostingMgt.UpdateTransferLine(TransLine, Quantity, "Quantity (Base)", TempGlobalItemLedgEntry);
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewTransShptLine: Record "Transfer Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.FindSet(false, false) then begin
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsTransShptLine(NewTransShptLine);
                ItemEntryRelation.Insert;
            until TempItemEntryRelation.Next = 0;
        end;
    end;

    local procedure GetItemList(var TransShptLine: Record "Transfer Shipment Line") ItemList: Text
    var
        TransShptLine2: Record "Transfer Shipment Line";
    begin
        with TransShptLine2 do begin
            Copy(TransShptLine);
            SetFilter("Item No.", '<>%1', '');
            SetFilter(Quantity, '<>%1', 0);
            if FindSet then
                repeat
                    ItemList := ItemList + StrSubstNo('%1 %2: %3 %4\', "Item No.", Description, Quantity, "Unit of Measure Code");
                until Next = 0;
        end;
    end;

    local procedure InsertTempWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; RefDoc: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer)
    var
        WhseEntry: Record "Warehouse Entry";
        WhseMgt: Codeunit "Whse. Management";
        WMSMgt: Codeunit "WMS Management";
    begin
        with ItemJnlLine do begin
            WhseEntry.Reset;
            WhseEntry.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            WhseEntry.SetRange("Source Type", SourceType);
            WhseEntry.SetRange("Source Subtype", SourceSubType);
            WhseEntry.SetRange("Source No.", SourceNo);
            WhseEntry.SetRange("Source Line No.", SourceLineNo);
            WhseEntry.SetRange("Reference No.", "Document No.");
            WhseEntry.SetRange("Item No.", "Item No.");
            if WhseEntry.Find('+') then
                repeat
                    TempWhseJnlLine.Init;
                    if WhseEntry."Entry Type" = WhseEntry."Entry Type"::"Positive Adjmt." then
                        "Entry Type" := "Entry Type"::"Negative Adjmt."
                    else
                        "Entry Type" := "Entry Type"::"Positive Adjmt.";
                    Quantity := Abs(WhseEntry.Quantity);
                    "Quantity (Base)" := Abs(WhseEntry."Qty. (Base)");
                    WMSMgt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, true);
                    TempWhseJnlLine."Source Type" := SourceType;
                    TempWhseJnlLine."Source Subtype" := SourceSubType;
                    TempWhseJnlLine."Source No." := SourceNo;
                    TempWhseJnlLine."Source Line No." := SourceLineNo;
                    TempWhseJnlLine."Source Document" :=
                      WhseMgt.GetSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
                    TempWhseJnlLine."Reference Document" := RefDoc;
                    TempWhseJnlLine."Reference No." := "Document No.";
                    TempWhseJnlLine."Location Code" := WhseEntry."Location Code";
                    TempWhseJnlLine."Zone Code" := WhseEntry."Zone Code";
                    TempWhseJnlLine."Bin Code" := WhseEntry."Bin Code";
                    TempWhseJnlLine."Whse. Document Type" := WhseEntry."Whse. Document Type";
                    TempWhseJnlLine."Whse. Document No." := WhseEntry."Whse. Document No.";
                    TempWhseJnlLine."Unit of Measure Code" := WhseEntry."Unit of Measure Code";
                    TempWhseJnlLine."Line No." := NextLineNo;
                    TempWhseJnlLine."Serial No." := WhseEntry."Serial No.";
                    TempWhseJnlLine."Lot No." := WhseEntry."Lot No.";
                    TempWhseJnlLine."Expiration Date" := WhseEntry."Expiration Date";
                    if "Entry Type" = "Entry Type"::"Negative Adjmt." then begin
                        TempWhseJnlLine."From Zone Code" := TempWhseJnlLine."Zone Code";
                        TempWhseJnlLine."From Bin Code" := TempWhseJnlLine."Bin Code";
                    end else begin
                        TempWhseJnlLine."To Zone Code" := TempWhseJnlLine."Zone Code";
                        TempWhseJnlLine."To Bin Code" := TempWhseJnlLine."Bin Code";
                    end;
                    TempWhseJnlLine.Insert;
                    NextLineNo := TempWhseJnlLine."Line No." + 10000;
                until WhseEntry.Next(-1) = 0;
        end;
    end;
}

